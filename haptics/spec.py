"""Single machine-readable haptics source for Lockwright, built from docs/FEEL.md.

Layers (lowest to highest):
  1. game/data/haptics_patterns.json  -- current runtime bank (read only, owned by session B)
  2. FEEL.md §9 JSON merge patch       -- extracted programmatically from the ```json fence under "## 9."
     merged with RFC 7396 semantics -> BANK (the full bank, same shape the game will load)
  3. IOS_PATTERNS / SUB_PATTERNS below -- the iOS Core Haptics pattern shapes from FEEL §2 / §3 tables,
     encoded as data (brass values, I_event = 1, before material x family modifiers, FEEL §1.4)
  4. FAMILY_EVENTS                     -- what each family really emits (FEEL §3 cards, checked against
     lockcore/src/families/*.cpp)

Nothing here writes files; build.py and validate.py import this module.
"""
from __future__ import annotations

import copy
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
FEEL_PATH = ROOT / "docs" / "FEEL.md"
BANK_PATH = ROOT / "game" / "data" / "haptics_patterns.json"
SFX_DIR = ROOT / "audio" / "v2" / "out" / "sfx"
OUT_DIR = Path(__file__).resolve().parent / "out"

FAMILIES = ["pin_tumbler", "wafer", "wooden_pin", "warded", "lever", "lever_detector", "ring_combo"]
BASE_EVENTS = ["contact", "bind", "near_shear", "set", "false_set", "counter_rotate", "overset", "drop",
               "stress", "break", "wear", "gate_align", "detector_trip", "open"]
CONTINUOUS = ["tension_resistance", "pick_drag"]
TOOL_EVENTS = {"stress", "break", "wear"}  # FEEL §1.4: always steel (lockcore ToolStress), no family modifier
TIERS = ["a4", "a3", "a2", "a1", "a0"]  # FEEL §1.3, best first
TIER_RANK = {"a0": 0, "a1": 1, "a2": 2, "a3": 3, "a4": 4}
ANDROID_PRIMITIVES = ["CLICK", "TICK", "LOW_TICK", "THUD", "SPIN", "QUICK_RISE", "SLOW_RISE", "QUICK_FALL"]
# A2 detection guarantees only CLICK + TICK (TECH §2.2); used for the "minimal primitives" selection column.
MIN_PRIMITIVES = {"CLICK", "TICK"}


# --------------------------------------------------------------------------------------------------
# 1-2. Bank = haptics_patterns.json  (+)  FEEL §9 merge patch
# --------------------------------------------------------------------------------------------------
def extract_feel_patch(feel_text: str) -> dict:
    """Return the JSON object in the first ```json fence after the '## 9.' heading of FEEL.md."""
    m = re.search(r"^## 9\..*?$", feel_text, flags=re.M)
    if not m:
        raise ValueError("FEEL.md: heading '## 9.' not found")
    rest = feel_text[m.end():]
    f = re.search(r"^```json[ \t]*\n(.*?)^```", rest, flags=re.M | re.S)
    if not f:
        raise ValueError("FEEL.md §9: no ```json fence")
    return json.loads(f.group(1))


def merge_patch(target, patch):
    """RFC 7396 JSON Merge Patch."""
    if not isinstance(patch, dict):
        return copy.deepcopy(patch)
    result = copy.deepcopy(target) if isinstance(target, dict) else {}
    for k, v in patch.items():
        if v is None:
            result.pop(k, None)
        else:
            result[k] = merge_patch(result.get(k), v)
    return result


def load_bank() -> tuple[dict, dict, dict]:
    """Returns (merged_bank, original_bank, feel_patch)."""
    original = json.loads(BANK_PATH.read_text(encoding="utf-8"))
    patch = extract_feel_patch(FEEL_PATH.read_text(encoding="utf-8"))
    return merge_patch(original, patch), original, patch


# --------------------------------------------------------------------------------------------------
# 3. Modifiers (FEEL §1.4)
# --------------------------------------------------------------------------------------------------
def clamp(x: float, lo: float = 0.0, hi: float = 1.0) -> float:
    return lo if x < lo else hi if x > hi else x


