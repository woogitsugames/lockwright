class_name ChalkHint
extends Control
## Chalk gesture hint (ONBOARDING §2.2, D-80; replaces the G23 ghost hand of D-76/D-77): a chalk
## touch ring where the finger goes and a chalk trail drawn on behind it along the gesture path, at
## the speed we want from the player; then the trail fades (FADE_S, out-cubic, no overshoot). Same
## chalk as the lesson lines (ChalkLayer.draw_stroke / draw_ring, the shared grain material): no
## clean vector line, no glow, no colour, no hand. mouse_filter IGNORE: never takes a touch.
##
## H2 play_gesture(): the ring travels from -> to (ease in-out), the trail grows behind it (up to the
## ring's edge); `repeats` times, a hold shows a second inner ring ("keep pressing").
## H4 begin_follow() / follow() / end_follow(): no gesture of its own; the ring sits on the virtual
## touch point of the master hand (the tool the game moves) and the trail follows it.
## Reduce Motion: static chalk: the whole path, its arrowhead and the ring at the start, no travel.
##
## Every point is clamped inside `bounds` (the safe area, shrunk by the ring), and the ring is pushed
## out of the `avoid` rects (the tension wrench), so nothing is clipped at a screen edge (N-73).
## dp == canvas units (dp_scale.gd), coordinates are the parent control's.

## Eased 0..1 travel of the current repeat (0 at the start pose, 1 during the hold); the scene can
## answer it (the plug face turns with a tension gesture).
signal gesture_progress(t: float)
## All repeats are done and the chalk has faded (also after end_follow()).
signal gesture_finished

const FADE_S := 0.2              # appear / fade (DESIGN: 100–250 ms)
const RING_R := 24.0             # touch ring: 48 dp across, the size of a touch target
const HOLD_R := 13.0             # inner ring while the gesture holds
const STROKE_DP := 3.0
const MARGIN_DP := 6.0           # from the safe-area edge
const MIN_STEP_DP := 2.0         # trail point spacing while following
const MAX_POINTS := 96

enum Mode { IDLE, PLAY, FOLLOW, STATIC }
enum _Phase { FADE_IN, MOVE, HOLD, CLEAR, FADE_OUT }

## Left-handed "swap thumbs" option (HUD §9): mirrored across the parent's width.
var mirror := false
## Safe area in parent coordinates; empty = the parent's rect (SafeArea applied).
var bounds := Rect2()
## Rects (parent coordinates) the ring must not sit on (H4: the tension wrench / plug face).
var avoid: Array[Rect2] = []
## System Reduce Motion: static chalk instead of the drawn-on trail.
var reduce_motion := false

var mode := Mode.IDLE
## Current (virtual) touch point: the ring's centre, clamped and mirrored.
var touch_point := Vector2.ZERO
## The chalk trail drawn so far (clamped and mirrored points).
var trail := PackedVector2Array()
var alpha := 0.0

var _phase := _Phase.FADE_IN
var _t := 0.0
var _from := Vector2.ZERO
var _to := Vector2.ZERO
var _duration := 0.0
var _repeats := 1
var _repeat := 0
var _hold_s := 0.0
var _static_s := 0.0
var _holding := false
var _shift := Vector2.ZERO  # whole-path offset that keeps the gesture off the avoid rects


func _init() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE  # never intercept the player's touches
	material = ChalkLayer.grain_material()
	set_process(false)  # idle: no redraw every frame


func _ready() -> void:
	_fit_parent()


func _fit_parent() -> void:
	var p := get_parent_control()
	if p != null:
		position = Vector2.ZERO
		size = p.size


func is_playing() -> bool:
	return mode != Mode.IDLE


## Static chalk (Reduce Motion): the path is drawn whole, nothing travels.
func is_static() -> bool:
	return mode == Mode.STATIC


