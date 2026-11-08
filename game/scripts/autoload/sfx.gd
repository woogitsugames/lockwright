extends Node
## Sfx facade. Short samples from a preallocated AudioStreamPlayer pool
## (no first-click latency), layered by material x event with random variants.
## Continuous friction/resistance loops run on an AudioStreamGenerator driven
## by a parameter. Critical clicks additionally go to the native low-latency
## bridge when present (docs/TECH.md §1.6).

const EVENTS := [&"contact", &"bind", &"near_shear", &"set", &"false_set", &"counter_rotate", &"overset", &"drop", &"stress", &"break", &"wear", &"gate_align", &"detector_trip", &"open"]
const MATERIALS := [&"brass", &"steel", &"iron", &"wood"]
const LOOPS := [&"tension_resistance", &"pick_drag"]
const POOL_SIZE := 12
const VARIANTS := 6  # FEEL F-09: audio/v2 ships 6 variants
const SFX_ROOT := "res://assets/audio/sfx"
const AMBIENCE_ROOT := "res://assets/audio/ambience"
const UI_ROOT := "res://assets/audio/ui"
const REWARD_ROOT := "res://assets/audio/reward"
const MUSIC_ROOT := "res://assets/audio/music"
const FOLEY_ROOT := "res://assets/audio/foley"
const VOICE_ROOT := "res://assets/audio/voices"
# D-57: voiced dialogue lines <root>/<lang>/<job_id>.line.<N>.ogg (tools/voice_lines.py)
const LINES_ROOT := "res://assets/audio/lines"
const VOICE_BUS := &"Voice"
const VOICE_DUCK_DB := -6.0  # D-57: music under a voiced line, never lower than -6 dB
# speaker id -> voice folder (S03 delivered one folder for the Ola/Krystyna pair)
const VOICE_DIR := {&"ola": &"ola_krystyna", &"krystyna": &"ola_krystyna"}
# S03 cast files use farewell/impatience/laughter/sadness, S03v2 goodbye/impatient/laugh/sad
const VOICE_KIND_ALIAS := {
	&"farewell": &"goodbye", &"goodbye": &"farewell",
	&"impatience": &"impatient", &"impatient": &"impatience",
	&"laughter": &"laugh", &"laugh": &"laughter",
	&"sadness": &"sad", &"sad": &"sadness",
}
const AMBIENCES := [&"stairwell", &"workshop", &"night_timer", &"rain_window"]

var _pool: Array[AudioStreamPlayer] = []
var _free: Array[AudioStreamPlayer] = []
var _cache: Dictionary = {}  # "event/material/n" -> AudioStream
var _loops: Dictionary = {}  # loop id -> {player, generator, playback, active}
var _rng := RandomNumberGenerator.new()
var _native_click: Object = null
var _pending_bridge: Object = null  # attached once the lock clicks are loaded (_process)
var _pending_bridge_name := ""
var _warm: Dictionary = {}  # "event/material/n" -> path still loading on a worker thread
const WARM_BUDGET_US := 4000  # main-thread time per frame for collecting finished loads
## Native click bridge state (N-70 follow-up): sample ids the bridge accepted, consecutive
## play() failures, and whether the bridge is still trusted. Any failure path falls back
## to the AudioServer pool for that click; NATIVE_MAX_FAILS in a row disable the bridge.
const NATIVE_MAX_FAILS := 3
var _native_loaded: Dictionary = {}  # "event/material/n" -> true
var _native_fails := 0
var _native_enabled := false
var _native_plays := 0
var _engine_clicks := 0  # L2 lock clicks that went through AudioServer (no native slot / bridge off)
var _native_skipped := 0
## Tests: id -> AudioStreamWAV offered to the bridge instead of the shipped clicks.
var native_test_samples: Dictionary = {}
var _ambience: AudioStreamPlayer = null
var _ambience_name: StringName = &""
var _ambience_base_db := 0.0
var _duck_tween: Tween = null
var _music: AudioStreamPlayer = null
var _music_name: StringName = &""
var _voice_duck_tween: Tween = null
var _busy: Array[AudioStreamPlayer] = []  # pool players in use, oldest first (voice stealing)


