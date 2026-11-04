#!/usr/bin/env python3
"""Lockwright SFX synthesizer — generates all game samples as 48 kHz 16-bit mono WAV.

Technique: modal synthesis (sum of exponentially damped sinusoids whose modal
frequencies depend on the material), filtered noise for friction, short
transients with envelopes for clicks. Dry samples, no reverb.

set = short, dry, bright click; false_set = duller double click with rattle;
break = sharp crack; open = heavy mechanism clunk (docs/DESIGN.md, docs/TECH.md §3).

Usage: python3 audio/tools/synth.py [--out game/assets/audio/sfx]
"""

import argparse
import json
import math
import os

import numpy as np
import soundfile as sf

SR = 48000
PEAK = 10 ** (-1.0 / 20.0)  # -1 dBFS

EVENTS = [
    "contact", "bind", "near_shear", "set", "false_set", "counter_rotate",
    "overset", "drop", "stress", "break", "wear", "gate_align",
    "detector_trip", "open",
]
LOOPS = ["tension_resistance", "pick_drag"]
MATERIALS = ["brass", "steel", "iron", "wood"]
VARIANTS = 4  # 3-5 random variants per event x material

# Material profiles (docs/TECH.md §3.2): modal freqs (Hz), decay (s), noise character.
MATERIAL_PROFILES = {
    "brass": {"modes": [2300, 3100, 3900], "decay": 0.075, "noise_hp": 1800.0, "noise_amp": 0.25, "base": 1.0},
    "steel": {"modes": [5200, 6600, 7900], "decay": 0.050, "noise_hp": 3000.0, "noise_amp": 0.35, "base": 1.05},
    "iron":  {"modes": [1200, 1700, 2300], "decay": 0.040, "noise_hp": 700.0,  "noise_amp": 0.45, "base": 0.95},
    "wood":  {"modes": [420, 640, 810],    "decay": 0.028, "noise_hp": 300.0,  "noise_amp": 0.20, "base": 0.80},
}


def t_axis(dur: float) -> np.ndarray:
    return np.arange(int(dur * SR), dtype=np.float64) / SR


def damped_sine(freq: float, decay: float, dur: float, amp: float = 1.0, phase: float = 0.0) -> np.ndarray:
    t = t_axis(dur)
    return amp * np.exp(-t / decay) * np.sin(2 * np.pi * freq * t + phase)


def damped_sine_sweep(f0: float, f1: float, decay: float, dur: float, amp: float = 1.0) -> np.ndarray:
    t = t_axis(dur)
    phase = 2 * np.pi * np.cumsum(f0 + (f1 - f0) * (t / dur)) / SR
    return amp * np.exp(-t / decay) * np.sin(phase)


def noise_burst(dur: float, rng: np.random.Generator, hp: float = 0.0, lp: float = 20000.0, amp: float = 1.0) -> np.ndarray:
    n = int(dur * SR)
    x = rng.standard_normal(n)
    if lp < SR / 2 or hp > 0.0:
        from scipy.signal import butter, sosfilt
        sos = []
        if hp > 0.0:
            sos += list(butter(2, hp, "highpass", fs=SR, output="sos"))
        if lp < SR / 2:
            sos += list(butter(2, lp, "lowpass", fs=SR, output="sos"))
        if sos:
            x = sosfilt(np.array(sos), x)
    return amp * x


def env_attack_release(dur: float, attack: float = 0.001, release: float = 0.01) -> np.ndarray:
    t = t_axis(dur)
    e = np.minimum(1.0, t / max(attack, 1e-6))
    e *= np.minimum(1.0, (dur - t) / max(release, 1e-6))
    return np.clip(e, 0.0, 1.0)


def modal_click(mat: dict, rng: np.random.Generator, dur: float, bright: float = 1.0, detune: float = 0.0) -> np.ndarray:
    out = np.zeros(int(dur * SR))
    for i, f in enumerate(mat["modes"]):
        f *= bright * (1.0 + rng.uniform(-detune, detune))
        out += damped_sine(f, mat["decay"] * rng.uniform(0.8, 1.2), dur, amp=1.0 / (i + 1))
    out += noise_burst(dur, rng, hp=mat["noise_hp"], amp=mat["noise_amp"]) * env_attack_release(dur, 0.0005, dur * 0.5)
    return out


def place(buf: np.ndarray, sig: np.ndarray, at_s: float) -> None:
    i = int(at_s * SR)
    j = min(len(buf), i + len(sig))
    if i < len(buf):
        buf[i:j] += sig[: j - i]


def normalize(x: np.ndarray) -> np.ndarray:
    m = np.max(np.abs(x))
    if m > 0:
        x = x / m * PEAK
    return x


