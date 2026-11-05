extends SceneTree
## QA career bot (session C, stage 3, task 3). Runs the game headless and plays the whole career:
## tutorial, every job in res://data/jobs, workshop purchases, showcase. In lock scenes it feeds the
## inputs of lockcore's scripted bot; elsewhere it presses buttons with a per-screen policy and a generic
## fallback. Reports soft-locks, screens without an exit, unknown screens and timings as JSON
## (stdout line "QA_REPORT {...}" + user://qa_report.json). Log analysis (crashes, missing i18n keys) is
## done by qa/report.py. Run through qa/run_career.sh (a copy of game/ with this directory as res://qa_bot).

const MAX_DECISIONS := 4000
const LOCK_SIM_LIMIT_S := 300.0
const IDLE_LIMIT_S := 15.0
const FORWARD_NAMES := ["Continue", "Accept", "Start", "Verify", "Next", "Ok", "Play", "Open", "Done", "Confirm", "Proceed"]

var report := {
	"schema": "lockwright.qa/1", "jobs_total": 0, "jobs_completed": [], "tutorial_done": false,
	"scenes": {}, "unknown_scenes": [], "softlocks": [], "dead_ends": [], "locks": [],
	"purchases": 0, "showcase_opened": 0, "profile_expected": {}, "not_listed": [], "decisions": 0, "sim_seconds": 0.0, "wall_seconds": 0.0, "finished": false,
}
var _jobs: Array = []
var _attempts := {}          # job id -> tries
var _visited := {}           # scene base name -> count
var _done_once := {}         # flags for one-time visits
var _t0 := 0
var _sim := 0.0
var _last_scene := ""
var _refused_visit := -1
var _ev_counts := {}         # lock event kind -> count for the current lock
var _channels := {}          # "kind/material" -> {"audio": bool, "haptic": bool}
var _last_change_sim := 0.0


func _initialize() -> void:
	_t0 = Time.get_ticks_msec()
	_load_jobs()
	report["jobs_total"] = _jobs.size()
	change_scene_to_file(ProjectSettings.get_setting("application/run/main_scene"))
	_run()


func _load_jobs() -> void:
	var dir := "res://data/jobs"
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".json"):
			var j: Variant = JSON.parse_string(FileAccess.get_file_as_string(dir + "/" + f))
			if typeof(j) == TYPE_DICTIONARY:
				_jobs.append(j)


func _jr() -> GDScript:
	# class_name scripts that use autoloads must not be compiled before the autoloads exist
	return load("res://scripts/lock/job_run.gd")


func _al(name: String) -> Node:
	# autoloads are not compile-time identifiers in a --script SceneTree; reach them through the tree
	return root.get_node(name)


func _wait_frames(n: int) -> void:
	for k in n:
		await physics_frame
		_sim += 1.0 / 120.0


func _scene_name() -> String:
	return current_scene.scene_file_path if current_scene else ""


func _buttons(node: Node = null, out: Array = []) -> Array:
	if node == null:
		node = root
	for c in node.get_children():
		if c is BaseButton and c.is_visible_in_tree() and not c.disabled:
			out.append(c)
		_buttons(c, out)
	return out


func _find_button(names: Array) -> BaseButton:
	for b in _buttons():
		for n in names:
			if String(b.name).findn(n) >= 0:
				return b
	return null


func _find_button_text(text: String) -> BaseButton:
	for b in _buttons():
		if b is Button and (b as Button).text == text:
			return b
	return null


func _press(b: BaseButton, why: String) -> void:
	report["decisions"] += 1
	print("QA_STEP t=%.1f scene=%s press=%s (%s)" % [_sim, _scene_name().get_file(), b.name, why])
	b.emit_signal("pressed")


func _finish(reason: String) -> void:
	report["finished"] = reason == "career_complete"
	report["end_reason"] = reason
	report["tutorial_done"] = bool(_al("Save").get_value("tutorial_done", false))
	report["coins"] = _al("Save").get_value("coins", 0)
	report["channels"] = _channels
	report["jobs_completed"] = _al("Save").get_value("jobs_completed", [])
	report["sim_seconds"] = snappedf(_sim, 0.1)
	report["wall_seconds"] = snappedf((Time.get_ticks_msec() - _t0) / 1000.0, 0.1)
	report["scenes"] = _visited
	var f := FileAccess.open("user://qa_report.json", FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(report, "  "))
	print("QA_REPORT " + JSON.stringify(report))
	quit(0)


func _pending_jobs() -> Array:
	var done: Array = _al("Save").get_value("jobs_completed", [])
	var out := []
	for j in _jobs:
		var jid: String = j.get("id", "")
		if not done.has(jid) and _attempts.get(jid, 0) < 2:
			out.append(j)
	return out


