extends GutTest
## N-65 (Fold 8 Ultra, "high"): the plan-B section is rendered at its on-screen pixel size
## × Quality planb_scale, never a fixed 824×1100 stretched over a large screen; MSAA follows
## the profile, FXAA when MSAA is off.


func _open(path: String, size: Vector2i) -> Node:
	var vp := SubViewport.new()
	vp.size = size
	add_child_autofree(vp)
	var scene: Node = load(path).instantiate()
	vp.add_child(scene)
	await wait_physics_frames(3)
	return scene


func test_section_viewport_follows_the_screen_size() -> void:
	for path in ["res://scenes/lock_job.tscn", "res://scenes/photoreal/lock_job_warded.tscn"]:
		var small: Node = await _open(path, Vector2i(412, 915))
		var big: Node = await _open(path, Vector2i(824, 1830))
		var a: Vector2i = small.view.viewport.size
		var b: Vector2i = big.view.viewport.size
		var sec: Rect2 = big.view.section_rect
		assert_gt(b.y, a.y * 1.8, "%s: section viewport grows with the screen (%s → %s)" % [path.get_file(), a, b])
		assert_gte(float(b.y), sec.size.y * 0.99, "%s: at least one 3D pixel per screen pixel" % path.get_file())


func test_quality_scale_and_msaa_apply_to_the_section() -> void:
	var scene: Node = await _open("res://scenes/lock_job.tscn", Vector2i(412, 915))
	var view: LockPhotorealView = scene.view
	var full: Vector2i = view.viewport.size
	view.render_scale = 0.5
	assert_almost_eq(float(view.viewport.size.y), full.y * 0.5, 2.0, "planb_scale halves the section")
	view.msaa = 2
	assert_eq(view.viewport.msaa_3d, Viewport.MSAA_4X)
	view.msaa = 0
	assert_eq(view.viewport.msaa_3d, Viewport.MSAA_DISABLED)
	assert_eq(view.viewport.screen_space_aa, Viewport.SCREEN_SPACE_AA_FXAA, "FXAA when MSAA is off")


func test_pixel_cap() -> void:
	var scene: Node = await _open("res://scenes/lock_job.tscn", Vector2i(412, 915))
	var view: LockPhotorealView = scene.view
	view.render_scale = 3.0
	var s: Vector2i = view.viewport.size
	assert_lte(float(s.x) * s.y, LockPhotorealView.MAX_VP_PIXELS * 1.01, "capped")
