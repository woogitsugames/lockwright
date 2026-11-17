extends GutTest
## D-129 (visual QA 2026-11-13): layout rules behind the fixes of docs/handoff/VISUAL-QA-2026-11-13.md.
## Screens are laid out in a SubViewport (as in test_ui_layout.gd) at 412x915, 360x800 and 915x412.

const PORTRAIT := Vector2i(412, 915)
const NARROW := Vector2i(360, 800)
const LANDSCAPE := Vector2i(915, 412)

var _save_backup: Dictionary
var _lang := ""


func before_all() -> void:
	_save_backup = Save.data.duplicate(true)
	_lang = I18n.current_language()


func after_each() -> void:
	I18n.apply_language(_lang)


func after_all() -> void:
	Save.data = _save_backup
	Save.save()


func _open(path: String, size: Vector2i) -> Control:
	var vp := SubViewport.new()
	vp.size = size
	vp.disable_3d = true
	add_child_autofree(vp)
	var scene: Control = load(path).instantiate()
	vp.add_child(scene)
	for i in 6:
		await get_tree().process_frame
	return scene


# VQA-01: in landscape both control cards show their whole text; nothing is left under the fold
func test_control_choice_landscape_needs_no_scrolling() -> void:
	for lang in ["pl", "en", "de"]:
		I18n.apply_language(lang)
		var scene := await _open("res://scenes/control_choice.tscn", LANDSCAPE)
		var scroll: ScrollContainer = scene.get_node("Frame/VBox/Scroll")
		var options: Control = scene.get_node("Frame/VBox/Scroll/Options")
		assert_lte(options.get_combined_minimum_size().y, scroll.size.y + 0.5, "%s: cards fit the list height" % lang)
		var view := scroll.get_global_rect().grow(0.5)
		for n in options.find_children("*", "Label", true, false):
			var l := n as Label
			if l.is_visible_in_tree():
				assert_true(view.encloses(l.get_global_rect()), "%s: %s inside the list (%s)" % [lang, l.name, l.get_global_rect()])
				assert_eq(l.get_visible_line_count(), l.get_line_count(), "%s: %s not cut" % [lang, l.name])
		scene.get_parent().queue_free()
		await get_tree().process_frame


func test_control_choice_portrait_keeps_the_large_sketches() -> void:
	var scene := await _open("res://scenes/control_choice.tscn", PORTRAIT)
	var sketch: Control = scene.get_node("Frame/VBox/Scroll/Options/Auto").find_child("Sketch", true, false)
	assert_eq(sketch.custom_minimum_size, Vector2(112, 112))


# VQA-02: landscape workshop gives the list the height (coins in the header row, no map strip)
func test_workshop_landscape_list_gets_the_height() -> void:
	var scene := await _open("res://scenes/workshop.tscn", LANDSCAPE)
	var scroll: ScrollContainer = scene.get_node("Frame/VBox/Scroll")
	assert_gte(scroll.size.y, 230.0, "list height in landscape (was about 150 dp)")
	var coins: Label = scene.coins_label
	assert_eq(coins.get_parent().name, &"Header", "coins beside the title")
	assert_true(coins.is_visible_in_tree())
	assert_gt(coins.size.x, 40.0, "the coins line keeps its width")
	assert_true(Rect2(Vector2.ZERO, Vector2(LANDSCAPE)).encloses(coins.get_global_rect()))
	assert_false(scene._map_frame != null and scene._map_frame.visible, "no map strip in landscape")
	for tab in ["furnishings", "practice", "tools"]:
		scene.show_tab(tab)
		await get_tree().process_frame
		assert_false(scene._map_frame != null and scene._map_frame.visible, "%s: no map strip in landscape" % tab)


func test_workshop_portrait_is_unchanged() -> void:
	for size in [PORTRAIT, NARROW]:
		var scene := await _open("res://scenes/workshop.tscn", size)
		assert_eq(scene.coins_label.get_parent().name, &"VBox", "coins on their own line")
		assert_eq(scene.coins_label.get_index(), 1)
		if scene._map_frame != null:
			assert_true(scene._map_frame.visible, "district map above the tools")
			scene.show_tab("practice")
			assert_false(scene._map_frame.visible)
		scene.get_parent().queue_free()
		await get_tree().process_frame


