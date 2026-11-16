extends GutTest
## D-136: on-demand packs (voices, chapters) and a full or flaky disk: a download that cannot fit is
## refused before it starts, a write the disk refuses ends as "storage" with the whole bytes kept, the
## lists of installed / removed packs are replaced atomically, a finished pack the list forgot is
## checked instead of fetched again, and leftovers of older builds are swept.
## The store under test is PackStore itself with mounting stubbed (no real pck needed).

const WAIT_S := 10.0


class Store:
	extends "res://scripts/autoload/pack_store.gd"

	func _mount(lang: String) -> bool:
		_mounted[lang] = true
		return true


var _work := ""
var _body := PackedByteArray()
var _sha := ""


func before_each() -> void:
	_work = "user://test_d136_packs/t%d_%d" % [Time.get_ticks_usec(), randi() % 100000]
	DirAccess.make_dir_recursive_absolute(_work + "/src")
	DirAccess.make_dir_recursive_absolute(_work + "/store")
	_body = PackedByteArray()
	_body.resize(3 * (1 << 19) + 777)   # several copy steps
	for i in _body.size():
		_body[i] = (i * 31 + 7) % 251
	var f := FileAccess.open(_work + "/src/a.pck", FileAccess.WRITE)
	f.store_buffer(_body)
	f.close()
	var h := HashingContext.new()
	h.start(HashingContext.HASH_SHA256)
	h.update(_body)
	_sha = h.finish().hex_encode()
	SafeFile.fail_mode = ""


func after_each() -> void:
	SafeFile.fail_mode = ""
	for sub: String in ["/src", "/store", ""]:
		for f in DirAccess.get_files_at(_work + sub):
			DirAccess.remove_absolute((_work + sub).path_join(f))
		DirAccess.remove_absolute(_work + sub)


func _store(base := "", packs := {}) -> Node:
	if packs.is_empty():
		packs = {"a": {"file": "a.pck", "url": (base if base != "" else _work + "/src") + "/a.pck", "size": _body.size(), "sha256": _sha}}
	var m := FileAccess.open(_work + "/manifest.json", FileAccess.WRITE)
	m.store_string(JSON.stringify({"schema": 1, "packs": packs}))
	m.close()
	var s: Node = Store.new()
	s.manifest_path = _work + "/manifest.json"
	s.dir = _work + "/store"
	s.set_process(false)
	add_child_autofree(s)
	s.reload()
	return s


func _wait_done(s: Node, id := "a") -> void:
	var t0 := Time.get_ticks_msec()
	while s.state(id) in ["downloading", "verifying"] and Time.get_ticks_msec() - t0 < WAIT_S * 1000.0:
		await get_tree().process_frame


func _files() -> Array:
	var out := Array(DirAccess.get_files_at(_work + "/store"))
	out.sort()
	return out


func test_plain_download_still_installs() -> void:
	var s := _store()
	assert_false(s.ensure("a"))
	await _wait_done(s)
	assert_eq(s.state("a"), "installed")
	assert_eq(_files(), ["a.pck", "installed.json"], "no .part, no sidecar, no temp file left")
	assert_eq(JSON.parse_string(FileAccess.get_file_as_string(_work + "/store/installed.json")), {"a": _sha})


func test_download_that_cannot_fit_is_refused_before_it_starts() -> void:
	var s := _store()
	s.space_left_override = _body.size() / 2
	watch_signals(s)
	assert_false(s.ensure("a"))
	assert_eq(s.state("a"), "failed")
	assert_eq(s.last_error("a"), "storage")
	assert_signal_emitted_with_parameters(s, "failed", ["a", "storage"])
	assert_eq(FileAccess.get_file_as_bytes(_work + "/store/a.pck.part").size(), 0, "nothing was written")
	# room again -> the same tap works
	s.space_left_override = -1
	s.ensure("a")
	await _wait_done(s)
	assert_eq(s.state("a"), "installed")


func test_unknown_free_space_does_not_block() -> void:
	var s := _store()
	s.space_left_override = 0   # the platform cannot tell
	s.ensure("a")
	await _wait_done(s)
	assert_eq(s.state("a"), "installed")


func test_resume_counts_only_the_missing_part_against_free_space() -> void:
	var s := _store()
	s.ensure("a")
	await get_tree().process_frame   # one copy step: 512 KB on disk
	s.cancel("a")
	var have := FileAccess.get_file_as_bytes(_work + "/store/a.pck.part").size()
	assert_gt(have, 0)
	s.space_left_override = _body.size() - have + s.SPACE_MARGIN + 1   # room for the rest only
	s.ensure("a")
	assert_eq(s.state("a"), "downloading")
	await _wait_done(s)
	assert_eq(s.state("a"), "installed")


