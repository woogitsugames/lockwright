extends GutTest

const ALL_EVENTS := ["contact", "bind", "near_shear", "set", "false_set", "counter_rotate", "overset",
	"drop", "stress", "break", "wear", "gate_align", "detector_trip", "open"]

func test_every_event_has_pattern() -> void:
	for e in ALL_EVENTS:
		var p: Dictionary = Haptics.pattern_for(e)
		assert_false(p.is_empty(), "missing pattern: %s" % e)
		assert_true(p.has("ios") and p.has("android") and p.has("fallback"), "incomplete pattern: %s" % e)
		assert_true(p.has("priority"), "no priority: %s" % e)

func test_continuous_signals_have_patterns() -> void:
	for c in ["tension_resistance", "pick_drag"]:
		assert_false(Haptics.continuous_pattern_for(c).is_empty(), "missing continuous: %s" % c)

func test_material_modifiers() -> void:
	for m in ["brass", "steel", "iron", "wood"]:
		var mod: Dictionary = Haptics.material_modifier(m)
		assert_true(mod.has("delta_sharpness") and mod.has("intensity_scale"), "bad modifier: %s" % m)

func test_disabled_haptics_plays_nothing() -> void:
	Settings.set_value("haptics_enabled", false)
	Haptics.play(&"set", 1.0, &"brass")  # must not crash nor vibrate
	Settings.set_value("haptics_enabled", true)
	assert_true(true)

func test_capabilities_dict() -> void:
	var caps: Dictionary = Haptics.capabilities()
	assert_true(caps.has("tier"))


# ---------------------------------------------------------------- N-70: facade decision logic

## Behaves like Godot's JNISingleton for an Android plugin: its Java methods are only
## visible through has_java_method() (the real one answers has_method() with false).
class FakeJniSingleton extends RefCounted:
	var java_methods: Array = []
	var calls: Array = []
	var caps_json := "{\"tier\":\"ON_OFF\",\"primitives\":[],\"amplitude_control\":false,\"envelope\":false,\"native\":true}"

	func has_java_method(m: StringName) -> bool:
		return java_methods.has(String(m))

	func play(event: String, intensity: float, material: String) -> void:
		calls.append(["play", event, intensity, material])

	func test_pulse(ms: int, level: float) -> void:
		calls.append(["test_pulse", ms, level])

	func capabilities() -> String:
		return caps_json

	func begin_continuous(id: String) -> void:
		calls.append(["begin_continuous", id])

	func end_continuous(id: String) -> void:
		calls.append(["end_continuous", id])


var _vibrations: Array = []
var _settings_backup: Dictionary


func before_each() -> void:
	_vibrations = []
	_settings_backup = {"haptics_enabled": Settings.get_value("haptics_enabled"),
		"haptics_intensity": Settings.get_value("haptics_intensity")}
	Settings.set_value("haptics_enabled", true)
	Settings.set_value("haptics_intensity", 1.0)
	Haptics.vibrate_override = func(ms: int, amp: float) -> void: _vibrations.append([ms, amp])
	Haptics._last_fallback_ms = -100000


func after_each() -> void:
	Haptics.vibrate_override = Callable()
	Haptics.use_native(null)
	for k in _settings_backup:
		Settings.set_value(k, _settings_backup[k])


func _fake(methods: Array) -> FakeJniSingleton:
	var f := FakeJniSingleton.new()
	f.java_methods = methods
	return f


func test_android_singleton_methods_found_via_has_java_method() -> void:
	var f := _fake(["play", "capabilities", "test_pulse", "begin_continuous", "update_continuous", "end_continuous"])
	Haptics.use_native(f)
	assert_true(Haptics.is_native(), "plugin methods come from has_java_method()")
	var caps := Haptics.capabilities()
	assert_eq(caps.get("native"), true, "Kotlin JSON capabilities parsed")
	assert_eq(caps.get("tier"), "ON_OFF")
	Haptics.play(&"set", 1.0, &"brass")
	assert_eq(f.calls.size(), 1, "native play used")
	assert_eq(f.calls[0][0], "play")
	assert_eq(f.calls[0][1], "set")
	assert_eq(_vibrations.size(), 0, "no fallback vibration when the plugin plays")


func test_has_java_method_wins_over_has_method() -> void:
	# the fake defines play()/capabilities() as script methods, but the Java side lists none
	var f := _fake([])
	Haptics.use_native(f)
	assert_false(Haptics.is_native())
	assert_eq(Haptics.capabilities().get("native"), false)
	Haptics.play(&"set", 1.0, &"brass")
	assert_eq(f.calls.size(), 0, "plugin without play() is not called")
	assert_eq(_vibrations.size(), 1, "fallback vibrates instead")


func test_fallback_pulses_are_perceptible_on_erm() -> void:
	for e in ["set", "false_set", "overset", "drop", "break", "open", "detector_trip", "gate_align", "counter_rotate"]:
		var ms := Haptics.fallback_pulse_ms(Haptics.pattern_for(e), 1.0)
		assert_gte(ms, Haptics.ERM_MIN_MS, "%s: >= %d ms on an on/off motor" % [e, Haptics.ERM_MIN_MS])
		assert_lte(ms, Haptics.ERM_MAX_MS, "%s: bounded" % e)
		assert_gte(Haptics.fallback_pulse_ms(Haptics.pattern_for(e), 0.1), Haptics.ERM_MIN_MS, "%s: low intensity keeps the floor" % e)
	for e in ["contact", "bind", "near_shear", "stress", "wear"]:
		assert_eq(Haptics.fallback_pulse_ms(Haptics.pattern_for(e), 1.0), 0, "%s: no buzz on an on/off motor" % e)
	assert_eq(Haptics.fallback_pulse_ms(Haptics.pattern_for("set"), 0.0), 0, "zero intensity = no pulse")


