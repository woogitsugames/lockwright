#!/usr/bin/env python3
"""Generate per-event haptic files from haptics/spec.py (FEEL.md + game/data/haptics_patterns.json).

Output (deterministic: sorted keys, fixed float rounding, no timestamps):
  haptics/out/ios/<family>/<event>[.<variant>].ahap   Apple AHAP (Core Haptics)
  haptics/out/ios/<family>/<event>.mod.json           modulation of the continuous players (dips, boosts)
  haptics/out/ios/_continuous/<signal>.ahap           looping templates + <signal>.control.json
  haptics/out/android/<family>/<event>.json           android_chain + resolved selection per tier
  haptics/out/android/_continuous/<signal>.json
  haptics/out/android/selection_table.json           family -> event -> tier A4..A0 -> chosen entry
  haptics/out/index.json                              manifest with sha256
  haptics/out/preview_data.js                         window.LW_HAPTICS for preview.html

Usage: python3 haptics/build.py
"""
from __future__ import annotations

import hashlib
import json
import shutil
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import spec  # noqa: E402
from spec import q, clamp  # noqa: E402

OUT = spec.OUT_DIR


def dumps(obj) -> str:
    return json.dumps(obj, sort_keys=True, indent=2, ensure_ascii=False) + "\n"


def sha256_bytes(b: bytes) -> str:
    return hashlib.sha256(b).hexdigest()


# ------------------------------------------------------------------------------------------------
# iOS
# ------------------------------------------------------------------------------------------------
def ahap_transient(t_ms, i, s):
    return {"Event": {"Time": q(t_ms / 1000.0), "EventType": "HapticTransient", "EventParameters": [
        {"ParameterID": "HapticIntensity", "ParameterValue": q(clamp(i))},
        {"ParameterID": "HapticSharpness", "ParameterValue": q(clamp(s))}]}}


def ahap_continuous(t_ms, dur_ms, i, s, release_s=0.02):
    return {"Event": {"Time": q(t_ms / 1000.0), "EventType": "HapticContinuous",
                      "EventDuration": q(dur_ms / 1000.0), "EventParameters": [
        {"ParameterID": "HapticIntensity", "ParameterValue": q(clamp(i))},
        {"ParameterID": "HapticSharpness", "ParameterValue": q(clamp(s))},
        {"ParameterID": "AttackTime", "ParameterValue": 0.0},
        {"ParameterID": "ReleaseTime", "ParameterValue": q(release_s)},
        {"ParameterID": "Sustained", "ParameterValue": 1.0}]}}


def ahap_curve(param, points_ms, t0_ms=0):
    return {"ParameterCurve": {"ParameterID": param, "Time": q(t0_ms / 1000.0), "ParameterCurveControlPoints": [
        {"Time": q(t / 1000.0), "ParameterValue": q(v)} for t, v in points_ms]}}


def ahap_doc(description: str, pattern: list) -> dict:
    # Sort by time (stable), events before curves at the same time
    def key(p):
        if "Event" in p:
            return (p["Event"]["Time"], 0)
        return (p["ParameterCurve"]["Time"], 1)
    return {"Version": 1.0, "Metadata": {"Project": "Lockwright", "Description": description},
            "Pattern": sorted(pattern, key=key)}


def resolve_elements(elements, mods, second_ms):
    """Apply FEEL §1.4 modifiers to a list of element tuples; returns AHAP pattern entries."""
    k, ds = mods["k"], mods["ds"]
    pat = []
    for el in elements:
        if el[0] == "T":
            t = second_ms if el[1] == "SECOND" else el[1]
            pat.append(ahap_transient(t, el[2] * k, el[3] + ds))
        elif el[0] == "C":
            pat.append(ahap_continuous(el[1], el[2], el[3] * k, el[4] + ds))
        elif el[0] == "CURVE":
            pat.append(ahap_curve(el[1], el[2]))
        else:
            raise ValueError(el)
    return pat


