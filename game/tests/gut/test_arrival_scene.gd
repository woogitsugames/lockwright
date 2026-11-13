extends GutTest
## D-58: arrival scene (stair climb flipbook -> hold frame with the client -> dialogue), data-driven
## from res://data/arrival_scenes.json; jobs without an entry keep the plain arrival screen.

const JOB := "job.wrong_floor"
const PLAIN_JOB := "job.kiosk_shutter"
## early jobs with a plate-only scene (no full-body cut-out of their clients): the door and props tell the story
const PLATE_JOBS := ["job.grandma_broth", "job.cat_bathroom", "job.refuse_ex_partner", "job.newlyweds_4am", "job.refuse_rush_bribe",
	"job.night_nurse", "job.pizzeria_pays_pizza", "job.bike_interview", "job.museum_time_lock",
	"job.krakow_tenement_gate", "job.ghent_beguinage", "job.liege_bakery", "job.uncle_safe_heirs", "job.dollhouse_wooden_lock",
	"job.widow_bureau", "job.t43_09_08_spare_key_hook", "job.charleroi_letters"]
## D-94: places that are not a tenement landing (art/blender/arrival_place.py)
const PLACE_JOBS := {"job.night_nurse": "night", "job.pizzeria_pays_pizza": "evening", "job.bike_interview": "day",
	"job.museum_time_lock": "day",  # D-102: the museum vault room
	"job.krakow_tenement_gate": "rainy", "job.ghent_beguinage": "rainy", "job.liege_bakery": "night"}  # D-108
## D-108: chapter 3-6 jobs whose arrival scene replaces the borrowed G07 photo (scene time = the job's time)
const D108_JOBS := {"job.krakow_tenement_gate": "rainy", "job.ghent_beguinage": "rainy", "job.liege_bakery": "night",
	"job.uncle_safe_heirs": "evening", "job.dollhouse_wooden_lock": "day", "job.widow_bureau": "evening",
	"job.t43_09_08_spare_key_hook": "day", "job.charleroi_letters": "evening"}
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
	# The climb starts in _ready(); the tests drive its clock with arr._process(dt). Without this the
	# real frames below advance it by wall-clock time (a slow first frame on a busy machine is 0.2-3 s),
	# so "12 fps after 1 s" or "still climbing" depended on how loaded the machine was.
	if scene.scene != null:
		scene.scene.set_process(false)
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
	if DisplayServer.get_name() == "headless":
		# D-105: no worker-thread texture loads headless; one left running races the next test's
		# main-thread textures in the dummy renderer ("Parameter t is null").
		assert_false(ArrivalScene.threaded_loads)
		for p: String in arr._paths:
			assert_eq(ResourceLoader.load_threaded_get_status(p), ResourceLoader.THREAD_LOAD_INVALID_RESOURCE, p)


## D-108: the chapter 3-6 scenes play with the job's own time, the verification and the day after show
## that place, and the screen drops the borrowed photo's room sign / door plate (the door is in the picture).
func test_chapter_3_to_6_scenes_replace_the_g07_photo() -> void:
	for jid: String in D108_JOBS:
		var job := JobRun.job_by_id(jid)
		assert_false(job.is_empty(), jid)
		assert_eq(String(job.get("time")), String(D108_JOBS[jid]), "%s: the scene keeps the job's time" % jid)
		var r := ArrivalScene.resolve(job)
		assert_eq(String(r.get("time", "")), String(D108_JOBS[jid]), jid)
		var still := ArrivalScene.place_still(job)
		assert_eq(still.size(), 2, jid)
		if still.size() == 2:
			assert_true(String(still[0]).ends_with("%s/%s/plate.webp" % [jid.trim_prefix("job."), D108_JOBS[jid]]), "%s: verification shows the scene" % jid)
		assert_eq(ArrivalScene.place_still(job, "day", false).size(), 2, "%s: the day after shows the same place" % jid)
	var scene := await _open(JobRun.job_by_id("job.krakow_tenement_gate"), true)
	assert_not_null(scene.scene, "the gate job plays its scene")
	assert_false(scene.place_plate.visible, "no borrowed administration sign beside the title")
	# D-104 audit: the evening G07 photo's door 7 is Mrs Halina's; these evening flats now show their own doors
	for jid: String in ["job.uncle_safe_heirs", "job.widow_bureau", "job.charleroi_letters"]:
		assert_false(ArrivalScene.place_still(JobRun.job_by_id(jid)).is_empty(), "%s: own door, not G07's 7" % jid)


