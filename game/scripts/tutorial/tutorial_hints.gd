class_name TutorialHints
extends Node
## Wordless hint escalation on the lock screen (ONBOARDING §2.1–2.2, D-23): HintLadder (H0–H4)
## driven by the lock's progress, ChalkHint (chalk trail + touch ring, D-80) for the gestures. Lives under the lock scene for the
## tutorial S1–S3 and the first jobs (wherever a TutorialCoach runs); both D-52 control modes.
##
## Each physics step the lock scene calls tick(); progress events (bind, set, gate_align) reset
## the ladder, a new step starts it from H0. What each level does:
##   H1 nudge:  the coach's element makes a small move (plug face nudge) and a thumb imprint
##              appears in the leather where the finger goes; the element's quiet sound.
##   H2 chalk gesture: a chalk touch ring travels the needed gesture twice with a chalk trail drawn on
##              behind it, at the speed we want (tension 0→0.3 in 0.6 s, lift 0.2/s); the plug face
##              answers the gesture's tension. No hand (D-80 removed the G23 ghost hand).
##   H3 chalk:  full chalk for the rest of the step plus an arrow at the thumb that should move.
##   H4 master: the game does the step once and the lock really does it (autopilot drives the
##              session's input, so the tool itself moves: pick, wrench, dial, wheel); no hand is
##              drawn: the chalk ring and trail follow the virtual touch point (virtual_touch()).
##              Afterwards control returns in the post-step state (the autopilot keeps the tension
##              until the player's left thumb takes over).
## In the dark (view.dark): H1–H3 sound + haptics only, H4 also lights the scene for a moment.
## Reduce Motion: static chalk (the whole path, the ring at its start; nothing travels).
##
## T42 first lessons (TutorialCoach.set_lesson, res://data/lessons/<family>.json): the step id is the
## lesson's step, and the H2 chalk / H4 master play the step's gesture kind at lesson speed:
##   tension  left thumb up to the lesson's tension     lift  right thumb lifts the target element
##   roll     right thumb on the wheel/disc, held up      turn  right thumb held up: the dial turns once
##   ease     left thumb eases down to ease_level         tap   (auto) a short tap on the left zone
##   back     right thumb eases back a little
## A step's kind comes from its "ghost" key (lesson data: the H2 gesture; else its thumb: left =
## tension, right = the family's "right"); its H4 from "master" (else the same kind).
## The left-handed "swap thumbs" option (HUD §9, setting swap_thumbs) mirrors the chalk hint.

const LIFT_SPEED := 0.2         # lift per second the H2 chalk / H4 master use (§2.2)
const TENSION_DP := 60.0        # 0 → 0.3 tension = 60 dp of left-thumb drag
const TENSION_S := 0.6
const AUTOPILOT_MAX_S := 8.0
const LIGHT_S := 2.0
const DP_PER_UNIT := 200.0      # InputSampler: 200 dp = 1.0 of tension / lift

var ladder := HintLadder.new()
var chalk_hint: ChalkHint
var view: LockPhotorealView
var coach: TutorialCoach
var control = null              # WardedControl for warded, else null
var family: StringName = &"pin_tumbler"
var auto := false
var reduce_motion := false
## H4: true while the master hand drives the lock.
var autopilot := false
## Two thumbs after H4: the autopilot holds this tension until the left thumb comes down.
var held_tension := -1.0
## H2: tension the plug face shows in answer to the chalk gesture (< 0 = none).
var preview_tension := -1.0
## Steps in which H4 played (telemetry / tests).
var h4_steps: Array[StringName] = []
var step := &""
## ONBOARDING §11: H2–H4 also get a short spoken line when a screen reader is on.
var screen_reader_override := -1  # tests: 0/1 force; -1 asks DisplayServer
var spoken: Array[StringName] = []
var _a11y: Control

var _base_chalk := ChalkLayer.Level.OFF
var _auto_s := 0.0
var _auto_lift := 0.0
var _auto_target := -1
var _auto_k := 0
var _light_s := 0.0
var _was_dark := false
var _last_vm := {}
var _last_input := {}
var _auto_kind := ""  # lesson master hand: tension | lift | roll | turn | ease | back
var _h4_gesture: Array = []  # [from, to, seconds, hold] of the H4 step (the chalk follows along it)
var _h4_kind := ""  # what the virtual touch follows: tension | lift | time


