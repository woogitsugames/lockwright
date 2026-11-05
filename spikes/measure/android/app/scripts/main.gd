extends Control
## LW Pomiary (D-33, spikes/measure/SPEC.md): step-by-step latency measurement for the owner.
## Steps: start -> prepare -> haptic auto -> continuous -> audio (fast + engine) -> taps -> results.
## Texts PL/EN from the table below (test tool; the game uses game/i18n).

const T := {
	"pl": {
		"title": "Pomiar opóźnień",
		"intro": "Ta aplikacja sprawdza, jak szybko telefon odpowiada drganiem i dźwiękiem. Zajmie to około 4 minut. To narzędzie testowe, nie gra.\n\nWykryty typ telefonu: %s. Jeśli się nie zgadza, dotknij przycisku „Zmień typ”.",
		"change_class": "Zmień typ", "start": "Zaczynamy",
		"prep_title": "Przygotowanie",
		"prep": "1. Połóż telefon ekranem do góry na twardym stole (nie na kolanach, nie na kocu).\n2. Wyłącz tryb cichy i ustaw głośność multimediów na ok. 70%.\n3. W pokoju powinno być cicho.\n\nGdy będziesz gotowy, dotknij „Gotowe”.",
		"ready": "Gotowe",
		"haptic_title": "Krok 1 z 4: drgania",
		"haptic": "Nie dotykaj telefonu. Przez ok. 15 sekund będzie krótko wibrował.",
		"cont_title": "Krok 2 z 4: ciągły opór",
		"cont": "Nie dotykaj telefonu. Przez 4 sekundy poczujesz ciągłe, lekkie drżenie.",
		"mic_title": "Krok 3 z 4: dźwięk",
		"mic_ask": "Teraz telefon zagra 60 krótkich kliknięć i posłucha ich mikrofonem. Nic nie jest nagrywane ani wysyłane. Za chwilę telefon zapyta o zgodę na mikrofon — wybierz „Zezwól”.",
		"mic_run": "Nie dotykaj telefonu i nie mów. Kliknięcia: %d z 60.",
		"mic_denied": "Bez mikrofonu nie zmierzymy dźwięku. Ten krok pomijam.",
		"tap_title": "Krok 4 z 4: stuknięcia",
		"tap": "Telefon dalej leży na stole. Stuknij opuszką palca w środek koła 20 razy, spokojnie, mniej więcej raz na sekundę. Zostało: %d.",
		"working": "Liczę…",
		"result_title": "Wynik",
		"share": "Udostępnij wynik", "again": "Powtórz pomiar",
		"saved": "Wynik zapisany w: %s. Przycisk „Udostępnij wynik” wyśle go mailem lub komunikatorem.",
		"v_pass": "Przechodzi", "v_border": "Na granicy", "v_fail": "Nie przechodzi", "v_no_data": "Brak danych",
		"m_haptic_tap": "Stuknięcie → drganie", "m_haptic_call": "Polecenie → drganie",
		"m_audio_tap": "Stuknięcie → kliknięcie", "m_audio_gain": "Zysk szybkiej ścieżki dźwięku",
		"m_cont": "Przerwy w ciągłym oporze", "m_sync": "Dźwięk a drganie (rozjazd)",
		"p95": "95%% prób poniżej %.0f ms (próg %s)", "gain": "szybsza o %.0f ms (wymagane ≥ %d ms)",
		"gap": "najdłuższa przerwa %.0f ms (próg %d ms)", "none": "nie udało się zmierzyć",
		"class_pixel": "Pixel lub flagowiec", "class_samsung_a": "średnia półka (np. Samsung A)", "class_budget": "tani telefon",
	},
	"en": {
		"title": "Latency check",
		"intro": "This app checks how fast the phone answers with vibration and sound. It takes about 4 minutes. It is a test tool, not a game.\n\nDetected phone type: %s. If that is wrong, tap “Change type”.",
		"change_class": "Change type", "start": "Start",
		"prep_title": "Preparation",
		"prep": "1. Put the phone screen up on a hard table (not on your lap or a blanket).\n2. Turn silent mode off and set media volume to about 70%.\n3. The room should be quiet.\n\nWhen ready, tap “Done”.",
		"ready": "Done",
		"haptic_title": "Step 1 of 4: vibration",
		"haptic": "Do not touch the phone. It will vibrate briefly for about 15 seconds.",
		"cont_title": "Step 2 of 4: continuous resistance",
		"cont": "Do not touch the phone. For 4 seconds it will hum gently.",
		"mic_title": "Step 3 of 4: sound",
		"mic_ask": "The phone will now play 60 short clicks and listen to them with the microphone. Nothing is recorded or sent. The phone will ask for microphone access — choose “Allow”.",
		"mic_run": "Do not touch the phone and stay quiet. Clicks: %d of 60.",
		"mic_denied": "Without the microphone we cannot measure sound. Skipping this step.",
		"tap_title": "Step 4 of 4: taps",
		"tap": "Keep the phone on the table. Tap the centre of the circle 20 times with your fingertip, calmly, about once a second. Left: %d.",
		"working": "Working…",
		"result_title": "Result",
		"share": "Share result", "again": "Measure again",
		"saved": "Result saved in: %s. “Share result” sends it by e-mail or messenger.",
		"v_pass": "Passes", "v_border": "Borderline", "v_fail": "Fails", "v_no_data": "No data",
		"m_haptic_tap": "Tap → vibration", "m_haptic_call": "Command → vibration",
		"m_audio_tap": "Tap → click", "m_audio_gain": "Fast audio path gain",
		"m_cont": "Gaps in continuous resistance", "m_sync": "Sound vs vibration offset",
		"p95": "95%% of tries under %.0f ms (limit %s)", "gain": "faster by %.0f ms (needs ≥ %d ms)",
		"gap": "longest gap %.0f ms (limit %d ms)", "none": "could not be measured",
		"class_pixel": "Pixel or flagship", "class_samsung_a": "mid-range (e.g. Samsung A)", "class_budget": "budget phone",
	},
}
const CLASSES := ["pixel", "samsung_a", "budget"]
const BG := Color(0.10, 0.094, 0.086)
const INK := Color(0.95, 0.93, 0.88)
const MUTED := Color(0.78, 0.75, 0.69)
const V_COLORS := {"pass": Color(0.86, 0.80, 0.62), "border": Color(0.85, 0.62, 0.25), "fail": Color(0.71, 0.36, 0.25), "no_data": Color(0.6, 0.58, 0.55)}

