extends GutTest
## Perf pass 2026-11-08 on the budget phone (SM-A165F, docs/handoff/POMIARY.md §9): guards for the
## fixes that keep video memory and loading hitches down, and the PerfProbe helpers.

const PLATE_2X := [
	"res://assets/photoreal_families/warded/photo/wards.png",
	"res://assets/photoreal_families/warded/photo/plate.png",
	"res://assets/photoreal_families/warded/photo/parts.png",
	"res://assets/photoreal_families/wafer/photo/plate.png",
	"res://assets/photoreal_families/wafer/photo/parts.png",
	"res://assets/photoreal_families/lever/photo/plate.png",
	"res://assets/photoreal_families/lever/photo/parts_detector.png",
	"res://assets/photoreal_families/lever/photo/parts.png",
	"res://assets/photoreal/plate/plate_1236x1650.png",
	"res://assets/photoreal/plate/plate_dimple_1236x1650.png",
	"res://assets/photoreal/plate/plate_magnetic_1236x1650.png",
]


func _import_param(res_path: String, key: String) -> String:
	var f := FileAccess.open(res_path + ".import", FileAccess.READ)
	if f == null:
		return ""
	for line in f.get_as_text().split("\n"):
		if line.strip_edges().begins_with(key + "="):
			return line.strip_edges().substr(key.length() + 1)
	return ""


func test_every_2x_plate_has_a_half_size_1x_sibling() -> void:
	for p in PLATE_2X:
		var alt := LockPhotorealView.plate_variant(p, 1080.0)
		assert_ne(alt, p, "%s: a phone loads the 1x sibling" % p)
		var big := load(p) as Texture2D
		var small := load(alt) as Texture2D
		assert_not_null(small, alt)
		if big != null and small != null:
			assert_eq(small.get_size(), big.get_size() / 2.0, "%s is exactly half of %s" % [alt, p])
		assert_eq(_import_param(alt, "compress/mode"), "4", "%s: Basis Universal on phones (D-88)" % alt)


func test_plate_variant_picks_by_section_size() -> void:
	var p: String = PLATE_2X[0]
	assert_eq(LockPhotorealView.plate_variant(p, 1080.0), p.replace(".png", "_1x.png"), "1080 px phone")
	assert_eq(LockPhotorealView.plate_variant(p, 1290.0), p.replace(".png", "_1x.png"), "1290 px phone")
	assert_eq(LockPhotorealView.plate_variant(p, 1812.0), p, "Fold inner screen keeps the 2x plate")
	var no_sibling := "res://assets/photoreal_families/combo/photo/plate.png"
	assert_eq(LockPhotorealView.plate_variant(no_sibling, 1080.0), no_sibling, "1x-only plates unchanged")


func test_no_2x_plate_without_1x_sibling() -> void:
	# a new 2472-px plate must come with its _1x sibling (or be added to PLATE_2X)
	for dir in ["res://assets/photoreal/plate", "res://assets/photoreal_families/warded/photo",
			"res://assets/photoreal_families/wafer/photo", "res://assets/photoreal_families/lever/photo"]:
		for f in ResourceLoader.list_directory(dir):
			if not f.ends_with(".png") or f.contains("_1x."):
				continue
			var t := load(dir + "/" + f) as Texture2D
			if t != null and t.get_width() > 2000:
				assert_has(PLATE_2X, dir + "/" + f, "2x plate with a 1x sibling")


func test_workshop_layers_are_size_limited() -> void:
	for f in ResourceLoader.list_directory("res://assets/ui/workshop"):
		if f.ends_with(".webp"):
			var lim := int(_import_param("res://assets/ui/workshop/" + f, "process/size_limit"))
			assert_between(lim, 1, 2560, "%s: <= 2560 px (2x of a 1080x2340 cover fit is ~2630)" % f)


func test_staging_buffer_is_capped() -> void:
	# Godot's default 128 MB staging pool grows on texture/glyph uploads and is never returned
	var mb := int(ProjectSettings.get_setting("rendering/rendering_device/staging_buffer/max_size_mb", 128))
	assert_lte(mb, 32, "staging buffer cap (video memory high-water mark)")


func test_perf_probe_helpers() -> void:
	var Probe := load("res://scripts/autoload/perf_probe.gd")
	var marks := [["A", 110], ["B", 150], ["C", 400]]
	assert_eq(Probe.mark_durations(marks, 100), [["A", 10], ["B", 40], ["C", 250]])
	var v := PackedFloat32Array([16.0, 17.0, 16.5, 33.0, 16.7, 16.6, 16.8, 16.9, 16.4, 100.0])
	assert_almost_eq(Probe.percentile(v, 0.5), 16.7, 0.001)
	assert_eq(Probe.percentile(v, 1.0), 100.0)
	assert_eq(Probe.percentile(PackedFloat32Array(), 0.95), 0.0)


