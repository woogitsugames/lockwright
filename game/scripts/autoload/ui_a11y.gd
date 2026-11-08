extends Node
## UiA11y: the game's accessibility layer (docs/ACCESSIBILITY.md, D-90).
## - text scale (A-05/A-11): every font size of the project theme follows Settings `text_scale`
##   (100-200 %); code that sets its own font size goes through fs();
## - reduce motion: Settings `reduce_motion` OR the system setting (iOS Reduce Motion, Android
##   "remove animations", read through DisplayServer.accessibility_should_reduce_animation());
## - screen reader: announce() speaks through a live region (AccessKit) or the engine's TTS;
##   lock state changes (HUD.md §9.2) are announced from Events.lock_event, short and throttled,
##   only while a screen reader runs and Settings `announce_lock_events` is on;
## - name_button(): a localized name + role for controls without visible text.

signal announced(text: String)

## Theme type -> font size at 100 % (read from theme/main.tres once, before any scaling).
var _base_sizes := {}
var _base_default := 16
var _theme: Theme
var _os_reduce := false
var _live: Label
## Tests: -1 = real value, 0/1 = forced.
var screen_reader_override := -1
var reduce_motion_override := -1
## Everything announced since start (tests, QA logs); capped.
var history: Array[String] = []
const HISTORY_MAX := 64

## Lock event kind -> i18n key of the spoken line (HUD.md §9.2, DESIGN.md §1).
## near_shear / contact / wear stay silent (too frequent; their picture and sound remain).
const LOCK_LINES := {
	&"bind": &"a11y.lock.bind",
	&"set": &"a11y.lock.set",
	&"false_set": &"a11y.lock.false_set",
	&"overset": &"a11y.lock.overset",
	&"counter_rotate": &"a11y.lock.counter_rotate",
	&"drop": &"a11y.lock.drop",
	&"stress": &"a11y.lock.stress",
	&"break": &"a11y.lock.break",
	&"gate_align": &"a11y.lock.gate_align",
	&"detector_trip": &"a11y.lock.detector_trip",
	&"open": &"a11y.lock.open",
}
## Seconds before the same (kind, element) may be announced again.
const REPEAT_S := {&"bind": 2.5, &"stress": 3.0, &"counter_rotate": 2.0, &"gate_align": 1.0}
const ASSERTIVE := [&"overset", &"stress", &"break", &"detector_trip", &"open", &"false_set"]
var _last_said := {}  # "kind/element" -> msec


func _ready() -> void:
	_theme = load("res://theme/main.tres")
	if _theme:
		_base_default = _theme.default_font_size
		for type in _theme.get_font_size_type_list():
			for fs_name in _theme.get_font_size_list(type):
				_base_sizes["%s/%s" % [type, fs_name]] = _theme.get_font_size(fs_name, type)
	_refresh_os_flags()
	_build_live_region()
	Settings.changed.connect(_apply_text_scale)
	_apply_text_scale()
	Events.lock_event.connect(_on_lock_event)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_IN:
		_refresh_os_flags()  # the player may have changed the system setting meanwhile


func _refresh_os_flags() -> void:
	_os_reduce = false
	if DisplayServer.has_method("accessibility_should_reduce_animation"):
		_os_reduce = int(DisplayServer.accessibility_should_reduce_animation()) == 1  # -1 = unknown


# ------------------------------------------------------------------ text scale
func text_scale() -> float:
	return clampf(float(Settings.get_value("text_scale", 1.0)), 1.0, 2.0)


## A font size from code (overrides) at the current text scale.
func fs(base: int) -> int:
	return roundi(base * text_scale())


func _apply_text_scale() -> void:
	if _theme == null:
		return
	var s := text_scale()
	_theme.default_font_size = roundi(_base_default * s)
	for k in _base_sizes:
		var parts: PackedStringArray = String(k).split("/")
		_theme.set_font_size(parts[1], parts[0], roundi(int(_base_sizes[k]) * s))


## Font size of a theme type at 100 % (tests).
func base_font_size(type: StringName) -> int:
	return int(_base_sizes.get("%s/font_size" % type, _base_default))


# ------------------------------------------------------------------ reduce motion
func reduce_motion() -> bool:
	if reduce_motion_override >= 0:
		return reduce_motion_override == 1
	return bool(Settings.get_value("reduce_motion", false)) or _os_reduce


# ------------------------------------------------------------------ screen reader
func screen_reader_active() -> bool:
	if screen_reader_override >= 0:
		return screen_reader_override == 1
	if DisplayServer.has_method("accessibility_screen_reader_active"):
		return int(DisplayServer.accessibility_screen_reader_active()) == 1
	return false


