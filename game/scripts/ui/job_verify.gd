extends Control
## Symbolic verification of the right to enter (JOBS.md §2): cards with confidence
## values; the player decides. Refusal on a suspicious job gives reputation, not coins.

@onready var cards_label: Label = $VBox/Cards
@onready var accept_button: Button = $VBox/AcceptButton
@onready var refuse_button: Button = $VBox/RefuseButton
@onready var back_button: Button = $BackButton


func _ready() -> void:
	var job: Dictionary = JobRun.current_job
	var i18n: Dictionary = job.get("i18n", {})
	$VBox/Title.text = I18n.t(i18n.get("title", &"jobs.title"))
	cards_label.text = job.get("verification", "")
	accept_button.text = I18n.t(&"job.accept")
	refuse_button.text = I18n.t(&"job.refuse")
	back_button.text = I18n.t(&"common.back")
	accept_button.pressed.connect(_start_lock)
	refuse_button.pressed.connect(_refuse)
	back_button.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/job_arrival.tscn"))


func _start_lock() -> void:
	# map the job onto a lockcore family + tier and enter the lock scene
	get_tree().change_scene_to_file("res://scenes/lock.tscn")


func _refuse() -> void:
	# refusal on a "refuse" job: +5 reputation, back to the list (JOBS.md §5)
	var jid: String = JobRun.current_job.get("id", "")
	if jid.begins_with("job.refuse"):
		Save.set_value("reputation", Save.get_value("reputation", 0) + 5)
	JobRun.current_job = {}
	get_tree().change_scene_to_file("res://scenes/jobs_list.tscn")
