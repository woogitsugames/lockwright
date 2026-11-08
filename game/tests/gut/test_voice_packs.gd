extends GutTest
## D-62/D-100: on-demand voice packs (only EN ships; PL, DE, FR, ES are packs) (VoicePacks autoload script, fresh instance per test).
## A tiny fixture pck is packed at test time with PCKPacker: it maps
## res://tests/vp_fixture/<tag>/lines/de/job.test_dialogue.line.1.ogg onto the already
## imported PL fixture clip, so "the DialoguePlayer finds the DE clip" is real: the path
## does not exist until the pack is mounted. Packs cannot be unmounted, so every test
## uses its own <tag>. Downloads go through file:// copy or a local fake HTTP server.

const VoicePacksScript := preload("res://scripts/autoload/voice_packs.gd")
const DialoguePlayer := preload("res://scripts/ui/dialogue_player.gd")
const SRC_IMPORT := "res://tests/fixtures/lines/pl/job.test_dialogue.line.1.ogg.import"
const KEY := "job.test_dialogue.line.1"
const WAIT_S := 10.0

var _tag := ""
var _work := ""


class FakeServer:
	extends Node
	## Minimal HTTP/1.1 file server: one request per connection, honours Range,
	## can drop the connection mid-body or answer an error status.
	var server := TCPServer.new()
	var body := PackedByteArray()
	var status := 200
	var drop_after := -1
	var ranges: Array[String] = []
	var requests := 0
	var _peers: Array = []

	func start() -> int:
		server.listen(0, "127.0.0.1")
		return server.get_local_port()

	func _process(_d: float) -> void:
		while server.is_connection_available():
			_peers.append({"p": server.take_connection(), "buf": ""})
		for c in _peers.duplicate():
			var p: StreamPeerTCP = c.p
			p.poll()
			if p.get_status() != StreamPeerTCP.STATUS_CONNECTED:
				_peers.erase(c)
				continue
			var n := p.get_available_bytes()
			if n > 0:
				c.buf += p.get_utf8_string(n)
			if String(c.buf).contains("\r\n\r\n"):
				_peers.erase(c)
				_respond(p, c.buf)

	func _respond(p: StreamPeerTCP, req: String) -> void:
		requests += 1
		var start := 0
		for line in req.split("\r\n"):
			if line.to_lower().begins_with("range:"):
				ranges.append(line)
				start = int(line.split("=")[1].split("-")[0])
		if status != 200:
			p.put_data(("HTTP/1.1 %d Nope\r\nContent-Length: 0\r\nConnection: close\r\n\r\n" % status).to_utf8_buffer())
			p.disconnect_from_host()
			return
		var part := body.slice(start)
		var head := "HTTP/1.1 %s\r\nContent-Length: %d\r\nConnection: close\r\n" % [
			"206 Partial Content" if start > 0 else "200 OK", part.size()]
		if start > 0:
			head += "Content-Range: bytes %d-%d/%d\r\n" % [start, body.size() - 1, body.size()]
		p.put_data((head + "\r\n").to_utf8_buffer())
		if drop_after >= 0:
			p.put_data(part.slice(0, drop_after))
			drop_after = -1
		else:
			p.put_data(part)
		p.disconnect_from_host()


func before_each() -> void:
	_tag = "t%d_%d" % [Time.get_ticks_usec(), randi() % 100000]
	_work = "user://test_voice_packs/" + _tag
	DirAccess.make_dir_recursive_absolute(_work + "/src")


func after_each() -> void:
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
	return "res://tests/vp_fixture/%s/lines" % _tag


## Packs the fixture pck; returns [path, size, sha256].
func _make_pack() -> Array:
	var imported := ""
	for line in FileAccess.get_file_as_string(SRC_IMPORT).split("\n"):
		if line.begins_with("path="):
			imported = line.trim_prefix("path=").replace("\"", "")
	assert_ne(imported, "", "fixture .import has a path")
	var remap := _work + "/remap.import"
	var f := FileAccess.open(remap, FileAccess.WRITE)
	f.store_string('[remap]\n\nimporter="oggvorbisstr"\ntype="AudioStreamOggVorbis"\npath="%s"\n' % imported)
	f.close()
	var pck := _work + "/src/voice_de.pck"
	var packer := PCKPacker.new()
	assert_eq(packer.pck_start(pck), OK)
	packer.add_file("%s/de/%s.ogg.import" % [_root(), KEY], remap)
	assert_eq(packer.flush(), OK)
	var bytes := FileAccess.get_file_as_bytes(pck)
	var h := HashingContext.new()
	h.start(HashingContext.HASH_SHA256)
	h.update(bytes)
	return [pck, bytes.size(), h.finish().hex_encode()]


