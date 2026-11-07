extends GutTest
## V04 / D-78: "day after" scenes — queued when a job ends, shown once over the job list, closed by a tap
## (or Continue / Back), no crash without a portrait, remembered in Save, layout fits phones.

const ONE_LINE := "job.cat_bathroom"            # marta, one line
const TWO_LINES := "job.t43_12_08_henryks_bench"  # halina, then the locksmith
const REFUSAL := "job.refuse_aunt_alive"

var _save_backup: Dictionary


func before_each() -> void:
	_save_backup = Save.data.duplicate(true)
	Save.data = Save.DEFAULTS.duplicate(true)
	DayAfter.reduce_motion_override = 1
	Nav.change_scenes = false


func after_each() -> void:
	DayAfter.reduce_motion_override = -1
	Nav.change_scenes = true
	Nav.scene_override = null
	JobRun.current_job = {}
	JobRun.mode = &"job"
	Save.data = _save_backup
	Save.save()


func _host() -> Control:
	var host := Control.new()
	host.size = Vector2(412, 915)
	add_child_autofree(host)
	return host


func _tap(scene: Control) -> void:
	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	down.position = Vector2(200, 300)
	scene._gui_input(down)
	var up := down.duplicate()
	up.pressed = false
	scene._gui_input(up)


func test_every_after_line_has_text_and_a_face() -> void:
	var jobs := 0
	for f in DirAccess.get_files_at("res://data/jobs"):
		if not f.ends_with(".json"):
			continue
		var j: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/jobs/" + f))
		var after: Array = j.get("after", [])
		assert_false(after.is_empty(), "%s has a day-after speaker" % j["id"])
		assert_eq(DayAfter.lines_for(j).size(), after.size(), "%s: a text for every after speaker" % j["id"])
		for sp in after:
			assert_true(I18n.has_key(StringName("cast.%s.name" % sp)), "%s: cast name for %s" % [j["id"], sp])
		jobs += 1
	assert_gt(jobs, 80)



## D-78 voices: every day-after line ships with a recorded clip in the bundled languages (PL, EN), at the path the
## scene plays (`lines/<lang>/<job_id>.after.N.ogg`), loadable as a non-looping Ogg stream. DE/FR/ES come in voice packs.
func test_every_after_line_has_audio_in_pl_and_en() -> void:
	var lines := 0
	for f in DirAccess.get_files_at("res://data/jobs"):
		if not f.ends_with(".json"):
			continue
		var j: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/jobs/" + f))
		for line in DayAfter.lines_for(j):
			for lang in ["pl", "en"]:
				var path := Sfx.line_clip_path(String(line["key"]), lang)
				assert_ne(path, "", "%s: %s clip" % [line["key"], lang])
				if path != "":
					var stream := load(path) as AudioStreamOggVorbis
					assert_not_null(stream, "%s: %s is Ogg Vorbis" % [line["key"], lang])
					if stream != null:
						assert_false(stream.loop, "%s: %s does not loop" % [line["key"], lang])
						assert_between(stream.get_length(), 0.5, 15.0, "%s: %s length" % [line["key"], lang])
			lines += 1
	assert_gt(lines, 90)


func test_scene_plays_the_line_clip() -> void:
	var lang := Settings.language()
	if not lang in ["pl", "en"]:
		pass_test("bundled clips are PL/EN only; %s comes from a voice pack" % lang)
		return
	DayAfter.note_finished(JobRun.job_by_id(ONE_LINE))
	var scene := DayAfter.maybe_show(_host())
	await wait_process_frames(2)
	assert_not_null(scene)
	if scene != null:
		assert_not_null(scene.player.stream, "the first line has a voice clip")
		if scene.player.stream != null:
			assert_eq(scene.player.stream.resource_path, "res://assets/audio/lines/%s/%s.after.1.ogg" % [lang, ONE_LINE])


