extends Control
## Settings screen (N-53): sections Haptics / Sound / Controls (D-52) / Language and
## accessibility / Graphics and help, inside the shared ScreenFrame (16 dp + safe-area).
## Every slider shows its value. Back = >= 48 dp plate in the top-left corner.

const S := "Frame/VBox/Scroll/Sections/"
const BG := "res://assets/ui/gpt/workshop/04-tool-board-portrait.webp"
## Language picker item index -> Settings "language" ("" = device); items 3-5 only with the dev flag.
const LANGUAGE_IDS := ["", "pl", "en", "de", "fr", "es"]

@onready var haptics_check: CheckButton = get_node(S + "Haptics/Box/HapticsCheck")
@onready var intensity_slider: HSlider = get_node(S + "Haptics/Box/IntensitySlider")
@onready var intensity_value: Label = get_node(S + "Haptics/Box/IntensityRow/Value")
@onready var test_button: Button = get_node(S + "Haptics/Box/TestButton")
@onready var calibration_button: Button = get_node(S + "Haptics/Box/CalibrationButton")
@onready var calibration_result: Label = get_node(S + "Haptics/Box/CalibrationResult")
@onready var master_slider: HSlider = get_node(S + "Sound/Box/MasterSlider")
@onready var sfx_slider: HSlider = get_node(S + "Sound/Box/SfxSlider")
@onready var ambience_slider: HSlider = get_node(S + "Sound/Box/AmbienceSlider")
@onready var voice_slider: HSlider = get_node(S + "Sound/Box/VoiceSlider")
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
# D-62: on-demand voice language block under the language picker (built in code)
var _vp_box: VBoxContainer
var _vp_label: Label
var _vp_rows: VBoxContainer
var _vp_auto: CheckButton
var _vp_note: Label


func _ready() -> void:
	Sfx.play_ambience(&"rain_window")
	ScreenFrame.backdrop(self, BG, 0.62)
	ScreenFrame.fit(self, $Frame)
	# N-42: a scroll gesture starting on a control must scroll the list, not press the control
	$Frame/VBox/Scroll.scroll_deadzone = 12
	# D-90: at 125-200 % text the longest item ("Auto (measured)") must wrap, not widen the screen
	for ob: OptionButton in [language_option, quality_option]:
		ob.fit_to_longest_item = false
		ob.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_build_voice_pack_block()
	_build_help_captions()
	_build_a11y_toggles()
	_build_system_text()
	_pass_mouse($Frame/VBox/Scroll/Sections)
	_load_values()
	_refresh_texts()
	if not _wired:
		_wire()
	ScreenFrame.enter($Frame/VBox/Scroll)
	ScreenFrame.wire_sounds(self)  # S05 enamel-plate sounds


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
	voice_slider.set_value_no_signal(Settings.get_value("volume_voice", 1.0))
	auto_tension_check.set_pressed_no_signal(Settings.get_value("auto_tension", true))
	dark_assist_check.set_pressed_no_signal(Settings.get_value("dark_mode_assist"))
	reading_aid_check.set_pressed_no_signal(Settings.get_value("reading_aid"))
	wide_windows_check.set_pressed_no_signal(Settings.get_value("wide_windows"))
	continuous_check.set_pressed_no_signal(Settings.get_value("continuous_resistance"))
	text_scale_slider.set_value_no_signal(UiA11y.text_scale() * 100.0)  # D-107: the size in use (system or own)
	if _system_text != null:
		_system_text.set_pressed_no_signal(bool(Settings.get_value("text_scale_system", true)))
	reduce_motion_check.set_pressed_no_signal(Settings.get_value("reduce_motion"))
	for key in A11Y_TOGGLES:
		(_toggles[key] as CheckButton).set_pressed_no_signal(bool(Settings.get_value(key)))
	_fill_options()
	_update_values()
	_update_voice_pack()


func _fill_options() -> void:
	language_option.clear()
	language_option.add_item(I18n.t(&"settings.language_system"), 0)
	language_option.add_item(I18n.t(&"settings.language_pl"), 1)
	language_option.add_item(I18n.t(&"settings.language_en"), 2)
	var dev: bool = Save.get_value("dev_mode", false)
	if dev:  # T03: DE tylko za flagą deweloperską; T41: FR/ES też (teksty niepełne, bez głosów)
		language_option.add_item(I18n.t(&"settings.language_de"), 3)
		language_option.add_item(I18n.t(&"settings.language_fr"), 4)
		language_option.add_item(I18n.t(&"settings.language_es"), 5)
	var idx := LANGUAGE_IDS.find(str(Settings.get_value("language")))
	language_option.selected = idx if idx >= 0 and (idx <= 2 or dev) else 0
	quality_option.clear()
	quality_option.add_item(Quality.auto_label(), 0)  # N-99: "Auto (średnia)"
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
	get_node(S + "Sound/Box/VoiceRow/Value").text = _pct(voice_slider.value)
	get_node(S + "Access/Box/TextScaleRow/Value").text = "%d%%" % int(text_scale_slider.value)


