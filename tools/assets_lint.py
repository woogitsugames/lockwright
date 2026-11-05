#!/usr/bin/env python3
"""Assets lint for Lockwright: checks game/assets against docs/ASSETS.md and size limits.

Checks:
  1. every binary file in game/assets/** (png, jpg, jpeg, webp, wav, ogg, ttf, otf, glb;
     .import files skipped) is listed in docs/ASSETS.md. An entry matches when it is
     the file's repo-relative path, a glob pattern matching that path, a path suffix
     at a "/" boundary (an entry naming the file plus its directory, which covers
     entries written relative to a sibling file), or a directory prefix of the path
     (entry naming the file's directory).
     A bare filename with no directory never matches: filenames in a comma list
     inherit the directory of the first path of the same list, so an entry like
     "mockups/fonts/X, Y" cannot cover game/assets/**/Y (review V01: no false
     negatives from same-name files in other directories).
     Backtick entries may list several comma-separated paths and use {a,b} braces.
  2. every font (*.ttf/*.otf) in the repo has an OFL license: either an OFL*.txt file
     in the same directory, or an ASSETS.md line mentioning the font (or its
     directory) together with "OFL".
  3. no file in game/assets exceeds 8 MB; the 20 largest files are always printed.

Usage: python tools/assets_lint.py   (from the repo root; exit code 1 only on errors)
"""
import fnmatch
import os
import re
import sys
from dataclasses import dataclass

BINARY_EXTS = {".png", ".jpg", ".jpeg", ".webp", ".wav", ".ogg",
               ".ttf", ".otf", ".glb"}
FONT_EXTS = {".ttf", ".otf"}
ASSETS_DIR = "game/assets"
ASSETS_MD = "docs/ASSETS.md"
MAX_BYTES = 8 * 1024 * 1024
TOP_N = 20

BACKTICK_RE = re.compile(r"`([^`]+)`")
BRACE_RE = re.compile(r"\{([^{}]+)\}")


@dataclass
class Finding:
    severity: str  # "ERROR" or "WARN"
    location: str
    message: str


def repo_root():
    return os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def expand_braces(pattern):
    """Expand one {a,b} group into multiple patterns (repeatedly, left to right)."""
    match = BRACE_RE.search(pattern)
    if not match:
        return [pattern]
    out = []
    for alt in match.group(1).split(","):
        out.extend(expand_braces(pattern[:match.start()] + alt.strip()
                                 + pattern[match.end():]))
    return out


def _looks_like_path(part):
    exts = (".png", ".jpg", ".jpeg", ".webp", ".wav", ".ogg", ".ttf", ".otf",
            ".glb", ".svg", ".gd", ".py", ".md", ".json")
    return bool(part) and ("/" in part or part.lower().endswith(exts))


PAREN_RE = re.compile(r"\([^)]*\)")
EXT_ALT_RE = re.compile(r"([*\w-]+)\.([a-z0-9]+)\|([a-z0-9]+)", re.IGNORECASE)
SEPARATOR_RE = re.compile(r",|\||\+|\s+i\s+")
CELL_SPLIT_RE = re.compile(r"\s+\|\s+")


def _line_patterns(tokens):
    """Split one ASSETS.md line's tokens into path patterns.

    Drops backtick-quoted remarks and (...) notes, turns extension alternations
    like `*.png|webp` into two patterns, expands {a,b} braces, then splits on
    commas / " i " / " + " / "|". A bare filename in a line is written relative
    to the sibling paths of the same line (often in a separate backtick or a
    brace expansion), so every token of the line shares one anchor: the
    directory of the first part that carries one. A bare filename in a line
    with no directory never matches (it used to cover the same name in any
    directory).
    """
    anchor = ""
    patterns = []
    for token in tokens:
        token = BACKTICK_RE.sub(" ", token)
        token = PAREN_RE.sub(" ", token)
        token = EXT_ALT_RE.sub(
            lambda m: f"{m.group(1)}.{m.group(2)}, {m.group(1)}.{m.group(3)}", token)
        for expanded in expand_braces(token):
            for part in SEPARATOR_RE.split(expanded):
                part = part.strip()
                if not _looks_like_path(part):
                    continue
                if "/" in part:
                    if anchor == "":
                        anchor = part.rsplit("/", 1)[0] + "/"
                elif anchor:
                    part = anchor + part
                patterns.append(part)
    return patterns


def _token_to_patterns(token):
    """Path patterns of a single token (a one-token line)."""
    return _line_patterns([token])


def load_assets_md_entries(root):
    """Extract path patterns from docs/ASSETS.md.

    Sources: backtick-quoted tokens anywhere in the file, plus the first cell of
    every table row (some rows list paths without backticks). Tokens are grouped
    per line so bare filenames inherit the sibling directory of their line.
    """
    path = os.path.join(root, ASSETS_MD)
    if not os.path.isfile(path):
        return [], None
    with open(path, encoding="utf-8") as fh:
        text = fh.read()
    patterns = []
    for line in text.splitlines():
        line = line.strip()
        tokens = BACKTICK_RE.findall(line)
        if line.startswith("|"):
            cells = CELL_SPLIT_RE.split(line[1:])
            if cells and cells[0].strip():
                # Reading order: plain first-cell paths, then backtick tokens.
                tokens.insert(0, BACKTICK_RE.sub(" ", cells[0]))
        if tokens:
            patterns.extend(_line_patterns(tokens))
    return patterns, text


