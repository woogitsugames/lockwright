extends Node
## Spike 4: photoreal lit metal on the Mobile renderer (docs/TECH.md §4).
##
## Variant A ("realtime"): baked material textures (albedo, ORM, normal) on ORMMaterial3D, omni lights
## placed like the Blender area lights, emissive cards that only the ReflectionProbe sees (the area
## lights' reflections on flat metal), the same HDRI as Cycles for the sky, AgX tonemapping, no glow.
## Variant B ("baked", plan B): static meshes draw the Cycles render of the static scene through the
## camera (unshaded); moving parts use a Cycles-rendered matcap. No lights, no probe.
##
## User args (after `--`):
##   --variant a|b        start variant (default a); tap the top-right corner to switch
##   --animate 0|1        pins 1 Hz up/down + pick (default 1); tap the bottom edge to toggle
##   --shot FILE          render offscreen at --size and save a PNG, then quit
##   --size WxH           shot size (default 1236x1650)
##   --frames N           frames to wait before the shot (default 30)
##   --time T             animation time used for the shot (default 0 = rest pose of the Blender scene)
##   --bench SECONDS      run, then print frame-time statistics and quit
##   --msaa 0|2|4         3D MSAA (default 2)
##   --overlay 0|1        frame counter overlay (default 1, off in shots)

const SCENE_JSON := "res://assets/scene.json"
const GLB := "res://assets/cutaway_baked.glb"
const MOVING_PINS := ["a", "b", "c", "d", "e"]
const LIGHT_K := 60.0          # Blender area watts -> Godot omni energy (1 unit = 1 mm)
const CARD_K := 0.0016         # Blender area watts / m^2 -> emission energy of the reflection cards
const REFLECTION_LAYER := 2    # visual layer seen only by the ReflectionProbe
const AO_LIGHT_AFFECT := 0.7
const KEY_SHADOW := true

var args := {}
var rig: Dictionary
var root3d: Node3D
var model: Node3D
var camera: Camera3D
var env_a: Environment
var env_b: Environment
var world_env: WorldEnvironment
var lights: Array[Node3D] = []
var probe: ReflectionProbe
var variant := "a"
var animate := true
var anim_t := 0.0
var mats_a := {}               # mesh -> Array[Material] per surface
var mats_b := {}
var rest := {}                 # node -> Transform3D
var spring_info := {}          # spring node -> [bottom_y, top_y]
var overlay: Label
var frame_ms: PackedFloat32Array = []
var gpu_ms: PackedFloat32Array = []
var shot_viewport: SubViewport
var frames_left := -1
var bench_left := -1.0
var perf_log_t := 0.0


func _ready() -> void:
	_parse_args()
	rig = JSON.parse_string(FileAccess.get_file_as_string(SCENE_JSON))
	variant = args.get("variant", "a")
	animate = args.get("animate", "1") == "1"
	anim_t = float(args.get("time", "0"))
	var msaa := int(args.get("msaa", "2"))

	root3d = Node3D.new()
	root3d.name = "World"
	if args.has("shot"):
		var sz: PackedStringArray = String(args.get("size", "1236x1650")).split("x")
		shot_viewport = SubViewport.new()
		shot_viewport.size = Vector2i(int(sz[0]), int(sz[1]))
		shot_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		shot_viewport.msaa_3d = _msaa_enum(4 if msaa == 2 else msaa)
		shot_viewport.use_debanding = true
		add_child(shot_viewport)
		shot_viewport.add_child(root3d)
		frames_left = int(args.get("frames", "30"))
		animate = args.get("animate", "0") == "1"
	else:
		add_child(root3d)
		get_viewport().msaa_3d = _msaa_enum(msaa)
		get_viewport().use_debanding = true
		RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(), true)
		if args.has("bench"):
			bench_left = float(args["bench"])

	_build_model()
	_build_camera()
	_build_environments()
	_build_lights_and_probe()
	_build_materials()
	_apply_variant()
	_update_animation(anim_t)

	if not args.has("shot") and args.get("overlay", "1") == "1":
		overlay = Label.new()
		overlay.position = Vector2(16, 40)
		overlay.add_theme_font_size_override("font_size", 22)
		overlay.add_theme_color_override("font_color", Color(1, 1, 1))
		overlay.add_theme_color_override("font_outline_color", Color(0, 0, 0))
		overlay.add_theme_constant_override("outline_size", 6)
		var layer := CanvasLayer.new()
		layer.add_child(overlay)
		add_child(layer)


func _parse_args() -> void:
	var a := OS.get_cmdline_user_args()
	var i := 0
	while i < a.size():
		if a[i].begins_with("--") and i + 1 < a.size():
			args[a[i].substr(2)] = a[i + 1]
			i += 2
		else:
			i += 1