func _ready() -> void:
	_rng.randomize()
	for name in ["LockwrightClickAudio", "LockwrightLowLatencyAudio"]:
		if Engine.has_singleton(name):
			_pending_bridge = Engine.get_singleton(name)
			_pending_bridge_name = name
			break
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = "Sfx"
		add_child(p)
		_pool.append(p)
		_free.append(p)
	_preload_lock()  # L2 lock events + loops only: cold start must not wait for music/voices (GEM3 BUG-06)
	_preload_lazy_threaded()


## Perf pass 2026-11-08: the ~380 lock clicks and the native bridge upload took ~340 ms of the cold
## start on a budget phone (SM-A165F), before the menu could show. They now load on worker threads;
## _process() collects them a few per frame and attaches the native bridge (N-03) once all are in.
## A click asked for before that loads on the spot (_cached), so no sound is ever dropped.
func _preload_lock() -> void:
	for event in EVENTS + LOOPS:
		for material in MATERIALS:
			for n in range(1, VARIANTS + 1):
				var path := "%s/%s/%s_%d.wav" % [SFX_ROOT, event, material, n]
				if ResourceLoader.exists(path):
					var key := "%s/%s/%d" % [event, material, n]
					_warm[key] = path
					ResourceLoader.load_threaded_request(path)
	set_process(true)


func _process(_delta: float) -> void:
	var t0 := Time.get_ticks_usec()
	for key in _warm.keys():
		var path: String = _warm[key]
		var st := ResourceLoader.load_threaded_get_status(path)
		if st == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			continue
		_warm.erase(key)
		if not _cache.has(key):
			_cache[key] = ResourceLoader.load_threaded_get(path) if st == ResourceLoader.THREAD_LOAD_LOADED else load(path)
		if Time.get_ticks_usec() - t0 > WARM_BUDGET_US:
			return
	if _warm.is_empty():
		set_process(false)
		if _pending_bridge != null:
			var bridge := _pending_bridge
			_pending_bridge = null
			use_native_click(bridge, _pending_bridge_name)


## True while lock clicks are still loading in the background (tests wait on it).
func warming_up() -> bool:
	return not _warm.is_empty() or _pending_bridge != null


## A lock sample by "event/material/n": from the cache, or loaded now if its background load has
## not been collected yet (load() waits for a load already in flight).
func _cached(key: String) -> AudioStream:
	if _cache.has(key):
		return _cache[key]
	if _warm.has(key):
		var path: String = _warm[key]
		_warm.erase(key)
		_cache[key] = load(path)
		return _cache[key]
	return null


# ambience/music/ui/reward/foley/voices warm up off the critical path; the getters
# fall back to a synchronous load on first use so a sound never silently drops
func _preload_lazy_threaded() -> void:
	for amb in AMBIENCES:
		var apath := "%s/%s.wav" % [AMBIENCE_ROOT, amb]
		if ResourceLoader.exists(apath):
			ResourceLoader.load_threaded_request(apath)
	for dir in [UI_ROOT, REWARD_ROOT, MUSIC_ROOT, FOLEY_ROOT]:
		for f in _audio_files(dir):
			ResourceLoader.load_threaded_request(dir + "/" + f)
	for spk in DirAccess.get_directories_at(VOICE_ROOT):
		for f in _audio_files(VOICE_ROOT + "/" + spk):
			if f.ends_with(".wav"):  # 12 cast folders only; episodic .ogg load per speaker
				ResourceLoader.load_threaded_request(VOICE_ROOT + "/" + spk + "/" + f)


# .wav/.ogg resources in a folder. ResourceLoader.list_directory (not DirAccess) so an
# exported pck, which lists only <file>.import/.remap, still yields the source names.
func _audio_files(dir: String) -> PackedStringArray:
	var out := PackedStringArray()
	for f in ResourceLoader.list_directory(dir):
		if f.ends_with(".wav") or f.ends_with(".ogg"):
			out.append(f)
	return out


var _lazy_done := {}


func _lazy_load(path: String, key: String) -> void:
	if _cache.has(key):
		return
	if ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_LOADED:
		_cache[key] = ResourceLoader.load_threaded_get(path)
	else:
		_cache[key] = load(path)


func _ensure_ambience() -> void:
	if _lazy_done.has("amb"):
		return
	_lazy_done["amb"] = true
	for amb in AMBIENCES:
		var apath := "%s/%s.wav" % [AMBIENCE_ROOT, amb]
		if ResourceLoader.exists(apath):
			_lazy_load(apath, "amb/%s" % amb)


