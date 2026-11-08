extends Control
## Arrival + verification scene: client, situation, then the symbolic ID check
## (JOBS.md §2 — the game teaches that the locksmith always verifies the right to enter).
## N-60: every dialogue line is one row — 48 dp avatar, then the speaker's name
## (small, muted) above the line text (wraps) on a dark-paper underlay (>= 4.5:1).
## The locksmith (the player) has no avatar or plate: his lines sit on the right
## on a light enamel card, like the other side of a conversation.

const T := "Frame/VBox/Scroll/Body/"
const PLAYER := "locksmith"
const DialoguePlayer := preload("res://scripts/ui/dialogue_player.gd")
const MAX_LINES := 4

@onready var title_label: Label = $Frame/VBox/Header/Title
@onready var client_label: Label = get_node(T + "Intro/Row/Texts/Client")
@onready var situation_label: Label = get_node(T + "Intro/Row/Texts/Situation")
@onready var place_plate: TextureRect = get_node(T + "Intro/Row/Place")
@onready var lines_box: VBoxContainer = get_node(T + "Lines")
@onready var verify_button: Button = $Frame/VBox/VerifyButton
@onready var back_button: Button = $Frame/VBox/Header/BackButton
@onready var skip_all_button: Button = $Frame/VBox/Header/SkipAllButton
@onready var scroll: ScrollContainer = $Frame/VBox/Scroll

var dialogue: Node  # DialoguePlayer (D-57)
var scene: ArrivalScene  # D-58 arrival scene (jobs listed in data/arrival_scenes.json), else null
## tests: force reduce motion / screen reader for the scene (-1 = settings / DisplayServer)
static var reduce_motion_override := -1

# G07 arrival backgrounds: place + time of day -> image
const ARRIVAL_BG := {
	"apartment": {"day": "01_apartment_day.jpg", "evening": "02_apartment_evening.jpg", "night": "03_apartment_night_timer.jpg", "rainy": "04_apartment_rainy_evening.jpg"},
	"attic": {"": "05_attic.jpg"},
	"cellar": {"": "06_cellar.jpg"},
	"kiosk": {"": "07_kiosk_shutter.jpg"},
	"locker": {"": "08_changing_room_locker.jpg"},
	"gate": {"": "09_courtyard_gate.jpg"},
	"workshop": {"": "10_workshop_door.jpg"},
	# N-81: places without their own G07 still borrow the closest one, without a room sign
	"yard": {"": "09_courtyard_gate.jpg"},      # under the block (bike stand)
	"museum": {"": "06_cellar.jpg"},            # the museum's vault room below ground
}
# G01 room signs per place, PL/EN by game language
const PLACE_SIGN := {
	"attic": ["plate_sign_strych_pl.png", "plate_sign_attic_en.png"],
	"cellar": ["plate_sign_piwnica_pl.png", "plate_sign_cellar_en.png"],
	"locker": ["plate_sign_pralnia_pl.png", "plate_sign_laundry_en.png"],
	"workshop": ["plate_sign_warsztat_slusarski_pl.png", "plate_sign_locksmith_workshop_en.png"],
	"gate": ["plate_sign_administracja_pl.png", "plate_sign_administration_en.png"],
}
# G09 cast slots per dialog speaker (docs/CLIENTS.md zacznik B)
const CAST_SLOT := {
	"halina": "01_halina", "zosia": "02_zosia", "stefan": "03_stefan", "roman": "04_roman",
	"lena": "05_lena", "marta": "06_marta", "zuzanna": "07_zuzanna", "edek": "08_edek",
	"ola": "09_ola_krystyna", "krystyna": "09_ola_krystyna", "wladyslaw": "10_wladyslaw",
	"rygiel": "11_rygiel", "jadwiga": "12_jadwiga",
}
# G17 blank enamel initial plates; light letters except on ivory
const INITIAL_PLATES := ["navy", "bottle_green", "burgundy", "ivory"]


func _lang() -> String:
	return "pl" if Settings.language() == "pl" else "en"


static func _tex(path: String) -> Texture2D:
	return load(path) as Texture2D if ResourceLoader.exists(path) else null


## Avatar for a speaker: G09 cast avatar, then the episodic portrait, else null.
static func portrait_for(speaker: String) -> Texture2D:
	var slot: String = CAST_SLOT.get(speaker, "")
	var tex: Texture2D = null
	if slot != "":
		tex = _tex("res://assets/ui/gpt/cast/%s/avatar.png" % slot)
	if tex == null:
		tex = _tex("res://assets/ui/gpt/cast/episodic/portrait_%s.webp" % speaker)
	return tex