func _make_vp(size: int, sha: String, base: String, langs: Array = ["de"]) -> Node:
	var packs := {}
	for lang in langs:
		# every language points at the same fixture file (its clip lives under .../de/)
		packs[lang] = {"file": "voice_de.pck", "url": base + "/voice_de.pck", "size": size, "sha256": sha}
	var m := FileAccess.open(_work + "/voice_packs.json", FileAccess.WRITE)
	m.store_string(JSON.stringify({"schema": 1, "version": "test", "base_url": base, "packs": packs}))
	m.close()
	var vp: Node = VoicePacksScript.new()
	vp.manifest_path = _work + "/voice_packs.json"
	vp.dir = _work + "/store"
	vp.auto_follow_language = false
	add_child_autofree(vp)
	return vp


func _wait_done(vp: Node, lang: String = "de") -> void:
	var t0 := Time.get_ticks_msec()
	while vp.state(lang) in ["downloading", "verifying"] and Time.get_ticks_msec() - t0 < WAIT_S * 1000.0:
		await get_tree().process_frame


func _dialogue(lang: String) -> Node:
	var l := Label.new()
	l.text = "Guten Tag."
	add_child_autofree(l)
	var dp: Node = DialoguePlayer.new()
	dp.root = _root()
	dp.screen_reader_override = 0
	add_child_autofree(dp)
	dp.setup([l], PackedStringArray([KEY]), PackedStringArray([l.text]), lang)
	return dp


func test_bundled_policy_and_size_text() -> void:
	var p := _make_pack()
	var vp := _make_vp(p[1], p[2], "user://nowhere")
	assert_true(vp.is_ready("en"), "EN ships in the package (D-100)")
	assert_false(vp.is_ready("pl"), "PL is a pack now (D-100)")
	assert_eq(vp.state("en"), "bundled")
	assert_eq(vp.state("pl"), "none", "no PL pack in this manifest")
	assert_eq(vp.state("de"), "missing")
	assert_eq(vp.state("fr"), "none", "no pack in the manifest")
	assert_eq(vp.policy("de", "ask"), "download", "the old default 'ask' means auto (D-100)")
	assert_eq(vp.policy("de", "auto"), "download")
	assert_eq(vp.policy("de", "manual"), "offer")
	assert_eq(vp.policy("en", "auto"), "none")
	assert_eq(VoicePacksScript.size_text(8164916, "pl"), "8,2 MB")
	assert_eq(VoicePacksScript.size_text(8164916, "de"), "8,2 MB")
	assert_eq(VoicePacksScript.size_text(8164916, "en"), "8.2 MB")


func test_shipped_manifest_offers_packs_but_never_en() -> void:
	var m: Variant = JSON.parse_string(FileAccess.get_file_as_string(VoicePacksScript.MANIFEST_PATH))
	assert_true(m is Dictionary, "res://data/voice_packs.json parses")
	var packs: Dictionary = m.get("packs", {})
	assert_true(packs.has("de"), "DE is an on-demand pack (D-62)")
	assert_false(packs.has("en"), "EN ships in the package (D-100)")
	assert_eq(VoicePacksScript.BUNDLED, ["en"])
	var de: Dictionary = packs["de"]
	assert_gt(int(de.size), 1000000)
	assert_eq(str(de.sha256).length(), 64)
	assert_true(str(de.url).begins_with("https://") and str(de.url).ends_with("/voice_de.pck"))