func _build_live_region() -> void:
	var layer := CanvasLayer.new()
	layer.name = "A11yLayer"
	layer.layer = 128
	add_child(layer)
	_live = Label.new()
	_live.name = "Announcer"
	_live.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_live.position = Vector2(-4, -4)
	_live.size = Vector2(2, 2)
	_live.clip_text = true
	_live.self_modulate = Color(1, 1, 1, 0)  # spoken, never drawn
	_live.set("accessibility_live", DisplayServer.LIVE_ASSERTIVE)
	layer.add_child(_live)


## Speaks a line now: the engine TTS when it is on and has a voice for the game language,
## otherwise the AccessKit live region (the player's screen reader reads it).
func announce(text: String, assertive := true) -> void:
	if text == "":
		return
	history.append(text)
	if history.size() > HISTORY_MAX:
		history.pop_front()
	announced.emit(text)
	if bool(ProjectSettings.get_setting("audio/general/text_to_speech", false)) and screen_reader_override < 0:
		var voices := DisplayServer.tts_get_voices_for_language(TranslationServer.get_locale().substr(0, 2))
		if voices.size() > 0:
			if assertive:
				DisplayServer.tts_stop()
			DisplayServer.tts_speak(text, voices[0])
			return
	if _live:
		_live.set("accessibility_live", DisplayServer.LIVE_ASSERTIVE if assertive else DisplayServer.LIVE_POLITE)
		_live.text = text
		_live.set("accessibility_name", text)


## Spoken line of one lock event ("" = silent). Pure (tests).
static func lock_line(e: Dictionary) -> String:
	var key: StringName = LOCK_LINES.get(StringName(e.get("kind", &"")), &"")
	if key == &"":
		return ""
	var n := int(e.get("element", -1))
	return I18n.t(key).format({"n": str(n + 1) if n >= 0 else ""}).strip_edges().trim_prefix(": ").trim_prefix(":").strip_edges()


func _on_lock_event(e: Dictionary) -> void:
	if not screen_reader_active() or not bool(Settings.get_value("announce_lock_events", true)):
		return
	var kind := StringName(e.get("kind", &""))
	if not LOCK_LINES.has(kind):
		return
	var k := "%s/%d" % [kind, int(e.get("element", -1))]
	var now := Time.get_ticks_msec()
	if _last_said.has(k) and now - int(_last_said[k]) < int(float(REPEAT_S.get(kind, 0.25)) * 1000.0):
		return
	_last_said[k] = now
	if kind in [&"drop", &"open", &"break"]:
		_last_said.clear()  # a new attempt: every element may be announced again
	announce(lock_line(e), kind in ASSERTIVE)


# ------------------------------------------------------------------ names
## Accessible name (and role "button" with a click action) for a control drawn without text,
## e.g. the pause flap or the loupe on the lock screen. `on_click` runs on the screen reader's
## activate action (double tap); without it the control only gets its name.
static func name_button(c: Control, text: String, on_click: Callable = Callable()) -> void:
	c.set("accessibility_name", text)
	c.set_meta(&"a11y_click", on_click)
	if not c.has_meta(&"a11y_hooked"):
		c.set_meta(&"a11y_hooked", true)
		c.focus_mode = Control.FOCUS_ALL if c.focus_mode == Control.FOCUS_NONE else c.focus_mode
	c.queue_accessibility_update()


## For controls that call it from _notification(NOTIFICATION_ACCESSIBILITY_UPDATE).
static func update_button_role(c: Control) -> void:
	var rid := c.get_accessibility_element()
	if not rid.is_valid():
		return
	DisplayServer.accessibility_update_set_role(rid, DisplayServer.ROLE_BUTTON)
	var cb: Variant = c.get_meta(&"a11y_click", Callable())
	if cb is Callable and (cb as Callable).is_valid():
		DisplayServer.accessibility_update_add_action(rid, DisplayServer.ACTION_CLICK,
			func(_data: Variant) -> void: (cb as Callable).call())


## Name a screen reader reads for a control: its accessibility_name, else its visible text.
static func spoken_name(c: Control) -> String:
	var n := str(c.get("accessibility_name")) if c.get("accessibility_name") != null else ""
	if n.strip_edges() != "":
		return n
	if c is Button and (c as Button).text.strip_edges() != "":
		return (c as Button).text
	if c is Label and (c as Label).text.strip_edges() != "":
		return (c as Label).text
	return ""
