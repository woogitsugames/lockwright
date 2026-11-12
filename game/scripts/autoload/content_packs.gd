extends "res://scripts/autoload/pack_store.gd"
## D-112 (D-99): chapters beyond the base game ship as downloadable content packs.
## A pack is one data-only Godot pck (`content_<id>.pck`, built by tools/build_content_packs.py from
## game/packs/<id>/) that adds files under res://packs/<id>/ only:
##   pack.json             {schema, id, version, min_game, chapters, jobs}   (the pack's own manifest)
##   jobs/<job id>.json    the jobs, same schema as res://data/jobs
##   i18n/content.csv      their texts (5 languages), merged into I18n
##   arrival_scenes.json   their arrival scenes (schema of res://data/arrival_scenes.json), frames and
##                         plates anywhere under the pack (e.g. arrival/<job>/<time>/...)
## The app's own list of packs is res://data/content_packs.json (written by the build tool, committed by
## .github/workflows/content-packs.yml): per pack the file, URL, size, SHA-256, version, min_game,
## chapters and `jobs` ({job id: {chapter, family, tier}}). The size and hash are part of the app, so
## a pack is used only when it is byte for byte the one built for this version of the game.
##
## Download, resume, hash check, storage (user://content_packs) and removal are pack_store.gd, shared
## with the voice packs (D-100): one plain HTTPS GET to GitHub Releases, nothing sent.
## Nothing is downloaded on its own: the job list shows a chapter that is not on the phone with its
## size and a Download plate; Settings -> Content lists the packs and removes them.
##
## Registries: job_paths() / job_path() (every job list reads these, not the folder), stubs() (the
## minimal data of jobs whose pack is not on the phone, so progress read from the save — reached
## chapter, practice unlocks — does not go back when a pack is removed), arrival_scenes() and the
## texts (I18n.add_csv). A removed or missing pack never breaks the save: its jobs are just absent
## from the lists, `jobs_completed` keeps their ids, and they are back when the pack is.
##
## In the editor (not an exported build) every game/packs/<id>/ folder on disk counts as part of
## the game ("bundled"): the content is playable without building or downloading anything.

signal registry_changed

const MANIFEST_PATH := "res://data/content_packs.json"
const DIR := "user://content_packs"
const ROOT := "res://packs"
const BASE_JOBS_DIR := "res://data/jobs"
const PACK_SCHEMA := "lockwright.content_pack/1"
## What this build of the game can play. A pack whose `min_game` is higher needs a newer game
## (state "update"). Raise it together with game code that new pack data depends on (a new lock
## family, a new job field), and set `min_game` of the packs that use it.
const GAME_LEVEL := 1
const ID_RE := "^[a-z][a-z0-9_]{0,31}$"
const JOB_RE := "^job\\.[a-z0-9_]+$"

# Overridable by tests before the node enters the tree (or before reload()).
var packs_root := ROOT
var game_level := GAME_LEVEL
## Pack sources on disk under packs_root count as bundled. Off in exported builds (the folder is
## not exported: export_presets.cfg excludes packs/*).
var use_local_sources := not OS.has_feature("template")

var _local := {}        # id -> info of a source folder on disk (editor)
var _invalid := {}      # id -> why its manifest entry was dropped
var _job_paths := PackedStringArray()
var _job_path_of := {}  # job id -> path (base and ready packs)
var _job_pack := {}     # job id -> pack id (every valid pack, ready or not)
var _scenes := {}       # job id -> arrival scene (ready packs)
var _csv_done := {}     # csv path -> true
var _ready_ids := []    # ids ready at the last rebuild


func _init() -> void:
	manifest_path = MANIFEST_PATH
	dir = DIR


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(false)
	state_changed.connect(_on_state_changed)
	reload()


func reload() -> void:
	_local = {}
	_invalid = {}
	super.reload()
	if use_local_sources:
		_scan_local()
	_rebuild()


# --- manifest ------------------------------------------------------------------------

