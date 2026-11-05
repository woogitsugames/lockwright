#!/usr/bin/env python3
"""Lockwright SFX v2, part 2: ambience loops, diegetic UI one-shots and rewards.

Same approach as synth_v2.py (modal resonators + friction / noise exciters, numpy
only, own synthesis, no samples) and the same determinism: every file has its own
PCG64 stream seeded from CRC32("seed:world:name:variant").

Ambience loops are built *circularly*: every layer is periodic in the loop length
(noise shaped in the frequency domain of one period, events placed modulo the
length, reverb by circular convolution), so the wrap is seamless by construction,
including reverb tails that cross the seam. The loop is rendered at 48 kHz and
resampled to 32 kHz by spectrum truncation (exact for a periodic signal, ideal
anti-alias low-pass at 16 kHz), then normalised to an integrated-loudness target
and TPDF-dithered to 16 bit.

UI and reward one-shots are 48 kHz / 16-bit / mono like the lock events and are
normalised to a momentary-loudness (EBU M, 400 ms) target; the motif uses its
integrated loudness. Targets: TARGETS below (also written to the manifest and
documented in README.md, "Miks").

Called from synth_v2.render_all(); can also be run alone:
  python3 audio/v2/world.py [--seed N] [--out audio/v2/out]
"""

import argparse
import hashlib
import math
import os
import struct
import sys

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import synth_v2 as S  # noqa: E402
import loudness as L  # noqa: E402

SR = S.SR
AMB_SR = 32000
AMB_DUR = 30.0  # s; integer seconds so the 1 Hz clock and the 4 Hz timer stay in phase over the wrap

# --- catalogue -------------------------------------------------------------------

# Loudness targets per category (LUFS / LU / dBTP). "measure" = what the file is
# normalised on: I = integrated (circular for loops), M = max momentary (400 ms).
TARGETS = {
    "ambience": dict(measure="I", target=-35.0, tol=1.0, s_max=-31.0, m_max=-30.0, tp_max=-12.0),
    "ui": dict(measure="M", target=-32.0, tol=1.0, tp_max=-6.0),
    "ui_phone": dict(measure="M", target=-29.0, tol=1.0, tp_max=-6.0),
    "reward": dict(measure="M", target=-25.0, tol=1.0, tp_max=-3.0),
    "reward_motif": dict(measure="I", target=-27.5, tol=1.0, m_max=-24.0, tp_max=-3.0),
}

AMBIENCE = ["stairwell", "workshop", "night_timer", "rain_window"]

# name: (target key, variants, (min, max) duration in s)
UI = {
    "tool_roll_open": ("ui", 3, (0.55, 1.00)),
    "tool_roll_close": ("ui", 3, (0.40, 0.90)),
    "paper_turn": ("ui", 3, (0.30, 0.60)),
    "paper_slide": ("ui", 3, (0.18, 0.45)),
    "chalk_stroke": ("ui", 4, (0.10, 0.35)),
    "notebook_open": ("ui", 3, (0.25, 0.55)),
    "notebook_close": ("ui", 3, (0.12, 0.40)),
    "pencil_tick": ("ui", 3, (0.08, 0.25)),
    "job_phone": ("ui_phone", 3, (1.80, 2.60)),
    "drawer_open": ("ui", 3, (0.45, 0.95)),
    "drawer_close": ("ui", 3, (0.35, 0.75)),
}
REWARDS = {
    "door_open": ("reward", 3, (1.30, 2.40)),
    "thanks": ("reward_motif", 3, (2.00, 3.20)),
    "coins": ("reward", 3, (0.45, 1.60)),
}
UI_ONSET_MAX = 240   # samples (5 ms): UI answers a tap, so it starts with its contact transient
REWARD_LEAD_MAX = 240

# --- helpers ------------------------------------------------------------------------


def U(rng, a, b):
    return float(rng.uniform(a, b))


def rms(x):
    return math.sqrt(float(np.mean(np.asarray(x) ** 2)) + 1e-30)


def rms_norm(x, level_db=0.0):
    return x * (10 ** (level_db / 20.0) / rms(x))


def freqs(n):
    return np.fft.rfftfreq(n, 1.0 / SR)


def mag_lp(f, fc, order=1):
    return 1.0 / np.sqrt(1.0 + (f / fc) ** (2 * order))


def mag_hp(f, fc, order=1):
    r = (np.maximum(f, 1e-9) / fc) ** (2 * order)
    return np.sqrt(r / (1.0 + r))


def circ_filter(x, mag):
    n = len(x)
    return np.fft.irfft(np.fft.rfft(x) * mag(freqs(n)), n)


def spec_noise(rng, n, mag):
    """Periodic (loopable) coloured noise of length n."""
    return circ_filter(rng.standard_normal(n), mag)


def slow_mod(rng, n, fc):
    """Smooth periodic random modulation, unit std."""
    m = spec_noise(rng, n, lambda f: mag_lp(f, fc, 4) * (f > 0))
    return m / (np.std(m) + 1e-12)


def cplace(buf, sig, at_s):
    n = len(buf)
    i = int(round(at_s * SR)) % n
    m = min(len(sig), n)
    k = min(m, n - i)
    buf[i:i + k] += sig[:k]
    if m > k:
        buf[:m - k] += sig[k:m]
    return buf


def circ_conv(x, ir):
    n = len(x)
    return np.fft.irfft(np.fft.rfft(x) * np.fft.rfft(ir, n), n)


def modal(rng, f, tau, g, dur, exc, detune=0.02):
    f = np.asarray(f, float) * (1 + rng.uniform(-detune, detune, len(f)))
    tau = np.asarray(tau, float)
    g = np.asarray(g, float)
    keep = f < 18000
    y = S.fftconv(exc, S.bank_ir(f[keep], tau[keep], g[keep], dur))
    n = int(round(dur * SR))
    out = np.zeros(n)
    out[:min(n, len(y))] = y[:n]
    return out


