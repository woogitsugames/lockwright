extends GutTest
## N-76: the verification screen — framed (16 dp + safe-area margins, Back in the header), cards as
## props, the JOBS.md §2.2 "I need one more thing" decision, job.wrong_floor settled by asking, and
## a line when a normal job is declined; D-85: accepting wrong_floor unchecked = the wrong door.

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


## VA-08: landscape used to hide the cards under the decisions in a scrolled strip and clip the title.
func test_va08_layout_portrait_and_landscape() -> void:
	JobRun.start(JobRun.job_by_id("job.grandma_broth"))
	for size in [Vector2i(412, 915), Vector2i(360, 800), Vector2i(915, 412), Vector2i(892, 412)]:
		var vp := SubViewport.new()
		vp.size = size
		add_child_autofree(vp)
		var v: Control = load(SCENE).instantiate()
		v.go_override = func(path: String) -> void: _went.append(path)
		vp.add_child(v)
		for i in 3:
			await get_tree().process_frame
		var tag := "%dx%d" % [size.x, size.y]
		var land: bool = size.x > size.y
		assert_eq(v.is_landscape(), land, tag)
		var buttons: Array = [v.accept_button, v.ask_more_button, v.refuse_button]
		for b in buttons:
			var br: Rect2 = b.get_global_rect()
			assert_gte(br.size.y, 48.0, tag + " %s >= 48 dp" % b.name)
			assert_gte(br.position.y, size.y * 0.6 - 0.5, tag + " %s in the bottom 40%%" % b.name)
			assert_lte(br.end.y, size.y + 0.5, tag + " %s on screen" % b.name)
		if land:
			assert_almost_eq(buttons[0].get_global_rect().position.y, buttons[2].get_global_rect().position.y, 0.5, tag + " decisions in one row")
		# the cards are whole on screen above the decisions (not hidden in the scroll), >= 96 dp pictures
		var top_of_actions: float = buttons[0].get_global_rect().position.y
		for c in v.cards_box.get_children():
			var cr: Rect2 = (c as Control).get_global_rect()
			assert_lte(cr.end.y, top_of_actions + 0.5, tag + " card %s above the decisions" % c.name)
			assert_gte(cr.position.y, 0.0, tag + " card on screen")
			assert_gte((c.get_node("Box/Pic") as Control).size.y, 95.5, tag + " card picture")
		# the title fits its label (one or two lines), no clipping
		var t: Label = v.title_label
		assert_lte(t.get_global_rect().position.y + t.get_combined_minimum_size().y, top_of_actions, tag + " title above")
		assert_true(t.get_line_count() <= 2, tag + " title in <= 2 lines")
		assert_gte(t.get_global_rect().position.y, 0.0, tag + " title not clipped at the top")
		if not land:
			# portrait: the photo shows under the header, the table sits on the decisions
			var intro: Control = v.job_label.get_parent().get_parent()
			assert_gt(intro.get_global_rect().position.y, size.y * 0.2, tag + " the door photo shows above the table")
	JobRun.current_job = {}


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
	Save.set_value("jobs_completed", [])  # N-91: the +4 is for the first time only
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


