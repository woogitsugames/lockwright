extends Node
## Photoreal lock screen (drop-in alternative to res://scenes/lock.tscn, see
## docs/handoff/SESSION-B-LOG.md "Od sesji A: ekran zamka photoreal").
## Same session plumbing as scripts/lock/lock_scene.gd: LockcoreSession (GDExtension) or
## FakeLockSession, InputSampler at 120 Hz, events -> Haptics + Sfx + Events in the same physics
## step. The picture is LockPhotorealView (plan B, D-31).
##
## Dev/CI user args (after `--`), all optional:
##   --lw-family pin_tumbler --lw-seed 42 --lw-tier 4
##   --lw-sim N          run N scripted steps (simple picker) before showing, then freeze the session
##   --lw-shot FILE      after --lw-frames frames (default 20) save the window as PNG and quit
##   --lw-lives N        picks left in the roll (default 3)
##   --lw-dark 1         "in the dark"
##   --lw-touch 1        draw two example thumb dents (screenshots)
##   --lw-bench S        print LW_PERF frame statistics after S seconds and quit
##   --lw-stage S        rest | tension | lift | set: drive the session with a scripted two-thumb
##                       input to that moment, then freeze (N-62 screenshots)
##   --lw-hint N         jump the hint ladder (ONBOARDING §2) to H1..H4 at start (screenshots)
##   --lw-tutorial N     run as tutorial stage N (0 = S1 with guided chalk steps), on its authored lock
##   --lw-spec PATH      play an authored lockwright.lock/1 file (res:// or absolute path)
##   --lw-chalk L        off | reduced | full
##   --lw-auto 1         D-52 auto tension
##   --lw-lesson 1|0     force the family's first lesson on (or off) whatever the save says (T42)
##   --lw-lesson-step N  start the lesson at step N (screenshots; steps + 1 = the closing line)
##   --lw-caution 1|0    force the tool caution on (or off) whatever the save and the tier say (D-120)
##   --lw-lang pl        UI language for this run (screenshots)
##   --lw-loupe 1        open the eyepiece (N-57)
##   --lw-pose blender   show the five stack states of art/renders/section.png (set, false set,
##                       binding, overset, free) for a side-by-side check against Cycles;
##                       with --lw-tension T --lw-core R --lw-stress S to check the diegetic HUD

@export var family: StringName = &"pin_tumbler"
@export var seed := 42
@export var tier := 4

@onready var view: LockPhotorealView = $ViewLayer/View
@onready var sampler: InputSampler = $InputSampler
@onready var pause_cover: Control = $UILayer/PauseCover

var session: RefCounted
var args := {}
var _frozen := false
var _paused := false
var _pause_dark_button: Button = null
var _last_input := {"tension": 0.0, "pick_depth": 0.5, "pick_lift": 0.0}
var _shot_frames := -1
var _bench_left := -1.0
var _frame_ms: PackedFloat32Array = []
var _pose_vm := {}  # fixed ViewModel for --lw-pose
var coach: TutorialCoach
## N-63: families with their own thumb mapping (warded probe: turn, reach, bit). null = pins.
var control = null  # WardedControl | DetectorControl
var hints: TutorialHints
var fb_gain := 1.0  # ONBOARDING §4: S1 ×1.5, S2 ×1.3, S3 ×1.15
var _open_pending := -1.0
# N-58: quiet contact / spring cues while lifting with no tension
var _cue_lift := 0.0
var _cue_peak := 0.0
const NO_TENSION := 0.1
const AUTO_SPOOL_LEVEL := 0.17  # D-52: counter-rotation band (cr 0.12–0.21) while a spool is caught


## The states of the Cycles reference (art/blender/cutaway.py, stacks a..e).
static func blender_pose_vm() -> Dictionary:
	return {
		"elements": [
			{"state": &"set", "position": 0.56, "variant": 0},
			{"state": &"false_set", "position": 0.40, "variant": 1},
			{"state": &"bound", "position": 0.40, "variant": 0},
			{"state": &"overset", "position": 1.28, "variant": 0},
			{"state": &"free", "position": 0.0, "variant": 0},
		],
		"pick_element": 2, "tension": 0.35, "core_rotation": 0.0, "stress": 0.0, "open": false,
	}


