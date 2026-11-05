extends Control
## Settings screen (N-53): sections Haptics / Sound / Controls (D-52) / Language and
## accessibility / Graphics and help, inside the shared ScreenFrame (16 dp + safe-area).
## Every slider shows its value. Back = >= 48 dp plate in the top-left corner.

const S := "Frame/VBox/Scroll/Sections/"
const BG := "res://assets/ui/gpt/workshop/04-tool-board-portrait.webp"

@onready var haptics_check: CheckButton = get_node(S + "Haptics/Box/HapticsCheck")
@onready var intensity_slider: HSlider = get_node(S + "Haptics/Box/IntensitySlider")
@onready var intensity_value: Label = get_node(S + "Haptics/Box/IntensityRow/Value")
@onready var test_button: Button = get_node(S + "Haptics/Box/TestButton")
@onready var calibration_button: Button = get_node(S + "Haptics/Box/CalibrationButton")
@onready var calibration_result: Label = get_node(S + "Haptics/Box/CalibrationResult")
@onready var master_slider: HSlider = get_node(S + "Sound/Box/MasterSlider")
@onready var sfx_slider: HSlider = get_node(S + "Sound/Box/SfxSlider")
@onready var ambience_slider: HSlider = get_node(S + "Sound/Box/AmbienceSlider")
@onready var auto_tension_check: CheckButton = get_node(S + "Controls/Box/AutoTensionCheck")
@onready var continuous_check: CheckButton = get_node(S + "Controls/Box/ContinuousCheck")
@onready var language_option: OptionButton = get_node(S + "Access/Box/LanguageOption")
@onready var dark_assist_check: CheckButton = get_node(S + "Access/Box/DarkAssistCheck")
@onready var reading_aid_check: CheckButton = get_node(S + "Access/Box/ReadingAidCheck")
@onready var wide_windows_check: CheckButton = get_node(S + "Access/Box/WideWindowsCheck")
@onready var reduce_motion_check: CheckButton = get_node(S + "Access/Box/ReduceMotionCheck")
@onready var text_scale_slider: HSlider = get_node(S + "Access/Box/TextScaleSlider")
@onready var quality_option: OptionButton = get_node(S + "Other/Box/QualityOption")
@onready var reset_button: Button = get_node(S + "Other/Box/ResetButton")
@onready var report_button: Button = get_node(S + "Other/Box/ReportButton")
@onready var report_result: Label = get_node(S + "Other/Box/ReportResult")
@onready var back_button: Button = $Frame/VBox/Header/BackButton

var _wired := false


func _ready() -> void:
	Sfx.play_ambience(&"rain_window")
	ScreenFrame.backdrop(self, BG, 0.62)
	ScreenFrame.fit(self, $Frame)
	# N-42: a scroll gesture starting on a control must scroll the list, not press the control
	$Frame/VBox/Scroll.scroll_deadzone = 12
	_pass_mouse($Frame/VBox/Scroll/Sections)
	_load_values()
	_refresh_texts()
	if not _wired:
		_wire()
	ScreenFrame.enter($Frame/VBox/Scroll)


func _pass_mouse(n: Node) -> void:
	for c in n.get_children():
		if c is Control:
			c.mouse_filter = Control.MOUSE_FILTER_PASS
		_pass_mouse(c)


func _load_values() -> void:
	haptics_check.set_pressed_no_signal(Settings.haptics_enabled())
	intensity_slider.set_value_no_signal(Settings.haptics_intensity())
	master_slider.set_value_no_signal(Settings.get_value("volume_master"))
	sfx_slider.set_value_no_signal(Settings.get_value("volume_sfx"))
	ambience_slider.set_value_no_signal(Settings.get_value("volume_ambience"))
	auto_tension_check.set_pressed_no_signal(Settings.get_value("auto_tension", true))
	dark_assist_check.set_pressed_no_signal(Settings.get_value("dark_mode_assist"))
	reading_aid_check.set_pressed_no_signal(Settings.get_value("reading_aid"))
	wide_windows_check.set_pressed_no_signal(Settings.get_value("wide_windows"))
	continuous_check.set_pressed_no_signal(Settings.get_value("continuous_resistance"))
	text_scale_slider.set_value_no_signal(float(Settings.get_value("text_scale", 1.0)) * 100.0)
	reduce_motion_check.set_pressed_no_signal(Settings.get_value("reduce_motion"))
	_fill_options()
	_update_values()


