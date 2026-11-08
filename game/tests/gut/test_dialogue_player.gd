extends GutTest
## D-57: voiced dialogue lines on the arrival screen (DialoguePlayer).
## Fixtures (test-only, not exported: tests/* is in exclude_filter):
##   tests/fixtures/lines/pl/job.test_dialogue.line.{1,3}.ogg
##   tests/fixtures/lines/en/job.test_dialogue.line.{1,2}.ogg
## so in PL line 2 is subtitle-only although EN has it (no cross-language fallback).

const DialoguePlayer := preload("res://scripts/ui/dialogue_player.gd")
const ROOT := "res://tests/fixtures/lines"
const KEYS := ["job.test_dialogue.line.1", "job.test_dialogue.line.2", "job.test_dialogue.line.3"]

var _music_db := 0.0


func before_each() -> void:
	var idx := AudioServer.get_bus_index("Music")
	_music_db = AudioServer.get_bus_volume_db(idx)


func after_each() -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), _music_db)


func _make(lang: String) -> Array:
	var box := VBoxContainer.new()
	add_child_autofree(box)
	var rows: Array = []
	var texts := PackedStringArray()
	for i in KEYS.size():
		var l := Label.new()
		l.text = "line %d" % (i + 1)
		box.add_child(l)
		rows.append(l)
		texts.append(l.text)
	var dp: Node = DialoguePlayer.new()
	dp.root = ROOT
	dp.screen_reader_override = 0
	add_child_autofree(dp)
	dp.setup(rows, PackedStringArray(KEYS), texts, lang)
	return [dp, rows, box]


func _click(dp: Node, from: Vector2, to: Vector2) -> void:
	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	down.position = from
	dp.on_gui_input(down)
	var up := InputEventMouseButton.new()
	up.button_index = MOUSE_BUTTON_LEFT
	up.pressed = false
	up.position = to
	dp.on_gui_input(up)


func test_voice_bus_exists_routed_to_master() -> void:
	var idx := AudioServer.get_bus_index("Voice")
	assert_gte(idx, 0, "Voice bus in default_bus_layout.tres")
	assert_eq(AudioServer.get_bus_send(idx), &"Master")
	assert_eq(Sfx.voice_bus(), &"Voice")


func test_language_picks_its_own_folder_without_fallback() -> void:
	var pl: Node = _make("pl")[0]
	assert_true(pl.clip_for(0).ends_with("/pl/job.test_dialogue.line.1.ogg"), pl.clip_for(0))
	assert_eq(pl.clip_for(1), "", "PL has no line 2: subtitle-only, never the EN clip")
	assert_true(pl.clip_for(2).contains("/pl/"))
	var en: Node = _make("en")[0]
	assert_true(en.clip_for(1).ends_with("/en/job.test_dialogue.line.2.ogg"), en.clip_for(1))
	assert_eq(en.clip_for(2), "")
	var de: Node = _make("de")[0]
	assert_false(de.has_any_clip(), "DE has no audio yet")


