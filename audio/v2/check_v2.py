#!/usr/bin/env python3
"""Checker for audio/v2/out (synth_v2.py output). Exits non-zero on any failure.

Per file: 48 kHz / 16-bit / mono PCM; peak = -1 dBFS + GAIN_DB[event] (+-0.5 dB);
onset (first sample >= -30 dB of peak) <= 96 samples (2 ms); first sample is not a
step; no clipping; no DC offset; ends at silence; duration in the event window;
loops: smpl forward loop over the whole file, length 1.0-1.5 s, no seam click,
RMS ~ -18 dBFS; 4-6 contiguous variants per event x material; manifest hashes.
Report: gated RMS per event (relative levels), set vs false_set distinguishability,
EBU loudness (M_max / true peak) per lock event.
Part 2 (world.py): ambience loops (32 kHz, 30-60 s, smpl, seamless wrap, integrated
loudness), UI and reward one-shots (48 kHz, durations, onset <= 5 ms, momentary or
integrated loudness, true-peak ceilings) and the mix hierarchy (lock events win).

Usage: python3 audio/v2/check_v2.py [--out audio/v2/out] [--determinism]
"""

import argparse
import glob
import hashlib
import json
import math
import os
import struct
import subprocess
import sys
import tempfile
import wave

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import synth_v2 as S  # noqa: E402
import loudness as L  # noqa: E402
import world as W  # noqa: E402

SR = S.SR
fails = []


def fail(msg):
    fails.append(msg)


def read_wav(path):
    with wave.open(path, "rb") as w:
        fmt = (w.getnchannels(), w.getsampwidth(), w.getframerate(), w.getcomptype())
        pcm = np.frombuffer(w.readframes(w.getnframes()), dtype="<i2")
    return fmt, pcm


def read_smpl(path):
    b = open(path, "rb").read()
    i = 12
    while i + 8 <= len(b):
        cid, size = b[i:i + 4], struct.unpack("<I", b[i + 4:i + 8])[0]
        if cid == b"smpl":
            body = b[i + 8:i + 8 + size]
            nloops = struct.unpack("<I", body[28:32])[0]
            if nloops < 1:
                return None
            _cue, typ, start, end, _f, _pc = struct.unpack("<6I", body[36:60])
            return typ, start, end
        i += 8 + size + (size & 1)
    return None


def seam_excess_db(x):
    """Click at the wrap = 2nd-order prediction residual at the seam beyond the
    signal's own 99.9th-percentile residual (a seamless loop has no excess)."""
    r = np.abs(x[2:] - 2 * x[1:-1] + x[:-2])
    seam = max(abs(x[0] - 2 * x[-1] + x[-2]), abs(x[1] - 2 * x[0] + x[-1]))
    ref = float(np.percentile(r, 99.9))
    excess = max(0.0, seam - ref)
    step = abs(x[0] - x[-1])
    pct = 100.0 * float(np.mean(np.abs(np.diff(x)) < step))  # rank of the wrap step among interior steps
    return S.db(excess) if excess > 0 else -200.0, pct, S.db(step)


def local_seam_excess_db(x, sr, win=0.1):
    """Like seam_excess_db, but against the residuals within +-100 ms of the wrap only (a long ambience
    has loud transients elsewhere that would hide a click at the seam in a whole-file percentile)."""
    w = int(win * sr)
    y = np.concatenate([x[-w:], x[:w]])  # the wrap sits between y[w-1] and y[w]
    r = np.abs(y[2:] - 2 * y[1:-1] + y[:-2])
    seam = max(r[w - 2], r[w - 1])
    ref = float(np.percentile(np.delete(r, [w - 2, w - 1]), 99.9))
    return S.db(seam - ref) if seam > ref else -200.0


def centroid(x):
    X = np.abs(np.fft.rfft(x * np.hanning(len(x)), 1 << 15)) ** 2
    f = np.fft.rfftfreq(1 << 15, 1 / SR)
    return float(np.sum(f * X) / np.sum(X))


def late_energy_db(x, t=0.025):
    i = int(t * SR)
    return 10 * math.log10(max(float(np.sum(x[i:] ** 2)), 1e-20) / float(np.sum(x ** 2)))


def phone(x):
    """Crude phone speaker: 2nd-order HP 500 Hz + LP 9 kHz."""
    return S.lp(S.hp(x, 500.0, 2), 9000.0, 1)


