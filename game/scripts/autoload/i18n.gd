extends Node
## I18n wrapper over TranslationServer. PL and EN from day one (CLAUDE.md).
## Every player-facing string goes through t(), never hardcoded.
## CSV files (i18n/*.csv) are the single source of truth and are loaded here,
## so headless runs and exports behave identically.

signal language_changed

const SUPPORTED := ["pl", "en", "de", "fr", "es"]
## T41 (D-59): FR/ES texts are in the CSV (columns fr/es) but incomplete (new T42 keys empty -> en)
## and without voices yet, so they are only offered with the dev flag and never picked from the
## device language without it. DE stays as before (dev flag in the picker, device language allowed).
const DEV_ONLY := ["fr", "es"]
const FALLBACK := "en"
const CSV_FILES := ["res://i18n/strings.csv", "res://i18n/content.csv"]

var _translations: Dictionary = {}  # locale -> Translation
## N-67: every message key from all CSV files (set). all_keys() reads this instead of
## Translation.get_message_list(): an exported OptimizedTranslation does not store its
## message list (warning "OptimizedTranslation does not store the message texts") and
## TranslationServer.get_translation_object() returns only one of the CSV files anyway.
var _keys: Dictionary = {}


func _ready() -> void:
	_load_csv_translations()
	apply_language(Settings.language())
	Settings.changed.connect(_on_settings_changed)


func _load_csv_translations() -> void:
	for path in CSV_FILES:
		_load_csv(path)


## D-112: texts of a content pack (res://packs/<id>/i18n/content.csv), added to the loaded ones.
## False (and silent) when the file is not there, e.g. a pack without texts of its own.
func add_csv(path: String) -> bool:
	if not FileAccess.file_exists(path) and not ResourceLoader.exists("%s.%s.translation" % [path.get_basename(), FALLBACK]):
		return false
	return _load_csv(path)


func _load_csv(path: String) -> bool:
	var rows := _parse_csv(path)
	if rows.is_empty():
		# R-28: in an exported pck the raw .csv is remapped away; load the compiled
		# .translation resources (stored next to the source in the pck) instead.
		if not _load_compiled_translations(path):
			push_error("I18n: cannot parse %s" % path)
			return false
		return true
	var header: PackedStringArray = rows[0]
	if header.is_empty() or header[0] != "keys":
		push_error("I18n: %s must start with 'keys' header" % path)
		return false
	var locales: Array = header.slice(1)
	var per_locale: Dictionary = {}
	for locale in locales:
		var tr := Translation.new()
		tr.locale = locale
		per_locale[locale] = tr
	for row in rows.slice(1):
		if row.is_empty() or row[0] == "":
			continue
		_keys[row[0]] = true
		for i in range(1, min(row.size(), header.size())):
			var locale: String = header[i]
			# empty cell (fr/es not translated yet): no message, TranslationServer falls back to en
			if per_locale.has(locale) and row[i] != "":
				per_locale[locale].add_message(row[0], row[i])
	for locale in per_locale:
		if not _translations.has(locale):
			_translations[locale] = per_locale[locale]
		else:
			for key in per_locale[locale].get_message_list():
				_translations[locale].add_message(key, per_locale[locale].get_message(key))
		TranslationServer.add_translation(per_locale[locale])
	return true


func _load_compiled_translations(path: String) -> bool:
	var base := path.get_basename()  # e.g. res://i18n/strings
	var found := false
	for locale in SUPPORTED:
		var tr_path := "%s.%s.translation" % [base, locale]
		if ResourceLoader.exists(tr_path):
			var tr := ResourceLoader.load(tr_path)
			if tr is Translation:
				TranslationServer.add_translation(tr)
				found = true
				# compiled with compress=false (i18n/*.csv.import) -> plain Translation with keys
				if not tr is OptimizedTranslation:
					for key in (tr as Translation).get_message_list():
						_keys[key] = true
	return found


func _parse_csv(path: String) -> Array:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return []
	var rows: Array = []
	var row: PackedStringArray = []
	var field := ""
	var in_quotes := false
	var text := file.get_as_text()
	var i := 0
	while i < text.length():
		var c := text[i]
		if in_quotes:
			if c == "\"":
				if i + 1 < text.length() and text[i + 1] == "\"":
					field += "\""
					i += 1
				else:
					in_quotes = false
			else:
				field += c
		else:
			if c == "\"":
				in_quotes = true
			elif c == ",":
				row.append(field)
				field = ""
			elif c == "\n":
				row.append(field)
				field = ""
				rows.append(row)
				row = []
			elif c != "\r":
				field += c
		i += 1
	if field != "" or not row.is_empty():
		row.append(field)
		rows.append(row)
	return rows


