extends GutTest
## D-136: the climb's frames (1080x1920, 8.3 MB each as RGBA) never outlive the climb. A frame asked
## for on a worker thread and not shown (the player taps to skip, presses Back, uses reduce motion)
## used to stay with ResourceLoader for the rest of the session: up to 6 frames, 50 MB, per arrival.
## Headless runs have no background loads (D-105), so the loader is replaced by a fake that records
## every request and every take; what must hold is "nothing requested is left untaken".

const JOB := "job.wrong_floor"
const JobArrival := preload("res://scripts/ui/job_arrival.gd")


class FakeLoader:
	extends RefCounted
	var requested := {}     # path -> true while the loader holds the result
	var taken: Array[String] = []
	var decoding := {}      # path -> true: still "in progress"

	func request(path: String) -> void:
		requested[path] = true

	func status(path: String) -> int:
		if not requested.has(path):
			return ResourceLoader.THREAD_LOAD_INVALID_RESOURCE
		return ResourceLoader.THREAD_LOAD_IN_PROGRESS if decoding.has(path) else ResourceLoader.THREAD_LOAD_LOADED

	func take(path: String) -> Texture2D:
		requested.erase(path)
		decoding.erase(path)
		taken.append(path)
		return load(path) as Texture2D

	func held() -> int:
		return requested.size()


var _loader: FakeLoader
var _threaded_before := false


func before_each() -> void:
	_loader = FakeLoader.new()
	_threaded_before = ArrivalScene.threaded_loads
	ArrivalScene.loader_override = _loader
	ArrivalScene.threaded_loads = true


func after_each() -> void:
	ArrivalScene.sweep()
	ArrivalScene.loader_override = null
	ArrivalScene.threaded_loads = _threaded_before
	JobArrival.reduce_motion_override = -1


func _open(reduce: bool) -> Control:
	JobArrival.reduce_motion_override = 1 if reduce else 0
	var job := JobRun.job_by_id(JOB).duplicate(true)
	job["time"] = "night"
	JobRun.start(job)
	var vp := SubViewport.new()
	vp.size = Vector2i(412, 915)
	vp.disable_3d = true
	add_child_autofree(vp)
	var scene: Control = load("res://scenes/job_arrival.tscn").instantiate()
	vp.add_child(scene)
	if scene.scene != null:
		scene.scene.set_process(false)  # the test drives the climb's clock (D-105)
	await get_tree().process_frame
	await get_tree().process_frame
	return scene


func _resident(arr: ArrivalScene) -> int:
	var n := 0
	for t in arr._frames:
		if t != null:
			n += 1
	return n


func test_climb_requests_ahead_and_takes_what_it_shows() -> void:
	var scene := await _open(false)
	var arr: ArrivalScene = scene.scene
	assert_eq(arr.phase, &"climb")
	assert_gt(_loader.held(), 0, "frames are requested ahead of the playhead")
	assert_lte(_loader.held(), ArrivalScene.AHEAD)
	for i in 10:
		arr._process(1.0 / 12.0)
	assert_gt(_loader.taken.size(), 0, "shown frames were taken from the loader")
	assert_lte(_loader.held(), ArrivalScene.AHEAD, "the window does not grow")


func test_played_out_climb_leaves_nothing_behind() -> void:
	var scene := await _open(false)
	var arr: ArrivalScene = scene.scene
	for i in 60:
		arr._process(1.0 / 12.0)
	assert_eq(arr.phase, &"hold")
	assert_eq(_loader.held(), 0, "every requested frame was taken")
	assert_eq(arr.requested_count(), 0)
	assert_eq(_resident(arr), 0, "no climb frame is kept under the dialogue")
	await get_tree().create_timer(ArrivalScene.CROSSFADE_S + 0.15).timeout
	assert_null(arr._seq.texture, "the last frame goes when the cross-fade is over")
	assert_false(arr._seq.visible)


func test_tap_to_skip_frees_the_frames_requested_ahead() -> void:
	var scene := await _open(false)
	var arr: ArrivalScene = scene.scene
	for i in 4:
		arr._process(1.0 / 12.0)
	assert_gt(_loader.held(), 0)
	arr.skip()
	assert_eq(arr.phase, &"hold")
	assert_eq(_loader.held(), 0, "the frames the skip made useless are not left with the loader")
	assert_eq(_resident(arr), 0)
	assert_null(arr._seq.texture)


func test_leaving_mid_climb_frees_them_too() -> void:
	var scene := await _open(false)
	var arr: ArrivalScene = scene.scene
	for i in 4:
		arr._process(1.0 / 12.0)
	assert_gt(_loader.held(), 0)
	scene.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	assert_eq(_loader.held(), 0, "Back during the climb: nothing stays behind")
	assert_eq(ArrivalScene.stray_count(), 0)


func test_frame_still_decoding_when_the_scene_leaves_is_taken_once_it_finishes() -> void:
	var scene := await _open(false)
	var arr: ArrivalScene = scene.scene
	arr._process(1.0 / 12.0)
	var slow: String = _loader.requested.keys()[0]
	_loader.decoding[slow] = true
	scene.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	assert_eq(_loader.held(), 1, "the running decode is not waited for (no hitch on the way out)")
	assert_eq(ArrivalScene.stray_count(), 1)
	_loader.decoding.erase(slow)   # the worker thread is done
	await get_tree().create_timer(0.4).timeout
	assert_eq(_loader.held(), 0, "taken by the sweep, without another arrival scene")
	assert_eq(ArrivalScene.stray_count(), 0)


func test_reduce_motion_loads_no_climb_frame_at_all() -> void:
	var scene := await _open(true)
	var arr: ArrivalScene = scene.scene
	assert_eq(arr.phase, &"hold", "no climb under reduce motion")
	assert_eq(_loader.held(), 0, "nothing requested")
	assert_eq(_loader.taken.size(), 0)
	assert_eq(_resident(arr), 0, "and nothing loaded up front (was 3 frames, 25 MB, for the whole dialogue)")
	assert_not_null(arr._plate.texture, "the hold is there")


## The rule behind the fix, for the next script that streams: a background load is recorded when it
## is requested, so it can be taken back.
func test_every_background_request_of_the_scene_is_recorded() -> void:
	var src := FileAccess.get_file_as_string("res://scripts/ui/arrival_scene.gd")
	assert_eq(src.count("load_threaded_request("), 1, "one place asks for background loads")
	assert_string_contains(src, "_requested[_paths[i]] = true")
	assert_string_contains(src, "func _exit_tree() -> void:\n\t_release_frames()")
