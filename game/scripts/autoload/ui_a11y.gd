extends Node
## UiA11y: the game's accessibility layer (docs/ACCESSIBILITY.md, D-90).
## - text scale (A-05/A-11): every font size of the project theme follows Settings `text_scale`
##   (100-200 %); code that sets its own font size goes through fs();
## - reduce motion: Settings `reduce_motion` OR the system setting (iOS Reduce Motion, Android
##   "remove animations", read through DisplayServer.accessibility_should_reduce_animation());
## - screen reader: announce() speaks through a live region (AccessKit) or the engine's TTS;
##   lock state changes (HUD.md §9.2) are announced from Events.lock_event, short and throttled,
##   only while a screen reader runs and Settings `announce_lock_events` is on;
## - Android (D-97, N-93): Godot 4.7.2 has no AccessKit adapter on Android, so TalkBack only saw the
##   SurfaceView. The LockwrightHaptics plugin carries a bridge (A11yBridge.kt): while TalkBack runs,
##   this node publishes the visible controls (name, role, bounds in window pixels, state) every
##   0.3 s when they change, activations / slider steps come back as signals, announce() goes to
##   TalkBack; the lock screen is one named area (thumbs: TalkBack's double-tap-and-hold pass-through);
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
	process_mode = Node.PROCESS_MODE_ALWAYS  # D-97: the pause panel (tree paused) must reach TalkBack too
	_setup_bridge()
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
	if _bridge_sr:
		return true
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
	if _bridge != null and _bridge_sr:
		_bridge.call(&"a11y_announce", text)  # D-97: TalkBack speaks it
		return
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

# ------------------------------------------------------------------ Android TalkBack bridge (D-97)
const BRIDGE_SINGLETON := "LockwrightHaptics"
const BRIDGE_POLL_S := 0.3
var _bridge: Object = null
var _bridge_active := false   # an accessibility client listens: nodes are published
var _bridge_sr := false       # a spoken screen reader (TalkBack) runs: announcements, screen-reader paths
var _bridge_left := 0.0
var _last_json := ""
var _ids := {}        # instance_id -> small stable id
var _by_id := {}      # small id -> WeakRef(Control)
var _next_id := 0


func _setup_bridge() -> void:
	if Engine.has_singleton(BRIDGE_SINGLETON):
		use_bridge(Engine.get_singleton(BRIDGE_SINGLETON))


## The plugin singleton (or a test double with the same methods and signals).
func use_bridge(b: Object) -> void:
	_bridge = null
	_bridge_active = false
	_bridge_sr = false
	_last_json = ""
	if b == null:
		return
	var has_m := func(m: StringName) -> bool:
		return bool(b.call(&"has_java_method", m)) if b.has_method(&"has_java_method") else b.has_method(m)
	if not has_m.call(&"a11y_set_nodes"):
		return  # an older AAR without the bridge
	_bridge = b
	if b is not RefCounted:
		print("UiA11y: TalkBack bridge ready (", BRIDGE_SINGLETON, ")")
	if b.has_signal(&"a11y_activate") and not b.is_connected(&"a11y_activate", _on_bridge_activate):
		b.connect(&"a11y_activate", _on_bridge_activate)
	if b.has_signal(&"a11y_adjust") and not b.is_connected(&"a11y_adjust", _on_bridge_adjust):
		b.connect(&"a11y_adjust", _on_bridge_adjust)


func bridge_active() -> bool:
	return _bridge_active


func bridge_screen_reader() -> bool:
	return _bridge_sr


func _process(delta: float) -> void:
	if _bridge == null:
		return
	_bridge_left -= delta
	if _bridge_left > 0.0:
		return
	_bridge_left = BRIDGE_POLL_S
	var was := _bridge_active
	_bridge_active = bool(_bridge.call(&"a11y_active"))
	_bridge_sr = _bridge_active and bool(_bridge.call(&"a11y_screen_reader"))
	if _bridge_active:
		var n := publish_nodes()
		if not was:
			print("UiA11y: accessibility on (screen reader %s), %d nodes" % [_bridge_sr, n.size()])
	elif was:
		print("UiA11y: accessibility off")
		_last_json = ""
		_bridge.call(&"a11y_set_nodes", "[]")


## Sends the visible controls to the bridge when they changed. Returns the node list (tests).
func publish_nodes(root: Node = null) -> Array:
	var out: Array = []
	if root == null:
		root = get_tree().root
	var vp_rect := Rect2(Vector2.ZERO, Vector2(DisplayServer.window_get_size()))
	if root is Viewport and not root == get_tree().root:
		vp_rect = Rect2(Vector2.ZERO, Vector2((root as Viewport).get_visible_rect().size))
	_collect(root, out, vp_rect)
	var json := JSON.stringify(out)
	if json != _last_json and _bridge != null:
		_last_json = json
		_bridge.call(&"a11y_set_nodes", json)
	return out


