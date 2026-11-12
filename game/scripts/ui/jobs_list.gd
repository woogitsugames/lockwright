extends Control
## Job list (Tryb Zleceń): all jobs from game/data/jobs/*.json, grouped by chapter.

@onready var list: VBoxContainer = $Frame/VBox/Scroll/JobsList
@onready var back_button: Button = $Frame/VBox/Header/BackButton


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
	_build_list()
	ScreenFrame.enter($Frame/VBox/Scroll)
	if _focus_button != null:
		_scroll_to_focus.call_deferred()
	ScreenFrame.wire_sounds(self)  # S05 enamel-plate sounds
	day_after = DayAfter.maybe_show(self)  # V04/D-78: one follow-up of a recently finished job
	# D-112: a content pack arrived or was removed -> the list is rebuilt; progress only updates its row
	ContentPacks.registry_changed.connect(_on_registry_changed)
	ContentPacks.state_changed.connect(_on_pack_event)
	ContentPacks.progress.connect(_on_pack_progress)
	LockPreload.release()  # perf 2026-11-08: a job left at the verify screen drops its warmed-up lock


## Fills the list: chapter headers, the jobs that can be played, and one row per chapter whose content
## pack is not on the phone (D-112).
func _build_list() -> void:
	for c in list.get_children():
		list.remove_child(c)
		c.queue_free()
	_pack_rows.clear()
	_focus_button = null
	var completed: Array = Save.get_value("jobs_completed", [])
	var refused: Array = Save.get_value("jobs_refused", [])  # N-15: refused jobs are closed
	for jid in Save.get_value("jobs_wrong_open", []):  # D-85: a wrong door opened leaves the list too,
		if not completed.has(jid):  # N-91: unless it had been settled honestly before (old saves)
			refused = refused + [jid]
	var jobs: Array = JobRun.all_jobs()  # D-112: the base game and the content packs on the phone
	for offer: Dictionary in ContentPacks.offers():  # a chapter that is not on the phone: one row to fetch it
		jobs.append({"chapter": offer["chapter"], "order": -1, "id": "", "_pack": offer["pack"]})
	jobs.sort_custom(job_before)  # D-71: chapters 1-12 in one career (7 and 8 no longer post-release)
	var shown_chapter := -1
	for job in jobs:
		if job.has("_pack"):
			var pch := int(job["chapter"])
			if pch != shown_chapter:
				shown_chapter = pch
				list.add_child(chapter_header(pch))
			var prow := pack_row(String(job["_pack"]), pch)
			_pack_rows.append(prow)
			list.add_child(prow)
			continue
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
		b.name = "Job_" + jid.trim_prefix("job.")
		if jid == last_job_id:
			_focus_button = b
		b.pressed.connect(func() -> void:
			last_job_id = jid  # N-85: coming back (pause "Exit", Back) the list opens at this job
			JobRun.start(job)
			get_tree().change_scene_to_file("res://scenes/job_arrival.tscn"))
		row.add_child(b)
		list.add_child(row)
	_update_pack_rows()


func _on_registry_changed() -> void:
	if is_inside_tree():
		_build_list()


# --- D-112: a chapter that is not on the phone -------------------------------------------
# A plain block under the chapter header (no card): what it is and how big ("6 jobs · 84,2 MB"),
# one line of advice (Wi-Fi; it stays on the phone until removed in Settings), and one plate >= 48 dp:
# Download / Stop / Try again. The tap is the consent; nothing is fetched on its own. While it
# downloads the line shows the percentage; offline or failed says so in words and keeps the plate.

var _pack_rows: Array = []


func pack_row(pack: String, ch: int) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.name = "Pack_%s_%d" % [pack, ch]
	box.set_meta(&"pack", pack)
	box.add_theme_constant_override("separation", 6)
	var info := Label.new()
	info.name = "Info"
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(info)
	var note := Label.new()
	note.name = "Note"
	note.theme_type_variation = &"Caption"
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(note)
	var action := Button.new()
	action.name = "Action"
	action.custom_minimum_size = Vector2(0, 52)
	action.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	action.mouse_filter = Control.MOUSE_FILTER_PASS
	action.pressed.connect(_on_pack_pressed.bind(pack))
	box.add_child(action)
	return box


func _update_pack_rows() -> void:
	for box: VBoxContainer in _pack_rows:
		if not is_instance_valid(box):
			continue
		var pack := String(box.get_meta(&"pack"))
		var info: Label = box.get_node("Info")
		var note: Label = box.get_node("Note")
		var action: Button = box.get_node("Action")
		var st: String = ContentPacks.state(pack)
		var size: String = ContentPacks.size_text(ContentPacks.pack_size(pack), I18n.current_language())
		info.text = I18n.t(&"pack.row.info").format({"n": ContentPacks.job_count(pack), "size": size})
		note.text = I18n.t(&"pack.row.note")
		action.visible = true
		action.disabled = false
		match st:
			"downloading":
				info.text = I18n.t(&"pack.row.downloading").format(
					{"pct": roundi(ContentPacks.progress_ratio(pack) * 100.0), "size": size})
				action.text = I18n.t(&"settings.voice_pack.stop")
			"verifying":
				info.text = I18n.t(&"pack.row.verifying")
				action.visible = false
			"failed":
				var why := "offline" if ContentPacks.last_error(pack) in ["offline", "timeout", "interrupted"] else "failed"
				note.text = I18n.t(StringName("pack.row." + why))
				action.text = I18n.t(&"settings.voice_pack.retry")
			"update":
				note.text = I18n.t(&"pack.row.update")
				action.visible = false
			_:
				action.text = I18n.t(&"settings.voice_pack.download")


func _on_pack_event(_pack: String) -> void:
	_update_pack_rows()


func _on_pack_progress(_pack: String, _received: int, _total: int) -> void:
	_update_pack_rows()


func _on_pack_pressed(pack: String) -> void:
	match ContentPacks.state(pack):
		"downloading":
			ContentPacks.cancel(pack)
		"verifying", "update", "installed", "bundled":
			pass
		_:
			ContentPacks.ensure(pack)
	_update_pack_rows()


## N-85: the job the player opened last; the list comes back scrolled to it (it used to jump to the top
## or stay wherever it was, so the next job had to be looked for again).
static var last_job_id := ""
var _focus_button: Button


func _scroll_to_focus() -> void:
	await get_tree().process_frame  # wrapped titles have their final height after one frame
	if is_instance_valid(_focus_button):
		($Frame/VBox/Scroll as ScrollContainer).ensure_control_visible(_focus_button)


func focus_button() -> Button:
	return _focus_button


## Nav (Back): the "day after" scene closes first.
func go_back() -> bool:
	if is_instance_valid(day_after) and not day_after.is_finished():
		day_after.close()
		return true
	return false
