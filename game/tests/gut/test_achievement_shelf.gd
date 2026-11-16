extends GutTest
## D-133: the achievement shelf in the Showcase (VQA-17), one cream button style (VQA-18), the strict
## achievement triggers behind the shelf, and the main menu that stops listening outside the tree.

const PORTRAIT := Vector2i(412, 915)
const LANDSCAPE := Vector2i(915, 412)
const LANGS := ["en", "pl", "de", "fr", "es"]

var _save_backup: Dictionary
var _lang := ""
var _scale_before: Variant
var _scale_system_before: Variant


func before_all() -> void:
	_save_backup = Save.data.duplicate(true)
	_lang = I18n.current_language()
	_scale_before = Settings.get_value("text_scale", 1.0)
	_scale_system_before = Settings.get_value("text_scale_system", true)


func before_each() -> void:
	Save.data["achievements"] = []
	Save.data["achievements_at"] = {}
	Achievements.reset_run_counts()
	Events.lock_dark = false
	JobRun.current_job = {}
	JobRun.mode = &"job"


func after_each() -> void:
	I18n.apply_language(_lang)
	_text_scale(float(_scale_before), bool(_scale_system_before))
	Events.change_scenes = true


func after_all() -> void:
	Save.data = _save_backup
	Save.save()
	JobRun.current_job = {}
	JobRun.mode = &"job"


func _text_scale(s: float, system := false) -> void:
	Settings._cfg["text_scale_system"] = system
	Settings._cfg["text_scale"] = s
	UiA11y._apply_text_scale()


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


func _earn(ids: Array, day := "2026-11-15") -> void:
	var at := {}
	for id: String in ids:
		at[id] = day
	Save.data["achievements"] = ids.duplicate()
	Save.data["achievements_at"] = at


func _def(id: String) -> Dictionary:
	return Achievements.def_by_id(id)


# ------------------------------------------------------------------ data
func test_every_achievement_has_a_name_and_description_in_five_languages() -> void:
	for lang: String in LANGS:
		I18n.apply_language(lang)
		for d: Dictionary in Achievements.defs:
			for part in ["name", "desc"]:
				var key := StringName("ach.%s.%s" % [d["id"], part])
				assert_true(I18n.has_key(key), "%s: %s" % [lang, key])
				assert_ne(I18n.t(key).strip_edges(), "", "%s: %s is empty" % [lang, key])
		for key in [&"showcase.tab_exhibits", &"showcase.tab_shelf", &"ach.count", &"ach.hidden.name", &"ach.hidden.desc",
				&"ach.earned", &"ach.earned_on", &"ach.not_earned", &"ach.date_fmt"]:
			assert_true(I18n.has_key(key), "%s: %s" % [lang, key])
		for cat: String in Achievements.CATEGORIES:
			assert_true(I18n.has_key(StringName("ach.cat." + cat)), "%s: category %s" % [lang, cat])


func test_every_category_in_the_data_has_a_bay() -> void:
	for d: Dictionary in Achievements.defs:
		assert_true(Achievements.CATEGORIES.has(d.get("category", "")), "%s: category %s" % [d["id"], d.get("category")])


func test_shelf_lists_every_achievement() -> void:
	# D-135: all 48 can be earned (test_achievements_d135.gd), so the D-133 filter is gone
	var shown: Array = Achievements.shelf_defs()
	assert_eq(shown.size(), Achievements.defs.size())
	var ids := shown.map(func(d: Dictionary) -> String: return d["id"])
	for id in ["achievement.first_set", "achievement.clock_repaired", "achievement.hard_clean", "achievement.first_dark",
			"achievement.one_pick", "achievement.permission", "achievement.pin_master", "achievement.pin_school",
			"achievement.tool_care", "achievement.ring_false"]:
		assert_true(ids.has(id), id)
	for d: Dictionary in shown:
		assert_true(Achievements.supported(d), "%s: a spot that can be filled" % d["id"])


