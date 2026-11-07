class_name TapGate
extends RefCounted
## One tap = one press (N-77). On a phone a tap reaches Control.gui_input twice: as an
## InputEventScreenTouch and as the mouse click Godot emulates from it (emulate_mouse_from_touch).
## A toggle that reacts to both flips twice in one frame and the tap seems to do nothing (the loupe
## never opened on the SM-A165F). accept() takes the touch and drops the emulated click: Godot marks
## it with device InputEvent.DEVICE_ID_EMULATION. A real mouse (desktop, editor) still clicks, and
## fast taps are never swallowed (an earlier 250 ms echo window ate the warded bit taps and a quick
## second tap on the loupe). The caller still accept_event()s every press so none reaches the thumbs.


static func is_press(ev: InputEvent) -> bool:
	return (ev is InputEventScreenTouch and ev.pressed) or (ev is InputEventMouseButton and ev.pressed)


## The emulated echo of a touch (never a press of its own).
static func is_echo(ev: InputEvent) -> bool:
	return ev is InputEventMouseButton and ev.device == InputEvent.DEVICE_ID_EMULATION


## true for the one press of a tap. `_now_ms` is kept for older callers (no timing any more).
func accept(ev: InputEvent, _now_ms: int = -1) -> bool:
	return is_press(ev) and not is_echo(ev)
