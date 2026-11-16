class_name FamilyMark
extends Control
## D-132 (VQA-19): the lock family as a small hand-drawn sign on a job plate: ink on an open (enamel)
## plate, chalk on a finished (dark) one. Strokes only, one colour, no fill, no badge: each of the 15
## families (lockcore/tiers.json) is its own shape, so the signs differ in greyscale. The strokes go
## through the chalk grain shader of ChalkLayer (D-80), which gives the dry, broken edge of a hand-drawn line.
## The sign is decoration for the eye: the plate itself carries the family name for screen readers.
##
## A sign is a list of primitives in a unit box (0..1, y down):
##   {"l": PackedVector2Array}            open polyline
##   {"p": PackedVector2Array}            closed polyline
##   {"c": Vector2, "r": float}           circle outline
##   {"e": Vector2, "r": Vector2}         ellipse outline
##   {"a": Vector2, "r": float, "f": from, "t": to}   arc (radians)
##   {"d": Vector2, "r": float}           filled dot

const FAMILIES: PackedStringArray = [
	"pin_tumbler", "wafer", "wooden_pin", "lever", "lever_detector", "ring_combo", "warded", "dial_safe",
	"combo", "dimple", "disc_detainer", "egyptian", "axial_slider", "time_lock", "magnetic",
]
## Side of the sign at 100 % text (dp). DESIGN: parts that carry meaning are >= 28 dp.
const SIZE_DP := 36.0
const MIN_STROKE_DP := 2.0
const GRAIN_STRENGTH := 0.3

static var _grain: ShaderMaterial
## Tests: how many times a sign was drawn since the start. A sign is drawn when it appears or
## changes (family, ink, size), never per frame: the engine keeps the drawn commands.
static var draws := 0

var family := "": set = set_family
var ink := Color(0.11, 0.09, 0.07): set = set_ink


func _init(p_family := "", p_ink := Color(0.11, 0.09, 0.07)) -> void:
	family = p_family
	ink = p_ink
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	material = grain()
	var side := side_dp()
	custom_minimum_size = Vector2(side, side)


## The chalk grain of ChalkLayer (D-80: same shader, same tooth), eating less of the stroke: a sign
## is 2 dp wide at 36 dp, and at the full chalk strength the line breaks into dots.
static func grain() -> ShaderMaterial:
	if _grain == null:
		_grain = ShaderMaterial.new()
		_grain.shader = ChalkLayer.grain_material().shader
		_grain.set_shader_parameter(&"grain_dp", ChalkLayer.GRAIN_DP)
		_grain.set_shader_parameter(&"strength", GRAIN_STRENGTH)
	return _grain


## The sign grows with the text, but slower: 36 dp at 100 %, 48 dp at 200 %.
static func side_dp() -> float:
	var s: float = UiA11y.text_scale()
	return roundf(SIZE_DP * (1.0 + (clampf(s, 1.0, 2.0) - 1.0) / 3.0))


func set_family(f: String) -> void:
	if f == family:
		return
	family = f
	queue_redraw()


func set_ink(c: Color) -> void:
	if c == ink:
		return
	ink = c
	queue_redraw()


static func has_mark(f: String) -> bool:
	return not strokes(f).is_empty()


func _draw() -> void:
	var side := minf(size.x, size.y)
	if side <= 0.0:
		return
	draws += 1
	var o := (size - Vector2(side, side)) * 0.5
	var w := maxf(MIN_STROKE_DP, side * 0.058)
	for s: Dictionary in strokes(family):
		if s.has("l") or s.has("p"):
			var src: PackedVector2Array = s.get("l", s.get("p", PackedVector2Array()))
			var pts := PackedVector2Array()
			for p in src:
				pts.append(o + p * side)
			if s.has("p"):
				pts.append(pts[0])
			draw_polyline(pts, ink, w, true)
			for p in pts:  # round joints and ends: a pen, not a plotter
				draw_circle(p, w * 0.5, ink)
		elif s.has("c"):
			draw_arc(o + (s["c"] as Vector2) * side, float(s["r"]) * side, 0.0, TAU, 40, ink, w, true)
		elif s.has("e"):
			var c: Vector2 = s["e"]
			var r: Vector2 = s["r"]
			var pts := PackedVector2Array()
			for i in 33:
				var a := TAU * i / 32.0
				pts.append(o + (c + Vector2(cos(a) * r.x, sin(a) * r.y)) * side)
			draw_polyline(pts, ink, w, true)
		elif s.has("a"):
			draw_arc(o + (s["a"] as Vector2) * side, float(s["r"]) * side, float(s["f"]), float(s["t"]), 24, ink, w, true)
		elif s.has("d"):
			draw_circle(o + (s["d"] as Vector2) * side, maxf(float(s["r"]) * side, w * 0.75), ink)


