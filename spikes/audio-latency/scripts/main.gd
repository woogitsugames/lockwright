extends Control
## Spike 3 test app: touch -> click. Left half plays through the Oboe plugin (AAudio, low latency),
## right half through Godot's AudioStreamPlayer (OpenSL ES on Android). The touched half flashes
## for one frame (camera check of display latency). The top strip cycles the sample.
## Labels are PL/EN through a small table (no hard-coded player text).

const SAMPLES := ["impulse", "set_brass", "set_steel", "false_set_brass", "false_set_steel",
	"contact_brass", "contact_steel", "break_brass", "break_steel"]

const TEXT := {
	"en": {"oboe": "A · Oboe / AAudio", "godot": "B · Godot AudioStreamPlayer", "sample": "Sample (tap to change)",
		"missing": "Oboe plugin not loaded (desktop or missing AAR): left half plays through Godot too",
		"taps": "taps", "note": "Test tool, not a game."},
	"pl": {"oboe": "A · Oboe / AAudio", "godot": "B · Godot AudioStreamPlayer", "sample": "Próbka (dotknij, by zmienić)",
		"missing": "Brak pluginu Oboe (desktop albo brak AAR): lewa połowa też gra przez Godota",
		"taps": "dotknięć", "note": "Narzędzie testowe, nie gra."},
}

var lang := "en"
var oboe: Object
var players: Array[AudioStreamPlayer] = []
var streams := {}
var sample_index := 1
var taps := {"a": 0, "b": 0}
var flash := {"a": 0, "b": 0}
var event_to_call_us: PackedFloat32Array = []
var stats_label: Label
var sample_label: Label
var stats_t := 0.0


func _t(k: String) -> String:
	return TEXT[lang][k]


func _ready() -> void:
	lang = "pl" if OS.get_locale_language() == "pl" else "en"
	for s in SAMPLES:
		streams[s] = load("res://samples/%s.wav" % s) as AudioStreamWAV
	for i in 4:
		var p := AudioStreamPlayer.new()
		p.max_polyphony = 4
		add_child(p)
		players.append(p)
	if Engine.has_singleton("LockwrightLowLatencyAudio"):
		oboe = Engine.get_singleton("LockwrightLowLatencyAudio")
		for s in SAMPLES:
			var w: AudioStreamWAV = streams[s]
			# AudioStreamWAV.data holds 16-bit little-endian PCM for FORMAT_16_BITS (mono here).
			if w.format == AudioStreamWAV.FORMAT_16_BITS and not w.stereo:
				oboe.load_sample(s, w.data, w.mix_rate)
			else:
				push_warning("sample %s: import format %d, stereo %s (needs 16-bit mono)" % [s, w.format, w.stereo])
	sample_label = _label(Vector2(16, 48), 22)
	stats_label = _label(Vector2(16, 120), 16)
	_label(Vector2(16, 0), 14).text = _t("note")
	_update_sample_label()
	set_process(true)


func _label(pos: Vector2, size: int) -> Label:
	var l := Label.new()
	l.position = pos
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", Color(0.94, 0.92, 0.88))
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)
	return l


func _update_sample_label() -> void:
	sample_label.text = "%s: %s" % [_t("sample"), SAMPLES[sample_index]]


func _input(e: InputEvent) -> void:
	_handle(e)
	get_viewport().set_input_as_handled()


func _handle(e: InputEvent) -> void:
	var pressed := false
	var pos := Vector2.ZERO
	if e is InputEventScreenTouch and e.pressed:
		pressed = true
		pos = e.position
	elif e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		pressed = true
		pos = e.position
	if not pressed:
		return
	var t0 := Time.get_ticks_usec()
	if pos.y < size.y * 0.12:
		sample_index = (sample_index + 1) % SAMPLES.size()
		_update_sample_label()
		return
	var id: String = SAMPLES[sample_index]
	if pos.x < size.x * 0.5:
		taps["a"] += 1
		flash["a"] = 2
		if oboe:
			oboe.play(id, 1.0, 1.0)
		else:
			_play_godot(id)
	else:
		taps["b"] += 1
		flash["b"] = 2
		_play_godot(id)
	event_to_call_us.append(float(Time.get_ticks_usec() - t0))
	if event_to_call_us.size() > 200:
		event_to_call_us = event_to_call_us.slice(event_to_call_us.size() - 200)
	queue_redraw()


