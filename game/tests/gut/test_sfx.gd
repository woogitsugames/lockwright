extends GutTest

const EVENTS := ["contact", "bind", "near_shear", "set", "false_set", "counter_rotate", "overset",
	"drop", "stress", "break", "wear", "gate_align", "detector_trip", "open"]
const LOOPS := ["tension_resistance", "pick_drag"]
const MATERIALS := ["brass", "steel", "iron", "wood"]

func test_every_event_has_4_materials() -> void:
	for e in EVENTS + LOOPS:
		for m in MATERIALS:
			var nv := 4 if e in LOOPS else 6
			for n in range(1, nv + 1):
				var path := "res://assets/audio/sfx/%s/%s_%d.wav" % [e, m, n]
				assert_true(ResourceLoader.exists(path), "missing sample: %s" % path)

func test_play_does_not_crash_headless() -> void:
	Sfx.play(&"set", &"brass")
	Sfx.play(&"break", &"steel")
	Sfx.begin_loop(&"tension_resistance", &"brass")
	Sfx.update_loop(&"tension_resistance", 0.5)
	Sfx.end_loop(&"tension_resistance")
	assert_true(true)

func test_play_voice_finds_plain_file_and_shared_folder() -> void:
	# N-48: <root>/<speaker>/<kind>.wav (not only <kind>_NN.wav), ola/krystyna -> ola_krystyna
	# earlier suites leave long one-shots (jingles, foley) in the pool: start from a free pool
	Sfx.stop_all_one_shots()
	var before: int = Sfx._free.size()
	Sfx.play_voice(&"halina", &"greeting")
	assert_eq(Sfx._free.size(), before - 1, "halina/greeting.wav must occupy a player from the pool")
	Sfx.play_voice(&"ola", &"greeting")
	assert_eq(Sfx._free.size(), before - 2, "ola must resolve to the shared ola_krystyna folder")


# ------------------------------------------------- native click bridge (N-70 follow-up)

## Like Godot's JNISingleton: methods only visible through has_java_method().
class FakeClickBridge extends RefCounted:
	var java_methods: Array = ["play", "load_sample"]
	var accept_load := true
	var play_ok := true
	var loaded: Array = []
	var plays: Array = []

	func has_java_method(m: StringName) -> bool:
		return java_methods.has(String(m))

	func load_sample(id: String, _pcm: PackedByteArray, _rate: int) -> bool:
		if accept_load:
			loaded.append(id)
		return accept_load

	func play(id: String, gain: float, pitch: float) -> bool:
		plays.append([id, gain, pitch])
		return play_ok


func _pcm16(frames: int = 480) -> AudioStreamWAV:
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = 48000
	w.stereo = false
	var d := PackedByteArray()
	d.resize(frames * 2)
	w.data = d
	return w


func _with_samples() -> void:
	var samples := {}
	for n in range(1, Sfx.VARIANTS + 1):
		samples["set/brass/%d" % n] = _pcm16()
	samples["set/brass/qoa"] = AudioStreamWAV.new()  # FORMAT_8_BITS default: skipped
	samples["set/brass/qoa"].format = AudioStreamWAV.FORMAT_QOA
	Sfx.native_test_samples = samples


func after_each() -> void:
	Sfx.native_test_samples = {}
	Sfx.use_native_click(null)


func _busy_count() -> int:
	return Sfx._busy.size()


func test_native_click_bridge_used_via_has_java_method() -> void:
	_with_samples()
	var f := FakeClickBridge.new()
	Sfx.use_native_click(f, "fake")
	assert_eq(f.loaded.size(), Sfx.VARIANTS, "only 16-bit mono samples offered (QOA skipped)")
	assert_true(Sfx.native_click_active(), "bridge with has_java_method play/load_sample is used")
	var before := _busy_count()
	for i in 12:
		Sfx.play(&"set", &"brass")
	assert_gt(f.plays.size(), 0, "native play called")
	assert_true(Sfx.native_click_active())
	Sfx.use_native_click(null)
	assert_true(before >= 0)


func test_native_click_falls_back_and_disables_on_failure() -> void:
	_with_samples()
	var f := FakeClickBridge.new()
	f.play_ok = false
	Sfx.use_native_click(f, "fake")
	assert_true(Sfx.native_click_active())
	var before := _busy_count()
	Sfx.play(&"set", &"brass")
	assert_eq(f.plays.size(), 1, "native tried first")
	assert_eq(_busy_count(), before + 1, "failed native click is played through AudioServer")
	for i in 30:
		Sfx.play(&"set", &"brass")
	assert_false(Sfx.native_click_active(), "repeated play() failures disable the bridge")
	assert_lte(f.plays.size(), Sfx.NATIVE_MAX_FAILS, "no more native attempts after disabling")
	assert_gt(_busy_count() + Sfx._free.size(), 0, "AudioServer pool still serves the clicks")
	assert_true(before >= 0)
	Sfx.use_native_click(null)


func test_native_click_without_samples_or_methods_is_not_used() -> void:
	_with_samples()
	var f := FakeClickBridge.new()
	f.accept_load = false
	Sfx.use_native_click(f, "fake")
	assert_false(Sfx.native_click_active(), "no accepted samples -> AudioServer")
	var g := FakeClickBridge.new()
	g.java_methods = []
	Sfx.use_native_click(g, "fake")
	assert_false(Sfx.native_click_active(), "no java methods -> AudioServer")
	assert_eq(g.loaded.size(), 0)
	Sfx.use_native_click(null)
