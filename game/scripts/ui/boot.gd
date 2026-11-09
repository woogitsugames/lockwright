extends Control
## Boot: applies language, shows the one-time "this is a game, not a course" note
## on first launch (ONBOARDING §3.3), then the short first-run haptics+audio
## calibration (TECH.md §2.3), then the main menu.

var _preloaded: Array[String] = []

@onready var notice: PanelContainer = $NoticePanel
@onready var notice_label: Label = $NoticePanel/VBox/Label
@onready var calib: PanelContainer = $CalibPanel
@onready var calib_label: Label = $CalibPanel/VBox/Question
@onready var calib_two: Button = $CalibPanel/VBox/TwoButton
@onready var calib_one: Button = $CalibPanel/VBox/OneButton
@onready var calib_none: Button = $CalibPanel/VBox/NoneButton
@onready var calib_skip: Button = $CalibPanel/VBox/SkipButton


const MAIN_MENU := "res://scenes/main_menu.tscn"
const MenuScript := preload("res://scripts/ui/main_menu.gd")


func _ready() -> void:
	I18n.apply_language(Settings.language())
	_preload_menu()
	notice_label.text = I18n.t(&"about.notice")
	var first_run: bool = not Save.get_value("seen_notice", false)
	notice.visible = first_run
	if first_run:
		Save.set_value("seen_notice", true)
	await get_tree().create_timer(0.1).timeout
	if notice.visible:
		await get_tree().create_timer(3.0).timeout  # the card stays readable, never blocks
		notice.visible = false
	if first_run and not Settings.get_value("calibrated", false):
		await _run_calibration()
	get_tree().change_scene_to_file(MAIN_MENU)


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


func _run_calibration() -> void:
	# TECH.md §2.3: two `set` transients 120 ms apart + the matching sound; player answers.
	calib_label.text = I18n.t(&"boot.calib_title")
	calib_two.text = I18n.t(&"boot.calib_two")
	calib_one.text = I18n.t(&"boot.calib_one")
	calib_none.text = I18n.t(&"boot.calib_none")
	calib_skip.text = I18n.t(&"boot.calib_skip")
	calib.visible = true
	var answered := false
	var done := func(answer: String) -> void:
		if answered:
			return
		answered = true
		Settings.set_value("calibration", answer)
		Settings.set_value("calibrated", true)
		match answer:
			"two":
				Settings.set_value("haptics_intensity", 1.0)
				Settings.set_value("haptics_enabled", true)
			"one":
				Settings.set_value("haptics_intensity", 0.6)  # blurred ERM: lower tier feel
				Settings.set_value("haptics_enabled", true)
			"none":
				Settings.set_value("haptics_enabled", false)  # audio + visuals remain
		calib.visible = false
	calib_two.pressed.connect(func() -> void: done.call("two"))
	calib_one.pressed.connect(func() -> void: done.call("one"))
	calib_none.pressed.connect(func() -> void: done.call("none"))
	calib_skip.pressed.connect(func() -> void: done.call("two"))
	Haptics.play(&"set", 0.9, &"brass")
	Sfx.play(&"set", &"brass")
	await get_tree().create_timer(0.12).timeout
	Haptics.play(&"set", 0.9, &"brass")
	Sfx.play(&"set", &"brass")
	await get_tree().create_timer(6.0).timeout  # skippable by timeout too
	if not answered:
		done.call("two")
