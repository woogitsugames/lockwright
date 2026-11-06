extends GutTest
## GhostHand (ONBOARDING §2.2, D-77): a paper cut-out hand that never swallows touches (mouse_filter
## IGNORE), play_gesture finishes with a signal after the expected time, the eased
## gesture_progress runs 0..1, mirror flips the position for the left-handed option,
## and the fallback thumb oval (no texture) plays without crashing.

const DT := 1.0 / 30.0
const PARENT_DP := Vector2(412.0, 915.0)
const FROM_DP := Vector2(80.0, 700.0)
const TO_DP := Vector2(200.0, 580.0)


func _ghost() -> GhostHand:
	var parent := Control.new()
	parent.size = PARENT_DP
	add_child_autofree(parent)
	var ghost := GhostHand.new()
	parent.add_child(ghost)
	return ghost


func test_mouse_filter_is_ignore() -> void:
	var ghost := _ghost()
	assert_eq(ghost.mouse_filter, Control.MOUSE_FILTER_IGNORE)
	assert_true(ghost.mouse_filter != Control.MOUSE_FILTER_STOP)


func test_play_gesture_finishes_after_expected_time() -> void:
	var ghost := _ghost()
	watch_signals(ghost)
	# fade 0.15 + 2 repeats * (travel 0.5 + hold 0.25) + fade 0.15 = 1.8 s
	ghost.play_gesture(FROM_DP, TO_DP, 0.5, 2, 0.25)
	simulate(ghost, 40, DT)
	assert_true(ghost.is_playing(), "still mid-gesture at 1.33 s")
	assert_signal_not_emitted(ghost, "gesture_finished")
	simulate(ghost, 20, DT)
	assert_false(ghost.is_playing(), "finished by 2.07 s")
	assert_signal_emitted(ghost, "gesture_finished")
	assert_signal_emit_count(ghost, "gesture_finished", 1)
	assert_false(ghost.is_playing())


func test_gesture_progress_runs_0_to_1() -> void:
	var ghost := _ghost()
	var values: Array = []
	ghost.gesture_progress.connect(func(t: float) -> void: values.append(t))
	ghost.play_gesture(FROM_DP, TO_DP, 0.5, 1)
	simulate(ghost, 30, DT)
	assert_eq(values[0], 0.0, "the first reported progress is the start pose")
	assert_eq(values[values.size() - 1], 1.0, "the last reported progress is the end pose")
	for i in range(1, values.size()):
		assert_lte(values[i - 1], values[i], "progress never goes back within a repeat")


func test_hold_gesture_reports_1_during_the_hold() -> void:
	var ghost := _ghost()
	watch_signals(ghost)
	var values: Array = []
	ghost.gesture_progress.connect(func(t: float) -> void: values.append(t))
	# "place and hold": from == to, hold 1.5 s (ONBOARDING §4 step 1.2)
	ghost.play_gesture(FROM_DP, FROM_DP, 0.1, 1, 1.5)
	simulate(ghost, 80, DT)
	assert_eq(values[values.size() - 1], 1.0)
	assert_signal_emitted(ghost, "gesture_finished")


func test_mirror_flips_position() -> void:
	var straight := _ghost()
	straight.play_gesture(FROM_DP, TO_DP, 0.5, 1)
	assert_eq(straight.ghost_center, FROM_DP)
	simulate(straight, 25, DT)  # fade (0.15) + travel (0.5) done at 0.65 s
	assert_almost_eq(straight.ghost_center.x, TO_DP.x, 0.01)
	assert_almost_eq(straight.ghost_center.y, TO_DP.y, 0.01)

	var mirrored := _ghost()
	mirrored.mirror = true
	mirrored.play_gesture(FROM_DP, TO_DP, 0.5, 1)
	# mirrored across the parent's centre: x' = 412 - x
	assert_eq(mirrored.ghost_center, Vector2(PARENT_DP.x - FROM_DP.x, FROM_DP.y))
	simulate(mirrored, 25, DT)
	assert_almost_eq(mirrored.ghost_center.x, PARENT_DP.x - TO_DP.x, 0.01)
	assert_almost_eq(mirrored.ghost_center.y, TO_DP.y, 0.01)


