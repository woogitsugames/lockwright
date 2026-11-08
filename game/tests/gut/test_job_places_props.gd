extends GutTest
## N-80: every verification card type used by a job has its own prop (no default Halina note, no
## Lockwright receipt for a client's receipt); N-81: the job screens after the arrival show the arrival's
## own landing and the G01 plate shows the photo's door number; N-91: a finished job played again changes
## no reputation; N-85: "Exit" from a job's pause goes to the job list, which opens at that job.

const SCENE := "res://scenes/job_verify.tscn"
const LANGS := ["en", "pl", "de", "fr", "es"]
const Arrival := preload("res://scripts/ui/job_arrival.gd")
const Verify := preload("res://scripts/ui/job_verify.gd")

var _save_backup: Dictionary
var _went: Array = []


func before_each() -> void:
	_save_backup = Save.data.duplicate(true)
	_went = []


func after_each() -> void:
	JobRun.current_job = {}
	Save.data = _save_backup
	Save.save()


func _jobs() -> Array:
	var out := []
	for f in DirAccess.get_files_at("res://data/jobs"):
		if f.ends_with(".json"):
			out.append(JobRun.job_by_id(f.get_basename()))
	return out


func _open(job_id: String, size := Vector2i(412, 915)) -> Control:
	JobRun.start(JobRun.job_by_id(job_id))
	var vp := SubViewport.new()
	vp.size = size
	add_child_autofree(vp)
	var v: Control = load(SCENE).instantiate()
	v.go_override = func(path: String) -> void: _went.append(path)
	v.decision_pause_s = 0.0
	vp.add_child(v)
	await get_tree().process_frame
	await get_tree().process_frame
	return v


# ------------------------------------------------------------------ N-80
func test_every_card_type_has_its_own_prop() -> void:
	var seen := {}
	for j: Dictionary in _jobs():
		var jid := String(j["id"])
		for card in j.get("cards", ["id"]):
			var spec := Verify.card_prop_spec(jid, String(card))
			seen[String(card)] = true
			assert_ne(spec["kind"], "default", "%s: card %s has a prop (not the Halina note fallback)" % [jid, card])
			if spec["kind"] == "texture":
				var prop := String(spec["prop"])
				assert_ne(prop, "receipt", "%s: %s is not the locksmith's own Lockwright receipt" % [jid, card])
				assert_true(prop != "note" or card == "note", "%s: %s is not Halina's soup note" % [jid, card])
				assert_true(prop != "envelope" or jid == "job.grandma_broth", "%s: the G14 envelope is addressed to Mrs Halina" % jid)
				for lang in ["pl", "en"]:
					assert_true(ResourceLoader.exists("res://assets/ui/gpt/verify/%s_%s.webp" % [prop, lang]), "%s %s photo exists" % [prop, lang])
			else:
				assert_true(PaperProp.ASPECT.has(String(spec["style"])), "%s: paper style %s" % [card, spec["style"]])
	assert_true(seen.has("receipt") and seen.has("witness") and seen.has("institution"), "the survey sees the common cards")
	# the customer receipt is a till slip drawn in the game
	assert_eq(Verify.card_prop_spec("job.bike_interview", "receipt"), {"kind": "paper", "style": "till"})


func test_paper_words_exist_in_every_language() -> void:
	var keys := ["verify.paper.total", "verify.paper.receipt.thanks", "practice.result_left"]
	for card: String in Verify.PAPER_TEXT:
		for key in Verify.PAPER_TEXT[card]:
			if String(key) != "":
				keys.append(String(key))
	var seen := {}
	for r in I18n._parse_csv("res://i18n/strings.csv").slice(1):
		seen[String(r[0])] = r
	for key: String in keys:
		assert_true(I18n.has_key(StringName(key)), key)
		var row: PackedStringArray = seen.get(key, PackedStringArray())
		assert_eq(row.size(), 1 + LANGS.size(), key)
		for i in range(1, row.size()):
			assert_ne(String(row[i]).strip_edges(), "", "%s/%s" % [key, LANGS[i - 1]])


