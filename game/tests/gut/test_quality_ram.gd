extends GutTest
## D-93: "auto" quality is capped at "low" on phones with <= 4 GB RAM; a profile picked in Settings wins.

const GIB := 1073741824
var _backup: Dictionary
var _cap := ""


func before_each() -> void:
	_backup = {"quality_profile": Settings.get_value("quality_profile"), "quality_auto": Settings.get_value("quality_auto")}
	_cap = Quality.ram_cap


func after_each() -> void:
	for k in _backup:
		Settings.set_value(k, _backup[k])
	Quality.physical_override = -1
	Quality.ram_cap = _cap
	Quality.apply_profile(Settings.get_value("quality_profile", "auto"))


func test_cap_by_ram() -> void:
	var Q := load("res://scripts/autoload/quality.gd")
	assert_eq(Q.cap_for_ram(int(3.6 * GIB)), "low", "SM-A165F class (4 GB, ~3.6 GiB reported)")
	assert_eq(Q.cap_for_ram(4 * GIB), "low")
	assert_eq(Q.cap_for_ram(int(5.6 * GIB)), "", "6 GB phone: no cap")
	assert_eq(Q.cap_for_ram(8 * GIB), "")
	assert_eq(Q.cap_for_ram(0), "", "unknown RAM: no cap")


func test_capped_picks_the_lower_profile() -> void:
	var Q := load("res://scripts/autoload/quality.gd")
	assert_eq(Q.capped("high", "low"), "low")
	assert_eq(Q.capped("medium", "low"), "low")
	assert_eq(Q.capped("high", ""), "high")
	assert_eq(Q.capped("low", "medium"), "low")


func test_auto_key_respects_manual_choice() -> void:
	var Q := load("res://scripts/autoload/quality.gd")
	assert_eq(Q.auto_key("auto", "high", "low"), "low", "auto on a 4 GB phone")
	assert_eq(Q.auto_key("auto", "medium", ""), "medium", "auto elsewhere: frame-time pick")
	assert_eq(Q.auto_key("high", "low", "low"), "high", "hand-picked high stays high on 4 GB")
	assert_eq(Q.auto_key("bogus", "high", ""), "high")


func test_low_profile_values() -> void:
	var low: Dictionary = Quality.PROFILES["low"]
	assert_eq(low["planb_scale"], 0.5, "lock section 0.5x")
	assert_eq(low["msaa"], 0, "no MSAA")


func test_quality_applies_ram_cap_in_auto() -> void:
	Settings.set_value("quality_profile", "auto")
	Settings.set_value("quality_auto", "high")
	Quality.physical_override = int(3.6 * GIB)
	Quality.ram_cap = Quality.cap_for_ram(Quality.physical_ram())
	Quality.apply_profile("auto")
	assert_eq(Quality.current, Quality.PROFILES["low"])
	assert_eq(Quality.msaa_index(), 0)
	Settings.set_value("quality_profile", "high")
	Quality.apply_profile("high")
	assert_eq(Quality.current, Quality.PROFILES["high"], "manual override")
	Quality.physical_override = 8 * GIB
	Quality.ram_cap = Quality.cap_for_ram(Quality.physical_ram())
	Quality.apply_profile("auto")
	assert_eq(Quality.current, Quality.PROFILES["high"], "8 GB phone keeps the frame-time pick")


func test_meminfo_total_parses_proc_meminfo() -> void:
	var Q := load("res://scripts/autoload/quality.gd")
	var lines := PackedStringArray(["MemTotal:        3740844 kB", "MemFree:          123456 kB"])
	assert_eq(Q.meminfo_total(lines), 3740844 * 1024, "SM-A165F /proc/meminfo")
	assert_eq(Q.cap_for_ram(Q.meminfo_total(lines)), "low")
	assert_eq(Q.meminfo_total(PackedStringArray(["garbage"])), 0)
