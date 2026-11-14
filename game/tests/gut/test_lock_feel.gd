extends GutTest
## D-130 lock "game feel": the routing table (res://data/lock_feel.json), the folds of one physics
## step, sound variation bounds, the open payoff timeline and the event micro-motion of the views.

const BASE_EVENTS := ["contact", "bind", "near_shear", "set", "false_set", "counter_rotate", "overset",
	"drop", "stress", "break", "wear", "gate_align", "detector_trip", "open"]
const LOCKCORE_FAMILIES := ["pin_tumbler", "wafer", "wooden_pin", "lever", "lever_detector", "ring_combo",
	"warded", "dial_safe", "combo", "dimple", "disc_detainer", "egyptian", "axial_slider", "time_lock", "magnetic"]


class FakeClickBridge extends RefCounted:
	var plays: Array = []

	func has_java_method(m: StringName) -> bool:
		return String(m) in ["play", "load_sample"]

	func load_sample(_id: String, _pcm: PackedByteArray, _rate: int) -> bool:
		return true

	func play(id: String, gain: float, pitch: float) -> bool:
		plays.append([id, gain, pitch])
		return true


func before_each() -> void:
	LockFeel.reset()


func after_each() -> void:
	Sfx.use_native_click(null)
	Sfx.stop_all_one_shots()
	UiA11y.screen_reader_override = -1
	UiA11y.reduce_motion_override = -1
	Events.change_scenes = true
	Events.scene_override = null


func _ev(kind: StringName, sub: int = 0, element: int = 0, intensity: float = 1.0, material: StringName = &"brass") -> Dictionary:
	return {"kind": kind, "sub": sub, "name": "%s.%d" % [kind, sub], "element": element, "intensity": intensity, "material": material}


# ------------------------------------------------------------------ the table
func test_every_route_names_a_known_family_base_kind_and_sub_event() -> void:
	var d := LockFeel.data()
	assert_eq(String(d.get("schema", "")), "lockwright.feel/1")
	var subs: Dictionary = d["subs"]
	for fam in d["routes"]:
		assert_true(LOCKCORE_FAMILIES.has(fam), "route family %s is a lockcore family" % fam)
		for key in d["routes"][fam]:
			var parts: PackedStringArray = String(key).split(".")
			assert_eq(parts.size(), 2, "%s/%s is <kind>.<sub>" % [fam, key])
			assert_true(BASE_EVENTS.has(parts[0]), "%s/%s: base kind" % [fam, key])
			assert_gt(int(parts[1]), 0, "%s/%s: a sub id (0 is the base event)" % [fam, key])
			assert_true(subs.has(d["routes"][fam][key]), "%s/%s -> %s exists" % [fam, key, d["routes"][fam][key]])
	for fam in ["pin_tumbler", "wafer", "lever", "lever_detector", "warded", "dial_safe", "combo", "dimple",
			"disc_detainer", "egyptian", "axial_slider", "time_lock", "magnetic"]:
		assert_true(d["routes"].has(fam), "playable family %s has its sub-events routed" % fam)


func test_every_sub_event_plays_shipped_sounds_and_a_base_haptic() -> void:
	while Sfx.warming_up():
		await wait_process_frames(1)
	var subs: Dictionary = LockFeel.data()["subs"]
	for name in subs:
		var s: Dictionary = subs[name]
		assert_gt((s["sounds"] as Array).size(), 0, "%s: at least one sound (haptics is never the only channel)" % name)
		for snd in s["sounds"]:
			var id := StringName(snd["id"])
			assert_true(Sfx.EVENTS.has(id) or Sfx.EXTRA_EVENTS.has(id), "%s: sound %s is a lock sound" % [name, id])
			for m in Sfx.MATERIALS:
				var mat := Sfx.material_for(id, StringName(snd.get("material", m)))
				assert_true(ResourceLoader.exists("%s/%s/%s_1.wav" % [Sfx.SFX_ROOT, id, mat]), "%s: %s has a clip for %s (-> %s)" % [name, id, m, mat])
			assert_between(float(snd.get("gain_db", 0.0)), -18.0, 3.0, "%s: level" % name)
			assert_between(float(snd.get("pitch", 1.0)), 0.5, 1.5, "%s: pitch" % name)
			for pc in snd.get("pitch_cycle", []):
				assert_between(float(pc), 0.5, 1.5, "%s: pitch cycle" % name)
			assert_between(int(snd.get("delay_ms", 0)), 0, 300, "%s: a layer never trails more than 300 ms" % name)
		var h := String(s.get("haptic", ""))
		# D-81: the native bridges build raw pulses for base events only; a sub-event borrows one
		assert_true(h == "" or BASE_EVENTS.has(h), "%s: haptic %s is a base pattern" % [name, h])
		if h != "":
			assert_false(Haptics.pattern_for(StringName(h)).is_empty(), "%s: pattern %s exists" % [name, h])
		assert_between(float(s.get("haptic_intensity", 0.5)) * float(s.get("haptic_scale", 1.0)), 0.05, 1.0, "%s: haptic level" % name)
		var cap := String(s.get("caption", ""))
		assert_true(cap == "" or I18n.has_key(StringName(cap)), "%s: caption key %s" % [name, cap])
		assert_between(int(s.get("min_gap_ms", 0)), 0, 250, "%s: min gap" % name)