func test_paper_cards_render_on_the_table() -> void:
	# a job with each paper style: the tile's picture is a drawn sheet of a real size
	var want := {"witness": "job.grandma_broth", "photo": "job.grandma_broth", "letter": "job.kiosk_shutter",
		"institution": "job.museum_time_lock", "receipt": "job.bike_interview", "deed": "job.uncle_safe_heirs",
		"address_app": "job.newlyweds_4am", "resolution": "job.krakow_tenement_gate", "invoice": "job.bramah_bureau"}
	for card: String in want:
		var v := await _open(want[card])
		while v.card_names().size() < v._cards().size():
			v._ask_more()
			await get_tree().process_frame
		var tile: Control = v.cards_box.get_node_or_null("Card_" + card)
		assert_not_null(tile, "%s: card %s on the table" % [want[card], card])
		if tile == null:
			continue
		var pic := tile.get_node("Box/Pic")
		assert_true(pic is PaperProp, "%s is drawn as paper" % card)
		if pic is PaperProp:
			assert_gt((pic as PaperProp).sheet_size().x, 40.0, "%s: the sheet has a size" % card)
			assert_ne((pic as PaperProp).heading, "", "%s: the paper carries its words" % card)
	var g := await _open("job.grandma_broth")
	g._ask_more()
	await get_tree().process_frame
	var letter: Node = g.cards_box.get_node("Card_letter/Box/Pic")
	assert_true(letter is TextureRect and String((letter as TextureRect).texture.resource_path).contains("envelope_"), "Mrs Halina's letter is her G14 envelope")


# ------------------------------------------------------------------ N-81
func test_verify_shows_the_arrival_landing() -> void:
	for jid in ["job.grandma_broth", "job.wrong_floor", "job.halina_recipe_box"]:
		var v := await _open(jid)
		var bg: TextureRect = v.get_node("Backdrop")
		assert_true(String(bg.texture.resource_path).begins_with("res://assets/arrival/"), "%s: the arrival scene's landing, not a G07 still (%s)" % [jid, bg.texture.resource_path])
	var w := await _open("job.wrong_floor")
	assert_not_null(w.get_node_or_null("Backdrop/Figure"), "wrong_floor: Mr Kazimierz at the door, as at the arrival")
	var k := await _open("job.kiosk_shutter")
	assert_string_contains(String((k.get_node("Backdrop") as TextureRect).texture.resource_path), "/ui/gpt/arrival/07_kiosk", "no scene: the G07 still of the place")


func test_day_after_uses_the_same_door() -> void:
	var wf := JobRun.job_by_id("job.wrong_floor")
	var p := DayAfter.backdrop_path(wf)
	assert_true(p.begins_with("res://assets/arrival/wrong_floor/day/"), "the next day at door 19, by day (%s)" % p)
	assert_false(p.contains("plate_kazimierz"), "nobody standing at the door the next day")
	var gb := DayAfter.backdrop_path(JobRun.job_by_id("job.grandma_broth"))
	assert_eq(gb, "res://assets/arrival/grandma_broth/day/plate.webp")
	# no scene: the arrival's own G07 photo (the day and evening stairwells are different doors)
	for j: Dictionary in _jobs():
		if ArrivalScene.place_still(j).is_empty():
			assert_eq(DayAfter.backdrop_path(j), "res://assets/ui/gpt/arrival/" + Arrival.g07_image(j), "%s: same door as the arrival" % j["id"])


func test_flat_plate_matches_the_photo() -> void:
	for j: Dictionary in _jobs():
		if String(j.get("place", "apartment")) != "apartment" or not ArrivalScene.place_still(j).is_empty():
			continue
		var door: int = Arrival.G07_DOOR[Arrival.g07_image(j)]
		assert_eq(Arrival.plate_path(j, "pl"), "res://assets/ui/gpt/plates/plate_%02d.png" % int(j.get("door", door)), "%s: the plate shows the door of the photo" % j["id"])
	# texts that name a flat agree with the picture (Po dwunastu godzinach: night stairwell, door 5)
	var nn := JobRun.job_by_id("job.night_nurse")
	assert_eq(Arrival.G07_DOOR[Arrival.g07_image(nn)], 5)
	var pl := FileAccess.get_file_as_string("res://i18n/content.csv")
	assert_false(pl.contains("spod czternastki"), "no flat fourteen in front of door 5")
	# every place has a still
	for j: Dictionary in _jobs():
		assert_true(Arrival.ARRIVAL_BG.has(String(j.get("place", "apartment"))), "%s: place %s has a G07 still" % [j["id"], j.get("place")])
	assert_eq(String(JobRun.job_by_id("job.bike_interview")["place"]), "yard", "the bike stand is under the block, not on a landing")
	assert_eq(String(JobRun.job_by_id("job.museum_time_lock")["place"]), "museum")


