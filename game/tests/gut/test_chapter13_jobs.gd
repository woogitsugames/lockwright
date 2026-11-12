extends GutTest
## D-111 (chapter 13 "Spring Cleaning", spec docs/handoff/gpt10/PACZKA-GPT10.md G10A): ten jobs after the
## chapter 12 finale. Data integrity, the limits of the spec, texts in five languages, cards that say what
## the people say (D-104), arrival places borrowed from existing scenes (D-91/D-110, no new renders) and
## the subtitle-only path while the lines are not recorded (`voice_pending`, contrib/voice/PENDING.md).
## The chapter is self-contained: every file and text key of it carries "ch13" (it can move to a content pack).

const LANGS := ["en", "pl", "de", "fr", "es"]
const CHAPTER := 13
const FAMILIES := ["pin_tumbler", "warded", "wafer", "lever", "lever_detector", "dial_safe", "combo", "magnetic", "dimple",
	"disc_detainer", "egyptian", "time_lock", "axial_slider"]
const PLACES := ["apartment", "gate", "cellar", "locker", "workshop", "kiosk", "attic", "yard", "museum"]
const TIMES := ["day", "evening", "night"]
const CARDS := ["id", "lease", "manager", "witness", "institution", "invoice", "receipt", "deed", "inheritance", "resolution",
	"letter", "photo", "address_app"]
## Tiers each lockcore family really has (lockcore/src/families/*: min_tier/max_tier; `replay_tool record` says
## "<family> has tiers a..b"). The game clamps a job's tier silently, so a tier outside the range would promise
## a harder lock than the one played, and it stopped the QA career's feel/clumsy profiles.
const LOCKCORE_TIERS := {"pin_tumbler": [2, 7], "warded": [1, 2], "wafer": [1, 3], "lever": [3, 5], "lever_detector": [5, 6],
	"dial_safe": [1, 3], "combo": [1, 4], "magnetic": [1, 2], "dimple": [1, 3], "disc_detainer": [1, 3], "egyptian": [1, 2],
	"time_lock": [1, 2], "axial_slider": [1, 3]}
const LIMITS := {"title": 32, "client": 40, "situation": 140}
const LINE_LIMIT := 160
const Verify := preload("res://scripts/ui/job_verify.gd")
const JobArrival := preload("res://scripts/ui/job_arrival.gd")
const ARRIVAL := "res://scenes/job_arrival.tscn"

var _save_backup: Dictionary
var _locale := ""
var _rows := {}


func before_all() -> void:
	_save_backup = Save.data.duplicate(true)
	_locale = TranslationServer.get_locale()
	for r in (I18n._parse_csv("res://i18n/content.csv") as Array).slice(1):
		_rows[String(r[0])] = r


func after_each() -> void:
	TranslationServer.set_locale(_locale)
	JobArrival.reduce_motion_override = -1
	JobRun.current_job = {}


func after_all() -> void:
	Save.data = _save_backup
	Save.save()


func _all_jobs() -> Array:
	var out := []
	for f in DirAccess.get_files_at("res://data/jobs"):
		if f.ends_with(".json"):
			out.append(JSON.parse_string(FileAccess.get_file_as_string("res://data/jobs/" + f)))
	return out


func _chapter_jobs() -> Array:
	var out := _all_jobs().filter(func(j: Dictionary) -> bool: return int(j.get("chapter", 0)) == CHAPTER)
	var list_script: GDScript = load("res://scripts/ui/jobs_list.gd")
	out.sort_custom(list_script.job_before)
	return out


## Every language of a content key, non-empty; [] when the row is missing.
func _texts(key: String) -> Array:
	var row: PackedStringArray = _rows.get(key, PackedStringArray())
	if row.size() != 1 + LANGS.size():
		return []
	var out := []
	for i in range(1, row.size()):
		out.append(String(row[i]))
	return out


func test_career_has_93_jobs_in_13_chapters() -> void:
	var per_chapter := {}
	for j: Dictionary in _all_jobs():
		var ch := int(j.get("chapter", 0))
		per_chapter[ch] = int(per_chapter.get(ch, 0)) + 1
	assert_eq(_all_jobs().size(), 93, "83 jobs of chapters 1-12 + 10 of chapter 13")
	assert_eq(per_chapter.size(), 13, "chapters 1-13")
	assert_eq(int(per_chapter.get(CHAPTER, 0)), 10)
	for ch in range(1, 14):
		assert_gt(int(per_chapter.get(ch, 0)), 0, "chapter %d has jobs" % ch)
	assert_true(I18n.has_key(&"chapter.13.name") and I18n.has_key(&"chapter.13.desc"))
	assert_eq(_texts("chapter.13.name").size(), LANGS.size())
	assert_eq(_texts("chapter.13.desc").size(), LANGS.size())


