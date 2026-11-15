extends GutTest
## D-132 (VQA-19): the job list says more than a title. Each plate carries the sign of its lock family,
## a quiet line with the time of day and the place, and - once the job is settled - what it paid.
## Chapters fold. Nothing on an open plate tells a call that has to be refused from an honest one.

const PORTRAIT := Vector2i(412, 915)
const NARROW := Vector2i(360, 800)
const LANDSCAPE := Vector2i(915, 412)
const LIST := "res://scenes/jobs_list.tscn"

var _save_backup: Dictionary
var _lang := ""
var _jl: GDScript = load("res://scripts/ui/jobs_list.gd")


func before_all() -> void:
	_save_backup = Save.data.duplicate(true)
	_lang = I18n.current_language()


func before_each() -> void:
	_jl.set("chapter_open", {})
	_jl.set("last_job_id", "")
	Save.data["jobs_completed"] = []
	Save.data["jobs_refused"] = []
	Save.data["jobs_wrong_open"] = []
	Save.data["day_after"] = {}
	Save.data[DayAfter.PENDING_KEY] = []


func after_each() -> void:
	I18n.apply_language(_lang)
	_jl.set("chapter_open", {})


func after_all() -> void:
	Save.data = _save_backup
	Save.save()


func _open(size: Vector2i) -> Control:
	var vp := SubViewport.new()
	vp.size = size
	vp.disable_3d = true
	add_child_autofree(vp)
	var scene: Control = load(LIST).instantiate()
	vp.add_child(scene)
	for i in 6:
		await get_tree().process_frame
	return scene


func _all_jobs() -> Array:
	var out := []
	for f: String in preload("res://tests/job_dirs.gd").files():
		out.append(JSON.parse_string(FileAccess.get_file_as_string(f)))
	return out


func _is_refusal(job: Dictionary) -> bool:
	return String(job.get("id", "")).contains("refuse")


## The listed jobs of a chapter in list order (as the screen sorts them).
func _chapter_jobs(ch: int) -> Array:
	var jobs: Array = JobRun.all_jobs().filter(func(j: Dictionary) -> bool:
		return int(j.get("chapter", 0)) == ch and JobRun.is_playable(j))
	jobs.sort_custom(_jl.job_before)
	return jobs


# ------------------------------------------------------------------ family signs

## Where the ink of a sign falls on a coarse grid: what is left of it in a small greyscale picture.
func _cells(family: String, n := 16) -> Dictionary:
	var hit := {}
	var put := func(p: Vector2) -> void:
		hit[Vector2i(clampi(int(p.x * n), 0, n - 1), clampi(int(p.y * n), 0, n - 1))] = true
	for s: Dictionary in FamilyMark.strokes(family):
		if s.has("l") or s.has("p"):
			var pts: PackedVector2Array = s.get("l", s.get("p", PackedVector2Array()))
			var count := pts.size() if s.has("p") else pts.size() - 1
			for i in count:
				var a := pts[i]
				var b := pts[(i + 1) % pts.size()]
				for k in 41:
					put.call(a.lerp(b, k / 40.0))
		elif s.has("c") or s.has("e") or s.has("a"):
			var c: Vector2 = s.get("c", s.get("e", s.get("a", Vector2.ZERO)))
			var r: Vector2 = s["r"] if s.has("e") else Vector2(float(s["r"]), float(s["r"]))
			var from := float(s.get("f", 0.0))
			var to := float(s.get("t", TAU))
			for k in 121:
				var ang := lerpf(from, to, k / 120.0)
				put.call(c + Vector2(cos(ang) * r.x, sin(ang) * r.y))
		elif s.has("d"):
			put.call(s["d"])
	return hit


