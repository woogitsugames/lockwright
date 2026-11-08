extends GutTest
## D-90 accessibility audit (docs/ACCESSIBILITY.md):
## - every interactive control of every screen has a spoken name (screen reader), the lock screens'
##   text-less controls (pause flap, loupe, warded bit) are named buttons with an activate action;
## - lock state changes are announced (short, localized, throttled) only with a screen reader;
## - sound captions name the gameplay sounds (set click) on screen;
## - reduce motion (setting or system) removes movement but keeps every piece of information;
## - text scale 100-200 % scales every theme font size, and the menu screens still fit 360x800,
##   412x915 and 915x412 in all five languages;
## - "swap thumbs" (left-handed) swaps the thumb zones and the thumb words of the control texts.

const SCREENS := [
	"res://scenes/main_menu.tscn",
	"res://scenes/settings.tscn",
	"res://scenes/workshop.tscn",
	"res://scenes/jobs_list.tscn",
	"res://scenes/showcase.tscn",
	"res://scenes/job_arrival.tscn",
	"res://scenes/job_verify.tscn",
	"res://scenes/job_payment.tscn",
	"res://scenes/control_choice.tscn",
]
const SIZES := [Vector2i(360, 800), Vector2i(412, 915), Vector2i(915, 412)]
const LANGS := ["pl", "en", "de", "fr", "es"]
const ARRIVAL_JOB := "job.kiosk_shutter"   # the plain arrival screen (no D-58 scene: D-94 gave bike_interview one)

var _save_backup: Dictionary
var _settings_backup: Dictionary
var _lang := ""


func before_all() -> void:
	_save_backup = Save.data.duplicate(true)
	_settings_backup = Settings._cfg.duplicate(true)
	_lang = I18n.current_language()


func after_all() -> void:
	Save.data = _save_backup
	Save.save()
	Settings._cfg = _settings_backup
	Settings.save_settings()
	Settings.changed.emit()
	I18n.apply_language(_lang)


func after_each() -> void:
	UiA11y.screen_reader_override = -1
	UiA11y.reduce_motion_override = -1
	Settings._cfg["text_scale"] = 1.0
	Settings._cfg["swap_thumbs"] = false
	Settings._cfg["announce_lock_events"] = true
	Settings._cfg["sound_captions"] = false
	Settings._cfg["reduce_motion"] = false
	UiA11y._apply_text_scale()
	JobRun.current_job = {}


func _open(path: String, size: Vector2i) -> Control:
	if path.ends_with("job_arrival.tscn") or path.ends_with("job_verify.tscn") or path.ends_with("job_payment.tscn"):
		JobRun.start(JobRun.job_by_id(ARRIVAL_JOB))
	var vp := SubViewport.new()
	vp.size = size
	vp.disable_3d = true
	add_child_autofree(vp)
	var scene: Control = load(path).instantiate()
	vp.add_child(scene)
	for i in 4:
		await get_tree().process_frame
	return scene


func _walk(n: Node, out: Array) -> void:
	for c in n.get_children():
		if c is Control and c.is_visible_in_tree():
			out.append(c)
		_walk(c, out)


## Rows where a trimmed one-line plate is accepted at 200 % (workshop tab plates: fit_button_text
## shrinks them first; the full text stays the plate's accessible name).
const TRUNCATE_OK_PARENTS := ["Tabs"]


## A one-line Label/Button whose text does not fit (ellipsis or clipped).
static func _truncated(c: Control) -> bool:
	if not (c is Label or c is Button) or c.text == "":
		return false
	if c is Button and (c as Button).icon != null:
		return false
	if c.text_overrun_behavior == TextServer.OVERRUN_NO_TRIMMING and not c.get("clip_text"):
		return false
	if c.autowrap_mode != TextServer.AUTOWRAP_OFF:
		return false
	var font: Font = c.get_theme_font(&"font")
	var w := font.get_string_size(c.text, HORIZONTAL_ALIGNMENT_LEFT, -1, c.get_theme_font_size(&"font_size")).x
	var avail := c.size.x
	var sb: StyleBox = c.get_theme_stylebox(&"normal")
	if sb:
		avail -= sb.get_margin(SIDE_LEFT) + sb.get_margin(SIDE_RIGHT)
	return w > avail + 2.0


