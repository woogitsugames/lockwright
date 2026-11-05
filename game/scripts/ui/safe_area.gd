class_name SafeArea
extends RefCounted
## Safe-area margins for menu screens (A11Y A-01).

static func apply(root: Control) -> void:
	var safe := DisplayServer.get_display_safe_area()
	var vp := root.get_viewport().get_visible_rect().size
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = safe.position.x
	root.offset_top = safe.position.y
	root.offset_right = vp.x - (vp.x - safe.position.x - safe.size.x)
	root.offset_bottom = vp.y - (vp.y - safe.position.y - safe.size.y)