## D-110: the remaining wrong placeholders (D-104 audit). Four places get a scene; jobs in the same place reach
## it through `arrival_from`, so no job there shows the evening G07 door 7, the "Pralnia" sign or the
## locksmith-workshop sign any more; Borys's photo card is his own bike, not the bike_interview frame.
const D110_SCENES := {"job.shared_room_door": "evening", "job.student_dorm": "night", "job.drummer_locker": "evening",
	"job.gosia_workbench_drawer": "day"}
const D110_SHARED := {"job.shared_room_door": ["job.carol_singers_chest", "job.refuse_t43_12_surprise_key",
	"job.warm_room_for_neighbours", "job.wigilia_table_drawer", "job.t43_09_02_blanket_cupboard", "job.t43_09_04_choir_case",
	"job.t43_12_03_community_store", "job.t43_12_04_school_box", "job.t43_12_05_tea_fund_case"],
	"job.drummer_locker": ["job.edek_rehearsal_store", "job.t43_11_05_rehearsal_chest"],
	"job.student_dorm": ["job.t43_10_05_porters_drawer"], "job.gosia_workbench_drawer": ["job.bramah_bureau"]}


func test_placeholder_places_get_their_own_scene() -> void:
	for jid: String in D110_SCENES:
		var r := ArrivalScene.resolve(JobRun.job_by_id(jid))
		assert_eq(String(r.get("time", "")), String(D110_SCENES[jid]), "%s plays its own scene" % jid)
		var plate := "%s/%s/plate.webp" % [jid.trim_prefix("job."), D110_SCENES[jid]]
		for other: String in D110_SHARED[jid]:
			var job := JobRun.job_by_id(other)
			assert_eq(String(job.get("arrival_from", "")), jid, other)
			assert_true(ArrivalScene.resolve(job).is_empty(), "%s has no climb of its own" % other)
			var still := ArrivalScene.place_still(job)
			assert_eq(still.size(), 2, other)
			if still.size() == 2:
				assert_true(String(still[0]).ends_with(plate), "%s shows %s" % [other, plate])
	for other: String in ["job.t43_09_04_choir_case", "job.bramah_bureau"]:
		var scene := await _open(JobRun.job_by_id(other), true)
		assert_false(scene.place_plate.visible, "%s: no borrowed sign / door plate beside the title" % other)
	var photo: Dictionary = JobRun.job_by_id("job.t43_11_02_bicycle_stand")["card_detail"]["photo"]
	assert_false(String(photo["image"]).contains("bike_interview"), "Borys's photo is his own bike")
	assert_true(ResourceLoader.exists(String(photo["image"])))


## D-117: the last evening flats that showed the borrowed G07 photo (its door 7 is Mrs Halina's number, D-104 audit)
## have their own door. Only the hold frame was rendered (`frames: 0`): the arrival shows it at once, without a climb,
## and the verification and the day after show the same landing.
const D117_STILLS := ["job.krystyna_wooden_album", "job.refuse_wrong_letterbox", "job.refuse_t43_09_empty_flat"]


func test_last_door_7_flats_have_their_own_still() -> void:
	for jid: String in D117_STILLS:
		var job := JobRun.job_by_id(jid)
		assert_false(job.is_empty(), jid)
		assert_eq(String(job.get("arrival_from", "")), "", "%s: its own door, not another job's" % jid)
		var r := ArrivalScene.resolve(job)
		assert_false(r.is_empty(), "%s has a scene" % jid)
		assert_eq(String(r.get("time", "")), "evening", jid)
		assert_eq(String(r.get("hold", "x")), "", "%s plate only" % jid)
		assert_eq((r.get("frame_paths", ["x"]) as Array).size(), 0, "%s: still only, no climb" % jid)
		var plate := "%s/evening/plate.webp" % jid.trim_prefix("job.")
		var still := ArrivalScene.place_still(job)
		assert_eq(still.size(), 2, jid)
		if still.size() == 2:
			assert_true(String(still[0]).ends_with(plate), "%s: verification shows its own door" % jid)
			assert_true(ResourceLoader.exists(String(still[0])), jid)
		assert_eq(ArrivalScene.place_still(job, "day", false).size(), 2, "%s: the day after shows the same landing" % jid)
		var scene := await _open(job, false)
		var arr: ArrivalScene = scene.scene
		assert_not_null(arr, "%s plays its scene" % jid)
		if arr == null:
			continue
		assert_eq(arr.phase, &"hold", "%s: no climb frames, straight to the hold" % jid)
		assert_true(scene.get_node("Frame").visible, "%s: the dialogue is not waiting for a climb" % jid)
		assert_true(String(arr.get_node("Canvas/Plate").texture.resource_path).ends_with(plate))
		assert_false(scene.place_plate.visible, "%s: no door plate 7 beside the title" % jid)


