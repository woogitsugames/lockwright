extends GutTest
## HintLadder escalation, ONBOARDING §2.1 (D-23): thresholds 15/30/45/60 s, progress()
## resets to H0, updates without progress never reset the counter, H4 at most once per
## step (the level then stays at 3), a new step starts from zero, custom thresholds
## (S2/S3 shorten the H2 -> H4 gap), channels in the dark (ONBOARDING §7.2).

const DT := 0.5  # exact in binary, so threshold crossings are deterministic


func _events(ladder: HintLadder) -> Array:
	var events: Array = []
	ladder.level_changed.connect(func(level: int, step_id: StringName) -> void:
		events.append([level, step_id]))
	return events


func _run(ladder: HintLadder, seconds: float) -> int:
	var level := ladder.level
	for i in int(seconds / DT):
		level = ladder.update(DT)
	return level


func _count_level(events: Array, level: int) -> int:
	return events.filter(func(e: Array) -> bool: return e[0] == level).size()


func test_default_thresholds_15_30_45_60() -> void:
	var ladder := HintLadder.new()
	assert_true(ladder.thresholds == PackedFloat32Array([15.0, 30.0, 45.0, 60.0]))
	ladder.start_step(&"s1.tension")
	var events := _events(ladder)
	assert_eq(_run(ladder, 14.5), 0)
	assert_eq(ladder.update(0.5), 1, "H1 at 15 s")
	assert_eq(_run(ladder, 14.5), 1)
	assert_eq(ladder.update(0.5), 2, "H2 at 30 s")
	assert_eq(_run(ladder, 14.5), 2)
	assert_eq(ladder.update(0.5), 3, "H3 at 45 s")
	assert_eq(_run(ladder, 14.5), 3)
	assert_eq(ladder.update(0.5), 4, "H4 at 60 s")
	assert_eq(events, [[1, &"s1.tension"], [2, &"s1.tension"],
		[3, &"s1.tension"], [4, &"s1.tension"]])
	# telemetry: one {step, level, t} entry per level rise (ONBOARDING §12)
	assert_eq(ladder.history.size(), 4)
	assert_eq(ladder.history[0]["step"], &"s1.tension")
	assert_eq(ladder.history[0]["level"], 1)
	assert_almost_eq(ladder.history[0]["t"], 15.0, 0.01)
	assert_eq(ladder.history[3]["level"], 4)


func test_progress_resets_to_h0() -> void:
	var ladder := HintLadder.new()
	ladder.start_step(&"s1.tension")
	assert_eq(_run(ladder, 30.0), 2)
	ladder.progress()
	assert_eq(ladder.level, 0)
	assert_eq(ladder.update(0.5), 0, "0.5 s after progress: still H0")
	assert_eq(_run(ladder, 14.0), 0, "14.5 s after progress: still H0")
	var events := _events(ladder)
	assert_eq(ladder.update(0.5), 1, "H1 fires again after progress")
	assert_eq(_count_level(events, 1), 1)
	# the reset is in the telemetry
	assert_eq(ladder.history[ladder.history.size() - 2]["level"], 0)
	assert_eq(ladder.history[ladder.history.size() - 1]["level"], 1)


func test_updates_without_progress_keep_climbing() -> void:
	# Aimless swiping is just update() calls with no progress(): the ladder must not
	# reset (ONBOARDING §2.1: the counter measures time since the last progress).
	var ladder := HintLadder.new()
	ladder.start_step(&"s1.pick")
	assert_eq(_run(ladder, 15.0), 1)
	assert_eq(_run(ladder, 15.0), 2, "no touch of progress() in between")
	assert_eq(_run(ladder, 15.0), 3)
	assert_eq(_run(ladder, 15.0), 4)
	assert_eq(ladder.history.size(), 4)


func test_h4_at_most_once_per_step() -> void:
	var ladder := HintLadder.new()
	ladder.start_step(&"s1.tension")
	var events := _events(ladder)
	assert_eq(_run(ladder, 60.0), 4)
	assert_true(ladder.h4_done())
	# the counter keeps growing, but the level stays at 3 and H4 never fires again
	assert_eq(_run(ladder, 60.0), 3)
	assert_eq(_run(ladder, 60.0), 3)
	assert_eq(_count_level(events, 4), 1, "H4 fires exactly once per step")
	assert_eq(_count_level(events, 3), 1)


func test_new_step_starts_from_zero() -> void:
	var ladder := HintLadder.new()
	ladder.start_step(&"s1.tension")
	assert_eq(_run(ladder, 60.0), 4)
	assert_true(ladder.h4_done())
	ladder.start_step(&"s1.pick")
	assert_eq(ladder.level, 0)
	assert_eq(ladder.update(0.5), 0)
	assert_false(ladder.h4_done(), "H4 may play again in the new step")
	var events := _events(ladder)
	assert_eq(_run(ladder, 59.0), 3)
	assert_eq(ladder.update(0.5), 4, "H4 can play again in the new step")
	assert_eq(_count_level(events, 4), 1)
	assert_eq(ladder.history[ladder.history.size() - 1]["step"], &"s1.pick")


func test_custom_thresholds() -> void:
	var ladder := HintLadder.new()
	# S2/S3 shorten the path "H2 -> H4 after 30 s" (ONBOARDING §4, steps 2.1/3.1)
	ladder.thresholds = PackedFloat32Array([10.0, 15.0, 20.0, 30.0])
	ladder.start_step(&"s2.tension")
	assert_eq(_run(ladder, 9.5), 0)
	assert_eq(ladder.update(0.5), 1, "H1 at 10 s")
	assert_eq(ladder.update(5.0), 2, "H2 at 15 s")
	assert_eq(ladder.update(5.0), 3, "H3 at 20 s")
	assert_eq(ladder.update(10.0), 4, "H4 at 30 s")


func test_channels_normal_mode() -> void:
	var ladder := HintLadder.new()
	assert_eq_deep(ladder.channels(0), {"visual": false, "sound": false,
		"haptic": false, "light": false})
	# H1-H3: image + sound, no haptics (a hint must never read as lock state)
	assert_eq_deep(ladder.channels(1), {"visual": true, "sound": true,
		"haptic": false, "light": false})
	assert_eq_deep(ladder.channels(2), {"visual": true, "sound": true,
		"haptic": false, "light": false})
	assert_eq_deep(ladder.channels(3), {"visual": true, "sound": true,
		"haptic": false, "light": false})
	# H4: all channels, with haptics; no light needed
	assert_eq_deep(ladder.channels(4), {"visual": true, "sound": true,
		"haptic": true, "light": false})


func test_channels_dark_mode() -> void:
	var ladder := HintLadder.new()
	ladder.dark_mode = true
	# In the dark H1-H3 play by sound and haptics only (ONBOARDING §7.2)
	assert_eq_deep(ladder.channels(1), {"visual": false, "sound": true,
		"haptic": true, "light": false})
	assert_eq_deep(ladder.channels(2), {"visual": false, "sound": true,
		"haptic": true, "light": false})
	assert_eq_deep(ladder.channels(3), {"visual": false, "sound": true,
		"haptic": true, "light": false})
	# H4 turns the light on for a moment, so the master hand is visible
	assert_eq_deep(ladder.channels(4), {"visual": true, "sound": true,
		"haptic": true, "light": true})
	# channels() with no argument reads the current level
	ladder.start_step(&"a2.pick")
	ladder.thresholds = PackedFloat32Array([1.0, 2.0, 3.0, 4.0])
	ladder.update(2.5)
	assert_eq_deep(ladder.channels(), ladder.channels(2))