## H2: show the gesture from_dp -> to_dp in duration_s, `repeats` times, holding hold_s at the end.
func play_gesture(from_dp: Vector2, to_dp: Vector2, duration_s: float, repeats := 2, hold_s := 0.0) -> void:
	_fit_parent()
	_from = from_dp
	_to = to_dp
	_shift = fit_shift(_from, _to)
	_duration = maxf(duration_s, 0.0)
	_repeats = maxi(repeats, 1)
	_hold_s = maxf(hold_s, 0.0)
	_repeat = 0
	_t = 0.0
	alpha = 0.0
	_holding = false
	if reduce_motion:
		_show_static(_repeats * (_duration + _hold_s) + FADE_S)
		return
	mode = Mode.PLAY
	_phase = _Phase.FADE_IN
	touch_point = place(_from)
	trail = PackedVector2Array([touch_point])
	set_process(true)
	queue_redraw()


## H1 (N-83): only the chalk touch ring where the thumb goes, for `seconds` (then it fades). Replaces
## the dark thumb_dent imprint, which in landscape lay as a loose dark blob beside the moved chalk.
func show_touch(at_dp: Vector2, seconds: float) -> void:
	_fit_parent()
	_from = at_dp
	_to = at_dp
	_shift = fit_shift(at_dp, at_dp)
	alpha = 0.0
	_holding = false
	mode = Mode.STATIC
	_phase = _Phase.FADE_IN
	_t = 0.0
	_static_s = maxf(seconds, 0.0)
	touch_point = place(at_dp)
	trail = PackedVector2Array([touch_point])
	set_process(true)
	queue_redraw()


## H4: the master hand starts; the ring follows the virtual touch point from follow().
## from/to: the planned path (drawn whole under Reduce Motion).
func begin_follow(from_dp: Vector2, to_dp: Vector2) -> void:
	_fit_parent()
	_from = from_dp
	_to = to_dp
	_shift = fit_shift(_from, _to)
	_t = 0.0
	alpha = 0.0
	_holding = false
	if reduce_motion:
		_show_static(-1.0)  # until end_follow()
		return
	mode = Mode.FOLLOW
	_phase = _Phase.FADE_IN
	touch_point = place(from_dp)
	trail = PackedVector2Array([touch_point])
	set_process(true)
	queue_redraw()


## H4: the virtual touch point of this physics step (parent coordinates, before mirroring).
func follow(p: Vector2) -> void:
	if mode != Mode.FOLLOW or _phase == _Phase.FADE_OUT:
		return
	var q := place(p)
	touch_point = q
	if trail.is_empty() or trail[trail.size() - 1].distance_to(q) >= MIN_STEP_DP:
		trail.append(q)
		if trail.size() > MAX_POINTS:
			trail = trail.slice(trail.size() - MAX_POINTS)
	queue_redraw()


## H4 over: the trail and the ring fade.
func end_follow() -> void:
	if mode in [Mode.FOLLOW, Mode.STATIC]:
		_phase = _Phase.FADE_OUT
		_t = 0.0
		set_process(true)


func stop() -> void:
	mode = Mode.IDLE
	alpha = 0.0
	trail = PackedVector2Array()
	set_process(false)
	queue_redraw()


func _show_static(seconds: float) -> void:
	mode = Mode.STATIC
	_phase = _Phase.FADE_IN
	_static_s = seconds
	touch_point = place(_from)
	trail = PackedVector2Array([touch_point, place(_to)])
	set_process(true)
	queue_redraw()


func _mirrored(p: Vector2) -> Vector2:
	return Vector2(size.x - p.x, p.y) if mirror else p


