class_name WardedPose
extends RefCounted
## Pure mapping from a lockcore warded state / element to physical coordinates
## (in mm, Godot Y = Blender Z) in the photoreal iron chest warded lock.

const PIN_X := 0.0               # Drill pin X (mm)
const PIN_Y := -8.0              # Drill pin Y (mm, Blender Z)
const TPIV_X := -24.0            # Tumbler pivot X (mm)
const TPIV_Y := 28.8             # Tumbler pivot Y (26.0 + DZ = 28.8 mm)
const STUD_X := -7.2             # Tumbler stud X at rest (mm)
const TUMB_ARM := 16.8           # STUD_X - TPIV_X (mm)
const BOLT_TOP_Y := 23.4         # Top edge of sliding iron bolt (20.6 + DZ)
const STUD_R := 1.2              # Tumbler stud radius (mm)
const BIT_DEG_REST := 76.0       # Blender rest angle where bit aligns in ward gaps
const LIFT_REST := 1.38          # Blender rest lift where stud just clears bolt notch
const DEFAULT_TARGET := 0.60


static func target_of(el: Dictionary, default_target: float = DEFAULT_TARGET) -> float:
	if el.has("window_lo") and el.has("window_hi"):
		return (float(el["window_lo"]) + float(el["window_hi"])) * 0.5
	return default_target


## Returns {bit_delta_deg, bit_radial_mm, tumbler_lift, tumbler_delta_deg, stud_bottom_y, bolt_dx, in_false_step, detector_tripped}.
static func pose(el: Dictionary, default_target: float = DEFAULT_TARGET) -> Dictionary:
	var target := maxf(target_of(el, default_target), 0.15)
	var p: float = float(el.get("position", el.get("pos", 0.0)))
	var state := String(el.get("state", "free"))

	var bit_delta_deg := -42.0 + (p / target) * 42.0
	var bit_radial_mm := 0.0
	var tumbler_lift := clampf((p / target) * 1.45, 0.0, 2.8)
	var bolt_dx := 0.0
	var in_false_step := false
	var detector_tripped := false

	match state:
		"free":
			bit_delta_deg = minf(bit_delta_deg, -24.0)
			tumbler_lift = 0.0
			bolt_dx = 0.0
		"bound", "near":
			bit_delta_deg = -11.5
			bit_radial_mm = -0.35
			tumbler_lift = 0.68
			bolt_dx = -0.65
		"set":
			bit_delta_deg = 0.0
			bit_radial_mm = 0.0
			tumbler_lift = 1.48
			bolt_dx = -2.40
		"false_set":
			bit_delta_deg = -5.5
			bit_radial_mm = -0.20
			tumbler_lift = 0.96
			bolt_dx = -1.35
			in_false_step = true
		"overset":
			bit_delta_deg = 6.5
			bit_radial_mm = 0.85
			tumbler_lift = 2.65
			bolt_dx = -0.35
		"jammed", "detector":
			bit_delta_deg = -21.0
			bit_radial_mm = -0.60
			tumbler_lift = -0.35
			bolt_dx = 1.45
			detector_tripped = true

	var stud_center_y := BOLT_TOP_Y + tumbler_lift
	var stud_bottom_y := stud_center_y - STUD_R
	var delta_lift := tumbler_lift - LIFT_REST
	var tumbler_delta_deg := rad_to_deg(delta_lift / TUMB_ARM)

	return {
		"bit_delta_deg": bit_delta_deg,
		"bit_radial_mm": bit_radial_mm,
		"tumbler_lift": tumbler_lift,
		"tumbler_delta_deg": tumbler_delta_deg,
		"stud_bottom_y": stud_bottom_y,
		"bolt_dx": bolt_dx,
		"in_false_step": in_false_step,
		"detector_tripped": detector_tripped,
	}
