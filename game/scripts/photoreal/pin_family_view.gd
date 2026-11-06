class_name LockPinFamilyView
extends LockPhotorealView
## D-59: plan-B screens of the two lockcore families built on the pin_tumbler module (LOCKS.md §2.20
## dimple, §2.25 magnetic). Same Cycles cut-away, stacks, chalk, loupe and HUD as the pin screen; the
## family's own tool is a Cycles layer (art/blender/plates/tool_layers.py) drawn in place of the hook:
##   magnet_probe: the probe follows the thumb and never touches a pin; lockcore's pick_lift is the
##                 field position (it trails the thumb), drawn as a faint ring of filings where the
##                 pin is being pulled to (shape only, no glow). The pin lags behind the probe.
##   dimple_flag:  the flag pushes the pin like the hook does. Telescoping pins are lockcore spools
##                 (variant low bits) and draw as such; side-row pins (variant bit 4) get a short
##                 bracket on the plug face, "this one comes from the side".

const TOOLS_DIR := "res://assets/photoreal_families/tools/"
const SIDE_ROW := 16
const FIELD_GAP_MM := 0.8     # the probe stays this far under the pin it pulls

@export var tool := "magnet_probe"

var _tool_tex: Texture2D
var _tool_meta := {}
var _overlay: Control
var _field := 0.0             # lockcore field position (magnetic)
var _probe := 0.0             # thumb (probe) lift
var _side_rows: Array[bool] = []


func _ready() -> void:
	super._ready()
	_tool_tex = _tex(TOOLS_DIR + tool + ".png")
	if FileAccess.file_exists(TOOLS_DIR + "layers.json"):
		var m: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(TOOLS_DIR + "layers.json"))
		_tool_meta = m.get("tools", {}).get(tool, {})
		_tool_meta["ppmm"] = float(m.get("ppmm", 24.0))
	if _tool_tex != null:
		for n in [_pick, _pick_handle]:
			if n:
				n.visible = false
	_overlay = Control.new()
	_overlay.name = "ToolLayer"
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.draw.connect(_draw_tool)
	add_child(_overlay)
	move_child(_overlay, _section.get_index() + 1)


## lockcore's variant carries the dimple side-row bit above the pin variant: the stacks see only
## the pin variant (spool = telescoping pin).
static func pin_vm(vm: Dictionary) -> Dictionary:
	if not vm.has("elements"):
		return vm
	var out := vm.duplicate()
	var els: Array = []
	for e in vm["elements"]:
		var c: Dictionary = e.duplicate()
		c["variant"] = int(e.get("variant", 0)) & 15
		els.append(c)
	out["elements"] = els
	return out


func present(vm: Dictionary, input: Dictionary, delta: float = 1.0 / 120.0) -> void:
	_side_rows.clear()
	for e in vm.get("elements", []):
		_side_rows.append((int(e.get("variant", 0)) & SIDE_ROW) != 0)
	var k := 1.0 - exp(-delta / SMOOTH_S)
	_field = lerpf(_field, maxf(float(vm.get("pick_lift", 0.0)), 0.0), k) if delta < 0.5 else maxf(float(vm.get("pick_lift", 0.0)), 0.0)
	_probe = lerpf(_probe, maxf(float(input.get("pick_lift", 0.0)), 0.0), k)
	super.present(pin_vm(vm), input, delta)
	if _overlay:
		_overlay.queue_redraw()


func field_lift() -> float:
	return _field


## Screen point of the tool tip (tests, chalk).
func tool_tip_screen() -> Vector2:
	return mm_to_screen(Vector3(_pick_x, _tool_tip_mm(), 0.0))


func _tool_tip_mm() -> float:
	if tool == "magnet_probe":
		# the probe rides at the thumb, a gap under where it pulls the pin; never inside the plug floor
		var y := PinPose.REST_BOTTOM + _probe * PinPose.TRAVEL - FIELD_GAP_MM
		return clampf(y, PinPose.REST_BOTTOM - 1.4, PinPose.SHEAR - 1.2)
	return _pick_tip