## Entries that fail validate_entry() are dropped: the game never offers or mounts them.
func _read_manifest() -> Dictionary:
	var m := super._read_manifest()
	var packs: Variant = m.get("packs", {})
	var good := {}
	if packs is Dictionary:
		for id: Variant in packs:
			var why := validate_entry(str(id), packs[id])
			if why == "":
				good[str(id)] = packs[id]
			else:
				_invalid[str(id)] = why
				push_warning("ContentPacks: pack '%s' ignored: %s" % [id, why])
	m["packs"] = good
	return m


## "" when `e` is a usable entry of res://data/content_packs.json for pack `id`, else the reason.
static func validate_entry(id: String, e: Variant) -> String:
	if not e is Dictionary:
		return "entry is not an object"
	var why := validate_pack(id, e)
	if why != "":
		return why
	if str(e.get("file", "")) != "content_%s.pck" % id:
		return "file must be content_%s.pck" % id
	if not str(e.get("url", "")).begins_with("https://"):
		return "url must be https"
	if not _is_whole(e.get("size")) or int(e["size"]) <= 0:
		return "size must be a positive integer"
	if not RegEx.create_from_string("^[0-9a-f]{64}$").search(str(e.get("sha256", ""))):
		return "sha256 must be 64 lowercase hex digits"
	return ""


## The part shared by a manifest entry and a pack's own pack.json: id, version, min_game,
## chapters, jobs. `jobs` is {job id: {chapter, family, tier}}.
static func validate_pack(id: String, p: Variant) -> String:
	if not p is Dictionary:
		return "not an object"
	if not RegEx.create_from_string(ID_RE).search(id):
		return "bad id"
	if p.has("id") and str(p["id"]) != id:
		return "id does not match"
	if not _is_whole(p.get("version")) or int(p["version"]) < 1:
		return "version must be an integer >= 1"
	if not _is_whole(p.get("min_game")) or int(p["min_game"]) < 1:
		return "min_game must be an integer >= 1"
	var chapters: Variant = p.get("chapters")
	if not chapters is Array or chapters.is_empty():
		return "chapters must be a non-empty list"
	for c: Variant in chapters:
		if not _is_whole(c) or int(c) < 1:
			return "chapters must be integers >= 1"
	var jobs: Variant = p.get("jobs")
	if not jobs is Dictionary or jobs.is_empty():
		return "jobs must be a non-empty object"
	var job_re := RegEx.create_from_string(JOB_RE)
	for jid: Variant in jobs:
		if not job_re.search(str(jid)):
			return "bad job id %s" % jid
		var j: Variant = jobs[jid]
		if not j is Dictionary or not _is_whole(j.get("chapter")):
			return "job %s needs a chapter" % jid
		var in_pack := false
		for c: Variant in chapters:
			in_pack = in_pack or int(c) == int(j["chapter"])
		if not in_pack:
			return "job %s is in chapter %d, not one of the pack's" % [jid, int(j["chapter"])]
	return ""


static func _is_whole(v: Variant) -> bool:
	return (v is int) or (v is float and v == floorf(v))


# --- queries -------------------------------------------------------------------------

func is_bundled(id: String) -> bool:
	return _local.has(id)


func file_name(id: String) -> String:
	return "content_%s.pck" % id


## Every pack the game knows (manifest and, in the editor, source folders), by first chapter.
func ids() -> Array:
	var out := []
	var packs: Dictionary = _manifest.get("packs", {})
	for id: String in packs:
		out.append(id)
	for id: String in _local:
		if not out.has(id):
			out.append(id)
	out.sort_custom(func(a: String, b: String) -> bool:
		var ca := first_chapter(a)
		var cb := first_chapter(b)
		return ca < cb if ca != cb else a < b)
	return out


## {version, min_game, chapters, jobs, size...} of a pack, {} when unknown.
func info(id: String) -> Dictionary:
	if _local.has(id):
		return _local[id]
	return _entry(id)


func chapters(id: String) -> Array:
	var out := []
	for c: Variant in info(id).get("chapters", []):
		out.append(int(c))
	out.sort()
	return out


