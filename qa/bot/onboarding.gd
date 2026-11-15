extends SceneTree
## Onboarding walk (D-134): a fresh install played from boot through the tutorial and the first jobs,
## measured. Run through qa/run_onboarding.sh (fresh user://, fixed 120 FPS step). Unlike the career
## bot it does not hunt for soft-locks; it counts what a new player has to get through:
##   screens and taps before the first lock, seconds in which nothing can be done (waits; a scene
##   that a tap ends, like the arrival on the stairs, is counted apart as "watch"), words on each screen, time to the first opened lock (T1) and to the first opened job lock (T2), and
##   where the game leaves the player after each step.
## Locks: the authored tutorial locks are played by the "patient" player of qa_sampler.gd; job locks
## by lockcore's feel / clumsy bots (replay_tool record, QA_REPLAY_TOOL) or the solver.
## Output: stdout lines "ONB_STEP ..." and "ONB_REPORT {json}"; with a window (xvfb) and QA_SHOTS=dir
## a PNG of every screen as the player meets it.
##   QA_PROFILE feel|clumsy|solver   QA_LANG pl|en   QA_JOBS n (default 3)   QA_TWO_THUMBS 1
##   QA_READ_WPM words per minute for the reading estimate (default 180)   QA_TAP_S seconds per tap (0.8)

const JOBS_DEFAULT := 3
const LOCK_LIMIT_S := 240.0
const IDLE_LIMIT_S := 20.0
const SETTLE_FRAMES := 60  # 0.5 s: entry fades are over before a screen is read / shot

var report := {"schema": "lockwright.onboarding/1", "steps": [], "locks": [], "problems": []}
var _sim := 0.0
var _taps := 0
var _screens := 0
var _wait_s := 0.0   # time with nothing to press (forced waits)
var _words := 0
var _watch_s := 0.0  # scenes that play by themselves but end at a tap (the arrival on the stairs)
var _shots := ""
var _shot_n := 0
var _dir := ""
var _jobs_done := 0
var _first_lock_at := {}   # counters when the first lock screen appeared
var _marks := {}


func _initialize() -> void:
	_dir = (get_script() as Script).resource_path.get_base_dir()
	if DisplayServer.get_name() != "headless":
		# a window (xvfb, software GL) is for the pictures: the game runs in real time and may step the
		# physics many times per drawn frame, instead of drawing all 120 frames of every second
		Engine.max_physics_steps_per_frame = 120
	_shots = OS.get_environment("QA_SHOTS")
	if _shots != "":
		DirAccess.make_dir_recursive_absolute(_shots)
	change_scene_to_file(ProjectSettings.get_setting("application/run/main_scene"))
	_run()


func _al(n: String) -> Node:
	return root.get_node(n)


func _jr() -> GDScript:
	return load("res://scripts/lock/job_run.gd")


func _frames(n: int) -> void:
	for k in n:
		await physics_frame
		_sim += 1.0 / 120.0


func _scene() -> String:
	return current_scene.scene_file_path.get_file().get_basename() if current_scene else ""


## Texts the player can see now: visible, not faded out, and inside the window (a long list counts
## only the rows on screen).
func _visible_texts(node: Node = null, out: PackedStringArray = []) -> PackedStringArray:
	if node == null:
		node = root
	var win := Rect2(Vector2.ZERO, root.get_visible_rect().size)
	for c in node.get_children():
		if c is Window and not (c as Window).visible:
			continue
		if c is CanvasItem and not (c as CanvasItem).is_visible_in_tree():
			continue
		var t := ""
		if c is Label:
			t = (c as Label).text
		elif c is Button:
			t = (c as Button).text
		elif c is RichTextLabel:
			t = (c as RichTextLabel).get_parsed_text()
		if t.strip_edges() != "" and (c as CanvasItem).modulate.a > 0.05 and win.intersects((c as Control).get_global_rect()):
			out.append(t.strip_edges())
		_visible_texts(c, out)
	return out


