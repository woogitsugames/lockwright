extends GutTest
## D-62: the main menu is the rendered felt letter board (art/blender/menu_compose.py).
## - touch zones sit exactly over the rendered bands (menu_layout.json) in portrait, landscape
##   and on a Fold, every zone >= 48 dp, inside the screen, no overlaps, focus rect fully shown;
## - a real tap hits the right zone; every zone navigates where the old buttons did;
## - the pressed sprite is drawn for the press and hidden afterwards;
## - the board image follows the UI language (PL fallback); zones have i18n accessible names.

const MAIN_MENU := "res://scenes/main_menu.tscn"
const IDS := [&"start", &"jobs", &"workshop", &"showcase", &"settings", &"about"]
const NAMES := {
	&"start": &"menu.play", &"jobs": &"menu.jobs", &"workshop": &"menu.workshop",
	&"showcase": &"menu.showcase", &"settings": &"menu.settings", &"about": &"menu.about",
}
## Window sizes in px (the Fold inner screen in both orientations), converted to dp like DpScale.
const WINDOWS := [Vector2i(412, 915), Vector2i(915, 412), Vector2i(1916, 2160), Vector2i(2160, 1916), Vector2i(1080, 2400), Vector2i(360, 800)]

var _lang := ""
var _settings := {}


func before_all() -> void:
	_lang = I18n.current_language()
	for k in [&"control_chosen"]:
		_settings[k] = Settings.get_value(k, null)


func after_each() -> void:
	I18n.apply_language(_lang)
	for k in _settings:
		if _settings[k] != null:
			Settings.set_value(k, _settings[k])


static func dp_size(win: Vector2i) -> Vector2:
	var base := DpScale.base_for(win)
	var s := minf(float(win.x) / base.x, float(win.y) / base.y)
	return Vector2(win) / s


func _open(size: Vector2) -> Control:
	var vp := SubViewport.new()
	vp.size = Vector2i(roundi(size.x), roundi(size.y))
	vp.disable_3d = true
	add_child_autofree(vp)
	var menu: Control = load(MAIN_MENU).instantiate()
	menu.change_scenes = false
	vp.add_child(menu)
	for i in 3:
		await get_tree().process_frame
	return menu


func test_layout_file_is_complete() -> void:
	var l: Dictionary = (load("res://scripts/ui/main_menu.gd") as GDScript).load_layout()
	assert_true(l.has("orients") and l["orients"].has("portrait") and l["orients"].has("landscape"))
	assert_true(l["langs"].has("pl"), "PL render (fallback) exported")
	for o in ["portrait", "landscape"]:
		var ids := []
		for it in l["orients"][o]["items"]:
			ids.append(StringName(it["id"]))
			assert_true(it.has("hit_rect") and it.has("sprite_rect"), "%s %s rects" % [o, it["id"]])
		assert_eq(ids, IDS, o + ": every menu item, in reading order")
		for lang in l["langs"]:
			assert_true(ResourceLoader.exists("res://assets/ui/menu/menu_%s_%s.webp" % [o, lang]), "%s %s board" % [o, lang])
			for id in IDS:
				assert_true(ResourceLoader.exists("res://assets/ui/menu/menu_pressed_%s_%s_%s.webp" % [id, o, lang]),
					"%s %s %s pressed sprite" % [o, lang, id])


