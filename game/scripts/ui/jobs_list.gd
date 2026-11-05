extends Control
## Job list (Tryb Zleceń): all jobs from game/data/jobs/*.json, grouped by chapter.

@onready var list: VBoxContainer = $VBox/Scroll/VBox/JobsList
@onready var back_button: Button = $BackButton

const JOBS_DIR := "res://data/jobs"


func _ready() -> void:
	SafeArea.apply(self)
	$VBox/Title.text = I18n.t(&"jobs.title")
	back_button.text = I18n.t(&"common.back")
	back_button.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	var completed: Array = Save.get_value("jobs_completed", [])
	var jobs: Array = []
	for path in DirAccess.get_files_at(JOBS_DIR):
		if path.ends_with(".json"):
			jobs.append(JSON.parse_string(FileAccess.get_file_as_string(JOBS_DIR + "/" + path)))
	jobs.sort_custom(func(a, b): return str(int(a.get("chapter", 9))) + a.get("id", "") < str(int(b.get("chapter", 9))) + b.get("id", ""))
	for job in jobs:
		if not JobRun.is_playable(job):
			continue  # N-05: hide jobs whose family is not implemented in lockcore
		var row := HBoxContainer.new()
		var b := Button.new()
		b.text = I18n.t(job.get("i18n", {}).get("title", &"jobs.title"))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size = Vector2(0, 48)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var jid: String = job.get("id", "")
		if completed.has(jid):
			b.text = "✓ " + b.text
		b.pressed.connect(func() -> void:
			JobRun.start(job)
			get_tree().change_scene_to_file("res://scenes/job_arrival.tscn"))
		row.add_child(b)
		list.add_child(row)