def ios_files(bank, family, event, mods):
    """Return list of (variant_suffix, role, ahap_doc)."""
    d = spec.ios_def(event)
    fam = bank["families"][family]
    second = fam.get("false_set_second_delay_ms", 28)
    desc = f"{family} / {event} / {mods['material']} (k {mods['k']}, dS {mods['ds']}); {d['src']}"
    out = []
    kind = d.get("kind")
    k, ds = mods["k"], mods["ds"]
    if d.get("none") or d.get("folded_into"):
        return out
    if kind is None:
        extra = ""
        if event == "false_set":
            extra = f"; second impulse at +{second} ms (families.{family}.false_set_second_delay_ms)"
        if event == "set" and spec.FAMILY_EVENTS[family].get("gate_align") == "fold:set":
            extra = "; gate_align of the same step folded in (sound -6 dB + image only, FEEL §3.5/§3.7, F-05)"
        if event == "false_set" and "lever.false_gate" in spec.FAMILY_EVENTS[family]:
            extra += "; second impulse = lever.false_gate"
        out.append(("", "event", ahap_doc(desc + extra, resolve_elements(d["elements"], mods, second))))
    elif kind == "burst":
        lo, hi = d["count"]
        for n in range(lo, hi + 1):
            pat = []
            for j in range(n):
                frac = 0.0 if n == 1 else j / (n - 1)
                i = d["I_from"] + (d["I_to"] - d["I_from"]) * frac
                pat.append(ahap_transient(j * d["interval_ms"], i * k, d["S"] + ds))
            out.append((f"n{n}", f"count {n} (n = round({lo} + {hi - lo} * I_event))",
                        ahap_doc(desc + f"; cascade of {n}", pat)))
    elif kind == "tick_loop":
        ti, ts = d["tick"]
        for var, interval in d["variants"].items():
            n = d["loop_ticks"][var]
            pat = [ahap_transient(j * interval, ti * k, ts + ds) for j in range(n)]
            role = f"loop unit {n * interval} ms, tick every {interval} ms" + (f" ({var})" if var else "")
            out.append((var, role, ahap_doc(desc + "; " + role + "; loop with CHHapticAdvancedPatternPlayer",
                                            pat)))
    elif kind == "ramp_then_loop":
        ti, ts = d["tick"]
        ci, cs = d["cont"]
        iv = d["interval_ms"]
        ramp = [ahap_continuous(0, d["ramp_ms"], ci * k, cs + ds),
                ahap_curve("HapticIntensityControl", d["ramp"] + [[d["ramp_ms"], 1.0]])]
        ramp += [ahap_transient(t, ti * k, ts + ds) for t in range(0, d["ramp_ms"], iv)]
        out.append(("", "ramp (one-shot, then switch to .loop)", ahap_doc(desc + "; ramp 0.20->0.40", ramp)))
        loop = [ahap_continuous(0, d["loop_ms"], ci * k, cs + ds, release_s=0.0)]
        loop += [ahap_transient(t, ti * k, ts + ds) for t in range(0, d["loop_ms"], iv)]
        out.append(("loop", "loop while pressure lasts", ahap_doc(desc + "; held at 0.40, looped", loop)))
    else:
        raise ValueError(kind)
    return out


def mod_doc(family, event, mods):
    d = spec.ios_def(event)
    m = d.get("mod")
    if not m:
        return None
    m = json.loads(json.dumps(m))
    if isinstance(m.get("sharpness_set"), (int, float)):
        m["sharpness_set"] = q(clamp(m["sharpness_set"] + mods["ds"]))
    return {"family": family, "event": event, "source": d["src"], "modulation": m,
            "apply": ("Do not put into the event AHAP: Core Haptics curves only affect their own player "
                      "(TECH §2.1). Apply on the continuous player of `channel`: intensity_scale = multiply "
                      "HapticIntensityControl by the curve [[t_ms, factor]]; intensity_add / sharpness_add = add "
                      "to the control value; sharpness_set = absolute sharpness until the condition ends.")}


