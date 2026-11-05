extends GutTest
## GUT test suite for the 4 photoreal lock family screens (Plan B, D-31 / D-37):
##   - `wafer` (`lock_photoreal_wafer.tscn` + `WaferPose`)
##   - `lever` & `lever_detector` (`lock_photoreal_lever.tscn` + `LeverPose`)
##   - `warded` (`lock_photoreal_warded.tscn` + `WardedPose`)
##   - `wooden_pin` (`lock_photoreal_wooden_pin.tscn` + `WoodenPinPose`)
## Modeled after `res://tests/gut/test_photoreal.gd`.


# ------------------------------------------------------------------ WaferPose
func test_wafer_free_blocks_lower_shear_slot() -> void:
	var p := WaferPose.pose({"state": &"free", "position": 0.0})
	assert_lt(p["bottom_y"], -WaferPose.PLUG_R, "free wafer bottom tab protrudes into lower housing slot")
	assert_almost_eq(p["tilt_deg"], 0.0, 0.001)


func test_wafer_bound_leans_and_shifts() -> void:
	var p := WaferPose.pose({"state": &"bound", "position": 0.32})
	assert_gt(p["tilt_deg"], 0.0, "binding wafer leans against housing slot wall")
	assert_gt(p["sx"], 0.0, "binding wafer shifts laterally under tension")


func test_wafer_set_sits_flush_inside_plug() -> void:
	var p := WaferPose.pose({"state": &"set", "position": 0.55})
	assert_lt(p["top_y"], WaferPose.PLUG_R, "set wafer top horn clears upper shear line")
	assert_gt(p["bottom_y"], -WaferPose.PLUG_R, "set wafer bottom tab clears lower shear line")


func test_wafer_false_set_catches_step() -> void:
	var p := WaferPose.pose({"state": &"false_set", "position": 0.42, "variant": 1})
	assert_true(p["false_step"])
	assert_gt(p["tilt_deg"], WaferPose.BIND_TILT_DEG, "false-set wafer cants deeper into step")


func test_wafer_overset_horns_enter_upper_slot() -> void:
	var p := WaferPose.pose({"state": &"overset", "position": 1.2})
	assert_gt(p["top_y"], WaferPose.PLUG_R, "overset wafer top horns protrude into upper housing slot")


func test_wafer_states_are_distinct_by_geometry() -> void:
	var seen := {}
	for st in [&"free", &"bound", &"set", &"false_set", &"overset", &"detector"]:
		var p := WaferPose.pose({"state": st, "position": 0.35, "variant": 1})
		var sig := "%.2f|%.2f|%.1f|%.2f|%s|%s" % [
			p["top_y"], p["bottom_y"], p["tilt_deg"], p["sx"], p["false_step"], p["detector_tripped"]
		]
		assert_false(seen.has(sig), "wafer state %s collides with %s" % [st, seen.get(sig, "")])
		seen[sig] = st


# ------------------------------------------------------------------ LeverPose
func test_lever_free_upper_tooth_blocks_stump() -> void:
	var p := LeverPose.pose({"state": &"free", "position": 0.0})
	assert_lt(p["gate_hi_y"], LeverPose.STUMP_Y, "free lever gate sits completely below stump")


func test_lever_set_clears_stump_both_sides() -> void:
	var p := LeverPose.pose({"state": &"set", "position": 0.52})
	assert_lt(p["gate_lo_y"], -LeverPose.STUMP_R, "gate floor below stump bottom")
	assert_gt(p["gate_hi_y"], LeverPose.STUMP_R, "gate ceiling above stump top")


func test_lever_false_set_enters_false_notch() -> void:
	var p := LeverPose.pose({"state": &"false_set", "position": 0.38, "variant": 1})
	assert_true(p["in_false_gate"])
	assert_lt(p["bolt_dx"], -1.0, "bolt stump shifts deeper into false gate notch")


func test_lever_overset_lower_tooth_blocks_stump() -> void:
	var p := LeverPose.pose({"state": &"overset", "position": 1.15})
	assert_gt(p["gate_lo_y"], -LeverPose.STUMP_R, "overset lever lower tooth blocks stump")


func test_lever_detector_trips_pawl_into_bolt_notch() -> void:
	var p := LeverPose.pose({"state": &"detector", "position": 1.3})
	assert_true(p["detector_tripped"])
	assert_lt(p["detector_deg"], -10.0, "detector pawl rotates down into bolt tail notch")


func test_lever_states_are_distinct_by_geometry() -> void:
	var seen := {}
	for st in [&"free", &"bound", &"set", &"false_set", &"overset", &"detector"]:
		var p := LeverPose.pose({"state": st, "position": 0.35, "variant": 1})
		var sig := "%.2f|%.2f|%.2f|%s|%s" % [
			p["delta_lift"], p["rot_deg"], p["bolt_dx"], p["in_false_gate"], p["detector_tripped"]
		]
		assert_false(seen.has(sig), "lever state %s collides with %s" % [st, seen.get(sig, "")])
		seen[sig] = st


# ------------------------------------------------------------------ WardedPose
func test_warded_free_stud_locks_bolt() -> void:
	var p := WardedPose.pose({"state": &"free", "position": 0.0})
	assert_lt(p["stud_bottom_y"], WardedPose.BOLT_TOP_Y, "free tumbler stud sits inside bolt notch")