func _ready() -> void:
	Sfx.play_music(&"lock_harmony", -10.0)  # S01 quiet lock version
	Sfx.set_music_lowpass(true)  # 2-6 kHz slowed in the lock (audio/v2 README mix)
	Sfx.duck_ambience(-6.0, 400.0)
	_parse_args()
	if args.has("lw-lang"):
		I18n.apply_language(String(args["lw-lang"]))  # screenshots in a given language
	family = StringName(args.get("lw-family", family))
	seed = int(args.get("lw-seed", seed))
	tier = int(args.get("lw-tier", tier))
	var spec_path := String(JobRun.current_job.get("lock_spec", ""))
	if args.has("lw-tutorial"):
		spec_path = JobRun.TUTORIAL_SPECS[clampi(int(args["lw-tutorial"]), 0, JobRun.TUTORIAL_SPECS.size() - 1)]
	spec_path = String(args.get("lw-spec", spec_path))
	session = make_spec_session(spec_path, family, seed, tier) if spec_path != "" else make_session(family, seed, tier)
	if family == &"warded":
		_setup_warded(spec_path)
	elif family == &"lever_detector":
		control = DetectorControl.new(sampler.auto_tension)
	view.landscape_section_max = LockPhotorealView.landscape_max_for(family)  # D-85: no cut mechanism
	view.pause_requested.connect(_on_pause)
	sampler.latch_changed.connect(_on_tension_latch)  # D-107 tension lock
	view.set_lives(int(args.get("lw-lives", "3")))
	view.set_dark(args.get("lw-dark", "0") == "1")
	_build_pause_cover()
	if args.has("lw-sim"):
		_simulate(int(args["lw-sim"]))
		_frozen = true
	if args.get("lw-touch", "0") == "1":
		var s := get_viewport().get_visible_rect().size
		view.touch(0, Vector2(s.x * 0.24, s.y * 0.83), true)
		view.touch(1, Vector2(s.x * 0.72, s.y * 0.80), true)
	if args.get("lw-pose", "") == "blender":
		_pose_vm = blender_pose_vm()
		_pose_vm["tension"] = float(args.get("lw-tension", "0.35"))
		_pose_vm["core_rotation"] = float(args.get("lw-core", "0.0"))
		_pose_vm["stress"] = float(args.get("lw-stress", "0.0"))
		_last_input = {"tension": _pose_vm["tension"], "pick_depth": 0.5, "pick_lift": 0.3}
		_frozen = true
	_setup_guidance()
	if args.has("lw-stage"):
		if control is WardedControl:
			_simulate_warded(String(args["lw-stage"]))
		else:
			_simulate_stage(String(args["lw-stage"]))
		_frozen = true
	view.present(_vm(), _last_input, 1.0)
	if args.get("lw-loupe", "0") == "1":
		view.toggle_loupe.call_deferred()
	if args.has("lw-shot"):
		_shot_frames = int(args.get("lw-frames", "20"))
	if args.has("lw-bench"):
		_bench_left = float(args["lw-bench"])
		RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(), true)
	if not _frozen:
		Sfx.begin_loop(&"tension_resistance", &"brass")
		Sfx.begin_loop(&"pick_drag", &"steel")
		Haptics.begin_continuous(&"tension_resistance")


static func make_session(fam: StringName, sd: int, tr: int) -> RefCounted:
	if ClassDB.class_exists("LockcoreSession"):
		var s: RefCounted = ClassDB.instantiate("LockcoreSession")
		if s.create(fam, sd, tr):
			return s
	return FakeLockSession.create(fam, sd, tr)


## Authored lock (lockwright.lock/1) through lockcore's strict parser. Without the GDExtension
## (FakeLockSession) or on a parse error it falls back to the generated lock fam/sd/tr.
static func make_spec_session(path: String, fam: StringName, sd: int, tr: int) -> RefCounted:
	if ClassDB.class_exists("LockcoreSession") and FileAccess.file_exists(path):
		var s: RefCounted = ClassDB.instantiate("LockcoreSession")
		if s.has_method("create_from_json") and s.create_from_json(FileAccess.get_file_as_string(path)):
			return s
		push_warning("authored lock %s not loaded, playing generated %s t%d" % [path, fam, tr])
	return make_session(fam, sd, tr)