func first_chapter(id: String) -> int:
	var c := chapters(id)
	return int(c[0]) if not c.is_empty() else 0


func job_count(id: String) -> int:
	return (info(id).get("jobs", {}) as Dictionary).size()


## Player-facing name of a pack: its chapter as the job list names it ("Chapter 13 · name");
## a pack with more chapters: "... and more".
func title(id: String) -> String:
	var ch := first_chapter(id)
	var name_key := StringName("chapter.%d.name" % ch)
	var t: String = I18n.t(&"jobs.chapter").format([ch])
	if I18n.has_key(name_key):
		t = I18n.t(&"jobs.chapter_named").format([ch, I18n.t(name_key)])
	if chapters(id).size() > 1:
		t = I18n.t(&"pack.title_more").format({"title": t})
	return t


## This build of the game is too old for the pack.
func needs_update(id: String) -> bool:
	return int(info(id).get("min_game", 1)) > game_level


## As in pack_store.gd, plus "update": the pack needs a newer game (nothing to download).
func state(id: String) -> String:
	var s := super.state(id)
	if s in ["missing", "failed"] and needs_update(id):
		return "update"
	return s


## Paths of every job file that can be played now: the base game's and the ready packs'.
func job_paths() -> PackedStringArray:
	return _job_paths


## Path of one job's file, "" when the job is unknown or its pack is not on the phone.
func job_path(jid: String) -> String:
	return str(_job_path_of.get(jid, ""))


## The pack a job belongs to ("" for a job of the base game or an unknown one), ready or not.
func pack_of_job(jid: String) -> String:
	return str(_job_pack.get(jid, ""))


## Minimal data of the jobs whose pack is not on the phone: {id, chapter, family, tier, pack, stub}.
## For progress derived from the save only; such a job cannot be started.
func stubs() -> Array:
	var out := []
	for id: String in ids():
		if is_ready(id):
			continue
		var jobs: Dictionary = info(id).get("jobs", {})
		for jid: String in jobs:
			if _job_path_of.has(jid):
				continue
			var j: Dictionary = jobs[jid]
			out.append({"id": jid, "chapter": int(j.get("chapter", 0)), "family": str(j.get("family", "")),
					"tier": int(j.get("tier", 1)), "pack": id, "stub": true})
	return out


func stub(jid: String) -> Dictionary:
	for s: Dictionary in stubs():
		if s["id"] == jid:
			return s
	return {}


## Arrival scenes of the ready packs: {job id: scene}, merged by ArrivalScene.data().
func arrival_scenes() -> Dictionary:
	return _scenes


## Packs that are not on the phone, for the job list: one entry per chapter, in chapter order:
## {pack, chapter}. A pack with two chapters appears under both.
func offers() -> Array:
	var out := []
	for id: String in ids():
		if is_ready(id):
			continue
		for c: int in chapters(id):
			out.append({"pack": id, "chapter": c})
	return out


## Why the manifest entry of `id` was dropped at load ("" when it was not).
func invalid_reason(id: String) -> String:
	return str(_invalid.get(id, ""))


# --- actions -------------------------------------------------------------------------

func ensure(id: String) -> bool:
	if not is_ready(id) and needs_update(id):
		return false
	return super.ensure(id)


## Settings -> Chapters "Remove": the pack's jobs leave the lists now and its file is deleted now
## (a pck is opened per read, never held; a later download brings back the same bytes, the hash is
## pinned). The save is not touched: `jobs_completed` keeps the ids, stubs() keeps their chapters.
func remove(id: String) -> bool:
	if not super.remove(id):
		return false
	# not "mounted" any more for the store: a later download mounts the same file again (its paths
	# are already known to Godot and point at the same offsets)
	_mounted.erase(id)
	_drop_file(id)
	return true


# --- internals -----------------------------------------------------------------------

func pack_dir(id: String) -> String:
	return packs_root.path_join(id)


