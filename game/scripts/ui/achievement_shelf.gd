class_name AchievementShelf
extends VBoxContainer
## D-133 (VQA-17): the achievements as a shelf in the Showcase. One dark-paper bay per category
## (craft, modes, principles, stories); in it wooden boards with one spot per achievement:
##   earned   = a small enamel plate with the initial of its name (G17 plates, as the speaker
##              plates on the arrival screen), standing on the board, the name beside it;
##   unearned = an empty place, a dashed outline with the two screw holes, the name in muted text;
##   hidden   = the same empty place with a "?", no name and no description (no spoilers).
## Earned and empty differ in shape and value, not in hue (grey-scale readable). A tap on a spot
## asks for its card (`picked`): name, description, the day it was earned.
## D-135: every achievement has its spot (Achievements.shelf_defs()); each can be earned.

signal picked(def: Dictionary, spot: Control)

const PLATE := 56.0
const CELL_MIN := 150.0
const INK := Color(0.11, 0.09, 0.07)
const CREAM := Color(0.94, 0.90, 0.82)
const MUTED := Color(0.80, 0.74, 0.64)
const PLATE_COLOUR := {"craft": "ivory", "mode": "navy", "ethics": "bottle_green", "story": "burgundy"}

var spots: Array = []  # Spot, in shelf order


func _ready() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 12)
	rebuild()


func rebuild() -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()
	spots.clear()
	var by_cat := {}
	for d: Dictionary in Achievements.shelf_defs():
		var cat := String(d.get("category", "craft"))
		if not by_cat.has(cat):
			by_cat[cat] = []
		by_cat[cat].append(d)
	var cats: Array = Achievements.CATEGORIES.duplicate()
	for cat: String in by_cat:
		if not cats.has(cat):
			cats.append(cat)
	for cat: String in cats:
		if not by_cat.has(cat):
			continue
		var defs: Array = by_cat[cat]
		var bay := PanelContainer.new()
		bay.name = "Bay_" + cat
		bay.mouse_filter = Control.MOUSE_FILTER_PASS
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 10)
		col.mouse_filter = Control.MOUSE_FILTER_PASS
		bay.add_child(col)
		var head := HBoxContainer.new()
		head.add_theme_constant_override("separation", 8)
		col.add_child(head)
		var title := ScreenFrame.wrap(Label.new())
		title.name = "Heading"
		title.theme_type_variation = &"Heading"
		title.text = I18n.t(StringName("ach.cat." + cat))
		head.add_child(title)
		var earned := 0
		for d: Dictionary in defs:
			if Achievements.is_unlocked(d.get("id", "")):
				earned += 1
		var count := Label.new()
		count.name = "Count"
		count.theme_type_variation = &"Caption"
		count.text = I18n.t(&"ach.count").replace("{n}", str(earned)).replace("{m}", str(defs.size()))
		count.size_flags_vertical = Control.SIZE_SHRINK_END
		head.add_child(count)
		var board := Board.new()
		board.name = "Board"
		col.add_child(board)
		for d: Dictionary in defs:
			var spot := Spot.new()
			spot.setup(d)
			spot.pressed.connect(func() -> void: picked.emit(d, spot))
			board.add_child(spot)
			spots.append(spot)
		add_child(bay)


func spot_for(id: String) -> Control:
	for s: Spot in spots:
		if s.def.get("id", "") == id:
			return s
	return null


## Columns of spots on a board `width` dp wide: 2 on a phone in portrait, 3 in the landscape
## column, 1 with text at 200 % (the names need the width).
static func columns_for(width: float, text_scale: float) -> int:
	var cell := CELL_MIN * maxf(1.0, text_scale)
	return clampi(int((width + Board.GAP_X) / (cell + Board.GAP_X)), 1, 4)


# ------------------------------------------------------------------ texts
static func shown_name(def: Dictionary) -> String:
	if concealed(def):
		return I18n.t(&"ach.hidden.name")
	return I18n.t(StringName("ach.%s.name" % def.get("id", "")))