## The player's "Chalk markings" switch (Settings screen, key "reading_aid"; D-121: the lock screen
## used to ask for a key Settings never had, so the switch did nothing). Coach lines, the practice
## goal and the tool caution (D-120) do not depend on it.
static func chalk_layer_on() -> bool:
	return bool(Settings.get_value(&"reading_aid", false))


## Tutorial chalk + guided steps (N-61), first-jobs chalk and the no-tension hint (N-58, D-53).
func _setup_guidance() -> void:
	if args.has("lw-auto"):
		sampler.auto_tension = args["lw-auto"] == "1"
	var auto := sampler.auto_tension
	if Practice.active():
		_setup_practice(auto)
		return
	if control != null:
		control.auto = auto
		var done: int = (Save.get_value("jobs_completed", []) as Array).size()
		var lvl := ChalkLayer.Level.REDUCED if done < 3 or chalk_layer_on() else ChalkLayer.Level.OFF
		if args.has("lw-chalk"):
			lvl = {"off": ChalkLayer.Level.OFF, "reduced": ChalkLayer.Level.REDUCED, "full": ChalkLayer.Level.FULL}.get(args["lw-chalk"], lvl)
		view.chalk_level = lvl
		view.chalk_gauge = false
		coach = null
		if done < 3:
			coach = TutorialCoach.new(0, false, auto)  # N-63: family lines for the first jobs
			coach.family = family
		_setup_caution(auto)
		view.coach = coach
		view.loupe_toggled.connect(func(on: bool) -> void: sampler.frozen = on)
		_setup_hints()
		return
	var tutorial := JobRun.mode == &"tutorial" and not JobRun.current_job.is_empty()
	var stage := JobRun.tutorial_stage
	if args.has("lw-tutorial"):
		tutorial = true
		stage = int(args["lw-tutorial"])
	var jobs_done: int = (Save.get_value("jobs_completed", []) as Array).size()
	var level := ChalkLayer.Level.OFF
	var lesson := {} if tutorial else lesson_for_job(family, args)
	if not lesson.is_empty():
		# T42 / ONBOARDING §8: the family's first job is a guided lesson (full chalk, H0–H4, both modes)
		level = ChalkLayer.Level.FULL
		fb_gain = 1.3
		coach = TutorialCoach.new(0, false, auto)
		coach.set_lesson(lesson)
		if args.has("lw-lesson-step"):
			coach.jump_lesson(int(args["lw-lesson-step"]))
	elif TutorialCoach.has_lesson_for(family) and TutorialCoach.lesson_done(family) \
			and TutorialCoach.jobs_after_lesson(family) < TutorialCoach.FADE_JOBS and not args.has("lw-lesson"):
		# the coach fades: the next jobs of the family keep reduced chalk and the hint ladder, no lines
		level = ChalkLayer.Level.REDUCED
		coach = TutorialCoach.new(0, false, auto)
		coach.set_lesson(TutorialCoach.load_lesson(family), true)
	elif TutorialCoach.has_lesson_for(family) and not tutorial:
		# lesson families after the fade: no pin coach (its gestures are not theirs)
		if chalk_layer_on():
			level = ChalkLayer.Level.REDUCED
	elif tutorial:
		level = ChalkLayer.Level.FULL if stage == 0 else ChalkLayer.Level.REDUCED
		fb_gain = [1.5, 1.3, 1.15][clampi(stage, 0, 2)]
		coach = TutorialCoach.new(stage, stage == 0, auto)
	else:
		if jobs_done < 3 or chalk_layer_on():
			level = ChalkLayer.Level.REDUCED
		coach = TutorialCoach.new(0, false, auto) if jobs_done < 3 else null
	if args.has("lw-chalk"):
		level = {"off": ChalkLayer.Level.OFF, "reduced": ChalkLayer.Level.REDUCED, "full": ChalkLayer.Level.FULL}.get(args["lw-chalk"], level)
	if coach != null:
		coach.family = family  # N-63: wafer / lever get their own lines (no pin wording)
	if not tutorial:
		_setup_caution(auto)
	view.chalk_level = level
	view.chalk_gauge = (auto or (tutorial and stage == 0)) and lesson.is_empty()
	view.coach = coach
	view.loupe_toggled.connect(func(on: bool) -> void: sampler.frozen = on)
	_setup_hints()


