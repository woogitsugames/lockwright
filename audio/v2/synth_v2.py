#!/usr/bin/env python3
"""Lockwright SFX v2 — offline modal-synthesis generator (Python 3 + numpy only).

Model (docs/TECH.md §3):
  sound = excitation  *  bank of damped resonators (modes per PART x MATERIAL)
  excitation = contact force pulse (half-sine, 0.05-2.5 ms; narrower = brighter)
               + optional grain noise (iron) + friction (filtered noise + stick-slip
               impulse train) for scrapes, creaks and slips.
  modes      = (frequency, decay tau, gain); ratios per part (free-free bar, plate,
               ring, coil...), frequency scale / decay / pulse width per material
               (TECH §3.2), per-variant detuning (+-2..4 %), random excitation
               position (changes mode gains), higher modes decay faster.
  post       = dry early-reflection cluster 1-5 ms at -20..-30 dB (no tail),
               gentle high shelf, DC removal, leading-silence trim (onset <= 2 ms),
               tail trim + short fade-out, peak normalisation to an event gain table.

All filters are causal (IIR impulse responses applied by FFT convolution) so
nothing rings before the onset. Randomness: numpy PCG64 seeded from CRC32 of
"seed:event:material:variant" -> bit-identical output for the same seed.

Usage: python3 audio/v2/synth_v2.py [--seed N] [--out audio/v2/out]
"""

import argparse
import hashlib
import json
import math
import os
import struct
import zlib

import numpy as np

SR = 48000
DEFAULT_SEED = 20261105
HERE = os.path.dirname(os.path.abspath(__file__))

# --- catalogue ---------------------------------------------------------------

# Events the game already knows (game/scripts/autoload/sfx.gd EVENTS + LOOPS).
GAME_EVENTS = [
    "contact", "bind", "near_shear", "set", "false_set", "counter_rotate",
    "overset", "drop", "stress", "break", "wear", "gate_align",
    "detector_trip", "open",
]
LOOPS = ["tension_resistance", "pick_drag"]
# Additions for session B (lockcore sub-events: pin.serration -> ratchet/spring,
# lever.false_gate -> lever/lever_fall, ring.detent -> ring_detent, ward.scrape -> ward_scrape).
EXTRA_EVENTS = ["spring", "lever", "lever_fall", "ratchet", "ring_detent", "ward_scrape"]

ALL_MATS = ["brass", "steel", "iron", "wood"]
EVENT_MATERIALS = {e: ALL_MATS for e in GAME_EVENTS}
EVENT_MATERIALS.update({
    "spring": ["brass", "steel"],
    "lever": ["brass", "steel", "iron"],
    "lever_fall": ["brass", "steel", "iron"],
    "ratchet": ["steel", "brass", "iron"],
    "ring_detent": ["brass", "steel"],
    "ward_scrape": ["iron", "steel", "brass"],
})
for _l in LOOPS:
    EVENT_MATERIALS[_l] = ALL_MATS

VARIANTS_ONESHOT = 6
VARIANTS_LOOP = 4

# Relative level table: target peak = -1 dBFS + GAIN_DB[event].
# break/open loudest, contact/near_shear quietest (TECH §3.3 priorities + intensities).
GAIN_DB = {
    "break": 0.0, "open": 0.0, "detector_trip": -3.0, "drop": -6.0,
    "set": -4.5, "false_set": -4.5, "overset": -5.0, "counter_rotate": -6.0,
    "lever_fall": -6.0, "ratchet": -6.0, "stress": -7.0, "gate_align": -7.0,
    "lever": -7.0, "ring_detent": -7.0, "bind": -9.0, "ward_scrape": -9.0,
    "spring": -10.0, "wear": -12.0, "contact": -14.0, "near_shear": -18.0,
}
PEAK_REF_DB = -1.0
LOOP_RMS_DB = -18.0      # loops: RMS target (game scales them to -24..-14 dBFS)
LOOP_PEAK_MAX_DB = -1.0

# Expected duration windows (s) per one-shot, used by check_v2.py.
DUR_RANGE = {
    "contact": (0.008, 0.025), "bind": (0.015, 0.045), "near_shear": (0.05, 0.14),
    "set": (0.05, 0.13), "false_set": (0.08, 0.20), "counter_rotate": (0.07, 0.15),
    "overset": (0.025, 0.045), "drop": (0.15, 0.32), "stress": (0.30, 0.52),
    "break": (0.12, 0.22), "wear": (0.20, 0.40), "gate_align": (0.015, 0.040),
    "detector_trip": (0.17, 0.30), "open": (0.40, 0.72), "spring": (0.04, 0.13),
    "lever": (0.02, 0.06), "lever_fall": (0.03, 0.08), "ratchet": (0.02, 0.06),
    "ring_detent": (0.025, 0.07), "ward_scrape": (0.15, 0.27),
}
LOOP_DUR = (1.0, 1.5)

# Material modifiers (TECH §3.2): fs = frequency scale vs brass, tau = base decay of
# the fundamental (s), pulse = contact pulse width (s), grain = excitation noise,
# dexp = how much faster upper modes decay (tau_k = tau * (f1/fk)^dexp).
MATERIALS = {
    "brass": dict(fs=1.00, tau=0.016, pulse=0.30e-3, grain=0.00, dexp=0.50, shelf_db=-2.0),
    "steel": dict(fs=1.95, tau=0.011, pulse=0.11e-3, grain=0.00, dexp=0.40, shelf_db=-3.0),
    "iron":  dict(fs=0.52, tau=0.0085, pulse=0.45e-3, grain=0.45, dexp=0.60, shelf_db=-1.5),
    "wood":  dict(fs=0.19, tau=0.0055, pulse=1.30e-3, grain=0.25, dexp=1.00, shelf_db=-1.0),
}