def continuous_ahap(name, c):
    pat = [ahap_continuous(0, c["loop_s"] * 1000, 1.0, c["base_sharpness"], release_s=0.0),
           ahap_curve("HapticIntensityControl", [[0, 0.10 if name == "tension_resistance" else 0.05]]),
           ahap_curve("HapticSharpnessControl", [[0, 0.0]])]
    desc = (f"{name}: looping template (CHHapticAdvancedPatternPlayer, loopEnabled, loopEnd {c['loop_s']} s). "
            f"Event I 1.0, S {c['base_sharpness']}; drive HapticIntensityControl (multiplier 0..1) = "
            f"{c['intensity_map']} x k_material x k_family x slider, HapticSharpnessControl (offset -1..1) = "
            f"S_target - {c['base_sharpness']}; sendParameters <= 60 Hz. {c['src']}")
    return ahap_doc(desc, pat)


def continuous_control(bank, name, c):
    rows = []
    for j in range(11):
        x = j / 10
        if name == "tension_resistance":
            i = 0.10 + 0.45 * x ** 1.5
            s = c["sharpness_range"][0] + (c["sharpness_range"][1] - c["sharpness_range"][0]) * x
        else:
            i = 0.05 + 0.20 * x
            s = c["sharpness_range"][0] + (c["sharpness_range"][1] - c["sharpness_range"][0]) * x
        rows.append([q(x, 2), q(i), q(s), q(s - c["base_sharpness"])])
    fam = {}
    for f in spec.FAMILIES:
        m = spec.modifiers(bank, f, name)
        fam[f] = {"material": m["material"], "k": m["k"], "ds": m["ds"]}
    return {"signal": name, "source": c["src"], "template": f"{name}.ahap",
            "control_table_columns": ["input_0_1", "intensity_control", "sharpness_target", "sharpness_control"],
            "control_table": rows, "per_family": fam,
            "budget_sharpness_max": bank["budget"]["continuous_sharpness_max"],
            "budget_note": ("Clamp the final sharpness of this channel to budget_sharpness_max after material x "
                            "family modifiers (only stress may exceed it, max 4 s; FEEL §5.1). Without the clamp "
                            "pick_drag reaches 0.80 in wafer (0.75 + family dS +0.05)."),
            "rules": {k: v for k, v in c.items() if k not in ("src", "loop_s", "base_sharpness")}}


# ------------------------------------------------------------------------------------------------
# Android
# ------------------------------------------------------------------------------------------------
def entry_primitives(e) -> list:
    p = [c[0] for c in e.get("composition", [])]
    for key in ("tick", "then"):
        if key in e:
            p.append(e[key][0])
    return p


def scale_entry(e, mods, event, family_cfg):
    e = json.loads(json.dumps(e))
    k, ds = mods["k"], mods["ds"]
    if "composition" in e:
        comp = []
        for j, (prim, sc, dl) in enumerate(e["composition"]):
            if event == "false_set" and j == 1:
                dl = family_cfg.get("false_set_second_delay_ms", dl)  # F-01: levers 40 ms
            comp.append([prim, q(clamp(sc * k), 3), dl])
        e["composition"] = comp
        onset, t = [], 0
        for _, _, dl in comp:
            t += dl
            onset.append(t)
        e["onset_ms"] = onset
    if "envelope" in e:
        e["envelope"] = [[t, q(clamp(i * k), 3), q(clamp(s + ds), 3)] for t, i, s in e["envelope"]]
    for key in ("tick", "then"):
        if key in e:
            e[key] = [e[key][0], q(clamp(e[key][1] * k), 3)]
    if "waveform" in e:
        e["waveform"]["amps"] = [int(min(255, round(a * k))) for a in e["waveform"]["amps"]]
    return e


def normalize_chain(chain):
    notes = []
    if not chain or not (chain[-1].get("tier") == "a0" or chain[-1].get("skip")):
        chain.append({"tier": "a0", "skip": True, "normalized": True})
        notes.append("appended a0 skip (chain did not end with a0/skip)")
    elif chain[-1].get("tier") != "a0":
        chain.append({"tier": "a0", "skip": True, "normalized": True})
        notes.append("appended explicit a0 skip after a non-a0 skip")
    return notes


def select(chain, tier, supported):
    for idx, e in enumerate(chain):
        if spec.TIER_RANK[e["tier"]] <= spec.TIER_RANK[tier] and set(entry_primitives(e)) <= supported:
            return idx
    return None


