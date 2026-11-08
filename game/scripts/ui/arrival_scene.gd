class_name ArrivalScene
extends Control
## D-58: the arrival scene behind the arrival screen's dialogue (pilot: job.wrong_floor).
## Data: res://data/arrival_scenes.json (one entry per job; jobs without one keep the plain screen).
## 1. climb: the stairwell sequence as a flipbook (12 fps, ~3 s, time of day from the job's `time`);
##    a tap skips it; reduce motion or a screen reader skips it too;
## 2. hold: the GPU hold frame as two layers stacked 1:1 (plate with the figure's shadow + the figure alone),
##    reached with a short cross-fade; the figure "breathes" (a slow vertical scale about the feet, shader),
##    off under reduce motion;
## 3. show_speaker(): a speaker with their own hold (Teresa at the ajar door, night) swaps the layers.
## A job whose client has no full-body cut-out has `hold: ""`: its hold is the landing alone (plate.webp,
## the story told by the door and the props), no figure layer and no breathing.
## Layout: the picture covers the screen; `focus` (0..1 of the image) stays in view when the crop is
## large (landscape shows the head-and-shoulders band, portrait keeps the figure on the left in view).

signal climb_finished
signal figure_changed

const DATA_PATH := "res://data/arrival_scenes.json"
const CROSSFADE_S := 0.15     # last climb frame -> hold (DESIGN: 100-250 ms)
const SWAP_S := 0.2
const BREATH_SHADER := """
shader_type canvas_item;
uniform float breath = 1.0;      // >= 1: vertical scale about the feet line
uniform float feet_y = 0.85;
varying vec4 tint;
void vertex() {
	tint = COLOR;   // modulate only; COLOR in fragment() already holds the unscaled texel
}
void fragment() {
	vec2 uv = UV;
	uv.y = feet_y + (uv.y - feet_y) / breath;
	vec4 c = texture(TEXTURE, uv);
	c.a *= step(0.0, uv.y) * step(uv.y, 1.0);
	COLOR = c * tint;
}
"""

static var _data: Dictionary = {}

var cfg: Dictionary = {}           # resolved scene (see resolve())
var phase: StringName = &"idle"     # idle -> climb -> hold
var frame := 0
var reduce_motion := false
var current_figure := ""

var _canvas: Control               # image-sized, positioned to cover the stage
var _seq: TextureRect
var _plate: TextureRect
var _figure: TextureRect
var _frames: Array[Texture2D] = []
var _t := 0.0
var _breath_t := 0.0
var _img_size := Vector2(1080, 1920)
var _press_pos := Vector2.INF


static func data() -> Dictionary:
	if _data.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
		_data = parsed if typeof(parsed) == TYPE_DICTIONARY else {"scenes": {}}
	return _data


## The scene for a job, resolved for its time of day, or {} (no entry, or its hold is missing).
## Keys: dir, time, fps, frames, hold, frame_paths, layers {figure: [plate, figure]} (plate-only hold: {"": [plate, ""]}),
## anchors, breath, focus, steps.
static func resolve(job: Dictionary) -> Dictionary:
	var s: Dictionary = data().get("scenes", {}).get(String(job.get("id", "")), {})
	if s.is_empty():
		return {}
	var times: Array = s.get("times", [])
	var t := String(job.get("time", ""))
	t = String(s.get("time_alias", {}).get(t, t))
	if not times.has(t):
		t = String(s.get("default_time", times[0] if not times.is_empty() else ""))
	var dir := "%s/%s/" % [s.get("dir", ""), t]
	var layers := {}
	var hold := String(s.get("hold", ""))
	if hold == "":
		if ResourceLoader.exists(dir + "plate.webp"):
			layers[""] = [dir + "plate.webp", ""]
	var figs: Array = [hold] if hold != "" else []
	for sp: String in s.get("speaker_holds", {}):
		figs.append(String(s["speaker_holds"][sp]))
	for f: String in figs:
		var plate := dir + "plate_%s.webp" % f
		var fig := dir + "figure_%s.webp" % f
		if ResourceLoader.exists(plate) and ResourceLoader.exists(fig):
			layers[f] = [plate, fig]
	if not layers.has(hold):
		return {}
	var frame_paths: Array[String] = []
	for i in int(s.get("frames", 0)):
		var p := dir + "seq/f_%02d.webp" % (i + 1)
		if ResourceLoader.exists(p):
			frame_paths.append(p)
	var out := s.duplicate(true)
	out["time"] = t
	out["frame_paths"] = frame_paths
	out["layers"] = layers
	out["anchors"] = s.get("anchors", {}).get(t, {})
	return out


static func has_scene(job: Dictionary) -> bool:
	return not resolve(job).is_empty()


func setup(p_cfg: Dictionary, p_reduce_motion: bool) -> void:
	cfg = p_cfg
	reduce_motion = p_reduce_motion
	name = "ArrivalScene"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	_canvas = Control.new()
	_canvas.name = "Canvas"
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_canvas)
	_plate = _layer("Plate")
	_figure = _layer("Figure")
	var mat := ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = BREATH_SHADER
	mat.shader = sh
	_figure.material = mat
	_seq = _layer("Climb")
	for p: String in cfg.get("frame_paths", []):
		_frames.append(load(p) as Texture2D)
	_set_figure(String(cfg.get("hold", "")))
	if _plate.texture != null:
		_img_size = _plate.texture.get_size()
	resized.connect(_layout)
	_layout()


func _layer(n: String) -> TextureRect:
	var r := TextureRect.new()
	r.name = n
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_SCALE
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_canvas.add_child(r)
	return r


