extends Control
## Dev tool (spike 2, docs/TECH.md §4): one button per lock event, a resistance
## slider, a forced-fallback switch and a capabilities log.

const EVENTS := [&"contact", &"bind", &"near_shear", &"set", &"false_set", &"counter_rotate", &"overset", &"drop", &"stress", &"break", &"wear", &"gate_align", &"detector_trip", &"open"]

var _resistance := 0.0
var _resistance_on := false


func _ready() -> void:
	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.add_theme_constant_override("separation", 8)
	add_child(vb)

	var title := Label.new()
	title.text = I18n.t(&"dev.haptics_lab.title")
	vb.add_child(title)

	var caps := Label.new()
	caps.text = "%s: %s" % [I18n.t(&"dev.haptics_lab.caps"), str(Haptics.capabilities())]
	caps.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(caps)

	var grid := GridContainer.new()
	grid.columns = 3
	vb.add_child(grid)
	for e in EVENTS:
		var b := Button.new()
		b.text = String(e)
		b.pressed.connect(func() -> void: Haptics.play(e, 1.0, &"brass"))
		grid.add_child(b)

	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.value = 0.0
	slider.custom_minimum_size = Vector2(0, 48)
	var slabel := Label.new()
	slabel.text = I18n.t(&"dev.haptics_lab.resistance")
	vb.add_child(slabel)
	vb.add_child(slider)
	slider.value_changed.connect(func(v: float) -> void:
		_resistance = v
		if v > 0.0 and not _resistance_on:
			_resistance_on = true
			Haptics.begin_continuous(&"tension_resistance")
		if v <= 0.0 and _resistance_on:
			_resistance_on = false
			Haptics.end_continuous(&"tension_resistance")
		Haptics.update_continuous(&"tension_resistance", v, 0.3)
	)
