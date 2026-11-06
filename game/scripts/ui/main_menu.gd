extends Control
## Main menu v2 (D-62): the Blender render of the tenants' felt letter board IS the menu.
## - background: the rendered board for the window's orientation and the current language
##   (game/assets/ui/menu/menu_<orient>_<lang>.webp, fallback PL), cover-fitted; the "focus"
##   (title + every menu band) is never cropped and stays inside the safe area — on near-square
##   screens (Fold) the board shrinks and a dimmed copy of the photo fills the rest;
## - invisible touch zones (Buttons, >= 48 dp) over the rendered bands (menu_layout.json, from
##   art/blender/menu_compose.py), each with an accessible name from i18n, in reading order;
## - pressed state: the baked pressed sprite is drawn at the item's rect for PRESS_MS, with the
##   plate click sound (ScreenFrame.wire_sounds) and a light haptic tap, then the menu navigates.

const LAYOUT_PATH := "res://assets/ui/menu/menu_layout.json"
const MENU_DIR := "res://assets/ui/menu/"
const FALLBACK_LANG := "pl"
const PRESS_MS := 120
const FOCUS_PAD := 8.0  # dp kept free between the focus rect and the safe area
const CONTROL_CHOICE := "res://scenes/control_choice.tscn"
const RUN_LOOP := "res://scenes/run_loop.tscn"
const TUTORIAL := "res://scenes/tutorial.tscn"
const TARGETS := {
	&"jobs": "res://scenes/jobs_list.tscn",
	&"workshop": "res://scenes/workshop.tscn",
	&"showcase": "res://scenes/showcase.tscn",
	&"settings": "res://scenes/settings.tscn",
}
## zone node name -> layout id, i18n key (accessible name); order = focus / TalkBack order
const ZONES := [
	[&"PlayButton", &"start", &"menu.play"],
	[&"JobsButton", &"jobs", &"menu.jobs"],
	[&"WorkshopButton", &"workshop", &"menu.workshop"],
	[&"ShowcaseButton", &"showcase", &"menu.showcase"],
	[&"SettingsButton", &"settings", &"menu.settings"],
	[&"AboutButton", &"about", &"menu.about"],
]

## Tests: false = only record last_target instead of changing the scene.
var change_scenes := true
var last_target := ""
## Current choice (read by tests and the board drawing).
var orient := "portrait"
var lang := FALLBACK_LANG
var image_rect := Rect2()  # where the board image is drawn, canvas units
var image_scale := 1.0  # canvas units per image px
var pressed_id := &""  # item whose pressed sprite is showing
var pressed_texture: Texture2D = null
var pressed_rect := Rect2()

var _layout: Dictionary = {}
var _textures := {}  # res path -> Texture2D
var _busy := false
var _about_taps := 0

@onready var backdrop: TextureRect = $Backdrop
@onready var board: Control = $Board
@onready var zones: Control = $Zones
@onready var about_panel: PanelContainer = $AboutPanel
@onready var notice_label: Label = $AboutPanel/VBox/Scroll/Text/Notice


func _ready() -> void:
	Sfx.play_ambience(&"night_timer")
	Sfx.play_music(&"main_theme")
	_layout = load_layout()
	board.draw.connect(_draw_board)
	for z in ZONES:
		var b := zones.get_node(String(z[0])) as Button
		b.pressed.connect(_on_zone.bind(z[1]))
	_wire_focus_order()
	$AboutPanel/VBox/CloseButton.pressed.connect(func() -> void: about_panel.visible = false)
	notice_label.gui_input.connect(_on_about_input)  # 5 taps = dev flag "po premierze" (task 11)
	I18n.language_changed.connect(_refresh)
	resized.connect(_relayout)
	_refresh()
	ScreenFrame.wire_sounds(self)  # S05 plate sounds on every zone
	ScreenFrame.enter(board)


# ------------------------------------------------------------------ layout / choice


static func load_layout() -> Dictionary:
	var f := FileAccess.open(LAYOUT_PATH, FileAccess.READ)
	if f == null:
		push_error("main_menu: %s missing" % LAYOUT_PATH)
		return {}
	var d: Variant = JSON.parse_string(f.get_as_text())
	return d if d is Dictionary else {}


static func pick_orient(vp: Vector2) -> String:
	return "landscape" if vp.x > vp.y else "portrait"


## The rendered language for the UI language `cur` ("en", "de_DE", ...), PL when not rendered.
static func pick_lang(cur: String, available: Array) -> String:
	var l := cur.split("_")[0].to_lower()
	return l if available.has(l) else FALLBACK_LANG


