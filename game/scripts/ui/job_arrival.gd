extends Control
## Arrival + verification scene: client, situation, then the symbolic ID check
## (JOBS.md §2 — the game teaches that the locksmith always verifies the right to enter).

@onready var title_label: Label = $VBox/Title
@onready var client_label: Label = $VBox/Client
@onready var situation_label: Label = $VBox/Situation
@onready var lines_box: VBoxContainer = $VBox/Lines
@onready var verify_button: Button = $VBox/VerifyButton
@onready var back_button: Button = $BackButton

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


func _lang() -> String:
	return "pl" if Settings.language() == "pl" else "en"


func _arrival_image(job: Dictionary) -> String:
	var place: String = job.get("place", "apartment")
	var time: String = job.get("time", "evening")
	var by_place: Dictionary = ARRIVAL_BG.get(place, ARRIVAL_BG["apartment"])
	return by_place.get(time, by_place.get("", "02_apartment_evening.jpg"))


func _add_background(job: Dictionary) -> void:
	var tex := load("res://assets/ui/gpt/arrival/" + _arrival_image(job))
	if tex == null:
		return
	var bg := TextureRect.new()
	bg.texture = tex
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.modulate = Color(1, 1, 1, 0.35)
	add_child(bg)
	move_child(bg, 0)
	var place: String = job.get("place", "apartment")
	if place != "apartment":
		var signs: Array = PLACE_SIGN.get(place, [])
		if signs.size() == 2:
			_add_plate("res://assets/ui/gpt/plates/" + signs[0 if _lang() == "pl" else 1])
	else:
		# apartment number plate (G01) from the job id
		var jid: String = job.get("id", "")
		var n: int = (jid.hash() % 24 + 24) % 24 + 1
		_add_plate("res://assets/ui/gpt/plates/plate_%02d.png" % n)


func _add_plate(path: String) -> void:
	var tex := load(path)
	if tex == null:
		return
	var plate := TextureRect.new()
	plate.texture = tex
	plate.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	plate.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	plate.custom_minimum_size = Vector2(96, 96)
	plate.position = Vector2(12, 12)
	plate.size = Vector2(96, 96)
	add_child(plate)


func _ready() -> void:
	Sfx.play_ambience(&"stairwell")
	Sfx.play_music(&"main_theme")
	Sfx.play_foley(&"door_knock")
	Sfx.play_foley(&"apartment_bell")
	SafeArea.apply(self)
	var job: Dictionary = JobRun.current_job
	_add_background(job)
	var i18n: Dictionary = job.get("i18n", {})
	title_label.text = I18n.t(i18n.get("title", &"jobs.title"))
	client_label.text = I18n.t(i18n.get("client", &"jobs.title"))
	situation_label.text = I18n.t(i18n.get("situation", &"jobs.title"))
	# dialog lines from CLIENTS.md: speaker avatar (G09) + enamel plate + the line
	var lines: Array = job.get("lines", [])
	for i in mini(lines.size(), 4):
		var speaker: String = lines[i]
		var row := HBoxContainer.new()
		var slot: String = CAST_SLOT.get(speaker, "")
		if slot != "":
			var avatar := TextureRect.new()
			var atex := load("res://assets/ui/gpt/cast/%s/avatar.png" % slot)
			if atex != null:
				avatar.texture = atex
				avatar.custom_minimum_size = Vector2(48, 48)
				avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
				row.add_child(avatar)
		var plate := Label.new()
		plate.text = I18n.t(&"cast.%s.name" % speaker)
		plate.custom_minimum_size = Vector2(120, 48)
		var line := Label.new()
		line.text = I18n.t(&"%s.line.%d" % [job.get("id", ""), i + 1])
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(plate)
		row.add_child(line)
		lines_box.add_child(row)
		Sfx.play_voice(speaker, &"greeting")  # S03 voice at the dialog line
	verify_button.text = I18n.t(&"job.verify")
	back_button.text = I18n.t(&"common.back")
	verify_button.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/job_verify.tscn"))
	back_button.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/jobs_list.tscn"))
