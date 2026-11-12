extends "res://scripts/autoload/pack_store.gd"
## D-62/D-100: voice lines for languages beyond EN are downloaded on demand.
## Only EN lines ship in the package (D-100). Every other language (PL, DE, FR, ES) is one data-only pck
## (`voice_<lang>.pck`, built by tools/build_voice_packs.py) listed in
## res://data/voice_packs.json with its size and SHA-256. The hash is part of the app,
## so a pack is trusted only when it matches the build the player has.
##
## Flow: ensure(lang) -> HTTP GET (Range resume from <dir>/voice_<lang>.pck.part)
## -> SHA-256 in small per-frame steps -> rename -> ProjectSettings.load_resource_pack.
## After that Sfx.line_clip_path() finds res://assets/audio/lines/<lang>/... and the
## DialoguePlayer plays the clips. Offline or failed: nothing waits for it, the dialogue
## stays subtitle-only (as it always is without a clip).
## Privacy: one plain GET for a static file; no ids, no cookies, no analytics.
## D-100 (owner): EN ships; the phone/game language is fetched in the background on the first
## run (a short non-blocking note with the size and progress, subtitles meanwhile; offline ->
## retried later); the rest is up to the player in Settings -> Voices (download / remove; EN
## cannot be removed). Settings "voice_download": "auto" (default: fetch the game language;
## the old "ask" means the same) or "manual" (offer only). A pack the player removed is never
## fetched again on its own. Packs cannot be unmounted: a removed pack stops playing at once
## (blocks() -> Sfx.line_clip_path) and its file is deleted (at the next start if it was busy).
## The download, verification and storage live in pack_store.gd (shared with ContentPacks, D-112).

const BUNDLED := ["en"]           # D-100: only EN ships in the game package
const ORDER := ["en", "pl", "de", "fr", "es"]   # Settings -> Voices list order
const MANIFEST_PATH := "res://data/voice_packs.json"
const DIR := "user://voice_packs"
const RETRY_S := [60.0, 300.0, 900.0, 1800.0]   # automatic download failed offline: try later
const NOTE_HIDE_S := 4.0

# Overridable by tests / dev builds before the node enters the tree.
var auto_follow_language := true  # react to Settings language changes
## Automatic background download of the game language (D-100). Exported builds only by
## default: editor/CI runs (GUT, screenshots) never touch the network on their own.
var auto_download := OS.has_feature("template")
var show_note := true             # the small download note over the game (automatic downloads)

var _last_lang := ""
var _auto_jobs := {}              # lang -> true: started by auto(): shows the note, retried
var _retry_n := {}                # lang -> automatic retries so far
var _note: Control
var _note_label: Label
var _note_pct := -1


func _init() -> void:
	manifest_path = MANIFEST_PATH
	dir = DIR


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(false)
	state_changed.connect(_on_job_event)
	progress.connect(func(lang: String, _r: int, _t: int) -> void: _update_note(lang))
	reload()
	if auto_follow_language and get_node_or_null("/root/Settings") != null:
		_last_lang = Settings.language()
		Settings.changed.connect(_on_settings_changed)
		if auto_download:
			auto.call_deferred(_last_lang)


# --- queries -------------------------------------------------------------------------

func is_bundled(lang: String) -> bool:
	return BUNDLED.has(lang)


func file_name(lang: String) -> String:
	return "voice_%s.pck" % lang


## True when clips of `lang` must not play even if their files resolve (a removed pack, or
## a pack not installed, in an exported build). Sfx.line_clip_path() asks this.
func blocks(lang: String) -> bool:
	return enforce and not is_ready(lang)


## Settings -> Voices: EN first, then every language the manifest offers.
func languages() -> Array:
	var out := []
	for lang in ORDER:
		if is_bundled(lang) or has_pack(lang):
			out.append(lang)
	var packs: Variant = _manifest.get("packs", {})
	if packs is Dictionary:
		for lang in packs:
			if not out.has(lang):
				out.append(lang)
	return out


## What to do when the game language becomes `lang` with download mode `mode` (D-100):
## "none" (nothing to fetch), "download" (start in the background; "auto" and the old
## default "ask"), "offer" ("manual", or a pack the player removed: size + Download only).
func policy(lang: String, mode: String) -> String:
	if is_ready(lang) or not has_pack(lang):
		return "none"
	if _jobs.has(lang):
		return "download"
	if mode == "manual" or _removed.has(lang):
		return "offer"
	return "download"


# --- actions -------------------------------------------------------------------------

