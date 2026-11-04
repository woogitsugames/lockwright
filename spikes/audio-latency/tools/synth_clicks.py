#!/usr/bin/env python3
"""Own click samples for spike 3: modal synthesis (sum of damped sinusoids excited by a short
noise burst), 48 kHz, 16-bit mono WAV. Brass and steel x set, false_set, break, contact, plus a
1 ms measurement impulse with a hard attack. Deterministic (fixed seed).
   python3 tools/synth_clicks.py samples/"""
import sys, os, wave
import numpy as np

SR = 48000
rng = np.random.default_rng(20261104)

# (frequency Hz, decay s, amplitude) — invented "small machined part" modes, not measured from anything.
MAT = {
    'brass': {'modes': [(2350, .070, 1.0), (3480, .055, .55), (5120, .040, .35), (7900, .022, .2), (1180, .09, .25)], 'noise': .35},
    'steel': {'modes': [(3900, .050, 1.0), (6100, .040, .6), (8300, .030, .45), (11200, .018, .25), (2050, .06, .2)], 'noise': .25},
}

def env_noise(n, attack=0.0004, decay=0.002):
    t = np.arange(n) / SR
    return rng.standard_normal(n) * np.minimum(t / attack, 1.0) * np.exp(-t / decay)

def modal(mat, dur, gain=1.0, pitch=1.0, damp=1.0, low=0.0, start=0):
    n = int(dur * SR); t = np.arange(n) / SR
    x = np.zeros(n)
    for f, d, a in MAT[mat]['modes']:
        ph = rng.uniform(0, 2 * np.pi)
        x += a * np.sin(2 * np.pi * f * pitch * t + ph) * np.exp(-t / (d * damp))
    x *= np.minimum(t / 0.0003, 1.0)
    x += MAT[mat]['noise'] * env_noise(n)
    if low:
        x += low * np.sin(2 * np.pi * 420 * t) * np.exp(-t / 0.035) * np.minimum(t / 0.002, 1)
    out = np.zeros(n + start); out[start:] = x * gain
    return out

def mix(*parts):
    n = max(len(p) for p in parts); out = np.zeros(n)
    for p in parts: out[:len(p)] += p
    return out

def write(path, x, peak=0.8):
    x = x / max(1e-9, np.abs(x).max()) * peak
    x = np.concatenate([x, np.zeros(int(0.005 * SR))])  # short tail of silence
    with wave.open(path, 'wb') as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes((np.clip(x, -1, 1) * 32767).astype('<i2').tobytes())

def main(out):
    os.makedirs(out, exist_ok=True)
    for mat in MAT:
        # set: sharp click 15-25 ms (TECH.md §3.3)
        write(f'{out}/set_{mat}.wav', modal(mat, .12, damp=.35), .85)
        # false_set: the same click family + quiet low "body" 28 ms later (-4 semitones, longer tail)
        fs = mix(modal(mat, .12, damp=.35), modal(mat, .14, gain=.3, pitch=2 ** (-4 / 12), damp=.6, low=.6, start=int(.028 * SR)))
        write(f'{out}/false_set_{mat}.wav', fs, .85)
        # break: dry crack 40 ms + fragment bounce 120 ms later
        br = mix(modal(mat, .08, damp=.5) + 1.6 * env_noise(int(.08 * SR), decay=.006),
                 modal(mat, .06, gain=.35, pitch=1.4, damp=.3, start=int(.12 * SR)))
        write(f'{out}/break_{mat}.wav', br, .9)
        # contact: quiet tick 10-15 ms
        write(f'{out}/contact_{mat}.wav', modal(mat, .04, damp=.15), .45)
    # measurement impulse: 1 ms, flat attack (onset detectable at -30 dBFS within one sample)
    imp = np.zeros(int(.03 * SR)); k = int(.001 * SR)
    imp[:k] = np.sin(np.linspace(0, np.pi, k)) * np.sign(np.sin(2 * np.pi * 3000 * np.arange(k) / SR) + 1e-9)
    write(f'{out}/impulse.wav', imp, .95)
    print('wrote', sorted(os.listdir(out)))

if __name__ == '__main__':
    main(sys.argv[1] if len(sys.argv) > 1 else 'samples')