var lang := "en"
var m: Object
var device := {}
var dclass := "budget"
var thresholds := {}
var box: VBoxContainer
var title_l: Label
var body_l: Label
var taps_left := 0
var tap_circle: Control
var engine_player: AudioStreamPlayer
var result := {}
var font_title: Font
var font_body: Font


func _t(k: String) -> String:
	return T[lang][k]


func _ready() -> void:
	lang = "pl" if OS.get_locale_language() == "pl" else "en"
	font_title = load("res://fonts/BonaNova-Bold.ttf")
	font_body = load("res://fonts/AtkinsonHyperlegibleNext-wght.ttf")
	thresholds = JSON.parse_string(FileAccess.get_file_as_string("res://data/thresholds.json"))
	if Engine.has_singleton("LockwrightMeasure"):
		m = Engine.get_singleton("LockwrightMeasure")
		device = JSON.parse_string(m.device_info())
		dclass = device.get("class", "budget")
	engine_player = AudioStreamPlayer.new()
	add_child(engine_player)
	if m:
		var w := AudioStreamWAV.new()
		w.format = AudioStreamWAV.FORMAT_16_BITS
		w.mix_rate = 48000
		w.data = m.click_pcm()
		engine_player.stream = w
	_build_ui()
	if "--demo" in OS.get_cmdline_user_args():
		# Desktop preview of the results screen with made-up numbers (for docs/handoff/POMIARY.md).
		result = {"metrics": {
			"haptic_tap": {"n": 20, "p50_ms": 28.0, "p95_ms": 33.0}, "haptic_call": {"n": 30, "p50_ms": 14.0, "p95_ms": 21.0},
			"audio_tap": {"n": 20, "p50_ms": 41.0, "p95_ms": 52.0}, "audio_call_fast": {"n": 30, "p50_ms": 18.0, "p95_ms": 22.0},
			"audio_call_engine": {"n": 30, "p50_ms": 61.0, "p95_ms": 70.0}, "continuous_max_gap_ms": 22.0,
			"audio_haptic_sync": {"n": 18, "p50_ms": 9.0, "p95_ms": 14.0}}, "notes": ["Przykładowe liczby (tryb demo)."]}
		dclass = "samsung_a"
		_finish()
		return
	_screen_intro()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BG)