func test_timings_stay_inside_the_design_rule() -> void:
	# DESIGN.md §1: animations 100-250 ms; the open payoff covers the clip and the haptic
	assert_between(LockFeel.open_throw_s() * 1000.0, LockFeel.MOTION_MIN_MS, LockFeel.MOTION_MAX_MS, "opening throw")
	assert_between(LockFeel.open_hold_s() * 1000.0, 0.0, 100.0, "hold before the throw")
	var land_ms := (LockFeel.open_hold_s() + LockFeel.open_throw_s()) * 1000.0
	assert_between(land_ms, 250.0, 400.0, "the picture lands with the haptic click (300 ms) and the bolt of the clip (~380 ms)")
	assert_gt(LockFeel.open_payoff_s() * 1000.0, 537.0, "the longest open clip (537 ms) ends before the screen moves on")
	assert_lt(LockFeel.open_payoff_s(), 1.2, "the payoff never becomes a wait")
	for key in ["set_nudge_ms", "drop_fall_ms", "break_recoil_ms"]:
		assert_between(LockFeel.motion_s(key) * 1000.0, LockFeel.MOTION_MIN_MS, LockFeel.MOTION_MAX_MS, key)
	assert_almost_eq(LockFeel.motion_s("drop_stagger_ms") * 1000.0, 40.0, 0.01, "DESIGN.md §1 drop: 40 ms apart")


func test_open_progress_holds_then_lands_without_overshoot() -> void:
	assert_eq(LockFeel.open_progress(0.0), 0.0)
	assert_eq(LockFeel.open_progress(LockFeel.open_hold_s() * 0.99), 0.0, "still held")
	var last := 0.0
	var t := 0.0
	while t < 1.0:
		var p := LockFeel.open_progress(t)
		assert_true(p >= last - 0.000001, "monotonic at %.3f" % t)
		assert_true(p <= 1.0, "never past the target at %.3f" % t)
		last = p
		t += 1.0 / 120.0
	assert_almost_eq(LockFeel.open_progress(LockFeel.open_hold_s() + LockFeel.open_throw_s()), 1.0, 0.0001)
	assert_gt(LockFeel.open_progress(LockFeel.open_hold_s() + LockFeel.open_throw_s() * 0.5), 0.8, "out-cubic: most of the way by half time")


# ------------------------------------------------------------------ plans
func test_serration_does_not_play_as_a_false_set() -> void:
	var real := LockFeel.plan(&"pin_tumbler", _ev(&"false_set", 0, 2, 0.7))
	var tick := LockFeel.plan(&"pin_tumbler", _ev(&"false_set", 1, 2, 0.3))
	assert_eq(real["sounds"][0]["id"], &"false_set")
	assert_eq(real["haptic"], &"false_set")
	assert_eq(real["sounds"][0]["gain_db"], 0.0, "a false set always plays in full")
	assert_true(real["announce"])
	assert_eq(tick["name"], "pin.serration")
	assert_eq(tick["sounds"][0]["id"], &"ratchet", "FEEL F-04: its own tick")
	assert_lt(float(tick["sounds"][0]["gain_db"]), 0.0)
	assert_eq(tick["haptic"], &"contact", "a light tick, not the false-set double")
	assert_false(tick["announce"], "a screen reader does not call it a false set")
	assert_eq(tick["caption"], "a11y.sfx.serration")
	for fam in [&"dimple", &"magnetic"]:
		assert_eq(LockFeel.plan(fam, _ev(&"false_set", 1))["name"], "pin.serration", "%s shares the pin module" % fam)