static func _interactive(c: Control) -> bool:
	if c.mouse_filter == Control.MOUSE_FILTER_IGNORE:
		return false
	return c is BaseButton or c is Range and not c is ScrollBar or c is LineEdit or c is A11yHit or c is PauseFlap


# ------------------------------------------------------------------ 1. screen reader names
func test_every_interactive_control_has_a_spoken_name_on_every_screen() -> void:
	for path in SCREENS:
		for lang in ["pl", "en"]:
			I18n.apply_language(lang)
			var scene := await _open(path, Vector2i(412, 915))
			var controls: Array = []
			_walk(scene, controls)
			var n := 0
			for c: Control in controls:
				if not _interactive(c):
					continue
				n += 1
				var spoken := UiA11y.spoken_name(c)
				assert_ne(spoken.strip_edges(), "", "%s [%s]: %s has no spoken name" % [path.get_file(), lang, scene.get_path_to(c)])
				assert_false(I18n.has_key(StringName(spoken)), "%s [%s]: %s reads a raw key '%s'" % [path.get_file(), lang, scene.get_path_to(c), spoken])
			assert_gt(n, 0, path.get_file() + ": has interactive controls")
			scene.get_parent().queue_free()
			await get_tree().process_frame


func test_lock_screens_name_pause_loupe_and_bit() -> void:
	var scenes := {&"pin_tumbler": "res://scenes/lock_job.tscn"}
	scenes.merge(JobRun.PLANB_SCENES)
	for fam in scenes:
		var vp := SubViewport.new()
		vp.size = Vector2i(412, 915)
		add_child(vp)
		var scene: Node = load(scenes[fam]).instantiate()
		vp.add_child(scene)
		await wait_physics_frames(2)
		var view: LockPhotorealView = scene.view
		var flap: Control = view.get_node("PauseFlap")
		var loupe: Control = view.get_node("LoupeButton")
		assert_eq(str(flap.get("accessibility_name")), I18n.t(&"a11y.pause"), "%s: pause flap named" % fam)
		assert_eq(str(loupe.get("accessibility_name")), I18n.t(&"a11y.loupe"), "%s: loupe named" % fam)
		assert_true((flap.get_meta(&"a11y_click") as Callable).is_valid(), "%s: flap has an activate action" % fam)
		assert_true((loupe.get_meta(&"a11y_click") as Callable).is_valid(), "%s: loupe has an activate action" % fam)
		assert_ne(str(view.get("accessibility_description")), "", "%s: the lock screen describes the thumbs" % fam)
		if view.get("bit_button") != null:
			assert_eq(str(view.bit_button.get("accessibility_name")), I18n.t(&"a11y.warded_bit"), "warded bit named")
		# the activate action of the loupe really toggles it (what a double tap in TalkBack/VoiceOver does)
		(loupe.get_meta(&"a11y_click") as Callable).call()
		assert_true(view.zoomed, "%s: activate opens the loupe" % fam)
		view.toggle_loupe()
		vp.queue_free()
		await get_tree().process_frame


# ------------------------------------------------------------------ 1b. lock announcements
func _lines_said(events: Array) -> Array:
	var before := UiA11y.history.size()
	for e in events:
		Events.lock_event.emit(e)
	return UiA11y.history.slice(before)


func test_lock_state_changes_are_announced_with_a_screen_reader() -> void:
	I18n.apply_language("en")
	UiA11y.screen_reader_override = 1
	UiA11y._last_said.clear()
	var said := _lines_said([
		{"kind": &"bind", "element": 2}, {"kind": &"set", "element": 2}, {"kind": &"false_set", "element": 0},
		{"kind": &"overset", "element": 4}, {"kind": &"stress", "element": -1}, {"kind": &"open", "element": -1}])
	assert_eq(said, ["3: binding", "3: set", "1: false set — caught too deep",
		"5: pushed too high — let go of the tension", "The tool is bending — ease off", "Open"])
	# near_shear / contact stay silent; a second bind of the same element right away too
	said = _lines_said([{"kind": &"near_shear", "element": 1}, {"kind": &"contact", "element": 1},
		{"kind": &"bind", "element": 1}, {"kind": &"bind", "element": 1}])
	assert_eq(said, ["2: binding"], "throttled and filtered")