# ------------------------------------------------------------------ main loop
func _run() -> void:
	await _wait_frames(5)
	var lang := OS.get_environment("QA_LANG")
	if lang != "":
		_al("Settings").call("set_value", "language", lang)
		_al("I18n").call("apply_language", lang)
		report["lang"] = lang
	report["profile"] = OS.get_environment("QA_PROFILE") if OS.get_environment("QA_PROFILE") != "" else "solver"
	report["dark"] = OS.get_environment("QA_DARK") == "1"
	_al("Events").connect("lock_event", _on_lock_event)
	while report["decisions"] < MAX_DECISIONS:
		var sc := _scene_name()
		if sc != _last_scene:
			_last_scene = sc
			_last_change_sim = _sim
			var base := sc.get_file().get_basename()
			_visited[base] = _visited.get(base, 0) + 1
			print("QA_SCENE t=%.1f %s" % [_sim, sc])
			if _visited[base] > 60:
				report["softlocks"].append({"scene": sc, "reason": "visited more than 60 times (loop)", "t": _sim})
				return _finish("loop")
		if current_scene == null:
			await _wait_frames(2)
			continue
		if current_scene.find_child("InputSampler", true, false) != null:
			var ok: bool = await _play_lock()
			if not ok:
				return _finish("lock_softlock")
			continue
		var r: Variant = await _act_ui(sc.get_file().get_basename())
		if typeof(r) == TYPE_NIL:
			return _finish("career_complete")
		var acted: bool = bool(r)
		if not acted and _sim - _last_change_sim > IDLE_LIMIT_S:
			if _buttons().is_empty():
				report["dead_ends"].append({"scene": sc, "reason": "no enabled buttons and no automatic exit", "t": _sim})
			else:
				report["softlocks"].append({"scene": sc, "reason": "bot found no way forward", "buttons": _buttons().map(func(b): return String(b.name)), "t": _sim})
			return _finish("stuck")
		await _wait_frames(6)
	report["softlocks"].append({"scene": _scene_name(), "reason": "decision limit reached"})
	_finish("decision_limit")


# ------------------------------------------------------------------ lock scenes
## Inputs of lockcore's "feel" (average player) or "clumsy" bot for this lock, as rows of floats (1/256 units, RLE).
func _profile_rows(fam: String, seed: int, tier: int, profile: String) -> Array:
	var tool := OS.get_environment("QA_REPLAY_TOOL")
	if tool == "":
		return []
	var tmp := OS.get_user_data_dir().path_join("qa_profile_%s_%d_%d.json" % [fam, seed, tier])
	var out := []
	OS.execute(tool, ["record", fam, str(tier), str(seed), tmp, "--" + profile], out, true)
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(tmp))
	if typeof(d) != TYPE_DICTIONARY:
		return []
	var rows := []
	for r in d.get("inputs", []):
		for k in int(r[0]):
			rows.append([r[1] / 256.0, r[2] / 256.0, r[3] / 256.0, r[4] / 256.0, r[5] / 256.0, int(r[6])])
	report["profile_expected"][str(seed)] = d.get("expected", {})
	return rows


func _on_lock_event(e: Variant) -> void:
	if typeof(e) != TYPE_DICTIONARY:
		return
	var kind := String(e.get("kind", "?"))
	_ev_counts[kind] = _ev_counts.get(kind, 0) + 1
	var key := "%s/%s" % [kind, String(e.get("material", "brass"))]
	if not _channels.has(key):
		var sfx := _al("Sfx")
		var hap := _al("Haptics")
		var audio: bool = sfx.call("_stream_for", StringName(kind), StringName(e.get("material", "brass"))) != null
		var haptic: bool = not (hap.call("pattern_for", StringName(kind)) as Dictionary).is_empty()
		_channels[key] = {"audio": audio, "haptic": haptic}


