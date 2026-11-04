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
