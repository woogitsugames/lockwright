class_name LockFeel
extends RefCounted
## Lock "feel" routing (D-130, docs/handoff/LOCK-FEEL-2026-11-13.md): one place that turns the
## lockcore events of a physics step into sound, haptics and what a screen reader may say, for every
## lock screen (lock_photoreal.gd and planb_family_job.gd). Data: res://data/lock_feel.json.
##
## What it adds over "play the base kind":
##  - family sub-events (lockcore `sub` != 0: pin.serration, lever.false_gate, ring.detent ...) get
##    their own sound and a light haptic instead of the full base pattern (FEEL F-04: a serration
##    tick must not sound like a false set);
##  - the sound level of non-essential kinds follows the event intensity (a neighbour's faint
##    contact, one pin dropping vs. all five);
##  - two events that are one physical moment are folded (gate_align under set, the false gate's
##    second knock), and a step with open / break / detector_trip sends that haptic only: a later
##    vibrate() call would cut the long pattern short on Android;
##  - the open payoff timeline and the micro-motion durations every lock view shares.
## Pure where it can be (plan / plan_step / open_progress) so GUT checks the tables directly.

const PATH := "res://data/lock_feel.json"
## Kinds whose haptic must not be cut by another event of the same step.
const EXCLUSIVE := [&"open", &"break", &"detector_trip"]
## DESIGN.md §1: every animation 100-250 ms.
const MOTION_MIN_MS := 100.0
const MOTION_MAX_MS := 250.0
const TUTORIAL_BOOST_DB := 2.0  # ONBOARDING §4: fb_gain > 1 (S1-S3) plays a little louder

static var _data: Dictionary = {}
static var _last_ms: Dictionary = {}  # sub-event name -> msec of its last play (min_gap_ms)
static var _cycle: Dictionary = {}    # sub-event name -> plays so far (pitch_cycle)


static func data() -> Dictionary:
	if _data.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		if typeof(parsed) == TYPE_DICTIONARY:
			_data = parsed
		else:
			push_error("LockFeel: invalid %s" % PATH)
			_data = {"subs": {}, "routes": {}}
	return _data


## Tests: forget the per-name clocks.
static func reset() -> void:
	_last_ms.clear()
	_cycle.clear()


## Family name of a sub-event ("pin.serration"), "" for a base event or an unrouted sub.
static func sub_name(family: StringName, e: Dictionary) -> String:
	var sub := int(e.get("sub", 0))
	if sub == 0:
		return ""
	var routes: Dictionary = data().get("routes", {}).get(String(family), {})
	return String(routes.get("%s.%d" % [String(e.get("kind", "")), sub], ""))


## Level of a base event's sound from its intensity (0 dB for kinds that always play in full).
static func intensity_gain_db(kind: StringName, intensity: float) -> float:
	var ig: Dictionary = data().get("intensity_gain", {})
	if not (ig.get("kinds", []) as Array).has(String(kind)):
		return 0.0
	return float(ig.get("floor_db", -6.0)) * (1.0 - clampf(intensity, 0.0, 1.0))


## What one event plays: {name, kind, material, sounds: [{id, material, gain_db, pitch, delay_ms}],
## haptic (&"" = none), haptic_intensity, announce, caption (null = by kind), min_gap_ms}.
static func plan(family: StringName, e: Dictionary, fb_gain: float = 1.0) -> Dictionary:
	var kind := StringName(e.get("kind", &"contact"))
	var material := StringName(e.get("material", &"brass"))
	var intensity := clampf(float(e.get("intensity", 1.0)), 0.0, 1.0)
	var boost := TUTORIAL_BOOST_DB if fb_gain > 1.0 else 0.0
	var name := sub_name(family, e)
	var spec: Dictionary = data().get("subs", {}).get(name, {}) if name != "" else {}
	if spec.is_empty():
		return {
			"name": "", "kind": kind, "material": material,
			"sounds": [{"id": kind, "material": material, "gain_db": intensity_gain_db(kind, intensity) + boost, "pitch": 1.0, "delay_ms": 0}],
			"haptic": kind, "haptic_intensity": minf(intensity * fb_gain, 1.0),
			"announce": true, "caption": null, "min_gap_ms": 0,
		}
	var sounds: Array = []
	for s in spec.get("sounds", []):
		var pitch := float(s.get("pitch", 1.0)) + float(s.get("pitch_per_element", 0.0)) * clampi(int(e.get("element", 0)), 0, 4)
		var cyc: Array = s.get("pitch_cycle", [])
		if not cyc.is_empty():
			pitch = float(cyc[int(_cycle.get(name, 0)) % cyc.size()])
		sounds.append({
			"id": StringName(s.get("id", kind)), "material": StringName(s.get("material", material)),
			"gain_db": float(s.get("gain_db", 0.0)) + boost, "pitch": pitch, "delay_ms": int(s.get("delay_ms", 0)),
		})
	var h_int := intensity
	if spec.has("haptic_intensity"):
		h_int = float(spec["haptic_intensity"])
	h_int *= float(spec.get("haptic_scale", 1.0))
	return {
		"name": name, "kind": kind, "material": material, "sounds": sounds,
		"haptic": StringName(spec.get("haptic", "")), "haptic_intensity": minf(h_int * fb_gain, 1.0),
		"announce": bool(spec.get("announce", true)), "caption": String(spec.get("caption", "")),
		"min_gap_ms": int(spec.get("min_gap_ms", 0)),
	}


