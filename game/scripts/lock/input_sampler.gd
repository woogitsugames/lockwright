class_name InputSampler
extends Node

## D-107 tension lock latched / released (lock scene: clamp on the wrench, tuk, TalkBack line).
signal latch_changed(on: bool)
## Touch → InputFrame sampler (ARCHITECTURE.md §8). Left zone = tension (vertical),
## right zone = pick 2D (depth = x, lift = y); families using rotate/push read them
## from the right-zone gestures (R-01). Sampled every physics step (120 Hz); dead zone
## and smoothing live here, not in the lock logic. Thumb zones are invisible (D-12).
##
## N-62: tension and lift are scaled in dp of thumb travel, not in screen fractions. The
## old mapping (tension = drag / screen height, lift = drag / half height) needed ~330 dp
## of left-thumb drag to reach the working band and ~250 dp of right-thumb drag to reach
## the shear line, so on a phone the pins barely moved and nothing ever set.
##
## D-52 "auto tension": with Settings `auto_tension` on, the sampler holds a steady safe
## tension (auto_level, the lock scene may tune it per lock state) and the right thumb
## alone drives the pick. A short tap on the left zone releases tension for RELEASE_S,
## which clears an overset without dropping set pins (drop grace ≥ 350 ms in every tier).
##
## D-107 "tension lock" (HUD.md §9.2, motor; Settings `tension_lock`, two-thumb mode only): after the
## tension thumb lets go, T is held for LATCH_GRACE_S; a double tap on the tension half inside that
## time latches it (the thumb can rest). While latched, a drag on the tension half still changes T
## (relative, it stays latched at the new value) and a single tap lets go (T -> 0: an overset is
## fixed the usual way). Without the option nothing changes.
##
## D-90 "swap thumbs" (HUD.md §9.2, left-handed): Settings `swap_thumbs` puts tension on the right
## half and the pick on the left half. The picture does not mirror (the lock has its side): depth
## still grows to the right inside the pick half, lift is still up. "left"/"right" in the API below
## mean the tension / pick thumb, whichever side of the screen they are on.

const DEAD_ZONE_DP := 10.0
const SMOOTHING := 0.45
const TENSION_FULL_DP := 200.0  # left-thumb drag for tension 1.0 (working band 0.25–0.45 ≈ 50–90 dp)
const LIFT_FULL_DP := 200.0     # right-thumb drag for lift 1.0 (shear line ≈ 0.55 ≈ 110 dp)
const AUTO_LEVEL := 0.35        # D-52: centre of the tier 1–2 working band (probe: 0.25–0.45 opens)
const RELEASE_S := 0.1          # D-52: tap on the left zone = let go of tension this long (< drop grace)
const TAP_MAX_S := 0.35

var tension := 0.0
var pick_depth := 0.5
var pick_lift := 0.0
var rotate := 0.0   # ring_combo / warded: circular gesture on the right zone
var push := 0.0     # axial sliders: press-and-hold on the right zone
var tool := 0       # active tool slot (tool_swap button elsewhere)
## QA / replays: sample() already returns lockcore's input frame (rotate, tool ...), so the lock
## scene feeds it straight to the session (no family thumb mapping, no hint autopilot).
var raw := false
## Left thumb, signed: drag up from the touch-down point = +, down = - (warded probe: turn
## forward / back, |value| = turning force). Same dp scale as tension, no auto level.
var tension_signed := 0.0

## D-52: steady tension from the control layer instead of the left thumb.
var auto_tension := false
var auto_level := AUTO_LEVEL
## Seconds left of a released tension (auto mode tap, or the tutorial's master hand).
var release_left := 0.0
## Frozen pick (loupe open, ONBOARDING §6.2): input is still read but depth/lift hold.
var frozen := false
## D-90: tension zone on the right, pick zone on the left.
var swap_thumbs := false
## D-107 tension lock (see above).
const LATCH_GRACE_S := 0.45
var tension_lock := false
var latched := false
var latched_t := 0.0
var _grace_left := 0.0      # T held after the thumb let go (time for the double tap)
var _grace_t := 0.0
var _grace_taps := 0
var _latch_base := 0.0      # latched T when the current drag started
var _tension_moved := false # the current tension touch moved past the dead zone (not a tap)

var _touch_tension := -1
var _touch_pick := -1
var _tension_raw := 0.0
var _depth_raw := 0.5
var _lift_raw := 0.0
var _rotate_raw := 0.0
var _push_raw := 0.0
var _signed_raw := 0.0
var _pick_last_pos := Vector2.ZERO
# D-24: tension and lift are measured relative to the touch-down point, not the screen edge
var _tension_start := Vector2.ZERO
var _pick_start := Vector2.ZERO
var _tension_down_ms := 0


func _ready() -> void:
	auto_tension = bool(Settings.get_value(&"auto_tension", false))
	swap_thumbs = bool(Settings.get_value(&"swap_thumbs", false))
	tension_lock = bool(Settings.get_value(&"tension_lock", false))


func left_down() -> bool:
	return _touch_tension >= 0


func right_down() -> bool:
	return _touch_pick >= 0


func _dead_zone() -> float:
	# viewport units are dp (stretch mode canvas_items, base 412×915)
	return DEAD_ZONE_DP


