extends SceneTree
## A11Y screenshots (session C): every menu scene at the window size given with --resolution, PL, with a text scale.
##   godot --path <copy of game> --resolution 412x915 -s res://qa_bot/a11y_shots.gd -- --out DIR --scale 1.5 --tag p150
## Also prints, per scene, controls that end outside the viewport and the smallest font size in use (A11Y checks).

const SCENES := ["main_menu", "settings", "jobs_list", "job_arrival", "job_verify", "job_payment", "workshop", "showcase", "tutorial"]
var out := "/tmp"
var scale := 1.0
var tag := ""
var lang := "pl"


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	for i in a.size() - 1:
		match a[i]:
			"--out": out = a[i + 1]
			"--scale": scale = float(a[i + 1])
			"--tag": tag = a[i + 1]
			"--lang": lang = a[i + 1]
	_run.call_deferred()


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _run() -> void:
	await _frames(2)
	var st: Node = root.get_node("Settings")
	st.set_value("language", lang)
	root.get_node("I18n").call("apply_language", lang)
	st.set_value("text_scale", scale)
	var jr: GDScript = load("res://scripts/lock/job_run.gd")
	var job: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/jobs/job.student_dorm.json"))
	jr.start(job)
	for sc in SCENES:
		change_scene_to_file("res://scenes/%s.tscn" % sc)
		await _frames(12)
		var vp := root.get_visible_rect().size
		var outside := []
		var min_font := 999
		var truncated := []
		for c in _controls(current_scene):
			if not c.is_visible_in_tree():
				continue
			var r: Rect2 = c.get_global_rect()
			if (c is Label or c is BaseButton) and (r.position.x < -1 or r.position.y < -1 or r.end.x > vp.x + 1 or r.end.y > vp.y + 1):
				outside.append("%s(%d,%d %dx%d)" % [c.name, r.position.x, r.position.y, r.size.x, r.size.y])
			if c is Label or c is Button:
				min_font = mini(min_font, c.get_theme_font_size("font_size"))
				# text wider than its control (no wrapping): the player sees a cut word or an ellipsis
				var wraps: bool = c is Label and (c as Label).autowrap_mode != TextServer.AUTOWRAP_OFF
				if not wraps and c.text != "":
					var f: Font = c.get_theme_font("font")
					var need: float = f.get_string_size(c.text, HORIZONTAL_ALIGNMENT_LEFT, -1, c.get_theme_font_size("font_size")).x
					var have: float = r.size.x - (16.0 if c is Button else 0.0)
					if need > have + 1.0 and r.size.x > 0:
						truncated.append("%s(\"%s\" %d>%d)" % [c.name, c.text.substr(0, 40), need, have])
		var img := root.get_texture().get_image()
		img.save_png("%s/%s_%dx%d%s.png" % [out, sc, int(vp.x), int(vp.y), tag])
		print("A11Y scene=%s vp=%s min_font=%d outside=%s" % [sc, vp, min_font, outside])
		print("A11Y_TRUNC scene=%s lang=%s n=%d %s" % [sc, lang, truncated.size(), truncated])
	quit()


func _controls(n: Node, acc: Array = []) -> Array:
	if n is Control:
		acc.append(n)
	for c in n.get_children():
		_controls(c, acc)
	return acc