# ------------------------------------------------------------------ triggers
func test_first_open_lock_gives_only_what_it_earned() -> void:
	# before D-133 conditions the code did not know were skipped: one open lock gave "dark mode",
	# "no marks", "tier 5" and "master profile" plates at once
	Events.change_scenes = false
	JobRun.start({"id": "job.test_plain", "family": "pin_tumbler", "tier": 1})
	Events.lock_event.emit({"kind": &"set", "tick": 10})
	Events.lock_event.emit({"kind": &"drop", "tick": 20})
	Events.lock_event.emit({"kind": &"open", "tick": 30})
	Events.lock_opened.emit()
	var got: Array = Achievements.unlocked_ids()
	assert_true(got.has("achievement.first_set"))
	assert_true(got.has("achievement.after_drop"), "a drop, then open, no break")
	for id in ["achievement.first_dark", "achievement.dark_clean", "achievement.hard_clean", "achievement.pin_master",
			"achievement.clean_receipt", "achievement.first_open", "achievement.false_note", "achievement.wafer_clean"]:
		assert_false(got.has(id), "%s must not come with a plain tier 1 job that had a drop" % id)


func test_count_conditions_and_the_reset_between_locks() -> void:
	Events.change_scenes = false
	JobRun.start({"id": "job.test_a", "family": "pin_tumbler", "tier": 3})
	Events.lock_event.emit({"kind": &"false_set", "tick": 5})
	Events.lock_event.emit({"kind": &"open", "tick": 9})
	Events.lock_opened.emit()
	assert_true(Achievements.is_unlocked("achievement.false_note"), "count(false_set)>=1")
	assert_false(Achievements.is_unlocked("achievement.pin_plain"), "count(false_set)=0 is not met")
	assert_true(Achievements.is_unlocked("achievement.clean_receipt"), "no drop, no break")
	# the next lock starts from zero: a clean tier 3 open now earns the plain one
	JobRun.start({"id": "job.test_b", "family": "pin_tumbler", "tier": 3})
	Events.lock_event.emit({"kind": &"open", "tick": 4})
	Events.lock_opened.emit()
	assert_true(Achievements.is_unlocked("achievement.pin_plain"))


func test_a_lock_left_half_way_does_not_leak_its_events() -> void:
	Events.change_scenes = false
	JobRun.start({"id": "job.test_a", "family": "warded", "tier": 1})
	Events.lock_event.emit({"kind": &"drop", "tick": 400})
	# left through the pause; the next lock's ticks start again
	JobRun.start({"id": "job.test_b", "family": "warded", "tier": 1})
	Events.lock_event.emit({"kind": &"contact", "tick": 3})
	Events.lock_event.emit({"kind": &"open", "tick": 8})
	Events.lock_opened.emit()
	assert_true(Achievements.is_unlocked("achievement.iron_no_drop"), "the drop belonged to the lock before")


func test_sub_events_count_under_their_family_name() -> void:
	Events.change_scenes = false
	JobRun.start({"id": "job.test_w", "family": "egyptian", "tier": 1})  # data says wooden_pin: the lockcore module name
	Events.lock_event.emit({"kind": &"stress", "feel": "wood.creak", "tick": 2})
	Events.lock_event.emit({"kind": &"open", "tick": 8})
	Events.lock_opened.emit()
	assert_true(Achievements.is_unlocked("achievement.wooden_creak"))


func test_tutorial_set_is_not_the_first_click() -> void:
	JobRun.start_tutorial(0)
	Events.lock_event.emit({"kind": &"set", "tick": 1})
	assert_false(Achievements.is_unlocked("achievement.first_set"))
	JobRun.current_job = {}


func test_the_day_is_stored_with_the_achievement() -> void:
	Achievements.unlock("achievement.first_set")
	assert_eq(Achievements.unlocked_on("achievement.first_set"), Time.get_date_string_from_system())
	assert_eq(Achievements.unlocked_on("achievement.first_open"), "")
	I18n.apply_language("pl")
	assert_eq(AchievementShelf.format_date("2026-11-05"), "05.11.2026")
	assert_eq(AchievementShelf.format_date(""), "")
	# earned before D-133: no day on record, the card says "earned" without inventing one
	Save.data["achievements"] = ["achievement.first_open"]
	assert_eq(AchievementShelf.status_text(_def("achievement.first_open")), I18n.t(&"ach.earned"))


