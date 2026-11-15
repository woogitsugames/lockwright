extends Control
## D-132: sheet of the 15 lock family signs (FamilyMark) for review: each at the size of the job list
## (36 dp) and doubled, in ink on enamel and in chalk on the dark plate, with the family's name.
##   shot_scene.tscn -- --scene=res://tests/family_mark_sheet.tscn --size=915x700 --out=/tmp/marks.png

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.10, 0.08, 0.06)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var grid := GridContainer.new()
	grid.columns = 2 if get_viewport_rect().size.x < 600.0 else 3
	grid.set_anchors_preset(Control.PRESET_FULL_RECT)
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	grid.offset_left = 8
	grid.offset_top = 8
	grid.offset_right = -8
	grid.offset_bottom = -8
	add_child(grid)
	for fam: String in FamilyMark.FAMILIES:
		var cell := VBoxContainer.new()
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		for spec: Array in [[1.0, false], [2.0, false], [1.0, true], [2.0, true]]:
			var plate := PanelContainer.new()
			var sb := StyleBoxFlat.new()
			sb.bg_color = Color(0.10, 0.075, 0.055) if spec[1] else Color(0.91, 0.87, 0.78)
			sb.set_content_margin_all(4)
			sb.set_corner_radius_all(4)
			plate.add_theme_stylebox_override(&"panel", sb)
			var mark := FamilyMark.new(fam, Color(0.96, 0.95, 0.90) if spec[1] else Color(0.11, 0.09, 0.07))
			mark.custom_minimum_size = Vector2.ONE * FamilyMark.SIZE_DP * float(spec[0])
			mark.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			plate.add_child(mark)
			plate.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			row.add_child(plate)
		cell.add_child(row)
		var name_label := Label.new()
		name_label.theme_type_variation = &"Caption"
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		name_label.text = I18n.t(StringName("family.%s.name" % fam))
		cell.add_child(name_label)
		grid.add_child(cell)