func test_every_lock_family_has_a_sign() -> void:
	var families: Array = preload("res://tests/lockcore_tiers.gd").ranges().keys()
	assert_eq(families.size(), 15, "lockcore/tiers.json lists 15 families")
	for fam: String in families:
		assert_true(FamilyMark.has_mark(fam), "%s has a sign" % fam)
		assert_true(FamilyMark.FAMILIES.has(fam), "%s is listed in FamilyMark.FAMILIES" % fam)
		assert_true(I18n.has_key(StringName("family.%s.name" % fam)), "%s has a name for the screen reader" % fam)
		for s: Dictionary in FamilyMark.strokes(fam):  # drawn inside the box
			for key in ["l", "p"]:
				for p: Vector2 in s.get(key, PackedVector2Array()):
					assert_true(p.x >= 0.0 and p.x <= 1.0 and p.y >= 0.0 and p.y <= 1.0, "%s: %s inside the box" % [fam, p])
	assert_eq(FamilyMark.FAMILIES.size(), families.size(), "no sign without a family")
	for job: Dictionary in _all_jobs():
		assert_true(FamilyMark.has_mark(String(job.get("family", ""))), "%s: its family has a sign" % job.get("id", ""))
	assert_false(FamilyMark.has_mark("no_such_family"))


func test_family_signs_differ_by_shape() -> void:
	# one ink, no colour: two signs are told apart only by where their strokes run
	var cells := {}
	for fam: String in FamilyMark.FAMILIES:
		cells[fam] = _cells(fam)
		assert_gte(cells[fam].size(), 24, "%s is more than a dot" % fam)
	for i in FamilyMark.FAMILIES.size():
		for k in range(i + 1, FamilyMark.FAMILIES.size()):
			var a: Dictionary = cells[FamilyMark.FAMILIES[i]]
			var b: Dictionary = cells[FamilyMark.FAMILIES[k]]
			var diff := 0
			for c in a:
				if not b.has(c):
					diff += 1
			for c in b:
				if not a.has(c):
					diff += 1
			var share := float(diff) / float(a.size() + b.size())
			assert_gte(share, 0.25, "%s and %s: at least a quarter of their ink lies apart (%d %%)" % [FamilyMark.FAMILIES[i], FamilyMark.FAMILIES[k], roundi(share * 100.0)])


func test_sign_is_at_least_28_dp_and_one_ink() -> void:
	var mark := FamilyMark.new("lever")
	assert_gte(mark.custom_minimum_size.x, 28.0)
	assert_gte(mark.custom_minimum_size.y, 28.0)
	assert_eq(mark.mouse_filter, Control.MOUSE_FILTER_IGNORE, "the plate under it takes the tap")
	assert_eq((mark.material as ShaderMaterial).shader, ChalkLayer.grain_material().shader, "drawn with the chalk grain (D-80)")
	mark.free()


# ------------------------------------------------------------------ what a plate says

func test_plate_has_sign_title_and_time_and_place() -> void:
	var job: Dictionary = JobRun.job_by_id("job.cat_bathroom")
	var row: Control = _jl.job_tile(job, false)
	add_child_autofree(row)
	var b: Button = row.find_child("Job_cat_bathroom", true, false)
	assert_not_null(b)
	assert_eq(b.get_parent(), row, "the plate is the row's own child")
	assert_eq((row.find_child("Title", true, false) as Label).text, I18n.t(&"job.cat_bathroom.title"))
	assert_eq((row.find_child("Meta", true, false) as Label).text,
		"%s · %s" % [I18n.t(StringName("jobs.time.%s" % job["time"])), I18n.t(StringName("jobs.place.%s" % job["place"]))])
	assert_eq((row.find_child("Mark", true, false) as FamilyMark).family, String(job["family"]))
	var said := String(b.get("accessibility_name"))
	assert_string_contains(said, I18n.t(&"job.cat_bathroom.title"))
	assert_string_contains(said, I18n.t(StringName("family.%s.name" % job["family"])), true)
	# the smaller line is the quieter one
	var title: Label = row.find_child("Title", true, false)
	var meta: Label = row.find_child("Meta", true, false)
	assert_lt(meta.get_theme_font_size(&"font_size"), title.get_theme_font_size(&"font_size"))