def _plate_ratios(aspect=2.5, n=6):
    """Simply supported rectangular plate: f_mn ~ (m/a)^2 + n^2 (b = 1)."""
    v = sorted(((m / aspect) ** 2 + k ** 2) for m in range(1, 5) for k in range(1, 3))
    v = np.array(v[:n])
    return list(v / v[0])


def _ring_ratios():
    """In-plane flexural modes of a thin ring: n(n^2-1)/sqrt(n^2+1), n = 2..5."""
    v = np.array([k * (k * k - 1) / math.sqrt(k * k + 1) for k in range(2, 6)])
    return list(v / v[0])


# Parts: f1 = fundamental for brass (Hz), ratios, gains, taumul. fixed = material
# the part is always made of (the pick is spring steel whatever the lock is).
PARTS = {
    "pin":    dict(f1=2800, ratios=[1, 1.83, 2.756, 5.404, 8.933], gains=[1, .35, .6, .35, .18], taumul=1.0),
    "driver": dict(f1=2450, ratios=[1, 1.71, 2.756, 5.404, 8.933], gains=[1, .3, .55, .3, .15], taumul=1.1),
    "spool":  dict(f1=2600, ratios=[1, 1.31, 2.756, 4.10, 5.404], gains=[1, .5, .5, .3, .25], taumul=0.9),
    "plug":   dict(f1=1500, ratios=[1, 1.47, 2.09, 2.756, 3.62, 5.1], gains=[1, .7, .5, .45, .25, .15], taumul=1.6),
    "pick":   dict(f1=3300, ratios=[1, 1.83, 2.94, 4.2, 6.267], gains=[1, .6, .45, .3, .2], taumul=2.6, fixed="steel"),
    "lever":  dict(f1=1900, ratios=_plate_ratios(), gains=[1, .7, .55, .45, .35, .25], taumul=1.3),
    "pawl":   dict(f1=3600, ratios=[1, 2.756, 5.404], gains=[1, .5, .25], taumul=0.7),
    "wheel":  dict(f1=2100, ratios=[1, 1.59, 2.14, 2.65, 3.5], gains=[1, .6, .5, .35, .2], taumul=1.2),
    "ring":   dict(f1=2100, ratios=_ring_ratios(), gains=[1, .55, .3, .15], taumul=1.4),
    "case":   dict(f1=1400, ratios=[1, 1.6, 2.3, 3.1], gains=[1, .6, .4, .25], taumul=0.8),
    "bolt":   dict(f1=1100, ratios=[1, 1.5, 2.756, 4.1, 5.404], gains=[1, .5, .6, .3, .25], taumul=1.4),
    "ward":   dict(f1=2000, ratios=_plate_ratios(3.5), gains=[1, .7, .5, .4, .3, .2], taumul=0.9),
}


# --- DSP primitives ------------------------------------------------------------

def fftconv(a, b):
    n = len(a) + len(b) - 1
    nfft = 1 << (n - 1).bit_length()
    return np.fft.irfft(np.fft.rfft(a, nfft) * np.fft.rfft(b, nfft), nfft)[:n]


def _onepole_ir(fc):
    a = math.exp(-2.0 * math.pi * fc / SR)
    n = int(min(48000, math.ceil(math.log(1e-8) / math.log(a)) + 1))
    return (1.0 - a) * a ** np.arange(n)


def lp(x, fc, order=1):
    for _ in range(order):
        x = fftconv(x, _onepole_ir(fc))[:len(x)]
    return x


def hp(x, fc, order=1):
    for _ in range(order):
        x = x - lp(x, fc)
    return x


def bp(x, lo, hi):
    return hp(lp(x, hi, 2), lo, 2)


def high_shelf(x, fc, gain_db):
    g = 10 ** (gain_db / 20.0)
    return x - (1.0 - g) * hp(x, fc)


def silence(dur):
    return np.zeros(int(round(dur * SR)))


def place(buf, sig, at):
    i = int(round(at * SR))
    if i >= len(buf):
        return buf
    j = min(len(buf), i + len(sig))
    buf[i:j] += sig[:j - i]
    return buf


def norm(x, level_db=0.0):
    m = np.max(np.abs(x))
    return x * (10 ** (level_db / 20.0) / m) if m > 0 else x


def db(x):
    return 20 * math.log10(max(float(x), 1e-12))


# --- excitation ----------------------------------------------------------------

def pulse(width_s, n_total=None):
    w = max(2, int(round(width_s * SR)))
    p = np.sin(np.pi * np.arange(w + 1) / w)  # half-sine, starts and ends at 0
    if n_total:
        out = np.zeros(n_total)
        out[:len(p)] = p[:n_total]
        return out
    return p


def grain_burst(rng, width_s, amount):
    n = max(4, int(width_s * SR * 4))
    env = np.exp(-np.arange(n) / (n / 4.0))
    env[0] = 0.0
    return amount * rng.standard_normal(n) * env


def friction(rng, dur, rate=400.0, jitter=0.6, lo=600.0, hi=6000.0, noise=0.5,
             env=None, rate_end=None):
    """Friction / scrape exciter: band-limited noise + stick-slip impulse train."""
    n = int(round(dur * SR))
    x = bp(rng.standard_normal(n), lo, hi) * noise
    t = 0.0
    while t < dur:
        r = rate if rate_end is None else rate + (rate_end - rate) * (t / dur)
        i = int(t * SR)
        if i < n:
            x[i] += rng.uniform(0.4, 1.0) * (1 if rng.random() < 0.5 else -1) * 3.0
        t += (1.0 / r) * (1.0 + jitter * rng.uniform(-1, 1))
    if env is not None:
        x *= env
    return x


