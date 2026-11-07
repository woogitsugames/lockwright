extends GutTest
## D-62: on-demand voice packs (VoicePacks autoload script, fresh instance per test).
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


func _make_vp(size: int, sha: String, base: String) -> Node:
	var m := FileAccess.open(_work + "/voice_packs.json", FileAccess.WRITE)
	m.store_string(JSON.stringify({"schema": 1, "version": "test", "base_url": base, "packs": {
		"de": {"file": "voice_de.pck", "url": base + "/voice_de.pck", "size": size, "sha256": sha}}}))
	m.close()
	var vp: Node = VoicePacksScript.new()
	vp.manifest_path = _work + "/voice_packs.json"
	vp.dir = _work + "/store"
	vp.auto_follow_language = false
	add_child_autofree(vp)
	return vp


func _wait_done(vp: Node) -> void:
	var t0 := Time.get_ticks_msec()
	while vp.state("de") in ["downloading", "verifying"] and Time.get_ticks_msec() - t0 < WAIT_S * 1000.0:
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
	assert_true(vp.is_ready("pl"))
	assert_true(vp.is_ready("en"))
	assert_eq(vp.state("pl"), "bundled")
	assert_eq(vp.state("de"), "missing")
	assert_eq(vp.state("fr"), "none", "no pack in the manifest")
	assert_eq(vp.policy("de", "ask"), "ask")
	assert_eq(vp.policy("de", "auto"), "download")
	assert_eq(vp.policy("de", "manual"), "offer")
	assert_eq(vp.policy("pl", "auto"), "none")
	assert_eq(VoicePacksScript.size_text(8164916, "pl"), "8,2 MB")
	assert_eq(VoicePacksScript.size_text(8164916, "de"), "8,2 MB")
	assert_eq(VoicePacksScript.size_text(8164916, "en"), "8.2 MB")


func test_shipped_manifest_offers_de_only() -> void:
	var m: Variant = JSON.parse_string(FileAccess.get_file_as_string(VoicePacksScript.MANIFEST_PATH))
	assert_true(m is Dictionary, "res://data/voice_packs.json parses")
	var packs: Dictionary = m.get("packs", {})
	assert_true(packs.has("de"), "DE is an on-demand pack (D-62)")
	assert_false(packs.has("pl") or packs.has("en"), "PL+EN ship in the package")
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


func test_settings_offers_de_voices_with_size() -> void:
	var dev: Variant = Save.get_value("dev_mode", false)
	var lang_before: Variant = Settings.get_value("language")
	var mode_before: Variant = Settings.get_value("voice_download")
	Save.set_value("dev_mode", true)
	Settings.set_value("voice_download", "ask")  # never "auto" here: no real network in tests
	Settings.set_value("language", "de")
	var scene: Control = load("res://scenes/settings.tscn").instantiate()
	add_child_autofree(scene)
	await get_tree().process_frame
	var box: Control = scene.get_node("Frame/VBox/Scroll/Sections/Access/Box/VoicePack")
	var label: Label = box.get_node("VoicePackLabel")
	var download: Button = box.get_node("VoicePackButtons/VoicePackDownload")
	var later: Button = box.get_node("VoicePackButtons/VoicePackLater")
	if VoicePacks.is_ready("de"):
		assert_true(box.visible and not download.visible, "installed: no download plate")
	else:
		assert_true(box.visible, "DE is not bundled: the offer is shown")
		assert_string_contains(label.text, I18n.t(&"settings.voice_pack.title_de"))
		assert_string_contains(label.text, VoicePacks.size_text(VoicePacks.pack_size("de"), "de"))
		assert_true(download.visible and later.visible, "asked once: Download + Not now")
		assert_gte(download.custom_minimum_size.y, 48.0)
		assert_gte(later.custom_minimum_size.y, 48.0)
		later.pressed.emit()
		assert_eq(Settings.get_value("voice_download"), "manual")
		assert_false(later.visible, "Not now remembered")
		assert_true(download.visible, "manual download stays available")
	for k in ["title_de", "download", "not_now", "stop", "retry", "ready", "auto"]:
		for l in ["pl", "en", "de"]:
			var tr := TranslationServer.get_translation_object(l)
			assert_lte(String(tr.get_message("settings.voice_pack." + k)).length(), 28, "%s/%s" % [k, l])
	Settings.set_value("language", lang_before)
	Settings.set_value("voice_download", mode_before)
	Save.set_value("dev_mode", dev)
	assert_eq(Settings.get_value("language"), lang_before)