## D-85 (JOBS.md job.wrong_floor): "Przyjmij" without checking the flat number opens the neighbour's
## door: no lock, -25 reputation, the scene with Mrs Teresa in the "day after" presentation, no coins,
## the job leaves the list and its thank-you "day after" never comes.
func test_wrong_floor_accept_unchecked_is_the_wrong_door() -> void:
	Save.set_value("reputation", 40)
	Save.set_value("coins", 7)
	Save.set_value(DayAfter.PENDING_KEY, [])
	Save.set_value("jobs_wrong_open", [])
	Save.set_value("jobs_completed", [])
	var v := await _open("job.wrong_floor")
	assert_false(v.accept_button.disabled)
	v.accept_button.pressed.emit()
	await get_tree().process_frame
	assert_eq(int(Save.get_value("reputation", 0)), 15, "-25 reputation")
	assert_eq(int(Save.get_value("coins", 0)), 7, "no coins")
	assert_false(_went.has(JobRun.lock_scene_path()), "no lock scene")
	var da: DayAfter = v.wrong_scene
	assert_not_null(da, "the wrong-door scene is shown")
	assert_eq(da.title_label.text, I18n.t(&"wrongopen.title"))
	assert_eq(da.portrait_speaker, "teresa", "Mrs Teresa's portrait")
	assert_eq(da.text_label.text, I18n.t(&"job.wrong_floor.wrong_open.1"))
	assert_eq(da.lines.size(), 3)
	assert_eq(String(da.lines[1]["speaker"]), "locksmith")
	assert_true(v.accept_button.disabled and v.refuse_button.disabled and v.ask_more_button.disabled, "decided")
	assert_eq(_went, [], "the scene plays before anything else")
	for i in 3:
		da.advance()
	await get_tree().process_frame
	await get_tree().process_frame
	assert_true(da.is_finished())
	assert_eq(v.result_label.text, I18n.t(&"verify.lost_rep") % 25)
	assert_eq(_went, ["res://scenes/jobs_list.tscn"], "back to the list, not to the lock or payment")
	assert_true((Save.get_value("jobs_wrong_open", []) as Array).has("job.wrong_floor"), "the job is closed")
	assert_true(DayAfter.seen("job.wrong_floor"), "the cake for not opening never comes")
	assert_false(DayAfter.pending().has("job.wrong_floor"))
	assert_false((Save.get_value("jobs_completed", []) as Array).has("job.wrong_floor"), "not a completed job")
	assert_true(JobRun.current_job.is_empty())
	# the penalty is once per job and reputation does not go below zero
	Save.set_value("reputation", 10)
	var v2 := await _open("job.wrong_floor")
	v2.accept_button.pressed.emit()
	await get_tree().process_frame
	assert_eq(int(Save.get_value("reputation", 0)), 10, "no second penalty")
	Save.set_value("jobs_wrong_open", [])
	var v3 := await _open("job.wrong_floor")
	v3.accept_button.pressed.emit()
	await get_tree().process_frame
	assert_eq(int(Save.get_value("reputation", 0)), 0, "reputation stays >= 0")


func test_wrong_open_jobs_leave_the_list() -> void:
	Save.set_value("jobs_completed", [])  # N-91: a job finished honestly before stays on the list
	Save.set_value("jobs_wrong_open", ["job.wrong_floor"])
	Save.set_value(DayAfter.PENDING_KEY, [])
	var vp := SubViewport.new()
	vp.size = Vector2i(412, 915)
	add_child_autofree(vp)
	var list: Control = load("res://scenes/jobs_list.tscn").instantiate()
	vp.add_child(list)
	await get_tree().process_frame
	var title := I18n.t(&"job.wrong_floor.title")
	for b in list.find_children("*", "Button", true, false):
		assert_false((b as Button).text.begins_with(title), "job.wrong_floor is not on the list")


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
			&"job.wrong_floor.ask_more.ask", &"job.wrong_floor.ask_more.reply", &"pause.dark_mode_off",
			&"wrongopen.title", &"verify.lost_rep", &"job.wrong_floor.wrong_open.1",
			&"job.wrong_floor.wrong_open.2", &"job.wrong_floor.wrong_open.3"]:
		assert_true(I18n.has_key(key), String(key))
	var seen := {}
	for path in ["res://i18n/strings.csv", "res://i18n/content.csv"]:
		var rows: Array = I18n._parse_csv(path)
		for r in rows.slice(1):
			seen[String(r[0])] = r
	for key in ["verify.more_card", "verify.no_more", "verify.asked_rep", "verify.declined",
			"job.wrong_floor.ask_more.ask", "job.wrong_floor.ask_more.reply", "pause.dark_mode_off",
			"wrongopen.title", "verify.lost_rep", "job.wrong_floor.wrong_open.1",
			"job.wrong_floor.wrong_open.2", "job.wrong_floor.wrong_open.3"]:
		var row: PackedStringArray = seen.get(key, PackedStringArray())
		assert_eq(row.size(), 1 + LANGS.size(), key)
		for i in range(1, row.size()):
			assert_ne(String(row[i]).strip_edges(), "", "%s/%s" % [key, LANGS[i - 1]])
	assert_string_contains(I18n.t(&"verify.asked_rep") % 4, "4")
