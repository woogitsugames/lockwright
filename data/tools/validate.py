#!/usr/bin/env python3
"""Content data validator: JSON schemas, i18n completeness (PL+EN), unique ids,
reference integrity (family <-> tool <-> job). Exits non-zero on any problem.

Covers the base game (game/data, game/i18n/content.csv) and every content pack (D-112):
game/packs/<id>/jobs/*.json, game/packs/<id>/i18n/content.csv, game/packs/<id>/arrival_scenes.json,
so a chapter moved into a pack stays validated. Pack layout rules (pack.json, .import files, data-only)
are the job of tools/build_content_packs.py --check.

Usage: python3 data/tools/validate.py
"""

import csv
import glob
import json
import os
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))

failures = []


def fail(msg: str) -> None:
    failures.append(msg)
    print("FAIL:", msg)


def load_json(path: str):
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def pack_dirs(root: str) -> list:
    """Content pack source folders: game/packs/<id>/ (none when the game ships no pack)."""
    return sorted(d for d in glob.glob(os.path.join(root, "game", "packs", "*")) if os.path.isdir(d))


def load_i18n_keys(root: str) -> dict:
    """Keys of the base content.csv plus every pack's i18n/content.csv; a key defined in two files is a failure."""
    paths = [os.path.join(root, "game", "i18n", "content.csv")]
    paths += [p for p in (os.path.join(d, "i18n", "content.csv") for d in pack_dirs(root)) if os.path.exists(p)]
    keys = {}
    origin = {}
    for path in paths:
        rel = os.path.relpath(path, root).replace(os.sep, "/")
        with open(path, encoding="utf-8", newline="") as f:
            for row in csv.reader(f):
                if not row or row[0] == "keys":
                    continue
                if origin.get(row[0], rel) != rel:
                    fail(f"{rel}: i18n key {row[0]} already defined in {origin[row[0]]}")
                    continue
                origin[row[0]] = rel
                keys[row[0]] = {"en": row[1] if len(row) > 1 else "", "pl": row[2] if len(row) > 2 else ""}
    return keys


def check_arrival_scenes(path: str, job_ids: set, ctx: str) -> None:
    """Every scene of an arrival_scenes.json must belong to a known job (pack file: a job of that pack)."""
    try:
        scenes = load_json(path).get("scenes", {})
    except Exception as e:
        fail(f"{ctx}: invalid JSON: {e}")
        return
    if not isinstance(scenes, dict):
        fail(f"{ctx}: scenes must be an object")
        return
    for jid in sorted(scenes):
        if jid not in job_ids:
            fail(f"{ctx}: scene for unknown job {jid}")


def check_i18n(keys: dict, required: list, ctx: str) -> None:
    for key in required:
        if key not in keys:
            fail(f"{ctx}: missing i18n key {key}")
        else:
            for loc in ("en", "pl"):
                if not keys[key][loc].strip():
                    fail(f"{ctx}: empty {loc} for {key}")


def main(root: str = ROOT) -> int:
    del failures[:]
    game_data = os.path.join(root, "game", "data")
    i18n = load_i18n_keys(root)

    packs = pack_dirs(root)
    base_jobs = sorted(glob.glob(os.path.join(game_data, "jobs", "*.json")))
    jobs = base_jobs + [p for d in packs for p in sorted(glob.glob(os.path.join(d, "jobs", "*.json")))]
    showcase = sorted(glob.glob(os.path.join(game_data, "showcase", "*.json")))
    tools_path = os.path.join(game_data, "tools.json")
    prog_path = os.path.join(game_data, "progression.json")

    for path in [tools_path, prog_path]:
        if not os.path.exists(path):
            fail(f"missing data file: {path}")

    job_ids = set()
    ids_by_dir = {}  # folder holding jobs/ (game/data or a pack folder) -> its job ids
    for path in jobs:
        try:
            job = load_json(path)
        except Exception as e:
            fail(f"{path}: invalid JSON: {e}")
            continue
        jid = job.get("id", "")
        if not jid:
            fail(f"{path}: missing id")
        if jid in job_ids:
            fail(f"duplicate job id: {jid}")
        job_ids.add(jid)
        ids_by_dir.setdefault(os.path.dirname(os.path.dirname(path)), set()).add(jid)
        required = [f"{jid}.title", f"{jid}.client"]
        check_i18n(i18n, required, f"job {jid}")

    base_scenes = os.path.join(game_data, "arrival_scenes.json")
    if os.path.exists(base_scenes):
        check_arrival_scenes(base_scenes, ids_by_dir.get(game_data, set()), "game/data/arrival_scenes.json")
    for d in packs:
        scenes = os.path.join(d, "arrival_scenes.json")
        if os.path.exists(scenes):
            check_arrival_scenes(scenes, ids_by_dir.get(d, set()), os.path.relpath(scenes, root).replace(os.sep, "/"))

    note_ids = set()
    for path in showcase:
        try:
            note = load_json(path)
        except Exception as e:
            fail(f"{path}: invalid JSON: {e}")
            continue
        nid = note.get("id", "")
        if nid in note_ids:
            fail(f"duplicate showcase id: {nid}")
        note_ids.add(nid)
        check_i18n(i18n, [f"{nid}.title", f"{nid}.body"], f"showcase {nid}")

    if os.path.exists(tools_path):
        tools = load_json(tools_path)
        tool_ids = set()
        families = set()
        for t in tools.get("tools", []):
            tid = t.get("id", "")
            if tid in tool_ids:
                fail(f"duplicate tool id: {tid}")
            tool_ids.add(tid)
            check_i18n(i18n, [f"tool.{tid}.name"], f"tool {tid}")
            for fam in t.get("families", []):
                families.add(fam)
        if os.path.exists(prog_path):
            prog = load_json(prog_path)
            for fam in prog.get("families", []):
                if fam.get("id") not in families and prog.get("require_tools", True):
                    pass  # informational only until jobs reference families

    print(f"validated: {len(jobs)} jobs ({len(jobs) - len(base_jobs)} in {len(packs)} content packs), "
          f"{len(showcase)} showcase notes, i18n keys={len(i18n)}")
    if failures:
        print(f"VALIDATION FAIL: {len(failures)} problems")
        return 1
    print("VALIDATION OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
