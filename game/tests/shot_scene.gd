extends Node
## One-scene screenshot (dev/CI): loads --scene=res://..., waits --frames=N, saves --out=FILE.
##   xvfb-run godot --path game --display-driver x11 --rendering-driver opengl3 \
##     --resolution 412x915 res://tests/shot_scene.tscn -- --scene=res://scenes/tutorial.tscn --out=/tmp/t.png
## D-58 arrival scene: --job=job.wrong_floor [--time=night] [--reduce=0|1] [--climb-at=SECONDS | --hold=1] [--speaker=teresa].
## --lang=pl|en|de|fr|es sets the game language in memory (Settings + I18n, not saved; visual audit 2026-11-07).
## --no-day-after=1 drops a queued "day after" scene (in memory) so the job list itself is visible;
## the debug FPS overlay (Quality) is hidden in these shots unless --keep-fps=1 (VA-15: then it shows what a
## debug build shows by itself, i.e. nothing unless the game was started with --fps=1). --targets=1 prints every visible
## button smaller than 48x48 dp ("SMALL <path> <size>").
## --press=<button property> presses that button of the scene before the wait (e.g. accept_button on job_verify).
## D-90: --text-scale=1.5 sets the UI text scale, --setting=sound_captions:1,swap_thumbs:1 sets Settings keys (memory only).
## Visual QA 2026-11-13 (D-129): --inset=l,t,r,b lays the screen out round a notch / gesture bar (SafeArea.override_dp, dp);
## --scroll=N|end scrolls every visible ScrollContainer before the shot; --call=method[,method] calls scene methods
## after the wait; --show=NodePath[,NodePath] makes nodes of the scene visible; --done=N|all marks the first N jobs
## (list order) as completed, in memory only; --press-child=NodePath presses the first button under a node; --wait=SECONDS waits in real time after the frames; --day-after=<job id> queues a "day after" scene; --first-run=1 shows boot as on a first launch; --pack-row=N adds the row of a chapter N that is not on the phone to the job list; --overflow=1 prints every visible Label / Button whose text is cut
## ("CUT <path> <text>") or that sticks out of the window ("OUT <path> <rect>").
## D-133: --ach=all|N|id,id marks achievements as earned (in memory), --ach-open=<id> opens the card of one on the
## Showcase shelf (ids without the "achievement." prefix); --tab=shelf opens the shelf.
## D-132: --open=1,3 opens those chapters of the job list, --fold=1 folds them (jobs_list.chapter_open, as a tap on the header does).
## --size=WxH sets the window (as tests/screens.gd); --tab=furnishings opens the workshop's Wyposażenie tab; --tutorial-stage=N sets JobRun.tutorial_stage first; --auto=1 sets Settings auto_tension (not saved).

