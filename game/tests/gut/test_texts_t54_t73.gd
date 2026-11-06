extends GutTest
## Wiring of the GPT text package T54/T57/T59/T60/T65/T73 (review: contrib/gpt/REVIEW-T44-T73.md).

const PAYMENT := preload("res://scripts/ui/job_payment.gd")
const RUN_LOOP := preload("res://scripts/ui/run_loop.gd")
const VERIFY := preload("res://scripts/ui/job_verify.gd")
const CARDS := ["id", "witness", "manager", "lease", "resolution", "deed", "inheritance", "institution",
	"letter", "photo", "receipt", "invoice", "address_app"]

var _lang := ""


func before_each() -> void:
	_lang = I18n.current_language()
	I18n.apply_language("en")


func after_each() -> void:
	I18n.apply_language(_lang)


func test_receipt_service_names_the_family_and_time_lock_is_a_repair() -> void:
	assert_eq(PAYMENT.service_text({"family": "wafer"}), I18n.t(&"receipt.service.wafer"))
	assert_eq(PAYMENT.service_text({"family": "time_lock"}), "Clock mechanism repair")
	assert_eq(PAYMENT.service_text({"family": "no_such_family"}), I18n.t(&"receipt.service"))


func test_every_job_family_has_a_receipt_line() -> void:
	for dir in ["res://data/jobs"]:
		for f in DirAccess.get_files_at(dir):
			if not f.ends_with(".json"):
				continue
			var job: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(dir + "/" + f))
			var key := StringName("receipt.service." + String(job.get("family", "")))
			assert_true(I18n.has_key(key), "missing %s (%s)" % [key, f])


func test_dispatch_lines_do_not_repeat_within_fifteen_locks() -> void:
	var seen := {}
	for n in range(1, 16):
		var line: String = RUN_LOOP.dispatch_line(n)
		assert_false(line.begins_with("run.dispatch"), "untranslated %s" % line)
		assert_false(seen.has(line), "repeated at lock %d" % n)
		seen[line] = true


func test_every_verification_card_has_two_exchanges() -> void:
	for card in CARDS:
		var a: String = VERIFY.exchange_text("job.x", card, 0)
		var b: String = VERIFY.exchange_text("job.x", card, 1)
		assert_true(a.begins_with("— "), "no exchange for %s" % card)
		assert_ne(a, b, "tapping %s again should give the other variant" % card)
	assert_eq(VERIFY.exchange_text("job.x", "no_such_card", 0), "")


func test_tool_descriptions_and_settings_help_exist() -> void:
	var tools: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/tools.json"))
	for tool in tools["tools"]:
		assert_true(I18n.has_key(StringName("tool.%s.desc" % tool["id"])), "desc of %s" % tool["id"])
	for k in [&"settings.help.haptics", &"settings.help.chalk", &"settings.help.reduce_motion",
			&"settings.help.quality", &"about.story", &"about.credits"]:
		assert_true(I18n.has_key(k), String(k))
