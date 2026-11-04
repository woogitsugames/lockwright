extends Control
## Spikes 1-2 probe inside Godot. Tap = transient (set-like click), horizontal drag = continuous
## resistance (intensity = x / width * 0.55, at most 60 updates/s). The screen flashes on touch
## (240 fps camera check). Shows: input event -> API call time (in-engine part of the latency),
## API call duration, tier/capabilities. Compare with native-android / native-ios on the same phone.

const TEXT := {
	"en": {"title": "Godot haptics probe (test tool, not a game)", "taps": "taps",
		"drag": "drag horizontally: continuous resistance", "none": "No haptics module (desktop or missing build)"},
	"pl": {"title": "Sonda haptyki w Godocie (narzędzie testowe, nie gra)", "taps": "dotknięcia",
		"drag": "przesuń w poziomie: opór ciągły", "none": "Brak modułu haptyki (desktop albo brak buildu)"},
}

var lang := "en"
var android: Object
var ios: Object
var caps := {}
var flash := false
var last_update_us := 0
var ev_to_call_us: PackedFloat32Array = []
var call_us: PackedFloat32Array = []
var label: Label


func _t(k: String) -> String:
	return TEXT[lang][k]


func _ready() -> void:
	lang = "pl" if OS.get_locale_language() == "pl" else "en"
	if Engine.has_singleton("LockwrightHapticsProbe"):
		android = Engine.get_singleton("LockwrightHapticsProbe")
		caps = android.capabilities()
	elif ClassDB.class_exists("LockwrightHapticsProbeIOS"):
		ios = ClassDB.instantiate("LockwrightHapticsProbeIOS")
		caps = ios.capabilities()
	label = Label.new()
	label.position = Vector2(16, 60)
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", Color(0.94, 0.92, 0.88))
	add_child(label)
	_refresh()


func _input(e: InputEvent) -> void:
	var t_event := Time.get_ticks_usec()
	if e is InputEventScreenTouch or (e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT):
		if e.pressed:
			var t_call := Time.get_ticks_usec()
			var d := {}
			if android:
				d = android.transient(0.9, 0.85)
				android.continuous_start()
				android.continuous_update(e.position.x / size.x * 0.55, 0.3)
			elif ios:
				d = ios.transient(0.9, 0.85)
				ios.continuous_start()
				ios.continuous_update(e.position.x / size.x * 0.55, 0.3)
			ev_to_call_us.append(float(t_call - t_event))
			call_us.append(float(d.get("call_us", 0.0)))
			print("LW_HAPTICS tap event_to_call_us=%d call_us=%.1f" % [t_call - t_event, float(d.get("call_us", 0.0))])
			flash = true
		else:
			if android:
				android.continuous_stop()
			elif ios:
				ios.continuous_stop()
			flash = false
		queue_redraw()
		_refresh()
	elif e is InputEventScreenDrag or e is InputEventMouseMotion:
		if t_event - last_update_us < 16666:
			return
		last_update_us = t_event
		var x: float = e.position.x / size.x * 0.55
		if android:
			android.continuous_update(x, 0.3)
		elif ios:
			ios.continuous_update(x, 0.3)


func _pct(a: PackedFloat32Array, p: float) -> float:
	if a.is_empty():
		return 0.0
	var s := a.duplicate()
	s.sort()
	return s[int(p * (s.size() - 1))]


func _refresh() -> void:
	var lines := PackedStringArray([_t("title")])
	if caps.is_empty():
		lines.append(_t("none"))
	else:
		for k in caps:
			lines.append("%s: %s" % [k, caps[k]])
	lines.append("%s %d: event -> API p50 %.0f / p95 %.0f us, API call p50 %.0f us" % [
		_t("taps"), ev_to_call_us.size(), _pct(ev_to_call_us, 0.5), _pct(ev_to_call_us, 0.95), _pct(call_us, 0.5)])
	lines.append(_t("drag"))
	label.text = "\n".join(lines)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.92, 0.9, 0.85) if flash else Color(0.1, 0.094, 0.086))
