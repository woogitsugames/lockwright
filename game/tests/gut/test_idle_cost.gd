extends GutTest
## D-136: what a screen costs when nothing happens, and what the job list costs to open.
##  - a menu screen that just sits there runs no script per frame (no _process / _physics_process);
##  - the family signs on the job plates (D-132) are drawn once, when they appear, not per frame;
##  - the job list builds content only for the plates of open chapters;
##  - autoloads that have nothing to do do not process.

const JobsList := preload("res://scripts/ui/jobs_list.gd")
## Screens with nothing animated: nothing in them may process once they are up.
const STILL_SCREENS := ["res://scenes/jobs_list.tscn", "res://scenes/workshop.tscn", "res://scenes/showcase.tscn",
	"res://scenes/settings.tscn", "res://scenes/main_menu.tscn"]

var _save_backup := {}
var _open_backup := {}


func before_each() -> void:
	_save_backup = Save.data.duplicate(true)
	_open_backup = (JobsList.chapter_open as Dictionary).duplicate()
	JobsList.chapter_open = {}
	Save.data["tutorial_done"] = true
	Save.data.erase("day_after")


func after_each() -> void:
	Save.data = _save_backup
	JobsList.chapter_open = _open_backup


func _open(path: String) -> Node:
	var scene: Node = load(path).instantiate()
	add_child_autofree(scene)
	for i in 4:
		await get_tree().process_frame
	return scene


func _processing(n: Node, out: PackedStringArray) -> void:
	if n.is_processing() or n.is_physics_processing():
		out.append("%s (%s)" % [n.name, n.get_class()])
	for ch in n.get_children(true):
		_processing(ch, out)


func _count(n: Node) -> int:
	var c := 1
	for ch in n.get_children(true):
		c += _count(ch)
	return c


func test_still_screens_run_no_script_per_frame() -> void:
	for path: String in STILL_SCREENS:
		var scene := await _open(path)
		var busy: PackedStringArray = []
		_processing(scene, busy)
		assert_eq(busy, PackedStringArray(), "%s: nodes with a per-frame callback while nothing happens" % path.get_file())
		scene.queue_free()
		await get_tree().process_frame


func test_family_signs_are_drawn_once_not_per_frame() -> void:
	var list := await _open("res://scenes/jobs_list.tscn")
	var marks := list.find_children("Mark", "", true, false)
	assert_gt(marks.size(), 3, "the open chapter shows signs")
	for i in 6:
		await get_tree().process_frame
	var drawn := FamilyMark.draws
	for i in 30:
		await get_tree().process_frame
	assert_eq(FamilyMark.draws, drawn, "30 idle frames: no sign was drawn again")
	# setting the same family / ink again is not a reason to redraw either
	var mark: FamilyMark = marks[0]
	mark.family = mark.family
	mark.ink = mark.ink
	for i in 3:
		await get_tree().process_frame
	assert_eq(FamilyMark.draws, drawn, "unchanged sign: not queued for drawing")
	mark.ink = Color(0.5, 0.5, 0.5)
	for i in 3:
		await get_tree().process_frame
	assert_eq(FamilyMark.draws, drawn + 1, "a changed sign is drawn once")


func test_job_list_builds_content_only_for_open_chapters() -> void:
	var list := await _open("res://scenes/jobs_list.tscn")
	var jobs: VBoxContainer = list.get_node("Frame/VBox/Scroll/JobsList")
	var plates := jobs.find_children("Job_*", "Button", true, false)
	assert_gt(plates.size(), 100, "every job still has its plate (the list's structure is unchanged)")
	var filled := 0
	var hidden_filled := 0
	for b: Button in plates:
		var row := b.get_parent()
		if row.has_node("Content"):
			filled += 1
			if not row.visible:
				hidden_filled += 1
		else:
			assert_false(row.visible, "%s: a shown plate always has its content" % b.name)
	assert_eq(hidden_filled, 0, "plates of folded chapters carry no sign / title / line yet")
	assert_lt(filled, plates.size() / 2, "a fresh career shows one chapter")
	var nodes := _count(list)
	gut.p("job list: %d plates, %d with content, %d nodes" % [plates.size(), filled, nodes])
	assert_lt(nodes, 700, "was 1159 nodes with every plate filled (D-132); the first visit laid all of them out")