## D-79 practice: the goal in chalk at the top of the plate (the lessons' handwriting), even with the
## chalk layer off; marks only with "Warstwa kredy" on. No coach, no hint ladder: the family is known.
func _setup_practice(auto: bool) -> void:
	if control != null:
		control.auto = auto
	var level := ChalkLayer.Level.REDUCED if chalk_layer_on() else ChalkLayer.Level.OFF
	if args.has("lw-chalk"):
		level = {"off": ChalkLayer.Level.OFF, "reduced": ChalkLayer.Level.REDUCED, "full": ChalkLayer.Level.FULL}.get(args["lw-chalk"], level)
	coach = null
	view.coach = null
	view.chalk_level = level
	view.chalk_gauge = auto
	view.goal_line = I18n.t(Practice.current["goal_key"])
	view.loupe_toggled.connect(func(on: bool) -> void: sampler.frozen = on)


## D-79: the lock's lesson_target event; the goal counts once the lock opens (Practice.finish).
func _note_practice(events: Array) -> void:
	Practice.note_events(events)


## T42: the lesson of this job's family, or {} — only the family's first job (lesson not done in
## the save), in the job mode; --lw-lesson 1/0 forces it on/off (dev, screenshots).
static func lesson_for_job(fam: StringName, a: Dictionary) -> Dictionary:
	if a.get("lw-lesson", "") == "0":
		return {}
	var forced: bool = a.get("lw-lesson", "") == "1"
	if not forced and (JobRun.mode != &"job" or JobRun.current_job.is_empty() or TutorialCoach.lesson_done(fam)):
		return {}
	return TutorialCoach.load_lesson(fam)


## D-120: the first lock of the family at the tier where a heavy hand starts to break tools gets the
## tool caution (TutorialCoach, data/tool_caution.json) - in jobs and in the continuous run, not in
## the tutorial or practice. Without a coach of its own the lock gets one that only cautions.
## --lw-caution 1/0 forces it on/off (dev, screenshots).
func _setup_caution(auto: bool) -> void:
	var entry := caution_for_lock(family, tier, args)
	if entry.is_empty():
		return
	if coach == null:
		coach = TutorialCoach.new(0, false, auto)
		coach.family = family
		coach.caution_only = true
	coach.set_caution(entry)


static func caution_for_lock(fam: StringName, tr: int, a: Dictionary) -> Dictionary:
	if a.get("lw-caution", "") == "0":
		return {}
	if a.get("lw-caution", "") == "1":
		return TutorialCoach.caution_table().get(String(fam), {})
	if JobRun.current_job.is_empty() or TutorialCoach.caution_done(fam):
		return {}  # a lock outside a job or the run (dev scenes, screenshots) has none
	return TutorialCoach.caution_for(fam, tr)


## ONBOARDING §2: hint ladder H0–H4 + chalk gesture hints (D-80) wherever a coach runs (S1–S3, first jobs).
## Off for scripted dev / CI runs (frozen sessions, screenshots of a stage).
func _setup_hints() -> void:
	if coach == null or coach.caution_only or args.has("lw-stage") or args.has("lw-sim") or args.has("lw-pose") or args.get("lw-hints", "1") == "0":
		return
	hints = TutorialHints.new()
	hints.name = "TutorialHints"
	add_child(hints)
	hints.setup(view, coach, family, sampler.auto_tension, control)
	if args.has("lw-hint"):
		hints.jump_to.call_deferred(int(args["lw-hint"]))  # dev: screenshot one hint level


func _vm() -> Dictionary:
	return _pose_vm if not _pose_vm.is_empty() else session.describe()


func _parse_args() -> void:
	var a := OS.get_cmdline_user_args()
	var i := 0
	while i < a.size():
		if a[i].begins_with("--") and i + 1 < a.size():
			args[a[i].substr(2)] = a[i + 1]
			i += 2
		else:
			i += 1


## D-88: in exported builds the view is refreshed once per rendered frame (from _process) with the
## latest ViewModel and the summed delta, not on every 120 Hz physics step (two per frame at 60 FPS):
## the picture cannot change between two frames anyway, and present() was the biggest script cost of
## the step (~1 ms on SM-A165F). Lockcore, haptics, sound and view.on_event() stay per step.
## The editor binary (GUT, desktop runs) keeps the immediate per-step refresh tests rely on.
var view_per_frame := OS.has_feature("template")
var _pv_vm: Dictionary = {}
var _pv_input: Dictionary = {}
var _pv_delta := 0.0
var _pv_pending := false