static func _l(a: Array) -> Dictionary:
	var pts := PackedVector2Array()
	for i in range(0, a.size(), 2):
		pts.append(Vector2(a[i], a[i + 1]))
	return {"l": pts}


static func _p(a: Array) -> Dictionary:
	return {"p": _l(a)["l"]}


static func _rect(x0: float, y0: float, x1: float, y1: float) -> Dictionary:
	return _p([x0, y0, x1, y0, x1, y1, x0, y1])


## The drawing of one family; empty for a family without a sign.
static func strokes(f: String) -> Array:
	match f:
		"pin_tumbler":  # three pin stacks cut at different heights, and the shear line
			return [
				_l([0.06, 0.60, 0.94, 0.60]),
				_l([0.24, 0.12, 0.24, 0.40]), _l([0.24, 0.50, 0.24, 0.86]),
				_l([0.50, 0.12, 0.50, 0.52]), _l([0.50, 0.62, 0.50, 0.86]),
				_l([0.76, 0.12, 0.76, 0.28]), _l([0.76, 0.38, 0.76, 0.86]),
			]
		"wafer":  # a plug with flat wafers sticking out above and below in turn
			return [
				_rect(0.08, 0.32, 0.92, 0.68),
				_l([0.24, 0.12, 0.24, 0.68]), _l([0.41, 0.32, 0.41, 0.88]),
				_l([0.59, 0.12, 0.59, 0.68]), _l([0.76, 0.32, 0.76, 0.88]),
			]
		"wooden_pin":  # a block over a bolt, two pegs dropping into it
			return [
				_rect(0.06, 0.56, 0.94, 0.82),
				_p([0.26, 0.56, 0.26, 0.16, 0.74, 0.16, 0.74, 0.56]),
				_l([0.40, 0.30, 0.40, 0.68]), _l([0.60, 0.30, 0.60, 0.68]),
				{"d": Vector2(0.40, 0.30), "r": 0.05}, {"d": Vector2(0.60, 0.30), "r": 0.05},
			]
		"lever":  # a stack of three plates, each with its gate in a different place
			return [
				_rect(0.06, 0.14, 0.82, 0.32), _rect(0.16, 0.41, 0.94, 0.59), _rect(0.06, 0.68, 0.86, 0.86),
				_l([0.58, 0.14, 0.58, 0.32]), _l([0.44, 0.41, 0.44, 0.59]), _l([0.66, 0.68, 0.66, 0.86]),
			]
		"lever_detector":  # the same stack, the top plate thrown up: the detector has caught it
			return [
				_p([0.06, 0.40, 0.78, 0.08, 0.85, 0.24, 0.13, 0.56]),
				_rect(0.16, 0.60, 0.94, 0.74), _rect(0.06, 0.80, 0.86, 0.94),
				{"d": Vector2(0.93, 0.36), "r": 0.06},
			]
		"ring_combo":  # three rings threaded on one axis
			return [
				_l([0.03, 0.50, 0.15, 0.50]), _l([0.85, 0.50, 0.97, 0.50]),
				{"e": Vector2(0.26, 0.50), "r": Vector2(0.10, 0.34)},
				{"e": Vector2(0.50, 0.50), "r": Vector2(0.10, 0.34)},
				{"e": Vector2(0.74, 0.50), "r": Vector2(0.10, 0.34)},
			]
		"warded":  # an old key: bow, shank, notched bit
			return [
				{"c": Vector2(0.20, 0.42), "r": 0.15},
				_l([0.35, 0.42, 0.94, 0.42]),
				_l([0.64, 0.42, 0.64, 0.80, 0.73, 0.80, 0.73, 0.64, 0.81, 0.64, 0.81, 0.80, 0.90, 0.80, 0.90, 0.42]),
			]
		"dial_safe":  # a dial: rim, graduation, knob, index above
			var out := [{"c": Vector2(0.5, 0.54), "r": 0.38}, {"c": Vector2(0.5, 0.54), "r": 0.13}]
			for i in 8:
				var a := TAU * i / 8.0
				var d := Vector2(cos(a), sin(a))
				out.append(_l([0.5 + d.x * 0.38, 0.54 + d.y * 0.38, 0.5 + d.x * 0.27, 0.54 + d.y * 0.27]))
			out.append(_p([0.43, 0.03, 0.57, 0.03, 0.5, 0.12]))
			return out
		"combo":  # three number wheels in a housing: 0, 4, 7
			return [
				_rect(0.04, 0.20, 0.96, 0.80),
				_l([0.345, 0.20, 0.345, 0.80]), _l([0.655, 0.20, 0.655, 0.80]),
				{"e": Vector2(0.195, 0.50), "r": Vector2(0.065, 0.14)},
				_l([0.54, 0.64, 0.54, 0.36, 0.44, 0.55, 0.57, 0.55]),
				_l([0.75, 0.36, 0.87, 0.36, 0.79, 0.64]),
			]
		"dimple":  # a flat key blade with dimples in two rows
			return [
				_p([0.04, 0.32, 0.86, 0.32, 0.96, 0.50, 0.86, 0.68, 0.04, 0.68]),
				{"d": Vector2(0.20, 0.43), "r": 0.055}, {"d": Vector2(0.37, 0.57), "r": 0.055},
				{"d": Vector2(0.54, 0.43), "r": 0.055}, {"d": Vector2(0.71, 0.57), "r": 0.055},
			]
		"disc_detainer":  # one disc from the front: a notch in the rim, the key slot turned out of line
			var slot := PackedVector2Array()
			for corner: Vector2 in [Vector2(-0.19, -0.075), Vector2(0.19, -0.075), Vector2(0.19, 0.075), Vector2(-0.19, 0.075)]:
				slot.append(Vector2(0.5, 0.54) + corner.rotated(-0.6))
			return [
				{"a": Vector2(0.5, 0.5), "r": 0.40, "f": -PI * 0.5 + 0.30, "t": PI * 1.5 - 0.30},
				_l([0.38, 0.12, 0.38, 0.25, 0.62, 0.25, 0.62, 0.12]),
				{"p": slot},
			]
		"egyptian":  # a wooden bolt crossing a post, three pegs in a row
			return [
				_p([0.38, 0.06, 0.62, 0.06, 0.62, 0.36, 0.95, 0.36, 0.95, 0.64, 0.62, 0.64, 0.62, 0.94, 0.38, 0.94,
					0.38, 0.64, 0.05, 0.64, 0.05, 0.36, 0.38, 0.36]),
				{"d": Vector2(0.36, 0.50), "r": 0.045}, {"d": Vector2(0.50, 0.50), "r": 0.045},
				{"d": Vector2(0.64, 0.50), "r": 0.045},
			]
		"axial_slider":  # sliders round a post, seen from the front: rays of unequal length
			var rays := [{"c": Vector2(0.5, 0.5), "r": 0.11}]
			var reach := [0.44, 0.33, 0.40, 0.30, 0.44, 0.36, 0.30]
			for i in 7:
				var a := TAU * i / 7.0 - PI * 0.5
				var d := Vector2(cos(a), sin(a))
				rays.append(_l([0.5 + d.x * 0.21, 0.5 + d.y * 0.21, 0.5 + d.x * reach[i], 0.5 + d.y * reach[i]]))
			return rays
		"time_lock":  # a case with two clock movements
			return [
				_rect(0.04, 0.18, 0.96, 0.82),
				{"c": Vector2(0.29, 0.50), "r": 0.17}, {"c": Vector2(0.71, 0.50), "r": 0.17},
				_l([0.29, 0.38, 0.29, 0.50, 0.37, 0.55]), _l([0.71, 0.38, 0.71, 0.50, 0.63, 0.55]),
			]
		"magnetic":  # a horseshoe magnet with its two poles marked
			return [
				_l([0.14, 0.10, 0.14, 0.52]), _l([0.38, 0.10, 0.38, 0.52]),
				_l([0.62, 0.10, 0.62, 0.52]), _l([0.86, 0.10, 0.86, 0.52]),
				_l([0.14, 0.10, 0.38, 0.10]), _l([0.62, 0.10, 0.86, 0.10]),
				_l([0.14, 0.27, 0.38, 0.27]), _l([0.62, 0.27, 0.86, 0.27]),
				{"a": Vector2(0.5, 0.52), "r": 0.36, "f": 0.0, "t": PI},
				{"a": Vector2(0.5, 0.52), "r": 0.12, "f": 0.0, "t": PI},
			]
	return []
