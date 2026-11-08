extends Node
## Screenshot runner (task 13): walks all main screens at a given resolution and
## saves PNGs. Run under xvfb with opengl3:
##   xvfb-run godot --path game --display-driver x11 --rendering-driver opengl3 res://tests/screens.tscn -- --out /tmp/shots --size 412x915
const SCREENS := ["res://scenes/main_menu.tscn", "res://scenes/jobs_list.tscn", "res://scenes/workshop.tscn", "res://scenes/showcase.tscn", "res://scenes/settings.tscn", "res://scenes/control_choice.tscn", "res://scenes/job_arrival.tscn", "res://scenes/day_after.tscn", "res://scenes/lock.tscn",
	"res://scenes/workshop.tscn#practice", "res://scenes/lock_job.tscn#practice",
	"res://scenes/job_verify.tscn#wrong_floor", "res://scenes/job_verify.tscn#kiosk", "res://scenes/lock_job.tscn#pause",
	"res://scenes/job_verify.tscn#broth", "res://scenes/job_verify.tscn#bike", "res://scenes/job_verify.tscn#heirs",
	"res://scenes/job_verify.tscn#nurse", "res://scenes/job_verify.tscn#newlyweds"]
## D-79: the Ćwiczenia tab and one practice lock (goal in chalk), with the tutorial done in memory only
const PRACTICE_LOCK := "t20"
## job shown on the arrival screen (N-60: portrait + locksmith line)
const ARRIVAL_JOB := "job.bike_interview"
## N-76: verification (one card + "I need one more thing"; three cards, two shown first)
## N-80/N-81: paper props drawn in the game (witness, photo, receipt, deed, inheritance) over the arrival landing
const VERIFY_JOBS := {"wrong_floor": "job.wrong_floor", "kiosk": "job.kiosk_shutter", "broth": "job.grandma_broth",
	"bike": "job.bike_interview", "heirs": "job.uncle_safe_heirs", "nurse": "job.night_nurse",
	"newlyweds": "job.newlyweds_4am"}
## V04/D-78: "day after" scene, shown over the job list (one line, main-cast portrait)
const DAY_AFTER_JOB := "job.cat_bathroom"

var _out := "/tmp/shots"
var _size := Vector2i(412, 915)
var _shown: Node = null
var _demo := false  # --demo-save: fresh-ish save (few coins, a worn tool) to show the N-59 row states
var _only := ""  # --only=main_menu,settings: render a subset


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			_out = a.trim_prefix("--out=")
		elif a.begins_with("--size="):
			var p := a.trim_prefix("--size=").split("x")
			_size = Vector2i(int(p[0]), int(p[1]))
		elif a.begins_with("--only="):
			_only = a.trim_prefix("--only=")
		elif a.begins_with("--lang="):
			I18n.apply_language(a.trim_prefix("--lang="))
		elif a == "--demo-save":
			_demo = true
	DirAccess.make_dir_recursive_absolute(_out)
	var backup: Dictionary = Save.data.duplicate(true)
	if _demo:
		Save.set_value("coins", 200)
		Save.set_value("tools/pk_hook/owned", true)
		Save.set_value("tools/pk_hook/integrity", 40)
		Save.set_value("tools/pk_ward/owned", false)
		Save.set_value("tools/tw_bar/owned", false)
		Save.set_value("tools/tl_shackle/owned", false)
	get_window().size = _size
	await get_tree().process_frame
	for entry: String in SCREENS:
		var scene_path := entry.get_slice("#", 0)
		var tag := entry.get_slice("#", 1) if entry.contains("#") else ""
		var base: String = scene_path.get_file().get_basename() + ("_" + tag if tag != "" else "")
		if _only != "" and not (base in _only.split(",")):
			continue
		if base == "job_arrival":
			JobRun.start(JobRun.job_by_id(ARRIVAL_JOB))
		if VERIFY_JOBS.has(tag):
			JobRun.start(JobRun.job_by_id(VERIFY_JOBS[tag]))
		if tag == "pause":
			JobRun.current_job = {}
		if tag == "practice":
			Save.data["tutorial_done"] = true  # not saved to disk
			if base == "lock_job_practice":
				Practice.start(Practice.entry(PRACTICE_LOCK))
		# instantiate next to the runner (change_scene_to_file would free the runner
		# itself, since it is the current scene, and stop this loop)
		if _shown != null:
			_shown.queue_free()
		var path := scene_path
		var day_after_backup: Variant = null
		if base == "day_after":
			day_after_backup = Save.get_value("day_after", {})
			Save.set_value("day_after", {})
			DayAfter.note_finished(JobRun.job_by_id(DAY_AFTER_JOB))
			path = "res://scenes/jobs_list.tscn"
		_shown = load(path).instantiate()
		get_tree().root.add_child(_shown)
		get_tree().current_scene = _shown
		if base == "workshop_practice":
			_shown.call("show_tab", "practice")
		if tag == "pause":
			for i in 10:
				await get_tree().process_frame
			_shown.call("_on_pause")  # N-75: the pause panel over the lock
		for i in 30:
			await get_tree().process_frame
		await get_tree().create_timer(0.4).timeout  # the 200 ms entry fades (ScreenFrame.enter) are over
		var img := get_viewport().get_texture().get_image()
		var name := base + "_%dx%d.png" % [_size.x, _size.y]
		if day_after_backup != null:
			Save.set_value("day_after", day_after_backup)
		img.save_png(_out + "/" + name)
		print("SHOT ", name)
		if Practice.active():
			Practice.finish(false, true)
		if tag == "pause":
			get_tree().paused = false
	if _demo:
		Save.data = backup
		Save.save()
	get_tree().quit()
