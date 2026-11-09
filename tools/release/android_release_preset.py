#!/usr/bin/env python3
"""Append an Android release preset to game/export_presets.cfg, copied from preset.0 "Android" (D-106).

One source of truth: filters, permissions (VIBRATE, INTERNET), orientation, package name and SDK levels
all come from preset.0; only the release-specific keys are overridden. The new preset gets the next free
index (never reuses an existing one: preset.3..6 are the voice packs). Signing is NOT written to the file:
Godot reads GODOT_ANDROID_KEYSTORE_RELEASE_PATH / _USER / _PASSWORD from the environment when the preset
fields are empty, so passwords never touch disk.

   python3 tools/release/android_release_preset.py --version-code 10123 --version-name 0.1.0-ci.123 \
       [--signed] [--format aab|apk] [--name AndroidRelease] [--export-path build/lockwright-release.aab]
Prints the preset name. CI copies the file back from git afterwards; never commit the result.
"""
import argparse, pathlib, re, sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
VERSION_CODE_MAX = 2100000000  # Google Play limit


def sections(lines):
    """[(header, start, end)] for every [section] in the file."""
    heads = [(i, l.strip()) for i, l in enumerate(lines) if re.match(r"^\[[^\]]+\]\s*$", l)]
    return [(h, i, heads[k + 1][0] if k + 1 < len(heads) else len(lines)) for k, (i, h) in enumerate(heads)]


def body(lines, secs, header):
    for h, s, e in secs:
        if h == header:
            return [l.rstrip("\n") for l in lines[s + 1:e]]
    raise SystemExit("section %s not found" % header)


def override(block, values):
    out, seen = [], set()
    for l in block:
        m = re.match(r"^([A-Za-z0-9_/.]+)=", l)
        if m and m.group(1) in values:
            k = m.group(1)
            out.append("%s=%s" % (k, values[k]))
            seen.add(k)
        else:
            out.append(l)
    while out and out[-1].strip() == "":
        out.pop()
    out += ["%s=%s" % (k, v) for k, v in values.items() if k not in seen]
    return out


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--presets", default=str(ROOT / "game" / "export_presets.cfg"))
    ap.add_argument("--version-code", type=int, required=True)
    ap.add_argument("--version-name", required=True)
    ap.add_argument("--signed", action="store_true", help="release keystore comes from GODOT_ANDROID_KEYSTORE_RELEASE_*")
    ap.add_argument("--format", choices=("aab", "apk"), default="aab")
    ap.add_argument("--name", default="AndroidRelease")
    ap.add_argument("--export-path")
    args = ap.parse_args()
    if not 1 <= args.version_code <= VERSION_CODE_MAX:
        raise SystemExit("versionCode %d outside 1..%d" % (args.version_code, VERSION_CODE_MAX))
    if not re.fullmatch(r"[0-9A-Za-z.+_-]{1,100}", args.version_name):
        raise SystemExit("versionName %r: use letters, digits and . + _ - only" % args.version_name)

    path = pathlib.Path(args.presets)
    lines = path.read_text(encoding="utf-8").splitlines(True)
    secs = sections(lines)
    idx = [int(m.group(1)) for h, _, _ in secs for m in [re.fullmatch(r"\[preset\.(\d+)\]", h)] if m]
    names = [l.split("=", 1)[1].strip().strip('"') for l in lines if l.startswith("name=")]
    if args.name in names:
        raise SystemExit("preset %s already exists" % args.name)
    n = max(idx) + 1
    export_path = args.export_path or "build/lockwright-release.%s" % args.format

    head = override(body(lines, secs, "[preset.0]"), {
        "name": '"%s"' % args.name, "runnable": "false", "export_path": '"%s"' % export_path})
    opts = override(body(lines, secs, "[preset.0.options]"), {
        "gradle_build/use_gradle_build": "true",
        "gradle_build/export_format": "1" if args.format == "aab" else "0",
        "keystore/debug": '""', "keystore/debug_user": '""', "keystore/debug_password": '""',
        "keystore/release": '""', "keystore/release_user": '""', "keystore/release_password": '""',
        "package/signed": "true" if args.signed else "false",
        "version/code": str(args.version_code),
        "version/name": '"%s"' % args.version_name,
        "graphics/opengl_debug": "false",
    })
    text = "".join(lines)
    if not text.endswith("\n"):
        text += "\n"
    text += "\n[preset.%d]\n%s\n\n[preset.%d.options]\n%s\n" % (n, "\n".join(head), n, "\n".join(opts))
    path.write_text(text, encoding="utf-8")
    print(args.name)
    return 0


if __name__ == "__main__":
    sys.exit(main())