# ------------------------------------------------------------------ shelf
func test_shelf_tab_shows_a_spot_for_every_listed_achievement() -> void:
	_earn(["achievement.first_set", "achievement.clock_repaired"])
	var scene := await _open("res://scenes/showcase.tscn", PORTRAIT)
	assert_true(scene.get_node("Frame/VBox/Scroll").visible, "the exhibits come first")
	assert_false(scene.get_node("Frame/VBox/ShelfScroll").visible)
	scene.show_tab("shelf")
	await get_tree().process_frame
	await get_tree().process_frame
	assert_false(scene.get_node("Frame/VBox/Scroll").visible)
	assert_true(scene.get_node("Frame/VBox/ShelfScroll").visible)
	var shelf: AchievementShelf = scene.shelf
	assert_eq(shelf.spots.size(), Achievements.shelf_defs().size())
	var earned := 0
	for s in shelf.spots:
		assert_gte(s.size.y, 48.0, "%s: touch target height" % s.name)
		assert_gte(s.size.x, 48.0, "%s: touch target width" % s.name)
		if s.earned:
			earned += 1
			assert_not_null(s.get_node_or_null("Plate"), "%s: an earned spot holds a plate" % s.name)
			assert_null(s.get_node_or_null("Empty"))
		else:
			assert_not_null(s.get_node_or_null("Empty"), "%s: an open spot is an empty place (shape, not hue)" % s.name)
			assert_null(s.get_node_or_null("Plate"))
	assert_eq(earned, 2)
	for tab in ["Tab_exhibits", "Tab_shelf"]:
		assert_gte(scene.get_node("Frame/VBox/Tabs/" + tab).size.y, 48.0)


func test_hidden_achievement_gives_nothing_away_until_earned() -> void:
	for lang: String in ["pl", "en"]:
		I18n.apply_language(lang)
		var d := _def("achievement.hard_clean")
		assert_true(bool(d["hidden"]))
		var real_name := I18n.t(&"ach.achievement.hard_clean.name")
		var real_desc := I18n.t(&"ach.achievement.hard_clean.desc")
		_earn([])
		var scene := await _open("res://scenes/showcase.tscn", PORTRAIT)
		var spot: Control = scene.shelf.spot_for("achievement.hard_clean")
		assert_eq(spot.get_node("Name").text, I18n.t(&"ach.hidden.name"))
		assert_eq(spot.get_node("Empty").mark, "?")
		var spoken := UiA11y.spoken_name(spot)
		assert_false(spoken.contains(real_name), "%s: the screen reader does not spoil it" % lang)
		assert_false(spoken.contains(real_desc))
		scene.show_detail("achievement.hard_clean")
		assert_eq(scene.card.name_label.text, I18n.t(&"ach.hidden.name"))
		assert_eq(scene.card.desc_label.text, I18n.t(&"ach.hidden.desc"))
		scene.get_parent().queue_free()
		_earn(["achievement.hard_clean"])
		scene = await _open("res://scenes/showcase.tscn", PORTRAIT)
		assert_eq(scene.shelf.spot_for("achievement.hard_clean").get_node("Name").text, real_name)
		scene.get_parent().queue_free()
		await get_tree().process_frame


func test_screen_reader_names_say_name_state_and_hint() -> void:
	I18n.apply_language("pl")
	_earn(["achievement.first_set"], "2026-11-15")
	var scene := await _open("res://scenes/showcase.tscn", PORTRAIT)
	var got := UiA11y.spoken_name(scene.shelf.spot_for("achievement.first_set"))
	assert_eq(got, "Pierwszy klik. Zdobyte 15.11.2026")
	var open_one := UiA11y.spoken_name(scene.shelf.spot_for("achievement.false_note"))
	assert_true(open_one.begins_with(I18n.t(&"ach.achievement.false_note.name")))
	assert_true(open_one.contains(I18n.t(&"ach.not_earned")))
	assert_true(open_one.contains(I18n.t(&"ach.achievement.false_note.desc")), "an open spot reads how to earn it")
	for s in scene.shelf.spots:
		assert_ne(UiA11y.spoken_name(s).strip_edges(), "", "%s has a spoken name" % s.name)
		assert_eq(s.focus_mode, Control.FOCUS_ALL)


