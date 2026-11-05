class_name FamilyLockSession
extends RefCounted
## Faithful GDScript fallback session for `wafer`, `lever`, `lever_detector`, `warded`, and `wooden_pin`
## when the native C++ LockcoreSession GDExtension is not loaded on desktop.
## Implements the exact same interface as LockcoreSession and FakeLockSession:
##   - create(family, seed, tier) -> bool
##   - step(tension, pick_depth, pick_lift) -> Array[Dictionary]
##   - describe() -> Dictionary
##   - finished() -> bool

var family: StringName = &"wafer"
var seed_val := 42
var tier := 2
var _elements: Array[Dictionary] = []
var _binding_order: Array[int] = []
var _core_rotation := 0.0
var _tension := 0.0
var _pick_depth := 0.5
var _pick_lift := 0.0
var _stress := 0.0
var _hold_progress := 0.0
var _reset_progress := 0.0
var _open := false
var _broken := false
var _jammed := false


static func create(fam: StringName, sd: int, tr: int) -> FamilyLockSession:
	var s := FamilyLockSession.new()
	s.setup(fam, sd, tr)
	return s


func setup(fam: StringName, sd: int, tr: int) -> bool:
	family = fam
	seed_val = sd
	tier = tr
	var rng := RandomNumberGenerator.new()
	rng.seed = sd

	var count := 4
	var material := &"brass"
	match String(fam):
		"wafer":
			count = clampi(tr + 2, 3, 5)
			material = &"brass"
		"lever":
			count = clampi(tr, 3, 5)
			material = &"brass"
		"lever_detector":
			count = clampi(tr, 5, 6)
			material = &"brass"
		"warded":
			count = clampi(tr + 1, 2, 3)
			material = &"iron"
		"wooden_pin":
			count = 3 + (sd & 1)
			material = &"wood"

	_elements.clear()
	_binding_order.clear()
	for i in count:
		var target := rng.randf_range(0.40, 0.70)
		var win_half := 0.06
		var variant := 0
		if String(fam) in ["lever", "lever_detector"] and i % 2 == 1:
			variant = 1
		_elements.append({
			"index": i,
			"state": &"free",
			"position": 0.0,
			"window_lo": target - win_half,
			"window_hi": target + win_half,
			"variant": variant,
			"material": material,
		})
		_binding_order.append(i)

	# Deterministic shuffle of binding order
	for i in range(count - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp := _binding_order[i]
		_binding_order[i] = _binding_order[j]
		_binding_order[j] = tmp

	_core_rotation = 0.0
	_stress = 0.0
	_hold_progress = 0.0
	_reset_progress = 0.0
	_open = false
	_broken = false
	_jammed = false
	return true


func finished() -> bool:
	return _open or _broken


func _material_name() -> StringName:
	match String(family):
		"warded":
			return &"iron"
		"wooden_pin":
			return &"wood"
		_:
			return &"brass"


func step(tension: float, pick_depth: float, pick_lift: float) -> Array:
	var events: Array = []
	if finished():
		return events

	_tension = clampf(tension, -1.0, 1.0)
	_pick_depth = clampf(pick_depth, 0.0, 1.0)
	_pick_lift = clampf(pick_lift, -1.0, 1.0)
	var mat := _material_name()

	# Detector reset by reverse tension
	if _jammed:
		if _tension < -0.25:
			_reset_progress = clampf(_reset_progress + 0.04, 0.0, 1.0)
			if _reset_progress >= 1.0:
				_jammed = false
				_reset_progress = 0.0
				for el in _elements:
					el["state"] = &"free"
					el["position"] = 0.0
				events.append({"kind": &"reset", "element": 0, "intensity": 0.7, "material": mat})
		return events

	var n := maxi(_elements.size(), 1)
	var active_idx := clampi(int(round(_pick_depth * float(n - 1))), 0, n - 1)

	# Find current binding element
	var binder := -1
	if _tension > 0.12:
		for idx in _binding_order:
			if _elements[idx]["state"] != &"set":
				binder = idx
				break

	for i in _elements.size():
		var el: Dictionary = _elements[i]
		if el["state"] == &"set":
			continue
		if i == active_idx and _pick_lift > 0.0:
			el["position"] = clampf(lerpf(float(el["position"]), _pick_lift, 0.25), 0.0, 1.2)
		elif _tension < 0.08:
			el["position"] = maxf(float(el["position"]) - 0.03, 0.0)
			el["state"] = &"free"

		var pos: float = float(el["position"])
		var lo: float = float(el["window_lo"])
		var hi: float = float(el["window_hi"])

		if pos > hi + 0.14 and _tension > 0.15:
			if String(family) == "lever_detector":
				_jammed = true
				el["state"] = &"jammed"
				events.append({"kind": &"detector_trip", "element": i, "intensity": 0.95, "material": &"steel"})
			else:
				el["state"] = &"overset"
				_stress = clampf(_stress + 0.025, 0.0, 1.0)
				events.append({"kind": &"overset", "element": i, "intensity": 0.6, "material": mat})
		elif i == binder:
			if pos >= lo and pos <= hi:
				el["state"] = &"set"
				events.append({"kind": &"set", "element": i, "intensity": 0.75, "material": mat})
			elif int(el["variant"]) > 0 and absf(pos - (lo - 0.14)) < 0.05:
				el["state"] = &"false_set"
				events.append({"kind": &"false_set", "element": i, "intensity": 0.65, "material": mat})
			else:
				el["state"] = &"bound"
		else:
			el["state"] = &"free"

	var sets := 0
	for el in _elements:
		if el["state"] == &"set":
			sets += 1

	_core_rotation = 0.02 * float(sets)
	if sets == _elements.size() and _tension > 0.2:
		if String(family) == "wooden_pin":
			_hold_progress = clampf(_hold_progress + 0.08, 0.0, 1.0)
			_core_rotation = 0.08 + 0.92 * _hold_progress
			if _hold_progress >= 1.0:
				_open = true
				events.append({"kind": &"open", "element": -1, "intensity": 1.0, "material": mat})
		else:
			_open = true
			_core_rotation = 1.0
			events.append({"kind": &"open", "element": -1, "intensity": 1.0, "material": mat})

	if _stress >= 1.0:
		_broken = true
		events.append({"kind": &"break", "element": active_idx, "intensity": 1.0, "material": &"steel"})

	return events


func describe() -> Dictionary:
	var n := maxi(_elements.size(), 1)
	var active_idx := clampi(int(round(_pick_depth * float(n - 1))), 0, n - 1)
	return {
		"family": family,
		"tier": "t%d" % tier,
		"phase": &"open" if _open else (&"broken" if _broken else (&"jammed" if _jammed else &"picking")),
		"open": _open,
		"broken": _broken,
		"core_rotation": _core_rotation,
		"tension": _tension,
		"pick_depth": _pick_depth,
		"pick_lift": _pick_lift,
		"pick_element": active_idx,
		"active_element": active_idx,
		"stress": _stress,
		"hold_progress": _hold_progress,
		"reset_progress": _reset_progress,
		"tension_resistance": 0.55 if _tension > 0.1 else 0.0,
		"pick_drag": 0.25,
		"elements": _elements.duplicate(true),
	}
