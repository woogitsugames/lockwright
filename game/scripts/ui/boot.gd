extends Control
## Boot: applies language and goes to the main menu. On the first launch one card comes first
## (D-134): the haptics question of TECH.md §2.3 ("Do you feel two clicks?", answered with one tap,
## "Again" repeats the two clicks) and under it the one-time note "this is a game, not a course"
## (ONBOARDING §3.3). The card waits for the answer and the game moves on in the same moment.
## Before D-134 the note was its own card for 3 s (too short to read, impossible to skip), and the
## question kept a blank screen for the rest of its 6 s after it had been answered: 8.8 s in which
## a new player could do nothing.

var _preloaded: Array[String] = []

@onready var notice: PanelContainer = $NoticePanel
@onready var notice_label: Label = $NoticePanel/VBox/Label
@onready var calib: PanelContainer = $CalibPanel
@onready var calib_label: Label = $CalibPanel/VBox/Question
@onready var calib_two: Button = $CalibPanel/VBox/Answers/TwoButton
@onready var calib_one: Button = $CalibPanel/VBox/Answers/OneButton
@onready var calib_none: Button = $CalibPanel/VBox/Answers/NoneButton
@onready var calib_again: Button = $CalibPanel/VBox/AgainButton
@onready var calib_note: Label = $CalibPanel/VBox/Note
@onready var calib_continue: Button = $CalibPanel/VBox/ContinueButton

## Emitted once when the first-run card is answered ("two" | "one" | "none" | "" for the note alone).
signal first_card_done(answer: String)

const MAIN_MENU := "res://scenes/main_menu.tscn"
const PANEL_W := 360.0
const MenuScript := preload("res://scripts/ui/main_menu.gd")
## The two clicks start this long after the card appears, so the question is read first.
const STIMULUS_DELAY_S := 0.6
const CLICK_GAP_S := 0.12  # TECH.md §2.3

## Tests: false = the menu is not loaded when boot is done (last_target records it).
var change_scenes := true
var last_target := ""
var stimulus_count := 0  # how many times the two clicks were played (tests)
var _answered := false


func _ready() -> void:
	I18n.apply_language(Settings.language())
	_preload_menu()
	notice.visible = false  # D-134: the note is part of the first-run card
	resized.connect(_fit_panels)
	_fit_panels()
	var first_run: bool = not Save.get_value("seen_notice", false)
	if first_run:
		Save.set_value("seen_notice", true)
		await _run_first_card(not Settings.get_value("calibrated", false))
	else:
		await get_tree().create_timer(0.1).timeout
	last_target = MAIN_MENU
	if change_scenes and is_inside_tree():
		get_tree().change_scene_to_file(MAIN_MENU)


## D-129: both cards keep 16 dp to the screen edges and the safe area (the 400 dp calibration card left
## 6 dp at 412 dp and stuck out at 360 dp); at most 360 dp wide.
func _fit_panels() -> void:
	var vp := get_viewport_rect().size
	var i := SafeArea.insets(self)
	var half := panel_half_width(vp.x, i.x, i.z)
	var shift := (i.x - i.z) * 0.5
	for p: Control in [notice, calib]:
		p.offset_left = shift - half
		p.offset_right = shift + half
	_center_card()


## The first-run card is as tall as its text at this width (large text, long languages) and sits in
## the middle of the screen; called again whenever its content changes height.
func _center_card() -> void:
	if not calib.visible:
		return
	var h := calib.get_combined_minimum_size().y
	calib.offset_top = -h * 0.5
	calib.offset_bottom = h * 0.5


static func panel_half_width(screen_w: float, inset_left: float, inset_right: float) -> float:
	return minf(PANEL_W * 0.5, (screen_w - inset_left - inset_right - 32.0) * 0.5)


