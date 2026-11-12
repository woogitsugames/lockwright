extends GutTest
## D-112: downloadable content packs (ContentPacks autoload; download/verify/storage shared with the
## voice packs in pack_store.gd, whose HTTP paths test_voice_packs.gd covers).
## A synthetic pack is packed at test time with PCKPacker: one job of chapter 77 (family "wafer"),
## its texts, and an arrival scene that reuses the frames of job.cat_bathroom. Its files live under
## res://tests/cp_fixture/<tag>/<id>/ and do not exist until the pck is mounted. Packs cannot be
## unmounted, so every test has its own <tag> (pack id and job id). "Downloads" are file copies.
## Tests that need the game's own registries (JobRun, the job list, the save) point the ContentPacks
## autoload at the fixture and put it back in after_each.

const ContentPacksScript := preload("res://scripts/autoload/content_packs.gd")
const CHAPTER := 77
const WAIT_S := 10.0
const GOOD_SHA := "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"

var _tag := ""
var _work := ""
var _id := ""
var _jid := ""
var _save := {}
var _autoload_used := false
var _registry_events := 0


func before_each() -> void:
	_tag = "t%d_%d" % [Time.get_ticks_usec(), randi() % 100000]
	_id = "p" + _tag
	_jid = "job.cp_" + _tag
	_work = "user://test_content_packs/" + _tag
	DirAccess.make_dir_recursive_absolute(_work + "/src")
	_save = Save.data.duplicate(true)
	_autoload_used = false
	_registry_events = 0


func after_each() -> void:
	if _autoload_used:
		ContentPacks.manifest_path = ContentPacksScript.MANIFEST_PATH
		ContentPacks.dir = ContentPacksScript.DIR
		ContentPacks.packs_root = ContentPacksScript.ROOT
		ContentPacks.base_url_override = ""
		ContentPacks.game_level = ContentPacksScript.GAME_LEVEL
		ContentPacks.use_local_sources = not OS.has_feature("template")
		ContentPacks.reload()
	Save.data = _save.duplicate(true)
	Save.save()
	_rm_tree(_work)


func _rm_tree(path: String) -> void:
	var d := DirAccess.open(path)
	if d == null:
		return
	for f in d.get_files():
		d.remove(f)
	for sub in d.get_directories():
		_rm_tree(path.path_join(sub))
	DirAccess.remove_absolute(path)


func _root() -> String:
	return "res://tests/cp_fixture/" + _tag


func _jobs_meta() -> Dictionary:
	return {_jid: {"chapter": CHAPTER, "family": "wafer", "tier": 2}}


func _pack_json(version := 1) -> Dictionary:
	return {"schema": ContentPacksScript.PACK_SCHEMA, "id": _id, "version": version, "min_game": 1,
			"chapters": [CHAPTER], "jobs": _jobs_meta()}


func _write(path: String, text: String) -> String:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()
	return path


## Packs the fixture pck; returns [path, size, sha256]. `version` is what the pck's own pack.json says.
func _make_pack(version := 1, with_job_file := true) -> Array:
	var base := "%s/%s/" % [_root(), _id]
	var job := {"id": _jid, "chapter": CHAPTER, "family": "wafer", "tier": 2, "reward_coins": 10, "order": 1,
			"i18n": {"title": _jid + ".title", "client": _jid + ".client", "situation": _jid + ".situation"},
			"lines": ["nadia"], "after": ["nadia"], "cards": ["id"], "place": "apartment", "time": "evening"}
	var scene: Dictionary = (ArrivalScene.data()["scenes"]["job.cat_bathroom"] as Dictionary).duplicate(true)
	var csv := "keys,en,pl,de,fr,es\n"
	csv += "%s.title,Pack job %s,Zlecenie z paczki,Auftrag aus dem Paket,Intervention du pack,Encargo del paquete\n" % [_jid, _tag]
	csv += "%s.after.1,It still works.,Dalej działa.,Es geht noch.,Ça marche encore.,Sigue funcionando.\n" % _jid
	var packer := PCKPacker.new()
	var pck := _work + "/src/content_%s.pck" % _id
	assert_eq(packer.pck_start(pck), OK)
	packer.add_file(base + "pack.json", _write(_work + "/pack.json", JSON.stringify(_pack_json(version))))
	if with_job_file:
		packer.add_file(base + "jobs/%s.json" % _jid, _write(_work + "/job.json", JSON.stringify(job)))
	packer.add_file(base + "i18n/content.csv", _write(_work + "/content.csv", csv))
	packer.add_file(base + "arrival_scenes.json", _write(_work + "/scenes.json", JSON.stringify({"scenes": {_jid: scene}})))
	assert_eq(packer.flush(), OK)
	var bytes := FileAccess.get_file_as_bytes(pck)
	var h := HashingContext.new()
	h.start(HashingContext.HASH_SHA256)
	h.update(bytes)
	return [pck, bytes.size(), h.finish().hex_encode()]


