class_name EnamelButton
extends Button
## N-54: a menu button painted as a blank enamel plate (G17, contrib/gpt/G17,
## 9-slice margins from its manifest.json). The NinePatchRect is drawn at
## scale = button height / texture height, so the plate keeps its proportions
## (no vertical stretch) and stays sharp on 2-3x phones.
## States readable in grey-scale: pressed = pressed plate + drops 2 dp onto a
## smaller shadow; focus = brass ring (theme); disabled = faded plate, no shadow.

const PLATES := {
	&"navy": ["res://assets/ui/plates/button_navy_normal.png", "res://assets/ui/plates/button_navy_pressed.png", Vector4(175, 43, 175, 43)],
	&"bottle_green": ["res://assets/ui/plates/button_bottle_green_normal.png", "res://assets/ui/plates/button_bottle_green_pressed.png", Vector4(175, 43, 175, 43)],
	&"burgundy": ["res://assets/ui/plates/button_burgundy_normal.png", "res://assets/ui/plates/button_burgundy_pressed.png", Vector4(175, 43, 175, 43)],
	&"ivory": ["res://assets/ui/plates/button_ivory_normal.png", "res://assets/ui/plates/button_ivory_pressed.png", Vector4(175, 43, 175, 43)],
	&"primary_navy": ["res://assets/ui/plates/primary_navy_normal.png", "res://assets/ui/plates/primary_navy_pressed.png", Vector4(201, 60, 201, 60)],
}
const CREAM := Color(0.96, 0.92, 0.84)
const INK := Color(0.11, 0.09, 0.07)

@export var plate: StringName = &"navy":
	set(v):
		plate = v
		if is_node_ready():
			_apply_plate()

var _plate: NinePatchRect
var _shadow: NinePatchRect
var _tex_normal: Texture2D
var _tex_pressed: Texture2D


func _ready() -> void:
	focus_mode = Control.FOCUS_ALL
	_shadow = _make_patch()
	_shadow.modulate = Color(0, 0, 0, 0.45)
	_plate = _make_patch()
	var empty := StyleBoxEmpty.new()
	empty.content_margin_left = 28
	empty.content_margin_right = 28
	empty.content_margin_top = 6
	empty.content_margin_bottom = 8
	var down := empty.duplicate() as StyleBoxEmpty
	down.content_margin_top = 10
	down.content_margin_bottom = 4
	for st in ["normal", "hover", "disabled"]:
		add_theme_stylebox_override(st, empty)
	add_theme_stylebox_override("pressed", down)
	add_theme_stylebox_override("hover_pressed", down)
	_apply_plate()
	resized.connect(_layout)


func _apply_plate() -> void:
	var def: Array = PLATES.get(plate, PLATES[&"navy"])
	_tex_normal = load(def[0])
	_tex_pressed = load(def[1])
	var m: Vector4 = def[2]
	for p in [_plate, _shadow]:
		p.texture = _tex_normal
		p.patch_margin_left = int(m.x)
		p.patch_margin_top = int(m.y)
		p.patch_margin_right = int(m.z)
		p.patch_margin_bottom = int(m.w)
	var text_color := INK if plate == &"ivory" else CREAM
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		add_theme_color_override(c, text_color)
	add_theme_color_override("font_disabled_color", Color(text_color, 0.75))
	add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.0 if plate == &"ivory" else 0.35))
	add_theme_constant_override("outline_size", 0 if plate == &"ivory" else 3)
	_layout()


func _make_patch() -> NinePatchRect:
	var p := NinePatchRect.new()
	p.show_behind_parent = true
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(p, false, Node.INTERNAL_MODE_FRONT)
	return p


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAW:
		_layout.call_deferred()


func _layout() -> void:
	if _plate == null or _tex_normal == null or size.y <= 0.0:
		return
	var mode := get_draw_mode()
	var down := mode == DRAW_PRESSED or mode == DRAW_HOVER_PRESSED
	# scale so the texture's height = the button's height; width follows
	var k := size.y / float(_tex_normal.get_height())
	for p in [_plate, _shadow]:
		p.scale = Vector2(k, k)
		p.size = Vector2(size.x / k, float(_tex_normal.get_height()))
	_plate.texture = _tex_pressed if down else _tex_normal
	_plate.position = Vector2(0, 2 if down else 0)
	_shadow.position = Vector2(0, 3 if down else 5)
	_shadow.modulate.a = 0.25 if down else 0.45
	_shadow.visible = not disabled
	if disabled:
		_plate.modulate = Color(0.6, 0.58, 0.55, 0.55)
	elif mode == DRAW_HOVER:
		_plate.modulate = Color(1.08, 1.08, 1.08)
	else:
		_plate.modulate = Color.WHITE