func test_no_announcements_without_screen_reader_or_when_off() -> void:
	UiA11y.screen_reader_override = 0
	UiA11y._last_said.clear()
	assert_eq(_lines_said([{"kind": &"set", "element": 0}]), [], "no screen reader: silent")
	UiA11y.screen_reader_override = 1
	Settings._cfg["announce_lock_events"] = false
	assert_eq(_lines_said([{"kind": &"set", "element": 0}]), [], "switched off in Settings: silent")


func test_every_lock_line_exists_in_five_languages() -> void:
	for lang in LANGS:
		I18n.apply_language(lang)
		for kind in UiA11y.LOCK_LINES:
			var line := UiA11y.lock_line({"kind": kind, "element": 2})
			assert_ne(line, "", "%s %s" % [lang, kind])
			assert_false(line.begins_with("a11y."), "%s %s translated" % [lang, kind])
			if I18n.t(UiA11y.LOCK_LINES[kind]).contains("{n}"):
				assert_true(line.begins_with("3"), "%s %s names the element: %s" % [lang, kind, line])
		for key in SoundCaptions.KEYS.values():
			assert_true(I18n.has_key(key), "%s caption %s" % [lang, key])
			assert_true(I18n.t(key).begins_with("["), "%s caption %s in brackets" % [lang, key])


# ------------------------------------------------------------------ 5. captions
func test_sound_captions_show_the_set_click() -> void:
	I18n.apply_language("en")
	var cap := SoundCaptions.new()
	add_child_autofree(cap)
	await get_tree().process_frame
	Events.lock_event.emit({"kind": &"set", "element": 1})
	assert_false(cap.visible, "off by default")
	cap.enabled_override = 1
	Events.lock_event.emit({"kind": &"set", "element": 1})
	assert_true(cap.visible, "shown")
	assert_eq(cap.label.text, "[crisp click]")
	Events.lock_event.emit({"kind": &"bind", "element": 2})
	assert_eq(cap.label.text, "[crisp click]", "a scrape never hides a set")
	Events.lock_event.emit({"kind": &"false_set", "element": 2})
	assert_eq(cap.label.text, "[dull double click]", "false set outranks set")
	assert_eq(SoundCaptions.caption_key({"kind": &"false_set", "name": "pin.serration"}), &"a11y.sfx.serration")
	cap._process(SoundCaptions.SHOW_S + 0.1)
	assert_false(cap.visible, "gone after 1.2 s")
	cap.dark = true
	Events.lock_event.emit({"kind": &"set", "element": 1})
	assert_false(cap.visible, "never in the dark")


func test_lock_view_has_caption_strip_and_hides_it_in_the_dark() -> void:
	var vp := SubViewport.new()
	vp.size = Vector2i(412, 915)
	add_child_autofree(vp)
	var scene: Node = load("res://scenes/lock_job.tscn").instantiate()
	vp.add_child(scene)
	await wait_physics_frames(2)
	var cap: SoundCaptions = scene.view.get_node("SoundCaptions")
	assert_not_null(cap)
	assert_true(Rect2(Vector2.ZERO, Vector2(412, 915)).encloses(Rect2(cap.position, cap.size)), "strip on screen")
	assert_true(cap.position.y + cap.size.y <= scene.view.tray_rect.position.y, "strip above the roll")
	scene.view.set_dark(true)
	assert_true(cap.dark)


# ------------------------------------------------------------------ 2. reduce motion
func test_reduce_motion_follows_setting_and_override() -> void:
	Settings._cfg["reduce_motion"] = true
	assert_true(UiA11y.reduce_motion(), "setting")
	Settings._cfg["reduce_motion"] = false
	UiA11y.reduce_motion_override = 1
	assert_true(UiA11y.reduce_motion(), "override (system Reduce Motion path)")


