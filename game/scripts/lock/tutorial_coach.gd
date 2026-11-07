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
var n_elements := 0             # pins / wafers / levers of the lock (1-pin S1: no "sideways")

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
	if has_lesson():
		return _lesson_text_key()
	match step:
		Step.TENSION: return &"tutorial.s1_tension"
		Step.PICK: return &"tutorial.s1_pick_one" if n_elements == 1 else &"tutorial.s1_pick"  # S1 has one pin (HANDOVER §5.3)
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
	if has_lesson():
		_update_lesson(vm, input, events, left_down, right_down, delta)
		return
	var els: Array = vm.get("elements", [])
	n_elements = els.size()
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


# ------------------------------------------------------------------ T42 first lessons (data-driven)
## ONBOARDING §8/§10, contrib/gpt/T42/LESSONS.md: the first job of each v0.6 family runs a guided
## lesson. The steps are data (res://data/lessons/<family>.json, schema "lockwright.lesson/1"), so one
## coach serves every family; nothing here is family code. A lesson is:
##   steps   guided steps in order, each {id, text, text_auto?, thumb (left|right|""), until, until_auto?};
##           a step ends on its `until` condition (a logic event or a held input, never a timer):
##             tension_s: s   tension >= TENSION_MIN held this long (two thumbs)
##             right_down     the right thumb works (touch, or a moving pick_lift: the master hand)
##             moved_s: s     the right thumb moves the element (|pick_lift| > MOVE_MIN) this long
##             events: [..]   one of these lockcore events (kind) happened
##           an event that ends a later step skips ahead to it (players do not always go in order),
##           unless that step says "skip": false
##   (free)  after the last guided step: no line, chalk marks only, until the lock opens
##   done    the closing line, shown from `open` on
##   trap    the family's first trap {id, text, states, events, stress_over, hold_s,
##           min_s, after}: interrupts any step from `after` on while its condition holds (and min_s
##           longer, so the line can be read), then the coach returns to the step it left
## Two thumbs: letting go of the left thumb (T < LOST_T for LOST_S) brings the first step back.
## The H2 chalk gesture / H4 master step of each step is described in the same file (TutorialHints reads it).

const LESSON_DIR := "res://data/lessons/"
const LESSON_SCHEMA := "lockwright.lesson/1"
const TENSION_MIN := 0.12
const MOVE_MIN := 0.04
const LOST_T := 0.05
const TRAP_HOLD_S := 0.25
const TRAP_MIN_S := 2.0
## Jobs of a family after its lesson that still get reduced chalk and the hint ladder ("fades").
const FADE_JOBS := 2

var lesson := {}
## The coach fades (later jobs of the family): the steps still run for the hint ladder and the
## chalk gesture, but no line is written and the open is not held for the closing line.
var lesson_quiet := false
var lesson_idx := 0               # 0..n-1 guided steps, n = free, n + 1 = done
var lesson_trap := false          # the trap line is up
var lesson_history: Array[StringName] = []   # step ids in the order they were shown (GUT)
var _l_hold := 0.0
var _l_move := 0.0
var _l_trap_s := 0.0
var _l_trap_left := 0.0


static func lesson_path(fam: StringName) -> String:
	return LESSON_DIR + String(fam) + ".json"


static func has_lesson_for(fam: StringName) -> bool:
	return FileAccess.file_exists(lesson_path(fam))


## The lesson of a family ({} when it has none or the file is not a lesson).
static func load_lesson(fam: StringName) -> Dictionary:
	if not has_lesson_for(fam):
		return {}
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(lesson_path(fam)))
	if typeof(d) != TYPE_DICTIONARY or d.get("schema", "") != LESSON_SCHEMA or (d.get("steps", []) as Array).is_empty():
		push_warning("lesson %s: not a %s file" % [fam, LESSON_SCHEMA])
		return {}
	return d


## Save: lessons/<family>/done (the lesson ran to the open lock) and lessons/<family>/after (jobs
## of the family opened since, for the fading chalk).
static func lesson_done(fam: StringName) -> bool:
	return bool(Save.get_value("lessons/%s/done" % fam, false))


static func mark_lesson_done(fam: StringName) -> void:
	Save.set_value("lessons/%s/done" % fam, true)


static func jobs_after_lesson(fam: StringName) -> int:
	return int(Save.get_value("lessons/%s/after" % fam, 0))


static func count_job_after_lesson(fam: StringName) -> void:
	Save.set_value("lessons/%s/after" % fam, jobs_after_lesson(fam) + 1)


## Make this coach run a lesson (guided; quiet = the faded coach of the later jobs).
func set_lesson(p_lesson: Dictionary, quiet: bool = false) -> void:
	lesson = p_lesson
	lesson_quiet = quiet
	guided = not quiet
	step = Step.NONE
	history.clear()
	lesson_idx = 0
	lesson_trap = false
	lesson_history.clear()
	_l_hold = 0.0
	_l_move = 0.0
	lesson_history.append(lesson_step_id())


func has_lesson() -> bool:
	return not lesson.is_empty()


func _lesson_steps() -> Array:
	return lesson.get("steps", [])


func lesson_step_count() -> int:
	return _lesson_steps().size()


## Current step: "trap" while the trap line is up, "free" after the guided steps, "done" once open.
func lesson_step_id() -> StringName:
	if lesson_trap:
		return StringName(lesson.get("trap", {}).get("id", "trap"))
	var n := lesson_step_count()
	if lesson_idx < n:
		return StringName(_lesson_steps()[lesson_idx].get("id", "step%d" % lesson_idx))
	return &"free" if lesson_idx == n else &"done"


