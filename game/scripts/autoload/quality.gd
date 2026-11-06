extends Node

## Quality profiles for cheap phones (task 7): render_scale, MSAA and the plan-B
## plate (SubViewport) size. Profile "auto" picks after the first 10 s of play from the
## average frame time; the player can override it in Settings. Debug builds get an
## FPS / frame-time overlay.

signal profile_changed(profile: Dictionary)

const PROFILES := {
	"high": {"render_scale": 1.0, "planb_scale": 1.0, "msaa": 2},   # MSAA_4X
	"medium": {"render_scale": 0.75, "planb_scale": 0.75, "msaa": 1}, # MSAA_2X
	"low": {"render_scale": 0.5, "planb_scale": 0.5, "msaa": 0},    # MSAA off
}
const AUTO_WINDOW_S := 10.0
const AUTO_MEDIUM_MS := 16.7  # ~60 fps
const AUTO_LOW_MS := 22.0     # ~45 fps

var current := {}
var _auto_time := 0.0
var _auto_frames := 0
var _auto_done := false
var _fps_label: Label = null


func _ready() -> void:
	current = PROFILES.get(Settings.get_value("quality_auto", "high"), PROFILES["high"])
	apply_profile(Settings.get_value("quality_profile", "auto"))
	if OS.is_debug_build():
		_fps_label = Label.new()
		_fps_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
		_fps_label.add_theme_font_size_override("font_size", 14)
		_fps_label.position = Vector2(8, 8)
		_fps_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		# N-67: autoload _ready runs while root is still adding its children ("Parent node is
		# busy setting up children"), so the overlay joins root on the next idle frame.
		get_tree().root.add_child.call_deferred(_fps_label)


func _process(delta: float) -> void:
	if _fps_label != null:
		_fps_label.text = "FPS %d  frame %.1f ms" % [Engine.get_frames_per_second(), delta * 1000.0]
	if Settings.get_value("quality_profile", "auto") == "auto" and not _auto_done:
		_auto_time += delta
		_auto_frames += 1
		if _auto_time >= AUTO_WINDOW_S:
			_auto_done = true
			var avg_ms := _auto_time * 1000.0 / maxf(_auto_frames, 1)
			var picked := "high"
			if avg_ms >= AUTO_LOW_MS:
				picked = "low"
			elif avg_ms >= AUTO_MEDIUM_MS:
				picked = "medium"
			Settings.set_value("quality_auto", picked)
			current = PROFILES[picked]
			profile_changed.emit(current)
			print("Quality: auto profile after %.0f s avg %.1f ms -> %s" % [_auto_time, avg_ms, picked])


func apply_profile(name: String) -> void:
	var key := name
	if key == "auto":
		key = Settings.get_value("quality_auto", "high")
	if not PROFILES.has(key):
		key = "high"
	current = PROFILES[key]
	var root := get_tree().root
	root.scaling_3d_scale = current["render_scale"]
	root.msaa_3d = [Viewport.MSAA_DISABLED, Viewport.MSAA_2X, Viewport.MSAA_4X][current["msaa"]]
	profile_changed.emit(current)


func planb_size(base: Vector2i) -> Vector2i:
	return Vector2i(base * current["planb_scale"])


func msaa_index() -> int:
	return current["msaa"]
