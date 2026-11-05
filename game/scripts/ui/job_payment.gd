extends Control
## Payment + note after the lock opens (JOBS.md §3): coins as a diegetic counter
## on the receipt, then progress is saved (JobRun.complete).

@onready var result_label: Label = $VBox/Result
@onready var reward_label: Label = $VBox/Reward
@onready var continue_button: Button = $VBox/ContinueButton


func _ready() -> void:
	var job: Dictionary = JobRun.current_job
	result_label.text = I18n.t(&"job.opened")
	reward_label.text = I18n.t(&"job.reward_fmt").format({"n": int(job.get("reward_coins", 0))})
	continue_button.text = I18n.t(&"common.continue")
	continue_button.pressed.connect(func() -> void:
		JobRun.complete()
		get_tree().change_scene_to_file("res://scenes/jobs_list.tscn"))