# --- resonator bank --------------------------------------------------------------

def modes(part, mat, rng, fmul=1.0, taumul=1.0, detune=0.03, pos=None):
    P = PARTS[part]
    M = MATERIALS[P.get("fixed", mat)]
    k = len(P["ratios"])
    f1 = P["f1"] * M["fs"] * fmul * (1 + rng.uniform(-0.02, 0.02))
    ratios = np.array(P["ratios"], float) * (1 + rng.uniform(-detune, detune, k))
    ratios[0] = 1.0
    f = f1 * ratios
    pos = rng.uniform(0.08, 0.46) if pos is None else pos
    g = np.array(P["gains"], float) * (0.2 + np.abs(np.sin(np.pi * (np.arange(k) + 1) * pos)))
    tau = M["tau"] * P["taumul"] * taumul * (f1 / f) ** M["dexp"]
    keep = f < 19000
    return f[keep], tau[keep], g[keep]


def bank_ir(f, tau, g, dur):
    n = int(round(min(dur, 7.0 * float(np.max(tau)) + 0.002) * SR))
    t = np.arange(n) / SR
    return np.sum(g[:, None] * np.exp(-t[None, :] / tau[:, None]) *
                  np.sin(2 * np.pi * f[:, None] * t[None, :]), axis=0)


def drive(exc, part, mat, rng, dur, level_db=0.0, fmul=1.0, taumul=1.0, detune=0.03, pos=None):
    f, tau, g = modes(part, mat, rng, fmul, taumul, detune, pos)
    y = fftconv(exc, bank_ir(f, tau, g, dur))
    out = np.zeros(int(round(dur * SR)))
    m = min(len(out), len(y))
    out[:m] = y[:m]
    return norm(out, level_db)


def strike(part, mat, rng, dur, level_db=0.0, pulse_s=None, fmul=1.0, taumul=1.0,
           detune=0.03, pos=None, grain=None):
    M = MATERIALS[PARTS[part].get("fixed", mat)]
    w = (M["pulse"] if pulse_s is None else pulse_s) * rng.uniform(0.85, 1.15)
    e = pulse(w)
    gr = M["grain"] if grain is None else grain
    if gr > 0:
        gb = grain_burst(rng, w, gr)
        e2 = np.zeros(max(len(e), len(gb)))
        e2[:len(e)] += e
        e2[:len(gb)] += gb
        e = e2
    return drive(e, part, mat, rng, dur, level_db, fmul, taumul, detune, pos)


def env_lin(dur, pts):
    """Piecewise-linear envelope; pts = [(t, v), ...]."""
    t = np.arange(int(round(dur * SR))) / SR
    ts, vs = zip(*pts)
    return np.interp(t, ts, vs)


def body_mat(mat):
    """Lock body / plug material for events where the moving part is the steel pick."""
    return mat


# --- events -------------------------------------------------------------------

def ev_contact(mat, rng):
    d = rng.uniform(0.012, 0.016)
    x = strike("pin", mat, rng, d, 0, pulse_s=MATERIALS[mat]["pulse"] * 0.5, taumul=0.45)
    x += strike("pick", mat, rng, d, -9, pulse_s=0.08e-3, taumul=0.2)
    return x * env_lin(d, [(0, 1), (d * 0.6, 0.6), (d, 0)])


def ev_bind(mat, rng):
    d = rng.uniform(0.022, 0.030)
    x = strike("pin", mat, rng, d, -4, taumul=0.5)
    fr = friction(rng, d, rate=rng.uniform(900, 1400), lo=500, hi=7000, noise=0.4,
                  env=env_lin(d, [(0, 0.8), (0.004, 1), (0.012, 0.4), (d, 0)]))
    x += drive(fr, "pin", mat, rng, d, 0, taumul=0.4)
    x += drive(fr, "plug", mat, rng, d, -6, taumul=0.3)
    return x * env_lin(d, [(0, 1), (d * 0.7, 0.7), (d, 0)])


def ev_near_shear(mat, rng):
    d = rng.uniform(0.07, 0.11)
    env = env_lin(d, [(0, 0.55), (0.025, 1.0), (d * 0.6, 0.6), (d, 0)])
    fr = friction(rng, d, rate=rng.uniform(1500, 2200), lo=2500, hi=9000, noise=0.7, env=env)
    x = drive(fr, "pin", mat, rng, d, 0, taumul=0.5)
    x += norm(hp(fr, 3000) * env, -6)
    x += strike("pin", mat, rng, d, -6, pulse_s=0.1e-3, taumul=0.3)  # micro grain = onset
    return x * env_lin(d, [(0, 1), (d * 0.8, 1), (d, 0)])


def _set_click(mat, rng, d, dull=1.0):
    M = MATERIALS[mat]
    part = "spool" if rng.random() < 0.25 else "driver"
    x = strike(part, mat, rng, d, 0, pulse_s=M["pulse"] * 0.8 * dull, taumul=0.9)
    x += strike("pin", mat, rng, d, -6, pulse_s=M["pulse"] * 0.6 * dull, taumul=0.7)
    x += strike("plug", mat, rng, d, -10, pulse_s=M["pulse"] * 1.5, taumul=0.45)
    return x


