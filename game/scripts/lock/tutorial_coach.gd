class_name TutorialCoach
extends RefCounted
## Guided steps of the tutorial lock S1 (ONBOARDING §4, N-61) and the no-tension hint of the
## first jobs (N-58). Pure logic: feed update() with the ViewModel, the sampled input, the
## step's lockcore events and the touch state; read `step`, text_key() and the hint flags.
## The view draws them in chalk; nothing here touches nodes, so GUT drives it directly.
##
## S1 steps (two thumbs):          auto tension (D-52) skips TENSION:
##   TENSION  left thumb up = tension, ends when a stack binds and stays bound 0.5 s
##   PICK     right thumb: sideways picks the stack, up lifts; ends on the first lifted stack
##   BINDING  friction strokes at the binding stack, ends on the first set
##   CLICK    first set: "Click! ... find the next one", ends on the next set (or after 4 s)
##   FREE     no text, chalk marks only, until open
##   OPEN     praise
## OVERSET interrupts any step while a stack is overset, then the coach returns.
## Lost tension (two-thumb mode, T < 0.1 for 1.5 s after TENSION) brings TENSION back.

enum Step { NONE, TENSION, PICK, BINDING, CLICK, FREE, OVERSET, OPEN }

const BIND_HOLD_S := 0.5
const CLICK_S := 4.0
const LOST_S := 1.5
const HINT_AFTER_S := 2.0   # N-58: lifting with no tension this long shows the left-thumb hint
const REACH_HINT_S := 1.0  # warded: pressed against a ward this long → "slide the bit"
const BIT_HINT_S := 8.0    # ... this long → "bit too thick? swap it"

var stage := 0              # 0 = S1 (full chalk), 1–2 = S2–S3 (reduced)
var guided := true          # S1 steps on/off (false: only the N-58 hint and overset)
var auto_tension := false
var step := Step.NONE
var history: Array[int] = []   # steps in the order they were shown (GUT)
var hint_tension := false      # N-58 chalk thumb + arrow on the left
var tension_learned := false   # the first bind ends the N-58 hint for good
## N-63: the lock family; non-pin families get their own first-jobs lines (no pin wording).
var family: StringName = &"pin_tumbler"
var first_set := false          # wafer / lever: the family line shows until the first set
var turned := false             # warded: the probe has turned at least once
var blocked_s := 0.0            # warded: time pressed against the same ward
var tripped := false            # lever_detector: the detector holds every lever

var _bound_s := 0.0
var _lost_s := 0.0
var _lift_no_t := 0.0
var _click_s := 0.0
var _resume := Step.NONE


func _init(p_stage: int = 0, p_guided: bool = true, p_auto: bool = false) -> void:
	stage = p_stage
	guided = p_guided
	auto_tension = p_auto
	if guided:
		_go(Step.PICK if auto_tension else Step.TENSION)


func text_key() -> StringName:
	match step:
		Step.TENSION: return &"tutorial.s1_tension"
		Step.PICK: return &"tutorial.s1_pick"
		Step.BINDING: return &"tutorial.s1_binding"
		Step.CLICK: return &"tutorial.s1_click"
		Step.OVERSET: return &"tutorial.s1_overset_auto" if auto_tension else &"tutorial.s1_overset"
		Step.OPEN: return &"tutorial.s1_open"
	if tripped:
		return &"lock.detector_reset_auto" if auto_tension else &"lock.detector_reset"
	if hint_tension:
		match family:
			&"wafer": return &"lock.hint_tension_wafer"
			&"lever", &"lever_detector": return &"lock.hint_tension_lever"
		return &"lock.hint_tension"
	match family:
		&"warded":
			if not turned:
				return &"lock.warded_turn_auto" if auto_tension else &"lock.warded_turn"
			if blocked_s >= BIT_HINT_S:
				return &"lock.warded_bit"
			if blocked_s >= REACH_HINT_S:
				return &"lock.warded_reach"
		&"wafer":
			if tension_learned and not first_set:
				return &"lock.wafer_coach"
		&"lever", &"lever_detector":
			if tension_learned and not first_set:
				return &"lock.lever_coach"
	return &""