func _play_lock() -> bool:
	var sc := _scene_name()
	await _wait_frames(2)
	var fam: String = ""
	var seed := 0
	var tier := 0
	for k in ["family", "_family", "fam"]:
		if current_scene.get(k) != null:
			fam = String(current_scene.get(k))
	for k in ["seed", "_seed"]:
		if current_scene.get(k) != null:
			seed = int(current_scene.get(k))
	for k in ["tier", "_tier"]:
		if current_scene.get(k) != null:
			tier = int(current_scene.get(k))
	if fam == "" and not _jr().current_job.is_empty():
		fam = String(_jr().family_for(_jr().current_job))
		seed = _jr().seed_for(_jr().current_job)
		tier = _jr().tier_for(_jr().current_job)
	print("QA_LOCK vars family=%s seed=%s tier=%s job=%s" % [current_scene.get("family"), current_scene.get("seed"), current_scene.get("tier"), _jr().current_job.get("id", "")])
	var entry := {"scene": sc.get_file(), "job": _jr().current_job.get("id", ""), "family": fam, "seed": seed, "tier": tier,
		"coins_before": int(_al("Save").get_value("coins", 0)), "reward_data": int(_jr().current_job.get("reward_coins", 0))}
	_ev_counts = {}
	if OS.get_environment("QA_DARK") == "1":
		# "in the dark": the picture is off; the bot never looks anyway, so what matters is that every state event
		# reaches sound and haptics (checked per event kind in the report)
		if current_scene.has_method("_on_dark_mode_toggled"):
			current_scene.call("_on_dark_mode_toggled", true)
		elif current_scene.get("view") != null and current_scene.get("view").has_method("set_dark"):
			current_scene.get("view").call("set_dark", true)
		entry["dark"] = true
	if not ClassDB.class_exists("LockcoreSession"):
		entry["error"] = "LockcoreSession GDExtension not loaded"
		report["locks"].append(entry)
		report["softlocks"].append({"scene": sc, "reason": "no lockcore_gd: bot cannot solve"})
		return false
	var sol: Dictionary = ClassDB.class_call_static("LockcoreSession", "solve", fam, seed, tier) if ClassDB.class_has_method("LockcoreSession", "solve") else {}
	if sol.is_empty() or not sol.get("ok", false):
		entry["error"] = "solve failed: %s" % sol.get("reason", "?")
		report["locks"].append(entry)
		report["softlocks"].append({"scene": sc, "reason": entry["error"]})
		return false
	var rows: Array = sol.get("inputs", [])
	var profile := OS.get_environment("QA_PROFILE")
	if profile in ["feel", "clumsy"]:
		# player profiles from lockcore's native bots (replay_tool record … --feel / --clumsy), same lock as the game
		var alt := _profile_rows(fam, seed, tier, profile)
		if alt.is_empty():
			entry["error"] = "replay_tool --%s failed" % profile
			report["locks"].append(entry)
			report["softlocks"].append({"scene": sc, "reason": entry["error"], "job": entry["job"]})
			return false
		rows = alt
	entry["profile"] = profile if profile != "" else "solver"
	var sampler: Node = current_scene.find_child("InputSampler", true, false)
	sampler.set_script(load("res://qa_bot/qa_sampler.gd"))
	sampler.rows = rows
	entry["bot_steps"] = sampler.rows.size()
	var t_start := _sim
	while _scene_name() == sc and _sim - t_start < LOCK_SIM_LIMIT_S:
		await _wait_frames(30)
		var s: Variant = current_scene.get("session") if current_scene else null
		if s != null and s.has_method("finished") and s.finished():
			entry["opened"] = s.is_open()
			# opened locks without a job stay on the lock screen: press any forward/back button
			await _wait_frames(60)
			if _scene_name() == sc:
				var b := _find_button(FORWARD_NAMES + ["Quit", "Back", "Menu"])
				if b == null:
					# pause menu is the documented exit (D-12)
					var p := _find_button(["Pause"])
					if p:
						_press(p, "open pause")
						await _wait_frames(10)
						b = _find_button(["Quit", "Menu", "Back"])
				if b == null:
					# plan B screen: the pause flap is drawn, not a Button; ESC opens the same cover
					var ev := InputEventKey.new()
					ev.keycode = KEY_ESCAPE
					ev.pressed = true
					Input.parse_input_event(ev)
					await _wait_frames(10)
					b = _find_button_text(_al("I18n").t(&"pause.quit"))
					if b:
						report["softlocks"].append({"scene": sc, "job": entry["job"], "t": _sim,
							"reason": "lock opened but the screen does not advance; only exit is pause → quit (no progress)"})
				if b:
					_press(b, "leave finished lock")
					await _wait_frames(10)
				else:
					report["dead_ends"].append({"scene": sc, "reason": "lock finished but no way out", "t": _sim})
					report["locks"].append(entry)
					return false
			break
	entry["sim_s"] = snappedf(_sim - t_start, 0.1)
	entry["events"] = _ev_counts.duplicate()
	if not entry.has("opened") and _scene_name() != sc:
		# job locks switch to job_payment in the same physics step that opens them
		entry["opened"] = _scene_name().get_file() in ["job_payment.tscn", "tutorial.tscn"]  # job -> payment, tutorial stage -> next stage
	var sess: Variant = current_scene.get("session") if current_scene else null
	if sess != null and sess.has_method("t_step"):
		entry["session_t_step"] = sess.t_step()
		entry["sampler_rows_used"] = sampler.i if is_instance_valid(sampler) else -1
	if _scene_name() == sc and _sim - t_start >= LOCK_SIM_LIMIT_S:
		entry["error"] = "not opened within %d s (bot)" % int(LOCK_SIM_LIMIT_S)
		report["locks"].append(entry)
		report["softlocks"].append({"scene": sc, "reason": entry["error"], "job": entry["job"]})
		return false
	report["locks"].append(entry)
	return true


