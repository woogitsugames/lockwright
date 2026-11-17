extends Control
## Showcase: historical notes from game/data/showcase/*.json with source field.

@onready var notes_list: VBoxContainer = $Frame/VBox/Scroll/NotesList
@onready var back_button: Button = $Frame/VBox/Header/BackButton

const SHOWCASE_DIR := "res://data/showcase"

## D-133 (VQA-17): two tabs under the header, as in the workshop: the exhibits (historical notes)
## and the achievement shelf.
var shelf: AchievementShelf
var card: AchievementShelf.Card
var _tabs := {}
var _shelf_scroll: ScrollContainer
var _tab := "exhibits"


func _build_tabs() -> void:
	var row := HBoxContainer.new()
	row.name = "Tabs"
	row.add_theme_constant_override("separation", 8)
	$Frame/VBox.add_child(row)
	$Frame/VBox.move_child(row, $Frame/VBox/Header.get_index() + 1)
	var group := ButtonGroup.new()
	for spec: Array in [["exhibits", &"showcase.tab_exhibits"], ["shelf", &"showcase.tab_shelf"]]:
		var b := Button.new()
		b.name = "Tab_" + spec[0]
		b.text = I18n.t(spec[1])
		b.toggle_mode = true
		b.button_group = group
		b.custom_minimum_size = Vector2(0, 48)
		b.theme_type_variation = &"TabPlate"
		b.add_theme_font_size_override("font_size", UiA11y.fs(16))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		b.clip_text = true
		ScreenFrame.fit_button_text(b, 16, 11)
		ScreenFrame.tab_mark(b)
		var tab: String = spec[0]
		b.toggled.connect(func(on: bool) -> void:
			if on:
				show_tab(tab))
		row.add_child(b)
		_tabs[tab] = b
	_shelf_scroll = ScrollContainer.new()
	_shelf_scroll.name = "ShelfScroll"
	_shelf_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_shelf_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	ScreenFrame.soft_top_edge(_shelf_scroll)  # VQA-24
	_shelf_scroll.scroll_deadzone = 12
	_shelf_scroll.visible = false
	$Frame/VBox.add_child(_shelf_scroll)
	shelf = AchievementShelf.new()
	shelf.name = "Shelf"
	shelf.picked.connect(func(def: Dictionary, spot: Control) -> void: card.open(def, spot))
	_shelf_scroll.add_child(shelf)
	card = AchievementShelf.Card.new()
	add_child(card)


## "exhibits" (historical notes) or "shelf" (achievements).
func show_tab(tab: String) -> void:
	_tab = tab if _tabs.has(tab) else "exhibits"
	for t: String in _tabs:
		(_tabs[t] as Button).set_pressed_no_signal(t == _tab)
	$Frame/VBox/Scroll.visible = _tab == "exhibits"
	_shelf_scroll.visible = _tab == "shelf"


## The card of one achievement (also for screenshots: shot_scene --ach-open=<id>).
func show_detail(id: String) -> void:
	show_tab("shelf")
	card.open(Achievements.def_by_id(id), shelf.spot_for(id))


## Nav (Android Back, Esc): an open card closes first.
func go_back() -> bool:
	if card != null and card.visible:
		card.close()
		return true
	return false


func _show_notebook_entry() -> void:
	var keys: Array = []
	for k in I18n.all_keys():
		if String(k).begins_with("notebook.extra."):
			keys.append(k)
	if keys.is_empty():
		return
	# D-129: the entry is written on a blank page of the master's notebook (G10 lined paper, Caveat on
	# the rulings). It used to be a label above a cropped photo of the "five rules" page: other words
	# than the entry, cut mid-line, and Polish or English handwriting whatever the game language.
	var strip := NotebookStrip.new()
	strip.name = "Notebook"
	strip.setup(I18n.t(&"showcase.notebook_prefix"), I18n.t(keys[randi() % keys.size()]))
	notes_list.add_child(strip)


