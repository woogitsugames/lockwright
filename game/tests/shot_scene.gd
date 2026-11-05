extends Node
## One-scene screenshot (dev/CI): loads --scene=res://..., waits --frames=N, saves --out=FILE.
##   xvfb-run godot --path game --display-driver x11 --rendering-driver opengl3 \
##     --resolution 412x915 res://tests/shot_scene.tscn -- --scene=res://scenes/tutorial.tscn --out=/tmp/t.png
## --size=WxH sets the window (as tests/screens.gd); --tutorial-stage=N sets JobRun.tutorial_stage first; --auto=1 sets Settings auto_tension (not saved).

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
	# instance as a child (change_scene would free this runner before it saves)
	var scene: Node = load(a.get("scene", "res://scenes/tutorial.tscn")).instantiate()
	add_child(scene)
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
