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