func _present(vm: Dictionary, input: Dictionary, delta: float) -> void:
	if not view_per_frame:
		view.present(vm, input, delta)
		return
	_pv_vm = vm
	_pv_input = input
	_pv_delta += delta
	_pv_pending = true


func _flush_present() -> void:
	if not _pv_pending:
		return
	_pv_pending = false
	view.present(_pv_vm, _pv_input, _pv_delta)
	_pv_delta = 0.0


func _physics_process(delta: float) -> void:
	if _frozen or _paused:
		_present(_vm(), _last_input, delta)
		return
	if session.finished():
		_present(session.describe(), _last_input, delta)
		if not session.is_open():
			Events.lock_failed.emit(StringName(session.failure()))  # N-64: never a dead lock (Events ignores repeats)
		if coach != null:
			coach.update(session.describe(), _last_input, [], false, false, delta)
		if _open_pending > 0.0:
			_open_pending -= delta
			if _open_pending <= 0.0:
				Events.lock_opened.emit()
		return
	var input := sampler.sample()
	var events: Array
	if sampler.raw and not session is FakeLockSession:
		events = session.step(input["tension"], input["pick_depth"], input["pick_lift"], input.get("rotate", 0.0), input.get("push", 0.0), input.get("tool", 0))
	elif control != null and not session is FakeLockSession:
		input = control.map(input, sampler, session.describe(), delta)
		if hints != null:
			input = hints.drive(input, session.describe(), delta)
		events = session.step(input["tension"], input["pick_depth"], input["pick_lift"], input["rotate"], input["push"], input["tool"])
	else:
		if hints != null:
			input = hints.drive(input, session.describe(), delta)
		events = session.step(input["tension"], input["pick_depth"], input["pick_lift"])
	_last_input = input
	if Practice.active():
		_note_practice(events)  # before the loop: an "open" event leaves the practice run at once
	for e in events:
		Haptics.play(e["kind"], minf(e["intensity"] * fb_gain, 1.0), e["material"])
		Sfx.play(e["kind"], e["material"], 0.0 if fb_gain <= 1.0 else 2.0, 1.0)
		view.on_event(e)
		Events.lock_event.emit(e)
		if e["kind"] == &"open":
			_on_open()
		if e["kind"] == &"break":
			Events.lock_failed.emit(&"break")
	var vm: Dictionary = session.describe()
	if control == null:
		_no_tension_cues(vm, input)
	if sampler.auto_tension and (control == null or control is DetectorControl):  # N-72: detector levers have false gates too
		sampler.auto_level = AUTO_SPOOL_LEVEL if _has_state(vm, "false_set") else InputSampler.AUTO_LEVEL
	_update_guidance(vm, input, events, delta)
	if hints != null and not sampler.raw and hints.preview_tension >= 0.0:  # H2: the plug face answers the chalk gesture tension
		vm = vm.duplicate()
		vm["tension"] = maxf(float(vm.get("tension", 0.0)), hints.preview_tension)
	var resistance: float = vm.get("tension_resistance", vm.get("resistance", 0.0))
	Haptics.update_continuous(&"tension_resistance", resistance, 0.3)
	Sfx.update_loop(&"tension_resistance", resistance)
	Sfx.update_loop(&"pick_drag", vm.get("pick_drag", 0.0))
	_present(vm, input, delta)


## Coach + hint ladder of one physics step (shared with the plan-B family screens). The D-52 mode is
## read every step, so switching auto tension in the pause applies at once.
func _update_guidance(vm: Dictionary, input: Dictionary, events: Array, delta: float) -> void:
	if coach != null:
		coach.auto_tension = sampler.auto_tension
		var c_input := input
		var c_events := events
		if hints != null and coach.has_lesson() and not hints.own_input.is_empty():
			# N-98: the lesson waits for the player: the master hand's input and events do not pass a step
			c_input = hints.own_input
			c_events = [] if hints.drove else events
		coach.update(vm, c_input, c_events, sampler.left_down(), sampler.right_down(), delta)
	if hints != null and not sampler.raw:
		hints.auto = sampler.auto_tension
		hints.tick(vm, input, events, sampler.left_down(), sampler.right_down(), delta)


