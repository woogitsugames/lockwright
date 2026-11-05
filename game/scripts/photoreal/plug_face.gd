class_name PlugFace
extends Control
## Plug face seen down the keyway (HUD.md §3 "napięcie T": wrench arm + plug face). The cutaway
## looks at the lock from the side, so the plug turns about an axis that points almost straight
## at the camera's horizon: a 12° turn moves its edge by less than a pixel (N-62 "rdzeń się nie
## obraca"). This inset shows the same plug from the front, where the turn is a plain rotation:
##   - plug disc with the engraved scale (12 ticks, 7.5° apart) against a fixed "0" scratch on
##     the housing ring: core_rotation steps (set = +1 tick) read in greyscale;
##   - the tension wrench: foot at the bottom of the keyway, arm out to the left (the left
##     thumb's side). Arm angle follows T; the arm bows with the plug's resistance and trembles
##     near the tool's limit.
## Pure drawing, no input. Colours are flat metal tones (no gradients, no chrome, no glow).

const TICKS := 12
const TICK_DEG := 7.5
const PLAY_DEG := 4.5        # plug play taken up by full tension: ≈ 3 dp at the 40 dp rim
const ARM_MAX_DEG := 26.0    # arm angle at T = 1: ≥ 2 dp of tip travel per 0.05 T (HUD.md §3)
const ARM_LEN := 2.2         # arm length in plug radii

const C_SHADOW := Color(0, 0, 0, 0.35)
const C_HOUSING := Color(0.56, 0.57, 0.56)
const C_HOUSING_EDGE := Color(0.30, 0.30, 0.30)
const C_PLUG := Color(0.66, 0.53, 0.30)
const C_PLUG_LINE := Color(0.74, 0.62, 0.38)
const C_ENGRAVE := Color(0.20, 0.15, 0.08)
const C_KEYWAY := Color(0.06, 0.05, 0.045)
const C_STEEL := Color(0.78, 0.79, 0.80)
const C_STEEL_EDGE := Color(0.22, 0.23, 0.25)
const C_CHALK := Color(0.96, 0.95, 0.90, 0.9)

var radius := 40.0
var face_deg := 0.0      # plug turn (core_rotation + play), clockwise positive
var arm_deg := 0.0       # wrench arm, clockwise positive (tip up for an arm pointing left)
var bow := 0.0           # 0..1 arm deflection (tension_resistance)
var tremor := 0.0        # 0..1 near the limit
var gauge := false       # D-52 / S1: chalk tension scale beside the arm tip
var gauge_band := Vector2(0.25, 0.45)
var tension := 0.0
var opened := false


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Pivot of the plug in local coordinates (the arm reaches to the left of it).
func pivot() -> Vector2:
	return Vector2(size.x - radius - 10.0, size.y * 0.5)


## Arm tip in local coordinates (for the chalk hints).
func arm_tip() -> Vector2:
	var p := pivot()
	var foot := p + Vector2(0, radius * 0.58).rotated(deg_to_rad(face_deg))
	return foot + Vector2.LEFT.rotated(deg_to_rad(arm_deg)) * radius * ARM_LEN


static func size_for(r: float) -> Vector2:
	return Vector2(r * (ARM_LEN + 1.0) + 24.0, r * 2.0 + 28.0)


