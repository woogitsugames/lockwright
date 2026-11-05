extends Control
## Payment + note after the lock opens (JOBS.md §3): coins as a diegetic counter
## on the receipt, then progress is saved (JobRun.complete).

@onready var result_label: Label = $VBox/Result
@onready var reward_label: Label = $VBox/Reward
@onready var tip_label: Label = $VBox/Tip
@onready var continue_button: Button = $VBox/ContinueButton


func _ready() -> void:
	SafeArea.apply(self)
	var job: Dictionary = JobRun.current_job
	result_label.text = I18n.t(&"job.opened")
	reward_label.text = I18n.t(&"job.reward_fmt").format({"n": int(job.get("reward_coins", 0))})
	if JobRun.last_tip > 0:  # N-25: tip for a clean opening (JOBS.md §3)
		tip_label.text = I18n.t(&"job.tip_fmt").format({"n": JobRun.last_tip})
	else:
		tip_label.text = ""
	_play_reward_sequence()  # audio/v2 rewards: door_open -> thanks -> coins (mix README)


func _play_reward_sequence() -> void:
	Sfx.play_reward(&"door_open")
	await get_tree().create_timer(1.4).timeout
	Sfx.play_reward(&"thanks")
	await get_tree().create_timer(1.2).timeout
	Sfx.play_reward(&"coins")
	continue_button.text = I18n.t(&"common.continue")
	continue_button.pressed.connect(func() -> void:
		JobRun.complete()
		get_tree().change_scene_to_file("res://scenes/jobs_list.tscn"))