## Perf pass 2026-11-08: the menu board (1080x2400 lossy WebP, ~200 ms to decode on a budget phone)
## and the menu scene load on worker threads during the boot's own wait; change_scene_to_file() and
## the menu's load() pick them up (or wait for them) instead of decoding in the first menu frame.
func _preload_menu() -> void:
	# D-105: no worker-thread texture loads headless (dummy renderer race, "Parameter t is null").
	if DisplayServer.get_name() == "headless":
		return
	var paths := [MAIN_MENU]
	var layout := MenuScript.load_layout()
	var vp := get_viewport_rect().size
	if not layout.is_empty() and vp.x > 0.0:
		var orient := MenuScript.pick_orient(vp)
		var lang := MenuScript.pick_lang(I18n.current_language(), layout.get("langs", [MenuScript.FALLBACK_LANG]))
		paths.append(MenuScript.MENU_DIR + "menu_%s_%s.webp" % [orient, lang])
	for p in paths:
		if ResourceLoader.exists(p) and not ResourceLoader.has_cached(p):
			ResourceLoader.load_threaded_request(p)
			_preloaded.append(p)


## Takes the finished background loads off the loader and keeps them alive one more second, until the
## menu (built right after this node leaves) has load()ed them from the cache and holds them itself.
func _exit_tree() -> void:
	var held: Array[Resource] = []
	for p in _preloaded:
		if ResourceLoader.load_threaded_get_status(p) == ResourceLoader.THREAD_LOAD_LOADED:
			held.append(ResourceLoader.load_threaded_get(p))
	if not held.is_empty() and is_inside_tree():
		get_tree().create_timer(1.0).timeout.connect(func() -> void: held.clear())


## D-134: the first-run card. `ask` = the haptics question (TECH.md §2.3: two `set` transients 120 ms
## apart, haptics only, as in Settings -> Haptics -> Calibration); without it (settings kept from an
## earlier install) the card is the note and a Continue plate. Returns when the player has answered.
func _run_first_card(ask: bool) -> void:
	calib_label.text = I18n.t(&"settings.haptics_calibration_two_clicks")
	calib_label.add_theme_font_size_override("font_size", UiA11y.fs(20))
	calib_two.text = "●●\n" + I18n.t(&"boot.calib_two")
	calib_one.text = "●\n" + I18n.t(&"boot.calib_one")
	calib_none.text = "○\n" + I18n.t(&"boot.calib_none")
	calib_again.text = I18n.t(&"boot.calib_again")
	calib_note.text = I18n.t(&"about.notice")
	calib_continue.text = I18n.t(&"common.continue")
	for n: Control in [calib_label, $CalibPanel/VBox/Answers, calib_again]:
		n.visible = ask
	calib_continue.visible = not ask
	# the dots carry the answer for a player who does not read; the screen reader gets the words
	for pair in [[calib_two, &"boot.calib_two"], [calib_one, &"boot.calib_one"], [calib_none, &"boot.calib_none"]]:
		if "accessibility_name" in pair[0]:
			pair[0].set("accessibility_name", I18n.t(pair[1]))
	calib_two.pressed.connect(answer.bind("two"))
	calib_one.pressed.connect(answer.bind("one"))
	calib_none.pressed.connect(answer.bind("none"))
	calib_again.pressed.connect(play_stimulus)
	calib_continue.pressed.connect(answer.bind(""))
	calib.visible = true
	calib.minimum_size_changed.connect(_center_card)
	_fit_panels()
	ScreenFrame.wire_sounds(self)
	if ask:
		get_tree().create_timer(STIMULUS_DELAY_S).timeout.connect(func() -> void:
			if not _answered:
				play_stimulus())
	await first_card_done


## The player's answer: saved, the card closes and boot goes on at once (no timer).
func answer(what: String) -> void:
	if _answered:
		return
	_answered = true
	if what != "":
		Settings.set_value("calibration", what)
		Settings.set_value("calibrated", true)
	match what:
		"two":
			Settings.set_value("haptics_intensity", 1.0)
			Settings.set_value("haptics_enabled", true)
		"one":
			Settings.set_value("haptics_intensity", 0.6)  # blurred ERM: lower tier feel
			Settings.set_value("haptics_enabled", true)
		"none":
			Settings.set_value("haptics_enabled", false)  # audio + visuals remain
	calib.visible = false
	first_card_done.emit(what)


## TECH.md §2.3: two `set` transients 120 ms apart. Haptics only: with the click sound everybody
## "hears two" and the answer says nothing about the motor.
func play_stimulus() -> void:
	stimulus_count += 1
	Haptics.play(&"set", 0.9, &"brass")
	await get_tree().create_timer(CLICK_GAP_S).timeout
	Haptics.play(&"set", 0.9, &"brass")