static func _count_words(texts: PackedStringArray) -> int:
	var n := 0
	for t in texts:
		for w in t.replace("\n", " ").split(" ", false):
			if w.length() > 1 or w.is_valid_int():
				n += 1
	return n


func _buttons(node: Node = null, out: Array = []) -> Array:
	if node == null:
		node = root
	for c in node.get_children():
		if c is CanvasItem and not (c as CanvasItem).is_visible_in_tree():
			continue
		if c is BaseButton and not (c as BaseButton).disabled:
			out.append(c)
		_buttons(c, out)
	return out


func _button(names: Array) -> BaseButton:
	for b in _buttons():
		for n in names:
			if String(b.name) == n:
				return b
	return null


func _shot(tag: String) -> void:
	if _shots == "" or DisplayServer.get_name() == "headless":
		return
	await process_frame
	await process_frame
	_shot_n += 1
	var img := root.get_texture().get_image()
	img.save_png("%s/%02d_%s.png" % [_shots, _shot_n, tag])


## A screen the player has to take in: counted, its words added, logged.
func _note_screen(tag: String, extra_words := 0, note := "", within: Node = null) -> void:
	var texts := _visible_texts(within)
	var w := _count_words(texts) + extra_words
	_screens += 1
	_words += w
	var forward := []
	for b in _buttons():
		forward.append(String(b.name))
	var step := {"t": snappedf(_sim, 0.01), "screen": tag, "words": w, "buttons": forward.size(), "taps_so_far": _taps, "note": note}
	report["steps"].append(step)
	print("ONB_STEP t=%.2f screen=%s words=%d buttons=%d taps=%d %s" % [_sim, tag, w, forward.size(), _taps, note])
	print("ONB_TEXT %s | %s" % [tag, " ¦ ".join(texts)])
	await _shot(tag)


func _tap(b: BaseButton, why: String) -> void:
	_taps += 1
	print("ONB_TAP t=%.2f %s/%s (%s)" % [_sim, _scene(), b.name, why])
	b.emit_signal("pressed")


## Waits while `cond` is false; the time counts as a forced wait. Returns false on timeout.
func _wait_until(cond: Callable, why: String, limit := IDLE_LIMIT_S) -> bool:
	var t0 := _sim
	while not cond.call():
		await _frames(3)
		if _sim - t0 > limit:
			report["problems"].append({"t": snappedf(_sim, 0.01), "screen": _scene(), "problem": "nothing to do for %d s: %s" % [int(limit), why]})
			return false
	if _sim - t0 > 0.05:
		_wait_s += _sim - t0
		print("ONB_WAIT t=%.2f %.2fs %s" % [_sim, _sim - t0, why])
	return true


func _mark(name: String) -> void:
	_marks[name] = {"t": snappedf(_sim, 0.01), "taps": _taps, "screens": _screens, "wait_s": snappedf(_wait_s, 0.01), "words": _words}
	print("ONB_MARK %s %s" % [name, JSON.stringify(_marks[name])])


func _finish(reason: String) -> void:
	report["end"] = reason
	report["marks"] = _marks
	report["totals"] = {"t": snappedf(_sim, 0.01), "taps": _taps, "screens": _screens, "wait_s": snappedf(_wait_s, 0.01), "words": _words, "watch_s": snappedf(_watch_s, 0.01)}
	var wpm := float(OS.get_environment("QA_READ_WPM")) if OS.get_environment("QA_READ_WPM") != "" else 180.0
	var tap_s := float(OS.get_environment("QA_TAP_S")) if OS.get_environment("QA_TAP_S") != "" else 0.8
	for k: String in _marks:
		var m: Dictionary = _marks[k]
		m["human_estimate_s"] = snappedf(float(m["t"]) + float(m["words"]) / wpm * 60.0 + float(m["taps"]) * tap_s, 0.1)
	print("ONB_REPORT " + JSON.stringify(report))
	quit(0)