def ev_set(mat, rng):
    d = rng.uniform(0.075, 0.095)
    x = _set_click(mat, rng, d)
    # short core slip ~60 ms (~2 deg of free play), bright and small
    sd = rng.uniform(0.055, 0.065)
    fr = friction(rng, sd, rate=rng.uniform(1800, 2600), lo=1200, hi=8000, noise=0.5,
                  env=env_lin(sd, [(0, 1), (0.015, 0.5), (sd, 0)]))
    slip = silence(d)
    place(slip, drive(fr, "plug", mat, rng, sd, 0, taumul=0.35), 0.003)
    x += norm(slip, -15)
    return x * env_lin(d, [(0, 1), (d * 0.75, 0.8), (d, 0)])


SEMI_DOWN_4 = 2 ** (-4 / 12)


def ev_false_set(mat, rng):
    # same click family as set (slightly duller pulse), plus the signature:
    # low body (-4 semitones, +20 ms tail) and a second quiet low impulse at +28 ms.
    d = rng.uniform(0.130, 0.150)
    x = _set_click(mat, rng, d, dull=1.15) * 10 ** (-0.5 / 20)
    M = MATERIALS[mat]
    body = strike("plug", mat, rng, d, -5, pulse_s=M["pulse"] * 2.5, fmul=SEMI_DOWN_4, taumul=1.0)
    x += body * env_lin(d, [(0, 1), (0.095, 1), (d, 0)])
    t2 = 0.028 + rng.uniform(-0.0015, 0.0015)
    imp = strike("plug", mat, rng, d - t2, -9, pulse_s=max(M["pulse"] * 3, 0.9e-3),
                 fmul=SEMI_DOWN_4, taumul=0.9)
    # mid-band grain on the second hit so its rhythm survives a phone speaker (>~600 Hz)
    imp += strike("case", "brass" if mat == "wood" else mat, rng, d - t2, -17,
                  pulse_s=0.6e-3, taumul=0.3)
    place(x, imp, t2)
    # deeper free play (~6 deg): longer, lower slip
    sd = rng.uniform(0.10, 0.12)
    fr = friction(rng, sd, rate=rng.uniform(700, 1100), lo=500, hi=4000, noise=0.5,
                  env=env_lin(sd, [(0, 1), (0.04, 0.6), (sd, 0)]))
    slip = silence(d)
    place(slip, drive(fr, "plug", mat, rng, sd, 0, fmul=SEMI_DOWN_4, taumul=0.5), 0.004)
    x += norm(slip, -16)
    return x * env_lin(d, [(0, 1), (d * 0.8, 0.85), (d, 0)])


def ev_counter_rotate(mat, rng):
    d = rng.uniform(0.100, 0.120)
    M = MATERIALS[mat]
    x = strike("plug", mat, rng, d, 0, pulse_s=M["pulse"] * 2, fmul=0.85, taumul=0.5)
    x += strike("pin", mat, rng, d, -8, taumul=0.5)
    cd = d - 0.012
    fr = friction(rng, cd, rate=rng.uniform(170, 220), rate_end=rng.uniform(110, 140),
                  jitter=0.25, lo=300, hi=3000, noise=0.25,
                  env=env_lin(cd, [(0, 1), (cd * 0.7, 0.7), (cd, 0)]))
    creak = silence(d)
    place(creak, drive(fr, "plug", mat, rng, cd, 0, fmul=0.8, taumul=0.6), 0.010)
    x += norm(creak, -5)
    return x * env_lin(d, [(0, 1), (d * 0.85, 0.8), (d, 0)])


def ev_overset(mat, rng):
    d = rng.uniform(0.032, 0.038)
    x = strike("plug", mat, rng, d, 0, pulse_s=rng.uniform(1.8e-3, 2.5e-3), fmul=0.6, taumul=0.22)
    x += strike("case", mat, rng, d, -4, pulse_s=2.0e-3, fmul=0.8, taumul=0.25)
    x += strike("pin", mat, rng, d, -14, pulse_s=1.2e-3, taumul=0.2)
    return x * env_lin(d, [(0, 1), (0.012, 0.8), (d, 0)])  # no ring


def ev_drop(mat, rng):
    d = rng.uniform(0.17, 0.29)
    x = silence(d)
    n_hits = int(rng.integers(3, 7))
    t = 0.0
    for i in range(n_hits):
        lvl = -6.0 * i / max(1, n_hits - 1) + rng.uniform(-1.5, 0)
        if i == 0:
            lvl = 0.0
        part = ["pin", "driver", "spool"][int(rng.integers(0, 3))]
        hd = min(0.05, d - t)
        if hd <= 0.004:
            break
        place(x, strike(part, mat, rng, hd, lvl, detune=0.04, taumul=0.8), t)
        if rng.random() < 0.7:
            place(x, _spring_buzz(mat, rng, min(0.04, hd), lvl - 9), t + rng.uniform(0.001, 0.006))
        t += 0.040 * rng.uniform(0.8, 1.2)
        if t >= d - 0.01:
            break
    # springs keep rattling while the stack settles, up to the end
    st = min(t, d - 0.05)
    place(x, _spring_buzz(mat, rng, d - st, -13, clash_rate=rng.uniform(120, 200)) *
          env_lin(d - st, [(0, 1), (d - st, 0.15)]), st)
    return x * env_lin(d, [(0, 1), (d * 0.85, 0.9), (d, 0)])


