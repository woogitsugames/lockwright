class_name ChalkLayer
extends Control
## Chalk on the plate (ONBOARDING §1.8 / §4, D-53): the shear line, friction strokes beside the
## binding stack, the ledge under a set driver, a bracket over an overset chamber, chalk thumbs
## with arrows on the leather (which zone does what), and one or two lines of handwriting at the
## top edge of the plate (Caveat, OFL). Drawn strokes only: no panels, no icons, no colour codes;
## every mark is a shape, so it reads in greyscale.
##
## D-80 real chalk: everything on this layer (and the hint trail, ChalkHint) goes through one grain
## material (grain_material()): the alpha is broken by a fixed tooth of the surface (value noise in
## dp, fixed to the screen like the plate and the leather), so strokes and handwriting get the dry,
## broken edge of chalk instead of a clean vector line. No glow, no blur, no colour.
## The thumb hints (chalk thumb + arrows) are clamped inside the safe area (N-73: the right thumb
## hint ran off the right edge): clamp_hint_anchor(), hint_marks().
##
## The view fills `marks` every frame (screen positions already projected from the 3D section).

enum Level { OFF, REDUCED, FULL }

const FONT_PATH := "res://assets/fonts/Caveat-wght.ttf"
const C := Color(0.96, 0.95, 0.90)
const TEXT_SIZE := 26
const FADE_S := 0.18
## Chalk tooth: size of the surface grain in dp and how much of a stroke it eats (0..1).
const GRAIN_DP := 1.7
const GRAIN_STRENGTH := 0.6
## Margin kept between a hint mark and the safe-area edge (dp).
const SAFE_MARGIN := 6.0
## Reach of each thumb hint around its anchor (dp: left, top, right, bottom): chalk thumb + arrows.
const REACH := {
	"left": Vector4(24, 104, 24, 24),       # thumb + one arrow up
	"right": Vector4(92, 104, 92, 24),      # thumb + arrows left, right and up
	"vertical": Vector4(24, 104, 24, 92),   # thumb + arrows up and down (dial scroll)
}

const _GRAIN_SHADER := """
shader_type canvas_item;
render_mode unshaded;
// D-80 chalk grain. The tooth is fixed to the layer (local dp), so a moving stroke passes over the
// same grain, like chalk dragged over leather or brass. Only the alpha changes: no glow, no colour.
uniform float grain_dp = 1.7;
uniform float strength = 0.6;
varying vec2 p;
void vertex() {
	p = VERTEX;
}
float hash(vec2 q) {
	q = mod(q, 289.0);
	return fract(sin(dot(q, vec2(12.9898, 78.233))) * 43758.5453);
}
float vnoise(vec2 q) {
	vec2 i = floor(q);
	vec2 f = fract(q);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}
void fragment() {
	vec2 q = p / grain_dp;
	float n = vnoise(q) * 0.55 + vnoise(q * 2.3 + vec2(17.0, 5.0)) * 0.3 + vnoise(q * 0.31 + vec2(3.0, 41.0)) * 0.15;
	float keep = smoothstep(0.22, 0.6, n);
	COLOR.a *= mix(1.0, keep, strength);
}
"""

static var _grain: ShaderMaterial

var level := Level.OFF
var marks := {}            # see LockPhotorealView._update_chalk()
## N-90: while the hint ladder's chalk gesture plays (H1 ring, H2 gesture, H4 follow), it is THE thumb
## hint: the static chalk thumbs and arrows step aside instead of drawing a second ring and arrow.
var hide_thumbs := false
var text := "": set = set_text  # current handwritten line (already translated)
var _spoken := ""          # D-90: last line given to the screen reader
var _shown_text := ""
var _alpha := 0.0
var _font: Font


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	material = grain_material()


func _ready() -> void:
	if ResourceLoader.exists(FONT_PATH):
		var f := FontVariation.new()
		f.base_font = load(FONT_PATH)
		f.variation_opentype = {"wght": 600}
		_font = f
	else:
		_font = get_theme_default_font()


## The shared chalk material (D-80): one shader for the chalk layer and the hint trail.
static func grain_material() -> ShaderMaterial:
	if _grain == null:
		var sh := Shader.new()
		sh.code = _GRAIN_SHADER
		_grain = ShaderMaterial.new()
		_grain.shader = sh
		_grain.set_shader_parameter(&"grain_dp", GRAIN_DP)
		_grain.set_shader_parameter(&"strength", GRAIN_STRENGTH)
	return _grain