## D-117: Aino's chest at the neighbours' fair is outdoors (like her first job in the port), so the screen no
## longer shows the "Pralnia" / "Laundry" room sign of the borrowed changing-room photo.
func test_fair_stall_has_no_laundry_sign() -> void:
	var job := JobRun.job_by_id("job.t43_11_04_sailors_stall")
	assert_eq(String(job.get("place")), "yard")
	for lang: String in ["pl", "en"]:
		assert_eq(JobArrival.plate_path(job, lang), "", "no room sign (%s)" % lang)
	assert_false(JobArrival.g07_image(job).contains("changing_room"), "not the changing-room photo")


## D-122: two chapter 13 places have their own still (CPU render, `frames: 0`, no climb): the tenement cellar with
## storage 7 (the balcony boxes; the found cashbox is in the same cellar and reaches it through `arrival_from`,
## although that job happens in the evening) and the community room's back door to the courtyard (the finale no
## longer borrows the room's front door from job.shared_room_door).
const D122_STILLS := ["job.ch13_01_balcony_boxes", "job.ch13_10_courtyard_door"]


func test_chapter_13_places_have_their_own_still() -> void:
	for jid: String in D122_STILLS:
		var job := JobRun.job_by_id(jid)
		assert_false(job.is_empty(), jid)
		assert_eq(String(job.get("arrival_from", "")), "", "%s: its own place" % jid)
		var r := ArrivalScene.resolve(job)
		assert_false(r.is_empty(), "%s has a scene" % jid)
		assert_eq(String(r.get("time", "")), "day", jid)
		assert_eq(String(r.get("hold", "x")), "", "%s plate only" % jid)
		assert_eq((r.get("frame_paths", ["x"]) as Array).size(), 0, "%s: still only, no climb" % jid)
		var plate := "%s/day/plate.webp" % jid.trim_prefix("job.")
		var still := ArrivalScene.place_still(job)
		assert_eq(still.size(), 2, jid)
		if still.size() == 2:
			assert_true(String(still[0]).ends_with(plate), "%s: verification shows its own place" % jid)
			assert_true(ResourceLoader.exists(String(still[0])), jid)
		assert_eq(ArrivalScene.place_still(job, "day", false).size(), 2, "%s: the day after shows the same place" % jid)
		var scene := await _open(job, false)
		var arr: ArrivalScene = scene.scene
		assert_not_null(arr, "%s plays its scene" % jid)
		if arr == null:
			continue
		assert_eq(arr.phase, &"hold", "%s: no climb frames, straight to the hold" % jid)
		assert_true(scene.get_node("Frame").visible, "%s: the dialogue is not waiting for a climb" % jid)
		assert_true(String(arr.get_node("Canvas/Plate").texture.resource_path).ends_with(plate))
		assert_false(scene.place_plate.visible, "%s: no borrowed sign beside the title" % jid)
	# the refusal in the same cellar: no scene of its own, the cellar's still at every step (its evening falls back to "day")
	var cashbox := JobRun.job_by_id("job.refuse_ch13_08_found_cashbox")
	assert_eq(String(cashbox.get("arrival_from", "")), "job.ch13_01_balcony_boxes")
	assert_true(ArrivalScene.resolve(cashbox).is_empty(), "the cashbox job has no scene entry")
	for t: String in ["", "day"]:
		var st := ArrivalScene.place_still(cashbox, t, t == "")
		assert_eq(st.size(), 2, "cashbox still (%s)" % t)
		if st.size() == 2:
			assert_true(String(st[0]).ends_with("ch13_01_balcony_boxes/day/plate.webp"), "the cashbox is found in the same cellar")
	var cb_scene := await _open(cashbox, false)
	assert_false(cb_scene.place_plate.visible, "cashbox: no room sign beside the title")
	# the finale shows the back door, not the room's front door
	var finale := ArrivalScene.place_still(JobRun.job_by_id("job.ch13_10_courtyard_door"))
	assert_false(String(finale[0]).contains("shared_room_door"), "the finale has its own door")
