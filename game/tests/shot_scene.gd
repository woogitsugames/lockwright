extends Node
## One-scene screenshot (dev/CI): loads --scene=res://..., waits --frames=N, saves --out=FILE.
##   xvfb-run godot --path game --display-driver x11 --rendering-driver opengl3 \
##     --resolution 412x915 res://tests/shot_scene.tscn -- --scene=res://scenes/tutorial.tscn --out=/tmp/t.png
## --tutorial-stage=N sets JobRun.tutorial_stage first; --auto=1 sets Settings auto_tension (not saved).

func _ready() -> void:
	var a := {}
	for s in OS.get_cmdline_user_args():
		if s.begins_with("--") and "=" in s:
			a[s.substr(2, s.find("=") - 2)] = s.substr(s.find("=") + 1)
	if a.has("tutorial-stage"):
		JobRun.tutorial_stage = int(a["tutorial-stage"])
	if a.has("auto"):
		Settings._cfg["auto_tension"] = a["auto"] == "1"
	get_tree().change_scene_to_file.call_deferred(a.get("scene", "res://scenes/tutorial.tscn"))
	for i in int(a.get("frames", "30")):
		await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	img.save_png(a.get("out", "/tmp/shot.png"))
	print("SHOT ", a.get("out", ""), " ", img.get_size())
	get_tree().quit()