func test_unrouted_sub_event_falls_back_to_its_base_kind() -> void:
	var p := LockFeel.plan(&"combo", _ev(&"overset", 2, 1, 0.6))  # combo.slip
	assert_eq(p["name"], "")
	assert_eq(p["sounds"][0]["id"], &"overset")
	assert_eq(p["haptic"], &"overset")
	assert_eq(LockFeel.plan(&"no_such_family", _ev(&"contact", 9))["sounds"][0]["id"], &"contact")


func test_sound_level_follows_intensity_only_for_non_essential_kinds() -> void:
	var faint: float = LockFeel.plan(&"pin_tumbler", _ev(&"contact", 0, 1, 0.2))["sounds"][0]["gain_db"]
	var full: float = LockFeel.plan(&"pin_tumbler", _ev(&"contact", 0, 1, 1.0))["sounds"][0]["gain_db"]
	assert_lt(faint, full, "a neighbour's faint contact is quieter")
	assert_eq(full, 0.0)
	assert_gte(faint, -6.0, "never below the floor")
	assert_lt(LockFeel.intensity_gain_db(&"drop", 0.2), LockFeel.intensity_gain_db(&"drop", 1.0), "one pin dropping vs all")
	for kind in [&"set", &"false_set", &"overset", &"open", &"break", &"detector_trip"]:
		assert_eq(LockFeel.intensity_gain_db(kind, 0.1), 0.0, "%s always in full" % kind)
	assert_eq(LockFeel.plan(&"pin_tumbler", _ev(&"set"), 1.5)["sounds"][0]["gain_db"], LockFeel.TUTORIAL_BOOST_DB, "tutorial boost")
	assert_eq(LockFeel.plan(&"pin_tumbler", _ev(&"set", 0, 0, 0.9), 1.5)["haptic_intensity"], 1.0, "haptic boost is clamped")


func test_dial_safe_keeps_its_wheel_pitch_and_heavy_fence_drop() -> void:
	var p0 := LockFeel.plan(&"dial_safe", _ev(&"bind", 2, 0, 0.4, &"steel"))
	var p3 := LockFeel.plan(&"dial_safe", _ev(&"bind", 2, 3, 0.4, &"steel"))
	assert_lt(float(p0["sounds"][0]["pitch"]), float(p3["sounds"][0]["pitch"]), "wheels nearer the dial sound lower")
	var drop := LockFeel.plan(&"dial_safe", _ev(&"set", 3, -1, 0.7, &"steel"))
	assert_eq(drop["haptic"], &"set")
	assert_eq(drop["haptic_intensity"], 1.0)
	assert_eq((drop["sounds"] as Array).size(), 2, "click + the fence landing")
	var det := LockFeel.plan(&"dial_safe", _ev(&"contact", 1, -1, 0.5, &"steel"))
	assert_eq(det["sounds"][0]["id"], &"ring_detent")
	assert_lt(float(det["haptic_intensity"]), 0.5, "a detent is lighter than a contact")


func test_gate_align_folds_under_the_set_of_the_same_element() -> void:
	var plans := LockFeel.plan_step(&"lever", [_ev(&"gate_align", 0, 1), _ev(&"set", 0, 1, 0.95)])
	assert_eq(plans[0]["haptic"], &"", "one click, not two transients in one step")
	assert_almost_eq(float(plans[0]["sounds"][0]["gain_db"]), -6.0, 0.001, "the 'tok' stays as a quiet layer")
	assert_eq(plans[1]["haptic"], &"set")
	var alone := LockFeel.plan_step(&"lever", [_ev(&"gate_align", 0, 1), _ev(&"set", 0, 2)])
	assert_eq(alone[0]["haptic"], &"gate_align", "another element's set does not fold it")