func test_ten_jobs_follow_the_spec() -> void:
	var jobs := _chapter_jobs()
	assert_eq(jobs.size(), 10)
	var families := {}
	var refusals := 0
	var orders := []
	for j: Dictionary in jobs:
		var jid := String(j["id"])
		assert_true(jid.contains("ch13_"), "%s: the chapter's files are identifiable" % jid)
		assert_true(FileAccess.file_exists("res://data/jobs/%s.json" % jid), "%s: file named after the id" % jid)
		for field in ["district", "family", "tier", "verification", "verify_kind", "reward_coins", "tone", "i18n", "lines",
				"after", "cards", "threshold", "place", "time"]:
			assert_true(j.has(field), "%s.%s" % [jid, field])
		orders.append(int(j.get("order", 0)))
		var fam := String(j["family"])
		assert_has(FAMILIES, fam, jid)
		assert_true(JobRun.is_playable(j), "%s (%s) is hidden on the list" % [jid, fam])
		families[fam] = int(families.get(fam, 0)) + 1
		assert_between(int(j["tier"]), 2, 4, "%s tier" % jid)
		var tiers: Array = LOCKCORE_TIERS[fam]
		assert_between(int(j["tier"]), int(tiers[0]), int(tiers[1]), "%s: a tier lockcore has for %s" % [jid, fam])
		assert_has(PLACES, String(j["place"]), jid)
		assert_has(TIMES, String(j["time"]), jid)
		assert_has(JobRun.VERIFY_KINDS, String(j["verify_kind"]), jid)
		assert_eq(JobRun.outcome_for(j), &"open", jid)
		var lines: Array = j["lines"]
		assert_between(lines.size(), 2, 4, "%s speakers" % jid)
		assert_has(lines, "locksmith", "%s: the locksmith speaks" % jid)
		assert_eq((j["after"] as Array).size(), DayAfter.lines_for(j).size(), "%s: a text for every after speaker" % jid)
		for sp: String in lines + (j["after"] as Array):
			assert_true(I18n.has_key(StringName("cast.%s.name" % sp)), "cast.%s.name" % sp)
		var cards: Array = j["cards"]
		assert_gt(cards.size(), 0, jid)
		for c: String in cards:
			assert_has(CARDS, c, jid)
		for c: String in (j.get("card_detail", {}) as Dictionary):
			assert_has(cards, c, "%s: card_detail for a card on the table" % jid)
		if Verify.is_refusal_job(j):
			refusals += 1
			assert_eq(int(j["reward_coins"]), 0, "%s: a refusal pays nothing" % jid)
			assert_eq(cards, ["id"], "%s: nobody vouches for the client in a refusal (D-104)" % jid)
			assert_eq((j["after"] as Array).size(), 2, "%s: the day after shows the lawful way worked" % jid)
		else:
			assert_between(int(j["reward_coins"]), 100, 220, "%s reward" % jid)
	assert_eq(orders, range(1, 11), "order 1..10 inside the chapter")
	assert_gte(refusals, 2, "at least two refusals")
	for fam: String in families:
		assert_lte(int(families[fam]), 2, "at most two jobs with %s" % fam)
	assert_gte(families.size(), 8, "families are mixed")


func test_texts_in_five_languages_within_limits() -> void:
	for j: Dictionary in _chapter_jobs():
		var jid := String(j["id"])
		var keys := {}
		for part: String in LIMITS:
			keys["%s.%s" % [jid, part]] = int(LIMITS[part])
		for i in (j["lines"] as Array).size():
			keys["%s.line.%d" % [jid, i + 1]] = LINE_LIMIT
		for i in (j["after"] as Array).size():
			keys["%s.after.%d" % [jid, i + 1]] = LINE_LIMIT
		for c: String in (j.get("card_detail", {}) as Dictionary):
			var d: Dictionary = j["card_detail"][c]
			for k in ["ask", "reply"]:
				if d.has(k):
					assert_eq(String(d[k]), "%s.%s.%s" % [jid, c, k], "%s: own exchange key" % jid)
					keys[String(d[k])] = LINE_LIMIT
		for key: String in keys:
			var texts := _texts(key)
			assert_eq(texts.size(), LANGS.size(), key)
			for i in texts.size():
				var text := String(texts[i])
				assert_ne(text.strip_edges(), "", "%s/%s" % [key, LANGS[i]])
				assert_lte(text.length(), int(keys[key]), "%s/%s is %d characters" % [key, LANGS[i], text.length()])
				assert_false(text.contains("!"), "%s/%s: no exclamation marks (CLIENTS.md §1)" % [key, LANGS[i]])
		# the refusal is said in the locksmith's own words, the same in every job (CLIENTS.md §4.2)
		if Verify.is_refusal_job(j):
			var last := _texts("%s.line.%d" % [jid, (j["lines"] as Array).size()])
			assert_eq(String((j["lines"] as Array).back()), "locksmith", jid)
			assert_true(String(last[1]).begins_with("Tu nie otworzę."), "%s PL" % jid)
			assert_true(String(last[0]).begins_with("I can't open this one."), "%s EN" % jid)
	# no text of the chapter lives outside it: every "ch13" key belongs to one of its jobs
	var ids := _chapter_jobs().map(func(j: Dictionary) -> String: return String(j["id"]))
	for key: String in _rows:
		if key.contains("ch13"):
			assert_true(ids.any(func(id: String) -> bool: return key.begins_with(id + ".")), "%s has a job" % key)


