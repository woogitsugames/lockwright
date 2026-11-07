extends Control
## Workshop: tool list from game/data/tools.json, buy/repair with in-game coins only
## (no real money, TOOLS.md §1). All text via i18n.
## N-59: every tool is a two-line card that never widens the screen:
##   line 1 = tool name (wraps), line 2 = state/price (wraps) + action plate (>= 96x48).
## Repair is hidden at 100%; a progress reward has no button; a purchase you cannot
## afford reads "Not enough coins" on an outline-only plate (not colour alone).
## D-71: two plates switch Tools / Furnishings ("Wyposażenie"). Furnishings are cosmetic (Furnishings.gd):
## the background is the Blender workshop render with an overlay per owned item, and the Furnishings tab
## shows the same picture undimmed above the item rows (same two-line rows as the tools).
## D-79: a third plate "Ćwiczenia" lists the practice locks (Practice.gd) grouped by family, with the
## goal as the row's line and its state in words (no ticks, no colour code). A practice run comes back
## here, on this tab, with one line about the attempt.

@onready var coins_label: Label = $Frame/VBox/CoinsLabel
@onready var tools_list: VBoxContainer = $Frame/VBox/Scroll/ToolsList
@onready var back_button: Button = $Frame/VBox/Header/BackButton

const TOOLS_PATH := "res://data/tools.json"

# G08 workshop backgrounds by time of day
const WORKSHOP_BG := {
	"morning": "01-workshop-morning-portrait.webp",
	"afternoon": "06-workbench-afternoon-landscape.webp",
	"evening": "03-workshop-evening-portrait.webp",
	"night": "08-lamplight-evening-landscape.webp",
}

var _map: TextureRect
var _map_frame: Control
var _tab := "tools"  # "tools" | "furnishings" | "practice"
var _backdrop_scene: Control
var _preview: Control
var _tab_tools: Button
var _tab_furn: Button
var _tab_practice: Button


func _day_part() -> String:
	var hour: int = Time.get_time_dict_from_system()["hour"]
	if hour >= 6 and hour < 12:
		return "morning"
	if hour >= 12 and hour < 18:
		return "afternoon"
	if hour >= 18 and hour < 23:
		return "evening"
	return "night"


func _add_map() -> void:
	# G15 district map with chapter pins for the current chapter; N-59: <= 30% height, cover
	var chapter := clampi(int(Save.get_value("chapter", 1)), 1, 6)
	var path := "res://assets/ui/gpt/map/zameczno_chapter_%d.%s" % [chapter, "webp" if chapter >= 4 else "png"]
	if not ResourceLoader.exists(path):
		path = "res://assets/ui/gpt/map/zameczno_base.png"
	if not ResourceLoader.exists(path):
		return
	var frame := PanelContainer.new()
	frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	frame.clip_contents = true
	_map = TextureRect.new()
	_map.texture = load(path)
	_map.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_map.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_map.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_map.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(_map)
	$Frame/VBox.add_child(frame)
	$Frame/VBox.move_child(frame, 3)
	_map_frame = frame
	resized.connect(_size_map)
	_size_map()


func _size_map() -> void:
	if _map == null:
		return
	var vp := get_viewport_rect().size
	# portrait: 30% of the height at most; landscape: a short strip (list stays usable)
	_map.custom_minimum_size.y = roundf(vp.y * (0.24 if vp.x < vp.y else 0.2))


func _ready() -> void:
	Sfx.play_ambience(&"workshop")
	Sfx.play_music(&"menu_workshop")
	_add_backdrop()
	ScreenFrame.fit(self, $Frame)
	_add_tabs()
	_add_map()
	$Frame/VBox/Header/Title.text = I18n.t(&"workshop.title")
	ScreenFrame.ellipsis($Frame/VBox/Header/Title)
	back_button.text = "‹ " + I18n.t(&"common.back")
	back_button.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	$Frame/VBox/Scroll.scroll_deadzone = 12
	_refresh()
	if Practice.last_result != &"":
		show_tab("practice")  # D-79: back from a practice lock
	Save.changed.connect(_refresh)
	ScreenFrame.enter($Frame/VBox/Scroll)
	ScreenFrame.wire_sounds(self)  # S05 enamel-plate sounds


static func repair_cost(price: int, integrity: int) -> int:
	return maxi(5, int(price * (0.35 if integrity <= 0 else 0.15)))


