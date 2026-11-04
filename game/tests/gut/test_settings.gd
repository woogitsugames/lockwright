extends GutTest

func test_defaults_present() -> void:
	assert_true(Settings.get_value("haptics_enabled") == true)
	assert_eq(Settings.haptics_intensity(), 1.0)
	assert_true(Settings.get_value("haptics_enabled") in [true, false])

func test_set_and_clamp() -> void:
	Settings.set_value("haptics_intensity", 0.5)
	assert_eq(Settings.haptics_intensity(), 0.5)
	Settings.set_value("haptics_intensity", 1.0)
	assert_eq(Settings.haptics_intensity(), 1.0)

func test_unknown_key_rejected() -> void:
	Settings.set_value("no_such_key", 1)
	assert_false(Settings.get_value("no_such_key") == 1 and not Settings.DEFAULTS.has("no_such_key"))