func _entry(size: int, sha: String, version := 1, min_game := 1) -> Dictionary:
	return {"file": "content_%s.pck" % _id, "url": "https://example.invalid/content_%s.pck" % _id,
			"size": size, "sha256": sha, "godot": "4.7", "version": version, "min_game": min_game,
			"chapters": [CHAPTER], "jobs": _jobs_meta()}


func _write_manifest(packs: Dictionary) -> void:
	_write(_work + "/content_packs.json", JSON.stringify({"schema": 1, "packs": packs}))


func _configure(cp: Node) -> void:
	cp.manifest_path = _work + "/content_packs.json"
	cp.dir = _work + "/store"
	cp.packs_root = _root()
	cp.base_url_override = _work + "/src"
	cp.use_local_sources = false


## A fresh ContentPacks node on the fixture manifest.
func _make_cp(packs: Dictionary) -> Node:
	_write_manifest(packs)
	var cp: Node = ContentPacksScript.new()
	_configure(cp)
	add_child_autofree(cp)
	return cp


## Points the game's ContentPacks autoload at the fixture (restored in after_each).
func _use_autoload(packs: Dictionary) -> void:
	_write_manifest(packs)
	_autoload_used = true
	_configure(ContentPacks)
	ContentPacks.reload()


func _wait_done(cp: Node) -> void:
	var t0 := Time.get_ticks_msec()
	while cp.state(_id) in ["downloading", "verifying"] and Time.get_ticks_msec() - t0 < WAIT_S * 1000.0:
		await get_tree().process_frame


func _on_registry_changed() -> void:
	_registry_events += 1


# --- manifest ------------------------------------------------------------------------

func test_validate_entry() -> void:
	var good := _entry(1000, GOOD_SHA)
	assert_eq(ContentPacksScript.validate_entry(_id, good), "", "a complete entry is accepted")
	var cases := {
		"entry is not an object": "x",
		"file": {"file": "other.pck"},
		"url": {"url": "http://example.invalid/content.pck"},
		"size": {"size": 0},
		"sha256": {"sha256": "abc"},
		"version": {"version": 0},
		"min_game": {"min_game": "new"},
		"chapters": {"chapters": []},
		"jobs must": {"jobs": {}},
		"bad job id": {"jobs": {"shed": {"chapter": CHAPTER}}},
		"needs a chapter": {"jobs": {_jid: {"family": "wafer"}}},
		"not one of the pack's": {"jobs": {_jid: {"chapter": 3}}},
		"id does not match": {"id": "other"},
	}
	for expect: String in cases:
		var e: Variant = cases[expect]
		if e is Dictionary:
			var bad := good.duplicate(true)
			bad.merge(e, true)
			e = bad
		assert_string_contains(ContentPacksScript.validate_entry(_id, e), expect)
	assert_eq(ContentPacksScript.validate_entry("Bad Id", good), "bad id")
	for key in ["file", "url", "size", "sha256", "version", "min_game", "chapters", "jobs"]:
		var missing := good.duplicate(true)
		missing.erase(key)
		assert_ne(ContentPacksScript.validate_entry(_id, missing), "", "an entry without %s is rejected" % key)


func test_invalid_manifest_entry_is_dropped() -> void:
	var bad := _entry(1000, "not-a-hash")
	bad["file"] = "content_broken.pck"
	bad["jobs"] = {"job.cp_broken": {"chapter": CHAPTER, "family": "wafer", "tier": 1}}
	var cp := _make_cp({_id: _entry(1000, GOOD_SHA), "broken": bad})
	assert_engine_error_count(0)
	assert_eq(cp.ids(), [_id], "only the valid pack is known")
	assert_ne(cp.invalid_reason("broken"), "")
	assert_eq(cp.state("broken"), "none")
	assert_false(cp.ensure("broken"), "a dropped entry cannot be downloaded")
	assert_eq(cp.state("broken"), "none")
	assert_eq(cp.stub("job.cp_broken"), {}, "its jobs are unknown")