# ------------------------------------------------------------------ UI helpers
func _build_ui() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	var safe := DisplayServer.get_display_safe_area()
	var scale: float = get_viewport().get_visible_rect().size.x / max(1.0, float(DisplayServer.window_get_size().x))
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 24 + int(safe.position.y * scale))
	margin.add_theme_constant_override("margin_bottom", 24)
	add_child(margin)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(scroll)
	box = VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 18)
	scroll.add_child(box)


func _clear() -> void:
	for c in box.get_children():
		c.queue_free()
	tap_circle = null


func _label(text: String, size_px: int, title: bool = false, color: Color = INK) -> Label:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_override("font", font_title if title else font_body)
	l.add_theme_font_size_override("font_size", size_px)
	l.add_theme_color_override("font_color", color)
	box.add_child(l)
	return l


func _button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 60)   # >= 48 dp touch target
	b.add_theme_font_override("font", font_body)
	b.add_theme_font_size_override("font_size", 22)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.86, 0.80, 0.62)
	sb.set_corner_radius_all(6)
	b.add_theme_stylebox_override("normal", sb)
	var sbp := sb.duplicate()
	sbp.bg_color = Color(0.74, 0.68, 0.52)
	b.add_theme_stylebox_override("pressed", sbp)
	b.add_theme_stylebox_override("hover", sb)
	b.add_theme_color_override("font_color", Color(0.12, 0.11, 0.10))
	b.add_theme_color_override("font_pressed_color", Color(0.12, 0.11, 0.10))
	b.pressed.connect(cb)
	box.add_child(b)
	return b


func _screen(title: String, body: String) -> void:
	_clear()
	title_l = _label(title, 34, true)
	body_l = _label(body, 21)


func _wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout


func _await_status(name: String, label_fmt: String = "") -> bool:
	while true:
		var s: String = m.status()
		if s == "done:" + name:
			return true
		if s.begins_with("error:"):
			_label(s, 16, false, MUTED)
			return false
		if label_fmt != "":
			body_l.text = label_fmt % int(round(m.progress() * 100.0))
		await _wait(0.1)
	return false


# ------------------------------------------------------------------ screens
func _screen_intro() -> void:
	_screen(_t("title"), _t("intro") % _t("class_" + dclass))
	if not m:
		_label("Brak modułu pomiarowego (uruchomiono poza Androidem). / Measurement module missing (not on Android).", 16, false, MUTED)
		return
	_button(_t("change_class"), func() -> void:
		dclass = CLASSES[(CLASSES.find(dclass) + 1) % CLASSES.size()]
		_screen_intro())
	_button(_t("start"), _screen_prepare)


func _screen_prepare() -> void:
	_screen(_t("prep_title"), _t("prep"))
	_button(_t("ready"), _run_all)


func _run_all() -> void:
	m.reset()
	# 1. haptic API -> vibration, no touch
	_screen(_t("haptic_title"), _t("haptic"))
	await _wait(1.5)
	m.run_haptic_auto(30)
	await _await_status("haptic", _t("haptic") + "  %d%%")
	# 2. continuous resistance
	_screen(_t("cont_title"), _t("cont"))
	await _wait(1.5)
	m.run_continuous(4.0)
	await _await_status("continuous", _t("cont") + "  %d%%")
	# 3. audio: fast path (Oboe) and engine path (Godot AudioStreamPlayer), heard by the mic
	_screen(_t("mic_title"), _t("mic_ask"))
	await _wait(3.0)
	var mic_ok := await _ensure_mic()
	if mic_ok and m.mic_start():
		await _wait(0.8)
		m.run_audio_fast(30)
		while m.status() != "done:audio_fast" and not String(m.status()).begins_with("error"):
			body_l.text = _t("mic_run") % int(round(m.progress() * 30.0))
			await _wait(0.1)
		for i in 30:
			body_l.text = _t("mic_run") % (30 + i + 1)
			m.mark_engine()
			engine_player.play()
			await _wait(0.3)
		await _wait(0.4)
		m.analyze_audio("fast")
		m.analyze_audio("engine")
	else:
		body_l.text = _t("mic_denied")
		await _wait(2.5)
	# 4. taps (mic keeps running if allowed)
	_screen(_t("tap_title"), "")
	taps_left = 20
	body_l.text = _t("tap") % taps_left
	m.taps_begin()
	tap_circle = TapCircle.new()
	tap_circle.custom_minimum_size = Vector2(0, 300)
	tap_circle.tapped.connect(_on_tap)
	box.add_child(tap_circle)
	while taps_left > 0:
		await _wait(0.1)
	_screen(_t("result_title"), _t("working"))
	await _wait(0.6)
	m.taps_end()
	m.mic_stop()
	_finish()


