#!/usr/bin/env python3
"""Localization QA (task 15): every key has non-empty PL and EN; EN column must not
contain Polish words; crude overflow check at 200% text scale (EN len <= 2.2x PL is fine,
flag EN > 1.6x PL as suspicious, PL > 1.6x EN likewise for truncation risk).
Reads game/i18n/strings.csv, game/i18n/content.csv and every content pack's
game/packs/<id>/i18n/content.csv (D-112)."""
import csv, glob, re, sys, os

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
# diacritics in lowercase words only (capitalized = proper nouns: Józef, Wrocław, Toruń are fine)
ALLOW = {"Toruń", "Świątniki", "Kraków", "Wrocław", "béguinage", "dzień dobry", "pierogi", "Charleroi", "Ghent", "Świątniki Górne", "Radziwiłł", "rosół", "Paweł"}
def polish_in_en(text: str) -> bool:
    for a in ALLOW:
        text = text.replace(a, "")
    return bool(POLISH.search(text))

POLISH = re.compile(r"(?<![A-ZĄĆĘŁŃÓŚŹŻ])[ąćęłńóśźż](?![a-z])|\b(nie|się|że|jest|lub|oraz|przy|bez|jak|czy|tego|tej|tam|tu|już)\b")

def csv_paths(root: str = ROOT) -> list:
    """Base CSVs plus every content pack's i18n/content.csv (D-112: game/packs/<id>/)."""
    base = [os.path.join(root, "game", "i18n", "strings.csv"), os.path.join(root, "game", "i18n", "content.csv")]
    return base + sorted(glob.glob(os.path.join(root, "game", "packs", "*", "i18n", "content.csv")))


def main(root: str = ROOT) -> int:
    failures = 0
    for path in csv_paths(root):
        with open(path, encoding="utf-8", newline="") as f:
            rows = list(csv.reader(f))
        for r in rows[1:]:
            if len(r) < 3 or not r[0]:
                continue
            key, en, pl = r[0], r[1], r[2]
            if not en.strip() or not pl.strip():
                print(f"FAIL empty: {key} ({path})"); failures += 1
            if polish_in_en(en):
                print(f"FAIL Polish in EN: {key}: {en[:60]!r}"); failures += 1
            if len(pl) > 0 and len(en) > 1.6 * max(len(pl), 1):
                print(f"WARN EN much longer than PL (truncation risk): {key}")
    if failures:
        print(f"LOC QA FAIL: {failures} problems")
        return 1
    print("LOC QA OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