func test_lock_preload_paths() -> void:
	var pin := LockPreload.paths_for(&"pin_tumbler", "res://scenes/lock_job.tscn", 1080.0)
	assert_has(pin, "res://scenes/lock_job.tscn", "the scene itself")
	assert_has(pin, "res://assets/photoreal/plate/plate_1236x1650_1x.png", "the 1x plate the phone loads")
	assert_does_not_have(pin, "res://assets/photoreal/plate/plate_1236x1650.png", "not the 2x one")
	var fold := LockPreload.paths_for(&"pin_tumbler", "res://scenes/lock_job.tscn", 1812.0)
	assert_has(fold, "res://assets/photoreal/plate/plate_1236x1650.png", "Fold keeps the 2x plate")
	for fam in JobRun.PLANB_SCENES:
		var paths := LockPreload.paths_for(fam, JobRun.PLANB_SCENES[fam], 1080.0)
		assert_eq(paths[0], JobRun.PLANB_SCENES[fam], "%s: scene first" % fam)
		assert_gt(paths.size(), 1, "%s: plates/model besides the scene" % fam)
		for p in paths:
			assert_true(ResourceLoader.exists(p), p)
			assert_eq(LockPhotorealView.plate_variant(p, 1080.0), p, "%s: the variant a phone loads" % p)


func test_lock_preload_start_and_release() -> void:
	var n := LockPreload.start(&"combo", JobRun.PLANB_SCENES[&"combo"], 1080.0)
	assert_gte(n, 0)
	var t0 := Time.get_ticks_msec()
	while not LockPreload.pending().is_empty() and Time.get_ticks_msec() - t0 < 20000:
		LockPreload.release()
		await get_tree().process_frame
	assert_eq(LockPreload.pending().size(), 0, "every background load handed back")


func test_sfx_lock_clicks_warm_up_off_the_main_thread() -> void:
	# cold start no longer waits for ~380 lock clicks; a click before the warm-up ends still plays
	assert_not_null(Sfx._stream_for(&"set", &"brass"), "a lock click is available at once")
	var t0 := Time.get_ticks_msec()
	while Sfx.warming_up() and Time.get_ticks_msec() - t0 < 20000:
		await get_tree().process_frame
	assert_false(Sfx.warming_up(), "background loads collected")
	assert_not_null(Sfx._cached("pick_drag/brass/1") if ResourceLoader.exists("res://assets/audio/sfx/pick_drag/brass_1.wav") else Sfx._stream_for(&"set", &"brass"))


func test_boot_preloads_the_menu_board() -> void:
	var src := FileAccess.get_file_as_string("res://scripts/ui/boot.gd")
	assert_string_contains(src, "load_threaded_request", "boot warms the menu up on a worker thread")


func test_frame_hint_is_inert_without_the_plugin() -> void:
	# D-88: desktop/tests have no LockwrightHaptics plugin -> no ADPF session, no per-frame calls
	assert_false(FrameHint.active)
	assert_eq(FrameHint.reports, 0)
	var FH := load("res://scripts/autoload/frame_hint.gd")
	assert_eq(FH.work_us(1000, 14000), 13000)
	assert_eq(FH.work_us(5000, 5000), 1, "never zero")
	assert_eq(FH.work_us(0, 5000000), 1000000, "clamped to 1 s")


func test_lock_view_refresh_once_per_frame_in_exports() -> void:
	# D-88: exported builds refresh the view from _process with the summed delta of the frame's steps
	var scene: Node = load("res://scenes/lock_job.tscn").instantiate()
	add_child_autofree(scene)
	await get_tree().process_frame
	scene.set_process(false)
	scene.view_per_frame = true
	scene._physics_process(1.0 / 120.0)
	scene._physics_process(1.0 / 120.0)
	assert_true(scene._pv_pending, "no view refresh inside the physics steps")
	assert_almost_eq(scene._pv_delta, 2.0 / 120.0, 0.0001, "delta of both steps kept")
	scene._flush_present()
	assert_false(scene._pv_pending)
	assert_eq(scene._pv_delta, 0.0)


func test_large_lock_and_menu_textures_are_gpu_compressed() -> void:
	# D-88: Basis Universal (-> ASTC on Android/iOS) for the textures that dominate a screen's memory
	for p in ["res://assets/photoreal_families/wafer/photo/plate_1x.png", "res://assets/photoreal/plate/plate_1236x1650_1x.png",
			"res://assets/photoreal/tray/tray_full.png", "res://assets/ui/menu/menu_portrait_pl.webp",
			"res://assets/ui/workshop/workshop_base.webp"]:
		assert_eq(_import_param(p, "compress/mode"), "4", "%s: Basis Universal" % p)


func test_native_click_bank_holds_every_lock_click() -> void:
	# D-101: the Oboe bridge had 32 slots for 336 clicks; most clicks took Godot's ~126 ms path
	var n: int = Sfx._native_candidates().size()
	assert_gt(n, 32, "more clicks than the old 32 slots")
	var header := ProjectSettings.globalize_path("res://").path_join("../platform/android/lockwright-click-audio/src/main/cpp/click_engine.h")
	var f := FileAccess.open(header, FileAccess.READ)
	if f == null:
		pass_test("plugin sources not next to the project")
		return
	var m := RegEx.create_from_string("kMaxSamples[ ]*=[ ]*([0-9]+)").search(f.get_as_text())
	assert_not_null(m, "kMaxSamples in click_engine.h")
	if m != null:
		assert_gte(int(m.get_string(1)), n, "every lock click (%d) fits the native bank" % n)


func test_click_path_counts_engine_without_bridge() -> void:
	var before: Dictionary = Sfx.click_path_counts()
	Sfx.play(&"set", &"brass")
	var after: Dictionary = Sfx.click_path_counts()
	assert_eq(int(after["engine"]), int(before["engine"]) + 1, "desktop: AudioServer path counted")
	Sfx.stop_all_one_shots()