## Anchor of a thumb hint moved so its chalk thumb and arrows (REACH[kind]) stay inside `safe`.
static func clamp_hint_anchor(p: Vector2, safe: Rect2, kind: String) -> Vector2:
	if safe.size.x <= 0.0 or safe.size.y <= 0.0:
		return p
	var r: Vector4 = REACH.get(kind, REACH["right"])
	var lo := safe.position + Vector2(r.x, r.y) + Vector2.ONE * SAFE_MARGIN
	var hi := safe.end - Vector2(r.z, r.w) - Vector2.ONE * SAFE_MARGIN
	return Vector2(clampf(p.x, lo.x, maxf(lo.x, hi.x)), clampf(p.y, lo.y, maxf(lo.y, hi.y)))


## Rect a thumb hint of `kind` covers around its (clamped) anchor.
static func hint_rect(anchor: Vector2, kind: String, scale := 1.0) -> Rect2:
	var r: Vector4 = REACH.get(kind, REACH["right"]) * scale
	return Rect2(anchor - Vector2(r.x, r.y), Vector2(r.x + r.z, r.y + r.w))


## The safe area of this layer (dp, layer coordinates = view coordinates).
func safe_rect() -> Rect2:
	return SafeArea.shrink(self, Rect2(Vector2.ZERO, size))


## Thumb hints drawn now: [{kind, anchor, rect}], anchors already clamped (tests, N-73).
func hint_marks() -> Array:
	var out := []
	if level == Level.OFF or marks.is_empty() or hide_thumbs:
		return out
	var safe := safe_rect()
	var avoid := _avoid_rects()
	if avoid.is_empty():
		return _hint_marks_raw(safe)
	for m in _hint_marks_raw(safe):
		out.append(_placed(m, safe, avoid))
	return out


## N-90 / N-96: what the static thumb hints keep clear of — every interactive part of the screen the view
## reports (LockPhotorealView.hint_avoid_rects: the tension dial with its wrench arm, the picks in the
## roll, the loupe, the lock section); the loupe alone for a view without that method. Layer = view coordinates.
func _avoid_rects() -> Array[Rect2]:
	var out: Array[Rect2] = []
	var p := get_parent()
	if p != null and p.has_method("hint_avoid_rects"):
		for r: Rect2 in p.call("hint_avoid_rects"):
			if r.size.x > 0.0 and r.size.y > 0.0:
				out.append(r)
	elif p != null and p.has_method("loupe_rect"):
		var lr: Rect2 = p.call("loupe_rect")
		if lr.size.x > 0.0:
			out.append(lr.grow(4.0))
	return out


## The drawn parts of a thumb hint (thumb print, arrow shafts with heads) as thin rects, at `scale`.
static func hint_parts(anchor: Vector2, kind: String, scale := 1.0) -> Array[Rect2]:
	var out: Array[Rect2] = [Rect2(anchor - Vector2(19, 24) * scale, Vector2(38, 48) * scale)]
	var w := 9.0 * scale
	out.append(Rect2(anchor + Vector2(-w, -96.0 * scale), Vector2(2.0 * w, 68.0 * scale)))  # up
	match kind:
		"vertical":
			out.append(Rect2(anchor + Vector2(-w, 28.0 * scale), Vector2(2.0 * w, 56.0 * scale)))
		"right":
			out.append(Rect2(anchor + Vector2(-82.0 * scale, -w), Vector2(54.0 * scale, 2.0 * w)))
			out.append(Rect2(anchor + Vector2(28.0 * scale, -w), Vector2(54.0 * scale, 2.0 * w)))
	return out


static func _parts_clear(parts: Array[Rect2], avoid: Array[Rect2]) -> bool:
	for pr in parts:
		for r in avoid:
			if pr.intersects(r):
				return false
	return true


var _place_cache := {}


