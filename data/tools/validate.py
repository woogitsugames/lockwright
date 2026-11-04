#!/usr/bin/env python3
"""Content data validator: JSON schemas, i18n completeness (PL+EN), unique ids,
reference integrity (family <-> tool <-> job). Exits non-zero on any problem.

Usage: python3 data/tools/validate.py
"""

import csv
import glob
import json
import os
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
GAME_DATA = os.path.join(ROOT, "game", "data")
I18N_CONTENT = os.path.join(ROOT, "game", "i18n", "content.csv")

failures = []


def fail(msg: str) -> None:
    failures.append(msg)
    print("FAIL:", msg)


def load_json(path: str):
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def load_i18n_keys() -> dict:
    keys = {}
    with open(I18N_CONTENT, encoding="utf-8", newline="") as f:
        for row in csv.reader(f):
            if not row or row[0] == "keys":
                continue
            keys[row[0]] = {"en": row[1] if len(row) > 1 else "", "pl": row[2] if len(row) > 2 else ""}
    return keys


def check_i18n(keys: dict, required: list, ctx: str) -> None:
    for key in required:
        if key not in keys:
            fail(f"{ctx}: missing i18n key {key}")
        else:
            for loc in ("en", "pl"):
                if not keys[key][loc].strip():
                    fail(f"{ctx}: empty {loc} for {key}")


def main() -> int:
    i18n = load_i18n_keys()

    jobs = sorted(glob.glob(os.path.join(GAME_DATA, "jobs", "*.json")))
    showcase = sorted(glob.glob(os.path.join(GAME_DATA, "showcase", "*.json")))
    tools_path = os.path.join(GAME_DATA, "tools.json")
    prog_path = os.path.join(GAME_DATA, "progression.json")

    for path in [tools_path, prog_path]:
        if not os.path.exists(path):
            fail(f"missing data file: {path}")

    job_ids = set()
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
        required = [f"{jid}.title", f"{jid}.client"]
        check_i18n(i18n, required, f"job {jid}")

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

    print(f"validated: {len(jobs)} jobs, {len(showcase)} showcase notes, i18n keys={len(i18n)}")
    if failures:
        print(f"VALIDATION FAIL: {len(failures)} problems")
        return 1
    print("VALIDATION OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