func _add_backdrop() -> void:
	# D-71: the Blender workshop with the owned furnishings; G08 photos by time of day only as a fallback
	if not Furnishings.has_picture():
		ScreenFrame.backdrop(self, "res://assets/ui/gpt/workshop/" + WORKSHOP_BG[_day_part()], 0.55)
		return
	var bg := ScreenFrame.backdrop(self, "", 0.55)
	_backdrop_scene = Furnishings.build_scene(TextureRect.STRETCH_KEEP_ASPECT_COVERED)
	_backdrop_scene.name = "BackdropPicture"
	bg.add_child(_backdrop_scene)


func _add_tabs() -> void:
	# D-71: two enamel plates, >= 48 dp, the pressed one reads as pressed (toggle) and is named for TalkBack
	var row := HBoxContainer.new()
	row.name = "Tabs"
	row.add_theme_constant_override("separation", 10)
	var group := ButtonGroup.new()
	_tab_tools = _tab_button("TabTools", I18n.t(&"workshop.tab_tools"), group, "tools")
	_tab_furn = _tab_button("TabFurnishings", I18n.t(&"workshop.tab_furnishings"), group, "furnishings")
	_tab_practice = _tab_button("TabPractice", I18n.t(&"workshop.tab_practice"), group, "practice")
	row.add_child(_tab_tools)
	row.add_child(_tab_furn)
	row.add_child(_tab_practice)
	$Frame/VBox.add_child(row)
	$Frame/VBox.move_child(row, 2)
	_tab_tools.button_pressed = true


func _tab_button(node_name: String, text: String, group: ButtonGroup, tab: String) -> Button:
	var b := Button.new()
	b.name = node_name
	b.text = text
	b.toggle_mode = true
	b.button_group = group
	b.custom_minimum_size = Vector2(0, 48)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	b.clip_text = true
	b.toggled.connect(func(on: bool) -> void:
		if on:
			show_tab(tab))
	return b


## Switches the list between the tools, the furnishings and the practice locks. Public for tests.
func show_tab(tab: String) -> void:
	if _tab == tab and tools_list.get_child_count() > 0:
		return
	_tab = tab
	if _tab_furn != null:
		_tab_furn.set_pressed_no_signal(tab == "furnishings")
		_tab_tools.set_pressed_no_signal(tab == "tools")
		_tab_practice.set_pressed_no_signal(tab == "practice")
	if _map_frame != null:
		_map_frame.visible = tab == "tools"
	$Frame/VBox/Scroll.scroll_vertical = 0
	_preview = null
	_refresh()


func _refresh() -> void:
	var coins: int = Save.get_value("coins", 0)
	coins_label.text = "%s: %d" % [I18n.t(&"workshop.coins"), coins]
	if _backdrop_scene != null:
		Furnishings.refresh(_backdrop_scene)
	if _tab == "furnishings":
		_refresh_furnishings(coins)
		return
	if _tab == "practice":
		_refresh_practice()
		return
	for c in tools_list.get_children():
		tools_list.remove_child(c)  # out of the tree now, so the new rows keep their names
		c.queue_free()
	var tools: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(TOOLS_PATH))
	for tool in tools.get("tools", []):
		tools_list.add_child(_tool_card(tool, coins))


func _refresh_furnishings(coins: int) -> void:
	# the picture stays (so a bought item fades in); the rows are rebuilt
	for c in tools_list.get_children():
		if c != _preview:
			tools_list.remove_child(c)
			c.queue_free()
	if _preview == null and Furnishings.has_picture():
		_preview = _preview_frame()
		tools_list.add_child(_preview)
	elif _preview != null:
		Furnishings.refresh(_preview.find_child("WorkshopPicture", true, false))
	var note := ScreenFrame.wrap(Label.new())
	note.name = "FurnNote"
	note.theme_type_variation = &"Caption"
	note.text = I18n.t(&"workshop.furn_note")
	tools_list.add_child(note)
	for f in Furnishings.all():
		tools_list.add_child(_furnishing_card(f, coins))


func _refresh_practice() -> void:
	for c in tools_list.get_children():
		tools_list.remove_child(c)
		c.queue_free()
	var note := ScreenFrame.wrap(Label.new())
	note.name = "PracticeNote"
	note.theme_type_variation = &"Caption"
	note.text = I18n.t(&"practice.note")
	tools_list.add_child(note)
	if Practice.last_result != &"":
		# one line about the attempt just finished, then it is gone
		var res := ScreenFrame.wrap(Label.new())
		res.name = "PracticeResult"
		res.theme_type_variation = &"Heading"
		res.text = I18n.t(StringName("practice.result_%s" % Practice.last_result))
		tools_list.add_child(res)
		Practice.last_result = &""
	for fam in Practice.families():
		var head := ScreenFrame.wrap(Label.new())
		head.name = "Family_" + String(fam)
		head.theme_type_variation = &"Heading"
		head.text = I18n.t(StringName("family.%s.name" % fam))
		tools_list.add_child(head)
		for e in Practice.entries():
			if e["family"] == fam:
				tools_list.add_child(_practice_card(e))


