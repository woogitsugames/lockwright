class_name LockTimeLockView
extends LockLiftLayerView
## D-59: plan-B screen for the time-lock REPAIR (LOCKS.md §2.24, job.museum_time_lock): the museum's
## clock movement has stopped and the locksmith puts its train back in mesh and gets it running; the
## vault is not opened. lockcore runs it on the wafer module: each element is a train wheel, its
## position the seating depth (lowered onto its pivot with the tweezers, right thumb), tension the
## winding key (left thumb). Layers from art/blender/plates/time_lock_plate.py:
##   wheels hang above their pivots until seated (set = meshed, on the line); too deep = jammed teeth
##   (tilted); the barrel turns a little with the key; once every wheel is meshed and the key holds the
##   run band, the whole train turns (each wheel at its own ratio, alternating direction), the pallet
##   rocks with each tick and the dial hand advances with hold_progress (= the run). Nothing turns
##   that is not driven (DESIGN.md: no dead gears).
## N-86: the wheels are cut at one module, so rim / pinion radii are the tooth ratios and the train
## stays in mesh as it turns. The key turns the barrel in ratchet clicks (layers.json wind_step_deg,
## a whole number of barrel teeth), so the barrel never stands half a tooth off pinion 0.

var _phase := 0.0      # train turn of the barrel, radians
var _rock := 0.0
var _wind := 0.0
var _ratios: Array[float] = []
var _wind_step := 0.0  # degrees per ratchet click (0: smooth, plates without the key)
var _letdown_s := 0.0
const LETDOWN_S := 0.15  # one ratchet tooth back per step while the key lets the spring down


func _ready() -> void:
	super._ready()
	# gear ratios from the plate: wheel i turns (rim before / own pinion) times the one before
	var r_prev := float(meta.get("barrel_mm", 12.0))
	var ratio := 1.0
	_wind_step = float(meta.get("wind_step_deg", 0.0))
	var radii: Array = meta.get("radii_mm", [])
	var pins: Array = meta.get("pinions_mm", [])
	for i in radii.size():
		ratio *= -r_prev / maxf(float(pins[i]), 0.5)
		_ratios.append(ratio)
		r_prev = float(radii[i])


func _first_slot_for(_n: int) -> int:
	return 0  # the train starts at the barrel


func present(vm: Dictionary, input: Dictionary, delta: float = 1.0 / 120.0) -> void:
	var running := float(vm.get("hold_progress", 0.0)) > 0.0 and not bool(vm.get("open", false)) or (_opened and not vm.is_empty())
	if running and delta < 0.5:
		_phase += delta * 0.05          # barrel: slow; the escape wheel follows at its ratio
		_rock = 6.0 * signf(sin(Time.get_ticks_msec() * 0.0157))  # 2.5 ticks a second
	else:
		_rock = lerpf(_rock, 0.0, 0.2)
	var t := clampf(float(vm.get("tension", input.get("tension", 0.0))), 0.0, 1.0)
	var target := 25.0 * t
	if delta >= 0.5 or _wind_step <= 0.0 or UiA11y.reduce_motion():
		_wind = target if delta >= 0.5 or _wind_step > 0.0 else lerpf(_wind, target, 0.2)
		_letdown_s = 0.0
	elif target >= _wind - 0.01:
		_wind = lerpf(_wind, target, 0.2)  # winding: the key turns the barrel, the click drops into each tooth
		_letdown_s = 0.0
	else:
		# N-97: letting go is a let-down, not a spring-back: the thumb is the key held against the spring
		# (the click lifted, as a watchmaker powers a train under the key), so the barrel goes back one
		# ratchet tooth at a time, LETDOWN_S each (DESIGN: 100-250 ms steps), never in one jump
		_letdown_s += delta
		if _letdown_s >= LETDOWN_S:
			_letdown_s = 0.0
			_wind = maxf(target, snappedf(_wind, _wind_step) - _wind_step)
	super.present(vm, input, delta)


func is_running() -> bool:
	return absf(_rock) > 0.5


func train_phase() -> float:
	return _phase


func _centre(slot: int) -> Vector2:
	var c: Array = meta.get("centres_px", [])
	if slot < c.size():
		return Vector2(c[slot][0], c[slot][1])
	return anchor(slot)


func _element_xf(slot: int) -> Transform2D:
	var d := travel() * _off[slot]
	var turn := rad_to_deg(_phase * (_ratios[slot] if slot < _ratios.size() else 1.0))
	return Transform2D(0.0, d) * _rot_about(turn + _tilt[slot], _centre(slot))


## The barrel's turn in degrees: the key's wind in whole ratchet clicks plus the train's run.
func barrel_turn_deg() -> float:
	var w := snappedf(_wind, _wind_step) if _wind_step > 0.0 else _wind
	return w + rad_to_deg(_phase)


func _draw_progress_layer() -> void:
	var b: Array = meta.get("barrel_px", [0.0, 0.0])
	_draw_layer("barrel", _rot_about(barrel_turn_deg(), Vector2(b[0], b[1])), 0.45)
	var p: Array = meta.get("pallet_px", [0.0, 0.0])
	_draw_layer("pallet", _rot_about(_rock, Vector2(p[0], p[1])), 0.4)


func _draw_extra_front() -> void:
	var h: Array = meta.get("hand_px", [0.0, 0.0])
	_draw_layer("hand", _rot_about(300.0 * _progress, Vector2(h[0], h[1])), 0.4)
