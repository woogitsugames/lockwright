extends GutTest
## N-75: the lock pause is a centred panel inside the safe area with enamel plates >= 48 dp, on every
## lock screen (pin + plan-B hosts), instead of three bare labels in the top-left corner.

const W := 412.0
const H := 915.0


func after_each() -> void:
	get_tree().paused = false
	JobRun.current_job = {}


func _scenes() -> Array:
	var out := ["res://scenes/lock_job.tscn"]
	for fam in JobRun.PLANB_SCENES:
		out.append(JobRun.PLANB_SCENES[fam])
	return out


func _open(path: String) -> Node:
	var vp := SubViewport.new()
	vp.size = Vector2i(int(W), int(H))
	add_child_autofree(vp)
	var scene: Node = load(path).instantiate()
	vp.add_child(scene)
	for i in 3:
		await get_tree().process_frame
	return scene


func test_pause_is_a_centred_panel_with_big_plates() -> void:
	for path in _scenes():
		var scene := await _open(path)
		scene.call(&"_on_pause")
		for i in 2:
			await get_tree().process_frame
		var cover := scene.get_node("UILayer/PauseCover") as Control
		assert_true(cover.is_visible_in_tree(), "%s: pause shown" % path)
		var panel := cover.find_child("Panel", true, false) as PanelContainer
		assert_not_null(panel, "%s: dark-paper panel" % path)
		if panel == null:
			continue
		var r := panel.get_global_rect()
		assert_gte(r.position.x, 16.0 - 0.5, "%s: 16 dp left margin" % path)
		assert_lte(r.end.x, W - 16.0 + 0.5, "%s: 16 dp right margin" % path)
		assert_almost_eq(r.get_center().x, W * 0.5, 2.0, "%s: centred horizontally" % path)
		assert_almost_eq(r.get_center().y, H * 0.5, 40.0, "%s: centred vertically, away from the status bar" % path)
		var plates := 0
		for b in panel.find_children("*", "Button", true, false):
			assert_true(b is EnamelButton, "%s: %s is an enamel plate" % [path, b.name])
			assert_gte((b as Control).get_global_rect().size.y, 48.0, "%s: %s >= 48 dp" % [path, b.text])
			assert_false((b as Button).flat, "not a bare text button")
			plates += 1
		assert_eq(plates, 3, "%s: resume, dark mode, leave" % path)
		scene.call(&"_on_resume")
		get_tree().paused = false
		scene.get_parent().queue_free()
		await get_tree().process_frame


func test_dark_mode_plate_names_the_way_back() -> void:
	var scene := await _open("res://scenes/lock_job.tscn")
	scene.call(&"_on_pause")
	var dark: Button = scene.get("_pause_dark_button")
	assert_eq(dark.text, I18n.t(&"pause.dark_mode"))
	dark.pressed.emit()  # turns the dark mode on and resumes
	scene.call(&"_on_pause")
	assert_eq(dark.text, I18n.t(&"pause.dark_mode_off"), "in the dark the plate offers the light back")
	scene.call(&"_on_resume")