def q(x: float, nd: int = 4) -> float:
    """Stable float formatting: fixed rounding and no negative zero."""
    r = round(float(x), nd)
    return 0.0 if r == 0 else r


def event_material(bank: dict, family: str, event: str) -> tuple[str, bool]:
    """(material, apply_family_modifier) for an event played in a family with its default material.

    FEEL §1.4: tool events (stress/break/wear) are always steel - and, since the tool is the same in
    every family, we do not apply the family modifier to them (decision of this build, see README).
    wood.creak carries the lock material (lockcore wooden_pin.cpp emits S.material = wood).
    """
    if event in TOOL_EVENTS:
        return "steel", False
    return bank["families"][family]["material"], True


def modifiers(bank: dict, family: str, event: str) -> dict:
    mat, fam_on = event_material(bank, family, event)
    mm = bank["material_modifiers"][mat]
    fm = bank["families"][family]
    k_fam = fm.get("intensity_scale", 1.0) if fam_on else 1.0
    ds_fam = fm.get("delta_sharpness", 0.0) if fam_on else 0.0
    return {
        "material": mat,
        "family_modifier_applied": fam_on,
        "k": q(mm["intensity_scale"] * k_fam),
        "ds": q(mm["delta_sharpness"] + ds_fam),
        "k_material": mm["intensity_scale"], "ds_material": mm["delta_sharpness"],
        "k_family": k_fam, "ds_family": ds_fam,
    }


# --------------------------------------------------------------------------------------------------
# 4. Which events each family emits (FEEL §3 cards; cross-checked with lockcore/src/families/*.cpp)
#    Values: "play" = own pattern; "fold:<event>" = only as a layer of another pattern (FEEL §1.2, F-05);
#    "audio" = no haptic during the lock (wear).
# --------------------------------------------------------------------------------------------------
FAMILY_EVENTS: dict[str, dict[str, str]] = {
    # FEEL §3.1
    "pin_tumbler": {e: "play" for e in ["contact", "bind", "near_shear", "set", "false_set", "counter_rotate",
                                        "overset", "drop", "stress", "break", "open"]}
    | {"wear": "audio", "pin.serration": "play", "pin.spring_bounce": "play"},
    # FEEL §3.2 (no false_set, no counter_rotate)
    "wafer": {e: "play" for e in ["contact", "bind", "near_shear", "set", "overset", "drop", "stress", "break",
                                  "open"]} | {"wear": "audio", "wafer.rattle": "play"},
    # FEEL §3.3 (no_break: no break, stress only as wood.creak; wear not listed)
    "wooden_pin": {e: "play" for e in ["contact", "bind", "near_shear", "set", "overset", "drop", "open"]}
    | {"wood.creak": "play"},
    # FEEL §3.4 (no false_set/overset/counter_rotate/near_shear; gate_align stands alone here).
    # wear: not in the card, but warded.cpp runs ToolStress::end_step, which emits wear -> audio only.
    "warded": {e: "play" for e in ["contact", "gate_align", "bind", "set", "drop", "stress", "break", "open"]}
    | {"wear": "audio", "ward.scrape": "play"},
    # FEEL §3.5: gate_align + set in one step -> one set pattern; false_set + lever.false_gate -> one pair @40 ms
    "lever": {e: "play" for e in ["contact", "bind", "near_shear", "set", "false_set", "counter_rotate",
                                  "overset", "drop", "stress", "break", "open"]}
    | {"wear": "audio", "gate_align": "fold:set", "lever.false_gate": "fold:false_set"},
    # FEEL §3.6: lever + detector_trip, detector.reset (+ game-side reset-hold ticks)
    "lever_detector": {e: "play" for e in ["contact", "bind", "near_shear", "set", "false_set", "counter_rotate",
                                           "overset", "drop", "stress", "break", "open", "detector_trip"]}
    | {"wear": "audio", "gate_align": "fold:set", "lever.false_gate": "fold:false_set",
       "detector.reset": "play", "detector.reset_hold": "play"},
    # FEEL §3.7: no stress/break/wear, no counter_rotate/overset
    "ring_combo": {e: "play" for e in ["contact", "bind", "near_shear", "set", "false_set", "drop", "open"]}
    | {"gate_align": "fold:set", "ring.detent": "play"},
}


