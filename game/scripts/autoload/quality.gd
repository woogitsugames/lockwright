extends Node

## Quality profiles for cheap phones (task 7): render_scale, MSAA and the plan-B
## plate (SubViewport) size. Profile "auto" picks after the first 10 s of play from the
## average frame time; the player can override it in Settings ("low" is a manual choice only, D-96). Debug builds get an
## FPS / frame-time overlay, hidden by default (VA-15: in tester APKs it covered "‹ Wstecz" and landed
## in every screenshot). Dev switch: launch with `-- --fps=1`, press F3, or tap with four fingers.

signal profile_changed(profile: Dictionary)

const PROFILES := {
	"high": {"render_scale": 1.0, "planb_scale": 1.0, "msaa": 2},   # MSAA_4X
	"medium": {"render_scale": 0.75, "planb_scale": 0.75, "msaa": 1}, # MSAA_2X
	"low": {"render_scale": 0.5, "planb_scale": 0.5, "msaa": 0},    # MSAA off
}
const AUTO_WINDOW_S := 10.0
const AUTO_MEDIUM_MS := 16.7  # ~60 fps
## D-93 capped "auto" at "low" on <= 4 GB phones; measured on SM-A165F it saved no memory and softened
## the lock section, so the owner made "low" manual only (D-96). RAM is still read for the log line.
const ORDER := ["low", "medium", "high"]

## Tests set physical_override (bytes).
var physical_override := -1

var current := {}
var _auto_time := 0.0
var _auto_frames := 0
var _auto_done := false
var _fps_label: Label = null


func _ready() -> void:
	current = PROFILES.get(Settings.get_value("quality_auto", "high"), PROFILES["high"])
	apply_profile(Settings.get_value("quality_profile", "auto"))
	print("Quality: RAM %.2f GiB, profile %s" % [physical_ram() / 1073741824.0, resolved_name()])
	if OS.is_debug_build():
		_fps_label = Label.new()
		_fps_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
		_fps_label.add_theme_font_size_override("font_size", 14)
		_fps_label.position = Vector2(8, 8)
		_fps_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_fps_label.visible = "--fps=1" in OS.get_cmdline_user_args()
		# N-67: autoload _ready runs while root is still adding its children ("Parent node is
		# busy setting up children"), so the overlay joins root on the next idle frame.
		get_tree().root.add_child.call_deferred(_fps_label)


## VA-15: debug builds only; F3 or a four-finger tap shows / hides the FPS overlay (in memory).
func _input(event: InputEvent) -> void:
	if _fps_label == null:
		return
	var toggle := false
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F3:
		toggle = true
	elif event is InputEventScreenTouch and event.pressed and event.index == 3:
		toggle = true
	if toggle:
		set_fps_overlay(not _fps_label.visible)


func set_fps_overlay(on: bool) -> void:
	if _fps_label != null:
		_fps_label.visible = on


func _process(delta: float) -> void:
	if _fps_label != null and _fps_label.visible:
		_fps_label.text = "FPS %d  frame %.1f ms" % [Engine.get_frames_per_second(), delta * 1000.0]
	if Settings.get_value("quality_profile", "auto") == "auto" and not _auto_done:
		_auto_time += delta
		_auto_frames += 1
		if _auto_time >= AUTO_WINDOW_S:
			_auto_done = true
			var avg_ms := _auto_time * 1000.0 / maxf(_auto_frames, 1)
			var picked := "medium" if avg_ms >= AUTO_MEDIUM_MS else "high"  # D-96: "low" is manual only
			Settings.set_value("quality_auto", picked)
			current = PROFILES[picked]
			profile_changed.emit(current)
			print("Quality: auto profile after %.0f s avg %.1f ms -> %s" % [_auto_time, avg_ms, picked])


func apply_profile(name: String) -> void:
	var key := auto_key(name, Settings.get_value("quality_auto", "high"))
	current = PROFILES[key]
	var root := get_tree().root
	root.scaling_3d_scale = current["render_scale"]
	root.msaa_3d = [Viewport.MSAA_DISABLED, Viewport.MSAA_2X, Viewport.MSAA_4X][current["msaa"]]
	profile_changed.emit(current)


## Total physical RAM in bytes (0 when unknown).
func physical_ram() -> int:
	if physical_override >= 0:
		return physical_override
	var phys := int(OS.get_memory_info().get("physical", -1))
	if phys > 0:
		return phys
	# Godot 4.7 on Android reports -1: ask the Android plugin (ActivityManager), then /proc/meminfo
	if Engine.has_singleton("LockwrightHaptics"):
		var p: Object = Engine.get_singleton("LockwrightHaptics")
		if p.has_method(&"has_java_method") and bool(p.call(&"has_java_method", &"device_ram_bytes")):
			var s := String(p.call(&"device_ram_bytes"))
			if s.is_valid_int() and int(s) > 0:
				return int(s)
	return meminfo_total(_read_lines("/proc/meminfo"))


## MemTotal from /proc/meminfo lines, in bytes (0 when missing).
static func meminfo_total(lines: PackedStringArray) -> int:
	for line in lines:
		if line.begins_with("MemTotal:"):
			var kb := line.substr(9).strip_edges().split(" ", false)
			if kb.size() > 0 and kb[0].is_valid_int():
				return int(kb[0]) * 1024
	return 0


static func _read_lines(path: String) -> PackedStringArray:
	var out := PackedStringArray()
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return out
	# /proc files report length 0, so read line by line
	while out.size() < 64:
		var line := f.get_line()
		if line == "" and f.eof_reached():
			break
		out.append(line)
	return out


## Profile actually used for the Settings value `setting`: a hand-picked profile as is, "auto" =
## the last frame-time pick (`auto_pick`, never "low": D-96 keeps "low" a manual choice).
static func auto_key(setting: String, auto_pick: String) -> String:
	var key := setting
	if key == "auto":
		key = auto_pick if auto_pick == "high" or auto_pick == "medium" else ("medium" if auto_pick == "low" else "high")
	if not PROFILES.has(key):
		key = "high"
	return key


## N-99: the Settings entry for "auto", naming the profile it resolved to ("Auto (średnia)").
func auto_label() -> String:
	var key := auto_key("auto", Settings.get_value("quality_auto", "high"))
	return I18n.t(StringName("settings.quality_auto_" + key))


## Name of the profile in use ("high" | "medium" | "low"), also when the setting is "auto" (N-99).
func resolved_name() -> String:
	return auto_key(Settings.get_value("quality_profile", "auto"), Settings.get_value("quality_auto", "high"))


func planb_size(base: Vector2i) -> Vector2i:
	return Vector2i(base * current["planb_scale"])


func msaa_index() -> int:
	return current["msaa"]
