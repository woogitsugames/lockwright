extends Control
## Job list (Tryb Zleceń): all jobs from game/data/jobs/*.json, grouped by chapter.

@onready var list: VBoxContainer = $Frame/VBox/Scroll/JobsList
@onready var back_button: Button = $Frame/VBox/Header/BackButton

const JOBS_DIR := "res://data/jobs"

var day_after: DayAfter  # V04/D-78: the "day after" scene over the list, or null


## List order: chapter as a NUMBER (T43: "10" sorted before "9" as text), then the job's "order" within the
## chapter (T43 chapters 9-12; refusals no longer jump to the top because "job.refuse_" sorts first), then id.
static func job_before(a: Dictionary, b: Dictionary) -> bool:
	var ca := int(a.get("chapter", 99))
	var cb := int(b.get("chapter", 99))
	if ca != cb:
		return ca < cb
	var oa := int(a.get("order", 0))
	var ob := int(b.get("order", 0))
	if oa != ob:
		return oa < ob
	return String(a.get("id", "")) < String(b.get("id", ""))


## D-75 (T58): chapter header above the first visible job of each chapter: "Chapter N · name" and a
## one-line description (chapter.<n>.name / chapter.<n>.desc). A chapter without a name shows only
## its number; one without a description shows no caption.
static func chapter_header(ch: int) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.name = "Chapter%d" % ch
	box.add_theme_constant_override("separation", 2)
	var name_key := StringName("chapter.%d.name" % ch)
	var title := Label.new()
	title.theme_type_variation = &"Heading"
	var air := StyleBoxEmpty.new()  # VA-05: a chapter starts with air above it, not glued to the last plate
	air.content_margin_top = 12
	title.add_theme_stylebox_override(&"normal", air)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if I18n.has_key(name_key):
		title.text = I18n.t(&"jobs.chapter_named").format([ch, I18n.t(name_key)])
	else:
		title.text = I18n.t(&"jobs.chapter").format([ch])
	box.add_child(title)
	var desc_key := StringName("chapter.%d.desc" % ch)
	if I18n.has_key(desc_key):
		var desc := Label.new()
		desc.theme_type_variation = &"Caption"
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.text = I18n.t(desc_key)
		box.add_child(desc)
	return box


func _ready() -> void:
	Sfx.play_ambience(&"stairwell")
	Sfx.play_music(&"main_theme")
	ScreenFrame.backdrop(self, "res://assets/ui/stairwell.jpg", 0.64)  # VA-05: chapter captions >= 4.5:1 over the photo
	ScreenFrame.fit(self, $Frame)  # N-53/N-59: 16 dp + safe-area, no sideways scroll
	$Frame/VBox/Scroll.scroll_deadzone = 12
	$Frame/VBox/Header/Title.text = I18n.t(&"jobs.title")
	back_button.text = "‹ " + I18n.t(&"common.back")
	back_button.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	var completed: Array = Save.get_value("jobs_completed", [])
	var refused: Array = Save.get_value("jobs_refused", [])  # N-15: refused jobs are closed
	refused = refused + Save.get_value("jobs_wrong_open", [])  # D-85: a wrong door opened leaves the list too
	var jobs: Array = []
	for path in DirAccess.get_files_at(JOBS_DIR):
		if path.ends_with(".json"):
			jobs.append(JSON.parse_string(FileAccess.get_file_as_string(JOBS_DIR + "/" + path)))
	jobs.sort_custom(job_before)  # D-71: chapters 1-12 in one career (7 and 8 no longer post-release)
	var shown_chapter := -1
	for job in jobs:
		if not JobRun.is_playable(job):
			continue  # N-05: hide jobs whose family is not implemented in lockcore
		var jid: String = job.get("id", "")
		if refused.has(jid):
			continue  # N-15: refused jobs leave the list
		var ch := int(job.get("chapter", 0))
		if ch != shown_chapter:
			shown_chapter = ch
			list.add_child(chapter_header(ch))
		var row := HBoxContainer.new()
		var b := Button.new()
		b.text = I18n.t(job.get("i18n", {}).get("title", &"jobs.title"))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART  # N-59: long titles wrap
		b.custom_minimum_size = Vector2(0, 52)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.mouse_filter = Control.MOUSE_FILTER_PASS
		if completed.has(jid):
			b.text += " — " + I18n.t(&"ui.job_done")
			b.theme_type_variation = &"DonePlate"  # VA-05: done = laid-down plate (shape + value), open = raised enamel
		b.pressed.connect(func() -> void:
			JobRun.start(job)
			get_tree().change_scene_to_file("res://scenes/job_arrival.tscn"))
		row.add_child(b)
		list.add_child(row)
	ScreenFrame.enter($Frame/VBox/Scroll)
	ScreenFrame.wire_sounds(self)  # S05 enamel-plate sounds
	day_after = DayAfter.maybe_show(self)  # V04/D-78: one follow-up of a recently finished job


## Nav (Back): the "day after" scene closes first.
func go_back() -> bool:
	if is_instance_valid(day_after) and not day_after.is_finished():
		day_after.close()
		return true
	return false
