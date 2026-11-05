class_name LockPhotorealFamily
extends Node
## Photoreal lock screen controller for `wafer`, `lever` (with `lever_detector`),
## `warded`, and `wooden_pin` (Plan B, D-31 / D-37).
## Drop-in compatible with `res://scenes/photoreal/lock_photoreal.tscn`.
##
## Dev/CI user args (after `--`), all optional:
##   --lw-family wafer|lever|lever_detector|warded|wooden_pin --lw-seed 42 --lw-tier 3
##   --lw-pose free|bound|set|false_set|overset|detector|blender
##   --lw-size 824x1830|1830x824
##   --lw-sim N          run N scripted steps before showing, then freeze
##   --lw-shot FILE      after --lw-frames frames (default 20) save PNG and quit
##   --lw-lives N        picks left in the roll (default 3)
##   --lw-dark 1         "in the dark" (true OLED #000000 black, HUD.md §10)
##   --lw-touch 1        draw two example thumb dents
##   --lw-bench S        print LW_PERF frame statistics after S seconds and quit

@export var family: StringName = &"wafer"
@export var seed := 42
@export var tier := 2

@onready var view: LockPhotorealFamilyView = $ViewLayer/View
@onready var sampler: InputSampler = $InputSampler
@onready var pause_cover: Control = $UILayer/PauseCover

var session: RefCounted
var args := {}
var _frozen := false
var _paused := false
var _last_input := {"tension": 0.0, "pick_depth": 0.5, "pick_lift": 0.0}
var _shot_frames := -1
var _bench_left := -1.0
var _frame_ms: PackedFloat32Array = []
var _pose_vm := {}


static func blender_pose_vm(fam: StringName = &"wafer") -> Dictionary:
	return state_pose_vm(fam, "blender")


static func state_pose_vm(fam: StringName, state_name: String) -> Dictionary:
	var f := String(fam)
	if f == "lever_detector":
		f = "lever"

	if state_name == "blender":
		match f:
			"wafer":
				return {
					"family": fam,
					"elements": [
						{"state": &"set", "position": 0.55, "variant": 0},
						{"state": &"set", "position": 0.55, "variant": 0},
						{"state": &"bound", "position": 0.34, "variant": 0},
						{"state": &"overset", "position": 1.15, "variant": 0},
						{"state": &"free", "position": 0.0, "variant": 0},
					],
					"pick_element": 2, "active_element": 2,
					"tension": 0.38, "core_rotation": 0.03, "stress": 0.0, "open": false,
				}
			"lever":
				return {
					"family": fam,
					"elements": [
						{"state": &"bound", "position": 0.25, "variant": 0},
						{"state": &"set", "position": 0.52, "variant": 0},
						{"state": &"overset", "position": 1.10, "variant": 1},
					],
					"pick_element": 0, "active_element": 0,
					"tension": 0.42, "core_rotation": 0.02, "stress": 0.0, "open": false,
				}
			"warded":
				return {
					"family": fam,
					"elements": [
						{"state": &"set", "position": 0.60, "variant": 0},
						{"state": &"set", "position": 0.60, "variant": 1},
					],
					"pick_element": 1, "active_element": 1,
					"tension": 0.35, "core_rotation": 0.05, "stress": 0.0, "open": false,
				}
			"wooden_pin":
				return {
					"family": fam,
					"elements": [
						{"state": &"set", "position": 0.56, "variant": 0},
						{"state": &"bound", "position": 0.32, "variant": 0},
						{"state": &"free", "position": 0.0, "variant": 0},
					],
					"pick_element": 1, "active_element": 1,
					"tension": 0.40, "core_rotation": 0.02, "stress": 0.0, "open": false,
				}

	# Uniform or featured state pose for the 6 canonical states:
	# free, bound, set, false_set, overset, detector
	var count := 5 if f == "wafer" else (3 if f in ["lever", "wooden_pin"] else 2)
	var els: Array = []
	var tension := 0.0
	var core_rot := 0.0
	var stress := 0.0
	var active_idx := mini(1, count - 1)
	if f == "wafer":
		active_idx = 2

	for i in count:
		var st := StringName(state_name)
		var pos := 0.0
		var variant := 0
		match state_name:
			"free":
				st = &"free"
				pos = 0.0
				tension = 0.0
				core_rot = 0.0
			"bound":
				st = &"bound" if i == active_idx else (&"set" if i < active_idx else &"free")
				pos = 0.32 if i == active_idx else (0.55 if i < active_idx else 0.0)
				tension = 0.52
				core_rot = 0.02
			"set":
				st = &"set"
				pos = 0.55
				tension = 0.45
				core_rot = 0.12
			"false_set":
				st = &"false_set" if i == active_idx else (&"set" if i < active_idx else &"free")
				pos = 0.42 if i == active_idx else (0.55 if i < active_idx else 0.0)
				variant = 1
				tension = 0.60
				core_rot = 0.08
			"overset":
				st = &"overset" if i == active_idx else (&"set" if i < active_idx else &"free")
				pos = 1.22 if i == active_idx else (0.55 if i < active_idx else 0.0)
				tension = 0.65
				core_rot = 0.01
				stress = 0.55
			"detector", "jammed":
				st = &"jammed" if i == (count - 1) else (&"overset" if i == active_idx else &"free")
				pos = 1.32 if i >= active_idx else 0.0
				tension = 0.75
				core_rot = 0.0
				stress = 0.80
		els.append({
			"state": st,
			"position": pos,
			"variant": variant,
		})

	var out_fam := &"lever_detector" if (f == "lever" and state_name in ["detector", "jammed"]) else fam
	return {
		"family": out_fam,
		"elements": els,
		"pick_element": active_idx,
		"active_element": active_idx,
		"tension": tension,
		"core_rotation": core_rot,
		"stress": stress,
		"open": false,
	}