func _fill_options() -> void:
	language_option.clear()
	language_option.add_item(I18n.t(&"settings.language_system"), 0)
	language_option.add_item(I18n.t(&"settings.language_pl"), 1)
	language_option.add_item(I18n.t(&"settings.language_en"), 2)
	if Save.get_value("dev_mode", false):  # T03: DE tylko za flagą deweloperską
		language_option.add_item(I18n.t(&"settings.language_de"), 3)
	match Settings.get_value("language"):
		"pl": language_option.selected = 1
		"en": language_option.selected = 2
		"de": language_option.selected = 3 if Save.get_value("dev_mode", false) else 0
		_: language_option.selected = 0
	quality_option.clear()
	quality_option.add_item(I18n.t(&"settings.quality_auto"), 0)
	quality_option.add_item(I18n.t(&"settings.quality_high"), 1)
	quality_option.add_item(I18n.t(&"settings.quality_medium"), 2)
	quality_option.add_item(I18n.t(&"settings.quality_low"), 3)
	match Settings.get_value("quality_profile", "auto"):
		"high": quality_option.selected = 1
		"medium": quality_option.selected = 2
		"low": quality_option.selected = 3
		_: quality_option.selected = 0


func _pct(v: float) -> String:
	return "%d%%" % roundi(v * 100.0)


func _update_values() -> void:
	intensity_value.text = _pct(intensity_slider.value)
	get_node(S + "Sound/Box/MasterRow/Value").text = _pct(master_slider.value)
	get_node(S + "Sound/Box/SfxRow/Value").text = _pct(sfx_slider.value)
	get_node(S + "Sound/Box/AmbienceRow/Value").text = _pct(ambience_slider.value)
	get_node(S + "Access/Box/TextScaleRow/Value").text = "%d%%" % int(text_scale_slider.value)


func _wire() -> void:
	_wired = true
	haptics_check.toggled.connect(func(on: bool) -> void: Settings.set_value("haptics_enabled", on))
	intensity_slider.value_changed.connect(func(v: float) -> void:
		Settings.set_value("haptics_intensity", v)
		_update_values())
	master_slider.value_changed.connect(func(v: float) -> void:
		Settings.set_value("volume_master", v)
		_update_values())
	sfx_slider.value_changed.connect(func(v: float) -> void:
		Settings.set_value("volume_sfx", v)
		_update_values())
	ambience_slider.value_changed.connect(func(v: float) -> void:
		Settings.set_value("volume_ambience", v)
		_update_values())
	auto_tension_check.toggled.connect(func(on: bool) -> void:
		Settings.set_value("auto_tension", on)
		Settings.set_value("control_chosen", true))
	dark_assist_check.toggled.connect(func(on: bool) -> void: Settings.set_value("dark_mode_assist", on))
	reading_aid_check.toggled.connect(func(on: bool) -> void: Settings.set_value("reading_aid", on))
	wide_windows_check.toggled.connect(func(on: bool) -> void: Settings.set_value("wide_windows", on))
	continuous_check.toggled.connect(func(on: bool) -> void: Settings.set_value("continuous_resistance", on))
	text_scale_slider.value_changed.connect(func(v: float) -> void:
		Settings.set_value("text_scale", v / 100.0)
		_update_values())
	reduce_motion_check.toggled.connect(func(on: bool) -> void: Settings.set_value("reduce_motion", on))
	language_option.item_selected.connect(func(idx: int) -> void:
		Settings.set_value("language", ["", "pl", "en", "de"][mini(idx, 3)]))
	quality_option.item_selected.connect(func(idx: int) -> void:
		Settings.set_value("quality_profile", ["auto", "high", "medium", "low"][idx])
		Quality.apply_profile(["auto", "high", "medium", "low"][idx]))
	test_button.pressed.connect(func() -> void:
		Haptics.play(&"set", 1.0, &"brass")
		Sfx.play(&"set", &"brass"))
	calibration_button.pressed.connect(_run_two_click_calibration)
	reset_button.pressed.connect(func() -> void:
		for key in Settings.DEFAULTS:
			if key != "control_chosen":
				Settings.set_value(key, Settings.DEFAULTS[key])
		_load_values())
	back_button.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	report_button.pressed.connect(_report_problem)
	I18n.language_changed.connect(_refresh_texts)


