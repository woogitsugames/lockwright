class_name PauseFlap
extends Control
## Pause = a leather tongue of the tool roll hanging from the top edge of the screen (HUD.md §6,
## N-56): a cut-out photo (G21 leather tab, alpha-keyed, rounded end with the brass snap at the
## bottom) with a soft shadow on the plate. A press lifts it 4 dp with the snap's click
## (sound + haptics) in 150 ms, then asks for the pause. Without the photo it falls back to a
## drawn polygon tongue with stitching and the snap texture.

signal pressed

const WIDTH := 56.0
const TONGUE := 60.0      # visible length below the safe-area top
const LIFT := 4.0
const ANIM_S := 0.15
const TAB_TEX := "res://assets/photo/objects/pause_tab_1k.png"

var safe_top := 0.0       # status bar / notch height in local coordinates
var _leather: Texture2D
var _snap: Texture2D
var _tab: Texture2D
var _lift := 0.0
var _busy := false


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	if ResourceLoader.exists(TAB_TEX):
		_tab = load(TAB_TEX)


func has_photo() -> bool:
	return _tab != null


func setup(leather: Texture2D, snap: Texture2D) -> void:
	_leather = leather
	_snap = snap
	queue_redraw()


## Tongue outline in local coordinates: straight sides from the top edge, semicircular end.
func outline(inset: float = 0.0, lift: float = 0.0) -> PackedVector2Array:
	var w := size.x - inset * 2.0
	var r := w * 0.5
	var bottom := size.y - 6.0 - inset - lift
	var pts := PackedVector2Array()
	pts.append(Vector2(inset, -2.0))
	pts.append(Vector2(inset, bottom - r))
	for i in 17:
		var a := PI - PI * i / 16.0
		pts.append(Vector2(size.x * 0.5 + cos(a) * r, bottom - r + sin(a) * r))
	pts.append(Vector2(size.x - inset, -2.0))
	return pts


func _draw() -> void:
	var body := outline(0.0, _lift)
	# shadow on the plate: the same shape offset 3 dp, three soft passes
	for j in 3:
		var sh := PackedVector2Array()
		for p in outline(-1.0 + j, _lift):
			sh.append(p + Vector2(1.5, 3.0 + (2 - j)))
		draw_colored_polygon(sh, Color(0, 0, 0, 0.16))
	if _tab != null:
		# photo tab: full width, rounded end at the bottom; the straight end runs off the top edge
		var ts := Vector2(_tab.get_size())
		var h := size.x * ts.y / ts.x
		var bottom := size.y - 6.0 - _lift
		draw_texture_rect(_tab, Rect2(Vector2(0.0, bottom - h), Vector2(size.x, h)), false)
		return
	if _leather != null:
		var uvs := PackedVector2Array()
		for p in body:
			uvs.append(p / Vector2(_leather.get_size()) * 2.4 + Vector2(0.31, 0.27))
		draw_colored_polygon(body, Color(0.82, 0.74, 0.66), uvs, _leather)
	else:
		draw_colored_polygon(body, Color(0.36, 0.23, 0.14))
	# cut edge: darker skived rim
	var rim := body.duplicate()
	draw_polyline(rim, Color(0.10, 0.06, 0.03, 0.9), 2.0, true)
	# stitching: short dashes along an inset copy of the outline
	var st := outline(6.0, _lift)
	var acc := 0.0
	for i in st.size() - 1:
		var a := st[i]
		var b := st[i + 1]
		var seg := a.distance_to(b)
		var t := 0.0
		while t < seg:
			var on := fmod(acc + t, 7.0) < 4.0
			var nt := minf(t + 1.0, seg)
			if on and a.y > safe_top * 0.5:
				draw_line(a.lerp(b, t / seg), a.lerp(b, nt / seg), Color(0.86, 0.80, 0.66, 0.85), 1.5, true)
			t = nt
		acc += seg
	# brass snap at the rounded end
	var sc := Vector2(size.x * 0.5, size.y - 6.0 - size.x * 0.5 - _lift)
	var m := size.x * 0.52
	if _snap != null:
		draw_texture_rect(_snap, Rect2(sc - Vector2(m, m) * 0.5, Vector2(m, m)), false)
	else:
		draw_circle(sc, m * 0.4, Color(0.62, 0.50, 0.28))


func _notification(what: int) -> void:
	if what == NOTIFICATION_ACCESSIBILITY_UPDATE:
		UiA11y.update_button_role(self)  # D-90: a named button for the screen reader


func _gui_input(ev: InputEvent) -> void:
	var down: bool = (ev is InputEventScreenTouch and ev.pressed) or (ev is InputEventMouseButton and ev.pressed)
	if not down or _busy:
		return
	accept_event()
	press()


## Lift + snap click, then the pause (also used by the back button / Esc).
func press() -> void:
	_busy = true
	Sfx.play_ui(&"brass_snap_pause")
	Haptics.play(&"contact", 0.4, &"brass")
	if UiA11y.reduce_motion() or not is_inside_tree():  # D-90: no lift, the snap sound and haptic stay
		_busy = false
		pressed.emit()
		return
	var tw := create_tween()
	tw.tween_method(_set_lift, 0.0, LIFT, ANIM_S).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func() -> void:
		_busy = false
		_set_lift(0.0)
		pressed.emit())


func _set_lift(v: float) -> void:
	_lift = v
	queue_redraw()
