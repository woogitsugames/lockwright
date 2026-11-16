extends Node
## D-136: long-session soak runner (see soak_run.gd). Exit code 1 when a counter keeps growing.
##   godot --headless --path game res://tests/soak.tscn -- --cycles=200 [--out=/tmp/soak.json] [--warmup=N] [--only=menu,jobs]
## Limits: SoakRun.LIMITS; rationale in docs/handoff/PERF-STABILITY-2026-11-16.md §2.


func _ready() -> void:
	var cycles := 200
	var out := ""
	var warmup := -1
	var only: PackedStringArray = []
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--cycles="):
			cycles = int(a.trim_prefix("--cycles="))
		elif a.begins_with("--out="):
			out = a.trim_prefix("--out=")
		elif a.begins_with("--warmup="):
			warmup = int(a.trim_prefix("--warmup="))
		elif a.begins_with("--only="):
			only = a.trim_prefix("--only=").split(",", false)
	await get_tree().process_frame  # the root is still adding its children during _ready
	var soak := SoakRun.new()
	soak.only = only
	var t0 := Time.get_ticks_msec()
	await soak.run(get_tree(), cycles)
	var secs := (Time.get_ticks_msec() - t0) / 1000.0
	if warmup < 0:
		warmup = mini(soak.jobs.size() * 2, cycles / 2)  # every lock family seen twice
	var g := soak.growth(warmup)
	var failed := soak.over_limits(warmup)
	print("SOAK cycles=%d screens=%d families=%d warmup=%d wall_s=%.1f" % [cycles, soak.screens_shown, soak.jobs.size(), warmup, secs])
	print("SOAK first=%s" % JSON.stringify(soak.samples[0]))
	print("SOAK warm=%s" % JSON.stringify(soak.samples[maxi(warmup - 1, 0)]))
	print("SOAK last=%s" % JSON.stringify(soak.samples[soak.samples.size() - 1]))
	print("SOAK growth=%s" % JSON.stringify(g))
	print("SOAK renderer=%s" % DisplayServer.get_name())
	for step: String in soak.screen_peaks:
		var pk: Dictionary = soak.screen_peaks[step]
		print("SOAK screen %-24s static_mb=%6.1f texture_mb=%6.1f video_mb=%6.1f nodes=%d" % [step, pk["static_kb"] / 1024.0,
			pk["texture_kb"] / 1024.0, pk["video_kb"] / 1024.0, pk["nodes"]])
	if out != "":
		var f := FileAccess.open(out, FileAccess.WRITE)
		if f != null:
			f.store_string(JSON.stringify({"cycles": cycles, "screens": soak.screens_shown, "warmup": warmup, "wall_s": secs,
				"limits": SoakRun.LIMITS, "growth": g, "failed": failed, "renderer": DisplayServer.get_name(),
				"screen_peaks": soak.screen_peaks, "samples": soak.samples}))
	print(("SOAK FAIL: %s" % ", ".join(failed)) if not failed.is_empty() else "SOAK OK")
	await get_tree().process_frame
	get_tree().quit(1 if not failed.is_empty() else 0)
