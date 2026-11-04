#!/usr/bin/env python3
"""Touch -> haptic latency from a piezo recording (spikes 1-2, docs/TECH.md §2.4, §4).

Recording: 48 kHz stereo from an audio interface.
  channel 1 (left)  = piezo / contact mic taped to the BACK of the phone (sees the finger tap on the glass
                      as a broadband click AND the actuator burst ~150-230 Hz)
  channel 2 (right) = optional second piezo on the screen next to the touch point (cleaner tap onset);
                      if absent (--single), the tap is taken from channel 1's high band (> 2 kHz)

  python3 tools/analyze.py godot_pixel_1.wav native_pixel_1.wav ... [--single] [--csv out.csv] [--plot out.png]
  python3 tools/analyze.py --continuity drag.wav     # gaps in the continuous resistance (>15 ms = fail, TECH spike 2)
  python3 tools/analyze.py --selftest

Tap onset: high band (2-12 kHz) envelope crossing (threshold max(-35 dBFS, floor + 20 dB), 150 ms refractory).
Haptic onset: low band (100-400 Hz, the LRA/ERM band) envelope crossing after the tap, searched 5..250 ms
later. Reports p50/p95 per file and the Godot-minus-native difference when file names contain 'godot' and
'native' with the same suffix (criterion: difference p95 <= 8 ms, spike 1)."""
import sys, json, wave
import numpy as np

def read(path):
    with wave.open(path, 'rb') as w:
        sr, ch, sw, n = w.getframerate(), w.getnchannels(), w.getsampwidth(), w.getnframes()
        raw = w.readframes(n)
    dt = {2: '<i2', 4: '<i4'}.get(sw)
    if dt is None:
        b = np.frombuffer(raw, np.uint8).reshape(-1, 3)
        x = ((b[:, 0].astype(np.int32) | (b[:, 1].astype(np.int32) << 8) | (b[:, 2].astype(np.int32) << 16)) << 8 >> 8) / 8388608
    else:
        x = np.frombuffer(raw, dt).astype(np.float64) / (32768 if sw == 2 else 2147483648)
    return sr, x.reshape(-1, ch)

def band(x, sr, lo, hi):
    n = len(x); X = np.fft.rfft(x); f = np.fft.rfftfreq(n, 1 / sr)
    X *= 1 / np.sqrt(1 + (lo / np.maximum(f, 1e-9)) ** 8) / np.sqrt(1 + (f / hi) ** 8)
    return np.fft.irfft(X, n)

def biquad_bp(x, sr, f0, q):
    """Causal RBJ band-pass (constant 0 dB peak). No pre-ringing, so onsets are not pulled early."""
    w = 2 * np.pi * f0 / sr; al = np.sin(w) / (2 * q); c = np.cos(w)
    b0, b2, a0, a1, a2 = al, -al, 1 + al, -2 * c, 1 - al
    b0, b2, a1, a2 = b0 / a0, b2 / a0, a1 / a0, a2 / a0
    y = np.empty_like(x); x1 = x2 = y1 = y2 = 0.0
    for i, v in enumerate(x.tolist()):
        o = b0 * v + b2 * x2 - a1 * y1 - a2 * y2
        x2, x1, y2, y1 = x1, v, y1, o
        y[i] = o
    return y

def env(x, sr, ms, causal=False):
    k = max(1, int(sr * ms / 1000))
    if causal:  # trailing window: never rises before the signal does
        return np.convolve(np.abs(x), np.ones(k) / k, mode='full')[:len(x)]
    return np.convolve(np.abs(x), np.ones(k) / k, mode='same')

def thr_of(e, db):
    return max(10 ** (db / 20), (np.percentile(e, 50) + 1e-12) * 10)

def taps(x, sr, db=-35.0, refractory_ms=150.0):
    e = env(band(x, sr, 2000, 12000), sr, 0.25); t = thr_of(e, db)
    idx = np.flatnonzero(e > t)
    if not len(idx): return np.array([], int)
    q = int(sr * refractory_ms / 1000)
    return idx[np.diff(idx, prepend=-q - 1) > q]