func test_missing_or_broken_manifest_file_means_no_packs() -> void:
	var cp: Node = ContentPacksScript.new()
	_configure(cp)
	add_child_autofree(cp)
	assert_eq(cp.ids(), [])
	assert_eq(cp.offers(), [])
	assert_gt(cp.job_paths().size(), 0, "the base game's jobs are still there")
	_write(_work + "/content_packs.json", "{ this is not json")
	cp.reload()
	assert_eq(cp.ids(), [])


func test_shipped_manifest_and_sources_are_valid() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(ContentPacksScript.MANIFEST_PATH))
	assert_true(parsed is Dictionary and parsed.get("packs") is Dictionary, "res://data/content_packs.json has `packs`")
	for id: String in parsed["packs"]:
		assert_eq(ContentPacksScript.validate_entry(id, parsed["packs"][id]), "", "manifest entry " + id)
	# pack sources in the project (game/packs/<id>/): pack.json matches the job files
	if DirAccess.dir_exists_absolute(ContentPacksScript.ROOT):
		for id in DirAccess.get_directories_at(ContentPacksScript.ROOT):
			var dir := ContentPacksScript.ROOT.path_join(id)
			var p: Variant = JSON.parse_string(FileAccess.get_file_as_string(dir.path_join("pack.json")))
			assert_eq(ContentPacksScript.validate_pack(id, p), "", "pack.json of " + id)
			if not p is Dictionary:
				continue
			var on_disk := []
			for f in DirAccess.get_files_at(dir.path_join("jobs")):
				if f.ends_with(".json"):
					on_disk.append(f.trim_suffix(".json"))
			on_disk.sort()
			var listed: Array = (p.get("jobs", {}) as Dictionary).keys()
			listed.sort()
			assert_eq(listed, on_disk, "%s: `jobs` in pack.json lists jobs/*.json (tools/build_content_packs.py --sync)" % id)


func test_mobile_presets_do_not_ship_pack_sources() -> void:
	var cfg := ConfigFile.new()
	assert_eq(cfg.load("res://export_presets.cfg"), OK)
	var checked := 0
	for section in cfg.get_sections():
		if cfg.has_section_key(section, "name") and String(cfg.get_value(section, "name")) in ["Android", "iOS"]:
			checked += 1
			var filters := String(cfg.get_value(section, "exclude_filter", "")).split(",", false)
			assert_true(filters.has("packs/*"), "%s excludes packs/* (packs are downloaded, D-112)" % cfg.get_value(section, "name"))
	assert_eq(checked, 2)


# --- missing / offered ---------------------------------------------------------------

func test_missing_pack_is_offered_not_loaded() -> void:
	var p := _make_pack()
	var cp := _make_cp({_id: _entry(p[1], p[2])})
	assert_eq(cp.state(_id), "missing")
	assert_false(cp.is_ready(_id))
	assert_eq(cp.offers(), [{"pack": _id, "chapter": CHAPTER}])
	assert_eq(cp.pack_size(_id), p[1])
	assert_eq(cp.job_count(_id), 1)
	assert_eq(cp.job_path(_jid), "", "its job cannot be played")
	assert_eq(cp.pack_of_job(_jid), _id)
	assert_false(cp.job_paths().has("%s/%s/jobs/%s.json" % [_root(), _id, _jid]))
	var stub: Dictionary = cp.stub(_jid)
	assert_eq(int(stub.get("chapter", 0)), CHAPTER, "the app still knows the job's chapter")
	assert_eq(String(stub.get("family", "")), "wafer")
	assert_eq(String(stub.get("pack", "")), _id)
	assert_eq(cp.arrival_scenes(), {})


func test_offline_download_fails_and_can_be_retried() -> void:
	var p := _make_pack()
	var cp := _make_cp({_id: _entry(p[1], p[2])})
	cp.base_url_override = _work + "/nowhere"
	assert_false(cp.ensure(_id))
	await _wait_done(cp)
	assert_eq(cp.state(_id), "failed")
	assert_eq(cp.last_error(_id), "offline")
	assert_eq(cp.job_path(_jid), "")
	assert_eq(cp.offers().size(), 1, "still offered")
	cp.base_url_override = _work + "/src"
	cp.ensure(_id)
	await _wait_done(cp)
	assert_eq(cp.state(_id), "installed", "the retry works")


