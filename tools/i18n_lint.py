#!/usr/bin/env python3
"""i18n lint for Lockwright: validates game/i18n CSV files against the GDScript code.

Checks game/i18n/strings.csv and game/i18n/content.csv (header `keys,en,pl,de[,fr,es]`, UTF-8,
comma-separated with quoted fields). en/pl/de are required; fr/es (T41, behind the dev flag)
are optional: an empty value falls back to en at runtime, but a filled one is checked like the rest.

  errors:
    1. malformed CSV rows, wrong header, duplicate keys, empty en/pl/de values
    2. {placeholder} sets differ between languages for the same key (empty optional values skipped)
    3. a key used in code (I18n.t("key") / I18n.t(&"key") in game/**/*.gd) missing from CSV
    4. length limits: tutorial.* and lock.* <= 56 chars per language, menu.* <= 28
    5. a dynamically built key (e.g. "cast.%s.name") with no CSV key matching its
       pattern: at least one CSV key must match (%s -> any run without commas,
       %d -> digits), otherwise the pattern can never resolve
  warnings (never affect the exit code):
    - straight " quotes in the PL value instead of „…”
    - PL/DE value identical to EN, longer than 3 chars and not a proper noun
    - the word "włam" in any form (banned by the game tone)
    - one summary line per file and optional language with the number of empty values

Usage: python tools/i18n_lint.py   (from the repo root; exit code 1 only on errors)
"""
import csv
import os
import re
import sys
from dataclasses import dataclass, field

LANGUAGES = ("en", "pl", "de")          # required, never empty
OPTIONAL_LANGUAGES = ("fr", "es")        # T41: may be empty (runtime falls back to en)
ALL_LANGUAGES = LANGUAGES + OPTIONAL_LANGUAGES
EXPECTED_HEADER = ["keys"] + list(LANGUAGES)  # minimal header; optional columns may follow in order
CSV_FILES = ("game/i18n/strings.csv", "game/i18n/content.csv")

LENGTH_LIMITS = (("tutorial.", 56), ("lock.", 56), ("menu.", 28))

PLACEHOLDER_RE = re.compile(r"\{[^{}]+\}")
CODE_KEY_RE = re.compile(r'I18n\.t\(\s*&?"((?:[^"\\]|\\.)*)"')
DYNAMIC_RE = re.compile(r"[%{}]")
PRINTF_TOKEN_RE = re.compile(r"%(?:\d+)?[sd]")
WLAM_RE = re.compile(r"włam", re.IGNORECASE)


@dataclass
class Finding:
    severity: str  # "ERROR" or "WARN"
    location: str  # file:line
    key: str
    message: str


@dataclass
class CsvRow:
    lineno: int
    key: str
    values: dict = field(default_factory=dict)


def repo_root():
    return os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def read_csv(path, display, findings):
    """Parse one CSV file into CsvRow objects, appending ERROR findings on problems."""
    rows = []
    header = EXPECTED_HEADER
    try:
        with open(path, newline="", encoding="utf-8") as fh:
            reader = csv.reader(fh)
            for lineno, record in enumerate(reader, start=1):
                if lineno == 1:
                    full = ["keys"] + list(ALL_LANGUAGES)
                    if len(record) < len(EXPECTED_HEADER) or record != full[:len(record)]:
                        findings.append(Finding(
                            "ERROR", f"{display}:{lineno}", "",
                            f"bad header: expected {','.join(EXPECTED_HEADER)}"
                            f"[,{','.join(OPTIONAL_LANGUAGES)}], got {','.join(record)}"))
                    else:
                        header = record
                    continue
                if not record or all(not cell.strip() for cell in record):
                    continue
                if len(record) != len(header):
                    findings.append(Finding(
                        "ERROR", f"{display}:{lineno}", record[0] if record else "",
                        f"malformed row: expected {len(header)} columns, "
                        f"got {len(record)}"))
                    continue
                rows.append(CsvRow(lineno, record[0],
                                   dict(zip(header[1:], record[1:]))))
    except (csv.Error, UnicodeDecodeError) as exc:
        findings.append(Finding("ERROR", display, "", f"cannot parse CSV: {exc}"))
    return rows


def check_duplicates_and_empty(display, rows, findings):
    seen = {}
    for row in rows:
        loc = f"{display}:{row.lineno}"
        if row.key in seen:
            findings.append(Finding(
                "ERROR", loc, row.key,
                f"duplicate key (first defined at {display}:{seen[row.key]})"))
        else:
            seen[row.key] = row.lineno
        for lang in LANGUAGES:
            if not row.values.get(lang, "").strip():
                findings.append(Finding(
                    "ERROR", loc, row.key, f"empty value in column '{lang}'"))


def check_placeholders(display, rows, findings):
    for row in rows:
        loc = f"{display}:{row.lineno}"
        sets = {lang: set(PLACEHOLDER_RE.findall(row.values.get(lang, "")))
                for lang in ALL_LANGUAGES}
        reference = sets["en"]
        for lang in ("pl", "de") + OPTIONAL_LANGUAGES:
            if lang not in row.values or (lang in OPTIONAL_LANGUAGES and not row.values[lang]):
                continue
            if sets[lang] != reference:
                findings.append(Finding(
                    "ERROR", loc, row.key,
                    f"placeholder mismatch: en={sorted(reference)} "
                    f"{lang}={sorted(sets[lang])}"))


