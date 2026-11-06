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
