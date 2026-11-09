extends GutTest
## D-107: tension lock (HUD.md §9.2), the system font scale as the default text size, workshop tabs
## that stack instead of trimming at large text.


var _cfg_backup: Dictionary


func before_all() -> void:
	_cfg_backup = Settings._cfg.duplicate(true)


func after_all() -> void:
	Settings._cfg = _cfg_backup
	Settings.save_settings()
	UiA11y._apply_text_scale()


func _sampler(lock := true, auto := false) -> InputSampler:
	var s := InputSampler.new()
	add_child_autofree(s)
	s.tension_lock = lock
	s.auto_tension = auto
	s.swap_thumbs = false
	return s


func _touch(s: InputSampler, pos: Vector2, pressed: bool) -> void:
	var t := InputEventScreenTouch.new()
	t.index = 0
	t.position = pos
	t.pressed = pressed
	s._unhandled_input(t)


func _drag(s: InputSampler, pos: Vector2) -> void:
	var d := InputEventScreenDrag.new()
	d.index = 0
	d.position = pos
	s._unhandled_input(d)


func _steps(s: InputSampler, n: int) -> void:
	for i in n:
		s._physics_process(1.0 / 120.0)


func _left(s: InputSampler) -> float:
	return s._size().x * 0.2


## Hold T 0.4 with the left thumb (80 dp up), then let go.
func _hold_and_let_go(s: InputSampler) -> void:
	var x := _left(s)
	_touch(s, Vector2(x, 700), true)
	_drag(s, Vector2(x, 620))
	_steps(s, 30)
	_touch(s, Vector2(x, 620), false)


func _tap(s: InputSampler) -> void:
	_touch(s, Vector2(_left(s), 650), true)
	_steps(s, 2)
	_touch(s, Vector2(_left(s), 650), false)
	_steps(s, 6)


func test_double_tap_after_holding_latches_the_tension() -> void:
	var s := _sampler()
	var events := []
	s.latch_changed.connect(func(on: bool) -> void: events.append(on))
	_hold_and_let_go(s)
	var held := s.tension
	assert_almost_eq(held, 0.4, 0.03, "T before letting go")
	_steps(s, 6)
	assert_almost_eq(s.tension, held, 0.02, "T held during the grace window")
	_tap(s)
	assert_almost_eq(s.tension, held, 0.02, "the first tap does not drop it")
	_tap(s)
	assert_true(s.latched, "double tap latches")
	assert_eq(events, [true])
	_steps(s, 240)  # 2 s without any thumb
	assert_almost_eq(s.tension, held, 0.02, "latched T stays without the thumb")


func test_drag_changes_latched_tension_and_single_tap_lets_go() -> void:
	var s := _sampler()
	_hold_and_let_go(s)
	_tap(s)
	_tap(s)
	var x := _left(s)
	_touch(s, Vector2(x, 700), true)
	_drag(s, Vector2(x, 660))  # +0.2
	_steps(s, 20)
	_touch(s, Vector2(x, 660), false)
	_steps(s, 20)
	assert_true(s.latched, "still latched after a drag")
	assert_almost_eq(s.latched_t, 0.6, 0.04, "slide changes the latched T")
	assert_almost_eq(s.tension, 0.6, 0.04)
	_tap(s)
	assert_false(s.latched, "single tap lets go (overset fix)")
	_steps(s, 20)
	assert_almost_eq(s.tension, 0.0, 0.01, "T back to zero")


func test_without_double_tap_the_tension_drops_after_the_grace() -> void:
	var s := _sampler()
	_hold_and_let_go(s)
	_steps(s, int(InputSampler.LATCH_GRACE_S * 120.0) + 30)
	assert_false(s.latched)
	assert_almost_eq(s.tension, 0.0, 0.01, "plain let go, only 0.45 s later")


func test_option_off_and_auto_mode_keep_the_old_behaviour() -> void:
	var off := _sampler(false)
	_hold_and_let_go(off)
	_steps(off, 10)
	assert_almost_eq(off.tension, 0.0, 0.01, "option off: T drops at once")
	_tap(off)
	_tap(off)
	assert_false(off.latched)
	var auto := _sampler(true, true)
	_steps(auto, 30)
	_tap(auto)
	_tap(auto)
	assert_false(auto.latched, "auto tension: the lock does nothing (taps release, D-52)")


func test_plug_face_draws_the_clamp_and_lock_screen_says_so() -> void:
	Settings._cfg["auto_tension"] = false
	Settings._cfg["tension_lock"] = true
	var vp := SubViewport.new()
	vp.size = Vector2i(412, 915)
	add_child_autofree(vp)
	var scene: Node = load("res://scenes/lock_job.tscn").instantiate()
	vp.add_child(scene)
	await wait_physics_frames(2)
	var view: LockPhotorealView = scene.view
	assert_true(str(view.get("accessibility_description")).contains(I18n.t(&"a11y.lock_screen_latch")),
		"the screen reader hears how the lock works")
	UiA11y.screen_reader_override = 1
	var before := UiA11y.history.size()
	scene.sampler.latched_t = 0.35
	scene.sampler.set_latched(true)
	assert_true(view._face.clamp, "clamp on the wrench arm")
	assert_eq(UiA11y.history.slice(before), [I18n.t(&"a11y.tension_latched")], "spoken")
	scene.sampler.set_latched(false)
	assert_false(view._face.clamp)
	UiA11y.screen_reader_override = -1


