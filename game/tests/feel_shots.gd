extends Node
## D-130 "game feel" capture: frames of a lock's opening moment, at fixed times after the open event.
## For each family the real lock screen is opened, lockcore's own solution (LockcoreSession.solve) is
## replayed step by step through the view exactly as the screen does (on_event + present at 120 Hz),
## and after the `open` event the window is saved at each time of --ms:
##   <out>/<family>__open_<ms>.png
## The screen's own physics loop is off meanwhile, so the frames are the same on every run.
##   godot --path game --rendering-driver opengl3 res://tests/feel_shots.tscn -- \
##     --out=/path/dir [--size=412x915] [--families=pin_tumbler,lever,combo] [--ms=0,60,120,200,300,500]
## docs/handoff/LOCK-FEEL-2026-11-13.md shows the strips made from these frames.

const STEP := 1.0 / 120.0


func _ready() -> void:
	var a := {}
	for s in OS.get_cmdline_user_args():
		if s.begins_with("--") and "=" in s:
			a[s.substr(2, s.find("=") - 2)] = s.substr(s.find("=") + 1)
	var out: String = a.get("out", "user://feel_shots")
	DirAccess.make_dir_recursive_absolute(out)
	var p: PackedStringArray = String(a.get("size", "412x915")).split("x")
	get_window().size = Vector2i(int(p[0]), int(p[1]))
	if Quality._fps_label != null:
		Quality._fps_label.visible = false
	Settings._cfg["sound_captions"] = false
	var times: Array = []
	for t in String(a.get("ms", "0,60,120,200,300,500")).split(",", false):
		times.append(int(t))
	var scenes := {&"pin_tumbler": "res://scenes/lock_job.tscn"}
	scenes.merge(JobRun.PLANB_SCENES)
	var only: Array = String(a.get("families", "pin_tumbler,lever,combo")).split(",", false)
	await get_tree().process_frame
	for fam in scenes:
		if not String(fam) in only:
			continue
		JobRun.current_job = {}
		var scene: Node = load(scenes[fam]).instantiate()
		add_child(scene)
		await get_tree().process_frame
		scene.set_physics_process(false)
		await _replay_to_open(scene, fam, out, times)
		scene.queue_free()
		await get_tree().process_frame
	get_tree().quit()


func _replay_to_open(scene: Node, fam: StringName, out: String, times: Array) -> void:
	if not ClassDB.class_exists("LockcoreSession"):
		push_error("feel_shots needs the lockcore GDExtension")
		return
	var sd: int = scene.seed
	var tr: int = scene.tier
	scene.session = scene.make_session(fam, sd, tr)
	var rows: Array = ClassDB.class_call_static(&"LockcoreSession", &"solve", fam, sd, tr).get("inputs", [])
	var input := {"tension": 0.0, "pick_depth": 0.5, "pick_lift": 0.0}
	var opened := false
	for r in rows:
		input = {"tension": r[0], "pick_depth": r[1], "pick_lift": r[2]}
		var ev: Array = scene.session.step(r[0], r[1], r[2])
		for e in ev:
			scene.view.on_event(e)
			if e["kind"] == &"open":
				opened = true
		scene.view.present(scene.session.describe(), input, STEP)
		if opened or scene.session.finished():
			break
	if not opened:
		push_error("feel_shots: %s seed %d tier %d did not open" % [fam, sd, tr])
		return
	var elapsed := STEP  # the open step itself was presented once
	for ms in times:
		while elapsed * 1000.0 < float(ms):
			scene.view.present(scene.session.describe(), input, STEP)
			elapsed += STEP
		for i in 4:
			await get_tree().process_frame
		var path := "%s/%s__open_%03d.png" % [out, fam, int(ms)]
		get_viewport().get_texture().get_image().save_png(path)
		print("SHOT ", path)