# D-50/N-49/N-60: blank G17 enamel plate with the speaker's initial (no printed digit)
static func initial_plate(speaker: String, full_name: String) -> Control:
	var wrap := Control.new()
	wrap.name = "InitialPlate"
	wrap.custom_minimum_size = Vector2(48, 48)
	var colour: String = INITIAL_PLATES[absi(speaker.hash()) % INITIAL_PLATES.size()]
	var plate := TextureRect.new()
	plate.texture = _tex("res://assets/ui/plates/initial_%s.png" % colour)
	plate.set_anchors_preset(Control.PRESET_FULL_RECT)
	plate.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	plate.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	wrap.add_child(plate)
	var initial := Label.new()
	initial.name = "Initial"
	initial.text = full_name.strip_edges().substr(0, 1).to_upper()
	initial.set_anchors_preset(Control.PRESET_FULL_RECT)
	initial.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	initial.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	initial.add_theme_font_override("font", load("res://theme/title_font.tres"))
	initial.add_theme_font_size_override("font_size", 24)
	var light := colour != "ivory"
	initial.add_theme_color_override("font_color", Color(0.96, 0.92, 0.84) if light else Color(0.11, 0.09, 0.07))
	initial.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
	wrap.add_child(initial)
	return wrap


## G07 still of the job's place (file name) for its time of day, or `p_time` when given and the place has it.
static func g07_image(job: Dictionary, p_time := "") -> String:
	var place: String = job.get("place", "apartment")
	var time: String = p_time if p_time != "" else String(job.get("time", "evening"))
	var by_place: Dictionary = ARRIVAL_BG.get(place, ARRIVAL_BG["apartment"])
	return by_place.get(time, by_place.get(String(job.get("time", "")), by_place.get("", "02_apartment_evening.jpg")))


func _arrival_image(job: Dictionary) -> String:
	return g07_image(job)


## N-81: the door number painted in each G07 stairwell photo; the G01 plate beside the title shows the
## same number (it was a hash of the job id: plate 13 in front of door 5).
const G07_DOOR := {"01_apartment_day.jpg": 12, "02_apartment_evening.jpg": 7, "03_apartment_night_timer.jpg": 5, "04_apartment_rainy_evening.jpg": 9}


## N-81: the place behind a job screen. The arrival scene's own landing when the job has one (or names one
## with `arrival_from`), else the G07 still of its place. `with_figure`: the client stands at the door as
## at the arrival (verification); without (the day after) the landing is empty. Returns the backdrop.
static func place_backdrop(root: Control, job: Dictionary, shade: float, p_time := "", with_figure := true) -> TextureRect:
	var still := ArrivalScene.place_still(job, p_time, with_figure)
	if still.is_empty():
		return ScreenFrame.backdrop(root, "res://assets/ui/gpt/arrival/" + g07_image(job, p_time), shade)
	var bg := ScreenFrame.backdrop(root, String(still[0]), shade)
	if String(still[1]) != "" and ResourceLoader.exists(String(still[1])):
		var fig := TextureRect.new()  # the figure layer is image-sized like the plate: same cover crop
		fig.name = "Figure"
		fig.texture = load(String(still[1]))
		fig.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		fig.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		fig.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fig.set_anchors_preset(Control.PRESET_FULL_RECT)
		bg.add_child(fig)
	return bg


## The G01 plate beside the title: the room sign of a non-flat place, the flat's number (the one in the
## photo, or the job's `door` when the place has no number in the picture), or "" (scene: the door is
## in the picture).
static func plate_path(job: Dictionary, lang: String) -> String:
	var place: String = job.get("place", "apartment")
	if place != "apartment":
		var signs: Array = PLACE_SIGN.get(place, [])
		return "res://assets/ui/gpt/plates/" + signs[0 if lang == "pl" else 1] if signs.size() == 2 else ""
	var door := int(job.get("door", G07_DOOR.get(g07_image(job), 0)))
	return "res://assets/ui/gpt/plates/plate_%02d.png" % door if door >= 1 and door <= 24 else ""


func _add_background(job: Dictionary) -> void:
	var bg := place_backdrop(self, job, 0.45)
	var path := "" if bg.texture != null and not ArrivalScene.place_still(job).is_empty() else plate_path(job, _lang())
	place_plate.texture = _tex(path)
	place_plate.visible = place_plate.texture != null


