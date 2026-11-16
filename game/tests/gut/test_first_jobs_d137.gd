extends GutTest
## D-137 (audit D-134, findings 10 and 11): the first jobs follow the tutorial.
##  - chapter 1 has an explicit order; its first lock is the tutorial's family (pin_tumbler) at the
##    family's lowest lockcore tier;
##  - a new family arrives one job at a time, and its first job is guided: a lesson file, or the
##    first-jobs coach (own lines, reduced chalk) for a family without one — wherever the job sits in
##    the career, not only during the first three jobs;
##  - job.cat_bathroom: the locksmith says no paperwork is needed, so the table is empty and the
##    screens say "go inside" / "nothing to check" (verify_kind "home").

const LANGS := ["en", "pl", "de", "fr", "es"]
const CHAPTER_1 := ["job.grandma_broth", "job.cat_bathroom", "job.student_dorm", "job.kiosk_shutter",
	"job.bike_interview", "job.refuse_ex_partner"]
const ARRIVAL := "res://scenes/job_arrival.tscn"
const VERIFY := "res://scenes/job_verify.tscn"
const ListScript := preload("res://scripts/ui/jobs_list.gd")
const VerifyScript := preload("res://scripts/ui/job_verify.gd")
const LockScript := preload("res://scripts/photoreal/lock_photoreal.gd")

var _save: Dictionary
var _auto := false
var _aid := false
var _locale := ""


func before_each() -> void:
	_save = Save.data.duplicate(true)
	_auto = bool(Settings.get_value(&"auto_tension", true))
	_aid = bool(Settings.get_value(&"reading_aid", false))
	Settings.set_value(&"reading_aid", false)
	_locale = TranslationServer.get_locale()
	for k in ["lessons", "jobs_completed", "verify"]:
		Save.data.erase(k)
	JobRun.mode = &"job"
	JobRun.current_job = {}


func after_each() -> void:
	Save.data = _save.duplicate(true)
	Save.save()
	Settings.set_value(&"auto_tension", _auto)
	Settings.set_value(&"reading_aid", _aid)
	TranslationServer.set_locale(_locale)
	JobRun.mode = &"job"
	JobRun.current_job = {}


func _career() -> Array:
	var out: Array = []
	for f in preload("res://tests/job_dirs.gd").files():
		if f.ends_with(".json"):
			out.append(JSON.parse_string(FileAccess.get_file_as_string(f)))
	out.sort_custom(ListScript.job_before)
	return out


static func _has_lock(job: Dictionary) -> bool:
	return not String(job["id"]).begins_with("job.refuse") and not JobRun.is_talk(job) \
			and not bool((job.get("ask_more", {}) as Dictionary).get("resolves", false))


func _tiers() -> Dictionary:
	# lockcore/tiers.json is outside res://; the test reads the checkout's file
	var path := ProjectSettings.globalize_path("res://").path_join("../lockcore/tiers.json")
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return (d as Dictionary).get("families", {}) if d is Dictionary else {}


func _open(scene_path: String, job_id: String) -> Control:
	JobRun.start(JobRun.job_by_id(job_id))
	var vp := SubViewport.new()
	vp.size = Vector2i(412, 915)
	add_child_autofree(vp)
	var s: Control = load(scene_path).instantiate()
	vp.add_child(s)
	for i in 3:
		await get_tree().process_frame
	return s


func _open_lock(job_id: String) -> Node:
	JobRun.start(JobRun.job_by_id(job_id))
	var vp := SubViewport.new()
	vp.size = Vector2i(412, 915)
	add_child_autofree(vp)
	var scene: Node = load(JobRun.lock_scene_path()).instantiate()
	vp.add_child(scene)
	await wait_physics_frames(3)
	scene.set_physics_process(false)
	scene.sampler.set_physics_process(false)
	return scene


# ------------------------------------------------------------------ order of chapter 1
func test_chapter_1_is_ordered_and_starts_with_the_tutorial_family() -> void:
	var ch1: Array = _career().filter(func(j: Dictionary) -> bool: return int(j["chapter"]) == 1)
	assert_eq(ch1.map(func(j: Dictionary) -> String: return j["id"]), CHAPTER_1)
	for i in ch1.size():
		assert_eq(int(ch1[i].get("order", 0)), i + 1, "%s: explicit order" % ch1[i]["id"])
	var first: Dictionary = ch1[0]
	assert_eq(JobRun.family_for(first), &"pin_tumbler", "the first job uses what the tutorial taught")
	var tiers := _tiers()
	if tiers.is_empty():
		pending("lockcore/tiers.json not readable from this build")
		return
	assert_eq(int(first["tier"]), int(tiers["pin_tumbler"]["min"]), "at the family's lowest tier")
	for j: Dictionary in ch1:
		var r: Dictionary = tiers[String(j["family"])]
		assert_between(int(j["tier"]), int(r["min"]), int(r["max"]), "%s tier in the family's range" % j["id"])
		if _has_lock(j):
			assert_eq(int(j["tier"]), int(r["min"]), "%s: chapter 1 stays on introductory tiers" % j["id"])


func test_the_refusal_comes_after_the_kiosk() -> void:
	# job.refuse_ex_partner.after.2 is Mr Stefan from the kiosk ("Heard it at the bus stop")
	assert_gt(CHAPTER_1.find("job.refuse_ex_partner"), CHAPTER_1.find("job.kiosk_shutter"))
	assert_eq((JobRun.job_by_id("job.refuse_ex_partner")["after"] as Array)[1], "stefan")