func test_workshop_furnishing_preview_fits_the_landscape_list() -> void:
	if not Furnishings.has_picture():
		pass_test("no workshop render in this build")
		return
	var scene := await _open("res://scenes/workshop.tscn", LANDSCAPE)
	scene.show_tab("furnishings")
	for i in 4:
		await get_tree().process_frame
	var scroll: ScrollContainer = scene.get_node("Frame/VBox/Scroll")
	var preview: Control = scene.tools_list.get_node("Preview")
	assert_lte(preview.size.y, scroll.size.y, "the whole photo is visible without scrolling")


# VQA-03: the About sheet is opaque (the menu board no longer shows through its text)
func test_about_sheet_is_opaque() -> void:
	var scene := await _open("res://scenes/main_menu.tscn", PORTRAIT)
	var sb := (scene.get_node("AboutPanel") as PanelContainer).get_theme_stylebox(&"panel") as StyleBoxFlat
	assert_not_null(sb)
	assert_gte(sb.bg_color.a, 0.95)


# VQA-04: the arrival header band keeps the title readable over a white lamp (>= 7:1)
func test_arrival_header_band_contrast_over_white() -> void:
	var arrival := load("res://scripts/ui/job_arrival.gd")
	var a: float = arrival.HEADER_BAND_ALPHA
	var band := Color(0.06, 0.045, 0.035)
	var under := Color(band.r * a + (1.0 - a), band.g * a + (1.0 - a), band.b * a + (1.0 - a))
	var cream := Color(0.94, 0.90, 0.82)
	var ratio := (_lum(cream) + 0.05) / (_lum(under) + 0.05)
	assert_gte(ratio, 7.0, "title on the band over pure white: %.1f:1" % ratio)


func _lum(c: Color) -> float:
	var l := c.srgb_to_linear()
	return 0.2126 * l.r + 0.7152 * l.g + 0.0722 * l.b


# VQA-05: the "in the dark" tip follows the sound-captions caption, not the text-size switch
func test_settings_dark_note_follows_sound_captions() -> void:
	var scene := await _open("res://scenes/settings.tscn", PORTRAIT)
	var box: Node = scene.get_node("Frame/VBox/Scroll/Sections/Access/Box")
	var note: Node = box.get_node("DarkNote")
	var cap: Node = box.get_node("SoundCaptionsHelp")
	assert_eq(note.get_index(), cap.get_index() + 1)
	assert_ne(box.get_child(box.get_child_count() - 1), note, "not the last line of the section any more")


# VQA-06: the notebook entry is written on the lined page; the strip holds the whole text
func test_showcase_notebook_entry_sits_on_the_page() -> void:
	for size in [PORTRAIT, NARROW, LANDSCAPE]:
		for lang in ["pl", "de"]:
			I18n.apply_language(lang)
			var scene := await _open("res://scenes/showcase.tscn", size)
			var strip: Control = scene.notes_list.get_node_or_null("Notebook")
			assert_not_null(strip, "%s %s: notebook strip" % [size, lang])
			if strip == null:
				continue
			var label: Label = strip.get_node("Entry")
			assert_true(label.text.begins_with(I18n.t(&"showcase.notebook_prefix")))
			assert_eq(label.get_visible_line_count(), label.get_line_count(), "%s %s: entry not cut" % [size, lang])
			assert_true(Rect2(Vector2.ZERO, strip.size).grow(1.0).encloses(Rect2(label.position, label.size)),
				"%s %s: entry %s inside the strip %s" % [size, lang, Rect2(label.position, label.size), strip.size])
			assert_gte(label.get_theme_font_size(&"font_size"), 22, "handwriting stays readable")
			# one ruling per text line: the line height equals the ruling pitch
			var font := label.get_theme_font(&"font")
			var fs := label.get_theme_font_size(&"font_size")
			assert_almost_eq(font.get_height(fs) + label.get_theme_constant(&"line_spacing"), float(strip._pitch), 0.01)
			scene.get_parent().queue_free()
			await get_tree().process_frame