func _unhandled_input(event: InputEvent) -> void:
	# Thumb dents only; the InputSampler reads the same events for the lock.
	if event is InputEventScreenTouch:
		view.touch(event.index, event.position, event.pressed)
	elif event is InputEventScreenDrag:
		view.touch(event.index, event.position, true)
	# Esc / Android Back: handled only by the Nav autoload (N-69: a second handler here
	# turned one press into pause+resume) -> go_back() below, then _on_pause/_on_resume.


## Nav (Android back / Esc): close the eyepiece first, otherwise let Nav open the pause.
func go_back() -> bool:
	if view.zoomed:
		view.toggle_loupe()
		return true
	return false


func _on_open() -> void:
	_note_lesson_open()
	# tutorial: let the plug turn and the praise show before the stage screen (N-61 step 6)
	if coach != null and coach.guided:
		_open_pending = 1.8
	else:
		Events.lock_opened.emit()


## T42: the lesson is done once its lock opens; later jobs of the family count towards the fade.
func _note_lesson_open() -> void:
	if coach != null and coach.has_caution() and not args.has("lw-caution") and not JobRun.current_job.is_empty():
		TutorialCoach.mark_caution_done(family)  # D-120
	if args.has("lw-lesson") or JobRun.mode != &"job" or JobRun.current_job.is_empty():
		return
	if coach != null and coach.has_lesson() and not coach.lesson_quiet:
		TutorialCoach.mark_lesson_done(family)
	elif TutorialCoach.has_lesson_for(family) and TutorialCoach.lesson_done(family):
		TutorialCoach.count_job_after_lesson(family)


static func _has_state(vm: Dictionary, st: String) -> bool:
	for e in vm.get("elements", []):
		if String(e.get("state", "")) == st:
			return true
	return false


## N-58: with no tension the lock itself is silent while a free pin follows the pick. Give each
## lift a quiet contact tick (every 0.08 of lift) and the drop back a spring sound + light haptic.
func _no_tension_cues(vm: Dictionary, input: Dictionary) -> void:
	var t := float(input.get("tension", 0.0))
	var lift := maxf(float(input.get("pick_lift", 0.0)), 0.0)
	var idx := int(vm.get("pick_element", -1))
	var els: Array = vm.get("elements", [])
	var free := idx >= 0 and idx < els.size() and String(els[idx].get("state", "")) == "free"
	if t >= NO_TENSION or not free:
		_cue_lift = lift
		_cue_peak = 0.0
		return
	if lift > _cue_lift + 0.08:
		_cue_lift = lift
		_cue_peak = maxf(_cue_peak, lift)
		Sfx.play(&"contact", &"brass", -12.0, 1.15)
		Haptics.play(&"contact", 0.15, &"brass")
	elif lift < _cue_lift - 0.04:
		_cue_lift = lift
	if _cue_peak >= 0.2 and lift < 0.04:
		# the pin falls back on its spring: audible and visible (it follows the pick down)
		Sfx.play(&"contact", &"steel", -9.0, 0.7)
		Haptics.play(&"contact", 0.25, &"steel")
		_cue_peak = 0.0


## N-62 screenshots: drive a scripted two-thumb input to a moment of the opening, then freeze.
##   rest: nothing; tension: T 0.35 held, a stack binds; lift: the binding stack lifted to just
##   under its window; set: lifted until it sets, then the pick lowered (the set stays).
func _simulate_stage(stage: String) -> void:
	var t := 0.35
	var feed := func(tt: float, depth: float, lift: float) -> Array:
		_last_input = {"tension": tt, "pick_depth": depth, "pick_lift": lift}
		var ev: Array = session.step(tt, depth, lift)
		for e in ev:
			view.on_event(e)
		view.present(session.describe(), _last_input, 1.0 / 120.0)
		if coach != null:
			coach.update(session.describe(), _last_input, ev, true, lift > 0.0, 1.0 / 120.0)
		return ev
	if stage == "rest":
		return
	for i in 90:
		feed.call(t, 0.5, 0.0)
	if stage == "tension":
		return
	var els: Array = session.describe()["elements"]
	var b := 0
	for j in els.size():
		if String(els[j]["state"]) in ["bound", "near"]:
			b = j
	var depth := (float(b) + 0.5) / float(els.size())
	var lo := float(els[b].get("window_lo", 0.5))
	var lift := 0.0
	while lift < (lo - 0.08 if stage == "lift" else 1.0):
		lift += 0.004
		var ev: Array = feed.call(t, depth, lift)
		if ev.any(func(e: Dictionary) -> bool: return e["kind"] == &"set"):
			break
	if stage == "lift":
		for i in 30:
			feed.call(t, depth, lift)
		return
	for i in 40:
		feed.call(t, depth, maxf(lift - i * 0.02, 0.0))


