extends Node
## N-52: Android back button (NOTIFICATION_WM_GO_BACK_REQUEST) acts like the on-screen
## "Back" button instead of quitting the game (project.godot: quit_on_go_back=false).
##   settings / jobs / workshop / showcase / tutorial / run loop -> main menu
##   arrival -> jobs list, verify -> arrival, payment -> jobs list
##   lock -> open pause (the flap), pause -> close pause
##   main menu: About panel open -> close it; else confirm "Quit the game?" -> quit
## A screen can take over by defining go_back() -> bool (true = handled), e.g. a
## magnifier eyepiece that should close first (N-57).
## N-69: in Godot 4.7 one physical Back has several routes into the game: the input handler
## parses an InputEventKey (Key::BACK) and sends a deferred WM_GO_BACK_REQUEST for
## KEYCODE_BACK, and the activity's OnBackPressedCallback calls GodotLib.back() (another
## request) when the key reaches it. Two requests are harmless where Back is idempotent
## (settings, receipt) but on a lock pause+resume cancel out ("Back does nothing").
## Nav is the single Back handler (window request, Key::BACK, Esc) and collapses requests
## closer than back_debounce_ms into one.

const MAIN_MENU := "res://scenes/main_menu.tscn"
const JOBS_LIST := "res://scenes/jobs_list.tscn"
const BACK_TARGETS := {
	"res://scenes/settings.tscn": MAIN_MENU,
	"res://scenes/jobs_list.tscn": MAIN_MENU,
	"res://scenes/workshop.tscn": MAIN_MENU,
	"res://scenes/showcase.tscn": MAIN_MENU,
	"res://scenes/tutorial.tscn": MAIN_MENU,
	"res://scenes/run_loop.tscn": MAIN_MENU,
	"res://scenes/job_arrival.tscn": JOBS_LIST,
	"res://scenes/job_verify.tscn": "res://scenes/job_arrival.tscn",
	"res://scenes/job_payment.tscn": JOBS_LIST,
}

## Tests set this to the scene under test (GUT owns current_scene).
var scene_override: Node = null
## When false, scene changes are only recorded in last_target (tests).
var change_scenes := true
var last_target := ""
var last_action := &""
var _quit_dialog: ConfirmationDialog = null
## Requests closer than this to the previous handled one are the same press (tests set 0).
var back_debounce_ms := 250
## Debounce clock in ms. Device: Time.get_ticks_msec. Tests inject a fake clock so the
## result does not depend on how loaded the machine is.
var now_ms: Callable = Time.get_ticks_msec
var _last_back_ms := -100000


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # must work while the lock is paused


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		request_back()


func _input(event: InputEvent) -> void:
	# Key::BACK (Android) and Esc (desktop, keyboards) take the same single path as the
	# window request; lock screens no longer handle Esc themselves (N-69).
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if key.keycode == KEY_BACK or key.keycode == KEY_ESCAPE or key.physical_keycode == KEY_BACK:
		get_viewport().set_input_as_handled()
		request_back()


## Debounced entry for every Back source. Returns &"debounced" for a duplicate.
func request_back() -> StringName:
	var now := int(now_ms.call())
	if back_debounce_ms > 0 and now - _last_back_ms < back_debounce_ms:
		return &"debounced"
	_last_back_ms = now
	return handle_back()


func _current() -> Node:
	if scene_override != null and is_instance_valid(scene_override):
		return scene_override
	return get_tree().current_scene


## Returns the action taken: &"dialog_closed", &"custom", &"pause", &"resume",
## &"close_about", &"confirm_quit", &"scene", &"none".
func handle_back() -> StringName:
	last_action = _handle_back()
	return last_action


func _handle_back() -> StringName:
	if quit_dialog_open():
		_quit_dialog.hide()
		return &"dialog_closed"
	var scene := _current()
	if scene == null:
		return &"none"
	if scene.has_method("go_back") and scene.call("go_back"):
		return &"custom"
	# lock screens: photoreal (plan B, families) expose _on_pause/_on_resume,
	# the placeholder lock_scene.gd exposes _on_pause_pressed/_on_resume_pressed
	if scene.has_method("_on_pause") or scene.has_method("_on_pause_pressed"):
		if bool(scene.get("_paused")):
			scene.call("_on_resume" if scene.has_method("_on_resume") else "_on_resume_pressed")
			return &"resume"
		scene.call("_on_pause" if scene.has_method("_on_pause") else "_on_pause_pressed")
		return &"pause"
	var path := scene.scene_file_path
	if path == MAIN_MENU:
		var about := scene.get_node_or_null("AboutPanel") as CanvasItem
		if about != null and about.visible:
			about.visible = false
			return &"close_about"
		_open_quit_dialog()
		return &"confirm_quit"
	_go(BACK_TARGETS.get(path, MAIN_MENU))
	return &"scene"


func _go(target: String) -> void:
	last_target = target
	get_tree().paused = false
	if change_scenes:
		get_tree().change_scene_to_file(target)


func quit_dialog_open() -> bool:
	return _quit_dialog != null and _quit_dialog.visible


func _open_quit_dialog() -> void:
	if _quit_dialog == null:
		_quit_dialog = ConfirmationDialog.new()
		_quit_dialog.process_mode = Node.PROCESS_MODE_ALWAYS
		_quit_dialog.exclusive = true
		_quit_dialog.confirmed.connect(_on_quit_confirmed)
		add_child(_quit_dialog)
	_quit_dialog.title = ""
	_quit_dialog.dialog_text = I18n.t(&"nav.quit_confirm")
	_quit_dialog.ok_button_text = I18n.t(&"nav.quit_yes")
	_quit_dialog.cancel_button_text = I18n.t(&"nav.quit_no")
	_quit_dialog.get_ok_button().custom_minimum_size = Vector2(120, 48)
	_quit_dialog.get_cancel_button().custom_minimum_size = Vector2(120, 48)
	_quit_dialog.popup_centered(Vector2i(320, 160))


func _on_quit_confirmed() -> void:
	if change_scenes:
		get_tree().quit()
	else:
		last_target = "quit"
