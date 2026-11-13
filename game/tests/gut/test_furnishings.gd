extends GutTest
## D-71: cosmetic workshop furnishings — data, buying, Save persistence, overlays in the workshop picture,
## not enough coins, chapter lock, and the Wyposażenie tab rows (>= 48 dp, no sideways scroll).

var _save_backup: Dictionary


func before_each() -> void:
	_save_backup = Save.data.duplicate(true)
	Save.data = Save.DEFAULTS.duplicate(true)
	Save.data["jobs_completed"] = []


func after_each() -> void:
	Save.data = _save_backup
	Save.save()


func _cheapest() -> Dictionary:
	var best: Dictionary = {}
	for f in Furnishings.all():
		if int(f["chapter"]) == 1 and (best.is_empty() or int(f["price"]) < int(best["price"])):
			best = f
	return best


func test_data_is_complete() -> void:
	var items := Furnishings.all()
	assert_between(items.size(), 8, 12, "8-12 furnishings (D-71)")
	var ids := {}
	for f in items:
		for k in ["id", "price", "chapter", "i18n", "desc", "layer", "z"]:
			assert_true(f.has(k), "%s has %s" % [f.get("id"), k])
		assert_false(ids.has(f["id"]), "unique id %s" % f["id"])
		ids[f["id"]] = true
		assert_gt(int(f["price"]), 0)
		assert_true(I18n.has_key(StringName(f["i18n"])) and I18n.has_key(StringName(f["desc"])), "texts for %s" % f["id"])
		assert_true(ResourceLoader.exists(Furnishings.layer_path(f["layer"])), "overlay for %s" % f["id"])
	assert_true(Furnishings.has_picture(), "base render in the build")


func test_buy_spends_coins_and_persists() -> void:
	var f := _cheapest()
	var id: String = f["id"]
	Save.set_value("coins", int(f["price"]) + 7)
	assert_true(Furnishings.buy(id))
	assert_eq(Save.get_value("coins"), 7)
	assert_true(Furnishings.owned(id) and Furnishings.shown(id))
	assert_false(Furnishings.buy(id), "cannot buy twice")
	assert_eq(Save.get_value("coins"), 7)
	# persistence: reload the file written by Save
	Save.load_save()
	assert_true(Furnishings.owned(id), "owned after reload")
	assert_eq(Save.get_value("coins"), 7)
	Furnishings.set_shown(id, false)
	Save.load_save()
	assert_true(Furnishings.owned(id))
	assert_false(Furnishings.shown(id), "put away survives a reload")


func test_insufficient_coins() -> void:
	var f := _cheapest()
	Save.set_value("coins", int(f["price"]) - 1)
	assert_false(Furnishings.buy(f["id"]))
	assert_false(Furnishings.owned(f["id"]))
	assert_eq(Save.get_value("coins"), int(f["price"]) - 1, "no coins taken")


func test_chapter_lock() -> void:
	var late: Dictionary = {}
	for f in Furnishings.all():
		if int(f["chapter"]) > 1:
			late = f
	Save.set_value("coins", 99999)
	assert_false(Furnishings.unlocked(late))
	assert_false(Furnishings.buy(late["id"]), "locked until its chapter")
	# a completed job of that chapter unlocks it
	var jid := ""
	for j: Dictionary in JobRun.all_jobs():
		if int(j.get("chapter", 0)) == int(late["chapter"]):
			jid = j["id"]
	assert_ne(jid, "")
	Save.set_value("jobs_completed", [jid])
	assert_true(Furnishings.unlocked(late))
	assert_true(Furnishings.buy(late["id"]))


