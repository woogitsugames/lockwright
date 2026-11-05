class_name ComboControl
extends RefCounted
## D-59: two-thumb (and D-52 auto) input for the thumbwheel combination lock (LOCKS.md §2.19,
## lockcore combo = ring_combo module with the combo flag). lockcore reads tension, pick_depth and
## pick_lift:
##   right thumb: across = which wheel (pick_depth, the wheel under the thumb), up/down = roll the
##                wheel, how far = how fast. A pulled (bound) wheel rolled too fast slips: the notch
##                passes under the latch (combo.slip) — roll it slowly again.
##   left thumb:  drag up = pull the cable (latch tension). The wheel under pull turns stiffly and
##                its notch is felt; pulled too hard it stops turning.
##   D-52 auto:   the pull is held at AUTO_LEVEL (inside every tier's band); a short tap on the
##                left zone lets go for 0.1 s, which frees a wheel caught in a false notch without
##                losing the set ones (drop grace >= 250 ms).

const AUTO_LEVEL := 0.33     # band_lo 0.22–0.26, sticks above band_lo + 0.20…0.32
const DEAD := 0.03

var auto := false
var last := {}


func _init(p_auto: bool = false) -> void:
	auto = p_auto


static func wheel_speed(l: float) -> float:
	var a := absf(l)
	if a <= DEAD:
		return 0.0
	return signf(l) * clampf((a - DEAD) / (1.0 - DEAD), 0.0, 1.0)


static func deflection_for(speed: float) -> float:
	if absf(speed) <= 0.0:
		return 0.0
	return signf(speed) * (DEAD + (1.0 - DEAD) * absf(speed))


## Sampler output → lockcore input frame {tension, pick_depth, pick_lift}.
func map(inp: Dictionary, sampler: InputSampler) -> Dictionary:
	var t := float(inp.get("tension", 0.0))
	var lift := wheel_speed(float(inp.get("pick_lift", 0.0))) if sampler.right_down() else 0.0
	last = {"tension": t, "pick_depth": clampf(float(inp.get("pick_depth", 0.5)), 0.0, 1.0), "pick_lift": lift,
			"rotate": 0.0, "push": 0.0, "tool": 0}
	return last
