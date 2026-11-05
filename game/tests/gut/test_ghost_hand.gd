extends GutTest
## GhostHand (ONBOARDING §2.2): a shadow that never swallows touches (mouse_filter
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
