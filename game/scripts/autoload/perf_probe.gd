extends Node
## Device performance probe (perf pass 2026-11-08). Debug builds only; prints to the Godot log
## (`adb logcat -s godot`), nothing leaves the device.
##
## Always on in debug builds (one line per event, negligible cost):
##   LW_BOOT   engine start -> first drawn frame of the main menu: `tree_ms` when the probe (first
##             autoload) enters the tree, then the time each root child took until its `ready`
##             (autoload _ready, the boot scene) and the main menu's first frame.
##   LW_SCENE  every scene change: last tap release -> first frame drawn of the new scene
##             (tap_ms), and the worst frame in the first 2 s after it (hitch_ms, shader
##             compiles / texture uploads that happen after the first frame).
## With the flag file `user://perf_probe` (adb: `run-as <pkg> touch files/perf_probe`) or the
## user arg `--lw-perf`, also:
##   LW_FRAMES every WINDOW_S seconds: frame-time percentiles of real wall-clock frame times
##             (not the smoothed delta), FPS, the engine's worst process / physics step of the last
##             second (proc / phys, Performance TIME_*), average GPU time (root + SubViewports, and
##             the root alone), the renderer's CPU setup time, draw calls and memory counters.
##   LW_SLOW   any frame longer than SLOW_FRAME_MS, split into script time and the rest.
## A flag-file line `day_after=<job id>` shows that job's "day after" scene (D-78) over the job list
## once per session, for measuring it on a device whose save has no queued scene. The scene is freed
## after DAY_AFTER_S without close(), so nothing is written to the save.

const WINDOW_S := 5.0
const HITCH_WINDOW_MS := 2000
const FLAG_FILE := "user://perf_probe"
const SLOW_FRAME_MS := 150.0
const DAY_AFTER_S := 14.0

var enabled := false
var frames_enabled := false
var boot_done := false

var _boot_marks: Array = []  # [name, ticks_ms] when each root child finished _ready
var _tree_ms := 0
var _last_tap_ms := -1
var _scene_path := ""
var _scene_enter_ms := 0
var _scene_hitch_ms := 0.0
var _scene_hitch_open := false
var _last_us := 0
var _frame_ms: PackedFloat32Array = []
var _window_start_ms := 0
var _proc_sum := 0.0
var _phys_sum := 0.0
var _gpu_sum := 0.0
var _gpu_root_sum := 0.0
var _cpu_render_sum := 0.0
var _measured: Array[RID] = []
var _day_after_job := ""
var _click_scan := false


func _enter_tree() -> void:
	enabled = OS.is_debug_build()
	if not enabled:
		set_process(false)
		set_process_input(false)
		return
	process_mode = Node.PROCESS_MODE_ALWAYS
	frames_enabled = FileAccess.file_exists(FLAG_FILE) or OS.get_cmdline_user_args().has("--lw-perf")
	if FileAccess.file_exists(FLAG_FILE):
		for line in FileAccess.get_file_as_string(FLAG_FILE).split("\n"):
			if line.strip_edges() == "click_scan=1":
				_click_scan = true
			if line.strip_edges().begins_with("day_after="):
				_day_after_job = line.strip_edges().substr(10)
	_tree_ms = Time.get_ticks_msec()
	get_tree().node_added.connect(_on_node_added)
	get_tree().scene_changed.connect(_on_scene_changed)


func _ready() -> void:
	if enabled:
		_boot_marks.append([name, Time.get_ticks_msec()])


func _on_node_added(node: Node) -> void:
	if boot_done or node == self or node.get_parent() != get_tree().root:
		return
	node.ready.connect(func() -> void: _boot_marks.append([String(node.name), Time.get_ticks_msec()]), CONNECT_ONE_SHOT)


## Each mark's duration since the previous one: [[name, ms], ...] (the first one since `start_ms`).
static func mark_durations(marks: Array, start_ms: int) -> Array:
	var out := []
	var prev := start_ms
	for m in marks:
		out.append([String(m[0]), int(m[1]) - prev])
		prev = int(m[1])
	return out


