extends GutTest
## D-97 (N-93): Godot 4.7.2 has no AccessKit on Android, so the LockwrightHaptics plugin carries a
## TalkBack bridge (A11yBridge.kt). These tests drive UiA11y's side with a double of the plugin:
## published nodes (names, roles, bounds, state), activation and slider steps coming back, the
## lock screen as one named play area, announcements going to TalkBack.


class FakeBridge:
	extends RefCounted
	signal a11y_activate(id: int)
	signal a11y_adjust(id: int, dir: int)
	var active := true
	var json := ""
	var sets := 0
	var said: Array[String] = []

	func a11y_active() -> bool:
		return active

	func a11y_screen_reader() -> bool:
		return active

	func a11y_set_nodes(j: String) -> void:
		json = j
		sets += 1

	func a11y_announce(t: String) -> void:
		said.append(t)


var _fake: FakeBridge


func before_each() -> void:
	_fake = FakeBridge.new()
	UiA11y.use_bridge(_fake)


func after_each() -> void:
	UiA11y.use_bridge(null)
	UiA11y.screen_reader_override = -1
	JobRun.current_job = {}


func _open(path: String, size := Vector2i(412, 915), three_d := false) -> SubViewport:
	var vp := SubViewport.new()
	vp.size = size
	vp.disable_3d = not three_d
	add_child_autofree(vp)
	var scene: Node = load(path).instantiate()
	if "go_override" in scene:
		scene.go_override = func(_p: String) -> void: pass  # no lock preload threads (D-87)
	vp.add_child(scene)
	for i in 4:
		await get_tree().process_frame
	return vp


func _nodes(vp: SubViewport) -> Array:
	UiA11y._bridge_active = true
	return UiA11y.publish_nodes(vp)


func _find(nodes: Array, name: String) -> Dictionary:
	for n in nodes:
		if String(n["name"]) == name:
			return n
	return {}


func test_main_menu_buttons_reach_talkback_with_names_and_bounds() -> void:
	I18n.apply_language("pl")
	var vp := await _open("res://scenes/main_menu.tscn")
	var nodes := _nodes(vp)
	var buttons := nodes.filter(func(n: Dictionary) -> bool: return n["role"] == "button")
	assert_gt(buttons.size(), 3, "menu buttons published")
	for n in buttons:
		assert_ne(String(n["name"]), "", "named")
		assert_true(n["w"] >= 4 and n["h"] >= 4 and n["x"] >= 0 and n["y"] >= 0, "bounds on screen %s" % n)
		assert_true(n["x"] + n["w"] <= 412 + 1 and n["y"] + n["h"] <= 915 + 1, "inside the window %s" % n)
	assert_eq(JSON.parse_string(_fake.json).size(), nodes.size(), "the same list went to the plugin")


func test_settings_toggles_sliders_and_options_carry_state() -> void:
	I18n.apply_language("en")
	var vp := await _open("res://scenes/settings.tscn")
	var nodes := _nodes(vp)
	var roles := {}
	for n in nodes:
		roles[n["role"]] = true
	# the lists sit lower: only what is scrolled into view is published (TalkBack two-finger scroll)
	var scr: Control = vp.get_child(0)
	(scr.get_node("Frame/VBox/Scroll") as ScrollContainer).ensure_control_visible(scr.quality_option)
	for i in 3:
		await get_tree().process_frame
	for n in _nodes(vp):
		roles[n["role"]] = true
	(scr.get_node("Frame/VBox/Scroll") as ScrollContainer).scroll_vertical = 0
	for i in 3:
		await get_tree().process_frame
	nodes = _nodes(vp)
	for r in ["button", "check", "slider", "option", "text"]:
		assert_true(roles.has(r), "role %s published" % r)
	var hap := _find(nodes, I18n.t(&"settings.haptics_enabled"))
	assert_false(hap.is_empty(), "haptics switch found")
	assert_eq(hap["role"], "check")
	assert_true(hap.has("checked"))
	# a double tap on the switch toggles it (and saves the setting)
	var before := bool(Settings.get_value("haptics_enabled"))
	UiA11y._on_bridge_activate(int(hap["id"]))
	assert_eq(bool(Settings.get_value("haptics_enabled")), not before, "activate toggles")
	UiA11y._on_bridge_activate(int(hap["id"]))
	assert_eq(bool(Settings.get_value("haptics_enabled")), before, "and back")
	# a slider step (TalkBack volume keys / swipe up-down)
	var sl: Dictionary = nodes.filter(func(n: Dictionary) -> bool: return n["role"] == "slider")[0]
	var ctrl: Range = (UiA11y._by_id[int(sl["id"])] as WeakRef).get_ref()
	var v := ctrl.value
	UiA11y._on_bridge_adjust(int(sl["id"]), -1)
	assert_lt(ctrl.value, v + 0.0001, "scroll backward lowers")
	ctrl.value = v


