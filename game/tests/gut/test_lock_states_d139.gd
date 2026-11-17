extends GutTest
## D-139 lock state matrix: every state reads by shape / position with the chalk layer off, in
## greyscale and with reduce motion. The measured sheets are in docs/handoff/LOCK-STATES-2026-11-17.md;
## these tests hold the two fixes:
##   - near break (stress): the family's own tool in the section stands off its line as a still pose
##     (dimple flag, magnet probe, wafer pick, lever lifter, slider pusher, time-lock tweezers), not
##     only the wrench arm on the plug face;
##   - lift-layer screens (axial slider, egyptian, time lock): set = +1 tick and false set = +2 ticks
##     on the plug face, the same code as on the pin, wafer and lever screens.

const SCENES := {
	&"pin_tumbler": "res://scenes/lock_job.tscn",
	&"dimple": "res://scenes/photoreal/lock_job_dimple.tscn",
	&"magnetic": "res://scenes/photoreal/lock_job_magnetic.tscn",
	&"wafer": "res://scenes/photoreal/lock_job_wafer.tscn",
	&"lever": "res://scenes/photoreal/lock_job_lever.tscn",
	&"axial_slider": "res://scenes/photoreal/lock_job_axial_slider.tscn",
	&"time_lock": "res://scenes/photoreal/lock_job_time_lock.tscn",
	&"egyptian": "res://scenes/photoreal/lock_job_egyptian.tscn",
}
const INPUT := {"tension": 0.35, "pick_depth": 0.5, "pick_lift": 0.3}
var _reduce := -1


func before_all() -> void:
	_reduce = UiA11y.reduce_motion_override


func after_each() -> void:
	UiA11y.reduce_motion_override = _reduce
	JobRun.current_job = {}


func _vm(state: StringName, position: float, stress: float = 0.0, n: int = 5) -> Dictionary:
	var els := []
	for i in n:
		els.append({"state": state, "position": position, "variant": 0, "window_lo": 0.52, "window_hi": 0.60, "target": 0.56})
	return {"elements": els, "pick_element": 2, "tension": 0.35, "core_rotation": 0.0, "stress": stress,
		"open": false, "tension_resistance": 0.4}


func _view(fam: StringName) -> LockPhotorealView:
	JobRun.current_job = {}
	var vp := SubViewport.new()
	vp.size = Vector2i(412, 915)
	add_child_autofree(vp)
	var scene: Node = load(SCENES[fam]).instantiate()
	vp.add_child(scene)
	await wait_physics_frames(2)
	scene.set("_frozen", true)
	scene.set_physics_process(false)
	return scene.view


func test_tool_strain_starts_with_the_first_crack() -> void:
	var view: LockPhotorealView = await _view(&"dimple")
	for s: float in [0.0, 0.3, 0.6]:
		view.present(_vm(&"bound", 0.4, s), INPUT, 1.0)
		assert_eq(view.tool_strain_deg(), 0.0, "no strain at stress %.1f: an ordinary lift does not move the tool off its line" % s)
		assert_eq(PlugFace.crack_count(view._face.tremor), 0, "and no crack on the wrench arm")
	view.present(_vm(&"bound", 0.4, 0.8), INPUT, 1.0)
	assert_almost_eq(view.tool_strain_deg(), LockPhotorealView.TOOL_STRAIN_DEG * 0.5, 0.001)
	view.present(_vm(&"bound", 0.4, 1.0), INPUT, 1.0)
	assert_almost_eq(view.tool_strain_deg(), LockPhotorealView.TOOL_STRAIN_DEG, 0.001)


func test_tool_strain_is_a_still_pose_under_reduce_motion() -> void:
	UiA11y.reduce_motion_override = 1
	var view: LockPhotorealView = await _view(&"magnetic")
	var seen := {}
	for i in 5:
		view.present(_vm(&"bound", 0.4, 0.95), INPUT, 1.0)
		seen[snappedf(view.tool_strain_deg(), 0.0001)] = true
		await get_tree().create_timer(0.03).timeout
	assert_eq(seen.size(), 1, "one steady pose, no tremor")
	assert_gt(float(seen.keys()[0]), 2.0, "the tool stands off its line near break")


func test_lift_layer_tool_sags_handle_end_down() -> void:
	# pusher: tip at the right end of its layer, handle to the left; tweezers: handle up and to the right
	for fam: StringName in [&"axial_slider", &"time_lock"]:
		var view: LockLiftLayerView = await _view(fam)
		view.present(_vm(&"bound", 0.4, 0.0), INPUT, 1.0)
		assert_eq(view.tool_sag_deg(), 0.0, "%s: straight while the tool is safe" % fam)
		view.present(_vm(&"bound", 0.4, 0.95), INPUT, 1.0)
		var sag := view.tool_sag_deg()
		assert_almost_eq(absf(sag), LockPhotorealView.TOOL_STRAIN_DEG * 0.875, 0.001, "%s: sags near break" % fam)
		var tp: Array = view.meta.get(view.tool_layer + "_tip_px", [0.0, 0.0])
		var sz: Array = view.meta["layers"][view.tool_layer]["size"]
		var handle := view._layer_pos(view.tool_layer) + Vector2(sz[0], sz[1]) * 0.5 - Vector2(tp[0], tp[1])
		assert_gt(handle.rotated(deg_to_rad(sag)).y, handle.y, "%s: the handle end goes down on the screen" % fam)