def _spring_buzz(mat, rng, d, level_db, clash_rate=None):
    """Coil spring: many close, short modes + coil-clash amplitude modulation."""
    fs = MATERIALS[mat]["fs"] ** 0.3
    nm = 22
    f = np.sort(rng.uniform(1500, 6500, nm)) * fs
    tau = rng.uniform(0.004, 0.012, nm)
    g = rng.uniform(0.3, 1.0, nm)
    exc = np.zeros(int(0.004 * SR))
    exc[:len(pulse(0.1e-3))] += pulse(0.1e-3)
    exc += bp(rng.standard_normal(len(exc)), 1000, 9000) * np.exp(-np.arange(len(exc)) / 40.0) * 0.6
    exc[0] = 0.0
    y = fftconv(exc, bank_ir(f, tau, g, d))[:int(round(d * SR))]
    y = np.pad(y, (0, max(0, int(round(d * SR)) - len(y))))
    cr = clash_rate if clash_rate else rng.uniform(250, 420)
    tt = np.arange(len(y)) / SR
    am = 0.55 + 0.45 * np.abs(np.sin(np.pi * cr * tt + rng.uniform(0, np.pi)))
    am[: int(0.0015 * SR)] = 1.0  # keep the attack intact
    return norm(y * am, level_db)


def ev_stress(mat, rng):
    d = rng.uniform(0.32, 0.48)
    n = int(round(d * SR))
    t = np.arange(n) / SR
    f, tau, g = modes("pick", "steel", rng, fmul=rng.uniform(0.95, 1.05), detune=0.03)
    glide = rng.uniform(0.04, 0.08)  # pitch rises with stress
    s = (t / d) ** 1.5
    amp = 10 ** ((-16 + 16 * (t / d) ** 0.8) / 20.0)
    am = 0.6 + 0.4 * np.abs(lp(rng.standard_normal(n), 35, 2)) / 0.05
    am = np.clip(am, 0.3, 1.6)
    sing = np.zeros(n)
    for fk, gk in zip(f, g):
        ph = 2 * np.pi * np.cumsum(fk * (1 + glide * s)) / SR + rng.uniform(0, 2 * np.pi)
        sing += gk * np.sin(ph)
    sing *= amp * am * env_lin(d, [(0, 0), (0.0003, 1), (d - 0.04, 1), (d, 0)])
    x = norm(sing, -2)
    # stick-slip ticks every ~70 ms (TECH 3.3), first one at 0 = onset
    tt = 0.0
    while tt < d - 0.03:
        lvl = -7 + 5 * (tt / d)
        place(x, strike("pick", mat, rng, 0.03, lvl, pulse_s=0.1e-3, taumul=0.25), tt)
        place(x, strike("plug", body_mat(mat), rng, 0.03, lvl - 8, taumul=0.3), tt)
        tt += 0.070 * rng.uniform(0.85, 1.15)
    fr = friction(rng, d, rate=900, lo=2000, hi=9000, noise=0.6,
                  env=env_lin(d, [(0, 0.3), (d - 0.04, 1), (d, 0)]))
    x += drive(fr, "pick", mat, rng, d, -14, taumul=0.5)
    return x * env_lin(d, [(0, 1), (d - 0.03, 1), (d, 0)])


def ev_break(mat, rng):
    d = rng.uniform(0.14, 0.19)
    x = silence(d)
    cd = 0.040
    crack = strike("pick", mat, rng, cd, -2, pulse_s=0.05e-3, taumul=0.15)
    nz = rng.standard_normal(int(cd * SR)) * np.exp(-np.arange(int(cd * SR)) / (0.014 * SR))
    nz[0] = 0.0
    crack += norm(hp(nz, 1200), 0)
    crack += strike("plug", body_mat(mat), rng, cd, -4, pulse_s=0.2e-3, taumul=0.5)
    for tm in sorted(rng.uniform(0.002, 0.012, 3)):  # splinters of the same fracture
        place(crack, strike("pick", mat, rng, cd - tm, -5, pulse_s=0.06e-3, fmul=rng.uniform(1.1, 1.5),
                            taumul=0.15), tm)
    crack *= env_lin(cd, [(0, 1), (0.02, 0.6), (cd, 0)])
    place(x, crack, 0)
    # fragment bounces: decreasing intervals and levels (~120 ms)
    t = 0.045 + rng.uniform(0, 0.008)
    gap = rng.uniform(0.035, 0.045)
    lvl = -11.0
    while t < d - 0.012:
        place(x, strike("pick", mat, rng, 0.02, lvl, pulse_s=0.06e-3, fmul=rng.uniform(1.6, 2.2),
                        taumul=0.25), t)
        place(x, strike("case", body_mat(mat), rng, 0.02, lvl - 10, pulse_s=0.3e-3, taumul=0.2), t)
        t += gap
        gap *= 0.65
        lvl -= 4.0
        if gap < 0.006:
            break
    return x * env_lin(d, [(0, 1), (d * 0.9, 1), (d, 0)])


def ev_wear(mat, rng):
    d = rng.uniform(0.24, 0.34)
    env = env_lin(d, [(0, 0.7), (0.03, 1), (d * 0.55, 0.8), (d * 0.6, 0.5), (d * 0.7, 0.9), (d, 0)])
    fr = friction(rng, d, rate=rng.uniform(350, 600), jitter=0.3, lo=1500, hi=7000, noise=0.9, env=env)
    x = drive(fr, "pick", mat, rng, d, 0, taumul=0.12)
    x += norm(bp(fr, 2000, 8000), -4)
    x += strike("pick", mat, rng, d, -4, pulse_s=0.1e-3, taumul=0.1)
    return x * env_lin(d, [(0, 1), (d * 0.85, 1), (d, 0)])


def ev_gate_align(mat, rng):
    d = rng.uniform(0.020, 0.026)
    x = strike("lever", mat, rng, d, 0, pulse_s=rng.uniform(0.8e-3, 1.1e-3), taumul=0.35)
    x += strike("case", mat, rng, d, -8, pulse_s=1.0e-3, taumul=0.3)
    return x * env_lin(d, [(0, 1), (d * 0.6, 0.7), (d, 0)])