func test_tap_opens_the_card_and_back_closes_it() -> void:
	I18n.apply_language("en")
	_earn(["achievement.first_set"], "2026-11-15")
	var scene := await _open("res://scenes/showcase.tscn", PORTRAIT)
	scene.show_tab("shelf")
	await get_tree().process_frame
	var card: AchievementShelf.Card = scene.card
	assert_false(card.visible)
	assert_false(scene.go_back(), "nothing to close: Back leaves the screen")
	scene.shelf.spot_for("achievement.first_set").pressed.emit()
	assert_true(card.visible)
	assert_eq(card.name_label.text, "The First Click")
	assert_eq(card.desc_label.text, I18n.t(&"ach.achievement.first_set.desc"))
	assert_eq(card.status_label.text, "Earned on 2026-11-15")
	assert_eq(card.category_label.text, I18n.t(&"ach.cat.craft"))
	assert_gte(card.close_button.custom_minimum_size.y, 48.0)
	assert_true(scene.go_back(), "Back closes the card first")
	assert_false(card.visible)
	scene.shelf.spot_for("achievement.false_note").pressed.emit()
	assert_eq(card.status_label.text, "Not earned yet")
	card.close_button.pressed.emit()
	assert_false(card.visible)


func test_card_fits_the_window_at_text_200_in_both_orientations() -> void:
	I18n.apply_language("de")
	_text_scale(2.0)
	_earn(["achievement.after_drop"])
	for size: Vector2i in [PORTRAIT, LANDSCAPE]:
		var scene := await _open("res://scenes/showcase.tscn", size)
		scene.show_detail("achievement.after_drop")
		for i in 6:
			await get_tree().process_frame
		var win := Rect2(Vector2.ZERO, Vector2(size)).grow(0.5)
		var panel: Control = scene.card.get_node("Frame").find_child("Panel", true, false)
		assert_true(win.encloses(panel.get_global_rect()), "%s: the card is inside the window (%s)" % [size, panel.get_global_rect()])
		assert_true(win.encloses(scene.card.close_button.get_global_rect()), "%s: Close is reachable" % size)
		for l: Label in [scene.card.name_label, scene.card.desc_label, scene.card.status_label]:
			assert_eq(l.get_visible_line_count(), l.get_line_count(), "%s: %s is not cut" % [size, l.name])
		scene.get_parent().queue_free()
		await get_tree().process_frame


func test_plate_letter_skips_a_leading_article() -> void:
	assert_eq(AchievementShelf.initial_of("The First Click"), "F")
	assert_eq(AchievementShelf.initial_of("A Door Opens"), "D")
	assert_eq(AchievementShelf.initial_of("Eine Tür geht auf"), "T")
	assert_eq(AchievementShelf.initial_of("L'école des goupilles"), "É")
	assert_eq(AchievementShelf.initial_of("Pierwszy klik"), "P")
	assert_eq(AchievementShelf.initial_of("La"), "L", "a name that is one word keeps it")
	assert_eq(AchievementShelf.initial_of("51 godzin"), "5")
	I18n.apply_language("en")
	_earn(["achievement.first_set"])
	var p := AchievementShelf.plate(_def("achievement.first_set"), 56.0)
	assert_eq((p.get_node("Initial") as Label).text, "F")
	p.free()


func test_columns_follow_width_and_text_scale() -> void:
	assert_eq(AchievementShelf.columns_for(352.0, 1.0), 2, "phone portrait")
	assert_eq(AchievementShelf.columns_for(300.0, 1.0), 1, "360 dp phone minus margins still shows whole names")
	assert_eq(AchievementShelf.columns_for(612.0, 1.0), 3, "landscape column")
	assert_eq(AchievementShelf.columns_for(352.0, 2.0), 1, "text 200 %")
	assert_eq(AchievementShelf.columns_for(612.0, 2.0), 2)
	assert_eq(AchievementShelf.columns_for(612.0, 1.5), 2)


