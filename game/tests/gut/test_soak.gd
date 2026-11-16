extends GutTest
## D-136: a short long-session soak in every test run (tests/soak_run.gd). The full one (200+ cycles,
## real renderer, texture memory) is tests/soak.tscn, run by the perf-budget workflow.
## One cycle = menu -> job list -> arrival -> verification -> lock -> job list with the day after ->
## workshop -> showcase -> settings, with a job of another lock family each time. After every lock
## family was seen once (shared caches filled), eight more cycles must leave the engine's counters
## where they were: no node outside the tree, no node or resource kept, no connection left on an
## autoload.

const EXTRA_CYCLES := 8


func test_screen_cycles_leave_nothing_behind() -> void:
	var before_save: Dictionary = Save.data.duplicate(true)
	var soak := SoakRun.new()
	var families := SoakRun.rotation().size()
	assert_gte(families, 12, "the rotation covers the playable lock families")
	await soak.run(get_tree(), families + EXTRA_CYCLES)
	assert_eq(soak.samples.size(), families + EXTRA_CYCLES)
	assert_eq(soak.screens_shown, (families + EXTRA_CYCLES) * 9, "nine screens a cycle")
	var warm: Dictionary = soak.samples[families - 1]
	var last: Dictionary = soak.samples[soak.samples.size() - 1]
	gut.p("soak warm=%s last=%s" % [JSON.stringify(warm), JSON.stringify(last)])
	assert_eq(int(last["orphans"]), int(warm["orphans"]), "no node left outside the tree (the orphaned MainMenu of D-133)")
	assert_eq(int(last["nodes"]), int(warm["nodes"]), "every screen's nodes are freed")
	assert_eq(int(last["connections"]), int(warm["connections"]), "no screen stays connected to an autoload's signal")
	assert_lte(int(last["resources"]) - int(warm["resources"]), 2, "no texture / stream / material kept per cycle")
	# tweens and one-shot timers still running at the sample move the object count by a few
	assert_lte(int(last["objects"]) - int(warm["objects"]), 8, "objects stay flat")
	assert_eq(ArrivalScene.stray_count(), 0, "no background frame load left with the loader")
	assert_true(LockPreload.pending().is_empty(), "no warmed-up lock left with the loader")
	assert_eq(JSON.stringify(Save.data), JSON.stringify(before_save), "the soak puts the save back")


## The orphan monitor is what catches a screen taken out of the tree and never freed.
func test_orphan_monitor_sees_a_forgotten_screen() -> void:
	var before := int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	var forgotten := Control.new()
	assert_eq(int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)), before + 1)
	forgotten.free()
	assert_eq(int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)), before)
