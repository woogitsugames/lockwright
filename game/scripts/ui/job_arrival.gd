extends Control
## Arrival + verification scene: client, situation, then the symbolic ID check
## (JOBS.md §2 — the game teaches that the locksmith always verifies the right to enter).

@onready var title_label: Label = $VBox/Title
@onready var client_label: Label = $VBox/Client
@onready var situation_label: Label = $VBox/Situation
@onready var verify_button: Button = $VBox/VerifyButton
@onready var back_button: Button = $BackButton


func _ready() -> void:
	var job: Dictionary = JobRun.current_job
	var i18n: Dictionary = job.get("i18n", {})
	title_label.text = I18n.t(i18n.get("title", &"jobs.title"))
	client_label.text = I18n.t(i18n.get("client", &"jobs.title"))
	situation_label.text = I18n.t(i18n.get("situation", &"jobs.title"))
	verify_button.text = I18n.t(&"job.verify")
	back_button.text = I18n.t(&"common.back")
	verify_button.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/job_verify.tscn"))
	back_button.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/jobs_list.tscn"))