func _msaa_enum(n: int) -> Viewport.MSAA:
	match n:
		2: return Viewport.MSAA_2X
		4: return Viewport.MSAA_4X
		8: return Viewport.MSAA_8X
	return Viewport.MSAA_DISABLED


func _v(a: Array) -> Vector3:
	return Vector3(a[0], a[1], a[2])


# ------------------------------------------------------------------ scene
func _build_model() -> void:
	model = (load(GLB) as PackedScene).instantiate()
	for c in model.find_children("*", "Camera3D", true, false):
		c.get_parent().remove_child(c)   # the glTF camera would compete with ours
		c.free()
	root3d.add_child(model)
	for n in _all(model):
		if n is Node3D:
			rest[n] = n.transform
	for p in MOVING_PINS:
		var spr := model.find_child(p + "_spr", true, false) as MeshInstance3D
		if spr:
			var bb := spr.get_aabb()
			spring_info[spr] = [bb.position.y, bb.end.y]


func _all(n: Node) -> Array[Node]:
	var out: Array[Node] = [n]
	for c in n.get_children():
		out.append_array(_all(c))
	return out


func _meshes() -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	for n in _all(model):
		if n is MeshInstance3D:
			out.append(n)
	return out


func _build_camera() -> void:
	var c: Dictionary = rig["camera"]
	camera = Camera3D.new()
	# Blender sensor_fit HORIZONTAL: the horizontal FOV is fixed. Godot's KEEP_WIDTH did not hold it in a
	# SubViewport here, so derive the vertical FOV for the target aspect and keep the height instead.
	camera.keep_aspect = Camera3D.KEEP_HEIGHT
	var vs := Vector2(shot_viewport.size) if shot_viewport else get_viewport().get_visible_rect().size
	camera.fov = rad_to_deg(2.0 * atan(tan(deg_to_rad(c["hfov_deg"]) * 0.5) * vs.y / vs.x))
	get_viewport().size_changed.connect(_on_resize)
	camera.near = 20.0
	camera.far = 1000.0
	camera.cull_mask = 0xFFFFF & ~(1 << (REFLECTION_LAYER - 1))
	root3d.add_child(camera)
	camera.look_at_from_position(_v(c["position"]), _v(c["target"]), Vector3.UP)
	camera.current = true


func _on_resize() -> void:
	if shot_viewport:
		return
	var vs := get_viewport().get_visible_rect().size
	camera.fov = rad_to_deg(2.0 * atan(tan(deg_to_rad(rig["camera"]["hfov_deg"]) * 0.5) * vs.y / vs.x))


func _build_environments() -> void:
	# Variant A: the same studio HDRI as Cycles at the same strength, AgX like Blender's view transform.
	var sky_mat := PanoramaSkyMaterial.new()
	sky_mat.panorama = load("res://assets/interior.hdr")
	sky_mat.energy_multiplier = rig["world_strength"]
	var sky := Sky.new()
	sky.sky_material = sky_mat
	sky.radiance_size = Sky.RADIANCE_SIZE_256
	env_a = Environment.new()
	env_a.background_mode = Environment.BG_SKY
	env_a.sky = sky
	env_a.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env_a.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env_a.tonemap_mode = Environment.TONE_MAPPER_AGX
	env_a.tonemap_exposure = pow(2.0, rig["exposure"])
	env_a.glow_enabled = false
	env_a.ssr_enabled = false
	# Variant B: the plate is already display-referred (AgX in Cycles), so pass it through untouched.
	env_b = Environment.new()
	env_b.background_mode = Environment.BG_COLOR
	env_b.background_color = Color(0.05, 0.045, 0.04)
	env_b.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env_b.tonemap_exposure = 1.0
	env_b.glow_enabled = false
	world_env = WorldEnvironment.new()
	root3d.add_child(world_env)