# --------------------------------------------------------------------------------------------------
# 5. iOS pattern shapes (brass, I_event = 1). Times in ms.
#    Element forms:
#      ["T", t, I, S]                         HapticTransient
#      ["C", t, dur, I, S]                    HapticContinuous (attack 0, release 0.1, sustained)
#      ["CURVE", "HapticIntensityControl"|"HapticSharpnessControl", [[t, v], ...]]
#    Parametric kinds are expanded by expand_pattern():
#      "burst":     count transients every interval_ms, I linear I_from -> I_to
#      "tick_loop": ticks every interval_ms for loop_ms (looped by an advanced player while the state lasts)
#    "mod" = modulation of the *continuous* players (tension_resistance / pick_drag); it is NOT inside the
#    event AHAP (Core Haptics curves only affect their own player, TECH §2.1) and goes to <event>.mod.json.
# --------------------------------------------------------------------------------------------------
IOS_PATTERNS: dict[str, dict] = {
    # FEEL §2 contact: T I 0.30 S 0.70, 12 ms
    "contact": {"src": "FEEL §2 contact", "elements": [["T", 0, 0.30, 0.70]], "nominal_ms": 12},
    # FEEL §2 bind: T I 0.45 S 0.35 + resistance +0.2 in 80 ms
    "bind": {"src": "FEEL §2 bind", "elements": [["T", 0, 0.45, 0.35]], "nominal_ms": 18,
             "mod": {"channel": "tension_resistance", "intensity_add": [[0, 0.0], [80, 0.2]],
                     "hold": "while_bound"}},
    # FEEL §2 near_shear: one T I 0.12 S 0.80 on entering the window; resistance S +0.15 for 150 ms, back in 300
    "near_shear": {"src": "FEEL §2 near_shear (+ §9 events.near_shear.ios.entry_tick_*)",
                   "elements": [["T", 0, 0.12, 0.80]], "once_per_window": True,
                   "mod": {"channel": "tension_resistance", "sharpness_add": [[0, 0.15], [150, 0.15], [450, 0.0]]}},
    # FEEL §2 set: T I 0.90 S 0.85 + resistance dip x0.5 / 110 ms (+60 ms return, TECH §3.5 ducking ramp)
    "set": {"src": "FEEL §2 set", "elements": [["T", 0, 0.90, 0.85]], "nominal_ms": 20,
            "mod": {"channel": "tension_resistance", "intensity_scale": [[0, 0.5], [110, 0.5], [170, 1.0]]}},
    # FEEL §2 false_set + §1.1 rhythm + F-01: T + T2 at +28 ms (levers: +40 ms, families.*.false_set_second_delay_ms)
    "false_set": {"src": "FEEL §2 false_set, §1.1, F-01, §3.5",
                  "elements": [["T", 0, 0.85, 0.75], ["T", "SECOND", 0.25, 0.30]], "nominal_ms": 20,
                  "mod": {"channel": "tension_resistance", "intensity_scale": [[0, 0.35], [260, 0.35], [320, 1.0]]}},
    # FEEL §2 counter_rotate + F-02: C I 0.20->0.40 in 600 ms (x I_event), S 0.15 + T every 110 ms I 0.30 S 0.20.
    # Two files: <ramp> (one-shot, 660 ms) then <loop> (held at 0.40, looped while pressure lasts).
    "counter_rotate": {"src": "FEEL §2 counter_rotate, F-02",
                       "kind": "ramp_then_loop", "interval_ms": 110, "tick": [0.30, 0.20],
                       "cont": [0.40, 0.15], "ramp": [[0, 0.5], [600, 1.0]], "ramp_ms": 660, "loop_ms": 660},
    # FEEL §2 overset: T I 0.60 S 0.10 + dead resistance S 0.05 until release
    "overset": {"src": "FEEL §2 overset", "elements": [["T", 0, 0.60, 0.10]], "nominal_ms": 25,
                "mod": {"channel": "tension_resistance", "sharpness_set": 0.05, "until": "release"}},
    # FEEL §2 drop + §1.1: 2-6 T every 40 ms (count ~ I_event*n, §9 count_from_event), I 0.7->0.4, S 0.6;
    # resistance -> 0 in 200 ms
    "drop": {"src": "FEEL §2 drop, §1.1, §9 events.drop.ios.count_from_event",
             "kind": "burst", "interval_ms": 40, "count": [2, 6], "I_from": 0.7, "I_to": 0.4, "S": 0.6,
             "mod": {"channel": "tension_resistance", "intensity_scale": [[0, 1.0], [200, 0.0]]}},
    # FEEL §2 stress + F-06 + §5.2.3: resistance I +0.10..+0.35, S 0.85; T every 70 ms I 0.2 S 0.9;
    # >= 0.9 S/Smax every 45 ms (iOS); after 4 s continuous: every 140 ms
    "stress": {"src": "FEEL §2 stress, F-06, §5.2 rule 3",
               "kind": "tick_loop", "tick": [0.20, 0.90],
               "variants": {"": 70, "high": 45, "capped": 140}, "loop_ticks": {"": 15, "high": 21, "capped": 8},
               "mod": {"channel": "tension_resistance", "intensity_add_by_ratio": [0.10, 0.35],
                       "sharpness_set": 0.85, "sustain_cap_ms": 4000, "high_threshold": 0.9}},
    # FEEL §2 break: T I 1.0 S 1.0, 40 ms + continuous -> 0 + 150 ms haptic silence; §5.2.4 ramp 300 ms back
    "break": {"src": "FEEL §2 break, §5.2 rule 4", "elements": [["T", 0, 1.0, 1.0]], "nominal_ms": 40,
              "mod": {"channel": "all_continuous", "intensity_scale": [[0, 0.0], [150, 0.0], [450, 1.0]],
                      "haptic_silence_ms": 150}},
    # FEEL §2 wear: no haptics during the lock (L4 audio after the lock)
    "wear": {"src": "FEEL §2 wear", "none": True},
    # FEEL §2 gate_align + F-03: T I 0.50 S 0.40 + dip x0.7 / 60 ms
    "gate_align": {"src": "FEEL §2 gate_align, F-03", "elements": [["T", 0, 0.50, 0.40]], "nominal_ms": 15,
                   "mod": {"channel": "tension_resistance", "intensity_scale": [[0, 0.7], [60, 0.7], [120, 1.0]]}},
    # FEEL §2 detector_trip + §1.1: C 80 ms I 0.7 S 0.3, gap 60, C 80 ms (= two heavy, 140 ms apart)
    "detector_trip": {"src": "FEEL §2 detector_trip, §1.1",
                      "elements": [["C", 0, 80, 0.70, 0.30], ["C", 140, 80, 0.70, 0.30]],
                      "mod": {"channel": "tension_resistance", "sharpness_set": 0.05, "until": "reset"}},
    # FEEL §2 open + §1.1: C 300 ms I 0 -> 0.3 S 0.4 + T I 1.0 S 0.6 (strong click at the end of the rise)
    "open": {"src": "FEEL §2 open, §1.1",
             "elements": [["C", 0, 300, 0.30, 0.40], ["CURVE", "HapticIntensityControl", [[0, 0.0], [300, 1.0]]],
                          ["T", 300, 1.0, 0.60]]},
}