func _scan_local() -> void:
	if not DirAccess.dir_exists_absolute(packs_root):
		return
	for id in DirAccess.get_directories_at(packs_root):
		if _mounted.has(id):
			continue
		var p: Variant = _read_pack_json(id)
		if p is Dictionary and validate_pack(id, p) == "":
			_local[id] = p


func _read_pack_json(id: String) -> Variant:
	var path := pack_dir(id).path_join("pack.json")
	if not FileAccess.file_exists(path):
		return null
	return parse_json(FileAccess.get_file_as_string(path))


## Mounts the pck and checks that what it holds is the pack the manifest describes. A pck that
## fails is dropped (file and record), so the next try downloads it again.
func _mount(id: String) -> bool:
	if _mounted.has(id):
		return true
	if not super._mount(id):
		_drop_file(id)
		return false
	var why := _check_mounted(id)
	if why != "":
		push_warning("ContentPacks: pack '%s' not used: %s" % [id, why])
		_mounted.erase(id)
		_drop_file(id)
		return false
	return true


func _check_mounted(id: String) -> String:
	var e := _entry(id)
	var p: Variant = _read_pack_json(id)
	if not p is Dictionary:
		return "no pack.json"
	if str(p.get("schema", "")) != PACK_SCHEMA:
		return "unknown schema"
	var why := validate_pack(id, p)
	if why != "":
		return why
	if int(p["version"]) != int(e.get("version", 0)):
		return "version %d, the game expects %d" % [int(p["version"]), int(e.get("version", 0))]
	var jobs: Dictionary = e.get("jobs", {})
	for jid: String in jobs:
		if not (p["jobs"] as Dictionary).has(jid):
			return "job %s is not in the pack" % jid
		if not FileAccess.file_exists(pack_dir(id).path_join("jobs/%s.json" % jid)):
			return "file of job %s is missing" % jid
	return ""


func _drop_file(id: String) -> void:
	DirAccess.remove_absolute(pack_path(id))
	var st := _read_state()
	if st.erase(id):
		_write_json(STATE_FILE, st)


func _on_state_changed(_id: String) -> void:
	var now := []
	for id: String in ids():
		if is_ready(id):
			now.append(id)
	if now != _ready_ids:
		_rebuild()


## Builds the job / scene / text registries from the base game and the ready packs.
func _rebuild() -> void:
	_job_paths = PackedStringArray()
	_job_path_of = {}
	_job_pack = {}
	_scenes = {}
	_ready_ids = []
	if DirAccess.dir_exists_absolute(BASE_JOBS_DIR):
		for f in DirAccess.get_files_at(BASE_JOBS_DIR):
			if f.ends_with(".json"):
				_job_paths.append(BASE_JOBS_DIR.path_join(f))
				_job_path_of[f.trim_suffix(".json")] = BASE_JOBS_DIR.path_join(f)
	for id: String in ids():
		var jobs: Dictionary = info(id).get("jobs", {})
		for jid: String in jobs:
			if not _job_path_of.has(jid):  # a base job always wins over a pack's
				_job_pack[jid] = id
		if not is_ready(id):
			continue
		_ready_ids.append(id)
		var root := pack_dir(id)
		for jid: String in jobs:
			var path := root.path_join("jobs/%s.json" % jid)
			if _job_pack.get(jid, "") == id and FileAccess.file_exists(path):
				_job_paths.append(path)
				_job_path_of[jid] = path
		var scenes_path := root.path_join("arrival_scenes.json")
		if FileAccess.file_exists(scenes_path):
			var parsed: Variant = parse_json(FileAccess.get_file_as_string(scenes_path))
			if parsed is Dictionary and parsed.get("scenes") is Dictionary:
				for jid: String in parsed["scenes"]:
					_scenes[jid] = parsed["scenes"][jid]
		var csv := root.path_join("i18n/content.csv")
		if not _csv_done.has(csv) and get_node_or_null("/root/I18n") != null and I18n.add_csv(csv):
			_csv_done[csv] = true
	# caches built from the job files
	Practice.forget_jobs()
	Furnishings.forget_jobs()
	ArrivalScene.forget_data()
	registry_changed.emit()