func setup(p_view: LockPhotorealView, p_coach: TutorialCoach, p_family: StringName, p_auto: bool, p_control = null) -> void:
	view = p_view
	coach = p_coach
	family = p_family
	auto = p_auto
	control = p_control
	reduce_motion = UiA11y.reduce_motion()
	_base_chalk = view.chalk_level
	chalk_hint = ChalkHint.new()
	chalk_hint.name = "ChalkHint"
	chalk_hint.mirror = bool(Settings.get_value(&"swap_thumbs", false))
	chalk_hint.reduce_motion = reduce_motion
	view.add_child(chalk_hint)
	chalk_hint.gesture_progress.connect(_on_gesture_progress)
	chalk_hint.gesture_finished.connect(func() -> void: preview_tension = -1.0)
	ladder.level_changed.connect(_on_level)
	# live region for the spoken hints when the engine's TTS is off (no visible text)
	_a11y = Control.new()
	_a11y.name = "HintAnnouncer"
	_a11y.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_a11y.size = Vector2(1, 1)
	if "accessibility_live" in _a11y:
		_a11y.set("accessibility_live", 2)  # assertive
	view.add_child(_a11y)


## One physics step of the lock: vm after the step, the input that went in, its events.
func tick(vm: Dictionary, input: Dictionary, events: Array, left_down: bool, right_down: bool, delta: float) -> void:
	_last_vm = vm
	_last_input = input
	ladder.dark_mode = view.dark
	chalk_hint.visible = not view.dark  # chalk is a picture: none in the dark (H4 lights the scene)
	var chalk = view.get("_chalk")
	if chalk is ChalkLayer:  # N-90: one thumb hint at a time
		chalk.hide_thumbs = chalk_hint.visible and chalk_hint.is_playing()
	view.tick_hint_dent(delta)
	if _light_s > 0.0:
		_light_s -= delta
		if _light_s <= 0.0 and _was_dark:
			view.set_dark(true)
	if left_down and held_tension >= 0.0:
		held_tension = -1.0  # the player's left thumb takes the tension back
	if bool(vm.get("open", false)):
		_stop_autopilot()
		return
	var sid := _step_id(vm, input)
	if sid != step:
		step = sid
		ladder.start_step(sid)
		view.hint_arrows = ""
		view.chalk_level = _base_chalk
	for e in events:
		if StringName(e.get("kind", &"")) in [&"bind", &"set", &"gate_align"]:
			ladder.progress()
	if autopilot:
		_auto_s += delta
		if _auto_s >= AUTOPILOT_MAX_S:
			_stop_autopilot()
		return
	ladder.update(delta)


## The step the player is in: the coach's guided step (S1) or, for S2–S3 / first jobs, what
## the lock needs next; each set starts a new step.
func _step_id(vm: Dictionary, input: Dictionary) -> StringName:
	var els: Array = vm.get("elements", [])
	if _lesson():
		var n_set := 0
		for e in els:
			n_set += 1 if String(e.get("state", "")) == "set" else 0
		return StringName("L_%s_%d" % [coach.lesson_step_id(), n_set])
	if family == &"warded":
		var theta := float(vm.get("core_rotation", 0.0))
		var k := int(vm.get("pick_element", 0))
		return StringName("w%d_%s" % [k, "turn" if theta <= 0.0 else "pass"])
	var sets := 0
	var bound := false
	for e in els:
		var st := String(e.get("state", ""))
		sets += 1 if st == "set" else 0
		bound = bound or st in ["bound", "near", "set", "false_set"]
	var base := "lift"
	if coach != null and coach.guided and coach.step != TutorialCoach.Step.NONE:
		base = String(TutorialCoach.Step.keys()[coach.step]).to_lower()
	elif not auto and float(input.get("tension", 0.0)) < 0.1 and not bound and held_tension < 0.0:
		base = "tension"
	return StringName("%s_%d" % [base, sets])


func _lesson() -> bool:
	return coach != null and coach.has_lesson()


func _lesson_f(key: String, default: float) -> float:
	return float(coach.lesson.get(key, default))


## Gesture kind of the current lesson step (see the header); "" outside a lesson.
func gesture_kind() -> String:
	if not _lesson():
		return ""
	var st := coach.lesson_step()
	var k := String(st.get("ghost", ""))
	if k == "":
		var th := String(st.get("thumb", ""))
		k = "tension" if th == "left" else String(coach.lesson.get("right", "lift"))
	if auto:
		if k == "tension":
			k = String(coach.lesson.get("right", "lift"))  # the game holds the left thumb
		elif k == "ease":
			k = "tap"  # D-52: a tap on the left zone lets go for a moment
	return k


