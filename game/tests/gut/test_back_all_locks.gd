extends GutTest
## N-69: Android Back (NOTIFICATION_WM_GO_BACK_REQUEST, adb keyevent 4) on every lock screen —
## pin (lock_job.tscn) and every plan-B host in JobRun.PLANB_SCENES, including the
## planb_family_job.gd hosts (dial_safe, combo, disc_detainer). Back opens the pause, a second
## Back resumes; with the eyepiece open, Back closes the loupe first. The request is delivered
## the way Android delivers it: propagated from the root window through the whole tree.


func before_each() -> void:
	Nav.back_debounce_ms = 0  # several Back presses per frame in tests
	Nav.change_scenes = false
	Nav.last_target = ""
	JobRun.current_job = {}


func after_each() -> void:
	Nav.back_debounce_ms = 250
	Nav.scene_override = null
	Nav.change_scenes = true
	get_tree().paused = false


func _scenes() -> Dictionary:
	var out := {&"pin_tumbler": "res://scenes/lock_job.tscn"}
	for fam in JobRun.PLANB_SCENES:
		out[fam] = JobRun.PLANB_SCENES[fam]
	return out


func _open(path: String) -> Node:
	# phone-sized viewport (the headless root window is too small for the plan-B layouts)
	var vp := SubViewport.new()
	vp.size = Vector2i(412, 915)
	add_child_autofree(vp)
	var scene: Node = load(path).instantiate()
	vp.add_child(scene)
	Nav.scene_override = scene
	for i in 3:
		await get_tree().process_frame
	return scene


## Same path as DisplayServer WINDOW_EVENT_GO_BACK_REQUEST: Window._propagate_window_notification.
func _android_back() -> void:
	get_tree().root.propagate_notification(NOTIFICATION_WM_GO_BACK_REQUEST)
	await get_tree().process_frame


func _pause_visible(scene: Node) -> bool:
	var cover := scene.get_node_or_null("UILayer/PauseCover") as CanvasItem
	return cover != null and cover.is_visible_in_tree()


func test_back_opens_pause_on_every_lock_screen() -> void:
	var scenes := _scenes()
	assert_gt(scenes.size(), 10, "pin + plan-B families")
	for fam in scenes:
		var path: String = scenes[fam]
		var scene := await _open(path)
		assert_false(bool(scene.get("_paused")), "%s: starts unpaused" % fam)
		await _android_back()
		assert_eq(Nav.last_action, &"pause", "%s: Back opens the pause" % fam)
		assert_true(bool(scene.get("_paused")), "%s: lock paused" % fam)
		assert_true(get_tree().paused, "%s: tree paused" % fam)
		assert_true(_pause_visible(scene), "%s: pause cover shown" % fam)
		await _android_back()
		assert_eq(Nav.last_action, &"resume", "%s: second Back resumes" % fam)
		assert_false(bool(scene.get("_paused")), "%s: lock resumed" % fam)
		assert_false(get_tree().paused, "%s: tree resumed" % fam)
		assert_false(_pause_visible(scene), "%s: pause cover hidden" % fam)
		assert_eq(Nav.last_target, "", "%s: Back never leaves the lock" % fam)
		Nav.scene_override = null
		scene.get_parent().queue_free()
		await get_tree().process_frame


func test_back_closes_loupe_first() -> void:
	var scenes := _scenes()
	for fam in [&"pin_tumbler", &"wafer", &"warded", &"magnetic", &"dial_safe"]:
		var scene := await _open(scenes[fam])
		var view: Node = scene.get("view")
		view.toggle_loupe()
		assert_true(bool(view.get("zoomed")), "%s: loupe open" % fam)
		await _android_back()
		assert_eq(Nav.last_action, &"custom", "%s: Back closes the loupe" % fam)
		assert_false(bool(view.get("zoomed")), "%s: loupe closed" % fam)
		assert_false(bool(scene.get("_paused")), "%s: not paused yet" % fam)
		await _android_back()
		assert_eq(Nav.last_action, &"pause", "%s: next Back pauses" % fam)
		scene.call("_on_resume")
		Nav.scene_override = null
		scene.get_parent().queue_free()
		await get_tree().process_frame


func _key(code: Key) -> InputEventKey:
	var ev := InputEventKey.new()
	ev.keycode = code
	ev.physical_keycode = code
	ev.pressed = true
	return ev


## One press on the device = Key::BACK event + one or two window requests: still one pause.
func test_one_physical_back_is_one_action() -> void:
	Nav.back_debounce_ms = 250
	var scene := await _open("res://scenes/photoreal/lock_job_wafer.tscn")
	Nav._input(_key(KEY_BACK))
	get_tree().root.propagate_notification(NOTIFICATION_WM_GO_BACK_REQUEST)
	Nav.notification(NOTIFICATION_WM_GO_BACK_REQUEST)
	await get_tree().process_frame
	assert_true(bool(scene.get("_paused")), "duplicates of one press must not resume")
	assert_true(_pause_visible(scene), "pause cover stays open")
	await get_tree().create_timer(0.3, true).timeout
	Nav.notification(NOTIFICATION_WM_GO_BACK_REQUEST)
	assert_eq(Nav.last_action, &"resume", "a later, separate press resumes")
	assert_false(bool(scene.get("_paused")))
	Nav.scene_override = null
	scene.get_parent().queue_free()
	await get_tree().process_frame


## Esc (desktop/keyboard) goes through Nav only: one key press = one pause.
func test_escape_is_single_path() -> void:
	var scene := await _open("res://scenes/photoreal/lock_job_warded.tscn")
	Input.parse_input_event(_key(KEY_ESCAPE))
	Input.flush_buffered_events()
	await get_tree().process_frame
	await get_tree().process_frame
	assert_eq(Nav.last_action, &"pause", "Esc opens the pause through Nav")
	assert_true(bool(scene.get("_paused")), "Esc pauses (not pause+resume)")
	scene.call("_on_resume")
	Nav.scene_override = null
	scene.get_parent().queue_free()
	await get_tree().process_frame