static func shown_desc(def: Dictionary) -> String:
	if concealed(def):
		return I18n.t(&"ach.hidden.desc")
	return I18n.t(StringName("ach.%s.desc" % def.get("id", "")))


## A hidden achievement that is not earned yet: nothing about it is shown or read out.
static func concealed(def: Dictionary) -> bool:
	return bool(def.get("hidden", false)) and not Achievements.is_unlocked(def.get("id", ""))


static func status_text(def: Dictionary) -> String:
	var id := String(def.get("id", ""))
	if not Achievements.is_unlocked(id):
		return I18n.t(&"ach.not_earned")
	var day := format_date(Achievements.unlocked_on(id))
	if day == "":
		return I18n.t(&"ach.earned")  # earned before the day was recorded
	return I18n.t(&"ach.earned_on").replace("{date}", day)


## "2026-11-15" in the order of the game language (ach.date_fmt); "" for anything else.
static func format_date(iso: String) -> String:
	var p := iso.split("-")
	if p.size() != 3 or not (p[0].is_valid_int() and p[1].is_valid_int() and p[2].is_valid_int()):
		return ""
	return I18n.t(&"ach.date_fmt").replace("{y}", p[0]).replace("{m}", p[1]).replace("{d}", p[2])


## What a screen reader says for a spot: name, state, and for an open one how to earn it.
static func spoken(def: Dictionary) -> String:
	if Achievements.is_unlocked(def.get("id", "")):
		return "%s. %s" % [shown_name(def), status_text(def)]
	return "%s. %s. %s" % [shown_name(def), status_text(def), shown_desc(def)]


## The letter on a plate: the first letter of the name, past a leading article ("The First Click" is F,
## "Eine Tür geht auf" is T), so a shelf in English is not a row of A and T.
const ARTICLES := ["a", "an", "the", "der", "die", "das", "ein", "eine", "le", "la", "les", "un", "une", "el", "los", "las", "una"]


static func initial_of(text: String) -> String:
	var words := text.strip_edges().split(" ", false)
	if words.is_empty():
		return ""
	var word := words[0]
	if words.size() > 1 and ARTICLES.has(word.to_lower()):
		word = words[1]
	elif word.length() > 2 and word.substr(1, 1) in ["'", "’"]:  # L'école
		word = word.substr(2)
	return word.substr(0, 1).to_upper()


## The enamel plate of an earned achievement (`side` dp), with the initial of its name.
static func plate(def: Dictionary, side: float) -> Control:
	var wrap := Control.new()
	wrap.name = "Plate"
	wrap.custom_minimum_size = Vector2(side, side)
	wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var colour: String = PLATE_COLOUR.get(String(def.get("category", "")), "ivory")
	var path := "res://assets/ui/plates/initial_%s.png" % colour
	var tex := TextureRect.new()
	tex.texture = load(path) if ResourceLoader.exists(path) else null
	tex.set_anchors_preset(Control.PRESET_FULL_RECT)
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.add_child(tex)
	var initial := Label.new()
	initial.name = "Initial"
	initial.text = initial_of(shown_name(def))
	initial.set_anchors_preset(Control.PRESET_FULL_RECT)
	initial.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	initial.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	initial.mouse_filter = Control.MOUSE_FILTER_IGNORE
	initial.add_theme_font_override("font", load("res://theme/title_font.tres"))
	initial.add_theme_font_size_override("font_size", roundi(side * 0.46))
	initial.add_theme_color_override("font_color", INK if colour == "ivory" else Color(0.96, 0.92, 0.84))
	initial.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
	wrap.add_child(initial)
	return wrap


