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

func _ready() -> void:
	lock_opened.connect(_on_lock_opened)
	lock_event.connect(_on_lock_event)


func _on_lock_event(e: Dictionary) -> void:
	# N-25: a clean opening (no drop/break/overset) earns a tip (JOBS.md §3)
	if e.get("kind") in [&"drop", &"break", &"overset"]:
		JobRun.clean = false


func _on_lock_opened() -> void:
	# N-13: the photoreal lock screen (session A's scene) emits lock_opened but never
	# completes the job; lock.tscn handles its own navigation, so handle the rest here
	var scene := get_tree().current_scene
	if scene == null or scene.scene_file_path == "res://scenes/lock.tscn":
		return
	if JobRun.mode == &"run":
		get_tree().change_scene_to_file("res://scenes/run_loop.tscn")  # endless run
	elif JobRun.mode == &"tutorial":
		JobRun.complete()
		get_tree().change_scene_to_file("res://scenes/tutorial.tscn")  # N-09
	elif not JobRun.current_job.is_empty():
		get_tree().change_scene_to_file("res://scenes/job_payment.tscn")
	else:
		# N-64: a lock opened with no job and no mode must never leave the player stuck
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