SUB_PATTERNS: dict[str, dict] = {
    # FEEL §3.1 + F-04: own tick, not a false_set: T I 0.18 S 0.90, 8 ms, no dip, no ducking
    "pin.serration": {"src": "FEEL §3.1, F-04", "elements": [["T", 0, 0.18, 0.90]], "nominal_ms": 8},
    # FEEL §3.1: T I 0.12 S 0.55, 10 ms
    "pin.spring_bounce": {"src": "FEEL §3.1", "elements": [["T", 0, 0.12, 0.55]], "nominal_ms": 10},
    # FEEL §3.2: T I 0.10 S 0.80, 8 ms, haptic <= 6/s
    "wafer.rattle": {"src": "FEEL §3.2", "elements": [["T", 0, 0.10, 0.80]], "nominal_ms": 8, "limit_per_s": 6},
    # FEEL §3.3: resistance I +0.05..+0.20, S 0.25 + T every 140 ms I 0.15 S 0.20 (slow low creak)
    "wood.creak": {"src": "FEEL §3.3", "kind": "tick_loop", "tick": [0.15, 0.20],
                   "variants": {"": 140}, "loop_ticks": {"": 8},
                   "mod": {"channel": "tension_resistance", "intensity_add_by_ratio": [0.05, 0.20],
                           "sharpness_set": 0.25}},
    # FEEL §3.4: pick_drag S +0.10 + T every 60 ms I 0.15 S 0.60, haptic <= 10/s. One tick per AHAP; the
    # runtime fires it while scraping with min interval 60 ms and the 10/s cap (=> effectively 100 ms).
    "ward.scrape": {"src": "FEEL §3.4", "elements": [["T", 0, 0.15, 0.60]], "min_interval_ms": 60,
                    "limit_per_s": 10, "mod": {"channel": "pick_drag", "sharpness_add": 0.10, "while": "scraping"}},
    # FEEL §3.5 + F-05: second impulse of the lever false_set pair (40 ms) - no pattern of its own
    "lever.false_gate": {"src": "FEEL §3.5, F-05", "folded_into": "false_set.second"},
    # FEEL §3.6: relief, not a drop: C 350 ms I 0.30 -> 0 S 0.20 + 3 soft T at 120/200/260 ms I 0.25 S 0.30
    "detector.reset": {"src": "FEEL §3.6",
                       "elements": [["C", 0, 350, 0.30, 0.20],
                                    ["CURVE", "HapticIntensityControl", [[0, 1.0], [350, 0.0]]],
                                    ["T", 120, 0.25, 0.30], ["T", 200, 0.25, 0.30], ["T", 260, 0.25, 0.30]],
                       "mod": {"channel": "tension_resistance", "restore": "normal",
                               "note": "ends the dead resistance (S 0.05) set by detector_trip"}},
    # FEEL §3.6 reset hold (game side, needs ViewModel.reset_progress, F-07): TICK 0.15 every 250 ms,
    # iOS T I 0.15 S 0.5. Not a lockcore event; the game fires it every 250 ms of a valid hold.
    "detector.reset_hold": {"src": "FEEL §3.6 (Reset), F-07", "elements": [["T", 0, 0.15, 0.50]],
                            "game_side": True, "interval_ms": 250},
    # FEEL §3.7: T I 0.22 S 0.65, 10 ms; iOS 12/s, A2-A4 8/s, A1 4/s, A0 0
    "ring.detent": {"src": "FEEL §3.7", "elements": [["T", 0, 0.22, 0.65]], "nominal_ms": 10,
                    "limit_per_s": {"ios": 12, "a2_a4": 8, "a1": 4, "a0": 0}},
}

