class_name SafeArea
extends RefCounted
## Safe-area margins for menu screens (A11Y A-01).

static func apply(root: Control) -> void:
	# A-10: get_display_safe_area() is in screen pixels; control offsets are in canvas
	# units (stretch=canvas_items), so convert via the window size. Offsets are margins
	# from the edges (negative right/bottom), not absolute edges.
	var safe := DisplayServer.get_display_safe_area()
	var win := DisplayServer.window_get_size()
	var vp := root.get_viewport().get_visible_rect().size
	if win.x <= 0 or win.y <= 0 or vp.x <= 0 or vp.y <= 0:
		return
	var k := vp / Vector2(win)
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = safe.position.x * k.x
	root.offset_top = safe.position.y * k.y
	root.offset_right = -(win.x - safe.end.x) * k.x
	root.offset_bottom = -(win.y - safe.end.y) * k.y
