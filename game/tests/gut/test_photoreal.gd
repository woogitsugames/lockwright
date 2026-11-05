extends GutTest
## Photoreal lock screen (scenes/photoreal, plan B D-31): pin pose mapping and a headless run
## through a real (or fake) session.


func test_free_pin_driver_blocks_shear_line() -> void:
	var p := PinPose.pose({"state": &"free", "position": 0.0})
	var key_top: float = p["key_bottom"] + p["key_len"]
	assert_lt(key_top, PinPose.SHEAR, "key pin below the shear line at rest")
	assert_almost_eq(p["driver_bottom"], key_top, 0.001, "driver rests on the key pin")
	assert_lt(p["driver_bottom"], PinPose.SHEAR, "driver crosses the shear line: plug blocked")


func test_key_pin_top_reaches_shear_at_target() -> void:
	var el := {"state": &"bound", "position": 0.6, "window_lo": 0.55, "window_hi": 0.65}
	var p := PinPose.pose(el)
	assert_almost_eq(p["key_bottom"] + p["key_len"], PinPose.SHEAR, 0.001)
	assert_gt(p["tilt_deg"], 0.0, "binding driver leans (realizm.md)")


func test_set_leaves_a_gap_on_both_sides_of_the_shear_line() -> void:
	var p := PinPose.pose({"state": &"set", "position": 0.56})
	assert_gt(p["driver_bottom"], PinPose.SHEAR, "driver above the shear line")
	assert_lt(p["key_bottom"] + p["key_len"], PinPose.SHEAR, "key pin dropped below it")


func test_spool_false_set_straddles_shear() -> void:
	var p := PinPose.pose({"state": &"false_set", "position": 0.4, "variant": 1})
	assert_true(p["spool"])
	var waist: float = p["driver_bottom"] + PinPose.SPOOL_WAIST
	assert_almost_eq(waist, PinPose.SHEAR + 0.06, 0.001)


func test_overset_key_pin_crosses_shear() -> void:
	var p := PinPose.pose({"state": &"overset", "position": 1.2})
	assert_gt(p["key_bottom"] + p["key_len"], PinPose.SHEAR)
	assert_gt(p["driver_bottom"], PinPose.SHEAR)


func test_states_are_distinct_by_geometry() -> void:
	# A7: every state readable without colour -> different (key top, driver bottom, tilt) triples.
	var seen := {}
	for el in [{"state": &"free", "position": 0.2}, {"state": &"bound", "position": 0.2},
			{"state": &"set", "position": 0.56}, {"state": &"false_set", "position": 0.4, "variant": 1},
			{"state": &"overset", "position": 1.2}]:
		var p := PinPose.pose(el)
		var sig := "%.2f|%.2f|%.1f|%s" % [p["key_bottom"] + p["key_len"], p["driver_bottom"], p["tilt_deg"], p["spool"]]
		assert_false(seen.has(sig), "state %s looks like %s" % [el["state"], seen.get(sig, "")])
		seen[sig] = el["state"]


func test_scene_runs_headless_with_session() -> void:
	var scene: Node = load("res://scenes/photoreal/lock_photoreal.tscn").instantiate()
	add_child_autofree(scene)
	await wait_physics_frames(10)
	var view: LockPhotorealView = scene.get_node("ViewLayer/View")
	assert_not_null(view.viewport, "3D section viewport built")
	assert_eq(view.lives, 3)
	view.on_event({"kind": &"break", "element": 0, "intensity": 1.0, "material": &"steel"})
	assert_eq(view.lives, 2, "a broken pick leaves an empty pocket")
	view.present(scene.blender_pose_vm(), {"tension": 0.5, "pick_depth": 0.5, "pick_lift": 0.3})
	assert_true(view.section_rect.size.x > 0.0)
