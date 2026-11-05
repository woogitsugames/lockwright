extends "res://tests/gut/t27_fixture.gd"
## A11Y A-05/A-11: runtime 200% text scale and accessible settings controls.


## Checks 200% text scale doubles the project's baseline font size.
func test_200_percent_updates_default_theme_font() -> void:
	Settings.set_value("text_scale", 2.0)
	var theme: Theme = load("res://theme/main.tres")
	assert_eq(theme.default_font_size, 32)


## Checks the type-specific Label/Button/Title sizes also scale (A-11).
func test_200_percent_updates_per_type_overrides() -> void:
	Settings.set_value("text_scale", 2.0)
	var theme: Theme = load("res://theme/main.tres")
	assert_eq(theme.get_font_size("font_size", "Label"), 32)
	assert_eq(theme.get_font_size("font_size", "Button"), 36)
	assert_eq(theme.get_font_size("font_size", "Title"), 56)


## Checks restoring 100% text size removes the 200% state in the shared theme.
func test_text_scale_reset_to_100_percent() -> void:
	Settings.set_value("text_scale", 2.0)
	Settings.set_value("text_scale", 1.0)
	var theme: Theme = load("res://theme/main.tres")
	assert_eq(theme.default_font_size, 16)
	assert_eq(theme.get_font_size("font_size", "Button"), 18)


## Checks that selecting 200% persists in settings.cfg.
func test_text_scale_200_percent_survives_reload() -> void:
	Settings.set_value("text_scale", 2.0)
	Settings.load_settings()
	assert_eq(float(Settings.get_value("text_scale")), 2.0)


## Checks 200% is reachable through the shipped settings slider (100–200%).
func test_settings_slider_accepts_200_percent() -> void:
	var scene := t27_scene("res://scenes/settings.tscn")
	var slider: HSlider = scene.get_node("Scroll/VBox/TextScaleSlider")
	assert_eq(slider.min_value, 100.0)
	assert_gte(slider.max_value, 200.0)
	slider.value = 200.0
	assert_eq(float(Settings.get_value("text_scale")), 2.0)


## Checks text scaling does not reduce the touch target height below 48 dp.
func test_large_text_keeps_settings_button_targets() -> void:
	Settings.set_value("text_scale", 2.0)
	var scene := t27_scene("res://scenes/settings.tscn")
	for path in ["Scroll/VBox/HapticsCheck", "Scroll/VBox/CalibrationButton",
			"Scroll/VBox/ResetButton", "Scroll/VBox/ReportButton", "BackButton"]:
		var control: Control = scene.get_node(path)
		assert_gte(control.custom_minimum_size.y, 48.0, path)


## Checks the accessibility screen is scrollable at 200% instead of hiding options.
func test_200_percent_settings_content_has_scroll_container() -> void:
	Settings.set_value("text_scale", 2.0)
	var scene := t27_scene("res://scenes/settings.tscn")
	var scroll: ScrollContainer = scene.get_node("Scroll")
	assert_not_null(scroll.get_v_scroll_bar())
	assert_true(scroll.get_node("VBox").get_child_count() > 15)
