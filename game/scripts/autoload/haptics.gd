extends Node
## Haptics facade. Common interface matching HapticsBridge (docs/TECH.md §2.5):
## play(event, intensity, material), begin_continuous(id), update_continuous(id, intensity, sharpness),
## end_continuous(id), capabilities().
## Prefers the native plugin singleton "LockwrightHaptics"; falls back to
## Input.vibrate_handheld; logs in the editor. Haptics is never the only
## information channel (XAG 103/110) — audio and visuals mirror every event.

signal capabilities_changed(caps: Dictionary)

const PATTERNS_PATH := "res://data/haptics_patterns.json"
const NATIVE_SINGLETON := "LockwrightHaptics"

var patterns: Dictionary = {}
var _native: Object = null
var _continuous: Dictionary = {}  # id -> bool


func _ready() -> void:
	load_patterns()
	if Engine.has_singleton(NATIVE_SINGLETON):
		_native = Engine.get_singleton(NATIVE_SINGLETON)
		print("Haptics: native plugin %s detected, caps=%s" % [NATIVE_SINGLETON, capabilities()])
	else:
		print("Haptics: no native plugin, using Input.vibrate_handheld fallback (editor/desktop)")


func load_patterns() -> void:
	var file := FileAccess.open(PATTERNS_PATH, FileAccess.READ)
	if file == null:
		push_error("Haptics: missing %s" % PATTERNS_PATH)
		patterns = {}
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Haptics: invalid %s" % PATTERNS_PATH)
		patterns = {}
		return
	patterns = parsed


func pattern_for(event: StringName) -> Dictionary:
	return patterns.get("events", {}).get(String(event), {})


func continuous_pattern_for(id: StringName) -> Dictionary:
	return patterns.get("continuous", {}).get(String(id), {})


func material_modifier(material: StringName) -> Dictionary:
	return patterns.get("material_modifiers", {}).get(String(material), {"delta_sharpness": 0.0, "intensity_scale": 1.0})


func _scaled_intensity(event: StringName, intensity: float, material: StringName) -> float:
	var mod := material_modifier(material)
	var base: float = pattern_for(event).get("ios", {}).get("intensity", 0.5)
	var i := intensity * base * float(mod.get("intensity_scale", 1.0))
	if not Settings.haptics_enabled():
		return 0.0
	return clampf(i * Settings.haptics_intensity(), 0.0, 1.0)


func play(event: StringName, intensity: float = 1.0, material: StringName = &"brass", scale_intensity: bool = true) -> void:
	if not Settings.haptics_enabled():
		return
	var spec := pattern_for(event)
	if spec.is_empty():
		push_warning("Haptics: no pattern for event %s" % event)
		return
	var sharpness := clampf(float(spec.get("ios", {}).get("sharpness", 0.5)) + float(material_modifier(material).get("delta_sharpness", 0.0)), 0.0, 1.0)
	var inten := _scaled_intensity(event, intensity, material) if scale_intensity else clampf(intensity, 0.0, 1.0)
	if _native != null and _native.has_method("play"):
		_native.play(event, inten, material)
	else:
		_fallback_vibrate(spec, inten, sharpness)


func begin_continuous(id: StringName) -> void:
	_continuous[id] = true
	if _native != null and _native.has_method("begin_continuous"):
		_native.begin_continuous(id)


func update_continuous(id: StringName, intensity: float, sharpness: float) -> void:
	if not _continuous.get(id, false):
		return
	if not Settings.haptics_enabled() or not Settings.get_value("continuous_resistance"):
		end_continuous(id)
		return
	var i := clampf(intensity * Settings.haptics_intensity(), 0.0, 1.0)
	if _native != null and _native.has_method("update_continuous"):
		_native.update_continuous(id, i, clampf(sharpness, 0.0, 1.0))


func end_continuous(id: StringName) -> void:
	_continuous.erase(id)
	if _native != null and _native.has_method("end_continuous"):
		_native.end_continuous(id)


func capabilities() -> Dictionary:
	if _native != null and _native.has_method("capabilities"):
		var caps: Variant = _native.capabilities()
		if typeof(caps) == TYPE_STRING:
			var parsed: Variant = JSON.parse_string(caps)
			if typeof(parsed) == TYPE_DICTIONARY:
				return parsed
		elif typeof(caps) == TYPE_DICTIONARY:
			return caps
	return {"tier": "fallback", "primitives": [], "amplitude_control": false, "envelope": false, "native": false}


func _fallback_vibrate(spec: Dictionary, intensity: float, sharpness: float) -> void:
	var ios: Dictionary = spec.get("ios", {})
	var dur_ms := int(clampf(float(ios.get("duration_ms", 20)) * (0.5 + 0.5 * intensity), 5, 120))
	if DisplayServer.get_name() == "headless":
		return
	Input.vibrate_handheld(dur_ms, -1.0 if intensity > 0.0 else 0.0)