# ------------------------------------------------------------------ UI policy
## Returns true when it pressed something, false when nothing to do yet, null when the career is complete.
func _act_ui(base: String) -> Variant:
	match base:
		"boot":
			return false
		"main_menu", "workshop_menu":
			if not bool(_al("Save").get_value("tutorial_done", false)) and _visited.get("tutorial", 0) < 4:
				return _press_named(["PlayButton", "Play", "Tutorial"], "tutorial")
			if not _pending_jobs().is_empty():
				return _press_named(["JobsButton", "Jobs", "Phone"], "jobs")
			for target in [["WorkshopButton", "Workshop", "Shop"], ["ShowcaseButton", "Showcase"], ["SettingsButton", "Settings"]]:
				if not _done_once.has(target[0]):
					_done_once[target[0]] = true
					if _press_named(target, "visit"):
						return true
			return null
		"tutorial":
			return _press_named(["StartButton", "Start", "Continue"], "tutorial stage")
		"jobs_list":
			var pending := _pending_jobs()
			if pending.is_empty():
				return _press_named(["BackButton", "Back"], "no jobs left")
			for want in pending:
				var title: String = _al("I18n").t(want.get("i18n", {}).get("title", &"jobs.title"))
				for b in _buttons():
					if b is Button and (b.text == title or b.text.ends_with(title)):
						_attempts[want["id"]] = _attempts.get(want["id"], 0) + 1
						_press(b, "job " + want["id"])
						return true
				# not on the list (hidden by the game, e.g. family not implemented): note once and skip it
				if not report["not_listed"].has(want["id"]):
					report["not_listed"].append(want["id"])
				_attempts[want["id"]] = 99
			return _press_named(["BackButton", "Back"], "no listed jobs left")
		"job_arrival":
			return _press_named(["VerifyButton", "Verify", "Continue", "Accept"], "arrival")
		"job_verify":
			var jid: String = _jr().current_job.get("id", "")
			if jid.findn("refuse") >= 0:
				# press once per visit: the scene waits 1.2 s before leaving (a second tap would count twice, N-15)
				if _refused_visit == _visited.get("job_verify", 0):
					return false
				_refused_visit = _visited.get("job_verify", 0)
				return _press_named(["RefuseButton", "Refuse"], "refuse job")
			return _press_named(["AcceptButton", "Accept", "Open", "Continue"], "accept job")
		"job_payment":
			var pressed := _press_named(["ContinueButton", "Continue", "Ok"], "payment")
			if pressed and not report["locks"].is_empty():
				await _wait_frames(4)
				var last: Dictionary = report["locks"][-1]
				last["coins_after"] = int(_al("Save").get_value("coins", 0))
				last["reward_data"] = int(_jr().current_job.get("reward_coins", last.get("reward_data", 0))) if not _jr().current_job.is_empty() else last.get("reward_data", 0)
			return pressed
		"workshop":
			if not _done_once.has("workshop_buy"):
				_done_once["workshop_buy"] = true
				var n := 0
				for b in _buttons():
					if String(b.name).findn("Back") < 0:
						_press(b, "workshop action")
						n += 1
				report["purchases"] = n
				return true
			return _press_named(["BackButton", "Back"], "leave workshop")
		"showcase":
			if not _done_once.has("showcase_open"):
				_done_once["showcase_open"] = true
				var opened := 0
				for b in _buttons():
					if String(b.name).findn("Back") < 0 and opened < 3:
						_press(b, "showcase entry")
						opened += 1
				report["showcase_opened"] = opened
				return true
			return _press_named(["BackButton", "Back", "Close"], "leave showcase")
		"settings":
			return _press_named(["BackButton", "Back"], "leave settings")
		_:
			if not report["unknown_scenes"].has(base):
				report["unknown_scenes"].append(base)
			if _sim - _last_change_sim < 1.0:
				return false
			var b := _find_button(FORWARD_NAMES)
			if b == null:
				for c in _buttons():
					if String(c.name).findn("Back") < 0:
						b = c
						break
			if b == null:
				b = _find_button(["Back", "Close", "Quit"])
			if b:
				_press(b, "generic")
				return true
			return false


func _press_named(names: Array, why: String) -> bool:
	var b := _find_button(names)
	if b:
		_press(b, why)
		return true
	return false