func test_file_url_download_mounts_and_dialogue_finds_de_clip() -> void:
	var p := _make_pack()
	var vp := _make_vp(p[1], p[2], _work + "/src")
	assert_eq(Sfx.line_clip_path(KEY, "de", _root()), "", "no DE clip before the pack")
	var before := _dialogue("de")
	assert_false(before.has_any_clip(), "subtitle-only without the pack")
	watch_signals(vp)
	assert_false(vp.ensure("de"), "not ready yet: download started")
	assert_eq(vp.state("de"), "downloading")
	await _wait_done(vp)
	assert_signal_emitted_with_parameters(vp, "installed", ["de"])
	assert_signal_emitted(vp, "progress")
	assert_eq(vp.state("de"), "installed")
	assert_true(FileAccess.file_exists(vp.pack_path("de")))
	assert_false(FileAccess.file_exists(vp.pack_path("de") + ".part"))
	assert_ne(Sfx.line_clip_path(KEY, "de", _root()), "", "DE clip resolves after mount")
	var dp := _dialogue("de")
	assert_true(dp.has_any_clip())
	watch_signals(dp)
	dp.start()
	assert_signal_emitted_with_parameters(dp, "line_started", [0, true])
	dp.skip_all()
	assert_true(vp.ensure("de"), "ready now")


func test_http_download_resumes_after_drop() -> void:
	var p := _make_pack()
	var srv := FakeServer.new()
	add_child_autofree(srv)
	var port := srv.start()
	srv.body = FileAccess.get_file_as_bytes(p[0])
	srv.drop_after = 40
	var vp := _make_vp(p[1], p[2], "http://127.0.0.1:%d/packs" % port)
	watch_signals(vp)
	vp.ensure("de")
	await _wait_done(vp)
	assert_eq(vp.state("de"), "failed")
	assert_eq(vp.last_error("de"), "interrupted")
	assert_eq(FileAccess.get_file_as_bytes(vp.pack_path("de") + ".part").size(), 40, "partial file kept")
	vp.ensure("de")
	await _wait_done(vp)
	assert_eq(vp.state("de"), "installed", "resumed: " + vp.last_error("de"))
	assert_eq(srv.ranges, ["Range: bytes=40-"] as Array[String], "second request resumed")
	assert_ne(Sfx.line_clip_path(KEY, "de", _root()), "")


func test_checksum_mismatch_never_mounts() -> void:
	var p := _make_pack()
	var vp := _make_vp(p[1], "0".repeat(64), _work + "/src")
	watch_signals(vp)
	vp.ensure("de")
	await _wait_done(vp)
	assert_signal_emitted_with_parameters(vp, "failed", ["de", "checksum"])
	assert_false(vp.is_ready("de"))
	assert_false(FileAccess.file_exists(vp.pack_path("de")))
	assert_false(FileAccess.file_exists(vp.pack_path("de") + ".part"), "bad bytes dropped")
	assert_eq(Sfx.line_clip_path(KEY, "de", _root()), "", "still subtitle-only")


func test_offline_and_http_error_stay_subtitle_only() -> void:
	var p := _make_pack()
	var probe := TCPServer.new()
	probe.listen(0, "127.0.0.1")
	var closed_port := probe.get_local_port()
	probe.stop()
	var vp := _make_vp(p[1], p[2], "http://127.0.0.1:%d" % closed_port)
	# Godot 4.7.2 on Windows never reports a refused loopback connect (HTTPClient stays
	# STATUS_CONNECTING until our 20 s TIMEOUT_MS), so the "offline" leg only runs on
	# Linux/Android/iOS; the HTTP-error leg below still runs everywhere (local Windows runs).
	if OS.get_name() != "Windows":
		vp.ensure("de")
		await _wait_done(vp)
		assert_eq(vp.last_error("de"), "offline")
		assert_eq(vp.state("de"), "failed")
	var dp := _dialogue("de")
	watch_signals(dp)
	dp.start()
	assert_signal_emitted(dp, "finished", "no clip: all subtitles at once, nothing waits")
	var srv := FakeServer.new()
	add_child_autofree(srv)
	srv.status = 404
	vp.base_url_override = "http://127.0.0.1:%d" % srv.start()
	vp.ensure("de")
	await _wait_done(vp)
	assert_eq(vp.last_error("de"), "http_404")


func test_restart_mounts_installed_and_drops_stale() -> void:
	var p := _make_pack()
	var vp := _make_vp(p[1], p[2], _work + "/src")
	vp.ensure("de")
	await _wait_done(vp)
	assert_eq(vp.state("de"), "installed")
	var again := _make_vp(p[1], p[2], _work + "/src")
	assert_true(again.is_ready("de"), "pack from a previous run is mounted at startup")
	var stale := _make_vp(p[1], "f".repeat(64), _work + "/src")
	assert_false(stale.is_ready("de"))
	assert_false(FileAccess.file_exists(stale.pack_path("de")), "pack of another build removed")


