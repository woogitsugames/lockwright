#!/usr/bin/env python3
"""Touch -> sound latency from a 2-channel recording (spike 3, docs/TECH.md §2.4 and §4).

Recording: 48 kHz (or higher) stereo WAV from an audio interface.
  channel 1 (left)  = contact mic / piezo taped to the screen next to the touch point (finger tap impulse)
  channel 2 (right) = measurement mic 1-2 cm from the phone speaker (the click)

  python3 tools/measure.py rec_oboe.wav [rec_godot.wav ...] [--tap-ch 0 --mic-ch 1] [--thresh-db -30]
                           [--min-ms 3 --max-ms 300] [--csv out.csv] [--plot out.png]
  python3 tools/measure.py --selftest

Method: both channels are high-passed (>= 300 Hz, removes handling rumble), rectified and smoothed
(0.25 ms); an onset is the first sample above max(thresh_db, noise floor + 20 dB) after at least
`--refractory-ms` of quiet. Each tap is paired with the first mic onset `min-ms`..`max-ms` later
(the tap's own acoustic sound reaches the mic in < 1 ms and is skipped by min-ms). Reports n, p50,
p95, mean, min, max and unpaired taps per file. Resolution: one sample (0.02 ms at 48 kHz)."""
import sys, wave, json
import numpy as np

def read_wav(path):
    with wave.open(path, 'rb') as w:
        sr, ch, sw, n = w.getframerate(), w.getnchannels(), w.getsampwidth(), w.getnframes()
        raw = w.readframes(n)
    if sw == 2:
        x = np.frombuffer(raw, '<i2').astype(np.float64) / 32768
    elif sw == 3:
        b = np.frombuffer(raw, np.uint8).reshape(-1, 3)
        x = ((b[:, 0].astype(np.int32) | (b[:, 1].astype(np.int32) << 8) | (b[:, 2].astype(np.int32) << 16)) << 8 >> 8) / 8388608
    elif sw == 4:
        x = np.frombuffer(raw, '<i4').astype(np.float64) / 2147483648
    else:
        raise SystemExit(f'unsupported sample width {sw}')
    return sr, x.reshape(-1, ch)

def highpass(x, sr, fc=300.0):
    # 4th-order high-pass in the frequency domain (zero phase: does not shift the onset)
    n = len(x); X = np.fft.rfft(x); f = np.fft.rfftfreq(n, 1 / sr)
    X *= 1.0 / np.sqrt(1.0 + (fc / np.maximum(f, 1e-9)) ** 8)
    return np.fft.irfft(X, n)

def envelope(x, sr, ms=0.25):
    k = max(1, int(sr * ms / 1000))
    return np.convolve(np.abs(x), np.ones(k) / k, mode='same')

def onsets(x, sr, thresh_db, refractory_ms):
    e = envelope(highpass(x, sr), sr)
    floor = np.percentile(e, 50) + 1e-12
    thr = max(10 ** (thresh_db / 20), floor * 10)  # >= floor + 20 dB
    idx = np.flatnonzero(e > thr)
    if len(idx) == 0:
        return np.array([], dtype=int), thr
    quiet = int(sr * refractory_ms / 1000)
    gaps = np.diff(idx, prepend=-quiet - 1)
    out = idx[gaps > quiet]  # first loud sample after at least `quiet` samples below threshold
    return np.array(out), thr

def analyse(path, tap_ch=0, mic_ch=1, thresh_db=-30.0, min_ms=3.0, max_ms=300.0, refractory_ms=150.0):
    sr, x = read_wav(path)
    taps, t_thr = onsets(x[:, tap_ch], sr, thresh_db, refractory_ms)
    e = envelope(highpass(x[:, mic_ch], sr), sr)
    m_thr = max(10 ** (thresh_db / 20), (np.percentile(e, 50) + 1e-12) * 10)
    lat, unpaired = [], 0
    for t in taps:
        a, b = int(t + sr * min_ms / 1000), int(t + sr * max_ms / 1000)
        seg = e[a - 1:b] > m_thr
        rise = np.flatnonzero(seg[1:] & ~seg[:-1])  # first upward crossing after min_ms
        if len(rise):
            lat.append((a + rise[0] - t) * 1000.0 / sr)
        else:
            unpaired += 1
    lat = np.array(lat)
    analyse.tap_times = taps / sr
    r = {'file': path, 'sample_rate': sr, 'taps': int(len(taps)), 'paired': int(len(lat)), 'unpaired': unpaired}
    if len(lat):
        r.update({'p50_ms': round(float(np.percentile(lat, 50)), 2), 'p95_ms': round(float(np.percentile(lat, 95)), 2),
                  'mean_ms': round(float(lat.mean()), 2), 'min_ms': round(float(lat.min()), 2),
                  'max_ms': round(float(lat.max()), 2), 'std_ms': round(float(lat.std()), 2)})
    return r, lat

