extends GutTest
## D-105: guards for test determinism.
## - No worker-thread texture loads headless (CI, GUT): in the dummy renderer they race textures made on
##   the main thread and intermittently fail with "Parameter t is null" (texture_2d_initialize), which
##   turned unrelated tests red at random (D-101 LockPreload, arrival frames D-99). Every script that calls
##   ResourceLoader.load_threaded_request() must skip it headless; audio-only loaders are listed below.
## - The per-script isolation hook (res://tests/gut_isolation_hook.gd) is wired through .gutconfig.json,
##   so CI and every local run (also -gselect) get it.

## Scripts whose background loads are audio streams only (no renderer RIDs): safe headless.
const AUDIO_ONLY := ["res://scripts/autoload/sfx.gd"]


func _scripts(dir: String, out: Array) -> void:
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".gd"):
			out.append(dir.path_join(f))
	for d in DirAccess.get_directories_at(dir):
		_scripts(dir.path_join(d), out)


func test_threaded_loads_are_off_headless() -> void:
	var files: Array = []
	_scripts("res://scripts", files)
	assert_gt(files.size(), 20)
	var users := 0
	for p: String in files:
		var src := FileAccess.get_file_as_string(p)
		if not src.contains("load_threaded_request"):
			continue
		users += 1
		if p in AUDIO_ONLY:
			continue
		assert_true(src.contains("\"headless\""), "%s loads on worker threads without a headless guard" % p)
	assert_gt(users, 1, "the scan sees the background loaders")


func test_isolation_hook_is_configured() -> void:
	var cfg: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://.gutconfig.json"))
	assert_eq(typeof(cfg), TYPE_DICTIONARY, ".gutconfig.json parses")
	if typeof(cfg) != TYPE_DICTIONARY:
		return
	assert_eq(String(cfg.get("pre_run_script", "")), "res://tests/gut_isolation_hook.gd")
	assert_true(FileAccess.file_exists("res://tests/gut_isolation_hook.gd"))
	assert_not_null(gut.get_pre_run_script_instance(), "the hook ran for this run")