func _on_settings_changed() -> void:
	apply_language(Settings.language())


func system_language() -> String:
	return language_for_locale(OS.get_locale(), bool(Save.get_value("dev_mode", false)))


## Game language for an OS locale ("fr_BE" -> "fr"); DEV_ONLY languages need the dev flag.
static func language_for_locale(locale: String, dev_mode: bool) -> String:
	var os_lang := locale.split("_")[0].to_lower()
	if SUPPORTED.has(os_lang) and (dev_mode or not DEV_ONLY.has(os_lang)):
		return os_lang
	return FALLBACK


func apply_language(lang: String) -> void:
	if lang == "":
		lang = system_language()
	if not SUPPORTED.has(lang):
		lang = FALLBACK
	TranslationServer.set_locale(lang)
	language_changed.emit()


func current_language() -> String:
	return TranslationServer.get_locale()


func t(key: StringName) -> String:
	var text := TranslationServer.translate(key)
	if text == key or text == "":
		push_warning("I18n: missing translation for key %s" % key)
		return key
	if handed_key(key) and bool(Settings.get_value(&"swap_thumbs", false)):
		return swap_hands(text, current_language())
	return text


# --- D-90 "swap thumbs" (left-handed): control texts name the other thumb ---------------------
## Keys whose text names a thumb or screen side (tutorial, lock hints, control choice).
const HANDED_PREFIXES := ["tutorial.", "lock.", "ui.controls.", "a11y.lock_screen_"]
## "Just right" / "Genau richtig" are not sides.
const HANDED_EXCLUDE := ["tutorial.s1_binding"]
## Per language: word (lower case) -> the other side's word. FR has no "droite" target for
## "gauche" except after "à" / "la" / "moitié" ("à gauche" <-> "à droite"); thumbs are masculine.
const HAND_WORDS := {
	"en": {"left": "right", "right": "left"},
	"pl": {"lewy": "prawy", "lewa": "prawa", "lewą": "prawą", "lewej": "prawej", "lewego": "prawego",
		"lewym": "prawym", "lewo": "prawo", "lewe": "prawe", "lewemu": "prawemu",
		"prawy": "lewy", "prawa": "lewa", "prawą": "lewą", "prawej": "lewej", "prawego": "lewego",
		"prawym": "lewym", "prawo": "lewo", "prawe": "lewe", "prawemu": "lewemu"},
	"de": {"links": "rechts", "linke": "rechte", "linker": "rechter", "linken": "rechten",
		"linkes": "rechtes", "linkem": "rechtem", "rechts": "links", "rechte": "linke",
		"rechter": "linker", "rechten": "linken", "rechtes": "linkes", "rechtem": "linkem"},
	"fr": {"gauche": "droit", "droit": "gauche", "droite": "gauche"},
	"es": {"izquierda": "derecha", "izquierdo": "derecho", "izquierdas": "derechas",
		"izquierdos": "derechos", "derecha": "izquierda", "derecho": "izquierdo",
		"derechas": "izquierdas", "derechos": "izquierdos"},
}
static var _word_re: RegEx


static func handed_key(key: StringName) -> bool:
	var k := String(key)
	if k in HANDED_EXCLUDE:
		return false
	for p in HANDED_PREFIXES:
		if k.begins_with(p):
			return true
	return false


## The same sentence for the other hand (pure; tests check every handed key in 5 languages).
static func swap_hands(text: String, lang: String) -> String:
	var words: Dictionary = HAND_WORDS.get(lang, {})
	if words.is_empty():
		return text
	if _word_re == null:
		_word_re = RegEx.create_from_string("\\p{L}+")
	var out := ""
	var at := 0
	var prev := ""
	for m in _word_re.search_all(text):
		var w := m.get_string()
		out += text.substr(at, m.get_start() - at)
		var lw := w.to_lower()
		var rep: String = words.get(lw, "")
		if lang == "fr" and lw == "gauche" and prev in ["à", "la", "moitié"]:  # feminine: droite
			rep = "droite"
		if rep == "":
			out += w
		else:
			out += (rep.substr(0, 1).to_upper() + rep.substr(1)) if w.substr(0, 1) != lw.substr(0, 1) else rep
		at = m.get_end()
		prev = lw
	return out + text.substr(at)


func has_key(key: StringName) -> bool:
	var text := TranslationServer.translate(key)
	return text != key and text != ""


## All message keys (both CSV files), sorted. Never calls get_message_list() on an
## OptimizedTranslation (N-67).
func all_keys() -> PackedStringArray:
	var out := PackedStringArray(_keys.keys())
	out.sort()
	return out