def is_listed(rel_path, patterns):
    """True when any ASSETS.md pattern covers rel_path.

    A pattern matches as the full path, as a glob over the full path, as a path
    suffix (only patterns that name a directory: "fonts/X.ttf" covers
    "game/assets/fonts/X.ttf", a bare "X.ttf" covers nothing), or as a directory
    prefix of the path.
    """
    for pat in patterns:
        pat = pat.strip("/")
        if "/" in pat and fnmatch.fnmatch(rel_path, "*/" + pat):
            return pat
        if fnmatch.fnmatch(rel_path, pat):
            return pat
        if rel_path.startswith(pat + "/"):
            return pat
    return None


def iter_binary_assets(root):
    assets_dir = os.path.join(root, ASSETS_DIR)
    for dirpath, _dirnames, filenames in os.walk(assets_dir):
        for name in sorted(filenames):
            if name.endswith(".import"):
                continue
            if os.path.splitext(name)[1].lower() in BINARY_EXTS:
                full = os.path.join(dirpath, name)
                yield os.path.relpath(full, root).replace(os.sep, "/"), full


def check_listed(root, findings):
    patterns, _text = load_assets_md_entries(root)
    if not patterns:
        findings.append(Finding("ERROR", ASSETS_MD, "no path entries found in ASSETS.md"))
    unlisted = []
    for rel, _full in iter_binary_assets(root):
        if is_listed(rel, patterns) is None:
            unlisted.append(rel)
    for rel in unlisted:
        findings.append(Finding("ERROR", rel, "binary asset not listed in " + ASSETS_MD))
    return unlisted


def font_has_ofl(root, font_rel, assets_md_text):
    """True when an OFL*.txt sits next to the font, or an ASSETS.md line that
    mentions OFL also lists this font (exact path, glob, or directory entry)."""
    font_dir = os.path.dirname(os.path.join(root, font_rel))
    if os.path.isdir(font_dir):
        for name in os.listdir(font_dir):
            if name.upper().startswith("OFL") and name.lower().endswith(".txt"):
                return True
    if assets_md_text:
        for line in assets_md_text.splitlines():
            if "OFL" not in line:
                continue
            if is_listed(font_rel, _token_to_patterns(line)):
                return True
    return False


def check_fonts(root, findings):
    _patterns, text = load_assets_md_entries(root)
    missing = []
    for dirpath, _dirnames, filenames in os.walk(root):
        if ".git" in dirpath.split(os.sep):
            continue
        for name in sorted(filenames):
            if os.path.splitext(name)[1].lower() in FONT_EXTS:
                rel = os.path.relpath(os.path.join(dirpath, name), root)
                rel = rel.replace(os.sep, "/")
                if not font_has_ofl(root, rel, text):
                    missing.append(rel)
    for rel in missing:
        findings.append(Finding(
            "ERROR", rel, "font without OFL license (no OFL*.txt next to it, "
            "no 'OFL' entry for it in " + ASSETS_MD + ")"))
    return missing


def check_sizes(root, findings):
    assets_dir = os.path.join(root, ASSETS_DIR)
    sizes = []
    for dirpath, _dirnames, filenames in os.walk(assets_dir):
        for name in filenames:
            full = os.path.join(dirpath, name)
            sizes.append((os.path.getsize(full),
                          os.path.relpath(full, root).replace(os.sep, "/")))
    sizes.sort(reverse=True)
    oversized = [rel for size, rel in sizes if size > MAX_BYTES]
    for rel in oversized:
        size = dict((r, s) for s, r in sizes)[rel]
        findings.append(Finding(
            "ERROR", rel, f"file is {size / 1024 / 1024:.2f} MB, limit is 8 MB"))
    return sizes[:TOP_N], oversized


def run_lint(root):
    findings = []
    unlisted = check_listed(root, findings)
    missing_ofl = check_fonts(root, findings)
    top, oversized = check_sizes(root, findings)
    stats = {"unlisted": unlisted, "missing_ofl": missing_ofl,
             "oversized": oversized, "top": top}
    return findings, stats


def print_report(findings, stats):
    for finding in sorted(findings, key=lambda f: (f.severity != "ERROR", f.location)):
        print(f"[{finding.severity}] {finding.location}: {finding.message}")
    print("-" * 60)
    print(f"{TOP_N} largest files in {ASSETS_DIR}:")
    for size, rel in stats["top"]:
        print(f"  {size / 1024 / 1024:7.2f} MB  {rel}")
    errors = sum(1 for f in findings if f.severity == "ERROR")
    print("-" * 60)
    print(f"assets lint: {len(stats['unlisted'])} unlisted binary asset(s), "
          f"{len(stats['missing_ofl'])} font(s) without OFL, "
          f"{len(stats['oversized'])} file(s) over 8 MB, {errors} error(s) total")
    if errors:
        print("assets lint: FAILED")
    else:
        print("assets lint: OK")
    return 1 if errors else 0


def main(argv=None):
    root = repo_root()
    findings, stats = run_lint(root)
    return print_report(findings, stats)


if __name__ == "__main__":
    sys.exit(main())