def summarize(e):
    if e is None:
        return "none"
    if e.get("skip"):
        return "skip (sound + image only)"
    parts = []
    if "envelope" in e:
        parts.append(f"envelope {len(e['envelope'])} pts / {e['envelope'][-1][0]} ms")
    if "composition" in e:
        parts.append(" + ".join(f"{p}@{o} {s}" for (p, s, _), o in zip(e["composition"], e["onset_ms"])))
    for key in ("tick", "then"):
        if key in e:
            parts.append(f"{key} {e[key][0]} {e[key][1]}")
    if "waveform" in e:
        parts.append(f"waveform t{e['waveform']['timings']} a{e['waveform']['amps']}")
    if "effect" in e:
        parts.append(e["effect"])
    if "on_ms" in e:
        parts.append(f"on {e['on_ms']} ms" + (f" + {e['second_on_ms']} ms after {e['second_gap_ms']}"
                                               if "second_on_ms" in e else ""))
    if "pattern_ms" in e:
        parts.append(f"on/off {e['pattern_ms']}")
    if "resistance_amp_boost_pct" in e:
        parts.append(f"resistance amp +{e['resistance_amp_boost_pct']}%")
    if "repeat_interval_ms" in e:
        parts.append(f"every {e['repeat_interval_ms']} ms")
    if "interval_ms" in e:
        parts.append(f"every {e['interval_ms']} ms")
    if "micro" in e:
        parts.append(f"micro {e['micro'][0]} {e['micro'][1]}")
    if "limit_per_s" in e:
        parts.append(f"<= {e['limit_per_s']}/s")
    return ", ".join(parts) or json.dumps(e, sort_keys=True)


def selection_for(chain):
    full, minimal = {}, {}
    allp = set(spec.ANDROID_PRIMITIVES)
    for t in spec.TIERS:
        for dst, sup in ((full, allp), (minimal, spec.MIN_PRIMITIVES)):
            i = select(chain, t, sup)
            dst[t] = {"index": i, "entry_tier": None if i is None else chain[i]["tier"],
                      "summary": summarize(None if i is None else chain[i])}
    return full, minimal


def android_doc(bank, family, event, mods):
    chain = spec.android_chain(bank, event)
    fam_cfg = bank["families"][family]
    chain = [scale_entry(e, mods, event, fam_cfg) for e in chain]
    notes = normalize_chain(chain)
    full, minimal = selection_for(chain)
    meta = spec.event_meta(bank, event)
    return {"family": family, "event": event, "material": mods["material"],
            "modifiers": {"k": mods["k"], "ds": mods["ds"], "family_modifier_applied": mods["family_modifier_applied"]},
            "priority": meta["priority"], "essential": meta["essential"], "base": meta["base"],
            "source": "docs/FEEL.md §9 " + ("sub_events" if "." in event else "events") + f".{event}.android_chain"
                      + (" (+ haptics/spec.py EXTRA_SUB_BANK)" if event in spec.EXTRA_SUB_BANK else ""),
            "chain": chain, "normalization": notes,
            "selection": full, "selection_min_primitives": minimal,
            "rule": ("FEEL §1.3: first entry whose tier <= device tier and all primitives in "
                     "supported_primitives_mask. composition delay_ms is relative to the previous primitive's "
                     "start (FEEL semantics); onset_ms is cumulative. Android Composition.addPrimitive delay "
                     "counts from the end of the previous primitive: subtract getPrimitiveDurations().")}