func _go(s: Step) -> void:
	if step == s:
		return
	step = s
	history.append(s)


## warded: the probe turns (core_rotation), a ward pressed against reads "bound" in lockcore.
func _update_warded(vm: Dictionary, els: Array, delta: float) -> void:
	if float(vm.get("core_rotation", 0.0)) > 0.02:
		turned = true
	var blocked := false
	for i in maxi(els.size() - 1, 0):  # the last element is the bolt
		if String(els[i].get("state", "")) == "bound":
			blocked = true
	blocked_s = blocked_s + delta if blocked else 0.0
	hint_tension = false
	if bool(vm.get("open", false)) and guided:
		_go(Step.OPEN)


static func _binding(els: Array) -> int:
	for i in els.size():
		var st := String(els[i].get("state", ""))
		if st == "bound" or st == "near":
			return i
	return -1


static func _any(els: Array, state: String) -> bool:
	for e in els:
		if String(e.get("state", "")) == state:
			return true
	return false


func update(vm: Dictionary, input: Dictionary, events: Array, left_down: bool, right_down: bool, delta: float) -> void:
	var els: Array = vm.get("elements", [])
	var t := float(input.get("tension", 0.0))
	var lift := float(input.get("pick_lift", 0.0))
	var sets := 0
	for e in events:
		if StringName(e.get("kind", &"")) == &"set":
			sets += 1
		if StringName(e.get("kind", &"")) == &"bind":
			tension_learned = true
	if _binding(els) >= 0:
		tension_learned = true
	if sets > 0 or _any(els, "set"):
		first_set = true
	tripped = _any(els, "jammed") and family == &"lever_detector"
	if family == &"warded":
		_update_warded(vm, els, delta)
		return
	# N-58: lifting pins without tension says nothing by itself; after 2 s show the hint
	if not auto_tension and not tension_learned and right_down and lift > 0.08 and t < 0.05:
		_lift_no_t += delta
	elif t >= 0.15:
		_lift_no_t = 0.0
	hint_tension = not auto_tension and not tension_learned and _lift_no_t >= HINT_AFTER_S
	if bool(vm.get("open", false)):
		if guided:
			_go(Step.OPEN)
		return
	if not guided:
		return
	# overset interrupts whatever step is on (S1 cannot overset easily, S2–S3 can)
	if _any(els, "overset"):
		if step != Step.OVERSET:
			_resume = step
			_go(Step.OVERSET)
		return
	if step == Step.OVERSET:
		_go(_resume if _resume != Step.NONE else Step.BINDING)
	if stage > 0:
		return  # S2–S3: reduced chalk, no step texts beyond overset/open
	match step:
		Step.TENSION:
			_bound_s = _bound_s + delta if _binding(els) >= 0 else 0.0
			if _bound_s >= BIND_HOLD_S:
				_go(Step.PICK)
		Step.PICK:
			if right_down and int(vm.get("pick_element", -1)) >= 0 and lift > 0.05:
				_go(Step.BINDING)
			if sets > 0:
				_go(Step.CLICK)
		Step.BINDING:
			if sets > 0:
				_click_s = 0.0
				_go(Step.CLICK)
		Step.CLICK:
			_click_s += delta
			if (sets > 0 and _click_s > 0.3) or _click_s >= CLICK_S:
				_go(Step.FREE)
	# two-thumb mode: letting go of the tension brings the first step back (no skipping it)
	if not auto_tension and step in [Step.PICK, Step.BINDING, Step.FREE]:
		_lost_s = _lost_s + delta if (t < 0.1 and not left_down) else 0.0
		if _lost_s >= LOST_S:
			_lost_s = 0.0
			_bound_s = 0.0
			_go(Step.TENSION)