func _build_lights_and_probe() -> void:
	var aim := _v(rig["aim"])
	for L in rig["lights"]:
		var pos := _v(L["position"])
		var col := Color(L["color"][0], L["color"][1], L["color"][2])
		var o := OmniLight3D.new()
		o.name = "omni_" + L["name"]
		o.position = pos
		o.light_color = col
		o.light_energy = L["energy_w"] * LIGHT_K  # omni decay 2: E / d^2 at the aim point
		o.omni_range = 2000.0
		o.omni_attenuation = 2.0
		o.light_size = L["size"] * 0.5
		# Area lights reach metal mostly as reflections (cards below); keep a small analytic highlight.
		o.light_specular = 0.25
		o.shadow_enabled = KEY_SHADOW and L["name"] == "key"
		o.shadow_blur = 3.0
		o.shadow_bias = 0.03
		o.shadow_normal_bias = 1.0
		root3d.add_child(o)
		lights.append(o)
		# Emissive card with the light's size and radiance, visible only to the reflection probe.
		var card := MeshInstance3D.new()
		var q := QuadMesh.new()
		q.size = Vector2(L["size"], L["size"])
		card.mesh = q
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.albedo_color = Color(0, 0, 0)
		m.emission_enabled = true
		m.emission = col
		m.emission_energy_multiplier = L["energy_w"] / pow(L["size"] / 1000.0, 2) * CARD_K
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		card.material_override = m
		card.layers = 1 << (REFLECTION_LAYER - 1)
		card.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root3d.add_child(card)
		card.look_at_from_position(pos, aim, Vector3.UP)
		lights.append(card)
	probe = ReflectionProbe.new()
	probe.position = aim
	probe.size = Vector3(160, 160, 160)
	probe.max_distance = 1200.0
	probe.cull_mask = 0xFFFFF
	probe.update_mode = ReflectionProbe.UPDATE_ONCE
	probe.intensity = 1.0
	probe.ambient_mode = ReflectionProbe.AMBIENT_ENVIRONMENT
	root3d.add_child(probe)
	lights.append(probe)


func _build_materials() -> void:
	var mats: Dictionary = rig["materials"]
	var cache_a := {}
	var cache_b := {}
	var plate_path := "res://assets/plate/plate_1236x1650.png"
	if shot_viewport and shot_viewport.size.y > 2000 and ResourceLoader.exists("res://assets/plate/plate_2160x2880.png"):
		plate_path = "res://assets/plate/plate_2160x2880.png"
	var plate_tex: Texture2D = load(plate_path) if ResourceLoader.exists(plate_path) else null
	var moving := {}
	for p in MOVING_PINS:
		for k in ["key", "drv", "spr"]:
			moving[p + "_" + k] = true
	moving["pick"] = true
	moving["pick_handle"] = true
	for mi in _meshes():
		var la: Array[Material] = []
		var lb: Array[Material] = []
		for s in mi.mesh.get_surface_count():
			var src := mi.mesh.surface_get_material(s)
			var mname := src.resource_name if src else ""
			if not mats.has(mname):
				la.append(src)
				lb.append(src)
				continue
			if not cache_a.has(mname):
				cache_a[mname] = _pbr(mname, mats[mname])
			la.append(cache_a[mname])
			var key := mname + ("|m" if moving.has(String(mi.name)) else "|s")
			if not cache_b.has(key):
				cache_b[key] = _baked(mname, moving.has(String(mi.name)), plate_tex)
			lb.append(cache_b[key])
		mats_a[mi] = la
		mats_b[mi] = lb


func _tex(path: String) -> Texture2D:
	return load(path) if ResourceLoader.exists(path) else null


func _pbr(mname: String, info: Dictionary) -> Material:
	var m := ORMMaterial3D.new()
	m.resource_name = mname + "_pbr"
	m.albedo_texture = _tex("res://assets/tex/%s_albedo.png" % mname)
	m.orm_texture = _tex("res://assets/tex/%s_orm.png" % mname)
	m.metallic = 1.0
	m.roughness = 1.0
	m.normal_enabled = true
	m.normal_texture = _tex("res://assets/tex/%s_normal.png" % mname)
	m.normal_scale = 1.0
	m.ao_enabled = true
	m.ao_light_affect = AO_LIGHT_AFFECT  # no shadowed GI in real time: let baked AO darken direct light
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	if float(info.get("coat", 0.0)) > 0.0:
		m.clearcoat_enabled = true
		m.clearcoat = float(info["coat"])
		m.clearcoat_roughness = 0.35
	return m


func _baked(mname: String, is_moving: bool, plate_tex: Texture2D) -> Material:
	var m := ShaderMaterial.new()
	if is_moving:
		m.shader = load("res://shaders/matcap.gdshader")
		var mc := _tex("res://assets/plate/matcap_%s.png" % mname)
		if mc == null:
			mc = _tex("res://assets/plate/matcap_steel.png")
		m.set_shader_parameter("matcap", mc)
		m.set_shader_parameter("normal_map", _tex("res://assets/tex/%s_normal.png" % mname))
		m.set_shader_parameter("orm", _tex("res://assets/tex/%s_orm.png" % mname))
	else:
		m.shader = load("res://shaders/plate.gdshader")
		m.set_shader_parameter("plate", plate_tex)
	return m


func _apply_variant() -> void:
	var b := variant == "b"
	world_env.environment = env_b if b else env_a
	for n in lights:
		n.visible = not b
	for mi in mats_a:
		var l: Array = mats_b[mi] if b else mats_a[mi]
		for s in l.size():
			mi.set_surface_override_material(s, l[s])
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if b else GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	if not b:
		probe.update_mode = ReflectionProbe.UPDATE_ONCE  # re-capture after material swap