func _ready() -> void:
	var a := {}
	for s in OS.get_cmdline_user_args():
		if s.begins_with("--") and "=" in s:
			a[s.substr(2, s.find("=") - 2)] = s.substr(s.find("=") + 1)
	if a.has("size"):
		var p: PackedStringArray = a["size"].split("x")
		get_window().size = Vector2i(int(p[0]), int(p[1]))
		await get_tree().process_frame
	if Quality._fps_label != null and a.get("keep-fps", "") != "1":
		Quality._fps_label.visible = false
	if a.has("inset"):
		var q: PackedStringArray = String(a["inset"]).split(",")
		SafeArea.override_dp = Vector4(float(q[0]), float(q[1]), float(q[2]), float(q[3]))
	if a.has("done"):
		var jobs: Array = JobRun.all_jobs()
		jobs.sort_custom(load("res://scripts/ui/jobs_list.gd").job_before)
		var ids := []
		for j: Dictionary in jobs:
			if a["done"] == "all" or ids.size() < int(a["done"]):
				ids.append(j.get("id", ""))
		Save.data["jobs_completed"] = ids
	if a.has("ach"):  # D-133: --ach=all|N|id,id marks achievements as earned (memory only), dated today and before
		var got := []
		var at := {}
		for d: Dictionary in Achievements.defs:
			var id := String(d.get("id", ""))
			if a["ach"] == "all" or (String(a["ach"]).is_valid_int() and got.size() < int(a["ach"]) and Achievements.supported(d)) or id.trim_prefix("achievement.") in String(a["ach"]).split(","):
				got.append(id)
				at[id] = "2026-11-%02d" % (3 + got.size() % 12)
		Save.data["achievements"] = got
		Save.data["achievements_at"] = at
	for flag in ["open", "fold"]:  # D-132: chapters of the job list opened / folded by hand
		for ch in String(a.get(flag, "")).split(",", false):
			load("res://scripts/ui/jobs_list.gd").chapter_open[int(ch)] = flag == "open"
	if a.get("first-run", "") == "1":  # boot: the notice card, then the two-tap calibration
		Save.data["seen_notice"] = false
		Settings._cfg["calibrated"] = false
	if a.get("no-day-after", "") == "1":
		Save.data["day_after"] = {}
	if a.has("day-after"):  # --day-after=job.cat_bathroom: queues that job's "day after" scene (jobs_list shows it)
		Save.data["day_after"] = {}
		DayAfter.note_finished(JobRun.job_by_id(a["day-after"]))
	if a.has("lang"):
		if a["lang"] in ["de", "fr", "es"]:
			Save.data["dev_mode"] = true  # T03/T41: these languages are behind the developer flag
		Settings._cfg["language"] = a["lang"]
		I18n.apply_language(a["lang"])
	if a.has("tutorial-stage"):
		JobRun.tutorial_stage = int(a["tutorial-stage"])
	if a.has("auto"):
		Settings._cfg["auto_tension"] = a["auto"] == "1"
	# D-90: --text-scale=1.5 (UI text 150 %), --setting=key:value,key:value (bool/float, in memory only)
	if a.has("setting"):
		for kv in String(a["setting"]).split(",", false):
			var p2 := kv.split(":")
			Settings._cfg[p2[0]] = (p2[1] == "1" or p2[1] == "true") if p2[1] in ["0", "1", "true", "false"] else float(p2[1])
	if a.has("text-scale"):
		Settings._cfg["text_scale_system"] = false
		Settings._cfg["text_scale"] = float(a["text-scale"])
		UiA11y._apply_text_scale()
	# D-71 furnishings: --coins=N, --furnish=all|id,id (owned + shown), --chapter=N; in memory only (not saved)
	if a.has("coins"):
		Save.data["coins"] = int(a["coins"])
	if a.has("chapter"):
		Save.data["chapter"] = int(a["chapter"])
	if a.has("furnish"):
		Save.data["furnishings"] = {}
		for f in Furnishings.all():
			if a["furnish"] == "all" or String(f["id"]) in a["furnish"].split(","):
				Save.data["furnishings"][f["id"]] = {"owned": true, "shown": true}
	if a.has("job"):
		var job := JobRun.job_by_id(a["job"]).duplicate(true)
		if a.has("time"):
			job["time"] = a["time"]
		JobRun.start(job)
	if a.has("reduce"):
		load("res://scripts/ui/job_arrival.gd").reduce_motion_override = int(a["reduce"])
	# instance as a child (change_scene would free this runner before it saves)
	var scene: Node = load(a.get("scene", "res://scenes/tutorial.tscn")).instantiate()
	add_child(scene)
	if a.has("tab") and scene.has_method("show_tab"):
		await get_tree().process_frame
		scene.show_tab(a["tab"])
	if "scene" in scene and scene.scene != null:
		await get_tree().process_frame
		if a.has("climb-at"):
			scene.scene.set_process(false)
			scene.scene._process(float(a["climb-at"]))
		elif a.has("hold"):
			scene.scene.skip()
			if a.has("speaker"):
				scene.scene.show_speaker(a["speaker"])
			scene.dialogue.skip_all()
	if a.has("debug") and "scene" in scene and scene.scene != null:
		var arr: Control = scene.scene
		print("ARR size=", arr.size, " canvas=", arr.get_node("Canvas").position, arr.get_node("Canvas").size, " plate=", arr.get_node("Canvas/Plate").texture, arr.get_node("Canvas/Plate").size)
	if a.has("press"):  # --press=accept_button: presses a button property of the scene first (D-85 shots)
		await get_tree().process_frame
		var btn: Variant = scene.get(a["press"])
		if btn is BaseButton:
			(btn as BaseButton).pressed.emit()
	for i in int(a.get("frames", "30")):
		await get_tree().process_frame
	if a.has("wait"):  # --wait=3.5: real seconds (timers of the scene), after the frames
		await get_tree().create_timer(float(a["wait"])).timeout
	if a.has("pack-row") and scene.has_method("pack_row"):  # D-112 row of a chapter that is not on the phone
		var lst: Node = scene.get_node("Frame/VBox/Scroll/JobsList")
		var ch := int(a["pack-row"])
		var row: Control = scene.pack_row("demo", ch)
		scene._pack_rows.append(row)
		lst.add_child(row)
		lst.move_child(row, 0)
		var head: Control = scene.chapter_header(ch)
		lst.add_child(head)
		lst.move_child(head, 0)
		scene._update_pack_rows()
		for i in 6:
			await get_tree().process_frame
	if a.has("press-child"):  # --press-child=Frame/VBox/Scroll/Body/Cards: presses the first button under that node
		await get_tree().process_frame
		var holder := scene.get_node_or_null(a["press-child"])
		if holder:
			for c in holder.find_children("*", "BaseButton", true, false):
				(c as BaseButton).pressed.emit()
				break
	if a.has("ach-open") and scene.has_method("show_detail"):  # D-133: the card of one achievement
		scene.show_detail("achievement." + String(a["ach-open"]))
	if a.has("call"):
		for m in String(a["call"]).split(",", false):
			scene.call(m)
	if a.has("show"):
		for np in String(a["show"]).split(",", false):
			var shown := scene.get_node_or_null(np) as CanvasItem
			if shown:
				shown.visible = true
	if a.has("scroll"):
		for i in 3:
			await get_tree().process_frame
		for n in find_children("*", "ScrollContainer", true, false):
			var sc := n as ScrollContainer
			if sc.is_visible_in_tree():
				sc.scroll_vertical = int(sc.get_v_scroll_bar().max_value) if a["scroll"] == "end" else int(a["scroll"])
	if a.has("call") or a.has("show") or a.has("scroll") or a.has("ach-open"):
		for i in 12:
			await get_tree().process_frame
	if a.get("overflow", "") == "1":
		_report_overflow()
	if a.has("debug") and scene is Control:
		for n in scene.find_children("*", "Control", true, false):
			var c := n as Control
			if c.size.x > get_viewport().get_visible_rect().size.x:
				print("WIDE ", c.get_path(), " size=", c.size, " min=", c.get_combined_minimum_size())
	if a.get("targets", "") == "1":  # visual audit: visible buttons under 48x48 dp
		for n in find_children("*", "BaseButton", true, false):
			var b := n as Control
			if b.is_visible_in_tree() and (b.size.x < 47.5 or b.size.y < 47.5):
				print("SMALL ", b.get_path(), " ", b.size)
	var img := get_viewport().get_texture().get_image()
	img.save_png(a.get("out", "/tmp/shot.png"))
	print("SHOT ", a.get("out", ""), " ", img.get_size())
	get_tree().quit()


