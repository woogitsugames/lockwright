extends CanvasLayer
## Plan B performance HUD (spike, injected by apply_overlay.sh into a COPY of game/; not game code).
## Shows FPS, frame time p50/p95/p99, 1% low, GPU time, draw calls; logs LW_PERF every 10 s
## (adb logcat -s godot | grep LW_PERF). After 10 minutes it shows a verdict against docs/TECH.md §4
## (spike 4): frame p95 <= 16.7 ms and 1% low >= 55 FPS, in words (PL/EN), not by colour.

const TEST_SECONDS := 600.0
const WARMUP_SECONDS := 60.0
var _label: Label
var _frames: PackedFloat32Array = []      # whole run after warm-up (ms)
var _recent: PackedFloat32Array = []      # last 600 frames
var _gpu: PackedFloat32Array = []
var _t := 0.0
var _log_t := 0.0
var _done := false
var _pl := false


func _ready() -> void:
	layer = 100
	_pl = OS.get_locale_language() == "pl"
	_label = Label.new()
	_label.position = Vector2(12, 44)
	_label.add_theme_font_size_override("font_size", 15)
	_label.add_theme_color_override("font_color", Color(0.96, 0.94, 0.9))
	_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_label.add_theme_constant_override("outline_size", 5)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)
	RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(), true)
	Engine.max_fps = 0
	process_mode = Node.PROCESS_MODE_ALWAYS


func _pct(a: PackedFloat32Array, p: float) -> float:
	if a.is_empty():
		return 0.0
	var s := a.duplicate()
	s.sort()
	return s[int(p * (s.size() - 1))]


func _process(delta: float) -> void:
	var ms := delta * 1000.0
	_t += delta
	_recent.append(ms)
	if _recent.size() > 600:
		_recent = _recent.slice(_recent.size() - 600)
	if _t > WARMUP_SECONDS and not _done:
		_frames.append(ms)
	var g := RenderingServer.viewport_get_measured_render_time_gpu(get_viewport().get_viewport_rid())
	if g > 0.0:
		_gpu.append(g)
		if _gpu.size() > 600:
			_gpu = _gpu.slice(_gpu.size() - 600)
	var lines := PackedStringArray()
	lines.append("%d FPS   %d:%02d" % [Engine.get_frames_per_second(), int(_t) / 60, int(_t) % 60])
	lines.append("frame p50 %.1f  p95 %.1f  p99 %.1f ms" % [_pct(_recent, 0.5), _pct(_recent, 0.95), _pct(_recent, 0.99)])
	lines.append("GPU p50 %.1f  p95 %.1f ms   draws %d" % [_pct(_gpu, 0.5), _pct(_gpu, 0.95), Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)])
	lines.append("RAM %.0f MB  VRAM %.0f MB" % [Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0, Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0])
	if _t < WARMUP_SECONDS:
		lines.append(("Rozgrzewka: %d s" if _pl else "Warm-up: %d s") % int(WARMUP_SECONDS - _t))
	elif not _done:
		lines.append(("Pomiar: zostało %d s" if _pl else "Measuring: %d s left") % int(WARMUP_SECONDS + TEST_SECONDS - _t))
	if _t >= WARMUP_SECONDS + TEST_SECONDS and not _done:
		_done = true
		_log("final")
	if _done:
		lines.append(_verdict())
	_label.text = "\n".join(lines)
	_log_t += delta
	if _log_t >= 10.0:
		_log_t = 0.0
		_log("periodic")


func _one_percent_low_fps(a: PackedFloat32Array) -> float:
	var p99 := _pct(a, 0.99)
	return 1000.0 / max(p99, 0.001)


func _verdict() -> String:
	var p95 := _pct(_frames, 0.95)
	var low := _one_percent_low_fps(_frames)
	var ok := p95 <= 16.7 and low >= 55.0
	var border := not ok and p95 <= 20.0
	var word := ("Przechodzi" if ok else ("Na granicy" if border else "Nie przechodzi")) if _pl else ("Passes" if ok else ("Borderline" if border else "Fails"))
	return ("Wynik 10 min: %s (p95 %.1f ms, próg 16,7; 1%% low %.0f FPS, próg 55). Zrób zrzut ekranu." if _pl else
		"10-min result: %s (p95 %.1f ms, limit 16.7; 1%% low %.0f FPS, limit 55). Take a screenshot.") % [word, p95, low]


func _log(kind: String) -> void:
	var src := _frames if _frames.size() > 0 else _recent
	print("LW_PERF kind=%s t=%.0f fps=%d frame_p50=%.2f frame_p95=%.2f frame_p99=%.2f low1=%.1f gpu_p50=%.2f gpu_p95=%.2f draws=%d vram_mb=%.0f mem_mb=%.0f" % [
		kind, _t, Engine.get_frames_per_second(), _pct(src, 0.5), _pct(src, 0.95), _pct(src, 0.99), _one_percent_low_fps(src),
		_pct(_gpu, 0.5), _pct(_gpu, 0.95), Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0, Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0])