func _ensure_mic() -> bool:
	if "android.permission.RECORD_AUDIO" in OS.get_granted_permissions():
		return true
	OS.request_permission("android.permission.RECORD_AUDIO")
	var deadline := Time.get_ticks_msec() + 30000
	while Time.get_ticks_msec() < deadline:
		await _wait(0.3)
		if "android.permission.RECORD_AUDIO" in OS.get_granted_permissions():
			return true
	return false


func _on_tap() -> void:
	if taps_left <= 0:
		return
	m.tap()
	taps_left -= 1
	body_l.text = _t("tap") % taps_left


# ------------------------------------------------------------------ results
func _verdict_p95(metric: Dictionary, key: String) -> Array:
	var p95: float = metric.get("p95_ms", -1.0)
	if metric.get("n", 0) < 5 or p95 < 0:
		return ["no_data", _t("none")]
	var th: Dictionary = thresholds.get(key, {}).get(dclass, {})
	if th.is_empty():
		return ["no_data", _t("none")]
	var lim := float(th["pass"])
	var fail_lim := float(th.get("fail", lim * 1.25))
	var v := "pass" if p95 <= lim else ("border" if p95 <= fail_lim else "fail")
	return [v, _t("p95") % [p95, "%d ms" % int(lim)]]


func _finish() -> void:
	if m:
		result = JSON.parse_string(m.result_json())
	var mt: Dictionary = result.get("metrics", {})
	var fast: Dictionary = mt.get("audio_call_fast", {})
	var eng: Dictionary = mt.get("audio_call_engine", {})
	if fast.get("n", 0) >= 5 and eng.get("n", 0) >= 5:
		mt["audio_oboe_gain_ms"] = snappedf(float(eng["p50_ms"]) - float(fast["p50_ms"]), 0.1)
	var rows := []
	var verdicts := {}
	var v1 := _verdict_p95(mt.get("haptic_tap", {}), "haptic_tap_p95_ms")
	rows.append([_t("m_haptic_tap"), v1]); verdicts["haptic_tap_p95_ms"] = v1[0]
	var v2 := _verdict_p95(mt.get("haptic_call", {}), "haptic_call_p95_ms")
	rows.append([_t("m_haptic_call"), v2]); verdicts["haptic_call_p95_ms"] = v2[0]
	var v3 := _verdict_p95(mt.get("audio_tap", {}), "audio_tap_p95_ms")
	rows.append([_t("m_audio_tap"), v3]); verdicts["audio_tap_p95_ms"] = v3[0]
	var gmin: int = thresholds["audio_oboe_gain_ms"]["min"]
	var v4 := ["no_data", _t("none")]
	if mt.has("audio_oboe_gain_ms"):
		var g := float(mt["audio_oboe_gain_ms"])
		v4 = ["pass" if g >= gmin else ("border" if g >= 0.75 * gmin else "fail"), _t("gain") % [g, gmin]]
	rows.append([_t("m_audio_gain"), v4]); verdicts["audio_oboe_gain_ms"] = v4[0]
	var gap := float(mt.get("continuous_max_gap_ms", -1.0))
	var gl: int = thresholds["continuous_max_gap_ms"]["pass"]
	var v5 := ["no_data", _t("none")] if gap < 0 else [("pass" if gap <= gl else ("border" if gap <= gl * 1.25 else "fail")), _t("gap") % [gap, gl]]
	rows.append([_t("m_cont"), v5]); verdicts["continuous_max_gap_ms"] = v5[0]
	var sync: Dictionary = mt.get("audio_haptic_sync", {})
	var sl: int = thresholds["audio_haptic_sync_ms"]["pass"]
	var v6 := ["no_data", _t("none")]
	if sync.get("n", 0) >= 5:
		var sp := float(sync["p95_ms"])
		v6 = [("pass" if sp <= sl else ("border" if sp <= sl * 1.25 else "fail")), _t("p95") % [sp, "%d ms" % sl]]
	rows.append([_t("m_sync"), v6]); verdicts["audio_haptic_sync_ms"] = v6[0]

	device["class"] = dclass
	var out := {
		"schema": "lockwright.measure/1", "app": "android-godot", "app_version": "0.2.0",
		"created_utc": Time.get_datetime_string_from_system(true) + "Z",
		"device": device, "metrics": mt, "verdicts": verdicts, "notes": result.get("notes", []),
	}
	var text := JSON.stringify(out, "  ")
	var stamp := Time.get_datetime_string_from_system(false).replace(":", "").replace("-", "").replace("T", "-").substr(0, 13)
	var fname := "lockwright-pomiar-android-%s-%s.json" % [String(device.get("model", "phone")).replace(" ", "_"), stamp]
	var f := FileAccess.open("user://" + fname, FileAccess.WRITE)
	if f:
		f.store_string(text)
		f.close()
	var where: String = m.save_download(fname, text) if m else ""
	if not m:
		where = ProjectSettings.globalize_path("user://" + fname)

	_screen(_t("result_title"), "")
	body_l.queue_free()
	for r in rows:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)
		var icon := VerdictIcon.new()
		icon.kind = r[1][0]
		icon.color = V_COLORS[r[1][0]]
		icon.custom_minimum_size = Vector2(36, 36)
		row.add_child(icon)
		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var name_l := Label.new()
		name_l.text = "%s: %s" % [r[0], _t("v_" + r[1][0])]
		name_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		name_l.add_theme_font_override("font", font_body)
		name_l.add_theme_font_size_override("font_size", 21)
		name_l.add_theme_color_override("font_color", INK)
		col.add_child(name_l)
		var det := Label.new()
		det.text = r[1][1]
		det.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		det.add_theme_font_override("font", font_body)
		det.add_theme_font_size_override("font_size", 16)
		det.add_theme_color_override("font_color", MUTED)
		col.add_child(det)
		row.add_child(col)
		box.add_child(row)
	if where != "":
		_label(_t("saved") % where, 16, false, MUTED)
	for n in out["notes"]:
		_label("• " + String(n), 15, false, MUTED)
	_button(_t("share"), func() -> void: m.share_text(fname, text))
	_button(_t("again"), _screen_intro)
	print("LW_MEASURE ", JSON.stringify(out))


