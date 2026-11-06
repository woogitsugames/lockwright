extends GutTest
## N-52: Android back (NOTIFICATION_WM_GO_BACK_REQUEST) never quits outside the main
## menu. The notification is delivered to the Nav autoload on every screen.

const SCREENS := {
	"res://scenes/settings.tscn": "res://scenes/main_menu.tscn",
	"res://scenes/jobs_list.tscn": "res://scenes/main_menu.tscn",
	"res://scenes/workshop.tscn": "res://scenes/main_menu.tscn",
}
# routed by path only: showcase_screen.gd / job_arrival.gd currently load(), missing
# notebook/portrait files, which GUT reports as engine errors; routing is under test here
const STUB_SCREENS := {
	"res://scenes/job_arrival.tscn": "res://scenes/jobs_list.tscn",
	"res://scenes/showcase.tscn": "res://scenes/main_menu.tscn",
	"res://scenes/job_verify.tscn": "res://scenes/job_arrival.tscn",
	"res://scenes/job_payment.tscn": "res://scenes/jobs_list.tscn",
	"res://scenes/tutorial.tscn": "res://scenes/main_menu.tscn",
	"res://scenes/run_loop.tscn": "res://scenes/main_menu.tscn",
}


func before_each() -> void:
	Nav.back_debounce_ms = 0  # several Back presses per frame in tests
	Nav.change_scenes = false
	Nav.last_target = ""


func after_each() -> void:
	Nav.back_debounce_ms = 250
	Nav.scene_override = null
	Nav.change_scenes = true
	if Nav.quit_dialog_open():
		Nav._quit_dialog.hide()
	get_tree().paused = false


func _open(path: String) -> Node:
	var scene: Node = load(path).instantiate()
	add_child_autofree(scene)
	Nav.scene_override = scene
	await get_tree().process_frame
	await get_tree().process_frame
	return scene


func _send_back() -> void:
	Nav.notification(NOTIFICATION_WM_GO_BACK_REQUEST)


func test_project_does_not_quit_on_go_back() -> void:
	assert_false(ProjectSettings.get_setting("application/config/quit_on_go_back", true),
		"quit_on_go_back must be false, otherwise Android back kills the game")


func test_menu_screens_go_back() -> void:
	for path in SCREENS:
		await _open(path)
		_send_back()
		assert_eq(Nav.last_action, &"scene", "%s: back must change scene" % path)
		assert_eq(Nav.last_target, SCREENS[path], "%s: back target" % path)
		Nav.scene_override.queue_free()
	for path in STUB_SCREENS:
		var stub := Control.new()
		stub.scene_file_path = path
		add_child_autofree(stub)
		Nav.scene_override = stub
		_send_back()
		assert_eq(Nav.last_action, &"scene", "%s: back must change scene" % path)
		assert_eq(Nav.last_target, STUB_SCREENS[path], "%s: back target" % path)


func test_lock_back_opens_and_closes_pause() -> void:
	for path in ["res://scenes/lock.tscn", "res://scenes/lock_job.tscn"]:
		var scene := await _open(path)
		_send_back()
		assert_eq(Nav.last_action, &"pause", "%s: back opens pause" % path)
		assert_true(scene.get("_paused"), "%s: lock paused" % path)
		assert_true(get_tree().paused, "%s: tree paused" % path)
		_send_back()
		assert_eq(Nav.last_action, &"resume", "%s: back closes pause" % path)
		assert_false(scene.get("_paused"), "%s: lock resumed" % path)
		assert_false(get_tree().paused, "%s: tree resumed" % path)
		assert_eq(Nav.last_target, "", "%s: back never leaves the lock" % path)
		scene.queue_free()
		await get_tree().process_frame


func test_main_menu_asks_before_quitting() -> void:
	var menu := await _open("res://scenes/main_menu.tscn")
	var about := menu.get_node_or_null("AboutPanel") as CanvasItem
	if about != null:
		about.visible = true
		_send_back()
		assert_eq(Nav.last_action, &"close_about")
		assert_false(about.visible, "back closes the About panel first")
	_send_back()
	assert_eq(Nav.last_action, &"confirm_quit")
	assert_true(Nav.quit_dialog_open(), "back on the main menu shows the quit confirmation")
	assert_eq(Nav._quit_dialog.dialog_text, I18n.t(&"nav.quit_confirm"))
	assert_true(I18n.has_key(&"nav.quit_yes") and I18n.has_key(&"nav.quit_no"))
	_send_back()
	assert_eq(Nav.last_action, &"dialog_closed", "second back dismisses the dialog")
	assert_false(Nav.quit_dialog_open())
	assert_eq(Nav.last_target, "", "nothing quit without confirmation")
	_send_back()
	Nav._quit_dialog.confirmed.emit()
	assert_eq(Nav.last_target, "quit", "confirming quits")
