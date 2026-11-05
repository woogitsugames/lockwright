class_name WaferPose
extends RefCounted
## Pure mapping from a lockcore wafer element (state, position, variant, optional window)
## to physical coordinates (in mm, Godot Y = Blender Z) in the photoreal wafer cutaway.

const PLUG_R := 7.0             # Upper/lower shear radius (mm)
const WAFER_HALF_H := 6.97      # Half-height of wafer cylinder profile at rest (dz = 0)
const NOTCH_Y := 2.6            # Spring shoulder height at dz = 0
const BRIDGE_Y := 6.2           # Underside of brass staking bridge (top of return spring)
const REST_DZ := -1.8           # Free wafer at rest: bottom tab sits 1.8 mm in lower housing slot
const FALSE_SET_DZ := -0.38     # Anti-pick false step caught on housing shear lip
const OVERSET_MIN_DZ := 1.35    # Top horns pushed into upper housing slot
const DETECTOR_DZ := 1.85       # Jammed/detector trap catch in upper slot
const DEFAULT_TARGET := 0.55    # Centre of lockcore wafer target range (0.40..0.70)
const BIND_TILT_DEG := 1.4      # Binding wafer leans against housing slot wall (wafer.py w3)
const FALSE_TILT_DEG := 2.4     # False-set wafer cants deeper into anti-pick step
const DETECTOR_TILT_DEG := -2.6 # Jammed wafer canted against upper trap lip
const BIND_SX := 0.08           # Lateral shift against slot wall under tension (mm)


static func target_of(el: Dictionary, default_target: float = DEFAULT_TARGET) -> float:
	if el.has("window_lo") and el.has("window_hi"):
		return (float(el["window_lo"]) + float(el["window_hi"])) * 0.5
	return default_target


## Returns {dz, top_y, bottom_y, spring_bottom_y, tilt_deg, sx, false_step, detector_tripped}.
static func pose(el: Dictionary, default_target: float = DEFAULT_TARGET) -> Dictionary:
	var target := maxf(target_of(el, default_target), 0.15)
	var p: float = float(el.get("position", el.get("pos", 0.0)))
	var state := String(el.get("state", "free"))

	# Linear travel: p = 0 -> REST_DZ (-1.8 mm), p = target -> 0.0 mm (flush with plug)
	var dz := REST_DZ + (p / target) * (-REST_DZ)
	var tilt := 0.0
	var sx := 0.0
	var false_step := false
	var detector_tripped := false

	match state:
		"free":
			dz = minf(dz, -0.45)
		"bound", "near":
			dz = clampf(dz, REST_DZ, -0.22)
			tilt = BIND_TILT_DEG
			sx = BIND_SX
		"set":
			dz = 0.0
			tilt = 0.0
			sx = 0.0
		"false_set":
			dz = FALSE_SET_DZ
			tilt = FALSE_TILT_DEG
			sx = BIND_SX * 1.75
			false_step = true
		"overset":
			dz = maxf(dz, OVERSET_MIN_DZ)
			tilt = 0.45
			sx = BIND_SX * 0.5
		"jammed", "detector":
			dz = DETECTOR_DZ
			tilt = DETECTOR_TILT_DEG
			sx = -0.12
			detector_tripped = true

	var top_y := WAFER_HALF_H + dz
	var bottom_y := -WAFER_HALF_H + dz
	var spring_bottom_y := clampf(NOTCH_Y + dz, 0.5, BRIDGE_Y - 0.55)

	return {
		"dz": dz,
		"top_y": top_y,
		"bottom_y": bottom_y,
		"spring_bottom_y": spring_bottom_y,
		"tilt_deg": tilt,
		"sx": sx,
		"false_step": false_step,
		"detector_tripped": detector_tripped,
	}
