extends Control
## Arrival + verification scene: client, situation, then the symbolic ID check
## (JOBS.md §2 — the game teaches that the locksmith always verifies the right to enter).

@onready var title_label: Label = $VBox/Title
@onready var client_label: Label = $VBox/Client
@onready var situation_label: Label = $VBox/Situation
@onready var lines_box: VBoxContainer = $VBox/Lines
@onready var verify_button: Button = $VBox/VerifyButton
@onready var back_button: Button = $BackButton


func _ready() -> void:
	SafeArea.apply(self)
	var job: Dictionary = JobRun.current_job
	var i18n: Dictionary = job.get("i18n", {})
	title_label.text = I18n.t(i18n.get("title", &"jobs.title"))
	client_label.text = I18n.t(i18n.get("client", &"jobs.title"))
	situation_label.text = I18n.t(i18n.get("situation", &"jobs.title"))
	# dialog lines from CLIENTS.md: speaker name on an enamel plate + the line
	var lines: Array = job.get("lines", [])
	for i in mini(lines.size(), 4):
		var speaker: String = lines[i]
		var row := HBoxContainer.new()
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
	verify_button.text = I18n.t(&"job.verify")
	back_button.text = I18n.t(&"common.back")
	verify_button.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/job_verify.tscn"))
	back_button.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/jobs_list.tscn"))