func test_false_gate_is_a_delayed_second_knock_without_its_own_haptic() -> void:
	var plans := LockFeel.plan_step(&"lever", [_ev(&"false_set", 0, 1, 0.65), _ev(&"false_set", 1, 1, 0.45)])
	assert_eq(plans[0]["haptic"], &"false_set")
	assert_eq(plans[1]["haptic"], &"")
	assert_eq(plans[1]["sounds"][0]["id"], &"lever_fall")
	assert_eq(plans[1]["sounds"][0]["delay_ms"], 40, "FEEL §3.5: the pair is 40 ms apart")
	assert_false(plans[1]["announce"])


func test_open_break_and_trip_keep_the_haptic_to_themselves() -> void:
	var plans := LockFeel.plan_step(&"pin_tumbler", [_ev(&"set", 0, 4, 0.95), _ev(&"open", 0, -1)])
	assert_eq(plans[0]["haptic"], &"", "a set in the open step would cut the long open pattern on Android")
	assert_eq(plans[0]["sounds"][0]["id"], &"set", "its click is still heard")
	assert_eq(plans[1]["haptic"], &"open")
	plans = LockFeel.plan_step(&"lever_detector", [_ev(&"detector_trip", 0, 0), _ev(&"overset", 0, 0)])
	assert_eq(plans[1]["haptic"], &"")


func test_min_gap_drops_a_sub_event_repeated_too_soon() -> void:
	var p := LockFeel.plan(&"pin_tumbler", _ev(&"false_set", 1, 0, 0.3))
	assert_true(LockFeel.perform(p, 1000))
	assert_false(LockFeel.perform(p, 1010), "inside the 30 ms gap")
	assert_true(LockFeel.perform(p, 1040))


func test_time_lock_beats_alternate_tick_and_tock() -> void:
	var a := LockFeel.plan(&"time_lock", _ev(&"contact", 2, -1, 0.45))
	LockFeel.perform(a, 0)
	var b := LockFeel.plan(&"time_lock", _ev(&"contact", 2, -1, 0.45))
	assert_ne(a["sounds"][0]["pitch"], b["sounds"][0]["pitch"])
	assert_eq(a["sounds"][0]["id"], &"ratchet")


func test_play_step_tags_events_for_captions_and_the_screen_reader() -> void:
	var events := [_ev(&"false_set", 1, 2, 0.3), _ev(&"set", 0, 1, 0.95)]
	LockFeel.play_step(&"pin_tumbler", events)
	assert_eq(events[0]["feel"], "pin.serration")
	assert_false(events[0].get("announce", true))
	assert_eq(SoundCaptions.caption_key(events[0]), &"a11y.sfx.serration")
	assert_false(events[1].has("feel"))
	assert_eq(SoundCaptions.caption_key(events[1]), &"a11y.sfx.set")
	assert_eq(SoundCaptions.caption_key({"kind": &"contact", "caption": ""}), &"", "a detent shows no caption")
	UiA11y.screen_reader_override = 1
	var before := UiA11y.history.size()
	Events.lock_event.emit(events[0])
	assert_eq(UiA11y.history.size(), before, "the serration tick is not announced as a false set")
	Events.lock_event.emit(_ev(&"false_set", 0, 2, 0.7))
	assert_eq(UiA11y.history.size(), before + 1, "a real false set is")


# ------------------------------------------------------------------ sound variation
func test_variant_is_never_repeated_and_offsets_stay_in_bounds() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var last := 0
	var seen := {}
	for i in 500:
		var n := Sfx.pick_variant(rng, last, Sfx.VARIANTS)
		assert_between(n, 1, Sfx.VARIANTS)
		assert_ne(n, last, "no immediate repeat")
		seen[n] = true
		last = n
		var v := Sfx.vary(rng)
		assert_between(float(v["pitch"]), 1.0 - Sfx.PITCH_JITTER, 1.0 + Sfx.PITCH_JITTER)
		assert_between(float(v["gain_db"]), -Sfx.GAIN_JITTER_DB, Sfx.GAIN_JITTER_DB)
	assert_eq(seen.size(), Sfx.VARIANTS, "every variant is used")
	assert_eq(Sfx.pick_variant(rng, 1, 1), 1, "a single clip is just played")
	assert_lte(Sfx.PITCH_JITTER, 0.05, "subtle: a click keeps its identity")
	assert_lte(Sfx.GAIN_JITTER_DB, 1.5)