## p in 0..1 of an unsorted list of frame times (nearest rank).
static func percentile(values: PackedFloat32Array, p: float) -> float:
	if values.is_empty():
		return 0.0
	var s := values.duplicate()
	s.sort()
	var idx := clampi(int(ceil(p * s.size())) - 1, 0, s.size() - 1)
	return s[idx]


func _input(event: InputEvent) -> void:
	var touch := event as InputEventScreenTouch
	if touch != null and not touch.pressed:
		_last_tap_ms = Time.get_ticks_msec()
		return
	var mouse := event as InputEventMouseButton
	if mouse != null and not mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT:
		_last_tap_ms = Time.get_ticks_msec()


func _on_scene_changed() -> void:
	var scene := get_tree().current_scene
	_scene_path = scene.scene_file_path if scene != null else ""
	_scene_enter_ms = Time.get_ticks_msec()
	await RenderingServer.frame_post_draw
	var now := Time.get_ticks_msec()
	if not boot_done and _scene_path.ends_with("main_menu.tscn"):
		boot_done = true
		var parts := PackedStringArray()
		for d in mark_durations(_boot_marks, _tree_ms):
			parts.append("%s:%d" % [d[0], d[1]])
		print("LW_BOOT engine_to_menu_ms=%d tree_ms=%d menu_first_frame_ms=%d ready=%s" % [
			now, _tree_ms, now - _scene_enter_ms, ",".join(parts)])
	var tap := now - _last_tap_ms if _last_tap_ms >= 0 and now - _last_tap_ms < 15000 else -1
	print("LW_SCENE %s tap_ms=%d first_frame_ms=%d static_mb=%.0f tex_mb=%.0f" % [
		_scene_path.get_file(), tap, now - _scene_enter_ms, _mb(Performance.MEMORY_STATIC),
		_mb(Performance.RENDER_TEXTURE_MEM_USED)])
	if _click_scan and _scene_path.get_file().begins_with("lock_job"):
		_run_click_scan()
	if _day_after_job != "" and _scene_path.ends_with("jobs_list.tscn"):
		_show_day_after(scene, _day_after_job)
		_day_after_job = ""
	_scene_hitch_ms = 0.0
	_scene_hitch_open = true
	_reset_window(now)
	if frames_enabled:
		_measure_viewports.call_deferred()


## D-101 device check (flag line `click_scan=1`): every L2 event x material once through Sfx.play at
## -60 dB in a lock screen, then the native / engine path counts (which clicks have a native slot).
func _run_click_scan() -> void:
	_click_scan = false
	await get_tree().create_timer(2.0).timeout
	var before: Dictionary = Sfx.click_path_counts()
	for e in Sfx.EVENTS:
		for m in Sfx.MATERIALS:
			Sfx.play(e, m, -60.0)
			await get_tree().create_timer(0.03).timeout
	var after: Dictionary = Sfx.click_path_counts()
	print("LW_CLICK_SCAN %d plays: native=%d engine=%d" % [Sfx.EVENTS.size() * Sfx.MATERIALS.size(),
		int(after["native"]) - int(before["native"]), int(after["engine"]) - int(before["engine"])])


func _show_day_after(host: Node, jid: String) -> void:
	var path: String = ContentPacks.job_path(jid)
	if host == null or path == "":
		return
	var da: Node = load("res://scenes/day_after.tscn").instantiate()
	da.set("job", JSON.parse_string(FileAccess.get_file_as_string(path)))
	host.add_child(da)
	print("LW_DAY_AFTER %s shown for %.0f s (probe, no save writes)" % [jid, DAY_AFTER_S])
	await get_tree().create_timer(DAY_AFTER_S).timeout
	if is_instance_valid(da):
		da.queue_free()


func _mb(monitor: Performance.Monitor) -> float:
	return Performance.get_monitor(monitor) / 1048576.0


