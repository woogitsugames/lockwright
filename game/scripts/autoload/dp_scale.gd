extends Node
## N-59 / landscape scale: one dp is the same physical size in portrait and landscape.
## project.godot keeps the 412x915 portrait base with stretch canvas_items + aspect expand,
## which on its own scales a landscape window by min(w/412, h/915) = h/915 (UI at ~45%).
## Swapping the base with the orientation (915x412 when the window is wider than tall) keeps
## the factor min(short/412, long/915) in both orientations, and "expand" still grows the
## longer side, so every screen sees >= 412 dp on its short side.

const BASE := Vector2i(412, 915)


func _ready() -> void:
	var win := get_window()
	if win == null:
		return
	win.size_changed.connect(apply)
	apply()


func apply() -> void:
	var win := get_window()
	if win == null or win.content_scale_mode == Window.CONTENT_SCALE_MODE_DISABLED:
		return
	win.content_scale_size = base_for(win.size)


## Design base for a window of this size: portrait base, or swapped in landscape.
static func base_for(win_size: Vector2i) -> Vector2i:
	if win_size.x > win_size.y:
		return Vector2i(BASE.y, BASE.x)
	return BASE