static func rect_of(a: Array) -> Rect2:
	return Rect2(float(a[0]), float(a[1]), float(a[2]), float(a[3]))


## Where to draw an image of `img` px in a viewport `vp`: cover-fit, but the image `focus`
## rect always fits inside `safe` (smaller scale, centred, bars when it must).
static func fit_rect(img: Vector2, focus: Rect2, vp: Vector2, safe: Rect2) -> Rect2:
	var s := maxf(vp.x / img.x, vp.y / img.y)
	s = minf(s, minf(safe.size.x / focus.size.x, safe.size.y / focus.size.y))
	var size := img * s
	var pos := (vp - size) * 0.5
	var lo := safe.position - focus.position * s
	var hi := safe.end - focus.end * s
	pos.x = clampf(pos.x, lo.x, hi.x)
	pos.y = clampf(pos.y, lo.y, hi.y)
	return Rect2(pos, size)


func _orient_data() -> Dictionary:
	return _layout.get("orients", {}).get(orient, {})


func texture_path(id := &"") -> String:
	if id == &"":
		return MENU_DIR + "menu_%s_%s.webp" % [orient, lang]
	return MENU_DIR + "menu_pressed_%s_%s_%s.webp" % [id, orient, lang]


func _tex(path: String) -> Texture2D:
	if not _textures.has(path):
		_textures[path] = load(path) if ResourceLoader.exists(path) else null
	return _textures[path]


## Display rect (canvas units) of an image-px rect.
func to_screen(r: Rect2) -> Rect2:
	return Rect2(image_rect.position + r.position * image_scale, r.size * image_scale)


func _refresh() -> void:
	lang = pick_lang(I18n.current_language(), _layout.get("langs", [FALLBACK_LANG]))
	for z in ZONES:
		var b := zones.get_node(String(z[0])) as Button
		var name_text := I18n.t(z[2])
		if "accessibility_name" in b:
			b.set("accessibility_name", name_text)
		b.tooltip_text = ""
		b.set_meta(&"label", name_text)
	$AboutPanel/VBox/AboutTitle.text = I18n.t(&"about.title")
	notice_label.text = I18n.t(&"about.notice")
	$AboutPanel/VBox/Scroll/Text/Licenses.text = I18n.t(&"about.licenses")
	$AboutPanel/VBox/CloseButton.text = I18n.t(&"common.close")
	_relayout()


func _relayout() -> void:
	var vp := get_viewport_rect().size
	if vp.x <= 0.0 or vp.y <= 0.0:
		return
	orient = pick_orient(vp)
	var od := _orient_data()
	if od.is_empty():
		return
	var tex := _tex(texture_path())
	if tex == null:  # language render missing: PL
		lang = FALLBACK_LANG
		tex = _tex(texture_path())
	backdrop.texture = tex
	var img := Vector2(od["size"][0], od["size"][1])
	var safe := SafeArea.shrink(self, Rect2(Vector2.ZERO, vp)).grow(-FOCUS_PAD)
	image_rect = fit_rect(img, rect_of(od["focus_rect"]), vp, safe)
	image_scale = image_rect.size.x / img.x
	var full := Rect2(Vector2.ZERO, vp)
	for z in ZONES:
		var b := zones.get_node(String(z[0])) as Button
		var it := _item(z[1])
		var r := to_screen(rect_of(it["hit_rect"])).intersection(full) if not it.is_empty() else Rect2()
		b.position = r.position
		b.size = r.size
		b.visible = r.size.x > 0.0
	if pressed_id != &"":
		pressed_rect = to_screen(rect_of(_item(pressed_id)["sprite_rect"]))
	# preload this orientation's pressed sprites (small) so a tap never waits on a load
	for z in ZONES:
		_tex(texture_path(z[1]))
	board.queue_redraw()
	_layout_about(vp)


func _item(id: StringName) -> Dictionary:
	for it in _orient_data().get("items", []):
		if it["id"] == String(id):
			return it
	return {}


func zone(id: StringName) -> Button:
	for z in ZONES:
		if z[1] == id:
			return zones.get_node(String(z[0])) as Button
	return null