## D-100: the voice list orders EN first, offers every pack, never removes EN.
func test_pack_selection_by_language() -> void:
	var p := _make_pack()
	var vp := _make_vp(p[1], p[2], _work + "/src", ["pl", "de", "es"])
	assert_eq(vp.languages(), ["en", "pl", "de", "es"])
	assert_eq(vp.state("en"), "bundled")
	assert_false(vp.remove("en"), "EN cannot be removed")
	assert_true(vp.is_ready("en"))
	assert_false(vp.blocks("en"))
	assert_eq(vp.policy("pl", "auto"), "download", "the phone language is fetched")
	assert_eq(vp.policy("pl", "manual"), "offer")
	vp.enforce = true
	assert_true(vp.blocks("pl"), "exported build: no PL clips before the pack")
	assert_true(vp.remove("pl"))
	assert_eq(vp.policy("pl", "auto"), "offer", "removed: never fetched on its own")


## D-100: first run in a non-EN language downloads that pack in the background (mock HTTP),
## with a short note (size + progress, then "ready"); EN needs nothing.
func test_first_run_auto_downloads_the_game_language() -> void:
	var p := _make_pack()
	var srv := FakeServer.new()
	add_child_autofree(srv)
	var port := srv.start()
	srv.body = FileAccess.get_file_as_bytes(p[0])
	var mode_before: Variant = Settings.get_value("voice_download")
	Settings.set_value("voice_download", "auto")
	var vp := _make_vp(p[1], p[2], "http://127.0.0.1:%d/packs" % port, ["pl"])
	assert_false(vp.auto("en"), "EN ships: nothing to fetch")
	assert_true(vp.auto("pl"), "PL pack starts in the background")
	assert_string_contains(vp.note_text(), VoicePacksScript.size_text(p[1], I18n.current_language()))
	await _wait_done(vp, "pl")
	assert_eq(vp.state("pl"), "installed", vp.last_error("pl"))
	assert_eq(srv.requests, 1)
	assert_eq(vp.note_text(), I18n.t(&"voicepack.note.ready").format({"title": I18n.t(&"settings.voice_pack.title_pl")}))
	assert_false(vp.auto("pl"), "installed: no second download")
	Settings.set_value("voice_download", "manual")
	var vp2 := _make_vp(p[1], p[2], "http://127.0.0.1:%d/packs" % port, ["de"])
	assert_false(vp2.auto("de"), "manual: offer only")
	Settings.set_value("voice_download", mode_before)


## D-100: no connection -> subtitles only, a polite note, and the download is tried again later.
func test_auto_download_offline_keeps_subtitles_and_retries_later() -> void:
	var p := _make_pack()
	var srv := FakeServer.new()
	add_child_autofree(srv)
	var port := srv.start()
	srv.body = FileAccess.get_file_as_bytes(p[0])
	srv.drop_after = 0   # the connection dies before the first byte
	var mode_before: Variant = Settings.get_value("voice_download")
	Settings.set_value("voice_download", "auto")
	var vp := _make_vp(p[1], p[2], "http://127.0.0.1:%d/packs" % port, ["de"])
	vp.enforce = true
	vp.auto("de")
	await _wait_done(vp)
	assert_eq(vp.state("de"), "failed")
	assert_eq(vp.last_error("de"), "interrupted")
	assert_true(vp.blocks("de"), "no clip plays: subtitles only")
	assert_eq(vp.note_text(), I18n.t(&"voicepack.note.later").format({"title": I18n.t(&"settings.voice_pack.title_de")}))
	assert_eq(int(vp._retry_n.get("de", 0)), 1, "a retry is scheduled")
	assert_eq(VoicePacksScript.retry_delay(0), 60.0)
	assert_eq(VoicePacksScript.retry_delay(9), 1800.0)
	var dp := _dialogue("de")
	watch_signals(dp)
	dp.start()
	assert_signal_emitted(dp, "finished", "no clip: all subtitles at once, nothing waits")
	Settings.set_value("voice_download", mode_before)