func test_showcase_locked_exhibit_reads_in_two_lines() -> void:
	Save.data["jobs_completed"] = []
	var scene := await _open("res://scenes/showcase.tscn", PORTRAIT)
	var locked := 0
	for n in scene.notes_list.find_children("*", "Button", true, false):
		var b := n as Button
		if b.disabled:
			locked += 1
			assert_true(b.text.ends_with("\n" + I18n.t(&"showcase.locked")), b.text)
			assert_false(b.text.contains(" — " + I18n.t(&"showcase.locked")))
	assert_gt(locked, 0, "a fresh save has locked exhibits")


# VQA-07: boot cards keep 16 dp to the edges and the safe area, and are at most 360 dp wide
func test_boot_cards_keep_side_margins() -> void:
	var boot: GDScript = load("res://scripts/ui/boot.gd")
	assert_almost_eq(boot.panel_half_width(360.0, 0.0, 0.0) * 2.0, 328.0, 0.01, "360 dp phone: 16 dp each side")
	assert_almost_eq(boot.panel_half_width(412.0, 0.0, 0.0) * 2.0, 360.0, 0.01)
	assert_almost_eq(boot.panel_half_width(915.0, 47.0, 47.0) * 2.0, 360.0, 0.01)
	assert_almost_eq(boot.panel_half_width(360.0, 20.0, 20.0) * 2.0, 288.0, 0.01, "side cut-outs count")


# VQA-08: large text never breaks inside a word
func test_title_shrinks_below_min_before_breaking_a_word() -> void:
	var font: Font = load("res://theme/title_font.tres")
	var word := "Einstellungen"
	var fs := ScreenFrame.title_size(font, word, 190.0, 56, 34, 44)
	assert_lt(fs, 34, "goes under min_fs when the word does not fit")
	assert_gte(fs, 20, "but never under 60 % of it")
	assert_lte(font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x, 190.0, "the word fits one line")
	# unchanged when the word fits at min_fs
	assert_eq(ScreenFrame.title_size(font, "Ab", 2000.0, 28, 17, 22), 28)


func test_control_choice_sketch_gives_way_to_large_text() -> void:
	var cc: GDScript = load("res://scripts/ui/control_choice.gd")
	assert_eq(cc.sketch_side(true, 1.0), 112.0)
	assert_eq(cc.sketch_side(false, 1.0), 84.0)
	assert_eq(cc.sketch_side(true, 1.5), 72.0)
	assert_eq(cc.sketch_side(true, 2.0), 0.0, "no sketch at 200 %: the title needs the width")


func test_action_plate_is_as_wide_as_its_longest_word() -> void:
	var ws: GDScript = load("res://scripts/ui/workshop_screen.gd")
	var b := Button.new()
	add_child_autofree(b)
	b.custom_minimum_size = Vector2(112, 48)
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.add_theme_font_size_override(&"font_size", 34)
	b.text = "Wegräumen"
	ws.fit_action_plate(b)
	var need := b.get_theme_font(&"font").get_string_size(b.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 34).x
	var sb := b.get_theme_stylebox(&"normal")
	assert_gte(b.custom_minimum_size.x - sb.get_margin(SIDE_LEFT) - sb.get_margin(SIDE_RIGHT), need, "one word, one line")
	assert_lte(b.custom_minimum_size.x, 220.0)
	var small := Button.new()
	add_child_autofree(small)
	small.custom_minimum_size = Vector2(112, 48)
	small.text = "Kup"
	ws.fit_action_plate(small)
	assert_eq(small.custom_minimum_size.x, 112.0, "no autowrap (100 % text): the plate keeps its size")


