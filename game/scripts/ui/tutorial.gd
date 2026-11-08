extends Control
## Tutorial S1-S3 (ONBOARDING §4): three practice pin locks, chalk on by default (D-53).
## Stage state lives in JobRun.tutorial_stage, so returning from the lock scene
## restores it (N-09).
##
## N-61: before a stage the player sees two or three captioned frames (what each thumb does and
## what a click means) instead of an uncaptioned sketch, and "a game, not a course" as its own
## readable note under them, not printed into a drawing.

# VA-07 (D-98): photoreal close-ups of the pin cut-away (art/blender/tutorial_cards.py, same scene and
# materials as the lock screen), one per idea; no text or arrows baked in (chalk is the game's, D-83).
# stage -> [card, caption key]; card = res://assets/ui/tutorial/card_<card>.webp
const CARD_DIR := "res://assets/ui/tutorial/card_%s.webp"
const FRAMES := [
	[[&"tension", &"tutorial.frame_tension"], [&"lift", &"tutorial.frame_lift"], [&"set", &"tutorial.frame_click"]],
	[[&"binding", &"tutorial.s2_intro"]],
	[[&"overset", &"tutorial.s3_intro"]],
]
const FRAMES_AUTO_S1 := [[&"lift", &"tutorial.frame_lift_auto"], [&"set", &"tutorial.frame_click"]]
## HANDOVER §5.3: a one-pin lock (S1) has nothing to choose "sideways"; these captions say so.
const ONE_PIN_CAPTIONS := {
	&"tutorial.frame_lift": &"tutorial.frame_lift_one",
	&"tutorial.frame_lift_auto": &"tutorial.frame_lift_auto_one",
}
const CARD_W := 136.0  # VA-07: was 112x140 - the master's sketches were stamp-sized
const CARD_H := 168.0
## VA-07: the practice bench behind the cards instead of a flat brown fill (dimmed for the captions)
const BG := "res://assets/ui/gpt/workshop/03-workshop-evening-portrait.webp"

var _back: Button
var _back_space: Control


func _ready() -> void:
	Sfx.play_ambience(&"stairwell")
	$Bg.visible = false
	ScreenFrame.backdrop(self, BG, 0.72)
	SafeArea.apply(self)
	var v := $Margin/Scroll/VBox
	v.get_node("Title").text = I18n.t(&"tutorial.title")
	v.get_node("Title").theme_type_variation = &"MenuTitle"
	v.get_node("Title").add_theme_font_size_override("font_size", UiA11y.fs(30))
	v.get_node("StartButton").pressed.connect(_start_stage)
	# VA-16: "‹ Back" top-left like every other screen (run_loop.gd), outside the scroll so it is always
	# on screen; it sat under the three VA-07 cards, below the fold in portrait and in landscape
	_back = v.get_node("BackButton")
	_back.text = "‹ " + I18n.t(&"common.back")
	_back.custom_minimum_size = Vector2(112, 48)
	_back.reparent(self)
	_back.size = _back.get_combined_minimum_size()
	_back.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	_back_space = Control.new()
	_back_space.name = "BackSpace"
	_back_space.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(_back_space)
	v.move_child(_back_space, 0)
	_refresh()
	resized.connect(_relayout)
	_relayout()


func _relayout() -> void:
	# portrait: one frame per row (picture left, caption right); landscape: frames side by side
	var grid: GridContainer = $Margin/Scroll/VBox/Frames
	var landscape := size.x > size.y
	grid.columns = maxi(grid.get_child_count(), 1) if landscape else 1
	# VA-16: the back plate floats top-left; in portrait the centred two-line title starts below it,
	# in landscape the one-line title fits beside it
	var i := ScreenFrame.insets(self)
	_back.position = Vector2(i.x + ScreenFrame.SIDE, i.y + 8.0)
	_back_space.custom_minimum_size.y = 0.0 if landscape else 52.0
	# landscape (412 dp tall): smaller cards, so the note and "Start" stay above the fold too
	for row in grid.get_children():
		var pic := row.get_child(0) as Control
		pic.custom_minimum_size = Vector2(CARD_W, CARD_H) * (0.62 if landscape else 1.0)


