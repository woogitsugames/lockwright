extends Node
## D-57: plays a job's dialogue line by line. Each line row appears in turn (current line
## at full strength, earlier ones dimmed), its voiced clip plays on the Voice bus in the
## current UI language, and the next line starts CLIP_GAP_MS after the clip ends.
## Subtitles are always on (the row IS the subtitle). A line without a clip in this
## language is subtitle-only: it stays for a reading time, never a clip in another language.
## A tap on the dialogue skips to the next line; skip_all() reveals everything.
## If no line has a clip (e.g. DE, or audio not delivered yet) or a screen reader is
## active, all lines are shown at once with no audio (TalkBack/VoiceOver reads them).

signal line_started(index: int, voiced: bool)
signal finished

const CLIP_GAP_MS := 250
const DIM_ALPHA := 0.7        # earlier lines: still >= 4.5:1 on the dark-paper underlay
const FADE_S := 0.18          # 100-250 ms (DESIGN), skipped under reduce_motion
const READ_MS_BASE := 1400    # subtitle-only line: base + per character, clamped
const READ_MS_PER_CHAR := 55
const READ_MS_MAX := 6000
const TAP_SLOP_PX := 12.0     # same as the Scroll deadzone: farther = a scroll, not a tap

var root: String = Sfx.LINES_ROOT  # tests point this at a test-only folder
var lang: String = ""
var index := -1
var player: AudioStreamPlayer
var screen_reader_override := -1  # tests: 0/1 force; -1 asks DisplayServer

var _rows: Array[Control] = []
var _keys: PackedStringArray = []
var _texts: PackedStringArray = []
var _clips: PackedStringArray = []
var _timer: Timer
var _done := false
var _press_pos := Vector2.INF


func _ready() -> void:
	player = AudioStreamPlayer.new()
	player.name = "VoicePlayer"
	player.bus = Sfx.voice_bus()
	add_child(player)
	player.finished.connect(_on_clip_finished)
	_timer = Timer.new()
	_timer.one_shot = true
	add_child(_timer)
	_timer.timeout.connect(advance)
	Settings.changed.connect(_apply_volume)


func _exit_tree() -> void:
	if index >= 0 and not _done:
		Sfx.duck_music_for_voice(false)


## rows[i] shows keys[i] (`<job_id>.line.<N>`); texts[i] is its subtitle (for reading time).
func setup(rows: Array, keys: PackedStringArray, texts: PackedStringArray, p_lang: String = "") -> void:
	_rows.clear()
	for r in rows:
		_rows.append(r)
	_keys = keys
	_texts = texts
	lang = p_lang if p_lang != "" else Settings.language()
	_clips.clear()
	for k in _keys:
		_clips.append(Sfx.line_clip_path(k, lang, root))


func clip_for(i: int) -> String:
	return _clips[i] if i >= 0 and i < _clips.size() else ""


func has_any_clip() -> bool:
	for c in _clips:
		if c != "":
			return true
	return false


func is_finished() -> bool:
	return _done


func _screen_reader_active() -> bool:
	if screen_reader_override >= 0:
		return screen_reader_override == 1
	if DisplayServer.has_method("accessibility_screen_reader_active"):
		return int(DisplayServer.accessibility_screen_reader_active()) == 1
	return false


func start() -> void:
	_done = false
	index = -1
	if _rows.is_empty():
		_finish()
		return
	if not has_any_clip() or _screen_reader_active():
		_finish()
		return
	for r in _rows:
		r.visible = false
	advance()


## Next line now (tap): stops the current clip; past the last line it finishes.
func advance() -> void:
	if _done:
		return
	_timer.stop()
	if player.playing:
		player.stop()
	if index + 1 >= _rows.size():
		_finish()
		return
	index += 1
	_show(index)


func skip_all() -> void:
	if _done:
		return
	_timer.stop()
	player.stop()
	_finish()


func _show(i: int) -> void:
	for j in i:
		_rows[j].modulate.a = DIM_ALPHA
		_rows[j].set_meta("current", false)
	var row := _rows[i]
	row.visible = true
	row.set_meta("current", true)
	if Settings.get_value("reduce_motion", false) or not is_inside_tree():
		row.modulate.a = 1.0
	else:
		row.modulate.a = 0.0
		create_tween().tween_property(row, "modulate:a", 1.0, FADE_S)
	var path := clip_for(i)
	var stream: AudioStream = load(path) as AudioStream if path != "" else null
	line_started.emit(i, stream != null)
	if stream != null:
		if stream is AudioStreamOggVorbis:
			stream.loop = false
		player.stream = stream
		player.bus = Sfx.voice_bus()
		_apply_volume()
		Sfx.duck_music_for_voice(true)
		player.play()
	else:
		Sfx.duck_music_for_voice(false)
		_timer.start(reading_time_ms(_texts[i] if i < _texts.size() else "") / 1000.0)


static func reading_time_ms(text: String) -> int:
	return mini(READ_MS_BASE + READ_MS_PER_CHAR * text.length(), READ_MS_MAX)


func _on_clip_finished() -> void:
	if _done:
		return
	Sfx.duck_music_for_voice(false)
	_timer.start(CLIP_GAP_MS / 1000.0)


func _apply_volume() -> void:
	if player != null:
		player.volume_db = Sfx.voice_volume_db()


func _finish() -> void:
	var was_running := index >= 0
	_done = true
	for r in _rows:
		r.visible = true
		r.modulate.a = 1.0
		r.set_meta("current", false)
	if was_running:
		Sfx.duck_music_for_voice(false)
	finished.emit()


## Tap anywhere on the dialogue (connect to the lines container's gui_input; rows pass
## mouse events up). A press+release within TAP_SLOP_PX is a tap; a drag is a scroll.
func on_gui_input(event: InputEvent) -> void:
	if _done:
		return
	var mb := event as InputEventMouseButton
	if mb == null or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	if mb.pressed:
		_press_pos = mb.position
	elif _press_pos != Vector2.INF:
		var moved := mb.position.distance_to(_press_pos)
		_press_pos = Vector2.INF
		if moved <= TAP_SLOP_PX:
			advance()