# ------------------------------------------------------------------ the walk
func _run() -> void:
	await _frames(2)
	report["lang"] = _al("I18n").call("current_language")
	report["profile"] = OS.get_environment("QA_PROFILE") if OS.get_environment("QA_PROFILE") != "" else "solver"
	report["two_thumbs"] = OS.get_environment("QA_TWO_THUMBS") == "1"
	var want_jobs := int(OS.get_environment("QA_JOBS")) if OS.get_environment("QA_JOBS") != "" else JOBS_DEFAULT
	var last := ""
	var guard := 0
	while guard < 400:
		guard += 1
		if current_scene == null:
			await _frames(2)
			continue
		var sc := _scene()
		var fresh := sc != last or _fresh_lock
		_fresh_lock = false
		last = sc
		if current_scene.find_child("InputSampler", true, false) != null:
			if not await _lock():
				return _finish("lock_not_opened")
			last = ""  # the same scene file may follow (tutorial stage -> stage)
			continue
		if fresh:
			await _frames(SETTLE_FRAMES if sc != "boot" else 12)
			if _scene() != sc:
				continue
		match sc:
			"boot":
				await _boot()
			"main_menu":
				await _note_screen("main_menu", 6, "menu words are painted on the board")
				var done: bool = _al("Save").call("get_value", "tutorial_done", false)
				var b := _button(["JobsButton"] if done else ["PlayButton"])
				_tap(b, "jobs" if done else "play")
				await _wait_until(func() -> bool: return _scene() != "main_menu", "menu press animation")
			"control_choice":
				await _note_screen("control_choice")
				if OS.get_environment("QA_TWO_THUMBS") == "1":
					_tap(current_scene.find_child("Manual", true, false).find_child("Hit", true, false), "two thumbs")
					await _frames(12)
				_tap(_button(["ContinueButton", "StartButton"]), "continue")
				await _frames(4)
			"tutorial":
				var stage: int = _jr().tutorial_stage
				await _note_screen("tutorial_s%d" % (stage + 1) if not _al("Save").call("get_value", "tutorial_done", false) else "tutorial_done")
				_tap(_button(["StartButton"]), "start stage")
				await _frames(4)
			"jobs_list":
				var da: Variant = current_scene.get("day_after")
				if da != null and is_instance_valid(da) and not da.call("is_finished"):
					await _day_after(da)
					continue
				if _jobs_done >= want_jobs:
					await _note_screen("jobs_list_end")
					_mark("back_on_list_after_%d_jobs" % _jobs_done)
					return _finish("done")
				await _note_screen("jobs_list")
				var job_btn: BaseButton = null
				for b in _buttons():
					if String(b.name).begins_with("Job_") and (b as Button).theme_type_variation != &"DonePlate":
						job_btn = b
						break
				if job_btn == null:
					return _finish("no_job_on_list")
				_tap(job_btn, "first open job")
				await _frames(4)
			"job_arrival":
				await _arrival()
			"job_verify":
				await _note_screen("job_verify")
				var cards := current_scene.find_child("Cards", true, false)
				_tap(_button(["AcceptButton"]), "open")
				await _wait_until(func() -> bool: return _scene() != "job_verify", "after the decision")
			"job_payment":
				await _note_screen("job_payment", 12, "receipt fields are handwriting on the paper")
				_tap(_button(["ContinueButton"]), "continue")
				_jobs_done += 1
				await _frames(4)
			_:
				await _note_screen(sc, 0, "unexpected screen")
				var any := _button(["ContinueButton", "StartButton", "BackButton"])
				if any == null:
					return _finish("stuck_on_" + sc)
				_tap(any, "generic")
				await _frames(4)
	_finish("guard")


var _fresh_lock := false


