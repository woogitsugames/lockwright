class_name InputSampler
extends Node
## Touch → InputFrame sampler (ARCHITECTURE.md §8). Left half of the screen is
## tension on the vertical axis, right half is the pick in 2D (depth = x, lift = y).
## Sampled every physics step (120 Hz); dead zone and smoothing live here, not in
## the lock logic. Thumb zones are invisible (D-12).

const DEAD_ZONE_PX := 10.0
const SMOOTHING := 0.45

var tension := 0.0
var pick_depth := 0.5
var pick_lift := 0.0

var _touch_tension := -1  # touch index driving the left zone, -1 = none
var _touch_pick := -1
var _tension_raw := 0.0
var _depth_raw := 0.5
var _lift_raw := 0.0


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			var half := get_viewport().get_visible_rect().size.x * 0.5
			if event.position.x < half:
				_touch_tension = event.index
				update_tension(event.position)
			else:
				_touch_pick = event.index
				update_pick(event.position)
		else:
			if event.index == _touch_tension:
				_touch_tension = -1
				_tension_raw = 0.0
				if event.index == _touch_pick:
					_touch_pick = -1
	if event is InputEventScreenDrag:
		if event.index == _touch_tension:
			update_tension(event.position)
		elif event.index == _touch_pick:
			update_pick(event.position)


func update_tension(pos: Vector2) -> void:
	# vertical axis: bottom of the zone = 0, top = 1
	var h := get_viewport().get_visible_rect().size.y
	var t := 1.0 - clampf(pos.y / h, 0.0, 1.0)
	if absf(t - _tension_raw) > DEAD_ZONE_PX / h:
		_tension_raw = t


func update_pick(pos: Vector2) -> void:
	var size := get_viewport().get_visible_rect().size
	var half := size.x * 0.5
	var local := Vector2((pos.x - half) / half, pos.y / size.y)
	if absf(local.x - _depth_raw) * size.x > DEAD_ZONE_PX:
		_depth_raw = clampf(local.x, 0.0, 1.0)
	if absf(local.y - (1.0 - (_lift_raw + 1.0) * 0.5)) * size.y > DEAD_ZONE_PX:
		_lift_raw = clampf(1.0 - 2.0 * local.y, -1.0, 1.0)


func _physics_process(_delta: float) -> void:
	tension = lerpf(tension, _tension_raw, SMOOTHING)
	pick_depth = lerpf(pick_depth, _depth_raw, SMOOTHING)
	pick_lift = lerpf(pick_lift, _lift_raw, SMOOTHING)


func sample() -> Dictionary:
	return {"tension": tension, "pick_depth": pick_depth, "pick_lift": pick_lift}