def hit(rng, f, tau, g, dur, pulse_s, grain=0.0, detune=0.02, level_db=0.0):
    w = pulse_s * U(rng, 0.85, 1.15)
    e = S.pulse(w)
    if grain > 0:
        gb = S.grain_burst(rng, w, grain)
        e2 = np.zeros(max(len(e), len(gb)))
        e2[:len(e)] += e
        e2[:len(gb)] += gb
        e = e2
    return S.norm(modal(rng, f, tau, g, dur, e, detune), level_db)


def burst(rng, dur, decay, lo=None, hi=None, level_db=0.0):
    """Short decaying noise burst (contact of soft materials: leather, paper, a foot)."""
    n = int(round(dur * SR))
    x = rng.standard_normal(n) * np.exp(-np.arange(n) / (decay * SR))
    x[0] = 0.0
    if hi:
        x = S.lp(x, hi, 2)
    if lo:
        x = S.hp(x, lo, 2)
    return S.norm(x, level_db)


def crackle(rng, dur, rate, lo, hi, env=None):
    """Sparse random clicks (paper fibres, chalk grains)."""
    n = int(round(dur * SR))
    x = np.zeros(n)
    k = rng.poisson(rate * dur)
    idx = rng.integers(0, n, k)
    np.add.at(x, idx, rng.exponential(1.0, k) * rng.choice([-1.0, 1.0], k))
    x = S.bp(x, lo, hi)
    return x * env if env is not None else x


def reverb_ir(rng, rt60, length, pre=0.008, hi_rt=0.5, lo_rt=1.15, early=()):
    """Synthetic diffuse tail (three bands, highs decay faster) + optional early taps."""
    n = int(round(length * SR))
    t = np.arange(n) / SR
    nz = rng.standard_normal(n)
    lo = S.lp(nz, 450.0, 2)
    hi = S.hp(nz, 2800.0, 2)
    mid = nz - lo - hi
    ir = (lo * np.exp(-6.91 * t / (rt60 * lo_rt)) + mid * np.exp(-6.91 * t / rt60)
          + hi * np.exp(-6.91 * t / (rt60 * hi_rt)))
    ip = int(pre * SR)
    ir[:ip] = 0.0
    r = int(0.004 * SR)
    ir[ip:ip + r] *= np.linspace(0, 1, r)
    ir /= math.sqrt(float(np.sum(ir ** 2)))
    for dt, gdb in early:
        ir[int(dt * SR)] += 10 ** (gdb / 20.0)
    return ir


def lin_reverb(x, ir, wet_db, dry_db=0.0):
    y = S.fftconv(x, ir)
    out = np.zeros(len(y))
    out[:len(x)] += x * 10 ** (dry_db / 20.0)
    return out + y * 10 ** (wet_db / 20.0)


def note_hz(name):
    names = {"C": -9, "C#": -8, "D": -7, "D#": -6, "E": -5, "F": -4, "F#": -3, "G": -2,
             "G#": -1, "A": 0, "A#": 1, "B": 2}
    pc, octv = name[:-1], int(name[-1])
    return 440.0 * 2 ** ((names[pc] + 12 * (octv - 4)) / 12.0)


def tone(rng, f0, dur, ratios, gains, tau1, pulse_s, dexp=1.0, level_db=0.0):
    """Tuned modal tone (mallet bar / plucked tine); upper partials decay faster."""
    f = f0 * np.asarray(ratios, float) * (1 + rng.uniform(-0.002, 0.002, len(ratios)))
    f[0] = f0
    tau = tau1 * (f0 / f) ** dexp
    return hit(rng, f, tau, gains, dur, pulse_s, detune=0.0, level_db=level_db)


BAR = ([1.0, 3.93, 9.0], [1.0, 0.18, 0.04])          # tuned wooden/metal bar, soft mallet
TINE = ([1.0, 6.27, 17.55], [1.0, 0.10, 0.025])      # cantilever tine (pluck)
WOOD_TABLE = ([182, 305, 470, 760, 1180], [0.022, 0.016, 0.011, 0.007, 0.005], [1, .7, .5, .32, .2])


def table_knock(rng, dur, pulse_s=1.5e-3, level_db=0.0, fmul=1.0, grain=0.2):
    f, tau, g = WOOD_TABLE
    return hit(rng, np.array(f) * fmul * U(rng, 0.95, 1.05), tau, g, dur, pulse_s, grain=grain, level_db=level_db)


def drive(exc, rng, f, tau, g, dur, level_db=0.0):
    return S.norm(modal(rng, f, tau, g, dur, exc), level_db)


# --- ambience layers ----------------------------------------------------------------


def footstep(rng):
    d = 0.16
    x = burst(rng, d, 0.007, hi=380.0, level_db=0.0)
    f1 = U(rng, 650, 900)
    x += hit(rng, f1 * np.array([1, 1.71, 2.62, 3.9]), [0.006, 0.0045, 0.003, 0.002], [1, .6, .4, .2], d,
             1.4e-3, grain=0.3, level_db=-8)
    sc = S.friction(rng, 0.05, rate=U(rng, 140, 260), jitter=0.8, lo=400, hi=2500, noise=0.6,
                    env=S.env_lin(0.05, [(0, 0), (0.01, 1), (0.05, 0)]))
    S.place(x, S.norm(sc, -16), U(rng, 0.015, 0.03))
    return x


def door_far(rng):
    d = 0.7
    x = hit(rng, [72, 118, 176, 251, 390], [0.12, 0.09, 0.07, 0.05, 0.03], [1, .8, .6, .4, .25], d,
            5e-3, grain=0.3, level_db=0)
    S.place(x, S.strike("bolt", "steel", rng, 0.08, -9), U(rng, 0.008, 0.015))
    S.place(x, S.strike("case", "iron", rng, 0.06, -14), U(rng, 0.02, 0.03))
    return x


