class_name Furnishings
extends RefCounted
## D-71: cosmetic workshop furnishings bought with career coins. No effect on play.
## Data: game/data/furnishings.json (id, price, chapter, i18n name/desc, layer, z).
## Save: furnishings/<id>/owned (bool), furnishings/<id>/shown (bool, default true once owned).
## Picture: the Blender workshop render (base) with one full-frame transparent overlay per item,
## stacked by z (art/blender/workshop.py --layers + art/blender/workshop_layers.py), so the layers line up
## with the base at any size as long as every TextureRect uses the same rect and stretch mode.

const PATH := "res://data/furnishings.json"

static var _data: Dictionary = {}
static var _job_chapter: Dictionary = {}


static func data() -> Dictionary:
	if _data.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		_data = parsed if typeof(parsed) == TYPE_DICTIONARY else {"furnishings": []}
	return _data


static func all() -> Array:
	return data().get("furnishings", [])


static func by_id(id: String) -> Dictionary:
	for f in all():
		if f.get("id", "") == id:
			return f
	return {}


static func owned(id: String) -> bool:
	return bool(Save.get_value("furnishings/%s/owned" % id, false))


static func shown(id: String) -> bool:
	return owned(id) and bool(Save.get_value("furnishings/%s/shown" % id, true))


## Highest chapter the player has reached: any completed or refused job of that chapter
## (or the "chapter" save key used by dev saves). At least 1.
static func reached_chapter() -> int:
	if _job_chapter.is_empty():
		# D-112: jobs of content packs count too, also when the pack is not on the phone (stubs):
		# removing a pack does not take the reached chapter back
		for j: Dictionary in JobRun.all_jobs() + ContentPacks.stubs():
			_job_chapter[j.get("id", "")] = int(j.get("chapter", 1))
	var ch := maxi(1, int(Save.get_value("chapter", 1)))
	for jid in Save.get_value("jobs_completed", []) + Save.get_value("jobs_refused", []):
		ch = maxi(ch, int(_job_chapter.get(jid, 1)))
	return ch


## D-112: a content pack came or went; the job -> chapter map is built again on the next use.
static func forget_jobs() -> void:
	_job_chapter = {}


static func unlocked(f: Dictionary) -> bool:
	return reached_chapter() >= int(f.get("chapter", 1))


## Buys one item: needs the chapter and the coins. Returns true when bought.
static func buy(id: String) -> bool:
	var f := by_id(id)
	if f.is_empty() or owned(id) or not unlocked(f):
		return false
	var price := int(f.get("price", 0))
	var coins: int = Save.get_value("coins", 0)
	if coins < price:
		return false
	Save.set_value("coins", coins - price)
	Save.set_value("furnishings/%s/shown" % id, true)
	Save.set_value("furnishings/%s/owned" % id, true)
	return true


static func set_shown(id: String, on: bool) -> void:
	if owned(id):
		Save.set_value("furnishings/%s/shown" % id, on)


static func layer_path(file: String) -> String:
	return "%s/%s" % [data().get("layer_dir", "res://assets/ui/workshop"), file]


static func has_picture() -> bool:
	return ResourceLoader.exists(layer_path(data().get("base", "")))


## The workshop picture: base render + every overlay (hidden unless shown). Full-rect children,
## all with the same stretch mode, so the overlays stay aligned. Call refresh() after Save changes.
static func build_scene(stretch: TextureRect.StretchMode) -> Control:
	var root := Control.new()
	root.name = "WorkshopPicture"
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(_layer("Base", data().get("base", ""), stretch))
	var items := all().duplicate()
	items.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("z", 20)) < int(b.get("z", 20)) or (int(a.get("z", 20)) == int(b.get("z", 20)) and String(a["id"]) < String(b["id"])))
	for f in items:
		var t := _layer("Layer_" + String(f["id"]), f.get("layer", ""), stretch, false)
		t.visible = false
		root.add_child(t)
	refresh(root, false)
	return root


## Perf pass 2026-11-08: an overlay is a full-frame RGBA picture (14 MB of video memory each at
## 1440x2560), so only shown overlays hold a texture; refresh() loads it when the item is shown and
## drops it when it is put away. Loading all 10 hidden overlays cost ~370 MB and >1 s on a budget phone.
static func _layer(node_name: String, file: String, stretch: TextureRect.StretchMode, load_now := true) -> TextureRect:
	var t := TextureRect.new()
	t.name = node_name
	var path := layer_path(file)
	if file != "" and ResourceLoader.exists(path):
		t.set_meta(&"layer_path", path)
		if load_now:
			t.texture = load(path)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = stretch
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.set_anchors_preset(Control.PRESET_FULL_RECT)
	return t


## Shows the overlays of owned, placed items; a newly shown one fades in (200 ms, not with reduce motion).
static func refresh(root: Control, animate := true) -> void:
	for f in all():
		var t: TextureRect = root.get_node_or_null("Layer_" + String(f["id"]))
		if t == null:
			continue
		var on := shown(String(f["id"]))
		if on and t.texture == null and t.has_meta(&"layer_path"):
			t.texture = load(String(t.get_meta(&"layer_path")))
		elif not on and t.texture != null:
			t.texture = null
		if on and not t.visible and animate and not UiA11y.reduce_motion() and t.is_inside_tree():
			t.modulate.a = 0.0
			t.create_tween().tween_property(t, "modulate:a", 1.0, 0.2).set_trans(Tween.TRANS_SINE)
		t.visible = on
