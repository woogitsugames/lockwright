class_name PaperProp
extends Control
## N-80: a verification card with no G14 prop photo, drawn in the game as a physical piece of paper in
## the G14 paper style (warm off-white stock with a fixed grain, ink in dark umber, a red-brown stamp),
## laid on the dark card plate with a slight turn and a soft contact shadow. Not a UI panel: no frames,
## no icons, no colour codes. The readable words come from i18n (verify.paper.*, 5 languages); body
## copy is a few illegible ink bars, like the G14 lease (a game prop, not a real document).
##
## Styles (card type -> style in JobVerify.CARD_PAPER):
##   note        witness: a page from a lined notebook, a handwritten statement (Caveat) and a signature
##   letterhead  institution: letterhead rule, heading, one line, ink bars, round stamp, signature
##   invoice     invoice: heading, number line, a table of item bars with an amount column, total
##   till        customer receipt: a narrow till slip, centred lines, total, zig-zag torn foot
##   deed        deed / inheritance / police / bailiff: heading, bars, embossed seal, two signatures
##   resolution  residents' resolution: heading, bars, a column of signatures on lines
##   envelope    letter: envelope with flap fold, stamp and postmark, the address in handwriting strokes
##   photo       photo: a bordered print of the client (G09 portrait) or of the place
##   phone       address_app: the client's phone, a street map with a pin and the address block

const PAPER := Color(0.925, 0.886, 0.812)         # G14 paper (236, 226, 207)
const PAPER_NOTE := Color(0.949, 0.922, 0.851)    # G14 note stock (242, 235, 217)
const ENVELOPE := Color(0.91, 0.867, 0.784)       # G14 envelope (232, 221, 200)
const INK := Color(0.204, 0.184, 0.161)           # G14 text (52, 47, 41)
const PEN := Color(0.11, 0.13, 0.24)              # ballpoint for handwriting (blue-black, not a UI colour)
const INK_BAR := Color(0.302, 0.267, 0.224, 0.62) # G14 illegible lines (77, 68, 57, 165)
const RULE := Color(0.392, 0.345, 0.275, 0.6)     # G14 rules (100, 88, 70, 150)
const STAMP := Color(0.525, 0.247, 0.212, 0.74)   # G14 stamp ink (134, 63, 54, 188)
const NOTE_LINE := Color(0.42, 0.5, 0.56, 0.32)   # faint ruling of a notebook page
const SHADOW := Color(0, 0, 0, 0.32)
const FONT_HEAD := "res://assets/fonts/BonaNova-Bold.ttf"
const FONT_BODY := "res://assets/fonts/AtkinsonHyperlegibleNext-wght.ttf"
const FONT_HAND := "res://assets/fonts/Caveat-wght.ttf"
const GRAIN_PX := 96

## Sheet proportions (width / height) per style.
const ASPECT := {
	"note": 0.8, "letterhead": 0.72, "invoice": 0.72, "till": 0.44, "deed": 0.72, "resolution": 0.72,
	"envelope": 1.5, "photo": 1.22, "phone": 0.5,
}

static var _grain: ImageTexture
static var _fonts := {}

var style := "deed"
var card := ""
## Readable words of the sheet (already translated): heading and one line of body text.
var heading := ""
var body := ""
## photo: the picture inside the print.
var picture: Texture2D
var _seed := 0


static func create(p_style: String, p_card: String, p_heading: String, p_body := "", p_picture: Texture2D = null, p_seed := 0) -> PaperProp:
	var p := PaperProp.new()
	p.style = p_style if ASPECT.has(p_style) else "deed"
	p.card = p_card
	p.heading = p_heading
	p.body = p_body
	p.picture = p_picture
	p._seed = p_seed
	return p


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	clip_contents = false
	resized.connect(queue_redraw)


static func _font(path: String, weight := 0) -> Font:
	var key := "%s@%d" % [path, weight]
	if not _fonts.has(key):
		var f: Font = load(path) if ResourceLoader.exists(path) else ThemeDB.fallback_font
		if weight > 0 and f is FontFile:
			var v := FontVariation.new()
			v.base_font = f
			v.variation_opentype = {"wght": weight}
			f = v
		_fonts[key] = f
	return _fonts[key]