func test_pack_rows_stack_at_large_text() -> void:
	var before_sys: Variant = Settings.get_value("text_scale_system", true)
	var before: Variant = Settings.get_value("text_scale", 1.0)
	Settings._cfg["text_scale_system"] = false
	Settings._cfg["text_scale"] = 2.0
	UiA11y._apply_text_scale()
	var scene := await _open("res://scenes/settings.tscn", PORTRAIT)
	var rows: Node = scene.get_node("Frame/VBox/Scroll/Sections/Access/Box/VoicePack/VoicePackRows")
	for row in rows.get_children():
		assert_true((row as BoxContainer).vertical, "%s stacked" % row.name)
		var label: Label = row.get_node("Label")
		assert_gte(label.size.x, 250.0, "%s: the size line has the row's width" % row.name)
	scene.get_parent().queue_free()
	Settings._cfg["text_scale_system"] = before_sys
	Settings._cfg["text_scale"] = before
	UiA11y._apply_text_scale()
	await get_tree().process_frame
	scene = await _open("res://scenes/settings.tscn", PORTRAIT)
	rows = scene.get_node("Frame/VBox/Scroll/Sections/Access/Box/VoicePack/VoicePackRows")
	if UiA11y.text_scale() < 1.5:
		for row in rows.get_children():
			assert_false((row as BoxContainer).vertical, "%s side by side at normal text" % row.name)


func test_tutorial_title_clear_of_back_plate_at_large_text() -> void:
	var before_sys: Variant = Settings.get_value("text_scale_system", true)
	var before: Variant = Settings.get_value("text_scale", 1.0)
	Settings._cfg["text_scale_system"] = false
	Settings._cfg["text_scale"] = 2.0
	UiA11y._apply_text_scale()
	for lang in ["pl", "de"]:
		I18n.apply_language(lang)
		for size in [PORTRAIT, LANDSCAPE]:
			var scene := await _open("res://scenes/tutorial.tscn", size)
			var back: Button = scene.get_node("BackButton")
			var title: Label = scene.get_node("Margin/Scroll/VBox/Title")
			assert_gte(title.get_global_rect().position.y, back.get_global_rect().end.y - 0.5, "%s %s: title under the plate" % [lang, size])
			var font := title.get_theme_font(&"font")
			var fs := title.get_theme_font_size(&"font_size")
			for w in title.text.split(" ", false):
				assert_lte(font.get_string_size(w, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x, title.size.x + 0.5, "%s %s: '%s' fits a line" % [lang, size, w])
			scene.get_parent().queue_free()
			await get_tree().process_frame
	Settings._cfg["text_scale_system"] = before_sys
	Settings._cfg["text_scale"] = before
	UiA11y._apply_text_scale()


# VQA-09: tutorial on a phone with a notch and a gesture bar: photo edge to edge, content inside the
# safe area, the back plate clear of the title
func test_tutorial_respects_the_safe_area() -> void:
	for case in [[PORTRAIT, Vector4(0, 44, 0, 34)], [LANDSCAPE, Vector4(47, 0, 47, 21)]]:
		var size: Vector2i = case[0]
		var inset: Vector4 = case[1]
		SafeArea.override_dp = inset
		var scene := await _open("res://scenes/tutorial.tscn", size)
		# the insets stay for the checks: a phone keeps them, and a relayout after the scene opened
		# (D-140: "Start" now sits at the bottom) must still see them
		var full := Rect2(Vector2.ZERO, Vector2(size))
		assert_eq(scene.get_global_rect(), full, "%s: root is full-rect" % size)
		assert_eq((scene.get_node("Backdrop") as Control).get_global_rect(), full, "%s: photo fills the bands" % size)
		var safe := Rect2(inset.x, inset.y, size.x - inset.x - inset.z, size.y - inset.y - inset.w).grow(0.5)
		var back: Button = scene.get_node("BackButton")
		assert_true(safe.encloses(back.get_global_rect()), "%s: back %s in the safe area" % [size, back.get_global_rect()])
		assert_almost_eq(back.get_global_rect().position.y, inset.y + 8.0, 0.5, "%s: one inset, not two" % size)
		for path in ["Margin/Scroll/VBox/Title", "Margin/Scroll/VBox/StartButton"]:
			var c: Control = scene.get_node(path)
			assert_true(safe.encloses(c.get_global_rect()), "%s: %s %s in the safe area" % [size, path, c.get_global_rect()])
		var title: Label = scene.get_node("Margin/Scroll/VBox/Title")
		if size.x < size.y:
			assert_gte(title.get_global_rect().position.y, back.get_global_rect().end.y - 0.5, "title under the plate")
		SafeArea.override_dp = SafeArea.OVERRIDE_OFF
		scene.get_parent().queue_free()
		await get_tree().process_frame