func _boot() -> void:
	var notice := current_scene.get_node_or_null("NoticePanel") as Control
	var calib := current_scene.get_node_or_null("CalibPanel") as Control
	if notice != null and notice.visible:
		await _note_screen("boot_notice")
	await _wait_until(func() -> bool:
		return _scene() != "boot" or (calib != null and calib.visible) or not _buttons().is_empty(), "boot notice")
	if _scene() != "boot":
		return
	if calib != null and calib.visible:
		await _note_screen("boot_calibration")
		await _frames(60)  # the two taps have to be felt before they can be answered
		var b := _button(["TwoButton"])
		if b != null:
			_tap(b, "two")
	else:
		var go := _button(["ContinueButton", "StartButton", "OkButton"])
		if go != null:
			await _note_screen("boot_card")
			_tap(go, "continue")
	await _wait_until(func() -> bool: return _scene() != "boot", "boot hand-over", 10.0)


func _arrival() -> void:
	var verify := _button(["VerifyButton"])
	if verify == null:
		# the arrival scene (stairs) plays first: nothing to press, a tap on the picture skips it
		var t0 := _sim
		var w0 := _wait_s
		await _shot("job_arrival_scene")
		await _wait_until(func() -> bool: return _scene() != "job_arrival" or _button(["VerifyButton"]) != null, "arrival scene (stairs; a tap skips it)", 30.0)
		_wait_s = w0  # watched, not forced: a tap on the picture ends it
		_watch_s += _sim - t0
		report["steps"].append({"t": snappedf(_sim, 0.01), "screen": "job_arrival_scene", "watch_s": snappedf(_sim - t0, 0.01)})
		await _frames(SETTLE_FRAMES)
	var dlg: Variant = current_scene.get("dialogue")
	var voiced := 0.0
	if dlg != null:
		for i in 4:
			var p: String = dlg.call("clip_for", i)
			if p != "":
				var s: AudioStream = load(p)
				if s != null:
					voiced += s.get_length() + 0.25
		if voiced > 0.0:
			dlg.call("skip_all")
			await _frames(6)
	await _note_screen("job_arrival", 0, "voiced lines %.1f s if listened to the end" % voiced if voiced > 0.0 else "")
	report["steps"][-1]["voiced_s"] = snappedf(voiced, 0.1)
	_tap(_button(["VerifyButton"]), "check")
	await _frames(4)


func _day_after(da: Node) -> void:
	await _frames(SETTLE_FRAMES)
	var n := 0
	while is_instance_valid(da) and not da.call("is_finished") and n < 8:
		await _note_screen("day_after_%d" % (n + 1), 0, "", da)
		var b := _button(["ContinueButton"])
		if b == null:
			break
		_tap(b, "next line")
		await _frames(30)
		n += 1
	await _frames(30)


# ------------------------------------------------------------------ locks
func _profile_rows(fam: String, seed: int, tier: int, profile: String) -> Array:
	var tool := OS.get_environment("QA_REPLAY_TOOL")
	if tool == "":
		return []
	var tmp := OS.get_user_data_dir().path_join("onb_%s_%d_%d.json" % [fam, seed, tier])
	OS.execute(tool, ["record", fam, str(tier), str(seed), tmp, "--" + profile], [], true)
	if not FileAccess.file_exists(tmp):
		return []
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(tmp))
	var rows := []
	if typeof(d) == TYPE_DICTIONARY:
		for r in d.get("inputs", []):
			for k in int(r[0]):
				rows.append([r[1] / 256.0, r[2] / 256.0, r[3] / 256.0, r[4] / 256.0, r[5] / 256.0, int(r[6])])
	return rows


