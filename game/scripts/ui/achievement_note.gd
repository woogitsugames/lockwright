class_name AchievementNote
extends CanvasLayer
## Owner decision 2026-11-16 (D-138): an achievement earned is said at once, quietly — one chalk line
## on a small slate at the top of the screen, under the status bar, for NOTE_S seconds. No fanfare, no
## card over the game. Never on a lock screen: an achievement earned on the lock waits in the queue and
## is said on the next screen (the receipt, the job list, the workshop). Several at once are one line
## ("X and 2 more"). On a hub screen (MenuScreens) a tap opens the achievement's card on the shelf;
## during a job (arrival, verification, receipt) the line is information only, so a tap cannot leave
## a bill unsettled. Screen readers hear the same line (UiA11y.announce).
## Built by Achievements the first time something is earned, so the boot pays nothing for it.

const NOTE_S := 4.0
const FADE_S := 0.2
const POLL_S := 0.5
const FONT_PATH := "res://assets/fonts/Caveat-wght.ttf"
const CHALK := Color(0.96, 0.95, 0.90)           # ChalkLayer.C
const SLATE := Color(0.12, 0.12, 0.11, 0.94)     # contrast with the chalk ~15:1
const EDGE := Color(0.42, 0.33, 0.22)            # wooden frame of the slate, 2 dp
const TEXT_SIZE := 24
const MIN_H := 48.0
## Under the header row of the screens (Back + title, ~64 dp): the Back button stays free.
const HEADER_H := 76.0
const SHOWCASE := "res://scenes/showcase.tscn"
## Screens a tap may leave: nothing of a job is half done there.
const HUB_SCREENS := ["res://scenes/jobs_list.tscn", "res://scenes/main_menu.tscn", "res://scenes/workshop.tscn",
	"res://scenes/settings.tscn"]

var queue: Array[String] = []
var shown_ids: Array[String] = []   # what the line on screen names now (tests)
var panel: Button
var _label: Label
var _timer: Timer
var _hide_at := -1.0
var _tween: Tween


func _ready() -> void:
	name = "AchievementNoteLayer"
	layer = 91  # over the voice-pack note (90), under dialogs
	process_mode = Node.PROCESS_MODE_ALWAYS
	panel = Button.new()
	panel.name = "AchievementNote"
	panel.focus_mode = Control.FOCUS_NONE
	panel.visible = false
	var box := StyleBoxFlat.new()
	box.bg_color = SLATE
	box.border_color = EDGE
	box.set_border_width_all(2)
	box.set_corner_radius_all(4)
	box.content_margin_left = 16
	box.content_margin_right = 16
	box.content_margin_top = 8
	box.content_margin_bottom = 8
	for st: String in ["normal", "hover", "pressed", "focus", "disabled"]:
		panel.add_theme_stylebox_override(st, box)
	_label = Label.new()
	_label.name = "Text"
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_color_override("font_color", CHALK)
	_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.55))
	_label.add_theme_constant_override("shadow_offset_x", 1)
	_label.add_theme_constant_override("shadow_offset_y", 1)
	if ResourceLoader.exists(FONT_PATH):
		_label.add_theme_font_override("font", load(FONT_PATH))
	_label.add_theme_font_size_override("font_size", _font_size())
	_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_label.offset_left = 16
	_label.offset_right = -16
	panel.add_child(_label)
	panel.pressed.connect(_on_pressed)
	add_child(panel)
	_timer = Timer.new()
	_timer.wait_time = POLL_S
	_timer.timeout.connect(_tick)
	add_child(_timer)
	_timer.start()


## An achievement was earned (Achievements.unlock, dated).
func push(id: String) -> void:
	if id == "" or queue.has(id) or shown_ids.has(id):
		return
	queue.append(id)
	_tick.call_deferred()


## A lock is on screen (its scene has the input sampler, as VoicePacks checks): nothing is laid over it.
func on_lock_screen() -> bool:
	var sc := _scene()
	return sc != null and sc.get_node_or_null("InputSampler") != null


func _scene() -> Node:
	if not is_inside_tree():
		return null
	if get_node_or_null("/root/Nav") != null and Nav.scene_override != null:
		return Nav.scene_override
	return get_tree().current_scene


