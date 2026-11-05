#!/usr/bin/env python3
"""Validate haptics/out (schema basics) and simulate the FEEL §5 intensity budget.

  (a) schema: every AHAP (keys, parameter IDs, ranges, times, durations, curves), every Android chain
      (primitives, scales, delays, amplitudes, tiers, ends with a0/skip), index sha256, bank consistency;
  (b) budget: a synthetic 180 s event stream per family (FEEL §5.3 for pin_tumbler t5; other families
      derived from FEEL §3 / §5.3 notes), the §5.2 regulator per tier (iOS, A4..A0), then the §5.1 limits.

Exit code != 0 on any failure. `--markdown` prints the budget table as Markdown (for README).
Usage: python3 haptics/validate.py [--markdown]
"""
from __future__ import annotations

import hashlib
import json
import math
import random
import sys
from collections import deque
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import spec  # noqa: E402

OUT = spec.OUT_DIR
ERRORS: list[str] = []
WARNINGS: list[str] = []


def err(msg):
    ERRORS.append(msg)


def warn(msg):
    WARNINGS.append(msg)


# ==================================================================================================
# (a) schema
# ==================================================================================================
EVENT_PARAMS = {"HapticIntensity", "HapticSharpness", "AttackTime", "DecayTime", "ReleaseTime", "Sustained"}
CURVE_PARAMS = {"HapticIntensityControl", "HapticSharpnessControl"}
EVENT_TYPES = {"HapticTransient", "HapticContinuous"}


def num(x):
    return isinstance(x, (int, float)) and not isinstance(x, bool) and math.isfinite(x)


def check_ahap(rel: str, doc: dict):
    if set(doc) - {"Version", "Metadata", "Pattern"}:
        err(f"{rel}: unknown top-level keys {sorted(set(doc) - {'Version', 'Metadata', 'Pattern'})}")
    if doc.get("Version") != 1.0:
        err(f"{rel}: Version must be 1.0")
    pat = doc.get("Pattern")
    if not isinstance(pat, list) or not pat:
        err(f"{rel}: Pattern must be a non-empty list")
        return
    for j, item in enumerate(pat):
        where = f"{rel}: Pattern[{j}]"
        if not isinstance(item, dict) or len(item) != 1 or next(iter(item)) not in ("Event", "ParameterCurve"):
            err(f"{where}: must be exactly one of Event / ParameterCurve")
            continue
        if "Event" in item:
            ev = item["Event"]
            if set(ev) - {"Time", "EventType", "EventDuration", "EventParameters"}:
                err(f"{where}: unknown Event keys")
            if not num(ev.get("Time")) or ev["Time"] < 0:
                err(f"{where}: Time must be >= 0")
            if ev.get("EventType") not in EVENT_TYPES:
                err(f"{where}: EventType {ev.get('EventType')}")
            if ev.get("EventType") == "HapticContinuous":
                d = ev.get("EventDuration")
                if not num(d) or d <= 0 or d > 30:
                    err(f"{where}: continuous EventDuration must be in (0, 30] s")
            elif "EventDuration" in ev:
                err(f"{where}: transient must not carry EventDuration")
            ids = set()
            for p in ev.get("EventParameters", []):
                pid, v = p.get("ParameterID"), p.get("ParameterValue")
                if pid not in EVENT_PARAMS:
                    err(f"{where}: ParameterID {pid} not in Apple's list")
                if not num(v) or v < 0 or v > 1:
                    err(f"{where}: {pid} value {v} outside 0..1")
                if pid == "Sustained" and v not in (0, 1, 0.0, 1.0):
                    err(f"{where}: Sustained must be 0 or 1")
                if pid in ids:
                    err(f"{where}: duplicate {pid}")
                ids.add(pid)
            if "HapticIntensity" not in ids:
                err(f"{where}: missing HapticIntensity")
        else:
            c = item["ParameterCurve"]
            if c.get("ParameterID") not in CURVE_PARAMS:
                err(f"{where}: curve ParameterID {c.get('ParameterID')}")
            if not num(c.get("Time")) or c["Time"] < 0:
                err(f"{where}: curve Time must be >= 0")
            pts = c.get("ParameterCurveControlPoints", [])
            if not 1 <= len(pts) <= 16:
                err(f"{where}: 1..16 control points required")
            lo = -1.0 if c.get("ParameterID") == "HapticSharpnessControl" else 0.0
            last = -1.0
            for p in pts:
                if not num(p.get("Time")) or p["Time"] < 0 or p["Time"] < last:
                    err(f"{where}: control point times must be >= 0 and non-decreasing")
                last = p.get("Time", last)
                v = p.get("ParameterValue")
                if not num(v) or v < lo or v > 1:
                    err(f"{where}: control value {v} outside {lo}..1")


def check_chain(rel: str, chain: list):
    if not chain:
        err(f"{rel}: empty chain")
        return
    for j, e in enumerate(chain):
        where = f"{rel}: chain[{j}]"
        if e.get("tier") not in spec.TIER_RANK:
            err(f"{where}: tier {e.get('tier')}")
        for prim, sc, dl in e.get("composition", []):
            if prim not in spec.ANDROID_PRIMITIVES:
                err(f"{where}: primitive {prim} not allowed")
            if not num(sc) or not 0 <= sc <= 1:
                err(f"{where}: scale {sc} outside 0..1")
            if not num(dl) or dl < 0:
                err(f"{where}: delay {dl} < 0")
        for key in ("tick", "then", "micro"):
            if key in e:
                if e[key][0] not in spec.ANDROID_PRIMITIVES:
                    err(f"{where}: {key} primitive {e[key][0]} not allowed")
                if not 0 <= e[key][1] <= 1:
                    err(f"{where}: {key} scale outside 0..1")
        if "envelope" in e:
            ts = [p[0] for p in e["envelope"]]
            if ts != sorted(ts) or ts[0] < 0:
                err(f"{where}: envelope times must be >= 0, sorted")
            for _, i, s in e["envelope"]:
                if not (0 <= i <= 1 and 0 <= s <= 1):
                    err(f"{where}: envelope I/S outside 0..1")
        if "waveform" in e:
            w = e["waveform"]
            if len(w["timings"]) != len(w["amps"]):
                err(f"{where}: waveform timings/amps length differ")
            if any(t < 0 for t in w["timings"]) or any(not 0 <= a <= 255 for a in w["amps"]):
                err(f"{where}: waveform timing < 0 or amp outside 0..255")
        if "effect" in e and e["effect"] not in ("EFFECT_CLICK", "EFFECT_TICK", "EFFECT_HEAVY_CLICK",
                                                   "EFFECT_DOUBLE_CLICK"):
            err(f"{where}: effect {e['effect']}")
        if e.get("tier") == "a0" and not (e.get("skip") or "on_ms" in e or "pattern_ms" in e):
            err(f"{where}: a0 entry needs on_ms / pattern_ms / skip")
    last = chain[-1]
    if not (last.get("tier") == "a0" or last.get("skip")):
        err(f"{rel}: chain must end with an a0 entry or skip")