# ------------------------------------------------------------------ N-91
func test_finished_wrong_floor_does_not_punish_again() -> void:
	Save.set_value("reputation", 40)
	Save.set_value("jobs_completed", ["job.wrong_floor"])
	Save.set_value("jobs_wrong_open", [])
	var v := await _open("job.wrong_floor")
	assert_false(v.accept_button.visible, "settled by asking: no 'accept' for the neighbour's door")
	v._accept()
	await get_tree().process_frame
	assert_eq(int(Save.get_value("reputation", 0)), 40, "no -25")
	assert_eq(Save.get_value("jobs_wrong_open", []), [], "the job stays on the list")
	v._ask_more()
	await get_tree().process_frame
	assert_eq(int(Save.get_value("reputation", 0)), 40, "asking again gives no second +4")


func test_old_save_with_both_keeps_the_job_on_the_list() -> void:
	Save.set_value("jobs_completed", ["job.wrong_floor"])
	Save.set_value("jobs_wrong_open", ["job.wrong_floor"])
	Save.set_value(DayAfter.PENDING_KEY, [])
	var vp := SubViewport.new()
	vp.size = Vector2i(412, 915)
	add_child_autofree(vp)
	var list: Control = load("res://scenes/jobs_list.tscn").instantiate()
	vp.add_child(list)
	await get_tree().process_frame
	assert_not_null(list.find_child("Job_wrong_floor", true, false), "a job done honestly stays listed (done)")


# ------------------------------------------------------------------ N-85
func test_exit_from_a_job_goes_to_the_list_at_that_job() -> void:
	var lp: GDScript = load("res://scripts/photoreal/lock_photoreal.gd")
	JobRun.start(JobRun.job_by_id("job.wrong_floor"))
	assert_eq(lp.quit_target(), "res://scenes/jobs_list.tscn")
	JobRun.start_tutorial(0)
	assert_eq(lp.quit_target(), "res://scenes/main_menu.tscn", "the tutorial goes back to the menu")
	JobRun.mode = &"job"
	JobRun.current_job = {}
	var jl: GDScript = load("res://scripts/ui/jobs_list.gd")
	jl.set("last_job_id", "job.uncle_safe_heirs")
	Save.set_value(DayAfter.PENDING_KEY, [])
	var vp := SubViewport.new()
	vp.size = Vector2i(412, 915)
	add_child_autofree(vp)
	var list: Control = load("res://scenes/jobs_list.tscn").instantiate()
	vp.add_child(list)
	for i in 4:
		await get_tree().process_frame
	var b: Button = list.focus_button()
	assert_not_null(b, "the list knows the last job")
	if b != null:
		var scroll: ScrollContainer = list.get_node("Frame/VBox/Scroll")
		var sr := scroll.get_global_rect()
		assert_true(sr.encloses(b.get_global_rect()), "the last job is in view (%s in %s)" % [b.get_global_rect(), sr])
	jl.set("last_job_id", "")


# ------------------------------------------------------------------ N-82
func test_pin_family_tool_stays_in_the_section() -> void:
	for jid in ["job.night_nurse", "job.brussels_townhouse"]:  # magnetic, dimple
		for size: Vector2i in [Vector2i(915, 412), Vector2i(412, 915)]:
			JobRun.start(JobRun.job_by_id(jid))
			var vp := SubViewport.new()
			vp.size = size
			add_child_autofree(vp)
			var scene: Node = load(JobRun.lock_scene_path()).instantiate()
			vp.add_child(scene)
			await wait_physics_frames(4)
			var view = scene.get("view")
			assert_true(view is LockPinFamilyView, "%s uses the pin-family view" % jid)
			if not view is LockPinFamilyView:
				continue
			var pv: LockPinFamilyView = view
			var clip := pv.tool_clip_rect()
			assert_true(clip.is_equal_approx(pv.section_rect), "%s %s: the tool layer is the section %s (%s)" % [jid, size, pv.section_rect, clip])
			assert_true(pv.get_node("ToolLayer").clip_contents, "%s: the tool is clipped, never over the leather" % jid)
			scene.queue_free()
			await get_tree().process_frame
