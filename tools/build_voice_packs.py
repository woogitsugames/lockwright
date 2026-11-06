#!/usr/bin/env python3
"""Build on-demand voice packs (D-62): one data-only Godot pck per non-bundled language.

PL and EN voice lines ship inside the game package; every other language
(game/assets/audio/lines/<lang>/, today DE) becomes `voice_<lang>.pck`, exported by
Godot with `--export-pack "Voice <lang>"` (a dedicated preset in game/export_presets.cfg
whose include_filter holds only that language's lines). The game downloads the pck on
demand, checks its SHA-256 against game/data/voice_packs.json and mounts it with
ProjectSettings.load_resource_pack (scripts/autoload/voice_packs.gd).

Every pck is checked to be data only (store policy: downloaded content must not change
code): only the language's .ogg.import remaps, their .oggvorbisstr data and Godot's four
housekeeping files (project.binary, uid cache, class cache, icon) are allowed.

Usage (from the repo root):
  python3 tools/build_voice_packs.py --godot /path/to/godot [--import] [--langs de]
      [--out game/build/voice] [--base-url URL] [--version V] [--write-game-manifest]

The version is content-addressed (hash of the source .ogg files of all built languages),
so a release `voice-packs-<version>` only changes when the voice lines change.
`--base-url` may contain `{version}`; default: GitHub Releases of this repository
(env VOICE_PACKS_BASE_URL overrides).
"""
import argparse
import hashlib
import json
import os
import re
import struct
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GAME = os.path.join(ROOT, "game")
LINES = os.path.join(GAME, "assets", "audio", "lines")
PRESETS = os.path.join(GAME, "export_presets.cfg")
GAME_MANIFEST = os.path.join(GAME, "data", "voice_packs.json")
BUNDLED = ("pl", "en")
DEFAULT_BASE_URL = "https://github.com/woogitsugames/lockwright/releases/download/voice-packs-{version}"
HOUSEKEEPING = {
    "res://project.binary",
    "res://icon.svg",
    "res://.godot/uid_cache.bin",
    "res://.godot/global_script_class_cache.cfg",
}
SCHEMA = 1


def read_pck_paths(path):
    """File paths stored in a Godot 4 pck (format v2-v4; v3+ keep the directory at dir_offset)."""
    with open(path, "rb") as f:
        data = f.read()
    if data[:4] != b"GDPC":
        raise ValueError("%s: not a pck (no GDPC magic)" % path)
    fmt, major, minor, _patch, flags = struct.unpack_from("<5I", data, 4)
    if fmt not in (2, 3, 4):
        raise ValueError("%s: unsupported pck format %d" % (path, fmt))
    if flags & 1:
        raise ValueError("%s: encrypted directory is not allowed" % path)
    pos = 4 + 5 * 4 + 8  # magic, 5 x u32, file_base
    if fmt >= 3:
        (dir_offset,) = struct.unpack_from("<Q", data, pos)
        pos = dir_offset
    else:
        pos += 16 * 4  # reserved
    (count,) = struct.unpack_from("<I", data, pos)
    pos += 4
    paths = []
    for _ in range(count):
        (plen,) = struct.unpack_from("<I", data, pos)
        pos += 4
        name = data[pos:pos + plen].rstrip(b"\0").decode("utf-8")
        pos += plen + 8 + 8 + 16 + 4  # offset, size, md5, flags
        if not name.startswith("res://"):
            name = "res://" + name
        paths.append(name)
    return (major, minor), paths


def check_data_only(lang, paths, sources):
    """Errors if the pck holds anything but this language's voice lines."""
    errors = []
    prefix = "res://assets/audio/lines/%s/" % lang
    imports = set()
    for p in paths:
        if p in HOUSEKEEPING:
            continue
        if p.startswith(prefix) and p.endswith(".ogg.import"):
            imports.add(p[len(prefix):-len(".import")])
            continue
        if re.fullmatch(r"res://\.godot/imported/[^/]+\.ogg-[0-9a-f]{32}\.oggvorbisstr", p):
            continue
        errors.append("%s: not allowed in a data-only voice pack: %s" % (lang, p))
    missing = sorted(set(sources) - imports)
    if missing:
        errors.append("%s: %d lines missing from the pck (first: %s); run with --import"
                      % (lang, len(missing), missing[0]))
    return errors


