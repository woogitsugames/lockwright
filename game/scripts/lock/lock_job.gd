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
	# task 7 / N-65: quality profile drives the plan-B section resolution scale + MSAA
	_apply_quality()
	Quality.profile_changed.connect(func(_p: Dictionary) -> void: _apply_quality())
	_show_family_hint()
	LockPreload.release()  # perf 2026-11-08: the warmed-up resources now belong to this screen


# T42: the D-59 families show one chalk hint (what each thumb does) during the first jobs.
const HINT_FAMILIES := [&"dial_safe", &"combo", &"dimple", &"disc_detainer", &"egyptian",
	&"axial_slider", &"time_lock", &"magnetic"]
## Older key names kept (they predate T42); the rest is lock.<family>_hint.
const HINT_KEY_ALIASES := {&"dial_safe": "lock.dial_hint", &"combo": "lock.combo_hint",
	&"disc_detainer": "lock.disc_hint"}
const HINT_JOBS := 6  # completed jobs after which the hint is no longer shown


## Hint key for a family ("" when it has none); `auto` picks the "_auto" variant (the game holds
## the left thumb, Napięcie automatyczne) when that key exists.
static func family_hint_key(fam: StringName, auto: bool) -> String:
	if not HINT_FAMILIES.has(fam):
		return ""
	var key: String = HINT_KEY_ALIASES.get(fam, "lock.%s_hint" % fam)
	if auto and I18n.has_key(StringName(key + "_auto")):
		return key + "_auto"
	return key if I18n.has_key(StringName(key)) else ""


func _show_family_hint() -> void:
	if view == null or not view.has_method("set_hint"):
		return
	var key := family_hint_key(family, sampler != null and sampler.auto_tension)
	if key == "":
		return
	var done: int = (Save.get_value("jobs_completed", []) as Array).size()
	view.call("set_hint", I18n.t(StringName(key)) if done < HINT_JOBS else "")


func _apply_quality() -> void:
	# N-65: the section viewport follows the on-screen pixel size (view._layout) scaled by the
	# profile; never a fixed 824×1100 stretched over a large screen
	if view:
		view.msaa = Quality.msaa_index()
		view.render_scale = float(Quality.current.get("planb_scale", 1.0))