## One practice lock as the same two-line row as a tool: the goal, then its state + "Practice".
## Public for tests.
func _practice_card(e: Dictionary) -> Control:
	var id: String = e["id"]
	var card := PanelContainer.new()
	card.name = "Practice_" + id
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	card.add_child(box)
	var goal := ScreenFrame.wrap(Label.new())
	goal.name = "Name"
	goal.text = I18n.t(e["goal_key"])
	goal.add_theme_font_size_override("font_size", 18)
	box.add_child(goal)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	box.add_child(row)
	var state := ScreenFrame.wrap(Label.new())
	state.name = "State"
	state.theme_type_variation = &"Caption"
	state.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(state)
	var action := Button.new()
	action.name = "Action"
	action.custom_minimum_size = Vector2(112, 48)
	action.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	action.mouse_filter = Control.MOUSE_FILTER_PASS
	row.add_child(action)
	if not Practice.unlocked(e):
		state.text = I18n.t(&"practice.locked")  # label only, like a progress reward (N-59)
		action.visible = false
	else:
		state.text = I18n.t(&"practice.goal_met" if Practice.goal_met(id) else &"practice.goal_open")
		action.text = I18n.t(&"practice.start")
		action.pressed.connect(_start_practice.bind(e))
	if "accessibility_name" in action:
		action.set("accessibility_name", "%s: %s. %s" % [action.text, goal.text, state.text])
	return card


func _start_practice(e: Dictionary) -> void:
	Practice.start(e)
	get_tree().change_scene_to_file(JobRun.lock_scene_path())