func _line_row(speaker: String, text: String) -> Control:
	var is_player := speaker == PLAYER
	var row := HBoxContainer.new()
	row.name = "Line_" + speaker
	row.set_meta("speaker", speaker)
	row.add_theme_constant_override("separation", 10)
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_stretch_ratio = 5.0
	if is_player:
		card.theme_type_variation = &"EnamelPanel"
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 2)
	card.add_child(col)
	var who := ScreenFrame.wrap(Label.new())
	who.name = "Speaker"
	who.text = I18n.t(&"cast.%s.name" % speaker)
	who.theme_type_variation = &"Caption"
	var said := ScreenFrame.wrap(Label.new())
	said.name = "Text"
	said.text = text
	if is_player:
		who.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		who.add_theme_color_override("font_color", Color(0.32, 0.27, 0.22))
		who.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
		said.theme_type_variation = &"OnEnamel"
		# indent from the left, no avatar (the player is never shown)
		var gap := Control.new()
		gap.custom_minimum_size = Vector2(40, 0)
		gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		gap.size_flags_stretch_ratio = 1.0
		row.add_child(gap)
	else:
		var avatar_tex := portrait_for(speaker)
		if avatar_tex != null:
			var avatar := TextureRect.new()
			avatar.name = "Avatar"
			avatar.texture = avatar_tex
			avatar.custom_minimum_size = Vector2(48, 48)
			avatar.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
			avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			row.add_child(avatar)
		else:
			var plate := initial_plate(speaker, who.text)
			plate.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
			row.add_child(plate)
	col.add_child(who)
	col.add_child(said)
	row.add_child(card)
	return row


func _ready() -> void:
	Sfx.play_ambience(&"stairwell")
	Sfx.play_music(&"main_theme")
	ScreenFrame.fit(self, $Frame)
	$Frame/VBox/Scroll.scroll_deadzone = 12
	var job: Dictionary = JobRun.current_job
	var scene_cfg := ArrivalScene.resolve(job)
	if scene_cfg.is_empty():
		_knock()
		_add_background(job)
	else:
		_add_scene(scene_cfg)
	var i18n: Dictionary = job.get("i18n", {})
	title_label.text = I18n.t(i18n.get("title", &"jobs.title"))
	# VA-03: never "Vorstellungsg|espräch"; one line when it fits at >= 22, else two lines by words,
	# and the plates beside it keep their 48 dp height instead of stretching with a wrapped title
	ScreenFrame.fit_title(title_label)
	back_button.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	skip_all_button.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	client_label.text = I18n.t(i18n.get("client", &"jobs.title"))
	situation_label.text = I18n.t(i18n.get("situation", &"jobs.title"))
	_show_family(job)
	_setup_dialogue(job)
	verify_button.text = I18n.t(&"job.verify")
	back_button.text = "‹ " + I18n.t(&"common.back")
	verify_button.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/job_verify.tscn"))
	back_button.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/jobs_list.tscn"))
	ScreenFrame.wire_sounds(self)  # S05 enamel-plate sounds
	if scene == null:
		ScreenFrame.enter($Frame/VBox/Scroll)
		dialogue.start()
	else:
		dialogue.line_started.connect(func(i: int, _voiced: bool) -> void:
			var ls: Array = job.get("lines", [])
			if i < ls.size():
				scene.show_speaker(String(ls[i])))
		scene.climb_finished.connect(_on_climb_finished, CONNECT_ONE_SHOT)
		scene.play()


func _knock() -> void:
	Sfx.play_foley(&"door_knock")
	Sfx.play_foley(&"apartment_bell")


func _scene_reduce_motion() -> bool:
	if reduce_motion_override >= 0:
		return reduce_motion_override == 1
	if UiA11y.reduce_motion():
		return true
	# a screen reader user gets the still frame and the text at once
	return UiA11y.screen_reader_active()  # AccessKit or the Android TalkBack bridge (D-97)


