class_name ChalkLayer
extends Control
## Chalk on the plate (ONBOARDING §1.8 / §4, D-53): the shear line, friction strokes beside the
## binding stack, the ledge under a set driver, a bracket over an overset chamber, chalk thumbs
## with arrows on the leather (which zone does what), and one or two lines of handwriting at the
## top edge of the plate (Caveat, OFL). Drawn strokes only: no panels, no icons, no colour codes;
## every mark is a shape, so it reads in greyscale.
##
## The view fills `marks` every frame (screen positions already projected from the 3D section).

enum Level { OFF, REDUCED, FULL }

const FONT_PATH := "res://assets/fonts/Caveat-wght.ttf"
const C := Color(0.96, 0.95, 0.90)
const TEXT_SIZE := 26
const FADE_S := 0.18

var level := Level.OFF
var marks := {}            # see LockPhotorealView._update_chalk()
var text := ""             # current handwritten line (already translated)
var _shown_text := ""
var _alpha := 0.0
var _font: Font


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _ready() -> void:
	if ResourceLoader.exists(FONT_PATH):
		var f := FontVariation.new()
		f.base_font = load(FONT_PATH)
		f.variation_opentype = {"wght": 600}
		_font = f
	else:
		_font = get_theme_default_font()


## Fades the text in and out (150–250 ms, DESIGN.md) when the line changes.
func tick(delta: float) -> void:
	if text != _shown_text:
		_alpha = maxf(_alpha - delta / FADE_S, 0.0)
		if _alpha <= 0.0:
			_shown_text = text
	elif _shown_text != "":
		_alpha = minf(_alpha + delta / FADE_S, 1.0)
	queue_redraw()


func shown_text() -> String:
	return _shown_text if _alpha > 0.5 else ""


# ------------------------------------------------------------------ strokes
## A chalk stroke: a few thin, slightly offset passes (deterministic, no texture).
func stroke(a: Vector2, b: Vector2, w: float = 2.5, alpha: float = 0.9) -> void:
	var n := (b - a).normalized().orthogonal()
	var seed := int(a.x * 13.0 + a.y * 7.0 + b.x * 3.0) & 0xff
	draw_line(a, b, Color(C, alpha), w, true)
	for k in 2:
		var off := n * (((seed >> k) & 3) - 1.5) * 0.45
		draw_line(a + off, b + off, Color(C, alpha * 0.35), maxf(w - 1.0, 1.0), true)


func arrow(from: Vector2, to: Vector2, w: float = 3.0) -> void:
	stroke(from, to, w)
	var d := (to - from).normalized()
	var n := d.orthogonal()
	stroke(to, to - d * 12.0 + n * 8.0, w)
	stroke(to, to - d * 12.0 - n * 8.0, w)


func thumb(c: Vector2, r: float = 22.0) -> void:
	# chalk thumb print outline: an upright oval with two inner whorls
	var pts := PackedVector2Array()
	for i in 33:
		var a := TAU * i / 32.0
		pts.append(c + Vector2(cos(a) * r * 0.78, sin(a) * r))
	draw_polyline(pts, Color(C, 0.9), 2.5, true)
	draw_arc(c + Vector2(0, 2), r * 0.45, PI * 1.1, PI * 1.9, 12, Color(C, 0.6), 2.0, true)
	draw_arc(c + Vector2(0, 4), r * 0.25, PI * 1.1, PI * 1.9, 10, Color(C, 0.6), 2.0, true)


func label(pos: Vector2, s: String, size: int = TEXT_SIZE, alpha: float = 1.0, width: float = -1.0) -> void:
	if _font == null or s == "":
		return
	# thin dark under-stroke keeps the chalk readable on bright brass (contrast, not glow)
	draw_multiline_string(_font, pos + Vector2(1, 1.5), s, HORIZONTAL_ALIGNMENT_LEFT, width, size, 2, Color(0, 0, 0, 0.55 * alpha))
	draw_multiline_string(_font, pos, s, HORIZONTAL_ALIGNMENT_LEFT, width, size, 2, Color(C, alpha))


func _draw() -> void:
	if level == Level.OFF or marks.is_empty():
		return
	var full := level == Level.FULL
	# shear line (≥ 2 dp, CLAUDE.md): dashed chalk across the chambers, gaps between dashes
	if marks.has("shear"):
		var a: Vector2 = marks["shear"][0]
		var b: Vector2 = marks["shear"][1]
		var dashes := 14
		for i in dashes:
			var t0 := float(i) / dashes
			var t1 := t0 + 0.7 / dashes
			stroke(a.lerp(b, t0), a.lerp(b, t1), 2.5, 0.85)
	for st: Dictionary in marks.get("stacks", []):
		var x: float = st["x"]
		var y: float = st["shear_y"]
		var w: float = st.get("w", 30.0)
		match String(st["state"]):
			"bound", "near":
				if full or marks.get("friction", false):
					# three short friction strokes on the side the driver leans to
					for k in 3:
						var yy := y - 10.0 - k * 8.0
						stroke(Vector2(x + w * 0.55, yy + 4), Vector2(x + w * 0.55 + 9, yy - 3), 2.5)
			"set":
				# the ledge: a short underline under the driver, on the shear line
				stroke(Vector2(x - w * 0.5, y + 4), Vector2(x + w * 0.5, y + 4), 3.0)
			"overset", "jammed":
				# bracket over the chamber: "this one is too high"
				var top: float = st.get("top_y", y - 80.0)
				stroke(Vector2(x - w * 0.6, top + 12), Vector2(x - w * 0.6, top), 3.0)
				stroke(Vector2(x - w * 0.6, top), Vector2(x + w * 0.6, top), 3.0)
				stroke(Vector2(x + w * 0.6, top), Vector2(x + w * 0.6, top + 12), 3.0)
	if marks.get("hint_left", false):
		var l: Vector2 = marks["left_anchor"]
		thumb(l)
		arrow(l + Vector2(0, -30), l + Vector2(0, -92))
	if marks.get("hint_right", false):
		var r: Vector2 = marks["right_anchor"]
		thumb(r)
		arrow(r + Vector2(-30, 0), r + Vector2(-78, 0))
		arrow(r + Vector2(30, 0), r + Vector2(78, 0))
		arrow(r + Vector2(0, -30), r + Vector2(0, -92))
	if marks.get("hint_down", false) and marks.has("wrench_tip"):
		var wt: Vector2 = marks["wrench_tip"]
		arrow(wt + Vector2(18, -40), wt + Vector2(18, 10))
	if marks.has("zone_label"):
		label(marks["zone_label_pos"], marks["zone_label"], 22, 0.9)
	if marks.has("pause_label"):
		label(marks["pause_label_pos"], marks["pause_label"], 22, 0.9)
	if _shown_text != "":
		var tr: Rect2 = marks.get("text_rect", Rect2(16, 16, size.x - 96, 70))
		label(tr.position + Vector2(0, TEXT_SIZE), _shown_text, TEXT_SIZE, _alpha, tr.size.x)
