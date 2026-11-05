class_name WoodenPinPose
extends RefCounted
## Pure mapping from a lockcore wooden_pin element (state, position, variant, optional window)
## to physical coordinates (in mm, Godot Y = Blender Z) in the photoreal wooden pin cutaway.

const BOLT_TOP_Y := 14.0        # Top of sliding wooden bolt (shear line, mm)
const STEP_Y := 36.0            # Bore step where the pin collar rests at lift = 0
const PIN_LEN := 34.0           # Total turned wooden pin length (mm)
const COLLAR_H := 4.0           # Top collar height (mm)
const REST_FOOT_Y := 6.0        # STEP_Y + COLLAR_H - PIN_LEN: pin foot sits 8 mm inside bolt at rest
const SET_LIFT := 8.35          # Lift that puts foot_y = 14.35 mm (0.35 mm above BOLT_TOP_Y shear line)
const FALSE_GROOVE_OFFSET := 3.8 # Centre of turned false-set waist groove above pin foot (mm)
const FALSE_SET_LIFT := 4.20    # Lift where waist groove (6.0 + 4.2 + 3.8 = 14.0) straddles BOLT_TOP_Y
const OVERSET_LIFT := 13.5      # Over-lifted pin: bronze lifter peg enters bolt hole above shear line
const DETECTOR_LIFT := 15.2     # Jammed into upper keeper cap
const DEFAULT_TARGET := 0.56    # Centre of lockcore wooden_pin target range (0.42..0.70)
const BIND_TILT_DEG := 2.2      # Binding pin leans as bolt pulls left (wooden_pin.py P2)
const FALSE_TILT_DEG := 3.4     # False-set pin cants into turned waist groove
const DETECTOR_TILT_DEG := -3.8 # Jammed pin canted in upper keeper
const BIND_SX := -0.60          # Bolt pulled left presses pin against left wall of bolt hole (mm)


static func target_of(el: Dictionary, default_target: float = DEFAULT_TARGET) -> float:
	if el.has("window_lo") and el.has("window_hi"):
		return (float(el["window_lo"]) + float(el["window_hi"])) * 0.5
	return default_target


## Returns {lift, foot_y, top_y, collar_bottom_y, lifter_top_y, tilt_deg, sx, in_false_groove, detector_tripped}.
static func pose(el: Dictionary, default_target: float = DEFAULT_TARGET) -> Dictionary:
	var target := maxf(target_of(el, default_target), 0.15)
	var p: float = float(el.get("position", el.get("pos", 0.0)))
	var state := String(el.get("state", "free"))

	# Map lockcore position p: 0 -> lift 0.0 mm, target -> SET_LIFT (8.35 mm)
	var lift := clampf((p / target) * SET_LIFT, 0.0, 16.0)
	var tilt := 0.0
	var sx := 0.0
	var in_false_groove := false
	var detector_tripped := false
	var lifter_extra := 0.0

	match state:
		"free":
			lift = minf(lift, 3.0)
		"bound", "near":
			lift = clampf(lift, 3.5, 6.5)
			tilt = BIND_TILT_DEG
			sx = BIND_SX
		"set":
			lift = SET_LIFT
			tilt = 0.0
			sx = 0.0
		"false_set":
			lift = FALSE_SET_LIFT
			tilt = FALSE_TILT_DEG
			sx = BIND_SX * 1.5
			in_false_groove = true
		"overset":
			lift = maxf(lift, OVERSET_LIFT)
			tilt = 0.8
			sx = BIND_SX * 0.4
			lifter_extra = 2.4 # Bronze lifter peg crosses BOLT_TOP_Y (14.0 mm) into bolt hole
		"jammed", "detector":
			lift = DETECTOR_LIFT
			tilt = DETECTOR_TILT_DEG
			sx = 0.85
			detector_tripped = true
			lifter_extra = 3.0

	var foot_y := REST_FOOT_Y + lift
	var top_y := foot_y + PIN_LEN
	var collar_bottom_y := top_y - COLLAR_H
	var lifter_top_y := foot_y + lifter_extra

	return {
		"lift": lift,
		"foot_y": foot_y,
		"top_y": top_y,
		"collar_bottom_y": collar_bottom_y,
		"lifter_top_y": lifter_top_y,
		"tilt_deg": tilt,
		"sx": sx,
		"in_false_groove": in_false_groove,
		"detector_tripped": detector_tripped,
	}