func test_fallback_play_uses_floor_and_gap() -> void:
	Haptics.play(&"set", 1.0, &"brass")
	Haptics.play(&"set", 1.0, &"brass")  # same frame: would blur into one pulse on an ERM
	assert_eq(_vibrations.size(), 1, "pulses closer than FALLBACK_MIN_GAP_MS are dropped")
	assert_gte(int(_vibrations[0][0]), Haptics.ERM_MIN_MS)
	Haptics.play(&"contact", 1.0, &"brass")
	assert_eq(_vibrations.size(), 1, "contact has no on/off pulse")


func test_test_pulse_native_and_fallback() -> void:
	Haptics.test_pulse()
	assert_eq(_vibrations.size(), 1, "fallback test pulse")
	assert_gte(int(_vibrations[0][0]), 200, "test pulse >= 200 ms")
	assert_eq(float(_vibrations[0][1]), -1.0, "100 % = system default amplitude")
	var f := _fake(["play", "capabilities", "test_pulse"])
	Haptics.use_native(f)
	Haptics.test_pulse()
	assert_eq(f.calls.back()[0], "test_pulse", "native test pulse")
	assert_gte(int(f.calls.back()[1]), 200)
	assert_eq(_vibrations.size(), 1, "no extra fallback vibration")
	Settings.set_value("haptics_enabled", false)
	Haptics.test_pulse()
	assert_eq(f.calls.size(), 1, "disabled haptics: no test pulse")


## N-79 / D-80: the Android engine (platform/android/.../HapticsEngine.kt, built into the AAR by CI)
## builds every raw pulse in exactly two helpers that enforce the 30 ms floor (D-65) and, without
## amplitude control, use the on/off policy instead of an amplitude the motor ignores.
const ENGINE_KT := "../platform/android/lockwright-haptics/src/main/java/org/woogitsugames/lockwright/haptics/HapticsEngine.kt"


func _engine_source() -> String:
	var path := ProjectSettings.globalize_path("res://").path_join(ENGINE_KT).simplify_path()
	return FileAccess.get_file_as_string(path) if FileAccess.file_exists(path) else ""


func test_android_engine_pulse_floor_is_central() -> void:
	var src := _engine_source()
	if src == "":
		pending("platform/android not checked out next to game/")
		return
	var floor_re := RegEx.create_from_string(r"MIN_PULSE_MS\s*=\s*(\d+)L")
	var m := floor_re.search(src)
	assert_not_null(m, "MIN_PULSE_MS constant")
	if m != null:
		assert_eq(int(m.get_string(1)), Haptics.ERM_MIN_MS, "Kotlin floor == Haptics.ERM_MIN_MS")
	var raw := RegEx.create_from_string(r"VibrationEffect\.create(Waveform|OneShot)\(")
	var lines := PackedStringArray()
	for line in src.split("\n"):
		if raw.search(line) != null and not line.strip_edges().begins_with("*"):
			lines.append(line)
	assert_eq(lines.size(), 2, "raw pulses are built only in amplitudePulse()/onOffPulse():\n" + "\n".join(lines))
	for line in lines:
		assert_true(line.contains("MIN_PULSE_MS"), "pulse helper clamps to MIN_PULSE_MS: " + line.strip_edges())
	assert_true(src.contains("coerceIn(MIN_AMP, 255)"), "amplitude-scaled pulses keep the MIN_AMP floor")
	assert_true(src.contains("if (!amplitudeControl) return oneShotFor(event, i)"),
		"waveforms on a motor without amplitude control fall back to the on/off policy")
	assert_true(src.contains("SDK_INT_FULL >= 370200 && envelopeSupported"),
		"BUILDER tier needs envelope support (API 36 MOTOR_COIN_DC reported BUILDER, N-79)")


func test_android_on_off_events_match_patterns() -> void:
	var src := _engine_source()
	if src == "":
		pending("platform/android not checked out next to game/")
		return
	var start := src.find("private fun oneShotFor(")
	assert_gt(start, 0, "oneShotFor() present")
	var block := src.substr(start, src.find("else -> return null", start) - start)
	var row := RegEx.create_from_string(r'((?:"[a-z_]+",?\s*)+)->\s*(\d+)f')
	var name_re := RegEx.create_from_string(r'"([a-z_]+)"')
	var kt := {}
	for m in row.search_all(block):
		for n in name_re.search_all(m.get_string(1)):
			kt[n.get_string(1)] = int(m.get_string(2))
	var gd := {}
	for e in Haptics.patterns.get("events", {}):
		if Haptics.fallback_pulse_ms(Haptics.pattern_for(e), 1.0) > 0:
			var fb: Dictionary = Haptics.pattern_for(e).get("fallback", {})
			gd[e] = int(fb.get("a0_ms", fb.get("ms", 0)))
	assert_eq_deep(kt, gd)