def check_length_limits(display, rows, findings):
    for row in rows:
        for prefix, limit in LENGTH_LIMITS:
            if not row.key.startswith(prefix):
                continue
            for lang in ALL_LANGUAGES:
                length = len(row.values.get(lang, ""))
                if length > limit:
                    findings.append(Finding(
                        "ERROR", f"{display}:{row.lineno}", row.key,
                        f"{lang} value is {length} chars, limit for '{prefix}*' "
                        f"is {limit}"))


def collect_code_keys(root):
    """Scan game/**/*.gd for I18n.t("...")/I18n.t(&"...") literals.

    Returns (static_keys, dynamic_keys): dict key -> sorted [(file, line)] and the
    same shape for keys that look dynamically built.
    """
    static, dynamic = {}, {}
    game_dir = os.path.join(root, "game")
    for dirpath, _dirnames, filenames in os.walk(game_dir):
        for name in sorted(filenames):
            if not name.endswith(".gd"):
                continue
            path = os.path.join(dirpath, name)
            rel = os.path.relpath(path, root)
            with open(path, encoding="utf-8", errors="replace") as fh:
                for lineno, line in enumerate(fh, start=1):
                    for match in CODE_KEY_RE.finditer(line):
                        key = match.group(1)
                        target = dynamic if DYNAMIC_RE.search(key) else static
                        target.setdefault(key, set()).add(f"{rel}:{lineno}")
    return ({k: sorted(v) for k, v in static.items()},
            {k: sorted(v) for k, v in dynamic.items()})


def dynamic_key_regex(key):
    """Compile a printf-style dynamic key ("cast.%s.name") into a regex over CSV keys.

    %s matches any run without a comma, %d (also %02d) matches digits; everything
    else is literal. Used to check that at least one CSV key resolves the pattern.
    """
    parts = []
    last = 0
    for match in PRINTF_TOKEN_RE.finditer(key):
        parts.append(re.escape(key[last:match.start()]))
        parts.append(r"[0-9]+" if match.group(0).endswith("d") else r"[^,]+")
        last = match.end()
    parts.append(re.escape(key[last:]))
    return re.compile("^" + "".join(parts) + "$")


def check_code_keys(root, csv_keys, findings):
    static, dynamic = collect_code_keys(root)
    for key, locs in sorted(static.items()):
        if key not in csv_keys:
            findings.append(Finding(
                "ERROR", locs[0], key,
                f"key used in code but missing from CSV (used at {', '.join(locs)})"))
    for key, locs in sorted(dynamic.items()):
        regex = dynamic_key_regex(key)
        if not any(regex.match(k) for k in csv_keys):
            findings.append(Finding(
                "ERROR", locs[0], key,
                f"dynamic key pattern has no matching key in CSV "
                f"(used at {', '.join(locs)})"))


def check_warnings(display, rows, findings):
    for row in rows:
        loc = f"{display}:{row.lineno}"
        pl = row.values.get("pl", "")
        if '"' in pl:
            findings.append(Finding(
                "WARN", loc, row.key, "straight \" quote in PL, use „…”"))
        en = row.values.get("en", "")
        for lang in ("pl", "de"):
            value = row.values.get(lang, "")
            if value == en and len(value) > 3 and not value[:1].isupper():
                findings.append(Finding(
                    "WARN", loc, row.key,
                    f"{lang} value identical to en (possible untranslated text): "
                    f"\"{value}\""))
        for lang in ALL_LANGUAGES:
            if WLAM_RE.search(row.values.get(lang, "")):
                findings.append(Finding(
                    "WARN", loc, row.key,
                    f"banned word 'włam' (any form) in {lang}"))


def check_optional_coverage(display, rows, findings):
    """One WARN per optional language with empty values (they fall back to en)."""
    for lang in OPTIONAL_LANGUAGES:
        present = [row for row in rows if lang in row.values]
        if not present:
            continue
        empty = [row.key for row in present if not row.values[lang].strip()]
        if empty:
            findings.append(Finding(
                "WARN", display, f"[{lang}]",
                f"{len(empty)}/{len(present)} empty {lang} values (fall back to en), "
                f"first: {', '.join(empty[:3])}"))


def run_lint(root):
    """Run all checks under root. Returns (findings, csv_key_count)."""
    findings = []
    all_rows = []
    for rel in CSV_FILES:
        path = os.path.join(root, rel)
        if not os.path.isfile(path):
            findings.append(Finding("ERROR", rel, "", "CSV file not found"))
            continue
        rows = read_csv(path, rel, findings)
        check_duplicates_and_empty(rel, rows, findings)
        check_placeholders(rel, rows, findings)
        check_length_limits(rel, rows, findings)
        check_warnings(rel, rows, findings)
        check_optional_coverage(rel, rows, findings)
        all_rows.extend(rows)
    csv_keys = {row.key for row in all_rows}
    check_code_keys(root, csv_keys, findings)
    return findings, len(csv_keys)


def print_report(findings, csv_key_count):
    order = {"ERROR": 0, "WARN": 1}
    for finding in sorted(findings, key=lambda f: (order[f.severity], f.location, f.key)):
        print(f"[{finding.severity}] {finding.location}  {finding.key}: {finding.message}")
    errors = sum(1 for f in findings if f.severity == "ERROR")
    warns = sum(1 for f in findings if f.severity == "WARN")
    print("-" * 60)
    print(f"i18n lint: {csv_key_count} keys checked, "
          f"{errors} error(s), {warns} warning(s)")
    if errors:
        print("i18n lint: FAILED")
    else:
        print("i18n lint: OK (warnings only)" if warns else "i18n lint: OK")
    return 1 if errors else 0


def main(argv=None):
    root = repo_root()
    findings, csv_key_count = run_lint(root)
    return print_report(findings, csv_key_count)


if __name__ == "__main__":
    sys.exit(main())