## Offset for the whole gesture path so the ring never sweeps over an avoid rect (the tension wrench,
## the lock section) and stays in the safe area: the smallest shift past a colliding rect along
## either axis (0 when nothing collides; a path that cannot be shifted keeps 0 and place() pushes
## single points instead). The thumb zones are whole screen halves, so a shifted gesture still works.
func fit_shift(from_dp: Vector2, to_dp: Vector2) -> Vector2:
	var a := _mirrored(from_dp)
	var b := _mirrored(to_dp)
	var box := Rect2(a, Vector2.ZERO).expand(b).grow(0.5)
	var pad := RING_R + STROKE_DP
	if not _box_hits(box, pad):
		return Vector2.ZERO
	var inner := safe_bounds().grow(-(pad + MARGIN_DP))
	var best := Vector2.ZERO
	var bd := INF
	for r in avoid:
		var g := r.grow(pad + 1.0)
		for off: Vector2 in [Vector2(0, g.position.y - box.end.y), Vector2(0, g.end.y - box.position.y),
				Vector2(g.position.x - box.end.x, 0), Vector2(g.end.x - box.position.x, 0)]:
			var moved := Rect2(box.position + off, box.size)
			if inner.size.x > 0.0 and not inner.grow(1.0).encloses(moved):
				continue
			if _box_hits(moved, pad):
				continue
			if off.length() < bd:
				bd = off.length()
				best = off
	return best


func _box_hits(box: Rect2, pad: float) -> bool:
	for r in avoid:
		if box.intersects(r.grow(pad)):
			return true
	return false


## A gesture point moved into the safe area (shrunk by the ring), out of the avoid rects, mirrored.
func place(p: Vector2) -> Vector2:
	var q := _mirrored(p) + _shift
	var inner := safe_bounds().grow(-(RING_R + STROKE_DP + MARGIN_DP))
	for r in avoid:
		var g := r.grow(RING_R + STROKE_DP)
		if g.has_point(q):
			# push out along the shortest way that stays inside the safe area
			var opts := [Vector2(g.position.x, q.y), Vector2(g.end.x, q.y), Vector2(q.x, g.position.y), Vector2(q.x, g.end.y)]
			var best := q
			var bd := INF
			# prefer pushing across the gesture (a vertical gesture keeps travelling beside the wrench)
			var dir := _to - _from
			var vertical := absf(dir.y) >= absf(dir.x)
			for k in opts.size():
				var o: Vector2 = opts[k]
				if inner.size.x > 0.0 and not inner.grow(0.5).has_point(o):
					continue
				var across := (k < 2) == vertical
				var d := o.distance_squared_to(q) + (0.0 if across or dir.length() < 1.0 else 1.0e6)
				if d < bd:
					bd = d
					best = o
			q = best
	if inner.size.x > 0.0 and inner.size.y > 0.0:
		q = Vector2(clampf(q.x, inner.position.x, inner.end.x), clampf(q.y, inner.position.y, inner.end.y))
	return q


## Safe area this hint keeps inside (parent coordinates).
func safe_bounds() -> Rect2:
	if bounds.size.x > 0.0 and bounds.size.y > 0.0:
		return bounds
	return SafeArea.shrink(self, Rect2(Vector2.ZERO, size))


## Everything drawn now (ring, trail, arrowhead), as one rect in parent coordinates (tests).
func drawn_rect() -> Rect2:
	if mode == Mode.IDLE or alpha <= 0.0:
		return Rect2()
	var w := STROKE_DP + 1.5
	var r := Rect2(touch_point - Vector2.ONE * (RING_R * 1.07 + w), Vector2.ONE * 2.0 * (RING_R * 1.07 + w))
	for p in trail:
		r = r.merge(Rect2(p - Vector2.ONE * w, Vector2.ONE * 2.0 * w))
	if trail.size() >= 2:
		var tip := trail[trail.size() - 1]
		r = r.merge(Rect2(tip - Vector2.ONE * (14.0 + w), Vector2.ONE * 2.0 * (14.0 + w)))
	return r


func _process(delta: float) -> void:
	advance(delta)


