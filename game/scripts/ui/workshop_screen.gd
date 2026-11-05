extends Control
## Workshop: tool list from game/data/tools.json, buy/repair with in-game coins only
## (no real money, TOOLS.md §1). All text via i18n.

@onready var coins_label: Label = $VBox/CoinsLabel
@onready var tools_list: VBoxContainer = $VBox/Scroll/VBox/ToolsList
@onready var back_button: Button = $BackButton

const TOOLS_PATH := "res://data/tools.json"

# G08 workshop backgrounds by time of day
const WORKSHOP_BG := {
	"morning": "01-workshop-morning-portrait.webp",
	"afternoon": "06-workbench-afternoon-landscape.webp",
	"evening": "03-workshop-evening-portrait.webp",
	"night": "08-lamplight-evening-landscape.webp",
}


func _day_part() -> String:
	var hour := OS.get_time()["hour"]
	if hour >= 6 and hour < 12:
		return "morning"
	if hour >= 12 and hour < 18:
		return "afternoon"
	if hour >= 18 and hour < 23:
		return "evening"
	return "night"


func _add_background() -> void:
	var tex := load("res://assets/ui/gpt/workshop/" + WORKSHOP_BG[_day_part()])
	if tex == null:
		return
	var bg := TextureRect.new()
	bg.texture = tex
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.modulate = Color(1, 1, 1, 0.3)
	add_child(bg)
	move_child(bg, 0)


func _add_map() -> void:
	# G15 district map with chapter pins for the current chapter
	var chapter := clampi(int(Save.get_value("chapter", 1)), 1, 6)
	var path := "res://assets/ui/gpt/map/zameczno_chapter_%d.%s"
	var tex: Texture2D = load(path % [chapter, "webp" if chapter >= 4 else "png"])
	if tex == null:
		tex = load("res://assets/ui/gpt/map/zameczno_base.png")
	if tex == null:
		return
	var map := TextureRect.new()
	map.texture = tex
	map.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	map.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	map.custom_minimum_size = Vector2(0, 180)
	map.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	$VBox.add_child(map)
	$VBox.move_child(map, 1)


func _ready() -> void:
	Sfx.play_ambience(&"workshop")
	SafeArea.apply(self)
	_add_background()
	_add_map()
	$VBox/Title.text = I18n.t(&"workshop.title")
	back_button.text = I18n.t(&"common.back")
	back_button.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	_refresh()
	Save.changed.connect(_refresh)


func _refresh() -> void:
	coins_label.text = "%s: %d" % [I18n.t(&"workshop.coins"), Save.get_value("coins", 0)]
	for c in tools_list.get_children():
		c.queue_free()
	var tools: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(TOOLS_PATH))
	for tool in tools.get("tools", []):
		var row := HBoxContainer.new()
		var owned: bool = Save.get_value("tools/%s/owned" % tool["id"], tool.get("price", 0) == 0 and tool.get("unlock") == "start")
		var integrity: int = Save.get_value("tools/%s/integrity" % tool["id"], 100)
		var name_label := Label.new()
		name_label.text = I18n.t(tool.get("i18n", &"common.close"))
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_label)
		var state_label := Label.new()
		if owned:
			state_label.text = "%s %d%%" % [I18n.t(&"workshop.integrity"), integrity]
		else:
			state_label.text = "%d %s" % [tool.get("price", 0), I18n.t(&"common.coins")]
		row.add_child(state_label)
		var action := Button.new()
		action.custom_minimum_size = Vector2(96, 48)
		if owned:
			action.text = I18n.t(&"workshop.repair")
			action.disabled = integrity >= 100
			action.pressed.connect(_repair.bind(tool["id"], tool.get("price", 0)))
		else:
			action.text = I18n.t(&"workshop.buy")
			action.disabled = Save.get_value("coins", 0) < tool.get("price", 0)
			action.pressed.connect(_buy.bind(tool["id"], tool.get("price", 0)))
		row.add_child(action)
		tools_list.add_child(row)


func _buy(tool_id: String, price: int) -> void:
	var coins: int = Save.get_value("coins", 0)
	if coins < price:
		return
	Save.set_value("coins", coins - price)
	Save.set_value("tools/%s/owned" % tool_id, true)
	Save.set_value("tools/%s/integrity" % tool_id, 100)


func _repair(tool_id: String, price: int) -> void:
	var integrity: int = Save.get_value("tools/%s/integrity" % tool_id, 100)
	var cost := maxi(5, int(price * (0.35 if integrity <= 0 else 0.15)))
	var coins: int = Save.get_value("coins", 0)
	if coins < cost:
		return
	Save.set_value("coins", coins - cost)
	Save.set_value("tools/%s/integrity" % tool_id, 100)
