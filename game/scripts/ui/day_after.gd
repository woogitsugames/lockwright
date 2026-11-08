class_name DayAfter
extends Control
## V04 / D-78: "the day after" — a short follow-up after a finished job (opened, repaired, talked through,
## refused). Jobs list `after` speakers in game/data/jobs/*.json; the texts are `<job_id>.after.N`
## (content.csv). A finished job with `after` lines goes into a small queue in Save; the next time the
## player enters the job list, ONE scene plays for the newest unseen job: the place photo (by day), the
## speaker's portrait (G09 cast / episodic, else the G17 initial plate as on the arrival screen), the line,
## a tap (or the Continue plate, or Back) moves on; after the last line the scene closes and is never shown
## again for that job. A line with a recorded clip (`lines/<lang>/<key>.ogg`) is voiced: PL/EN ship in the game,
## DE/FR/ES come with the voice packs (D-63); no clip = subtitle only (TTS inputs: contrib/voice/tts_inputs_after.json).

signal closed

const PENDING_KEY := "day_after/pending"
const SEEN_KEY := "day_after/seen"
## Only the last few finished jobs wait for their scene: a "day after" from many jobs ago reads oddly.
const PENDING_MAX := 3
const PLAYER := "locksmith"
const SCENE := "res://scenes/day_after.tscn"
const FADE_S := 0.15          # DESIGN 100-250 ms; none under reduce motion
const TAP_SLOP_PX := 12.0     # same as the dialogue player: farther = a drag, not a tap
const PORTRAIT_DP := 168.0
const PORTRAIT_LANDSCAPE_DP := 136.0
const Arrival := preload("res://scripts/ui/job_arrival.gd")

## tests: 0/1 forces reduce motion; -1 reads the setting
static var reduce_motion_override := -1

var job: Dictionary = {}
## D-85: the same presentation for a scene on the spot (job.wrong_floor opened unchecked: Mrs Teresa):
## its own lines, header and photo, and it does not touch the "day after" queue.
var custom_lines: Array[Dictionary] = []
var title_key: StringName = &"dayafter.title"
var backdrop_override := ""
var marks_seen := true
var lines: Array[Dictionary] = []   # {speaker, key, text}
var index := -1
var portrait_speaker := ""
var player: AudioStreamPlayer
var _done := false
var _press_pos := Vector2.INF

@onready var title_label: Label = $Frame/VBox/Header/Title
@onready var job_title_label: Label = $Frame/VBox/Header/JobTitle
@onready var body: BoxContainer = $Frame/VBox/Body
@onready var portrait_frame: PanelContainer = $Frame/VBox/Body/PortraitFrame
@onready var line_card: PanelContainer = $Frame/VBox/Body/Line
@onready var speaker_label: Label = $Frame/VBox/Body/Line/Col/Speaker
@onready var text_label: Label = $Frame/VBox/Body/Line/Col/Text
@onready var continue_button: Button = $Frame/VBox/ContinueButton


# --- queue (Save) -------------------------------------------------------------------------------

