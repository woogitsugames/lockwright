class_name SoakRun
extends RefCounted
## D-136: long-session soak. One cycle walks the screens a player goes through in a job
##   menu -> job list -> arrival -> verification -> lock -> job list with the "day after" -> workshop
##   -> showcase -> settings
## (each scene is instantiated, shown for a few frames and freed, like a scene change), with a job of
## another lock family every cycle. After every cycle the engine's counters are sampled:
## objects, resources, nodes, orphan nodes, static memory, signal connections held on the autoloads.
## A leak (a node left outside the tree, a texture kept in a cache that only grows, a lambda still
## connected to an autoload) shows as a counter that climbs with the cycle number.
##
##   godot --headless --path game res://tests/soak.tscn -- --cycles=200 [--out=soak.json]
##   GUT: tests/gut/test_soak.gd (short run in every CI build)

const MENU := "res://scenes/main_menu.tscn"
const JOBS := "res://scenes/jobs_list.tscn"
const ARRIVAL := "res://scenes/job_arrival.tscn"
const VERIFY := "res://scenes/job_verify.tscn"
const WORKSHOP := "res://scenes/workshop.tscn"
const SHOWCASE := "res://scenes/showcase.tscn"
const SETTINGS := "res://scenes/settings.tscn"
const AUTOLOADS := ["Settings", "Save", "I18n", "Events", "Haptics", "FeedbackDirector", "UiA11y", "Sfx", "Quality",
	"Achievements", "Nav", "VoicePacks", "ContentPacks"]
const COUNTERS := ["objects", "resources", "nodes", "orphans", "connections", "static_kb", "texture_kb", "video_kb"]
## Allowed growth per cycle after the warm-up. Objects, resources, nodes, orphans and connections
## must not grow over a long run (the small allowance covers one-off lazy caches); static memory
## may drift by allocator fragmentation only.
const LIMITS := {"objects": 0.5, "resources": 0.2, "nodes": 0.2, "orphans": 0.05, "connections": 0.05, "static_kb": 24.0,
	"texture_kb": 8.0, "video_kb": 64.0}
## Headless only: Godot 4.7.2's dummy renderer keeps ~29 bytes of static memory for every Control
## ever created (engine-only check: 200,000 plain Controls created and freed grow MEMORY_STATIC by
## 5.8 MB headless and by 0 with OpenGL). A cycle creates ~4,000 Controls, so static memory cannot be
## held to the real limit there; texture and video memory read 0. The strict limits apply with a
## real renderer (xvfb + opengl3 in CI, a phone).
const HEADLESS_LIMITS := {"static_kb": 400.0}
## Frames a screen stays up (its _ready, deferred calls and first layout), and lock physics frames.
const SCREEN_FRAMES := 2
const LOCK_FRAMES := 6

var samples: Array[Dictionary] = []   # one per cycle, after the cycle's screens are freed
var jobs: Array[Dictionary] = []      # the rotation: one job per playable lock family
var screens_shown := 0
var screen_peaks := {}                # step -> {static_kb, texture_kb, video_kb, nodes, resources}: highest seen
## Diagnostics: when not empty, only these steps of the cycle run (to find which screen leaks):
## menu, jobs, arrival, verify, lock, day_after, workshop, showcase, settings.
var only: PackedStringArray = []
var _tree: SceneTree
var _shown: Node


## One job per playable lock family (the first of each in list order), so the rotation loads every
## family's lock screen.
static func rotation() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var seen := {}
	var all: Array = JobRun.all_jobs()
	all.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return String(a.get("id", "")) < String(b.get("id", "")))
	for job: Dictionary in all:
		var fam := JobRun.family_for(job)
		if seen.has(fam) or not JobRun.is_playable(job) or JobRun.is_talk(job):
			continue
		seen[fam] = true
		out.append(job)
	return out


static func sample(tree: SceneTree) -> Dictionary:
	var connections := 0
	for name: String in AUTOLOADS:
		var n := tree.root.get_node_or_null(name)
		if n == null:
			continue
		for sig: Dictionary in n.get_signal_list():
			connections += n.get_signal_connection_list(sig["name"]).size()
	return {
		"objects": int(Performance.get_monitor(Performance.OBJECT_COUNT)),
		"resources": int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)),
		"nodes": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		"orphans": int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)),
		"connections": connections,
		"static_kb": int(Performance.get_monitor(Performance.MEMORY_STATIC) / 1024.0),
		"texture_kb": int(Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1024.0),
		"video_kb": int(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1024.0),
	}


func _on(step: String) -> bool:
	return only.is_empty() or only.has(step)


func _frames(n: int) -> void:
	for i in n:
		await _tree.process_frame


