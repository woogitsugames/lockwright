extends GutTest
## D-58: arrival scene (stair climb flipbook -> hold frame with the client -> dialogue), data-driven
## from res://data/arrival_scenes.json; jobs without an entry keep the plain arrival screen.

const JOB := "job.wrong_floor"
const PLAIN_JOB := "job.kiosk_shutter"
## early jobs with a plate-only scene (no full-body cut-out of their clients): the door and props tell the story
const PLATE_JOBS := ["job.grandma_broth", "job.cat_bathroom", "job.refuse_ex_partner", "job.newlyweds_4am", "job.refuse_rush_bribe",
	"job.night_nurse", "job.pizzeria_pays_pizza", "job.bike_interview", "job.museum_time_lock"]
## D-94: places that are not a tenement landing (art/blender/arrival_place.py)
const PLACE_JOBS := {"job.night_nurse": "night", "job.pizzeria_pays_pizza": "evening", "job.bike_interview": "day",
	"job.museum_time_lock": "day"}  # D-102: the museum vault room
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
			if String(s["hold"]) == "":
				assert_true(r["layers"].has(""), "%s %s plate-only hold" % [jid, t])
			else:
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


func test_plate_only_jobs_resolve_with_their_own_time() -> void:
	for jid: String in PLATE_JOBS:
		var job := JobRun.job_by_id(jid)
		assert_false(job.is_empty(), jid)
		var r := ArrivalScene.resolve(job)
		assert_false(r.is_empty(), "%s has a scene" % jid)
		assert_eq(String(r["hold"]), "", "%s plate only" % jid)
		assert_eq((r["layers"] as Dictionary).keys(), [""], "%s: one plate layer, no figure" % jid)
		assert_true(String(r["layers"][""][0]).ends_with("/plate.webp"))
		assert_eq((r["frame_paths"] as Array).size(), 36, "%s 36 frames" % jid)
		assert_true(ArrivalScene.has_scene(job))
	# the job says evening, the story says 1 a.m.: the scene's only time wins
	assert_eq(String(JobRun.job_by_id("job.refuse_rush_bribe").get("time")), "evening")
	assert_eq(ArrivalScene.resolve(JobRun.job_by_id("job.refuse_rush_bribe")).get("time"), "night")
	assert_eq(ArrivalScene.resolve(JobRun.job_by_id("job.grandma_broth")).get("time"), "day")


func test_plate_only_scene_plays_then_dialogue_starts() -> void:
	var scene := await _open(JobRun.job_by_id("job.newlyweds_4am"), false)
	var arr: ArrivalScene = scene.scene
	assert_not_null(arr)
	assert_eq(arr.phase, &"climb")
	assert_false(scene.get_node("Frame").visible, "the UI waits for the climb")
	assert_eq(arr.current_figure, "")
	assert_false(arr.get_node("Canvas/Figure").visible, "no figure layer")
	assert_true(String(arr.get_node("Canvas/Plate").texture.resource_path).ends_with("newlyweds_4am/night/plate.webp"))
	arr._process(3.2)
	assert_eq(arr.phase, &"hold")
	assert_true(scene.get_node("Frame").visible)
	assert_true(scene.dialogue.index >= 0 or scene.dialogue.is_finished(), "dialogue started after the climb")
	arr._process(1.8)
	assert_eq(arr.breath_scale(), 1.0, "nothing breathes on an empty landing")
	arr.show_speaker("bartek")
	assert_eq(arr.current_figure, "", "speakers without a hold leave the frame alone")


func test_plate_only_scene_layout_and_reduce_motion() -> void:
	for size in [Vector2i(412, 915), Vector2i(915, 412)]:
		var scene := await _open(JobRun.job_by_id("job.grandma_broth"), true, size)
		var arr: ArrivalScene = scene.scene
		assert_eq(arr.phase, &"hold", "%s reduce motion: straight to the hold" % size)
		var canvas: Control = arr.get_node("Canvas")
		assert_true(canvas.size.x >= size.x - 1 and canvas.size.y >= size.y - 1, "%s picture covers" % size)
		var door := arr.image_to_stage(Vector2(0.5, 0.45))
		assert_between(door.x, 0.0, float(size.x), "%s door in view" % size)
		assert_between(door.y, 0.0, float(size.y), "%s door in view" % size)
		assert_true(scene.get_node("Frame").visible)
		if size.x > size.y:
			var frame: MarginContainer = scene.get_node("Frame")
			assert_gt(frame.get_theme_constant("margin_left") + frame.get_theme_constant("margin_right"), 300,
				"landscape: the dialogue is a column, not full width")


## D-94: the bike yard, the pizzeria back room and the new block's corridor have their own scene, so the
## verification and the day after show that place instead of a borrowed G07 photo (D-91 `yard`).
func test_place_scenes_replace_the_borrowed_photos() -> void:
	for jid: String in PLACE_JOBS:
		var job := JobRun.job_by_id(jid)
		var r := ArrivalScene.resolve(job)
		assert_false(r.is_empty(), "%s has a scene" % jid)
		assert_eq(String(r["time"]), String(PLACE_JOBS[jid]), "%s: the job's own time" % jid)
		var still := ArrivalScene.place_still(job)
		assert_eq(still.size(), 2, jid)
		if still.size() == 2:
			assert_true(String(still[0]).ends_with("%s/%s/plate.webp" % [jid.trim_prefix("job."), PLACE_JOBS[jid]]), "%s: verification shows the scene" % jid)
		assert_true(ResourceLoader.exists(String(r["layers"][""][0])))
		var dawn := ArrivalScene.place_still(job, "day", false)
		assert_eq(dawn.size(), 2, "%s: the day after shows the same place" % jid)
	assert_eq(String(JobRun.job_by_id("job.bike_interview")["place"]), "yard")
	assert_eq(String(JobRun.job_by_id("job.museum_time_lock")["place"]), "museum")


func test_climb_streams_frames_instead_of_holding_all() -> void:
	# 1080 px frames: all 36 resident would be ~300 MB of video memory on a 4 GB phone.
	var scene := await _open(_job("night"), false)
	var arr: ArrivalScene = scene.scene
	var peak := 0
	for i in 30:
		arr._process(1.0 / 12.0)
		var resident := 0
		for t in arr._frames:
			if t != null:
				resident += 1
		peak = maxi(peak, resident)
	assert_gt(arr.frame, 20, "the climb advanced")
	assert_lte(peak, ArrivalScene.AHEAD + ArrivalScene.SYNC_FIRST, "only a small window of frames is resident")