func _process(_delta: float) -> void:
	var us := Time.get_ticks_usec()
	var ms := 0.0 if _last_us == 0 else (us - _last_us) / 1000.0
	_last_us = us
	if ms <= 0.0:
		return
	var now := Time.get_ticks_msec()
	if ms > SLOW_FRAME_MS:
		# the previous frame was long: how much of it was scripts (process / physics) vs the rest
		# (rendering, shader pipelines, texture uploads, scene loading inside a callback)
		print("LW_SLOW %s frame_ms=%.0f process_ms=%.0f physics_ms=%.0f" % [_scene_path.get_file(), ms,
			Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
			Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0])
	if _scene_hitch_open:
		_scene_hitch_ms = maxf(_scene_hitch_ms, ms)
		if now - _scene_enter_ms > HITCH_WINDOW_MS:
			_scene_hitch_open = false
			print("LW_HITCH %s max_frame_ms=%.0f (first %d ms)" % [_scene_path.get_file(), _scene_hitch_ms, HITCH_WINDOW_MS])
	if not frames_enabled:
		return
	_frame_ms.append(ms)
	_proc_sum += Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
	_phys_sum += Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
	_gpu_sum += _gpu_ms()
	if not _measured.is_empty():
		_gpu_root_sum += RenderingServer.viewport_get_measured_render_time_gpu(_measured[0])
	_cpu_render_sum += RenderingServer.get_frame_setup_time_cpu()
	if now - _window_start_ms >= WINDOW_S * 1000.0:
		_print_window(now)


## GPU time of the last frame: the root viewport plus every SubViewport of the current scene
## (the plan-B section is a SubViewport), from RenderingServer render-time measurement.
func _gpu_ms() -> float:
	var total := 0.0
	for rid in _measured:
		total += RenderingServer.viewport_get_measured_render_time_gpu(rid)
	return total


func _measure_viewports() -> void:
	_measured.clear()
	var root_rid := get_tree().root.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(root_rid, true)
	_measured.append(root_rid)
	var scene := get_tree().current_scene
	if scene == null:
		return
	for vp in scene.find_children("*", "SubViewport", true, false):
		var rid: RID = (vp as SubViewport).get_viewport_rid()
		RenderingServer.viewport_set_measure_render_time(rid, true)
		_measured.append(rid)


func _print_window(now: int) -> void:
	var n := _frame_ms.size()
	var total := 0.0
	var over33 := 0
	for f in _frame_ms:
		total += f
		if f > 33.4:
			over33 += 1
	print("LW_FRAMES %s n=%d fps=%.1f p50=%.1f p95=%.1f p99=%.1f max=%.1f over33=%d proc=%.1f phys=%.1f gpu=%.1f gpu_root=%.1f rs_cpu=%.1f draws=%d static_mb=%.0f tex_mb=%.0f buf_mb=%.0f vmem_mb=%.0f" % [
		_scene_path.get_file(), n, n * 1000.0 / maxf(total, 1.0), percentile(_frame_ms, 0.5),
		percentile(_frame_ms, 0.95), percentile(_frame_ms, 0.99), percentile(_frame_ms, 1.0), over33,
		_proc_sum / maxf(n, 1), _phys_sum / maxf(n, 1), _gpu_sum / maxf(n, 1), _gpu_root_sum / maxf(n, 1),
		_cpu_render_sum / maxf(n, 1),
		Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		_mb(Performance.MEMORY_STATIC), _mb(Performance.RENDER_TEXTURE_MEM_USED),
		_mb(Performance.RENDER_BUFFER_MEM_USED), _mb(Performance.RENDER_VIDEO_MEM_USED)])
	if Sfx.has_method(&"click_path_counts"):
		var c: Dictionary = Sfx.click_path_counts()
		if int(c["native"]) + int(c["engine"]) > 0:
			var st: Dictionary = Sfx.native_stats()
			print("LW_CLICKS native=%d engine=%d bridge_samples=%s oboe_latency_ms=%s call_to_mix_p95_ms=%s xruns=%s stolen=%s engine_out_latency_ms=%.1f" % [
				c["native"], c["engine"], st.get("samplesLoaded", "-"), st.get("estimatedLatencyMs", "-"),
				st.get("callToMixP95Ms", "-"), st.get("xRunCount", "-"), st.get("voicesStolen", "-"),
				AudioServer.get_output_latency() * 1000.0])
	_reset_window(now)


func _reset_window(now: int) -> void:
	_frame_ms.clear()
	_proc_sum = 0.0
	_phys_sum = 0.0
	_gpu_sum = 0.0
	_gpu_root_sum = 0.0
	_cpu_render_sum = 0.0
	_window_start_ms = now