## Cover the stage with the image, keeping `focus` (0..1) as close to the centre as the crop allows.
func _layout() -> void:
	var stage := size
	if stage.x <= 0 or stage.y <= 0:
		return
	var sc := maxf(stage.x / _img_size.x, stage.y / _img_size.y)
	var sz := _img_size * sc
	var focus: Array = cfg.get("focus_by_figure", {}).get(current_figure, cfg.get("focus", [0.5, 0.5]))
	var pos := stage * 0.5 - Vector2(float(focus[0]) * sz.x, float(focus[1]) * sz.y)
	pos.x = clampf(pos.x, stage.x - sz.x, 0.0)
	pos.y = clampf(pos.y, stage.y - sz.y, 0.0)
	_canvas.position = pos
	_canvas.size = sz


## The current figure's feet, 0..1 of the image (the landscape dialogue column goes on the other side);
## a plate-only hold has no figure: the frame's focus (the door) stands in for it.
func figure_x() -> float:
	var a: Dictionary = cfg.get("anchors", {}).get(current_figure, {})
	if a.is_empty() and current_figure == "":
		return float(cfg.get("focus", [0.5, 0.5])[0])
	return float(a.get("feet", [0.3, 0.85])[0])


## Image point (0..1) -> stage position (tests, screenshots).
func image_to_stage(p: Vector2) -> Vector2:
	return _canvas.position + p * _canvas.size


func play() -> void:
	if reduce_motion or _frames.is_empty():
		_show_hold(false)
		return
	phase = &"climb"
	frame = 0
	_t = 0.0
	_seq.texture = _frames[0]
	_seq.visible = true
	_seq.modulate.a = 1.0
	mouse_filter = Control.MOUSE_FILTER_STOP
	_step_sounds(0)


## Tap during the climb: straight to the hold frame.
func skip() -> void:
	if phase == &"climb":
		_show_hold(false)


func _process(delta: float) -> void:
	if phase == &"climb":
		_t += delta
		var f := mini(int(_t * float(cfg.get("fps", 12))), _frames.size())
		while frame < f and frame < _frames.size() - 1:
			frame += 1
			_seq.texture = _frames[frame]
			_step_sounds(frame)
		if f >= _frames.size():
			_show_hold(true)
	elif phase == &"hold" and not reduce_motion:
		_breath_t += delta
		_apply_breath()


func _apply_breath() -> void:
	var b: Dictionary = cfg.get("breath", {}).get(current_figure, {})
	var s := 1.0
	if not b.is_empty() and not reduce_motion:
		var period := maxf(0.5, float(b.get("period_s", 3.6)))
		s = 1.0 + float(b.get("amplitude", 0.0)) * (0.5 - 0.5 * cos(TAU * _breath_t / period))
	(_figure.material as ShaderMaterial).set_shader_parameter("breath", s)


func breath_scale() -> float:
	return float((_figure.material as ShaderMaterial).get_shader_parameter("breath"))


func _step_sounds(f: int) -> void:
	var steps: Dictionary = cfg.get("steps", {})
	for ev: String in steps:
		if (steps[ev] as Array).has(f + 1):
			Sfx.play_foley(StringName(ev), -6.0)


func _show_hold(fade: bool) -> void:
	if phase == &"hold":
		return
	phase = &"hold"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_breath_t = 0.0
	_apply_breath()
	if fade and not reduce_motion and is_inside_tree():
		create_tween().tween_property(_seq, "modulate:a", 0.0, CROSSFADE_S).finished.connect(func() -> void: _seq.visible = false)
	else:
		_seq.visible = false
	climb_finished.emit()


func _set_figure(f: String) -> void:
	var l: Array = cfg.get("layers", {}).get(f, [])
	if l.is_empty():
		return
	current_figure = f
	_plate.texture = load(l[0]) as Texture2D
	_figure.texture = load(l[1]) as Texture2D if String(l[1]) != "" else null
	_figure.visible = _figure.texture != null
	if _canvas.size != Vector2.ZERO:
		_layout()
	figure_changed.emit()
	var a: Dictionary = cfg.get("anchors", {}).get(f, {})
	var feet: Array = a.get("feet", [0.5, 0.85])
	(_figure.material as ShaderMaterial).set_shader_parameter("feet_y", float(feet[1]))


## A dialogue line by `speaker` started: a speaker with their own hold takes the frame
## (Teresa opens the door), the client's hold comes back with the client's next line.
func show_speaker(speaker: String) -> void:
	var f := String(cfg.get("speaker_holds", {}).get(speaker, ""))
	if f == "" and speaker == String(cfg.get("hold", "")):
		f = speaker
	if f == "" or f == current_figure or not cfg.get("layers", {}).has(f):
		return
	if reduce_motion or not is_inside_tree() or phase != &"hold":
		_set_figure(f)
		return
	# a short dip (200 ms): the new layers come up from a darker frame, no hard cut
	_set_figure(f)
	_breath_t = 0.0
	create_tween().tween_property(_canvas, "modulate", Color.WHITE, SWAP_S).from(Color(0.4, 0.4, 0.4))


func _gui_input(event: InputEvent) -> void:
	if phase != &"climb":
		return
	var mb := event as InputEventMouseButton
	if mb != null and mb.button_index == MOUSE_BUTTON_LEFT:
		if mb.pressed:
			_press_pos = mb.position
		elif _press_pos != Vector2.INF:
			_press_pos = Vector2.INF
			accept_event()
			skip()
	var st := event as InputEventScreenTouch
	if st != null and not st.pressed:
		accept_event()
		skip()
