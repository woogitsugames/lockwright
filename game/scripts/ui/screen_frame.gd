class_name ScreenFrame
extends RefCounted
## N-53/N-59: shared frame for every menu screen.
## - the screen root stays full-rect, so its backdrop also fills the status-bar band;
## - the content lives in a MarginContainer with 16 dp sides + the display safe-area
##   (cut-outs, gesture bar), in portrait and landscape;
## - on wide (landscape) viewports the content column is capped at MAX_COLUMN dp.

const SIDE := 16.0
const MAX_COLUMN := 640.0


## Safe-area insets (left, top, right, bottom) in canvas units of `root`'s viewport.
static func insets(root: Control) -> Vector4:
	var vp := root.get_viewport_rect().size
	if DisplayServer.get_name() == "headless":
		return Vector4.ZERO
	var win := DisplayServer.window_get_size()
	var safe := DisplayServer.get_display_safe_area()
	if win.x <= 0 or win.y <= 0 or vp.x <= 0 or vp.y <= 0 or safe.size.x <= 0:
		return Vector4.ZERO
	var k := vp / Vector2(win)
	return Vector4(
		maxf(0.0, safe.position.x * k.x),
		maxf(0.0, safe.position.y * k.y),
		maxf(0.0, (win.x - safe.end.x) * k.x),
		maxf(0.0, (win.y - safe.end.y) * k.y))


## Applies margins now and on every resize/rotation. `max_column` <= 0 disables the cap.
static func fit(root: Control, frame: MarginContainer, max_column := MAX_COLUMN) -> void:
	var apply := func() -> void:
		var i := insets(root)
		var w := root.get_viewport_rect().size.x
		var left := i.x + SIDE
		var right := i.z + SIDE
		if max_column > 0.0:
			var spare := w - left - right - max_column
			if spare > 0.0:
				left += spare * 0.5
				right += spare * 0.5
		frame.add_theme_constant_override("margin_left", int(left))
		frame.add_theme_constant_override("margin_right", int(right))
		frame.add_theme_constant_override("margin_top", int(i.y + 8.0))
		frame.add_theme_constant_override("margin_bottom", int(i.w + 12.0))
	apply.call()
	if not root.resized.is_connected(apply):
		root.resized.connect(apply)


## Full-bleed photo behind the screen (under the status bar too) plus a flat dark shade.
static func backdrop(root: Control, path: String, shade := 0.5) -> TextureRect:
	var bg := TextureRect.new()
	bg.name = "Backdrop"
	if path != "" and ResourceLoader.exists(path):
		bg.texture = load(path)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)
	root.move_child(bg, 0)
	var dim := ColorRect.new()
	dim.name = "Shade"
	dim.color = Color(0.06, 0.045, 0.035, shade)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	root.move_child(dim, 1)
	return bg


## A label that never widens its row: wraps by words, min width 0.
static func wrap(label: Label) -> Label:
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.custom_minimum_size.x = 0
	return label


## A one-line label that trims with an ellipsis instead of widening its row.
static func ellipsis(label: Label) -> Label:
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.clip_text = true
	label.custom_minimum_size.x = 0
	return label


## Short fade-in (200 ms, DESIGN.md 100–250 ms); skipped with "reduce motion".
static func enter(node: Control, delay := 0.0) -> void:
	if Settings.get_value("reduce_motion", false):
		return
	node.modulate.a = 0.0
	var tw := node.create_tween()
	tw.tween_interval(delay)
	tw.tween_property(node, "modulate:a", 1.0, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