func test_no_texture_plays_the_fallback_oval() -> void:
	var ghost := _ghost()
	assert_eq(ghost.texture, null)
	# fallback silhouette: thumb oval 22x56 dp + half the soft edge on each side
	assert_eq(ghost.size, Vector2(22.0 + 12.0, 56.0 + 12.0))
	watch_signals(ghost)
	ghost.play_gesture(FROM_DP, FROM_DP, 0.1, 2, 1.5)
	simulate(ghost, 120, DT)  # 0.3 + 2 * 1.6 + 0.3 = 3.8 s
	assert_signal_emitted(ghost, "gesture_finished")
	assert_false(ghost.is_playing())
	assert_true(ghost.ghost_center.x > 0.0)


# ---------------------------------------------------------------- G23 silhouettes
const SILHOUETTES := [&"thumb_left_press", &"thumb_right_press", &"thumb_right_slide",
	&"hand_left_tool", &"hand_right_tool", &"hand_right_open"]


func test_g23_silhouettes_load() -> void:
	for n in SILHOUETTES:
		var d := GhostHand.load_silhouette(n)
		assert_false(d.is_empty(), "%s loads" % n)
		if d.is_empty():
			continue
		var tex: Texture2D = d["texture"]
		assert_gt(tex.get_width(), 64, "%s has a usable size" % n)
		var a: Vector2 = d["anchor"]
		assert_true(a.x > 0.0 and a.x < 1.0 and a.y > 0.0 and a.y < 1.0, "%s hotspot inside the texture" % n)
		var size_dp: Vector2 = tex.get_size() * float(d["scale"])
		assert_between(size_dp.x, 120.0, 320.0, "%s fits a 412 dp phone width (the wrist part runs off the edge)" % n)
		# a cut-out alpha: transparent at the corners (no photo rectangle), opaque in the middle of the shape
		var img := tex.get_image()
		if img.is_compressed():
			img.decompress()
		assert_lt(img.get_pixel(1, 1).a, 0.05, "%s corner transparent" % n)
		var hs := Vector2i(int(a.x * img.get_width()), int(a.y * img.get_height()))
		assert_gt(img.get_pixel(hs.x, hs.y).a, 0.5, "%s opaque at the thumb" % n)


func test_set_silhouette_and_fallback_oval() -> void:
	var ghost := _ghost()
	assert_true(ghost.set_silhouette(&"thumb_left_press"))
	assert_not_null(ghost.texture)
	assert_eq(ghost.silhouette, &"thumb_left_press")
	assert_eq(ghost.mouse_filter, Control.MOUSE_FILTER_IGNORE, "a texture never makes the ghost take touches")
	assert_false(ghost.set_silhouette(&"no_such_hand"), "a missing silhouette reports false")
	assert_null(ghost.texture, "... and falls back to the oval")
	assert_eq(ghost.silhouette, &"")
	ghost.play_gesture(FROM_DP, TO_DP, 0.2, 1)
	simulate(ghost, 20, DT)
	assert_false(ghost.is_playing(), "the oval still plays")


static func _rel_lum(c: Color) -> float:
	var l := func(v: float) -> float: return v / 12.92 if v <= 0.04045 else pow((v + 0.055) / 1.055, 2.4)
	return 0.2126 * l.call(c.r) + 0.7152 * l.call(c.g) + 0.0722 * l.call(c.b)


static func _ratio(a: float, b: float) -> float:
	return (maxf(a, b) + 0.05) / (minf(a, b) + 0.05)


