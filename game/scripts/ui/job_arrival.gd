extends Control
## Arrival + verification scene: client, situation, then the symbolic ID check
## (JOBS.md §2 — the game teaches that the locksmith always verifies the right to enter).
## N-60: every dialogue line is one row — 48 dp avatar, then the speaker's name
## (small, muted) above the line text (wraps) on a dark-paper underlay (>= 4.5:1).
## The locksmith (the player) has no avatar or plate: his lines sit on the right
## on a light enamel card, like the other side of a conversation.

const T := "Frame/VBox/Scroll/Body/"
const PLAYER := "locksmith"

@onready var title_label: Label = $Frame/VBox/Header/Title
@onready var client_label: Label = get_node(T + "Intro/Row/Texts/Client")
@onready var situation_label: Label = get_node(T + "Intro/Row/Texts/Situation")
@onready var place_plate: TextureRect = get_node(T + "Intro/Row/Place")
@onready var lines_box: VBoxContainer = get_node(T + "Lines")
@onready var verify_button: Button = $Frame/VBox/VerifyButton
@onready var back_button: Button = $Frame/VBox/Header/BackButton

# G07 arrival backgrounds: place + time of day -> image
const ARRIVAL_BG := {
	"apartment": {"day": "01_apartment_day.jpg", "evening": "02_apartment_evening.jpg", "night": "03_apartment_night_timer.jpg", "rainy": "04_apartment_rainy_evening.jpg"},
	"attic": {"": "05_attic.jpg"},
	"cellar": {"": "06_cellar.jpg"},
	"kiosk": {"": "07_kiosk_shutter.jpg"},
	"locker": {"": "08_changing_room_locker.jpg"},
	"gate": {"": "09_courtyard_gate.jpg"},
	"workshop": {"": "10_workshop_door.jpg"},
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
	initial.add_theme_font_override("font", load("res://assets/fonts/BonaNova-Bold.ttf"))
	initial.add_theme_font_size_override("font_size", 24)
	var light := colour != "ivory"
	initial.add_theme_color_override("font_color", Color(0.96, 0.92, 0.84) if light else Color(0.11, 0.09, 0.07))
	initial.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
	wrap.add_child(initial)
	return wrap


func _arrival_image(job: Dictionary) -> String:
	var place: String = job.get("place", "apartment")
	var time: String = job.get("time", "evening")
	var by_place: Dictionary = ARRIVAL_BG.get(place, ARRIVAL_BG["apartment"])
	return by_place.get(time, by_place.get("", "02_apartment_evening.jpg"))


func _add_background(job: Dictionary) -> void:
	ScreenFrame.backdrop(self, "res://assets/ui/gpt/arrival/" + _arrival_image(job), 0.45)
	var place: String = job.get("place", "apartment")
	var path := ""
	if place != "apartment":
		var signs: Array = PLACE_SIGN.get(place, [])
		if signs.size() == 2:
			path = "res://assets/ui/gpt/plates/" + signs[0 if _lang() == "pl" else 1]
	else:
		# apartment number plate (G01) from the job id
		var jid: String = job.get("id", "")
		path = "res://assets/ui/gpt/plates/plate_%02d.png" % ((jid.hash() % 24 + 24) % 24 + 1)
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
	Sfx.play_foley(&"door_knock")
	Sfx.play_foley(&"apartment_bell")
	ScreenFrame.fit(self, $Frame)
	$Frame/VBox/Scroll.scroll_deadzone = 12
	var job: Dictionary = JobRun.current_job
	_add_background(job)
	var i18n: Dictionary = job.get("i18n", {})
	title_label.text = I18n.t(i18n.get("title", &"jobs.title"))
	client_label.text = I18n.t(i18n.get("client", &"jobs.title"))
	situation_label.text = I18n.t(i18n.get("situation", &"jobs.title"))
	# dialog lines from CLIENTS.md
	var lines: Array = job.get("lines", [])
	var voiced := false
	for i in mini(lines.size(), 4):
		var speaker: String = lines[i]
		lines_box.add_child(_line_row(speaker, I18n.t(&"%s.line.%d" % [job.get("id", ""), i + 1])))
		if speaker != PLAYER and not voiced:
			Sfx.play_voice(speaker, &"greeting")  # S03 voice of the client
			voiced = true
	verify_button.text = I18n.t(&"job.verify")
	back_button.text = "‹ " + I18n.t(&"common.back")
	verify_button.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/job_verify.tscn"))
	back_button.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/jobs_list.tscn"))
	ScreenFrame.enter($Frame/VBox/Scroll)
	ScreenFrame.wire_sounds(self)  # S05 enamel-plate sounds