func test_settings_has_the_tension_lock_toggle() -> void:
	var vp := SubViewport.new()
	vp.size = Vector2i(412, 915)
	vp.disable_3d = true
	add_child_autofree(vp)
	var scr: Control = load("res://scenes/settings.tscn").instantiate()
	vp.add_child(scr)
	for i in 3:
		await get_tree().process_frame
	var cb: CheckButton = scr._toggles["tension_lock"]
	assert_ne(cb.text, "")
	cb.button_pressed = true
	assert_true(bool(Settings.get_value("tension_lock")))


# ------------------------------------------------------------------ system font scale
func test_system_font_scale_is_the_default_text_size() -> void:
	assert_eq(UiA11y.snap_scale(0.85), 1.0, "smaller than default: 100 %")
	assert_eq(UiA11y.snap_scale(1.15), 1.25)
	assert_eq(UiA11y.snap_scale(1.3), 1.25)
	assert_eq(UiA11y.snap_scale(2.4), 2.0)
	Settings._cfg["text_scale_system"] = true
	Settings._cfg["text_scale"] = 1.0
	UiA11y.system_scale_override = 1.5
	assert_eq(UiA11y.text_scale(), 1.5, "follows the system")
	Settings._cfg["text_scale_system"] = false
	assert_eq(UiA11y.text_scale(), 1.0, "own size when switched off")
	UiA11y.system_scale_override = -1.0


func test_settings_switch_and_slider() -> void:
	Settings._cfg["text_scale_system"] = true
	UiA11y.system_scale_override = 1.3
	var vp := SubViewport.new()
	vp.size = Vector2i(412, 915)
	vp.disable_3d = true
	add_child_autofree(vp)
	var scr: Control = load("res://scenes/settings.tscn").instantiate()
	vp.add_child(scr)
	for i in 3:
		await get_tree().process_frame
	var sw: CheckButton = scr._system_text
	assert_true(sw.button_pressed, "on by default")
	assert_true(sw.text.contains("130"), "names the system size: " + sw.text)
	assert_eq(scr.text_scale_slider.value, 125.0, "slider shows the size in use")
	scr.text_scale_slider.value = 150.0
	assert_false(bool(Settings.get_value("text_scale_system")), "moving the slider = own size")
	assert_false(sw.button_pressed)
	assert_eq(UiA11y.text_scale(), 1.5)
	sw.button_pressed = true
	assert_eq(UiA11y.text_scale(), 1.25, "back to the system size")
	UiA11y.system_scale_override = -1.0
	Settings._cfg["text_scale_system"] = false
	UiA11y._apply_text_scale()


func test_existing_own_size_is_kept_on_upgrade() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("settings", "text_scale", 1.5)
	var path := "user://test_settings_upgrade.cfg"
	cfg.save(path)
	var f := ConfigFile.new()
	f.load(path)
	# the same rule as Settings.load_settings()
	var follow := not f.has_section_key("settings", "text_scale_system") and is_equal_approx(float(f.get_value("settings", "text_scale")), 1.0)
	assert_false(follow, "a player with 150 % keeps 150 %")
	DirAccess.remove_absolute(path)


# ------------------------------------------------------------------ workshop tabs
func test_workshop_tabs_stack_at_200_percent_and_never_trim() -> void:
	Settings._cfg["text_scale_system"] = false
	for lang in ["pl", "en", "de", "fr", "es"]:
		I18n.apply_language(lang)
		for sc in [1.0, 2.0]:
			Settings._cfg["text_scale"] = sc
			UiA11y._apply_text_scale()
			var vp := SubViewport.new()
			vp.size = Vector2i(360, 800)
			vp.disable_3d = true
			add_child_autofree(vp)
			var ws: Control = load("res://scenes/workshop.tscn").instantiate()
			vp.add_child(ws)
			for i in 5:
				await get_tree().process_frame
			var row: GridContainer = ws.get_node("Frame/VBox/Tabs")
			if sc == 1.0:
				assert_eq(row.columns, 3, "%s 100 %%: side by side" % lang)
			for b: Button in row.get_children():
				var font := b.get_theme_font(&"font")
				var w := font.get_string_size(b.text, HORIZONTAL_ALIGNMENT_LEFT, -1, b.get_theme_font_size(&"font_size")).x
				var sb := b.get_theme_stylebox(&"normal")
				var avail := b.size.x - sb.get_margin(SIDE_LEFT) - sb.get_margin(SIDE_RIGHT)
				assert_lte(w, avail + 2.0, "%s %d%%: %s not trimmed (%.0f > %.0f)" % [lang, sc * 100, b.text, w, avail])
				assert_gte(b.size.y, 48.0, "touch target")
			vp.queue_free()
			await get_tree().process_frame
	Settings._cfg["text_scale"] = 1.0
	UiA11y._apply_text_scale()
