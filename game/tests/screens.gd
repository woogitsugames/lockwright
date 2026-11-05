extends Node
## Screenshot runner (task 13): walks all main screens at a given resolution and
## saves PNGs. Run under xvfb with opengl3:
##   xvfb-run godot --path game --display-driver x11 --rendering-driver opengl3 res://tests/screens.tscn -- --out /tmp/shots --size 412x915
const SCREENS := ["res://scenes/main_menu.tscn", "res://scenes/jobs_list.tscn", "res://scenes/workshop.tscn", "res://scenes/showcase.tscn", "res://scenes/settings.tscn", "res://scenes/lock.tscn"]

var _out := "/tmp/shots"
var _size := Vector2i(412, 915)


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			_out = a.trim_prefix("--out=")
		elif a.begins_with("--size="):
			var p := a.trim_prefix("--size=").split("x")
			_size = Vector2i(int(p[0]), int(p[1]))
	DirAccess.make_dir_recursive_absolute(_out)
	get_window().size = _size
	await get_tree().process_frame
	for scene_path in SCREENS:
		get_tree().change_scene_to_file(scene_path)
		for i in 30:
			await get_tree().process_frame
		var img := get_viewport().get_texture().get_image()
		var name := scene_path.get_file().get_basename() + "_%dx%d.png" % [_size.x, _size.y]
		img.save_png(_out + "/" + name)
		print("SHOT ", name)
	get_tree().quit()