def android_continuous(bank, name):
    c = bank["continuous"][name]
    if name == "tension_resistance":
        chain = [{"tier": "a3", "envelope_segment_ms": c["android"]["envelope_segment_ms"],
                  "intensity_map": "0.10 + 0.45 * r^1.5", "sharpness_range": [0.2, 0.35]},
                 {"tier": "a1", "waveform_segment_ms": c["android"]["waveform_segment_ms"],
                  "amp_range": c["android"]["waveform_amp_range"], "update_ms": c["android"]["update_ms"]},
                 {"tier": "a0", "skip": True}]
    else:
        chain = [{"tier": "a2", "micro": [c["android"]["micro_primitive"], c["android"]["micro_scale"]],
                  "limit_per_s": c["android"]["micro_limit_per_s"]},
                 {"tier": "a1", "effect": c["fallback"]["effect"], "limit_per_s": c["fallback"]["limit_per_s"]},
                 {"tier": "a0", "skip": True}]
    full, minimal = selection_for(chain)
    per_fam = {f: {k: v for k, v in spec.modifiers(bank, f, name).items() if k in ("material", "k", "ds")}
               for f in spec.FAMILIES}
    return {"signal": name, "source": "docs/FEEL.md §2 (continuous) + bank.continuous." + name,
            "priority": c["priority"], "chain": chain, "selection": full, "selection_min_primitives": minimal,
            "per_family": per_fam,
            "rule": "A2 uses the a1 waveform segment for tension (TECH §2.2 'A2: jak A1'); A0: none."}


# ------------------------------------------------------------------------------------------------
# Sound mapping (preview)
# ------------------------------------------------------------------------------------------------
def sfx_materials():
    res = {}
    for d in sorted(spec.SFX_DIR.iterdir()) if spec.SFX_DIR.exists() else []:
        if d.is_dir():
            mats = {}
            for f in d.glob("*.wav"):
                m, n = f.stem.rsplit("_", 1)
                mats[m] = max(mats.get(m, 0), int(n))
            res[d.name] = mats
    return res


def sound_layers(bank, family, event, mods, avail):
    sfx = spec.sfx_for(bank, family, event) or {"id": event}
    layers = spec.SOUND_LAYERS.get(f"{family}:{event}") or spec.SOUND_LAYERS.get(event) \
        or [[sfx["id"], sfx.get("delay_ms", 0), sfx.get("gain_db", 0.0)]]
    out = []
    for sid, delay, gain in layers:
        want = sfx.get("material", mods["material"]) if sid == sfx["id"] else mods["material"]
        mats = avail.get(sid, {})
        mat = next((m for m in [want, "brass", "steel", "iron", "wood"] if m in mats), None)
        if mat is None:
            continue
        out.append({"id": sid, "material": mat, "wanted_material": want, "variants": mats[mat],
                    "delay_ms": delay, "gain_db": gain, "rate": sfx.get("pitch", 1.0) if sid == sfx["id"] else 1.0,
                    "path": f"../audio/v2/out/sfx/{sid}/{mat}_{{n}}.wav"})
    return out