func test_labels_inside_buttons_are_not_separate_nodes() -> void:
	JobRun.start(JobRun.job_by_id("job.bike_interview"))
	var vp := await _open("res://scenes/job_verify.tscn")
	var nodes := _nodes(vp)
	for n in nodes:
		var c: Control = (UiA11y._by_id[int(n["id"])] as WeakRef).get_ref()
		var p := c.get_parent()
		while p != null:
			assert_false(p is BaseButton, "%s is inside a button" % n["name"])
			p = p.get_parent()
	var cards := nodes.filter(func(n: Dictionary) -> bool: return String(n.get("desc", "")) == I18n.t(&"a11y.card_ask"))
	assert_gt(cards.size(), 0, "document cards are buttons with the ask hint")


func test_lock_screen_is_an_area_with_named_pause_and_loupe() -> void:
	var vp := await _open("res://scenes/lock_job.tscn", Vector2i(412, 915), true)
	await wait_physics_frames(2)
	var nodes := _nodes(vp)
	var area_nodes := nodes.filter(func(n: Dictionary) -> bool: return n["role"] == "area")
	assert_eq(area_nodes.size(), 1, "one play area (the lock)")
	assert_ne(String(area_nodes[0]["desc"]), "", "it says what the thumbs do")
	var pause := _find(nodes, I18n.t(&"a11y.pause"))
	var loupe := _find(nodes, I18n.t(&"a11y.loupe"))
	assert_false(pause.is_empty(), "pause flap published")
	assert_false(loupe.is_empty(), "loupe published")
	assert_gt(nodes.find(pause), nodes.find(area_nodes[0]), "buttons come after (on top of) the lock area")
	var view: LockPhotorealView = vp.get_child(0).view
	UiA11y._on_bridge_activate(int(loupe["id"]))
	assert_true(view.zoomed, "double tap opens the loupe")


func test_activation_through_the_plugin_signal() -> void:
	var vp := await _open("res://scenes/control_choice.tscn")
	var nodes := _nodes(vp)
	var b: Dictionary = nodes.filter(func(n: Dictionary) -> bool: return n["role"] == "button")[0]
	var ctrl: BaseButton = (UiA11y._by_id[int(b["id"])] as WeakRef).get_ref()
	var got := []
	ctrl.pressed.connect(func() -> void: got.append(1))
	_fake.a11y_activate.emit(int(b["id"]))
	assert_eq(got.size(), 1, "a11y_activate presses the button")


func test_announcements_and_screen_reader_state_follow_talkback() -> void:
	UiA11y._bridge_active = false
	UiA11y._bridge_left = 0.0
	UiA11y._process(0.0)
	assert_true(UiA11y.bridge_active(), "plugin says TalkBack is on")
	assert_true(UiA11y.bridge_screen_reader())
	assert_true(UiA11y.screen_reader_active(), "the game treats TalkBack as a screen reader")
	I18n.apply_language("en")
	UiA11y._last_said.clear()
	Events.lock_event.emit({"kind": &"set", "element": 1})
	assert_eq(_fake.said, ["2: set"], "lock state spoken through TalkBack")
	_fake.active = false
	UiA11y._bridge_left = 0.0
	UiA11y._process(0.0)
	assert_false(UiA11y.bridge_active())
	assert_eq(_fake.json, "[]", "nodes cleared when TalkBack goes off")


func test_unchanged_screen_is_not_resent() -> void:
	var vp := await _open("res://scenes/main_menu.tscn")
	_nodes(vp)
	var n := _fake.sets
	_nodes(vp)
	assert_eq(_fake.sets, n, "same nodes: no JNI call")


func test_old_plugin_without_bridge_is_ignored() -> void:
	var old := RefCounted.new()
	UiA11y.use_bridge(old)
	assert_null(UiA11y._bridge, "no a11y_set_nodes: no bridge")


func test_paused_lock_publishes_only_the_pause_panel() -> void:
	var vp := await _open("res://scenes/lock_job.tscn", Vector2i(412, 915), true)
	await wait_physics_frames(2)
	var scene: Node = vp.get_child(0)
	scene._on_pause()
	await get_tree().process_frame
	var nodes := _nodes(vp)
	get_tree().paused = false
	assert_gt(nodes.size(), 0, "pause panel published")
	assert_true(nodes.filter(func(n: Dictionary) -> bool: return n["role"] == "area").is_empty(),
		"the lock under the pause is not")
	assert_true(_find(nodes, I18n.t(&"a11y.pause")).is_empty(), "nor its pause flap")
	assert_true(UiA11y.can_process(), "UiA11y keeps running while the tree is paused")
