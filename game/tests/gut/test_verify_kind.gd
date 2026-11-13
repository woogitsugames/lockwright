extends GutTest
## D-103: what the locksmith checks depends on what is opened (data `verify_kind`): the right to a
## flat ("premises"), whose the thing is ("object": the bike padlock, a chest, a tin) or the consent
## for a shared or institutional space or item ("shared"). The arrival button, the verification title,
## the witness's note and the generic exchanges follow it; the old keys stay for premises.

const LANGS := ["en", "pl", "de", "fr", "es"]
const KINDS := ["premises", "object", "shared"]
## one job of each kind (owner bug 2026-11-08: the bike padlock said "right of entry to the premises")
const SAMPLE := {"premises": "job.grandma_broth", "object": "job.bike_interview", "shared": "job.shared_room_door"}
const ARRIVAL := "res://scenes/job_arrival.tscn"
const VERIFY := "res://scenes/job_verify.tscn"
const JobArrival := preload("res://scripts/ui/job_arrival.gd")
const Verify := preload("res://scripts/ui/job_verify.gd")
## every key added for the kinds (all five languages, non-empty)
const NEW_KEYS := ["job.verify.object", "job.verify.shared", "verify.title.object", "verify.title.shared",
	"verify.paper.witness.body.object", "verify.paper.witness.body.shared",
	"verify.ask.witness.1.object", "verify.reply.witness.1.object", "verify.ask.witness.2.object", "verify.reply.witness.2.object",
	"verify.ask.witness.1.shared", "verify.reply.witness.1.shared", "verify.ask.witness.2.shared", "verify.reply.witness.2.shared",
	"verify.reply.deed.1.shared", "verify.ask.deed.2.object", "verify.reply.deed.2.object",
	"verify.ask.deed.2.shared", "verify.reply.deed.2.shared", "verify.reply.invoice.1.shared", "verify.reply.letter.1.shared",
	"job.verify", "verify.title", "verify.paper.purpose.access.body", "verify.ask.resolution.2"]

var _locale := ""


func before_each() -> void:
	_locale = TranslationServer.get_locale()


func after_each() -> void:
	TranslationServer.set_locale(_locale)
	JobArrival.reduce_motion_override = -1
	JobRun.current_job = {}


func _all_jobs() -> Array:
	var out := []
	for f in DirAccess.get_files_at("res://data/jobs"):
		if f.ends_with(".json"):
			out.append(JSON.parse_string(FileAccess.get_file_as_string("res://data/jobs/" + f)))
	return out


func _open(scene_path: String, job_id: String, size: Vector2i) -> Control:
	JobArrival.reduce_motion_override = 1
	JobRun.start(JobRun.job_by_id(job_id))
	var vp := SubViewport.new()
	vp.size = size
	vp.disable_3d = true
	add_child_autofree(vp)
	var s: Control = load(scene_path).instantiate()
	if "go_override" in s:
		s.go_override = func(_p: String) -> void: pass
	vp.add_child(s)
	for i in 3:
		await get_tree().process_frame
	return s


func test_every_job_has_a_valid_verify_kind() -> void:
	var jobs := _all_jobs()
	assert_gte(jobs.size(), 103, "all jobs of game/data/jobs (chapters 1-14, D-111, D-119)")
	var count := {}
	for j: Dictionary in jobs:
		assert_true(j.has("verify_kind"), "%s has verify_kind" % j["id"])
		assert_has(KINDS, String(j.get("verify_kind", "")), "%s: verify_kind is premises/object/shared" % j["id"])
		count[j.get("verify_kind", "")] = int(count.get(j.get("verify_kind", ""), 0)) + 1
	for k in KINDS:
		assert_gt(int(count.get(k, 0)), 0, "some jobs are %s" % k)
	assert_eq(JobRun.verify_kind({}), "premises", "no field: the old wording")
	assert_eq(JobRun.verify_kind({"verify_kind": "house"}), "premises", "unknown kind: the old wording")


func test_sample_jobs_have_the_expected_kind() -> void:
	for k in SAMPLE:
		assert_eq(JobRun.verify_kind(JobRun.job_by_id(SAMPLE[k])), k, SAMPLE[k])
	# refusals keep the kind of what is asked for
	assert_eq(JobRun.verify_kind(JobRun.job_by_id("job.refuse_ex_partner")), "premises")
	assert_eq(JobRun.verify_kind(JobRun.job_by_id("job.refuse_unapproved_repair")), "shared")
	assert_eq(JobRun.verify_kind(JobRun.job_by_id("job.refuse_wrong_letterbox")), "object")


func test_arrival_button_and_verify_title_follow_the_kind() -> void:
	TranslationServer.set_locale("pl")
	var expect := {"premises": "Sprawdź prawo do lokalu", "object": "Sprawdź, czyja to rzecz", "shared": "Sprawdź zgodę na otwarcie"}
	for k in KINDS:
		var a := await _open(ARRIVAL, SAMPLE[k], Vector2i(412, 915))
		assert_eq(a.verify_button.text, expect[k], "%s arrival button" % SAMPLE[k])
		var v := await _open(VERIFY, SAMPLE[k], Vector2i(412, 915))
		assert_eq(v.title_label.text, expect[k], "%s verification title" % SAMPLE[k])
	TranslationServer.set_locale("en")
	var bike := await _open(ARRIVAL, "job.bike_interview", Vector2i(412, 915))
	assert_eq(bike.verify_button.text, I18n.t(&"job.verify.object"))
	assert_ne(bike.verify_button.text, I18n.t(&"job.verify"), "the bike padlock is not premises")