func test_needs_newer_game() -> void:
	var p := _make_pack()
	var cp := _make_cp({_id: _entry(p[1], p[2], 1, 2)})
	assert_true(cp.needs_update(_id))
	assert_eq(cp.state(_id), "update")
	assert_false(cp.ensure(_id), "nothing is downloaded for a game that cannot play it")
	assert_eq(cp.state(_id), "update")
	assert_false(FileAccess.file_exists(cp.pack_path(_id) + ".part"))
	cp.game_level = 2
	assert_eq(cp.state(_id), "missing")


# --- install / merge -----------------------------------------------------------------

func test_download_installs_and_merges_jobs_texts_and_scene() -> void:
	var p := _make_pack()
	_use_autoload({_id: _entry(p[1], p[2])})
	ContentPacks.registry_changed.connect(_on_registry_changed)
	assert_eq(JobRun.job_by_id(_jid), {}, "not there before the download")
	assert_false(I18n.has_key(StringName(_jid + ".title")))
	assert_false(ContentPacks.ensure(_id))
	assert_true(ContentPacks.state(_id) in ["downloading", "verifying"])
	await _wait_done(ContentPacks)
	ContentPacks.registry_changed.disconnect(_on_registry_changed)
	assert_eq(ContentPacks.state(_id), "installed")
	assert_gt(_registry_events, 0, "registry_changed told the screens")
	assert_eq(ContentPacks.offers(), [], "no longer offered")
	# jobs
	var job := JobRun.job_by_id(_jid)
	assert_eq(String(job.get("id", "")), _jid, "the pack's job is a job of the game now")
	assert_eq(int(job.get("chapter", 0)), CHAPTER)
	var ids := []
	for j: Dictionary in JobRun.all_jobs():
		ids.append(j["id"])
	assert_true(ids.has(_jid))
	assert_true(ids.has("job.cat_bathroom"), "next to the base game's jobs")
	assert_true(JobRun.is_playable(job))
	assert_eq(ContentPacks.stubs(), [], "no stub for a job that is on the phone")
	# texts
	assert_true(I18n.has_key(StringName(_jid + ".title")))
	var pl: Translation = I18n._translations.get("pl")
	assert_eq(String(pl.get_message(StringName(_jid + ".title"))), "Zlecenie z paczki")
	var en: Translation = I18n._translations.get("en")
	assert_string_contains(String(en.get_message(StringName(_jid + ".title"))), "Pack job")
	# arrival scene
	assert_true(ArrivalScene.data()["scenes"].has(_jid), "the pack's arrival scene is merged")
	assert_true(ArrivalScene.has_scene(job), "and resolves to frames")
	assert_true(ArrivalScene.data()["scenes"].has("job.cat_bathroom"), "base scenes stay")
	assert_false(FileAccess.file_exists(ContentPacks.pack_path(_id) + ".part"))


func test_installed_pack_loads_at_startup() -> void:
	var p := _make_pack()
	var first := _make_cp({_id: _entry(p[1], p[2])})
	first.ensure(_id)
	await _wait_done(first)
	assert_eq(first.state(_id), "installed")
	# "next start": a new node on the same folder, the download source gone
	var cp: Node = ContentPacksScript.new()
	_configure(cp)
	cp.base_url_override = _work + "/nowhere"
	add_child_autofree(cp)
	assert_eq(cp.state(_id), "installed", "mounted from user:// at startup, no network")
	assert_eq(cp.job_path(_jid), "%s/%s/jobs/%s.json" % [_root(), _id, _jid])
	assert_true(cp.arrival_scenes().has(_jid))