func cancel(lang: String) -> void:
	_auto_jobs.erase(lang)
	var busy := _jobs.has(lang)
	super.cancel(lang)
	if busy:
		_hide_note()


## D-100: background download of the game language — first run and every start until it is
## installed (offline -> retried later); never for EN, a removed pack or mode "manual".
func auto(lang: String) -> bool:
	if lang == "" or is_ready(lang) or not has_pack(lang):
		return false
	if policy(lang, str(Settings.get_value("voice_download", "auto"))) != "download":
		return false
	_auto_jobs[lang] = true
	ensure(lang)
	_update_note(lang)
	return true


## The download note's text while it is shown, else "" (tests, accessibility).
func note_text() -> String:
	return _note_label.text if _note != null and _note.visible else ""


func _on_settings_changed() -> void:
	var lang := Settings.language()
	if lang == _last_lang:
		return
	_last_lang = lang
	if auto_download:
		auto(lang)


# --- D-100: the small download note (non-blocking, ignores input, above the bottom safe area) --

func _update_note(lang: String) -> void:
	if not show_note or not _auto_jobs.has(lang) or not is_inside_tree():
		return
	var st := state(lang)
	var text := ""
	match st:
		"downloading", "verifying":
			var pct := 100 if st == "verifying" else roundi(progress_ratio(lang) * 100.0)
			if pct == _note_pct and _note != null and _note.visible:
				return
			_note_pct = pct
			text = _tr(&"voicepack.note.downloading").format({"title": _title(lang),
					"size": size_text(pack_size(lang), _locale()), "pct": pct})
		"installed":
			text = _tr(&"voicepack.note.ready").format({"title": _title(lang)})
		"failed":
			text = _tr(&"voicepack.note.later").format({"title": _title(lang)})
		_:
			return
	_show_note(text, st in ["installed", "failed"])


func _show_note(text: String, then_hide: bool) -> void:
	if _note == null:
		var layer := CanvasLayer.new()
		layer.name = "VoicePackNoteLayer"
		layer.layer = 90
		add_child(layer)
		_note = PanelContainer.new()
		_note.name = "VoicePackNote"
		_note.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_note_label = Label.new()
		_note_label.name = "Text"
		_note_label.theme_type_variation = &"Caption"
		_note_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_note_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_note_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_note.add_child(_note_label)
		layer.add_child(_note)
	_note_label.text = text
	_note.visible = true
	_place_note()
	if then_hide:
		var shown := text
		get_tree().create_timer(NOTE_HIDE_S).timeout.connect(func() -> void:
			if _note != null and _note_label.text == shown:
				_hide_note())


func _place_note() -> void:
	var vp := get_viewport()
	if _note == null or vp == null:
		return
	var r := vp.get_visible_rect()
	var ins: Vector4 = SafeArea.insets(_note)
	var w := minf(r.size.x - 32.0 - ins.x - ins.z, 520.0)
	_note.custom_minimum_size = Vector2(w, 0)
	_note.reset_size()
	_note.position = Vector2(r.position.x + (r.size.x - w) * 0.5, r.end.y - ins.w - 16.0 - _note.size.y)


func _hide_note() -> void:
	if _note != null:
		_note.visible = false
	_note_pct = -1


func _title(lang: String) -> String:
	var k := StringName("settings.voice_pack.title_" + lang)
	var t := _tr(k)
	return lang.to_upper() if t == String(k) or t == "" else t


func _tr(key: StringName) -> String:
	return I18n.t(key) if get_node_or_null("/root/I18n") != null else String(key)


func _locale() -> String:
	return I18n.current_language() if get_node_or_null("/root/I18n") != null else "en"


## Automatic downloads: keep the note in step, and after an offline failure try again later.
func _on_job_event(lang: String) -> void:
	if not _auto_jobs.has(lang):
		return
	_update_note(lang)
	match state(lang):
		"installed":
			_auto_jobs.erase(lang)
			_retry_n.erase(lang)
		"failed":
			_auto_jobs.erase(lang)
			if last_error(lang) in ["offline", "timeout", "interrupted"] and is_inside_tree():
				var n := int(_retry_n.get(lang, 0))
				_retry_n[lang] = n + 1
				get_tree().create_timer(retry_delay(n)).timeout.connect(func() -> void:
					if auto_download and state(lang) in ["failed", "missing"]:
						auto(lang))


## Seconds before the n-th automatic retry (0-based): 1 min, 5 min, 15 min, then every 30 min.
static func retry_delay(n: int) -> float:
	return RETRY_S[clampi(n, 0, RETRY_S.size() - 1)]