func test_every_time_and_place_has_a_word_in_five_languages() -> void:
	var seen := {}
	for job: Dictionary in _all_jobs():
		seen["jobs.time.%s" % job.get("time", "")] = true
		seen["jobs.place.%s" % job.get("place", "")] = true
	for lang in ["pl", "en", "de", "fr", "es"]:
		I18n.apply_language(lang)
		for key: String in seen:
			assert_true(I18n.has_key(StringName(key)), "%s (%s)" % [key, lang])
			assert_ne(I18n.t(StringName(key)), key, "%s is translated (%s)" % [key, lang])


func test_open_plate_never_shows_a_fee() -> void:
	# a call that must be refused pays nothing: a fee on open plates would mark the others as safe
	var coins_word := I18n.t(&"common.coins")
	var refusals := 0
	for job: Dictionary in _all_jobs():
		var meta: String = _jl.job_meta(job, false)
		assert_false(meta.contains(coins_word), "%s: no coins before the job is settled" % job["id"])
		for digit in "0123456789":
			assert_false(meta.contains(digit), "%s: no amount before the job is settled (%s)" % [job["id"], meta])
		var title := I18n.t(job["i18n"]["title"])
		var said: String = _jl.job_spoken(job, false)
		assert_false(said.trim_prefix(title).contains(coins_word), "%s: the screen reader says no fee either" % job["id"])
		if _is_refusal(job):
			refusals += 1
	assert_gt(refusals, 10, "the career has refusals to protect")


func test_refusal_plate_looks_like_any_other() -> void:
	# two jobs with the same family, time and place: one to refuse, one honest. Apart from the title
	# the plates are the same, node for node.
	var by_key := {}
	var pairs := 0
	for job: Dictionary in _all_jobs():
		var key := "%s/%s/%s" % [job["family"], job["time"], job["place"]]
		if not by_key.has(key):
			by_key[key] = {}
		by_key[key][_is_refusal(job)] = job
	for key: String in by_key:
		if by_key[key].size() < 2:
			continue
		pairs += 1
		var honest: Control = _jl.job_tile(by_key[key][false], false)
		var refuse: Control = _jl.job_tile(by_key[key][true], false)
		for node_name in ["Meta", "Mark", "Title"]:
			var a: Control = honest.find_child(node_name, true, false)
			var b: Control = refuse.find_child(node_name, true, false)
			assert_eq(a.visible, b.visible, "%s %s" % [key, node_name])
			assert_eq(a.theme_type_variation, b.theme_type_variation)
		assert_eq((honest.find_child("Meta", true, false) as Label).text, (refuse.find_child("Meta", true, false) as Label).text, key)
		assert_eq((honest.find_child("Mark", true, false) as FamilyMark).family, (refuse.find_child("Mark", true, false) as FamilyMark).family)
		assert_eq((honest.get_child(0) as Button).theme_type_variation, (refuse.get_child(0) as Button).theme_type_variation)
		assert_eq(honest.find_children("*", "", true, false).size(), refuse.find_children("*", "", true, false).size(), "same nodes")
		honest.free()
		refuse.free()
	assert_gt(pairs, 2, "the data has such pairs")


func test_finished_job_says_done_and_what_it_paid() -> void:
	var paid: Dictionary = JobRun.job_by_id("job.cat_bathroom")
	assert_gt(int(paid["reward_coins"]), 0)
	assert_eq(_jl.job_meta(paid, true), "%s · %s" % [I18n.t(&"ui.job_done"),
		I18n.t(&"jobs.meta.coins").format({"n": int(paid["reward_coins"])})])
	var unpaid: Dictionary = JobRun.job_by_id("job.pizzeria_pays_pizza")  # paid in pizza: no coins to show
	assert_eq(int(unpaid["reward_coins"]), 0)
	assert_eq(_jl.job_meta(unpaid, true), I18n.t(&"ui.job_done"))
	var row: Control = _jl.job_tile(paid, true)
	add_child_autofree(row)
	assert_eq((row.get_child(0) as Button).theme_type_variation, &"DonePlate", "done = the laid-down plate (VA-05)")
	assert_string_contains(String(row.get_child(0).get("accessibility_name")), I18n.t(&"ui.job_done"))


