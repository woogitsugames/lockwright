extends GutTest
## D-58: arrival scene (stair climb flipbook -> hold frame with the client -> dialogue), data-driven
## from res://data/arrival_scenes.json; jobs without an entry keep the plain arrival screen.

const JOB := "job.wrong_floor"
const PLAIN_JOB := "job.bike_interview"
const JobArrival := preload("res://scripts/ui/job_arrival.gd")


func after_each() -> void:
	JobArrival.reduce_motion_override = -1


func _job(time: String) -> Dictionary:
	var j := JobRun.job_by_id(JOB).duplicate(true)
	if time != "":
		j["time"] = time
	return j


func _open(job: Dictionary, reduce: bool, size := Vector2i(412, 915)) -> Control:
	JobArrival.reduce_motion_override = 1 if reduce else 0
	JobRun.start(job)
	var vp := SubViewport.new()
	vp.size = size
	vp.disable_3d = true
	add_child_autofree(vp)
	var scene: Control = load("res://scenes/job_arrival.tscn").instantiate()
	vp.add_child(scene)
	await get_tree().process_frame
	await get_tree().process_frame
	return scene


func test_resolve_uses_job_time_and_falls_back() -> void:
	var day := ArrivalScene.resolve(_job("day"))
	assert_eq(day.get("time"), "day")
	assert_eq((day["frame_paths"] as Array).size(), 36, "36 frames @ 12 fps = 3 s")
	assert_eq(int(day["fps"]), 12)
	assert_true(day["layers"].has("kazimierz"))
	assert_false(day["layers"].has("teresa"), "Teresa's ajar hold exists only at night")
	var night := ArrivalScene.resolve(_job("night"))
	assert_true(night["layers"].has("teresa"))
	assert_eq(ArrivalScene.resolve(_job("rainy")).get("time"), "evening", "alias")
	assert_eq(ArrivalScene.resolve(_job("dawn")).get("time"), "evening", "unknown time -> default")
	assert_true(ArrivalScene.resolve(JobRun.job_by_id(PLAIN_JOB)).is_empty())
	assert_true(ArrivalScene.resolve({}).is_empty())


func test_every_scene_asset_exists() -> void:
	for jid: String in ArrivalScene.data()["scenes"]:
		var s: Dictionary = ArrivalScene.data()["scenes"][jid]
		for t: String in s["times"]:
			var r := ArrivalScene.resolve({"id": jid, "time": t})
			assert_eq(r.get("time"), t, "%s %s" % [jid, t])
			assert_eq((r["frame_paths"] as Array).size(), int(s["frames"]), "%s %s frames" % [jid, t])
			assert_true(r["anchors"].has(s["hold"]), "%s %s anchors" % [jid, t])


func test_scene_plays_then_dialogue_starts() -> void:
	var scene := await _open(_job("night"), false)
	var arr: ArrivalScene = scene.scene
	assert_not_null(arr)
	assert_eq(arr.phase, &"climb")
	assert_false(scene.get_node("Frame").visible, "the UI waits for the climb")
	assert_false(scene.dialogue.index >= 0 or scene.dialogue.is_finished(), "dialogue not started yet")
	arr._process(1.0)
	assert_eq(arr.phase, &"climb")
	assert_between(arr.frame, 10, 13, "12 fps")
	arr._process(2.2)
	assert_eq(arr.phase, &"hold")
	assert_true(scene.get_node("Frame").visible)
	assert_true(scene.dialogue.index >= 0 or scene.dialogue.is_finished(), "dialogue started after the climb")
	assert_eq(arr.current_figure, "kazimierz")


func test_tap_skips_the_climb() -> void:
	var scene := await _open(_job("day"), false)
	var arr: ArrivalScene = scene.scene
	assert_eq(arr.phase, &"climb")
	for pressed in [true, false]:
		var mb := InputEventMouseButton.new()
		mb.button_index = MOUSE_BUTTON_LEFT
		mb.pressed = pressed
		mb.position = Vector2(200, 400)
		arr._gui_input(mb)
	assert_eq(arr.phase, &"hold")
	assert_lt(arr.frame, 5, "skipped early")
	assert_true(scene.get_node("Frame").visible)


