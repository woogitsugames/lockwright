class_name SafeArea
extends RefCounted
## Safe-area margins (A11Y A-01, A-10), relative to the game window.
## DisplayServer.get_display_safe_area() is in screen pixels and covers the whole screen
## (on desktop/xvfb: the usable desktop, not the window). The insets are therefore taken
## from the safe rect intersected with the window rect, clamped to the window, and then
## converted to canvas units (stretch = canvas_items). On a phone the window is the screen,
## so this is the notch / gesture bar; on a desktop window it is normally zero.


## Insets (left, top, right, bottom) in window pixels; zero when headless or unknown.
static func window_insets_px(win: Window = null) -> Vector4:
	if DisplayServer.get_name() == "headless":
		return Vector4.ZERO
	var id := win.get_window_id() if win != null else DisplayServer.MAIN_WINDOW_ID
	var wsize := DisplayServer.window_get_size(id)
	if wsize.x <= 0 or wsize.y <= 0:
		return Vector4.ZERO
	var wrect := Rect2i(DisplayServer.window_get_position(id), wsize)
	var safe := DisplayServer.get_display_safe_area()
	if safe.size.x <= 0 or safe.size.y <= 0:
		return Vector4.ZERO
	var isec := wrect.intersection(safe)
	if isec.size.x <= 0 or isec.size.y <= 0:
		return Vector4.ZERO  # window on another screen than the reported safe area
	return Vector4(
		clampi(isec.position.x - wrect.position.x, 0, wsize.x / 2),
		clampi(isec.position.y - wrect.position.y, 0, wsize.y / 2),
		clampi(wrect.end.x - isec.end.x, 0, wsize.x / 2),
		clampi(wrect.end.y - isec.end.y, 0, wsize.y / 2))


## Insets in canvas units (dp) of `node`'s viewport.
static func insets(node: Node) -> Vector4:
	var vp := node.get_viewport()
	if vp == null:
		return Vector4.ZERO
	var win := node.get_window()
	var px := window_insets_px(win)
	if px == Vector4.ZERO:
		return px
	var vis := vp.get_visible_rect().size
	var wsize := Vector2(win.size) if win != null else Vector2(DisplayServer.window_get_size())
	if vis.x <= 0.0 or vis.y <= 0.0 or wsize.x <= 0.0 or wsize.y <= 0.0:
		return Vector4.ZERO
	var k := vis / wsize
	return Vector4(px.x * k.x, px.y * k.y, px.z * k.x, px.w * k.y)


## `r` (canvas units, normally the full viewport rect) shrunk by the safe-area insets.
static func shrink(node: Node, r: Rect2) -> Rect2:
	var i := insets(node)
	var out := Rect2(r.position + Vector2(i.x, i.y), r.size - Vector2(i.x + i.z, i.y + i.w))
	return out.intersection(r) if out.size.x > 0.0 and out.size.y > 0.0 else r


## Full-rect root inset by the safe area (offsets are margins from the edges).
static func apply(root: Control) -> void:
	var i := insets(root)
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = i.x
	root.offset_top = i.y
	root.offset_right = -i.z
	root.offset_bottom = -i.w