func test_refusals_in_the_list_carry_no_fee() -> void:
	_jl.set("chapter_open", {1: true, 2: true, 3: true})
	var list := await _open(PORTRAIT)
	var found := 0
	for job: Dictionary in JobRun.all_jobs():
		if not _is_refusal(job) or int(job["chapter"]) > 3:
			continue
		var b := list.find_child("Job_" + String(job["id"]).trim_prefix("job."), true, false) as Button
		assert_not_null(b, "%s is on the list" % job["id"])
		if b == null:
			continue
		found += 1
		assert_eq(b.text, "", "the plate has no text of its own")
		assert_eq((b.get_parent().find_child("Meta", true, false) as Label).text, _jl.job_meta(job, false))
		assert_ne(b.theme_type_variation, &"DonePlate")
	assert_gt(found, 1)


# ------------------------------------------------------------------ chapters fold

func _rows_visible(list: Control, ch: int) -> int:
	var n := 0
	for job: Dictionary in _chapter_jobs(ch):
		var b := list.find_child("Job_" + String(job["id"]).trim_prefix("job."), true, false) as Control
		if b != null and b.is_visible_in_tree():
			n += 1
	return n


func test_fresh_save_opens_the_first_chapter_only() -> void:
	var list := await _open(PORTRAIT)
	assert_eq(list.current_chapter(), 1)
	assert_true(list.is_chapter_open(1))
	assert_eq(_rows_visible(list, 1), _chapter_jobs(1).size(), "every job of chapter 1 is shown")
	for ch in [2, 5, 12]:
		assert_false(list.is_chapter_open(ch), "chapter %d is folded" % ch)
		assert_eq(_rows_visible(list, ch), 0)
		var header: Control = list.find_child("Chapter%d" % ch, true, false)
		assert_not_null(header, "its header stays")
		assert_true(header.is_visible_in_tree())
		assert_false((header.find_child("Desc", true, false) as Control).visible, "a folded chapter is one line")
		assert_eq((header.find_child("Count", true, false) as Label).text,
			I18n.t(&"jobs.chapter_count").format([0, _chapter_jobs(ch).size()]))
	assert_true((list.find_child("Chapter1", true, false).find_child("Desc", true, false) as Control).visible)


func test_finished_chapters_fold_and_the_current_one_opens() -> void:
	var done := []
	for ch in [1, 2]:
		for job: Dictionary in _chapter_jobs(ch):
			if _is_refusal(job):
				Save.data["jobs_refused"].append(job["id"])
			else:
				done.append(job["id"])
	Save.data["jobs_completed"] = done
	var list := await _open(PORTRAIT)
	assert_eq(list.current_chapter(), 3)
	assert_false(list.is_chapter_open(1), "a finished chapter is folded")
	assert_false(list.is_chapter_open(2))
	assert_true(list.is_chapter_open(3), "the current chapter is open")
	assert_false(list.is_chapter_open(4), "chapters further on are folded")
	assert_eq(_rows_visible(list, 1), 0)
	assert_gt(_rows_visible(list, 3), 0)
	var honest: int = _chapter_jobs(1).filter(func(j: Dictionary) -> bool: return not _is_refusal(j)).size()
	var header: Control = list.find_child("Chapter1", true, false)
	assert_eq((header.find_child("Count", true, false) as Label).text, I18n.t(&"jobs.chapter_count").format([honest, honest]),
		"the header counts the finished jobs")
	assert_string_contains((header.find_child("Title", true, false) as Label).text, I18n.t(&"chapter.1.name"))
	var said := String(header.find_child("Toggle", true, false).get("accessibility_name"))
	assert_string_contains(said, I18n.t(&"a11y.collapsed"))
	assert_string_contains(said, I18n.t(&"chapter.1.name"))


