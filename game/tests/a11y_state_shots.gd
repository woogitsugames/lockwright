extends Node
## D-90 colour / grayscale audit: one window, every lock family, every element state.
## For each family (pin + every plan-B scene) the real lock screen is opened once and frozen in a
## pose where ALL elements share one state (free, bound, near, set, false_set, overset, plus
## stress 0.95 = near break and open); each pose is saved as <out>/<family>__<state>.png.
## qa/a11y/state_report.py turns them into grayscale / deuteranopia / protanopia sheets and a
## per-pair difference table (are the states told apart without colour?).
##   godot --path game --rendering-driver opengl3 res://tests/a11y_state_shots.tscn -- \
##     --out=C:/path/dir [--size=412x915] [--families=pin_tumbler,wafer] [--reduce=1] [--captions=1]
## Uses the GPU for a short while (about 2 s per family).

const STATES := {
	"free": {"state": &"free", "position": 0.0},
	"bound": {"state": &"bound", "position": 0.40},
	"near": {"state": &"near", "position": 0.50},
	"set": {"state": &"set", "position": 0.56},
	"false_set": {"state": &"false_set", "position": 0.40, "variant": 1},
	"overset": {"state": &"overset", "position": 1.28},
	"stress": {"state": &"bound", "position": 0.40, "stress": 0.95},
	"open": {"state": &"set", "position": 0.56, "open": true},
}
const FRAMES := 24


func _vm(st: Dictionary) -> Dictionary:
	var els := []
	for i in 5:
		els.append({"state": st["state"], "position": st["position"], "variant": int(st.get("variant", 0)),
			"window_lo": 0.52, "window_hi": 0.60, "target": 0.56})
	return {"elements": els, "pick_element": 2, "tension": 0.35, "core_rotation": 0.6 if st.get("open", false) else 0.0,
		"stress": float(st.get("stress", 0.0)), "open": bool(st.get("open", false)), "tension_resistance": 0.4}


func _ready() -> void:
	var a := {}
	for s in OS.get_cmdline_user_args():
		if s.begins_with("--") and "=" in s:
			a[s.substr(2, s.find("=") - 2)] = s.substr(s.find("=") + 1)
	var out: String = a.get("out", "user://a11y_states")
	DirAccess.make_dir_recursive_absolute(out)
	var p: PackedStringArray = String(a.get("size", "412x915")).split("x")
	get_window().size = Vector2i(int(p[0]), int(p[1]))
	if Quality._fps_label != null:
		Quality._fps_label.visible = false
	if a.has("reduce"):
		UiA11y.reduce_motion_override = int(a["reduce"])
	Settings._cfg["sound_captions"] = false
	var scenes := {&"pin_tumbler": "res://scenes/lock_job.tscn"}
	scenes.merge(JobRun.PLANB_SCENES)
	var only: Array = String(a.get("families", "")).split(",", false)
	await get_tree().process_frame
	for fam in scenes:
		if not only.is_empty() and not String(fam) in only:
			continue
		JobRun.current_job = {}
		var scene: Node = load(scenes[fam]).instantiate()
		add_child(scene)
		await get_tree().process_frame
		await get_tree().process_frame
		scene.set("_frozen", true)
		for st_name in STATES:
			var vm := _vm(STATES[st_name])
			scene.set("_pose_vm", vm)
			scene.set("_last_input", {"tension": 0.35, "pick_depth": 0.5, "pick_lift": 0.3})
			scene.view._opened = bool(vm["open"])
			scene.view._broken = false
			for i in FRAMES:
				await get_tree().process_frame
			var img := get_viewport().get_texture().get_image()
			var path := "%s/%s__%s.png" % [out, fam, st_name]
			img.save_png(path)
			print("SHOT ", path)
		if a.get("captions", "") == "1":  # sound captions strip after a set click (HUD.md §9.1)
			Settings._cfg["sound_captions"] = true
			scene.set("_pose_vm", _vm(STATES["set"]))
			for i in FRAMES:
				await get_tree().process_frame
			Events.lock_event.emit({"kind": &"set", "element": 2, "intensity": 1.0, "material": &"brass"})
			for i in 6:
				await get_tree().process_frame
			get_viewport().get_texture().get_image().save_png("%s/%s__caption_set.png" % [out, fam])
			Settings._cfg["sound_captions"] = false
		scene.queue_free()
		await get_tree().process_frame
	get_tree().quit()
