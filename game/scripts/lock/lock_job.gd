extends "res://scripts/photoreal/lock_photoreal.gd"
## N-14: thin wrapper over the photoreal lock screen (session A's scene). Feeds it the
## active job's family/seed/tier from JobRun instead of the @export defaults, so every
## pin_tumbler job and the tutorial play their own lock. Dev/CI --lw-* args still win
## inside the parent _ready() only when passed on the command line.

func _ready() -> void:
	if not JobRun.current_job.is_empty():
		var fam := JobRun.family_for(JobRun.current_job)
		family = fam if fam != &"" else &"pin_tumbler"
		seed = JobRun.seed_for(JobRun.current_job)
		tier = JobRun.tier_for(JobRun.current_job)
	super._ready()
	# task 7: quality profile drives the plan-B plate (SubViewport) size + MSAA
	_apply_quality()
	Quality.profile_changed.connect(func(_p: Dictionary) -> void: _apply_quality())


func _apply_quality() -> void:
	msaa = Quality.msaa_index()
	if view and view.viewport:
		view.viewport.size = Quality.planb_size(Vector2i(824, 1100))
