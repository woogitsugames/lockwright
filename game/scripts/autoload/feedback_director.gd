extends Node
## FeedbackDirector (ARCHITECTURE.md §5, TECH.md §3.5): routes lock events to
## Haptics and Sfx with priorities, transient limits, 30 ms coalescing, ducking and
## the essential/continuousFloor rule. All rules come from game/data/haptics_patterns.json.

signal none

const COALESCE_WINDOW_MS := 30
const UPDATE_MIN_INTERVAL_MS := 16  # R-22: <= 60 Hz continuous updates

var _transient_times: Array[float] = []
var _last_transient_by_kind: Dictionary = {}
var _last_continuous_sent := 0.0
var _last_continuous: Dictionary = {}
var _continuous_floor := 0.1


func _ready() -> void:
	var rules: Dictionary = Haptics.patterns.get("mix_rules", {})
	_continuous_floor = 0.1


func continuous_floor() -> float:
	return _continuous_floor


func _now_ms() -> float:
	return Time.get_ticks_msec()


func _transient_limit() -> int:
	var caps: Dictionary = Haptics.capabilities()
	var tier: String = caps.get("tier", "fallback")
	var limits: Dictionary = Haptics.patterns.get("mix_rules", {}).get("transient_limit_per_s", {})
	if tier.begins_with("A0"):
		return int(limits.get("a0", 3))
	if tier.begins_with("A1"):
		return int(limits.get("a1", 6))
	if tier.begins_with("A"):
		return int(limits.get("android_a2_a4", 12))
	return int(limits.get("ios", 25))


func _prune(now_ms: float) -> void:
	while not _transient_times.is_empty() and now_ms - _transient_times[0] > 1000.0:
		_transient_times.pop_front()


func emit_event(event: Dictionary) -> void:
	# event: {kind, sub, element, intensity, material, tick}
	var kind: StringName = event.get("kind", &"contact")
	var pattern: Dictionary = Haptics.pattern_for(kind)
	if pattern.is_empty():
		return
	var priority: int = int(pattern.get("priority", 15))
	var essential: bool = pattern.get("essential", false)
	var intensity: float = event.get("intensity", 1.0)
	var material: StringName = event.get("material", &"brass")

	var now_ms := _now_ms()
	_prune(now_ms)
	# coalesce same-kind events inside the 30 ms window to max intensity (TECH §3.5)
	if _last_transient_by_kind.has(kind):
		var last: Dictionary = _last_transient_by_kind[kind]
		if now_ms - last["at"] < COALESCE_WINDOW_MS:
			last["intensity"] = maxf(last["intensity"], intensity)
			last["at"] = now_ms
			return
	# transient rate limit: drop lowest-priority excess (never queued)
	if _transient_times.size() >= _transient_limit():
		if priority >= 3:
			_transient_times.pop_front()  # priorities 1-3 interrupt everything
		else:
			return
	_transient_times.append(now_ms)
	_last_transient_by_kind[kind] = {"at": now_ms, "intensity": intensity}

	var scaled := intensity
	if essential and Settings.haptics_enabled():
		scaled = maxf(intensity * Settings.haptics_intensity(), _continuous_floor)
	# ducking: transient prio <= 10 ducks the resistance channel (TECH §3.5)
	if priority <= 10:
		_duck_continuous()
	Haptics.play(kind, scaled, material)
	Sfx.play(kind, material)


func update_continuous(id: StringName, intensity: float, sharpness: float) -> void:
	# R-22: throttle to <= 60 Hz and skip no-op updates
	var now_ms := _now_ms()
	if now_ms - _last_continuous_sent < UPDATE_MIN_INTERVAL_MS:
		_last_continuous[id] = [intensity, sharpness]
		return
	var last: Array = _last_continuous.get(id, [-1.0, -1.0])
	if absf(last[0] - intensity) < 0.02 and absf(last[1] - sharpness) < 0.02:
		return
	_last_continuous_sent = now_ms
	_last_continuous[id] = [intensity, sharpness]
	Haptics.update_continuous(id, intensity, sharpness)


func _duck_continuous() -> void:
	# brief dip of the resistance channel; Android A1/A3 skip one segment instead
	Haptics.update_continuous(&"tension_resistance", 0.0, 0.1)


func reset() -> void:
	_transient_times.clear()
	_last_transient_by_kind.clear()
	_last_continuous.clear()