func test_reduce_motion_paths_keep_the_information() -> void:
	UiA11y.reduce_motion_override = 1
	# screen fade: content shown at once
	var c := Control.new()
	add_child_autofree(c)
	ScreenFrame.enter(c)
	assert_eq(c.modulate.a, 1.0, "no fade-in")
	# pause flap: the pause comes at once, no lift tween
	var flap := PauseFlap.new()
	add_child_autofree(flap)
	var got := []
	flap.pressed.connect(func() -> void: got.append(1))
	flap.press()
	assert_eq(got.size(), 1, "pause without the lift animation")
	# eyepiece snaps open
	var eye := Eyepiece.new()
	add_child_autofree(eye)
	eye.set_open(true)
	eye.tick(0.001)
	assert_eq(eye._open, 1.0, "loupe opens without the zoom-in")
	# plug face: the near-break tremor is gone, the bend stays
	var face := PlugFace.new()
	add_child_autofree(face)
	face.tremor = 1.0
	assert_true(UiA11y.reduce_motion())
	# arrival + day-after: hold frame instead of the camera move (their own tests cover the frames)
	assert_true(load("res://scripts/ui/job_arrival.gd").new()._scene_reduce_motion(), "arrival: hold frame")


func test_reduce_motion_freezes_pick_tremor_near_break() -> void:
	var vp := SubViewport.new()
	vp.size = Vector2i(412, 915)
	add_child_autofree(vp)
	var scene: Node = load("res://scenes/lock_job.tscn").instantiate()
	vp.add_child(scene)
	await wait_physics_frames(2)
	var view: LockPhotorealView = scene.view
	var vm: Dictionary = load("res://scripts/photoreal/lock_photoreal.gd").blender_pose_vm()
	vm["stress"] = 0.95
	UiA11y.reduce_motion_override = 1
	var bends := {}
	for i in 6:
		view.present(vm, {"tension": 0.35, "pick_depth": 0.5, "pick_lift": 0.3}, 1.0)
		bends[snappedf(float(view._pick_mat.get_shader_parameter("bend")), 0.0001)] = true
		await get_tree().create_timer(0.03).timeout
	assert_eq(bends.size(), 1, "one steady bend under reduce motion")
	assert_almost_eq(bends.keys()[0], LockPhotorealView.PICK_BEND_MM * 0.95, 0.001, "bend still shows the stress")


# ------------------------------------------------------------------ 4. text scale
func test_text_scale_scales_every_theme_font_size() -> void:
	var theme: Theme = load("res://theme/main.tres")
	for s in [1.25, 1.5, 2.0]:
		Settings._cfg["text_scale"] = s
		UiA11y._apply_text_scale()
		for type in ["Label", "Button", "Caption", "Heading", "Title", "CheckButton", "OptionButton", "MenuTitle"]:
			assert_eq(theme.get_font_size(&"font_size", type), roundi(UiA11y.base_font_size(type) * s), "%s @ %d%%" % [type, s * 100])
		assert_eq(UiA11y.fs(18), roundi(18 * s), "code overrides follow")
	Settings._cfg["text_scale"] = 1.0
	UiA11y._apply_text_scale()
	assert_eq(theme.get_font_size(&"font_size", "Label"), 16, "back to 100 %")
	assert_eq(theme.get_font_size(&"font_size", "Caption"), 14, "back to 100 %")


func test_settings_slider_offers_100_to_200() -> void:
	var scene := await _open("res://scenes/settings.tscn", Vector2i(412, 915))
	var sl: HSlider = scene.text_scale_slider
	assert_eq(sl.min_value, 100.0)
	assert_eq(sl.step, 25.0)
	assert_gte(sl.max_value, 150.0)


