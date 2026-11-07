extends GutTest
## N-76: the verification screen — framed (16 dp + safe-area margins, Back in the header), cards as
## props, the JOBS.md §2.2 "I need one more thing" decision, job.wrong_floor settled by asking, and
## a line when a normal job is declined.

const SCENE := "res://scenes/job_verify.tscn"
const LANGS := ["en", "pl", "de", "fr", "es"]

var _save_backup: Dictionary
var _went: Array = []


func before_each() -> void:
	_save_backup = Save.data.duplicate(true)
	_went = []


func after_each() -> void:
	JobRun.current_job = {}
	Save.data = _save_backup
	Save.save()


func _open(job_id: String) -> Control:
	JobRun.start(JobRun.job_by_id(job_id))
	var vp := SubViewport.new()
	vp.size = Vector2i(412, 915)
	add_child_autofree(vp)
	var v: Control = load(SCENE).instantiate()
	v.go_override = func(path: String) -> void: _went.append(path)
	v.decision_pause_s = 0.0
	vp.add_child(v)
	await get_tree().process_frame
	await get_tree().process_frame
	return v


func _job_with_cards(n: int) -> String:
	for f in DirAccess.get_files_at("res://data/jobs"):
		if not f.ends_with(".json"):
			continue
		var j := JobRun.job_by_id(f.get_basename())
		if j.get("cards", []).size() == n and not String(j.get("id", "")).begins_with("job.refuse") and not j.has("ask_more"):
			return String(j["id"])
	return ""


func test_layout_has_margins_and_bottom_actions() -> void:
	var v := await _open("job.wrong_floor")
	var back: Button = v.back_button
	var r := back.get_global_rect()
	assert_gte(r.position.x, 16.0, "Back keeps the 16 dp side margin (was flush with the left edge)")
	assert_lt(r.position.y, 915.0 * 0.2, "Back sits in the header")
	for b in [v.accept_button, v.ask_more_button, v.refuse_button]:
		var br: Rect2 = b.get_global_rect()
		assert_gte(br.size.y, 48.0, "%s >= 48 dp" % b.name)
		assert_gte(br.position.y, 915.0 * 0.6, "%s in the bottom 40%% (DESIGN §2)" % b.name)
		assert_lte(br.end.x, 412.0 - 16.0 + 0.5, "%s inside the right margin" % b.name)
	assert_eq(v.title_label.text, I18n.t(&"verify.title"))
	assert_eq(v.job_label.text, I18n.t(&"job.wrong_floor.title"), "the job title is shown under the screen title")
	assert_eq(v.card_names(), PackedStringArray(["id"]))
	var tile: Button = v.cards_box.get_child(0)
	assert_gte(tile.get_global_rect().size.y, 120.0, "the card is a prop picture, not a text chip")


func test_ask_more_lays_out_the_next_card() -> void:
	var jid := _job_with_cards(3)
	assert_ne(jid, "", "a job with three cards exists")
	var v := await _open(jid)
	assert_eq(v.card_names().size(), 2, "the client shows two cards first")
	assert_false(v.ask_more_button.disabled)
	v.ask_more_button.pressed.emit()
	await get_tree().process_frame
	assert_eq(v.card_names().size(), 3, "asking for more lays out the third card (was unreachable)")
	assert_true(v.result_panel.visible, "the locksmith asks about the new card")
	assert_true(v.ask_more_button.disabled, "nothing more to show")
	assert_eq(_went, [], "no scene change")


func test_ask_more_without_cards_left_says_so() -> void:
	var jid := _job_with_cards(1)
	assert_ne(jid, "", "a one-card job without ask_more exists")
	var v := await _open(jid)
	assert_true(v.ask_more_button.disabled, "one card, nothing more and no resolution: disabled")


func test_wrong_floor_is_settled_by_asking() -> void:
	Save.set_value("reputation", 10)
	var v := await _open("job.wrong_floor")
	assert_false(v.ask_more_button.disabled, "wrong_floor offers 'I need one more thing' (job data)")
	v.ask_more_button.pressed.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	assert_eq(int(Save.get_value("reputation", 0)), 14, "+4 reputation (JOBS.md job.wrong_floor)")
	assert_string_contains(v.result_label.text, I18n.t(&"job.wrong_floor.ask_more.reply"))
	assert_eq(_went, ["res://scenes/job_payment.tscn"], "paid as a visit, no lock scene")
	assert_true(JobRun.is_talk(JobRun.current_job), "settled by talking")
	assert_eq(String(JobRun.current_job.get("id")), "job.wrong_floor")


func test_declining_a_normal_job_gives_feedback() -> void:
	var v := await _open("job.wrong_floor")
	v.refuse_button.pressed.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	assert_eq(v.result_label.text, I18n.t(&"verify.declined"), "a line says the call stays on the list")
	assert_eq(_went, ["res://scenes/jobs_list.tscn"])
	assert_false((Save.get_value("jobs_refused", []) as Array).has("job.wrong_floor"), "a normal job is not closed")


func test_new_texts_in_all_languages() -> void:
	for key in [&"verify.more_card", &"verify.no_more", &"verify.asked_rep", &"verify.declined",
			&"job.wrong_floor.ask_more.ask", &"job.wrong_floor.ask_more.reply", &"pause.dark_mode_off"]:
		assert_true(I18n.has_key(key), String(key))
	var seen := {}
	for path in ["res://i18n/strings.csv", "res://i18n/content.csv"]:
		var rows: Array = I18n._parse_csv(path)
		for r in rows.slice(1):
			seen[String(r[0])] = r
	for key in ["verify.more_card", "verify.no_more", "verify.asked_rep", "verify.declined",
			"job.wrong_floor.ask_more.ask", "job.wrong_floor.ask_more.reply", "pause.dark_mode_off"]:
		var row: PackedStringArray = seen.get(key, PackedStringArray())
		assert_eq(row.size(), 1 + LANGS.size(), key)
		for i in range(1, row.size()):
			assert_ne(String(row[i]).strip_edges(), "", "%s/%s" % [key, LANGS[i - 1]])
	assert_string_contains(I18n.t(&"verify.asked_rep") % 4, "4")