## D-100: Remove stops the clips at once, survives a restart, and Download brings them back.
func test_remove_and_download_again() -> void:
	var p := _make_pack()
	var vp := _make_vp(p[1], p[2], _work + "/src")
	vp.enforce = true
	vp.ensure("de")
	await _wait_done(vp)
	assert_eq(vp.state("de"), "installed")
	assert_false(vp.blocks("de"))
	assert_true(vp.remove("de"))
	assert_eq(vp.state("de"), "missing")
	assert_true(vp.is_removed("de"))
	assert_true(vp.blocks("de"), "removed: clips stop now")
	assert_false(vp.auto("de"), "removed: no automatic download")
	assert_true(vp.ensure("de"), "Download again: the file is still here, undone at once")
	assert_false(vp.is_removed("de"))
	assert_eq(vp.state("de"), "installed")
	vp.remove("de")
	var again := _make_vp(p[1], p[2], _work + "/src")
	assert_false(again.is_ready("de"), "removed stays removed after a restart")
	assert_false(FileAccess.file_exists(again.pack_path("de")), "the file is deleted at the next start")
	assert_true(again.is_removed("de"))
	again.ensure("de")
	await _wait_done(again)
	assert_eq(again.state("de"), "installed", again.last_error("de"))
	assert_false(again.is_removed("de"))


## D-100: Settings -> Voices lists EN (in the game, no button) and every pack with its size;
## Download and Remove work from there (the autoload pointed at a fixture manifest).
func test_settings_lists_packs_download_and_remove() -> void:
	var p := _make_pack()
	var _m := _make_vp(p[1], p[2], _work + "/src", ["pl", "de"])   # writes the fixture manifest
	var mode_before: Variant = Settings.get_value("voice_download")
	Settings.set_value("voice_download", "manual")   # no automatic downloads here
	VoicePacks.manifest_path = _work + "/voice_packs.json"
	VoicePacks.dir = _work + "/autoload_store"
	VoicePacks.reload()
	var scene: Control = load("res://scenes/settings.tscn").instantiate()
	add_child_autofree(scene)
	await get_tree().process_frame
	var rows: Control = scene.get_node("Frame/VBox/Scroll/Sections/Access/Box/VoicePack/VoicePackRows")
	assert_eq(rows.get_child_count(), 3, "EN, PL, DE")
	assert_eq(String(rows.get_child(0).name), "Row_en")
	var en_label: Label = rows.get_node("Row_en/Label")
	assert_string_contains(en_label.text, I18n.t(&"settings.voice_pack.builtin"))
	assert_false((rows.get_node("Row_en/Action") as Button).visible, "EN cannot be removed")
	var de_label: Label = rows.get_node("Row_de/Label")
	var de_action: Button = rows.get_node("Row_de/Action")
	if not VoicePacks.is_ready("de"):
		assert_string_contains(de_label.text, I18n.t(&"settings.voice_pack.title_de"))
		assert_string_contains(de_label.text, VoicePacks.size_text(p[1], I18n.current_language()))
		assert_eq(de_action.text, I18n.t(&"settings.voice_pack.download"))
		assert_gte(de_action.custom_minimum_size.y, 48.0)
		de_action.pressed.emit()
		await _wait_done(VoicePacks)
	assert_eq(VoicePacks.state("de"), "installed", VoicePacks.last_error("de"))
	await get_tree().process_frame
	assert_eq(de_action.text, I18n.t(&"settings.voice_pack.remove"))
	de_action.pressed.emit()
	assert_true(VoicePacks.is_removed("de"))
	assert_eq(de_action.text, I18n.t(&"settings.voice_pack.download"))
	de_action.pressed.emit()   # download again (undo: the file is still here)
	assert_eq(VoicePacks.state("de"), "installed")
	for k in ["title_pl", "title_en", "title_de", "download", "remove", "stop", "retry", "ready", "builtin"]:
		for l in ["pl", "en", "de", "fr", "es"]:
			var tr := TranslationServer.get_translation_object(l)
			assert_lte(String(tr.get_message("settings.voice_pack." + k)).length(), 28, "%s/%s" % [k, l])
	for l in ["pl", "en", "de"]:   # the wrapping toggle; FR/ES are longer and wrap (as before D-100)
		assert_lte(String(TranslationServer.get_translation_object(l).get_message("settings.voice_pack.auto")).length(), 28, l)
	VoicePacks.manifest_path = VoicePacksScript.MANIFEST_PATH
	VoicePacks.dir = VoicePacksScript.DIR
	VoicePacks._mounted.erase("de")   # the fixture pack is not the real DE pack
	VoicePacks.reload()
	Settings.set_value("voice_download", mode_before)