def analyse(path, single=False, db=-35.0):
    sr, x = read(path)
    tap_ch = x[:, 0] if single or x.shape[1] < 2 else x[:, 1]
    T = taps(tap_ch, sr, db)
    hb = biquad_bp(x[:, 0], sr, 200.0, 0.7)   # causal, ~100-400 Hz (LRA/ERM band)
    e = env(hb, sr, 2.0, causal=True)   # 2 ms trailing window: smooths the 150-230 Hz carrier
    th = thr_of(e, db - 6)
    fine = env(hb, sr, 0.5, causal=True)
    lat, miss = [], 0
    for t in T:
        a, b = int(t + sr * 0.005), int(t + sr * 0.25)  # tap ring-down in the low band lasts ~3 ms
        seg = e[a - 1:b] > th
        r = np.flatnonzero(seg[1:] & ~seg[:-1])
        if len(r):
            c = a + r[0]
            # back-track to where the fast envelope first left the noise (30% of threshold)
            stop = max(a, c - int(sr * 0.003))  # at most 3 ms back
            while c > stop and fine[c - 1] > 0.3 * th:
                c -= 1
            lat.append((c - t) * 1000 / sr)
        else:
            miss += 1
    lat = np.array(lat)
    out = {'file': path, 'taps': int(len(T)), 'paired': int(len(lat)), 'missing_haptic': miss}
    if len(lat):
        out.update({k: round(float(v), 2) for k, v in {'p50_ms': np.percentile(lat, 50), 'p95_ms': np.percentile(lat, 95),
                    'mean_ms': lat.mean(), 'min_ms': lat.min(), 'max_ms': lat.max()}.items()})
    return out, lat

def continuity(path, db=-40.0):
    sr, x = read(path)
    e = env(band(x[:, 0], sr, 100, 400), sr, 2.0); th = thr_of(e, db)
    on = e > th
    edges = np.flatnonzero(np.diff(on.astype(int)))
    gaps = []
    for i in range(len(edges) - 1):
        if not on[edges[i] + 1]:
            gaps.append((edges[i + 1] - edges[i]) * 1000 / sr)
    gaps = np.array(gaps)
    r = {'file': path, 'active_s': round(float(on.sum() / sr), 2), 'gaps': int(len(gaps)),
         'gaps_over_15ms': int((gaps > 15).sum()) if len(gaps) else 0,
         'max_gap_ms': round(float(gaps.max()), 1) if len(gaps) else 0.0}
    r['verdict'] = 'pass' if r['gaps_over_15ms'] == 0 else 'FAIL'
    return r

def selftest():
    sr = 48000; rng = np.random.default_rng(3); n = sr * 15
    x = rng.normal(0, 0.001, (n, 2)); truth = []; t = int(0.4 * sr)
    while t < n - sr // 2:
        d = rng.uniform(8, 60); truth.append(d)
        k = np.arange(int(0.003 * sr)); click = rng.standard_normal(len(k)) * np.exp(-k / (0.0004 * sr))
        x[t:t + len(k), 0] += 0.3 * click; x[t:t + len(k), 1] += 0.6 * click
        h = t + int(round(d * sr / 1000)); k2 = np.arange(int(0.02 * sr))
        x[h:h + len(k2), 0] += 0.4 * np.sin(2 * np.pi * 175 * k2 / sr) * np.minimum(k2 / (0.0015 * sr), 1) * np.exp(-k2 / (0.012 * sr))
        t += int(rng.uniform(0.35, 0.6) * sr)
    import tempfile, os
    p = os.path.join(tempfile.mkdtemp(), 's.wav')
    with wave.open(p, 'wb') as w:
        w.setnchannels(2); w.setsampwidth(2); w.setframerate(sr); w.writeframes((np.clip(x, -1, 1) * 32767).astype('<i2').tobytes())
    r, lat = analyse(p)
    ok = len(lat) == len(truth)
    err = np.abs(lat - np.array(truth)) if ok else np.array([999.0])
    # the burst crosses the threshold ~1-2 ms after its start (rise + 2 ms smoothing): report the bias
    print(json.dumps({'selftest': 'pass' if ok and err.max() < 4 else 'FAIL', 'taps': len(truth), 'paired': len(lat),
                      'bias_ms': round(float((lat - np.array(truth)).mean()), 2) if ok else None, 'max_abs_error_ms': round(float(err.max()), 2)}))
    return 0 if ok and err.max() < 4 else 1

def main(a):
    if '--selftest' in a: return selftest()
    if '--continuity' in a:
        for f in [x for x in a if x.endswith('.wav')]: print(json.dumps(continuity(f)))
        return 0
    files = [x for x in a if x.endswith('.wav')]
    res = {}
    rows = []
    for f in files:
        r, lat = analyse(f, '--single' in a); print(json.dumps(r)); res[f] = r
        rows += [(f, i, round(float(v), 3)) for i, v in enumerate(lat)]
    for f, r in res.items():
        if 'godot' in f:
            g = f.replace('godot', 'native')
            if g in res and 'p95_ms' in r and 'p95_ms' in res[g]:
                d = r['p95_ms'] - res[g]['p95_ms']
                print(json.dumps({'compare': [f, g], 'godot_minus_native_p95_ms': round(d, 2),
                                  'spike1_criterion_8ms': 'pass' if d <= 8 else 'FAIL'}))
    if '--csv' in a:
        with open(a[a.index('--csv') + 1], 'w') as c:
            c.write('file,tap,latency_ms\n'); c.writelines(f'{x},{y},{z}\n' for x, y, z in rows)
    return 0

if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
