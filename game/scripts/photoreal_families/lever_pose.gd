class_name LeverPose
extends RefCounted
## Pure mapping from a lockcore lever element (state, position, variant, optional window)
## to physical coordinates (in mm, Godot Y = Blender Z) in the photoreal lever mortise lock.

const PIVOT_X := -22.0          # Lever pivot post X (mm)
const PIVOT_Y := 4.0            # Lever pivot post Y (mm, Blender Z)
const STUMP_X := 7.7            # Bolt stump X at rest (mm)
const STUMP_Y := 0.0            # Bolt stump Y (mm)
const STUMP_R := 2.2            # Bolt stump radius (mm)
const GATE_HALF_H := 2.45       # True gate half-height (mm); > STUMP_R leaves light gap above & below
const ARM_LEN := 29.7           # STUMP_X - PIVOT_X (mm)
const REST_DELTA_LIFT := -3.2   # Free lever at rest: gate centre sits 3.2 mm below stump
const BOUND_DELTA_LIFT := -1.65 # Binding lever: upper tooth bears against stump
const FALSE_GATE_LIFT := -2.25  # False gate notch aligned with stump
const OVERSET_MIN_LIFT := 2.35  # Gate passed above stump; lower tooth blocks stump
const DETECTOR_LIFT := 3.10     # Over-lifted lever kicks detector pawl into bolt tail notch
const DEFAULT_TARGET := 0.52    # Centre of lockcore lever target range (0.30..0.72)
const DETECTOR_TRIP_DEG := -18.5 # Rotation of detector pawl when tripped into bolt notch


static func target_of(el: Dictionary, default_target: float = DEFAULT_TARGET) -> float:
	if el.has("window_lo") and el.has("window_hi"):
		return (float(el["window_lo"]) + float(el["window_hi"])) * 0.5
	return default_target


static func has_false_gate(el: Dictionary) -> bool:
	return int(el.get("variant", 0)) > 0 or String(el.get("state", "")) == "false_set"


## Returns {delta_lift, gate_center_y, gate_lo_y, gate_hi_y, rot_deg, bolt_dx, in_false_gate, detector_tripped, detector_deg}.
static func pose(el: Dictionary, default_target: float = DEFAULT_TARGET) -> Dictionary:
	var target := maxf(target_of(el, default_target), 0.15)
	var p: float = float(el.get("position", el.get("pos", 0.0)))
	var state := String(el.get("state", "free"))

	# Map lockcore position p: 0 -> REST_DELTA_LIFT (-3.2 mm), target -> 0.0 mm (in gate)
	var delta_lift := REST_DELTA_LIFT + (p / target) * (-REST_DELTA_LIFT)
	var bolt_dx := 0.0
	var in_false_gate := false
	var detector_tripped := false
	var detector_deg := 0.0

	match state:
		"free":
			delta_lift = minf(delta_lift, -1.2)
			bolt_dx = 0.0
		"bound", "near":
			delta_lift = clampf(delta_lift, REST_DELTA_LIFT + 0.4, -0.65)
			bolt_dx = -0.42
		"set":
			delta_lift = 0.0
			bolt_dx = -0.85
		"false_set":
			delta_lift = FALSE_GATE_LIFT
			bolt_dx = -1.38
			in_false_gate = true
		"overset":
			delta_lift = maxf(delta_lift, OVERSET_MIN_LIFT)
			bolt_dx = -0.30
		"jammed", "detector":
			delta_lift = DETECTOR_LIFT
			bolt_dx = 0.15
			detector_tripped = true
			detector_deg = DETECTOR_TRIP_DEG

	var gate_center_y := STUMP_Y + delta_lift
	var gate_lo_y := gate_center_y - GATE_HALF_H
	var gate_hi_y := gate_center_y + GATE_HALF_H
	var rot_deg := rad_to_deg(delta_lift / ARM_LEN)

	return {
		"delta_lift": delta_lift,
		"gate_center_y": gate_center_y,
		"gate_lo_y": gate_lo_y,
		"gate_hi_y": gate_hi_y,
		"rot_deg": rot_deg,
		"bolt_dx": bolt_dx,
		"in_false_gate": in_false_gate,
		"detector_tripped": detector_tripped,
		"detector_deg": detector_deg,
	}