func test_corrupt_download_is_rejected() -> void:
	var p := _make_pack()
	var cp := _make_cp({_id: _entry(p[1], p[2])})
	# same size, other bytes: what a damaged or swapped file looks like
	var bytes := FileAccess.get_file_as_bytes(p[0])
	bytes[bytes.size() - 1] = (bytes[bytes.size() - 1] + 1) % 256
	DirAccess.make_dir_recursive_absolute(_work + "/bad")
	var f := FileAccess.open(_work + "/bad/content_%s.pck" % _id, FileAccess.WRITE)
	f.store_buffer(bytes)
	f.close()
	cp.base_url_override = _work + "/bad"
	cp.ensure(_id)
	await _wait_done(cp)
	assert_eq(cp.state(_id), "failed")
	assert_eq(cp.last_error(_id), "checksum")
	assert_false(cp.is_ready(_id))
	assert_eq(cp.job_path(_jid), "", "nothing from a file that failed the hash")
	assert_false(FileAccess.file_exists(cp.pack_path(_id)), "not kept")
	assert_false(FileAccess.file_exists(cp.pack_path(_id) + ".part"), "the bad bytes are dropped")
	cp.base_url_override = _work + "/src"
	cp.ensure(_id)
	await _wait_done(cp)
	assert_eq(cp.state(_id), "installed", "the right file installs afterwards")


func test_corrupt_file_on_disk_is_dropped_at_startup() -> void:
	var p := _make_pack()
	_write_manifest({_id: _entry(p[1], p[2])})
	DirAccess.make_dir_recursive_absolute(_work + "/store")
	_write(_work + "/store/content_%s.pck" % _id, "this is not a pck")
	_write(_work + "/store/installed.json", JSON.stringify({_id: p[2]}))
	var cp: Node = ContentPacksScript.new()
	_configure(cp)
	add_child_autofree(cp)
	assert_eq(cp.state(_id), "missing", "a file Godot cannot mount is not a pack")
	assert_false(FileAccess.file_exists(_work + "/store/content_%s.pck" % _id), "and is deleted")
	assert_eq(cp.offers().size(), 1, "the chapter is offered again")
	assert_gt(cp.job_paths().size(), 0)


func test_pack_from_another_build_is_removed_at_startup() -> void:
	var p := _make_pack()
	_write_manifest({_id: _entry(p[1], p[2])})
	DirAccess.make_dir_recursive_absolute(_work + "/store")
	DirAccess.copy_absolute(p[0], _work + "/store/content_%s.pck" % _id)
	_write(_work + "/store/installed.json", JSON.stringify({_id: GOOD_SHA}))  # hash of an older build's pack
	var cp: Node = ContentPacksScript.new()
	_configure(cp)
	add_child_autofree(cp)
	assert_eq(cp.state(_id), "missing")
	assert_false(FileAccess.file_exists(_work + "/store/content_%s.pck" % _id))


func test_pack_that_is_not_what_the_manifest_says_is_rejected() -> void:
	# the hash matches (the manifest was made from this file) but its pack.json is version 2
	var p := _make_pack(2)
	var cp := _make_cp({_id: _entry(p[1], p[2], 1)})
	cp.ensure(_id)
	await _wait_done(cp)
	assert_eq(cp.state(_id), "failed")
	assert_eq(cp.last_error(_id), "mount")
	assert_eq(cp.job_path(_jid), "")
	assert_false(FileAccess.file_exists(cp.pack_path(_id)), "the file is dropped, the next try downloads again")


func test_pack_without_its_job_file_is_rejected() -> void:
	var p := _make_pack(1, false)
	var cp := _make_cp({_id: _entry(p[1], p[2])})
	cp.ensure(_id)
	await _wait_done(cp)
	assert_eq(cp.state(_id), "failed")
	assert_eq(cp.job_paths().has("%s/%s/jobs/%s.json" % [_root(), _id, _jid]), false)


func test_source_folder_counts_as_bundled_in_the_editor() -> void:
	# game/packs/<id>/ on disk (here: a folder in user://) is playable without a download
	var root := _work + "/packs"
	DirAccess.make_dir_recursive_absolute(root + "/%s/jobs" % _id)
	_write(root + "/%s/pack.json" % _id, JSON.stringify(_pack_json()))
	_write(root + "/%s/jobs/%s.json" % [_id, _jid], JSON.stringify({"id": _jid, "chapter": CHAPTER, "family": "wafer"}))
	_write_manifest({})
	var cp: Node = ContentPacksScript.new()
	_configure(cp)
	cp.packs_root = root
	cp.use_local_sources = true
	add_child_autofree(cp)
	assert_eq(cp.state(_id), "bundled")
	assert_true(cp.is_ready(_id))
	assert_eq(cp.job_path(_jid), root + "/%s/jobs/%s.json" % [_id, _jid])
	assert_false(cp.remove(_id), "a bundled pack cannot be removed")
	cp.use_local_sources = false   # an exported build never looks there
	cp.reload()
	assert_eq(cp.ids(), [])


