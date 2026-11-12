extends GutTest
## D-113: iOS Dynamic Type feeds the same "As in the system" text size as Android's font scale
## (D-107). The iOS GDExtension singleton `LockwrightHaptics` answers font_scale() = body text size of
## the user's category / 17 pt; UiA11y asks the singleton of either platform the same way. Settings
## shows what changed behind its back: the system size after coming back to the game, and the
## profile "Auto" resolved to when the 10 s measurement ends while the screen is open (N-99).


## The Android plugin as GDScript sees it: a JNISingleton answers has_method() only through
## has_java_method().
class FakeAndroid:
	extends RefCounted
	var scale := 1.3
	var methods := ["font_scale"]

	func has_java_method(m: StringName) -> bool:
		return methods.has(String(m))

	func font_scale() -> float:
		return scale


## The iOS GDExtension node: a plain bound method.
class FakeIos:
	extends RefCounted
	var scale := 1.0

	func font_scale() -> float:
		return scale


## An xcframework / AAR built before font_scale() existed.
class FakeOld:
	extends RefCounted

	func play(_e: StringName, _i: float, _m: StringName) -> void:
		pass


class FakeBroken:
	extends RefCounted
	var answer: Variant = null

	func font_scale() -> Variant:
		return answer


var _backup := {}


func before_each() -> void:
	for k in ["text_scale_system", "text_scale", "quality_profile", "quality_auto"]:
		_backup[k] = Settings.get_value(k)


func after_each() -> void:
	for k in _backup:
		Settings._cfg[k] = _backup[k]
	UiA11y.system_scale_override = -1.0
	UiA11y._refresh_system_scale()  # no native singleton in tests: back to 1.0
	UiA11y._apply_text_scale()
	Quality.apply_profile(Settings.get_value("quality_profile", "auto"))
	I18n.apply_language(Settings.language())


func test_both_platform_singletons_are_asked_the_same_way() -> void:
	assert_eq(UiA11y.bridge_font_scale(FakeAndroid.new()), 1.3, "Android: through has_java_method")
	var ios := FakeIos.new()
	ios.scale = 28.0 / 17.0
	assert_almost_eq(UiA11y.bridge_font_scale(ios), 28.0 / 17.0, 0.0001, "iOS: a bound method")
	var android_old := FakeAndroid.new()
	android_old.methods = []
	assert_eq(UiA11y.bridge_font_scale(android_old), 1.0, "an AAR without font_scale")
	assert_eq(UiA11y.bridge_font_scale(FakeOld.new()), 1.0, "an xcframework without font_scale")
	assert_eq(UiA11y.bridge_font_scale(null), 1.0, "desktop")


func test_nonsense_answers_fall_back_to_100_percent() -> void:
	var b := FakeBroken.new()
	for bad: Variant in [null, "big", 0.0, -1.0, NAN]:
		b.answer = bad
		assert_eq(UiA11y.bridge_font_scale(b), 1.0, "answer %s" % str(bad))
	b.answer = 2
	assert_eq(UiA11y.bridge_font_scale(b), 2.0, "an integer factor is fine")


func test_dynamic_type_categories_land_on_the_slider_steps() -> void:
	# body text points per content size category (Apple HIG): xSmall ... xxxLarge, then AX1 ... AX5
	var expected := {
		14.0: 1.0, 15.0: 1.0, 16.0: 1.0, 17.0: 1.0,  # up to the default "Large": never below 100 %
		19.0: 1.0, 21.0: 1.25, 23.0: 1.25,
		28.0: 1.75, 33.0: 2.0, 40.0: 2.0, 47.0: 2.0, 53.0: 2.0,  # accessibility sizes: capped at 200 %
	}
	Settings._cfg["text_scale_system"] = true
	var ios := FakeIos.new()
	var last := 0.0
	for points: float in expected:
		ios.scale = points / 17.0
		UiA11y._refresh_system_scale(ios)
		assert_eq(UiA11y.text_scale(), float(expected[points]), "%d pt body text" % int(points))
		assert_gte(UiA11y.text_scale(), last, "a larger category never gives smaller text")
		last = UiA11y.text_scale()