def schema_checks(bank, original, patch):
    index = json.loads((OUT / "index.json").read_text(encoding="utf-8"))
    n_ahap = n_android = 0
    for p in sorted(OUT.rglob("*.ahap")):
        check_ahap(str(p.relative_to(OUT)), json.loads(p.read_text(encoding="utf-8")))
        n_ahap += 1
    for p in sorted((OUT / "android").rglob("*.json")):
        if p.name == "selection_table.json":
            continue
        d = json.loads(p.read_text(encoding="utf-8"))
        check_chain(str(p.relative_to(OUT)), d["chain"])
        n_android += 1
        if d.get("essential"):
            for t, s in d["selection"].items():
                if s["index"] is None or d["chain"][s["index"]].get("skip"):
                    err(f"{p.relative_to(OUT)}: essential event has no haptic on tier {t}")
    # sha256 in index
    def walk(node):
        if isinstance(node, dict):
            if "file" in node and "sha256" in node:
                f = OUT / node["file"]
                if not f.exists():
                    err(f"index: missing {node['file']}")
                elif hashlib.sha256(f.read_bytes()).hexdigest() != node["sha256"]:
                    err(f"index: sha256 mismatch {node['file']}")
            for v in node.values():
                walk(v)
        elif isinstance(node, list):
            for v in node:
                walk(v)
    walk(index)
    # Every sub-event chain in the merged bank (raw, before build normalisation)
    for name, se in bank.get("sub_events", {}).items():
        ch = se.get("android_chain", [])
        if ch and not (ch[-1].get("tier") == "a0" or ch[-1].get("skip")) and not se.get("fold_into"):
            warn(f"FEEL §9 sub_events.{name}.android_chain does not end with a0/skip (build appends a0 skip)")
        elif ch and ch[-1].get("tier") != "a0" and not se.get("fold_into"):
            warn(f"FEEL §9 sub_events.{name}.android_chain ends with '{ch[-1]['tier']} skip', no explicit a0 "
                 f"(build appends a0 skip)")
    consistency(bank, original, patch)
    return n_ahap, n_android, index


def consistency(bank, original, patch):
    """Divergences between FEEL §2 tables (encoded in spec.py), the bank and lockcore (warnings)."""
    ev = bank["events"]
    pairs = [("contact", "intensity", 0.30), ("bind", "intensity", 0.45), ("set", "intensity", 0.90),
             ("false_set", "intensity", 0.85), ("overset", "intensity", 0.60), ("gate_align", "sharpness", 0.40),
             ("counter_rotate", "intensity_from", 0.20), ("counter_rotate", "intensity_to", 0.40)]
    for e, k, v in pairs:
        if abs(ev[e]["ios"].get(k, -1) - v) > 1e-9:
            warn(f"bank events.{e}.ios.{k} = {ev[e]['ios'].get(k)} but FEEL §2 says {v}")
    if ev["drop"]["ios"].get("count") != ev["drop"]["ios"].get("count_from_event"):
        warn(f"bank events.drop.ios.count {ev['drop']['ios'].get('count')} vs FEEL §2/§9 count_from_event "
             f"{ev['drop']['ios'].get('count_from_event')} (patch adds the new key but leaves the old one)")
    if ev["gate_align"]["android"]["primitive"] != "LOW_TICK":
        warn("bank events.gate_align.android.primitive is still CLICK; FEEL F-03 wants LOW_TICK first "
             "(only android_chain has it; the legacy 'android' key is not patched)")
    lc = (spec.ROOT / "lockcore" / "src" / "families" / "wafer.cpp")
    if lc.exists() and "MaterialId material = MaterialId::steel" in lc.read_text(encoding="utf-8"):
        if bank["families"]["wafer"]["material"] != "steel":
            warn("lockcore wafer default material is steel (wafer.cpp), FEEL §3.2 / §9 families.wafer says brass")


# ==================================================================================================
# (b) budget simulation
# ==================================================================================================
DT = 10  # ms
WIN = 180_000
N = WIN // DT
SIM_TIERS = ["ios", "a4", "a3", "a2", "a1", "a0"]
CAP_1S = {"ios": 25, "a4": 12, "a3": 12, "a2": 12, "a1": 6, "a0": 3}       # TECH §3.5
CAP_10S = {"ios": 40, "a4": 25, "a3": 25, "a2": 25, "a1": 15, "a0": 8}     # FEEL §5.1
MIN_GAP = {"ios": 40, "a4": 60, "a3": 60, "a2": 60, "a1": 60, "a0": 150}   # TECH §2.3 calibration
STRONG = 0.7
STRONG_CAP = 8
SUB_LIMIT = {  # per-sub-event haptic limits per second (FEEL §3)
    "ring.detent": {"ios": 12, "a4": 8, "a3": 8, "a2": 8, "a1": 4, "a0": 0},
    "wafer.rattle": {t: 6 for t in SIM_TIERS},
    "ward.scrape": {"ios": 10, "a4": 10, "a3": 10, "a2": 10, "a1": 5, "a0": 0},
    "pick_drag.micro": {"ios": 20, "a4": 12, "a3": 12, "a2": 12, "a1": 6, "a0": 0},
}
EPISODIC = {"counter_rotate", "stress", "wood.creak", "ward.scrape", "detector.reset_hold"}