def amb_stairwell(rng, n):
    tone_ = spec_noise(rng, n, lambda f: mag_lp(f, 220, 2) * mag_hp(f, 45, 2))
    tone_ *= 1 + 0.18 * slow_mod(rng, n, 0.08)
    traffic = spec_noise(rng, n, lambda f: mag_lp(f, 400, 2) * mag_hp(f, 60, 1))
    traffic *= np.clip(0.6 + 0.4 * slow_mod(rng, n, 0.05), 0.1, None)
    far = np.zeros(n)
    groups = [U(rng, 1.0, 6.0), U(rng, 17.0, 22.0)]
    for g0 in groups:
        steps = int(rng.integers(6, 11))
        iv = U(rng, 0.52, 0.60)
        up = rng.random() < 0.5
        for k in range(steps):
            lvl = -6.0 * (k / (steps - 1) if up else 1 - k / (steps - 1)) + U(rng, -1.5, 0.5)
            cplace(far, footstep(rng) * 10 ** (lvl / 20), g0 + k * iv + U(rng, -0.02, 0.02))
    cplace(far, door_far(rng) * 10 ** (-7 / 20), U(rng, 11.0, 14.5))
    if rng.random() < 0.7:  # a second, fainter door somewhere upstairs
        cplace(far, door_far(rng) * 10 ** (-13 / 20), U(rng, 25.0, 28.5))
    far = circ_filter(far, lambda f: mag_lp(f, 1800, 2))
    ir = reverb_ir(rng, 2.4, 3.2, pre=0.022, hi_rt=0.45,
                   early=[(0.031, -9), (0.047, -11), (0.068, -13), (0.093, -15)])
    wet = circ_conv(far, ir)
    far_mix = rms_norm(wet, 0) + rms_norm(far, -10)
    return rms_norm(tone_, -3) + rms_norm(traffic, -10) + rms_norm(far_mix, -9)


def clock_tick(rng, tock):
    d = 0.07
    fm = 0.9 if tock else 1.0
    esc = hit(rng, np.array([3100, 4870, 7020, 9400]) * fm, [0.004, 0.003, 0.002, 0.0015], [1, .7, .4, .2],
              d, 0.06e-3, level_db=-5)
    case = hit(rng, np.array([410, 640, 980, 1500]) * fm, [0.014, 0.010, 0.008, 0.005], [1, .8, .5, .3],
               d, 0.8e-3, level_db=0)
    return esc + case


def tool_clink(rng):
    d = 0.6
    f1 = U(rng, 900, 1900)
    tm = U(rng, 0.6, 1.2)
    steel = hit(rng, f1 * np.array([1, 2.756, 5.404, 8.933]), np.array([0.09, 0.05, 0.03, 0.02]) * tm,
                [1, .6, .4, .2], d, 0.15e-3, level_db=-2)
    x = steel + table_knock(rng, d, 2e-3, level_db=0)
    b = U(rng, 0.05, 0.12)
    S.place(x, hit(rng, f1 * np.array([1, 2.756, 5.404]), np.array([0.05, 0.03, 0.02]) * tm, [1, .5, .3],
                   d - b, 0.12e-3, level_db=-12), b)
    return x


def amb_workshop(rng, n):
    tone_ = spec_noise(rng, n, lambda f: mag_lp(f, 550, 2) * mag_hp(f, 50, 2) / np.sqrt(np.maximum(f, 30) / 100))
    tone_ *= 1 + 0.12 * slow_mod(rng, n, 0.1)
    close = np.zeros(n)
    ticks = [clock_tick(rng, k % 2 == 1) for k in range(8)]
    secs = int(round(n / SR))
    for s in range(secs):
        t = ticks[(s % 2) + 2 * int(rng.integers(0, 4))]
        cplace(close, t * 10 ** (U(rng, -0.6, 0.0) / 20), s + U(rng, -0.002, 0.002))
    clock = rms_norm(close, 0)
    tools = np.zeros(n)
    times = np.sort(rng.uniform(0, n / SR, int(rng.integers(4, 6))))
    for t in times:
        cplace(tools, tool_clink(rng) * 10 ** (U(rng, -6, 0) / 20), t)
    ir = reverb_ir(rng, 0.45, 0.9, pre=0.006, early=[(0.009, -8), (0.014, -10), (0.021, -12)])
    clock_w = clock + rms_norm(circ_conv(clock, ir), -9)
    tools_w = tools + circ_conv(tools, ir) * 10 ** (-6 / 20) * (rms(tools) / rms(circ_conv(tools, ir)))
    base = rms(tone_)
    return (rms_norm(tone_, 0) + clock_w * (10 ** (20 / 20) * base / np.max(np.abs(clock_w)))
            + tools_w * (10 ** (27 / 20) * base / np.max(np.abs(tools_w))))


def timer_tick(rng, alt):
    d = 0.04
    fm = 1.035 if alt else 1.0
    esc = hit(rng, np.array([4300, 6100, 8200]) * fm, [0.0025, 0.002, 0.0015], [1, .6, .3], d, 0.05e-3,
              level_db=-4)
    body = hit(rng, np.array([950, 1480, 2350, 3300]) * fm, [0.006, 0.005, 0.004, 0.003], [1, .7, .5, .3], d,
               0.5e-3, level_db=0)
    return esc + body


def car_pass(rng):
    d = U(rng, 6.0, 8.0)
    m = int(round(d * SR))
    x = S.hp(S.lp(rng.standard_normal(m), 650.0, 2), 60.0, 1)
    x += S.norm(S.bp(rng.standard_normal(m), 900, 3000), -14) * np.std(x) * 4
    w = np.sin(np.pi * np.arange(m) / m) ** 3
    return x * w


