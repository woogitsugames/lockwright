class_name PinPose
extends RefCounted
## Pure mapping from a lockcore element (state, position, variant, optional window) to the
## heights of one pin stack in the photoreal cutaway. Units: mm in the Blender scene, where
## Blender z == Godot y (art/blender/cutaway.py). No nodes, so it is unit-tested directly.

const SHEAR := 6.4          # top of the plug (shear line), y
const CAP_UNDERSIDE := 21.6 # underside of the chamber caps: top end of the springs
const REST_BOTTOM := 1.2    # key-pin tip at rest (Blender KP_FLOOR)
const TRAVEL := 4.2         # mm of key-pin lift for lockcore position 1.0 (≈ 55 dp in portrait, N-62:
                            # 2.5 mm gave ≈ 18 dp to the shear line and read as "pins barely move")
const DEFAULT_TARGET := 0.56  # centre of the pin_tumbler generator's target range (0.42–0.70)
const SET_GAP := 0.2        # driver resting on the plug edge, light gap (realizm.md "set")
const SET_DROP := 0.5       # key pin drops this far under the shear line once set (≈ 6 dp ledge)
const SPOOL_WAIST := 0.46   # spool driver: waist height above its bottom (lw_common.spool)
const BIND_TILT_DEG := 2.2  # binding driver leans against the chamber wall (Blender pin c)
const SPOOL_VARIANTS := [1, 3]  # lockcore::pin::Variant spool, spool_serrated


## Key-pin length that puts its top on the shear line at lift `target` (a real lock's cut).
static func key_length(target: float) -> float:
	return SHEAR - REST_BOTTOM - target * TRAVEL


## Target lift of an element: window centre when the session reports it, else the default.
static func target_of(el: Dictionary, default_target: float = DEFAULT_TARGET) -> float:
	if el.has("window_lo") and el.has("window_hi"):
		return (float(el["window_lo"]) + float(el["window_hi"])) * 0.5
	return default_target


static func is_spool(el: Dictionary) -> bool:
	return SPOOL_VARIANTS.has(int(el.get("variant", 0))) or bool(el.get("is_spool", false))


## Returns {key_bottom, key_len, driver_bottom, driver_len, tilt_deg, spool}.
static func pose(el: Dictionary, default_target: float = DEFAULT_TARGET, driver_len: float = 4.0) -> Dictionary:
	var target := target_of(el, default_target)
	var klen := key_length(target)
	var p: float = float(el.get("position", el.get("pos", 0.0)))
	var state := String(el.get("state", "free"))
	var key_bottom := REST_BOTTOM + p * TRAVEL
	var key_top := key_bottom + klen
	var drv_bottom := key_top
	var tilt := 0.0
	match state:
		"set":
			drv_bottom = SHEAR + SET_GAP
			key_top = minf(key_top, SHEAR - SET_DROP)
		"false_set":
			if is_spool(el):
				drv_bottom = SHEAR + 0.06 - SPOOL_WAIST
				key_top = minf(key_top, drv_bottom)
			else:
				drv_bottom = SHEAR + SET_GAP
				key_top = minf(key_top, SHEAR - SET_DROP)
		"bound", "near":
			tilt = BIND_TILT_DEG
		"overset", "jammed":
			drv_bottom = maxf(key_top, SHEAR + SET_GAP)
	drv_bottom = maxf(drv_bottom, key_top)
	return {
		"key_bottom": key_top - klen,
		"key_len": klen,
		"driver_bottom": drv_bottom,
		"driver_len": driver_len,
		"tilt_deg": tilt,
		"spool": is_spool(el),
	}