## The thumb hint moved to the nearest spot (same screen half: the thumb zones are halves) where none of
## its drawn parts touches an avoid rect and its whole reach stays in the safe area; smaller arrows
## (0.8, 0.65) when the full-size hint has no room. Cached: the avoid rects only change with the layout.
func _placed(m: Dictionary, safe: Rect2, avoid: Array[Rect2]) -> Dictionary:
	var kind := String(m["kind"])
	var a: Vector2 = m["anchor"]
	var key := "%s|%s|%s|%s|%s" % [kind, a, safe, avoid, size]
	if _place_cache.has(key):
		return _place_cache[key]
	var res := place_hint(a, kind, safe, avoid, size.x)
	if _place_cache.size() > 32:
		_place_cache.clear()
	_place_cache[key] = res
	return res


static func place_hint(a: Vector2, kind: String, safe: Rect2, avoid: Array[Rect2], width: float) -> Dictionary:
	var inner := safe.grow(-SAFE_MARGIN + 0.5)
	var left_zone := a.x < width * 0.5  # the side the hint was put on (mirrored with swapped thumbs)
	for sc in [1.0, 0.8, 0.65]:
		if inner.encloses(hint_rect(a, kind, sc)) and _parts_clear(hint_parts(a, kind, sc), avoid):
			return {"kind": kind, "anchor": a, "rect": hint_rect(a, kind, sc), "scale": sc}
		var best := Vector2.INF
		var bd := INF
		var step := 8.0
		for iy in range(-30, 31):
			for ix in range(-30, 31):
				var off := Vector2(ix, iy) * step
				var d := off.length_squared()
				if d >= bd:
					continue
				var c := a + off
				if (c.x < width * 0.5) != left_zone:
					continue  # stays in its thumb's half of the screen
				var hr := hint_rect(c, kind, sc)
				if not inner.encloses(hr) or not _parts_clear(hint_parts(c, kind, sc), avoid):
					continue
				bd = d
				best = c
		if best != Vector2.INF:
			return {"kind": kind, "anchor": best, "rect": hint_rect(best, kind, sc), "scale": sc}
	return {"kind": kind, "anchor": a, "rect": hint_rect(a, kind), "scale": 1.0}


func _hint_marks_raw(safe: Rect2) -> Array:
	var out := []
	if marks.get("hint_vertical", false) and marks.has("right_anchor"):
		out.append(_hint("vertical", marks["right_anchor"], safe))
	if marks.get("hint_left", false) and marks.has("left_anchor"):
		out.append(_hint("left", marks["left_anchor"], safe))
	if marks.get("hint_right", false) and marks.has("right_anchor"):
		out.append(_hint("right", marks["right_anchor"], safe))
	return out


static func _hint(kind: String, p: Vector2, safe: Rect2) -> Dictionary:
	var a := clamp_hint_anchor(p, safe, kind)
	return {"kind": kind, "anchor": a, "rect": hint_rect(a, kind)}


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
## A chalk stroke: a few thin, slightly offset passes (deterministic); the grain material breaks them.
func stroke(a: Vector2, b: Vector2, w: float = 2.5, alpha: float = 0.9) -> void:
	draw_stroke(self, a, b, w, alpha)


## The chalk stroke on any canvas item (ChalkHint draws its trail with it). shade: a thin dark
## under-pass, as under the handwriting, so the mark holds on bright brass (contrast, not glow).
static func draw_stroke(ci: CanvasItem, a: Vector2, b: Vector2, w: float = 2.5, alpha: float = 0.9, shade := false) -> void:
	if a.distance_squared_to(b) < 0.01:
		return
	var n := (b - a).normalized().orthogonal()
	var seed := int(a.x * 13.0 + a.y * 7.0 + b.x * 3.0) & 0xff
	if shade:
		ci.draw_line(a + Vector2(0.8, 1.2), b + Vector2(0.8, 1.2), Color(0, 0, 0, 0.35 * alpha), w + 0.5, true)
	ci.draw_line(a, b, Color(C, alpha), w, true)
	for k in 2:
		var off := n * (((seed >> k) & 3) - 1.5) * 0.45
		ci.draw_line(a + off, b + off, Color(C, alpha * 0.35), maxf(w - 1.0, 1.0), true)


