#!/usr/bin/env python3
"""Minimal ITU-R BS.1770-4 / EBU R128 loudness meter in numpy (mono).

- K-weighting = BS.1770 pre-filter (high shelf ~+4 dB above ~1.7 kHz) + RLB
  high-pass (~38 Hz). Biquads are derived from the analogue prototype for any
  sample rate; at 48 kHz they reproduce the coefficients printed in BS.1770
  (checked by self_test()). Filtering is done in the frequency domain with the
  exact complex response H(e^jw): linear (zero-padded) for one-shots, circular
  for loops (a loop is periodic, so circular filtering is what the player hears).
- integrated(): 400 ms blocks, 75 % overlap, absolute gate -70 LUFS, relative
  gate -10 LU (mono: channel weight 1).
- momentary_max(): max over 400 ms windows (hop 10 ms); short sounds are padded
  with silence, so a 30 ms click counts as its energy spread over 400 ms.
- short_term_max(): same with 3 s windows.
- true_peak_db(): 4x oversampling by FFT interpolation (BS.1770 Annex 2 asks
  for >= 4x; FFT interpolation is an ideal band-limited interpolator).

Usage: python3 audio/v2/loudness.py file.wav [...]   (prints I / M_max / S_max / TP)
"""

import math
import sys
import wave

import numpy as np

# Analogue prototype of the BS.1770 K filter (same constants as used by common
# open implementations; they reproduce the 48 kHz table to ~1e-9).
_SHELF_F0, _SHELF_G, _SHELF_Q = 1681.974450955533, 3.999843853973347, 0.7071752369554196
_HP_F0, _HP_Q = 38.13547087602444, 0.5003270373238773


def k_biquads(sr):
    K = math.tan(math.pi * _SHELF_F0 / sr)
    Vh = 10 ** (_SHELF_G / 20.0)
    Vb = Vh ** 0.4996667741545416
    a0 = 1.0 + K / _SHELF_Q + K * K
    b1 = [(Vh + Vb * K / _SHELF_Q + K * K) / a0, 2.0 * (K * K - Vh) / a0, (Vh - Vb * K / _SHELF_Q + K * K) / a0]
    a1 = [1.0, 2.0 * (K * K - 1.0) / a0, (1.0 - K / _SHELF_Q + K * K) / a0]
    K = math.tan(math.pi * _HP_F0 / sr)
    a0 = 1.0 + K / _HP_Q + K * K
    b2 = [1.0, -2.0, 1.0]
    a2 = [1.0, 2.0 * (K * K - 1.0) / a0, (1.0 - K / _HP_Q + K * K) / a0]
    return (b1, a1), (b2, a2)


def _resp(ba, z):
    b, a = ba
    zi = 1.0 / z
    return (b[0] + b[1] * zi + b[2] * zi * zi) / (a[0] + a[1] * zi + a[2] * zi * zi)


def kweight(x, sr, circular=False):
    x = np.asarray(x, float)
    n = len(x) if circular else len(x) + int(0.5 * sr)  # 0.5 s pad: the 38 Hz HP tail has decayed by then
    X = np.fft.rfft(x, n)
    z = np.exp(2j * np.pi * np.arange(len(X)) / n)
    s1, s2 = k_biquads(sr)
    y = np.fft.irfft(X * _resp(s1, z) * _resp(s2, z), n)
    return y


def _block_powers(y, sr, win_s, hop_s, circular):
    b, hop = int(round(win_s * sr)), int(round(hop_s * sr))
    if circular:
        reps = int(math.ceil((len(y) + b) / len(y)))
        yy = np.tile(y, reps + 1)[:len(y) + b]
        starts = np.arange(0, len(y), hop)
    else:
        yy = np.concatenate([np.zeros(b), y, np.zeros(b)])
        starts = np.arange(0, len(yy) - b + 1, hop)
    c = np.concatenate([[0.0], np.cumsum(yy * yy)])
    return (c[starts + b] - c[starts]) / b