def _clack(mat, rng, d, lvl):
    x = strike("lever", mat, rng, d, lvl, pulse_s=MATERIALS[mat]["pulse"] * 1.2, taumul=0.6)
    x += strike("case", mat, rng, d, lvl - 5, pulse_s=0.8e-3, taumul=0.5)
    place(x, _spring_buzz(mat, rng, min(d, 0.03), lvl - 14), 0)
    return x


def ev_detector_trip(mat, rng):
    d = rng.uniform(0.20, 0.24)
    x = silence(d)
    place(x, _clack(mat, rng, 0.06, 0), 0)
    place(x, _clack(mat, rng, d - 0.14, -1), 0.140 + rng.uniform(-0.004, 0.004))
    return x * env_lin(d, [(0, 1), (d * 0.85, 0.9), (d, 0)])


def ev_open(mat, rng):
    d = rng.uniform(0.45, 0.68)
    x = silence(d)
    M = MATERIALS[mat]
    place(x, strike("plug", mat, rng, 0.04, -6, taumul=0.5) + strike("pin", mat, rng, 0.04, -12, taumul=0.5), 0)
    turn = rng.uniform(0.24, 0.30)
    fr = friction(rng, turn, rate=rng.uniform(500, 800), lo=300, hi=4000, noise=0.4,
                  env=env_lin(turn, [(0, 0.6), (turn * 0.8, 1), (turn, 0.2)]))
    place(x, drive(fr, "plug", mat, rng, turn, -17, taumul=0.5), 0.004)
    for _ in range(2):
        place(x, strike("pin", mat, rng, 0.02, -18, taumul=0.4), rng.uniform(0.05, turn - 0.03))
    cam = turn + rng.uniform(0.0, 0.02)
    place(x, strike("bolt", mat, rng, 0.04, -9, pulse_s=M["pulse"] * 1.5, fmul=1.3, taumul=0.5), cam)
    slide = rng.uniform(0.08, 0.12)
    fr2 = friction(rng, slide, rate=rng.uniform(300, 500), lo=200, hi=3000, noise=0.4,
                   env=env_lin(slide, [(0, 0.5), (slide * 0.7, 1), (slide, 0.3)]))
    place(x, drive(fr2, "bolt", mat, rng, slide, -15, taumul=0.5), cam + 0.005)
    hit = min(cam + slide + 0.005, d - 0.09)
    tail = d - hit
    place(x, strike("bolt", mat, rng, tail, 0, pulse_s=M["pulse"] * 2.5, taumul=1.0), hit)
    place(x, strike("case", mat, rng, tail, -4, pulse_s=1.2e-3, taumul=1.2), hit)
    place(x, strike("bolt", mat, rng, tail - 0.03, -15, pulse_s=M["pulse"] * 2, taumul=0.5), hit + 0.03)
    return x * env_lin(d, [(0, 1), (d - 0.04, 1), (d, 0)])


def ev_spring(mat, rng):
    d = rng.uniform(0.06, 0.11)
    x = _spring_buzz(mat, rng, d, 0, clash_rate=rng.uniform(220, 380))
    x += strike("pin", mat, rng, d, -8, taumul=0.4)
    return x * env_lin(d, [(0, 1), (d * 0.5, 0.6), (d, 0)])


def ev_lever(mat, rng):
    d = rng.uniform(0.028, 0.040)
    x = strike("lever", mat, rng, d, 0, pulse_s=MATERIALS[mat]["pulse"] * 0.9, taumul=0.6)
    x += strike("pick", mat, rng, d, -12, pulse_s=0.1e-3, taumul=0.2)
    place(x, _spring_buzz(mat, rng, min(d, 0.025), -18), 0)
    return x * env_lin(d, [(0, 1), (d * 0.7, 0.7), (d, 0)])


def ev_lever_fall(mat, rng):
    d = rng.uniform(0.045, 0.065)
    M = MATERIALS[mat]
    x = strike("lever", mat, rng, d, 0, pulse_s=M["pulse"] * 1.6, taumul=0.7)
    x += strike("case", mat, rng, d, -8, pulse_s=0.8e-3, taumul=0.4)
    b = rng.uniform(0.012, 0.018)
    place(x, strike("lever", mat, rng, d - b, -12, pulse_s=M["pulse"] * 1.6, taumul=0.5), b)
    return x * env_lin(d, [(0, 1), (d * 0.75, 0.8), (d, 0)])


def ev_ratchet(mat, rng):
    d = rng.uniform(0.030, 0.042)
    x = strike("pawl", mat, rng, d, 0, pulse_s=MATERIALS[mat]["pulse"] * 0.7, taumul=0.7)
    x += strike("wheel", mat, rng, d, -8, taumul=0.5)
    place(x, _spring_buzz(mat, rng, min(d, 0.02), -18), 0)
    return x * env_lin(d, [(0, 1), (d * 0.7, 0.7), (d, 0)])


def ev_ring_detent(mat, rng):
    d = rng.uniform(0.035, 0.050)
    x = strike("ring", mat, rng, d, 0, pulse_s=MATERIALS[mat]["pulse"] * 1.1, taumul=0.8)
    x += strike("pin", mat, rng, d, -6, fmul=1.4, taumul=0.4)
    return x * env_lin(d, [(0, 1), (d * 0.7, 0.7), (d, 0)])


