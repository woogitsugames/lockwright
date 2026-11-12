extends Node
## Shared store for on-demand packs (D-62/D-100 voices, D-112 content): one data-only Godot pck per
## pack id, listed in a manifest that ships inside the app with the pack's size and SHA-256. The hash
## is part of the app, so a pack is trusted only when it matches the build the player has.
##
## Flow: ensure(id) -> HTTP GET (Range resume from <dir>/<file>.part) -> SHA-256 in small per-frame
## steps -> rename -> ProjectSettings.load_resource_pack. Offline or failed: nothing waits for it.
## Privacy: one plain GET for a static file; no ids, no cookies, no analytics.
## Packs cannot be unmounted: a removed pack stops being used at once (is_ready() is false) and its
## file is deleted (at the next start if it was mounted).
## Subclasses: voice_packs.gd (VoicePacks), content_packs.gd (ContentPacks). They set manifest_path
## and dir in _init() and may override is_bundled(), file_name(), _read_manifest() and _mount().
## (The pack id is called `lang` in this file: it started as the voice packs' language.)

signal state_changed(lang: String)
signal progress(lang: String, received: int, total: int)
signal installed(lang: String)
signal failed(lang: String, reason: String)

const STATE_FILE := "installed.json"
const REMOVED_FILE := "removed.json"  # packs the player removed: no automatic download again
const CHUNK := 65536
const HASH_STEP := 1 << 20        # bytes hashed per frame while verifying
const COPY_STEP := 1 << 19        # bytes copied per frame for file:// / res:// sources
const TIMEOUT_MS := 20000         # no progress for this long -> "timeout"
const MAX_REDIRECTS := 5          # GitHub release assets redirect to a CDN host

# Overridable by tests / dev builds before the node enters the tree.
var manifest_path := ""
var dir := ""
var base_url_override := ""       # replaces the manifest's base_url (file name kept)
## A removed / not installed pack is not used. Exported builds only: in the editor every pack's
## source files exist on disk and stay usable for development.
var enforce := OS.has_feature("template")

var _manifest := {}
var _mounted := {}                # id -> true
var _jobs := {}                   # id -> Job
var _errors := {}                 # id -> last failure reason
var _removed := {}                # id -> true (persisted in REMOVED_FILE)


class Job:
	extends RefCounted
	var lang := ""                # the pack id
	var url := ""
	var sha := ""
	var size := 0
	var part := ""
	var phase := "start"          # start, connect, request, body, copy, verify, done
	var client: HTTPClient
	var src: FileAccess           # file:// copy source
	var out: FileAccess
	var hasher: HashingContext
	var hashed := 0
	var received := 0
	var redirects := 0
	var path_query := ""
	var origin := ""              # scheme://host:port of the current request
	var last_ms := 0


## Reads the manifest and mounts every pack already downloaded for this build.
func reload() -> void:
	_manifest = _read_manifest()
	DirAccess.make_dir_recursive_absolute(dir)
	_removed = {}
	for lang in _read_json(REMOVED_FILE, []):
		_removed[str(lang)] = true
		DirAccess.remove_absolute(pack_path(str(lang)))  # deleted now if it was busy last time
	var state := _read_state()
	for lang in state:
		var entry := _entry(lang)
		var path := pack_path(lang)
		if entry.is_empty() or str(state[lang]) != str(entry.get("sha256", "")):
			# stale pack from an older build: its content may not match the new game
			DirAccess.remove_absolute(path)
			continue
		if FileAccess.file_exists(path) and not _removed.has(lang):
			_mount(lang)


## The manifest as shipped in the app ({} when missing or unreadable).
func _read_manifest() -> Dictionary:
	if FileAccess.file_exists(manifest_path):
		var parsed: Variant = parse_json(FileAccess.get_file_as_string(manifest_path))
		if parsed is Dictionary:
			return parsed
	return {}


## JSON.parse_string without the engine error on bad input (a damaged file is not a crash): null.
static func parse_json(text: String) -> Variant:
	var j := JSON.new()
	return j.data if j.parse(text) == OK else null


# --- queries -------------------------------------------------------------------------

## Ships inside the game package: always ready, never downloaded or removed.
func is_bundled(_lang: String) -> bool:
	return false


## File name of the pack in `dir` and under the URL base.
func file_name(lang: String) -> String:
	return str(_entry(lang).get("file", "%s.pck" % lang))


## The manifest offers a pack with this id.
func has_pack(lang: String) -> bool:
	return not _entry(lang).is_empty()


## The pack's content can be used now.
func is_ready(lang: String) -> bool:
	return is_bundled(lang) or (_mounted.has(lang) and not _removed.has(lang))


