extends Node
## Screenshot runner (task 13): walks all main screens at a given resolution and
## saves PNGs. Run under xvfb with opengl3:
##   xvfb-run godot --path game --display-driver x11 --rendering-driver opengl3 res://tests/screens.tscn -- --out /tmp/shots --size 412x915
const SCREENS := ["res://scenes/main_menu.tscn", "res://scenes/jobs_list.tscn", "res://scenes/workshop.tscn", "res://scenes/showcase.tscn", "res://scenes/settings.tscn", "res://scenes/control_choice.tscn", "res://scenes/job_arrival.tscn", "res://scenes/day_after.tscn", "res://scenes/lock.tscn"]
## job shown on the arrival screen (N-60: portrait + locksmith line)
const ARRIVAL_JOB := "job.bike_interview"
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
	for scene_path: String in SCREENS:
		var base: String = scene_path.get_file().get_basename()
		if _only != "" and not (base in _only.split(",")):
			continue
		if base == "job_arrival":
			JobRun.start(JobRun.job_by_id(ARRIVAL_JOB))
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
		for i in 30:
			await get_tree().process_frame
		var img := get_viewport().get_texture().get_image()
		var name := base + "_%dx%d.png" % [_size.x, _size.y]
		if day_after_backup != null:
			Save.set_value("day_after", day_after_backup)
		img.save_png(_out + "/" + name)
		print("SHOT ", name)
	if _demo:
		Save.data = backup
		Save.save()
	get_tree().quit()