func _draw_tool() -> void:
	if dark or _last_vm.is_empty():
		return
	var tip := tool_tip_screen()
	var one := mm_to_screen(Vector3(_pick_x + 1.0, _tool_tip_mm(), 0.0)) - tip
	var ppm := absf(one.x)
	if ppm <= 0.0:
		return
	if tool == "magnet_probe":
		_draw_field(tip, ppm)
	_draw_side_rows(ppm)
	if _tool_tex == null:
		return
	var tp: Array = _tool_meta.get("tip_px", [0.0, 0.0])
	var sc := ppm / float(_tool_meta.get("ppmm", 24.0))
	var at := tip - Vector2(tp[0], tp[1]) * sc
	if _broken:
		at.y += 0.6 * ppm
	_overlay.draw_set_transform(at + Vector2(0.5, 0.8) * ppm * 0.4, 0.0, Vector2(sc, sc))
	_overlay.draw_texture(_tool_tex, Vector2.ZERO, Color(0, 0, 0, 0.35))
	_overlay.draw_set_transform(at, 0.0, Vector2(sc, sc))
	_overlay.draw_texture(_tool_tex, Vector2.ZERO)
	_overlay.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## The field: a dashed ring of filings at the height lockcore has pulled the field to, and three
## short field lines from the probe tip towards it. Thin strokes, steel grey, no glow.
func _draw_field(tip: Vector2, ppm: float) -> void:
	var y_mm := PinPose.REST_BOTTOM + _field * PinPose.TRAVEL
	var c := mm_to_screen(Vector3(_pick_x, y_mm, 0.0))
	var rx := 1.9 * ppm
	var ry := 0.7 * ppm
	var seg := 18
	for i in seg:
		if i % 2 == 1:
			continue
		var a0 := TAU * i / seg
		var a1 := TAU * (i + 1) / seg
		var p0 := c + Vector2(cos(a0) * rx, sin(a0) * ry)
		var p1 := c + Vector2(cos(a1) * rx, sin(a1) * ry)
		_overlay.draw_line(p0 + Vector2(0, 1), p1 + Vector2(0, 1), Color(0, 0, 0, 0.45), 2.5, true)
		_overlay.draw_line(p0, p1, Color(0.82, 0.83, 0.80, 0.75), 2.0, true)
	for s in [-1.0, 0.0, 1.0]:
		var a := tip + Vector2(s * 0.6 * ppm, -0.2 * ppm)
		var b := c + Vector2(s * rx * 0.8, ry * 0.6)
		var mid := (a + b) * 0.5 + Vector2(s * 0.8 * ppm, 0)
		var pts := PackedVector2Array([a, mid, b])
		_overlay.draw_polyline(pts, Color(0.75, 0.76, 0.74, 0.35), 1.5, true)


## Dimple side row: a short bracket under the stack's chamber mouth (shape, not colour).
func _draw_side_rows(ppm: float) -> void:
	for i in mini(_side_rows.size(), _active_stacks):
		if not _side_rows[i]:
			continue
		var x: float = PINS_X[i]
		var a := mm_to_screen(Vector3(x - 1.5, PinPose.REST_BOTTOM - 0.9, 0.0))
		var b := mm_to_screen(Vector3(x + 1.5, PinPose.REST_BOTTOM - 0.9, 0.0))
		var d := Vector2(0, 0.5 * ppm)
		var col := Color(0.86, 0.85, 0.80, 0.85)
		_overlay.draw_polyline(PackedVector2Array([a - d, a, b, b - d]), Color(0, 0, 0, 0.5), 3.0, true)
		_overlay.draw_polyline(PackedVector2Array([a - d, a, b, b - d]), col, 2.0, true)


func set_dark(on: bool) -> void:
	super.set_dark(on)
	if _overlay:
		_overlay.queue_redraw()