func _size() -> Vector2:
	var size := get_viewport().get_visible_rect().size if is_inside_tree() else Vector2.ZERO
	if size.x <= 0.0 or size.y <= 0.0:
		size = Vector2(412, 915)  # headless fallback for tests
	return size


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			var half := maxf(_size().x, 412.0) * 0.5
			if (event.position.x < half) != swap_thumbs:
				_touch_tension = event.index
				_tension_start = event.position
				_tension_down_ms = Time.get_ticks_msec()
				_tension_raw = 0.0
				_tension_moved = false
				_latch_base = latched_t
				_update_tension(event.position)
			else:
				_touch_pick = event.index
				_pick_start = event.position
				_pick_last_pos = event.position
				_lift_raw = 0.0
				_update_pick(event.position)
		else:
			if event.index == _touch_tension:
				var was_tap := not _tension_moved and Time.get_ticks_msec() - _tension_down_ms <= int(TAP_MAX_S * 1000.0)
				var held_t := tension
				_touch_tension = -1
				_tension_raw = 0.0
				_signed_raw = 0.0
				if auto_tension and was_tap:
					release_tension()
				elif lock_active():
					_on_tension_up(was_tap, held_t)
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
			var size := _size()
			var center := Vector2(size.x * (0.25 if swap_thumbs else 0.75), size.y * 0.5)
			var a0: float = (_pick_last_pos - center).angle()
			var a1: float = (event.position - center).angle()
			_rotate_raw = clampf(_rotate_raw + (a1 - a0), -1.0, 1.0)
			_pick_last_pos = event.position


## D-52: let go of the tension for a moment (left-zone tap in auto mode).
func release_tension(seconds: float = RELEASE_S) -> void:
	release_left = maxf(release_left, seconds)
	tension = 0.0


## D-107: the tension lock works only with two thumbs (auto tension already holds T).
func lock_active() -> bool:
	return tension_lock and not auto_tension


func _on_tension_up(was_tap: bool, held_t: float) -> void:
	if latched:
		if was_tap:
			set_latched(false)  # a single tap lets go
		return  # a drag while latched: stays latched at the new T
	if not was_tap:
		_grace_t = held_t  # the thumb let go after holding: a double tap now latches this T
		_grace_left = LATCH_GRACE_S
		_grace_taps = 0
	elif _grace_left > 0.0:
		_grace_taps += 1
		_grace_left = LATCH_GRACE_S
		if _grace_taps >= 2:
			latched_t = _grace_t
			set_latched(true)


func set_latched(on: bool) -> void:
	if on == latched:
		return
	latched = on
	_grace_left = 0.0
	_grace_taps = 0
	if not on:
		latched_t = 0.0
	latch_changed.emit(on)


func _update_tension(pos: Vector2) -> void:
	# D-24: drag up from the touch-down point = tension; the touch point itself is always 0
	var t := clampf((_tension_start.y - pos.y) / TENSION_FULL_DP, 0.0, 1.0)
	var sg := clampf((_tension_start.y - pos.y) / TENSION_FULL_DP, -1.0, 1.0)
	if absf(sg) * TENSION_FULL_DP <= _dead_zone() * 0.5:
		sg = 0.0
	elif absf(sg) * TENSION_FULL_DP > _dead_zone():
		if not _tension_moved and _grace_left > 0.0 and not latched:
			_grace_left = 0.0  # a real drag during the grace: plain two-thumb control again
		_tension_moved = true
	if latched:
		latched_t = clampf(_latch_base + sg, 0.0, 1.0)  # "Zmiana T dalej działa przesunięciem"
	_signed_raw = sg
	if absf(t - _tension_raw) * TENSION_FULL_DP > _dead_zone() * 0.5 or t == 0.0:
		_tension_raw = t


func _update_pick(pos: Vector2) -> void:
	var size := _size()
	var half := size.x * 0.5
	var local_x := (pos.x - (0.0 if swap_thumbs else half)) / half
	if absf(local_x - _depth_raw) * half > _dead_zone():
		_depth_raw = clampf(local_x, 0.0, 1.0)
	# D-24: lift is the vertical drag from the touch-down point (up = positive)
	var l := clampf((_pick_start.y - pos.y) / LIFT_FULL_DP, -1.0, 1.0)
	if absf(l - _lift_raw) * LIFT_FULL_DP > _dead_zone() * 0.5:
		_lift_raw = l


func _physics_process(delta: float) -> void:
	var target_t := _tension_raw
	if auto_tension:
		target_t = auto_level
	elif latched:
		target_t = latched_t
	elif _grace_left > 0.0:
		_grace_left -= delta
		if _touch_tension < 0 or not _tension_moved:
			target_t = _grace_t  # taps of the double tap do not drop the held tension
	if release_left > 0.0:
		release_left -= delta
		target_t = 0.0
		tension = 0.0
	tension = lerpf(tension, target_t, SMOOTHING)
	if not frozen:
		pick_depth = lerpf(pick_depth, _depth_raw, SMOOTHING)
		pick_lift = lerpf(pick_lift, _lift_raw, SMOOTHING)
	rotate = lerpf(rotate, _rotate_raw, SMOOTHING)
	tension_signed = lerpf(tension_signed, _signed_raw, SMOOTHING)
	push = lerpf(push, _push_raw, SMOOTHING)


func sample() -> Dictionary:
	return {
		"tension": tension, "pick_depth": pick_depth, "pick_lift": pick_lift,
		"rotate": rotate, "push": push, "tool": tool,
	}
