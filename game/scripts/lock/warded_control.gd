class_name WardedControl
extends RefCounted
## N-63: two-thumb (and D-52 auto) input for the warded lock (LOCKS.md §2.2, lockcore warded).
## lockcore wants depth, tip height, a turn rate, a turning force and the bit slot; the thumbs
## give the same gestures as the pin lock:
##   right thumb: held = the probe is in the keyhole; vertical drag sets the reach of the bit
##                (tip height h). h is kept between touches (it is the probe's setting, not a
##                drag from zero).
##   left thumb:  drag up = turn forward, drag down = turn back; how far = turning force
##                (bolt_spring <= T <= the bit's safe torque, too much bends the probe).
##   D-52 auto:   the force is held at a safe level for the chosen bit; the right thumb held
##                turns forward, the left thumb held turns back.
## Bits (square / hook / fork) swap only with the probe out and unturned (lockcore rule), by a
## tap on the probe head (view: bit button).

const BIT_THICKNESS := [0.12, 0.06, 0.22]  # lockcore warded.hpp, fraction of the tip range
const BIT_TAU_SAFE := [0.55, 0.32, 0.80]
const T_TURN := 0.05
const A_BOLT := 0.82
const A_SET := 0.92
const LIFT_GAIN := 1.0       # h per unit of InputSampler lift (200 dp of drag = whole range)
const AUTO_MARGIN := 0.06    # auto force: this far under the bit's safe torque
const ROTATE_GAIN := 2.0     # turn rate = force × gain (full speed from T = 0.5)
const AUTO_RATE := 0.5       # D-52 auto: half speed (a full turn in 3 s), time to feel a fence

var bit := 0
var options := 2             # bit slots offered: tier 1 → 2, tier 2 → 3 (lockcore sec_max)
var h := 0.5
var auto := false
var _prev_lift := 0.0
var _was_down := false
var last := {}


func _init(tier: int = 1, p_auto: bool = false) -> void:
	options = 2 if tier <= 1 else 3
	auto = p_auto


## Sampler output → lockcore input frame {tension, pick_depth, pick_lift, rotate, push, tool}.
func map(inp: Dictionary, sampler: InputSampler, vm: Dictionary, _delta: float = 1.0 / 120.0) -> Dictionary:
	var right := sampler.right_down()
	var left := sampler.left_down()
	var lift := float(inp.get("pick_lift", 0.0))
	if right:
		if not _was_down:
			_prev_lift = lift
		h = clampf(h + (lift - _prev_lift) * LIFT_GAIN, 0.0, 1.0)
		_prev_lift = lift
	_was_down = right
	var theta := float(vm.get("core_rotation", 0.0))
	var t := 0.0
	var rot := 0.0
	if auto:
		t = BIT_TAU_SAFE[bit] - AUTO_MARGIN
		if right:
			rot = AUTO_RATE
		elif left:
			rot = -AUTO_RATE
	else:
		var s := sampler.tension_signed
		t = absf(s)
		rot = clampf(s * ROTATE_GAIN, -1.0, 1.0) if t >= T_TURN else 0.0
	if not (right or left) and theta <= 0.0:
		rot = 0.0
	var depth := 1.0 if (right or left or theta > 0.0) else 0.0
	last = {"tension": t, "pick_depth": depth, "pick_lift": h, "rotate": rot, "push": 0.0, "tool": bit}
	return last


## Bit swap (tap on the probe head): only withdrawn and unturned, like lockcore. Returns true
## when the slot changed; the next step() carries it into the session.
func cycle_bit(vm: Dictionary, thumbs_down: bool) -> bool:
	if thumbs_down or float(vm.get("core_rotation", 0.0)) > 0.0:
		return false
	bit = (bit + 1) % options
	return true


func bit_width() -> float:
	return BIT_THICKNESS[bit]


## Angular spans of the wards, measured on a twin session (same spec): lockcore's ViewModel
## carries the gaps but not where the wards sit on the turn. The twin probe is driven with the
## thinnest bit: below every gap it stops at a ward's start (a_lo), then in the gap it slides on
## until the next ward faces (a_hi). Deterministic, a few thousand steps, no events leak out.
static func measure_spans(twin: RefCounted) -> Array:
	var spans: Array = []
	if twin == null or not twin.has_method("describe"):
		return spans
	var els: Array = twin.describe().get("elements", [])
	var n := els.size() - 1
	if n <= 0 or not twin.has_method("finished"):
		return spans
	twin.step(0.0, 0.0, 0.0, 0.0, 0.0, 1)  # hook: fits every gap
	var theta := 0.0
	var guard := 0
	for k in n:
		# a_lo: tip under the gap, turn slowly until the probe stops
		var last_theta := -1.0
		var still := 0
		while still < 3 and guard < 20000:
			guard += 1
			twin.step(0.2, 1.0, 0.0, 0.1, 0.0, 1)
			theta = float(twin.describe()["core_rotation"])
			still = still + 1 if absf(theta - last_theta) < 1e-6 else 0
			last_theta = theta
		var a_lo := theta
		var gap: Dictionary = twin.describe()["elements"][k]
		var mid := (float(gap["window_lo"]) + float(gap["window_hi"])) * 0.5
		while int(twin.describe()["pick_element"]) <= k and guard < 20000:
			guard += 1
			twin.step(0.2, 1.0, mid, 0.1, 0.0, 1)
		theta = float(twin.describe()["core_rotation"])
		spans.append(Vector2(a_lo, theta))
	return spans


## Even spans in [0.06, a_bolt - 0.06] (FakeLockSession or a failed measurement).
static func default_spans(n: int) -> Array:
	var out: Array = []
	var from := 0.06
	var slot := (A_BOLT - 0.12) / maxf(n, 1)
	for i in n:
		out.append(Vector2(from + slot * (i + 0.2), from + slot * (i + 0.75)))
	return out
