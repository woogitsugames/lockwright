extends Node
## I18n wrapper over TranslationServer. PL and EN from day one (CLAUDE.md).
## Every player-facing string goes through t(), never hardcoded.
## CSV files (i18n/*.csv) are the single source of truth and are loaded here,
## so headless runs and exports behave identically.

signal language_changed

const SUPPORTED := ["pl", "en"]
const FALLBACK := "en"
const CSV_FILES := ["res://i18n/strings.csv", "res://i18n/content.csv"]

var _translations: Dictionary = {}  # locale -> Translation


func _ready() -> void:
	_load_csv_translations()
	apply_language(Settings.language())
	Settings.changed.connect(_on_settings_changed)


func _load_csv_translations() -> void:
	for path in CSV_FILES:
		var rows := _parse_csv(path)
		if rows.is_empty():
			# R-28: in an exported pck the raw .csv is remapped away; load the compiled
			# .translation resources (stored next to the source in the pck) instead.
			if not _load_compiled_translations(path):
				push_error("I18n: cannot parse %s" % path)
			continue
		var header: PackedStringArray = rows[0]
		if header.is_empty() or header[0] != "keys":
			push_error("I18n: %s must start with 'keys' header" % path)
			continue
		var locales: Array = header.slice(1)
		var per_locale: Dictionary = {}
		for locale in locales:
			var tr := Translation.new()
			tr.locale = locale
			per_locale[locale] = tr
		for row in rows.slice(1):
			if row.is_empty() or row[0] == "":
				continue
			for i in range(1, min(row.size(), header.size())):
				var locale: String = header[i]
				if per_locale.has(locale):
					per_locale[locale].add_message(row[0], row[i])
		for locale in per_locale:
			if not _translations.has(locale):
				_translations[locale] = per_locale[locale]
			else:
				for key in per_locale[locale].get_message_list():
					_translations[locale].add_message(key, per_locale[locale].get_message(key))
			TranslationServer.add_translation(per_locale[locale])


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
	var os_lang := OS.get_locale().split("_")[0].to_lower()
	if SUPPORTED.has(os_lang):
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
	return text


func has_key(key: StringName) -> bool:
	var text := TranslationServer.translate(key)
	return text != key and text != ""


func all_keys() -> PackedStringArray:
	var tr := TranslationServer.get_translation_object(TranslationServer.get_locale())
	if tr == null:
		return PackedStringArray()
	return tr.get_message_list()
