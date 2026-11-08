class_name Eyepiece
extends Control
## Loupe eyepiece (D-13, ONBOARDING §6.2, N-57): a round field Ø 60% of the screen width with a
## brass ring, showing the live 3D section magnified around the shear line of the stack under
## the pick. Same model, same state, a closer look; no fish-eye, no glow on the rim.

const ZOOM := 2.6
const OPEN_S := 0.18

var _tex_rect: TextureRect
var _mat: ShaderMaterial
var _open := 0.0
var _target := 0.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false


func _ready() -> void:
	_tex_rect = TextureRect.new()
	_tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_tex_rect.stretch_mode = TextureRect.STRETCH_SCALE
	_mat = ShaderMaterial.new()
	_mat.shader = load("res://scripts/photoreal/eyepiece.gdshader")
	_tex_rect.material = _mat
	add_child(_tex_rect)


func is_open() -> bool:
	return _target > 0.5


func set_open(on: bool) -> void:
	_target = 1.0 if on else 0.0
	if on:
		visible = true


## centre_uv: point of the section texture to magnify; half_uv: half extent of the field in uv.
func aim(tex: Texture2D, centre_uv: Vector2, half_uv: Vector2) -> void:
	_tex_rect.texture = tex
	_mat.set_shader_parameter("centre_uv", centre_uv)
	_mat.set_shader_parameter("half_uv", half_uv)


func tick(delta: float) -> void:
	_open = _target if UiA11y.reduce_motion() else move_toward(_open, _target, delta / OPEN_S)  # D-90
	visible = _open > 0.0
	if not visible:
		return
	# iris: the field opens from the centre (ease-out), like putting the eye to the lens
	var e := 1.0 - pow(1.0 - _open, 3.0)
	_mat.set_shader_parameter("iris", e)
	_tex_rect.position = Vector2.ZERO
	_tex_rect.size = size
	queue_redraw()


func _draw() -> void:
	var c := size * 0.5
	var r := minf(size.x, size.y) * 0.5
	var e := 1.0 - pow(1.0 - _open, 3.0)
	# brass ring: dark outer edge, flat brass band, dark inner lip (flat tones only)
	draw_arc(c, r * e + 1.0, 0, TAU, 64, Color(0.12, 0.09, 0.05), 4.0, true)
	draw_arc(c, r * e - 4.0, 0, TAU, 64, Color(0.62, 0.49, 0.26), 8.0, true)
	draw_arc(c, r * e - 8.5, 0, TAU, 64, Color(0.20, 0.15, 0.08), 2.0, true)