def ev_ward_scrape(mat, rng):
    d = rng.uniform(0.16, 0.25)
    env = env_lin(d, [(0, 0.8), (0.02, 1), (d * 0.7, 0.8), (d, 0)])
    fr = friction(rng, d, rate=rng.uniform(250, 450), jitter=0.7, lo=400, hi=6000, noise=0.5, env=env)
    x = drive(fr, "ward", mat, rng, d, 0, taumul=0.4)
    x += drive(fr, "pick", mat, rng, d, -6, taumul=0.3)
    x += strike("ward", mat, rng, d, -2, taumul=0.4)
    place(x, strike("ward", mat, rng, 0.03, -6, taumul=0.5), d - 0.035)  # small catch at the end
    return x * env_lin(d, [(0, 1), (d * 0.9, 1), (d, 0)])


EVENT_FNS = {k[3:]: v for k, v in list(globals().items()) if k.startswith("ev_")}


# --- loops -------------------------------------------------------------------

def loop_texture(loop, mat, rng, n):
    dur = n / SR
    if loop == "tension_resistance":
        fc = {"brass": 450, "steel": 650, "iron": 380, "wood": 250}[mat]
        base = lp(rng.standard_normal(n), fc, 2)
        slow = 0.65 + 0.35 * np.tanh(lp(rng.standard_normal(n), 6, 2) * 60)
        fr = friction(rng, dur, rate=rng.uniform(60, 110), jitter=0.7, lo=150, hi=fc * 3, noise=0.0)
        fr *= 0.15
        x = norm(base * slow, 0) + drive(fr, "plug", mat, rng, dur, -8, fmul=0.5, taumul=0.5) \
            + drive(base * slow, "plug", mat, rng, dur, -10, fmul=0.45, taumul=0.3)
    else:  # pick_drag
        lo, hi = {"brass": (900, 4500), "steel": (1500, 8000), "iron": (600, 3500), "wood": (300, 2000)}[mat]
        base = bp(rng.standard_normal(n), lo, hi)
        slow = 0.6 + 0.4 * np.tanh(lp(rng.standard_normal(n), 9, 2) * 50)
        fr = friction(rng, dur, rate=rng.uniform(25, 40), jitter=0.9, lo=lo, hi=hi, noise=0.0)
        x = norm(base * slow, 0) + drive(fr, "pin", mat, rng, dur, -6, taumul=0.4) \
            + drive(base * slow, "pick", mat, rng, dur, -9, taumul=0.25)
    return x


def make_loop(loop, mat, rng):
    L = int(round(rng.uniform(1.10, 1.40) * SR))
    X = int(0.12 * SR)       # crossfade length
    pre = int(0.20 * SR)     # pre-roll (filter settling), discarded
    y = loop_texture(loop, mat, rng, pre + L + X)
    y = post_common(y, mat)[pre:]
    out = y[:L].copy()
    w = np.sin(0.5 * np.pi * (np.arange(X) + 0.5) / X)  # equal power for uncorrelated noise
    out[:X] = y[:X] * w + y[L:L + X] * np.sqrt(1 - w * w)
    out -= np.mean(out)       # the loop is periodic: a constant offset is not a step
    rms = math.sqrt(float(np.mean(out ** 2)))
    out *= 10 ** (LOOP_RMS_DB / 20) / rms
    pk = np.max(np.abs(out))
    lim = 10 ** ((LOOP_PEAK_MAX_DB - 0.3) / 20)
    if pk > lim:
        out *= lim / pk
    return out


# --- post-processing ---------------------------------------------------------------

ROOM_TAPS = [(0.0013, -22.0), (0.0021, -25.0), (0.0034, -27.0), (0.0047, -30.0)]


def room(x, rng=None):
    n = int(0.0055 * SR)
    h = np.zeros(n)
    h[0] = 1.0
    for t, g in ROOM_TAPS:
        i = int(round(t * SR))
        # each reflection slightly low-passed (3-tap)
        h[i - 1:i + 2] += 10 ** (g / 20) * np.array([0.25, 0.5, 0.25])
    return fftconv(x, h)[:len(x)]


def post_common(x, mat):
    x = room(x)
    x = hp(x, 25.0, 2)
    x = high_shelf(x, 7000.0, MATERIALS[mat]["shelf_db"])
    return x