def check_world(out, man, lock_m):
    """Part 2: ambience loops, UI one-shots, rewards (world.py) + mix hierarchy."""
    by_file = {f["file"]: f for f in man.get("world_files", [])}
    if not by_file:
        fail("manifest: no world_files (re-run synth_v2.py)")
        return
    expected = {f"ambience/{n}.wav": ("ambience", n, "ambience", None) for n in W.AMBIENCE}
    for cat, table in (("ui", W.UI), ("reward", W.REWARDS)):
        for name, (tkey, nv, rng_) in table.items():
            for v in range(1, nv + 1):
                expected[f"{cat}/{name}_{v}.wav"] = (cat, name, tkey, rng_)
    found = {os.path.relpath(p, out) for d in ("ambience", "ui", "reward")
             for p in glob.glob(os.path.join(out, d, "*.wav"))}
    for rel in sorted(found - set(expected)):
        fail(f"{rel}: unexpected file")
    for rel in sorted(set(expected) - found):
        fail(f"{rel}: missing")
    stats = {}
    seams = []
    for rel in sorted(set(expected) & found):
        cat, name, tkey, dur_rng = expected[rel]
        p = os.path.join(out, rel)
        loop = cat == "ambience"
        sr = W.AMB_SR if loop else SR
        fmt, pcm = read_wav(p)
        if fmt != (1, 2, sr, "NONE"):
            fail(f"{rel}: format {fmt}, want mono/16-bit/{sr}/PCM")
            continue
        blob = open(p, "rb").read()
        if rel not in by_file or by_file[rel]["sha256"] != hashlib.sha256(blob).hexdigest():
            fail(f"{rel}: sha256 differs from manifest")
        x = pcm.astype(float) / 32767.0
        pk = float(np.max(np.abs(x)))
        if np.any(pcm >= 32767) or np.any(pcm <= -32767):
            fail(f"{rel}: clipping")
        if abs(float(np.mean(x))) > 10 ** (-60 / 20):
            fail(f"{rel}: DC offset {S.db(abs(np.mean(x))):.1f} dBFS")
        dur = len(x) / sr
        t = W.TARGETS[tkey]
        meas = {"I": L.integrated(x, sr, circular=loop), "M": L.momentary_max(x, sr, circular=loop),
                "S": L.short_term_max(x, sr, circular=loop), "TP": L.true_peak_db(x, circular=loop)}
        v = meas[t["measure"]]
        if abs(v - t["target"]) > t["tol"]:
            fail(f"{rel}: {t['measure']} {v:.1f} LUFS, want {t['target']:.1f} +-{t['tol']}")
        if "s_max" in t and meas["S"] > t["s_max"]:
            fail(f"{rel}: short-term max {meas['S']:.1f} LUFS > {t['s_max']}")
        if "m_max" in t and meas["M"] > t["m_max"]:
            fail(f"{rel}: momentary max {meas['M']:.1f} LUFS > {t['m_max']}")
        if meas["TP"] > t["tp_max"]:
            fail(f"{rel}: true peak {meas['TP']:.1f} dBTP > {t['tp_max']}")
        stats.setdefault(tkey, []).append(meas)
        if loop:
            if not 29.5 <= dur <= 60.5:
                fail(f"{rel}: ambience length {dur:.2f}s (30-60 s)")
            sm = read_smpl(p)
            if sm is None or sm[0] != 0 or sm[1] != 0 or sm[2] != len(x) - 1:
                fail(f"{rel}: smpl loop chunk missing/wrong {sm}")
            ex, rank, step = seam_excess_db(x)
            # no level jump over the wrap: K-weighted energy 50 ms before vs after the seam
            k = L.kweight(x, sr, circular=True)
            w = int(0.05 * sr)
            jump = 10 * math.log10((np.mean(k[:w] ** 2) + 1e-20) / (np.mean(k[-w:] ** 2) + 1e-20))
            lex = local_seam_excess_db(x, sr)
            seams.append((rel, max(ex, lex), rank, step, jump))
            if ex >= -40:
                fail(f"{rel}: loop seam excess {ex:.1f} dBFS (>= -40)")
            if lex >= -50:
                fail(f"{rel}: loop seam excess vs +-100 ms around the wrap {lex:.1f} dBFS (>= -50)")
            if rank > 99.5:
                fail(f"{rel}: wrap step is an outlier (p{rank:.1f})")
            if abs(jump) > 6.0:
                fail(f"{rel}: level jump over the wrap {jump:+.1f} dB")
            continue
        lo, hi = dur_rng
        if not lo <= dur <= hi:
            fail(f"{rel}: duration {dur:.3f}s outside {lo}-{hi} s")
        on = int(np.argmax(np.abs(x) >= pk * 10 ** (-30 / 20)))
        lim = W.UI_ONSET_MAX if cat == "ui" else W.REWARD_LEAD_MAX
        if on > lim:
            fail(f"{rel}: onset {on} samples > {lim}")
        if abs(x[0]) > pk * 0.1:
            fail(f"{rel}: first sample is a step")
        if abs(x[-1]) > 10 ** (-50 / 20):
            fail(f"{rel}: does not end in silence")

    print("Part 2 loudness (EBU R128 / BS.1770, mean [min..max] over files):")
    print(f"  {'category':13s} {'n':>3s} {'I LUFS':>18s} {'M_max LUFS':>18s} {'S_max LUFS':>18s} {'TP max':>7s}  target")
    for tkey, ms in stats.items():
        t = W.TARGETS[tkey]

        def col(k):
            v = [m[k] for m in ms]
            return f"{np.mean(v):6.1f} [{min(v):5.1f}..{max(v):5.1f}]"
        print(f"  {tkey:13s} {len(ms):3d} {col('I')} {col('M')} {col('S')} {max(m['TP'] for m in ms):7.1f}  "
              f"{t['measure']} {t['target']:.1f} +-{t['tol']}, TP <= {t['tp_max']}")
    for rel, ex, rank, step, jump in seams:
        print(f"  seam {rel:28s} click excess (whole file / +-100 ms) {ex:7.1f} dBFS, wrap step p{rank:4.1f}, "
              f"level jump {jump:+.2f} dB")

    # mix hierarchy (README "Miks"): lock events win
    if lock_m:
        ref = float(np.mean([lock_m[e] for e in ("open", "break")]))
        rew = max(m["M"] for k in ("reward", "reward_motif") for m in stats.get(k, []))
        ui = max(m["M"] for m in stats.get("ui", []))
        phone = max(m["M"] for m in stats.get("ui_phone", []))
        amb = max(m["I"] for m in stats.get("ambience", []))
        amb_m = max(m["M"] for m in stats.get("ambience", []))
        print(f"Mix hierarchy: lock open/break M {ref:.1f}, set M {lock_m['set']:.1f} | rewards M max {rew:.1f} | "
              f"UI M max {ui:.1f}, phone {phone:.1f} | ambience I max {amb:.1f}, M max {amb_m:.1f} LUFS")
        if rew > ref:
            fail(f"mix: a reward ({rew:.1f}) is louder than open/break ({ref:.1f})")
        if ui > lock_m["set"] - 2.0:
            fail(f"mix: UI ({ui:.1f}) not >= 2 LU below set ({lock_m['set']:.1f})")
        if phone > ref - 3.0:
            fail(f"mix: phone ({phone:.1f}) not >= 3 LU below open/break ({ref:.1f})")
        if amb > ref - 10.0 or amb_m > lock_m["set"] - 1.0:
            fail(f"mix: ambience too close to lock events (I {amb:.1f}, M {amb_m:.1f})")