func _preview_frame() -> Control:
	# the workshop as a framed photo: whole picture visible (no crop), undimmed
	var frame := PanelContainer.new()
	frame.name = "Preview"
	frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	frame.mouse_filter = Control.MOUSE_FILTER_PASS
	frame.clip_contents = true
	var holder := Control.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vp := get_viewport_rect().size
	holder.custom_minimum_size.y = roundf(clampf(vp.y * (0.42 if vp.x < vp.y else 0.8), 200.0, 520.0))
	frame.add_child(holder)
	var pic := Furnishings.build_scene(TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
	holder.add_child(pic)
	pic.set_anchors_preset(Control.PRESET_FULL_RECT)
	pic.name = "WorkshopPicture"
	if "accessibility_name" in frame:
		frame.set("accessibility_name", I18n.t(&"workshop.furn_preview"))
	return frame


## One furnishing as the same two-line row as a tool. Public for tests.
func _furnishing_card(f: Dictionary, coins: int) -> Control:
	var id: String = f["id"]
	var price: int = int(f.get("price", 0))
	var card := PanelContainer.new()
	card.name = "Furn_" + id
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	card.add_child(box)
	var name_label := ScreenFrame.wrap(Label.new())
	name_label.name = "Name"
	name_label.text = I18n.t(StringName(f.get("i18n", "workshop.title")))
	name_label.add_theme_font_size_override("font_size", 18)
	box.add_child(name_label)
	var desc_key := StringName(f.get("desc", ""))
	if I18n.has_key(desc_key):
		var desc_label := ScreenFrame.wrap(Label.new())
		desc_label.name = "Desc"
		desc_label.theme_type_variation = &"Caption"
		desc_label.text = I18n.t(desc_key)
		box.add_child(desc_label)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	box.add_child(row)
	var state_label := ScreenFrame.wrap(Label.new())
	state_label.name = "State"
	state_label.theme_type_variation = &"Caption"
	state_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(state_label)
	var action := Button.new()
	action.name = "Action"
	action.custom_minimum_size = Vector2(112, 48)
	action.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	action.mouse_filter = Control.MOUSE_FILTER_PASS
	row.add_child(action)
	if Furnishings.owned(id):
		var on := Furnishings.shown(id)
		state_label.text = I18n.t(&"workshop.furn_in_place" if on else &"workshop.furn_stored")
		action.text = I18n.t(&"workshop.furn_hide" if on else &"workshop.furn_place")
		action.pressed.connect(func() -> void: Furnishings.set_shown(id, not on))
	elif not Furnishings.unlocked(f):
		# not a purchase yet: label only, like a progress reward (N-59)
		state_label.text = "%s — %s" % [I18n.t(&"workshop.price").format([price]),
			I18n.t(&"workshop.furn_from_chapter").format([int(f.get("chapter", 1))])]
		action.visible = false
	else:
		state_label.text = I18n.t(&"workshop.price").format([price])
		action.text = I18n.t(&"workshop.buy")
		action.disabled = coins < price
		if action.disabled:
			action.text = I18n.t(&"workshop.not_enough")
		action.pressed.connect(func() -> void: Furnishings.buy(id))
	if "accessibility_name" in action:
		action.set("accessibility_name", "%s: %s. %s" % [action.text, name_label.text, state_label.text])
	return card


## One tool as a two-line card. Public for tests (N-59 rules).
func _tool_card(tool: Dictionary, coins: int) -> Control:
	var id: String = tool["id"]
	var price: int = int(tool.get("price", 0))
	var owned: bool = Save.get_value("tools/%s/owned" % id, price == 0 and tool.get("unlock") == "start")
	var integrity: int = Save.get_value("tools/%s/integrity" % id, 100)
	var card := PanelContainer.new()
	card.name = "Tool_" + id
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	card.add_child(box)
	var name_label := ScreenFrame.wrap(Label.new())
	name_label.name = "Name"
	name_label.text = I18n.t(tool.get("i18n", &"common.close"))
	name_label.add_theme_font_size_override("font_size", 18)
	box.add_child(name_label)
	# T57: one short line on what the tool is for and what feedback it gives
	var desc_key := StringName("tool.%s.desc" % id)
	if I18n.has_key(desc_key):
		var desc_label := ScreenFrame.wrap(Label.new())
		desc_label.name = "Desc"
		desc_label.theme_type_variation = &"Caption"
		desc_label.text = I18n.t(desc_key)
		box.add_child(desc_label)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	box.add_child(row)
	var state_label := ScreenFrame.wrap(Label.new())
	state_label.name = "State"
	state_label.theme_type_variation = &"Caption"
	state_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(state_label)
	var action := Button.new()
	action.name = "Action"
	action.custom_minimum_size = Vector2(112, 48)
	action.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	action.mouse_filter = Control.MOUSE_FILTER_PASS
	row.add_child(action)
	if owned:
		if integrity >= 100:
			state_label.text = "%s %d%%" % [I18n.t(&"workshop.integrity"), integrity]
			action.visible = false  # N-59: nothing to repair
		else:
			var cost := repair_cost(price, integrity)
			state_label.text = "%s %d%%\n%s" % [I18n.t(&"workshop.integrity"), integrity,
				I18n.t(&"workshop.repair_cost").format([cost])]
			action.text = I18n.t(&"workshop.repair")
			action.disabled = coins < cost
			if action.disabled:
				action.text = I18n.t(&"workshop.not_enough")
			action.pressed.connect(_repair.bind(id, price))
	elif price == 0:
		# reward for progress (unlock: after_t1 etc.), not a purchase: label only (N-59)
		state_label.text = "%s — %s" % [I18n.t(&"workshop.reward"), I18n.t(&"workshop.reward_hint")]
		action.visible = false
	else:
		state_label.text = I18n.t(&"workshop.price").format([price])
		action.text = I18n.t(&"workshop.buy")
		action.disabled = coins < price
		if action.disabled:
			action.text = I18n.t(&"workshop.not_enough")
		action.pressed.connect(_buy.bind(id, price))
	# T70: several plates read "Buy"/"Repair"; the screen reader also hears which tool and its state
	if "accessibility_name" in action:
		action.set("accessibility_name", "%s: %s. %s" % [action.text, name_label.text, state_label.text])
	return card


func _buy(tool_id: String, price: int) -> void:
	var coins: int = Save.get_value("coins", 0)
	if coins < price:
		return
	Save.set_value("coins", coins - price)
	Save.set_value("tools/%s/owned" % tool_id, true)
	Save.set_value("tools/%s/integrity" % tool_id, 100)


func _repair(tool_id: String, price: int) -> void:
	var integrity: int = Save.get_value("tools/%s/integrity" % tool_id, 100)
	var cost := repair_cost(price, integrity)
	var coins: int = Save.get_value("coins", 0)
	if coins < cost:
		return
	Save.set_value("coins", coins - cost)
	Save.set_value("tools/%s/integrity" % tool_id, 100)
