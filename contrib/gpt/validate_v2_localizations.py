#!/usr/bin/env python3
"""Check seven v2 localization drafts against source CSV and store character limits.

Run at repository root: python contrib/gpt/validate_v2_localizations.py
No third-party dependencies. Exit 1 on missing keys or errors.
"""
import argparse
import csv
import json
import re
import sys
from pathlib import Path

LANGUAGES = {
    "fr": "T31", "es": "T32", "it": "T33", "pt_br": "T34",
    "cs": "T35", "uk": "T36", "de": "T37",
}
PLACEHOLDERS = re.compile(r"\{[A-Za-z_0-9]+\}")
STORE = re.compile(
    r"<!--\s*field:\s*(\S+)\s+max=(\d+)[^>]*-->\s*"
    r"(?:[^\x60]*?)\x60{3}(?:text)?\s*\n([\s\S]*?)\n\x60{3}", re.M,
)


def read_csv(path):
    with path.open(encoding="utf-8-sig", newline="") as f:
        reader = csv.DictReader(f)
        return reader.fieldnames or [], list(reader)


def analyze(root):
    base = {}
    for part in ("strings", "content"):
        header, rows = read_csv(root / "game/i18n" / (part + ".csv"))
        if header[:2] != ["keys", "en"]:
            raise ValueError("Source header changed: " + part)
        keys = [row["keys"] for row in rows]
        if len(keys) != len(set(keys)):
            raise ValueError("Duplicate source keys: " + part)
        base[part] = {row["keys"]: row["en"] for row in rows}
    summary = {"source_counts": {k: len(v) for k, v in base.items()}, "languages": {}}
    for lang, task in LANGUAGES.items():
        record = {"task": task, "parts": {}, "store_fields": 0, "errors": []}
        for part in ("strings", "content"):
            path = root / "contrib/gpt" / task / (part + "_" + lang + "_v2.csv")
            try:
                header, rows = read_csv(path)
            except OSError as exc:
                record["errors"].append(str(exc))
                continue
            expected_header = ["key", lang + "_old", lang + "_new", "note"]
            if header != expected_header:
                record["errors"].append(part + ": invalid header")
            seen = set()
            for row in rows:
                key = row.get("key") or ""
                old = row.get(lang + "_old") or ""
                new = row.get(lang + "_new") or ""
                note = row.get("note") or ""
                if key in seen:
                    record["errors"].append(part + ": duplicate " + key)
                seen.add(key)
                if key not in base[part]:
                    record["errors"].append(part + ": extra key " + key)
                    continue
                if not new.strip():
                    record["errors"].append(part + ": blank " + key)
                if sorted(PLACEHOLDERS.findall(base[part][key])) != sorted(PLACEHOLDERS.findall(new)):
                    record["errors"].append(part + ": placeholders " + key)
                if old != new and not note.strip():
                    record["errors"].append(part + ": no rationale " + key)
                if part == "content":
                    if re.search(r"\.(?:line|after)\.\d+$", key) and len(new) > 90:
                        record["errors"].append(part + ": dialog >90 " + key)
                    if (key.endswith(".note") or key.startswith("notebook.")) and len(new) > 130:
                        record["errors"].append(part + ": notebook >130 " + key)
            missing = sorted(set(base[part]) - seen)
            record["parts"][part] = {
                "source_keys": len(base[part]), "draft_keys": len(seen),
                "missing": missing,
            }
        store_path = root / "contrib/gpt" / task / ("store_" + lang + "_v2.md")
        try:
            fields = list(STORE.finditer(store_path.read_text(encoding="utf-8")))
            record["store_fields"] = len(fields)
            names = set()
            if len(fields) < 10:
                record["errors"].append("Store: fewer than 10 fields parsed")
            for match in fields:
                name, rawlimit, value = match.groups()
                limit = int(rawlimit)
                if name in names:
                    record["errors"].append("Store: duplicate " + name)
                names.add(name)
                size = len(value.encode("utf-8")) if name.endswith(".keywords") else len(value)
                if size > limit:
                    record["errors"].append("Store: over limit " + name)
        except OSError as exc:
            record["errors"].append(str(exc))
        summary["languages"][lang] = record
    summary["pass"] = all(
        not row["errors"] and all(not x["missing"] for x in row["parts"].values())
        for row in summary["languages"].values()
    )
    return summary


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path("."))
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()
    results = analyze(args.root)
    if args.json:
        print(json.dumps(results, ensure_ascii=False, indent=2))
    else:
        print("Lockwright T31–T37 localization QA")
        print("Source keys:", results["source_counts"], "PASS:", results["pass"])
        print("LANG | UI | Content | Missing UI | Missing content | Store | Errors")
        for lang, row in results["languages"].items():
            s = row["parts"].get("strings", {})
            c = row["parts"].get("content", {})
            print(lang, s.get("draft_keys", 0), c.get("draft_keys", 0),
                  len(s.get("missing", [])), len(c.get("missing", [])),
                  row["store_fields"], len(row["errors"]), sep=" | ")
            if s.get("missing"):
                print("Missing", lang, "strings:", ", ".join(s["missing"]))
            if c.get("missing"):
                print("Missing", lang, "content:", ", ".join(c["missing"]))
            for error in row["errors"]:
                print("ERROR:", lang, error)
    return 0 if results["pass"] else 1


if __name__ == "__main__":
    sys.exit(main())
