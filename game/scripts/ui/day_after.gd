class_name DayAfter
extends Control
## V04 "day after" scene: after a finished job (opened / fixed / talked / refused), the next
## entry into the jobs list shows one short scene for one of the recently finished jobs that
## has `after` speakers and was not shown yet. Speaker portrait (gpt/cast), else an enamel
## initial plate (same fallback as job_arrival.gd), the line(s) `<job_id>.after.N` as
## subtitles only (no voice), a tap closes. Shown jobs are remembered in Save.

const JOBS_DIR := "res://data/jobs"
const Arrival := preload("res://scripts/ui/job_arrival.gd")

## Tests switch the scene change off (the GUT runner owns the scene tree).
static var change_scenes := true

var job: Dictionary = {}

@onready var title_label: Label = $Frame/VBox/Header/Title
@onready var body: VBoxContainer = $Frame/VBox/Scroll/Body
@onready var hint_label: Label = $Frame/VBox/Hint


## One finished job with unshown after-lines, or {} when there is none.
## Most recently finished first (jobs_completed / jobs_refused are append-ordered).
static func pending_job() -> Dictionary:
	var shown: Array = Save.get_value("day_after_shown", [])
	var ids: Array = Save.get_value("jobs_completed", []) + Save.get_value("jobs_refused", [])
	for i in range(ids.size() - 1, -1, -1):
		var jid := String(ids[i])
		if shown.has(jid):
			continue
		var job := job_by_id(jid)
		if (job.get("after", []) as Array).is_empty():
			continue
		if not I18n.has_key(StringName("%s.after.1" % jid)):
			continue
		return job
	return {}


static func job_by_id(jid: String) -> Dictionary:
	for path in DirAccess.get_files_at(JOBS_DIR):
		if not path.ends_with(".json"):
			continue
		var job: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(JOBS_DIR + "/" + path))
		if job.get("id", "") == jid:
			return job
	return {}


static func mark_shown(jid: String) -> void:
	var shown: Array = Save.get_value("day_after_shown", [])
	if not shown.has(jid):
		shown.append(jid)
		Save.set_value("day_after_shown", shown)


func _ready() -> void:
	if job.is_empty():
		job = pending_job()
	if job.is_empty():
		queue_free()
		return
	Sfx.play_ambience(&"stairwell")
	Sfx.play_music(&"main_theme")
	ScreenFrame.backdrop(self, "res://assets/ui/stairwell.jpg", 0.55)
	ScreenFrame.fit(self, $Frame)
	$Frame/VBox/Scroll.scroll_deadzone = 12
	title_label.text = I18n.t(job.get("i18n", {}).get("title", &"jobs.title"))
	hint_label.text = I18n.t(&"common.close")
	var after: Array = job.get("after", [])
	for i in after.size():
		body.add_child(_line_row(String(after[i]), StringName("%s.after.%d" % [job.get("id", ""), i + 1])))
	for c in get_children():
		_pass_mouse(c)
	ScreenFrame.enter($Frame/VBox)
	ScreenFrame.wire_sounds(self)
	gui_input.connect(_on_gui_input)


func _line_row(speaker: String, key: StringName) -> Control:
	var row := HBoxContainer.new()
	row.name = "Line_" + speaker
	row.set_meta("speaker", speaker)
	row.add_theme_constant_override("separation", 10)
	var name_key := StringName("cast.%s.name" % speaker)
	var full_name: String = I18n.t(name_key) if I18n.has_key(name_key) else speaker
	var avatar_tex: Texture2D = Arrival.portrait_for(speaker)
	if avatar_tex != null:
		var avatar := TextureRect.new()
		avatar.name = "Avatar"
		avatar.texture = avatar_tex
		avatar.custom_minimum_size = Vector2(48, 48)
		avatar.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		row.add_child(avatar)
	else:
		# no portrait asset: G17 enamel plate with the speaker's initial (job_arrival.gd fallback)
		var plate := Arrival.initial_plate(speaker, full_name)
		plate.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		row.add_child(plate)
	var card := PanelContainer.new()
	card.name = "Card"
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var col := VBoxContainer.new()
	col.name = "Texts"
	col.add_theme_constant_override("separation", 2)
	card.add_child(col)
	var who := ScreenFrame.wrap(Label.new())
	who.name = "Speaker"
	who.text = full_name
	who.theme_type_variation = &"Caption"
	var said := ScreenFrame.wrap(Label.new())
	said.name = "Text"
	said.text = I18n.t(key)
	col.add_child(who)
	col.add_child(said)
	row.add_child(card)
	return row


## Any tap closes the scene; the whole screen is the >= 48 dp target.
func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_close()
	elif event is InputEventScreenTouch and event.pressed:
		_close()


func _close() -> void:
	if job.is_empty():
		return
	mark_shown(String(job.get("id", "")))
	if change_scenes:
		get_tree().change_scene_to_file("res://scenes/jobs_list.tscn")


static func _pass_mouse(n: Node) -> void:
	if n is Control:
		n.mouse_filter = Control.MOUSE_FILTER_PASS
	for c in n.get_children():
		_pass_mouse(c)