func test_names_are_never_cut_on_the_shelf() -> void:
	for lang: String in ["pl", "de"]:
		I18n.apply_language(lang)
		for setup: Array in [[PORTRAIT, 1.0], [PORTRAIT, 2.0], [LANDSCAPE, 1.0], [LANDSCAPE, 2.0], [Vector2i(360, 800), 1.0]]:
			_text_scale(setup[1])
			_earn(["achievement.first_set", "achievement.after_overset", "achievement.clock_repaired"])
			var scene := await _open("res://scenes/showcase.tscn", setup[0])
			scene.show_tab("shelf")
			for i in 4:
				await get_tree().process_frame
			var tag := "%s %s %s" % [lang, setup[0], setup[1]]
			var list: Control = scene.get_node("Frame/VBox/ShelfScroll")
			for s in scene.shelf.spots:
				var l: Label = s.get_node("Name")
				assert_eq(l.get_visible_line_count(), l.get_line_count(), "%s: %s not cut" % [tag, s.name])
				assert_lte(s.get_global_rect().end.x, list.get_global_rect().end.x + 0.5, "%s: %s inside the column" % [tag, s.name])
			scene.get_parent().queue_free()
			await get_tree().process_frame


# ------------------------------------------------------------------ VQA-18: one cream button style
func test_enamel_photo_plates_only_in_the_lock_pause() -> void:
	# the coloured G17 plates (EnamelButton) belong to the lock pause; everything else is the theme's
	# cream plate
	for path in ["res://scenes/control_choice.tscn", "res://scenes/showcase.tscn", "res://scenes/settings.tscn",
			"res://scenes/workshop.tscn", "res://scenes/jobs_list.tscn", "res://scenes/tutorial.tscn"]:
		var scene := await _open(path, PORTRAIT)
		for n in scene.find_children("*", "Button", true, false):
			assert_false(n is EnamelButton, "%s: %s is a photo plate outside the pause" % [path, n.get_path()])
		scene.get_parent().queue_free()
		await get_tree().process_frame
	for f in DirAccess.get_files_at("res://scenes"):
		if f.ends_with(".tscn"):
			assert_false(FileAccess.get_file_as_string("res://scenes/" + f).contains("enamel_button.gd"), "%s uses EnamelButton" % f)
	assert_false(EnamelButton.PLATES.has(&"ivory"), "the cream-with-rust plate is gone from the button plates")


func test_control_choice_continue_is_the_theme_plate() -> void:
	var scene := await _open("res://scenes/control_choice.tscn", PORTRAIT)
	var b: Button = scene.get_node("Frame/VBox/ContinueButton")
	var theme_plate := scene.get_theme_stylebox(&"normal", &"Button")
	assert_eq(b.get_theme_stylebox(&"normal"), theme_plate, "the same stylebox as every other button")
	assert_false(b.has_theme_stylebox_override(&"normal"))
	assert_gte(b.size.y, 48.0)
	assert_eq(b.get_theme_color(&"font_color"), scene.get_theme_color(&"font_color", &"Button"))


# ------------------------------------------------------------------ flaky test of D-130 / D-131
func test_main_menu_outside_the_tree_ignores_language_changes() -> void:
	var menu: Control = load("res://scenes/main_menu.tscn").instantiate()
	add_child(menu)
	await get_tree().process_frame
	assert_true(I18n.language_changed.is_connected(menu._refresh))
	remove_child(menu)
	assert_false(I18n.language_changed.is_connected(menu._refresh), "an orphaned menu no longer listens")
	I18n.language_changed.emit()
	menu._relayout()  # and a stray call does not reach the viewport
	assert_engine_error_count(0)
	add_child(menu)
	assert_true(I18n.language_changed.is_connected(menu._refresh), "back in the tree it listens again")
	menu.free()
