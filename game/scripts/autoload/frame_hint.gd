extends Node
## D-88: per-frame CPU work report to Android's performance hint (ADPF) through the
## LockwrightHaptics plugin (`perf_hint_start/report/stop`, platform/android FrameHint.kt).
## On SM-A165F a lock screen ran at 41-44 FPS without touch (the governor keeps the CPU low,
## ~13 ms of game-thread work per frame) and 60 FPS under the thumb (touch boost). With the hint
## the system sees each frame's work against the vsync target and raises the clock as needed.
## Work = first physics/process callback of the frame -> RenderingServer.frame_post_draw.
## No plugin (desktop, iOS, tests) or Android < 12: does nothing.
## Off by default (POMIARY §10): on SM-A165F the session worked but gave ~+1 FPS without touch in a
## release build (the rest is GPU-bound) and more 25-33 ms frames under constant touch. Opt in with
## the settings key `adpf_hint` = true (no UI) to re-measure on other phones.

const PLUGIN := "LockwrightHaptics"

var active := false
var reports := 0
var _plugin: Object = null
var _frame_start_us := -1


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not bool(Settings.get_value(&"adpf_hint", false)) or not Engine.has_singleton(PLUGIN):
		return
	var p: Object = Engine.get_singleton(PLUGIN)
	if not (p.has_method(&"has_java_method") and bool(p.call(&"has_java_method", &"perf_hint_start"))):
		return
	var hz := DisplayServer.screen_get_refresh_rate()
	var target_us := int(1000000.0 / (hz if hz > 1.0 else 60.0))
	# called on the game thread: the hint session is bound to it
	active = bool(p.call(&"perf_hint_start", target_us))
	if not active:
		return
	_plugin = p
	get_tree().physics_frame.connect(_mark_start)
	get_tree().process_frame.connect(_mark_start)
	RenderingServer.frame_post_draw.connect(_on_post_draw)
	print("FrameHint: ADPF session for the game thread, target %d us" % target_us)


func _mark_start() -> void:
	if _frame_start_us < 0:
		_frame_start_us = Time.get_ticks_usec()


func _on_post_draw() -> void:
	if _frame_start_us < 0:
		return
	var work := work_us(_frame_start_us, Time.get_ticks_usec())
	_frame_start_us = -1
	_plugin.call(&"perf_hint_report", work)
	reports += 1


## Work time reported for a frame (clamped to 1 us .. 1 s).
static func work_us(start_us: int, end_us: int) -> int:
	return clampi(end_us - start_us, 1, 1000000)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_PREDELETE:
		if active and _plugin != null:
			_plugin.call(&"perf_hint_stop")
			active = false