## The player removed this pack (no automatic download until they fetch it again).
func is_removed(lang: String) -> bool:
	return _removed.has(lang)


## "bundled" | "installed" | "downloading" | "verifying" | "failed" | "missing" | "none"
func state(lang: String) -> String:
	if is_bundled(lang):
		return "bundled"
	if _mounted.has(lang) and not _removed.has(lang):
		return "installed"
	if _jobs.has(lang):
		return "verifying" if _jobs[lang].phase == "verify" else "downloading"
	if not has_pack(lang):
		return "none"
	return "failed" if _errors.has(lang) else "missing"


func pack_size(lang: String) -> int:
	return int(_entry(lang).get("size", 0))


func last_error(lang: String) -> String:
	return str(_errors.get(lang, ""))


func progress_ratio(lang: String) -> float:
	if not _jobs.has(lang):
		return 1.0 if is_ready(lang) else 0.0
	var j: Job = _jobs[lang]
	return clampf(float(j.received) / maxf(1.0, float(j.size)), 0.0, 1.0)


func pack_path(lang: String) -> String:
	return dir.path_join(file_name(lang))


func pack_url(lang: String) -> String:
	var e := _entry(lang)
	if e.is_empty():
		return ""
	if base_url_override != "":
		return base_url_override.trim_suffix("/") + "/" + file_name(lang)
	return str(e.get("url", ""))


## "8.2 MB" / "8,2 MB" (decimal comma for PL, DE, FR, ES).
static func size_text(bytes: int, locale: String) -> String:
	var s := "%.1f MB" % (float(bytes) / 1e6)
	if locale.substr(0, 2) in ["pl", "de", "fr", "es"]:
		s = s.replace(".", ",")
	return s


# --- actions -------------------------------------------------------------------------

## True when the pack is already usable; otherwise starts (or keeps) a download.
func ensure(lang: String) -> bool:
	if is_ready(lang):
		return true
	if _jobs.has(lang) or not has_pack(lang):
		return false
	if _removed.erase(lang):
		_write_removed()
		if _mounted.has(lang) and FileAccess.file_exists(pack_path(lang)):
			state_changed.emit(lang)  # removed earlier this session, file still here: undo
			return true
	var e := _entry(lang)
	var j := Job.new()
	j.lang = lang
	j.url = pack_url(lang)
	j.sha = str(e.get("sha256", "")).to_lower()
	j.size = int(e.get("size", 0))
	j.part = pack_path(lang) + ".part"
	j.last_ms = Time.get_ticks_msec()
	_errors.erase(lang)
	_jobs[lang] = j
	_start(j)
	set_process(true)
	state_changed.emit(lang)
	return false


func cancel(lang: String) -> void:
	if not _jobs.has(lang):
		return
	_close(_jobs[lang])  # the .part stays: the next ensure() resumes it
	_jobs.erase(lang)
	state_changed.emit(lang)


## "Remove" in Settings: the pack stops being used now, the files go, and the choice is kept so
## the pack is not fetched again on its own. A bundled pack cannot be removed.
func remove(lang: String) -> bool:
	if is_bundled(lang):
		return false
	cancel(lang)
	_removed[lang] = true
	_write_removed()
	DirAccess.remove_absolute(pack_path(lang) + ".part")
	DirAccess.remove_absolute(pack_path(lang) + ".part.json")
	if not _mounted.has(lang):
		DirAccess.remove_absolute(pack_path(lang))
		var st := _read_state()
		st.erase(lang)
		_write_json(STATE_FILE, st)
	# a mounted pack's file is deleted at the next start (reload reads REMOVED_FILE)
	_errors.erase(lang)
	state_changed.emit(lang)
	return true


# --- internals -----------------------------------------------------------------------

func _entry(lang: String) -> Dictionary:
	var packs: Variant = _manifest.get("packs", {})
	if packs is Dictionary and packs.has(lang) and packs[lang] is Dictionary:
		return packs[lang]
	return {}


func _read_json(file: String, fallback: Variant) -> Variant:
	var p := dir.path_join(file)
	if not FileAccess.file_exists(p):
		return fallback
	var parsed: Variant = parse_json(FileAccess.get_file_as_string(p))
	return parsed if typeof(parsed) == typeof(fallback) else fallback


func _write_json(file: String, value: Variant) -> void:
	var f := FileAccess.open(dir.path_join(file), FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(value))


func _read_state() -> Dictionary:
	return _read_json(STATE_FILE, {})


func _write_state(lang: String, sha: String) -> void:
	var s := _read_state()
	s[lang] = sha
	_write_json(STATE_FILE, s)