func _lock() -> bool:
	var node := current_scene
	var sc := _scene()
	await _frames(2)
	var job: Dictionary = _jr().current_job
	var tutorial: bool = _jr().mode == &"tutorial"
	var tag := ("tutorial_lock_s%d" % (int(_jr().tutorial_stage) + 1)) if tutorial else "job_lock_%d" % (_jobs_done + 1)
	if _first_lock_at.is_empty():
		_first_lock_at = {"taps": _taps, "screens": _screens, "wait_s": snappedf(_wait_s, 0.01), "words": _words, "t": snappedf(_sim, 0.01)}
		_mark("first_lock_on_screen")
	if not tutorial and not _marks.has("first_job_lock_on_screen"):
		_mark("first_job_lock_on_screen")
	var fam := String(node.get("family"))
	var seed := int(node.get("seed"))
	var tier := int(node.get("tier"))
	var entry := {"lock": tag, "job": job.get("id", ""), "family": fam, "tier": tier, "t_start": snappedf(_sim, 0.01)}
	var sampler: Node = node.find_child("InputSampler", true, false)
	sampler.set_script(load(_dir.path_join("qa_sampler.gd")))
	sampler.set("raw", true)
	var profile := OS.get_environment("QA_PROFILE")
	var authored := String(job.get("lock_spec", "")) != "" or (node.get("pre_lesson") is Dictionary and not (node.get("pre_lesson") as Dictionary).is_empty())
	if authored:
		sampler.set("patient", true)
		entry["player"] = "patient"
	else:
		var rows: Array = []
		if profile in ["feel", "clumsy"]:
			rows = _profile_rows(fam, seed, tier, profile)
		if rows.is_empty():
			var sol: Dictionary = ClassDB.class_call_static("LockcoreSession", "solve", fam, seed, tier)
			rows = sol.get("inputs", [])
			entry["player"] = "solver"
		else:
			entry["player"] = profile
		sampler.set("rows", rows)
	await _frames(SETTLE_FRAMES)
	var coach: Variant = node.get("coach")
	var lines := {}
	var words := 0
	await _shot(tag + "_start")
	var t0 := _sim
	var opened_at := -1.0
	var shot_open := false
	while current_scene == node and _sim - t0 < LOCK_LIMIT_S:
		await _frames(6)
		if current_scene != node:
			break
		coach = node.get("coach")
		if coach != null:
			var key := String(coach.call("text_key"))
			if key != "" and not lines.has(key):
				lines[key] = snappedf(_sim - t0, 0.1)
				words += _count_words(PackedStringArray([_al("I18n").call("t", StringName(key))]))
		var s: Variant = node.get("session")
		if s != null and s.finished():
			if opened_at < 0.0:
				opened_at = _sim
				entry["opened"] = s.is_open()
				if not s.is_open():
					break
			if not shot_open and _sim - opened_at >= 0.35:
				shot_open = true
				await _shot(tag + "_open")
	entry["lines"] = lines
	entry["line_words"] = words
	_words += words
	if opened_at < 0.0:
		entry["opened"] = false
		report["locks"].append(entry)
		return false
	entry["open_s"] = snappedf(opened_at - t0, 0.01)
	# after the open nothing can be pressed until the game moves on
	var hold0 := _sim
	while current_scene == node and _sim - hold0 < 6.0:
		await _frames(3)
	entry["after_open_s"] = snappedf(_sim - hold0 + (hold0 - opened_at), 0.01)
	_wait_s += _sim - opened_at
	_screens += 1
	report["locks"].append(entry)
	print("ONB_LOCK %s" % JSON.stringify(entry))
	if tutorial and not _marks.has("first_lock_opened"):
		_marks["first_lock_opened"] = {"t": snappedf(opened_at, 0.01), "taps": _taps, "screens": _screens, "wait_s": snappedf(_wait_s, 0.01), "words": _words}
		print("ONB_MARK first_lock_opened %s" % JSON.stringify(_marks["first_lock_opened"]))
	if not tutorial and not _marks.has("first_job_lock_opened"):
		_marks["first_job_lock_opened"] = {"t": snappedf(opened_at, 0.01), "taps": _taps, "screens": _screens, "wait_s": snappedf(_wait_s, 0.01), "words": _words}
		print("ONB_MARK first_job_lock_opened %s" % JSON.stringify(_marks["first_job_lock_opened"]))
	if current_scene == node:
		report["problems"].append({"t": snappedf(_sim, 0.01), "screen": sc, "problem": "lock opened but the screen did not move on in 6 s"})
		return false
	_fresh_lock = true
	return true
