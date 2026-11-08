extends GutTest
## D-96 (owner, replaces the D-93 RAM cap): "low" is a manual choice only. "auto" resolves to the
## frame-time pick, medium or high, on every phone; Settings shows what "auto" resolved to (N-99).

const GIB := 1073741824
var _backup: Dictionary


func before_each() -> void:
	_backup = {"quality_profile": Settings.get_value("quality_profile"), "quality_auto": Settings.get_value("quality_auto")}


func after_each() -> void:
	for k in _backup:
		Settings.set_value(k, _backup[k])
	Quality.physical_override = -1
	Quality.apply_profile(Settings.get_value("quality_profile", "auto"))


func test_auto_never_resolves_to_low() -> void:
	var Q := load("res://scripts/autoload/quality.gd")
	assert_eq(Q.auto_key("auto", "high"), "high")
	assert_eq(Q.auto_key("auto", "medium"), "medium")
	assert_eq(Q.auto_key("auto", "low"), "medium", "an old save's auto pick 'low' reads as medium")
	assert_eq(Q.auto_key("auto", "bogus"), "high")


func test_manual_choice_wins() -> void:
	var Q := load("res://scripts/autoload/quality.gd")
	assert_eq(Q.auto_key("low", "high"), "low", "low only when picked by hand")
	assert_eq(Q.auto_key("high", "medium"), "high")
	assert_eq(Q.auto_key("bogus", "high"), "high")


func test_small_ram_phone_keeps_auto() -> void:
	# the SM-A165F class (4 GB) no longer gets "low" automatically
	Quality.physical_override = int(3.57 * GIB)
	Settings.set_value("quality_profile", "auto")
	Settings.set_value("quality_auto", "medium")
	Quality.apply_profile("auto")
	assert_eq(Quality.current, Quality.PROFILES["medium"])
	assert_eq(Quality.resolved_name(), "medium")
	Settings.set_value("quality_profile", "low")
	Quality.apply_profile("low")
	assert_eq(Quality.current, Quality.PROFILES["low"])
	assert_eq(Quality.msaa_index(), 0, "manual low: no MSAA")


func test_low_profile_values() -> void:
	var low: Dictionary = Quality.PROFILES["low"]
	assert_eq(low["planb_scale"], 0.5, "lock section 0.5x")
	assert_eq(low["msaa"], 0, "no MSAA")


func test_meminfo_total_parses_proc_meminfo() -> void:
	var Q := load("res://scripts/autoload/quality.gd")
	var lines := PackedStringArray(["MemTotal:        3740844 kB", "MemFree:          123456 kB"])
	assert_eq(Q.meminfo_total(lines), 3740844 * 1024, "SM-A165F /proc/meminfo")
	assert_eq(Q.meminfo_total(PackedStringArray(["garbage"])), 0)
	assert_gt(Quality.physical_ram(), 0, "RAM known on the test machine")


func test_settings_shows_what_auto_resolved_to() -> void:
	# N-99: "Auto (medium)" in every UI language
	Settings.set_value("quality_profile", "auto")
	Settings.set_value("quality_auto", "medium")
	for lang in ["pl", "en", "de", "fr", "es"]:
		I18n.apply_language(lang)
		var label: String = Quality.auto_label()
		assert_true(I18n.has_key(&"settings.quality_auto_medium"), lang)
		assert_eq(label, I18n.t(&"settings.quality_auto_medium"), lang)
		assert_ne(label, I18n.t(&"settings.quality_auto_high"), "%s: says which profile" % lang)
	I18n.apply_language(Settings.language())