# ------------------------------------------------------------------ small widgets
class TapCircle extends Control:
	signal tapped
	var flash := 0.0

	func _gui_input(e: InputEvent) -> void:
		if (e is InputEventScreenTouch and e.pressed) or (e is InputEventMouseButton and e.pressed):
			tapped.emit()
			flash = 1.0
			queue_redraw()

	func _process(d: float) -> void:
		if flash > 0.0:
			flash = max(0.0, flash - d * 8.0)
			queue_redraw()

	func _draw() -> void:
		var c := size / 2.0
		var r: float = min(size.x, size.y) * 0.42
		draw_circle(c, r, Color(0.86, 0.80, 0.62).lerp(Color(0.95, 0.93, 0.88), flash))
		draw_arc(c, r, 0, TAU, 96, Color(0.12, 0.11, 0.10), 4.0)
		draw_circle(c, 10, Color(0.12, 0.11, 0.10))


class VerdictIcon extends Control:
	## Shape carries the verdict (not only colour): pass = filled circle, border = triangle,
	## fail = octagon, no data = hollow ring.
	var kind := "no_data"
	var color := Color.WHITE

	func _draw() -> void:
		var c := size / 2.0
		var r: float = min(size.x, size.y) * 0.45
		match kind:
			"pass":
				draw_circle(c, r, color)
			"border":
				draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r), c + Vector2(r * 0.95, r * 0.8), c + Vector2(-r * 0.95, r * 0.8)]), color)
			"fail":
				var pts := PackedVector2Array()
				for i in 8:
					pts.append(c + Vector2.from_angle(TAU * (i + 0.5) / 8.0) * r)
				draw_colored_polygon(pts, color)
			_:
				draw_arc(c, r * 0.85, 0, TAU, 48, color, 4.0)