# ------------------------------------------------------------------------------------------------
def main():
    bank, original, patch = spec.load_bank()
    if OUT.exists():
        shutil.rmtree(OUT)
    files: dict[str, bytes] = {}

    def put(rel, obj):
        files[rel] = dumps(obj).encode("utf-8")
        return rel

    index = {"schema": "lockwright.haptics.out/1", "generator": "haptics/build.py",
             "feel_version": spec.feel_version(bank),
             "sources": {"docs/FEEL.md": sha256_bytes(spec.FEEL_PATH.read_bytes()),
                         "game/data/haptics_patterns.json": sha256_bytes(spec.BANK_PATH.read_bytes())},
             "families": {}, "continuous": {}}
    selection_table = {}
    preview = {"families": {}, "continuous": {}, "tiers": spec.TIERS}
    avail = sfx_materials()

    for fam in spec.FAMILIES:
        fcfg = bank["families"][fam]
        fi = {"material": fcfg["material"], "intensity_scale": fcfg.get("intensity_scale", 1.0),
              "delta_sharpness": fcfg.get("delta_sharpness", 0.0), "events": {}}
        pf = {"material": fcfg["material"], "events": {}}
        selection_table[fam] = {}
        for ev, status in sorted(spec.FAMILY_EVENTS[fam].items()):
            mods = spec.modifiers(bank, fam, ev)
            meta = spec.event_meta(bank, ev)
            entry = {"status": status, "priority": meta["priority"], "essential": meta["essential"],
                     "material": mods["material"], "k": mods["k"], "ds": mods["ds"], "ios": [], "android": None,
                     "sfx": spec.sfx_for(bank, fam, ev)}
            pe = {"status": status, "priority": meta["priority"], "essential": meta["essential"],
                  "material": mods["material"], "ios": [], "mod": None, "android": None,
                  "sound": sound_layers(bank, fam, ev, mods, avail)}
            if status == "play":
                for var, role, doc in ios_files(bank, fam, ev, mods):
                    rel = put(f"ios/{fam}/{ev}{'.' + var if var else ''}.ahap", doc)
                    entry["ios"].append({"file": rel, "role": role})
                    pe["ios"].append({"file": rel, "role": role, "ahap": doc})
                md = mod_doc(fam, ev, mods)
                if md:
                    rel = put(f"ios/{fam}/{ev}.mod.json", md)
                    entry["ios_mod"] = {"file": rel}
                    pe["mod"] = md["modulation"]
                ad = android_doc(bank, fam, ev, mods)
                rel = put(f"android/{fam}/{ev}.json", ad)
                entry["android"] = {"file": rel}
                selection_table[fam][ev] = {"full": ad["selection"], "min_primitives": ad["selection_min_primitives"]}
                pe["android"] = {"chain": ad["chain"], "selection": ad["selection"],
                                 "selection_min_primitives": ad["selection_min_primitives"]}
            elif status.startswith("fold:"):
                selection_table[fam][ev] = {"folded_into": status[5:]}
            else:
                selection_table[fam][ev] = {"audio_only": True}
            fi["events"][ev] = entry
            pf["events"][ev] = pe
        index["families"][fam] = fi
        preview["families"][fam] = pf

    for name, c in spec.CONTINUOUS_PATTERNS.items():
        a = put(f"ios/_continuous/{name}.ahap", continuous_ahap(name, c))
        cc = put(f"ios/_continuous/{name}.control.json", continuous_control(bank, name, c))
        ad = android_continuous(bank, name)
        an = put(f"android/_continuous/{name}.json", ad)
        index["continuous"][name] = {"ios": {"file": a}, "ios_control": {"file": cc}, "android": {"file": an}}
        preview["continuous"][name] = {"ahap": json.loads(files[a]), "control": json.loads(files[cc]),
                                       "android": ad}
    put("android/selection_table.json", {"source": "FEEL §1.3", "tiers": spec.TIERS,
                                         "columns": {"full": "all 8 primitives supported",
                                                     "min_primitives": "only CLICK + TICK (A2 minimum)"},
                                         "families": selection_table})

    # sha256 into index
    def fill(node):
        if isinstance(node, dict):
            if "file" in node and node["file"] in files:
                node["sha256"] = sha256_bytes(files[node["file"]])
            for v in node.values():
                fill(v)
        elif isinstance(node, list):
            for v in node:
                fill(v)
    fill(index)
    index["selection_table"] = {"file": "android/selection_table.json",
                                "sha256": sha256_bytes(files["android/selection_table.json"])}
    index["counts"] = {
        "ahap": sum(1 for r in files if r.endswith(".ahap")),
        "ios_mod": sum(1 for r in files if r.endswith(".mod.json")),
        "android_event": sum(1 for r in files if r.startswith("android/") and "/_continuous/" not in r
                             and not r.endswith("selection_table.json")),
        "family_events_played": sum(1 for f in index["families"].values() for e in f["events"].values()
                                    if e["status"] == "play"),
        "family_events_total": sum(len(f["events"]) for f in index["families"].values()),
    }
    files["index.json"] = dumps(index).encode("utf-8")
    files["preview_data.js"] = ("// generated by haptics/build.py - do not edit\nwindow.LW_HAPTICS = "
                                + json.dumps(preview, sort_keys=True, ensure_ascii=False, separators=(",", ":"))
                                + ";\n").encode("utf-8")

    for rel, data in sorted(files.items()):
        p = OUT / rel
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_bytes(data)
    c = index["counts"]
    print(f"haptics/out: {len(files)} files; AHAP {c['ahap']}, iOS mod {c['ios_mod']}, "
          f"Android event files {c['android_event']}; family x event: {c['family_events_played']} played "
          f"of {c['family_events_total']} listed")


if __name__ == "__main__":
    main()