func test_opening_a_chapter_fills_its_plates_once() -> void:
	var list := await _open("res://scenes/jobs_list.tscn")
	var folded := -1
	for ch: int in list._chapter_rows:
		if not list.is_chapter_open(ch) and not (list._chapter_rows[ch] as Array).is_empty() \
				and (list._chapter_rows[ch][0] as Control).has_meta(&"job"):
			folded = ch
			break
	assert_gt(folded, 0, "a folded chapter with jobs exists")
	var row: Control = list._chapter_rows[folded][0]
	assert_false(row.has_node("Content"))
	(list._chapter_headers[folded].find_child("Toggle", true, false) as Button).pressed.emit()
	await get_tree().process_frame
	assert_true(row.visible)
	assert_true(row.has_node("Content"), "opened: sign, title and line are there")
	var job: Dictionary = row.get_meta(&"job")
	assert_eq((row.find_child("Title", true, false) as Label).text, I18n.t(job["i18n"]["title"]))
	assert_eq((row.find_child("Mark", true, false) as FamilyMark).family, String(job["family"]))
	var content := row.get_node("Content")
	list.set_chapter_open(folded, false)
	list.set_chapter_open(folded, true)
	assert_eq(row.get_node("Content"), content, "folding and opening again does not build it twice")
	assert_eq(row.find_children("Title", "", true, false).size(), 1)


func test_a_lazily_filled_plate_is_the_same_as_a_plate_built_whole() -> void:
	var job := JobRun.job_by_id("job.cat_bathroom")
	for done: bool in [false, true]:
		var whole: Control = JobsList.job_tile(job, done)
		var lazy: Control = JobsList.job_tile(job, done, false)
		add_child_autofree(whole)
		add_child_autofree(lazy)
		assert_eq(lazy.get_child_count(), 1, "plate only")
		assert_eq(String(lazy.get_child(0).name), String(whole.get_child(0).name))
		JobsList.fill_tile(lazy)
		JobsList.fill_tile(lazy)
		var a := whole.find_children("*", "", true, false)
		var b := lazy.find_children("*", "", true, false)
		assert_eq(b.size(), a.size(), "same nodes")
		for i in a.size():
			if not String(a[i].name).begins_with("@"):  # unnamed nodes get a running number
				assert_eq(String(b[i].name), String(a[i].name))
			assert_eq(b[i].get_class(), a[i].get_class())
		assert_eq((lazy.find_child("Title", true, false) as Label).text, (whole.find_child("Title", true, false) as Label).text)
		assert_eq((lazy.find_child("Meta", true, false) as Label).text, (whole.find_child("Meta", true, false) as Label).text)
		assert_eq((lazy.find_child("Mark", true, false) as FamilyMark).ink, (whole.find_child("Mark", true, false) as FamilyMark).ink)


func test_idle_autoloads_do_not_process() -> void:
	# nothing downloading, clicks warmed up: these have no per-frame work
	var t0 := Time.get_ticks_msec()
	while Sfx.warming_up() and Time.get_ticks_msec() - t0 < 10000:
		await get_tree().process_frame
	for name: String in ["VoicePacks", "ContentPacks", "Sfx", "Save", "Settings", "Events", "Achievements", "Nav", "I18n"]:
		var n := get_tree().root.get_node(name)
		assert_false(n.is_processing(), "%s has no per-frame work when idle" % name)
		assert_false(n.is_physics_processing(), "%s: no physics callback" % name)


## Opening the job list (the screen the player returns to after every job): a generous bound that
## still fails if every visit goes back to building and laying out a thousand nodes, or to anything
## quadratic. Headless desktop: ~40 ms for _ready (median of 5).
func test_job_list_opens_within_budget() -> void:
	var packed: PackedScene = load("res://scenes/jobs_list.tscn")
	var times: Array[float] = []
	for i in 5:
		var t0 := Time.get_ticks_usec()
		var scene: Node = packed.instantiate()
		add_child(scene)
		times.append((Time.get_ticks_usec() - t0) / 1000.0)
		await get_tree().process_frame
		scene.queue_free()
		await get_tree().process_frame
	times.sort()
	gut.p("job list instantiate + _ready ms (sorted): %s" % str(times))
	assert_lt(times[2], 400.0, "median of 5")