## The menu screens at 125 % / 150 % in all five languages and at 200 % in PL, EN, DE (the longest
## texts): nothing sticks out sideways, no sideways scroll, touch targets stay >= 48 dp.
func test_text_scale_layouts_fit_in_five_languages() -> void:
	Save.data["dev_mode"] = true
	var plan := []
	for lang in LANGS:
		plan.append([lang, 1.5])
	plan.append(["pl", 1.25])
	plan.append(["de", 1.25])
	for lang in ["pl", "en", "de"]:
		plan.append([lang, 2.0])
	for p in plan:
		I18n.apply_language(p[0])
		Settings._cfg["text_scale"] = p[1]
		UiA11y._apply_text_scale()
		for path in SCREENS:
			for size in SIZES:
				var scene := await _open(path, size)
				var tag := "%s @ %dx%d %s %d%%" % [path.get_file(), size.x, size.y, p[0], p[1] * 100]
				assert_lte(scene.get_combined_minimum_size().x, float(size.x), tag + ": root min width")
				var controls: Array = []
				_walk(scene, controls)
				for c: Control in controls:
					var r := c.get_global_rect()
					if r.size.x <= 0.0:
						continue
					if not (r.position.x >= -1.0 and r.end.x <= size.x + 1.0):
						assert_true(false, "%s: %s sticks out (%.0f..%.0f)" % [tag, scene.get_path_to(c), r.position.x, r.end.x])
					if c is ScrollContainer and c.horizontal_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED:
						assert_true(false, "%s: %s scrolls sideways" % [tag, scene.get_path_to(c)])
					if _interactive(c) and c.size.y < 48.0:
						assert_true(false, "%s: %s touch target < 48 dp" % [tag, scene.get_path_to(c)])
					if c is Label and c.text.strip_edges() != "" and c.get_visible_line_count() == 0:
						assert_true(false, "%s: %s collapsed, text '%s' not shown" % [tag, scene.get_path_to(c), c.text])
					if _truncated(c) and not String(c.get_parent().name) in TRUNCATE_OK_PARENTS:
						assert_true(false, "%s: %s text cut '%s'" % [tag, scene.get_path_to(c), c.text])
				scene.get_parent().queue_free()
				await get_tree().process_frame
	pass_test("layouts checked")


func test_fit_title_follows_text_scale() -> void:
	var font: Font = load("res://theme/main.tres").default_font
	Settings._cfg["text_scale"] = 1.5
	var fs := ScreenFrame.title_size(font, "Ab", 2000.0, UiA11y.fs(28), UiA11y.fs(17), UiA11y.fs(22))
	assert_eq(fs, 42, "a short title gets 28 * 1.5")


# ------------------------------------------------------------------ 6. one thumb / left-handed
func _touch(s: InputSampler, x: float, y: float, pressed: bool, idx := 0) -> void:
	var t := InputEventScreenTouch.new()
	t.index = idx
	t.position = Vector2(x, y)
	t.pressed = pressed
	s._unhandled_input(t)


func test_swap_thumbs_swaps_the_zones() -> void:
	var s := InputSampler.new()
	add_child_autofree(s)
	s.swap_thumbs = true
	var w := s._size().x
	_touch(s, w * 0.15, 600, true, 0)
	assert_true(s.right_down(), "left half = pick when swapped")
	assert_false(s.left_down())
	_touch(s, w * 0.85, 600, true, 1)
	assert_true(s.left_down(), "right half = tension when swapped")
	# depth still grows to the right inside the pick half
	s._update_pick(Vector2(0, 600))
	assert_almost_eq(s._depth_raw, 0.0, 0.01)
	s._update_pick(Vector2(w * 0.5, 600))
	assert_almost_eq(s._depth_raw, 1.0, 0.03)


func test_auto_tension_one_thumb_path_with_swap() -> void:
	# D-52 one-thumb path, left-handed: auto tension, the pick on the left, a tap on the right
	# half lets go of the tension (overset fix) - one thumb does everything.
	var s := InputSampler.new()
	add_child_autofree(s)
	s.auto_tension = true
	s.swap_thumbs = true
	for i in 30:
		s._physics_process(1.0 / 120.0)
	assert_almost_eq(s.tension, InputSampler.AUTO_LEVEL, 0.01, "tension held by the game")
	_touch(s, s._size().x * 0.85, 600, true)
	_touch(s, s._size().x * 0.85, 600, false)
	assert_gt(s.release_left, 0.0, "tap on the (swapped) tension half releases")
	s._physics_process(1.0 / 120.0)
	assert_eq(s.tension, 0.0)