# Sub-event metadata not present in the bank (game-side pattern)
EXTRA_SUB_BANK = {
    "detector.reset_hold": {
        "base": None, "priority": 11, "essential": False, "audio_layer": "L2", "ducks_resistance": False,
        "game_side": True,
        "android_chain": [{"tier": "a2", "composition": [["TICK", 0.15, 0]], "repeat_interval_ms": 250},
                          {"tier": "a1", "effect": "EFFECT_TICK"}, {"tier": "a0", "skip": True}],
        "sfx": {"id": "ratchet", "variants": 6, "gain_db": -6},
    }
}

# Continuous signals (FEEL §2 "Sygnały ciągłe"; bank.continuous). Templates for a looping advanced player:
# the event has I = 1.0 and a mid sharpness; the runtime drives HapticIntensityControl (x, 0..1) and
# HapticSharpnessControl (+, -1..1) with sendParameters <= 60 Hz.
CONTINUOUS_PATTERNS = {
    "tension_resistance": {"src": "FEEL §2 continuous, TECH §3.3", "base_sharpness": 0.275, "loop_s": 30.0,
                           "intensity_map": "I = 0.10 + 0.45 * r^1.5 (r = resistance 0..1)",
                           "sharpness_range": [0.20, 0.35],
                           "ducking": {"factor": 0.3, "hold_ms": 35, "release_ms": 60},
                           "idle": {"after_ms": 1500, "fade_ms": 300}},
    "pick_drag": {"src": "FEEL §2 continuous, TECH §3.3", "base_sharpness": 0.65, "loop_s": 30.0,
                  "intensity_map": "I = 0.05 + 0.20 * v (v = normalised pick speed 0..1)",
                  "sharpness_range": [0.55, 0.75],
                  "micro_transient": {"I": 0.15, "S": 0.7, "limit_per_s": 20},
                  "idle": {"after_ms": 1500, "fade_ms": 300}},
}

