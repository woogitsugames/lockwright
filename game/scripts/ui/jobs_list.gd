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


## D-75 (T58): chapter header above the jobs of each chapter: "Chapter N · name" and a one-line
## description (chapter.<n>.name / chapter.<n>.desc). A chapter without a name shows only its number;
## one without a description shows no caption.
## D-132: the header is also the switch that folds the chapter (>= 48 dp, the whole line is the target):
## a drawn chevron (right = folded, down = open), the name, and "done of all" on the right when
## `total` > 0. The description shows only while the chapter is open. Nodes: Head/Toggle (the button),
## Title, Count, Chevron, Desc.
static func chapter_header(ch: int, done := 0, total := 0) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.name = "Chapter%d" % ch
	box.add_theme_constant_override("separation", 0)
	var head := MarginContainer.new()
	head.name = "Head"
	head.add_theme_constant_override("margin_top", 6)  # VA-05: a chapter starts with air above it
	box.add_child(head)
	var toggle := Button.new()
	toggle.name = "Toggle"
	toggle.theme_type_variation = &"LinkButtonDark"
	toggle.custom_minimum_size = Vector2(0, 48)
	toggle.mouse_filter = Control.MOUSE_FILTER_PASS
	head.add_child(toggle)
	var pad := MarginContainer.new()
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side in ["margin_top", "margin_bottom"]:
		pad.add_theme_constant_override(side, 6)
	pad.add_theme_constant_override("margin_right", 4)
	head.add_child(pad)
	var line := HBoxContainer.new()
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_theme_constant_override("separation", 8)
	pad.add_child(line)
	var chevron := Control.new()
	chevron.name = "Chevron"
	chevron.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var k := FamilyMark.side_dp() / FamilyMark.SIZE_DP  # grows with the text, like the signs
	chevron.custom_minimum_size = Vector2(18, 28) * k
	chevron.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	chevron.draw.connect(func() -> void:
		var c := chevron.size * 0.5
		var open: bool = chevron.get_meta(&"open", true)
		var pts := PackedVector2Array([c + Vector2(-6, -3) * k, c + Vector2(0, 4) * k, c + Vector2(6, -3) * k]) if open \
				else PackedVector2Array([c + Vector2(-3, -6) * k, c + Vector2(4, 0) * k, c + Vector2(-3, 6) * k])
		chevron.draw_polyline(pts, Color(0.83, 0.67, 0.37), 2.0 * k, true)
		for p in pts:
			chevron.draw_circle(p, k, Color(0.83, 0.67, 0.37)))
	line.add_child(chevron)
	var name_key := StringName("chapter.%d.name" % ch)
	var names := VBoxContainer.new()
	names.mouse_filter = Control.MOUSE_FILTER_IGNORE
	names.add_theme_constant_override("separation", 0)
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	names.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	line.add_child(names)
	var title := Label.new()
	title.name = "Title"
	title.theme_type_variation = &"Heading"
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if I18n.has_key(name_key):
		title.text = I18n.t(&"jobs.chapter_named").format([ch, I18n.t(name_key)])
	else:
		title.text = I18n.t(&"jobs.chapter").format([ch])
	names.add_child(title)
	var count := Label.new()
	count.name = "Count"
	count.theme_type_variation = &"Caption"
	count.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	count.text = I18n.t(&"jobs.chapter_count").format([done, total]) if total > 0 else ""
	count.visible = total > 0
	# from 150 % text the count goes under the name: beside it the name broke into three lines
	(names if UiA11y.text_scale() >= 1.5 else line).add_child(count)
	var desc_key := StringName("chapter.%d.desc" % ch)
	if I18n.has_key(desc_key):
		var desc := Label.new()
		desc.name = "Desc"
		desc.theme_type_variation = &"Caption"
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.text = I18n.t(desc_key)
		var under := StyleBoxEmpty.new()  # under the name, in line with it (past the chevron)
		under.content_margin_left = 18 * k + 8
		under.content_margin_bottom = 4
		desc.add_theme_stylebox_override(&"normal", under)
		box.add_child(desc)
	set_header_open(box, true)
	return box


## Shows a chapter header as open or folded: chevron, description, and what a screen reader says.
static func set_header_open(box: Control, open: bool) -> void:
	box.set_meta(&"open", open)
	var chevron: Control = box.find_child("Chevron", true, false)
	chevron.set_meta(&"open", open)
	chevron.queue_redraw()
	var desc := box.find_child("Desc", true, false) as Control
	if desc != null:
		desc.visible = open
	var toggle: Button = box.find_child("Toggle", true, false)
	var said := (box.find_child("Title", true, false) as Label).text
	var count: Label = box.find_child("Count", true, false)
	if count.text != "":
		said += ", " + count.text
	said += ", " + I18n.t(&"a11y.expanded" if open else &"a11y.collapsed")
	if "accessibility_name" in toggle:
		toggle.set("accessibility_name", said)


