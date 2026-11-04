class_name FakeLockSession
extends RefCounted
## Temporary GDScript stand-in for the lockcore GDExtension (same interface as
## lockcore::LockSession, lockcore/include/lockcore/session.hpp). 5-pin lock with
## binding order, set/false_set (spool), overset, drop, stress and break per
## docs/LOCKS.md §1.4-1.5. Replaced by the GDExtension when lockcore API is wired.

const SIM_HZ := 120
const PIN_COUNT := 5
const T_BIND := 0.20
const T_HOLD := 0.10
const T_RELEASE := 0.05
const DROP_GRACE_TICKS := 24  # 200 ms
const SHEAR_WINDOW := 0.06     # fraction of pin travel
const OVERSET_MARGIN := 0.12
const S_MAX := 1.0
const STRESS_WARN := 0.6

var _rng := RandomNumberGenerator.new()
var _pins: Array = []  # {offset, pos 0..1, state, is_spool}
var _tension := 0.0
var _tick := 0
var _open := false
var _broken := false
var _stress := 0.0
var _low_tension_ticks := 0
var _binding_pin := -1
var resistance := 0.0
var pick_drag := 0.0


static func create(family: StringName = &"pin_tumbler", seed: int = 1, difficulty: int = 1) -> FakeLockSession:
	var s := FakeLockSession.new()
	s._rng.seed = seed
	for i in PIN_COUNT:
		s._pins.append({
			"offset": s._rng.randf_range(0.0, 1.0),
			"pos": 0.0,
			"state": "free",
			"is_spool": i == 2,
		})
	s._pins.sort_custom(func(a, b): return a["offset"] < b["offset"])
	return s


func step(tension: float, depth: float, lift: float) -> Array:
	## One 1/120 s step. Returns emitted events [{kind, element, intensity, material}].
	var events: Array = []
	if _open or _broken:
		return events
	_tick += 1
	_tension = clampf(tension, 0.0, 1.0)
	var prev_resistance := resistance
	resistance = _tension * 0.55
	pick_drag = clampf(absf(lift) * 0.5 + absf(depth - 0.5) * 0.2, 0.0, 1.0)

	# binding order: unset pin with smallest offset binds when T >= T_BIND
	_binding_pin = -1
	if _tension >= T_BIND:
		var best := 1.0
		for i in PIN_COUNT:
			var p: Dictionary = _pins[i]
			if p["state"] == "free" and p["offset"] < best:
				best = p["offset"]
				_binding_pin = i
		if _binding_pin >= 0 and _pins[_binding_pin]["state"] == "free":
			_pins[_binding_pin]["state"] = "bound"
			events.append({"kind": &"bind", "element": _binding_pin, "intensity": 0.5, "material": &"brass"})
			resistance += 0.2

	# move the active pick pin (nearest to depth) with lift, gated by friction mu*T
	var active := clampi(int(depth * PIN_COUNT), 0, PIN_COUNT - 1)
	var p: Dictionary = _pins[active]
	if p["state"] == "bound" or p["state"] == "free":
		var mu := 0.35
		if absf(lift) > mu * maxf(_tension, 0.05):
			var dpos := lift * 0.02
			p["pos"] = clampf(p["pos"] + dpos, 0.0, 1.15)
			if absf(lift) > 0.05:
				events.append({"kind": &"contact", "element": active, "intensity": 0.3, "material": &"brass"})
			# stress accumulates when forcing a bound pin at high tension
			if p["state"] == "bound" and _tension > 0.85:
				_stress += (_tension - 0.85) * absf(dpos) * 8.0
				if _stress >= STRESS_WARN and _stress < S_MAX:
					events.append({"kind": &"stress", "element": active, "intensity": _stress / S_MAX, "material": &"steel"})
			elif _stress >= S_MAX:
					_broken = true
					events.append({"kind": &"break", "element": active, "intensity": 1.0, "material": &"steel"})
			else:
				_stress = maxf(0.0, _stress - 0.002)
			# set / false_set / overset
			if p["state"] == "bound":
				if p["pos"] >= 1.0 - SHEAR_WINDOW and p["pos"] <= 1.0 + SHEAR_WINDOW and _tension >= T_HOLD:
					if p["is_spool"]:
						p["state"] = "false_set"
						events.append({"kind": &"false_set", "element": active, "intensity": 0.9, "material": &"brass"})
						events.append({"kind": &"counter_rotate", "element": active, "intensity": 0.5, "material": &"brass"})
					else:
						p["state"] = "set"
						events.append({"kind": &"set", "element": active, "intensity": 0.95, "material": &"brass"})
				elif p["pos"] > 1.0 + SHEAR_WINDOW + OVERSET_MARGIN:
					p["state"] = "overset"
					events.append({"kind": &"overset", "element": active, "intensity": 0.6, "material": &"brass"})
			elif p["state"] == "overset" and _tension < T_RELEASE:
				p["state"] = "free"
				p["pos"] = 0.0

	# drop: set pins fall when tension stays below T_HOLD
	if _tension < T_HOLD:
		_low_tension_ticks += 1
		if _low_tension_ticks > DROP_GRACE_TICKS:
			var dropped := false
			for i in PIN_COUNT:
				if _pins[i]["state"] == "set" or _pins[i]["state"] == "false_set":
					_pins[i]["state"] = "free"
					_pins[i]["pos"] = 0.0
					dropped = true
			if dropped:
				events.append({"kind": &"drop", "element": -1, "intensity": 0.8, "material": &"brass"})
				_low_tension_ticks = 0
	else:
		_low_tension_ticks = 0

	# open when all pins set
	if _pins.all(func(p): return p["state"] == "set"):
		_open = true
		events.append({"kind": &"open", "element": -1, "intensity": 1.0, "material": &"steel"})

	if absf(resistance - prev_resistance) > 0.05:
		events.append({"kind": &"near_shear", "element": active, "intensity": 0.4, "material": &"brass"})
	return events


func is_open() -> bool:
	return _open


func finished() -> bool:
	return _open or _broken


func failure() -> StringName:
	return &"break" if _broken else &"none"


func describe() -> Dictionary:
	return {
		"tick": _tick,
		"tension": _tension,
		"resistance": resistance,
		"pick_drag": pick_drag,
		"open": _open,
		"broken": _broken,
		"pins": _pins.map(func(p): return {"pos": p["pos"], "state": p["state"]}),
	}