func test_zones_map_onto_the_rendered_bands() -> void:
	var script: GDScript = load("res://scripts/ui/main_menu.gd")
	var layout: Dictionary = script.load_layout()
	for win in WINDOWS:
		var menu := await _open(dp_size(win))
		var size: Vector2 = menu.get_viewport_rect().size  # SubViewport sizes are whole dp
		var tag := "%dx%d px (%.0fx%.0f dp)" % [win.x, win.y, size.x, size.y]
		var o := "landscape" if size.x > size.y else "portrait"
		assert_eq(menu.orient, o, tag + ": orientation asset")
		var od: Dictionary = layout["orients"][o]
		var img := Vector2(od["size"][0], od["size"][1])
		# independent check of the fit: cover-fit unless the focus would not fit the screen
		var cover := maxf(size.x / img.x, size.y / img.y)
		var focus: Rect2 = script.rect_of(od["focus_rect"])
		assert_lte(menu.image_scale, cover + 1e-4, tag + ": never larger than cover")
		var f: Rect2 = menu.to_screen(focus)
		assert_true(f.position.x >= -0.5 and f.position.y >= -0.5 and f.end.x <= size.x + 0.5 and f.end.y <= size.y + 0.5,
			"%s: title + menu fully on screen (%s)" % [tag, f])
		var safe: Rect2 = SafeArea.shrink(menu, Rect2(Vector2.ZERO, size)).grow(-menu.FOCUS_PAD)
		assert_true(safe.grow(0.5).encloses(f), "%s: title + menu inside the safe area - %.0f dp (%s in %s)" % [tag, menu.FOCUS_PAD, f, safe])
		if focus.size.y * cover <= size.y - 16.0 and focus.size.x * cover <= size.x - 16.0:
			assert_almost_eq(menu.image_scale, cover, 1e-4, tag + ": cover-fit when the focus fits")
			assert_true(menu.image_rect.encloses(Rect2(Vector2.ZERO, size).grow(-0.5)), tag + ": image covers the screen")
		var prev := Rect2()
		for it in od["items"]:
			var b: Button = menu.zone(StringName(it["id"]))
			var want: Rect2 = Rect2(menu.image_rect.position + script.rect_of(it["hit_rect"]).position * menu.image_scale,
				script.rect_of(it["hit_rect"]).size * menu.image_scale).intersection(Rect2(Vector2.ZERO, size))
			var got := b.get_global_rect()
			assert_almost_eq(got.position, want.position, Vector2(0.6, 0.6), "%s %s: zone position" % [tag, it["id"]])
			assert_almost_eq(got.size, want.size, Vector2(0.6, 0.6), "%s %s: zone size" % [tag, it["id"]])
			assert_gte(got.size.y, 48.0, "%s %s: zone >= 48 dp high (%.1f)" % [tag, it["id"], got.size.y])
			assert_gte(got.size.x, 48.0, "%s %s: zone >= 48 dp wide" % [tag, it["id"]])
			assert_true(got.position.x >= -0.5 and got.end.x <= size.x + 0.5 and got.position.y >= -0.5 and got.end.y <= size.y + 0.5,
				"%s %s: zone on screen" % [tag, it["id"]])
			if prev.size.x > 0.0:
				assert_lte(prev.intersection(got).get_area(), 1.0, "%s %s: zones do not overlap" % [tag, it["id"]])
			prev = got
		menu.get_parent().queue_free()
		await get_tree().process_frame


## D-66: the portrait finals are the wide (~75%) frame, not the close v2 camera (board 96% of the width).
func test_layout_is_the_75_percent_gpu_frame() -> void:
	var l: Dictionary = (load("res://scripts/ui/main_menu.gd") as GDScript).load_layout()
	var p: Dictionary = l["orients"]["portrait"]
	var frac: float = float(p["board_rect"][2]) / float(p["size"][0])
	assert_between(frac, 0.70, 0.80, "portrait board ~75%% of the image width (%.3f)" % frac)
	assert_eq(float(p["view"]["vw"]), 600.0, "portrait hits from the --vw 600 camera of the renders")
	assert_true(l["orients"]["landscape"].has("view"), "landscape camera recorded")


## Real phones have notches / gesture bars (headless = no insets): with typical insets the focus
## (title + all bands) still fits inside the safe area and every zone stays >= 48 dp.
func test_fit_with_safe_area_insets() -> void:
	var script: GDScript = load("res://scripts/ui/main_menu.gd")
	var layout: Dictionary = script.load_layout()
	for win in WINDOWS:
		var size := dp_size(win)
		var o := "landscape" if size.x > size.y else "portrait"
		var od: Dictionary = layout["orients"][o]
		var img := Vector2(od["size"][0], od["size"][1])
		# left, top, right, bottom (dp): portrait = notch + gesture bar, landscape = notch on a side + bar
		var ins := Vector4(0, 48, 0, 34) if o == "portrait" else Vector4(48, 0, 48, 21)
		var full := Rect2(Vector2.ZERO, size)
		var safe := Rect2(full.position + Vector2(ins.x, ins.y), full.size - Vector2(ins.x + ins.z, ins.y + ins.w)).grow(-8.0)
		var r: Rect2 = script.fit_rect(img, script.rect_of(od["focus_rect"]), size, safe)
		var k := r.size.x / img.x
		var f := Rect2(r.position + script.rect_of(od["focus_rect"]).position * k, script.rect_of(od["focus_rect"]).size * k)
		var tag := "%dx%d px, insets %s" % [win.x, win.y, ins]
		assert_true(safe.grow(0.5).encloses(f), "%s: focus %s inside safe %s" % [tag, f, safe])
		for it in od["items"]:
			var h: Rect2 = script.rect_of(it["hit_rect"])
			var z := Rect2(r.position + h.position * k, h.size * k).intersection(full)
			assert_gte(minf(z.size.x, z.size.y), 48.0, "%s %s: zone >= 48 dp (%s)" % [tag, it["id"], z.size])


func _click(vp: SubViewport, at: Vector2) -> void:
	for pressed in [true, false]:
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.pressed = pressed
		e.position = at
		e.global_position = at
		vp.push_input(e, true)
		await get_tree().process_frame