func _write_removed() -> void:
	_write_json(REMOVED_FILE, _removed.keys())


func _mount(lang: String) -> bool:
	if _mounted.has(lang):
		return true
	# replace_files=false: the pack only ADDS its own files, it never shadows
	# anything in the main package (its project.binary / caches are ignored).
	if ProjectSettings.load_resource_pack(pack_path(lang), false):
		_mounted[lang] = true
		return true
	return false


func _start(j: Job) -> void:
	# resume only a .part of the same file (sha in the sidecar), else start clean
	var meta := j.part + ".json"
	var resumable := FileAccess.file_exists(j.part) and FileAccess.file_exists(meta) \
			and FileAccess.get_file_as_string(meta).strip_edges() == j.sha
	if not resumable:
		DirAccess.remove_absolute(j.part)
		var m := FileAccess.open(meta, FileAccess.WRITE)
		if m != null:
			m.store_string(j.sha)
	if FileAccess.file_exists(j.part):
		j.out = FileAccess.open(j.part, FileAccess.READ_WRITE)
		if j.out != null:
			j.out.seek_end()
	else:
		j.out = FileAccess.open(j.part, FileAccess.WRITE)
	if j.out == null:
		_fail(j, "storage")
		return
	j.received = j.out.get_position()
	if j.received >= j.size and j.size > 0:
		_begin_verify(j)
		return
	if j.url.begins_with("file://") or j.url.begins_with("res://") or j.url.begins_with("user://"):
		j.src = FileAccess.open(j.url.trim_prefix("file://"), FileAccess.READ)
		if j.src == null:
			_fail(j, "offline")
			return
		j.src.seek(j.received)
		j.phase = "copy"
		return
	_connect(j, j.url)


func _connect(j: Job, url: String) -> void:
	var m := RegEx.create_from_string("^(https?)://([^/:]+)(?::(\\d+))?(/.*)?$").search(url)
	if m == null:
		_fail(j, "url")
		return
	var tls := m.get_string(1) == "https"
	var port := int(m.get_string(3)) if m.get_string(3) != "" else (443 if tls else 80)
	j.path_query = m.get_string(4) if m.get_string(4) != "" else "/"
	j.origin = "%s://%s:%d" % [m.get_string(1), m.get_string(2), port]
	if j.client != null:
		j.client.close()
	j.client = HTTPClient.new()
	j.client.read_chunk_size = CHUNK
	var err := j.client.connect_to_host(m.get_string(2), port, TLSOptions.client() if tls else null)
	if err != OK:
		_fail(j, "offline")
		return
	j.phase = "connect"
	j.last_ms = Time.get_ticks_msec()


func _process(_delta: float) -> void:
	for lang in _jobs.keys():
		var j: Job = _jobs[lang]
		match j.phase:
			"connect", "request", "body":
				_step_http(j)
			"copy":
				_step_copy(j)
			"verify":
				_step_verify(j)
		if j.phase not in ["done", "failed"] and Time.get_ticks_msec() - j.last_ms > TIMEOUT_MS:
			_fail(j, "timeout")
	if _jobs.is_empty():
		set_process(false)


func _step_http(j: Job) -> void:
	j.client.poll()
	var st := j.client.get_status()
	match st:
		HTTPClient.STATUS_RESOLVING, HTTPClient.STATUS_CONNECTING:
			return
		HTTPClient.STATUS_CANT_RESOLVE, HTTPClient.STATUS_CANT_CONNECT, \
		HTTPClient.STATUS_CONNECTION_ERROR, HTTPClient.STATUS_TLS_HANDSHAKE_ERROR:
			# a server closing right after the last byte reads as an error: the size decides
			if j.phase != "body":
				_fail(j, "offline" if j.phase == "connect" else "interrupted")
				return
	if j.phase == "connect":
		if st != HTTPClient.STATUS_CONNECTED:
			return
		var headers := PackedStringArray(["Accept: application/octet-stream"])
		if j.received > 0:
			headers.append("Range: bytes=%d-" % j.received)
		if j.client.request(HTTPClient.METHOD_GET, j.path_query, headers) != OK:
			_fail(j, "offline")
			return
		j.phase = "request"
		j.last_ms = Time.get_ticks_msec()
		return
	if j.phase == "request":
		if st == HTTPClient.STATUS_REQUESTING:
			return
		if not j.client.has_response():
			_fail(j, "interrupted")
			return
		_on_response(j)
		return
	# body
	if st == HTTPClient.STATUS_BODY:
		var chunk := j.client.read_response_body_chunk()
		if chunk.size() > 0:
			j.out.store_buffer(chunk)
			j.received += chunk.size()
			j.last_ms = Time.get_ticks_msec()
			progress.emit(j.lang, j.received, j.size)
		if j.received > j.size:
			_restart_clean(j, "checksum")
		return
	# the body ended (or the connection dropped): complete only if every byte is here
	if j.received == j.size:
		j.client.close()
		_begin_verify(j)
	else:
		_fail(j, "interrupted")