func test_lever_lifter_gives_near_break() -> void:
	var view: LockLeverView = await _view(&"lever")
	view.present(_vm(&"bound", 0.4, 0.0, 3), INPUT, 1.0)
	var safe := view._lift_deg
	view.present(_vm(&"bound", 0.4, 0.5, 3), INPUT, 1.0)
	assert_almost_eq(view._lift_deg, safe, 0.001, "no change below the first crack")
	view.present(_vm(&"bound", 0.4, 1.0, 3), INPUT, 1.0)
	assert_almost_eq(safe - view._lift_deg, LockPhotorealView.TOOL_STRAIN_DEG, 0.01, "the lifter stands off the lever belly")


func test_wafer_pick_sags_about_its_tip() -> void:
	var view: LockWaferView = await _view(&"wafer")
	var pick: Node3D = view._by["pick"]
	view.present(_vm(&"bound", 0.4, 0.0), INPUT, 1.0)
	var safe := pick.transform
	view.present(_vm(&"bound", 0.4, 0.5), INPUT, 1.0)
	assert_true(pick.transform.is_equal_approx(safe), "no change below the first crack")
	view.present(_vm(&"bound", 0.4, 1.0), INPUT, 1.0)
	assert_false(pick.transform.is_equal_approx(safe), "the pick moves off its line near break")
	var turned := safe.basis.inverse() * pick.transform.basis
	assert_almost_eq(rad_to_deg(turned.get_euler().length()), LockPhotorealView.TOOL_STRAIN_DEG, 0.05)


func test_lift_layer_face_counts_set_and_false_set() -> void:
	var view: LockLiftLayerView = await _view(&"axial_slider")
	var face: PlugFace = view._face
	view.present(_vm(&"free", 0.4, 0.0, 3), INPUT, 1.0)
	var rest := face.face_deg
	view.present(_vm(&"bound", 0.4, 0.0, 3), INPUT, 1.0)
	assert_almost_eq(face.face_deg, rest, 0.01, "binding does not turn the face")
	view.present(_vm(&"set", 0.56, 0.0, 3), INPUT, 1.0)
	assert_almost_eq(face.face_deg - rest, 3 * PlugFace.TICK_DEG, 0.01, "set: one tick each")
	view.present(_vm(&"false_set", 0.4, 0.0, 3), INPUT, 1.0)
	assert_almost_eq(face.face_deg - rest, 6 * PlugFace.TICK_DEG, 0.01, "false set: two ticks each, deeper than a set")
	var mixed := _vm(&"free", 0.4, 0.0, 3)
	mixed["elements"][1]["state"] = &"false_set"
	view.present(mixed, INPUT, 1.0)
	assert_almost_eq(face.face_deg - rest, 2 * PlugFace.TICK_DEG, 0.01, "one slider in a false notch among free ones")


func test_lift_layer_face_still_ends_at_a_quarter_turn() -> void:
	for fam: StringName in [&"egyptian", &"time_lock", &"axial_slider"]:
		var view: LockLiftLayerView = await _view(fam)
		var vm := _vm(&"set", 0.56, 0.0, 3)
		vm["hold_progress"] = 1.0
		view.present(vm, INPUT, 1.0)
		assert_almost_eq(view._face.face_deg, 90.0, 0.01, "%s: the hold turns the face on to 90 degrees" % fam)
		vm["hold_progress"] = 0.5
		view.present(vm, INPUT, 1.0)
		assert_between(view._face.face_deg, 3 * PlugFace.TICK_DEG, 90.0, "%s: between the ticks and the quarter turn" % fam)


func test_pin_screen_keeps_its_own_bend() -> void:
	# the pin screen's hook bows (PICK_BEND_MM) as before; nothing of D-139 moves its parts
	var view: LockPhotorealView = await _view(&"pin_tumbler")
	view.present(_vm(&"bound", 0.4, 0.0), INPUT, 1.0)
	var safe: Transform3D = view._pick.transform
	UiA11y.reduce_motion_override = 1
	view.present(_vm(&"bound", 0.4, 0.95), INPUT, 1.0)
	assert_true(view._pick.transform.is_equal_approx(safe), "the hook is not turned")
	assert_almost_eq(float(view._pick_mat.get_shader_parameter("bend")), LockPhotorealView.PICK_BEND_MM * 0.95, 0.001)