func frame_captions() -> PackedStringArray:
	var out := PackedStringArray()
	for row in $Margin/Scroll/VBox/Frames.get_children():
		out.append((row.get_node("Caption") as Label).text)
	return out


func _add_frame(card: StringName, caption_key: StringName) -> void:
	var tex: Texture2D = load(CARD_DIR % card)
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 12)
	var pic := TextureRect.new()
	pic.name = "Card"
	pic.texture = tex
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pic.custom_minimum_size = Vector2(CARD_W, CARD_H)
	row.add_child(pic)
	var cap := Label.new()
	cap.name = "Caption"
	cap.text = I18n.t(caption_key)
	cap.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cap.custom_minimum_size = Vector2(0, 0)
	cap.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cap.add_theme_font_size_override("font_size", UiA11y.fs(19))
	cap.add_theme_color_override("font_color", Color(0.95, 0.91, 0.82))
	row.add_child(cap)
	$Margin/Scroll/VBox/Frames.add_child(row)


func _add_note() -> void:
	# "a game, not a course": a separate paper slip with dark text (contrast ≥ 4.5:1)
	var paper := PanelContainer.new()
	paper.name = "Note"
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.90, 0.86, 0.76)
	sb.set_corner_radius_all(2)
	sb.shadow_color = Color(0, 0, 0, 0.45)
	sb.shadow_size = 3
	sb.shadow_offset = Vector2(1, 2)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	paper.add_theme_stylebox_override("panel", sb)
	var l := Label.new()
	l.text = I18n.t(&"tutorial.note_game")
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_color_override("font_color", Color(0.16, 0.12, 0.08))
	l.add_theme_font_size_override("font_size", UiA11y.fs(17))
	paper.add_child(l)
	var v := $Margin/Scroll/VBox
	v.add_child(paper)
	v.move_child(paper, v.get_node("StartButton").get_index())


func _refresh() -> void:
	var stage: int = JobRun.tutorial_stage
	var done: bool = Save.get_value("tutorial_done", false)
	var v := $Margin/Scroll/VBox
	if done:
		v.get_node("Stage").text = I18n.t(&"tutorial.done")
		v.get_node("StartButton").text = I18n.t(&"common.continue")
		return
	v.get_node("Stage").text = I18n.t(&"tutorial.stage").format({"n": stage + 1})
	v.get_node("StartButton").text = I18n.t(&"tutorial.start")
	for f in frames_for(stage, bool(Settings.get_value(&"auto_tension", false))):
		_add_frame(f[0], f[1])
	if stage == 0:
		_add_note()


## Pins of the authored tutorial lock of `stage` (difficulty.n_max of data/tutorial/sN.json), 0 if unknown.
static func stage_pins(stage: int) -> int:
	if stage < 0 or stage >= JobRun.TUTORIAL_SPECS.size():
		return 0
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(JobRun.TUTORIAL_SPECS[stage]))
	if typeof(d) != TYPE_DICTIONARY:
		return 0
	return int((d as Dictionary).get("difficulty", {}).get("n_max", 0))


## [card, caption key] frames shown before `stage` (auto = automatic tension, D-52).
static func frames_for(stage: int, auto: bool) -> Array:
	var frames: Array = FRAMES[clampi(stage, 0, 2)]
	if stage == 0 and auto:
		frames = FRAMES_AUTO_S1
	if stage_pins(stage) != 1:
		return frames
	return frames.map(func(f: Array) -> Array: return [f[0], ONE_PIN_CAPTIONS.get(f[1], f[1])])


func _start_stage() -> void:
	if Save.get_value("tutorial_done", false):
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
		return
	JobRun.start_tutorial(JobRun.tutorial_stage)
	get_tree().change_scene_to_file(JobRun.lock_scene_path())
