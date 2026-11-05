extends GutTest
## Task 4: every lockcore family is creatable/steppable through the Godot binding,
## and lockcore's own scripted bot (solve) opens each family when its recorded
## inputs are replayed through step() — i.e. through the Godot layer.

const FAMILIES := [&"pin_tumbler", &"wafer", &"wooden_pin", &"warded", &"lever", &"lever_detector", &"ring_combo"]

func _make(family: StringName, seed: int = 7, tier: int = 1) -> RefCounted:
	assert_true(ClassDB.class_exists("LockcoreSession"))
	var s: RefCounted = ClassDB.instantiate("LockcoreSession")
	assert_true(s.create(family, seed, tier), "create failed for %s" % family)
	return s


func test_all_families_create_and_step() -> void:
	for fam in FAMILIES:
		var s := _make(fam)
		var events: Array = s.step(0.5, 0.5, 0.5, 0.3, 0.0, 0)
		var vm: Dictionary = s.describe()
		assert_true(vm.has("elements"), "describe missing elements for %s" % fam)
		assert_false(s.finished(), "%s finished after one step" % fam)


func test_lockcore_bot_opens_every_family_through_godot() -> void:
	for fam in FAMILIES:
		var report: Dictionary = LockcoreSession.solve(fam, 7, 1)
		assert_true(report.get("ok", false), "solver failed for %s: %s" % [fam, report.get("reason")])
		var s := _make(fam, 7, 1)
		var opened := false
		for row in report.get("inputs", []):
			var events: Array = s.step(row[0], row[1], row[2], row[3], row[4], row[5])
			for e in events:
				if e["kind"] == &"open":
					opened = true
		assert_true(opened or s.is_open(), "replaying bot inputs did not open %s" % fam)
		assert_eq(s.event_hash(), report.get("event_hash"), "event_hash mismatch for %s" % fam)
