extends GutTest
## N-53/N-59/N-60: menu screens fit narrow phones and landscape.
## Each screen is laid out inside a SubViewport of 360x800, 412x915 and 915x412:
## - the root's combined minimum width is <= the viewport width (no sideways scroll);
## - no visible control sticks out left/right of the viewport;
## - every visible button/toggle/slider is a touch target >= 48 dp high;
## - ScrollContainers never scroll horizontally.

const SCREENS := [
	"res://scenes/main_menu.tscn",
	"res://scenes/settings.tscn",
	"res://scenes/workshop.tscn",
	"res://scenes/jobs_list.tscn",
	"res://scenes/showcase.tscn",
	"res://scenes/job_arrival.tscn",
	"res://scenes/control_choice.tscn",
]
const SIZES := [Vector2i(360, 800), Vector2i(412, 915), Vector2i(915, 412)]
const ARRIVAL_JOB := "job.bike_interview"

var _save_backup: Dictionary


func before_all() -> void:
	_save_backup = Save.data.duplicate(true)


func after_all() -> void:
	Save.data = _save_backup
	Save.save()


func _open(path: String, size: Vector2i) -> Control:
	if path.ends_with("job_arrival.tscn"):
		JobRun.start(JobRun.job_by_id(ARRIVAL_JOB))
	var vp := SubViewport.new()
	vp.size = size
	vp.disable_3d = true
	add_child_autofree(vp)
	var scene: Control = load(path).instantiate()
	vp.add_child(scene)
	for i in 4:
		await get_tree().process_frame
	return scene


func _walk(n: Node, out: Array) -> void:
	for c in n.get_children():
		if c is Control and c.is_visible_in_tree():
			out.append(c)
		_walk(c, out)


func test_screens_fit_every_size() -> void:
	for path in SCREENS:
		for size in SIZES:
			var scene := await _open(path, size)
			var tag := "%s @ %dx%d" % [path.get_file(), size.x, size.y]
			assert_lte(scene.get_combined_minimum_size().x, float(size.x), tag + ": root min width")
			var controls: Array = []
			_walk(scene, controls)
			for c: Control in controls:
				var r := c.get_global_rect()
				if r.size.x <= 0.0:
					continue
				assert_true(r.position.x >= -1.0 and r.end.x <= size.x + 1.0,
					"%s: %s sticks out (%.0f..%.0f)" % [tag, scene.get_path_to(c), r.position.x, r.end.x])
				if c is ScrollContainer:
					assert_eq(c.horizontal_scroll_mode, ScrollContainer.SCROLL_MODE_DISABLED,
						"%s: %s scrolls sideways" % [tag, scene.get_path_to(c)])
				if (c is BaseButton or c is HSlider) and c.mouse_filter != Control.MOUSE_FILTER_IGNORE:
					assert_gte(c.size.y, 48.0, "%s: %s touch target < 48 dp" % [tag, scene.get_path_to(c)])
			scene.get_parent().queue_free()
			await get_tree().process_frame


func test_frame_keeps_16dp_sides() -> void:
	var scene := await _open("res://scenes/settings.tscn", Vector2i(360, 800))
	var frame: MarginContainer = scene.get_node("Frame")
	assert_gte(frame.get_theme_constant("margin_left"), 16)
	assert_gte(frame.get_theme_constant("margin_right"), 16)


func test_every_episodic_speaker_has_portrait() -> void:
	var speakers := {}
	for dir in ["res://data/jobs", "res://data/jobs_ch7"]:
		for f in DirAccess.get_files_at(dir):
			if f.ends_with(".json"):
				var job: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(dir + "/" + f))
				for s in job.get("lines", []):
					speakers[s] = true
	var arrival := load("res://scripts/ui/job_arrival.gd")
	speakers.erase("locksmith")  # the player has no portrait by design (N-60)
	# T43: G24 portraits (docs/handoff/gpt6/G24-portraits-t43.md) not delivered yet; until then the arrival
	# screen shows the blank enamel plate with the initial (remove ids here once the .webp files land)
	var pending := ["celina", "dorota", "seweryn", "borys", "alicja"]
	for s in speakers:
		if s in pending and arrival.portrait_for(s) == null:
			var plate: Control = arrival.initial_plate(s, "X")
			add_child_autofree(plate)
			assert_not_null((plate.get_child(0) as TextureRect).texture, "initial plate for %s" % s)
			continue
		assert_not_null(arrival.portrait_for(s), "no portrait for speaker %s" % s)