# --- removed pack and the save -------------------------------------------------------

func test_removed_pack_does_not_break_the_save() -> void:
	var p := _make_pack()
	_use_autoload({_id: _entry(p[1], p[2])})
	ContentPacks.ensure(_id)
	await _wait_done(ContentPacks)
	assert_eq(ContentPacks.state(_id), "installed")
	# the player finishes the pack's job: completed, day-after pending
	var job := JobRun.job_by_id(_jid)
	Save.set_value("jobs_completed", ["job.cat_bathroom", _jid])
	Save.set_value("lessons/wafer/done", false)
	DayAfter.note_finished(job)
	assert_eq(Furnishings.reached_chapter(), CHAPTER)
	assert_true(Practice.family_met(&"wafer"))
	# ... and removes the pack in Settings
	assert_true(ContentPacks.remove(_id))
	assert_eq(ContentPacks.state(_id), "missing")
	assert_false(FileAccess.file_exists(ContentPacks.pack_path(_id)), "the file is gone at once")
	assert_eq(JobRun.job_by_id(_jid), {}, "the job is not on the phone")
	assert_eq(ContentPacks.offers(), [{"pack": _id, "chapter": CHAPTER}], "the chapter is offered again")
	assert_false(ArrivalScene.data()["scenes"].has(_jid), "its arrival scene is gone from the registry")
	assert_eq(ArrivalScene.resolve({"id": _jid, "time": "evening"}), {})
	# progress read from the save stays
	assert_true((Save.get_value("jobs_completed", []) as Array).has(_jid), "the save keeps the job")
	assert_eq(int(JobRun.job_meta(_jid).get("chapter", 0)), CHAPTER)
	assert_eq(Furnishings.reached_chapter(), CHAPTER, "the reached chapter does not go back")
	assert_true(Practice.family_met(&"wafer"), "practice unlocked by the job stays unlocked")
	assert_eq(DayAfter.next_job(), {}, "a day-after scene of a job that is gone is skipped")
	assert_false(DayAfter.pending().has(_jid))
	# the screens that read the save open
	var list: Control = load("res://scenes/jobs_list.tscn").instantiate()
	add_child_autofree(list)
	await get_tree().process_frame
	assert_null(list.find_child("Job_cp_" + _tag, true, false), "no plate for the removed job")
	assert_not_null(list.find_child("Pack_%s_%d" % [_id, CHAPTER], true, false), "its chapter can be downloaded again")
	assert_not_null(list.find_child("Job_cat_bathroom", true, false), "the other jobs are there")
	var showcase: Control = load("res://scenes/showcase.tscn").instantiate()
	add_child_autofree(showcase)
	await get_tree().process_frame
	assert_engine_error_count(0)
	# a restart keeps it removed and the save readable
	Save.save()
	Save.load_save()
	ContentPacks.reload()
	assert_eq(ContentPacks.state(_id), "missing")
	assert_true((Save.get_value("jobs_completed", []) as Array).has(_jid))
	# downloading it again brings the job back, done
	ContentPacks.ensure(_id)
	await _wait_done(ContentPacks)
	assert_eq(ContentPacks.state(_id), "installed")
	assert_eq(String(JobRun.job_by_id(_jid).get("id", "")), _jid)


# --- the job list --------------------------------------------------------------------