## Fixed paper tooth (value noise, deterministic), tiled over every sheet: 0.93..1.0 grey.
static func grain() -> ImageTexture:
	if _grain == null:
		var img := Image.create_empty(GRAIN_PX, GRAIN_PX, false, Image.FORMAT_L8)
		var rng := RandomNumberGenerator.new()
		rng.seed = 1405  # G14's seed
		for y in GRAIN_PX:
			for x in GRAIN_PX:
				var fibre := 0.012 * sin(x / 7.1 + y / 19.3) + 0.008 * sin(x / 2.3 - y / 9.9)
				img.set_pixel(x, y, Color.from_hsv(0, 0, clampf(0.985 + rng.randfn(0.0, 0.012) + fibre, 0.93, 1.0)))
		_grain = ImageTexture.create_from_image(img)
	return _grain


## The sheet rect (unrotated, centred) fitted into this control with a small margin.
func sheet_size() -> Vector2:
	var a: float = ASPECT.get(style, 0.72)
	var room := size - Vector2(10, 10)
	if room.x <= 0.0 or room.y <= 0.0:
		return Vector2.ZERO
	var w := minf(room.x, room.y * a)
	return Vector2(w, w / a)


func _turn() -> float:
	return deg_to_rad(float(absi(hash(card + str(_seed))) % 9 - 4) * 0.45)  # -1.8°..+1.8°


func _draw() -> void:
	var s := sheet_size()
	if s.x < 8.0:
		return
	var c := size * 0.5
	var rot := _turn()
	# contact shadow: two offset copies of the outline (key light from the top left, as the G14 props)
	var outline := _outline(s)
	for j in 2:
		draw_set_transform(c + Vector2(2.0 + 2.0 * j, 3.0 + 2.5 * j), rot, Vector2.ONE)
		draw_colored_polygon(outline, Color(SHADOW, SHADOW.a * (0.6 if j == 0 else 0.35)))
	draw_set_transform(c, rot, Vector2.ONE)
	if style == "phone":
		_draw_phone(s)
	elif style == "photo":
		_draw_photo(s, outline)
	else:
		var col := PAPER_NOTE if style == "note" else (ENVELOPE if style == "envelope" else PAPER)
		_paper(outline, col)
		match style:
			"note": _draw_note(s)
			"letterhead": _draw_letterhead(s)
			"invoice": _draw_invoice(s)
			"till": _draw_till(s)
			"resolution": _draw_resolution(s)
			"envelope": _draw_envelope(s)
			_: _draw_deed(s)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Sheet outline in sheet coordinates (centre = 0): straight cut paper, a torn top on the notebook
## page, a zig-zag tear at the foot of the till slip, rounded corners on the phone.
func _outline(s: Vector2) -> PackedVector2Array:
	var h := s * 0.5
	var pts := PackedVector2Array()
	var rng := RandomNumberGenerator.new()
	rng.seed = absi(hash(card)) + 7
	match style:
		"note":
			pts.append(Vector2(-h.x, h.y))
			pts.append(Vector2(h.x, h.y))
			var n := 18
			for i in n + 1:  # torn top edge, right to left
				var x := h.x - s.x * i / n
				pts.append(Vector2(x, -h.y + rng.randf_range(0.0, s.y * 0.025)))
		"till":
			pts.append(Vector2(-h.x, -h.y))
			pts.append(Vector2(h.x, -h.y))
			var teeth := 9
			for i in teeth * 2 + 1:  # zig-zag foot, right to left
				var x := h.x - s.x * i / (teeth * 2.0)
				pts.append(Vector2(x, h.y - (0.0 if i % 2 == 0 else s.x * 0.05)))
		"phone":
			var r := s.x * 0.14
			var corners := [[Vector2(-h.x + r, -h.y + r), PI], [Vector2(h.x - r, -h.y + r), PI * 1.5],
					[Vector2(h.x - r, h.y - r), 0.0], [Vector2(-h.x + r, h.y - r), PI * 0.5]]
			for cr: Array in corners:
				for j in 7:
					var a: float = float(cr[1]) + (PI * 0.5) * j / 6.0
					pts.append((cr[0] as Vector2) + Vector2(cos(a), sin(a)) * r)
		_:
			pts = PackedVector2Array([Vector2(-h.x, -h.y), Vector2(h.x, -h.y), Vector2(h.x, h.y), Vector2(-h.x, h.y)])
	return pts


