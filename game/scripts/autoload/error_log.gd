extends Node
class_name ErrorLog
## Local error log, no telemetry (task 12). Writes to user://logs/ with rotation
## (keep the newest LOG_FILES files, LOG_MAX_BYTES each). Nothing ever leaves the
## device: the Settings "Report a problem" screen only copies the latest log to the
## clipboard / offers the system share sheet.

const LOG_DIR := "user://logs"
const LOG_FILE := "session.log"
const LOG_MAX_BYTES := 512 * 1024
const LOG_FILES := 5

var _file: FileAccess = null


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(LOG_DIR)
	_rotate()
	_file = FileAccess.open(LOG_DIR + "/" + LOG_FILE, FileAccess.WRITE)
	write_line("=== session start %s ===" % Time.get_datetime_string_from_system())


func _rotate() -> void:
	# shift session.log -> session.1.log ... keep LOG_FILES
	for i in range(LOG_FILES - 1, 0, -1):
		var from := "%s/session.%d.log" % [LOG_DIR, i]
		var to := "%s/session.%d.log" % [LOG_DIR, i + 1]
		if FileAccess.file_exists(from):
			DirAccess.rename_absolute(from, to)
	var cur := LOG_DIR + "/" + LOG_FILE
	if FileAccess.file_exists(cur):
		DirAccess.rename_absolute(cur, LOG_DIR + "/session.1.log")


func write_line(msg: String) -> void:
	if _file == null:
		return
	_file.store_line("%s %s" % [Time.get_time_string_from_system(), msg])
	_file.flush()
	if _file.get_length() > LOG_MAX_BYTES:
		_file.close()
		_rotate()
		_file = FileAccess.open(LOG_DIR + "/" + LOG_FILE, FileAccess.WRITE)


func log_error(msg: String) -> void:
	write_line("ERROR " + msg)
	push_error(msg)


func log_info(msg: String) -> void:
	write_line("INFO " + msg)


func latest_log_text() -> String:
	if not FileAccess.file_exists(LOG_DIR + "/" + LOG_FILE):
		return ""
	return FileAccess.get_file_as_string(LOG_DIR + "/" + LOG_FILE)