func _play_godot(id: String) -> void:
	for p in players:
		if not p.playing:
			p.stream = streams[id]
			p.play()
			return
	players[0].stream = streams[id]
	players[0].play()


func _process(delta: float) -> void:
	for k in flash:
		if flash[k] > 0:
			flash[k] -= 1
			queue_redraw()
	stats_t += delta
	if stats_t < 0.5:
		return
	stats_t = 0.0
	var lines := PackedStringArray()
	lines.append("%s: %d %s   |   %s: %d %s" % [_t("oboe"), taps["a"], _t("taps"), _t("godot"), taps["b"], _t("taps")])
	if oboe:
		var s: Dictionary = oboe.stats()
		lines.append("AAudio: %s, %s, %s" % [s.get("audioApiName"), s.get("sharingModeName"), s.get("performanceModeName")])
		lines.append("rate %s Hz, burst %s, buffer %s / %s frames" % [s.get("sampleRate"), s.get("framesPerBurst"), s.get("bufferSize"), s.get("bufferCapacity")])
		var rate := float(s.get("sampleRate", 48000))
		lines.append("buffer = %.2f ms, est. output latency %.1f ms" % [1000.0 * float(s.get("bufferSize", 0)) / max(rate, 1.0), float(s.get("estimatedLatencyMs", -1))])
		lines.append("play() -> mix p50 %.2f / p95 %.2f ms, callback p95 %.0f us" % [s.get("callToMixP50Ms"), s.get("callToMixP95Ms"), s.get("callbackP95Us")])
		lines.append("xruns %s, opens %s, dropped %s, device %s Hz / %s frames, pro %s, low-latency %s" % [s.get("xRunCount"), s.get("opens"), s.get("droppedTriggers"), s.get("deviceNativeRate"), s.get("deviceNativeBurst"), s.get("proAudio"), s.get("lowLatencyFeature")])
		if String(s.get("error", "")) != "":
			lines.append("error: " + String(s.get("error")))
	else:
		lines.append(_t("missing"))
	lines.append("Godot: mix %d Hz, output latency %.1f ms (AudioServer)" % [AudioServer.get_mix_rate(), AudioServer.get_output_latency() * 1000.0])
	if not event_to_call_us.is_empty():
		var c := event_to_call_us.duplicate()
		c.sort()
		lines.append("input event -> play() p50 %.0f us" % c[c.size() / 2])
	stats_label.text = "\n".join(lines)
	print("LW_AUDIO ", stats_label.text.replace("\n", " | "))


func _draw() -> void:
	var half := Vector2(size.x * 0.5, size.y)
	var base := Color(0.10, 0.095, 0.09)
	draw_rect(Rect2(Vector2.ZERO, size), base)
	draw_rect(Rect2(Vector2(0, 0), half), Color(0.92, 0.9, 0.85) if flash["a"] > 0 else Color(0.16, 0.15, 0.13))
	draw_rect(Rect2(Vector2(half.x, 0), half), Color(0.92, 0.9, 0.85) if flash["b"] > 0 else Color(0.12, 0.13, 0.15))
	draw_line(Vector2(half.x, size.y * 0.12), Vector2(half.x, size.y), Color(0.94, 0.92, 0.88), 2.0)
	draw_line(Vector2(0, size.y * 0.12), Vector2(size.x, size.y * 0.12), Color(0.94, 0.92, 0.88), 2.0)
	var f := get_theme_default_font()
	draw_string(f, Vector2(16, size.y - 40), _t("oboe"), HORIZONTAL_ALIGNMENT_LEFT, half.x - 24, 18, Color(0.94, 0.92, 0.88))
	draw_string(f, Vector2(half.x + 16, size.y - 40), _t("godot"), HORIZONTAL_ALIGNMENT_LEFT, half.x - 24, 18, Color(0.94, 0.92, 0.88))