func _ensure_dir(root: String) -> void:
	if _lazy_done.has(root):
		return
	_lazy_done[root] = true
	for f in _audio_files(root):
		var key := "mus/%s" % f.get_basename() if root == MUSIC_ROOT else "%s/%s" % [root, f]
		_lazy_load(root + "/" + f, key)


# per speaker folder, on first use: 12 cast (.wav, prefetched) + 39 episodic S03v2 (.ogg)
func _ensure_voices(folder: String) -> void:
	var tag := VOICE_ROOT + "/" + folder
	if _lazy_done.has(tag):
		return
	_lazy_done[tag] = true
	for f in _audio_files(tag):
		_lazy_load(tag + "/" + f, "%s/%s" % [tag, f])


## Attaches a native click bridge (Android JNISingleton, iOS object, test fake); null detaches.
## Uses it only if it exposes play + load_sample and accepted at least one sample.
func use_native_click(bridge: Object, name: String = "") -> void:
	_native_click = bridge
	_native_loaded.clear()
	_native_fails = 0
	_native_plays = 0
	_native_skipped = 0
	_native_enabled = false
	if bridge == null:
		return
	var can_play := native_click_has(&"play")
	var can_load := native_click_has(&"load_sample")
	var total := 0
	var t0 := Time.get_ticks_msec()
	if can_play and can_load:
		total = _preload_native()
	_native_enabled = can_play and can_load and not _native_loaded.is_empty()
	print("Sfx: native click bridge %s play=%s load_sample=%s samples=%d/%d (skipped non-PCM16/stereo %d) -> %s in %d ms" % [
		name, can_play, can_load, _native_loaded.size(), total, _native_skipped,
		"native" if _native_enabled else "AudioServer fallback", Time.get_ticks_msec() - t0])
	if _native_enabled and native_click_has(&"stats"):
		var st: Variant = bridge.call(&"stats")
		if st is Dictionary and st.has("samplesLoaded"):
			print("Sfx: bridge holds %d samples, %.1f MB PCM16" % [int(st["samplesLoaded"]), int(st["sampleBytes"]) / 1048576.0])


## D-101: how many L2 lock clicks took each path since start (PerfProbe, device tests).
func click_path_counts() -> Dictionary:
	return {"native": _native_plays, "engine": _engine_clicks}


## D-101: the native bridge's own statistics (Oboe latency, xruns, call-to-mix), {} without a bridge.
func native_stats() -> Dictionary:
	if _native_click == null or not native_click_has(&"stats"):
		return {}
	var st: Variant = _native_click.call(&"stats")
	return st if st is Dictionary else {}


## Same JNISingleton rule as Haptics.native_has(): Android plugin methods are visible only
## through has_java_method(); has_method() is false for them.
func native_click_has(method: StringName) -> bool:
	if _native_click == null:
		return false
	if _native_click.has_method(&"has_java_method"):
		return bool(_native_click.call(&"has_java_method", method))
	return _native_click.has_method(method)


func native_click_active() -> bool:
	return _native_enabled


## Tries the native bridge; false = caller plays the click through AudioServer.
func _play_native(id: String, gain: float, pitch: float) -> bool:
	if not _native_enabled or not _native_loaded.has(id):
		return false
	var ok := bool(_native_click.call(&"play", id, gain, pitch))
	if ok:
		_native_fails = 0
		_native_plays += 1
		if _native_plays == 1:
			print("Sfx: first native click played (%s)" % id)
		return true
	_native_fails += 1
	if _native_fails >= NATIVE_MAX_FAILS:
		_native_enabled = false
		push_warning("Sfx: native click bridge failed %d times in a row, using AudioServer" % _native_fails)
		print("Sfx: native click bridge disabled after %d failures (played %d)" % [_native_fails, _native_plays])
	return false


func _preload_native() -> int:
	# N-03: preload decoded PCM of all L2 events into the native bridge (16-bit mono);
	# returns how many samples were offered, _native_loaded holds the accepted ones.
	# The bridge takes 16-bit mono PCM only; the lock clicks are imported that way
	# (compress/mode=0, force/mono). QOA or stereo samples are skipped and stay on AudioServer.
	var total := 0
	_native_skipped = 0
	var candidates := native_test_samples if not native_test_samples.is_empty() else _native_candidates()
	for id in candidates:
		var wav: AudioStreamWAV = candidates[id]
		if wav == null or wav.format != AudioStreamWAV.FORMAT_16_BITS or wav.stereo:
			_native_skipped += 1
			continue
		total += 1
		if bool(_native_click.call(&"load_sample", id, wav.data, wav.mix_rate)):
			_native_loaded[id] = true
	return total