func test_tap_on_the_header_switches_and_is_remembered() -> void:
	var list := await _open(PORTRAIT)
	var toggle: Button = list.find_child("Chapter4", true, false).find_child("Toggle", true, false)
	assert_gte(toggle.size.y, 48.0, "the header is a 48 dp target")
	assert_gte(toggle.size.x, 300.0, "the whole line is the target")
	toggle.pressed.emit()
	await get_tree().process_frame
	assert_true(list.is_chapter_open(4))
	assert_eq(_rows_visible(list, 4), _chapter_jobs(4).size())
	assert_string_contains(String(toggle.get("accessibility_name")), I18n.t(&"a11y.expanded"))
	list.find_child("Chapter1", true, false).find_child("Toggle", true, false).pressed.emit()
	await get_tree().process_frame
	assert_false(list.is_chapter_open(1), "the current chapter can be folded too")
	assert_eq(_rows_visible(list, 1), 0)
	# the list is opened again (back from a job): both choices are still there
	var again := await _open(PORTRAIT)
	assert_true(again.is_chapter_open(4), "kept for the session")
	assert_false(again.is_chapter_open(1))
	assert_false(again.is_chapter_open(2), "untouched chapters keep the default")
	# a second tap folds it back
	again.find_child("Chapter4", true, false).find_child("Toggle", true, false).pressed.emit()
	await get_tree().process_frame
	assert_false(again.is_chapter_open(4))
	assert_eq(_rows_visible(again, 4), 0)


func test_chapter_of_the_last_job_is_open() -> void:
	# N-85: back from a job in a chapter that is not the current one, the list still opens at that job
	var job: Dictionary = _chapter_jobs(6)[0]
	_jl.set("last_job_id", job["id"])
	var list := await _open(PORTRAIT)
	assert_true(list.is_chapter_open(6))
	assert_true(list.is_chapter_open(1), "next to the current chapter")
	var b: Button = list.focus_button()
	assert_not_null(b)
	assert_true(b.is_visible_in_tree())
	assert_true((list.get_node("Frame/VBox/Scroll") as Control).get_global_rect().encloses(b.get_global_rect()), "and it is in view")


func test_download_row_folds_with_its_chapter() -> void:
	# D-112 / D-131: a chapter that is not on the phone is a header and a row; the row folds like plates
	var list := await _open(PORTRAIT)
	var jobs: VBoxContainer = list.get_node("Frame/VBox/Scroll/JobsList")
	var ch := 77
	var header: Control = _jl.chapter_header(ch)
	var row: Control = list.pack_row("demo", ch)
	jobs.add_child(header)
	jobs.add_child(row)
	list._chapter_headers[ch] = header
	list._chapter_rows[ch] = [row]
	assert_false((header.find_child("Count", true, false) as Control).visible, "no count for a chapter not on the phone")
	list.set_chapter_open(ch, false)
	assert_false(row.visible)
	list.set_chapter_open(ch, true)
	assert_true(row.visible)
	assert_not_null(row.get_node("Action"), "its Download plate is where it was")
	assert_gte((row.get_node("Action") as Button).custom_minimum_size.y, 48.0)


# ------------------------------------------------------------------ layout

