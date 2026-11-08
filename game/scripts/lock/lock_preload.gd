class_name LockPreload
extends RefCounted
## Perf pass 2026-11-08: the lock screen took 0.4-1.0 s from "Accept" to its first frame on a budget
## phone (SM-A165F): compiling its scripts, decoding the plan-B plates (lossy WebP -> RGBA) and loading
## the baked model, all on the main thread in the tap's frame. The verify screen (the player reads the
## client's cards for a few seconds) starts those loads on worker threads, so change_scene_to_file()
## and the view's load() calls find them in the ResourceLoader cache (load() waits for a load already
## in flight instead of starting a second one).
## Only a cache warm-up: a path that the screen does not use costs memory until release(), nothing else.

const FAM_ROOT := "res://assets/photoreal_families/"
const COMMON := [
	"res://assets/photoreal/tray/tray_full.png",
	"res://assets/photoreal/tray/tray_empty.png",
	"res://assets/photo/leather_brown_worn_albedo_1k.jpg",
	"res://assets/photo/leather_stitching_strip_albedo_1k.jpg",
	"res://assets/photo/leather_brass_snap_1k.webp",
]
const PIN_PATHS := [
	"res://assets/photoreal/plate/plate_1236x1650.png",
	"res://assets/photoreal/cutaway_baked.glb",
]

static var _requested: PackedStringArray = []


## Files worth loading ahead for the lock screen of `family` at `scene_path` on a section viewport of
## `section_px` (short side, see LockPhotorealView.plate_variant): the scene, the shared tray/leather,
## the family's photo plates (the 1x or 2x variant the view will pick) and its baked model.
static func paths_for(family: StringName, scene_path: String, section_px: float) -> PackedStringArray:
	var out := PackedStringArray([scene_path])
	out.append_array(COMMON)
	if family == &"pin_tumbler":
		for p in PIN_PATHS:
			out.append(LockPhotorealView.plate_variant(p, section_px) if p.ends_with(".png") else p)
	else:
		var fam_dir := FAM_ROOT + String(family) + "/"
		var photo := fam_dir + "photo/"
		for f in ResourceLoader.list_directory(photo):
			if not (f.ends_with(".png") or f.ends_with(".webp")) or f.contains("_1x."):
				continue
			out.append(LockPhotorealView.plate_variant(photo + f, section_px))
		var glb := fam_dir + String(family) + "_baked.glb"
		out.append(glb)
	var seen := {}
	var unique := PackedStringArray()
	for p in out:
		if not seen.has(p) and ResourceLoader.exists(p):
			seen[p] = true
			unique.append(p)
	return unique


## Starts the background loads for the current job's lock screen (no-op for talk-only jobs).
static func start(family: StringName, scene_path: String, section_px: float) -> int:
	release()
	var n := 0
	for p in paths_for(family, scene_path, section_px):
		if ResourceLoader.has_cached(p):
			continue
		if ResourceLoader.load_threaded_request(p) == OK:
			_requested.append(p)
			n += 1
	return n


## Drops the loader's hold on the finished background loads (the lock screen keeps what it uses).
## Loads still running stay listed and are dropped on the next call.
static func release() -> void:
	var still := PackedStringArray()
	for p in _requested:
		var st := ResourceLoader.load_threaded_get_status(p)
		if st == ResourceLoader.THREAD_LOAD_LOADED:
			ResourceLoader.load_threaded_get(p)
		elif st == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			still.append(p)
	_requested = still


static func pending() -> PackedStringArray:
	return _requested
