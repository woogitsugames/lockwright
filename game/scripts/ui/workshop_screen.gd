extends Control
## Workshop: tool list from game/data/tools.json, buy/repair with in-game coins only
## (no real money, TOOLS.md §1). All text via i18n.

@onready var coins_label: Label = $VBox/CoinsLabel
@onready var tools_list: VBoxContainer = $VBox/Scroll/VBox/ToolsList
@onready var back_button: Button = $BackButton

const TOOLS_PATH := "res://data/tools.json"


func _ready() -> void:
	Sfx.play_ambience(&"workshop")
	SafeArea.apply(self)
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