## A hand-drawn chalk ring (the touch point): a slightly uneven circle whose stroke overshoots its
## start by ~25°, thinner where the chalk lands and lifts off.
static func draw_ring(ci: CanvasItem, c: Vector2, r: float, w: float = 2.5, alpha: float = 0.9, shade := false) -> void:
	var seg := 28
	var a0 := -PI * 0.62
	var sweep := TAU + 0.44
	var prev := Vector2.ZERO
	for i in seg + 1:
		var t := float(i) / seg
		var ang := a0 + sweep * t
		var rr := r * (1.0 + 0.045 * sin(ang * 3.0 + 0.7) + 0.02 * sin(ang * 7.0))
		var pt := c + Vector2(cos(ang), sin(ang)) * rr
		if i > 0:
			var taper := clampf(minf(t, 1.0 - t) * 8.0, 0.35, 1.0)
			draw_stroke(ci, prev, pt, w * (0.6 + 0.4 * taper), alpha * taper, shade)
		prev = pt


## Chalk arrowhead at `tip`, pointing along `dir`.
static func draw_head(ci: CanvasItem, tip: Vector2, dir: Vector2, w: float = 3.0, alpha: float = 0.9, shade := false) -> void:
	var d := dir.normalized()
	var n := d.orthogonal()
	draw_stroke(ci, tip, tip - d * 12.0 + n * 8.0, w, alpha, shade)
	draw_stroke(ci, tip, tip - d * 12.0 - n * 8.0, w, alpha, shade)


func arrow(from: Vector2, to: Vector2, w: float = 3.0) -> void:
	stroke(from, to, w)
	draw_head(self, to, to - from, w)


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
			"false_set":
				# DESIGN §1 "false set": the outline goes dashed. A dashed frame around the waist caught
				# on the shear line (D-121); by shape unlike the solid ledge of a set and the solid
				# bracket of an overset, so it reads in greyscale. Still picture, no motion.
				var fx0 := x - w * 0.7
				var fx1 := x + w * 0.7
				var fy0 := y - 16.0
				var fy1 := y + 16.0
				for k in 3:
					var u0 := k / 3.0
					var u1 := u0 + 0.2
					stroke(Vector2(lerpf(fx0, fx1, u0), fy0), Vector2(lerpf(fx0, fx1, u1), fy0), 2.5)
					stroke(Vector2(lerpf(fx0, fx1, u0), fy1), Vector2(lerpf(fx0, fx1, u1), fy1), 2.5)
					stroke(Vector2(fx0, lerpf(fy0, fy1, u0)), Vector2(fx0, lerpf(fy0, fy1, u1)), 2.5)
					stroke(Vector2(fx1, lerpf(fy0, fy1, u0)), Vector2(fx1, lerpf(fy0, fy1, u1)), 2.5)
			"overset", "jammed":
				# bracket over the chamber: "this one is too high"
				var top: float = st.get("top_y", y - 80.0)
				stroke(Vector2(x - w * 0.6, top + 12), Vector2(x - w * 0.6, top), 3.0)
				stroke(Vector2(x - w * 0.6, top), Vector2(x + w * 0.6, top), 3.0)
				stroke(Vector2(x + w * 0.6, top), Vector2(x + w * 0.6, top + 12), 3.0)
	# free chalk polylines (warded: the channel of each ward, the bolt band)
	for path in marks.get("paths", []):
		var pts: PackedVector2Array = path
		for i in pts.size() - 1:
			stroke(pts[i], pts[i + 1], 2.5, 0.8)
	# thumb hints, clamped inside the safe area (N-73)
	for h: Dictionary in hint_marks():
		var p: Vector2 = h["anchor"]
		var k: float = h.get("scale", 1.0)
		thumb(p, 22.0 * k)
		arrow(p + Vector2(0, -30) * k, p + Vector2(0, -92) * k)
		match String(h["kind"]):
			"vertical":
				arrow(p + Vector2(0, 30) * k, p + Vector2(0, 80) * k)
			"right":
				arrow(p + Vector2(-30, 0) * k, p + Vector2(-78, 0) * k)
				arrow(p + Vector2(30, 0) * k, p + Vector2(78, 0) * k)
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


## D-90: the chalk line is drawn, so a screen reader cannot see it: the layer carries it as its
## accessible name and a new line is announced (politely) while a screen reader runs.
func set_text(v: String) -> void:
	text = v
	if v == "" or v == _spoken:
		return
	_spoken = v
	set("accessibility_name", v)
	if UiA11y.screen_reader_active():
		UiA11y.announce(v, false)
