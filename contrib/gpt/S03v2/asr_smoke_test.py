#!/usr/bin/env python3
"""Optional ASR screening of S03v2 non-lexical clips, using faster-whisper.

No model weights or external recordings are bundled. Any recognized text is
flagged for human review. ASR silence does not establish absence of intelligible
words in every language.
"""
from __future__ import annotations
import argparse
import json
import sys
from pathlib import Path


def clips_from_manifest(root: Path):
    manifest = json.loads((root / "manifest.json").read_text(encoding="utf-8"))
    clips = []
    for person, files in manifest["characters"].items():
        if len(files) != 8:
            raise ValueError(f"{person}: expected 8 clips, got {len(files)}")
        for entry in files:
            rel = entry["file"]
            path = (root / rel).resolve()
            if root not in path.parents or not rel.startswith("voices/"):
                raise ValueError(f"Unsafe WAV path: {rel}")
            if not path.is_file():
                raise FileNotFoundError(path)
            clips.append((person, rel, path))
    if len(clips) != 312:
        raise ValueError(f"Expected 312 clips, got {len(clips)}")
    return clips


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parent)
    parser.add_argument("--model", default="tiny",
                        help="faster-whisper model name or local model path")
    parser.add_argument("--device", default="cpu", help="cpu or cuda")
    parser.add_argument("--language", default="auto",
                        help="auto or a language code such as en/pl/de")
    parser.add_argument("--limit", type=int, default=0,
                        help="0=all 312; otherwise a short smoke test")
    parser.add_argument("--output", type=Path, default=Path("ASR_REPORT.json"))
    parser.add_argument("--offline", action="store_true",
                        help="fail unless the model is already cached")
    args = parser.parse_args()
    root = args.root.resolve()
    try:
        clips = clips_from_manifest(root)
    except (OSError, KeyError, ValueError) as exc:
        print(f"Invalid input: {exc}", file=sys.stderr)
        return 2
    try:
        from faster_whisper import WhisperModel
    except ImportError:
        print("ASR NOT RUN: install faster-whisper first.", file=sys.stderr)
        return 2
    try:
        model = WhisperModel(args.model, device=args.device,
                             compute_type="int8" if args.device == "cpu" else "float16",
                             local_files_only=args.offline)
    except Exception as exc:
        print(f"ASR NOT RUN: model unavailable: {exc}", file=sys.stderr)
        return 2
    flagged = []
    checked = 0
    for person, rel, path in clips[:args.limit or len(clips)]:
        try:
            segments, info = model.transcribe(
                str(path), language=None if args.language == "auto" else args.language,
                beam_size=1, best_of=1, temperature=0,
                condition_on_previous_text=False, vad_filter=False,
            )
            segments = list(segments)
        except Exception as exc:
            print(f"ASR ERROR: {rel}: {exc}", file=sys.stderr)
            return 2
        checked += 1
        transcript = " ".join(s.text.strip() for s in segments).strip()
        if transcript:
            flagged.append({
                "character": person, "file": rel, "transcript": transcript,
                "language": info.language,
                "language_probability": round(info.language_probability, 3),
                "segments": len(segments),
            })
    result = {
        "status": "NEEDS_REVIEW" if flagged else
                  ("PARTIAL_SCREEN" if checked != 312 else "ASR_EMPTY"),
        "screened": checked, "total": 312, "model": args.model,
        "language": args.language, "flagged_count": len(flagged), "flagged": flagged,
        "disclaimer": "False positives and negatives are possible; human listening required.",
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n",
                           encoding="utf-8")
    print(f"ASR screened={checked}/312 flagged={len(flagged)} report={args.output}")
    return 1 if flagged else (0 if checked == 312 else 3)


if __name__ == "__main__":
    sys.exit(main())
