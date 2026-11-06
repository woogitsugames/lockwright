extends "res://scripts/lock/lock_job.gd"
## D-59 plan-B lock screens for the dial safe and the thumbwheel combination lock (scenes
## photoreal/lock_job_dial_safe.tscn, lock_job_combo.tscn). Same session plumbing as the pin and
## warded screens (lock_photoreal.gd: LockcoreSession, InputSampler at 120 Hz, events -> Haptics +
## Sfx + Events in the same physics step, pause flap, loupe, chalk, N-65 quality); only the thumb
## mapping (DialSafeControl / ComboControl) and the scripted stages for screenshots differ.
## lockcore v0.6: both families read only tension, pick_depth and pick_lift.
##
## Family sub-events arrive as their nearest base event (`kind`), with `sub` for the detail:
## dial_safe safe.detent / safe.fence_bounce = contact, safe.pickup = bind, safe.fence_drop = set;
## combo combo.detent = contact, combo.slip = overset. Detent ticks are played quieter, the rest
## through the base event's sound and haptic.

var fam_control: RefCounted  # DialSafeControl | ComboControl


func _fam() -> RefCounted:
	if fam_control == null:
		match family:
			&"dial_safe":
				fam_control = DialSafeControl.new(sampler.auto_tension)
				sampler.auto_level = DialSafeControl.AUTO_LEVEL
			_:
				fam_control = ComboControl.new(sampler.auto_tension)
				sampler.auto_level = ComboControl.AUTO_LEVEL
	fam_control.auto = sampler.auto_tension
	return fam_control


func _ready() -> void:
	super._ready()
	_fam()
	if view.has_method("set_hint"):
		var done: int = (Save.get_value("jobs_completed", []) as Array).size()
		var line: String = I18n.t(&"lock.combo_hint")
		if family == &"dial_safe":
			line = I18n.t(&"lock.dial_hint")
		elif family == &"disc_detainer":
			line = I18n.t(&"lock.disc_hint")
		view.call("set_hint", line if done < 6 else "")


func _physics_process(delta: float) -> void:
	if _frozen or _paused:
		view.present(_vm(), _last_input, delta)
		return
	if session.finished():
		view.present(session.describe(), _last_input, delta)
		if not session.is_open():
			Events.lock_failed.emit(StringName(session.failure()))
		return
	var input: Dictionary = sampler.sample() if is_raw_source(sampler) else _fam().map(sampler.sample(), sampler)
	var events: Array = session.step(input["tension"], input["pick_depth"], input["pick_lift"])
	_last_input = input
	for e in events:
		play_event(e, fb_gain)
		view.on_event(e)
		Events.lock_event.emit(e)
		if e["kind"] == &"open":
			_on_open()
	var vm: Dictionary = session.describe()
	var resistance: float = vm.get("tension_resistance", 0.0)
	Haptics.update_continuous(&"tension_resistance", resistance, 0.3)
	Sfx.update_loop(&"tension_resistance", resistance)
	Sfx.update_loop(&"pick_drag", vm.get("pick_drag", 0.0))
	view.present(vm, input, delta)


## QA hook (qa/bot/qa_sampler.gd): a sampler that carries lockcore input rows (`rows`, e.g. the
## replay of LockcoreSession.solve) already speaks lockcore's frame, so the thumb mapping is skipped.
static func is_raw_source(s: Node) -> bool:
	return s != null and s.get("rows") is Array