## Plans for all events of one physics step, with the folds applied (see the class comment).
static func plan_step(family: StringName, events: Array, fb_gain: float = 1.0) -> Array:
	var plans: Array = []
	var exclusive := false
	var set_elements := {}
	for e in events:
		var kind := StringName(e.get("kind", &""))
		if kind in EXCLUSIVE:
			exclusive = true
		if kind == &"set":
			set_elements[int(e.get("element", -1))] = true
	var under_db := float(data().get("fold", {}).get("gate_align_under_set_db", -6.0))
	for e in events:
		var p := plan(family, e, fb_gain)
		var kind: StringName = p["kind"]
		if kind == &"gate_align" and set_elements.has(int(e.get("element", -1))):
			# FEEL §3.5: gate_align + set of one element = one click; the "tok" stays as a quiet layer
			p["haptic"] = &""
			for s in p["sounds"]:
				s["gain_db"] = float(s["gain_db"]) + under_db
			p["announce"] = false
		if exclusive and not kind in EXCLUSIVE:
			p["haptic"] = &""
		plans.append(p)
	return plans


## Plays one plan. Returns false when the sub-event came again inside its min gap (nothing played).
static func perform(p: Dictionary, now_ms: int = -1) -> bool:
	var name := String(p.get("name", ""))
	if name != "":
		var now := now_ms if now_ms >= 0 else Time.get_ticks_msec()
		var gap := int(p.get("min_gap_ms", 0))
		if gap > 0 and _last_ms.has(name) and now - int(_last_ms[name]) < gap:
			return false
		_last_ms[name] = now
		_cycle[name] = int(_cycle.get(name, 0)) + 1
	var haptic: StringName = p.get("haptic", &"")
	if haptic != &"":
		Haptics.play(haptic, float(p.get("haptic_intensity", 1.0)), p.get("material", &"brass"))
	for s in p.get("sounds", []):
		if int(s.get("delay_ms", 0)) > 0:
			Sfx.play_delayed(s["id"], s["material"], int(s["delay_ms"]), float(s["gain_db"]), float(s["pitch"]))
		else:
			Sfx.play(s["id"], s["material"], float(s["gain_db"]), float(s["pitch"]))
	return true


## Sound + haptics for all events of one step. Each event is tagged for the listeners of
## Events.lock_event: `feel` (sub-event name), and for routed sub-events `announce` (may a screen
## reader say the base line) and `caption` (sound caption key, "" = none).
static func play_step(family: StringName, events: Array, fb_gain: float = 1.0) -> Array:
	var plans := plan_step(family, events, fb_gain)
	for i in events.size():
		var p: Dictionary = plans[i]
		var e: Dictionary = events[i]
		if String(p["name"]) != "":
			e["feel"] = p["name"]
			e["caption"] = p["caption"]
		if not bool(p["announce"]):
			e["announce"] = false
		perform(p)
	return plans


# ------------------------------------------------------------------ timing shared by the lock views
static func _ms(section: String, key: String, fallback: float) -> float:
	return float(data().get(section, {}).get(key, fallback))


static func open_hold_s() -> float:
	return _ms("open", "hold_ms", 60.0) / 1000.0


static func open_throw_s() -> float:
	return _ms("open", "throw_ms", 220.0) / 1000.0


## How long the screen stays on the open lock before it moves on (the clip, the haptic and the
## throw have all finished by then).
static func open_payoff_s() -> float:
	return _ms("open", "payoff_ms", 850.0) / 1000.0


static func motion_s(key: String, fallback_ms: float = 120.0) -> float:
	return _ms("motion", key, fallback_ms) / 1000.0


## DESIGN.md §1 easing: fast start, soft landing, never past the target.
static func ease_out_cubic(u: float) -> float:
	var v := 1.0 - clampf(u, 0.0, 1.0)
	return 1.0 - v * v * v


## 0..1 progress of the opening throw `t` seconds after the open event: a short hold (the last
## element has just clicked), then the throw. Monotonic, ends exactly at 1.
static func open_progress(t: float) -> float:
	var hold := open_hold_s()
	if t <= hold:
		return 0.0
	return ease_out_cubic((t - hold) / maxf(open_throw_s(), 0.001))


## 0..1 progress of a micro-motion of `dur` seconds that started `t` seconds ago (after `delay`).
static func motion_progress(t: float, dur: float, delay: float = 0.0) -> float:
	if t <= delay:
		return 0.0
	return ease_out_cubic((t - delay) / maxf(dur, 0.001))