func test_finished_job_is_queued_once_and_capped() -> void:
	DayAfter.note_finished(JobRun.job_by_id(ONE_LINE))
	DayAfter.note_finished(JobRun.job_by_id(ONE_LINE))
	assert_eq(DayAfter.pending(), [ONE_LINE], "no duplicates")
	DayAfter.note_finished({"id": "run.3", "family": "pin_tumbler"})
	DayAfter.note_finished({})
	assert_eq(DayAfter.pending(), [ONE_LINE], "shift locks and empty jobs have no scene")
	for jid in ["job.bike_interview", "job.allotment_shed", "job.kiosk_shutter"]:
		DayAfter.note_finished(JobRun.job_by_id(jid))
	assert_eq(DayAfter.pending().size(), DayAfter.PENDING_MAX)
	assert_false(DayAfter.pending().has(ONE_LINE), "the oldest one drops out")
	assert_eq(String(DayAfter.next_job().get("id")), "job.kiosk_shutter", "the newest plays first")


func test_job_run_complete_queues_the_scene() -> void:
	JobRun.start(JobRun.job_by_id(ONE_LINE))
	JobRun.complete()
	assert_eq(DayAfter.pending(), [ONE_LINE])


func test_refusal_queues_the_scene() -> void:
	# job_verify._refuse() calls this for a closed job.refuse_* job (then waits 1.2 s and changes scene)
	var src := FileAccess.get_file_as_string("res://scripts/ui/job_verify.gd")
	assert_string_contains(src, "DayAfter.note_finished(JobRun.current_job)")
	DayAfter.note_finished(JobRun.job_by_id(REFUSAL))
	assert_eq(DayAfter.pending(), [REFUSAL])
	assert_eq(DayAfter.lines_for(JobRun.job_by_id(REFUSAL)).size(), 2, "two neighbours speak the day after")


func test_shows_once_and_a_tap_closes_it() -> void:
	DayAfter.note_finished(JobRun.job_by_id(ONE_LINE))
	var host := _host()
	var da := DayAfter.maybe_show(host)
	assert_not_null(da, "a waiting job opens its scene")
	await get_tree().process_frame
	assert_eq(da.get_node("Frame/VBox/Header/Title").text, I18n.t(&"dayafter.title"))
	assert_eq(da.get_node("Frame/VBox/Body/Line/Col/Text").text, I18n.t(&"job.cat_bathroom.after.1"))
	assert_eq(da.get_node("Frame/VBox/Body/Line/Col/Speaker").text, I18n.t(&"cast.marta.name"))
	var portrait: TextureRect = da.get_node_or_null("Frame/VBox/Body/PortraitFrame/Portrait")
	assert_not_null(portrait, "Marta's portrait")
	assert_eq(portrait.texture.resource_path, "res://assets/ui/gpt/cast/06_marta/portrait.jpg", "square G09 photo")
	assert_eq(da.get_node("Frame/VBox/ContinueButton").text, I18n.t(&"dayafter.close"), "last line: back to work")
	watch_signals(da)
	_tap(da)
	assert_true(da.is_finished(), "one tap closes a one-line scene")
	assert_signal_emitted(da, "closed")
	await get_tree().process_frame
	assert_false(is_instance_valid(da), "the scene is gone")
	assert_true(DayAfter.seen(ONE_LINE))
	assert_null(DayAfter.maybe_show(host), "never twice for the same job")
	DayAfter.note_finished(JobRun.job_by_id(ONE_LINE))
	assert_eq(DayAfter.pending(), [], "a seen job is not queued again (replay)")


func test_two_lines_keep_the_client_in_view() -> void:
	DayAfter.note_finished(JobRun.job_by_id(TWO_LINES))
	var da := DayAfter.maybe_show(_host())
	await get_tree().process_frame
	var card: PanelContainer = da.get_node("Frame/VBox/Body/Line")
	assert_eq(da.portrait_speaker, "halina")
	assert_eq(da.get_node("Frame/VBox/ContinueButton").text, I18n.t(&"common.continue"))
	da.get_node("Frame/VBox/ContinueButton").pressed.emit()
	assert_false(da.is_finished())
	assert_eq(da.get_node("Frame/VBox/Body/Line/Col/Text").text, I18n.t(&"job.t43_12_08_henryks_bench.after.2"))
	assert_eq(card.theme_type_variation, &"EnamelPanel", "the locksmith's line on the enamel card")
	assert_eq(da.portrait_speaker, "halina", "the player is never shown; Halina stays")
	_tap(da)
	assert_true(da.is_finished())


func test_a_drag_is_not_a_tap() -> void:
	DayAfter.note_finished(JobRun.job_by_id(ONE_LINE))
	var da := DayAfter.maybe_show(_host())
	await get_tree().process_frame
	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	down.position = Vector2(100, 100)
	da._gui_input(down)
	var up := down.duplicate()
	up.pressed = false
	up.position = Vector2(100, 160)
	da._gui_input(up)
	assert_false(da.is_finished())