## One animation step (the scene's _process; tests call it directly).
func advance(delta: float) -> void:
	_t += delta
	match _phase:
		_Phase.FADE_IN:
			alpha = clampf(_t / FADE_S, 0.0, 1.0)
			if _t >= FADE_S:
				alpha = 1.0
				_t = 0.0
				if mode == Mode.PLAY:
					_phase = _Phase.MOVE
					gesture_progress.emit(0.0)
				else:
					_phase = _Phase.HOLD  # follow / static: shown until told otherwise
		_Phase.MOVE:
			var u := 1.0 if _duration <= 0.0 else clampf(_t / _duration, 0.0, 1.0)
			var e := ease_in_out(u)
			touch_point = place(_from.lerp(_to, e))
			if trail.is_empty() or trail[trail.size() - 1].distance_to(touch_point) >= MIN_STEP_DP:
				trail.append(touch_point)
			gesture_progress.emit(e)
			if u >= 1.0:
				_t = 0.0
				_holding = _hold_s > 0.0
				if _holding:
					_phase = _Phase.HOLD
				else:
					_end_repeat()
		_Phase.HOLD:
			if mode == Mode.PLAY:
				gesture_progress.emit(1.0)
				if _t >= _hold_s:
					_end_repeat()
			elif mode == Mode.STATIC and _static_s >= 0.0 and _t >= _static_s:
				_t = 0.0
				_phase = _Phase.FADE_OUT
		_Phase.CLEAR:
			# the trail of one repeat fades; the next repeat starts again from the start pose
			var kc := clampf(_t / FADE_S, 0.0, 1.0)
			alpha = 1.0 - out_cubic(kc)
			if kc >= 1.0:
				_t = 0.0
				alpha = 1.0
				touch_point = place(_from)
				trail = PackedVector2Array([touch_point])
				_phase = _Phase.MOVE
				gesture_progress.emit(0.0)
		_Phase.FADE_OUT:
			var k := clampf(_t / FADE_S, 0.0, 1.0)
			alpha = 1.0 - out_cubic(k)
			if k >= 1.0:
				mode = Mode.IDLE
				alpha = 0.0
				trail = PackedVector2Array()
				set_process(false)
				gesture_finished.emit()
	queue_redraw()


func _end_repeat() -> void:
	_repeat += 1
	_t = 0.0
	_holding = false
	_phase = _Phase.FADE_OUT if _repeat >= _repeats else _Phase.CLEAR


static func ease_in_out(u: float) -> float:
	if u <= 0.0:
		return 0.0
	if u >= 1.0:
		return 1.0
	if u < 0.5:
		return 4.0 * u * u * u
	return 1.0 - pow(-2.0 * u + 2.0, 3.0) * 0.5


static func out_cubic(u: float) -> float:
	return 1.0 - pow(1.0 - clampf(u, 0.0, 1.0), 3.0)


func _draw() -> void:
	if mode == Mode.IDLE or alpha <= 0.0:
		return
	var a := 0.92 * alpha
	var n := trail.size()
	var gap := RING_R + 2.0  # the trail stops at the ring's edge, never crosses the touch point
	if n >= 2:
		# the older end of the trail is lighter: the chalk is drawn on in the gesture's direction
		for i in n - 1:
			var p0 := trail[i]
			var p1 := trail[i + 1]
			var d0 := p0.distance_to(touch_point)
			var d1 := p1.distance_to(touch_point)
			if d0 < gap and d1 < gap:
				continue
			if d1 < gap:
				p1 = p0.lerp(p1, clampf((d0 - gap) / maxf(d0 - d1, 0.001), 0.0, 1.0))
			elif d0 < gap:
				p0 = p1.lerp(p0, clampf((d1 - gap) / maxf(d1 - d0, 0.001), 0.0, 1.0))
			var age := float(i) / float(n - 1)
			ChalkLayer.draw_stroke(self, p0, p1, STROKE_DP, a * (0.55 + 0.45 * age), true)
		# static chalk (Reduce Motion): the ring stays at the start, an arrowhead marks the end
		var tip := trail[n - 1]
		if mode == Mode.STATIC and tip.distance_to(touch_point) > gap + 12.0:
			ChalkLayer.draw_head(self, tip, tip - trail[0], STROKE_DP, a, true)
	ChalkLayer.draw_ring(self, touch_point, RING_R, STROKE_DP, a, true)
	if _holding or (mode == Mode.FOLLOW and n < 2):
		ChalkLayer.draw_ring(self, touch_point, HOLD_R, STROKE_DP - 0.5, a * 0.8, true)
