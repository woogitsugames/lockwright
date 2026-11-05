class_name EnamelButton
extends Button
## N-54: a menu button painted as a real G01 enamel plate (blank, digits erased,
## data/tools/ui_plate_blank.py). The plate is a 3x NinePatchRect drawn at 1/3
## scale, so it stays crisp on 2-3x phones. States readable in grey-scale:
## pressed = plate drops 2 dp onto its shadow; focus = brass ring (theme);
## disabled = faded plate + muted text (and callers change the label).

const PLATE := preload("res://assets/ui/plate_button.png")
const K := 3.0  # source texture scale

var _plate: NinePatchRect
var _shadow: NinePatchRect


func _init() -> void:
	focus_mode = Control.FOCUS_ALL


func _ready() -> void:
	_shadow = _make_patch()
	_shadow.modulate = Color(0, 0, 0, 0.55)
	_plate = _make_patch()
	var empty := StyleBoxEmpty.new()
	empty.content_margin_left = 22
	empty.content_margin_right = 22
	empty.content_margin_top = 8
	empty.content_margin_bottom = 8
	var down := empty.duplicate() as StyleBoxEmpty
	down.content_margin_top = 12
	down.content_margin_bottom = 4
	for st in ["normal", "hover", "disabled"]:
		add_theme_stylebox_override(st, empty)
	add_theme_stylebox_override("pressed", down)
	add_theme_stylebox_override("hover_pressed", down)
	resized.connect(_layout)
	button_down.connect(_layout)
	button_up.connect(_layout)
	mouse_entered.connect(_layout)
	mouse_exited.connect(_layout)
	_layout()


func _make_patch() -> NinePatchRect:
	var p := NinePatchRect.new()
	p.texture = PLATE
	p.patch_margin_left = 48
	p.patch_margin_right = 48
	p.patch_margin_top = 40
	p.patch_margin_bottom = 40
	p.scale = Vector2.ONE / K
	p.show_behind_parent = true
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(p, false, Node.INTERNAL_MODE_FRONT)
	return p


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAW or what == NOTIFICATION_THEME_CHANGED:
		_layout.call_deferred()


func _layout() -> void:
	if _plate == null:
		return
	var down := is_pressed() and toggle_mode or get_draw_mode() == DRAW_PRESSED or get_draw_mode() == DRAW_HOVER_PRESSED
	_plate.size = size * K
	_shadow.size = size * K
	_plate.position = Vector2(0, 2 if down else 0)
	_shadow.position = Vector2(0, 2 if down else 4)
	if disabled:
		_plate.modulate = Color(0.55, 0.52, 0.48, 0.7)
		_shadow.visible = false
	else:
		_plate.modulate = Color(1.06, 1.05, 1.02) if get_draw_mode() == DRAW_HOVER else Color.WHITE
		_shadow.visible = true