## Scripted picker for screenshots/tests: holds tension, lifts the binding stack until it sets.
func _simulate(steps: int) -> void:
	var t := 0.42
	for i in steps:
		var vm: Dictionary = session.describe()
		var els: Array = vm.get("elements", vm.get("pins", []))
		var target := -1
		for j in els.size():
			var st := String(els[j].get("state", ""))
			if st == "bound" or st == "near":
				target = j
				break
		if target < 0:
			target = (i / 60) % maxi(els.size(), 1)
		var depth := (float(target) + 0.5) / float(maxi(els.size(), 1))
		var lift := 0.55 if (i % 40) < 30 else -0.2
		_last_input = {"tension": t, "pick_depth": depth, "pick_lift": lift}
		for e in session.step(t, depth, lift):
			view.on_event(e)
		if session.finished():
			break


# ------------------------------------------------------------------ N-63 warded
func _setup_warded(spec_path: String) -> void:
	control = WardedControl.new(tier, sampler.auto_tension)
	var twin: RefCounted = make_spec_session(spec_path, family, seed, tier) if spec_path != "" else make_session(family, seed, tier)
	var spans: Array = WardedControl.measure_spans(twin) if twin is not FakeLockSession else []
	if view.has_method("set_wards"):
		view.call("set_wards", spans)
		view.call("set_bit", control.bit, control.bit_width())
	if view.has_signal("bit_pressed"):
		view.connect("bit_pressed", _on_bit_pressed)


func _on_bit_pressed() -> void:
	if control == null or _frozen or _paused:
		return
	if control.cycle_bit(session.describe(), sampler.left_down() or sampler.right_down()):
		view.call("set_bit", control.bit, control.bit_width())
		Sfx.play(&"contact", &"steel", -6.0, 1.3)
		Haptics.play(&"contact", 0.3, &"steel")
	else:
		# only out of the keyhole and unturned: a dull knock, nothing changes
		Sfx.play(&"contact", &"iron", -10.0, 0.7)
		Haptics.play(&"contact", 0.15, &"iron")


## Screenshots / tests: replay lockcore's scripted plan (solver inputs) until a moment.
##   blocked: the probe pressed against the first ward with the reach outside its channel;
##   turn: a third of the turn done; bolt: the bit on the bolt; set: tumbler lifted; open.
func _simulate_warded(stage: String) -> void:
	if not ClassDB.class_exists("LockcoreSession"):
		return
	var rep: Dictionary = ClassDB.class_call_static(&"LockcoreSession", &"solve", family, seed, tier)
	var rows: Array = rep.get("inputs", [])
	if rows.is_empty():
		return
	control.bit = int(rows[rows.size() - 1][5])
	view.call("set_bit", control.bit, control.bit_width())
	var feed := func(r: Array) -> void:
		_last_input = {"tension": r[0], "pick_depth": r[1], "pick_lift": r[2], "rotate": r[3], "push": r[4], "tool": r[5]}
		for e in session.step(r[0], r[1], r[2], r[3], r[4], r[5]):
			view.on_event(e)
		view.present(session.describe(), _last_input, 1.0 / 120.0)
	if stage == "blocked":
		var first: Array = rows[rows.size() - 1]
		feed.call([0.0, 0.0, 0.0, 0.0, 0.0, first[5]])
		for i in 240:
			feed.call([first[0] * 0.8, 1.0, 0.0, 1.0, 0.0, first[5]])
		return
	for r in rows:
		feed.call(r)
		var vm: Dictionary = session.describe()
		var els: Array = vm["elements"]
		var bolt := String(els[els.size() - 1]["state"])
		var th := float(vm["core_rotation"])
		if (stage == "turn" and th >= 0.33) or (stage == "bolt" and bolt == "bound" and th > 0.86) or (stage == "set" and bolt == "set") or session.finished():
			break
	for i in 30:
		view.present(session.describe(), _last_input, 1.0 / 120.0)