func test_disk_filling_up_mid_download_ends_as_storage_and_keeps_whole_bytes() -> void:
	var s := _store()
	s.ensure("a")
	await get_tree().process_frame
	var j: RefCounted = s._jobs["a"]
	var have: int = j.received
	assert_gt(have, 0)
	s.refuse_writes = true   # the disk is full from now on
	watch_signals(s)
	await get_tree().process_frame
	assert_eq(s.state("a"), "failed")
	assert_eq(s.last_error("a"), "storage", "not 'checksum' after downloading everything twice")
	assert_signal_emitted_with_parameters(s, "failed", ["a", "storage"])
	assert_eq(FileAccess.get_file_as_bytes(_work + "/store/a.pck.part").size(), have, "the bytes that did arrive are kept for a resume")
	s.refuse_writes = false
	s.ensure("a")
	await _wait_done(s)
	assert_eq(s.state("a"), "installed", "resumed and verified once there is room")
	assert_eq(FileAccess.get_file_as_bytes(_work + "/store/a.pck"), _body)


func test_installed_list_survives_a_failed_write() -> void:
	var s := _store()
	s.ensure("a")
	await _wait_done(s)
	var before := FileAccess.get_file_as_string(_work + "/store/installed.json")
	SafeFile.fail_mode = "short"
	s._write_state("b", "00")
	s.remove("a")
	SafeFile.fail_mode = ""
	assert_eq(FileAccess.get_file_as_string(_work + "/store/installed.json"), before, "the list is whole, not cut")
	assert_false(FileAccess.file_exists(_work + "/store/installed.json.tmp"))


func test_finished_pack_forgotten_by_the_list_is_checked_not_fetched_again() -> void:
	var s := _store()
	s.ensure("a")
	await _wait_done(s)
	s.queue_free()
	await get_tree().process_frame
	# installed.json damaged (or the app was killed between the rename and the list)
	var f := FileAccess.open(_work + "/store/installed.json", FileAccess.WRITE)
	f.store_string("{\"a\": \"")
	f.close()
	DirAccess.remove_absolute(_work + "/src/a.pck")   # the source is gone: only the file on the phone can satisfy it
	var s2 := _store("user://nowhere_d136")
	assert_eq(s2.state("a"), "missing", "not trusted without its hash")
	watch_signals(s2)
	s2.ensure("a")
	assert_eq(s2.state("a"), "verifying", "straight to the hash check")
	await _wait_done(s2)
	assert_eq(s2.state("a"), "installed")
	assert_signal_not_emitted(s2, "progress")
	assert_eq(JSON.parse_string(FileAccess.get_file_as_string(_work + "/store/installed.json")), {"a": _sha})


func test_file_with_the_right_size_but_wrong_bytes_is_not_adopted() -> void:
	var bad := _body.duplicate()
	bad[100] = (bad[100] + 1) % 256
	var f := FileAccess.open(_work + "/store/a.pck", FileAccess.WRITE)
	f.store_buffer(bad)
	f.close()
	var s := _store()
	s.ensure("a")
	await _wait_done(s)
	assert_eq(s.state("a"), "failed")
	assert_eq(s.last_error("a"), "checksum")
	assert_false(FileAccess.file_exists(_work + "/store/a.pck"), "the bad file is gone")
	s.ensure("a")
	await _wait_done(s)
	assert_eq(s.state("a"), "installed", "the next try fetches a good one")


func test_leftovers_of_cut_off_work_are_swept_at_start() -> void:
	for name: String in ["old_pack.pck.part", "old_pack.pck.part.json", "installed.json.tmp", "removed.json.tmp",
			"a.pck.part", "a.pck.part.json", "notes.txt"]:
		var f := FileAccess.open(_work + "/store/" + name, FileAccess.WRITE)
		f.store_string(_sha if name == "a.pck.part.json" else "x")
		f.close()
	_store()
	assert_eq(_files(), ["a.pck.part", "a.pck.part.json", "notes.txt"],
		"gone: .part of a pack this build does not know and temp files; kept: this build's resumable download and unrelated files")


func test_damaged_lists_are_read_as_empty() -> void:
	for body: String in ["", "{", "[]", "null", "7"]:
		for name: String in ["installed.json", "removed.json"]:
			var f := FileAccess.open(_work + "/store/" + name, FileAccess.WRITE)
			f.store_string(body)
			f.close()
		var s := _store()
		assert_eq(s.state("a"), "missing", "body '%s'" % body)
		assert_false(s.is_removed("a"))


func test_store_folder_removed_while_running_is_made_again() -> void:
	var s := _store()
	for f in DirAccess.get_files_at(_work + "/store"):
		DirAccess.remove_absolute(_work + "/store/" + f)
	DirAccess.remove_absolute(_work + "/store")
	s._write_state("a", _sha)
	assert_true(FileAccess.file_exists(_work + "/store/installed.json"), "a cleared app folder does not stop the list from being written")