func _native_candidates() -> Dictionary:
	var out := {}
	for event in EVENTS:
		for material in MATERIALS:
			for n in range(1, VARIANTS + 1):
				var path := "%s/%s/%s_%d.wav" % [SFX_ROOT, event, material, n]
				if ResourceLoader.exists(path):
					out["%s/%s/%d" % [event, material, n]] = load(path) as AudioStreamWAV
	return out


func _stream_for(event: StringName, material: StringName) -> AudioStream:
	var n := _rng.randi_range(1, VARIANTS)
	var key := "%s/%s/%d" % [event, material, n]
	var s := _cached(key)
	if s != null:
		return s
	return _cached("%s/%s/1" % [event, material])


func play(event: StringName, material: StringName = &"brass", volume_db: float = 0.0, pitch: float = 1.0) -> void:
	# audio/v2 mix (README "Miks"): every L2 lock event ducks the ambience -6 dB / 50 ms,
	# `break` ducks everything else -12 dB / 300 ms (FEEL §5.1)
	if event in [&"break"]:
		duck_ambience(-12.0, 300.0)
	elif not LOOPS.has(event):
		duck_ambience(-6.0, 50.0)
	# R-20: L2 clicks prefer the native low-latency bridge (Oboe/AAudio, AVAudioEngine);
	# AudioServer pool is the fallback (and the only path on desktop/editor).
	if _native_enabled:
		var n := _rng.randi_range(1, VARIANTS)
		var gain := db_to_linear(volume_db) * float(Settings.get_value("volume_sfx")) * float(Settings.get_value("volume_master"))
		if _play_native("%s/%s/%d" % [event, material, n], gain, pitch):
			return
	var stream := _stream_for(event, material)
	if stream == null:
		return
	if not LOOPS.has(event):
		_engine_clicks += 1
	var p := _take_player()
	if p == null:
		return
	p.stream = stream
	p.bus = "Sfx"
	p.volume_db = volume_db + linear_to_db(Settings.get_value("volume_sfx") * Settings.get_value("volume_master"))
	p.pitch_scale = pitch * _rng.randf_range(0.97, 1.03)
	p.play()
	p.finished.connect(_on_player_finished.bind(p), CONNECT_ONE_SHOT)  # R-26


func _on_player_finished(p: AudioStreamPlayer) -> void:
	p.stream = null
	_busy.erase(p)
	if not _free.has(p):
		_free.append(p)


# A free pool player, or the oldest busy one (stopped and reused) so a new sound is never
# silently dropped when long one-shots (jingles, foley) still hold the whole pool.
func _take_player() -> AudioStreamPlayer:
	var p: AudioStreamPlayer
	if not _free.is_empty():
		p = _free.pop_back()
	elif not _busy.is_empty():
		p = _busy.pop_front()
		p.stop()
		for c in p.finished.get_connections():
			p.finished.disconnect(c["callable"])
	else:
		return null
	_busy.append(p)
	return p


## Stops every pool one-shot and returns the players to the free list (scene change, tests).
func stop_all_one_shots() -> void:
	for p in _busy.duplicate():
		p.stop()
		for c in p.finished.get_connections():
			p.finished.disconnect(c["callable"])
		_on_player_finished(p)


func begin_loop(id: StringName, material: StringName = &"brass") -> void:
	if _loops.has(id):
		return
	var player := AudioStreamPlayer.new()
	var stream := _stream_for(id, material)
	if stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	player.stream = stream
	player.bus = "Sfx"
	player.volume_db = -80.0
	add_child(player)
	_loops[id] = {"player": player, "material": material, "level": 0.0}
	player.play()


func update_loop(id: StringName, level: float) -> void:
	if not _loops.has(id):
		return
	_loops[id]["level"] = clampf(level, 0.0, 1.0)
	var p: AudioStreamPlayer = _loops[id]["player"]
	# L1 continuous layer: audible only while there is resistance/drag (TECH §3.3)
	p.volume_db = linear_to_db(Settings.get_value("volume_sfx") * Settings.get_value("volume_master")) + (linear_to_db(maxf(level, 0.001)) * 0.7 - 24.0)
	p.pitch_scale = 0.9 + 0.3 * level