func _master_kind() -> String:
	var k := String(coach.lesson_step().get("master", ""))
	if k == "" or (auto and k == "tension"):
		k = gesture_kind()
	return "ease" if k == "tap" else k


## The current step is played by the left thumb (master: the master hand's gesture).
func _left_thumb_step(master := false) -> bool:
	if _lesson():
		var k := _master_kind() if master else gesture_kind()
		return k in ["tension", "ease", "tap"]
	return _needs_tension() or (family == &"warded" and String(step).ends_with("turn") and not auto)


func _needs_tension() -> bool:
	if _lesson():
		return gesture_kind() == "tension"
	return String(step).begins_with("tension") or (family == &"warded" and String(step).ends_with("turn") and not auto)


## Target element of the lift (binding / near first, else the first unset).
func _target(els: Array) -> int:
	for i in els.size():
		if String(els[i].get("state", "")) in ["bound", "near"]:
			return i
	for i in els.size():
		if String(els[i].get("state", "")) != "set":
			return i
	return 0


## Gesture of the current step: [from, to, seconds, hold]. master: the H4 step (the lesson's
## "master" kind, which may use the other thumb than the H2 gesture).
func gesture(master := false) -> Array:
	var anchors := view.thumb_anchors()
	var left: Vector2 = anchors[0]
	var right: Vector2 = anchors[1]
	if _lesson():
		return _lesson_gesture(left, right, _master_kind() if master else gesture_kind())
	if family == &"warded":
		if String(step).ends_with("turn"):
			if auto:
				return [right, right, 0.3, 1.5]  # hold the right thumb: the probe turns
			return [left, left + Vector2(0, -TENSION_DP), TENSION_S, 0.0]
		var dh := 0.0
		if control != null:
			dh = _warded_target_h() - float(control.h)
		var d := clampf(dh * DP_PER_UNIT, -120.0, 120.0)
		return [right, right + Vector2(0, -d), maxf(absf(dh) / 0.5, 0.4), 0.0]
	if _needs_tension():
		return [left, left + Vector2(0, -TENSION_DP), TENSION_S, 0.0]
	var els: Array = _last_vm.get("elements", [])
	var n := maxi(els.size(), 1)
	var i := _target(els)
	var size := view.get_rect().size
	var x := size.x * 0.5 + size.x * 0.5 * (i + 0.5) / n
	var lift := 0.55
	if i < els.size() and els[i].has("window_hi"):
		lift = (float(els[i]["window_lo"]) + float(els[i]["window_hi"])) * 0.5
	var from := Vector2(x, right.y)
	return [from, from + Vector2(0, -lift * DP_PER_UNIT), lift / LIFT_SPEED, 0.0]


## Screen x of element i's thumb column (InputSampler: pick_depth = x across the right half).
func _element_x(i: int, n: int) -> float:
	var size := view.get_rect().size
	return size.x * 0.5 + size.x * 0.5 * (i + 0.5) / maxi(n, 1)


func _lesson_gesture(left: Vector2, right: Vector2, kind: String) -> Array:
	var t := _lesson_f("tension", 0.35)
	var els: Array = _last_vm.get("elements", [])
	var n := maxi(els.size(), 1)
	var i := _target(els)
	match kind:
		"tension":
			return [left, left + Vector2(0, -t * DP_PER_UNIT), TENSION_S * t / 0.3, 0.0]
		"ease":
			var lo := _lesson_f("ease_level", 0.15)
			var tr_ease := float(coach.lesson.get("trap", {}).get("ease_level", lo))
			return [left + Vector2(0, -t * DP_PER_UNIT), left + Vector2(0, -tr_ease * DP_PER_UNIT), 0.5, 0.4]
		"tap":
			return [left, left, 0.1, 0.15]
		"roll":
			var from := Vector2(_element_x(i, n), right.y)
			return [from, from + Vector2(0, -_lesson_f("roll_dp", 45.0)), 0.4, 1.2]
		"turn":
			return [right, right + Vector2(0, -_lesson_f("roll_dp", 70.0)), 0.4, 2.0]
		"back":
			var bx := Vector2(_element_x(i, n), right.y)
			return [bx + Vector2(0, -60.0), bx + Vector2(0, -30.0), 0.5, 0.3]
	# lift: the target element up to the middle of its window at the lesson's speed
	var lift := 0.55
	if i < els.size() and els[i].has("window_hi"):
		lift = (float(els[i]["window_lo"]) + float(els[i]["window_hi"])) * 0.5
	var speed := _lesson_f("lift_speed", LIFT_SPEED)
	var f := Vector2(_element_x(i, n), right.y)
	return [f, f + Vector2(0, -lift * DP_PER_UNIT), lift / speed, 0.0]


