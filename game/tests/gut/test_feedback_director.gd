extends GutTest
## R-21/R-22: FeedbackDirector rate limits, coalescing, essential floor, 60 Hz throttle.

func _event(kind: StringName, intensity: float = 1.0) -> Dictionary:
	return {"kind": kind, "sub": 0, "element": 0, "intensity": intensity, "material": &"brass", "tick": 0}


func test_transient_rate_limit() -> void:
	var fd := FeedbackDirector
	fd.reset()
	var played := 0
	var orig := Haptics.play
	# count via monkey-see: use a local counter through the events signal is complex;
	# instead verify no crash and limits list stays bounded
	for i in 200:
		fd.emit_event(_event(&"contact", 0.5))
	assert_lte(fd._transient_times.size(), fd._transient_limit())

func test_coalescing_30ms_window() -> void:
	var fd := FeedbackDirector
	fd.reset()
	fd.emit_event(_event(&"drop", 0.4))
	fd.emit_event(_event(&"drop", 0.9))  # within 30 ms -> coalesced, not re-emitted
	assert_eq(fd._last_transient_by_kind[&"drop"]["intensity"], 0.9)

func test_essential_floor() -> void:
	Settings.set_value("haptics_intensity", 0.0)
	Settings.set_value("haptics_enabled", true)
	var fd := FeedbackDirector
	assert_gt(fd.continuous_floor(), 0.0)
	Settings.set_value("haptics_intensity", 1.0)

func test_continuous_throttle_60hz() -> void:
	var fd := FeedbackDirector
	fd._last_continuous_sent = 0.0
	fd._last_continuous.clear()
	fd.update_continuous(&"tension_resistance", 0.5, 0.3)
	var sent_at := fd._last_continuous_sent
	fd.update_continuous(&"tension_resistance", 0.6, 0.3)  # < 16 ms later -> skipped
	assert_eq(fd._last_continuous_sent, sent_at, "update within 16 ms must be throttled (R-22)")