func test_paper_cutout_reads_on_dark_leather_and_light_metal() -> void:
	# D-77: a dark shadow on the dark roll could not pass ~1.3:1 (D-76). The ghost is a bone fill with
	# a 2 dp ink edge: the fill must clear 3:1 on the darkest leather (rel. luminance ~0.01 under the
	# thumbs in portrait) and the ink on the light lock body (~0.35), and the two must differ in
	# lightness alone (grayscale). Every silhouette and the oval use the same look.
	var fill := GhostHand.FILL_COLOR.lerp(Color(0.02, 0.015, 0.01), 1.0 - GhostHand.FILL_OPACITY)
	assert_gte(_ratio(_rel_lum(fill), 0.01), 3.0, "fill over the darkest leather")
	assert_gte(_ratio(_rel_lum(fill), 0.05), 3.0, "fill over mid leather")
	assert_gte(_ratio(_rel_lum(GhostHand.EDGE_COLOR), 0.35), 3.0, "ink edge over the light lock body")
	assert_gte(_ratio(_rel_lum(GhostHand.EDGE_COLOR), _rel_lum(fill)), 3.0, "ink vs fill")
	assert_gte(GhostHand.EDGE_DP, 2.0, "dividing lines >= 2 dp")
	var ghost := _ghost()
	assert_null(ghost.material, "the oval draws its own fill + ring")
	var seen := {}
	for n in [&"thumb_left_press", &"thumb_right_press", &"thumb_right_slide", &"hand_left_tool"]:
		assert_true(ghost.set_silhouette(n))
		assert_not_null(ghost.material, "%s is cut out by the shader" % n)
		var mat := ghost.material as ShaderMaterial
		assert_almost_eq(float(mat.get_shader_parameter(&"edge_px")), GhostHand.EDGE_DP / ghost.texture_scale, 0.001,
			"%s ink edge is 2 dp at any import size" % n)
		seen[n] = ghost.fill_opacity()
	assert_eq(seen[&"thumb_left_press"], seen[&"thumb_right_press"], "both thumbs look the same")
	ghost.set_silhouette(&"no_such_hand")
	assert_null(ghost.material, "back to the oval")


func test_release_shape_shows_while_letting_go() -> void:
	var ghost := _ghost()
	watch_signals(ghost)
	ghost.set_silhouette(&"hand_left_tool")
	assert_true(ghost.set_release_silhouette(&"hand_right_open", true))
	var tool_tex := ghost.texture
	# fade 0.15 + travel 0.3 + hold 0.1 -> release 0.25
	ghost.play_gesture(FROM_DP, TO_DP, 0.3, 1, 0.1)
	simulate(ghost, 18, DT)  # 0.6 s: in the release
	assert_true(ghost.is_playing())
	assert_ne(ghost.texture, tool_tex, "the open hand shows while letting go")
	assert_true(ghost.texture_flip, "the right-hand photo is mirrored for the left side")
	var d := ghost.ghost_center.distance_to(TO_DP)
	assert_between(d, 0.1, GhostHand.RELEASE_DP + 0.01, "it withdraws a little")
	simulate(ghost, 10, DT)
	assert_false(ghost.is_playing())
	assert_signal_emit_count(ghost, "gesture_finished", 1)
	assert_eq(ghost.texture, tool_tex, "the gesture shape is back for the next play")


func test_textured_ghost_never_intercepts_clicks() -> void:
	var vp := SubViewport.new()
	vp.size = Vector2i(412, 915)
	vp.gui_disable_input = false
	add_child_autofree(vp)
	var under := Button.new()
	under.position = Vector2.ZERO
	under.size = Vector2(412, 915)
	vp.add_child(under)
	var parent := Control.new()
	parent.size = PARENT_DP
	parent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vp.add_child(parent)
	var ghost := GhostHand.new()
	parent.add_child(ghost)
	ghost.set_silhouette(&"hand_right_open")
	ghost.play_gesture(FROM_DP, FROM_DP, 0.1, 1, 2.0)
	simulate(ghost, 6, DT)
	assert_true(ghost.is_playing())
	var hits := [0]
	under.button_down.connect(func() -> void: hits[0] += 1)
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.position = FROM_DP
	ev.global_position = FROM_DP
	ev.pressed = true
	vp.push_input(ev)
	assert_eq(hits[0], 1, "the click under the ghost hand reaches the control below")