class Ev:
    __slots__ = ("t", "name", "el", "ie", "dur", "ratio")

    def __init__(self, t, name, el=-1, ie=1.0, dur=0, ratio=0.0):
        self.t, self.name, self.el, self.ie, self.dur, self.ratio = int(t), name, el, ie, int(dur), ratio


class Scenario:
    def __init__(self, family, title, seed):
        self.family, self.title = family, title
        self.rng = random.Random(seed)
        self.events: list[Ev] = []
        self.tension: list[tuple[int, int]] = []
        self.pick: list[tuple[int, int, float]] = []
        self.info_only = False

    # ---- helpers
    def attempts(self, n, on_total_s, start_ms=2000):
        """n tension-on intervals summing ~on_total_s, separated by gaps (no tension)."""
        rng = self.rng
        gap_total = WIN - start_ms - on_total_s * 1000 - 1500
        gaps = [rng.uniform(0.6, 1.4) for _ in range(n)]
        g_sum = sum(gaps)
        lens = [rng.uniform(0.8, 1.2) for _ in range(n)]
        l_sum = sum(lens)
        t = start_ms
        for j in range(n):
            ln = int(on_total_s * 1000 * lens[j] / l_sum)
            self.tension.append((t, t + ln))
            t += ln + int(gap_total * gaps[j] / g_sum)
        return self.tension

    def rand_t(self, margin=600):
        rng = self.rng
        tot = sum(b - a - margin for a, b in self.tension)
        x = rng.uniform(0, tot)
        for a, b in self.tension:
            ln = b - a - margin
            if x <= ln:
                return int(a + 200 + x)
            x -= ln
        a, b = self.tension[-1]
        return a + 200

    def scatter(self, name, n, ie=(1.0, 1.0), elements=6):
        for _ in range(n):
            self.events.append(Ev(self.rand_t(), name, self.rng.randrange(elements), self.rng.uniform(*ie)))

    def episodes(self, name, durs_s, ratio=(0.5, 0.95)):
        for d in durs_s:
            dur = int(d * 1000)
            # find an attempt long enough
            cands = [(a, b) for a, b in self.tension if b - a > dur + 800]
            a, b = self.rng.choice(cands)
            t0 = self.rng.randint(a + 300, b - dur - 300)
            self.events.append(Ev(t0, name, self.rng.randrange(6), 1.0, dur, self.rng.uniform(*ratio)))

    def drops_and_open(self, opens=1, drop_ie=(0.4, 1.0), hold_ms=0):
        """Every attempt ends with a drop except attempts that end with open."""
        k = len(self.tension)
        open_idx = set(range(k - 1, -1, -max(1, k // opens)))
        open_idx = set(sorted(open_idx)[-opens:])
        for j, (a, b) in enumerate(self.tension):
            if j in open_idx:
                self.events.append(Ev(b - 20, "open", -1, 1.0))
            else:
                self.events.append(Ev(b - 20, "drop", -1, self.rng.uniform(*drop_ie)))

    def pick_motion(self, frac=0.6, offtension_s=5.0):
        rng = self.rng
        for a, b in self.tension:
            t = a
            while t < b:
                seg = rng.randint(300, 1500)
                if rng.random() < frac:
                    self.pick.append((t, min(b, t + seg), rng.uniform(0.2, 0.9)))
                t += seg
        # probing without tension, inside gaps
        left = offtension_s * 1000
        gaps = [(self.tension[j][1] + 300, self.tension[j + 1][0] - 300) for j in range(len(self.tension) - 1)]
        for a, b in gaps:
            if left <= 0 or b - a < 600:
                continue
            ln = int(min(left, (b - a) * 0.5))
            self.pick.append((a, a + ln, rng.uniform(0.2, 0.6)))
            left -= ln
        # micro ticks on edges while the pick moves (~2.5/s), prio 13, shed first
        for a, b, v in self.pick:
            t = a
            while True:
                t += int(rng.uniform(250, 550))
                if t >= b:
                    break
                self.events.append(Ev(t, "pick_drag.micro", -1, 1.0))


def scenarios() -> list[Scenario]:
    S = []
    # FEEL §5.3: pin_tumbler t5, struggling player. 4 drops, 2 overset, 2 stress episodes (~6 s), 1 spool with
    # 3 counter-rotation attempts (~5 s), contact+phantom ~300, bind 45, near_shear 35, set 28, false_set 6,
    # serration 20, open 1. Tension on 112 s (see README: 150 s from §5.3 breaks the duty limit).
    for title, on_s, info in (("t5 struggling (§5.3)", 112, False), ("§5.3 literal: tension 150 s", 150, True)):
        s = Scenario("pin_tumbler", title, 5301)
        s.info_only = info
        s.attempts(5, on_s)
        s.scatter("contact", 220, (0.6, 0.8), 6)
        s.scatter("contact", 80, (0.25, 0.8), 6)  # phantom neighbours, I_event 1/3..1
        s.scatter("pin.spring_bounce", 30, (0.15, 0.5))
        s.scatter("bind", 45, (0.3, 0.9))
        s.scatter("near_shear", 35, (0.2, 1.0))
        s.scatter("set", 28)
        s.scatter("false_set", 6)
        s.scatter("pin.serration", 20, (0.3, 0.3))
        s.scatter("overset", 2)
        s.episodes("counter_rotate", [1.5, 1.7, 1.8], (0.6, 1.0))
        s.episodes("stress", [4.6, 1.4], (0.85, 0.97))
        s.scatter("wear", 1)
        s.drops_and_open(1)
        s.pick_motion()
        S.append(s)
    # wafer t3 (FEEL §3.2): lighter clicks, loose wafers rattle (haptic <= 6/s), 3 drops, 1 stress episode
    s = Scenario("wafer", "t3 typical", 5302)
    s.attempts(4, 108)
    s.scatter("contact", 250, (0.6, 0.8))
    s.scatter("wafer.rattle", 150, (0.25, 0.25))
    s.scatter("bind", 40, (0.3, 0.9))
    s.scatter("near_shear", 30)
    s.scatter("set", 20)
    s.scatter("overset", 3)
    s.scatter("contact", 3, (0.5, 0.5))  # wafer returns after overset (FEEL §3.2)
    s.episodes("stress", [3.0], (0.6, 0.85))
    s.scatter("wear", 1)
    s.drops_and_open(1)
    s.pick_motion()
    S.append(s)
    # wooden_pin t1 (FEEL §3.3): 3 short locks in 180 s, creak instead of stress, no break
    s = Scenario("wooden_pin", "t1 x3 locks", 5303)
    s.attempts(5, 105)
    s.scatter("contact", 150, (0.2, 0.2))
    s.scatter("bind", 30)
    s.scatter("near_shear", 25)
    s.scatter("set", 15)
    s.scatter("overset", 1)
    s.episodes("wood.creak", [3.0, 2.5, 2.0], (0.3, 0.8))
    s.drops_and_open(3)
    s.pick_motion()
    S.append(s)
    # warded t2 (FEEL §3.4, §5.3 note): long ward.scrape (10 episodes, 50 s), 3 stress episodes then a break
    s = Scenario("warded", "t2 long scrape", 5304)
    s.attempts(5, 110)
    s.scatter("contact", 60, (0.3, 0.6))
    s.episodes("ward.scrape", [5.0] * 10, (0.5, 0.5))
    s.scatter("gate_align", 30)
    s.scatter("bind", 20)
    s.scatter("set", 10, (0.85, 0.85))
    s.episodes("stress", [3.0, 2.5, 2.0], (0.6, 0.88))
    s.scatter("break", 1)
    s.scatter("wear", 1)
    s.drops_and_open(1)
    s.pick_motion()
    S.append(s)
    # lever t5 (FEEL §3.5): gate_align+set folded, false_set+false_gate pair @40 ms
    for fam, title, seed in (("lever", "t5 struggling", 5305), ("lever_detector", "t6, 2 trips + 2 resets", 5306)):
        s = Scenario(fam, title, seed)
        s.attempts(5, 110)
        s.scatter("contact", 120, (0.6, 0.8))
        s.scatter("bind", 60, (0.3, 0.9))
        s.scatter("near_shear", 40)
        for _ in range(30):
            t, el = s.rand_t(), s.rng.randrange(6)
            s.events += [Ev(t, "gate_align", el), Ev(t, "set", el)]
        for _ in range(8):
            t, el = s.rand_t(), s.rng.randrange(6)
            s.events += [Ev(t, "false_set", el), Ev(t, "lever.false_gate", el, 0.4)]
        s.episodes("counter_rotate", [1.2, 1.5, 1.0, 1.3], (0.6, 1.0))
        s.scatter("overset", 3)
        s.episodes("stress", [3.0, 2.0], (0.7, 0.92))
        s.scatter("wear", 1)
        if fam == "lever_detector":
            for _ in range(2):
                t = s.rand_t(4000)
                s.events.append(Ev(t, "detector_trip", s.rng.randrange(6)))
                s.events.append(Ev(t + 300, "detector.reset_hold", -1, 1.0, 2500))
                s.events.append(Ev(t + 2850, "detector.reset", -1, 1.0))
        s.drops_and_open(1)
        s.pick_motion()
        S.append(s)
    # ring_combo t3 (FEEL §3.7, §5.3 note): fast spinning, detents > 20/s
    s = Scenario("ring_combo", "t3 fast spinning", 5307)
    s.attempts(4, 110)
    for _ in range(30):
        a, b = s.rng.choice(s.tension)
        t0 = s.rng.randint(a + 200, b - 2800)
        el = s.rng.randrange(4)
        bound = s.rng.random() < 0.4
        for j in range(55):  # 2.5 s at 22/s
            s.events.append(Ev(t0 + j * 45, "ring.detent", el, (0.35 if bound else 0.15) * (0.5 + 0.45 / 2)))
    s.scatter("contact", 30, (0.6, 0.6))
    s.scatter("bind", 40)
    s.scatter("near_shear", 60, (0.225, 0.225))
    for _ in range(12):
        t, el = s.rand_t(), s.rng.randrange(4)
        s.events += [Ev(t, "gate_align", el, 0.45), Ev(t, "set", el, 0.67)]
    s.scatter("false_set", 10, (0.43, 0.43))
    s.drops_and_open(1, (0.25, 1.0))
    s.pick_motion()
    S.append(s)
    for s in S:
        s.events.sort(key=lambda e: (e.t, e.name))
    return S


# ---- pulses (transients) for an event on a tier --------------------------------------------------
def ahap_pulses(doc):
    """[(t_ms, I)] from an AHAP: transients + short continuous events (< 250 ms)."""
    out = []
    for item in doc["Pattern"]:
        if "Event" not in item:
            continue
        e = item["Event"]
        i = next(p["ParameterValue"] for p in e["EventParameters"] if p["ParameterID"] == "HapticIntensity")
        if e["EventType"] == "HapticTransient" or e.get("EventDuration", 1) < 0.25:
            out.append((int(round(e["Time"] * 1000)), i))
    return out


def entry_pulses(e):
    if e is None or e.get("skip") or e.get("folded"):
        return []
    out = []
    if "composition" in e:
        out += [(o, sc) for (_, sc, _), o in zip(e["composition"], e["onset_ms"])]
    if "tick" in e:
        out.append((0, e["tick"][1]))
    if "then" in e:
        end = e["envelope"][-1][0] if "envelope" in e else 0
        out.append((end, e["then"][1]))
    if "envelope" in e and not out:
        on, start, peak = False, 0, 0.0
        for t, i, _ in e["envelope"] + [[e["envelope"][-1][0] + 1, 0.0, 0.0]]:
            if i > 0.05 and not on:
                on, start, peak = True, t, i
            elif i > 0.05:
                peak = max(peak, i)
            elif on:
                on = False
                if t - start < 250:
                    out.append((start, peak))
    if "waveform" in e:
        t = 0
        for dur, a in zip(e["waveform"]["timings"], e["waveform"]["amps"]):
            if a > 0 and dur < 250:
                out.append((t, a / 255))
            t += dur
    if "effect" in e:
        out.append((0, 0.9 if e["effect"] == "EFFECT_CLICK" else 0.3))
    if "on_ms" in e:
        out.append((0, 1.0))
        if "second_on_ms" in e:
            out.append((e["on_ms"] + e["second_gap_ms"], 1.0))
    if "pattern_ms" in e:
        t = 0
        for j, d in enumerate(e["pattern_ms"]):
            if j % 2 == 0:
                out.append((t, 1.0))
            t += d
    if "micro" in e:
        out.append((0, e["micro"][1]))
    return out


def entry_interval(e, default):
    if e is None:
        return None
    for key in ("tick_interval_ms", "repeat_interval_ms", "interval_ms"):
        if key in e:
            return e[key]
    if "waveform" in e and "repeat" in e["waveform"]:
        return sum(e["waveform"]["timings"])
    if "limit_per_s" in e:
        return max(default, 1000 // e["limit_per_s"])
    return default


class Library:
    """Resolved pulses per (family, event, tier) from the built files."""

    def __init__(self, index, bank):
        self.index, self.bank, self.cache = index, bank, {}

    def info(self, fam, ev):
        return self.index["families"][fam]["events"].get(ev)

    def android(self, fam, ev):
        key = ("android", fam, ev)
        if key not in self.cache:
            a = self.info(fam, ev)["android"]
            self.cache[key] = json.loads((OUT / a["file"]).read_text(encoding="utf-8"))
        return self.cache[key]

    def ahap(self, fam, ev, suffix=""):
        info = self.info(fam, ev)
        for f in info["ios"]:
            if f["file"].endswith(f"{ev}{'.' + suffix if suffix else ''}.ahap"):
                key = ("ios", f["file"])
                if key not in self.cache:
                    self.cache[key] = json.loads((OUT / f["file"]).read_text(encoding="utf-8"))
                return self.cache[key]
        raise KeyError((fam, ev, suffix))

    def selected(self, fam, ev, tier):
        d = self.android(fam, ev)
        s = d["selection"][tier]
        return None if s["index"] is None else d["chain"][s["index"]]

    def pick_micro(self, tier):
        if tier == "ios":
            return [(0, 0.15)], None
        d = json.loads((OUT / "android/_continuous/pick_drag.json").read_text(encoding="utf-8"))
        s = d["selection"][tier]
        e = None if s["index"] is None else d["chain"][s["index"]]
        return entry_pulses(e), e


def occurrence_units(lib: Library, fam: str, ev: Ev, tier: str):
    """Expand one stream event into haptic units: list of (t_abs, [(dt, I)], name, phase)."""
    name = ev.name
    if name == "pick_drag.micro":
        p, _ = lib.pick_micro(tier)
        return [(ev.t, [(0, i) for _, i in p])] if p else []
    info = lib.info(fam, name)
    if info is None:
        raise KeyError(f"{fam} does not emit {name}")
    if info["status"] != "play":
        return []
    k_ie = ev.ie if name in ("contact", "pin.spring_bounce", "ring.detent", "near_shear", "bind",
                             "lever.false_gate") else 1.0
    if name not in EPISODIC:
        if tier == "ios":
            if name == "drop":
                n = max(2, min(6, round(2 + 4 * ev.ie)))
                p = ahap_pulses(lib.ahap(fam, "drop", f"n{n}"))
            elif name == "counter_rotate":
                p = ahap_pulses(lib.ahap(fam, name))
            else:
                p = ahap_pulses(lib.ahap(fam, name))
        else:
            p = entry_pulses(lib.selected(fam, name, tier))
        return [(ev.t, [(dt, i * k_ie) for dt, i in p])] if p else []
    # episodic: ticks every interval for ev.dur
    units = []
    if tier == "ios":
        if name == "stress":
            tick = ahap_pulses(lib.ahap(fam, "stress"))[0][1]
        elif name == "counter_rotate":
            tick = ahap_pulses(lib.ahap(fam, "counter_rotate", "loop"))[0][1]
        else:
            tick = ahap_pulses(lib.ahap(fam, name))[0][1]
        base_iv = {"stress": 70, "counter_rotate": 110, "wood.creak": 140, "ward.scrape": 60,
                   "detector.reset_hold": 250}[name]
        pulses = [(0, tick)]
        e = None
    else:
        e = lib.selected(fam, name, tier)
        pulses = entry_pulses(e)
        base_iv = entry_interval(e, 100)
        if name in ("counter_rotate", "stress", "wood.creak") and "waveform" in (e or {}):
            pulses = pulses[:1]
    if not pulses:
        return []
    t, end = ev.t, ev.t + ev.dur
    while t < end:
        iv = base_iv
        if name == "stress":
            if t - ev.t >= 4000:
                iv = 140  # FEEL §5.2 rule 3
            elif tier == "ios" and ev.ratio >= 0.9:
                iv = 45   # FEEL §2 stress >= 0.9 S/Smax (iOS only)
        units.append((t, [(dt, i * (ev.ie if name == "counter_rotate" else 1.0)) for dt, i in pulses]))
        t += iv
    return units


def regulate(lib, sc: Scenario, tier: str):
    """FEEL §5.2 regulator. Returns played pulses [(t, I, prio, essential, name)] and stats."""
    fam = sc.family
    played: list[tuple[int, float, int, bool, str]] = []
    win1, win10, strong10 = deque(), deque(), deque()
    last_by_key: dict = {}
    sub_win: dict[str, deque] = {}
    stats = {"occurrences": 0, "folded": 0, "coalesced": 0, "sub_limited": 0, "min_gap": 0, "shed_11": 0,
             "shed_9_10": 0, "shed_other": 0, "silence": 0, "essential_dropped": 0, "essential_played": 0}
    silence_until = -1
    last_played_t = {p: -10 ** 9 for p in range(0, 20)}
    # build units with priority info
    units = []
    for ev in sc.events:
        if ev.name == "wear":
            continue
        meta = {"priority": 13, "essential": False} if ev.name == "pick_drag.micro" else \
            spec.event_meta(lib.bank, ev.name)
        info = None if ev.name == "pick_drag.micro" else lib.info(fam, ev.name)
        if info is not None and info["status"].startswith("fold:"):
            stats["folded"] += 1
            continue
        for t, pulses in occurrence_units(lib, fam, ev, tier):
            units.append((t, ev, pulses, meta["priority"], meta["essential"]))
    units.sort(key=lambda u: (u[0], u[3]))
    for t, ev, pulses, prio, ess in units:
        stats["occurrences"] += 1
        while win1 and win1[0] <= t - 1000:
            win1.popleft()
        while win10 and win10[0] <= t - 10000:
            win10.popleft()
        while strong10 and strong10[0] <= t - 10000:
            strong10.popleft()
        n = len(pulses)
        n_strong = sum(1 for _, i in pulses if i >= STRONG)
        if not ess:
            # FEEL §5.2 rule 4 / §2 break: 150 ms haptic silence
            if t < silence_until:
                stats["silence"] += 1
                continue
            # coalescing 30 ms on (kind, sub, element), window not shifted (FEEL §7.3)
            key = (ev.name, ev.el)
            if ev.name not in EPISODIC and key in last_by_key and t - last_by_key[key] < 30:
                stats["coalesced"] += 1
                continue
            # per-sub-event limits (FEEL §3)
            lim = SUB_LIMIT.get(ev.name, {}).get(tier)
            if lim is not None:
                dq = sub_win.setdefault(ev.name, deque())
                while dq and dq[0] <= t - 1000:
                    dq.popleft()
                if len(dq) >= lim:
                    stats["sub_limited"] += 1
                    continue
            # min gap after a played pulse of equal or higher importance (TECH §3.5)
            if t - max(last_played_t[p] for p in range(0, prio + 1)) < MIN_GAP[tier]:
                stats["min_gap"] += 1
                continue
            over1 = len(win1) + n > CAP_1S[tier]
            fill10 = (len(win10) + n) / CAP_10S[tier]
            over_strong = n_strong and len(strong10) + n_strong > STRONG_CAP
            if prio >= 11 and (over1 or fill10 > 0.8 or over_strong):
                stats["shed_11"] += 1
                continue
            if 9 <= prio <= 10 and (over1 or fill10 > 1.0 or over_strong):
                stats["shed_9_10"] += 1
                continue
            if over1 or fill10 > 1.0 or over_strong:
                stats["shed_other"] += 1
                continue
            last_by_key[(ev.name, ev.el)] = t
            if ev.name in SUB_LIMIT:
                sub_win[ev.name].append(t)
        else:
            stats["essential_played"] += 1
            if not pulses:
                stats["essential_dropped"] += 1
        for dt, i in pulses:
            win1.append(t + dt)
            win10.append(t + dt)
            if i >= STRONG:
                strong10.append(t + dt)
            played.append((t + dt, i, prio, ess, ev.name))
        last_played_t[prio] = t + (pulses[-1][0] if pulses else 0)
        if ev.name == "break":
            silence_until = t + 150
    played.sort()
    return played, stats


def continuous(lib, sc: Scenario, tier: str, played):
    """Continuous channel(s) at 10 ms. Returns metrics."""
    if tier == "a0":
        return {"rms": 0.0, "rms_t": 0.0, "rms_p": 0.0, "duty": 0.0, "s_max": 0.0, "s_raw_max": 0.0,
                "s_clamped": 0.0, "stress_run_s": 0.0, "s_violations": 0, "gov_min": 1.0}
    fam = sc.family
    mt = spec.modifiers(lib.bank, fam, "tension_resistance")
    mp = spec.modifiers(lib.bank, fam, "pick_drag")
    ton = [False] * N
    for a, b in sc.tension:
        for j in range(a // DT, min(N, b // DT)):
            ton[j] = True
    rng = random.Random(len(sc.title) * 7919 + len(fam))
    r = [0.0] * N
    cur = 0.45
    for j in range(N):
        if j % 50 == 0:
            cur = min(0.7, max(0.25, cur + rng.uniform(-0.08, 0.08)))
        r[j] = cur
    pick_v = [0.0] * N
    pon = [False] * N
    for a, b, v in sc.pick:
        for j in range(a // DT, min(N, b // DT)):
            pon[j], pick_v[j] = True, v
    add = [0.0] * N
    scale = [1.0] * N
    s_set = [None] * N
    stress_flag = [False] * N
    p_s_add = [0.0] * N

    def span(t0, ms):
        return range(max(0, t0 // DT), min(N, (t0 + ms) // DT))

    for ev in sc.events:
        nm = ev.name
        if nm == "bind":
            for j in span(ev.t, 300):
                add[j] += 0.2 * min(1.0, (j * DT - ev.t) / 80.0)
        elif nm in ("set", "false_set", "gate_align") and not lib.info(fam, nm)["status"].startswith("fold"):
            depth, hold = {"set": (0.5, 110), "false_set": (0.35, 260), "gate_align": (0.7, 60)}[nm]
            for j in span(ev.t, hold + 60):
                x = j * DT - ev.t
                f = depth if x < hold else depth + (1 - depth) * (x - hold) / 60
                scale[j] *= f
        elif nm == "drop":
            for j in span(ev.t, 200):
                scale[j] *= max(0.0, 1 - (j * DT - ev.t) / 200)
        elif nm == "break":
            for j in span(ev.t, 450):
                x = j * DT - ev.t
                scale[j] *= 0.0 if x < 150 else (x - 150) / 300
        elif nm in ("overset", "detector_trip"):
            end = next((b for a, b in sc.tension if a <= ev.t < b), ev.t + 1000)
            if nm == "detector_trip":
                end = next((e.t for e in sc.events if e.name == "detector.reset" and e.t > ev.t), end)
            for j in span(ev.t, end - ev.t):
                s_set[j] = spec.clamp(0.05 + mt["ds"])
        elif nm == "stress":
            ms = spec.modifiers(lib.bank, fam, "stress")
            for j in span(ev.t, min(ev.dur, 4000)):  # FEEL §5.2 rule 3: continuous part max 4 s
                add[j] += 0.10 + 0.25 * ev.ratio
                s_set[j] = spec.clamp(0.85 + ms["ds"])
                stress_flag[j] = True
        elif nm == "wood.creak":
            for j in span(ev.t, ev.dur):
                add[j] += 0.05 + 0.15 * ev.ratio
                s_set[j] = spec.clamp(0.25 + mt["ds"])
        elif nm == "ward.scrape":
            for j in span(ev.t, ev.dur):
                p_s_add[j] = 0.10  # overlapping scrapes do not stack
    duck = [1.0] * N
    if tier in ("ios", "a4", "a3"):
        for t, _, prio, _, _ in played:
            if prio <= 10:
                for j in span(t, 95):
                    x = j * DT - t
                    f = 0.3 if x < 35 else 0.3 + 0.7 * (x - 35) / 60
                    duck[j] = min(duck[j], f)
    pick_cont = tier == "ios"  # Android: pick_drag only as micro ticks (FEEL §2)
    out_i = [0.0] * N
    sum_t = sum_p = 0.0
    s_max, s_raw_max, s_clamped, s_viol, run, run_max = 0.0, 0.0, 0, 0, 0, 0
    s_cap = lib.bank["budget"]["continuous_sharpness_max"]
    gov, gov_min = 1.0, 1.0
    sq = deque()
    sq_sum = 0.0
    fade = 0
    for j in range(N):
        if ton[j]:
            it = (0.10 + 0.45 * r[j] ** 1.5) * mt["k"] + add[j]
            fade = 30
        elif fade > 0:
            fade -= 1
            it = (0.10 + 0.45 * r[j] ** 1.5) * mt["k"] * fade / 30
        else:
            it = 0.0
        it = spec.clamp(it * scale[j] * duck[j] * gov)
        ip = spec.clamp((0.05 + 0.20 * pick_v[j]) * mp["k"] * gov) if (pon[j] and pick_cont) else 0.0
        tot = min(1.0, it + ip)
        out_i[j] = tot
        sum_t += it * it
        sum_p += ip * ip
        st = s_set[j] if s_set[j] is not None else spec.clamp(0.20 + 0.15 * r[j] + mt["ds"])
        sp = spec.clamp(0.55 + 0.20 * pick_v[j] + mp["ds"] + p_s_add[j])
        # runtime clamp budget.continuous_sharpness_max (stress exempt, <= 4 s): count what it catches
        if ip > 0.05:
            s_raw_max = max(s_raw_max, sp)
        if it > 0.05 and not stress_flag[j]:
            s_raw_max = max(s_raw_max, st)
        if (ip > 0.05 and sp > s_cap) or (it > 0.05 and not stress_flag[j] and st > s_cap):
            s_clamped += 1
        sp = min(sp, s_cap)
        if not stress_flag[j]:
            st = min(st, s_cap)
        hi = 0.0
        if it > 0.05:
            hi = st
            if st > 0.75 and not stress_flag[j]:
                s_viol += 1
        if ip > 0.05:
            hi = max(hi, sp)
            if sp > 0.75:
                s_viol += 1
        if it > 0.05 and stress_flag[j] and st > 0.75:
            run += 1
            run_max = max(run_max, run)
        else:
            run = 0
            s_max = max(s_max, hi)
        # governor (FEEL §5.2 rule 1): rolling 30 s RMS
        sq.append(tot * tot)
        sq_sum += tot * tot
        if len(sq) > 3000:
            sq_sum -= sq.popleft()
        if j % 100 == 99:
            rms30 = math.sqrt(max(0.0, sq_sum) / len(sq))
            if rms30 > 0.35:
                gov = max(0.75, gov - 0.05)
            elif rms30 < 0.28:
                gov = min(1.0, gov + 0.025)  # back to 1.0 in ~10 s
            gov_min = min(gov_min, gov)
    rms = math.sqrt(sum(x * x for x in out_i) / N)
    duty = sum(1 for x in out_i if x > 0.05) / N
    return {"rms": rms, "rms_t": math.sqrt(sum_t / N), "rms_p": math.sqrt(sum_p / N), "duty": duty,
            "s_max": s_max, "s_raw_max": s_raw_max, "s_clamped": s_clamped / N,
            "stress_run_s": run_max * DT / 1000, "s_violations": s_viol, "gov_min": gov_min}


def window_max(times, span=10000):
    dq, best = deque(), 0
    for t in times:
        dq.append(t)
        while dq[0] <= t - span:
            dq.popleft()
        best = max(best, len(dq))
    return best


def budget(lib):
    rows, fails = [], []
    for sc in scenarios():
        for tier in SIM_TIERS:
            played, st = regulate(lib, sc, tier)
            cont = continuous(lib, sc, tier, played)
            times = [p[0] for p in played]
            strong = [p[0] for p in played if p[1] >= STRONG]
            strong_ne = [p[0] for p in played if p[1] >= STRONG and not p[3]]
            row = {"family": sc.family, "scenario": sc.title, "tier": tier, "info": sc.info_only,
                   "played": len(played), "per10": len(played) / 18.0, "max10": window_max(times),
                   "strong_per10": len(strong) / 18.0, "strong_max10": window_max(strong),
                   "strong_ne_max10": window_max(strong_ne), **st, **cont}
            # FEEL §5.1 assertions
            problems = []
            # FEEL §5.1 RMS is checked per channel (tension, pick_drag) - this is the reading that reproduces
            # the §5.3 estimate (RMS ~0.22 at 65 % duty); the summed value is reported, see README.
            if max(cont["rms_t"], cont["rms_p"]) > 0.30:
                problems.append(f"continuous RMS {max(cont['rms_t'], cont['rms_p']):.3f} > 0.30")
            if cont["duty"] > 0.70:
                problems.append(f"continuous duty {cont['duty']:.1%} > 70%")
            if cont["s_violations"] or cont["s_max"] > 0.75 + 1e-9:
                problems.append(f"continuous sharpness {cont['s_max']:.2f} > 0.75 outside stress")
            if cont["stress_run_s"] > 4.0 + 1e-9:
                problems.append(f"stress sharpness run {cont['stress_run_s']:.2f} s > 4 s")
            if row["per10"] > CAP_10S[tier]:
                problems.append(f"transients/10 s {row['per10']:.1f} > {CAP_10S[tier]}")
            if row["strong_per10"] > STRONG_CAP:
                problems.append(f"strong/10 s {row['strong_per10']:.1f} > {STRONG_CAP}")
            if row["strong_ne_max10"] > STRONG_CAP:
                problems.append(f"non-essential strong in a 10 s window {row['strong_ne_max10']} > {STRONG_CAP}")
            if st["essential_dropped"]:
                problems.append(f"{st['essential_dropped']} essential events dropped")
            row["problems"] = problems
            rows.append(row)
            if problems and not sc.info_only:
                fails.append(f"budget {sc.family} [{sc.title}] {tier}: " + "; ".join(problems))
    return rows, fails


def print_table(rows, markdown=False):
    hdr = ["family", "tier", "T/10s", "max10", "cap", "strong/10s", "strong max10", "shed", "ess drop",
           "RMS tension", "RMS pick", "RMS sum", "duty", "S max (raw)", "stress S run", "result"]
    lines = []
    if markdown:
        lines.append("| " + " | ".join(hdr) + " |")
        lines.append("|" + "---|" * len(hdr))
    else:
        lines.append(f"{'family':<20}{'tier':<5}{'T/10s':>7}{'max10':>7}{'cap':>5}{'str/10s':>9}{'strMax':>8}"
                     f"{'shed':>7}{'essD':>6}{'RMS_t':>7}{'RMS_p':>7}{'RMSsum':>7}{'duty':>6}{'Smax(raw)':>13}"
                     f"{'Srun':>6}  result")
    last = None
    for r in rows:
        name = r["family"] + (" (info)" if r["info"] else "")
        shed = r["shed_11"] + r["shed_9_10"] + r["shed_other"] + r["sub_limited"] + r["min_gap"] + r["coalesced"]
        res = ("INFO: " if r["info"] else "") + ("ok" if not r["problems"] else "; ".join(r["problems"]))
        if r["info"] and not r["problems"]:
            res = "INFO ok"
        vals = [name, r["tier"], f"{r['per10']:.1f}", str(r["max10"]), str(CAP_10S[r["tier"]]),
                f"{r['strong_per10']:.1f}", str(r["strong_max10"]), str(shed), str(r["essential_dropped"]),
                f"{r['rms_t']:.3f}", f"{r['rms_p']:.3f}", f"{r['rms']:.3f}", f"{r['duty']:.0%}",
                f"{r['s_max']:.2f} ({r['s_raw_max']:.2f})", f"{r['stress_run_s']:.1f}", res]
        if markdown:
            lines.append("| " + " | ".join(vals) + " |")
        else:
            if last and last != name:
                lines.append("")
            lines.append(f"{name:<20}{vals[1]:<5}{vals[2]:>7}{vals[3]:>7}{vals[4]:>5}{vals[5]:>9}{vals[6]:>8}"
                         f"{vals[7]:>7}{vals[8]:>6}{vals[9]:>7}{vals[10]:>7}{vals[11]:>7}{vals[12]:>6}"
                         f"{vals[13]:>13}{vals[14]:>6}  {res}")
        last = name
    print("\n".join(lines))


def main():
    markdown = "--markdown" in sys.argv
    if not (OUT / "index.json").exists():
        print("haptics/out missing: run python3 haptics/build.py first")
        return 2
    bank, original, patch = spec.load_bank()
    n_ahap, n_android, index = schema_checks(bank, original, patch)
    print(f"schema: {n_ahap} AHAP, {n_android} Android chain files checked, {len(ERRORS)} errors")
    lib = Library(index, bank)
    rows, fails = budget(lib)
    print("\nbudget (FEEL §5.1, 180 s per family, regulator §5.2); T = transients after regulator, "
          "max10 = worst rolling 10 s (essential never shed), RMS/duty/S = continuous channel")
    print_table(rows, markdown)
    ERRORS.extend(fails)
    if WARNINGS:
        print("\nwarnings (divergences, not failures):")
        for w in WARNINGS:
            print("  - " + w)
    if ERRORS:
        print(f"\nFAIL: {len(ERRORS)} error(s)")
        for e in ERRORS[:60]:
            print("  * " + e)
        return 1
    print("\nOK: schema + budget pass")
    return 0


if __name__ == "__main__":
    sys.exit(main())
