extends Node
## Events: central signal bus. Decouples lockcore events from feedback channels.

# Lock lifecycle
signal lock_event(event: Dictionary)  # {tick, kind, element, intensity, material}
signal lock_opened
signal lock_failed(reason: StringName)
# Feedback routing (same frame as lock_event, never waits for render — ARCHITECTURE.md §5)
signal feedback(event: Dictionary)
# Scene navigation
signal scene_change_requested(scene: StringName)

const MAIN_MENU := "res://scenes/main_menu.tscn"
const RUN_LOOP := "res://scenes/run_loop.tscn"
const TUTORIAL := "res://scenes/tutorial.tscn"
const JOBS_LIST := "res://scenes/jobs_list.tscn"
const PAYMENT := "res://scenes/job_payment.tscn"
const PLACEHOLDER_LOCK := "res://scenes/lock.tscn"
const WORKSHOP := "res://scenes/workshop.tscn"  # D-79: practice runs come back to its Ćwiczenia tab
## N-64: after a break the broken pick stays on screen this long, then the game moves on
## (a finished lockcore session ignores input: staying on the lock looks like a frozen game).
const FAIL_DELAY_S := 1.5

## Tests: the scene treated as current (GUT owns current_scene) and a dry-run switch;
## when change_scenes is false, the target is only recorded in last_target.
var scene_override: Node = null
var change_scenes := true
var last_target := ""
var _fail_scene: Node = null


func _ready() -> void:
	lock_opened.connect(_on_lock_opened)
	lock_failed.connect(_on_lock_failed)
	lock_event.connect(_on_lock_event)


func _on_lock_event(e: Dictionary) -> void:
	# N-25: a clean opening (no drop/break/overset) earns a tip (JOBS.md §3)
	if e.get("kind") in [&"drop", &"break", &"overset"]:
		JobRun.clean = false


func _current() -> Node:
	return scene_override if scene_override != null else get_tree().current_scene


func _go(path: String) -> void:
	last_target = path
	if not change_scenes:
		return
	get_tree().paused = false
	get_tree().change_scene_to_file(path)


func _on_lock_opened() -> void:
	# N-13: the photoreal lock screen emits lock_opened but never completes the job;
	# lock.tscn handles its own navigation, so handle the rest here
	var scene := _current()
	if scene == null:
		return
	if JobRun.mode == &"run":
		# N-64: record the result before run_loop.tscn is reloaded (it used to reset each lock)
		RunState.lock_finished(true, int(JobRun.current_job.get("reward_coins", 0)))
		JobRun.current_job = {}
	if scene.scene_file_path == PLACEHOLDER_LOCK:
		return
	if JobRun.mode == &"run":
		_go(RUN_LOOP)  # endless run
	elif Practice.active():
		Practice.finish(true)  # D-79: no payment, no coins
		_go(WORKSHOP)
	elif JobRun.mode == &"tutorial" and not JobRun.current_job.is_empty():
		JobRun.complete()
		_go(TUTORIAL)  # N-09
	elif not JobRun.current_job.is_empty():
		_go(PAYMENT)
	else:
		# N-64: a lock opened with no job (e.g. "play" after the tutorial, or after an app
		# restart reset JobRun.mode to "job") must never leave the player stuck
		_go(MAIN_MENU)


## N-64: a broken pick ends the lockcore session (finished(), input ignored). Neither lock
## screen navigated away on failure, so the player was left on a lock that did not react.
func _on_lock_failed(_reason: StringName) -> void:
	var scene := _current()
	if scene == null or scene == _fail_scene:
		return
	_fail_scene = scene
	if not change_scenes or FAIL_DELAY_S <= 0.0:
		_route_failed(scene)
		return
	get_tree().create_timer(FAIL_DELAY_S, true).timeout.connect(func() -> void:
		if is_instance_valid(scene) and _current() == scene:
			_route_failed(scene))


func _route_failed(_scene: Node) -> void:
	_fail_scene = null
	if JobRun.mode == &"run":
		RunState.lock_finished(false, 0)
		JobRun.current_job = {}
		_go(RUN_LOOP)
	elif Practice.active():
		Practice.finish(false)  # D-79: a break in practice costs nothing (no stats, no pick)
		_go(WORKSHOP)
	elif JobRun.mode == &"tutorial" and not JobRun.current_job.is_empty():
		_go(TUTORIAL)  # the same stage again (tutorial_stage unchanged)
	elif not JobRun.current_job.is_empty():
		Save.set_value("stats/locks_broken", Save.get_value("stats/locks_broken", 0) + 1)
		JobRun.current_job = {}
		_go(JOBS_LIST)  # the job stays open on the list
	else:
		_go(MAIN_MENU)