func test_theme_follows_dynamic_type_and_own_size_wins() -> void:
	Settings._cfg["text_scale_system"] = true
	var ios := FakeIos.new()
	ios.scale = 28.0 / 17.0
	UiA11y._refresh_system_scale(ios)
	var theme: Theme = load("res://theme/main.tres")
	assert_eq(theme.get_font_size(&"font_size", &"Label"), roundi(UiA11y.base_font_size(&"Label") * 1.75),
			"theme scaled when the system size arrives")
	Settings._cfg["text_scale_system"] = false
	Settings._cfg["text_scale"] = 1.0
	assert_eq(UiA11y.text_scale(), 1.0, "the player's own size is not overridden by Dynamic Type")


func test_change_is_signalled_once() -> void:
	UiA11y._refresh_system_scale()
	watch_signals(UiA11y)
	var ios := FakeIos.new()
	ios.scale = 21.0 / 17.0
	UiA11y._refresh_system_scale(ios)
	assert_signal_emit_count(UiA11y, "system_scale_changed", 1)
	UiA11y._refresh_system_scale(ios)  # focus-in again, nothing changed
	assert_signal_emit_count(UiA11y, "system_scale_changed", 1)


func _settings_screen() -> Control:
	var vp := SubViewport.new()
	vp.size = Vector2i(412, 915)
	vp.disable_3d = true
	add_child_autofree(vp)
	var scr: Control = load("res://scenes/settings.tscn").instantiate()
	vp.add_child(scr)
	for i in 3:
		await get_tree().process_frame
	return scr


func test_settings_shows_the_new_system_size_after_coming_back() -> void:
	Settings._cfg["text_scale_system"] = true
	var scr: Control = await _settings_screen()
	assert_true(scr._system_text.text.contains("100"), scr._system_text.text)
	var ios := FakeIos.new()
	ios.scale = 28.0 / 17.0  # the player picked the first accessibility size in iOS Settings
	UiA11y._refresh_system_scale(ios)
	assert_true(scr._system_text.text.contains("165"), "names the system size: " + scr._system_text.text)
	assert_eq(scr.text_scale_slider.value, 175.0, "slider shows the size in use")
	assert_true(bool(Settings.get_value("text_scale_system")), "still following the system")
	assert_eq(scr.get_node(scr.S + "Access/Box/TextScaleRow/Value").text, "175%")


func test_settings_auto_label_follows_the_measurement() -> void:
	# N-99: the 10 s frame-time pick can land while Settings is open
	Settings._cfg["quality_profile"] = "auto"
	for lang in ["pl", "en", "de", "fr", "es"]:
		I18n.apply_language(lang)
		Settings._cfg["quality_auto"] = "high"
		var scr: Control = await _settings_screen()
		assert_eq(scr.quality_option.get_item_text(0), I18n.t(&"settings.quality_auto_high"), lang)
		Settings._cfg["quality_auto"] = "medium"  # what Quality._process does when the window ends
		Quality.profile_changed.emit(Quality.PROFILES["medium"])
		assert_eq(scr.quality_option.get_item_text(0), I18n.t(&"settings.quality_auto_medium"),
				"%s: Auto names the profile just picked" % lang)
		assert_eq(scr.quality_option.selected, 0, "the choice itself stays Auto")
		scr.queue_free()
		await get_tree().process_frame
	Quality.profile_changed.emit(Quality.PROFILES["high"])  # no freed screen is called
	pass_test("no error after the screens are gone")


func test_ios_plugin_source_binds_font_scale() -> void:
	# the iOS library is only built on macOS CI (game-ios); keep the method name the game calls
	var root := ProjectSettings.globalize_path("res://").path_join("../platform/ios/lockwright_haptics")
	var mm := root.path_join("Sources/lockwright_haptics.mm")
	if not FileAccess.file_exists(mm):
		pass_test("platform/ is not part of this run (exported pack)")
		return
	var src := FileAccess.get_file_as_string(mm)
	assert_true(src.contains('D_METHOD("font_scale")'), "font_scale is bound for GDScript")
	assert_true(src.contains("preferredContentSizeCategory"), "reads Dynamic Type")
	var header := FileAccess.get_file_as_string(root.path_join("include/lockwright_haptics/lockwright_haptics.h"))
	assert_true(header.contains("double font_scale() const;"))
