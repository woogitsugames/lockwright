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
## N-70: a cheap ERM ("coin") motor without amplitude control needs ~25-30 ms to spin up;
## the 6-19 ms pulses the fallback used to send were registered by the vibrator service
## but not felt. Every on/off pulse is at least this long.
const ERM_MIN_MS := 30
const ERM_MAX_MS := 120
## Two on/off pulses closer than this blur into one on an ERM; extra ones are dropped
## (the two-click calibration is 120 ms apart and must keep both).
const FALLBACK_MIN_GAP_MS := 100
## Settings "Test pulse": long enough to be unmistakable on any motor (owner felt a system
## 250 ms oneshot, not the game's 19 ms one).
const TEST_PULSE_MS := 220

var patterns: Dictionary = {}
var _native: Object = null
var _native_methods: Dictionary = {}  # method -> bool (cache)
var _continuous: Dictionary = {}  # id -> bool
var _last_fallback_ms := -100000
## Tests: replaces Input.vibrate_handheld(duration_ms, amplitude).
var vibrate_override: Callable = Callable()


func _ready() -> void:
	load_patterns()
	if Engine.has_singleton(NATIVE_SINGLETON):
		use_native(Engine.get_singleton(NATIVE_SINGLETON))
	else:
		print("Haptics: no native plugin, using Input.vibrate_handheld fallback (editor/desktop)")


## Attaches the native bridge (the Android JNISingleton, the iOS GDExtension object, or a
## test fake). null detaches it.
func use_native(native: Object) -> void:
	_native = native
	_native_methods.clear()
	if _native == null:
		return
	prepare_native()
	print("Haptics: native plugin %s detected, play=%s test_pulse=%s caps=%s" % [
		NATIVE_SINGLETON, native_has(&"play"), native_has(&"test_pulse"), capabilities()])


## N-70: Object.has_method() is false for every method of an Android plugin singleton
## (JNISingleton registers them in its own map, exposed as has_java_method()), so the
## facade used to treat the Kotlin plugin as absent: capabilities() reported
## fallback/native=false and play() went to the 6-19 ms vibrate_handheld fallback.
func native_has(method: StringName) -> bool:
	if _native == null:
		return false
	if _native_methods.has(method):
		return _native_methods[method]
	var ok := false
	if _native.has_method(&"has_java_method"):
		ok = bool(_native.call(&"has_java_method", method))
	else:
		ok = _native.has_method(method)
	_native_methods[method] = ok
	return ok


func is_native() -> bool:
	return native_has(&"play")


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


func detail_index() -> Dictionary:
	# Task 4: per-event files from haptics/out (AHAP on iOS, Android chains A4->A0).
	# Routing: sub_events["<family>.<name>"] first, then the base event; the file key
	# comes from index.json -> families[f].events[e].ios[] / android.file.
	var idx_path: String = patterns.get("detail", {}).get("index", "")
	if idx_path == "" or not ResourceLoader.exists(idx_path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(idx_path))
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}


func pattern_files_for(family: StringName, event: StringName) -> Dictionary:
	var idx := detail_index()
	var fam: Dictionary = idx.get("families", {}).get(String(family), {})
	var ev: Dictionary = fam.get("events", {}).get(String(event), {})
	return ev if ev is Dictionary else {}


func prepare_native() -> void:
	# Bridges with a prepare()/load_patterns() hook receive the runtime index plus the
	# detail file map, so AHAP/chains are prebuilt off the game thread.
	if native_has(&"load_patterns"):
		_native.call(&"load_patterns", JSON.stringify({"patterns": patterns, "detail": detail_index()}))


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
	if native_has(&"play"):
		_native.call(&"play", String(event), inten, String(material))
	else:
		_fallback_vibrate(spec, inten, sharpness)


## Settings "Test pulse": one clearly perceptible pulse on every motor type (N-70).
## Honors the on/off switch; at 100 % the system default amplitude is used.
func test_pulse() -> void:
	if not Settings.haptics_enabled():
		return
	var level := clampf(Settings.haptics_intensity(), 0.0, 1.0)
	if native_has(&"test_pulse"):
		_native.call(&"test_pulse", TEST_PULSE_MS, level)
	elif native_has(&"play"):
		_native.call(&"play", "open", maxf(level, 0.2), "brass")  # iOS bridge: strongest transient
	else:
		_vibrate(TEST_PULSE_MS, -1.0 if level >= 0.99 else maxf(level, 0.2))


func begin_continuous(id: StringName) -> void:
	_continuous[id] = true
	if native_has(&"begin_continuous"):
		_native.call(&"begin_continuous", String(id))


func update_continuous(id: StringName, intensity: float, sharpness: float) -> void:
	if not _continuous.get(id, false):
		return
	if not Settings.haptics_enabled() or not Settings.get_value("continuous_resistance"):
		end_continuous(id)
		return
	var i := clampf(intensity * Settings.haptics_intensity(), 0.0, 1.0)
	if native_has(&"update_continuous"):
		_native.call(&"update_continuous", String(id), i, clampf(sharpness, 0.0, 1.0))


func end_continuous(id: StringName) -> void:
	_continuous.erase(id)
	if native_has(&"end_continuous"):
		_native.call(&"end_continuous", String(id))


func capabilities() -> Dictionary:
	if native_has(&"capabilities"):
		var caps: Variant = _native.call(&"capabilities")
		if typeof(caps) == TYPE_STRING:
			var parsed: Variant = JSON.parse_string(caps)
			if typeof(parsed) == TYPE_DICTIONARY:
				return parsed
		elif typeof(caps) == TYPE_DICTIONARY:
			return caps
	return {"tier": "fallback", "primitives": [], "amplitude_control": false, "envelope": false, "native": false}


## On/off pulse length (ms) for an event without the native plugin (A0 tier,
## docs/TECH.md §2.2): only events with an `a0_ms` (or essential ones) vibrate, never
## shorter than ERM_MIN_MS; 0 = this event has no pulse on an on/off motor.
static func fallback_pulse_ms(spec: Dictionary, intensity: float) -> int:
	if spec.is_empty() or intensity <= 0.0:
		return 0
	var fb: Dictionary = spec.get("fallback", {})
	var base := 0.0
	if fb.has("a0_ms"):
		base = float(fb["a0_ms"])
	elif bool(spec.get("essential", false)):
		base = float(fb.get("ms", spec.get("ios", {}).get("duration_ms", ERM_MIN_MS)))
	if base <= 0.0:
		return 0
	# without amplitude control the length is the only lever: soften a little, never below the floor
	return int(clampf(base * (0.75 + 0.25 * clampf(intensity, 0.0, 1.0)), ERM_MIN_MS, ERM_MAX_MS))


func _fallback_vibrate(spec: Dictionary, intensity: float, _sharpness: float) -> void:
	var dur_ms := fallback_pulse_ms(spec, intensity)
	if dur_ms <= 0:
		return
	var now := Time.get_ticks_msec()
	if now - _last_fallback_ms < FALLBACK_MIN_GAP_MS:
		return
	_last_fallback_ms = now
	_vibrate(dur_ms, -1.0)


func _vibrate(dur_ms: int, amplitude: float) -> void:
	if vibrate_override.is_valid():
		vibrate_override.call(dur_ms, amplitude)
		return
	if DisplayServer.get_name() == "headless":
		return
	Input.vibrate_handheld(dur_ms, amplitude)