# ------------------------------------------------------------------ board
## Lays the spots out in rows and draws a wooden board under each row.
class Board extends Container:
	const GAP_X := 12.0
	const PLANK := 9.0       # front edge of the board
	const ROW_GAP := 16.0    # air under a board, before the next row
	const WOOD_TOP := Color(0.47, 0.31, 0.18)
	const WOOD_EDGE := Color(0.30, 0.19, 0.11)
	const WOOD_LINE := Color(0.66, 0.49, 0.30)
	var _planks: PackedFloat32Array = []

	func _init() -> void:
		size_flags_horizontal = Control.SIZE_EXPAND_FILL
		mouse_filter = Control.MOUSE_FILTER_PASS

	func _notification(what: int) -> void:
		if what == NOTIFICATION_SORT_CHILDREN:
			_sort()

	func _sort() -> void:
		var w := maxf(size.x, 120.0)
		var cols := AchievementShelf.columns_for(w, UiA11y.text_scale())
		var cell := (w - GAP_X * (cols - 1)) / cols
		var kids: Array = []
		for c in get_children():
			if c is Spot:
				kids.append(c)
		_planks = PackedFloat32Array()
		var y := 0.0
		for row in range(0, kids.size(), cols):
			var h := 0.0
			for i in range(row, mini(row + cols, kids.size())):
				h = maxf(h, (kids[i] as Spot).height_for(cell))
			for i in range(row, mini(row + cols, kids.size())):
				fit_child_in_rect(kids[i], Rect2((i - row) * (cell + GAP_X), y, cell, h))
				(kids[i] as Spot)._layout()
			y += h
			_planks.append(y)
			y += PLANK + ROW_GAP
		var total := maxf(0.0, y - ROW_GAP)
		if absf(custom_minimum_size.y - total) > 0.5:
			custom_minimum_size.y = total
		queue_redraw()

	func _draw() -> void:
		for y in _planks:
			draw_rect(Rect2(0, y + PLANK, size.x, 4.0), Color(0, 0, 0, 0.35))  # the board's shadow on the back
			draw_rect(Rect2(0, y - 3.0, size.x, 3.0), WOOD_TOP)                # the top face, seen from above
			draw_rect(Rect2(0, y, size.x, PLANK), WOOD_EDGE)                   # the front edge
			draw_rect(Rect2(0, y, size.x, 1.0), WOOD_LINE)                     # worn arris


# ------------------------------------------------------------------ spot
## One place on the shelf: a button (>= 48 dp) with its own screen-reader name.
class Spot extends Button:
	const GAP := 10.0
	const PAD_TOP := 6.0
	var def: Dictionary = {}
	var earned := false
	var _plate: Control
	var _label: Label

	func setup(d: Dictionary) -> void:
		def = d
		earned = Achievements.is_unlocked(d.get("id", ""))
		name = String(d.get("id", "spot")).replace(".", "_")
		flat = true
		focus_mode = Control.FOCUS_ALL
		mouse_filter = Control.MOUSE_FILTER_PASS  # a drag that starts on a spot still scrolls the shelf
		for st in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
			add_theme_stylebox_override(st, StyleBoxEmpty.new())
		if earned:
			_plate = AchievementShelf.plate(d, AchievementShelf.PLATE)
		else:
			_plate = EmptyPlace.new()
			(_plate as EmptyPlace).mark = "?" if AchievementShelf.concealed(d) else ""
		add_child(_plate)
		_label = Label.new()
		_label.name = "Name"
		_label.text = AchievementShelf.shown_name(d)
		_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_label.clip_text = true  # no minimum height of its own: the spot sizes it (height_for)
		_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if earned:
			_label.add_theme_font_override(&"font", load("res://theme/title_font.tres"))
			_label.add_theme_font_size_override(&"font_size", UiA11y.fs(17))
			_label.add_theme_color_override(&"font_color", AchievementShelf.CREAM)
		else:
			_label.add_theme_font_size_override(&"font_size", UiA11y.fs(15))
			_label.add_theme_color_override(&"font_color", AchievementShelf.MUTED)
		add_child(_label)
		set("accessibility_name", AchievementShelf.spoken(d))
		resized.connect(_layout)

	func _text_width(w: float) -> float:
		return maxf(w - AchievementShelf.PLATE - GAP, 40.0)

	## Height the spot needs at width `w`: the plate, or the wrapped name when that is taller.
	func height_for(w: float) -> float:
		_label.size.x = _text_width(w)  # the label wraps at its own width: ask it, do not re-measure
		var lines := maxi(1, _label.get_line_count())
		var text_h := lines * _label.get_line_height() + (lines - 1) * _label.get_theme_constant(&"line_spacing")
		return ceilf(maxf(AchievementShelf.PLATE, text_h) + PAD_TOP)

	func _layout() -> void:
		var side := AchievementShelf.PLATE
		_plate.position = Vector2(0, size.y - side)  # the plate stands on the board
		_plate.size = Vector2(side, side)
		_label.position = Vector2(side + GAP, PAD_TOP)
		_label.size = Vector2(_text_width(size.x), size.y - PAD_TOP)

	func _draw() -> void:
		if get_draw_mode() == DRAW_PRESSED or get_draw_mode() == DRAW_HOVER_PRESSED:
			draw_rect(Rect2(Vector2.ZERO, size), Color(1, 1, 1, 0.08))