## D-58: the scene covers the screen (under the status bar too); the dialogue sits over its lower part
## (portrait) or on the right half (landscape), so the client at the door stays in view. The UI waits
## until the climb ends (or is tapped away).
func _add_scene(cfg: Dictionary) -> void:
	scene = ArrivalScene.new()
	add_child(scene)
	move_child(scene, 0)
	scene.setup(cfg, _scene_reduce_motion())
	place_plate.visible = false   # the door has its own number in the picture
	var vbox: VBoxContainer = $Frame/VBox
	var gap := Control.new()
	gap.name = "SceneGap"
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	gap.size_flags_stretch_ratio = 1.5
	vbox.add_child(gap)
	vbox.move_child(gap, 1)
	scroll.size_flags_stretch_ratio = 1.0
	$Frame.visible = false
	# flat dark band behind the header: the title stays >= 4.5:1 over a bright daytime wall
	var band := ColorRect.new()
	band.name = "HeaderBand"
	band.color = Color(0.06, 0.045, 0.035, 0.62)
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	band.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	add_child(band)
	move_child(band, 1)
	band.visible = false
	scene.climb_finished.connect(func() -> void: band.visible = true)
	var header: Control = $Frame/VBox/Header
	var fit_band := func() -> void:   # a title wrapped to two lines grows the band with it
		band.offset_bottom = ScreenFrame.insets(self).y + 8.0 + maxf(48.0, header.get_combined_minimum_size().y) + 8.0
	header.resized.connect(fit_band)
	var landscape := func() -> void:
		var vp := get_viewport_rect().size
		fit_band.call()
		gap.visible = vp.y >= vp.x
		band.offset_left = 0.0
		band.offset_right = 0.0
		if vp.x > vp.y:   # dialogue column on the side away from the figure, so the client stays clear
			var i := ScreenFrame.insets(self)
			var left := i.x + ScreenFrame.SIDE
			var right := i.z + ScreenFrame.SIDE
			var col := minf(ScreenFrame.MAX_COLUMN, vp.x * 0.5)
			if scene.figure_x() < 0.5:
				$Frame.add_theme_constant_override("margin_left", int(vp.x - right - col))
				$Frame.add_theme_constant_override("margin_right", int(right))
				band.offset_left = vp.x - right - col - 8.0
			else:
				$Frame.add_theme_constant_override("margin_left", int(left))
				$Frame.add_theme_constant_override("margin_right", int(vp.x - left - col))
				band.offset_right = -(vp.x - left - col - 8.0)
	landscape.call()
	resized.connect(landscape)
	scene.figure_changed.connect(landscape)


func _on_climb_finished() -> void:
	_knock()
	$Frame.visible = true
	ScreenFrame.enter($Frame)
	dialogue.start()


## T42: which lock waits behind the door, one small line under the situation (family.<id>.name and
## .short). Families without these texts (the older ones) show nothing.
func _show_family(job: Dictionary) -> void:
	var lbl: Label = get_node_or_null(T + "Intro/Row/Texts/Family")
	if lbl == null:
		return
	var fam := String(JobRun.family_for(job))
	var name_key := StringName("family.%s.name" % fam)
	var short_key := StringName("family.%s.short" % fam)
	lbl.visible = fam != "" and I18n.has_key(name_key) and I18n.has_key(short_key)
	if lbl.visible:
		lbl.text = "%s — %s" % [I18n.t(name_key), I18n.t(short_key)]


# D-57: dialogue lines from CLIENTS.md, spoken line by line with subtitles (DialoguePlayer).
func _setup_dialogue(job: Dictionary) -> void:
	var lines: Array = job.get("lines", [])
	var rows: Array = []
	var keys := PackedStringArray()
	var texts := PackedStringArray()
	for i in mini(lines.size(), MAX_LINES):
		var speaker: String = lines[i]
		var key := "%s.line.%d" % [job.get("id", ""), i + 1]
		var text := I18n.t(StringName(key))
		var row := _line_row(speaker, text)
		_pass_mouse(row)
		lines_box.add_child(row)
		rows.append(row)
		keys.append(key)
		texts.append(text)
	dialogue = DialoguePlayer.new()
	dialogue.name = "Dialogue"
	add_child(dialogue)
	dialogue.setup(rows, keys, texts)
	lines_box.mouse_filter = Control.MOUSE_FILTER_PASS
	lines_box.gui_input.connect(dialogue.on_gui_input)
	dialogue.line_started.connect(func(i: int, _voiced: bool) -> void:
		scroll.ensure_control_visible.call_deferred(rows[i]))
	if dialogue.has_any_clip():
		skip_all_button.visible = true
		skip_all_button.tooltip_text = I18n.t(&"dialogue.skip_all")
		if "accessibility_name" in skip_all_button:
			skip_all_button.set("accessibility_name", I18n.t(&"dialogue.skip_all"))
		skip_all_button.pressed.connect(dialogue.skip_all)
		dialogue.finished.connect(func() -> void: skip_all_button.visible = false)
	else:
		# no voiced line in this language: the S03 wordless greeting of the client stays
		for speaker in lines.slice(0, MAX_LINES):
			if speaker != PLAYER:
				Sfx.play_voice(StringName(speaker), &"greeting")
				break


static func _pass_mouse(n: Node) -> void:
	if n is Control:
		n.mouse_filter = Control.MOUSE_FILTER_PASS
	for c in n.get_children():
		_pass_mouse(c)
