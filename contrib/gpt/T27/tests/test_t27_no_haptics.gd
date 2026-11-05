extends "res://tests/gut/t27_fixture.gd"
## Non-haptic devices and opt-out: playable visuals and audio remain available.


## Checks generic fallback capabilities when no native bridge is installed.
func test_missing_native_bridge_reports_fallback() -> void:
	Haptics._native = null
	var caps: Dictionary = Haptics.capabilities()
	assert_eq(caps.get("tier"), "fallback")
	assert_false(caps.get("native", true))


## Checks every disabled event has zero effective vibration intensity.
func test_disabled_haptics_scales_to_zero() -> void:
	Settings.set_value("haptics_enabled", false)
	for event in [&"contact", &"set", &"break", &"open"]:
		assert_eq(Haptics._scaled_intensity(event, 1.0, &"steel"), 0.0)


## Checks that discrete feedback calls are harmless with haptics disabled.
func test_disabled_discrete_feedback_does_not_crash() -> void:
	Settings.set_value("haptics_enabled", false)
	Haptics.play(&"set", 1.0, &"brass")
	Haptics.play(&"break", 1.0, &"steel")
	assert_false(Settings.haptics_enabled())


## Checks continuous feedback is stopped when haptics become unavailable.
func test_disabling_haptics_ends_continuous_signal() -> void:
	Settings.set_value("haptics_enabled", true)
	Haptics.begin_continuous(&"tension_resistance")
	assert_true(Haptics._continuous.has(&"tension_resistance"))
	Settings.set_value("haptics_enabled", false)
	Haptics.update_continuous(&"tension_resistance", 0.7, 0.2)
	assert_false(Haptics._continuous.has(&"tension_resistance"))


## Checks continuous feedback can restart after the player re-enables it.
func test_reenabled_continuous_haptics_can_restart() -> void:
	Settings.set_value("haptics_enabled", false)
	Haptics.begin_continuous(&"tension_resistance")
	Haptics.update_continuous(&"tension_resistance", 0.5, 0.3)
	Settings.set_value("haptics_enabled", true)
	Haptics.begin_continuous(&"tension_resistance")
	assert_true(Haptics._continuous.has(&"tension_resistance"))
	Haptics.end_continuous(&"tension_resistance")


## Checks the non-native fallback handles a pulse safely in headless/editor mode.
func test_generic_fallback_can_play_without_bridge() -> void:
	Haptics._native = null
	Settings.set_value("haptics_enabled", true)
	Haptics.play(&"set", 0.4, &"brass")
	assert_eq(Haptics.capabilities().get("tier"), "fallback")


## Checks the same critical cue retains visual and sound definitions without rumble.
func test_no_haptics_keeps_other_feedback_channels_defined() -> void:
	Settings.set_value("haptics_enabled", false)
	assert_false(Haptics.pattern_for(&"set").is_empty())
	assert_true(Sfx.EVENTS.has(&"set"))
	var session: RefCounted = FakeLockSession.create(&"pin_tumbler", 42, 2)
	assert_false(session.describe().is_empty())