def amb_night_timer(rng, n):
    tone_ = spec_noise(rng, n, lambda f: mag_lp(f, 160, 2) * mag_hp(f, 45, 2))
    tone_ *= 1 + 0.1 * slow_mod(rng, n, 0.06)
    air = spec_noise(rng, n, lambda f: mag_hp(f, 1500, 1) * mag_lp(f, 6000, 2))
    tick = np.zeros(n)
    tv = [timer_tick(rng, k % 2 == 1) for k in range(8)]
    rate = 4  # ticks per second
    for k in range(int(round(n / SR)) * rate):
        cplace(tick, tv[(k % 2) + 2 * int(rng.integers(0, 4))] * 10 ** (U(rng, -1.0, 0.0) / 20),
               k / rate + U(rng, -0.003, 0.003))
    ir = reverb_ir(rng, 0.4, 0.8, pre=0.005, early=[(0.008, -9), (0.013, -11)])
    tick = tick + circ_conv(tick, ir) * 10 ** (-10 / 20) * rms(tick) / rms(circ_conv(tick, ir))
    cars = np.zeros(n)
    for t0 in (U(rng, 2.0, 8.0), U(rng, 16.0, 22.0)):
        cplace(cars, car_pass(rng) * 10 ** (U(rng, -4, 0) / 20), t0)
    cars = circ_filter(cars, lambda f: mag_lp(f, 900, 2))
    base = rms(tone_)
    return (rms_norm(tone_, 0) + rms_norm(air, -14) + cars * (10 ** (2 / 20) * base / np.max(np.abs(cars)) * 0.5)
            + tick * (10 ** (17 / 20) * base / np.max(np.abs(tick))))


def drop_ir(rng):
    m = int(0.004 * SR)
    x = rng.standard_normal(m) * np.exp(-np.arange(m) / (0.0012 * SR))
    return S.bp(x, 1200, 5500)


def sill_drip(rng):
    d = 0.12
    x = hit(rng, np.array([1350, 2210, 3480, 5100]) * U(rng, 0.93, 1.07), [0.03, 0.022, 0.015, 0.01],
            [1, .7, .4, .25], d, 0.2e-3, level_db=0)
    x += burst(rng, d, 0.002, lo=2000, level_db=-8)
    return x


def glass_tap(rng):
    d = 0.03
    return hit(rng, np.array([2400, 3700, 5600]) * U(rng, 0.9, 1.1), [0.004, 0.003, 0.002], [1, .6, .3], d,
               0.15e-3, level_db=0)


def amb_rain_window(rng, n):
    window = lambda f: mag_lp(f, 2600, 2) * mag_hp(f, 180, 1)  # noqa: E731  glass + frame muffle the highs
    bed = spec_noise(rng, n, lambda f: window(f) / np.sqrt(np.maximum(f, 50) / 1000) ** 0.5)
    imp = np.zeros(n)
    k = rng.poisson(500 * n / SR)
    np.add.at(imp, rng.integers(0, n, k), rng.uniform(0.25, 1.0, k))  # bounded: no single drop pokes out
    patter = circ_filter(circ_conv(imp, drop_ir(rng)), lambda f: mag_lp(f, 3400, 2))
    inten = np.clip(1 + 0.22 * slow_mod(rng, n, 0.12), 0.5, None)
    drips = np.zeros(n)
    for seg0 in (U(rng, 0.0, 6.0), U(rng, 14.0, 20.0)):
        t = seg0
        end = seg0 + U(rng, 6.0, 9.0)
        while t < end:
            cplace(drips, sill_drip(rng) * 10 ** (U(rng, -4, 0) / 20), t)
            t += U(rng, 0.85, 1.7)
    taps = np.zeros(n)
    for t in rng.uniform(0, n / SR, rng.poisson(0.5 * n / SR)):
        cplace(taps, glass_tap(rng) * 10 ** (U(rng, -8, 0) / 20), t)
    drips = circ_filter(drips, lambda f: mag_lp(f, 4200, 2))
    taps = circ_filter(taps, lambda f: mag_lp(f, 6000, 1))
    tone_ = spec_noise(rng, n, lambda f: mag_lp(f, 180, 2) * mag_hp(f, 30, 2))
    base = rms(bed)
    return ((rms_norm(bed, 0) + rms_norm(patter, -4)) * inten + rms_norm(tone_, -10)
            + drips * (10 ** (9 / 20) * base / np.max(np.abs(drips)))
            + taps * (10 ** (8 / 20) * base / np.max(np.abs(taps))))


AMB_FNS = {"stairwell": amb_stairwell, "workshop": amb_workshop, "night_timer": amb_night_timer,
           "rain_window": amb_rain_window}


