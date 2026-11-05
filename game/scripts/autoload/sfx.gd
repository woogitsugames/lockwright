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
const AMBIENCES := [&"stairwell", &"workshop", &"night_timer", &"rain_window"]

var _pool: Array[AudioStreamPlayer] = []
var _free: Array[AudioStreamPlayer] = []
var _cache: Dictionary = {}  # "event/material/n" -> AudioStream
var _loops: Dictionary = {}  # loop id -> {player, generator, playback, active}
var _rng := RandomNumberGenerator.new()
var _native_click: Object = null
var _ambience: AudioStreamPlayer = null
var _ambience_name: StringName = &""
var _ambience_base_db := 0.0
var _duck_tween: Tween = null
var _music: AudioStreamPlayer = null
var _music_name: StringName = &""


func _ready() -> void:
	_rng.randomize()
	for name in ["LockwrightClickAudio", "LockwrightLowLatencyAudio"]:
		if Engine.has_singleton(name):
			_native_click = Engine.get_singleton(name)
			print("Sfx: native click audio bridge detected: %s" % name)
			break
	if _native_click != null and _native_click.has_method("load_sample"):
		_preload_native()
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = "Sfx"
		add_child(p)
		_pool.append(p)
		_free.append(p)
	_preload_all()


func _preload_all() -> void:
	for event in EVENTS:
		for material in MATERIALS:
			for n in range(1, VARIANTS + 1):
				var path := "%s/%s/%s_%d.wav" % [SFX_ROOT, event, material, n]
				if ResourceLoader.exists(path):
					_cache["%s/%s/%d" % [event, material, n]] = load(path)
	for loop in LOOPS:
		for material in MATERIALS:
			for n in range(1, VARIANTS + 1):
				var path := "%s/%s/%s_%d.wav" % [SFX_ROOT, loop, material, n]
				if ResourceLoader.exists(path):
					_cache["%s/%s/%d" % [loop, material, n]] = load(path)
	for amb in AMBIENCES:
		var apath := "%s/%s.wav" % [AMBIENCE_ROOT, amb]
		if ResourceLoader.exists(apath):
			_cache["amb/%s" % amb] = load(apath)
	for dir in [UI_ROOT, REWARD_ROOT]:
		for f in DirAccess.get_files_at(dir):
			if f.ends_with(".wav"):
				_cache["%s/%s" % [dir, f]] = load(dir + "/" + f)
	for f in DirAccess.get_files_at(MUSIC_ROOT):
		if f.ends_with(".ogg"):
			_cache["mus/%s" % f.get_basename()] = load(MUSIC_ROOT + "/" + f)
	for f in DirAccess.get_files_at(FOLEY_ROOT):
		if f.ends_with(".wav"):
			_cache["%s/%s" % [FOLEY_ROOT, f]] = load(FOLEY_ROOT + "/" + f)
	for spk in DirAccess.get_directories_at(VOICE_ROOT):
		for f in DirAccess.get_files_at(VOICE_ROOT + "/" + spk):
			if f.ends_with(".wav"):
				_cache["%s/%s/%s" % [VOICE_ROOT, spk, f]] = load(VOICE_ROOT + "/" + spk + "/" + f)


func _preload_native() -> void:
	# N-03: preload decoded PCM of all L2 events into the native bridge (48 kHz 16-bit mono)
	for event in EVENTS:
		for material in MATERIALS:
			for n in range(1, VARIANTS + 1):
				var path := "%s/%s/%s_%d.wav" % [SFX_ROOT, event, material, n]
				if not ResourceLoader.exists(path):
					continue
				var wav := load(path) as AudioStreamWAV
				if wav == null or wav.format != AudioStreamWAV.FORMAT_16_BITS:
					continue
				var pcm := PackedByteArray()
				pcm.resize(wav.data.size())
				for i in wav.data.size():
					pcm[i] = wav.data[i]
				_native_click.load_sample("%s/%s/%d" % [event, material, n], pcm, 48000)


func _stream_for(event: StringName, material: StringName) -> AudioStream:
	var n := _rng.randi_range(1, VARIANTS)
	var key := "%s/%s/%d" % [event, material, n]
	if _cache.has(key):
		return _cache[key]
	key = "%s/%s/1" % [event, material]
	return _cache.get(key)


func play(event: StringName, material: StringName = &"brass", volume_db: float = 0.0, pitch: float = 1.0) -> void:
	# audio/v2 mix (README "Miks"): every L2 lock event ducks the ambience -6 dB / 50 ms,
	# `break` ducks everything else -12 dB / 300 ms (FEEL §5.1)
	if event in [&"break"]:
		duck_ambience(-12.0, 300.0)
	elif not LOOPS.has(event):
		duck_ambience(-6.0, 50.0)
	# R-20: L2 clicks prefer the native low-latency bridge (Oboe/AAudio, AVAudioEngine);
	# AudioServer pool is the fallback (and the only path on desktop/editor).
	if _native_click != null and _native_click.has_method("play"):
		var n := _rng.randi_range(1, VARIANTS)
		var gain := db_to_linear(volume_db)
		_native_click.play("%s/%s/%d" % [event, material, n], gain, pitch)
		return
	if _free.is_empty():
		return
	var stream := _stream_for(event, material)
	if stream == null:
		return
	var p: AudioStreamPlayer = _free.pop_back()
	p.stream = stream
	p.volume_db = volume_db + linear_to_db(Settings.get_value("volume_sfx") * Settings.get_value("volume_master"))
	p.pitch_scale = pitch * _rng.randf_range(0.97, 1.03)
	p.play()
	p.finished.connect(_on_player_finished.bind(p), CONNECT_ONE_SHOT)  # R-26


func _on_player_finished(p: AudioStreamPlayer) -> void:
	p.stream = null
	if not _free.has(p):
		_free.append(p)


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
	var keys: Array = []
	for k in _cache.keys():
		if k.begins_with(root + "/"):
			keys.append(k)
	var pool := keys.filter(func(k): return k.trim_prefix(root + "/").begins_with(file_key))
	if pool.is_empty():
		return
	if _free.is_empty():
		return
	var stream: AudioStream = _cache[pool[_rng.randi_range(0, pool.size() - 1)]]
	var p: AudioStreamPlayer = _free.pop_back()
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


func play_voice(speaker: StringName, kind: StringName, volume_db: float = 0.0) -> void:
	# S03 character voices (normalized to -28 LUFS M): <root>/<speaker>/<kind>_NN.wav
	var keys: Array = []
	for k in _cache.keys():
		if k.begins_with(VOICE_ROOT + "/" + String(speaker) + "/" + String(kind) + "_"):
			keys.append(k)
	if keys.is_empty() or _free.is_empty():
		return
	var p: AudioStreamPlayer = _free.pop_back()
	p.stream = _cache[keys[_rng.randi_range(0, keys.size() - 1)]]
	p.bus = "Sfx"
	p.volume_db = volume_db + linear_to_db(Settings.get_value("volume_sfx") * Settings.get_value("volume_master"))
	p.play()
	p.finished.connect(_on_player_finished.bind(p), CONNECT_ONE_SHOT)


func play_jingle(name: StringName, volume_db: float = -4.0) -> void:
	# S01 one-shot jingles on the Music bus
	if _free.is_empty() or not _cache.has("mus/%s" % name):
		return
	var p: AudioStreamPlayer = _free.pop_back()
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
