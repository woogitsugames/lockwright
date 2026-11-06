extends Control
## Workshop: tool list from game/data/tools.json, buy/repair with in-game coins only
## (no real money, TOOLS.md §1). All text via i18n.
## N-59: every tool is a two-line card that never widens the screen:
##   line 1 = tool name (wraps), line 2 = state/price (wraps) + action plate (>= 96x48).
## Repair is hidden at 100%; a progress reward has no button; a purchase you cannot
## afford reads "Not enough coins" on an outline-only plate (not colour alone).

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
	$Frame/VBox.move_child(frame, 2)
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
	ScreenFrame.backdrop(self, "res://assets/ui/gpt/workshop/" + WORKSHOP_BG[_day_part()], 0.55)
	ScreenFrame.fit(self, $Frame)
	_add_map()
	$Frame/VBox/Header/Title.text = I18n.t(&"workshop.title")
	ScreenFrame.ellipsis($Frame/VBox/Header/Title)
	back_button.text = "‹ " + I18n.t(&"common.back")
	back_button.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	$Frame/VBox/Scroll.scroll_deadzone = 12
	_refresh()
	Save.changed.connect(_refresh)
	ScreenFrame.enter($Frame/VBox/Scroll)
	ScreenFrame.wire_sounds(self)  # S05 enamel-plate sounds


static func repair_cost(price: int, integrity: int) -> int:
	return maxi(5, int(price * (0.35 if integrity <= 0 else 0.15)))


func _refresh() -> void:
	var coins: int = Save.get_value("coins", 0)
	coins_label.text = "%s: %d" % [I18n.t(&"workshop.coins"), coins]
	for c in tools_list.get_children():
		c.queue_free()
	var tools: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(TOOLS_PATH))
	for tool in tools.get("tools", []):
		tools_list.add_child(_tool_card(tool, coins))


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