## Visual QA (D-129): text that does not fit its control, and controls that stick out of the window.
func _report_overflow() -> void:
	var win := Rect2(Vector2.ZERO, get_viewport().get_visible_rect().size).grow(0.5)
	for n in find_children("*", "Control", true, false):
		var c := n as Control
		if not c.is_visible_in_tree() or c.size.x < 1.0:
			continue
		var clipped := false
		var p := c.get_parent()
		while p != null:  # inside a scroll list: off-window is normal
			if p is ScrollContainer:
				clipped = true
			p = p.get_parent()
		var text := ""
		if c is Label:
			var l := c as Label
			text = l.text
			var cut := l.get_visible_line_count() < l.get_line_count()
			if l.autowrap_mode == TextServer.AUTOWRAP_OFF and l.get_minimum_size().x > l.size.x + 1.0:
				cut = true
			if l.clip_text and l.autowrap_mode == TextServer.AUTOWRAP_OFF and l.get_theme_font(&"font").get_string_size(l.text, HORIZONTAL_ALIGNMENT_LEFT, -1, l.get_theme_font_size(&"font_size")).x > l.size.x + 1.0:
				cut = true
			if cut and text != "":
				print("CUT ", c.get_path(), " ", text.left(40))
		elif c is Button:
			var b := c as Button
			text = b.text
			if text != "" and b.autowrap_mode == TextServer.AUTOWRAP_OFF:
				var sb := b.get_theme_stylebox(&"normal")
				var avail := b.size.x - (sb.get_margin(SIDE_LEFT) + sb.get_margin(SIDE_RIGHT) if sb else 0.0)
				if b.get_theme_font(&"font").get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, b.get_theme_font_size(&"font_size")).x > avail + 1.0:
					print("CUT ", c.get_path(), " ", text.left(40))
		if not clipped and (c is Label or c is BaseButton) and not win.encloses(c.get_global_rect()):
			print("OUT ", c.get_path(), " ", c.get_global_rect())