func test_breathing_loop_runs_on_hold() -> void:
	var scene := await _open(_job("evening"), false)
	var arr: ArrivalScene = scene.scene
	arr.skip()
	arr._process(1.8)
	assert_gt(arr.breath_scale(), 1.0)
	assert_lte(arr.breath_scale(), 1.01, "subtle")


func test_reduce_motion_shows_the_hold_only() -> void:
	var scene := await _open(_job("night"), true)
	var arr: ArrivalScene = scene.scene
	assert_eq(arr.phase, &"hold", "no climb")
	assert_eq(arr.frame, 0)
	assert_false(arr.get_node("Canvas/Climb").visible)
	assert_true(scene.get_node("Frame").visible)
	arr._process(1.8)
	assert_eq(arr.breath_scale(), 1.0, "no breathing under reduce motion")


func test_speaker_with_own_hold_takes_the_frame() -> void:
	var scene := await _open(_job("night"), true)
	var arr: ArrivalScene = scene.scene
	arr.show_speaker("locksmith")
	assert_eq(arr.current_figure, "kazimierz")
	arr.show_speaker("teresa")
	assert_eq(arr.current_figure, "teresa")
	assert_true(String(arr.get_node("Canvas/Plate").texture.resource_path).ends_with("night/plate_teresa.webp"))
	arr.show_speaker("kazimierz")
	assert_eq(arr.current_figure, "kazimierz")
	var day := await _open(_job("day"), true)
	day.scene.show_speaker("teresa")
	assert_eq(day.scene.current_figure, "kazimierz", "no Teresa hold by day: the client stays")


func test_layout_keeps_the_client_in_view() -> void:
	for size in [Vector2i(412, 915), Vector2i(360, 800), Vector2i(915, 412)]:
		var scene := await _open(_job("day"), true, size)
		var arr: ArrivalScene = scene.scene
		var a: Dictionary = arr.cfg["anchors"]["kazimierz"]
		var canvas: Control = arr.get_node("Canvas")
		assert_eq(arr.size, Vector2(size), "%s scene fills the screen" % size)
		assert_true(canvas.size.x >= size.x - 1 and canvas.size.y >= size.y - 1, "%s picture covers" % size)
		var head := arr.image_to_stage(Vector2(a["head"][0], a["head"][1]))
		assert_between(head.x, 0.0, float(size.x), "%s head x" % size)
		assert_between(head.y, 0.0, float(size.y), "%s head y" % size)
		if size.x > size.y:   # landscape: the dialogue column sits right of the client
			var frame: MarginContainer = scene.get_node("Frame")
			assert_gt(float(frame.get_theme_constant("margin_left")), head.x, "dialogue clear of the client")


func test_jobs_without_scene_keep_the_plain_screen() -> void:
	var scene := await _open(JobRun.job_by_id(PLAIN_JOB), false)
	assert_null(scene.scene)
	assert_null(scene.get_node_or_null("ArrivalScene"))
	assert_not_null(scene.get_node_or_null("Backdrop"))
	assert_true(scene.get_node("Frame").visible)
	assert_true(scene.dialogue.index >= 0 or scene.dialogue.is_finished(), "dialogue starts at once")


func test_landscape_column_moves_away_from_teresa() -> void:
	var scene := await _open(_job("night"), true, Vector2i(915, 412))
	var arr: ArrivalScene = scene.scene
	var frame: MarginContainer = scene.get_node("Frame")
	assert_gt(frame.get_theme_constant("margin_left"), 400, "Kazimierz on the left: column right")
	arr.show_speaker("teresa")
	var a: Dictionary = arr.cfg["anchors"]["teresa"]
	var head := arr.image_to_stage(Vector2(a["head"][0], a["head"][1]))
	assert_lt(float(915 - frame.get_theme_constant("margin_right")), head.x, "column left of Teresa")
	assert_between(head.y, 0.0, 412.0)