func test_same_click_twice_in_a_row_differs_on_both_paths() -> void:
	while Sfx.warming_up():
		await wait_process_frames(1)
	var prev := 0
	for i in 40:
		Sfx.play(&"set", &"brass", -3.0, 1.0)
		assert_ne(int(Sfx.last_play["variant"]), prev, "engine path: another variant")
		prev = int(Sfx.last_play["variant"])
		assert_between(float(Sfx.last_play["pitch"]), 1.0 - Sfx.PITCH_JITTER, 1.0 + Sfx.PITCH_JITTER)
		assert_between(float(Sfx.last_play["volume_db"]), -3.0 - Sfx.GAIN_JITTER_DB, -3.0 + Sfx.GAIN_JITTER_DB)
	Sfx.stop_all_one_shots()
	var f := FakeClickBridge.new()
	Sfx.use_native_click(f, "fake")
	assert_true(Sfx.native_click_active())
	for i in 40:
		Sfx.play(&"set", &"brass")
	assert_eq(f.plays.size(), 40)
	var pitches := {}
	for i in f.plays.size():
		assert_between(float(f.plays[i][2]), 1.0 - Sfx.PITCH_JITTER, 1.0 + Sfx.PITCH_JITTER, "native path: pitch offset in bounds")
		pitches[snappedf(float(f.plays[i][2]), 0.0001)] = true
		if i > 0:
			assert_ne(f.plays[i][0], f.plays[i - 1][0], "native path: another variant")
	assert_gt(pitches.size(), 10, "the native bridge no longer plays every click at one pitch")


func test_sub_event_clicks_load_and_fall_back_to_a_shipped_material() -> void:
	while Sfx.warming_up():
		await wait_process_frames(1)
	assert_eq(Sfx.material_for(&"spring", &"wood"), &"brass", "no wooden spring: brass stands in")
	assert_eq(Sfx.material_for(&"ward_scrape", &"iron"), &"iron")
	assert_eq(Sfx.material_for(&"set", &"none"), &"brass", "an event without a material is still heard")
	var c: Dictionary = Sfx._native_candidates()
	for id in Sfx.EXTRA_EVENTS:
		assert_true(c.has("%s/brass/1" % id), "%s is offered to the native click bridge" % id)
	Sfx.play(&"ratchet", &"wood", -6.0)
	assert_eq(Sfx.last_play["material"], &"brass")


# ------------------------------------------------------------------ views
func _pin_scene() -> Node:
	var scene: Node = load("res://scenes/photoreal/lock_photoreal.tscn").instantiate()
	add_child_autofree(scene)
	await wait_physics_frames(2)
	scene.set_physics_process(false)
	return scene


func _vm(state: StringName, pos: float, open: bool = false) -> Dictionary:
	var els := []
	for i in 5:
		els.append({"state": state, "position": pos, "variant": 0, "window_lo": 0.52, "window_hi": 0.60})
	return {"elements": els, "pick_element": -1, "tension": 0.35, "core_rotation": 1.0 if open else 0.1, "stress": 0.0, "open": open}


func test_plug_holds_then_throws_on_the_shared_timeline() -> void:
	var scene: Node = await _pin_scene()
	var view: LockPhotorealView = scene.view
	var input := {"tension": 0.35, "pick_depth": 0.5, "pick_lift": 0.0}
	for i in 60:
		view.present(_vm(&"set", 0.56), input, 1.0 / 120.0)
	var from: float = view._plug_deg
	view.on_event({"kind": &"open", "element": -1, "intensity": 1.0, "material": &"brass"})
	var vm := _vm(&"set", 0.56, true)
	var target: float = view._plug_target(vm, 0.35)
	assert_gt(target, from + 10.0, "the open turn is a visible throw")
	var last := from
	var t := 0.0
	while t < LockFeel.open_hold_s() - 1.0 / 120.0:
		view.present(vm, input, 1.0 / 120.0)
		t += 1.0 / 120.0
		assert_almost_eq(view._plug_deg, from, 0.01, "held at %.0f ms" % (t * 1000.0))
	while t < 0.5:
		view.present(vm, input, 1.0 / 120.0)
		t += 1.0 / 120.0
		assert_true(view._plug_deg >= last - 0.0001, "monotonic")
		assert_true(view._plug_deg <= target + 0.0001, "no overshoot")
		last = view._plug_deg
		if t >= LockFeel.open_hold_s() + LockFeel.open_throw_s() + 0.01:
			assert_almost_eq(view._plug_deg, target, 0.01, "landed by %.0f ms" % (t * 1000.0))
	assert_almost_eq(view.open_p(), 1.0, 0.0001)


