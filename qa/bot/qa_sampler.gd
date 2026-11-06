extends InputSampler
## QA: replaces the touch sampler in the lock scene. Two modes:
##   rows    the inputs of lockcore's scripted bot (LockcoreSession.solve), one row per physics step;
##   patient no rows (authored locks, e.g. tutorial S1-S3 from lockwright.lock/1 files, which solve()
##           cannot replay): a patient player that reads the session each step - tension held,
##           the binding element lifted slowly until it sets, tension let go on an overset.
## sample() is a pure getter like the real sampler (the lock scene calls it more than once per
## step); the state advances once per physics tick. raw = true: the lock scene feeds the frame
## straight to lockcore. Injected by career.gd into a COPY of game/.

const T_HOLD := 0.36
const LIFT_SPEED := 0.35  # per second

var rows: Array = []
var i := 0
var patient := false
var _frame := {}
var _target := -1
var _lift := 0.0
var _release := 0.0


func _ready() -> void:
	raw = true


func _physics_process(delta: float) -> void:
	# runs after the parent lock scene's _physics_process (tree order), so step k uses row k
	if not patient:
		if i < rows.size():
			i += 1
		return
	i += 1
	var s: Variant = get_parent().get("session")
	if s == null:
		return
	var els: Array = s.describe().get("elements", [])
	var n := maxi(els.size(), 1)
	if _release > 0.0:
		_release -= delta
		_frame = {"tension": 0.0, "pick_depth": 0.5, "pick_lift": 0.0}
		return
	for e in els:
		if String(e.get("state", "")) == "overset":
			_release = 0.15
			_lift = 0.0
			_target = -1
			return
	if _target < 0 or _target >= els.size() or String(els[_target].get("state", "")) == "set":
		_target = -1
		for k in els.size():
			if String(els[k].get("state", "")) in ["bound", "near"]:
				_target = k
				break
		if _target < 0:
			for k in els.size():
				if String(els[k].get("state", "")) != "set":
					_target = k
					break
		_lift = 0.0
	_lift += LIFT_SPEED * delta
	if _lift > 1.1:
		_lift = 0.0
		_target = (_target + 1) % n
	_frame = {"tension": T_HOLD, "pick_depth": (maxi(_target, 0) + 0.5) / n, "pick_lift": _lift}


func sample() -> Dictionary:
	var out := {"tension": 0.0, "pick_depth": 0.0, "pick_lift": 0.0, "rotate": 0.0, "push": 0.0, "tool": 0}
	if patient:
		out.merge(_frame, true)
		return out
	if i < rows.size():
		var r: Array = rows[i]
		return {"tension": float(r[0]), "pick_depth": float(r[1]), "pick_lift": float(r[2]),
			"rotate": float(r[3]) if r.size() > 3 else 0.0, "push": float(r[4]) if r.size() > 4 else 0.0,
			"tool": int(r[5]) if r.size() > 5 else 0}
	return out
