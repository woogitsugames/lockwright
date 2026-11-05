extends Control
## Settings screen: haptics on/off + intensity + test pulse, volumes, language,
## accessibility (dark mode assist, reading aid, wide windows), two-click calibration.

@onready var haptics_check: CheckButton = $Scroll/VBox/HapticsCheck
@onready var intensity_slider: HSlider = $Scroll/VBox/IntensitySlider
@onready var intensity_value: Label = $Scroll/VBox/IntensityValue
@onready var test_button: Button = $Scroll/VBox/TestButton
@onready var calibration_button: Button = $Scroll/VBox/CalibrationButton
@onready var calibration_result: Label = $Scroll/VBox/CalibrationResult
@onready var master_slider: HSlider = $Scroll/VBox/MasterSlider
@onready var sfx_slider: HSlider = $Scroll/VBox/SfxSlider
@onready var ambience_slider: HSlider = $Scroll/VBox/AmbienceSlider
@onready var language_option: OptionButton = $Scroll/VBox/LanguageOption
@onready var dark_assist_check: CheckButton = $Scroll/VBox/DarkAssistCheck
@onready var reading_aid_check: CheckButton = $Scroll/VBox/ReadingAidCheck
@onready var wide_windows_check: CheckButton = $Scroll/VBox/WideWindowsCheck
@onready var continuous_check: CheckButton = $Scroll/VBox/ContinuousCheck
@onready var text_scale_slider: HSlider = $Scroll/VBox/TextScaleSlider
@onready var reduce_motion_check: CheckButton = $Scroll/VBox/ReduceMotionCheck
@onready var quality_option: OptionButton = $Scroll/VBox/QualityOption
@onready var reset_button: Button = $Scroll/VBox/ResetButton
@onready var report_button: Button = $Scroll/VBox/ReportButton
@onready var report_result: Label = $Scroll/VBox/ReportResult
@onready var back_button: Button = $BackButton


func _ready() -> void:
	Sfx.play_ambience(&"rain_window")
	SafeArea.apply(self)
	_refresh_texts()
	haptics_check.button_pressed = Settings.haptics_enabled()
	intensity_slider.value = Settings.haptics_intensity()
	master_slider.value = Settings.get_value("volume_master")
	sfx_slider.value = Settings.get_value("volume_sfx")
	ambience_slider.value = Settings.get_value("volume_ambience")
	dark_assist_check.button_pressed = Settings.get_value("dark_mode_assist")
	reading_aid_check.button_pressed = Settings.get_value("reading_aid")
	wide_windows_check.button_pressed = Settings.get_value("wide_windows")
	continuous_check.button_pressed = Settings.get_value("continuous_resistance")
	text_scale_slider.value = float(Settings.get_value("text_scale", 1.0)) * 100.0
	reduce_motion_check.button_pressed = Settings.get_value("reduce_motion")
	language_option.clear()
	language_option.add_item(I18n.t(&"settings.language_system"), 0)
	language_option.add_item(I18n.t(&"settings.language_pl"), 1)
	language_option.add_item(I18n.t(&"settings.language_en"), 2)
	match Settings.get_value("language"):
		"": language_option.selected = 0
		"pl": language_option.selected = 1
		"en": language_option.selected = 2

	haptics_check.toggled.connect(func(on: bool) -> void: Settings.set_value("haptics_enabled", on))
	intensity_slider.value_changed.connect(func(v: float) -> void:
		Settings.set_value("haptics_intensity", v)
		intensity_value.text = "%d%%" % int(v * 100))
	master_slider.value_changed.connect(func(v: float) -> void: Settings.set_value("volume_master", v))
	sfx_slider.value_changed.connect(func(v: float) -> void: Settings.set_value("volume_sfx", v))
	ambience_slider.value_changed.connect(func(v: float) -> void: Settings.set_value("volume_ambience", v))
	dark_assist_check.toggled.connect(func(on: bool) -> void: Settings.set_value("dark_mode_assist", on))
	reading_aid_check.toggled.connect(func(on: bool) -> void: Settings.set_value("reading_aid", on))
	wide_windows_check.toggled.connect(func(on: bool) -> void: Settings.set_value("wide_windows", on))
	continuous_check.toggled.connect(func(on: bool) -> void: Settings.set_value("continuous_resistance", on))
	text_scale_slider.value_changed.connect(func(v: float) -> void: Settings.set_value("text_scale", v / 100.0))
	reduce_motion_check.toggled.connect(func(on: bool) -> void: Settings.set_value("reduce_motion", on))
	language_option.item_selected.connect(func(idx: int) -> void:
		Settings.set_value("language", ["", "pl", "en"][idx]))
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
	quality_option.item_selected.connect(func(idx: int) -> void:
		Settings.set_value("quality_profile", ["auto", "high", "medium", "low"][idx])
		Quality.apply_profile(["auto", "high", "medium", "low"][idx]))
	test_button.pressed.connect(func() -> void:
		Haptics.play(&"set", 1.0, &"brass")
		Sfx.play(&"set", &"brass"))
	calibration_button.pressed.connect(_run_two_click_calibration)
	reset_button.pressed.connect(func() -> void:
		for key in Settings.DEFAULTS:
			Settings.set_value(key, Settings.DEFAULTS[key])
		_ready())
	back_button.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	report_button.pressed.connect(_report_problem)
	I18n.language_changed.connect(_refresh_texts)


func _report_problem() -> void:
	# task 12: local log only — copy to clipboard (system share sheet on mobile via
	# the OS "share" affordance is not wired; nothing is ever sent from the device)
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
	$Scroll/VBox/Title.text = I18n.t(&"settings.title")
	$Scroll/VBox/FeelLabel.text = I18n.t(&"settings.feel_section")
	haptics_check.text = I18n.t(&"settings.haptics_enabled")
	$Scroll/VBox/IntensityLabel.text = I18n.t(&"settings.haptics_intensity")
	test_button.text = I18n.t(&"settings.haptics_test")
	calibration_button.text = I18n.t(&"settings.haptics_calibration")
	$Scroll/VBox/MasterLabel.text = I18n.t(&"settings.volume_master")
	$Scroll/VBox/SfxLabel.text = I18n.t(&"settings.volume_sfx")
	$Scroll/VBox/AmbienceLabel.text = I18n.t(&"settings.volume_ambience")
	$Scroll/VBox/LanguageLabel.text = I18n.t(&"settings.language")
	dark_assist_check.text = I18n.t(&"settings.dark_mode_assist")
	reading_aid_check.text = I18n.t(&"settings.reading_aid")
	wide_windows_check.text = I18n.t(&"settings.wide_windows")
	continuous_check.text = I18n.t(&"settings.continuous_resistance")
	$Scroll/VBox/TextScaleLabel.text = I18n.t(&"settings.text_scale")
	reduce_motion_check.text = I18n.t(&"settings.reduce_motion")
	$Scroll/VBox/QualityLabel.text = I18n.t(&"settings.quality")
	$Scroll/VBox/DarkNote.text = I18n.t(&"settings.dark_mode_note")
	reset_button.text = I18n.t(&"settings.reset")
	report_button.text = I18n.t(&"settings.report_problem")
	report_result.text = ""
	back_button.text = I18n.t(&"common.back")
	intensity_value.text = "%d%%" % int(Settings.haptics_intensity() * 100)