# Sound for the preview / runtime layering (FEEL §2 Dźwięk, §3 cards, §9 sfx).
# Layers: [sfx_id, delay_ms, gain_db]. Material "lock" = event material, else a fixed one.
SOUND_LAYERS = {
    "lever:set": [["set", 0, 0.0], ["gate_align", 0, -6.0]],          # FEEL §3.5
    "lever_detector:set": [["set", 0, 0.0], ["gate_align", 0, -6.0]],  # FEEL §3.6 (= lever)
    "ring_combo:set": [["set", 0, 0.0], ["gate_align", 0, -6.0]],      # FEEL §3.7
    "lever:false_set": [["false_set", 0, 0.0], ["lever_fall", 40, 0.0]],          # FEEL §3.5
    "lever_detector:false_set": [["false_set", 0, 0.0], ["lever_fall", 40, 0.0]],
    "detector.reset": [["lever_fall", 0, 0.0], ["lever_fall", 120, 0.0], ["lever_fall", 200, 0.0]],  # §3.6
    "counter_rotate": [["counter_rotate", 0, 0.0], ["counter_rotate", 110, 0.0], ["counter_rotate", 220, 0.0],
                       ["counter_rotate", 330, 0.0], ["counter_rotate", 440, 0.0], ["counter_rotate", 550, 0.0]],
}


def sfx_for(bank: dict, family: str, event: str) -> dict | None:
    """sfx id + parameters from the merged bank (events.*.sfx / sub_events.*.sfx)."""
    if event in bank.get("sub_events", {}):
        return bank["sub_events"][event].get("sfx")
    if event in EXTRA_SUB_BANK:
        return EXTRA_SUB_BANK[event]["sfx"]
    if event in bank["events"]:
        return bank["events"][event].get("sfx", {"id": event})
    if event in CONTINUOUS:
        return {"id": event}
    return None


def event_meta(bank: dict, event: str) -> dict:
    if event in bank["events"]:
        e = bank["events"][event]
    elif event in bank.get("sub_events", {}):
        e = bank["sub_events"][event]
    elif event in EXTRA_SUB_BANK:
        e = EXTRA_SUB_BANK[event]
    else:
        e = bank["continuous"][event]
    return {"priority": e.get("priority"), "essential": bool(e.get("essential", False)),
            "base": e.get("base"), "audio_layer": e.get("audio_layer")}


def ios_def(event: str) -> dict:
    return SUB_PATTERNS[event] if event in SUB_PATTERNS else IOS_PATTERNS[event]


def android_chain(bank: dict, event: str) -> list:
    if event in bank.get("sub_events", {}):
        return copy.deepcopy(bank["sub_events"][event].get("android_chain", []))
    if event in EXTRA_SUB_BANK:
        return copy.deepcopy(EXTRA_SUB_BANK[event]["android_chain"])
    return copy.deepcopy(bank["events"].get(event, {}).get("android_chain", []))


def feel_version(bank: dict) -> int:
    return int(bank.get("feel_version", 0))