func _report_problem() -> void:
	# task 12: local log only — copy to clipboard; nothing is ever sent from the device
	var text := ErrorLog.latest_log_text()
	if text == "":
		report_result.text = I18n.t(&"settings.report_empty")
		return
	DisplayServer.clipboard_set(text)
	report_result.text = I18n.t(&"settings.report_copied")


func _run_two_click_calibration() -> void:
	# TECH.md §2.3: two `set` transients 120 ms apart; player answers.
	Haptics.play(&"set", 0.9, &"brass")
	await get_tree().create_timer(0.12).timeout
	Haptics.play(&"set", 0.9, &"brass")
	calibration_result.text = I18n.t(&"settings.haptics_calibration_two_clicks")


func _refresh_texts() -> void:
	$Frame/VBox/Header/Title.text = I18n.t(&"settings.title")
	back_button.text = "‹ " + I18n.t(&"common.back")
	get_node(S + "Haptics/Box/Heading").text = I18n.t(&"settings.haptics")
	get_node(S + "Sound/Box/Heading").text = I18n.t(&"settings.section_sound")
	get_node(S + "Controls/Box/Heading").text = I18n.t(&"settings.section_controls")
	get_node(S + "Access/Box/Heading").text = I18n.t(&"settings.section_access")
	get_node(S + "Other/Box/Heading").text = I18n.t(&"settings.section_other")
	haptics_check.text = I18n.t(&"settings.haptics_enabled")
	get_node(S + "Haptics/Box/IntensityRow/Name").text = I18n.t(&"settings.haptics_intensity")
	test_button.text = I18n.t(&"settings.haptics_test")
	calibration_button.text = I18n.t(&"settings.haptics_calibration")
	get_node(S + "Sound/Box/MasterRow/Name").text = I18n.t(&"settings.volume_master")
	get_node(S + "Sound/Box/SfxRow/Name").text = I18n.t(&"settings.volume_sfx")
	get_node(S + "Sound/Box/AmbienceRow/Name").text = I18n.t(&"settings.volume_ambience")
	auto_tension_check.text = I18n.t(&"ui.controls.auto_toggle")
	get_node(S + "Controls/Box/AutoTensionNote").text = I18n.t(&"ui.controls.auto_desc")
	continuous_check.text = I18n.t(&"settings.continuous_resistance")
	get_node(S + "Access/Box/LanguageLabel").text = I18n.t(&"settings.language")
	dark_assist_check.text = I18n.t(&"settings.dark_mode_assist")
	reading_aid_check.text = I18n.t(&"settings.reading_aid")
	wide_windows_check.text = I18n.t(&"settings.wide_windows")
	reduce_motion_check.text = I18n.t(&"settings.reduce_motion")
	get_node(S + "Access/Box/TextScaleRow/Name").text = I18n.t(&"settings.text_scale")
	get_node(S + "Access/Box/DarkNote").text = I18n.t(&"settings.dark_mode_note")
	get_node(S + "Other/Box/QualityLabel").text = I18n.t(&"settings.quality")
	reset_button.text = I18n.t(&"settings.reset")
	report_button.text = I18n.t(&"settings.report_problem")
	report_result.text = ""
	_fill_options()
	_update_values()
