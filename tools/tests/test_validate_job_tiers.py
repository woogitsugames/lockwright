"""data/tools/validate.py: a job's `tier` must be inside the lockcore tier range of its family (D-118).

The ranges come from lockcore/tiers.json (written by `verify_seeds --tiers`, kept in sync with the families'
min_tier()/max_tier() by ctest `tiers_json_in_sync`), not from a copy in the validator."""
import glob
import json
import os
import re

import pytest

from test_pack_validators import REPO, make_root, pack_file, validate


def write_job(root, **fields):
    job = {"id": "job.test", "chapter": 1, "lines": ["client"]}
    job.update(fields)
    path = root / "game" / "data" / "jobs" / "job.test.json"
    path.write_text(json.dumps(job), encoding="utf-8")


def run(root, capsys):
    code = validate.main(str(root))
    return code, capsys.readouterr().out


# --- the table itself ---

def test_ranges_are_read_from_lockcore_tiers_json():
    ranges = validate.load_tier_ranges()
    with open(os.path.join(REPO, "lockcore", "tiers.json"), encoding="utf-8") as f:
        stored = json.load(f)
    assert stored["schema"] == "lockcore.tiers/1"
    assert ranges == {fam: (r["min"], r["max"]) for fam, r in stored["families"].items()}
    assert ranges and all(1 <= lo <= hi for lo, hi in ranges.values())


def test_tiers_json_names_every_family_the_game_maps():
    """JobRun.FAMILY_MAP (job family -> lockcore family) must not name a family the table lacks."""
    with open(os.path.join(REPO, "game", "scripts", "lock", "job_run.gd"), encoding="utf-8") as f:
        src = f.read()
    block = src[src.index("const FAMILY_MAP"):]
    block = block[:block.index("}")]
    mapped = re.findall(r'"(\w+)":\s*&"(\w+)"', block)
    assert mapped, "FAMILY_MAP not found in job_run.gd"
    ranges = validate.load_tier_ranges()
    for job_family, core_family in mapped:
        assert job_family == core_family, "validate.py assumes aliases are identities"
        assert core_family in ranges


def test_missing_tiers_json_is_a_failure(tmp_path, capsys):
    del validate.failures[:]
    assert validate.load_tier_ranges(str(tmp_path / "nope.json")) == {}
    assert "cannot read lockcore tier ranges" in capsys.readouterr().out
    assert validate.failures
    del validate.failures[:]


# --- the check ---

@pytest.mark.parametrize("family,tier", [
    ("pin_tumbler", 2), ("pin_tumbler", 7), ("lever", 3), ("lever", 5), ("lever_detector", 5),
    ("warded", 1), ("warded", 2), ("dial_safe", 3), ("combo", 4), ("egyptian", 2), ("time_lock", 2),
])
def test_tier_inside_the_range_passes(tmp_path, capsys, family, tier):
    root = make_root(tmp_path, with_pack=False)
    write_job(root, family=family, tier=tier)
    code, out = run(root, capsys)
    assert code == 0, out


@pytest.mark.parametrize("family,tier,played", [
    ("pin_tumbler", 1, 2),      # student_dorm / wrong_floor before D-118
    ("lever", 1, 3),            # pizzeria_pays_pizza
    ("lever", 2, 3),            # widow_bureau
    ("warded", 3, 2),           # grandpa_chest, krakow_tenement_gate, swiatniki_journeyman_padlock
    ("lever_detector", 2, 5),   # liege_bakery
    ("pin_tumbler", 8, 7),
    ("dial_safe", 0, 1),
])
def test_tier_outside_the_range_fails(tmp_path, capsys, family, tier, played):
    root = make_root(tmp_path, with_pack=False)
    write_job(root, family=family, tier=tier)
    code, out = run(root, capsys)
    assert code == 1
    lo, hi = validate.load_tier_ranges()[family]
    assert (f"job job.test: tier {tier} is outside the lockcore range of {family} (t{lo}-t{hi}); "
            f"the game would play t{played}") in out


def test_pack_job_tier_is_checked_too(tmp_path, capsys):
    root = make_root(tmp_path)
    path = pack_file(root, "jobs/job.fixture_cellar.json")
    job = json.loads(path.read_text(encoding="utf-8"))
    assert (job["family"], job["tier"]) == ("wafer", 2)
    job["tier"] = 4
    path.write_text(json.dumps(job), encoding="utf-8")
    code, out = run(root, capsys)
    assert code == 1
    assert "job job.fixture_cellar: tier 4 is outside the lockcore range of wafer (t1-t3)" in out


def test_unknown_family_fails(tmp_path, capsys):
    root = make_root(tmp_path, with_pack=False)
    write_job(root, family="tubular", tier=1)
    code, out = run(root, capsys)
    assert code == 1
    assert "job job.test: family 'tubular' is not a lockcore family" in out


@pytest.mark.parametrize("tier", [None, "2", 2.0, True])
def test_tier_must_be_an_integer(tmp_path, capsys, tier):
    root = make_root(tmp_path, with_pack=False)
    fields = {"family": "wafer"}
    if tier is not None:
        fields["tier"] = tier
    write_job(root, **fields)
    code, out = run(root, capsys)
    assert code == 1
    assert "job job.test: tier must be an integer" in out


def test_job_without_family_is_not_checked(tmp_path, capsys):
    root = make_root(tmp_path, with_pack=False)
    write_job(root, tier=99)
    code, out = run(root, capsys)
    assert code == 0, out


# --- the real data ---

def test_every_shipped_job_has_a_tier_lockcore_plays():
    ranges = validate.load_tier_ranges()
    paths = sorted(glob.glob(os.path.join(REPO, "game", "data", "jobs", "*.json")) +
                   glob.glob(os.path.join(REPO, "game", "packs", "*", "jobs", "*.json")))
    assert paths
    bad = []
    for path in paths:
        with open(path, encoding="utf-8") as f:
            job = json.load(f)
        lo, hi = ranges[job["family"]]
        if not lo <= job["tier"] <= hi:
            bad.append((job["id"], job["family"], job["tier"]))
    assert bad == []