def selftest():
    """Synthetic recording with known delays: taps (broadband impulse) + clicks (damped 3 kHz) with noise."""
    import tempfile, os
    sr = 48000; rng = np.random.default_rng(1)
    n = sr * 20; x = rng.normal(0, 0.002, (n, 2))
    truth = []
    t = int(0.5 * sr)
    while t < n - sr:
        d = rng.uniform(8, 120); truth.append(d)
        k = np.arange(int(0.004 * sr))
        x[t:t + len(k), 0] += 0.6 * rng.standard_normal(len(k)) * np.exp(-k / (0.0006 * sr))
        x[t:t + 30, 1] += 0.05 * rng.standard_normal(30)          # acoustic tap leaking into the mic
        c = t + int(round(d * sr / 1000))
        k2 = np.arange(int(0.03 * sr))
        x[c:c + len(k2), 1] += 0.5 * np.sin(2 * np.pi * 3000 * k2 / sr) * np.exp(-k2 / (0.008 * sr))
        x[c:c + len(k2), 0] += 0.03 * np.sin(2 * np.pi * 3000 * k2 / sr) * np.exp(-k2 / (0.008 * sr))  # speaker in piezo
        t += int(rng.uniform(0.45, 0.7) * sr)
    path = os.path.join(tempfile.mkdtemp(), 'selftest.wav')
    with wave.open(path, 'wb') as w:
        w.setnchannels(2); w.setsampwidth(2); w.setframerate(sr)
        w.writeframes((np.clip(x, -1, 1) * 32767).astype('<i2').tobytes())
    r, lat = analyse(path)
    err = np.abs(lat - np.array(truth[:len(lat)])) if len(lat) == len(truth) else np.array([999.0])
    ok = len(lat) == len(truth) and err.max() < 1.0
    print(json.dumps({'selftest': 'pass' if ok else 'FAIL', 'taps': len(truth), 'paired': len(lat),
                      'max_error_ms': round(float(err.max()), 3), 'mean_error_ms': round(float(err.mean()), 3)}))
    return 0 if ok else 1

def main(argv):
    if '--selftest' in argv:
        return selftest()
    def opt(name, d):
        return type(d)(argv[argv.index(name) + 1]) if name in argv else d
    files = [a for i, a in enumerate(argv) if a.endswith('.wav') and (i == 0 or not argv[i - 1].startswith('--'))]
    rows = []
    for f in files:
        r, lat = analyse(f, opt('--tap-ch', 0), opt('--mic-ch', 1), opt('--thresh-db', -30.0), opt('--min-ms', 3.0),
                         opt('--max-ms', 300.0), opt('--refractory-ms', 150.0))
        print(json.dumps(r))
        rows += [(f, i, round(float(v), 3)) for i, v in enumerate(lat)]
    if '--csv' in argv:
        with open(argv[argv.index('--csv') + 1], 'w') as c:
            c.write('file,tap,latency_ms\n'); c.writelines(f'{a},{b},{v}\n' for a, b, v in rows)
    if '--plot' in argv:
        import matplotlib; matplotlib.use('Agg'); import matplotlib.pyplot as plt
        fig, ax = plt.subplots(figsize=(7, 3.2))
        for f in files:
            ax.hist([v for a, _, v in rows if a == f], bins=40, alpha=.6, label=f.split('/')[-1])
        ax.set_xlabel('touch -> sound [ms]'); ax.legend(); fig.tight_layout(); fig.savefig(argv[argv.index('--plot') + 1], dpi=150)
    return 0

if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
