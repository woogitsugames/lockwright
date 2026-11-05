extends SceneTree
## Single-process screenshot & variant generator for all 4 photoreal lock families:
## Renders 824x1830 (portrait) and 1830x824 (landscape) screenshots for:
##   - wafer, lever (with lever_detector), warded, wooden_pin
## across all 6 required states:
##   - free, bound, set, false_set, overset, detector
## plus dark mode (OLED #000000 with touch dents and pause flap relief),
## and generates `.gray.png` and `.dim.png` variants for every screenshot.

const SHOTS_DIR := "res://scenes/photoreal_families/shots"
const SCENES := {
	"wafer": "res://scenes/photoreal_families/lock_photoreal_wafer.tscn",
	"lever": "res://scenes/photoreal_families/lock_photoreal_lever.tscn",
	"warded": "res://scenes/photoreal_families/lock_photoreal_warded.tscn",
	"wooden_pin": "res://scenes/photoreal_families/lock_photoreal_wooden_pin.tscn",
}
const STATES := ["free", "bound", "set", "false_set", "overset", "detector", "dark"]
const ORIENTATIONS := {
	"portrait": Vector2i(824, 1830),
	"landscape": Vector2i(1830, 824),
}

var _started := false


func _process(_delta: float) -> bool:
	if not _started:
		_started = true
		_run_all()
	return false


func _run_all() -> void:
	var abs_dir := ProjectSettings.globalize_path(SHOTS_DIR)
	DirAccess.make_dir_recursive_absolute(abs_dir)

	var orient_filter := ""
	for a in OS.get_cmdline_user_args():
		if a == "--portrait-only":
			orient_filter = "portrait"
		elif a == "--landscape-only":
			orient_filter = "landscape"

	for orient_name in ORIENTATIONS.keys():
		if orient_filter != "" and orient_name != orient_filter:
			continue
		var sz: Vector2i = ORIENTATIONS[orient_name]
		root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
		root.size = sz
		await process_frame
		await process_frame

		for fam in SCENES.keys():
			var packed := load(SCENES[fam]) as PackedScene
			var scene: Node = packed.instantiate()
			scene.set("_frozen", true)
			root.add_child(scene)
			await process_frame
			await process_frame

			var vis := Vector2(sz)
			var view: Control = scene.get_node("ViewLayer/View")
			view.size = vis
			view.call("_layout")
			await process_frame

			for st in STATES:
				if st == "dark":
					view.call("set_dark", true)
					view.call("touch", 0, Vector2(vis.x * 0.24, vis.y * 0.83), true)
					view.call("touch", 1, Vector2(vis.x * 0.72, vis.y * 0.80), true)
					var vm_dark: Dictionary = scene.call("state_pose_vm", StringName(fam), "bound")
					view.call("present", vm_dark, {"tension": 0.5, "pick_depth": 0.5, "pick_lift": 0.4}, 1.0)
				else:
					view.call("set_dark", false)
					view.call("touch", 0, Vector2.ZERO, false)
					view.call("touch", 1, Vector2.ZERO, false)
					var eff_fam := &"lever_detector" if (fam == "lever" and st == "detector") else StringName(fam)
					view.set("detector_enabled", eff_fam == &"lever_detector")
					var vm: Dictionary = scene.call("state_pose_vm", eff_fam, st)
					view.call("present", vm, {"tension": float(vm.get("tension", 0.4)), "pick_depth": 0.5, "pick_lift": 0.45}, 1.0)

				await process_frame
				await process_frame
				await process_frame

				var img := root.get_texture().get_image()
				var stem := "%s_%s_%s" % [fam, st, orient_name]
				var png_path := abs_dir.path_join(stem + ".png")
				var gray_path := abs_dir.path_join(stem + ".gray.png")
				var dim_path := abs_dir.path_join(stem + ".dim.png")
				img.save_png(png_path)
				_save_gray_and_dim(img, gray_path, dim_path)
				print("CAPTURED ", stem, " ", img.get_size())

			scene.queue_free()
			await process_frame

	print("ALL_SHOTS_COMPLETE")
	quit(0)


func _save_gray_and_dim(img: Image, gray_path: String, dim_path: String) -> void:
	var src := img.duplicate() as Image
	if src.get_format() != Image.FORMAT_RGBA8:
		src.convert(Image.FORMAT_RGBA8)
	var w := src.get_width()
	var h := src.get_height()
	var raw := src.get_data()
	var gray_raw := PackedByteArray()
	var dim_raw := PackedByteArray()
	gray_raw.resize(raw.size())
	dim_raw.resize(raw.size())
	var idx := 0
	var total := raw.size()
	while idx < total:
		var r := raw[idx]
		var g := raw[idx + 1]
		var b := raw[idx + 2]
		var a := raw[idx + 3]
		var y := clampi((54 * r + 183 * g + 19 * b) >> 8, 0, 255)
		gray_raw[idx] = y
		gray_raw[idx + 1] = y
		gray_raw[idx + 2] = y
		gray_raw[idx + 3] = a
		dim_raw[idx] = r >> 1
		dim_raw[idx + 1] = g >> 1
		dim_raw[idx + 2] = b >> 1
		dim_raw[idx + 3] = a
		idx += 4
	Image.create_from_data(w, h, false, Image.FORMAT_RGBA8, gray_raw).save_png(gray_path)
	Image.create_from_data(w, h, false, Image.FORMAT_RGBA8, dim_raw).save_png(dim_path)