def trim_leading_silence(x: np.ndarray, max_lead_ms: float = 1.0) -> np.ndarray:
    thresh = 1e-4
    idx = np.argmax(np.abs(x) > thresh) if np.any(np.abs(x) > thresh) else 0
    max_lead = int(max_lead_ms / 1000 * SR)
    return x[min(idx, max_lead):]


def click_dur(rng: np.random.Generator, lo: float = 0.020, hi: float = 0.080) -> float:
    return rng.uniform(lo, hi)


# --- event recipes -----------------------------------------------------------

def ev_contact(mat, rng):
    d = click_dur(rng, 0.010, 0.015)
    return trim_leading_silence(modal_click(mat, rng, d, bright=1.2, detune=0.02) * 0.5)

def ev_bind(mat, rng):
    d = 0.05
    out = modal_click(mat, rng, 0.02, bright=0.9) * 0.9
    place(out, noise_burst(0.03, rng, hp=mat["noise_hp"], amp=0.5) * env_attack_release(0.03, 0.001, 0.02), 0.012)
    return trim_leading_silence(out[: int(d * SR)])

def ev_near_shear(mat, rng):
    d = 0.06
    out = noise_burst(d, rng, hp=mat["noise_hp"] * 1.3, lp=9000, amp=0.25) * env_attack_release(d, 0.005, 0.03)
    return trim_leading_silence(out)

def ev_set(mat, rng):
    d = click_dur(rng, 0.020, 0.030)
    core = modal_click(mat, rng, d, bright=1.0, detune=0.015)
    place(core, damped_sine(mat["modes"][0] * 0.5, 0.06, 0.06, amp=0.4), 0.0)
    return trim_leading_silence(core)

def ev_false_set(mat, rng):
    d = click_dur(rng, 0.025, 0.040)
    core = modal_click(mat, rng, d, bright=0.72, detune=0.02) * 1.0
    second = modal_click(mat, rng, 0.02, bright=0.5, detune=0.03) * 0.35
    place(core, second, 0.028)
    place(core, noise_burst(0.02, rng, hp=500, lp=2500, amp=0.4) * env_attack_release(0.02, 0.001, 0.015), 0.03)
    return trim_leading_silence(core[: int(0.09 * SR)])

def ev_counter_rotate(mat, rng):
    d = 0.16
    out = damped_sine_sweep(220, 160, 0.09, d, amp=0.7)
    place(out, noise_burst(0.1, rng, hp=400, lp=2200, amp=0.35) * env_attack_release(0.1, 0.005, 0.05), 0.02)
    return trim_leading_silence(out)

def ev_overset(mat, rng):
    d = click_dur(rng, 0.030, 0.040)
    out = damped_sine(180 + rng.uniform(-30, 30), 0.02, d, amp=1.0)
    place(out, noise_burst(d, rng, hp=150, lp=900, amp=0.5) * env_attack_release(d, 0.0005, 0.02), 0.0)
    return trim_leading_silence(out)

def ev_drop(mat, rng):
    d = 0.30
    out = np.zeros(int(d * SR))
    n = int(rng.integers(3, 6))
    for i in range(n):
        c = modal_click(mat, rng, 0.018, bright=0.8 + 0.1 * i, detune=0.03) * (0.9 - 0.12 * i)
        place(out, c, i * 0.040)
    place(out, damped_sine(120, 0.08, 0.18, amp=0.5), 0.05)
    return trim_leading_silence(out)

def ev_stress(mat, rng):
    d = 0.20
    out = damped_sine_sweep(2200, 5200, 0.06, d, amp=0.6)
    place(out, noise_burst(d, rng, hp=2500, lp=8000, amp=0.3) * env_attack_release(d, 0.002, 0.05), 0.0)
    return trim_leading_silence(out)

def ev_break(mat, rng):
    d = 0.16
    out = noise_burst(0.006, rng, hp=800, amp=1.0) * env_attack_release(0.006, 0.0002, 0.004)
    place(out, modal_click(mat, rng, 0.12, bright=1.4, detune=0.02) * 0.8, 0.004)
    place(out, damped_sine(90, 0.10, 0.12, amp=0.6), 0.01)
    return trim_leading_silence(out)

def ev_wear(mat, rng):
    d = 0.05
    out = noise_burst(d, rng, hp=300, lp=2000, amp=0.4) * env_attack_release(d, 0.002, 0.02)
    return trim_leading_silence(out)

def ev_gate_align(mat, rng):
    d = click_dur(rng, 0.020, 0.025)
    out = modal_click(mat, rng, d, bright=0.55, detune=0.01) * 0.7
    return trim_leading_silence(out)

