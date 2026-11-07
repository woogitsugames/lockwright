extends Control
## Tutorial S1-S3 (ONBOARDING §4): three practice pin locks, chalk on by default (D-53).
## Stage state lives in JobRun.tutorial_stage, so returning from the lock scene
## restores it (N-09).
##
## N-61: before a stage the player sees two or three captioned frames (what each thumb does and
## what a click means) instead of an uncaptioned sketch, and "a game, not a course" as its own
## readable note under them, not printed into a drawing.

# G11 master's cards (clean variant, no baked-in text): stage -> [card number, caption key]
const FRAMES := [
	[[1, &"tutorial.frame_tension"], [3, &"tutorial.frame_lift"], [5, &"tutorial.frame_click"]],
	[[7, &"tutorial.s2_intro"]],
	[[9, &"tutorial.s3_intro"]],
]
const FRAMES_AUTO_S1 := [[3, &"tutorial.frame_lift_auto"], [5, &"tutorial.frame_click"]]
## HANDOVER §5.3: a one-pin lock (S1) has nothing to choose "sideways"; these captions say so.
const ONE_PIN_CAPTIONS := {
	&"tutorial.frame_lift": &"tutorial.frame_lift_one",
	&"tutorial.frame_lift_auto": &"tutorial.frame_lift_auto_one",
}
const CARD_W := 112.0
const CARD_H := 140.0
const CARD_CROP := Rect2(0.08, 0.14, 0.84, 0.66)  # drawing area of a 1200×1500 card (skip margins)


func _ready() -> void:
	Sfx.play_ambience(&"stairwell")
	SafeArea.apply(self)
	var v := $Margin/Scroll/VBox
	v.get_node("Title").text = I18n.t(&"tutorial.title")
	v.get_node("Title").theme_type_variation = &"MenuTitle"
	v.get_node("Title").add_theme_font_size_override("font_size", 30)
	v.get_node("StartButton").pressed.connect(_start_stage)
	v.get_node("BackButton").text = I18n.t(&"common.back")
	v.get_node("BackButton").pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	_refresh()
	resized.connect(_relayout)
	_relayout()


func _relayout() -> void:
	# portrait: one frame per row (picture left, caption right); landscape: frames side by side
	var grid: GridContainer = $Margin/Scroll/VBox/Frames
	var landscape := size.x > size.y
	grid.columns = maxi(grid.get_child_count(), 1) if landscape else 1


func frame_captions() -> PackedStringArray:
	var out := PackedStringArray()
	for row in $Margin/Scroll/VBox/Frames.get_children():
		out.append((row.get_node("Caption") as Label).text)
	return out


func _add_frame(card: int, caption_key: StringName) -> void:
	# text-free card art (the -pl/-en variants are excluded from the package, D-55/N-74)
	var tex: Texture2D = load("res://assets/ui/gpt/tutorial/g11-%02d-clean.png" % card)
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 12)
	var pic := TextureRect.new()
	if tex != null:
		var at := AtlasTexture.new()
		at.atlas = tex
		var s := Vector2(tex.get_size())
		at.region = Rect2(CARD_CROP.position * s, CARD_CROP.size * s)
		pic.texture = at
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
	cap.add_theme_font_size_override("font_size", 19)
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
	l.add_theme_font_size_override("font_size", 17)
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