func _scene_path() -> String:
	var sc := _scene()
	return sc.scene_file_path if sc != null else ""


func _tick() -> void:
	if not is_inside_tree():
		return
	var now := Time.get_ticks_msec() / 1000.0
	if panel.visible and _hide_at > 0.0 and now >= _hide_at:
		_hide()
	if on_lock_screen():
		if panel.visible:
			_hide(true)  # a line still up when a lock opens goes away at once
		return
	if queue.is_empty() or panel.visible:
		return
	shown_ids = queue.duplicate()
	queue.clear()
	_show(text_for(shown_ids))


## "Achievement: The First Click" / "Achievements: The First Click and 2 more".
static func text_for(ids: Array) -> String:
	if ids.is_empty():
		return ""
	var first := I18n.t(StringName("ach.%s.name" % ids[0]))
	if ids.size() == 1:
		return I18n.t(&"ach.note.one").format({"name": first})
	return I18n.t(&"ach.note.many").format({"name": first, "n": ids.size() - 1})


func tappable() -> bool:
	return HUB_SCREENS.has(_scene_path())


func _show(text: String) -> void:
	_label.text = text
	_label.add_theme_font_size_override("font_size", _font_size())
	panel.mouse_filter = Control.MOUSE_FILTER_STOP if tappable() else Control.MOUSE_FILTER_IGNORE
	panel.tooltip_text = ""
	panel.set("accessibility_name", text)
	panel.visible = true
	_place()
	_hide_at = Time.get_ticks_msec() / 1000.0 + NOTE_S
	_fade(1.0)
	if get_node_or_null("/root/UiA11y") != null:
		UiA11y.announce(text, false)


func _hide(now := false) -> void:
	_hide_at = -1.0
	shown_ids.clear()
	if now or _reduce_motion():
		panel.visible = false
		panel.modulate.a = 1.0
		return
	_fade(0.0)


func _fade(to: float) -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	if _reduce_motion():
		panel.modulate.a = 1.0
		panel.visible = to > 0.0
		return
	if to > 0.0:
		panel.modulate.a = 0.0
	_tween = create_tween()
	_tween.tween_property(panel, "modulate:a", to, FADE_S)
	if to <= 0.0:
		_tween.tween_callback(func() -> void:
			panel.visible = false
			panel.modulate.a = 1.0)


func _reduce_motion() -> bool:
	return get_node_or_null("/root/UiA11y") != null and UiA11y.reduce_motion()


func _font_size() -> int:
	return UiA11y.fs(TEXT_SIZE) if get_node_or_null("/root/UiA11y") != null else TEXT_SIZE


## Near the top, as the voice-pack note (D-134: the bottom of every screen is where its main plate
## is), but under the header row, so it never covers the Back button.
func _place() -> void:
	var vp := get_viewport()
	if vp == null:
		return
	var r := vp.get_visible_rect()
	var ins: Vector4 = SafeArea.insets(panel)
	var w := minf(r.size.x - 32.0 - ins.x - ins.z, 520.0)
	# the label's own minimum size is not known before its first layout (it wraps at width 0), so the
	# height comes from the font: the text wrapped at the slate's inner width
	var font: Font = _label.get_theme_font("font")
	var fsize := _label.get_theme_font_size("font_size")
	var text_h := font.get_multiline_string_size(_label.text, HORIZONTAL_ALIGNMENT_CENTER, w - 32.0, fsize).y
	var h := maxf(MIN_H, ceilf(text_h) + 16.0)
	panel.size = Vector2(w, h)
	panel.position = Vector2(r.position.x + (r.size.x - w) * 0.5, r.position.y + ins.y + HEADER_H)


## A tap on a hub screen: the card of the (first) achievement on the shelf.
func _on_pressed() -> void:
	if shown_ids.is_empty() or not tappable():
		return
	var id: String = shown_ids[0]
	_hide(true)
	Achievements.open_on_shelf = id
	if get_node_or_null("/root/Nav") != null and not Nav.change_scenes:
		Nav.last_target = SHOWCASE
		return
	get_tree().change_scene_to_file(SHOWCASE)