def lock_loudness(data):
    """Momentary max (400 ms) per lock event, mean over materials x variants; loops: integrated (circular)."""
    m, tp = {}, {}
    for key, val in data.items():
        ev = key[0]
        x = val[0] if ev in S.LOOPS else val
        if ev in S.LOOPS:
            m.setdefault(ev, []).append(L.integrated(x, SR, circular=True))
            tp.setdefault(ev, []).append(L.true_peak_db(x, circular=True))
        else:
            m.setdefault(ev, []).append(L.momentary_max(x, SR))
            tp.setdefault(ev, []).append(L.true_peak_db(x))
    return {e: float(np.mean(v)) for e, v in m.items()}, {e: float(np.max(v)) for e, v in tp.items()}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=os.path.join(HERE, "out"))
    ap.add_argument("--determinism", action="store_true", help="re-render into a temp dir and compare hashes")
    a = ap.parse_args()
    out = os.path.abspath(a.out)
    sfx = os.path.join(out, "sfx")
    man = json.load(open(os.path.join(out, "manifest.json")))
    by_file = {f["file"]: f for f in man["files"]}

    files = sorted(glob.glob(os.path.join(sfx, "*", "*.wav")))
    groups = {}
    rms = {}
    data = {}
    for p in files:
        event = os.path.basename(os.path.dirname(p))
        stem = os.path.splitext(os.path.basename(p))[0]
        mat, _, n = stem.rpartition("_")
        rel = f"{event}/{stem}.wav"
        tag = rel
        if event not in S.EVENT_MATERIALS or mat not in S.MATERIALS or not n.isdigit():
            fail(f"{tag}: unexpected file name")
            continue
        groups.setdefault((event, mat), []).append(int(n))
        fmt, pcm = read_wav(p)
        if fmt != (1, 2, SR, "NONE"):
            fail(f"{tag}: format {fmt}, want mono/16-bit/48k/PCM")
            continue
        blob = open(p, "rb").read()
        if rel not in by_file or by_file[rel]["sha256"] != hashlib.sha256(blob).hexdigest():
            fail(f"{tag}: sha256 differs from manifest")
        x = pcm.astype(float) / 32767.0
        n_s = len(x)
        pk = float(np.max(np.abs(x)))
        pk_db = S.db(pk)
        if np.any(pcm >= 32767) or np.any(pcm <= -32767):
            fail(f"{tag}: clipping")
        if abs(float(np.mean(x))) > 10 ** (-60 / 20):
            fail(f"{tag}: DC offset {S.db(abs(np.mean(x))):.1f} dBFS")
        is_loop = event in S.LOOPS
        dur = n_s / SR
        if is_loop:
            lo, hi = S.LOOP_DUR
            if not lo <= dur <= hi:
                fail(f"{tag}: loop length {dur:.3f}s")
            sm = read_smpl(p)
            if sm is None or sm[0] != 0 or sm[1] != 0 or sm[2] != n_s - 1:
                fail(f"{tag}: smpl loop chunk missing/wrong {sm}")
            ex, seam, step = seam_excess_db(x)
            if seam > 99.5:
                fail(f"{tag}: wrap step is an outlier (p{seam:.1f})")
            if ex >= -40:
                fail(f"{tag}: loop seam excess {ex:.1f} dBFS (>= -40)")
            r = 10 * math.log10(float(np.mean(x ** 2)))
            if abs(r - S.LOOP_RMS_DB) > 1.5 and pk_db < S.LOOP_PEAK_MAX_DB - 0.5:
                fail(f"{tag}: loop RMS {r:.1f} dBFS")
            if pk_db > S.LOOP_PEAK_MAX_DB + 0.5:
                fail(f"{tag}: loop peak {pk_db:.2f} dBFS")
            rms.setdefault(event, []).append(r)
            data[(event, mat, int(n))] = (x, seam, step, ex)
            continue
        target = S.PEAK_REF_DB + S.GAIN_DB[event]
        if abs(pk_db - target) > 0.5:
            fail(f"{tag}: peak {pk_db:.2f} dBFS, want {target:.1f} +-0.5")
        on = int(np.argmax(np.abs(x) >= pk * 10 ** (-30 / 20)))
        if on > 96:
            fail(f"{tag}: onset {on} samples ({on / SR * 1000:.2f} ms) > 2 ms")
        if abs(x[0]) > pk * 0.1:
            fail(f"{tag}: first sample is a step ({S.db(abs(x[0]) / pk):.1f} dB re peak)")
        if abs(x[-1]) > 10 ** (-50 / 20):
            fail(f"{tag}: does not end in silence")
        lo, hi = S.DUR_RANGE[event]
        if not lo <= dur <= hi:
            fail(f"{tag}: duration {dur * 1000:.1f} ms outside {lo * 1000:.0f}-{hi * 1000:.0f} ms")
        rms.setdefault(event, []).append(S.gated_rms_db(x))
        data[(event, mat, int(n))] = x

    for event, mats in S.EVENT_MATERIALS.items():
        for mat in mats:
            v = sorted(groups.get((event, mat), []))
            if not (4 <= len(v) <= 6) or v != list(range(1, len(v) + 1)):
                fail(f"{event}/{mat}: variants {v} (need 4-6, contiguous from 1)")

    # relative levels (gated RMS, 'LUFS-ish')
    mean_rms = {e: float(np.mean(v)) for e, v in rms.items() if e not in S.LOOPS}
    order = sorted(mean_rms, key=mean_rms.get, reverse=True)
    print("Gated RMS per event (dBFS, mean over materials x variants), loudest first:")
    for e in order:
        pk = S.PEAK_REF_DB + S.GAIN_DB[e]
        print(f"  {e:15s} rms {mean_rms[e]:6.1f}   peak {pk:5.1f}")
    for e in S.LOOPS:
        if e in rms:
            print(f"  {e:15s} rms {np.mean(rms[e]):6.1f}   (loop)")
    top = set(order[:4])
    bottom = set(order[-3:])
    if not {"break", "open"} <= top:
        fail(f"relative levels: break/open not among the 4 loudest ({order[:4]})")
    if not {"contact", "near_shear"} <= bottom:
        fail(f"relative levels: contact/near_shear not among the 3 quietest ({order[-3:]})")

    seams = [v for k, v in data.items() if k[0] in S.LOOPS]
    if seams:
        print(f"Loop seams ({len(seams)}): click excess at wrap (2nd-order residual above the signal's own "
              f"p99.9) worst {max(s[3] for s in seams):.1f} dBFS (limit -40); wrap step rank among interior "
              f"steps worst p{max(s[1] for s in seams):.0f}; raw step worst {max(s[2] for s in seams):.1f} dBFS")

    # set vs false_set distinguishability
    print("set vs false_set (mean over variants): centroid Hz | energy after 25 ms dB  [full / phone sim]")
    for mat in S.ALL_MATS:
        r = {}
        for ev in ("set", "false_set"):
            xs = [data[(ev, mat, n)] for n in range(1, 7) if (ev, mat, n) in data]
            r[ev] = (np.mean([centroid(x) for x in xs]), np.mean([late_energy_db(x) for x in xs]),
                     np.mean([centroid(phone(x)) for x in xs]), np.mean([late_energy_db(phone(x)) for x in xs]))
        s, f = r["set"], r["false_set"]
        print(f"  {mat:6s} set {s[0]:6.0f} | {s[1]:6.1f}   false {f[0]:6.0f} | {f[1]:6.1f}   "
              f"d_centroid {100 * (f[0] / s[0] - 1):+5.1f}% d_late {f[1] - s[1]:+5.1f} dB   "
              f"phone: d_centroid {100 * (f[2] / s[2] - 1):+5.1f}% d_late {f[3] - s[3]:+5.1f} dB")
        if not (f[0] < s[0] * 0.92 and f[1] - s[1] >= 3.0 and f[3] - s[3] >= 3.0):
            fail(f"set/false_set not distinguishable enough for {mat}")

    lock_m, lock_tp = lock_loudness(data)
    print("Lock events, EBU loudness: M_max LUFS (mean) / true peak max dBTP; loops: integrated (file level):")
    for e in sorted(lock_m, key=lock_m.get, reverse=True):
        print(f"  {e:18s} {'I' if e in S.LOOPS else 'M'} {lock_m[e]:6.1f}   TP {lock_tp[e]:5.1f}")
        if e not in S.LOOPS and lock_tp[e] > -0.3:
            # part 1 files are peak-normalised on samples; not changed here (hashes used by session B)
            print(f"  WARN {e}: true peak {lock_tp[e]:+.2f} dBTP > -0.3 (inter-sample over; see README, Miks)")
    for e, ref in (("open", S.LOCK_REF_LUFS_M), ("break", S.LOCK_REF_LUFS_M),
                   ("set", S.LOCK_SET_LUFS_M), ("false_set", S.LOCK_SET_LUFS_M)):
        if abs(lock_m.get(e, -99) - ref) > 1.5:
            fail(f"{e}: M_max {lock_m.get(e, -99):.1f} LUFS, want {ref} +-1.5 (lock reference)")
    check_world(out, man, lock_m)

    if a.determinism:
        with tempfile.TemporaryDirectory() as td:
            subprocess.run([sys.executable, os.path.join(HERE, "synth_v2.py"), "--seed", str(man["seed"]),
                            "--out", td], check=True, stdout=subprocess.DEVNULL)
            m2 = json.load(open(os.path.join(td, "manifest.json")))
            h1 = {f["file"]: f["sha256"] for f in man["files"] + man.get("world_files", [])}
            h2 = {f["file"]: f["sha256"] for f in m2["files"] + m2.get("world_files", [])}
            if h1 != h2:
                fail(f"determinism: {sum(h1.get(k) != v for k, v in h2.items())} files differ on re-render")
            else:
                print(f"Determinism: re-render with seed {man['seed']} is bit-identical ({len(h1)} files)")

    total = sum(os.path.getsize(p) for p in glob.glob(os.path.join(out, "**", "*"), recursive=True)
                if os.path.isfile(p))
    print(f"Files: {len(files)} wav in sfx/ + {len(man.get('world_files', []))} in ambience/ ui/ reward/, "
          f"output total {total / 1e6:.2f} MB")
    if total > 32e6:
        fail(f"output too large: {total / 1e6:.1f} MB")
    if fails:
        print(f"\nFAIL ({len(fails)}):")
        for m in fails[:60]:
            print("  " + m)
        sys.exit(1)
    print("\nOK: all checks passed")


if __name__ == "__main__":
    main()