## The current step's dictionary ({} for free / done; the trap's own dictionary while it is up).
func lesson_step() -> Dictionary:
	if lesson_trap:
		return lesson.get("trap", {})
	if lesson_idx < lesson_step_count():
		return _lesson_steps()[lesson_idx]
	return {}


## Which thumb the chalk cue and the chalk gesture point at: "left", "right" or "" (free / done).
## Auto tension (D-52): a left step is the game's, so the cue moves to the right thumb.
func lesson_thumb() -> String:
	if lesson_idx > lesson_step_count():
		return ""
	var th := String(lesson_step().get("thumb", ""))
	if th == "left" and auto_tension and not lesson_trap:
		return "right"
	return th


func _lesson_text_key() -> StringName:
	if lesson_quiet:
		return &""
	if lesson_idx > lesson_step_count():
		return StringName(lesson.get("done", ""))
	var st := lesson_step()
	var key := String(st.get("text", ""))
	if auto_tension and st.has("text_auto"):
		key = String(st["text_auto"])
	return StringName(key)


func _lesson_go(i: int) -> void:
	if i == lesson_idx:
		return
	lesson_idx = i
	_l_hold = 0.0
	_l_move = 0.0
	if not lesson_trap:
		lesson_history.append(lesson_step_id())


func jump_lesson(i: int) -> void:
	lesson_trap = false
	_lesson_go(clampi(i, 0, lesson_step_count() + 1))


static func _ev_kinds(events: Array) -> Array:
	return events.map(func(e: Dictionary) -> String: return String(e.get("kind", "")))


func _until_met(cond: Dictionary, input: Dictionary, kinds: Array, right_down: bool, delta: float) -> bool:
	var lift := absf(float(input.get("pick_lift", 0.0)))
	if cond.has("tension_s"):
		_l_hold = _l_hold + delta if float(input.get("tension", 0.0)) >= TENSION_MIN else 0.0
		if _l_hold >= float(cond["tension_s"]):
			return true
	if cond.get("right_down", false) and (right_down or lift > MOVE_MIN):
		return true
	if cond.has("moved_s"):
		_l_move = _l_move + delta if lift > MOVE_MIN else maxf(_l_move - delta, 0.0)
		if _l_move >= float(cond["moved_s"]):
			return true
	for k in cond.get("events", []):
		if kinds.has(String(k)):
			return true
	return false


func _trap_condition(vm: Dictionary, kinds: Array) -> bool:
	var tr: Dictionary = lesson.get("trap", {})
	if tr.is_empty():
		return false
	var els: Array = vm.get("elements", [])
	var hit := false
	for e in els:
		if (tr.get("states", []) as Array).has(String(e.get("state", ""))):
			hit = true
	for k in tr.get("events", []):
		hit = hit or kinds.has(String(k))
	if tr.has("stress_over") and float(vm.get("stress", 0.0)) > float(tr["stress_over"]):
		hit = true
	return hit


func _update_lesson(vm: Dictionary, input: Dictionary, events: Array, left_down: bool, right_down: bool, delta: float) -> void:
	var n := lesson_step_count()
	var kinds := _ev_kinds(events)
	if bool(vm.get("open", false)):
		lesson_trap = false
		_lesson_go(n + 1)
		return
	if lesson_idx > n:
		return
	# the family's trap interrupts from its `after` step on, and stays up min_s after it clears
	var tr: Dictionary = lesson.get("trap", {})
	if not tr.is_empty() and lesson_idx >= int(tr.get("after", 1)):
		var cond := _trap_condition(vm, kinds)
		_l_trap_s = _l_trap_s + delta if cond else 0.0
		var instant := false
		for k in tr.get("events", []):
			instant = instant or kinds.has(String(k))
		if cond and (instant or _l_trap_s >= float(tr.get("hold_s", TRAP_HOLD_S))):
			_l_trap_left = float(tr.get("min_s", TRAP_MIN_S))
			if not lesson_trap:
				lesson_trap = true
				lesson_history.append(lesson_step_id())
		elif lesson_trap:
			_l_trap_left -= delta
			if _l_trap_left <= 0.0:
				lesson_trap = false
				lesson_history.append(lesson_step_id())
	# an event that ends a later step skips ahead (e.g. a set before the "move" step ended)
	for j in range(lesson_idx + 1, n):
		if not _lesson_steps()[j].get("skip", true):
			continue  # this step waits for its own event (dial: the next pickup)
		for k in _lesson_steps()[j].get("until", {}).get("events", []):
			if kinds.has(String(k)):
				_lesson_go(j + 1)
	if lesson_idx < n:
		var st: Dictionary = _lesson_steps()[lesson_idx]
		var cond: Dictionary = st.get("until_auto", st.get("until", {})) if auto_tension else st.get("until", {})
		if _until_met(cond, input, kinds, right_down, delta):
			_lesson_go(lesson_idx + 1)
	# two thumbs: letting go of the left thumb brings the first (left) step back
	if not auto_tension and lesson_idx > 0 and String(_lesson_steps()[0].get("thumb", "")) == "left":
		_lost_s = _lost_s + delta if (float(input.get("tension", 0.0)) < LOST_T and not left_down) else 0.0
		if _lost_s >= LOST_S:
			_lost_s = 0.0
			lesson_trap = false
			_lesson_go(0)