func _id_for(c: Control) -> int:
	var iid := c.get_instance_id()
	if not _ids.has(iid):
		_ids[iid] = _next_id
		_next_id += 1
	var id: int = _ids[iid]
	_by_id[id] = weakref(c)
	return id


## Window-pixel rect of a control, clipped by the scroll containers above it.
static func screen_rect(c: Control) -> Rect2:
	var xf := c.get_viewport().get_final_transform() * c.get_global_transform_with_canvas()
	var r := xf * Rect2(Vector2.ZERO, c.size)
	var p := c.get_parent()
	while p != null:
		if p is ScrollContainer:
			var pc := p as Control
			var pr := pc.get_viewport().get_final_transform() * pc.get_global_transform_with_canvas() * Rect2(Vector2.ZERO, pc.size)
			r = r.intersection(pr)
		p = p.get_parent()
	return r


func _collect(n: Node, out: Array, vp: Rect2) -> void:
	if n == self:
		return
	if n is CanvasItem and not (n as CanvasItem).visible:
		return
	if get_tree().paused and n is Control and not n.can_process():
		return  # paused: only the pause panel (process ALWAYS) is live, the lock under it is not
	if n is Control:
		var c := n as Control
		var node := describe(c)
		if not node.is_empty():
			var r := screen_rect(c).intersection(vp)
			if r.size.x >= 4.0 and r.size.y >= 4.0:
				node["id"] = _id_for(c)
				node["x"] = int(r.position.x)
				node["y"] = int(r.position.y)
				node["w"] = int(r.size.x)
				node["h"] = int(r.size.y)
				out.append(node)
			if node.get("role") != "area":
				return  # the labels and pictures inside a button are part of its name
	for ch in n.get_children():
		_collect(ch, out, vp)


## Role / name / state of one control for the bridge ({} = not exposed).
static func describe(c: Control) -> Dictionary:
	if c is LockPhotorealView:
		return {"role": "area", "name": spoken_name(c),
			"desc": str(c.get("accessibility_description")) + " " + I18n.t(&"a11y.lock_talkback")}
	if c.mouse_filter == Control.MOUSE_FILTER_IGNORE and not c is Label:
		return {}
	if c.has_meta(&"a11y_click"):
		return {"role": "button", "name": spoken_name(c)}
	if c is OptionButton:
		var ob := c as OptionButton
		var label := str(ob.get("accessibility_name"))
		return {"role": "option", "name": label if label != "" else ob.text, "value": ob.text,
			"disabled": ob.disabled}
	if c is BaseButton:
		var b := c as BaseButton
		var d := {"role": "check" if b.toggle_mode else "button", "name": spoken_name(c), "disabled": b.disabled}
		if b.toggle_mode:
			d["checked"] = 1 if b.button_pressed else 0
		var desc := str(c.get("accessibility_description"))
		if desc != "":
			d["desc"] = desc
		return d if d["name"] != "" else {}
	if c is Range and not c is ScrollBar:
		var rg := c as Range
		var pct := roundi((rg.value - rg.min_value) / maxf(rg.max_value - rg.min_value, 0.0001) * 100.0)
		return {"role": "slider", "name": spoken_name(c), "value": "%d%%" % pct}
	if c is Label and (c as Label).text.strip_edges() != "":
		return {"role": "text", "name": (c as Label).text.strip_edges()}
	return {}


func _on_bridge_activate(id: int) -> void:
	var c: Control = (_by_id.get(id, weakref(null)) as WeakRef).get_ref()
	if c == null or not c.is_inside_tree():
		return
	activate(c)
	_bridge_left = 0.05  # republish soon (new screen, toggled state)


## The effect of a TalkBack double tap on a control (also used by tests).
static func activate(c: Control) -> void:
	var cb: Variant = c.get_meta(&"a11y_click", Callable()) if c.has_meta(&"a11y_click") else Callable()
	if cb is Callable and (cb as Callable).is_valid():
		(cb as Callable).call()
	elif c is OptionButton:
		var ob := c as OptionButton
		if ob.item_count > 0:
			var i := (ob.selected + 1) % ob.item_count  # next option (the popup list is not exposed)
			ob.select(i)
			ob.item_selected.emit(i)
	elif c is BaseButton:
		var b := c as BaseButton
		if b.disabled:
			return
		if b.toggle_mode:
			b.button_pressed = not b.button_pressed
		else:
			b.pressed.emit()


func _on_bridge_adjust(id: int, dir: int) -> void:
	var c: Control = (_by_id.get(id, weakref(null)) as WeakRef).get_ref()
	if c is Range:
		var rg := c as Range
		rg.value += signf(dir) * maxf(rg.step, (rg.max_value - rg.min_value) / 10.0)
		_bridge_left = 0.05