# ------------------------------------------------------------------ pause (HUD.md §6, simplified)
func _build_pause_cover() -> void:
	# N-75: centred dark-paper panel with enamel plates inside the safe area (PausePanel)
	pause_cover.visible = false
	pause_cover.process_mode = Node.PROCESS_MODE_ALWAYS
	var buttons := PausePanel.build(pause_cover as ColorRect, [
		[&"pause.resume", _on_resume, &"primary_navy"],
		[&"pause.dark_mode", _on_dark, &"navy"],
		[&"pause.quit", _on_quit, &"burgundy"]])
	_pause_dark_button = buttons[&"pause.dark_mode"]


func _on_pause() -> void:
	_paused = true
	if _pause_dark_button != null:
		_pause_dark_button.text = I18n.t(&"pause.dark_mode_off" if view.dark else &"pause.dark_mode")
	PausePanel.open(pause_cover)
	get_tree().paused = true


func _on_resume() -> void:
	_paused = false
	pause_cover.visible = false
	get_tree().paused = false


func _on_dark() -> void:
	view.set_dark(not view.dark)
	_on_resume()


func _on_quit() -> void:
	get_tree().paused = false
	if Practice.active():  # D-79: leaving a practice lock goes back to the Workshop's Ćwiczenia tab
		Practice.finish(false, true)
		get_tree().change_scene_to_file(Events.WORKSHOP)
		return
	get_tree().change_scene_to_file(quit_target())


## N-85: "Exit" from the pause of a job goes back to the job list (the list scrolls to that job); the
## tutorial and the endless shift go back to the main menu as before.
static func quit_target() -> String:
	if JobRun.mode == &"job" and not JobRun.current_job.is_empty():
		return "res://scenes/jobs_list.tscn"
	return "res://scenes/main_menu.tscn"


# ------------------------------------------------------------------ shots and perf
func _process(delta: float) -> void:
	_flush_present()
	if _shot_frames > 0:
		_shot_frames -= 1
		if _shot_frames == 0:
			var img := get_viewport().get_texture().get_image()
			img.save_png(args["lw-shot"])
			print("SHOT ", args["lw-shot"], " ", img.get_size())
			_print_perf()
			get_tree().quit()
			# lavapipe sometimes hangs in RenderingDevice teardown: do not keep CI waiting
			get_tree().create_timer(3.0).timeout.connect(func() -> void: OS.kill(OS.get_process_id()))
		return
	if _bench_left > 0.0:
		_frame_ms.append(delta * 1000.0)
		_bench_left -= delta
		if _bench_left <= 0.0:
			_print_perf()
			get_tree().quit()


func _print_perf() -> void:
	var states := []
	for el in _vm().get("elements", _vm().get("pins", [])):
		states.append("%s@%.2f" % [el.get("state", "?"), float(el.get("position", el.get("pos", 0.0)))])
	print("LW_STATE ", states, " core=", _vm().get("core_rotation", 0.0), " T=", _last_input.get("tension", 0.0))
	var s := _frame_ms.duplicate()
	s.sort()
	var p95: float = s[int(0.95 * (s.size() - 1))] if s.size() > 0 else 0.0
	print("LW_PERF scene=lock_photoreal frame_p95=%.2f gpu=%.3f draws=%d prims=%d vram_mb=%.1f vp=%s" % [
		p95, RenderingServer.viewport_get_measured_render_time_gpu(get_viewport().get_viewport_rid()),
		Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
		Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0, view.viewport.size])


## D-107 tension lock: clamp drawn on the wrench arm, a soft tuk + haptic (never haptics alone),
## and a line for the screen reader.
func _on_tension_latch(on: bool) -> void:
	view.set_tension_clamp(on)
	Sfx.play(&"gate_align", &"steel", -6.0)
	Haptics.play(&"gate_align" if on else &"contact", 0.6, &"steel")
	if UiA11y.screen_reader_active():
		UiA11y.announce(I18n.t(&"a11y.tension_latched" if on else &"a11y.tension_released"))