func test_snapshot_present_lands_the_open_pose_at_once() -> void:
	var scene: Node = await _pin_scene()
	var view: LockPhotorealView = scene.view
	var vm := _vm(&"set", 0.56, true)
	view.present(vm, {"tension": 0.35, "pick_depth": 0.5, "pick_lift": 0.0}, 1.0)
	assert_almost_eq(view._plug_deg, view._plug_target(vm, 0.35), 0.01, "screenshots and tests see the final pose")


func test_dropped_stacks_fall_one_after_another() -> void:
	var scene: Node = await _pin_scene()
	var view: LockPhotorealView = scene.view
	var input := {"tension": 0.0, "pick_depth": 0.5, "pick_lift": 0.0}
	for i in 30:
		view.present(_vm(&"set", 0.56), input, 1.0 / 120.0)
	var set_drv: float = view._shown[0][1]
	view.on_event({"kind": &"drop", "element": -1, "intensity": 1.0, "material": &"brass"})
	assert_true(view.is_dropping())
	var free := _vm(&"free", 0.0)
	view.present(free, input, 1.0 / 120.0)
	var rest_drv: float = PinPose.pose(free["elements"][0])["driver_bottom"]
	assert_lt(view._shown[0][1], set_drv, "the first stack is already on its way")
	assert_gt(view._shown[0][1], rest_drv, "... but not teleported to rest")
	assert_almost_eq(view._shown[4][1], set_drv, 0.001, "the fifth waits its turn (4 x 40 ms)")
	var prev: Array = []
	for i in 5:
		prev.append(view._shown[i][1])
	var t := 1.0 / 120.0
	while t < 0.4:
		view.present(free, input, 1.0 / 120.0)
		t += 1.0 / 120.0
		for i in 5:
			assert_true(view._shown[i][1] <= prev[i] + 0.0001, "stack %d only falls" % i)
			prev[i] = view._shown[i][1]
	assert_false(view.is_dropping(), "the cascade is over within 4 x 40 + 120 ms")
	for i in 5:
		assert_almost_eq(view._shown[i][1], rest_drv, 0.001)


func test_reduce_motion_drops_at_once() -> void:
	var scene: Node = await _pin_scene()
	var view: LockPhotorealView = scene.view
	UiA11y.reduce_motion_override = 1
	for i in 10:
		view.present(_vm(&"set", 0.56), {"tension": 0.0, "pick_depth": 0.5, "pick_lift": 0.0}, 1.0 / 120.0)
	view.on_event({"kind": &"drop", "element": -1, "intensity": 1.0, "material": &"brass"})
	assert_false(view.is_dropping())


func test_break_recoil_is_a_short_motion_not_a_jump() -> void:
	var scene: Node = await _pin_scene()
	var view: LockPhotorealView = scene.view
	var input := {"tension": 0.3, "pick_depth": 0.5, "pick_lift": 0.0}
	view.present(_vm(&"free", 0.0), input, 1.0 / 120.0)
	assert_eq(view.break_p(), 0.0)
	view.on_event({"kind": &"break", "element": 0, "intensity": 1.0, "material": &"steel"})
	view.present(_vm(&"free", 0.0), input, 1.0 / 120.0)
	assert_between(view.break_p(), 0.01, 0.5, "started, not finished")
	for i in 30:
		view.present(_vm(&"free", 0.0), input, 1.0 / 120.0)
	assert_almost_eq(view.break_p(), 1.0, 0.0001)


func test_open_lock_stays_for_the_payoff_before_the_screen_moves_on() -> void:
	Events.change_scenes = false
	var scene: Node = await _pin_scene()
	Events.scene_override = scene
	watch_signals(Events)
	assert_almost_eq(float(scene.open_payoff_s), LockFeel.open_payoff_s(), 0.0001)
	scene._on_open()
	assert_signal_not_emitted(Events, "lock_opened", "the plug, the bolt and the click play on the lock itself")
	assert_almost_eq(float(scene._open_pending), LockFeel.open_payoff_s(), 0.0001)
	scene.open_payoff_s = 0.0
	scene._on_open()
	assert_signal_emitted(Events, "lock_opened", "0 = at once (tests)")