func _warded_target_h() -> float:
	var els: Array = _last_vm.get("elements", [])
	if els.is_empty():
		return 0.5
	var k := clampi(int(_last_vm.get("pick_element", 0)), 0, els.size() - 1)
	return (float(els[k].get("window_lo", 0.4)) + float(els[k].get("window_hi", 0.6))) * 0.5


func _on_level(level: int, _step_id: StringName) -> void:
	var ch := ladder.channels(level)
	var g := gesture()
	var mat := &"iron" if family == &"warded" else (StringName(coach.lesson.get("material", "brass")) if _lesson() else &"brass")
	if ch["sound"] and level < 4:
		Sfx.play(&"contact", mat, -12.0 if level == 1 else -6.0, 1.0)
	if ch["haptic"] and level < 4:
		Haptics.play(&"contact", 0.2 + 0.05 * level, mat)
	match level:
		1:
			if ch["visual"]:
				chalk_hint.avoid = _avoid_rects()
				chalk_hint.show_touch(g[0], 2.0)  # N-83 / D-83: a chalk ring, no dark imprint
				view._set_flash = 1.0  # the plug face nudges (≈ 1.5°)
		2:
			if ch["visual"]:
				chalk_hint.avoid = _avoid_rects()
				chalk_hint.play_gesture(g[0], g[1], g[2], 2, g[3])  # Reduce Motion: static chalk
		3:
			if ch["visual"]:
				view.chalk_level = ChalkLayer.Level.FULL
				view.hint_arrows = "left" if _left_thumb_step() else "right"
		4:
			h4_steps.append(step)
			if ch["light"] and view.dark:
				_was_dark = true
				view.set_dark(false)
				_light_s = LIGHT_S
			Haptics.play(&"bind", 0.4, mat)
			_start_autopilot()
			_h4_gesture = gesture(true)
			_h4_kind = _follow_kind()
			chalk_hint.avoid = _avoid_rects(true)
			chalk_hint.begin_follow(_h4_gesture[0], _h4_gesture[1])
	_speak(level)
	_save_history()


func _screen_reader_active() -> bool:
	if screen_reader_override >= 0:
		return screen_reader_override == 1
	if DisplayServer.has_method("accessibility_screen_reader_active"):
		return int(DisplayServer.accessibility_screen_reader_active()) == 1
	return false


## H2 says the gesture of the step, H3 the chalk, H4 the master hand (ONBOARDING §11).
func _speak(level: int) -> void:
	if level < 2 or not _screen_reader_active():
		return
	var key := &"tutorial.say_master"
	if level == 3:
		key = &"tutorial.say_chalk"
	elif level == 2 and _lesson() and coach.text_key() != &"":
		key = coach.text_key()  # the lesson line says the gesture of the step
	elif level == 2:
		if family == &"warded":
			key = &"tutorial.say_warded"
		else:
			key = &"tutorial.say_tension" if _needs_tension() else &"tutorial.say_lift"
	spoken.append(key)
	var text := I18n.t(key)
	if _a11y:
		_a11y.set("accessibility_description", text)
	UiA11y.announce(text)  # D-90: one announcer for the whole game (TTS or the AccessKit live region)


## Dev / screenshots (--lw-hint N): climb the ladder to level N right now.
func jump_to(level: int) -> void:
	var i := clampi(level, 1, ladder.thresholds.size()) - 1
	ladder.update(ladder.thresholds[i] + 0.01)


func _on_gesture_progress(t: float) -> void:
	if _needs_tension() and not autopilot:
		preview_tension = (_lesson_f("tension", 0.3) if _lesson() else 0.3) * t  # the plug face answers the gesture, then returns (§2.1 H2)


## Rects the chalk ring must not cover: the tension wrench / plug face, the lock section, and in H4
## also the loupe on the roll (N-73: the H4 hand covered the wrench and the pockets). View coordinates.
func _avoid_rects(master := false) -> Array[Rect2]:
	var out: Array[Rect2] = []
	var face = view.get("_face")
	if face is Control and face.visible and face.size.x > 0.0:
		out.append(Rect2(face.position, face.size))
	var sec = view.get("section_rect")
	if sec is Rect2 and sec.size.x > 0.0:
		out.append(sec)  # the mechanism the lesson is about stays uncovered
	if master and view.has_method("loupe_rect"):
		var lr: Rect2 = view.loupe_rect()
		if lr.size.x > 0.0:
			out.append(lr)
	return out