# --- D-132 (VQA-19): what a job plate says ---------------------------------------------------
# Sign of the lock family (FamilyMark), the title, and one quiet line under it: time of day and
# place ("evening · stairwell"). A finished job says "done" and what it paid instead.
#
# No fee on a job that is still open: a call that has to be refused pays nothing (reward_coins 0),
# so a fee on the open plates would tell which calls to refuse before the papers are checked.
# The data has no "what the client offers" either, so nothing is shown until the job is settled.

const INK := Color(0.11, 0.09, 0.07)
const INK_QUIET := Color(0.29, 0.24, 0.18)  # the second line on enamel: 8:1 on the plate, quieter than the title
const CHALK := Color(0.96, 0.95, 0.90)


## "evening · stairwell" for an open job, "done · 105 coins" for a finished one. Values the game has
## no word for (a content pack with a new place) are left out.
static func job_meta(job: Dictionary, done: bool) -> String:
	var parts := PackedStringArray()
	if done:
		parts.append(I18n.t(&"ui.job_done"))
		var coins := int(job.get("reward_coins", 0))
		if coins > 0:
			parts.append(I18n.t(&"jobs.meta.coins").format({"n": coins}))
		return " · ".join(parts)
	for key in ["jobs.time.%s" % job.get("time", ""), "jobs.place.%s" % job.get("place", "")]:
		if I18n.has_key(StringName(key)):
			parts.append(I18n.t(StringName(key)))
	return " · ".join(parts)


## What a screen reader says for a plate: title, lock family by name, then the line under the title.
static func job_spoken(job: Dictionary, done: bool) -> String:
	var parts := PackedStringArray([I18n.t(job.get("i18n", {}).get("title", &"jobs.title"))])
	var fam_key := StringName("family.%s.name" % job.get("family", ""))
	if I18n.has_key(fam_key):
		parts.append(I18n.t(fam_key))
	var meta := job_meta(job, done)
	if meta != "":
		parts.append(meta)
	return ". ".join(parts)


## A title never breaks inside a word (D-129 rule for large text): when its longest word is wider than
## the line, the title's font steps down from the plate size until the word fits, to 60 % of it at most.
static func fit_words(label: Label) -> void:
	var w := label.size.x
	if w <= 1.0 or is_equal_approx(w, float(label.get_meta(&"fit_w", -1.0))):
		return
	label.set_meta(&"fit_w", w)
	var font := label.get_theme_font(&"font")
	var full := label.get_theme_font_size(&"font_size", &"Button")  # a plate's title is plate text (18 at 100 %)
	var fs := full
	while fs > ceili(full * 0.6):
		var longest := 0.0
		for word in label.text.split(" ", false):
			longest = maxf(longest, font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x)
		if longest <= w:
			break
		fs -= 1
	label.add_theme_font_size_override(&"font_size", fs)


## One job: a row (direct child of the list) with the plate button `Job_<id>` under the drawn content.
## The button has no text of its own; Title / Meta / Mark are its content.
## D-136: `fill` false makes the row and its plate only; fill_tile() adds the content when the row is
## first shown. The list builds the plates of folded chapters that way: ~110 of 123 plates are
## folded in a career, and their signs, titles and lines (6 of 8 nodes per plate) were built, themed
## and laid out on every visit of the list without ever being seen.
static func job_tile(job: Dictionary, done: bool, fill := true) -> MarginContainer:
	var jid: String = job.get("id", "")
	var row := MarginContainer.new()
	row.name = "Row_" + jid.trim_prefix("job.")
	var b := Button.new()
	b.name = "Job_" + jid.trim_prefix("job.")
	b.custom_minimum_size = Vector2(0, 56)
	b.mouse_filter = Control.MOUSE_FILTER_PASS
	if done:
		b.theme_type_variation = &"DonePlate"  # VA-05: done = laid-down plate (shape + value), open = raised enamel
	if "accessibility_name" in b:
		b.set("accessibility_name", job_spoken(job, done))
	row.add_child(b)
	row.set_meta(&"job", job)
	row.set_meta(&"done", done)
	if fill:
		fill_tile(row)
	return row


## Adds the drawn content (sign, title, quiet line) to a plate made by job_tile(); once per plate.
static func fill_tile(row: Control) -> void:
	if not row.has_meta(&"job") or row.has_node("Content"):
		return
	var job: Dictionary = row.get_meta(&"job")
	var done: bool = row.get_meta(&"done", false)
	var pad := MarginContainer.new()
	pad.name = "Content"
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pad.add_theme_constant_override("margin_left", 12)
	pad.add_theme_constant_override("margin_right", 14)
	pad.add_theme_constant_override("margin_top", 8)
	pad.add_theme_constant_override("margin_bottom", 10)
	row.add_child(pad)
	var line := HBoxContainer.new()
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_theme_constant_override("separation", 12)
	pad.add_child(line)
	var mark := FamilyMark.new(String(job.get("family", "")), CHALK if done else INK)
	mark.name = "Mark"
	mark.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	line.add_child(mark)
	var text := VBoxContainer.new()
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text.add_theme_constant_override("separation", 0)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.alignment = BoxContainer.ALIGNMENT_CENTER
	line.add_child(text)
	var title := Label.new()
	title.name = "Title"
	if not done:
		title.theme_type_variation = &"OnEnamel"
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART  # N-59: long titles wrap
	title.text = I18n.t(job.get("i18n", {}).get("title", &"jobs.title"))
	title.resized.connect(func() -> void: fit_words(title))
	text.add_child(title)
	var meta := Label.new()
	meta.name = "Meta"
	meta.theme_type_variation = &"Caption"
	meta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	meta.text = job_meta(job, done)
	meta.visible = meta.text != ""
	if not done:
		meta.add_theme_color_override(&"font_color", INK_QUIET)
		meta.add_theme_color_override(&"font_shadow_color", Color(0, 0, 0, 0))
	text.add_child(meta)


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