## A strip of the blank lined notebook page with a handwritten entry sitting on its rulings.
class NotebookStrip extends Control:
	const PAGE := "res://assets/ui/gpt/notebook/15-blank-lined.jpg"
	const HAND := "res://assets/fonts/Caveat-wght.ttf"
	# measured on the 1600x2200 page: first ruling, ruling pitch, red margin line, usable paper
	const FIRST_RULE := 194.0
	const PITCH := 68.5
	const MARGIN_X := 243.0
	const PAPER_X0 := 120.0
	const PAPER_X1 := 1500.0
	const INK := Color(0.16, 0.13, 0.17)
	var label: Label
	var _page: Texture2D
	var _pitch := 26
	var _rule_y := 22.0  # where the first ruling is drawn (under the first baseline)

	func setup(prefix: String, entry: String) -> void:
		_page = load(PAGE) if ResourceLoader.exists(PAGE) else null
		size_flags_horizontal = Control.SIZE_EXPAND_FILL
		mouse_filter = Control.MOUSE_FILTER_PASS
		clip_contents = true
		label = Label.new()
		label.name = "Entry"
		label.text = prefix + "\n" + entry
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if ResourceLoader.exists(HAND):
			label.add_theme_font_override(&"font", load(HAND))
		label.add_theme_color_override(&"font_color", INK)
		label.add_theme_color_override(&"font_shadow_color", Color(0, 0, 0, 0))
		add_child(label)
		resized.connect(_fit)
		_fit()

	## Screen pixels per page pixel: the rulings land `_pitch` dp apart (26 dp, more on a wide column
	## and with large text), so the handwriting stays readable in portrait and landscape.
	func page_scale() -> float:
		return _pitch / PITCH

	func _fit() -> void:
		var w := maxf(size.x, 200.0)
		_pitch = clampi(roundi(maxf(26.0, PITCH * w / (PAPER_X1 - PAPER_X0)) * UiA11y.text_scale()), 26, 52)
		var k := page_scale()
		var font := label.get_theme_font(&"font")
		var fs := maxi(12, roundi(_pitch * 0.92))
		label.add_theme_font_size_override(&"font_size", fs)
		label.add_theme_constant_override(&"line_spacing", _pitch - int(font.get_height(fs)))
		var left := (MARGIN_X - PAPER_X0) * k + 10.0
		var text_w := maxf(w - left - 12.0, 80.0)
		var lines := maxi(1, roundi(font.get_multiline_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, text_w, fs).y / font.get_height(fs)))
		# the first baseline sits a hair above the first ruling shown
		label.position = Vector2(left, 4.0)
		label.size = Vector2(text_w, lines * _pitch)
		_rule_y = label.position.y + font.get_ascent(fs) + 2.0
		custom_minimum_size.y = roundf(label.position.y + label.size.y + 4.0)
		queue_redraw()

	func _draw() -> void:
		if _page == null:
			draw_rect(Rect2(Vector2.ZERO, size), Color(0.86, 0.80, 0.68))
			return
		var k := page_scale()
		var src := Rect2(PAPER_X0, FIRST_RULE - _rule_y / k, size.x / k, size.y / k)
		draw_texture_rect_region(_page, Rect2(Vector2.ZERO, size), src, Color(0.94, 0.92, 0.88))


func _exhibit_photo(nid: String) -> Texture2D:
	# G16 showcase photos: showcase.<slug> -> <NN>_<slug>.jpg
	var slug := nid.replace("showcase.", "")
	for f in ResourceLoader.list_directory("res://assets/ui/gpt/showcase"):
		if f.ends_with("_%s.jpg" % slug):
			return load("res://assets/ui/gpt/showcase/" + f)
	return null