func end_loop(id: StringName) -> void:
	if not _loops.has(id):
		return
	var entry: Dictionary = _loops[id]
	entry["player"].stop()
	entry["player"].queue_free()
	_loops.erase(id)


func set_loop_material(id: StringName, material: StringName) -> void:
	if _loops.has(id):
		_loops[id]["material"] = material


func _one_shot_from(root: String, file_key: String, volume_db: float) -> void:
	# UI/reward one-shots: random variant among the shipped files (audio/v2 part 2)
	_ensure_dir(root)
	var keys: Array = []
	for k in _cache.keys():
		if k.begins_with(root + "/"):
			keys.append(k)
	var pool := keys.filter(func(k): return k.trim_prefix(root + "/").begins_with(file_key))
	if pool.is_empty():
		return
	var stream: AudioStream = _cache[pool[_rng.randi_range(0, pool.size() - 1)]]
	var p := _take_player()
	if p == null:
		return
	p.stream = stream
	p.bus = "Sfx"
	p.volume_db = volume_db + linear_to_db(Settings.get_value("volume_sfx") * Settings.get_value("volume_master"))
	p.play()
	p.finished.connect(_on_player_finished.bind(p), CONNECT_ONE_SHOT)


func play_ui(event: StringName, volume_db: float = 0.0) -> void:
	_one_shot_from(UI_ROOT, String(event) + "_", volume_db)


func play_reward(event: StringName, volume_db: float = 0.0) -> void:
	_one_shot_from(REWARD_ROOT, String(event) + "_", volume_db)


func play_music(name: StringName, volume_db: float = -6.0) -> void:
	# S01 music (ChatGPT, D-43): pre-mixed ~-16 LUFS I, so the Music bus sits quiet;
	# in the lock the low-pass (2-6 kHz slowed, audio/v2 README mix) + ducking applies
	if _music_name == name and _music != null and _music.playing:
		return
	stop_music()
	_ensure_dir(MUSIC_ROOT)
	if not _cache.has("mus/%s" % name):
		return
	_music_name = name
	_music = AudioStreamPlayer.new()
	var stream: AudioStream = _cache["mus/%s" % name]
	if stream is AudioStreamOggVorbis:
		stream.loop = true
	_music.stream = stream
	_music.bus = "Music"
	_music.volume_db = volume_db + linear_to_db(maxf(Settings.get_value("volume_music", 0.8) * Settings.get_value("volume_master"), 0.001))
	add_child(_music)
	_music.play()


func stop_music() -> void:
	if _music != null:
		_music.stop()
		_music.queue_free()
		_music = null
	_music_name = &""
	set_music_lowpass(false)


func set_music_lowpass(enabled: bool) -> void:
	# "cicha wersja w zamku": tłumienie 2-6 kHz na magistrali Music
	var idx := AudioServer.get_bus_index("Music")
	if idx < 0:
		return
	if enabled and AudioServer.get_bus_effect_count(idx) > 0:
		AudioServer.set_bus_effect_enabled(idx, 0, true)
	elif not enabled and AudioServer.get_bus_effect_count(idx) > 0:
		AudioServer.set_bus_effect_enabled(idx, 0, false)


func play_foley(event: StringName, volume_db: float = 0.0) -> void:
	_one_shot_from(FOLEY_ROOT, String(event) + "_", volume_db)


func voice_keys(speaker: StringName, kind: StringName) -> Array:
	# S03 cast (12, .wav) and S03v2 episodic (39, .ogg) voices, all ~-28 LUFS M:
	# <root>/<speaker>/<kind>.(wav|ogg) or <kind>_NN.*; the two batches name four emotions
	# differently (VOICE_KIND_ALIAS); a missing emotion falls back to greeting
	var folder := String(VOICE_DIR.get(speaker, speaker))
	_ensure_voices(folder)
	var dir := VOICE_ROOT + "/" + folder + "/"
	for k in [kind, VOICE_KIND_ALIAS.get(kind, kind), &"greeting"]:
		var base := dir + String(k)
		var keys: Array = []
		for key in _cache.keys():
			if key == base + ".wav" or key == base + ".ogg" or key.begins_with(base + "_"):
				keys.append(key)
		if not keys.is_empty():
			return keys
	return []