func test_job_list_offers_the_chapter_and_shows_its_jobs_after_download() -> void:
	var p := _make_pack()
	_use_autoload({_id: _entry(p[1], p[2])})
	ContentPacks.base_url_override = _work + "/nowhere"
	var list: Control = load("res://scenes/jobs_list.tscn").instantiate()
	add_child_autofree(list)
	await get_tree().process_frame
	var row := list.find_child("Pack_%s_%d" % [_id, CHAPTER], true, false)
	assert_not_null(row, "a chapter that is not on the phone has a row")
	if row == null:
		return
	assert_not_null(list.find_child("Chapter%d" % CHAPTER, true, false), "under its chapter header")
	assert_gt(row.get_index(), list.find_child("Job_cat_bathroom", true, false).get_parent().get_index(), "after the earlier chapters")
	var info: Label = row.get_node("Info")
	var action: Button = row.get_node("Action")
	var size_text: String = ContentPacks.size_text(p[1], I18n.current_language())
	assert_string_contains(info.text, size_text, "the size is on the row before the tap")
	assert_string_contains(row.get_node("Note").text, "Wi-Fi")
	assert_true(action.visible)
	assert_gte(action.get_combined_minimum_size().y, 48.0, "touch target >= 48 dp")
	assert_eq(action.text, I18n.t(&"settings.voice_pack.download"))
	assert_null(list.find_child("Job_cp_" + _tag, true, false))
	# offline: said in words, the plate stays as "Try again"
	action.pressed.emit()
	await _wait_done(ContentPacks)
	assert_eq(ContentPacks.state(_id), "failed")
	assert_eq(row.get_node("Note").text, I18n.t(&"pack.row.offline"))
	assert_eq(action.text, I18n.t(&"settings.voice_pack.retry"))
	assert_true(action.visible)
	# online: progress, then the list shows the job
	ContentPacks.base_url_override = _work + "/src"
	action.pressed.emit()
	assert_true(ContentPacks.state(_id) in ["downloading", "verifying"])
	assert_ne(info.text.find("%"), -1, "progress in words")
	await _wait_done(ContentPacks)
	await get_tree().process_frame
	assert_eq(ContentPacks.state(_id), "installed")
	assert_null(list.find_child("Pack_%s_%d" % [_id, CHAPTER], true, false), "the row is gone")
	var plate := list.find_child("Job_cp_" + _tag, true, false) as Button
	assert_not_null(plate, "the pack's job has its plate")
	if plate != null:
		assert_string_contains(plate.text, "Pack job" if I18n.current_language() == "en" else "")
	assert_engine_error_count(0)


func test_job_list_says_when_the_game_is_too_old() -> void:
	var p := _make_pack()
	_use_autoload({_id: _entry(p[1], p[2], 1, 99)})
	var list: Control = load("res://scenes/jobs_list.tscn").instantiate()
	add_child_autofree(list)
	await get_tree().process_frame
	var row := list.find_child("Pack_%s_%d" % [_id, CHAPTER], true, false)
	assert_not_null(row)
	if row == null:
		return
	assert_false((row.get_node("Action") as Button).visible, "nothing to tap")
	assert_eq(row.get_node("Note").text, I18n.t(&"pack.row.update"))


# --- Settings ------------------------------------------------------------------------

func test_settings_lists_packs_and_removes_them() -> void:
	var p := _make_pack()
	_use_autoload({_id: _entry(p[1], p[2])})
	ContentPacks.ensure(_id)
	await _wait_done(ContentPacks)
	var settings: Control = load("res://scenes/settings.tscn").instantiate()
	add_child_autofree(settings)
	await get_tree().process_frame
	var row := settings.find_child("Row_" + _id, true, false)
	assert_not_null(row, "Settings has a row for the pack")
	if row == null:
		return
	var action: Button = row.get_node("Action")
	assert_gte(action.get_combined_minimum_size().y, 48.0)
	assert_eq(action.text, I18n.t(&"settings.voice_pack.remove"))
	assert_string_contains(row.get_node("Label").text, I18n.t(&"settings.content.ready"))
	action.pressed.emit()
	assert_eq(ContentPacks.state(_id), "missing")
	assert_eq(action.text, I18n.t(&"settings.voice_pack.download"))
	assert_string_contains(row.get_node("Label").text, ContentPacks.size_text(p[1], I18n.current_language()))


func test_settings_has_no_block_without_packs() -> void:
	_use_autoload({})
	var settings: Control = load("res://scenes/settings.tscn").instantiate()
	add_child_autofree(settings)
	await get_tree().process_frame
	assert_null(settings.find_child("ContentPacks", true, false))


func test_strings_exist_in_five_languages() -> void:
	var keys := ["pack.row.info", "pack.row.note", "pack.row.downloading", "pack.row.verifying", "pack.row.offline",
			"pack.row.failed", "pack.row.update", "pack.title_more", "settings.content.header",
			"settings.content.ready", "settings.content.note"]
	for lang in ["en", "pl", "de", "fr", "es"]:
		var tr: Translation = I18n._translations.get(lang)
		assert_not_null(tr)
		for k: String in keys:
			assert_ne(String(tr.get_message(StringName(k))), "", "%s in %s" % [k, lang])