func test_overlay_shown_in_picture() -> void:
	var f := _cheapest()
	var pic := Furnishings.build_scene(TextureRect.STRETCH_KEEP_ASPECT_COVERED)
	add_child_autofree(pic)
	var layer: TextureRect = pic.get_node("Layer_" + String(f["id"]))
	assert_null(layer.texture, "perf 2026-11-08: a hidden overlay holds no texture")
	assert_false(layer.visible, "hidden before buying")
	Save.set_value("coins", int(f["price"]))
	Furnishings.buy(f["id"])
	Furnishings.refresh(pic, false)
	assert_true(layer.visible, "overlay shown once bought")
	var base: TextureRect = pic.get_node("Base")
	assert_eq(layer.stretch_mode, base.stretch_mode, "same stretch as the base -> aligned")
	assert_eq(layer.texture.get_size(), base.texture.get_size(), "full-frame overlay")
	Furnishings.set_shown(f["id"], false)
	Furnishings.refresh(pic, false)
	assert_false(layer.visible, "put away hides it")
	assert_null(layer.texture, "put away releases the full-frame texture")


func test_only_shown_overlays_are_loaded() -> void:
	# perf 2026-11-08: a new save loads just the base picture, not the 10 hidden full-frame overlays
	var pic := Furnishings.build_scene(TextureRect.STRETCH_KEEP_ASPECT_COVERED)
	add_child_autofree(pic)
	var loaded := 0
	for c in pic.get_children():
		if (c as TextureRect).texture != null:
			loaded += 1
	assert_eq(loaded, 1, "only the base render")


func test_workshop_tab_and_backdrop() -> void:
	var f := _cheapest()
	Save.set_value("coins", int(f["price"]) + 10)
	var vp := SubViewport.new()
	vp.size = Vector2i(412, 915)
	vp.disable_3d = true
	add_child_autofree(vp)
	var ws: Control = load("res://scenes/workshop.tscn").instantiate()
	vp.add_child(ws)
	await get_tree().process_frame
	ws.show_tab("furnishings")
	await get_tree().process_frame
	await get_tree().process_frame
	var list: Control = ws.get_node("Frame/VBox/Scroll/ToolsList")
	assert_not_null(list.get_node_or_null("Preview"), "picture of the workshop above the rows")
	var card: Control = list.get_node("Furn_" + String(f["id"]))
	var buy: Button = card.find_child("Action", true, false)
	assert_true(buy.visible and not buy.disabled)
	assert_gte(buy.size.y, 48.0, "touch target")
	for tab in [ws.get_node("Frame/VBox/Tabs/TabTools"), ws.get_node("Frame/VBox/Tabs/TabFurnishings")]:
		assert_gte((tab as Control).size.y, 48.0)
	buy.pressed.emit()
	await get_tree().process_frame
	assert_true(Furnishings.owned(f["id"]))
	assert_eq(Save.get_value("coins"), 10)
	var backdrop: Control = ws.find_child("BackdropPicture", true, false)
	assert_not_null(backdrop)
	assert_true((backdrop.get_node("Layer_" + String(f["id"])) as Control).visible, "backdrop shows the bought item")
	# a row that cannot be afforded reads "Not enough coins" and is disabled
	var dear: Dictionary = {}
	for x in Furnishings.all():
		if int(x["chapter"]) == 1 and x["id"] != f["id"]:
			dear = x
	var row: Control = list.get_node("Furn_" + String(dear["id"]))
	var b: Button = row.find_child("Action", true, false)
	assert_true(b.disabled)
	assert_eq(b.text, I18n.t(&"workshop.not_enough"))
	assert_lte(ws.get_combined_minimum_size().x, 412.0, "no sideways scroll")


func test_every_chapter_gate_has_jobs() -> void:
	# D-124: an item gated by a chapter without jobs (base game or a content pack) could never be bought
	var chapters := {}
	for j: Dictionary in JobRun.all_jobs() + ContentPacks.stubs():
		chapters[int(j.get("chapter", 0))] = true
	for f in Furnishings.all():
		assert_true(chapters.has(int(f["chapter"])), "%s: chapter %d has jobs" % [f["id"], int(f["chapter"])])