func test_tap_navigates() -> void:
	Settings.set_value(&"control_chosen", false)
	var want := {
		&"start": "res://scenes/control_choice.tscn", &"jobs": "res://scenes/jobs_list.tscn",
		&"workshop": "res://scenes/workshop.tscn", &"showcase": "res://scenes/showcase.tscn",
		&"settings": "res://scenes/settings.tscn",
	}
	for size in [Vector2(412, 915), Vector2(915, 412)]:
		var menu := await _open(size)
		var vp: SubViewport = menu.get_parent()
		for id in IDS:
			menu.last_target = ""
			var r: Rect2 = menu.zone(id).get_global_rect()
			await _click(vp, r.get_center())  # a real tap at the middle of the rendered band
			await get_tree().create_timer(0.25).timeout
			if id == &"about":
				assert_true(menu.about_panel.visible, "%s: about opens the About sheet" % size)
				menu.about_panel.visible = false
			else:
				assert_eq(menu.last_target, want[id], "%s: tap on %s" % [size, id])
		menu.get_parent().queue_free()
		await get_tree().process_frame


func test_pressed_sprite_shows_then_hides() -> void:
	var menu := await _open(Vector2(412, 915))
	for id in [&"jobs", &"settings"]:
		menu.zone(id).pressed.emit()
		assert_eq(menu.pressed_id, id, "pressed state on")
		assert_not_null(menu.pressed_texture, "baked sprite loaded")
		assert_eq(menu.pressed_texture.resource_path, "res://assets/ui/menu/menu_pressed_%s_portrait_%s.webp" % [id, menu.lang])
		var it: Dictionary = menu._item(id)
		var want: Rect2 = menu.to_screen(menu.rect_of(it["sprite_rect"]))
		assert_almost_eq(menu.pressed_rect.position, want.position, Vector2(0.5, 0.5), "sprite at the item's rect")
		assert_true(menu.pressed_rect.encloses(menu.zone(id).get_global_rect().grow(-0.5)), "sprite covers the band")
		await get_tree().create_timer(0.05).timeout
		assert_eq(menu.pressed_id, id, "still pressed after 50 ms")
		await get_tree().create_timer(0.2).timeout
		assert_eq(menu.pressed_id, &"", "pressed state off after the press (%d ms)" % menu.PRESS_MS)
		assert_null(menu.pressed_texture)
	assert_between(menu.PRESS_MS, 100, 150, "press 100-150 ms")


func test_language_picks_the_render() -> void:
	var script: GDScript = load("res://scripts/ui/main_menu.gd")
	assert_eq(script.pick_lang("fr_FR", ["pl", "en", "de"]), "pl", "unrendered language -> PL")
	assert_eq(script.pick_lang("de_DE", ["pl", "en", "de"]), "de")
	var menu := await _open(Vector2(412, 915))
	var langs: Array = script.load_layout()["langs"]
	for l in ["pl", "en", "de"]:
		I18n.apply_language(l)
		await get_tree().process_frame
		var want: String = l if langs.has(l) else "pl"
		assert_eq(menu.lang, want, l)
		assert_eq(menu.backdrop.texture.resource_path, "res://assets/ui/menu/menu_portrait_%s.webp" % want, l + ": board image")
		for id in IDS:
			var b: Button = menu.zone(id)
			assert_eq(b.get_meta(&"label"), I18n.t(NAMES[id]), "%s %s: accessible name" % [l, id])
			if "accessibility_name" in b:
				assert_eq(b.get("accessibility_name"), I18n.t(NAMES[id]))
	menu.get_parent().queue_free()
	await get_tree().process_frame
	menu = await _open(Vector2(915, 412))
	I18n.apply_language("en")
	await get_tree().process_frame
	assert_eq(menu.backdrop.texture.resource_path,
		"res://assets/ui/menu/menu_landscape_%s.webp" % ("en" if langs.has("en") else "pl"), "landscape EN")


func test_focus_order_is_reading_order() -> void:
	var menu := await _open(Vector2(412, 915))
	for i in IDS.size():
		var b: Button = menu.zone(IDS[i])
		assert_eq(b.focus_mode, Control.FOCUS_ALL, "%s focusable (keyboard, TalkBack)" % IDS[i])
		var next: Node = b.get_node(b.focus_next)
		assert_eq(next, menu.zone(IDS[(i + 1) % IDS.size()]), "%s -> next" % IDS[i])
	# tree order (what screen readers walk) = reading order
	var kids: Array = menu.get_node("Zones").get_children()
	for i in IDS.size():
		assert_eq(kids[i], menu.zone(IDS[i]))
