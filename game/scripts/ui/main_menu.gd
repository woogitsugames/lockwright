extends Control
## Main menu (N-54, D-43): the workshop at night as the menu — G08 photo, Bona Nova
## title, blank G01 enamel plates as buttons. Buttons >= 48 dp; all text via i18n.

const BG_PORTRAIT := "res://assets/ui/gpt/workshop/03-workshop-evening-portrait.webp"
const BG_LANDSCAPE := "res://assets/ui/gpt/workshop/08-lamplight-evening-landscape.webp"
const CONTROL_CHOICE := "res://scenes/control_choice.tscn"

@onready var layout: BoxContainer = $Frame/Layout
@onready var play_button: Button = $Frame/Layout/MenuBlock/PlayButton
@onready var jobs_button: Button = $Frame/Layout/MenuBlock/Grid/JobsButton
@onready var workshop_button: Button = $Frame/Layout/MenuBlock/Grid/WorkshopButton
@onready var showcase_button: Button = $Frame/Layout/MenuBlock/Grid/ShowcaseButton
@onready var settings_button: Button = $Frame/Layout/MenuBlock/Grid/SettingsButton
@onready var about_button: Button = $Frame/Layout/MenuBlock/AboutButton
@onready var title_label: Label = $Frame/Layout/TitleBlock/Title
@onready var subtitle_label: Label = $Frame/Layout/TitleBlock/Subtitle
@onready var tip_label: Label = $Frame/Layout/MenuBlock/TipPanel/TipLabel
@onready var about_panel: PanelContainer = $AboutPanel
@onready var notice_label: Label = $AboutPanel/VBox/Scroll/Text/Notice

var _about_taps := 0
var _landscape := false


func _show_tip() -> void:
	# task 10: a random master's tip (contrib/gpt/T10 tips.csv -> i18n tip.* keys)
	var keys: Array = []
	for k in I18n.all_keys():
		if String(k).begins_with("tip."):
			keys.append(k)
	tip_label.text = "" if keys.is_empty() else I18n.t(keys[randi() % keys.size()])
	$Frame/Layout/MenuBlock/TipPanel.visible = tip_label.text != ""


func _ready() -> void:
	Sfx.play_ambience(&"night_timer")
	Sfx.play_music(&"main_theme")
	ScreenFrame.fit(self, $Frame, 0.0)
	_show_tip()
	_refresh_texts()
	play_button.pressed.connect(_on_play)
	jobs_button.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/jobs_list.tscn"))
	workshop_button.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/workshop.tscn"))
	showcase_button.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/showcase.tscn"))
	settings_button.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/settings.tscn"))
	about_button.pressed.connect(func() -> void: about_panel.visible = true)
	$AboutPanel/VBox/CloseButton.pressed.connect(func() -> void: about_panel.visible = false)
	notice_label.gui_input.connect(_on_about_input)  # 5 taps = dev flag "po premierze" (task 11)
	I18n.language_changed.connect(_refresh_texts)
	resized.connect(_relayout)
	_relayout()
	ScreenFrame.enter($Frame/Layout/TitleBlock)
	ScreenFrame.wire_sounds(self)  # S05 enamel-plate sounds
	ScreenFrame.enter($Frame/Layout/MenuBlock, 0.05)


func _on_play() -> void:
	# D-52: the control mode is chosen once, before the first tutorial
	if not Settings.get_value("control_chosen", false):
		get_tree().change_scene_to_file(CONTROL_CHOICE)
	elif Save.get_value("tutorial_done", false):
		get_tree().change_scene_to_file(JobRun.lock_scene_path())
	else:
		get_tree().change_scene_to_file("res://scenes/tutorial.tscn")


## Portrait: title in the top third, plates at the bottom. Landscape: side by side.
func _relayout() -> void:
	var vp := get_viewport_rect().size
	_landscape = vp.x > vp.y
	layout.vertical = not _landscape
	$Frame/Layout/TitleBlock.size_flags_stretch_ratio = 1.0 if _landscape else 0.8
	var path := BG_LANDSCAPE if _landscape else BG_PORTRAIT
	if ResourceLoader.exists(path):
		$Backdrop.texture = load(path)
	var mat := $Vignette.material as ShaderMaterial
	mat.set_shader_parameter("landscape", _landscape)
	mat.set_shader_parameter("split", 0.3 if _landscape else 0.34)
	play_button.custom_minimum_size.y = 64 if _landscape else 72
	for b in [jobs_button, workshop_button, showcase_button, settings_button]:
		b.custom_minimum_size.y = 52 if _landscape else 56
	$Frame/Layout/MenuBlock/TipPanel.visible = not _landscape and tip_label.text != ""
	# About sheet: inside the safe area, 16 dp sides, at most 560 dp wide
	var i := ScreenFrame.insets(self)
	var w := minf(560.0, vp.x - i.x - i.z - 32.0)
	var left := i.x + (vp.x - i.x - i.z - w) * 0.5
	about_panel.offset_left = left
	about_panel.offset_right = -(vp.x - left - w)
	about_panel.offset_top = i.y + 16.0
	about_panel.offset_bottom = -(i.w + 16.0)


func _on_about_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_about_taps += 1
		if _about_taps >= 5 and not Save.get_value("post_release", false):
			Save.set_value("post_release", true)  # task 11: chapter 7 unlocked
			Save.set_value("dev_mode", true)  # T03: odblokowuje język DE w ustawieniach
			notice_label.text = I18n.t(&"about.post_release_unlocked")
			_about_taps = 0


func _refresh_texts() -> void:
	title_label.text = I18n.t(&"menu.title")
	subtitle_label.text = I18n.t(&"menu.subtitle")
	play_button.text = I18n.t(&"menu.play")
	jobs_button.text = I18n.t(&"menu.jobs")
	workshop_button.text = I18n.t(&"menu.workshop")
	showcase_button.text = I18n.t(&"menu.showcase")
	settings_button.text = I18n.t(&"menu.settings")
	about_button.text = I18n.t(&"menu.about")
	$AboutPanel/VBox/AboutTitle.text = I18n.t(&"about.title")
	notice_label.text = I18n.t(&"about.notice")
	$AboutPanel/VBox/Scroll/Text/Licenses.text = I18n.t(&"about.licenses")
	$AboutPanel/VBox/CloseButton.text = I18n.t(&"common.close")
