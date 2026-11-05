extends GutTest
## Task 17: CPU cost of one 120 Hz physics step through the binding (step + describe
## + feedback dispatch), measured headless. Budget on a weak phone: << 8.33 ms/step.

func test_step_cost() -> void:
	assert_true(ClassDB.class_exists("LockcoreSession"))
	var s: RefCounted = ClassDB.instantiate("LockcoreSession")
	s.create(&"pin_tumbler", 42, 3)
	# warmup
	for i in 120:
		s.step(0.5, 0.5, 0.5)
	var t0 := Time.get_ticks_usec()
	var n := 120 * 60
	for i in n:
		var ev: Array = s.step(0.4 + 0.001 * (i % 100), 0.5, 0.6)
		for e in ev:
			FeedbackDirector.emit_event(e)
		var vm: Dictionary = s.describe()
	var dt := (Time.get_ticks_usec() - t0) / float(n)
	print("PERF step+describe+feedback avg_us=%.2f (budget 8333 us)" % dt)
	assert_lt(dt, 8333.0, "one step must cost < 8.33 ms even on weak CPU")
