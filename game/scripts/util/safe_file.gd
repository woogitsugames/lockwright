class_name SafeFile
extends RefCounted
## D-136: text files in user:// are replaced, never rewritten in place. FileAccess.WRITE truncates the
## file the moment it is opened, so a full disk, a crash or a kill between "open" and "all bytes
## written" used to leave an empty or cut file (the save: the whole career).
##   write_text(): write <path>.tmp -> check that every byte arrived -> (keep_backup) the file that
##   was good until now becomes <path>.bak -> rename the temp file over <path>.
## A failed write leaves <path> and <path>.bak exactly as they were and returns the error.
## Godot cannot fsync from scripts; the backup is what covers a power cut right after the rename.

const TMP_SUFFIX := ".tmp"
const BACKUP_SUFFIX := ".bak"

## Tests: "" (real disk) | "open" (the temp file cannot be created) | "short" (the disk fills up
## half way) | "rename" (the temp file cannot take the place of the file).
static var fail_mode := ""
## Tests / diagnostics: number of files replaced since the start.
static var writes := 0


static func write_text(path: String, text: String, keep_backup := false) -> Error:
	var tmp := path + TMP_SUFFIX
	if fail_mode == "open":
		return ERR_FILE_CANT_OPEN
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		# a user:// subfolder removed behind the game's back: make it and try once more
		DirAccess.make_dir_recursive_absolute(path.get_base_dir())
		f = FileAccess.open(tmp, FileAccess.WRITE)
		if f == null:
			return FileAccess.get_open_error() if FileAccess.get_open_error() != OK else ERR_FILE_CANT_OPEN
	var bytes := text.to_utf8_buffer()
	var stored := f.store_buffer(bytes.slice(0, bytes.size() / 2) if fail_mode == "short" else bytes)
	f.flush()
	var err := f.get_error()
	var written := f.get_length()
	f.close()
	if not stored or (err != OK and err != ERR_FILE_EOF) or written != bytes.size():
		DirAccess.remove_absolute(tmp)
		return ERR_FILE_CANT_WRITE
	if fail_mode == "rename":
		DirAccess.remove_absolute(tmp)
		return ERR_FILE_CANT_WRITE
	if keep_backup and FileAccess.file_exists(path):
		_replace(path, path + BACKUP_SUFFIX)
	if _replace(tmp, path) != OK:
		DirAccess.remove_absolute(tmp)
		# the good copy went to .bak a moment ago: put it back so <path> is never missing
		if keep_backup and not FileAccess.file_exists(path) and FileAccess.file_exists(path + BACKUP_SUFFIX):
			DirAccess.copy_absolute(path + BACKUP_SUFFIX, path)
		return ERR_FILE_CANT_WRITE
	writes += 1
	return OK


## rename() that also works where the target exists and the platform refuses to overwrite (Windows).
static func _replace(from: String, to: String) -> Error:
	if DirAccess.rename_absolute(from, to) == OK:
		return OK
	if FileAccess.file_exists(to):
		DirAccess.remove_absolute(to)
		return DirAccess.rename_absolute(from, to)
	return ERR_FILE_CANT_WRITE


## Parsed JSON of `path` when it holds a JSON object, else null (missing, empty, cut, not an object).
## No engine error on bad input: a damaged file is an expected case, not a bug.
static func read_json_object(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	var j := JSON.new()
	if j.parse(FileAccess.get_file_as_string(path)) != OK or typeof(j.data) != TYPE_DICTIONARY:
		return null
	return j.data


## Removes a temp file left by a write that was cut off (a kill between "written" and "renamed").
static func drop_stale_tmp(path: String) -> void:
	if FileAccess.file_exists(path + TMP_SUFFIX):
		DirAccess.remove_absolute(path + TMP_SUFFIX)
