class_name TapGate
extends RefCounted
## One tap = one press (N-77). On a phone a tap reaches Control.gui_input twice: as an
## InputEventScreenTouch and as the mouse click Godot emulates from it (emulate_mouse_from_touch).
## A toggle that reacts to both flips twice in one frame and the tap seems to do nothing (the loupe
## never opened on the SM-A165F). accept() lets the first press through and swallows any other press
## within WINDOW_MS; the caller still accept_event()s every press so none reaches the thumbs.

const WINDOW_MS := 250

var _last_ms := -1000000


static func is_press(ev: InputEvent) -> bool:
	return (ev is InputEventScreenTouch and ev.pressed) or (ev is InputEventMouseButton and ev.pressed)


## true for the first press of a tap; `now_ms` < 0 = the engine clock (tests pass their own).
func accept(ev: InputEvent, now_ms: int = -1) -> bool:
	if not is_press(ev):
		return false
	var t := Time.get_ticks_msec() if now_ms < 0 else now_ms
	if t - _last_ms < WINDOW_MS:
		return false
	_last_ms = t
	return true
