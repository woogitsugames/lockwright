class_name HintLadder
extends RefCounted
## Escalation of wordless tutorial hints, ONBOARDING §2.1 (D-23). Pure logic, no nodes:
## the tutorial scene feeds update(delta) with its own delta and presents the channels
## reported by channels(); the ghost hand, chalk and sounds are drawn/played elsewhere.
##
## The stuck counter measures time since the last *progress* in the current step, not
## since the last touch: aimless swiping never pauses the ladder (ONBOARDING §2.1).
##   H0 nothing    H1 nudge 15 s    H2 ghost thumb 30 s    H3 chalk 45 s    H4 master hand 60 s
## H4 happens at most once per step; afterwards the counter keeps growing but the level
## stays at 3. Thresholds are configurable because S2–S3 shorten the H2 -> H4 gap
## (ONBOARDING §4, steps 2.1/3.1: "H2 -> H4 after 30 s").
##
## Deterministic: no Time calls and no randomness; time arrives only through delta.
##
## Telemetry (ONBOARDING §12): `history` gets one {step, level, t} entry per level rise
## (and one {step, level: 0} per progress() reset), so a session can derive the highest
## level per step and the "opened without H4" metric for test A1.

## Emitted once every time the ladder enters a strictly higher level.
signal level_changed(level: int, step_id: StringName)

## Seconds of no progress after which H1..H4 are reached. Ascending, 1-4 entries.
const DEFAULT_THRESHOLDS := [15.0, 30.0, 45.0, 60.0]

var thresholds: PackedFloat32Array = PackedFloat32Array(DEFAULT_THRESHOLDS):
	set(value):
		# REVIEW-V02: thresholds must rise (H1 < H2 < ...); sort, drop negatives, keep at most 4
		var v := Array(value).filter(func(x: float) -> bool: return x >= 0.0)
		v.sort()
		thresholds = PackedFloat32Array(v.slice(0, 4))
## REVIEW-V02: history is telemetry, keep the last entries only.
const HISTORY_MAX := 256
## "In the dark" mode (ONBOARDING §7): same levels and timing, different channels.
var dark_mode := false
var step_id: StringName = &""
## Current hint level 0-4; 4 on the H4 tick, 3 afterwards (H4 plays at most once).
var level := 0
## {step: StringName, level: int, t: float} per level change, in order.
var history: Array[Dictionary] = []

var _stuck_s := 0.0
var _h4_done := false


## Start a new step: counter, level and the H4 flag are reset (H4 can play again).
func start_step(p_step_id: StringName) -> void:
	step_id = p_step_id
	_stuck_s = 0.0
	level = 0
	_h4_done = false


## Real progress happened in the current step (an event that moves towards the step's
## goal, e.g. a bind or a set): the ladder restarts from H0.
func progress() -> void:
	if level > 0:
		_log({"step": step_id, "level": 0, "t": _stuck_s})
	_stuck_s = 0.0
	level = 0


## Advance the stuck counter by delta and return the current level 0-4: 4 on the
## update where H4 fires, 3 afterwards (the master hand plays at most once per step).
## level_changed fires once for each higher level entered (a big delta that crosses
## several thresholds fires once per level, in order).
func update(delta: float) -> int:
	_stuck_s += delta
	var target := 0
	for i in thresholds.size():
		if _stuck_s >= thresholds[i]:
			target = i + 1
	if _h4_done:
		target = mini(target, 3)
	var fired_h4 := false
	while level < target:
		level += 1
		var fired := level
		if fired == 4:
			_h4_done = true
			fired_h4 = true
		_log({"step": step_id, "level": fired, "t": _stuck_s})
		level_changed.emit(fired, step_id)
		if fired == 4:
			level = 3  # H4 played once; the level then stays at 3 (§2.1)
			break
	return 4 if fired_h4 else level


func _log(entry: Dictionary) -> void:
	history.append(entry)
	if history.size() > HISTORY_MAX:
		history = history.slice(history.size() - HISTORY_MAX)


## True once H4 has played for the current step (start_step resets it).
func h4_done() -> bool:
	return _h4_done


## Which channels carry the hint of this level, per the ONBOARDING §2.1 table:
## - normal: H1-H3 image + the element's quiet sound, no haptics (a hint must never read
##   as lock feedback); H4 all channels, with haptics.
## - in the dark (§7.2): H1-H3 sound + haptics only (no image), H4 also turns the light
##   on for a moment, so the master hand is visible.
## p_level defaults to the current level.
func channels(p_level: int = -1) -> Dictionary:
	var l := clampi(level if p_level < 0 else p_level, 0, 4)
	var ch := {"visual": false, "sound": false, "haptic": false, "light": false}
	if l >= 1 and l <= 3:
		ch["visual"] = not dark_mode
		ch["sound"] = true
		ch["haptic"] = dark_mode
	elif l == 4:
		ch["visual"] = true
		ch["sound"] = true
		ch["haptic"] = true
		ch["light"] = dark_mode
	return ch