# N-40: a note unlocks with progress — every `job.*` reference in `unlocks` must be
# a completed job, and a tier ref T<n> needs a completed job of tier >= n.
func _note_unlocked(note: Dictionary) -> bool:
	var completed: Array = Save.get_value("jobs_completed", [])
	var unlocks: String = note.get("unlocks", "")
	if unlocks == "":
		return true
	var re := RegEx.new()
	re.compile("`([^`]+)`")
	var max_tier := 0
	for j in completed:
		max_tier = maxi(max_tier, JobRun.tier_for(JobRun.job_meta(j)))  # D-112: also jobs of a pack that is not on the phone
	for m in re.search_all(unlocks):
		var token := m.get_string(1)
		if token.begins_with("job."):
			if not completed.has(token):
				return false
		elif token.begins_with("T") and token.substr(1).is_valid_int():
			if max_tier < token.substr(1).to_int():
				return false
	return true


# markdown emphasis *...* -> BBCode [i]...[/i]
func _bbcode(text: String) -> String:
	var re := RegEx.new()
	re.compile("\\*([^*]+)\\*")
	return re.sub(text, "[i]$1[/i]", true)


func _ready() -> void:
	Sfx.play_ambience(&"workshop")
	Sfx.play_music(&"menu_workshop")
	ScreenFrame.backdrop(self, "res://assets/ui/gpt/workshop/05-display-cabinet-portrait.webp", 0.6)
	ScreenFrame.fit(self, $Frame)  # N-53/N-59
	$Frame/VBox/Scroll.scroll_deadzone = 12
	$Frame/VBox/Header/Title.text = I18n.t(&"showcase.title")
	back_button.text = "‹ " + I18n.t(&"common.back")
	back_button.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	_build_tabs()
	show_tab("exhibits")
	if Achievements.open_on_shelf != "":  # D-138: a tap on the chalk line of an earned achievement
		var id := Achievements.open_on_shelf
		Achievements.open_on_shelf = ""
		show_detail.call_deferred(id)
	_show_notebook_entry()  # task 10: master's notebook entries (contrib/gpt/T10 notebook_extra.csv)
	for path in DirAccess.get_files_at(SHOWCASE_DIR):
		if not path.ends_with(".json"):
			continue
		var note: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SHOWCASE_DIR + "/" + path))
		var nid: String = note.get("id", path.get_basename())
		var unlocked: bool = _note_unlocked(note)
		var panel := PanelContainer.new()
		panel.mouse_filter = Control.MOUSE_FILTER_PASS
		var card := VBoxContainer.new()
		card.add_theme_constant_override("separation", 8)
		panel.add_child(card)
		var photo := _exhibit_photo(nid)
		if photo != null and unlocked:
			var tex := TextureRect.new()
			tex.texture = photo
			tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			tex.custom_minimum_size = Vector2(0, 160)
			card.add_child(tex)
		var title := Button.new()
		title.text = I18n.t(note.get("i18n", {}).get("title", &"showcase.title"))
		if not unlocked:
			# D-129: the name on its own line, the lock note under it ("X — Locked — unlock it…" read as one run-on)
			title.text += "\n" + I18n.t(&"showcase.locked")
			title.disabled = true
		title.alignment = HORIZONTAL_ALIGNMENT_LEFT
		title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART  # N-59
		title.custom_minimum_size = Vector2(0, 48)
		title.mouse_filter = Control.MOUSE_FILTER_PASS
		var body := RichTextLabel.new()
		body.bbcode_enabled = true
		body.text = _bbcode(I18n.t(note.get("i18n", {}).get("body", &"showcase.title")))
		body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.fit_content = true
		body.visible = false
		var source := ScreenFrame.wrap(Label.new())
		source.theme_type_variation = &"Caption"
		var src: String = note.get("source", "")
		source.text = "%s: %s" % [I18n.t(&"showcase.source"), src if src != "" else I18n.t(&"showcase.unknown_source")]
		source.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		source.visible = false
		title.pressed.connect(func() -> void:
			body.visible = not body.visible
			source.visible = body.visible)
		card.add_child(title)
		card.add_child(body)
		card.add_child(source)
		notes_list.add_child(panel)
	ScreenFrame.soft_top_edge($Frame/VBox/Scroll)  # VQA-24: no hard cut under the header
	ScreenFrame.enter($Frame/VBox/Scroll)
	ScreenFrame.wire_sounds(self)  # S05 enamel-plate sounds
