class_name ScreenFrame
extends RefCounted
## N-53/N-59: shared frame for every menu screen.
## - the screen root stays full-rect, so its backdrop also fills the status-bar band;
## - the content lives in a MarginContainer with 16 dp sides + the window's safe-area
##   (cut-outs, gesture bar), in portrait and landscape;
## - on wide (landscape) viewports the content column is capped at MAX_COLUMN dp.

const SIDE := 16.0
const MAX_COLUMN := 640.0


## Safe-area insets (left, top, right, bottom) in canvas units of `root`'s viewport
## (window-relative, see SafeArea).
static func insets(root: Control) -> Vector4:
	return SafeArea.insets(root)


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
	_fit_header(frame)


## D-90: the header row (‹ Back + title) never cuts words at large text: the back plate grows to its
## text, the title shrinks to fit and may take two lines (fit_title) instead of an ellipsis.
static func _fit_header(frame: Control) -> void:
	var header := frame.get_node_or_null("VBox/Header")
	if header == null:
		return
	var back := header.get_node_or_null("BackButton") as Button
	if back:
		back.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
		back.clip_text = false
	var title := header.get_node_or_null("Title") as Label
	if title and not title.has_meta(&"fit_title"):
		title.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
		title.clip_text = false
		fit_title(title)


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
	if UiA11y.reduce_motion():
		return
	node.modulate.a = 0.0
	var tw := node.create_tween()
	tw.tween_interval(delay)
	tw.tween_property(node, "modulate:a", 1.0, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


## S05 enamel-plate sounds for every button of a screen (also rows added later):
## press on button_down, release on button_up, a dull knock when a disabled plate
## is tapped, and a soft whoosh when the screen comes in. Random variant each time.
static func wire_sounds(root: Control, whoosh := true) -> void:
	_wire_tree(root)
	var on_added := func(n: Node) -> void:
		if n is BaseButton and root.is_ancestor_of(n):
			_wire_button(n)
	root.get_tree().node_added.connect(on_added)
	root.tree_exiting.connect(func() -> void:
		if root.get_tree().node_added.is_connected(on_added):
			root.get_tree().node_added.disconnect(on_added), CONNECT_ONE_SHOT)
	if whoosh:
		Sfx.play_ui(&"screen_whoosh_soft")


static func _wire_tree(n: Node) -> void:
	if n is BaseButton:
		_wire_button(n)
	for c in n.get_children():
		_wire_tree(c)


static func _wire_button(b: BaseButton) -> void:
	if b.has_meta(&"ui_sounds"):
		return
	b.set_meta(&"ui_sounds", true)
	b.button_down.connect(func() -> void: Sfx.play_ui(&"plate_press"))
	b.button_up.connect(func() -> void: Sfx.play_ui(&"plate_release"))
	b.gui_input.connect(func(e: InputEvent) -> void:
		if b.disabled and e is InputEventMouseButton and e.pressed:
			Sfx.play_ui(&"plate_disabled"))


## Visual audit 2026-11-07 (VA-03): a header title that never breaks inside a word. Picks the
## largest size in [min_fs, max_fs] that puts the text on one line, down to `one_line_min`; below
## that it allows two lines (word breaks only) before shrinking further. Re-fits on resize and
## when the text changes (call again after setting a new text).
static func fit_title(label: Label, max_fs := 28, min_fs := 17, one_line_min := 22) -> void:
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = 0
	var apply := func() -> void:
		# D-90: the sizes follow the player's text scale (UiA11y), the fitting rule stays
		var fs := title_size(label.get_theme_font(&"font"), label.text, label.size.x,
			UiA11y.fs(max_fs), UiA11y.fs(min_fs), UiA11y.fs(one_line_min))
		if fs > 0 and fs != label.get_theme_font_size(&"font_size"):
			label.add_theme_font_size_override(&"font_size", fs)
		if fs > 0:
			# D-90: an autowrapped label in an HBox (header) does not grow its row by itself
			var f := label.get_theme_font(&"font")
			label.custom_minimum_size.y = ceilf(f.get_multiline_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, label.size.x, fs).y)
	if not label.has_meta(&"fit_title"):
		label.set_meta(&"fit_title", true)
		label.resized.connect(apply)
	apply.call_deferred()


## Font size for fit_title (static, for tests). 0 = width unknown yet.
static func title_size(font: Font, text: String, width: float, max_fs: int, min_fs: int, one_line_min: int) -> int:
	if font == null or width <= 1.0 or text == "":
		return 0
	var words := text.split(" ", false)
	for fs in range(max_fs, one_line_min - 1, -1):
		if font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x <= width:
			return fs
	for fs in range(max_fs, min_fs - 1, -1):
		var longest := 0.0
		for w in words:
			longest = maxf(longest, font.get_string_size(w, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x)
		if longest > width:
			continue
		var h := font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, width, fs).y
		if h <= font.get_height(fs) * 2.2:
			return fs
	return min_fs


## VA-01: a one-line plate label (tab) that shrinks down to `min_fs` before the ellipsis trims it.
static func fit_button_text(b: Button, max_fs := 16, min_fs := 13) -> void:
	var apply := func() -> void:
		var sb := b.get_theme_stylebox(&"normal")
		var avail := b.size.x - (sb.get_margin(SIDE_LEFT) + sb.get_margin(SIDE_RIGHT) if sb else 0.0) - 2.0
		if avail <= 1.0:
			return
		var font := b.get_theme_font(&"font")
		var fs := UiA11y.fs(max_fs)  # D-90: text scale
		while fs > UiA11y.fs(min_fs) and font.get_string_size(b.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > avail:
			fs -= 1
		if fs != b.get_theme_font_size(&"font_size"):
			b.add_theme_font_size_override(&"font_size", fs)
	if not b.has_meta(&"fit_text"):
		b.set_meta(&"fit_text", true)
		b.resized.connect(apply)
	apply.call_deferred()