# ------------------------------------------------------------------ H4 virtual touch
## What the H4 chalk follows: the real tension (left thumb), the real lift (right thumb) or, for
## gestures whose input is a rate (roll, turn, back, warded), the planned path over time.
func _follow_kind() -> String:
	if _auto_kind == "":
		if family == &"warded":
			return "time"
		return "tension" if String(step).begins_with("tension") else "lift"
	match _auto_kind:
		"tension", "ease":
			return "tension"
		"lift":
			return "lift"
	return "time"


## Virtual touch point of the master hand for this step's input `out` (view coordinates): the point
## of the planned path whose thumb travel gives that input (200 dp of travel per unit of tension or
## lift); rate gestures move along the path over the gesture's time.
func virtual_touch(out: Dictionary) -> Vector2:
	if _h4_gesture.is_empty():
		return Vector2.ZERO
	var from: Vector2 = _h4_gesture[0]
	var to: Vector2 = _h4_gesture[1]
	var u := 1.0
	match _h4_kind:
		"tension":
			# the path's height above the left anchor is the tension
			var base_y: float = view.thumb_anchors()[0].y
			var t_from := (base_y - from.y) / DP_PER_UNIT
			var t_to := (base_y - to.y) / DP_PER_UNIT
			if absf(t_to - t_from) > 0.001:
				u = (float(out.get("tension", 0.0)) - t_from) / (t_to - t_from)
		"lift":
			var span := (from.y - to.y) / DP_PER_UNIT
			if span > 0.001:
				u = float(out.get("pick_lift", 0.0)) / span
		_:
			var dur := maxf(float(_h4_gesture[2]), 0.1)
			u = ChalkHint.ease_in_out(clampf(_auto_s / dur, 0.0, 1.0))
	return from.lerp(to, clampf(u, 0.0, 1.0))


# ------------------------------------------------------------------ H4 autopilot
func _start_autopilot() -> void:
	autopilot = true
	_auto_s = 0.0
	_auto_lift = 0.0
	var els: Array = _last_vm.get("elements", [])
	_auto_target = _target(els)
	_auto_k = int(_last_vm.get("pick_element", 0))
	_auto_kind = _master_kind() if _lesson() else ""
	_auto_lift = float(_last_input.get("pick_lift", 0.0)) if _auto_kind == "back" else 0.0


func _stop_autopilot() -> void:
	if not autopilot:
		return
	autopilot = false
	preview_tension = -1.0
	if chalk_hint != null:
		chalk_hint.end_follow()
	if _lesson():
		held_tension = _lesson_f("tension", 0.35) if not auto else -1.0
	elif not auto and family != &"warded":
		held_tension = 0.35  # control returns in the post-step state: the tension stays on


## Input the lock gets while the master hand works (or after it, the held tension). While it works
## the chalk ring and trail follow its virtual touch point.
func drive(input: Dictionary, vm: Dictionary, delta: float) -> Dictionary:
	if not autopilot:
		if held_tension >= 0.0:
			var held := input.duplicate()
			held["tension"] = maxf(float(held.get("tension", 0.0)), held_tension)
			return held
		return input
	var out := _drive_auto(input, vm, delta)
	if autopilot and chalk_hint != null:
		chalk_hint.follow(virtual_touch(out))
	return out


