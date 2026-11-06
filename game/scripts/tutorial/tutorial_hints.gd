class_name TutorialHints
extends Node
## Wordless hint escalation on the lock screen (ONBOARDING §2.1–2.2, D-23): HintLadder (H0–H4)
## driven by the lock's progress, GhostHand for the gestures. Lives under the lock scene for the
## tutorial S1–S3 and the first jobs (wherever a TutorialCoach runs); both D-52 control modes.
##
## Each physics step the lock scene calls tick(); progress events (bind, set, gate_align) reset
## the ladder, a new step starts it from H0. What each level does:
##   H1 nudge:  the coach's element makes a small move (plug face nudge) and a thumb imprint
##              appears in the leather where the finger goes; the element's quiet sound.
##   H2 ghost:  the thumb shadow shows the needed gesture twice, at the speed we want
##              (tension 0→0.3 in 0.6 s, lift 0.2/s); the plug face answers the ghost tension.
##   H3 chalk:  full chalk for the rest of the step plus an arrow at the thumb that should move.
##   H4 master: the shadow hand does the step once and the lock really does it (autopilot drives
##              the session's input); afterwards control returns in the post-step state (the
##              autopilot keeps the tension until the player's left thumb takes over).
## In the dark (view.dark): H1–H3 sound + haptics only, H4 also lights the scene for a moment.
## Reduce Motion: the ghost is not played (H3/H4 still work).

const LIFT_SPEED := 0.2         # lift per second the ghost / master hand use (§2.2)
const TENSION_DP := 60.0        # 0 → 0.3 tension = 60 dp of left-thumb drag
const TENSION_S := 0.6
const AUTOPILOT_MAX_S := 8.0
const LIGHT_S := 2.0
const DP_PER_UNIT := 200.0      # InputSampler: 200 dp = 1.0 of tension / lift

var ladder := HintLadder.new()
var ghost: GhostHand
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
## H2: tension the plug face shows in answer to the ghost (< 0 = none).
var preview_tension := -1.0
## Steps in which H4 played (telemetry / tests).
var h4_steps: Array[StringName] = []
var step := &""

var _base_chalk := ChalkLayer.Level.OFF
var _auto_s := 0.0
var _auto_lift := 0.0
var _auto_target := -1
var _auto_k := 0
var _light_s := 0.0
var _was_dark := false
var _last_vm := {}
var _last_input := {}


func setup(p_view: LockPhotorealView, p_coach: TutorialCoach, p_family: StringName, p_auto: bool, p_control = null) -> void:
	view = p_view
	coach = p_coach
	family = p_family
	auto = p_auto
	control = p_control
	reduce_motion = bool(Settings.get_value("reduce_motion", false))
	_base_chalk = view.chalk_level
	ghost = GhostHand.new()
	ghost.name = "GhostHand"
	view.add_child(ghost)
	ghost.gesture_progress.connect(_on_ghost_progress)
	ghost.gesture_finished.connect(func() -> void: preview_tension = -1.0)
	ladder.level_changed.connect(_on_level)


## One physics step of the lock: vm after the step, the input that went in, its events.
func tick(vm: Dictionary, input: Dictionary, events: Array, left_down: bool, right_down: bool, delta: float) -> void:
	_last_vm = vm
	_last_input = input
	ladder.dark_mode = view.dark
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


func _needs_tension() -> bool:
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


## Ghost gesture of the current step: [from, to, seconds, hold].
func gesture() -> Array:
	var anchors := view.thumb_anchors()
	var left: Vector2 = anchors[0]
	var right: Vector2 = anchors[1]
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


func _warded_target_h() -> float:
	var els: Array = _last_vm.get("elements", [])
	if els.is_empty():
		return 0.5
	var k := clampi(int(_last_vm.get("pick_element", 0)), 0, els.size() - 1)
	return (float(els[k].get("window_lo", 0.4)) + float(els[k].get("window_hi", 0.6))) * 0.5


func _on_level(level: int, _step_id: StringName) -> void:
	var ch := ladder.channels(level)
	var g := gesture()
	var mat := &"iron" if family == &"warded" else &"brass"
	if ch["sound"] and level < 4:
		Sfx.play(&"contact", mat, -12.0 if level == 1 else -6.0, 1.0)
	if ch["haptic"] and level < 4:
		Haptics.play(&"contact", 0.2 + 0.05 * level, mat)
	match level:
		1:
			if ch["visual"]:
				view.show_hint_dent(g[0], 2.0)
				view._set_flash = 1.0  # the plug face nudges (≈ 1.5°)
		2:
			if ch["visual"] and not reduce_motion:
				ghost.play_gesture(g[0], g[1], g[2], 2, g[3])
		3:
			if ch["visual"]:
				view.chalk_level = ChalkLayer.Level.FULL
				view.hint_arrows = "left" if (_needs_tension() or (family == &"warded" and String(step).ends_with("turn") and not auto)) else "right"
		4:
			h4_steps.append(step)
			if ch["light"] and view.dark:
				_was_dark = true
				view.set_dark(false)
				_light_s = LIGHT_S
			if not reduce_motion:
				ghost.play_gesture(g[0], g[1], g[2], 1, 1.5)
			Haptics.play(&"bind", 0.4, mat)
			_start_autopilot()
	_save_history()


func _on_ghost_progress(t: float) -> void:
	if _needs_tension() and not autopilot:
		preview_tension = 0.3 * t  # the plug face answers the ghost, then returns (§2.1 H2)


# ------------------------------------------------------------------ H4 autopilot
func _start_autopilot() -> void:
	autopilot = true
	_auto_s = 0.0
	_auto_lift = 0.0
	var els: Array = _last_vm.get("elements", [])
	_auto_target = _target(els)
	_auto_k = int(_last_vm.get("pick_element", 0))


func _stop_autopilot() -> void:
	if not autopilot:
		return
	autopilot = false
	preview_tension = -1.0
	if not auto and family != &"warded":
		held_tension = 0.35  # control returns in the post-step state: the tension stays on


## Input the lock gets while the master hand works (or after it, the held tension).
func drive(input: Dictionary, vm: Dictionary, delta: float) -> Dictionary:
	if not autopilot:
		if held_tension >= 0.0:
			var held := input.duplicate()
			held["tension"] = maxf(float(held.get("tension", 0.0)), held_tension)
			return held
		return input
	var out := input.duplicate()
	var els: Array = vm.get("elements", [])
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
