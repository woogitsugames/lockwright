extends GutTest

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