func test_warded_set_stud_clears_bolt_top() -> void:
	var p := WardedPose.pose({"state": &"set", "position": 0.60})
	assert_gt(p["stud_bottom_y"], WardedPose.BOLT_TOP_Y, "set tumbler stud clears bolt top edge")


func test_warded_states_are_distinct_by_geometry() -> void:
	var seen := {}
	for st in [&"free", &"bound", &"set", &"false_set", &"overset", &"detector"]:
		var p := WardedPose.pose({"state": st, "position": 0.40, "variant": 1})
		var sig := "%.1f|%.2f|%.2f|%.2f|%s|%s" % [
			p["bit_delta_deg"], p["tumbler_lift"], p["stud_bottom_y"], p["bolt_dx"], p["in_false_step"], p["detector_tripped"]
		]
		assert_false(seen.has(sig), "warded state %s collides with %s" % [st, seen.get(sig, "")])
		seen[sig] = st


# ------------------------------------------------------------------ WoodenPinPose
func test_wooden_pin_free_foot_deep_in_bolt() -> void:
	var p := WoodenPinPose.pose({"state": &"free", "position": 0.0})
	assert_lt(p["foot_y"], WoodenPinPose.BOLT_TOP_Y, "free wooden pin foot blocks sliding bolt")


func test_wooden_pin_set_foot_clears_bolt_shear_line() -> void:
	var p := WoodenPinPose.pose({"state": &"set", "position": 0.56})
	assert_gt(p["foot_y"], WoodenPinPose.BOLT_TOP_Y, "set wooden pin foot clears top of sliding bolt")


func test_wooden_pin_false_set_waist_straddles_shear() -> void:
	var p := WoodenPinPose.pose({"state": &"false_set", "position": 0.40, "variant": 1})
	assert_true(p["in_false_groove"])
	var groove_y: float = float(p["foot_y"]) + WoodenPinPose.FALSE_GROOVE_OFFSET
	assert_almost_eq(groove_y, WoodenPinPose.BOLT_TOP_Y, 0.05, "turned waist groove catches on bolt top")


func test_wooden_pin_overset_lifter_crosses_shear() -> void:
	var p := WoodenPinPose.pose({"state": &"overset", "position": 1.2})
	assert_gt(p["lifter_top_y"], WoodenPinPose.BOLT_TOP_Y, "overset lifter peg enters bolt hole")


func test_wooden_pin_states_are_distinct_by_geometry() -> void:
	var seen := {}
	for st in [&"free", &"bound", &"set", &"false_set", &"overset", &"detector"]:
		var p := WoodenPinPose.pose({"state": st, "position": 0.35, "variant": 1})
		var sig := "%.2f|%.2f|%.1f|%.2f|%s|%s" % [
			p["foot_y"], p["lifter_top_y"], p["tilt_deg"], p["sx"], p["in_false_groove"], p["detector_tripped"]
		]
		assert_false(seen.has(sig), "wooden_pin state %s collides with %s" % [st, seen.get(sig, "")])
		seen[sig] = st


# ------------------------------------------------------------------ Headless Scene & Session Tests
func _verify_family_scene(scene_path: String, expected_family: StringName) -> void:
	var scene: LockPhotorealFamily = load(scene_path).instantiate()
	add_child_autofree(scene)
	await wait_physics_frames(6)
	var view: LockPhotorealFamilyView = scene.get_node("ViewLayer/View")
	assert_not_null(view.viewport, "3D section viewport built for %s" % expected_family)
	assert_eq(view.lives, 3)
	view.on_event({"kind": &"break", "element": 0, "intensity": 1.0, "material": &"steel"})
	assert_eq(view.lives, 2, "broken tool leaves an empty pocket in %s" % expected_family)
	for st in ["free", "bound", "set", "false_set", "overset", "detector"]:
		var vm := LockPhotorealFamily.state_pose_vm(expected_family, st)
		view.present(vm, {"tension": 0.5, "pick_depth": 0.5, "pick_lift": 0.4})
	assert_gt(view.section_rect.size.x, 0.0)


func test_wafer_scene_runs_headless_with_session() -> void:
	await _verify_family_scene("res://scenes/photoreal_families/lock_photoreal_wafer.tscn", &"wafer")


func test_lever_and_detector_scene_runs_headless_with_session() -> void:
	await _verify_family_scene("res://scenes/photoreal_families/lock_photoreal_lever.tscn", &"lever_detector")


func test_warded_scene_runs_headless_with_session() -> void:
	await _verify_family_scene("res://scenes/photoreal_families/lock_photoreal_warded.tscn", &"warded")


func test_wooden_pin_scene_runs_headless_with_session() -> void:
	await _verify_family_scene("res://scenes/photoreal_families/lock_photoreal_wooden_pin.tscn", &"wooden_pin")


func test_dark_mode_hides_3d_section_for_true_oled_black() -> void:
	var scene: LockPhotorealFamily = load("res://scenes/photoreal_families/lock_photoreal_wafer.tscn").instantiate()
	add_child_autofree(scene)
	await wait_physics_frames(4)
	var view: LockPhotorealFamilyView = scene.get_node("ViewLayer/View")
	view.set_dark(true)
	var section_rect_node: Control = view.get_node("Section")
	assert_false(section_rect_node.visible, "T06 P0: 3D section must be hidden in dark mode for true #000000 OLED black")
	view.set_dark(false)
	assert_true(section_rect_node.visible, "3D section restored when leaving dark mode")
