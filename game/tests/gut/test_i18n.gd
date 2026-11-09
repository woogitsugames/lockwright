extends GutTest

## D-105: this script writes to the save; the scripts after it get it back unchanged.
var _save_backup: Dictionary


func before_all() -> void:
	_save_backup = Save.data.duplicate(true)


func after_all() -> void:
	Save.data = _save_backup
	Save.save()

const UI_KEYS := ["menu.title", "menu.play", "menu.workshop", "menu.showcase", "menu.settings", "menu.about",
	"settings.title", "settings.haptics", "settings.haptics_enabled", "settings.haptics_intensity",
	"settings.haptics_test", "settings.haptics_calibration", "settings.continuous_resistance",
	"settings.volume_master", "settings.volume_sfx", "settings.volume_ambience", "settings.language",
	"settings.dark_mode_assist", "settings.reading_aid", "settings.wide_windows", "settings.reset",
	"pause.title", "pause.resume", "pause.settings", "pause.dark_mode", "pause.restart", "pause.quit",
	"lock.pause", "workshop.title", "workshop.coins", "workshop.buy", "workshop.repair", "workshop.owned",
	"workshop.integrity", "showcase.title", "showcase.source", "about.title", "about.notice",
	"common.back", "common.on", "common.off", "common.coins"]

func test_every_key_has_pl_and_en() -> void:
	for key in UI_KEYS:
		TranslationServer.set_locale("pl")
		var pl := TranslationServer.translate(key)
		TranslationServer.set_locale("en")
		var en := TranslationServer.translate(key)
		assert_ne(pl, key, "missing PL: %s" % key)
		assert_ne(en, key, "missing EN: %s" % key)
		assert_ne(pl, "", "empty PL: %s" % key)
		assert_ne(en, "", "empty EN: %s" % key)

func test_fallback_is_en() -> void:
	assert_eq(ProjectSettings.get_setting("internationalization/locale/fallback"), "en")

func test_system_language_supported() -> void:
	assert_true(I18n.SUPPORTED.has(I18n.system_language()))


## N-67: all_keys() covers both CSV files and never touches an OptimizedTranslation.
func test_all_keys_both_csv_files() -> void:
	var keys := I18n.all_keys()
	assert_true(keys.has("menu.title"), "strings.csv key listed")
	var content_key := ""
	for k in keys:
		if String(k).begins_with("notebook.extra."):
			content_key = k
			break
	assert_ne(content_key, "", "content.csv keys listed (notebook.extra.* used by the menu tip)")


## N-67: the exported build loads the compiled .translation files; they must be plain
## Translations (import compress=0) so their keys can be listed.
func test_compiled_translations_list_keys() -> void:
	for base in ["res://i18n/strings", "res://i18n/content"]:
		for locale in ["pl", "en"]:
			var tr: Resource = load("%s.%s.translation" % [base, locale])
			assert_not_null(tr, "%s.%s compiled" % [base, locale])
			assert_false(tr is OptimizedTranslation, "%s.%s must not be OptimizedTranslation" % [base, locale])
	var fresh: Node = load("res://scripts/autoload/i18n.gd").new()
	assert_true(fresh._load_compiled_translations("res://i18n/strings.csv"))
	assert_true(fresh.all_keys().has("menu.title"), "keys from the compiled path")
	for locale in I18n.SUPPORTED:
		var p := "res://i18n/strings.%s.translation" % locale
		if ResourceLoader.exists(p):
			TranslationServer.remove_translation(load(p))
	fresh.free()


## T41: fr/es columns load (an empty fr/es cell would fall back to en; since the T42 keys got
## FR/ES from session A every cell is filled, so the T42 texts are checked in FR/ES here).
func test_fr_es_columns_and_fallback() -> void:
	var before := TranslationServer.get_locale()
	TranslationServer.set_locale("fr")
	assert_eq(TranslationServer.translate("settings.language_fr"), "Français (dev)")
	assert_eq(TranslationServer.translate("tutorial.say_master"), "Le maître montre le geste une fois. À toi.")
	assert_eq(TranslationServer.translate("family.dial_safe.name"), "Coffre-fort à cadran", "T42 in FR")
	TranslationServer.set_locale("es")
	assert_eq(TranslationServer.translate("tutorial.combo.step1"), "Pulgar izquierdo: tira un poco del arco.", "T42 in ES")
	assert_eq(TranslationServer.translate("job.allotment_shed.line.2"), "¿Tiene la tarjeta del huerto? ¿Y un vecino que lo confirme?")
	TranslationServer.set_locale(before)


## T41: FR/ES only with the dev flag (picker and device language); DE keeps its device-language path.
func test_fr_es_need_dev_flag() -> void:
	assert_eq(I18n.language_for_locale("fr_BE", false), "en")
	assert_eq(I18n.language_for_locale("es_ES", false), "en")
	assert_eq(I18n.language_for_locale("fr_BE", true), "fr")
	assert_eq(I18n.language_for_locale("es", true), "es")
	assert_eq(I18n.language_for_locale("de_DE", false), "de")
	assert_eq(I18n.language_for_locale("pl_PL", false), "pl")
	var dev = Save.get_value("dev_mode", false)
	var lang = Settings.get_value("language")
	Save.set_value("dev_mode", false)
	Settings.set_value("language", "fr")
	assert_ne(Settings.language(), "fr", "fr hidden without the dev flag")
	Save.set_value("dev_mode", true)
	assert_eq(Settings.language(), "fr")
	Save.set_value("dev_mode", dev)
	Settings.set_value("language", lang)


## T42: one hint key per v0.6 family, the _auto variant when the game holds the left thumb.
func test_family_hint_keys() -> void:
	var lj: GDScript = load("res://scripts/lock/lock_job.gd")
	assert_eq(lj.family_hint_key(&"dial_safe", false), "lock.dial_hint")
	assert_eq(lj.family_hint_key(&"dial_safe", true), "lock.dial_hint_auto")
	assert_eq(lj.family_hint_key(&"disc_detainer", true), "lock.disc_hint_auto")
	assert_eq(lj.family_hint_key(&"time_lock", true), "lock.time_lock_hint_auto")
	assert_eq(lj.family_hint_key(&"pin_tumbler", false), "", "older families use the tutorial coach")
	for fam in lj.HINT_FAMILIES:
		for auto in [false, true]:
			var key: String = lj.family_hint_key(fam, auto)
			assert_ne(key, "", "%s auto=%s has a hint" % [fam, auto])
			assert_true(I18n.t(StringName(key)).length() <= 56, "%s fits two lines" % key)
		for n in range(1, 6):
			assert_true(I18n.has_key(StringName("tutorial.%s.step%d" % [fam, n])), "%s step %d" % [fam, n])
		assert_true(I18n.has_key(StringName("family.%s.name" % fam)))