func _check_layout(list: Control, tag: String) -> void:
	var scroll: ScrollContainer = list.get_node("Frame/VBox/Scroll")
	var jobs: VBoxContainer = list.get_node("Frame/VBox/Scroll/JobsList")
	assert_lte(jobs.size.x, scroll.size.x + 0.5, "%s: no sideways scroll" % tag)
	var plates := 0
	for n in jobs.find_children("Job_*", "Button", true, false):
		var b := n as Button
		if not b.is_visible_in_tree():
			continue
		plates += 1
		var row: Control = b.get_parent()
		var plate := b.get_global_rect().grow(0.5)
		assert_gte(b.size.y, 48.0, "%s %s: 48 dp target" % [tag, b.name])
		var title: Label = row.find_child("Title", true, false)
		var meta: Label = row.find_child("Meta", true, false)
		var mark: Control = row.find_child("Mark", true, false)
		for l: Label in [title, meta]:
			assert_eq(l.get_visible_line_count(), l.get_line_count(), "%s %s: %s not cut" % [tag, b.name, l.name])
			assert_true(plate.encloses(l.get_global_rect()), "%s %s: %s on the plate (%s in %s)" % [tag, b.name, l.name, l.get_global_rect(), plate])
			assert_gte(l.size.x, 120.0, "%s %s: %s has room to read" % [tag, b.name, l.name])
		assert_true(plate.encloses(mark.get_global_rect()), "%s %s: sign on the plate" % [tag, b.name])
		assert_gte(minf(mark.size.x, mark.size.y), 28.0, "%s %s: sign >= 28 dp" % [tag, b.name])
		assert_lte(meta.get_global_rect().position.y + 0.5, plate.end.y)
		assert_gte(meta.get_global_rect().position.y, title.get_global_rect().end.y - 0.5, "%s %s: title first, then the quiet line" % [tag, b.name])
	assert_gt(plates, 3, "%s: plates are shown" % tag)
	for n in jobs.find_children("Chapter*", "VBoxContainer", false, false):
		var toggle: Button = n.find_child("Toggle", true, false)
		var title: Label = n.find_child("Title", true, false)
		assert_gte(toggle.size.y, 48.0, "%s %s" % [tag, n.name])
		assert_eq(title.get_visible_line_count(), title.get_line_count(), "%s %s: name not cut" % [tag, n.name])
		assert_true(toggle.get_global_rect().grow(0.5).encloses(title.get_global_rect()), "%s %s: name inside its target" % [tag, n.name])


func test_layout_at_100_percent() -> void:
	Save.data["jobs_completed"] = [_chapter_jobs(1)[0]["id"], _chapter_jobs(1)[1]["id"]]
	_jl.set("chapter_open", {1: true, 9: true})
	for lang in ["pl", "de"]:
		I18n.apply_language(lang)
		for size: Vector2i in [PORTRAIT, NARROW, LANDSCAPE]:
			var list := await _open(size)
			_check_layout(list, "%s %s 100%%" % [size, lang])
			list.get_parent().queue_free()
			await get_tree().process_frame


func test_layout_at_200_percent() -> void:
	var before_sys: Variant = Settings.get_value("text_scale_system", true)
	var before: Variant = Settings.get_value("text_scale", 1.0)
	Settings._cfg["text_scale_system"] = false
	Settings._cfg["text_scale"] = 2.0
	UiA11y._apply_text_scale()
	Save.data["jobs_completed"] = [_chapter_jobs(1)[0]["id"], _chapter_jobs(1)[1]["id"]]
	_jl.set("chapter_open", {1: true, 9: true})
	for lang in ["pl", "de"]:
		I18n.apply_language(lang)
		for size: Vector2i in [PORTRAIT, NARROW, LANDSCAPE]:
			var list := await _open(size)
			_check_layout(list, "%s %s 200%%" % [size, lang])
			var mark: Control = list.find_child("Mark", true, false)
			assert_gt(mark.size.x, FamilyMark.SIZE_DP, "the sign grows with the text")
			list.get_parent().queue_free()
			await get_tree().process_frame
	Settings._cfg["text_scale_system"] = before_sys
	Settings._cfg["text_scale"] = before
	UiA11y._apply_text_scale()