# --- D-132: chapters fold ----------------------------------------------------------------------
# A chapter with nothing left to do is folded; so is a chapter further on. Open is the current
# chapter: the first one with a job to do or a download row, and the chapter of the job the player
# opened last (N-85). A tap on the header switches it; the choice is kept until the game is closed
# (session only, not saved).

## chapter -> bool: headers the player switched by hand in this session.
static var chapter_open := {}

var _chapter_rows := {}     # chapter -> Array[Control]: its plates and download rows
var _chapter_headers := {}  # chapter -> VBoxContainer
var _current_chapter := -1


func is_chapter_open(ch: int) -> bool:
	return bool(_chapter_headers[ch].get_meta(&"open", true)) if _chapter_headers.has(ch) else false


func current_chapter() -> int:
	return _current_chapter


func set_chapter_open(ch: int, open: bool, remember := true) -> void:
	if not _chapter_headers.has(ch):
		return
	if remember:
		chapter_open[ch] = open
	set_header_open(_chapter_headers[ch], open)
	for row: Control in _chapter_rows.get(ch, []):
		if open:
			fill_tile(row)  # D-136: a plate gets its content when its chapter is first opened
		row.visible = open
		if open and remember and not UiA11y.reduce_motion():
			row.modulate.a = 0.0
			row.create_tween().tween_property(row, "modulate:a", 1.0, 0.15)


## Fills the list: chapter headers, the jobs that can be played, and one row per chapter whose content
## pack is not on the phone (D-112).
func _build_list() -> void:
	# D-136: the list is filled outside the tree and put back whole. Added one by one to a live
	# container, each of the ~250 rows and headers entered the tree, took its theme and pushed a new
	# minimum size up through the scroll area on its own: over half of the time the list took to open.
	var holder := list.get_parent()
	var at := list.get_index() if holder != null else -1
	if holder != null:
		holder.remove_child(list)
	_fill_list()
	if holder != null:
		holder.add_child(list)
		holder.move_child(list, at)


func _fill_list() -> void:
	for c in list.get_children():
		list.remove_child(c)
		c.queue_free()
	_pack_rows.clear()
	_chapter_rows.clear()
	_chapter_headers.clear()
	_current_chapter = -1
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
	# what each chapter holds, in list order
	var chapters := []      # chapter numbers in order
	var shown := {}         # chapter -> Array of jobs / pack entries that get a row
	var done_count := {}
	var job_count := {}
	var focus_chapter := -1
	for job: Dictionary in jobs:
		var ch := int(job.get("chapter", 0))
		var jid: String = job.get("id", "")
		if not job.has("_pack"):
			if not JobRun.is_playable(job):
				continue  # N-05: hide jobs whose family is not implemented in lockcore
			if refused.has(jid):
				continue  # N-15: refused jobs leave the list
			job_count[ch] = int(job_count.get(ch, 0)) + 1
			if completed.has(jid):
				done_count[ch] = int(done_count.get(ch, 0)) + 1
			elif _current_chapter < 0:
				_current_chapter = ch
			if jid == last_job_id:
				focus_chapter = ch
		elif _current_chapter < 0:
			_current_chapter = ch
		if not shown.has(ch):
			shown[ch] = []
			chapters.append(ch)
		shown[ch].append(job)
	for ch: int in chapters:
		var header := chapter_header(ch, int(done_count.get(ch, 0)), int(job_count.get(ch, 0)))
		(header.find_child("Toggle", true, false) as Button).pressed.connect(
			func() -> void: set_chapter_open(ch, not is_chapter_open(ch)))
		_chapter_headers[ch] = header
		_chapter_rows[ch] = []
		list.add_child(header)
		var open_now := bool(chapter_open.get(ch, ch == _current_chapter or ch == focus_chapter))
		for job: Dictionary in shown[ch]:
			var row: Control
			if job.has("_pack"):
				row = pack_row(String(job["_pack"]), ch)
				_pack_rows.append(row)
			else:
				var jid: String = job.get("id", "")
				row = job_tile(job, completed.has(jid), open_now)
				var b: Button = row.get_child(0)
				if jid == last_job_id:
					_focus_button = b
				b.pressed.connect(func() -> void:
					last_job_id = jid  # N-85: coming back (pause "Exit", Back) the list opens at this job
					JobRun.start(job)
					get_tree().change_scene_to_file("res://scenes/job_arrival.tscn"))
			_chapter_rows[ch].append(row)
			list.add_child(row)
		set_chapter_open(ch, open_now, false)
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