func _wire_focus_order() -> void:
	var n := ZONES.size()
	for i in n:
		var b := zones.get_node(String(ZONES[i][0])) as Button
		var prev := zones.get_node(String(ZONES[(i - 1 + n) % n][0])) as Button
		var next := zones.get_node(String(ZONES[(i + 1) % n][0])) as Button
		b.focus_previous = b.get_path_to(prev)
		b.focus_next = b.get_path_to(next)
		b.focus_neighbor_top = b.get_path_to(prev)
		b.focus_neighbor_bottom = b.get_path_to(next)


# ------------------------------------------------------------------ drawing


func _draw_board() -> void:
	var tex := backdrop.texture
	if tex == null:
		return
	board.draw_texture_rect(tex, image_rect, false)
	if pressed_texture != null:
		board.draw_texture_rect(pressed_texture, pressed_rect, false)
	# where the board does not reach the screen edge (near-square screens), soften its edge
	# into the dimmed backdrop: a 24 dp ramp to black inside the image
	var vp := board.size
	var r := image_rect
	var ramp := 24.0
	var dark := Color(0, 0, 0, 0.7)
	var clear := Color(0, 0, 0, 0)
	if r.position.x > 0.5:
		_ramp(Vector2(r.position.x, r.position.y), Vector2(0, r.size.y), Vector2(ramp, 0), dark, clear)
	if r.end.x < vp.x - 0.5:
		_ramp(Vector2(r.end.x, r.position.y), Vector2(0, r.size.y), Vector2(-ramp, 0), dark, clear)
	if r.position.y > 0.5:
		_ramp(Vector2(r.position.x, r.position.y), Vector2(r.size.x, 0), Vector2(0, ramp), dark, clear)
	if r.end.y < vp.y - 0.5:
		_ramp(Vector2(r.position.x, r.end.y), Vector2(r.size.x, 0), Vector2(0, -ramp), dark, clear)


func _ramp(o: Vector2, along: Vector2, inward: Vector2, c0: Color, c1: Color) -> void:
	board.draw_polygon(
		PackedVector2Array([o, o + along, o + along + inward, o + inward]),
		PackedColorArray([c0, c0, c1, c1]))


# ------------------------------------------------------------------ press + navigation


func _on_zone(id: StringName) -> void:
	if _busy:
		return
	_busy = true
	show_pressed(id)
	Haptics.play(&"contact", 0.6, &"brass")
	await get_tree().create_timer(PRESS_MS / 1000.0).timeout
	if not is_inside_tree():
		return
	show_pressed(&"")
	_busy = false
	_activate(id)


## Swap in the baked pressed sprite of `id` (&"" hides it).
func show_pressed(id: StringName) -> void:
	pressed_id = id
	pressed_texture = null
	if id != &"":
		var it := _item(id)
		pressed_texture = _tex(texture_path(id))
		pressed_rect = to_screen(rect_of(it["sprite_rect"])) if not it.is_empty() else Rect2()
	board.queue_redraw()


func _activate(id: StringName) -> void:
	match id:
		&"start":
			_on_play()
		&"about":
			about_panel.visible = true
		_:
			_go(TARGETS[id])


func _go(path: String) -> void:
	last_target = path
	if change_scenes:
		get_tree().change_scene_to_file(path)


func _on_play() -> void:
	# D-52: the control mode is chosen once, before the first tutorial
	if not Settings.get_value("control_chosen", false):
		_go(CONTROL_CHOICE)
	elif Save.get_value("tutorial_done", false):
		# N-64: "Zacznij dyżur" after the tutorial starts the shift (endless run), never a bare
		# lock without a job (its opening had nowhere to go and the screen froze)
		_go(RUN_LOOP)
	else:
		_go(TUTORIAL)


# ------------------------------------------------------------------ About sheet


func _layout_about(vp: Vector2) -> void:
	# inside the safe area, 16 dp sides, at most 560 dp wide
	var i := ScreenFrame.insets(self)
	var w := minf(560.0, vp.x - i.x - i.z - 32.0)
	var left := i.x + (vp.x - i.x - i.z - w) * 0.5
	about_panel.offset_left = left
	about_panel.offset_right = -(vp.x - left - w)
	about_panel.offset_top = i.y + 16.0
	about_panel.offset_bottom = -(i.w + 16.0)


func _on_about_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_about_taps += 1
		if _about_taps >= 5 and not Save.get_value("post_release", false):
			Save.set_value("post_release", true)  # task 11: chapter 7 unlocked
			Save.set_value("dev_mode", true)  # T03: odblokowuje język DE w ustawieniach
			notice_label.text = I18n.t(&"about.post_release_unlocked")
			_about_taps = 0