func _paper(outline: PackedVector2Array, col: Color) -> void:
	var uvs := PackedVector2Array()
	for p in outline:
		uvs.append(p / float(GRAIN_PX) * 1.4)
	draw_colored_polygon(outline, col, uvs, grain())
	# a slightly darker edge: handled paper, not a flat fill
	draw_polyline(_closed(outline), Color(0.36, 0.3, 0.22, 0.22), 1.2, true)


static func _closed(p: PackedVector2Array) -> PackedVector2Array:
	var out := p.duplicate()
	out.append(p[0])
	return out


# ------------------------------------------------------------------ type and ink helpers
func _text(pos: Vector2, s: String, font: Font, fs: float, col: Color, width := -1.0, align := HORIZONTAL_ALIGNMENT_LEFT, lines := 1) -> float:
	fs = maxf(fs, 6.0)
	if lines <= 1:
		var shown := s
		if width > 0.0:
			while shown.length() > 1 and font.get_string_size(shown, HORIZONTAL_ALIGNMENT_LEFT, -1, int(fs)).x > width:
				fs -= 0.5
				if fs <= 7.0:
					break
		draw_string(font, pos, shown, align, width, int(fs), col)
		return fs * 1.25
	draw_multiline_string(font, pos, s, align, width, int(fs), lines, col)
	var n := clampi(int(font.get_multiline_string_size(s, align, width, int(fs), lines).y / (fs * 1.2)), 1, lines)
	return n * fs * 1.25


func _bar(x: float, y: float, w: float, th: float) -> void:
	if w <= 0.0:
		return
	draw_rect(Rect2(x, y - th * 0.5, w, th), INK_BAR)