## The place of a plate that is not there yet: dashed outline, the two screw holes, "?" when hidden.
class EmptyPlace extends Control:
	var mark := ""

	func _init() -> void:
		name = "Empty"
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var line := Color(AchievementShelf.MUTED, 0.75)
		var r := Rect2(Vector2(4, 6), size - Vector2(8, 8))
		var corners := [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]
		for i in 4:
			draw_dashed_line(corners[i], corners[(i + 1) % 4], line, 2.0, 5.0)
		for x: float in [r.position.x + 7.0, r.end.x - 7.0]:
			draw_arc(Vector2(x, r.get_center().y), 2.5, 0.0, TAU, 16, line, 1.5)
		if mark != "":
			var font: Font = load("res://theme/title_font.tres")
			var fs := roundi(size.y * 0.5)
			var w := font.get_string_size(mark, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			draw_string(font, Vector2(r.get_center().x - w * 0.5, r.get_center().y + font.get_ascent(fs) * 0.36), mark,
				HORIZONTAL_ALIGNMENT_LEFT, -1, fs, AchievementShelf.MUTED)


# ------------------------------------------------------------------ card
## The card of one achievement over the shelf: a cream label card (EnamelPanel) on the dark shade
## of the pause screen. Name, description, the day it was earned; Close, a tap beside the card or
## Back closes it.
class Card extends ColorRect:
	const SHADE := Color(0.06, 0.045, 0.035, 0.84)
	const COLUMN := 420.0
	var close_button: Button
	var name_label: Label
	var desc_label: Label
	var status_label: Label
	var category_label: Label
	var _panel: PanelContainer
	var _scroll: ScrollContainer
	var _body: VBoxContainer
	var _head: HBoxContainer
	var _from: Control = null

	func _init() -> void:
		name = "AchievementCard"
		color = SHADE
		visible = false
		mouse_filter = Control.MOUSE_FILTER_STOP
		set_anchors_preset(Control.PRESET_FULL_RECT)

	func _ready() -> void:
		var frame := MarginContainer.new()
		frame.name = "Frame"
		frame.set_anchors_preset(Control.PRESET_FULL_RECT)
		frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(frame)
		ScreenFrame.fit(self, frame, COLUMN)
		var column := VBoxContainer.new()
		column.alignment = BoxContainer.ALIGNMENT_CENTER
		column.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.add_child(column)
		_panel = PanelContainer.new()
		_panel.name = "Panel"
		_panel.theme_type_variation = &"EnamelPanel"
		column.add_child(_panel)
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 12)
		_panel.add_child(box)
		_scroll = ScrollContainer.new()
		_scroll.name = "Scroll"
		_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		_scroll.scroll_deadzone = 12
		box.add_child(_scroll)
		_body = VBoxContainer.new()
		_body.name = "Body"
		_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_body.add_theme_constant_override("separation", 10)
		_scroll.add_child(_body)
		_head = HBoxContainer.new()
		_head.name = "Head"
		_head.add_theme_constant_override("separation", 12)
		_body.add_child(_head)
		var titles := VBoxContainer.new()
		titles.name = "Titles"
		titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		titles.alignment = BoxContainer.ALIGNMENT_CENTER
		titles.add_theme_constant_override("separation", 2)
		_head.add_child(titles)
		category_label = _on_enamel("Category", 14)
		category_label.add_theme_color_override(&"font_color", Color(0.32, 0.25, 0.12))
		titles.add_child(category_label)
		name_label = _on_enamel("Name", 22)
		name_label.add_theme_font_override(&"font", load("res://theme/title_font.tres"))
		titles.add_child(name_label)
		desc_label = _on_enamel("Desc", 16)
		_body.add_child(desc_label)
		var rule := ColorRect.new()
		rule.name = "Rule"
		rule.color = Color(AchievementShelf.INK, 0.55)
		rule.custom_minimum_size = Vector2(0, 2)
		rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_body.add_child(rule)
		status_label = _on_enamel("Status", 15)
		_body.add_child(status_label)
		close_button = Button.new()
		close_button.name = "CloseButton"
		close_button.text = I18n.t(&"common.close")
		close_button.custom_minimum_size = Vector2(0, 48)
		close_button.pressed.connect(close)
		box.add_child(close_button)
		gui_input.connect(_on_shade_input)
		resized.connect(_fit_scroll)
		_body.minimum_size_changed.connect(_fit_scroll)

	func _on_enamel(node_name: String, font_size: int) -> Label:
		var l := ScreenFrame.wrap(Label.new())
		l.name = node_name
		l.theme_type_variation = &"OnEnamel"
		l.add_theme_font_size_override(&"font_size", UiA11y.fs(font_size))
		return l

	func open(def: Dictionary, from: Control = null) -> void:
		_from = from
		var old := _head.get_node_or_null("Plate")
		if old == null:
			old = _head.get_node_or_null("Empty")
		if old != null:
			_head.remove_child(old)
			old.queue_free()
		var mark: Control
		if Achievements.is_unlocked(def.get("id", "")):
			mark = AchievementShelf.plate(def, 64.0)
		else:
			var empty := EmptyPlace.new()
			empty.mark = "?" if AchievementShelf.concealed(def) else ""
			empty.custom_minimum_size = Vector2(64, 64)
			empty.modulate = Color(0.25, 0.2, 0.15)  # the muted chalk line, dark on the cream card
			mark = empty
		mark.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		_head.add_child(mark)
		_head.move_child(mark, 0)
		category_label.text = I18n.t(StringName("ach.cat." + String(def.get("category", "craft"))))
		name_label.text = AchievementShelf.shown_name(def)
		desc_label.text = AchievementShelf.shown_desc(def)
		status_label.text = AchievementShelf.status_text(def)
		_scroll.scroll_vertical = 0
		visible = true
		_fit_scroll.call_deferred()
		if is_inside_tree():
			close_button.grab_focus()
			if not UiA11y.reduce_motion():
				modulate.a = 0.0
				create_tween().tween_property(self, "modulate:a", 1.0, 0.15)
			UiA11y.announce("%s. %s. %s" % [name_label.text, desc_label.text, status_label.text], false)

	func close() -> void:
		if not visible:
			return
		visible = false
		if _from != null and is_instance_valid(_from) and _from.is_inside_tree():
			_from.grab_focus()
		_from = null

	## The card never grows past the window: with large text the body scrolls, Close stays in view.
	func _fit_scroll() -> void:
		if _scroll == null or not visible:
			return
		var i := ScreenFrame.insets(self)
		var avail := size.y - i.y - i.w - 20.0 - 24.0 - 12.0 - close_button.get_combined_minimum_size().y - 8.0
		var want := minf(_body.get_combined_minimum_size().y, maxf(avail, 96.0))
		if absf(_scroll.custom_minimum_size.y - want) > 0.5:
			_scroll.custom_minimum_size.y = want

	func _on_shade_input(event: InputEvent) -> void:
		var mb := event as InputEventMouseButton
		if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			close()
			accept_event()