## The job's day-after lines that have a text: [{speaker, key, text}]. Empty = no scene.
static func lines_for(p_job: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var jid := String(p_job.get("id", ""))
	var after: Variant = p_job.get("after", [])
	if jid == "" or typeof(after) != TYPE_ARRAY:
		return out
	for i in (after as Array).size():
		var key := "%s.after.%d" % [jid, i + 1]
		if I18n.has_key(StringName(key)):
			out.append({"speaker": String(after[i]), "key": key, "text": I18n.t(StringName(key))})
	return out


static func seen(jid: String) -> bool:
	return (Save.get_value(SEEN_KEY, []) as Array).has(jid)


static func pending() -> Array:
	return (Save.get_value(PENDING_KEY, []) as Array).duplicate()


## Called when a job ends (JobRun.complete, refusal in job_verify). Jobs without `after` lines, tutorial
## and shift locks are ignored; a job already seen never comes back.
static func note_finished(p_job: Dictionary) -> void:
	var jid := String(p_job.get("id", ""))
	if lines_for(p_job).is_empty() or seen(jid):
		return
	var q := pending()
	q.erase(jid)
	q.append(jid)
	while q.size() > PENDING_MAX:
		q.pop_front()
	Save.set_value(PENDING_KEY, q)


## Newest pending job that still has lines and was not seen; drops stale entries on the way.
static func next_job() -> Dictionary:
	var q := pending()
	var changed := false
	var found: Dictionary = {}
	for i in range(q.size() - 1, -1, -1):
		var jid := String(q[i])
		var j: Dictionary = JobRun.job_by_id(jid) if not seen(jid) else {}
		if j.is_empty() or lines_for(j).is_empty():
			q.remove_at(i)
			changed = true
			continue
		found = j
		break
	if changed:
		Save.set_value(PENDING_KEY, q)
	return found


static func mark_seen(jid: String) -> void:
	var s: Array = (Save.get_value(SEEN_KEY, []) as Array).duplicate()
	if not s.has(jid):
		s.append(jid)
	Save.set_value(SEEN_KEY, s)
	var q := pending()
	q.erase(jid)
	Save.set_value(PENDING_KEY, q)


## Job list hook: opens the scene over `host` when a finished job waits for it. Returns the scene or null.
static func maybe_show(host: Control) -> DayAfter:
	var j := next_job()
	if j.is_empty():
		return null
	var da: DayAfter = load(SCENE).instantiate()
	da.job = j
	host.add_child(da)
	return da


## D-85: plays `p_lines` ([{speaker, key, text}]) over `host` in this presentation, now (not queued).
static func show_scene(host: Control, p_job: Dictionary, p_lines: Array[Dictionary], p_title: StringName, p_backdrop: String) -> DayAfter:
	var da: DayAfter = load(SCENE).instantiate()
	da.job = p_job
	da.custom_lines = p_lines
	da.title_key = p_title
	da.backdrop_override = p_backdrop
	da.marks_seen = false
	host.add_child(da)
	return da


# --- scene --------------------------------------------------------------------------------------

## Place photo for the next day (N-81): the landing of the job's arrival scene (by day when it has a day
## version, nobody at the door), else the G07 picture of the arrival itself: the G07 stairwells by day
## and by evening are different doors (12 and 7), so the time of the arrival wins over daylight.
static func backdrop_path(p_job: Dictionary) -> String:
	var still := ArrivalScene.place_still(p_job, "day", false)
	if not still.is_empty():
		return String(still[0])
	return "res://assets/ui/gpt/arrival/" + Arrival.g07_image(p_job)


func _reduce_motion() -> bool:
	if reduce_motion_override >= 0:
		return reduce_motion_override == 1
	return UiA11y.reduce_motion()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP   # the list underneath gets no taps while the scene is up
	var photo := backdrop_override if backdrop_override != "" and ResourceLoader.exists(backdrop_override) else backdrop_path(job)
	ScreenFrame.backdrop(self, photo, 0.6)
	ScreenFrame.fit(self, $Frame)
	player = AudioStreamPlayer.new()
	player.name = "VoicePlayer"
	player.bus = Sfx.voice_bus()
	add_child(player)
	lines = custom_lines if not custom_lines.is_empty() else lines_for(job)
	title_label.text = I18n.t(title_key)
	var title_key := String(job.get("i18n", {}).get("title", ""))
	job_title_label.text = I18n.t(StringName(title_key)) if title_key != "" else ""
	job_title_label.visible = job_title_label.text != ""
	ScreenFrame.wrap(speaker_label)
	ScreenFrame.wrap(text_label)
	continue_button.pressed.connect(advance)
	resized.connect(_layout)
	_layout()
	if not _reduce_motion():
		ScreenFrame.enter(self)
	advance()


func _exit_tree() -> void:
	if player != null and player.playing:
		player.stop()
		Sfx.duck_music_for_voice(false)


## Portrait above the line in portrait orientation; side by side in landscape (the column stays <= 640 dp).
func _layout() -> void:
	var vp := get_viewport_rect().size
	var landscape := vp.x > vp.y
	body.vertical = not landscape
	var side := PORTRAIT_LANDSCAPE_DP if landscape else PORTRAIT_DP
	side = minf(side, (vp.y if landscape else vp.x) * 0.42)
	for c in portrait_frame.get_children():
		(c as Control).custom_minimum_size = Vector2(side, side)
	portrait_frame.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN if landscape else Control.SIZE_SHRINK_CENTER


func is_finished() -> bool:
	return _done


## Next line; past the last one the scene closes.
func advance() -> void:
	if _done:
		return
	if player.playing:
		player.stop()
	if index + 1 >= lines.size():
		close()
		return
	index += 1
	_show(index)


func _show(i: int) -> void:
	var line: Dictionary = lines[i]
	var speaker := String(line["speaker"])
	var is_player := speaker == PLAYER
	# the locksmith (the player) is never shown: his line sits on the light enamel card, the client stays
	if not is_player and speaker != portrait_speaker:
		_set_portrait(speaker)
	portrait_frame.visible = portrait_speaker != ""
	line_card.theme_type_variation = &"EnamelPanel" if is_player else &""
	text_label.theme_type_variation = &"OnEnamel" if is_player else &""
	speaker_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if is_player else HORIZONTAL_ALIGNMENT_LEFT
	if is_player:
		speaker_label.add_theme_color_override("font_color", Color(0.32, 0.27, 0.22))
		speaker_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
	else:
		speaker_label.remove_theme_color_override("font_color")
		speaker_label.remove_theme_color_override("font_shadow_color")
	speaker_label.text = I18n.t(StringName("cast.%s.name" % speaker))
	text_label.text = String(line["text"])
	continue_button.text = I18n.t(&"dayafter.close") if i == lines.size() - 1 else I18n.t(&"common.continue")
	if not _reduce_motion() and is_inside_tree():
		line_card.modulate.a = 0.0
		create_tween().tween_property(line_card, "modulate:a", 1.0, FADE_S)
	_play_clip(String(line["key"]))


## Square photo for the big frame: the G09 cast portrait (the arrival avatar is a round cut-out, which
## sits oddly in a square frame), else whatever the arrival screen uses (episodic portrait), else null.
static func portrait_for(speaker: String) -> Texture2D:
	var slot := String(Arrival.CAST_SLOT.get(speaker, ""))
	var path := "res://assets/ui/gpt/cast/%s/portrait.jpg" % slot
	if slot != "" and ResourceLoader.exists(path):
		return load(path) as Texture2D
	return Arrival.portrait_for(speaker)


func _set_portrait(speaker: String) -> void:
	portrait_speaker = speaker
	for c in portrait_frame.get_children():
		portrait_frame.remove_child(c)
		c.queue_free()
	var tex := portrait_for(speaker)
	var node: Control
	if tex != null:
		var rect := TextureRect.new()
		rect.name = "Portrait"
		rect.texture = tex
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		node = rect
	else:
		node = Arrival.initial_plate(speaker, I18n.t(StringName("cast.%s.name" % speaker)))
		var initial: Label = node.get_node("Initial")
		initial.add_theme_font_size_override("font_size", 64)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait_frame.add_child(node)
	_layout()
	if not _reduce_motion() and is_inside_tree():
		node.modulate.a = 0.0
		create_tween().tween_property(node, "modulate:a", 1.0, FADE_S)


func _play_clip(key: String) -> void:
	var path := Sfx.line_clip_path(key, Settings.language())
	var stream: AudioStream = load(path) as AudioStream if path != "" else null
	if stream == null:
		Sfx.duck_music_for_voice(false)
		return
	if stream is AudioStreamOggVorbis:
		stream.loop = false
	player.stream = stream
	player.volume_db = Sfx.voice_volume_db()
	Sfx.duck_music_for_voice(true)
	player.play()


## Marks the job seen and removes the scene (short fade unless reduce motion).
func close() -> void:
	if _done:
		return
	_done = true
	if marks_seen:
		mark_seen(String(job.get("id", "")))
	if player.playing:
		player.stop()
	Sfx.duck_music_for_voice(false)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	continue_button.disabled = true
	closed.emit()
	if _reduce_motion() or not is_inside_tree():
		queue_free()
		return
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, FADE_S)
	tw.tween_callback(queue_free)


## A tap anywhere on the scene moves on (press + release within TAP_SLOP_PX).
func _gui_input(event: InputEvent) -> void:
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
			accept_event()
			advance()