## Illegible body copy: `rows` lines of ink bars from y with line height lh, width w.
func _bars(x: float, y: float, w: float, rows: int, lh: float, th: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = absi(hash(card + style)) + 3
	for r in rows:
		var last := r == rows - 1
		var ln := w * (rng.randf_range(0.35, 0.6) if last else rng.randf_range(0.78, 1.0))
		var cx := x
		while cx < x + ln - th:  # words: bars with small gaps
			var word := minf(rng.randf_range(0.08, 0.22) * w, x + ln - cx)
			_bar(cx, y + r * lh, word, th)
			cx += word + th * 1.6


func _signature(at: Vector2, w: float, col := INK) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = absi(hash(card + str(at))) + 11
	var pts := PackedVector2Array()
	var n := 22
	for i in n:
		var t := float(i) / (n - 1)
		var amp := w * 0.12 * (1.0 - t * 0.4)
		pts.append(at + Vector2(t * w, sin(t * 13.0 + rng.randf() * 0.6) * amp - t * w * 0.08))
	draw_polyline(pts, Color(col, 0.85), maxf(1.2, w * 0.022), true)


func _stamp_round(c: Vector2, r: float) -> void:
	draw_arc(c, r, 0.0, TAU, 48, STAMP, maxf(1.5, r * 0.07), true)
	draw_arc(c, r * 0.78, 0.0, TAU, 40, STAMP, maxf(1.0, r * 0.04), true)
	for i in 24:  # the lettering ring as short ink ticks: no readable institution name
		var a := TAU * i / 24.0
		if i % 6 == 5:
			continue
		draw_line(c + Vector2(cos(a), sin(a)) * r * 0.84, c + Vector2(cos(a), sin(a)) * r * 0.94, STAMP, maxf(1.0, r * 0.05))
	draw_line(c + Vector2(-r * 0.4, 0), c + Vector2(r * 0.4, 0), STAMP, maxf(1.0, r * 0.06))


func _seal(c: Vector2, r: float) -> void:
	# a blind-embossed notarial seal: light and dark rims, no ink
	draw_arc(c, r, 0.0, TAU, 48, Color(1, 1, 1, 0.35), maxf(1.5, r * 0.08), true)
	draw_arc(c + Vector2(0.8, 1.0), r, 0.0, TAU, 48, Color(0.3, 0.25, 0.18, 0.28), maxf(1.2, r * 0.06), true)
	for i in 32:
		var a := TAU * i / 32.0
		draw_line(c + Vector2(cos(a), sin(a)) * r * 0.72, c + Vector2(cos(a), sin(a)) * r * 0.86, Color(0.3, 0.25, 0.18, 0.22), 1.0)
	draw_circle(c, r * 0.3, Color(0.3, 0.25, 0.18, 0.12))


# ------------------------------------------------------------------ styles
func _draw_note(s: Vector2) -> void:
	var h := s * 0.5
	var m := s.x * 0.1
	var lh := s.y * 0.105
	for i in 8:
		var y := -h.y + s.y * 0.2 + i * lh
		draw_line(Vector2(-h.x + 2, y), Vector2(h.x - 2, y), NOTE_LINE, 1.0)
	draw_line(Vector2(-h.x + m * 0.8, -h.y + s.y * 0.06), Vector2(-h.x + m * 0.8, h.y - 2), Color(0.6, 0.32, 0.28, 0.25), 1.0)
	var hand := _font(FONT_HAND, 700)
	var fs := lh * 0.92
	draw_multiline_string(hand, Vector2(-h.x + m, -h.y + s.y * 0.2 + lh - lh * 0.18), body, HORIZONTAL_ALIGNMENT_LEFT,
			s.x - m * 1.6, int(maxf(fs, 7.0)), 4, PEN)
	_signature(Vector2(h.x - s.x * 0.48, h.y - lh * 1.1), s.x * 0.36, PEN)


func _draw_letterhead(s: Vector2) -> void:
	var h := s * 0.5
	var m := s.x * 0.1
	var w := s.x - 2.0 * m
	var y := -h.y + s.y * 0.07
	_bar(-h.x + m, y, w * 0.55, s.y * 0.022)  # institution name in the letterhead (illegible)
	_bar(-h.x + m, y + s.y * 0.045, w * 0.38, s.y * 0.012)
	y += s.y * 0.085
	draw_line(Vector2(-h.x + m, y), Vector2(h.x - m, y), RULE, maxf(1.0, s.y * 0.006))
	y += s.y * 0.1
	y += _text(Vector2(-h.x + m, y), heading, _font(FONT_HEAD), s.y * 0.06, INK, w)
	y += _text(Vector2(-h.x + m, y + s.y * 0.01), body, _font(FONT_BODY, 500), s.y * 0.038, INK, w, HORIZONTAL_ALIGNMENT_LEFT, 3)
	_bars(-h.x + m, y + s.y * 0.04, w, 5, s.y * 0.052, s.y * 0.012)
	_stamp_round(Vector2(h.x - m - s.x * 0.16, h.y - s.y * 0.14), s.x * 0.14)
	_signature(Vector2(-h.x + m, h.y - s.y * 0.12), s.x * 0.34)


func _draw_invoice(s: Vector2) -> void:
	var h := s * 0.5
	var m := s.x * 0.1
	var w := s.x - 2.0 * m
	var y := -h.y + s.y * 0.12
	y += _text(Vector2(-h.x + m, y), heading, _font(FONT_HEAD), s.y * 0.07, INK, w * 0.6)
	_bar(h.x - m - w * 0.3, -h.y + s.y * 0.1, w * 0.3, s.y * 0.012)
	_bar(-h.x + m, y + s.y * 0.01, w * 0.42, s.y * 0.012)  # seller / buyer blocks
	_bar(-h.x + m, y + s.y * 0.045, w * 0.34, s.y * 0.012)
	_bar(h.x - m - w * 0.42, y + s.y * 0.01, w * 0.42, s.y * 0.012)
	_bar(h.x - m - w * 0.3, y + s.y * 0.045, w * 0.3, s.y * 0.012)
	y += s.y * 0.11
	var col_x := h.x - m - w * 0.24
	draw_line(Vector2(-h.x + m, y), Vector2(h.x - m, y), RULE, maxf(1.0, s.y * 0.005))
	for r in 4:
		var ry := y + s.y * (0.06 + r * 0.07)
		_bar(-h.x + m, ry, w * (0.55 - 0.08 * (r % 2)), s.y * 0.013)
		_bar(col_x, ry, w * 0.2, s.y * 0.013)
		draw_line(Vector2(-h.x + m, ry + s.y * 0.035), Vector2(h.x - m, ry + s.y * 0.035), Color(RULE, 0.25), 1.0)
	y += s.y * 0.36
	draw_line(Vector2(col_x - w * 0.3, y), Vector2(h.x - m, y), RULE, maxf(1.2, s.y * 0.006))
	_text(Vector2(col_x - w * 0.3, y + s.y * 0.06), I18n.t(&"verify.paper.total"), _font(FONT_BODY, 700), s.y * 0.04, INK, w * 0.28)
	_bar(col_x, y + s.y * 0.045, w * 0.2, s.y * 0.018)
	_signature(Vector2(-h.x + m, h.y - s.y * 0.1), s.x * 0.3)


func _draw_till(s: Vector2) -> void:
	var h := s * 0.5
	var m := s.x * 0.12
	var w := s.x - 2.0 * m
	var y := -h.y + s.y * 0.06
	_bar(-w * 0.35, y, w * 0.7, s.y * 0.012)  # shop name and address, centred
	_bar(-w * 0.28, y + s.y * 0.03, w * 0.56, s.y * 0.008)
	y += s.y * 0.1
	y += _text(Vector2(-h.x + m, y), heading, _font(FONT_BODY, 700), s.x * 0.085, INK, w, HORIZONTAL_ALIGNMENT_CENTER)
	draw_dashes(Vector2(-h.x + m, y), Vector2(h.x - m, y), s.x * 0.03)
	for r in 5:
		var ry := y + s.y * (0.05 + r * 0.055)
		_bar(-h.x + m, ry, w * (0.5 + 0.1 * (r % 2)), s.y * 0.009)
		_bar(h.x - m - w * 0.22, ry, w * 0.22, s.y * 0.009)
	y += s.y * 0.33
	draw_dashes(Vector2(-h.x + m, y), Vector2(h.x - m, y), s.x * 0.03)
	y += s.y * 0.055
	_text(Vector2(-h.x + m, y), I18n.t(&"verify.paper.total").to_upper(), _font(FONT_BODY, 700), s.x * 0.075, INK, w * 0.55)
	_bar(h.x - m - w * 0.28, y - s.y * 0.012, w * 0.28, s.y * 0.016)
	y += s.y * 0.1
	_text(Vector2(-h.x + m, y), I18n.t(&"verify.paper.receipt.thanks"), _font(FONT_BODY, 400), s.x * 0.07, INK, w, HORIZONTAL_ALIGNMENT_CENTER)
	for i in 18:  # a barcode-like strip of ink lines
		var bx := -w * 0.36 + w * 0.72 * i / 18.0
		draw_line(Vector2(bx, y + s.y * 0.05), Vector2(bx, y + s.y * 0.1), Color(INK, 0.55), 1.0 + float(i % 3))


func draw_dashes(a: Vector2, b: Vector2, dash: float) -> void:
	var n := int(a.distance_to(b) / (dash * 2.0))
	for i in n:
		draw_line(a.lerp(b, (i * 2.0) / (n * 2.0)), a.lerp(b, (i * 2.0 + 1.0) / (n * 2.0)), Color(INK, 0.45), 1.0)


func _draw_deed(s: Vector2) -> void:
	var h := s * 0.5
	var m := s.x * 0.1
	var w := s.x - 2.0 * m
	var y := -h.y + s.y * 0.13
	y += _text(Vector2(-h.x + m, y), heading, _font(FONT_HEAD), s.y * 0.055, INK, w, HORIZONTAL_ALIGNMENT_CENTER, 2)
	_bar(-w * 0.2, y, w * 0.4, s.y * 0.01)
	y += s.y * 0.05
	draw_line(Vector2(-h.x + m, y), Vector2(h.x - m, y), RULE, maxf(1.0, s.y * 0.005))
	_bars(-h.x + m, y + s.y * 0.06, w, 8, s.y * 0.05, s.y * 0.011)
	_seal(Vector2(-h.x + m + s.x * 0.13, h.y - s.y * 0.15), s.x * 0.12)
	_signature(Vector2(h.x - m - s.x * 0.34, h.y - s.y * 0.17), s.x * 0.3)
	_signature(Vector2(h.x - m - s.x * 0.3, h.y - s.y * 0.08), s.x * 0.26)


func _draw_resolution(s: Vector2) -> void:
	var h := s * 0.5
	var m := s.x * 0.1
	var w := s.x - 2.0 * m
	var y := -h.y + s.y * 0.13
	y += _text(Vector2(-h.x + m, y), heading, _font(FONT_HEAD), s.y * 0.06, INK, w)
	_bar(-h.x + m, y, w * 0.3, s.y * 0.011)
	_bars(-h.x + m, y + s.y * 0.06, w, 4, s.y * 0.05, s.y * 0.011)
	y += s.y * 0.3
	for r in 4:  # the residents' signatures, each on its own line
		var ry := y + r * s.y * 0.1
		draw_line(Vector2(-h.x + m + w * 0.42, ry), Vector2(h.x - m, ry), Color(RULE, 0.5), 1.0)
		_bar(-h.x + m, ry - s.y * 0.01, w * 0.32, s.y * 0.01)
		_signature(Vector2(-h.x + m + w * 0.45, ry - s.y * 0.025), w * (0.36 + 0.06 * (r % 2)))


func _draw_envelope(s: Vector2) -> void:
	var h := s * 0.5
	var fold := Color(0.45, 0.38, 0.28, 0.5)
	draw_line(Vector2(-h.x + s.x * 0.04, -h.y + s.y * 0.12), Vector2(0, s.y * 0.15), fold, maxf(1.0, s.y * 0.008), true)
	draw_line(Vector2(h.x - s.x * 0.04, -h.y + s.y * 0.12), Vector2(0, s.y * 0.15), fold, maxf(1.0, s.y * 0.008), true)
	# stamp and postmark (wavy lines and a ring, no country, no date)
	var st := Rect2(Vector2(h.x - s.x * 0.2, -h.y + s.y * 0.1), Vector2(s.x * 0.13, s.y * 0.22))
	draw_rect(st, Color(0.56, 0.42, 0.3, 0.55))
	draw_rect(st.grow(-s.x * 0.012), Color(0.85, 0.8, 0.7, 0.9))
	draw_rect(st.grow(-s.x * 0.03), Color(0.4, 0.45, 0.42, 0.55))
	var pm := st.position + Vector2(-s.x * 0.02, st.size.y * 0.5)
	draw_arc(pm, s.y * 0.13, 0.0, TAU, 40, Color(INK, 0.45), 1.4, true)
	for k in 4:
		var pts := PackedVector2Array()
		for i in 16:
			var t := float(i) / 15.0
			pts.append(pm + Vector2(-s.x * 0.36 + t * s.x * 0.3, -s.y * 0.06 + k * s.y * 0.04 + sin(t * 9.0) * s.y * 0.012))
		draw_polyline(pts, Color(INK, 0.4), 1.2, true)
	# "registered" label in a box, red-brown
	var lab := _font(FONT_BODY, 700)
	var fs := s.y * 0.07
	var tw := minf(lab.get_string_size(heading, HORIZONTAL_ALIGNMENT_LEFT, -1, int(fs)).x, s.x * 0.4)
	var box := Rect2(Vector2(-h.x + s.x * 0.07, -h.y + s.y * 0.1), Vector2(tw + s.x * 0.04, fs * 1.5))
	draw_rect(box, STAMP, false, maxf(1.0, s.y * 0.01))
	_text(box.position + Vector2(s.x * 0.02, fs * 1.1), heading, lab, fs, STAMP, s.x * 0.4)
	# the address, handwritten: ink strokes on three lines
	for r in 3:
		var y := s.y * (0.18 + r * 0.1)
		_signature(Vector2(-s.x * 0.22, y), s.x * (0.42 - 0.08 * r), PEN)


func _draw_photo(s: Vector2, outline: PackedVector2Array) -> void:
	var h := s * 0.5
	_paper(outline, Color(0.95, 0.93, 0.88))  # the print's white border, slightly aged
	var b := s.x * 0.06
	var inner := Rect2(-h + Vector2(b, b), s - Vector2(b, b) * Vector2(2.0, 3.2))
	if picture != null:
		# cover-crop the picture into the print (upper part of a portrait: the face)
		var ts := Vector2(picture.get_size())
		var k := maxf(inner.size.x / ts.x, inner.size.y / ts.y)
		var src := Rect2((ts - inner.size / k) * Vector2(0.5, 0.25), inner.size / k)
		draw_texture_rect_region(picture, inner, src, Color(0.97, 0.9, 0.8))  # an old print's warm cast
	else:
		draw_rect(inner, Color(0.3, 0.27, 0.23))
	draw_rect(inner, Color(0, 0, 0, 0.18), false, 1.0)
	# a little gloss scuff, the only highlight (no glow): a thin line across one corner
	draw_line(inner.position + Vector2(inner.size.x * 0.7, 0), inner.position + Vector2(inner.size.x, inner.size.y * 0.25), Color(1, 1, 1, 0.12), 2.0, true)


func _draw_phone(s: Vector2) -> void:
	var h := s * 0.5
	var body_pts := _outline(s)
	draw_colored_polygon(body_pts, Color(0.12, 0.115, 0.11))
	draw_polyline(_closed(body_pts), Color(0.32, 0.3, 0.28), maxf(1.0, s.x * 0.012), true)  # worn edge of the case
	var b := s.x * 0.06
	var scr := Rect2(-h + Vector2(b, b * 2.2), s - Vector2(b * 2.0, b * 4.4))
	draw_rect(scr, Color(0.9, 0.89, 0.85))
	# the map: a few streets in two greys, a block, a river band
	var map := Rect2(scr.position, Vector2(scr.size.x, scr.size.y * 0.58))
	draw_rect(map, Color(0.84, 0.83, 0.79))
	var street := Color(0.97, 0.96, 0.93)
	for i in 4:
		var y := map.position.y + map.size.y * (0.15 + i * 0.24)
		draw_line(Vector2(map.position.x, y), Vector2(map.end.x, y + map.size.y * 0.06), street, maxf(2.0, s.x * 0.035))
	for i in 3:
		var x := map.position.x + map.size.x * (0.2 + i * 0.32)
		draw_line(Vector2(x, map.position.y), Vector2(x - map.size.x * 0.08, map.end.y), street, maxf(1.5, s.x * 0.025))
	draw_line(Vector2(map.position.x, map.end.y - map.size.y * 0.12), Vector2(map.end.x, map.end.y - map.size.y * 0.3), Color(0.62, 0.7, 0.72), maxf(3.0, s.x * 0.06))
	# the pin: a drawn teardrop, umber with a light dot
	var pc := map.get_center() + Vector2(map.size.x * 0.06, -map.size.y * 0.08)
	var pr := s.x * 0.075
	draw_colored_polygon(PackedVector2Array([pc + Vector2(-pr * 0.75, pr * 0.4), pc + Vector2(0, pr * 2.0), pc + Vector2(pr * 0.75, pr * 0.4)]), STAMP)
	draw_circle(pc, pr, STAMP)
	draw_circle(pc, pr * 0.38, Color(0.95, 0.93, 0.88))
	# the address block under the map
	var y := map.end.y + scr.size.y * 0.1
	_text(Vector2(scr.position.x + b * 0.6, y), heading, _font(FONT_BODY, 700), s.x * 0.08, INK, scr.size.x - b * 1.2)
	_bar(scr.position.x + b * 0.6, y + scr.size.y * 0.08, scr.size.x * 0.7, s.y * 0.014)
	_bar(scr.position.x + b * 0.6, y + scr.size.y * 0.14, scr.size.x * 0.5, s.y * 0.014)
	draw_circle(Vector2(0, h.y - b * 1.1), b * 0.45, Color(0.22, 0.21, 0.2))  # the home button of an old phone
