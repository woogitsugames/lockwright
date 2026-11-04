#!/usr/bin/env python3
"""Check store metadata limits in store/listing.md and rewrite its character-count table.

Fields are marked in listing.md as:
    <!-- field: <id> max=<N>[ bytes] -->
    ```
    text
    ```
Counts Unicode code points and UTF-8 bytes. Fields marked "bytes" are checked in bytes
(App Store keywords). Also checks keyword repetition and a few forbidden words.

Usage: python3 store/tools/check_lengths.py [--no-write]
"""
import re
import sys
import unicodedata
from pathlib import Path

LISTING = Path(__file__).resolve().parent.parent / "listing.md"
FIELD_RE = re.compile(r"<!-- field: (\S+) max=(\d+)( bytes)? -->\s*\n```\n(.*?)\n```", re.S)
FORBIDDEN = ["free", "darmow", "za darmo", "best", "najlepsz", "#1", "nr 1", "welcome", "get started",
             "unlock your", "epic", "ultimate", "heist", "burglar", "włam", "napad"]
# Words allowed inside longer texts even if they contain a forbidden substring.
ALLOWED_CONTEXT = {"as.pl.variant_a", "as.en.variant_a"}


def words(s):
    return {w for w in re.split(r"[^\wąćęłńóśźż]+", s.lower()) if w}


def has_emoji(s):
    return any(unicodedata.category(c) == "So" and ord(c) > 0x2600 for c in s)


def main():
    text = LISTING.read_text(encoding="utf-8")
    fields = {m.group(1): (int(m.group(2)), bool(m.group(3)), m.group(4)) for m in FIELD_RE.finditer(text)}

    # Composite fields: Play descriptions = App Store description with the haptics bullet swapped,
    # and descriptions with the optional business-model paragraph (variant A) inserted.
    for lang in ("pl", "en"):
        desc = fields[f"as.{lang}.description"][2]
        lines = desc.split("\n")
        idx = next(i for i, l in enumerate(lines) if l.startswith("• Hapty") or l.startswith("• Haptics"))
        lines[idx] = fields[f"gp.{lang}.haptics_line"][2]
        gp = "\n".join(lines)
        fields[f"gp.{lang}.description"] = (4000, False, gp)
        paras = desc.split("\n\n")
        va = fields[f"as.{lang}.variant_a"][2]
        fields[f"as.{lang}.description+A"] = (4000, False, "\n\n".join([paras[0], va] + paras[1:]))
        gparas = gp.split("\n\n")
        fields[f"gp.{lang}.description+A"] = (4000, False, "\n\n".join([gparas[0], va] + gparas[1:]))
        fields[f"gp.{lang}.whatsnew"] = (500, False, fields[f"as.{lang}.whatsnew"][2])
        if "ipad" in gp.lower() or "app store" in gp.lower():
            print(f"ERROR gp.{lang}.description mentions iPad/App Store")
        if "android" in desc.lower() or "google" in desc.lower():
            print(f"ERROR as.{lang}.description mentions Android/Google")

    rows, ok_all = [], True
    for fid, (limit, in_bytes, val) in fields.items():
        n_chars, n_bytes = len(val), len(val.encode("utf-8"))
        n = n_bytes if in_bytes else n_chars
        ok = n <= limit
        problems = []
        low = val.lower()
        if fid not in ALLOWED_CONTEXT and not fid.endswith("+A"):
            problems += [f"forbidden '{w}'" for w in FORBIDDEN if w in low]
        if has_emoji(val):
            problems.append("emoji")
        if re.search(r"\b[A-ZĄĆĘŁŃÓŚŹŻ]{5,}\b", val):
            problems.append("CAPS")
        if "keywords" in fid:
            if " " in val:
                problems.append("space in keywords")
            lang = fid.split(".")[1]
            taken = words(fields[f"as.{lang}.name"][2]) | words(fields[f"as.{lang}.subtitle"][2])
            kw = val.split(",")
            dup = [k for k in kw if k in taken]
            if dup:
                problems.append("repeats name/subtitle: " + ",".join(dup))
            if len(kw) != len(set(kw)):
                problems.append("duplicate keyword")
        ok = ok and not problems
        ok_all &= ok
        rows.append((fid, f"{limit}{' bytes' if in_bytes else ''}", n_chars, n_bytes,
                     "tak" if ok else "**NIE** " + "; ".join(problems)))

    table = ["| Pole | Limit | Znaki | Bajty | OK |", "|---|---|---|---|---|"]
    table += [f"| {r[0]} | {r[1]} | {r[2]} | {r[3]} | {r[4]} |" for r in rows]
    print("\n".join(table))

    if "--no-write" not in sys.argv:
        new = re.sub(r"(<!-- table:start -->\n).*?(<!-- table:end -->)",
                     lambda m: m.group(1) + "\n".join(table) + "\n" + m.group(2), text, flags=re.S)
        LISTING.write_text(new, encoding="utf-8")
    print("ALL OK" if ok_all else "SOME FIELDS FAIL")
    return 0 if ok_all else 1


if __name__ == "__main__":
    sys.exit(main())