func _drive_auto(input: Dictionary, vm: Dictionary, delta: float) -> Dictionary:
	var out := input.duplicate()
	var els: Array = vm.get("elements", [])
	if _auto_kind != "":
		return _drive_lesson(out, vm, delta)
	if family == &"warded":
		if control != null:
			control.h = _warded_target_h()
		out["pick_lift"] = _warded_target_h()
		out["pick_depth"] = 1.0
		out["tension"] = WardedControl.BIT_TAU_SAFE[control.bit if control != null else 0] - WardedControl.AUTO_MARGIN
		out["rotate"] = WardedControl.AUTO_RATE
		var k := int(vm.get("pick_element", 0))
		var bolt_set := not els.is_empty() and String(els.back().get("state", "")) == "set"
		if k > _auto_k or bolt_set:
			_stop_autopilot()
		return out
	var t := 0.35 if not auto else float(input.get("tension", 0.35))
	if String(step).begins_with("tension"):
		out["tension"] = minf(0.35, 0.3 * _auto_s / TENSION_S)
		out["pick_lift"] = 0.0
		for e in els:
			if String(e.get("state", "")) in ["bound", "near"]:
				_stop_autopilot()
				held_tension = 0.35 if not auto else -1.0
		return out
	var n := maxi(els.size(), 1)
	var i := clampi(_auto_target, 0, n - 1)
	_auto_lift += LIFT_SPEED * 2.0 * delta
	out["tension"] = t
	out["pick_depth"] = (i + 0.5) / n
	out["pick_lift"] = _auto_lift
	if i < els.size():
		var st := String(els[i].get("state", ""))
		if st == "set" or st == "overset" or _auto_lift > 1.2:
			_stop_autopilot()
	return out


func _save_history() -> void:
	# ONBOARDING §12: every level per step (test A1 counts openings without H4)
	var h: Array = Save.get_value("tutorial/hint_history", [])
	var last: Dictionary = ladder.history.back() if not ladder.history.is_empty() else {}
	if last.is_empty():
		return
	h.append({"lock": String(JobRun.current_job.get("id", "")), "step": String(last["step"]), "level": int(last["level"]), "t": float(last["t"])})
	if h.size() > 400:
		h = h.slice(h.size() - 400)
	Save.set_value("tutorial/hint_history", h)


## H4 of a lesson: the master hand does the step's gesture once, in lockcore's input frame (after the
## family's thumb mapping), at lesson speed; then control returns in the post-step state.
func _drive_lesson(out: Dictionary, vm: Dictionary, delta: float) -> Dictionary:
	var els: Array = vm.get("elements", [])
	var n := maxi(els.size(), 1)
	var t := _lesson_f("tension", 0.35)
	var t_in := t if not auto else float(out.get("tension", t))
	var i := clampi(_auto_target, 0, n - 1)
	var st := String(els[i].get("state", "")) if i < els.size() else ""
	match _auto_kind:
		"tension":
			out["tension"] = minf(t, t * _auto_s / (TENSION_S * t / 0.3))
			if _auto_s >= TENSION_S * t / 0.3 + 0.6:
				_stop_autopilot()
		"ease":
			var tr: Dictionary = coach.lesson.get("trap", {})
			out["tension"] = float(tr.get("ease_level", _lesson_f("ease_level", 0.15)))
			if bool(tr.get("keep_lift", false)):
				_auto_lift = minf(_auto_lift + _lesson_f("lift_speed", LIFT_SPEED) * delta, 1.2)
				out["pick_depth"] = (i + 0.5) / n
				out["pick_lift"] = maxf(float(out.get("pick_lift", 0.0)), _auto_lift)
			if _auto_s >= 1.2:
				_stop_autopilot()
		"back":
			out["tension"] = t_in
			out["pick_depth"] = (i + 0.5) / n
			if String(coach.lesson.get("right", "lift")) == "lift":
				_auto_lift = maxf(_auto_lift - 0.2 * delta, 0.0)
				out["pick_lift"] = _auto_lift
			else:
				out["pick_lift"] = -0.15  # a small turn back
			if _auto_s >= 0.6:
				_stop_autopilot()
		"turn":
			out["tension"] = t_in
			out["pick_lift"] = 0.25  # about one turn of the dial in 5 s
			if _auto_s >= 1.0 / (0.25 * 0.8):
				_stop_autopilot()
		"roll":
			out["tension"] = t_in
			out["pick_depth"] = (i + 0.5) / n
			if i < els.size():
				var e: Dictionary = els[i]
				var g := fposmod((float(e.get("window_lo", 0.0)) + float(e.get("window_hi", 0.0))) * 0.5, 1.0)
				var off := fposmod(g - float(e.get("position", 0.0)) + 0.5, 1.0) - 0.5
				out["pick_lift"] = signf(off) * clampf(absf(off) * 3.0, 0.12, 0.3)
			if st == "set":
				_stop_autopilot()
		_:  # lift
			_auto_lift += _lesson_f("lift_speed", LIFT_SPEED) * 2.0 * delta
			out["tension"] = t_in
			out["pick_depth"] = (i + 0.5) / n
			out["pick_lift"] = _auto_lift
			if st in ["set", "overset", "false_set"] or _auto_lift > 1.2:
				_stop_autopilot()
	return out