## Every lock job of chapters 1-2 brings at most one family the player has not met, and a new family
## never arrives twice in a row before the tutorial's family was used once.
func test_new_families_arrive_one_at_a_time_and_guided() -> void:
	var met := {&"pin_tumbler": true}  # the tutorial
	var first_lock := true
	for j: Dictionary in _career():
		if int(j["chapter"]) > 6 or not _has_lock(j):
			continue
		var fam := JobRun.family_for(j)
		if first_lock:
			assert_true(met.has(fam), "%s: the first lock of the career is a family the tutorial taught" % j["id"])
			first_lock = false
		if met.has(fam):
			continue
		met[fam] = true
		# guided: a lesson file, or the first-jobs coach of a family without one
		JobRun.start(j)
		assert_true(TutorialCoach.has_lesson_for(fam) or LockScript.family_intro_due(fam),
				"%s: the first %s job is guided" % [j["id"], fam])
	JobRun.current_job = {}


# ------------------------------------------------------------------ the family's first job is guided
func test_family_without_a_lesson_is_introduced_on_its_first_job_after_the_first_three() -> void:
	Settings.set_value(&"auto_tension", false)
	Save.set_value("jobs_completed", ["job.a", "job.b", "job.c", "job.d"])
	assert_false(TutorialCoach.family_met(&"wafer"))
	assert_true(TutorialCoach.family_met(&"pin_tumbler"), "the tutorial's family")
	assert_true(TutorialCoach.family_met(&"combo"), "a family with a lesson file has the lesson")
	var kiosk := await _open_lock("job.kiosk_shutter")
	assert_not_null(kiosk.coach, "the wafer coach is there on the family's first job")
	assert_eq(kiosk.coach.family, &"wafer")
	assert_eq(kiosk.view.chalk_level, ChalkLayer.Level.REDUCED)
	kiosk._note_lesson_open()
	assert_true(TutorialCoach.family_met(&"wafer"), "met once its lock opened")
	var shed := await _open_lock("job.allotment_shed")
	assert_null(shed.coach, "the next wafer job is the player's own")
	assert_eq(shed.view.chalk_level, ChalkLayer.Level.OFF)
	# the tutorial's family gets no second introduction
	var dorm := await _open_lock("job.student_dorm")
	assert_null(dorm.coach)


func test_warded_is_introduced_on_its_first_job_after_the_first_three() -> void:
	Save.set_value("jobs_completed", ["job.a", "job.b", "job.c", "job.d"])
	var cat := await _open_lock("job.cat_bathroom")
	assert_not_null(cat.coach, "the probe lines are there")
	assert_eq(cat.coach.family, &"warded")
	cat._note_lesson_open()
	var chest := await _open_lock("job.grandpa_chest")
	assert_true(chest.coach == null or chest.coach.caution_only or chest.coach.has_caution(),
			"no family lines again (only the D-120 tool caution of warded t2)")


func test_the_endless_shift_gets_no_family_intro() -> void:
	Save.set_value("jobs_completed", ["job.a", "job.b", "job.c", "job.d"])
	JobRun.mode = &"run"
	JobRun.current_job = {"id": "run.1", "family": "wafer", "tier": 1}
	assert_false(LockScript.family_intro_due(&"wafer"))
	JobRun.mode = &"job"
	JobRun.current_job = {}
	assert_false(LockScript.family_intro_due(&"wafer"), "no job: a dev scene")


# ------------------------------------------------------------------ the cat: nothing to check
func test_cat_bathroom_has_nothing_on_the_table() -> void:
	var job: Dictionary = JobRun.job_by_id("job.cat_bathroom")
	assert_eq(JobRun.verify_kind(job), "home")
	assert_eq((job["cards"] as Array).size(), 0, "the locksmith says: no paperwork this time")
	assert_false(job.has("card_detail"))
	TranslationServer.set_locale("pl")
	var a := await _open(ARRIVAL, "job.cat_bathroom")
	assert_eq(a.verify_button.text, "Wejdź do środka")
	var v := await _open(VERIFY, "job.cat_bathroom")
	v.go_override = func(_p: String) -> void: pass
	assert_eq(v.title_label.text, "U klienta w domu")
	assert_eq(v.hint_label.text, "Tu nie ma czego sprawdzać. Ty decydujesz.")
	assert_eq(v.cards_box.get_child_count(), 0, "no identity card on the table")
	assert_true(v.ask_more_button.disabled, "nothing more to ask for")
	assert_true(v.accept_button.visible and not v.accept_button.disabled, "the door can be opened")
	assert_true(v.refuse_button.visible)
	# the tap hint of D-134 is not spent on a table without cards
	assert_eq(VerifyScript.hint_key(JobRun.job_by_id("job.grandma_broth")), &"verify.hint_tap")
	for lang in LANGS:
		TranslationServer.set_locale(lang)
		for key: StringName in [&"job.verify.home", &"verify.title.home", &"verify.hint.home"]:
			assert_true(I18n.has_key(key), "%s/%s" % [key, lang])
			assert_ne(I18n.t(key).strip_edges(), "", "%s/%s" % [key, lang])
		assert_false(I18n.has_key(&"job.cat_bathroom.id.ask"), "the identity-card exchange is gone (%s)" % lang)


func test_only_the_cat_has_an_empty_table() -> void:
	for j: Dictionary in _career():
		var empty: bool = (j.get("cards", ["id"]) as Array).is_empty()
		assert_eq(empty, JobRun.verify_kind(j) == "home", "%s: no cards <=> verify_kind home" % j["id"])