func test_swap_hands_texts_in_five_languages() -> void:
	assert_eq(I18n.swap_hands("Left thumb gently up.", "en"), "Right thumb gently up.")
	assert_eq(I18n.swap_hands("Lewym kciukiem lekko, prawy w górę.", "pl"), "Prawym kciukiem lekko, lewy w górę.")
	assert_eq(I18n.swap_hands("Linker Daumen, rechts halten.", "de"), "Rechter Daumen, links halten.")
	assert_eq(I18n.swap_hands("Pouce gauche ; touche à gauche ; le droit lève.", "fr"), "Pouce droit ; touche à droite ; le gauche lève.")
	assert_eq(I18n.swap_hands("Pulgar izquierdo; a la derecha.", "es"), "Pulgar derecho; a la izquierda.")
	assert_false(I18n.handed_key(&"tutorial.s1_binding"), "'Just right' is not a side")
	# every handed key: swapping twice gives the original text back (no side word is lost)
	for lang in LANGS:
		I18n.apply_language(lang)
		for key in I18n.all_keys():
			if not I18n.handed_key(key):
				continue
			var tx := TranslationServer.translate(key)
			assert_eq(I18n.swap_hands(I18n.swap_hands(tx, lang), lang), tx, "%s %s round trip" % [lang, key])
	I18n.apply_language("en")
	Settings._cfg["swap_thumbs"] = true
	assert_eq(I18n.t(&"tutorial.s1_overset_auto"), "Too high — tap the right side to let go of the tension")
	assert_eq(I18n.t(&"tutorial.s1_binding"), "That pin is resisting. Just right.")


func test_settings_screen_has_the_new_toggles() -> void:
	var scene := await _open("res://scenes/settings.tscn", Vector2i(412, 915))
	for key in ["swap_thumbs", "announce_lock_events", "sound_captions"]:
		var cb: CheckButton = scene._toggles[key]
		assert_not_null(cb, key)
		assert_ne(cb.text, "", key + " labelled")
		assert_gte(cb.size.y, 48.0, key + " touch target")
		cb.button_pressed = not bool(Settings.get_value(key))
		assert_eq(bool(Settings.get_value(key)), cb.button_pressed, key + " saved")


func test_tutorial_and_day_after_controls_are_named() -> void:
	I18n.apply_language("pl")
	var tut := await _open("res://scenes/tutorial.tscn", Vector2i(412, 915))
	var da: Control = load(DayAfter.SCENE).instantiate()
	da.job = JobRun.job_by_id("job.cat_bathroom").duplicate(true)
	tut.get_parent().add_child(da)
	await get_tree().process_frame
	for root: Control in [tut, da]:
		var controls: Array = []
		_walk(root, controls)
		for c: Control in controls:
			if _interactive(c):
				assert_ne(UiA11y.spoken_name(c).strip_edges(), "", "%s: %s named" % [root.name, root.get_path_to(c)])


func test_near_break_has_a_still_cue_on_every_family() -> void:
	# DESIGN.md §1 stress: cross cracks 1 -> 3 on the wrench arm (plug face), no motion needed
	assert_eq(PlugFace.crack_count(0.0), 0)
	assert_eq(PlugFace.crack_count(0.1), 1)
	assert_eq(PlugFace.crack_count(0.5), 2)
	assert_eq(PlugFace.crack_count(1.0), 3)


func test_chalk_lines_are_spoken() -> void:
	var ch := ChalkLayer.new()
	add_child_autofree(ch)
	UiA11y.screen_reader_override = 1
	var before := UiA11y.history.size()
	ch.text = "Lewy kciuk lekko w górę."
	ch.text = "Lewy kciuk lekko w górę."  # every frame: said once
	ch.text = ""
	assert_eq(UiA11y.history.slice(before), ["Lewy kciuk lekko w górę."])
	assert_eq(str(ch.get("accessibility_name")), "Lewy kciuk lekko w górę.")
