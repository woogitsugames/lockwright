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
var _duck_until_ms := 0.0


var _budget := {}

func _ready() -> void:
	_budget = Haptics.patterns.get("budget", {})
	_continuous_floor = 0.1


func budget() -> Dictionary:
	return _budget


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
	var sub: int = event.get("sub", 0)
	var element: int = event.get("element", -1)
	var name: String = event.get("name", String(kind) + "." + str(sub))
	# FEEL 7.2: sub-events route by family name first (sub_events), fallback to base kind
	var pattern: Dictionary = Haptics.patterns.get("sub_events", {}).get(name, {})
	if pattern.is_empty():
		pattern = Haptics.pattern_for(kind)
	if pattern.is_empty():
		return
	var priority: int = int(pattern.get("priority", Haptics.pattern_for(kind).get("priority", 15)))
	var essential: bool = pattern.get("essential", Haptics.pattern_for(kind).get("essential", false))
	var intensity: float = event.get("intensity", 1.0)
	var material: StringName = event.get("material", &"brass")

	var now_ms := _now_ms()
	_prune(now_ms)
	# FEEL 7.3: coalesce by (kind, sub, element), window does NOT move
	var ckey := "%s/%d/%d" % [kind, sub, element]
	if _last_transient_by_kind.has(ckey):
		var last: Dictionary = _last_transient_by_kind[ckey]
		if now_ms - last["at"] < COALESCE_WINDOW_MS:
			last["intensity"] = maxf(last["intensity"], intensity)
			return
	# transient rate limit: drop lowest-priority excess (never queued)
	if _transient_times.size() >= _transient_limit():
		if priority <= int(Haptics.patterns.get("mix_rules", {}).get("interrupt_priority_max", 3)):
			_transient_times.pop_front()  # FEEL 7.1: priorities 1-3 interrupt everything (low number = high priority)
		else:
			return
	_transient_times.append(now_ms)
	_last_transient_by_kind[ckey] = {"at": now_ms, "intensity": intensity}

	# FEEL 7.5: scale by the slider exactly once; essential floor applied at the very end
	var scaled := intensity * Settings.haptics_intensity() if Settings.haptics_enabled() else 0.0
	if essential and scaled > 0.0:
		scaled = maxf(scaled, _continuous_floor)
	# ducking: transient prio <= 10 ducks the resistance channel (TECH §3.5)
	if priority <= 10:
		_duck_continuous()
	Haptics.play(kind, scaled, material, false)  # no second scaling inside Haptics
	Sfx.play(pattern.get("sfx", {}).get("id", kind), material)


func update_continuous(id: StringName, intensity: float, sharpness: float) -> void:
	# R-22: throttle to <= 60 Hz and skip no-op updates
	var now_ms := _now_ms()
	if now_ms < _duck_until_ms:
		return  # N-02/FEEL 7.4: ducking pauses updates instead of zeroing the channel
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
	# FEEL 7.4 / TECH §3.5: duck x0.3 for 35 ms + 60 ms ramp — implemented as a pause
	# of updates (the bridge never sees a zero, so A1/A3 don't cut the transient — N-02)
	_duck_until_ms = _now_ms() + 95.0


func reset() -> void:
	_transient_times.clear()
	_last_transient_by_kind.clear()
	_last_continuous.clear()
