extends Node
## One-scene screenshot (dev/CI): loads --scene=res://..., waits --frames=N, saves --out=FILE.
##   xvfb-run godot --path game --display-driver x11 --rendering-driver opengl3 \
##     --resolution 412x915 res://tests/shot_scene.tscn -- --scene=res://scenes/tutorial.tscn --out=/tmp/t.png
## D-58 arrival scene: --job=job.wrong_floor [--time=night] [--reduce=0|1] [--climb-at=SECONDS | --hold=1] [--speaker=teresa].
## --size=WxH sets the window (as tests/screens.gd); --tab=furnishings opens the workshop's Wyposażenie tab; --tutorial-stage=N sets JobRun.tutorial_stage first; --auto=1 sets Settings auto_tension (not saved).

func _ready() -> void:
	var a := {}
	for s in OS.get_cmdline_user_args():
		if s.begins_with("--") and "=" in s:
			a[s.substr(2, s.find("=") - 2)] = s.substr(s.find("=") + 1)
	if a.has("size"):
		var p: PackedStringArray = a["size"].split("x")
		get_window().size = Vector2i(int(p[0]), int(p[1]))
		await get_tree().process_frame
	if a.has("tutorial-stage"):
		JobRun.tutorial_stage = int(a["tutorial-stage"])
	if a.has("auto"):
		Settings._cfg["auto_tension"] = a["auto"] == "1"
	# D-71 furnishings: --coins=N, --furnish=all|id,id (owned + shown), --chapter=N; in memory only (not saved)
	if a.has("coins"):
		Save.data["coins"] = int(a["coins"])
	if a.has("chapter"):
		Save.data["chapter"] = int(a["chapter"])
	if a.has("furnish"):
		Save.data["furnishings"] = {}
		for f in Furnishings.all():
			if a["furnish"] == "all" or String(f["id"]) in a["furnish"].split(","):
				Save.data["furnishings"][f["id"]] = {"owned": true, "shown": true}
	if a.has("job"):
		var job := JobRun.job_by_id(a["job"]).duplicate(true)
		if a.has("time"):
			job["time"] = a["time"]
		JobRun.start(job)
	if a.has("reduce"):
		load("res://scripts/ui/job_arrival.gd").reduce_motion_override = int(a["reduce"])
	# instance as a child (change_scene would free this runner before it saves)
	var scene: Node = load(a.get("scene", "res://scenes/tutorial.tscn")).instantiate()
	add_child(scene)
	if a.has("tab") and scene.has_method("show_tab"):
		await get_tree().process_frame
		scene.show_tab(a["tab"])
	if "scene" in scene and scene.scene != null:
		await get_tree().process_frame
		if a.has("climb-at"):
			scene.scene.set_process(false)
			scene.scene._process(float(a["climb-at"]))
		elif a.has("hold"):
			scene.scene.skip()
			if a.has("speaker"):
				scene.scene.show_speaker(a["speaker"])
			scene.dialogue.skip_all()
	if a.has("debug") and "scene" in scene and scene.scene != null:
		var arr: Control = scene.scene
		print("ARR size=", arr.size, " canvas=", arr.get_node("Canvas").position, arr.get_node("Canvas").size, " plate=", arr.get_node("Canvas/Plate").texture, arr.get_node("Canvas/Plate").size)
	for i in int(a.get("frames", "30")):
		await get_tree().process_frame
	if a.has("debug") and scene is Control:
		for n in scene.find_children("*", "Control", true, false):
			var c := n as Control
			if c.size.x > get_viewport().get_visible_rect().size.x:
				print("WIDE ", c.get_path(), " size=", c.size, " min=", c.get_combined_minimum_size())
	var img := get_viewport().get_texture().get_image()
	img.save_png(a.get("out", "/tmp/shot.png"))
	print("SHOT ", a.get("out", ""), " ", img.get_size())
	get_tree().quit()
