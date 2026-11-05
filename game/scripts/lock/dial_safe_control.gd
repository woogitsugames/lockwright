class_name DialSafeControl
extends RefCounted
## D-59: two-thumb (and D-52 auto) input for the dial safe (LOCKS.md §2.18, lockcore dial_safe).
## lockcore reads only tension and pick_lift:
##   right thumb: the dial as a scroll wheel. Hold and drag up = turn right, down = turn left;
##                how far = how fast (up to 0.8 turn/s). A small drag still turns (MIN_SPEED, one
##                division in about a second), so a gate can be stopped on. Lift the thumb = the
##                dial lets go and settles on the nearest division (lockcore detent).
##   left thumb:  drag up = press the handle (listening pressure). Inside the band the fence rests
##                on the wheels and the gates are heard; above it the pack clamps.
##   D-52 auto:   the handle is held in the middle of the listening band (AUTO_LEVEL); the right
##                thumb alone turns the dial and the safe opens when the dial reaches the mark.

const AUTO_LEVEL := 0.40     # centre of the listening band in every tier (0.20–0.60 … 0.29–0.51)
const MIN_SPEED := 0.075     # lockcore dead zone is 1/16: the slowest turn is just above it
const DEAD := 0.03           # thumb travel (fraction of 200 dp) that still means "hold still"
const CURVE := 1.5           # fine control near zero, full speed at a long drag

var auto := false
var last := {}


func _init(p_auto: bool = false) -> void:
	auto = p_auto


## Dial speed for a thumb deflection l in [-1, 1].
static func dial_speed(l: float) -> float:
	var a := absf(l)
	if a <= DEAD:
		return 0.0
	return signf(l) * clampf(MIN_SPEED + (1.0 - MIN_SPEED) * pow((a - DEAD) / (1.0 - DEAD), CURVE), 0.0, 1.0)


## Thumb deflection that gives a dial speed (tests, bots): the inverse of dial_speed().
static func deflection_for(speed: float) -> float:
	var a := absf(speed)
	if a < MIN_SPEED:
		return 0.0
	return signf(speed) * (DEAD + (1.0 - DEAD) * pow((a - MIN_SPEED) / (1.0 - MIN_SPEED), 1.0 / CURVE))


## Sampler output → lockcore input frame {tension, pick_depth, pick_lift}.
func map(inp: Dictionary, sampler: InputSampler) -> Dictionary:
	var t := float(inp.get("tension", 0.0))
	var lift := dial_speed(float(inp.get("pick_lift", 0.0))) if sampler.right_down() else 0.0
	last = {"tension": t, "pick_depth": 0.5, "pick_lift": lift, "rotate": 0.0, "push": 0.0, "tool": 0}
	return last
