"""tools/econ_sim.py follows the career as it is in game/data (D-124): no chapter or job count is written into
the report by hand, so a new chapter shows up in docs/ECONOMY.md after a plain re-run."""
import re

import econ_sim


def build_report(careers=2):
    balance = econ_sim.load_balance()
    jobs, tools, prog = econ_sim.load_data()
    furnishings = econ_sim.load_furnishings()
    results = {s: {p: econ_sim.simulate(s, p, careers, balance, jobs, tools, prog, furnishings)
                   for p in econ_sim.PROFILES} for s in econ_sim.SCENARIOS}
    cont = econ_sim.continuous_check(balance, tools, prog, n=5)
    return jobs, furnishings, results, econ_sim.report(results, jobs, tools, prog, cont, careers, furnishings)


def test_report_covers_every_chapter_in_the_data():
    jobs, furnishings, results, text = build_report()
    ends = econ_sim.chapter_ends(jobs)
    last = max(ends)
    assert f"{len(jobs)} zleceń, rozdz. 1–{last}" in text
    section = text.split("## 6b.")[1].split("## 7.")[0]
    rows = [(int(m.group(1)), int(m.group(2))) for m in re.finditer(r"^\| (\d+) \| (\d+) \|", section, re.M)]
    assert [ch for ch, _ in rows] == sorted(ends), "one row per chapter"
    assert sum(n for _, n in rows) == len(jobs)
    assert econ_sim.NEVER > len(jobs), "'not bought' can never be mistaken for a job number"


def test_snapshot_adds_up():
    jobs, furnishings, results, _ = build_report()
    prices = {f["id"]: f["price"] for f in furnishings}
    for career in results["C"]["average"]:
        coins, owned, spent = econ_sim.snapshot(career, len(jobs), prices)
        assert coins == career.st["coins"]
        assert owned == len(career.furn)
        assert spent == career.totals["furnishings"]
        t = career.totals
        assert t["job_income"] - t["tools"] - t["repair"] - t["furnishings"] == coins, "every coin is accounted for"


def test_furnishing_gates_are_chapters_of_the_career():
    jobs = econ_sim.load_data()[0]
    chapters = set(econ_sim.chapter_ends(jobs))
    for f in econ_sim.load_furnishings():
        assert f["chapter"] in chapters, f["id"]
