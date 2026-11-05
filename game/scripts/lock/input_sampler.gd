class_name InputSampler
extends Node
## Touch → InputFrame sampler (ARCHITECTURE.md §8). Left zone = tension (vertical),
## right zone = pick 2D (depth = x, lift = y); families using rotate/push read them
## from the right-zone gestures (R-01). Sampled every physics step (120 Hz); dead zone
## and smoothing live here, not in the lock logic. Thumb zones are invisible (D-12).

const DEAD_ZONE_DP := 10.0
const SMOOTHING := 0.45

var tension := 0.0
var pick_depth := 0.5
var pick_lift := 0.0
var rotate := 0.0   # ring_combo / warded: circular gesture on the right zone
var push := 0.0     # axial sliders: press-and-hold on the right zone
var tool := 0       # active tool slot (tool_swap button elsewhere)

var _touch_tension := -1
var _touch_pick := -1
var _tension_raw := 0.0
var _depth_raw := 0.5
var _lift_raw := 0.0
var _rotate_raw := 0.0
var _push_raw := 0.0
var _pick_last_pos := Vector2.ZERO


func _dead_zone() -> float:
	return DEAD_ZONE_DP * DisplayServer.screen_get_scale()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			var vp := get_viewport().get_visible_rect().size
			var half := maxf(vp.x, 412.0) * 0.5
			if event.position.x < half:
				_touch_tension = event.index
				_update_tension(event.position)
			else:
				_touch_pick = event.index
				_pick_last_pos = event.position
				_update_pick(event.position)
		else:
			if event.index == _touch_tension:
				_touch_tension = -1
				_tension_raw = 0.0
			elif event.index == _touch_pick:  # R-02: elif, not nested — right thumb release must reset
				_touch_pick = -1
				_lift_raw = 0.0
				_rotate_raw = 0.0
				_push_raw = 0.0
	if event is InputEventScreenDrag:
		if event.index == _touch_tension:
			_update_tension(event.position)
		elif event.index == _touch_pick:
			_update_pick(event.position)
			# rotate: angular delta around the zone center (ring_combo)
			var size := get_viewport().get_visible_rect().size
			if size.x <= 0.0 or size.y <= 0.0:
				size = Vector2(412, 915)
			var center := Vector2(size.x * 0.75, size.y * 0.5)
			var a0: float = (_pick_last_pos - center).angle()
			var a1: float = (event.position - center).angle()
			_rotate_raw = clampf(_rotate_raw + (a1 - a0), -1.0, 1.0)
			_pick_last_pos = event.position


func _update_tension(pos: Vector2) -> void:
	var h := maxf(get_viewport().get_visible_rect().size.y, 1.0)
	var t := 1.0 - clampf(pos.y / h, 0.0, 1.0)
	if absf(t - _tension_raw) > _dead_zone() / h:
		_tension_raw = t


func _update_pick(pos: Vector2) -> void:
	var size := get_viewport().get_visible_rect().size
	if size.x <= 0.0 or size.y <= 0.0:
		size = Vector2(412, 915)  # headless fallback for tests
	var half := size.x * 0.5
	var local := Vector2((pos.x - half) / half, pos.y / size.y)
	if absf(local.x - _depth_raw) * half > _dead_zone():
		_depth_raw = clampf(local.x, 0.0, 1.0)
	if absf(local.y - (1.0 - (_lift_raw + 1.0) * 0.5)) * size.y > _dead_zone():
		_lift_raw = clampf(1.0 - 2.0 * local.y, -1.0, 1.0)


func _physics_process(_delta: float) -> void:
	tension = lerpf(tension, _tension_raw, SMOOTHING)
	pick_depth = lerpf(pick_depth, _depth_raw, SMOOTHING)
	pick_lift = lerpf(pick_lift, _lift_raw, SMOOTHING)
	rotate = lerpf(rotate, _rotate_raw, SMOOTHING)
	push = lerpf(push, _push_raw, SMOOTHING)


func sample() -> Dictionary:
	return {
		"tension": tension, "pick_depth": pick_depth, "pick_lift": pick_lift,
		"rotate": rotate, "push": push, "tool": tool,
	}