func test_missing_portrait_falls_back_to_the_plate() -> void:
	var job := JobRun.job_by_id(ONE_LINE).duplicate(true)
	job["after"] = ["nobody_without_portrait"]
	var da: DayAfter = load(DayAfter.SCENE).instantiate()
	da.job = job
	_host().add_child(da)
	await get_tree().process_frame
	assert_null(da.get_node_or_null("Frame/VBox/Body/PortraitFrame/Portrait"))
	var plate := da.get_node_or_null("Frame/VBox/Body/PortraitFrame/InitialPlate")
	assert_not_null(plate, "G17 initial plate instead of a portrait")
	assert_gte(plate.custom_minimum_size.x, 96.0, "the plate takes the portrait's place")
	_tap(da)
	assert_true(da.is_finished())


func test_save_remembers_seen_and_pending() -> void:
	DayAfter.note_finished(JobRun.job_by_id(ONE_LINE))
	DayAfter.note_finished(JobRun.job_by_id(TWO_LINES))
	Save.load_save()
	assert_eq(DayAfter.pending(), [ONE_LINE, TWO_LINES], "the queue survives a restart")
	DayAfter.mark_seen(TWO_LINES)
	Save.load_save()
	assert_true(DayAfter.seen(TWO_LINES), "seen survives a restart")
	assert_eq(DayAfter.pending(), [ONE_LINE])
	assert_eq(String(DayAfter.next_job().get("id")), ONE_LINE, "the older one comes next time")


func test_job_list_shows_it_and_back_closes_it() -> void:
	DayAfter.note_finished(JobRun.job_by_id(ONE_LINE))
	var list: Control = load("res://scenes/jobs_list.tscn").instantiate()
	add_child_autofree(list)
	await get_tree().process_frame
	var da: DayAfter = list.day_after
	assert_not_null(da, "the job list opens the waiting scene")
	assert_eq(da.get_parent(), list)
	assert_eq(da.get_index(), list.get_child_count() - 1, "on top of the list")
	Nav.scene_override = list
	Nav.last_target = ""
	assert_eq(Nav.handle_back(), &"custom", "Back closes the scene first")
	assert_eq(Nav.last_target, "", "and stays on the list")
	assert_true(DayAfter.seen(ONE_LINE))
	assert_eq(Nav.handle_back(), &"scene", "then Back leaves the list")
	assert_eq(Nav.last_target, "res://scenes/main_menu.tscn")
	# entering the list again shows nothing
	var again: Control = load("res://scenes/jobs_list.tscn").instantiate()
	add_child_autofree(again)
	await get_tree().process_frame
	assert_null(again.day_after)


func test_layout_fits_phones() -> void:
	for size in [Vector2i(360, 800), Vector2i(412, 915), Vector2i(915, 412)]:
		DayAfter.note_finished(JobRun.job_by_id(TWO_LINES))
		var vp := SubViewport.new()
		vp.size = size
		vp.disable_3d = true
		add_child_autofree(vp)
		var host := Control.new()
		vp.add_child(host)
		host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var da := DayAfter.maybe_show(host)
		for i in 4:
			await get_tree().process_frame
		var tag := "%dx%d" % [size.x, size.y]
		assert_lte(da.get_combined_minimum_size().x, float(size.x), tag + ": min width")
		var btn: Button = da.get_node("Frame/VBox/ContinueButton")
		assert_gte(btn.size.y, 48.0, tag + ": Continue >= 48 dp")
		for n: Control in [btn, da.get_node("Frame/VBox/Body/Line"), da.get_node("Frame/VBox/Body/PortraitFrame")]:
			var r := n.get_global_rect()
			assert_true(r.position.x >= -1.0 and r.end.x <= size.x + 1.0 and r.end.y <= size.y + 1.0,
				"%s: %s inside the screen (%s)" % [tag, n.name, r])
		assert_eq(da.get_node("Frame/VBox/Body").vertical, size.y >= size.x, tag + ": portrait above / beside the line")
		da.close()
		Save.data = Save.DEFAULTS.duplicate(true)
		vp.queue_free()
		await get_tree().process_frame