func play_voice(speaker: StringName, kind: StringName, volume_db: float = 0.0) -> void:
	# S03 wordless vocalizations (reactions) are character voices: Voice bus + "Voices" slider
	var keys := voice_keys(speaker, kind)
	if keys.is_empty():
		return
	var p := _take_player()
	if p == null:
		return
	p.stream = _cache[keys[_rng.randi_range(0, keys.size() - 1)]]
	p.bus = voice_bus()
	p.volume_db = volume_db + voice_volume_db()
	p.play()
	p.finished.connect(_on_player_finished.bind(p), CONNECT_ONE_SHOT)


func play_jingle(name: StringName, volume_db: float = -4.0) -> void:
	# S01 one-shot jingles on the Music bus
	if not _cache.has("mus/%s" % name):
		return
	var p := _take_player()
	if p == null:
		return
	p.stream = _cache["mus/%s" % name]
	p.bus = "Music"
	p.volume_db = volume_db + linear_to_db(maxf(Settings.get_value("volume_music", 0.8) * Settings.get_value("volume_master"), 0.001))
	p.play()
	p.finished.connect(_on_player_finished.bind(p), CONNECT_ONE_SHOT)


func play_ambience(name: StringName) -> void:
	# Ambience loops are pre-mixed to -35 LUFS I (audio/v2 README); play at 0 dB with the
	# ambience slider on the Ambience bus (never ducked below -6/-12 dB transiently only)
	if _ambience_name == name and _ambience != null and _ambience.playing:
		return
	stop_ambience()
	_ensure_ambience()
	if not _cache.has("amb/%s" % name):
		return
	_ambience_name = name
	_ambience = AudioStreamPlayer.new()
	var stream: AudioStream = _cache["amb/%s" % name]
	if stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	_ambience.stream = stream
	_ambience.bus = "Ambience"
	_ambience_base_db = linear_to_db(maxf(Settings.get_value("volume_ambience", 0.8) * Settings.get_value("volume_master"), 0.001))
	_ambience.volume_db = _ambience_base_db
	add_child(_ambience)
	_ambience.play()


func stop_ambience() -> void:
	if _duck_tween != null:
		_duck_tween.kill()
		_duck_tween = null
	if _ambience != null:
		_ambience.stop()
		_ambience.queue_free()
		_ambience = null
	_ambience_name = &""


func duck_ambience(db: float, ms: float) -> void:
	if _ambience == null or not _ambience.playing:
		return
	if _duck_tween != null:
		_duck_tween.kill()
	_duck_tween = create_tween()
	_duck_tween.tween_property(_ambience, "volume_db", _ambience_base_db + db, ms / 1000.0)
	_duck_tween.tween_property(_ambience, "volume_db", _ambience_base_db, 0.05)


# --- D-57 voiced dialogue lines -------------------------------------------------------

## Bus for voices: "Voice" (default_bus_layout.tres), "Sfx" if a layout lacks it.
func voice_bus() -> StringName:
	return VOICE_BUS if AudioServer.get_bus_index(VOICE_BUS) >= 0 else &"Sfx"


func voice_volume_db() -> float:
	return linear_to_db(maxf(float(Settings.get_value("volume_voice", 1.0)) * float(Settings.get_value("volume_master")), 0.001))


## res:// path of a voiced line in exactly this language, or "" (no fallback to another
## language: a missing clip means subtitle-only, never a mismatched voice).
func line_clip_path(key: String, lang: String, root: String = LINES_ROOT) -> String:
	if key == "" or lang == "":
		return ""
	# D-100: a removed / not installed voice pack stays silent even while its files resolve
	if root == LINES_ROOT and get_node_or_null("/root/VoicePacks") != null and VoicePacks.blocks(lang):
		return ""
	var path := "%s/%s/%s.ogg" % [root, lang, key]
	return path if ResourceLoader.exists(path) else ""


## Music under a voiced line: Music bus -6 dB (120 ms), back to 0 dB (250 ms).
func duck_music_for_voice(on: bool) -> void:
	var idx := AudioServer.get_bus_index("Music")
	if idx < 0:
		return
	if _voice_duck_tween != null:
		_voice_duck_tween.kill()
	var from := AudioServer.get_bus_volume_db(idx)
	var to := VOICE_DUCK_DB if on else 0.0
	_voice_duck_tween = create_tween()
	_voice_duck_tween.tween_method(func(db: float) -> void: AudioServer.set_bus_volume_db(idx, db),
		from, to, 0.12 if on else 0.25)