def _lufs(p):
    return -0.691 + 10 * math.log10(max(float(p), 1e-20))


def integrated(x, sr, circular=False):
    y = kweight(x, sr, circular)
    if not circular:
        y = y[:len(x)]  # whole blocks of the signal only (a sub-400 ms sound is zero-padded to one block)
    p = _block_powers(y, sr, 0.4, 0.1, circular) if circular else _gated_blocks_linear(y, sr)
    p = p[np.array([_lufs(v) for v in p]) > -70.0]
    if len(p) == 0:
        return -200.0
    rel = _lufs(np.mean(p)) - 10.0
    p = p[np.array([_lufs(v) for v in p]) > rel]
    return _lufs(np.mean(p)) if len(p) else -200.0


def _gated_blocks_linear(y, sr):
    b, hop = int(0.4 * sr), int(0.1 * sr)
    if len(y) < b:
        y = np.pad(y, (0, b - len(y)))
    c = np.concatenate([[0.0], np.cumsum(y * y)])
    starts = np.arange(0, len(y) - b + 1, hop)
    return (c[starts + b] - c[starts]) / b


def momentary_max(x, sr, circular=False):
    y = kweight(x, sr, circular)
    return _lufs(np.max(_block_powers(y, sr, 0.4, 0.01, circular)))


def short_term_max(x, sr, circular=False):
    y = kweight(x, sr, circular)
    return _lufs(np.max(_block_powers(y, sr, 3.0, 0.1, circular)))


def true_peak_db(x, os_factor=4, circular=False):
    x = np.asarray(x, float)
    n = len(x) if circular else len(x) + 64
    X = np.fft.rfft(x, n)
    m = n * os_factor
    Y = np.zeros(m // 2 + 1, complex)
    Y[:len(X)] = X
    if n % 2 == 0:
        Y[len(X) - 1] *= 0.5  # split the Nyquist bin
    y = np.fft.irfft(Y, m) * os_factor
    return 20 * math.log10(max(float(np.max(np.abs(y))), float(np.max(np.abs(x))), 1e-12))


def self_test():
    (b1, a1), (b2, a2) = k_biquads(48000)
    ref_b1 = [1.53512485958697, -2.69169618940638, 1.19839281085285]
    ref_a1 = [1.0, -1.69065929318241, 0.73248077421585]
    ref_a2 = [1.0, -1.99004745483398, 0.99007225036621]
    assert np.allclose(b1, ref_b1, atol=1e-6) and np.allclose(a1, ref_a1, atol=1e-6), (b1, a1)
    assert np.allclose(b2, [1, -2, 1]) and np.allclose(a2, ref_a2, atol=1e-6), a2
    # EBU Tech 3341 style sanity: 1 kHz sine at -20 dBFS (mono) reads -23.0 LUFS (+-0.1)
    sr = 48000
    t = np.arange(sr * 10) / sr
    s = 10 ** (-20 / 20) * np.sin(2 * np.pi * 1000 * t)
    li = integrated(s, sr)
    # mean square 0.005 = -23.01 dB; K-weighting is +0.691 dB at 1 kHz, cancelled by the -0.691 offset
    assert abs(li + 23.01) < 0.05, li
    assert abs(integrated(s, sr, circular=True) + 23.01) < 0.05
    assert abs(true_peak_db(s) + 20.0) < 0.05
    return li


def read_wav(path):
    with wave.open(path, "rb") as w:
        sr = w.getframerate()
        pcm = np.frombuffer(w.readframes(w.getnframes()), dtype="<i2")
    return pcm.astype(float) / 32767.0, sr


if __name__ == "__main__":
    print(f"self-test: 1 kHz sine, -20 dBFS peak -> {self_test():.2f} LUFS (mono)")
    for p in sys.argv[1:]:
        x, sr = read_wav(p)
        print(f"{p}: I {integrated(x, sr):6.1f}  M_max {momentary_max(x, sr):6.1f}  "
              f"S_max {short_term_max(x, sr):6.1f}  TP {true_peak_db(x):6.1f} dBTP")