func _show(path: String, frames := SCREEN_FRAMES, step := "") -> void:
	if is_instance_valid(_shown):
		_shown.queue_free()
		await _frames(1)  # the screen before is gone before this one is measured
	_shown = (load(path) as PackedScene).instantiate()
	_tree.root.add_child(_shown)
	_tree.current_scene = _shown
	screens_shown += 1
	await _frames(frames)
	_note_screen(step if step != "" else path.get_file().get_basename())


## Highest memory seen while each screen was up (a real renderer reports texture / video memory).
func _note_screen(step: String) -> void:
	var now := sample(_tree)
	var peak: Dictionary = screen_peaks.get(step, {})
	for k: String in ["static_kb", "texture_kb", "video_kb", "nodes", "resources"]:
		peak[k] = maxi(int(peak.get(k, 0)), int(now[k]))
	screen_peaks[step] = peak


func _close() -> void:
	if is_instance_valid(_shown):
		_shown.queue_free()
	_shown = null
	await _frames(2)


## Runs `cycles` cycles. The save, the settings and the job context are put back at the end.
func run(tree: SceneTree, cycles: int) -> void:
	_tree = tree
	jobs = rotation()
	var save: Node = tree.root.get_node("Save")
	var events: Node = tree.root.get_node("Events")
	var save_backup: Dictionary = save.data.duplicate(true)
	var events_backup := [events.change_scenes, events.scene_override]
	var job_backup := [JobRun.mode, JobRun.current_job, JobRun.lives, JobRun.clean]
	var last_job_backup: String = load("res://scripts/ui/jobs_list.gd").last_job_id
	events.change_scenes = false
	save.data["tutorial_done"] = true   # memory only: the menu and the workshop of a career in progress
	for c in cycles:
		var job: Dictionary = jobs[c % jobs.size()] if not jobs.is_empty() else {}
		if _on("menu"):
			await _show(MENU)
		if _on("jobs"):
			await _show(JOBS)
		if not job.is_empty():
			JobRun.start(job)
			if _on("arrival"):
				await _show(ARRIVAL)
			if _on("verify"):
				await _show(VERIFY)
			if _on("lock"):
				await _show(JobRun.lock_scene_path(), LOCK_FRAMES, "lock_" + String(JobRun.family_for(job)))
			if _on("day_after"):
				# the day after: the finished job's follow-up over the job list
				save.data["day_after"] = {}
				DayAfter.note_finished(job)
				await _show(JOBS, SCREEN_FRAMES, "jobs_list_day_after")
		if _on("workshop"):
			await _show(WORKSHOP)
		if _on("showcase"):
			await _show(SHOWCASE)
		if _on("settings"):
			await _show(SETTINGS)
		await _close()
		LockPreload.release()
		# background loads still decoding when their screen left are taken as they finish
		# (ArrivalScene sweeps every 0.25 s); the sample waits for that, 3 s at most
		var t0 := Time.get_ticks_msec()
		while (ArrivalScene.stray_count() > 0 or not LockPreload.pending().is_empty()) and Time.get_ticks_msec() - t0 < 3000:
			await _frames(1)
			LockPreload.release()
		samples.append(sample(tree))
	save.data = save_backup
	save.save()
	events.change_scenes = events_backup[0]
	events.scene_override = events_backup[1]
	JobRun.mode = job_backup[0]
	JobRun.current_job = job_backup[1]
	JobRun.lives = job_backup[2]
	JobRun.clean = job_backup[3]
	load("res://scripts/ui/jobs_list.gd").last_job_id = last_job_backup


## Growth of each counter from the sample after `warmup` cycles to the last one, and per cycle.
## The warm-up covers the first visit of every lock family (shared caches fill once).
func growth(warmup: int) -> Dictionary:
	var out := {}
	if samples.size() <= warmup:
		return out
	var a: Dictionary = samples[warmup - 1] if warmup > 0 else samples[0]
	var b: Dictionary = samples[samples.size() - 1]
	var n := float(samples.size() - maxi(warmup, 1))
	for k: String in COUNTERS:
		out[k] = int(b[k]) - int(a[k])
		out[k + "_per_cycle"] = (int(b[k]) - int(a[k])) / maxf(n, 1.0)
	return out


## Counters whose growth per cycle after the warm-up is over LIMITS (empty = flat).
func over_limits(warmup: int) -> PackedStringArray:
	var g := growth(warmup)
	var failed: PackedStringArray = []
	for k: String in LIMITS:
		if float(g.get(k + "_per_cycle", 0.0)) > limit(k):
			failed.append(k)
	return failed


static func limit(counter: String) -> float:
	if DisplayServer.get_name() == "headless" and HEADLESS_LIMITS.has(counter):
		return float(HEADLESS_LIMITS[counter])
	return float(LIMITS[counter])