## N-99 (D-113): the 10 s frame-time measurement can end while Settings is open; "Auto (…)" then names
## the profile just picked, not the one from the last run.
func _on_quality_profile(_profile: Dictionary) -> void:
	if quality_option.item_count > 0:
		quality_option.set_item_text(0, Quality.auto_label())


## D-113: the player came back from the system settings with another text size (Android font scale,
## iOS Dynamic Type): the switch names it and the slider shows the size in use.
func _on_system_scale(_scale: float) -> void:
	_system_text.text = I18n.t(&"settings.text_scale_system").format(
		{"pct": roundi(UiA11y.raw_system_scale() * 100.0)})
	text_scale_slider.set_value_no_signal(UiA11y.text_scale() * 100.0)
	_update_values()


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
	voice_slider.value_changed.connect(func(v: float) -> void:
		Settings.set_value("volume_voice", v)
		_update_values())
	auto_tension_check.toggled.connect(func(on: bool) -> void:
		Settings.set_value("auto_tension", on)
		Settings.set_value("control_chosen", true))
	dark_assist_check.toggled.connect(func(on: bool) -> void: Settings.set_value("dark_mode_assist", on))
	reading_aid_check.toggled.connect(func(on: bool) -> void: Settings.set_value("reading_aid", on))
	wide_windows_check.toggled.connect(func(on: bool) -> void: Settings.set_value("wide_windows", on))
	continuous_check.toggled.connect(func(on: bool) -> void: Settings.set_value("continuous_resistance", on))
	text_scale_slider.value_changed.connect(func(v: float) -> void:
		Settings.set_value("text_scale_system", false)  # D-107: an own size stops following the system
		Settings.set_value("text_scale", v / 100.0)
		_system_text.set_pressed_no_signal(false)
		_update_values())
	_system_text.toggled.connect(func(on: bool) -> void:
		Settings.set_value("text_scale_system", on)
		if not on:
			Settings.set_value("text_scale", UiA11y.system_text_scale())  # start from what is shown
		text_scale_slider.set_value_no_signal(UiA11y.text_scale() * 100.0)
		_update_values())
	reduce_motion_check.toggled.connect(func(on: bool) -> void: Settings.set_value("reduce_motion", on))
	for key in A11Y_TOGGLES:
		(_toggles[key] as CheckButton).toggled.connect(func(on: bool) -> void: Settings.set_value(key, on))
	language_option.item_selected.connect(func(idx: int) -> void:
		Settings.set_value("language", LANGUAGE_IDS[clampi(idx, 0, LANGUAGE_IDS.size() - 1)])
		_update_voice_pack())
	_vp_auto.toggled.connect(func(on: bool) -> void:
		Settings.set_value("voice_download", "auto" if on else "manual")
		if on:
			VoicePacks.auto(Settings.language())
		_update_voice_pack())
	VoicePacks.state_changed.connect(_on_voice_pack_event)
	VoicePacks.progress.connect(_on_voice_pack_progress)
	quality_option.item_selected.connect(func(idx: int) -> void:
		Settings.set_value("quality_profile", ["auto", "high", "medium", "low"][idx])
		Quality.apply_profile(["auto", "high", "medium", "low"][idx]))
	# D-113: what is shown follows what changed behind the screen's back (methods, so the
	# connections end with this screen)
	Quality.profile_changed.connect(_on_quality_profile)
	UiA11y.system_scale_changed.connect(_on_system_scale)
	test_button.pressed.connect(func() -> void:
		Haptics.test_pulse()  # N-70: one long, clearly felt pulse (a 19 ms `set` was not)
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
	get_node(S + "Sound/Box/VoiceRow/Name").text = I18n.t(&"settings.volume_voice")
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
	_vp_label.text = I18n.t(&"settings.voice_pack.header")
	_vp_auto.text = I18n.t(&"settings.voice_pack.auto")
	_vp_note.text = I18n.t(&"settings.voice_pack.note")
	for cap_name in HELP:
		(_help[cap_name] as Label).text = I18n.t(HELP[cap_name][1])
	_system_text.text = I18n.t(&"settings.text_scale_system").format(
		{"pct": roundi(UiA11y.raw_system_scale() * 100.0)})
	for key in A11Y_TOGGLES:
		(_toggles[key] as CheckButton).text = I18n.t(A11Y_TOGGLES[key][2])
		(_toggles[key].get_meta(&"help") as Label).text = I18n.t(A11Y_TOGGLES[key][3])
	# T70: a slider's name sits in a separate row label; give it to the screen reader too
	for row in [S + "Haptics/Box/IntensityRow", S + "Sound/Box/MasterRow", S + "Sound/Box/SfxRow",
			S + "Sound/Box/AmbienceRow", S + "Sound/Box/VoiceRow", S + "Access/Box/TextScaleRow"]:
		var slider := _slider_for_row(row)
		if slider != null and "accessibility_name" in slider:
			slider.set("accessibility_name", (get_node(row + "/Name") as Label).text)
	reset_button.text = I18n.t(&"settings.reset")
	report_button.text = I18n.t(&"settings.report_problem")
	report_result.text = ""
	_fill_options()
	_update_values()
	_update_voice_pack()


# --- T60: one help line (Caption) under a control ------------------------------------
## caption node name -> [control it follows, i18n key]
const HELP := {
	"HapticsHelp": ["Haptics/Box/HapticsCheck", &"settings.help.haptics"],
	"ChalkHelp": ["Access/Box/ReadingAidCheck", &"settings.help.chalk"],
	"MotionHelp": ["Access/Box/ReduceMotionCheck", &"settings.help.reduce_motion"],
	"QualityHelp": ["Other/Box/QualityOption", &"settings.help.quality"],
}
var _help := {}


func _build_help_captions() -> void:
	for cap_name in HELP:
		var after: Control = get_node(S + String(HELP[cap_name][0]))
		var cap := Label.new()
		cap.name = cap_name
		cap.theme_type_variation = &"Caption"
		cap.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		after.get_parent().add_child(cap)
		after.get_parent().move_child(cap, after.get_index() + 1)
		_help[cap_name] = cap


# --- D-90: accessibility toggles built in code (same look as the scene's CheckButtons) ----------
## Settings key -> [section box, insert after (node path in Sections), i18n label, i18n help]
const A11Y_TOGGLES := {
	"swap_thumbs": ["Controls/Box", "Controls/Box/ContinuousCheck", &"settings.swap_thumbs", &"settings.help.swap_thumbs"],
	"tension_lock": ["Controls/Box", "Controls/Box/ContinuousCheck", &"settings.tension_lock", &"settings.help.tension_lock"],
	"announce_lock_events": ["Access/Box", "Access/Box/MotionHelp", &"settings.announce_lock", &"settings.help.announce_lock"],
	"sound_captions": ["Access/Box", "Access/Box/MotionHelp", &"settings.sound_captions", &"settings.help.sound_captions"],
}
var _toggles := {}


func _build_a11y_toggles() -> void:
	var keys := A11Y_TOGGLES.keys()
	keys.reverse()  # both Access toggles go right after MotionHelp: insert in reverse to keep the order
	for key in keys:
		var after: Control = get_node(S + String(A11Y_TOGGLES[key][1]))
		var box := after.get_parent()
		var cb := CheckButton.new()
		cb.name = String(key).to_pascal_case() + "Check"
		cb.custom_minimum_size = Vector2(0, 48)
		cb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		cb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var cap := Label.new()
		cap.name = String(key).to_pascal_case() + "Help"
		cap.theme_type_variation = &"Caption"
		cap.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(cb)
		box.move_child(cb, after.get_index() + 1)
		box.add_child(cap)
		box.move_child(cap, cb.get_index() + 1)
		cb.set_meta(&"help", cap)
		_toggles[key] = cb


# --- D-107: "as in the system" switch under the text size slider ------------------------------
var _system_text: CheckButton


func _build_system_text() -> void:
	_system_text = CheckButton.new()
	_system_text.name = "SystemTextCheck"
	_system_text.custom_minimum_size = Vector2(0, 48)
	_system_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_system_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var box := text_scale_slider.get_parent()
	box.add_child(_system_text)
	box.move_child(_system_text, text_scale_slider.get_index() + 1)


## The slider placed right after a "<X>Row" label row (IntensityRow -> IntensitySlider).
func _slider_for_row(row_path: String) -> HSlider:
	var row := get_node(row_path)
	var i := row.get_index() + 1
	if i >= row.get_parent().get_child_count():
		return null
	return row.get_parent().get_child(i) as HSlider


# --- D-62/D-100: voice packs ------------------------------------------------------------
# A plain block in the Language section (no cards): a heading, one row per voice language
# ("Polish voices: 18.4 MB" + Download / Stop / Remove / Try again, plates >= 48 dp; EN is in
# the game and has no button), the auto-download toggle (the game language) and a privacy
# note. Never blocks anything: without a pack the dialogue is subtitle-only.

func _build_voice_pack_block() -> void:
	var box: VBoxContainer = get_node(S + "Access/Box")
	_vp_box = VBoxContainer.new()
	_vp_box.name = "VoicePack"
	_vp_box.add_theme_constant_override("separation", 8)
	_vp_label = Label.new()
	_vp_label.name = "VoicePackLabel"
	_vp_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_vp_box.add_child(_vp_label)
	_vp_rows = VBoxContainer.new()
	_vp_rows.name = "VoicePackRows"
	_vp_rows.add_theme_constant_override("separation", 8)
	_vp_box.add_child(_vp_rows)
	for lang in VoicePacks.languages():
		var row := HBoxContainer.new()
		row.name = "Row_" + lang
		row.add_theme_constant_override("separation", 12)
		var label := Label.new()
		label.name = "Label"
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(label)
		var action := Button.new()
		action.name = "Action"
		action.custom_minimum_size = Vector2(132, 52)
		action.pressed.connect(_on_voice_pack_pressed.bind(lang))
		row.add_child(action)
		_vp_rows.add_child(row)
	_vp_auto = CheckButton.new()
	_vp_auto.name = "VoicePackAuto"
	_vp_auto.custom_minimum_size = Vector2(0, 48)
	_vp_auto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_vp_box.add_child(_vp_auto)
	_vp_note = Label.new()
	_vp_note.name = "VoicePackNote"
	_vp_note.theme_type_variation = &"Caption"
	_vp_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_vp_box.add_child(_vp_note)
	box.add_child(_vp_box)
	box.move_child(_vp_box, language_option.get_index() + 1)


static func _voice_title(lang: String) -> String:
	var k := StringName("settings.voice_pack.title_" + lang)
	return I18n.t(k) if I18n.has_key(k) else lang.to_upper()


func _update_voice_pack() -> void:
	if _vp_box == null:
		return
	for row in _vp_rows.get_children():
		var lang := String(row.name).trim_prefix("Row_")
		var label: Label = row.get_node("Label")
		var action: Button = row.get_node("Action")
		var st := VoicePacks.state(lang)
		var info := VoicePacks.size_text(VoicePacks.pack_size(lang), I18n.current_language())
		action.visible = true
		match st:
			"bundled":
				info = I18n.t(&"settings.voice_pack.builtin")
				action.visible = false
			"installed":
				info = I18n.t(&"settings.voice_pack.ready")
				action.text = I18n.t(&"settings.voice_pack.remove")
			"downloading":
				info = I18n.t(&"settings.voice_pack.progress").format(
					{"pct": roundi(VoicePacks.progress_ratio(lang) * 100.0)})
				action.text = I18n.t(&"settings.voice_pack.stop")
			"verifying":
				info = I18n.t(&"settings.voice_pack.verifying")
				action.visible = false
			"failed":
				action.text = I18n.t(&"settings.voice_pack.retry")
			_:
				action.text = I18n.t(&"settings.voice_pack.download")
		var line := I18n.t(&"settings.voice_pack.line").format({"title": _voice_title(lang), "state": info})
		if st == "failed":
			var why := "offline" if VoicePacks.last_error(lang) in ["offline", "timeout"] else "failed"
			line += "\n" + I18n.t(StringName("settings.voice_pack." + why))
		label.text = line
	_vp_auto.set_pressed_no_signal(str(Settings.get_value("voice_download", "auto")) != "manual")


func _on_voice_pack_pressed(lang: String) -> void:
	match VoicePacks.state(lang):
		"downloading":
			VoicePacks.cancel(lang)
		"installed":
			VoicePacks.remove(lang)
		"bundled", "verifying":
			pass
		_:
			VoicePacks.ensure(lang)
	_update_voice_pack()


func _on_voice_pack_event(_lang: String) -> void:
	_update_voice_pack()


func _on_voice_pack_progress(_lang: String, _received: int, _total: int) -> void:
	_update_voice_pack()