func _on_response(j: Job) -> void:
	var code := j.client.get_response_code()
	var hdr := j.client.get_response_headers_as_dictionary()
	if code in [301, 302, 303, 307, 308]:
		var loc := ""
		for k in hdr:
			if str(k).to_lower() == "location":
				loc = str(hdr[k])
		j.redirects += 1
		if loc.begins_with("/"):
			loc = j.origin + loc
		if loc == "" or j.redirects > MAX_REDIRECTS:
			_fail(j, "http_%d" % code)
			return
		_connect(j, loc)
		return
	if code == 200 and j.received > 0:
		# server ignored Range: start the file over
		j.out.close()
		j.out = FileAccess.open(j.part, FileAccess.WRITE)
		j.received = 0
	elif code == 206 and not _range_starts_at(hdr, j.received):
		_restart_clean(j, "http_206")
		return
	elif code == 416:
		_restart_clean(j, "http_416")
		return
	elif code != 200 and code != 206:
		_fail(j, "http_%d" % code)
		return
	j.phase = "body"
	j.last_ms = Time.get_ticks_msec()


static func _range_starts_at(hdr: Dictionary, offset: int) -> bool:
	for k in hdr:
		if str(k).to_lower() == "content-range":
			var m := RegEx.create_from_string("bytes\\s+(\\d+)-").search(str(hdr[k]))
			return m != null and int(m.get_string(1)) == offset
	return false


func _step_copy(j: Job) -> void:
	var buf := j.src.get_buffer(COPY_STEP)
	if buf.size() > 0:
		j.out.store_buffer(buf)
		j.received += buf.size()
		j.last_ms = Time.get_ticks_msec()
		progress.emit(j.lang, j.received, j.size)
	if j.src.eof_reached() or buf.size() == 0:
		j.src = null
		if j.received == j.size:
			_begin_verify(j)
		else:
			_fail(j, "checksum" if j.received > j.size else "interrupted")


func _begin_verify(j: Job) -> void:
	if j.out != null:
		j.out.close()
	j.out = FileAccess.open(j.part, FileAccess.READ)
	if j.out == null:
		_fail(j, "storage")
		return
	j.hasher = HashingContext.new()
	j.hasher.start(HashingContext.HASH_SHA256)
	j.hashed = 0
	j.phase = "verify"
	j.last_ms = Time.get_ticks_msec()
	state_changed.emit(j.lang)


func _step_verify(j: Job) -> void:
	var buf := j.out.get_buffer(HASH_STEP)
	if buf.size() > 0:
		j.hasher.update(buf)
		j.hashed += buf.size()
		j.last_ms = Time.get_ticks_msec()
	if buf.size() == HASH_STEP:
		return
	j.out.close()
	j.out = null
	var got := j.hasher.finish().hex_encode()
	if got != j.sha:
		_restart_clean(j, "checksum")
		return
	var final := pack_path(j.lang)
	DirAccess.remove_absolute(final)
	if DirAccess.rename_absolute(j.part, final) != OK:
		_fail(j, "storage")
		return
	DirAccess.remove_absolute(j.part + ".json")
	_write_state(j.lang, j.sha)
	j.phase = "done"
	_jobs.erase(j.lang)
	if _mount(j.lang):
		state_changed.emit(j.lang)
		installed.emit(j.lang)
	else:
		_errors[j.lang] = "mount"
		state_changed.emit(j.lang)
		failed.emit(j.lang, "mount")


## Bad bytes: drop the .part so the next try starts from zero.
func _restart_clean(j: Job, reason: String) -> void:
	_close(j)
	DirAccess.remove_absolute(j.part)
	DirAccess.remove_absolute(j.part + ".json")
	_fail(j, reason)


func _close(j: Job) -> void:
	if j.client != null:
		j.client.close()
		j.client = null
	if j.out != null:
		j.out.close()
		j.out = null
	j.src = null


func _fail(j: Job, reason: String) -> void:
	_close(j)
	j.phase = "failed"
	_jobs.erase(j.lang)
	_errors[j.lang] = reason
	state_changed.emit(j.lang)
	failed.emit(j.lang, reason)