## One lockcore event through the existing sounds and haptics (nearest base event).
static func play_event(e: Dictionary, gain: float = 1.0) -> void:
	var kind: StringName = e["kind"]
	var sub := int(e.get("sub", 0))
	var vol := 0.0 if gain <= 1.0 else 2.0
	var pitch := 1.0
	var inten := minf(float(e["intensity"]) * gain, 1.0)
	if kind == &"contact" and sub == 1:  # safe.detent / combo.detent: one tick per division
		vol -= 8.0
		pitch = 1.25
		inten *= 0.6
	elif kind == &"bind" and sub == 2:   # safe.pickup: a lower "tok" for wheels nearer the dial
		pitch = 0.85 + 0.05 * clampi(int(e.get("element", 0)), 0, 4)
	elif kind == &"set" and sub == 3:    # safe.fence_drop: a heavy fall
		pitch = 0.7
		inten = 1.0
	Haptics.play(kind, inten, e["material"])
	Sfx.play(kind, e["material"], vol, pitch)


# ------------------------------------------------------------------ screenshots / tests
## Scripted moments through lockcore's own plan (LockcoreSession.solve), then frozen:
##   dial_safe: rest | listen (handle pressed, first wheels carried) | gate (wheel 0 at its gate)
##              | set (wheel 0 left in its gate, the next one carried) | open
##   combo:     rest | pull (first wheel bound) | slip (the bound wheel spun too fast) | set (first
##              wheel in its gate) | open
func _simulate_stage(stage: String) -> void:
	if not ClassDB.class_exists("LockcoreSession") or stage == "rest":
		return
	var rep: Dictionary = ClassDB.class_call_static(&"LockcoreSession", &"solve", family, seed, tier)
	var rows: Array = rep.get("inputs", [])
	var feed := func(r: Array) -> Array:
		_last_input = {"tension": r[0], "pick_depth": r[1], "pick_lift": r[2], "rotate": 0.0, "push": 0.0, "tool": 0}
		var ev: Array = session.step(r[0], r[1], r[2])
		for e in ev:
			view.on_event(e)
		view.present(session.describe(), _last_input, 1.0 / 120.0)
		return ev
	if family == &"combo" and stage == "slip":
		# pull, select the first binding wheel, roll it fast: the sleeve slips
		var depth := 0.5
		for r in rows:
			if absf(float(r[2])) > 0.0:
				depth = float(r[1])
				break
		for i in 60:
			feed.call([0.34, depth, 0.0])
		for i in 40:
			feed.call([0.34, depth, 0.95])
		return
	var seen_set := 0
	for r in rows:
		var ev: Array = feed.call(r)
		var vm: Dictionary = session.describe()
		var els: Array = vm["elements"]
		var states := els.map(func(e: Dictionary) -> String: return String(e["state"]))
		for e in ev:
			if e["kind"] == &"set" and int(e["element"]) >= 0:
				seen_set += 1
		if stage in ["listen", "pull"] and float(r[0]) > 0.2 and states.has("bound") and (family == &"combo" or int(vm.get("pick_element", -1)) >= 0):
			break
		if stage == "gate" and states.size() > 0 and states[0] == "near":
			var e0: Dictionary = els[0]
			var g0 := (float(e0["window_lo"]) + float(e0["window_hi"])) * 0.5
			if absf(fposmod(float(e0["position"]) - g0 + 0.5, 1.0) - 0.5) <= (float(e0["window_hi"]) - float(e0["window_lo"])) * 0.5:
				break
		if stage == "set" and seen_set >= 1 and states.has("bound"):
			break
		if session.finished():
			break
	if stage == "open" or stage == "set":
		for i in 30:
			view.present(session.describe(), _last_input, 1.0 / 120.0)
	else:
		for i in 6:
			view.present(session.describe(), _last_input, 1.0 / 120.0)


func _simulate(steps: int) -> void:
	if not ClassDB.class_exists("LockcoreSession"):
		return
	var rows: Array = ClassDB.class_call_static(&"LockcoreSession", &"solve", family, seed, tier).get("inputs", [])
	for i in mini(steps, rows.size()):
		var r: Array = rows[i]
		_last_input = {"tension": r[0], "pick_depth": r[1], "pick_lift": r[2]}
		for e in session.step(r[0], r[1], r[2]):
			view.on_event(e)
		if session.finished():
			break