func _draw() -> void:
	var c := pivot()
	var r := radius
	var rot := deg_to_rad(face_deg)
	# soft contact shadow on the leather (offset, no blur shader: three stacked discs)
	for j in 3:
		draw_circle(c + Vector2(2, 3), r + 10.0 - j * 1.5, Color(0, 0, 0, 0.12))
	# housing ring (nickel) with a bevel line
	draw_circle(c, r + 9.0, C_HOUSING_EDGE)
	draw_circle(c, r + 8.0, C_HOUSING)
	draw_arc(c, r + 5.0, PI * 1.05, PI * 1.95, 24, Color(0.68, 0.69, 0.68), 1.5)
	draw_circle(c, r + 1.5, C_HOUSING_EDGE)
	# fixed "0" scratch on the housing, straight up
	draw_line(c + Vector2(0, -r - 8.0), c + Vector2(0, -r - 1.0), Color(0.12, 0.12, 0.12), 2.5)
	# plug disc: flat brass with a few turned rings (machining marks, static)
	draw_circle(c, r, C_PLUG)
	for k in 4:
		draw_arc(c, r * (0.35 + 0.15 * k), 0, TAU, 48, C_PLUG_LINE, 1.0)
	# engraved scale: 12 ticks, 7.5° apart, starting at "0"; turns with the plug
	for k in TICKS + 1:
		var a := rot + deg_to_rad(-90.0 + k * TICK_DEG)
		var d := Vector2(cos(a), sin(a))
		var inner := r * (0.70 if k == 0 else 0.80)
		draw_line(c + d * inner, c + d * (r - 1.0), C_ENGRAVE, 2.5 if k == 0 else 2.0)
	# keyway: a narrow profile, top to bottom, turns with the plug
	var kw := PackedVector2Array([
		Vector2(-0.07, -0.62), Vector2(0.06, -0.62), Vector2(0.06, -0.20), Vector2(0.11, -0.10),
		Vector2(0.06, 0.00), Vector2(0.09, 0.30), Vector2(0.09, 0.66), Vector2(-0.09, 0.66),
		Vector2(-0.09, 0.30), Vector2(-0.12, 0.18), Vector2(-0.07, 0.05)])
	var pts := PackedVector2Array()
	for v in kw:
		pts.append(c + (v * r).rotated(rot))
	draw_colored_polygon(pts, C_KEYWAY)
	if opened:
		return
	# tension wrench: foot in the bottom of the keyway, arm to the left
	var foot := c + Vector2(0, r * 0.58).rotated(rot)
	var dir := Vector2.LEFT.rotated(deg_to_rad(arm_deg))
	var nrm := Vector2(-dir.y, dir.x)  # points down for an arm to the left
	var length := r * ARM_LEN
	var shake := tremor * 1.2 * sin(Time.get_ticks_msec() * 0.09)
	var line := PackedVector2Array()
	for i in 9:
		var t := i / 8.0
		var sag := bow * r * 0.16 * sin(t * PI) * t  # bows toward the plug's resistance
		line.append(foot + dir * length * t + nrm * (sag + shake * t))
	draw_polyline(line, C_STEEL_EDGE, r * 0.16 + 2.0, true)
	draw_polyline(line, C_STEEL, r * 0.16, true)
	# foot bent into the keyway (the short leg of the L)
	draw_line(foot + dir * 2.0, foot + Vector2(0, -r * 0.20).rotated(rot), C_STEEL_EDGE, r * 0.16 + 2.0)
	draw_line(foot + dir * 2.0, foot + Vector2(0, -r * 0.20).rotated(rot), C_STEEL, r * 0.16)
	if gauge:
		_draw_gauge(line[line.size() - 1])


func _draw_gauge(tip: Vector2) -> void:
	# chalk scale beside the arm tip: a short upright stroke 0..1 with the working band
	# bracketed and the current tension as a chalk notch (D-52: shown in auto mode too)
	var h := radius * 1.6
	var x := tip.x - 14.0
	var base := Vector2(x, tip.y + h * 0.5)
	draw_line(base, base + Vector2(0, -h), Color(C_CHALK, 0.55), 2.0)
	for k in 5:
		var y := base.y - h * k / 4.0
		draw_line(Vector2(x - 4, y), Vector2(x, y), Color(C_CHALK, 0.55), 2.0)
	var b0 := base.y - h * gauge_band.x
	var b1 := base.y - h * gauge_band.y
	draw_line(Vector2(x - 7, b0), Vector2(x - 7, b1), C_CHALK, 3.0)
	draw_line(Vector2(x - 7, b0), Vector2(x - 2, b0), C_CHALK, 3.0)
	draw_line(Vector2(x - 7, b1), Vector2(x - 2, b1), C_CHALK, 3.0)
	var ty := base.y - h * clampf(tension, 0.0, 1.0)
	draw_colored_polygon(PackedVector2Array([Vector2(x + 2, ty), Vector2(x + 10, ty - 5), Vector2(x + 10, ty + 5)]), C_CHALK)
