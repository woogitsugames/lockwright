extends Node
## Headless smoke test: autoloads, i18n completeness (PL+EN), haptics patterns.
## Run: godot --headless --path game res://tests/smoke.tscn

var _failures := 0


func _ready() -> void:
	_check_autoloads()
	_check_translations_loaded()
	_check_i18n()
	_check_haptics_patterns()
	if _failures == 0:
		print("SMOKE OK")
	else:
		print("SMOKE FAIL: %d failures" % _failures)
	await get_tree().process_frame
	get_tree().quit(1 if _failures > 0 else 0)


func _check_autoloads() -> void:
	for singleton in ["Settings", "Save", "I18n", "Events", "Haptics", "Sfx"]:
		if not get_tree().root.has_node(singleton):
			printerr("missing autoload: %s" % singleton)
			_failures += 1


func _check_translations_loaded() -> void:
	var locales: PackedStringArray = TranslationServer.get_loaded_locales()
	print("SMOKE locales loaded: %s" % str(locales))
	if not locales.has("pl") or not locales.has("en"):
		printerr("translations missing for pl/en")
		_failures += 1


func _check_i18n() -> void:
	var keys := ["menu.title", "settings.title", "pause.title", "workshop.title", "showcase.title", "about.notice", "lock.pause"]
	for locale in ["pl", "en"]:
		TranslationServer.set_locale(locale)
		for key in keys:
			var text := TranslationServer.translate(key)
			if text == key or text == "":
				printerr("missing %s for %s" % [locale, key])
				_failures += 1


func _check_haptics_patterns() -> void:
	var events := ["contact", "bind", "near_shear", "set", "false_set", "counter_rotate", "overset", "drop", "stress", "break", "wear", "gate_align", "detector_trip", "open"]
	for e in events:
		if Haptics.pattern_for(e).is_empty():
			printerr("missing haptics pattern: %s" % e)
			_failures += 1
	for c in ["tension_resistance", "pick_drag"]:
		if Haptics.continuous_pattern_for(c).is_empty():
			printerr("missing continuous pattern: %s" % c)
			_failures += 1