def ev_detector_trip(mat, rng):
    d = 0.30
    out = np.zeros(int(d * SR))
    for at in (0.0, 0.14):
        place(out, modal_click(mat, rng, 0.06, bright=1.1, detune=0.01) * 0.95, at)
    return trim_leading_silence(out)

def ev_open(mat, rng):
    d = 0.65
    out = np.zeros(int(d * SR))
    place(out, damped_sine(140, 0.05, 0.08, amp=1.0), 0.0)
    place(out, noise_burst(0.05, rng, hp=200, lp=1200, amp=0.7) * env_attack_release(0.05, 0.001, 0.03), 0.0)
    place(out, noise_burst(0.25, rng, hp=500, lp=3000, amp=0.35) * env_attack_release(0.25, 0.01, 0.15), 0.08)
    place(out, modal_click(mat, rng, 0.07, bright=0.8, detune=0.01) * 0.9, 0.42)
    place(out, damped_sine(70, 0.12, 0.2, amp=0.7), 0.42)
    return trim_leading_silence(out)

EVENT_FNS = {
    "contact": ev_contact, "bind": ev_bind, "near_shear": ev_near_shear,
    "set": ev_set, "false_set": ev_false_set, "counter_rotate": ev_counter_rotate,
    "overset": ev_overset, "drop": ev_drop, "stress": ev_stress, "break": ev_break,
    "wear": ev_wear, "gate_align": ev_gate_align, "detector_trip": ev_detector_trip,
    "open": ev_open,
}

CLICK_EVENTS = {"contact", "bind", "set", "false_set", "overset", "gate_align"}


def make_loop(loop: str, mat: dict, rng: np.random.Generator, dur: float = 1.2) -> np.ndarray:
    n = int(dur * SR)
    t = t_axis(dur)
    if loop == "tension_resistance":
        from scipy.signal import butter, sosfilt
        x = rng.standard_normal(n)
        sos = butter(2, 500, "lowpass", fs=SR, output="sos")
        x = sosfilt(sos, x)
        lfo = 0.6 + 0.4 * np.sin(2 * np.pi * 7.0 * t + rng.uniform(0, 6))
        x = x * lfo * 0.5
    else:  # pick_drag: scratchy mid-band friction with crackle
        from scipy.signal import butter, sosfilt
        x = rng.standard_normal(n)
        sos = butter(2, [900, 4200], "bandpass", fs=SR, output="sos")
        x = sosfilt(sos, x)
        crackle = (rng.random(n) > 0.9985).astype(float)
        x = x * 0.6 + crackle * rng.standard_normal(n) * 0.25
    # crossfade loop edges for seamless looping
    fade = int(0.05 * SR)
    x[:fade] = x[:fade] * np.linspace(0, 1, fade) + x[-fade:] * np.linspace(1, 0, fade)
    return x


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=os.path.join(os.path.dirname(__file__), "..", "..", "game", "assets", "audio", "sfx"))
    ap.add_argument("--manifest", default=os.path.join(os.path.dirname(__file__), "..", "manifest.json"))
    args = ap.parse_args()
    out_root = os.path.abspath(args.out)
    manifest = {"sample_rate": SR, "bit_depth": 16, "schema": "lockwright.sfx/1", "files": []}

    for event in EVENTS + LOOPS:
        for material in MATERIALS:
            mat = MATERIAL_PROFILES[material]
            os.makedirs(os.path.join(out_root, event), exist_ok=True)
            for v in range(1, VARIANTS + 1):
                rng = np.random.default_rng(hash((event, material, v)) & 0xFFFFFFFF)
                if event in LOOPS:
                    x = make_loop(event, mat, rng)
                else:
                    x = EVENT_FNS[event](mat, rng)
                    x = normalize(x.astype(np.float64))
                    if event in CLICK_EVENTS:
                        d = len(x) / SR
                        if not (0.010 <= d <= 0.080):
                            x = x[: int(0.075 * SR)]
                path = os.path.join(out_root, event, f"{material}_{v}.wav")
                sf.write(path, x.astype(np.float32), SR, subtype="PCM_16")
                manifest["files"].append({
                    "file": os.path.relpath(path, out_root),
                    "event": event, "material": material, "variant": v,
                    "duration_s": round(len(x) / SR, 4),
                })
    with open(os.path.abspath(args.manifest), "w") as f:
        json.dump(manifest, f, indent=2)
    total = len(manifest["files"])
    print(f"wrote {total} wav files to {out_root}")


if __name__ == "__main__":
    main()