# ------------------------------------------------------------------ animation: pins 1 Hz, pick follows pin c
func _update_animation(t: float) -> void:
	var i := 0
	for p in MOVING_PINS:
		var dy := 0.45 * sin(TAU * (t + 0.13 * i))
		if t == 0.0:
			dy = 0.0
		for k in ["key", "drv"]:
			var n := model.find_child(p + "_" + k, true, false) as Node3D
			if n:
				n.transform = rest[n].translated(Vector3(0, dy, 0))
		var spr := model.find_child(p + "_spr", true, false) as Node3D
		if spr and spring_info.has(spr):
			var lo: float = spring_info[spr][0]
			var hi: float = spring_info[spr][1]
			var s := (hi - (lo + dy)) / (hi - lo)
			var tr := Transform3D(Basis.from_scale(Vector3(1, s, 1)), Vector3(0, hi * (1.0 - s), 0))
			spr.transform = tr * rest[spr]
		i += 1
	var lift := 0.45 * sin(TAU * (t + 0.26))
	if t == 0.0:
		lift = 0.0
	for k in ["pick", "pick_handle"]:
		var n := model.find_child(k, true, false) as Node3D
		if n:
			n.transform = rest[n].translated(Vector3(0.6 * sin(TAU * 0.25 * t), lift, 0))


func _unhandled_input(e: InputEvent) -> void:
	var pos := Vector2(-1, -1)
	if e is InputEventScreenTouch and e.pressed:
		pos = e.position
	elif e is InputEventMouseButton and e.pressed:
		pos = e.position
	elif e is InputEventKey and e.pressed:
		if e.keycode == KEY_V:
			pos = Vector2(1e6, 0)
		elif e.keycode == KEY_SPACE:
			animate = not animate
	if pos.x < 0:
		return
	var vs := get_viewport().get_visible_rect().size
	if pos.y < vs.y * 0.2 and pos.x > vs.x * 0.6 or pos.x >= 1e6:
		variant = "b" if variant == "a" else "a"
		_apply_variant()
		frame_ms.clear()
		gpu_ms.clear()
	elif pos.y > vs.y * 0.8:
		animate = not animate


func _process(delta: float) -> void:
	if animate:
		anim_t += delta
		_update_animation(anim_t)
	if frames_left >= 0:
		frames_left -= 1
		if frames_left == 0:
			var img := shot_viewport.get_texture().get_image()
			img.save_png(args["shot"])
			print("SHOT ", args["shot"], " ", img.get_size())
			get_tree().quit()
		return
	frame_ms.append(delta * 1000.0)
	var vp := get_viewport().get_viewport_rid()
	var g := RenderingServer.viewport_get_measured_render_time_gpu(vp)
	if g > 0.0:
		gpu_ms.append(g)
	if frame_ms.size() > 600:
		frame_ms = frame_ms.slice(frame_ms.size() - 600)
	if gpu_ms.size() > 600:
		gpu_ms = gpu_ms.slice(gpu_ms.size() - 600)
	perf_log_t += delta
	if overlay:
		overlay.text = "%s  %d FPS\nframe p50 %.1f / p95 %.1f ms\nGPU p50 %.2f / p95 %.2f ms\ndraws %d  prims %d" % [
			"A realtime" if variant == "a" else "B baked", Engine.get_frames_per_second(),
			_pct(frame_ms, 0.5), _pct(frame_ms, 0.95), _pct(gpu_ms, 0.5), _pct(gpu_ms, 0.95),
			Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
			Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)]
	if perf_log_t >= 10.0:
		perf_log_t = 0.0
		_print_perf()
	if bench_left > 0.0:
		bench_left -= delta
		if bench_left <= 0.0:
			_print_perf()
			get_tree().quit()


func _print_perf() -> void:
	# adb logcat -s godot | grep LW_PERF
	print("LW_PERF variant=%s fps=%d frame_p50=%.2f frame_p95=%.2f frame_p99=%.2f gpu_p50=%.3f gpu_p95=%.3f draws=%d prims=%d vram_mb=%.1f" % [
		variant, Engine.get_frames_per_second(), _pct(frame_ms, 0.5), _pct(frame_ms, 0.95), _pct(frame_ms, 0.99),
		_pct(gpu_ms, 0.5), _pct(gpu_ms, 0.95),
		Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
		Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0])


func _pct(a: PackedFloat32Array, p: float) -> float:
	if a.is_empty():
		return 0.0
	var s := a.duplicate()
	s.sort()
	return s[int(p * (s.size() - 1))]