func test_voiced_line_plays_on_voice_bus_and_ducks_music() -> void:
	var made := _make("pl")
	var dp: Node = made[0]
	var rows: Array = made[1]
	dp.start()
	assert_eq(dp.index, 0)
	assert_true(rows[0].visible)
	assert_false(rows[1].visible, "later lines appear one by one")
	assert_false(rows[2].visible)
	assert_eq(dp.player.bus, &"Voice")
	assert_true(dp.player.playing, "line 1 clip plays")
	assert_true(dp.player.stream is AudioStreamOggVorbis)
	await wait_seconds(0.2)
	assert_almost_eq(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music")), -6.0, 0.1, "music -6 dB under voice")
	dp.skip_all()
	await wait_seconds(0.35)
	assert_almost_eq(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music")), 0.0, 0.1, "music back after the dialogue")


func test_advances_after_clip_end_plus_gap() -> void:
	var made := _make("pl")
	var dp: Node = made[0]
	var rows: Array = made[1]
	dp.start()
	dp.player.stop()
	dp.player.finished.emit()  # clip ended
	await wait_seconds(0.1)
	assert_eq(dp.index, 0, "waits 250 ms after the clip")
	await wait_seconds(0.3)
	assert_eq(dp.index, 1, "next line after clip end + 250 ms")
	assert_true(rows[1].visible)
	assert_almost_eq(rows[0].modulate.a, DialoguePlayer.DIM_ALPHA, 0.01, "earlier line dimmed")
	assert_true(rows[1].get_meta("current"), "current line highlighted")


func test_missing_clip_is_subtitle_only_then_continues() -> void:
	var made := _make("pl")
	var dp: Node = made[0]
	dp.start()
	dp.advance()  # line 2: no PL clip
	assert_eq(dp.index, 1)
	assert_false(dp.player.playing, "no audio for a missing clip")
	assert_true(made[1][1].visible, "subtitle shown")
	var wait_ms: int = DialoguePlayer.reading_time_ms("line 2")
	await wait_seconds(wait_ms / 1000.0 + 0.2)
	assert_eq(dp.index, 2, "reading time elapsed -> next line")
	assert_true(dp.player.playing, "line 3 has a PL clip")


func test_tap_skips_to_next_line_drag_does_not() -> void:
	var made := _make("pl")
	var dp: Node = made[0]
	dp.start()
	_click(dp, Vector2(20, 20), Vector2(60, 90))  # a scroll gesture
	assert_eq(dp.index, 0, "drag is not a tap")
	_click(dp, Vector2(20, 20), Vector2(24, 22))
	assert_eq(dp.index, 1, "tap skips to the next line")
	_click(dp, Vector2(5, 5), Vector2(5, 5))
	assert_eq(dp.index, 2)
	_click(dp, Vector2(5, 5), Vector2(5, 5))
	assert_true(dp.is_finished(), "tap on the last line ends the dialogue")
	for r in made[1]:
		assert_true(r.visible)
		assert_almost_eq(r.modulate.a, 1.0, 0.01)


func test_skip_all_reveals_everything() -> void:
	var made := _make("en")
	var dp: Node = made[0]
	watch_signals(dp)
	dp.start()
	dp.skip_all()
	assert_signal_emitted(dp, "finished")
	assert_false(dp.player.playing)
	for r in made[1]:
		assert_true(r.visible)


func test_no_audio_in_language_shows_all_lines_at_once() -> void:
	var made := _make("de")
	var dp: Node = made[0]
	dp.start()
	assert_true(dp.is_finished())
	for r in made[1]:
		assert_true(r.visible, "subtitles always on")
	assert_false(dp.player.playing)


func test_screen_reader_gets_all_lines_without_autoplay() -> void:
	var made := _make("pl")
	var dp: Node = made[0]
	dp.screen_reader_override = 1
	dp.start()
	assert_true(dp.is_finished())
	assert_false(dp.player.playing, "no voice over TalkBack/VoiceOver")
	for r in made[1]:
		assert_true(r.visible)


func test_voice_volume_follows_settings() -> void:
	var before: float = Settings.get_value("volume_voice")
	assert_eq(Settings.DEFAULTS.get("volume_voice"), 1.0)
	var made := _make("pl")
	var dp: Node = made[0]
	dp.start()
	Settings.set_value("volume_voice", 0.5)
	assert_almost_eq(dp.player.volume_db, linear_to_db(0.5 * float(Settings.get_value("volume_master"))), 0.01)
	Settings.set_value("volume_voice", before)
	dp.skip_all()


func test_settings_screen_has_voices_slider() -> void:
	var scene: Control = load("res://scenes/settings.tscn").instantiate()
	add_child_autofree(scene)
	await get_tree().process_frame
	var slider: HSlider = scene.get_node("Frame/VBox/Scroll/Sections/Sound/Box/VoiceSlider")
	assert_not_null(slider)
	assert_gte(slider.custom_minimum_size.y, 48.0)
	var name_label: Label = scene.get_node("Frame/VBox/Scroll/Sections/Sound/Box/VoiceRow/Name")
	assert_eq(name_label.text, I18n.t(&"settings.volume_voice"))
	assert_lte(I18n.t(&"settings.volume_voice").length(), 28)


func test_arrival_screen_uses_dialogue_player() -> void:
	JobRun.start(JobRun.job_by_id("job.bike_interview"))
	var scene: Control = load("res://scenes/job_arrival.tscn").instantiate()
	add_child_autofree(scene)
	await get_tree().process_frame
	var dp: Node = scene.dialogue
	assert_not_null(dp)
	var lines: VBoxContainer = scene.get_node("Frame/VBox/Scroll/Body/Lines")
	var skip: Button = scene.get_node("Frame/VBox/Header/SkipAllButton")
	if dp.has_any_clip():
		assert_true(lines.get_child(0).visible)
		assert_true(skip.visible, "skip-all plate while voiced lines play")
		assert_gte(skip.custom_minimum_size.y, 48.0)
		dp.skip_all()
		assert_false(skip.visible)
	else:
		assert_true(dp.is_finished(), "no clips -> all subtitles at once")
		assert_false(skip.visible)
	for row in lines.get_children():
		assert_true(row.visible)


func test_arrival_scrolls_to_each_new_line() -> void:
	# Owner 2026-11-08: during a voiced conversation the newest line went below the fold and had to be
	# scrolled by hand. Each started line must end up fully inside the scroll viewport.
	JobRun.start(JobRun.job_by_id("job.kiosk_shutter"))
	var scene: Control = load("res://scenes/job_arrival.tscn").instantiate()
	var holder := Control.new()
	holder.size = Vector2(360, 560)  # small phone-like frame so the lines overflow
	add_child_autofree(holder)
	holder.add_child(scene)
	await get_tree().process_frame
	var dp: Node = scene.dialogue
	var scroll: ScrollContainer = scene.get_node("Frame/VBox/Scroll")
	var lines: VBoxContainer = scene.get_node("Frame/VBox/Scroll/Body/Lines")
	if not dp.has_any_clip():
		pass_test("no voiced lines in this language: all lines are shown at once")
		return
	for i in lines.get_child_count():
		if i > 0:
			dp.advance()
		await wait_seconds(0.35)
		var row: Control = lines.get_child(i)
		assert_true(row.visible)
		var view := scroll.get_global_rect()
		assert_lte(row.get_global_rect().end.y, view.end.y + 1.0, "line %d is visible without manual scrolling" % i)