func test_kind_keys_in_all_languages() -> void:
	var seen := {}
	for path in ["res://i18n/strings.csv", "res://i18n/content.csv"]:
		for r in (I18n._parse_csv(path) as Array).slice(1):
			seen[String(r[0])] = r
	for key: String in NEW_KEYS:
		var row: PackedStringArray = seen.get(key, PackedStringArray())
		assert_eq(row.size(), 1 + LANGS.size(), key)
		for i in range(1, row.size()):
			assert_ne(String(row[i]).strip_edges(), "", "%s/%s" % [key, LANGS[i - 1]])
	for lang in LANGS:
		TranslationServer.set_locale(lang)
		for key: String in NEW_KEYS:
			assert_true(I18n.has_key(StringName(key)), "%s/%s" % [key, lang])


## The arrival button is one line wide enough for every kind in every language at 360x800 (no wrap),
## and the verification title fits in <= 2 lines without cutting a word, like fit_title wants (VA-03/VA-08).
func test_texts_fit_at_360x800_in_all_languages() -> void:
	for k in KINDS:
		var a := await _open(ARRIVAL, SAMPLE[k], Vector2i(360, 800))
		var b: Button = a.verify_button
		var font: Font = b.get_theme_font(&"font")
		var fs := b.get_theme_font_size(&"font_size")
		var avail := b.size.x
		var sb: StyleBox = b.get_theme_stylebox(&"normal")
		if sb:
			avail -= sb.get_margin(SIDE_LEFT) + sb.get_margin(SIDE_RIGHT)
		assert_gt(avail, 200.0, "button width known")
		var v := await _open(VERIFY, SAMPLE[k], Vector2i(360, 800))
		var t: Label = v.title_label
		var tfont: Font = t.get_theme_font(&"font")
		for lang in LANGS:
			TranslationServer.set_locale(lang)
			var text := I18n.t(JobRun.verify_key(&"job.verify", JobRun.current_job))
			var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			assert_lte(w, avail, "%s/%s button '%s' %.0f <= %.0f" % [k, lang, text, w, avail])
			var title := I18n.t(JobRun.verify_key(&"verify.title", JobRun.current_job))
			var tfs := ScreenFrame.title_size(tfont, title, t.size.x, UiA11y.fs(28), UiA11y.fs(17), UiA11y.fs(22))
			var longest := 0.0
			for word in title.split(" ", false):
				longest = maxf(longest, tfont.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, tfs).x)
			assert_lte(longest, t.size.x, "%s/%s title '%s': no word cut" % [k, lang, title])
			var th := tfont.get_multiline_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, t.size.x, tfs).y
			assert_lte(th, tfont.get_height(tfs) * 2.2, "%s/%s title '%s' in <= 2 lines" % [k, lang, title])
		TranslationServer.set_locale(_locale)


func test_witness_and_exchanges_follow_the_kind() -> void:
	TranslationServer.set_locale("en")
	var home := I18n.t(&"verify.ask.witness.1")
	# a thing: the witness vouches for whose it is, not for a home
	var tin := Verify.exchange_text("job.halina_christmas_tin", "witness", 0) + Verify.exchange_text("job.halina_christmas_tin", "witness", 1)
	assert_false(tin.contains(home), "no 'your home' for Halina's tin")
	assert_true(tin.contains(I18n.t(&"verify.ask.witness.1.object")) or tin.contains(I18n.t(&"verify.ask.witness.2.object")))
	var room := Verify.exchange_text("job.shared_room_door", "witness", 0) + Verify.exchange_text("job.shared_room_door", "witness", 1)
	assert_false(room.contains(home), "no 'your home' for the shared room")
	assert_true(room.contains(I18n.t(&"verify.ask.witness.1.shared")) or room.contains(I18n.t(&"verify.ask.witness.2.shared")))
	var flat := Verify.exchange_text("job.grandma_broth", "witness", 0) + Verify.exchange_text("job.grandma_broth", "witness", 1)
	assert_true(flat.contains(home) or flat.contains(I18n.t(&"verify.ask.witness.2")), "premises keep the old exchange")
	# the deed of a thing does not ask about the building
	for i in 2:
		assert_false(Verify.exchange_text("job.bramah_bureau", "deed", i).contains(I18n.t(&"verify.ask.deed.2")), "bureau deed %d" % i)
	# the witness's note
	var note: PaperProp = Verify.paper_for(JobRun.job_by_id("job.halina_recipe_box"), "witness", "note")
	assert_eq(note.body, I18n.t(&"verify.paper.witness.body.object"))
	var note2: PaperProp = Verify.paper_for(JobRun.job_by_id("job.wigilia_table_drawer"), "witness", "note")
	assert_eq(note2.body, I18n.t(&"verify.paper.witness.body.shared"))
	var note3: PaperProp = Verify.paper_for(JobRun.job_by_id("job.grandma_broth"), "witness", "note")
	assert_eq(note3.body, I18n.t(&"verify.paper.witness.body"))
	for n in [note, note2, note3]:
		n.free()


## Generic words that assumed a flat are gone where every user is not one (D-103).
func test_neutral_wording_for_access_and_resolution() -> void:
	TranslationServer.set_locale("pl")
	assert_false(I18n.t(&"verify.paper.purpose.access.body").contains("drzwi"))
	assert_false(I18n.t(&"verify.ask.resolution.2").contains("drzwi"))
	TranslationServer.set_locale("en")
	assert_false(I18n.t(&"verify.paper.purpose.access.body").contains("door"))
	assert_false(I18n.t(&"verify.ask.resolution.2").contains("door"))
