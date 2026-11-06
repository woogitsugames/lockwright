class_name RunState
extends RefCounted
## N-64: state of the endless run (Tryb Ciągły, PROGRESSION §2). It lives outside run_loop.tscn,
## because that scene is reloaded after every lock (Events routes back to it), which used to
## reset the lock counter each time and the run never progressed.

const LIVES := 3
const COINS_PER_TIER := 10

static var n := 0  # locks finished in this run (opened or broken)
static var opened := 0
static var breaks_in_row := 0  # rubber band: -1 tier after 2 breaks in a row
static var lives := LIVES
static var coins := 0  # earned in this run
static var finished := false


static func reset() -> void:
	n = 0
	opened = 0
	breaks_in_row = 0
	lives = LIVES
	coins = 0
	finished = false


## progression.json tier_curve: 1 + 1.2*ln(1+k)*skill, rubber band -1 after 2 breaks in a row.
static func tier_for(k: int) -> int:
	var skill := 1.0
	var t := 1.0 + 1.2 * log(1.0 + k) * skill
	if breaks_in_row >= 2:
		t -= 1.0
	return clampi(int(t), 1, 6)


## The job dictionary of the next lock in the run (family rotates through the ready ones).
static func next_job() -> Dictionary:
	var tier := tier_for(n)
	var families: Array = JobRun.PHOTOREAL_READY.duplicate()  # N-63: never the placeholder view
	if JobRun.planb_ready(&"lever_detector") and not families.has(&"lever_detector"):
		families.append(&"lever_detector")  # joins when its 5-lever assets land (JobRun.planb_ready)
	var fam: StringName = families[n % families.size()]
	return {"id": "run.%d" % n, "family": String(fam), "tier": tier, "reward_coins": COINS_PER_TIER * tier, "i18n": {}}


## Called once per lock of the run when it ends (Events: lock_opened / lock_failed).
static func lock_finished(was_opened: bool, reward: int) -> void:
	if finished:
		return
	n += 1
	if was_opened:
		opened += 1
		breaks_in_row = 0
		coins += reward
		Save.set_value("coins", Save.get_value("coins", 0) + reward)
		Save.set_value("stats/locks_opened", Save.get_value("stats/locks_opened", 0) + 1)
	else:
		breaks_in_row += 1
		lives -= 1
		Save.set_value("stats/locks_broken", Save.get_value("stats/locks_broken", 0) + 1)
		if lives <= 0:
			finished = true
			Save.set_value("stats/runs_finished", Save.get_value("stats/runs_finished", 0) + 1)
