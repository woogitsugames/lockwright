extends SceneTree
## Menu v2 screenshots (D-62): normal + pressed, per window size and language, with the touch
## zones outlined in a separate "_zones" shot. Run under xvfb with opengl3:
##   xvfb-run -s "-screen 0 4000x4000x24" godot --path game --display-driver x11 --rendering-driver opengl3 \
##     -s res://tests/menu_shots.gd -- --out=/tmp/menu_v2
const SIZES := [Vector2i(412, 915), Vector2i(915, 412), Vector2i(1080, 2400), Vector2i(2400, 1080), Vector2i(1916, 2160), Vector2i(2160, 1916)]
const LANGS := ["pl", "en", "de"]

var _out := "/tmp/menu_v2"


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			_out = a.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(_out)
	_run.call_deferred()


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(_out.path_join(name + ".png"))
	print("SHOT ", name)


func _run() -> void:
	var rm: Variant = root.get_node("Settings").get_value(&"reduce_motion", false)
	root.get_node("Settings").set_value(&"reduce_motion", true)  # no fade-in in the shots (restored below)
	for size in SIZES:
		root.size = size
		await _frames(3)
		for lang in LANGS:
			root.get_node("I18n").apply_language(lang)
			var menu: Control = load("res://scenes/main_menu.tscn").instantiate()
			menu.change_scenes = false
			root.add_child(menu)
			await _frames(4)
			var tag := "menu_%dx%d_%s" % [size.x, size.y, lang]
			print("FIT ", tag, " vp=", menu.get_viewport_rect().size, " image=", menu.image_rect, " insets=", SafeArea.insets(menu))
			await _shot(tag)
			menu.show_pressed(&"jobs")
			await _frames(2)
			await _shot(tag + "_pressed_jobs")
			menu.show_pressed(&"")
			if lang == "pl":
				var outline := Control.new()
				outline.set_anchors_preset(Control.PRESET_FULL_RECT)
				outline.mouse_filter = Control.MOUSE_FILTER_IGNORE
				menu.add_child(outline)
				outline.draw.connect(func() -> void:
					for b in menu.get_node("Zones").get_children():
						outline.draw_rect(b.get_global_rect(), Color(1, 0.2, 0.1, 0.9), false, 2.0))
				outline.queue_redraw()
				await _frames(2)
				await _shot(tag + "_zones")
			menu.queue_free()
			await _frames(2)
	root.get_node("Settings").set_value(&"reduce_motion", rm)
	quit()