func test_arrival_locksmith_has_no_avatar_and_lines_sit_with_speaker() -> void:
	var scene := await _open("res://scenes/job_arrival.tscn", Vector2i(412, 915))
	var lines: VBoxContainer = scene.get_node("Frame/VBox/Scroll/Body/Lines")
	assert_gt(lines.get_child_count(), 0)
	for row in lines.get_children():
		var is_player: bool = row.get_meta("speaker", "") == "locksmith"
		assert_eq(row.find_child("Avatar", true, false) == null and row.find_child("InitialPlate", true, false) == null,
			is_player, "%s: avatar only for clients" % row.name)
		# speaker name and line text live in the same card
		var who: Label = row.find_child("Speaker", true, false)
		var said: Label = row.find_child("Text", true, false)
		assert_eq(who.get_parent(), said.get_parent())


func test_initial_plate_has_no_printed_digit() -> void:
	var arrival := load("res://scripts/ui/job_arrival.gd")
	var plate: Control = arrival.initial_plate("zz_nobody", "Zenon")
	add_child_autofree(plate)
	var tex: Texture2D = (plate.get_child(0) as TextureRect).texture
	assert_not_null(tex)
	assert_true(tex.resource_path.contains("/plates/initial_"), "blank G17 plate, not plate_01")
	assert_eq((plate.get_node("Initial") as Label).text, "Z")


func _card(tool: Dictionary, coins: int, owned: bool, integrity: int) -> Control:
	var ws: Control = load("res://scenes/workshop.tscn").instantiate()
	add_child_autofree(ws)
	Save.set_value("tools/%s/owned" % tool["id"], owned)
	Save.set_value("tools/%s/integrity" % tool["id"], integrity)
	var card: Control = ws._tool_card(tool, coins)
	ws.add_child(card)
	return card


func test_workshop_row_rules() -> void:
	var tool := {"id": "zz_test_tool", "price": 300, "i18n": "workshop.title"}
	# full integrity: no repair button
	var full := _card(tool, 1000, true, 100)
	assert_false((full.find_child("Action", true, false) as Button).visible, "no Repair at 100%")
	# worn + affordable: repair visible and enabled
	var worn := _card(tool, 1000, true, 40)
	var b: Button = worn.find_child("Action", true, false)
	assert_true(b.visible and not b.disabled)
	# not affordable: disabled AND a different label (not colour alone)
	var poor := _card(tool, 0, false, 100)
	b = poor.find_child("Action", true, false)
	assert_true(b.disabled)
	assert_eq(b.text, I18n.t(&"workshop.not_enough"))
	# progress reward: the text appears once, no button
	var reward := _card({"id": "zz_test_reward", "price": 0, "unlock": "after_t1", "i18n": "workshop.title"}, 0, false, 100)
	assert_false((reward.find_child("Action", true, false) as Button).visible)
	assert_eq((reward.find_child("State", true, false) as Label).text.count(I18n.t(&"workshop.reward")), 1)


func test_control_choice_defaults_to_auto_and_saves() -> void:
	var before_auto = Settings.get_value("auto_tension")
	var before_chosen = Settings.get_value("control_chosen")
	Settings.set_value("control_chosen", false)
	var scene := await _open("res://scenes/control_choice.tscn", Vector2i(412, 915))
	assert_true(scene.auto_selected, "automatic tension is preselected (D-52)")
	scene.select(false)
	assert_false(scene.auto_selected)
	Settings.set_value("auto_tension", before_auto)
	Settings.set_value("control_chosen", before_chosen)
