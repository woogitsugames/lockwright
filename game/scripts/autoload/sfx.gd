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

var _pool: Array[AudioStreamPlayer] = []
var _free: Array[AudioStreamPlayer] = []
var _cache: Dictionary = {}  # "event/material/n" -> AudioStream
var _loops: Dictionary = {}  # loop id -> {player, generator, playback, active}
var _rng := RandomNumberGenerator.new()
var _native_click: Object = null


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