def finish_oneshot(x, mat, event):
    x = post_common(x, mat)
    pk = np.max(np.abs(x))
    # leading trim: first sample above -60 dB of peak
    i0 = int(np.argmax(np.abs(x) > pk * 1e-3))
    x = x[i0:]
    nf = 12  # 0.25 ms fade-in (<= 0.3 ms)
    x[:nf] *= np.sin(0.5 * np.pi * np.arange(nf) / nf) ** 2
    # tail trim at -60 dB, 3 ms fade-out
    above = np.nonzero(np.abs(x) > pk * 1e-3)[0]
    end = min(len(x), int(above[-1]) + int(0.003 * SR))
    x = x[:end]
    nfo = min(int(0.003 * SR), len(x) // 4)
    x[-nfo:] *= np.cos(0.5 * np.pi * np.arange(1, nfo + 1) / nfo) ** 2
    # DC removal without edge steps: subtract a raised-cosine bump with the same mean
    bump = np.sin(np.pi * (np.arange(len(x)) + 0.5) / len(x)) ** 2
    x = x - bump * (np.mean(x) / np.mean(bump))
    return norm(x, PEAK_REF_DB + GAIN_DB[event])


def onset_samples(x, rel_db=-30.0):
    pk = np.max(np.abs(x))
    return int(np.argmax(np.abs(x) >= pk * 10 ** (rel_db / 20)))


# --- WAV I/O ---------------------------------------------------------------------

def to_int16(x):
    return np.clip(np.round(x * 32767.0), -32767, 32767).astype("<i2")


def wav_bytes(pcm, loop=False):
    data = pcm.tobytes()
    fmt = struct.pack("<HHIIHH", 1, 1, SR, SR * 2, 2, 16)
    chunks = b"fmt " + struct.pack("<I", len(fmt)) + fmt
    chunks += b"data" + struct.pack("<I", len(data)) + data
    if len(data) % 2:
        chunks += b"\0"
    if loop:
        smpl = struct.pack("<9I", 0, 0, int(round(1e9 / SR)), 60, 0, 0, 0, 1, 0)
        smpl += struct.pack("<6I", 0, 0, 0, len(pcm) - 1, 0, 0)  # forward loop, whole file
        chunks += b"smpl" + struct.pack("<I", len(smpl)) + smpl
    return b"RIFF" + struct.pack("<I", 4 + len(chunks)) + b"WAVE" + chunks


def rng_for(seed, *parts):
    key = ":".join([str(seed)] + [str(p) for p in parts])
    return np.random.default_rng(zlib.crc32(key.encode()))


def gated_rms_db(x):
    """'LUFS-ish' loudness for transients: max RMS over a sliding 25 ms window
    (hop 2.5 ms) after a 100 Hz high-pass; files shorter than 25 ms count as
    their energy spread over 25 ms (short sounds are perceived quieter)."""
    y = hp(np.asarray(x, float), 100.0)
    b, hop = int(0.025 * SR), int(0.0025 * SR)
    c = np.concatenate([[0.0], np.cumsum(y * y)])
    if len(y) <= b:
        e = c[-1]
    else:
        idx = np.arange(0, len(y) - b + 1, hop)
        e = float(np.max(c[idx + b] - c[idx]))
    return 10 * math.log10(max(e / b, 1e-20))


# --- main -----------------------------------------------------------------------

def render_all(seed, out_dir, verbose=True):
    sfx_dir = os.path.join(out_dir, "sfx")
    manifest = {
        "schema": "lockwright.sfx/2", "generator": "audio/v2/synth_v2.py", "seed": seed,
        "sample_rate": SR, "bit_depth": 16, "channels": 1,
        "peak_ref_dbfs": PEAK_REF_DB, "gain_db": GAIN_DB, "loop_rms_dbfs": LOOP_RMS_DB,
        "game_events": GAME_EVENTS, "loops": LOOPS, "extra_events": EXTRA_EVENTS,
        "files": [],
    }
    demo = {}
    for event in GAME_EVENTS + EXTRA_EVENTS + LOOPS:
        is_loop = event in LOOPS
        os.makedirs(os.path.join(sfx_dir, event), exist_ok=True)
        for mat in EVENT_MATERIALS[event]:
            nv = VARIANTS_LOOP if is_loop else VARIANTS_ONESHOT
            for v in range(1, nv + 1):
                rng = rng_for(seed, event, mat, v)
                if is_loop:
                    x = make_loop(event, mat, rng)
                else:
                    x = finish_oneshot(EVENT_FNS[event](mat, rng), mat, event)
                pcm = to_int16(x)
                xf = pcm.astype(float) / 32767.0
                on = onset_samples(xf)
                if not is_loop and on > 96:
                    raise SystemExit(f"onset too late: {event}/{mat}_{v}: {on} samples")
                blob = wav_bytes(pcm, loop=is_loop)
                rel = f"{event}/{mat}_{v}.wav"
                with open(os.path.join(sfx_dir, rel), "wb") as fh:
                    fh.write(blob)
                manifest["files"].append({
                    "file": rel, "event": event, "material": mat, "variant": v,
                    "loop": is_loop, "sha256": hashlib.sha256(blob).hexdigest(),
                    "samples": len(pcm), "duration_s": round(len(pcm) / SR, 4),
                    "peak_dbfs": round(db(np.max(np.abs(xf))), 2),
                    "onset_ms": round(on / SR * 1000, 3),
                    "rms_db": round(gated_rms_db(xf), 2),
                    **({"loop_start": 0, "loop_end": len(pcm) - 1} if is_loop else {}),
                })
                if v == 1 or (event in ("set", "false_set") and mat == "brass"):
                    demo[(event, mat, v)] = xf
    with open(os.path.join(out_dir, "manifest.json"), "w") as fh:
        json.dump(manifest, fh, indent=1, sort_keys=False)

    # demo: every event x material (variant 1), 300 ms gaps; loops: 1.0 s excerpt
    gap = silence(0.3)
    parts = []
    for event in GAME_EVENTS + EXTRA_EVENTS + LOOPS:
        for mat in EVENT_MATERIALS[event]:
            x = demo[(event, mat, 1)]
            if event in LOOPS:
                x = x[:SR] * env_lin(1.0, [(0, 0), (0.02, 1), (0.95, 1), (1.0, 0)])
            parts += [x, gap]
    _write_plain(os.path.join(out_dir, "demo_all.wav"), np.concatenate(parts))
    ab = []
    for v in range(1, 7):
        ab += [demo[("set", "brass", v)], silence(0.7), demo[("false_set", "brass", v)], silence(0.9)]
    _write_plain(os.path.join(out_dir, "ab_set_false_set.wav"), np.concatenate(ab))
    if verbose:
        n = len(manifest["files"])
        size = sum(os.path.getsize(os.path.join(sfx_dir, f["file"])) for f in manifest["files"])
        print(f"synth_v2: wrote {n} files to {sfx_dir} ({size / 1e6:.2f} MB), seed {seed}")
    return manifest


def _write_plain(path, x):
    with open(path, "wb") as fh:
        fh.write(wav_bytes(to_int16(x)))


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--seed", type=int, default=DEFAULT_SEED)
    ap.add_argument("--out", default=os.path.join(HERE, "out"))
    a = ap.parse_args()
    render_all(a.seed, os.path.abspath(a.out))


if __name__ == "__main__":
    main()