## D-104: each card on the table answers with words that are true for this job, in every language.
func test_every_card_has_an_exchange_and_a_prop() -> void:
	for j: Dictionary in _chapter_jobs():
		var jid := String(j["id"])
		for c: String in j["cards"]:
			assert_ne(String(Verify.card_prop_spec(jid, c)["kind"]), "default", "%s/%s has its own prop" % [jid, c])
			for lang: String in LANGS:
				TranslationServer.set_locale(lang)
				for taps in 2:
					var text := Verify.exchange_text(jid, c, taps)
					assert_true(text.begins_with("— ") and text.contains("\n— "), "%s/%s/%s exchange %d" % [jid, c, lang, taps])
		TranslationServer.set_locale(_locale)
		var detail: Dictionary = j.get("card_detail", {})
		# a witness is a named person of the dialogue, a manager's letter says who issued it and why
		if (j["cards"] as Array).has("witness"):
			assert_true((detail.get("witness", {}) as Dictionary).has("ask"), "%s: the witness has the job's own exchange" % jid)
		if (j["cards"] as Array).has("manager"):
			var m: Dictionary = detail.get("manager", {})
			assert_has(Verify.MANAGER_ISSUERS, String(m.get("issuer", "")), jid)
			assert_has(Verify.MANAGER_PURPOSES, String(m.get("purpose", "")), jid)
		if (j["cards"] as Array).has("id"):
			var id: Dictionary = detail.get("id", {})
			assert_eq(id.get("exchange", []), [1.0], "%s: no 'name by the door' for a thing" % jid)
			assert_ne(String(id.get("holder", "")), "", jid)
		for c: String in j["cards"]:
			var spec := Verify.card_prop_spec(jid, c)
			if String(spec["kind"]) == "paper":
				var paper: PaperProp = Verify.paper_for(j, c, String(spec["style"]))
				assert_not_null(paper, "%s/%s paper" % [jid, c])
				paper.free()


## No new renders: a job happens either at a place that already has a scene (`arrival_from`) or at the
## G07 still of its place. The borrowed scene exists and gives a still for verification and the day after.
func test_arrival_places_reuse_existing_scenes() -> void:
	var scenes: Dictionary = ArrivalScene.data().get("scenes", {})
	var borrowed := 0
	for j: Dictionary in _chapter_jobs():
		var jid := String(j["id"])
		assert_false(scenes.has(jid), "%s has no scene of its own" % jid)
		var from := String(j.get("arrival_from", ""))
		if from == "":
			assert_true(ResourceLoader.exists("res://assets/ui/gpt/arrival/" + JobArrival.g07_image(j)), "%s G07 still" % jid)
			continue
		borrowed += 1
		assert_true(scenes.has(from), "%s: %s is a scene" % [jid, from])
		assert_false(JobRun.job_by_id(from).is_empty(), "%s: %s is a job" % [jid, from])
		var still := ArrivalScene.place_still(j)
		assert_eq(still.size(), 2, "%s shows the place of %s" % [jid, from])
		if still.size() == 2:
			assert_true(ResourceLoader.exists(String(still[0])), "%s plate" % jid)
		assert_eq(ArrivalScene.place_still(j, "day", false).size(), 2, "%s: the day after has the place too" % jid)
	assert_gte(borrowed, 5, "places that match an existing scene use it")