def make_ambience(name, rng):
    n = int(round(AMB_DUR * SR))
    x = AMB_FNS[name](rng, n)
    x = circ_filter(x, lambda f: mag_hp(f, 25, 2))
    x -= np.mean(x)
    # 48 kHz -> 32 kHz: keep the spectrum below 16 kHz (exact for a periodic signal)
    m = int(round(AMB_DUR * AMB_SR))
    X = np.fft.rfft(x)[:m // 2 + 1].copy()
    X[-1] = X[-1].real  # Nyquist bin of the shorter period
    y = np.fft.irfft(X, m) * (m / n)
    t = TARGETS["ambience"]
    y *= 10 ** ((t["target"] - L.integrated(y, AMB_SR, circular=True)) / 20)
    # TPDF dither (+-1 LSB), seeded: ambience is quiet, keep its tails from truncating
    d = (rng.random(m) - rng.random(m)) / 32767.0
    return y + d


# --- UI one-shots --------------------------------------------------------------------


def leather_pat(rng, level_db=0.0, big=1.0):
    d = 0.12
    x = burst(rng, d, 0.006 * big, hi=900.0, level_db=0)
    x += hit(rng, np.array([150, 260, 420]) * U(rng, 0.9, 1.1) / big ** 0.3, [0.02, 0.015, 0.01], [1, .6, .4],
             d, 3e-3, level_db=-3)
    return S.norm(x, level_db)


def leather_rustle(rng, d, env):
    fr = S.friction(rng, d, rate=U(rng, 40, 75), jitter=0.8, lo=250, hi=3500, noise=0.8, env=env)
    x = drive(fr, rng, np.array([380, 620, 990, 1500]) * U(rng, 0.9, 1.1), [0.004, 0.003, 0.0025, 0.002],
              [1, .7, .5, .3], d, 0)
    return x + S.norm(S.bp(fr, 600, 4000) * env, -6)


def tiny_tink(rng, level_db):
    f1 = U(rng, 2200, 3400)
    return hit(rng, f1 * np.array([1, 2.756, 5.404]), [0.03, 0.02, 0.012], [1, .5, .25], 0.1, 0.1e-3,
               level_db=level_db)


def ui_tool_roll_open(rng):
    d = U(rng, 0.65, 0.85)
    x = S.silence(d)
    S.place(x, leather_pat(rng, -10), 0)
    S.place(x, leather_rustle(rng, d - 0.15, S.env_lin(d - 0.15, [(0, 0.3), (0.2, 1), (d - 0.25, 0.6), (d - 0.15, 0)])
                              ) * 10 ** (-8 / 20), 0.01)
    flaps = [U(rng, 0.14, 0.18), U(rng, 0.30, 0.34), d - U(rng, 0.20, 0.24)]
    for i, t in enumerate(flaps):
        S.place(x, leather_pat(rng, -6 + 3 * i, big=1.0 + 0.4 * i), t)
    S.place(x, tiny_tink(rng, -22), flaps[-1] + U(rng, 0.004, 0.01))
    S.place(x, tiny_tink(rng, -26), flaps[-1] + U(rng, 0.02, 0.04))
    return x


def ui_tool_roll_close(rng):
    d = U(rng, 0.55, 0.75)
    x = S.silence(d)
    S.place(x, leather_pat(rng, -8), 0)
    rd = d * 0.6
    S.place(x, leather_rustle(rng, rd, S.env_lin(rd, [(0, 0.6), (rd * 0.5, 1), (rd, 0)])) * 10 ** (-7 / 20), 0.005)
    S.place(x, leather_pat(rng, -5, big=1.2), U(rng, 0.10, 0.14))
    S.place(x, leather_pat(rng, -3, big=1.5), rd - 0.03)
    # strap pulled tight: short low leather creak
    cd = U(rng, 0.10, 0.15)
    fr = S.friction(rng, cd, rate=U(rng, 70, 90), rate_end=U(rng, 40, 55), jitter=0.2, lo=200, hi=2000, noise=0.2,
                    env=S.env_lin(cd, [(0, 0), (0.02, 1), (cd, 0)]))
    S.place(x, drive(fr, rng, [420, 690, 1050], [0.008, 0.006, 0.004], [1, .6, .4], cd, -9), rd + 0.03)
    return x


def ui_paper_turn(rng):
    d = U(rng, 0.38, 0.50)
    env = S.env_lin(d, [(0, 0.25), (U(rng, 0.12, 0.18), 1.0), (d - 0.08, 0.35), (d, 0)])
    x = S.norm(S.bp(rng.standard_normal(int(round(d * SR))), 800, 7000) * env, -4)
    x += S.norm(crackle(rng, d, U(rng, 350, 600), 2000, 9000, env), -7)
    S.place(x, burst(rng, 0.01, 0.0012, lo=2500, level_db=-8), 0)   # finger catches the corner
    S.place(x, burst(rng, 0.04, 0.008, hi=1500, level_db=-6), d - U(rng, 0.07, 0.09))  # page lands
    return S.lp(x, 9000.0, 1)


def ui_paper_slide(rng):
    d = U(rng, 0.24, 0.36)
    env = S.env_lin(d, [(0, 0.8), (0.03, 1.0), (d * 0.6, 0.6), (d, 0)])
    x = S.norm(S.bp(rng.standard_normal(int(round(d * SR))), 600, 5000) * env, -2)
    x += S.norm(crackle(rng, d, U(rng, 120, 220), 1500, 7000, env), -12)
    S.place(x, burst(rng, 0.01, 0.0015, lo=1500, level_db=-6), 0)
    return S.lp(x, 9000.0, 1)


def ui_chalk_stroke(rng):
    d = U(rng, 0.12, 0.28)
    env = S.env_lin(d, [(0, 0.7), (0.01, 1), (d * 0.7, 0.8), (d, 0)])
    fr = S.friction(rng, d, rate=U(rng, 450, 900), jitter=0.9, lo=1500, hi=8000, noise=0.7, env=env)
    fb = np.array([820, 1310, 1990, 2870, 3900]) * U(rng, 0.92, 1.08)
    x = drive(fr, rng, fb, [0.005, 0.004, 0.003, 0.0025, 0.002], [1, .8, .6, .4, .3], d, 0)
    x += S.norm(S.bp(fr, 2500, 9000), -5)
    x += S.norm(crackle(rng, d, U(rng, 150, 300), 2500, 9000, env), -9)  # crumbs
    S.place(x, hit(rng, fb, [0.004, 0.003, 0.002, 0.002, 0.0015], [1, .7, .5, .3, .2], 0.02, 0.3e-3, level_db=-3), 0)
    return x


def cardboard_thump(rng, level_db, big=1.0):
    d = 0.1
    x = hit(rng, np.array([220, 410, 700, 1100]) * U(rng, 0.9, 1.1) / big ** 0.2, [0.012, 0.009, 0.006, 0.004],
            [1, .7, .4, .25], d, 3.5e-3 * big, grain=0.15, level_db=0)
    x += burst(rng, d, 0.007 * big, hi=900, level_db=-5)
    return S.norm(x, level_db)


def ui_notebook_open(rng):
    d = U(rng, 0.32, 0.45)
    x = S.silence(d)
    S.place(x, burst(rng, 0.01, 0.0012, lo=1500, level_db=-12), 0)  # fingertip on the cover
    sd = U(rng, 0.10, 0.16)
    env = S.env_lin(sd, [(0, 0), (sd * 0.4, 1), (sd, 0)])
    S.place(x, S.norm(crackle(rng, sd, 500, 1800, 8000, env) + S.bp(rng.standard_normal(int(round(sd * SR))),
                                                                  900, 6000) * env * 0.05, -10), 0.04)
    S.place(x, cardboard_thump(rng, -2), d - U(rng, 0.11, 0.14))
    return x


def ui_notebook_close(rng):
    d = U(rng, 0.20, 0.30)
    x = S.silence(d)
    S.place(x, burst(rng, 0.01, 0.0015, lo=1200, level_db=-10), 0)
    sd = U(rng, 0.06, 0.10)
    env = S.env_lin(sd, [(0, 0.3), (sd * 0.7, 1), (sd, 0)])
    S.place(x, S.norm(S.bp(rng.standard_normal(int(round(sd * SR))), 700, 5000) * env, -10), 0.01)
    S.place(x, cardboard_thump(rng, 0, big=1.4), sd + 0.01)  # cover claps shut (air pocket = longer burst)
    return x


def ui_pencil_tick(rng):
    d = U(rng, 0.13, 0.18)
    x = S.silence(d)
    S.place(x, table_knock(rng, 0.04, 0.4e-3, level_db=-6, fmul=1.3), 0)
    S.place(x, burst(rng, 0.006, 0.0006, lo=3000, level_db=-4), 0)
    s1 = U(rng, 0.025, 0.04)
    s2 = U(rng, 0.06, 0.09)
    for t0, sd, lvl in ((0.003, s1, -3), (0.003 + s1 + U(rng, 0.008, 0.015), s2, 0)):
        env = S.env_lin(sd, [(0, 0.6), (sd * 0.2, 1), (sd, 0)])
        fr = S.friction(rng, sd, rate=U(rng, 1600, 2400), jitter=0.9, lo=2500, hi=9000, noise=0.8, env=env)
        S.place(x, S.norm(S.lp(fr, 7500.0, 2), lvl), t0)  # raw stick-slip impulses are broadband: no hiss
    return x


def ui_job_phone(rng):
    """Phone vibrating on a wooden desk + a soft two-note mallet dyad on each pulse (own motif)."""
    d = U(rng, 2.05, 2.25)
    x = S.silence(d)
    pulses = [(0.0, U(rng, 0.40, 0.44)), (U(rng, 0.60, 0.64), U(rng, 0.40, 0.44))]
    dyads = [("G4", "D5"), ("A4", "E5")]
    for (t0, pd), (n1, n2) in zip(pulses, dyads):
        n = int(round(pd * SR))
        fm = U(rng, 165, 178)
        exc = np.zeros(n)
        t = 0.0
        while t < pd:
            exc[int(t * SR)] += 1.0
            t += (1.0 / fm) * (1 + 0.04 * rng.uniform(-1, 1))
        env = S.env_lin(pd, [(0, 0.45), (0.02, 1.0), (pd - 0.04, 1.0), (pd, 0)])
        exc *= env
        desk = drive(exc, rng, [185, 330, 520, 870, 1350], [0.02, 0.018, 0.012, 0.008, 0.005], [1, .8, .6, .4, .25],
                     pd + 0.05, 0)
        rat = drive(exc * (rng.random(n) < 0.6), rng, [1250, 2100, 3300], [0.003, 0.0025, 0.002], [1, .6, .4],
                    pd + 0.05, -10)
        S.place(x, (desk + rat) * 10 ** (-4 / 20), t0)
        for nm, lv in ((n1, -2), (n2, -6)):
            S.place(x, tone(rng, note_hz(nm), d - t0 - 0.01, *BAR, tau1=0.45, pulse_s=3.5e-3, dexp=1.2,
                            level_db=lv), t0 + 0.002)
    ir = reverb_ir(rng, 0.45, 0.8, pre=0.006)
    return lin_reverb(x, ir, -14)[:len(x)]


def drawer_slide(rng, d, rate, env):
    fr = S.friction(rng, d, rate=rate, rate_end=rate * U(rng, 0.8, 1.2), jitter=0.6, lo=200, hi=2500, noise=0.5,
                    env=env)
    box = np.array([140, 230, 370, 560, 900]) * U(rng, 0.93, 1.07)
    return drive(fr, rng, box, [0.03, 0.025, 0.018, 0.012, 0.008], [1, .8, .6, .45, .3], d, 0)


def glass_ring(rng, level_db):
    return hit(rng, np.array([2500, 3900, 6100]) * U(rng, 0.95, 1.05), [0.03, 0.022, 0.015], [1, .6, .35],
               0.15, 0.2e-3, level_db=level_db)


def ui_drawer_open(rng):
    d = U(rng, 0.60, 0.82)
    x = S.silence(d)
    S.place(x, S.strike("case", "brass", rng, 0.04, -12, taumul=0.6), 0)  # fingers on the small brass pull
    sd = d - U(rng, 0.20, 0.25)
    env = S.env_lin(sd, [(0, 0.5), (0.05, 1.0), (sd * 0.8, 0.8), (sd, 0.2)])
    S.place(x, drawer_slide(rng, sd, U(rng, 55, 90), env) * 10 ** (-6 / 20), 0.005)
    st = sd + 0.005
    S.place(x, table_knock(rng, d - st, 3e-3, level_db=0, fmul=0.75), st)  # drawer reaches its stop
    S.place(x, glass_ring(rng, -24), st + 0.003)
    return x


def ui_drawer_close(rng):
    d = U(rng, 0.45, 0.62)
    x = S.silence(d)
    S.place(x, S.strike("case", "brass", rng, 0.04, -12, taumul=0.6), 0)
    sd = d - U(rng, 0.18, 0.22)
    env = S.env_lin(sd, [(0, 0.6), (0.03, 1.0), (sd, 0.6)])
    S.place(x, drawer_slide(rng, sd, U(rng, 80, 120), env) * 10 ** (-6 / 20), 0.004)
    st = sd + 0.004
    S.place(x, table_knock(rng, d - st, 4e-3, level_db=0, fmul=0.7), st)
    S.place(x, glass_ring(rng, -20), st + 0.003)
    return x


# --- rewards ------------------------------------------------------------------------


def rw_door_open(rng):
    d = U(rng, 1.6, 2.0)
    x = S.silence(d)
    # handle pressed: latch bolt retracts against its spring
    S.place(x, S.strike("bolt", "brass", rng, 0.06, -6, taumul=0.6), 0)
    S.place(x, S._spring_buzz("brass", rng, 0.05, -18), 0.002)
    tu = U(rng, 0.12, 0.18)
    # latch leaves the strike plate, door body moves
    S.place(x, S.strike("bolt", "brass", rng, 0.05, -10, fmul=1.2, taumul=0.5), tu)
    S.place(x, hit(rng, [68, 112, 170, 240, 360], [0.09, 0.07, 0.05, 0.04, 0.03], [1, .8, .6, .4, .25], 0.4,
                   6e-3, grain=0.2, level_db=-3), tu + 0.004)
    # hinge: short, low, gentle creak (oiled; not a horror door)
    cd = U(rng, 0.35, 0.50)
    fr = S.friction(rng, cd, rate=U(rng, 28, 40), rate_end=U(rng, 55, 75), jitter=0.15, lo=300, hi=3000, noise=0.15,
                    env=S.env_lin(cd, [(0, 0), (0.06, 1), (cd * 0.7, 0.7), (cd, 0)]))
    hinge = drive(fr, rng, [620, 1180, 1900, 2750], [0.012, 0.009, 0.007, 0.005], [1, .6, .4, .25], cd, 0)
    hinge += drive(fr, rng, [95, 160, 240], [0.03, 0.025, 0.02], [1, .7, .5], cd, -6)
    S.place(x, S.norm(hinge, -15), tu + U(rng, 0.08, 0.14))
    # air: the door swings, the room opens up (soft low whoosh + a breath of the hallway)
    ad = d - tu - 0.05
    m = int(round(ad * SR))
    a_env = S.env_lin(ad, [(0, 0), (ad * 0.3, 1), (ad, 0)]) ** 1.5
    whoosh = S.hp(S.lp(rng.standard_normal(m), 480.0, 2), 50.0, 1) * a_env
    hall = S.bp(rng.standard_normal(m), 250, 2500) * S.env_lin(ad, [(0, 0), (ad * 0.5, 1), (ad, 0)])
    S.place(x, S.norm(whoosh, -12) + S.norm(hall, -26), tu + 0.03)
    ir = reverb_ir(rng, 0.7, 1.2, pre=0.01, early=[(0.012, -10), (0.019, -12)])
    y = lin_reverb(x, ir, -12)
    return y[:len(x) + int(0.25 * SR)]


MOTIFS = [
    # (time s, notes, velocity dB): D major, gentle rise and a soft resolving chord
    [(0.00, ["A4"], -2), (0.17, ["D5"], -1), (0.34, ["F#5"], 0), (0.62, ["E5"], -3),
     (0.88, ["D5", "F#4", "A4"], -2), (0.90, ["D4"], -4)],
    [(0.00, ["F#4"], -2), (0.16, ["A4"], -1), (0.32, ["D5"], 0), (0.60, ["C#5"], -3),
     (0.86, ["D5", "A4", "F#4"], -2), (0.88, ["D4"], -4)],
    [(0.00, ["A4"], -2), (0.15, ["B4"], -2), (0.30, ["D5"], 0), (0.58, ["E5"], -3),
     (0.84, ["F#5", "D5", "A4"], -3), (0.86, ["D4"], -4)],
]


def rw_thanks(rng, v):
    d = U(rng, 2.5, 2.7)
    x = S.silence(d)
    for t0, notes, vel in MOTIFS[(v - 1) % len(MOTIFS)]:
        for j, nm in enumerate(notes):
            t = t0 + 0.012 * j + U(rng, 0, 0.006)  # chords are gently rolled, not struck
            f0 = note_hz(nm)
            lv = vel - 2.5 * j
            if f0 < 300:  # soft mallet bar for the low note
                s = tone(rng, f0, d - t, *BAR, tau1=0.8, pulse_s=4e-3, dexp=1.0, level_db=lv)
            else:         # plucked tine for the melody
                s = tone(rng, f0, d - t, *TINE, tau1=U(rng, 0.55, 0.7), pulse_s=1.6e-3, dexp=0.9, level_db=lv)
                s += tone(rng, f0 * 2, d - t, [1.0], [1.0], tau1=0.12, pulse_s=1.0e-3, level_db=lv - 14)
            S.place(x, s, t)
    x = S.lp(x, 6000.0, 1)
    x *= S.env_lin(d, [(0, 1), (d - 0.5, 1), (d, 0)])
    ir = reverb_ir(rng, 0.9, 1.4, pre=0.012, hi_rt=0.4)
    y = lin_reverb(x, ir, -9)
    return y[:len(x)] * S.env_lin(d, [(0, 1), (d - 0.15, 1), (d, 0)])


def coin_hit(rng, level_db, on_coin=False):
    d = 0.22
    f1 = U(rng, 2100, 3200)
    tm = 1.6 if on_coin else 1.0
    c = hit(rng, f1 * np.array([1, 1.53, 2.21, 2.98, 3.91]), np.array([0.05, 0.04, 0.03, 0.022, 0.015]) * tm,
            [.6, 1, .7, .5, .3], d, 0.08e-3 if on_coin else 0.14e-3, level_db=0)
    w = table_knock(rng, d, 1.0e-3, level_db=-2 if not on_coin else -10, fmul=1.15)
    return S.norm(c + w, level_db)


def rw_coins(rng, v):
    d = U(rng, 0.95, 1.30)
    x = S.silence(d)
    nc = int(rng.integers(3, 6))
    t = 0.0
    for i in range(nc):
        S.place(x, coin_hit(rng, -1 - 1.5 * i + U(rng, -1, 0), on_coin=i > 0), t)
        if rng.random() < 0.7:  # small bounce / neighbour coin shifts
            S.place(x, coin_hit(rng, -12 - 1.5 * i, on_coin=True), t + U(rng, 0.025, 0.05))
        t += U(rng, 0.07, 0.13)
    if v == 2:  # the last coin settles on its rim: accelerating ticks
        tt, per, lv = t + 0.02, 0.055, -14.0
        while per > 0.012 and tt < d - 0.05:
            S.place(x, coin_hit(rng, lv, on_coin=True) * S.env_lin(0.22, [(0, 1), (0.02, 0.3), (0.22, 0)]), tt)
            tt += per
            per *= 0.78
            lv -= 1.2
    ir = reverb_ir(rng, 0.4, 0.7, pre=0.005, early=[(0.007, -10), (0.011, -12)])
    y = lin_reverb(x, ir, -14)
    return y[:len(x)]


UI_FNS = {k[3:]: v for k, v in list(globals().items()) if k.startswith("ui_")}
RW_FNS = {"door_open": lambda r, v: rw_door_open(r), "thanks": rw_thanks, "coins": rw_coins}


# --- finishing / IO -------------------------------------------------------------------


def finish(x, tkey, fade_ms):
    x = S.hp(np.asarray(x, float), 25.0, 2)
    pk = np.max(np.abs(x))
    i0 = int(np.argmax(np.abs(x) > pk * 1e-3))
    x = x[i0:]
    nf = 12
    x[:nf] *= np.sin(0.5 * np.pi * np.arange(nf) / nf) ** 2
    above = np.nonzero(np.abs(x) > pk * 10 ** (-62 / 20))[0]
    nfo = int(fade_ms * 1e-3 * SR)
    x = x[:min(len(x), int(above[-1]) + nfo)]
    nfo = min(nfo, len(x) // 4)
    x[-nfo:] *= np.cos(0.5 * np.pi * np.arange(1, nfo + 1) / nfo) ** 2
    bump = np.sin(np.pi * (np.arange(len(x)) + 0.5) / len(x)) ** 2
    x = x - bump * (np.mean(x) / np.mean(bump))
    t = TARGETS[tkey]
    cur = L.integrated(x, SR) if t["measure"] == "I" else L.momentary_max(x, SR)
    return x * 10 ** ((t["target"] - cur) / 20)


def wav_bytes_sr(pcm, sr, loop=False):
    data = pcm.tobytes()
    fmt = struct.pack("<HHIIHH", 1, 1, sr, sr * 2, 2, 16)
    chunks = b"fmt " + struct.pack("<I", len(fmt)) + fmt
    chunks += b"data" + struct.pack("<I", len(data)) + data
    if loop:
        smpl = struct.pack("<9I", 0, 0, int(round(1e9 / sr)), 60, 0, 0, 0, 1, 0)
        smpl += struct.pack("<6I", 0, 0, 0, len(pcm) - 1, 0, 0)
        chunks += b"smpl" + struct.pack("<I", len(smpl)) + smpl
    return b"RIFF" + struct.pack("<I", 4 + len(chunks)) + b"WAVE" + chunks


def measure(xf, sr, loop):
    return {
        "lufs_i": round(L.integrated(xf, sr, circular=loop), 2),
        "lufs_m_max": round(L.momentary_max(xf, sr, circular=loop), 2),
        "lufs_s_max": round(L.short_term_max(xf, sr, circular=loop), 2),
        "true_peak_dbtp": round(L.true_peak_db(xf, circular=loop), 2),
    }


def render_world(seed, out_dir, verbose=True):
    entries = []
    demo = []
    gap = S.silence(0.4)

    def write(rel, pcm, sr, loop, extra):
        blob = wav_bytes_sr(pcm, sr, loop)
        path = os.path.join(out_dir, rel)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "wb") as fh:
            fh.write(blob)
        xf = pcm.astype(float) / 32767.0
        e = {"file": rel, **extra, "loop": loop, "sha256": hashlib.sha256(blob).hexdigest(),
             "sample_rate": sr, "samples": len(pcm), "duration_s": round(len(pcm) / sr, 4),
             "peak_dbfs": round(S.db(np.max(np.abs(xf))), 2), "onset_ms": round(S.onset_samples(xf) / sr * 1000, 3),
             **measure(xf, sr, loop)}
        if loop:
            e.update(loop_start=0, loop_end=len(pcm) - 1)
        entries.append(e)
        return xf

    for name in AMBIENCE:
        rng = S.rng_for(seed, "world", name, 1)
        y = make_ambience(name, rng)
        pcm = np.clip(np.round(y * 32767.0), -32767, 32767).astype("<i2")
        xf = write(f"ambience/{name}.wav", pcm, AMB_SR, True, {"category": "ambience", "name": name, "variant": 1})

    for cat, table, fns in (("ui", UI, UI_FNS), ("reward", REWARDS, RW_FNS)):
        for name, (tkey, nv, _rng) in table.items():
            for v in range(1, nv + 1):
                rng = S.rng_for(seed, "world", name, v)
                raw = fns[name](rng) if cat == "ui" else fns[name](rng, v)
                x = finish(raw, tkey, 5 if cat == "ui" else 20)
                xf = write(f"{cat}/{name}_{v}.wav", S.to_int16(x), SR, False,
                           {"category": cat, "name": name, "variant": v, "target": tkey})
                if v == 1:
                    demo += [xf, gap]
    with open(os.path.join(out_dir, "demo_world.wav"), "wb") as fh:
        fh.write(wav_bytes_sr(S.to_int16(np.concatenate(demo)), SR))
    if verbose:
        size = sum(os.path.getsize(os.path.join(out_dir, e["file"])) for e in entries)
        print(f"world: wrote {len(entries)} files (ambience/ ui/ reward/) to {out_dir} ({size / 1e6:.2f} MB)")
    return entries


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--seed", type=int, default=S.DEFAULT_SEED)
    ap.add_argument("--out", default=os.path.join(HERE, "out"))
    a = ap.parse_args()
    render_world(a.seed, os.path.abspath(a.out))


if __name__ == "__main__":
    main()
