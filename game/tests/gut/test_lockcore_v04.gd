extends GutTest
## Task 2: lockcore v0.4 in the game — progress fields in ViewModel, lever rules v2.

func test_describe_has_progress_fields() -> void:
	assert_true(ClassDB.class_exists("LockcoreSession"))
	var s: RefCounted = ClassDB.instantiate("LockcoreSession")
	assert_true(s.create(&"pin_tumbler", 42, 2))
	s.step(0.5, 0.5, 0.5)
	var vm: Dictionary = s.describe()
	assert_true(vm.has("hold_progress"), "v0.4 hold_progress missing")
	assert_true(vm.has("reset_progress"), "v0.4 reset_progress missing")

func test_lever_rules_version_2() -> void:
	# v0.3/D-34: lever and lever_detector are RULES_VERSION 2
	assert_eq(LockcoreSession.rules_version(&"lever"), 2)
	assert_eq(LockcoreSession.rules_version(&"lever_detector"), 2)

func test_lever_detector_progress_in_range() -> void:
	var s: RefCounted = ClassDB.instantiate("LockcoreSession")
	assert_true(s.create(&"lever_detector", 8, 6))
	for tick in 120 * 30:
		s.step(0.6, 0.5, 0.7, 0.5, 0.0, 0)  # poke the detector
		var vm: Dictionary = s.describe()
		var rp: float = vm.get("reset_progress", -1.0)
		assert_true(rp >= 0.0 and rp <= 1.0, "reset_progress out of range")
		if s.finished():
			break