## D-100 / D-111: the chapter has no recordings yet. `voice_pending` says so in the data; such a job has no
## clip in any language, and the arrival and the "day after" run on subtitles alone.
func test_voice_pending_jobs_play_subtitle_only() -> void:
	var pending := 0
	for j: Dictionary in _all_jobs():
		var jid := String(j["id"])
		var keys := []
		for i in (j.get("lines", []) as Array).size():
			keys.append("%s.line.%d" % [jid, i + 1])
		for i in (j.get("after", []) as Array).size():
			keys.append("%s.after.%d" % [jid, i + 1])
		var clips := 0
		for key: String in keys:
			if ResourceLoader.exists("%s/en/%s.ogg" % [Sfx.LINES_ROOT, key]):
				clips += 1
		if bool(j.get("voice_pending", false)):
			pending += 1
			assert_eq(clips, 0, "%s is recorded: remove voice_pending (and its rows in contrib/voice/PENDING.md)" % jid)
		else:
			assert_eq(clips, keys.size(), "%s: every line has its EN clip, or the job says voice_pending" % jid)
	assert_eq(pending, 10, "only chapter 13 waits for its recordings")
	# arrival: every line is on the screen at once, nothing waits for a clip
	var job: Dictionary = _chapter_jobs()[0]
	JobArrival.reduce_motion_override = 1
	JobRun.start(job)
	var vp := SubViewport.new()
	vp.size = Vector2i(412, 915)
	vp.disable_3d = true
	add_child_autofree(vp)
	var arrival: Control = load(ARRIVAL).instantiate()
	vp.add_child(arrival)
	await wait_process_frames(3)
	assert_not_null(arrival.dialogue)
	assert_false(arrival.dialogue.has_any_clip(), "no clips")
	assert_true(arrival.dialogue.is_finished(), "the dialogue does not wait")
	assert_eq(arrival.lines_box.get_child_count(), (job["lines"] as Array).size(), "every line is shown")
	assert_true(arrival.verify_button.visible and not arrival.verify_button.disabled, "the player can go on to the check")
	# day after: the line shows, no stream
	var host := Control.new()
	host.size = Vector2(412, 915)
	add_child_autofree(host)
	var scene := DayAfter.show_scene(host, job, DayAfter.lines_for(job), &"dayafter.title", "")
	await wait_process_frames(2)
	assert_not_null(scene)
	if scene != null:
		assert_eq(scene.text_label.text, I18n.t(StringName("%s.after.1" % job["id"])))
		assert_false(scene.player.playing, "subtitle only")
		scene.close()


## Both refusals: opening is not offered, refusing closes the job once with +5 reputation and queues
## the day after; a normal job of the chapter pays its reward and a tip for a clean opening.
func test_refusal_and_payment_paths() -> void:
	for j: Dictionary in _chapter_jobs():
		var jid := String(j["id"])
		if not Verify.is_refusal_job(j):
			continue
		Save.set_value("jobs_refused", [])
		Save.set_value("reputation", 10)
		Save.set_value(DayAfter.PENDING_KEY, [])
		Save.set_value(DayAfter.SEEN_KEY, [])
		JobRun.start(j)
		var vp := SubViewport.new()
		vp.size = Vector2i(412, 915)
		vp.disable_3d = true
		add_child_autofree(vp)
		var v: Control = load("res://scenes/job_verify.tscn").instantiate()
		var went := []
		v.go_override = func(p: String) -> void: went.append(p)
		v.decision_pause_s = 0.0
		vp.add_child(v)
		await wait_process_frames(2)
		assert_false(v.accept_button.visible, "%s: opening is not an option" % jid)
		assert_eq(Array(v.card_names()), ["id"], jid)
		v.refuse_button.pressed.emit()
		await wait_process_frames(2)
		assert_true((Save.get_value("jobs_refused", []) as Array).has(jid), jid)
		assert_eq(int(Save.get_value("reputation", 0)), 15, "%s: +5 reputation" % jid)
		assert_eq(DayAfter.pending(), [jid], "%s: its day after waits" % jid)
		assert_eq(went, ["res://scenes/jobs_list.tscn"], jid)
	var paid: Dictionary = JobRun.job_by_id("job.ch13_10_courtyard_door")
	Save.set_value("coins", 0)
	Save.set_value("jobs_completed", [])
	JobRun.start(paid)
	JobRun.complete()
	assert_eq(int(Save.get_value("coins", 0)), 250, "200 coins + 25% tip for a clean opening")
	assert_true((Save.get_value("jobs_completed", []) as Array).has("job.ch13_10_courtyard_door"))
	assert_eq(Furnishings.reached_chapter(), 13, "the career reaches chapter 13")
