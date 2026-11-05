extends GutTest
## R-16: the same seed + input stream through LockcoreSession must give the same
## event_hash on every run and platform (golden value recorded from lockcore CI).

const GOLDEN_HASH := 8916582219576943443

func test_lockcore_session_deterministic() -> void:
	assert_true(ClassDB.class_exists("LockcoreSession"), "LockcoreSession must be loaded (R-16)")
	var s: RefCounted = ClassDB.instantiate("LockcoreSession")
	assert_true(s.create(&"pin_tumbler", 42, 2))
	for tick in 120 * 10:
		var t := 0.5 if (tick % 480) < 400 else 0.0
		var depth := float((tick / 96) % 5) / 5.0
		var lift := 0.6 if (tick % 96) > 48 else 0.0
		s.step(t, depth, lift)
	var h1: int = s.event_hash()
	var s2: RefCounted = ClassDB.instantiate("LockcoreSession")
	s2.create(&"pin_tumbler", 42, 2)
	for tick in 120 * 10:
		var t := 0.5 if (tick % 480) < 400 else 0.0
		var depth := float((tick / 96) % 5) / 5.0
		var lift := 0.6 if (tick % 96) > 48 else 0.0
		s2.step(t, depth, lift)
	assert_eq(s2.event_hash(), h1, "same inputs must give the same event_hash")
	assert_eq(h1, GOLDEN_HASH, "golden event_hash mismatch (R-16)")
	print("GOLDEN event_hash = ", h1)
