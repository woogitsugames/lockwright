class_name DetectorControl
extends RefCounted
## N-63: thumbs for the detector lever lock (LOCKS.md §2.8, lockcore lever_detector). Same as the
## lever / pin lock, plus the reset of a tripped detector: let go of the tension and turn the
## key back (lockcore: T < t_hold and rotate <= -1/2 held for reset_steps, 1.5–2.5 s).
##   two thumbs: drag the left thumb DOWN from its touch point (below the dead zone) and hold;
##   D-52 auto:  hold the left thumb (longer than a tap) — auto tension lets go meanwhile.

const BACK_SIGNED := -0.15   # left-thumb signed drag that counts as "turn back"
const HOLD_S := 0.35         # auto: a left press longer than a tap

var auto := false
var _left_held := 0.0
var turning_back := false


func _init(p_auto: bool = false) -> void:
	auto = p_auto


func map(inp: Dictionary, sampler: InputSampler, _vm: Dictionary, delta: float = 1.0 / 120.0) -> Dictionary:
	var out := inp.duplicate()
	_left_held = _left_held + delta if sampler.left_down() else 0.0
	turning_back = (sampler.tension_signed <= BACK_SIGNED) if not auto else (_left_held >= HOLD_S)
	out["rotate"] = -1.0 if turning_back else 0.0
	if turning_back:
		out["tension"] = 0.0
	out["push"] = 0.0
	out["tool"] = 0
	return out