func _ready() -> void:
	_parse_args()
	if args.has("lw-size"):
		var parts := String(args["lw-size"]).split("x")
		if parts.size() == 2:
			var w := int(parts[0])
			var h := int(parts[1])
			if get_window():
				get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
				get_window().size = Vector2i(w, h)
			get_viewport().size = Vector2i(w, h)

	family = StringName(args.get("lw-family", family))
	seed = int(args.get("lw-seed", seed))
	tier = int(args.get("lw-tier", tier))
	view.family_id = family
	if String(family) == "lever_detector":
		view.detector_enabled = true

	session = make_session(family, seed, tier)
	view.pause_requested.connect(_on_pause)
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
	if args.has("lw-pose"):
		var pose_name := String(args["lw-pose"])
		if pose_name == "detector" and String(family) == "lever":
			family = &"lever_detector"
			view.family_id = family
			view.detector_enabled = true
		_pose_vm = state_pose_vm(family, pose_name)
		if args.has("lw-tension"):
			_pose_vm["tension"] = float(args["lw-tension"])
		if args.has("lw-core"):
			_pose_vm["core_rotation"] = float(args["lw-core"])
		if args.has("lw-stress"):
			_pose_vm["stress"] = float(args["lw-stress"])
		_last_input = {
			"tension": float(_pose_vm.get("tension", 0.35)),
			"pick_depth": 0.5,
			"pick_lift": 0.45,
		}
		_frozen = true

	view.present(_vm(), _last_input, 1.0)
	if args.has("lw-shot"):
		_shot_frames = int(args.get("lw-frames", "20"))
	if args.has("lw-bench"):
		_bench_left = float(args["lw-bench"])
		RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(), true)
	if not _frozen:
		var mat := _material_for_family(family)
		Sfx.begin_loop(&"tension_resistance", mat)
		Sfx.begin_loop(&"pick_drag", &"steel")
		Haptics.begin_continuous(&"tension_resistance")


static func _material_for_family(fam: StringName) -> StringName:
	match String(fam):
		"warded":
			return &"iron"
		"wooden_pin":
			return &"wood"
		_:
			return &"brass"


static func make_session(fam: StringName, sd: int, tr: int) -> RefCounted:
	if ClassDB.class_exists("LockcoreSession"):
		var s: RefCounted = ClassDB.instantiate("LockcoreSession")
		if s.create(fam, sd, tr):
			return s
	return FamilyLockSession.create(fam, sd, tr)


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


func _physics_process(delta: float) -> void:
	if _frozen or _paused:
		view.present(_vm(), _last_input, delta)
		return
	if session.finished():
		view.present(session.describe(), _last_input, delta)
		if not session.is_open():
			Events.lock_failed.emit(StringName(session.failure()))  # N-64: never a dead lock (Events ignores repeats)
		return
	var input := sampler.sample()
	_last_input = input
	var events: Array = session.step(input["tension"], input["pick_depth"], input["pick_lift"])
	for e in events:
		Haptics.play(e["kind"], e["intensity"], e["material"])
		Sfx.play(e["kind"], e["material"], 0.0, 1.0)
		view.on_event(e)
		if is_instance_valid(Events):
			Events.lock_event.emit(e)
			if e["kind"] == &"open":
				Events.lock_opened.emit()
			if e["kind"] == &"break":
				Events.lock_failed.emit(&"break")
	var vm: Dictionary = session.describe()
	var resistance: float = vm.get("tension_resistance", vm.get("resistance", 0.0))
	Haptics.update_continuous(&"tension_resistance", resistance, 0.3)
	Sfx.update_loop(&"tension_resistance", resistance)
	Sfx.update_loop(&"pick_drag", vm.get("pick_drag", 0.0))
	view.present(vm, input, delta)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		view.touch(event.index, event.position, event.pressed)
	elif event is InputEventScreenDrag:
		view.touch(event.index, event.position, true)
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if _paused:
			_on_resume()
		else:
			_on_pause()


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


func _build_pause_cover() -> void:
	pause_cover.visible = false
	pause_cover.process_mode = Node.PROCESS_MODE_ALWAYS
	var box: VBoxContainer = $UILayer/PauseCover/Box
	for spec in [[&"pause.resume", _on_resume], [&"pause.dark_mode", _on_dark], [&"pause.quit", _on_quit]]:
		var b := Button.new()
		b.text = I18n.t(spec[0]) if is_instance_valid(I18n) else String(spec[0])
		b.flat = true
		b.custom_minimum_size = Vector2(0, 48)
		b.add_theme_font_size_override("font_size", 20)
		b.add_theme_color_override("font_color", Color(0.93, 0.88, 0.78))
		b.pressed.connect(spec[1])
		box.add_child(b)


func _on_pause() -> void:
	_paused = true
	pause_cover.visible = true
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
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _process(delta: float) -> void:
	if _shot_frames > 0:
		_shot_frames -= 1
		if _shot_frames == 0:
			var img := get_viewport().get_texture().get_image()
			img.save_png(args["lw-shot"])
			print("SHOT ", args["lw-shot"], " ", img.get_size())
			_print_perf()
			get_tree().quit()
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
	print("LW_PERF scene=lock_photoreal_%s frame_p95=%.2f gpu=%.3f draws=%d prims=%d vram_mb=%.1f vp=%s" % [
		String(family),
		p95, RenderingServer.viewport_get_measured_render_time_gpu(get_viewport().get_viewport_rid()),
		Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
		Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0, view.viewport.size])