def sha256_file(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def source_lines(lang):
    d = os.path.join(LINES, lang)
    return sorted(n for n in os.listdir(d) if n.endswith(".ogg"))


def content_version(langs):
    h = hashlib.sha256()
    for lang in sorted(langs):
        for name in source_lines(lang):
            h.update(("%s/%s:%s\n" % (lang, name, sha256_file(os.path.join(LINES, lang, name)))).encode())
    return h.hexdigest()[:12]


def preset_names():
    with open(PRESETS, encoding="utf-8") as f:
        return re.findall(r'^name="([^"]*)"', f.read(), re.M)


def discover_langs():
    return sorted(d for d in os.listdir(LINES)
                  if os.path.isdir(os.path.join(LINES, d)) and d not in BUNDLED)


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--godot", default=os.environ.get("GODOT", "godot"))
    ap.add_argument("--import", dest="do_import", action="store_true", help="run `--import` first (fresh checkout)")
    ap.add_argument("--langs", default="", help="comma list; default: every non-bundled lines/<lang>/")
    ap.add_argument("--out", default=os.path.join(GAME, "build", "voice"))
    ap.add_argument("--base-url", default=os.environ.get("VOICE_PACKS_BASE_URL", DEFAULT_BASE_URL))
    ap.add_argument("--version", default="", help="default: content hash of the source lines")
    ap.add_argument("--write-game-manifest", action="store_true", help="also write game/data/voice_packs.json")
    args = ap.parse_args(argv)

    langs = [l for l in args.langs.split(",") if l] or discover_langs()
    bad = [l for l in langs if l in BUNDLED]
    if bad:
        sys.exit("bundled languages are not packed: %s" % ",".join(bad))
    presets = preset_names()
    for lang in langs:
        if "Voice %s" % lang not in presets:
            sys.exit('missing export preset "Voice %s" in game/export_presets.cfg (copy "Voice de")' % lang)
    version = args.version or content_version(langs)
    base_url = args.base_url.replace("{version}", version).rstrip("/")
    os.makedirs(args.out, exist_ok=True)
    out = os.path.abspath(args.out)

    if args.do_import:
        subprocess.run([args.godot, "--headless", "--path", GAME, "--import"], check=True)

    manifest = {"schema": SCHEMA, "version": version, "base_url": base_url, "packs": {}}
    errors = []
    for lang in langs:
        pck = os.path.join(out, "voice_%s.pck" % lang)
        if os.path.exists(pck):
            os.remove(pck)
        subprocess.run([args.godot, "--headless", "--path", GAME, "--export-pack", "Voice %s" % lang, pck],
                       check=True, stdout=subprocess.DEVNULL)
        if not os.path.exists(pck):
            errors.append("%s: Godot did not write %s" % (lang, pck))
            continue
        engine, paths = read_pck_paths(pck)
        sources = source_lines(lang)
        errors += check_data_only(lang, paths, sources)
        size = os.path.getsize(pck)
        manifest["packs"][lang] = {
            "file": "voice_%s.pck" % lang,
            "url": "%s/voice_%s.pck" % (base_url, lang),
            "size": size,
            "sha256": sha256_file(pck),
            "lines": len(sources),
            "godot": "%d.%d" % engine,
        }
        print("voice_%s.pck  %.1f MB  %d lines  sha256 %s" % (lang, size / 1e6, len(sources),
                                                               manifest["packs"][lang]["sha256"][:16]))
    if errors:
        sys.exit("\n".join(errors))
    text = json.dumps(manifest, indent=2, sort_keys=True) + "\n"
    with open(os.path.join(out, "voice_packs.json"), "w", encoding="utf-8") as f:
        f.write(text)
    if args.write_game_manifest:
        with open(GAME_MANIFEST, "w", encoding="utf-8") as f:
            f.write(text)
    print("version %s -> %s" % (version, base_url))


if __name__ == "__main__":
    main()
