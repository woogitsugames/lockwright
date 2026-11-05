#!/usr/bin/env python3
"""Import S03v2 episodic speaker voices into the game (Ogg Vorbis, mono, q~4).

    python3 tools/import_episodic_voices.py                # default source below
    python3 tools/import_episodic_voices.py --src contrib/gpt/S03v2-py   # A/B set
    python3 tools/import_episodic_voices.py --quality 3    # smaller package

Writes game/assets/audio/voices/<id>/<emotion>.ogg for every speaker folder in
<src>/voices (the 12 cast voices stay .wav and are not touched). Requires ffmpeg.
"""
import argparse
import pathlib
import subprocess
import sys

# One-line switch between voice sets (owner A/B listening): S03v2 (JS) or S03v2-py.
VOICE_SRC = "contrib/gpt/S03v2"
OGG_QUALITY = 4
EMOTIONS = ["greeting", "surprise", "relief", "thanks", "impatient", "sad", "laugh", "goodbye"]

ROOT = pathlib.Path(__file__).resolve().parent.parent
DEST = ROOT / "game/assets/audio/voices"


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--src", default=VOICE_SRC)
    ap.add_argument("--quality", type=float, default=OGG_QUALITY)
    args = ap.parse_args()
    src = (ROOT / args.src / "voices").resolve()
    if not src.is_dir():
        print(f"missing {src}", file=sys.stderr)
        return 1
    count = 0
    for spk in sorted(p for p in src.iterdir() if p.is_dir()):
        out = DEST / spk.name
        out.mkdir(parents=True, exist_ok=True)
        for emo in EMOTIONS:
            wav = spk / f"{emo}.wav"
            if not wav.exists():
                print(f"warning: {wav} missing (play_voice falls back to greeting)")
                continue
            ogg = out / f"{emo}.ogg"
            subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-i", str(wav), "-ac", "1",
                            "-c:a", "libvorbis", "-q:a", str(args.quality), "-map_metadata", "-1",
                            str(ogg)], check=True)
            count += 1
    (DEST / "EPISODIC_SOURCE.txt").write_text(f"{args.src} q={args.quality}\n")
    print(f"{count} files from {args.src} -> {DEST.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
