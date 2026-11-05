#!/usr/bin/env python3
"""Career economy simulator for Lockwright (Jobs mode + Continuous-mode grinding).

Plain Python stdlib. Reads game/data (read only) and lockcore/BALANCE.md, simulates
29 jobs for three player profiles under three scenarios and writes docs/ECONOMY.md.

    python3 tools/econ_sim.py                 # writes docs/ECONOMY.md
    python3 tools/econ_sim.py --careers 400 --out /tmp/eco.md

Model (all assumptions are listed in the report, section "Model"):
- job order = order in docs/JOBS.md; refusal jobs are played as refusals (no lock);
- lock time = feeling-bot p50 (BALANCE.md) x human factor x learning factor;
- tool wear per lock from TOOLS.md §2 event costs and per-profile event counts;
- missing tool (price or unlock condition) -> the player grinds Continuous-mode
  sessions (8 min, PROGRESSION.md §2) until it can be bought; capped, then "blocked".
"""
import argparse
import glob
import json
import math
import os
import random
import re
import statistics

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# --- job -> lock family/tier as written in docs/JOBS.md ("Zamek:" lines). ---------
# The JSON files carry "lever" for every "zapadkowy" (warded) lock and for the detector
# lock, and "unknown" for the tubular one; scenario A keeps the JSON as is.
JOBS_MD_FAMILY = {
    "job.grandma_broth": ("warded", 1), "job.cat_bathroom": ("warded", 1),
    "job.bike_interview": ("combo", 1), "job.student_dorm": ("pin_tumbler", 1),
    "job.kiosk_shutter": ("wafer", 1), "job.refuse_ex_partner": ("pin_tumbler", 2),
    "job.newlyweds_4am": ("pin_tumbler", 2), "job.pizzeria_pays_pizza": ("lever", 1),
    "job.night_nurse": ("magnetic", 1), "job.wrong_floor": ("pin_tumbler", 1),
    "job.refuse_rush_bribe": ("pin_tumbler", 2), "job.drummer_locker": ("tubular", 1),
    "job.grandpa_chest": ("warded", 3), "job.uncle_safe_heirs": ("dial_safe", 2),
    "job.dollhouse_wooden_lock": ("egyptian", 1), "job.allotment_shed": ("wafer", 2),
    "job.widow_bureau": ("lever", 2), "job.refuse_aunt_alive": ("lever", 2),
    "job.krakow_tenement_gate": ("warded", 3), "job.swiatniki_journeyman_padlock": ("warded", 3),
    "job.krakow_antiquarian": ("dial_safe", 1), "job.brussels_townhouse": ("dimple", 2),
    "job.ghent_beguinage": ("warded", 2), "job.liege_bakery": ("lever_detector", 2),
    "job.charleroi_letters": ("wafer", 2), "job.museum_time_lock": ("time_lock", 2),
    "job.bramah_bureau": ("axial_slider", 2), "job.finnish_sailor": ("disc_detainer", 2),
    "job.time_capsule": ("combo", 3),
}
# Jobs whose best path is not opening the lock (JOBS.md: refusals, "ask for more").
NO_LOCK_JOBS = {"job.refuse_ex_partner", "job.refuse_rush_bribe", "job.refuse_aunt_alive",
                "job.wrong_floor"}

# Job tier (T1 intro, T2, T3 master) -> lockcore family + tier.
LOCKCORE_MAP = {
    "pin_tumbler": ("pin_tumbler", {1: 2, 2: 3, 3: 4}),
    "wafer": ("wafer", {1: 1, 2: 2, 3: 3}),
    "egyptian": ("wooden_pin", {1: 1, 2: 1, 3: 1}),
    "warded": ("warded", {1: 1, 2: 2, 3: 2}),  # lockcore has warded t1-t2 only
    "lever": ("lever", {1: 3, 2: 4, 3: 5}),
    "lever_detector": ("lever_detector", {1: 5, 2: 5, 3: 6}),
    "combo": ("ring_combo", {1: 2, 2: 2, 3: 3}),
}
# Family -> tool the job needs (tools.json ids). Families without a lockcore module get an
# estimated time; their tool still gates the job.
FAMILY_TOOLS = {
    "pin_tumbler": ["tw_angle", "pk_hook"], "wafer": ["tw_angle", "pk_hook"],
    "egyptian": ["pk_peg"], "warded": ["pk_ward"], "lever": ["pk_lever"],
    "lever_detector": ["pk_lever"], "combo": ["tl_shackle"], "magnetic": ["tl_polar"],
    "tubular": ["pk_crown"], "dial_safe": ["tl_cup"], "time_lock": ["kit_clock"],
    "dimple": ["tw_bar", "pk_flag"], "axial_slider": ["pk_plunger"],
    "disc_detainer": ["pk_disc"], "unknown": [],
}
# Rough sizes for families with no lockcore data (feel p50 s, clumsy success) by job tier.
EST_FEEL = {1: 20.0, 2: 26.0, 3: 34.0}
EST_CLUMSY_OK = 0.95

PROFILES = {
    # human_x: player time / feeling-bot p50 at first contact; learn: asymptotic factor;
    # oversets/stress per lock; clean: P(no drop, no break); tip: expected tip share;
    # skill: Continuous-mode skill (PROGRESSION §2.2); brk: base P(break) per lock;
    # scene_s: dialog + verification + quote per job.
    "careful": dict(human_x=3.0, learn=0.65, overs=0.5, stress=0.2, clean=0.80, tip=0.20,
                    skill=1.15, brk=0.010, scene_s=80, repair_at=60),
    "average": dict(human_x=2.4, learn=0.60, overs=2.0, stress=1.0, clean=0.55, tip=0.10,
                    skill=1.00, brk=0.040, scene_s=60, repair_at=50),
    "clumsy": dict(human_x=2.0, learn=0.60, overs=5.0, stress=3.0, clean=0.25, tip=0.03,
                   skill=0.85, brk=0.080, scene_s=45, repair_at=30),
}

SCENARIOS = {
    "A": dict(label="data as is (JSON families, tier coef 0.55)", families="json", coef=0.55,
              changes={}),
    "B": dict(label="JOBS.md families, tier coef 0.55", families="md", coef=0.55, changes={}),
    "C": dict(label="proposed numbers (JOBS.md families, coef 1.2, changes in §6)",
              families="md", coef=1.2,
              changes={
                  "price": {"pk_lever": 300, "tl_polar": 700, "pk_crown": 600, "tw_bar": 450,
                            "pk_flag": 900, "pk_plunger": 1000, "pk_disc": 1100, "tl_cup": 1200},
                  "unlock": {"tl_cup": "after_t4", "pk_disc": "after_t6", "tl_polar": "after_t4",
                             "pk_crown": "after_t3", "pk_lever": "after_t2",
                             "pk_flag": "after_t5", "pk_plunger": "after_t5"},
                  "reward_x": 1.0,
              }),
}

GRIND_CAP_SESSIONS = 60  # after this many grinding sessions for one job, the job is "blocked"
SESSION_S = 8 * 60
LOCK_OVERHEAD_S = 8  # Continuous mode: transition between locks


def load_balance():
    """Parse lockcore/BALANCE.md first table -> {(family, tier): (feel_p50, clumsy_ok, clumsy_p50)}."""
    text = open(os.path.join(ROOT, "lockcore", "BALANCE.md"), encoding="utf-8").read()
    table = text.split("## Reading the table")[0]
    out, fam = {}, None
    for line in table.splitlines():
        m = re.match(r"\|\s*(`(\w+)`)?\s*\|\s*t(\d)\s*\|\s*([\d.]+) %\s*\|\s*([\d.]+) s\s*\|"
                     r"\s*([\d.]+) %\s*\|\s*([\d.]+) s", line)
        if not m:
            continue
        fam = m.group(2) or fam
        out[(fam, int(m.group(3)))] = (float(m.group(5)), float(m.group(6)) / 100, float(m.group(7)))
    return out


def load_data():
    jobs = {}
    for f in glob.glob(os.path.join(ROOT, "game", "data", "jobs", "*.json")):
        d = json.load(open(f, encoding="utf-8"))
        jobs[d["id"]] = d
    order = list(JOBS_MD_FAMILY)  # JOBS.md order
    assert set(order) == set(jobs), set(order) ^ set(jobs)
    tools = {t["id"]: t for t in json.load(open(os.path.join(ROOT, "game", "data", "tools.json"),
                                                encoding="utf-8"))["tools"]}
    prog = json.load(open(os.path.join(ROOT, "game", "data", "progression.json"), encoding="utf-8"))
    return [jobs[i] for i in order], tools, prog


def unlock_ok(cond, st):
    if cond in ("start", "after_tutorial_t1", "with_tl_cup"):
        return True
    if cond == "event_F2":
        return st["chapter"] >= 6  # assumed: the clockmaker's kit is the chapter-6 event reward
    if cond == "after_first_t2":
        return st["max_tier"] >= 2
    if cond == "after_5_locks_t2":
        return st["t2_count"] >= 5
    if cond == "after_tier4":
        return st["max_tier"] >= 4
    m = re.match(r"after_t(\d)", cond)
    if m:
        return st["max_tier"] >= int(m.group(1))
    return False  # jobs_mode_only and unknown


class Career:
    def __init__(self, prof, scen, balance, tools, prog, rng):
        self.p, self.s, self.bal, self.rng = PROFILES[prof], SCENARIOS[scen], balance, rng
        self.tools = {k: dict(v) for k, v in tools.items()}
        for tid, price in self.s["changes"].get("price", {}).items():
            self.tools[tid]["price"] = price
        for tid, cond in self.s["changes"].get("unlock", {}).items():
            self.tools[tid]["unlock"] = cond
        self.prog = prog
        self.owned = {t: 100.0 for t, v in self.tools.items() if v["price"] == 0 and v["unlock"] in
                      ("start", "after_tutorial_t1")}
        self.st = dict(coins=0, max_tier=1, t2_count=0, chapter=1)
        self.exposure = {}
        self.log = []  # per job rows
        self.totals = dict(job_income=0, grind_income=0, repair=0, tools=0, breaks=0,
                           grind_sessions=0, job_time=0.0, grind_time=0.0)
        self.unlock_curve = []  # (job_index, tool_id)

    # --- lock model ----------------------------------------------------------------
    def lock_stats(self, family, tier):
        """Returns (lockcore family, lockcore tier, feel_p50, clumsy_ok)."""
        if family in LOCKCORE_MAP:
            lf, tmap = LOCKCORE_MAP[family]
            lt = tmap.get(tier, max(tmap.values()))
            feel, cok, _ = self.bal[(lf, lt)]
            return lf, lt, feel, cok
        return family, tier + 1, EST_FEEL.get(tier, 30.0), EST_CLUMSY_OK

    def play_lock(self, family, tier, tool_ids):
        lf, lt, feel, cok = self.lock_stats(family, tier)
        n = self.exposure.get(lf, 0)
        learn = self.p["learn"] + (1 - self.p["learn"]) * math.exp(-n / 3.0)
        t = feel * self.p["human_x"] * learn * self.rng.uniform(0.8, 1.25)
        self.exposure[lf] = n + 1
        blades = [x for x in tool_ids if x in self.owned and self.tools[x]["kind"] not in
                  ("tensioner", "notebook", "kit")]
        brk = False
        for b in blades:
            wear = 2.0 * min(1.0, t / 60) + self.p["overs"] + 2 * self.p["stress"]
            if lf == "lever_detector":
                wear += 1.0 if self.p is PROFILES["careful"] else 3.0
            self.owned[b] = max(0.0, self.owned[b] - wear * self.rng.uniform(0.6, 1.4))
        pbrk = self.p["brk"] * (lt / 3.0)
        if self.p is PROFILES["clumsy"]:
            pbrk += (1 - cok)
        if blades:
            worn = min(self.owned[b] for b in blades)
            pbrk *= 1 + (100 - worn) / 100 * 0.43  # S_max -30 % at I = 0 ~ +43 % break odds
        if self.rng.random() < min(pbrk, 0.9):
            brk = True
            self.totals["breaks"] += 1
            t *= 1.5  # restart with a spare blade
            if blades:
                self.owned[self.rng.choice(blades)] = 0.0
        clean = (not brk) and self.rng.random() < self.p["clean"]
        self.st["max_tier"] = max(self.st["max_tier"], lt)
        if lt == 2:
            self.st["t2_count"] += 1
        return t, clean, brk, lt

    def repair_all(self):
        cost = 0
        for tid, integ in self.owned.items():
            tool = self.tools[tid]
            if tool["kind"] in ("tensioner", "notebook", "kit"):
                continue
            if integ <= 0:
                cost += max(5, round(tool["price"] * 0.35))
            elif integ < self.p["repair_at"]:
                cost += max(5, round(tool["price"] * 0.15))
            else:
                continue
            self.owned[tid] = 100.0
        cost = min(cost, self.st["coins"])  # cannot go below 0; unpaid tools stay worn
        self.st["coins"] -= cost
        self.totals["repair"] += cost

    # --- Continuous mode -------------------------------------------------------------
    def tier_max(self):
        return 7 if "tw_bar" in self.owned else 5

    def grind_session(self):
        """One 8-minute Continuous-mode session; the run restarts after 3 breaks."""
        rm = self.prog["run_mode"]
        elapsed, coins = 0.0, 0
        n, lives, breaks_row = getattr(self, "_run_n", 0), getattr(self, "_lives", 3), 0
        while elapsed < SESSION_S:
            n += 1
            raw = 1 + self.s["coef"] * math.log(1 + n) * self.p["skill"]
            tier = max(1, min(self.tier_max(), int(raw)))
            if breaks_row >= rm["rubber_band_after_breaks"]:
                tier = max(1, tier - 1)
            pool = [("wafer", min(tier, 3))] if tier <= 3 else []
            if tier >= 2:
                pool.append(("pin_tumbler", min(tier, 7)))
            if tier == 1:
                pool.append(("wooden_pin", 1))
            if "pk_ward" in self.owned and tier <= 2:
                pool.append(("warded", tier))
            if "pk_lever" in self.owned and tier >= 3:
                pool.append(("lever", min(tier, 5)))
            if "tl_shackle" in self.owned and tier in (2, 3):
                pool.append(("ring_combo", tier))
            fam, lt = self.rng.choice(pool)
            inv = {v[0]: k for k, v in LOCKCORE_MAP.items()}
            tool_ids = FAMILY_TOOLS[inv.get(fam, fam)]
            # lockcore tier == the tier we play: bypass the job-tier map
            feel, cok, _ = self.bal[(fam, lt)]
            nn = self.exposure.get(fam, 0)
            learn = self.p["learn"] + (1 - self.p["learn"]) * math.exp(-nn / 3.0)
            t = feel * self.p["human_x"] * learn * self.rng.uniform(0.8, 1.25) + LOCK_OVERHEAD_S
            self.exposure[fam] = nn + 1
            pbrk = self.p["brk"] * (lt / 3.0) + ((1 - cok) if self.p is PROFILES["clumsy"] else 0)
            for b in tool_ids:
                if b in self.owned and self.tools[b]["kind"] != "tensioner":
                    self.owned[b] = max(0.0, self.owned[b] - (self.p["overs"] + 2 * self.p["stress"]))
            elapsed += t
            if self.rng.random() < pbrk:
                lives -= 1
                breaks_row += 1
                self.totals["breaks"] += 1
                if lives == 0:
                    n, lives, breaks_row = 0, 3, 0  # new run
                continue
            breaks_row = 0
            clean = self.rng.random() < self.p["clean"]
            coins += round(rm["coins_per_tier"] * lt * (1.5 if clean else 1.0))
            self.st["max_tier"] = max(self.st["max_tier"], lt)
            if lt == 2:
                self.st["t2_count"] += 1
        self._run_n, self._lives = n, lives
        self.st["coins"] += coins
        self.totals["grind_income"] += coins
        self.totals["grind_sessions"] += 1
        self.totals["grind_time"] += elapsed
        self.repair_all()
        return coins

    # --- career --------------------------------------------------------------------
    def need_tools(self, job):
        fam = self.family_of(job)
        return [t for t in FAMILY_TOOLS.get(fam, []) if t not in self.owned]

    def family_of(self, job):
        if self.s["families"] == "md":
            return JOBS_MD_FAMILY[job["id"]][0]
        return job["family"]

    def tier_of(self, job):
        return JOBS_MD_FAMILY[job["id"]][1] if self.s["families"] == "md" else job["tier"]

    def try_buy(self, idx, tids):
        for tid in tids:
            tool = self.tools[tid]
            if tid in self.owned or not unlock_ok(tool["unlock"], self.st):
                continue
            if self.st["coins"] >= tool["price"]:
                self.st["coins"] -= tool["price"]
                self.totals["tools"] += tool["price"]
                self.owned[tid] = 100.0
                self.unlock_curve.append((idx, tid))
                if tool.get("paired_with"):
                    self.owned[tool["paired_with"]] = 100.0

    def run(self, jobs):
        for idx, job in enumerate(jobs, 1):
            self.st["chapter"] = job["chapter"]
            fam, tier = self.family_of(job), self.tier_of(job)
            sessions = 0
            lock_needed = job["id"] not in NO_LOCK_JOBS
            need = self.need_tools(job) if lock_needed else []
            self.try_buy(idx, need)
            while lock_needed and self.need_tools(job) and sessions < GRIND_CAP_SESSIONS:
                self.grind_session()
                sessions += 1
                self.try_buy(idx, self.need_tools(job))
            blocked = lock_needed and bool(self.need_tools(job))
            row = dict(idx=idx, id=job["id"], ch=job["chapter"], fam=fam, tier=tier,
                       grind=sessions, blocked=blocked, time=0.0, earned=0, coins_after=0)
            if not blocked:
                t = self.p["scene_s"]
                tip = 0
                if lock_needed:
                    lt_time, clean, brk, _ = self.play_lock(fam, tier, FAMILY_TOOLS.get(fam, []))
                    t += lt_time
                    if clean:
                        tip = round(job["reward_coins"] * self.p["tip"] / self.p["clean"])
                earned = round(job["reward_coins"] * self.s["changes"].get("reward_x", 1.0)) + tip
                self.st["coins"] += earned
                self.totals["job_income"] += earned
                self.totals["job_time"] += t
                row.update(time=t, earned=earned)
                self.repair_all()
            row["coins_after"] = self.st["coins"]
            self.log.append(row)
            # buy anything useful for upcoming jobs when affordable (look-ahead 3 jobs)
            ahead = []
            for j in jobs[idx:idx + 3]:
                if j["id"] not in NO_LOCK_JOBS:
                    ahead += FAMILY_TOOLS.get(self.family_of(j), [])
            self.try_buy(idx, ahead)
        return self


def simulate(scen, prof, n, balance, jobs, tools, prog):
    out = []
    for i in range(n):
        rng = random.Random(f"{scen}-{prof}-{i}")
        out.append(Career(prof, scen, balance, tools, prog, rng).run(jobs))
    return out


def med(xs):
    return statistics.median(xs) if xs else 0


def fmt_min(s):
    return f"{s / 60:.1f}"


def continuous_check(balance, tools, prog, n=300):
    """Income per lock and per session in Continuous mode with start tools only."""
    rows = []
    for scen in ("B", "C"):
        for prof in PROFILES:
            inc, maxt = [], []
            for i in range(n):
                c = Career(prof, scen, balance, tools, prog, random.Random(f"cont-{scen}-{prof}-{i}"))
                inc.append(c.grind_session())
                maxt.append(c.st["max_tier"])
            rows.append((scen, prof, med(inc), med(maxt)))
    return rows


def tier_at(coef, skill, n):
    return 1 + coef * math.log(1 + n) * skill


def report(results, jobs, tools, prog, cont, careers):
    L = []
    w = L.append
    w("# Ekonomia kariery — symulacja (tools/econ_sim.py)")
    w("")
    w(f"Wygenerowane przez `python3 tools/econ_sim.py` ({careers} karier na profil i scenariusz, "
      "seed deterministyczny). Dane wejściowe: `game/data/jobs/*.json`, `game/data/tools.json`, "
      "`game/data/progression.json`, `lockcore/BALANCE.md`, `docs/JOBS.md`. Plik danych gry "
      "nie jest zmieniany (właściciel `game/data`: sesja B); propozycje są w §6.")
    w("")
    w("## 1. Wnioski w skrócie")
    w("")
    a, b, c = (results[s] for s in "ABC")

    def tot(res, prof, key):
        return med([x.totals[key] for x in res[prof]])

    def blocked(res, prof):
        return med([sum(r["blocked"] for r in x.log) for x in res[prof]])

    def grind_h(res, prof):
        return med([x.totals["grind_time"] for x in res[prof]]) / 3600

    for line in FINDINGS(results, jobs, tools, prog, cont):
        w(line)
    w("")
    w("## 2. Scenariusze i profile")
    w("")
    w("| Scenariusz | Opis |")
    w("|---|---|")
    for k, v in SCENARIOS.items():
        w(f"| {k} | {v['label']} |")
    w("")
    w("| Profil | czas / bot p50 | wspólczynnik nauki | overset / stress na zamek | czysto | napiwek | skill (Ciągły) | P(złamanie) bazowe |")
    w("|---|---|---|---|---|---|---|---|")
    for k, p in PROFILES.items():
        w(f"| {k} | ×{p['human_x']} | → ×{p['learn']} | {p['overs']} / {p['stress']} | "
          f"{p['clean']:.0%} | {p['tip']:.0%} | {p['skill']} | {p['brk']:.1%} × tier/3 |")
    w("")
    w("## 3. Podsumowanie kariery (mediany)")
    w("")
    w("| Scen. | Profil | zlecenia zablok. | dochód ze zleceń | dochód z grindu | sesje grindu | "
      "grind [h] | czas zleceń [min] | naprawy | narzędzia | złamania |")
    w("|---|---|---|---|---|---|---|---|---|---|---|")
    for s in "ABC":
        for prof in PROFILES:
            res = results[s]
            w(f"| {s} | {prof} | {blocked(res, prof):.0f} / 29 | {tot(res, prof, 'job_income'):.0f} | "
              f"{tot(res, prof, 'grind_income'):.0f} | {tot(res, prof, 'grind_sessions'):.0f} | "
              f"{grind_h(res, prof):.1f} | {fmt_min(tot(res, prof, 'job_time'))} | "
              f"{tot(res, prof, 'repair'):.0f} | {tot(res, prof, 'tools'):.0f} | "
              f"{tot(res, prof, 'breaks'):.0f} |")
    w("")
    w("Grind = sesje Trybu Ciągłego (8 min), które gracz musi rozegrać, zanim kupi narzędzie "
      f"potrzebne do następnego zlecenia. Po {GRIND_CAP_SESSIONS} sesjach na jedno zlecenie "
      "liczymy je jako zablokowane i idziemy dalej.")
    w("")
    w("## 4. Przebieg zlecenie po zleceniu (profil average)")
    w("")
    for s in "BC":
        w(f"### Scenariusz {s}")
        w("")
        w("| # | zlecenie | rozdz. | rodzina T | czas [min] | zarobek | sesje grindu | monety po | stan |")
        w("|---|---|---|---|---|---|---|---|---|")
        res = results[s]["average"]
        for i, job in enumerate(jobs):
            rows = [x.log[i] for x in res]
            blk = sum(r["blocked"] for r in rows) / len(rows)
            w(f"| {i + 1} | `{job['id'][4:]}` | {job['chapter']} | {rows[0]['fam']} T{rows[0]['tier']} | "
              f"{fmt_min(med([r['time'] for r in rows]))} | {med([r['earned'] for r in rows]):.0f} | "
              f"{med([r['grind'] for r in rows]):.0f} | {med([r['coins_after'] for r in rows]):.0f} | "
              f"{'zablokowane' if blk > 0.5 else ('odmowa/bez zamka' if job['id'] in NO_LOCK_JOBS else 'ok')} |")
        w("")
    w("## 5. Krzywa odblokowań (narzędzie kupione po zleceniu nr, mediana; — = nigdy)")
    w("")
    tids = [t for t in tools if tools[t]["price"] > 0 and not tools[t].get("jobs_only")]
    w("| narzędzie | cena dane / C | warunek dane / C | " +
      " | ".join(f"{s}:{p[0]}" for s in "ABC" for p in PROFILES) + " |")
    w("|---|---|---|" + "---|" * 9)
    for tid in tids:
        cells = []
        for s in "ABC":
            for prof in PROFILES:
                idxs = []
                for x in results[s][prof]:
                    got = [i for i, t in x.unlock_curve if t == tid]
                    idxs.append(got[0] if got else 99)
                m = med(idxs)
                cells.append("—" if m >= 99 else f"{m:.0f}")
        ch = SCENARIOS["C"]["changes"]
        w(f"| `{tid}` | {tools[tid]['price']} / {ch['price'].get(tid, tools[tid]['price'])} | "
          f"{tools[tid]['unlock']} / {ch['unlock'].get(tid, tools[tid]['unlock'])} | " + " | ".join(cells) + " |")
    w("")
    w("Krzywa (average): liczba posiadanych narzędzi płatnych po każdym zleceniu, mediana.")
    w("")
    w("```")
    for s in "ABC":
        res = results[s]["average"]
        counts = []
        for i in range(1, 30):
            counts.append(med([sum(1 for j, t in x.unlock_curve if j <= i) for x in res]))
        w(f"{s} " + "".join(f"{int(cn):>2d}" for cn in counts))
    w("  " + "".join(f"{i:>2d}" for i in range(1, 30)) + "   <- zlecenie nr")
    w("```")
    w("")
    w("### Krzywa trudności Trybu Ciągłego: wzór a tabela (§2.2 PROGRESSION)")
    w("")
    w("| zamek n | tabela §2.2 | wzór 0,55 (skill 1,0) | wzór 0,55 (skill 1,25) | wzór 1,2 (skill 1,0) |")
    w("|---|---|---|---|---|")
    for n, tab in ((3, "1–2"), (8, "2–3"), (15, "3–4"), (25, "4–5"), (40, "5–6")):
        w(f"| {n} | {tab} | {tier_at(0.55, 1, n):.2f} | {tier_at(0.55, 1.25, n):.2f} | {tier_at(1.2, 1, n):.2f} |")
    w("")
    w("| Scen. | Profil | monety / sesja 8 min (start: narzędzia startowe) | max tier w sesji |")
    w("|---|---|---|---|")
    for s, prof, inc, mt in cont:
        w(f"| {s} | {prof} | {inc:.0f} | {mt:.0f} |")
    w(f"\n`progression.json` zakłada {prog['economy']['session_income']} monet na sesję "
      f"i ok. {prog['economy']['avg_income_mid_run']} na zamek w środku serii.")
    w("")
    for line in PROPOSALS():
        w(line)
    w("")
    w("## 7. Model i założenia")
    w("")
    w("- Kolejność zleceń jak w `docs/JOBS.md`. Odmowy (`refuse_*`) i `wrong_floor` grane najlepszą ścieżką, bez zamka.")
    w("- Rodzina i tier zlecenia → lockcore: wkładka T1/T2/T3 → t2/t3/t4, płytkowy → t1/t2/t3, zapadkowy → t1/t2/t2 "
      "(lockcore nie ma t3), dźwigniowy → t3/t4/t5, z detektorem → t5, szyfrowa → `ring_combo` t2/t2/t3, egipski → `wooden_pin` t1.")
    w(f"- Rodziny bez modułu lockcore (magnetic, tubular, dial_safe, time_lock, dimple, axial_slider, disc_detainer): "
      f"czas bota szacowany {EST_FEEL[1]:.0f}/{EST_FEEL[2]:.0f}/{EST_FEEL[3]:.0f} s dla T1/T2/T3, niezdarny 95 % sukcesu.")
    w("- Czas gracza = p50 bota czującego × współczynnik profilu × nauka (od ×1 do ×asymptota, stała 3 zamki rodziny) "
      "× szum 0,8–1,25, plus scena zlecenia (dialog, dowody, wycena) 45–80 s.")
    w("- Zużycie wg `TOOLS.md` §2: kontakt pod napięciem (max −2), overset −1, stress −2, detektor −1/−3. "
      "Złamanie: I → 0, czas ×1,5, naprawa 35 % ceny; zużyte poniżej progu profilu: 15 % ceny (min. 5).")
    w("- P(złamanie) = bazowe × tier/3 (+ porażki bota niezdarnego dla profilu clumsy) × do +43 % przy I = 0.")
    w("- Warunki `after_tN` = gracz otworzył zamek lockcore tieru ≥ N w dowolnym trybie. `tw_bar` podnosi tier_max Trybu Ciągłego z 5 do 7. "
      "`kit_clock` (wydarzenie F2) przyjęty jako nagroda rozdziału 6.")
    w("- Napiwek tylko przy otwarciu czystym; oczekiwana wartość = udział profilu × nagroda.")
    w("- To model, nie pomiar: liczby profili trzeba zastąpić danymi z playtestów (telemetria czasu i zdarzeń `wear`).")
    return "\n".join(L) + "\n"


def FINDINGS(results, jobs, tools, prog, cont):
    """Concrete findings; numbers are taken from the simulation results."""
    a, b, c = (results[s] for s in "ABC")

    def m(res, prof, f):
        return med([f(x) for x in res[prof]])

    blocked = lambda x: sum(r["blocked"] for r in x.log)
    names = lambda res, prof: sorted({r["id"][4:] for x in res[prof] for r in x.log if r["blocked"]},
                                     key=lambda s: [j["id"][4:] for j in jobs].index(s))
    job_sum = sum(j["reward_coins"] for j in jobs)
    tool_need = {"pk_ward", "pk_lever", "tl_shackle", "tl_polar", "pk_crown", "tl_cup", "tw_bar",
                 "pk_flag", "pk_plunger", "pk_disc"}
    need_cost = sum(tools[t]["price"] for t in tool_need)
    need_cost_c = sum(SCENARIOS["C"]["changes"]["price"].get(t, tools[t]["price"]) for t in tool_need)
    ch1 = [j for j in jobs if j["chapter"] == 1]
    ch1_json_lever = [j["id"][4:] for j in ch1 if j["family"] == "lever"]
    cont_b = {p: inc for s, p, inc, _ in cont if s == "B"}
    cont_c = {p: inc for s, p, inc, _ in cont if s == "C"}
    out = [
        f"1. **Dane zleceń mają błędne rodziny.** W `game/data/jobs` 7 zamków „zapadkowych” (warded) z `JOBS.md` ma `family: lever`, "
        f"`liege_bakery` (dźwigniowy z detektorem) też `lever`, a `drummer_locker` (rurkowy) `unknown`. Skutek: rozdział 1 "
        f"zaczyna się od {len(ch1_json_lever)} zleceń wymagających korby dźwigniowej (500 monet, warunek `after_t3`), "
        f"choć rozdział 1 płaci łącznie {sum(j['reward_coins'] for j in ch1)} monet. W scenariuszu A gracz average ma "
        f"zablokowane {m(a, 'average', blocked):.0f} z 29 zleceń. Do poprawy w danych (sesja B).",
        f"2. **Wzór krzywej Trybu Ciągłego nie zgadza się z tabelą.** `1 + 0,55·ln(1+n)·skill` daje tier "
        f"{tier_at(0.55, 1, 25):.2f} na 25. zamku (tabela: 4–5); t4 wymaga n ≈ 230, t5 n ≈ 1 440. Seria z 3 życiami "
        f"nigdy tam nie dochodzi, więc warunki `after_t4`…`after_t7` są nieosiągalne w Trybie Ciągłym. Współczynnik 1,2 "
        f"odtwarza tabelę (n = 25 → {tier_at(1.2, 1, 25):.1f}).",
        f"3. **Martwa strefa: warunki bez źródła tieru.** Zlecenia otwierają co najwyżej lockcore t5 (dźwigniowy T3, detektor), "
        f"a `tl_cup` wymaga `after_t8` (w lockcore nie ma t8). W scenariuszu B (poprawione rodziny, stary wzór) zablokowane "
        f"zostają (average): {', '.join(names(b, 'average')) or 'brak'}. Kolejność narzędzi `TOOLS.md` (t5–t8) jest dłuższa niż "
        f"kariera zleceń (T1–T3).",
        f"4. **Grind: zlecenia nie finansują narzędzi.** Suma nagród 29 zleceń = {job_sum} monet (+ napiwki), a narzędzia "
        f"potrzebne zleceniom kosztują {need_cost}. Gracz average w B gra {m(b, 'average', lambda x: x.totals['grind_sessions']):.0f} "
        f"sesji Trybu Ciągłego ({m(b, 'average', lambda x: x.totals['grind_time']) / 3600:.1f} h) tylko po to, by kupić narzędzia "
        f"do zleceń; clumsy {m(b, 'clumsy', lambda x: x.totals['grind_sessions']):.0f}. To łamie zasadę „bez grind-to-win” (`TOOLS.md` §1.2). "
        f"Sesja 8 min przynosi (start, B) careful/average/clumsy: {cont_b['careful']:.0f}/{cont_b['average']:.0f}/{cont_b['clumsy']:.0f} "
        f"monet, a nie {prog['economy']['session_income']}: niski tier = 10–20 monet na zamek, nie 40.",
        "5. **Za łatwe odblokowania:** `pk_ward` (80, `after_t1`) i `tl_shackle` (150, `after_first_t2`) gracz ma od pierwszego "
        "zlecenia, które ich potrzebuje, bez decyzji. To dobrze dla samouczka, ale nie są „zakupem”, tylko formalnością: "
        "można je dać za zlecenie (nagroda rzeczowa), a monety zostawić na wybory.",
        f"6. **Naprawy są tanie, złamania nie bolą.** Mediana kosztów napraw przez całą karierę (C): careful "
        f"{m(c, 'careful', lambda x: x.totals['repair']):.0f}, average {m(c, 'average', lambda x: x.totals['repair']):.0f}, clumsy "
        f"{m(c, 'clumsy', lambda x: x.totals['repair']):.0f} monet, przy {m(c, 'clumsy', lambda x: x.totals['breaks']):.0f} złamaniach "
        f"clumsy. Darmowe narzędzia startowe naprawia się za minimum 5. Zużycie jest więc sygnałem, nie ekonomią: zgodne z tonem, "
        f"ale `repair_broken_pct` można podnieść, jeśli ma uczyć ostrożności.",
        f"7. **Po zmianach (C)** zablokowanych zleceń: careful/average/clumsy "
        f"{m(c, 'careful', blocked):.0f}/{m(c, 'average', blocked):.0f}/{m(c, 'clumsy', blocked):.0f}; grind "
        f"{m(c, 'careful', lambda x: x.totals['grind_sessions']):.0f}/{m(c, 'average', lambda x: x.totals['grind_sessions']):.0f}/"
        f"{m(c, 'clumsy', lambda x: x.totals['grind_sessions']):.0f} sesji; koszt narzędzi do zleceń {need_cost_c} zamiast {need_cost}. "
        f"Sesja 8 min (C, start) daje {cont_c['careful']:.0f}/{cont_c['average']:.0f}/{cont_c['clumsy']:.0f} monet.",
        f"8. **Czas gry:** sama ścieżka zleceń (bez grindu) trwa (C) careful/average/clumsy "
        f"{m(c, 'careful', lambda x: x.totals['job_time']) / 60:.0f}/{m(c, 'average', lambda x: x.totals['job_time']) / 60:.0f}/"
        f"{m(c, 'clumsy', lambda x: x.totals['job_time']) / 60:.0f} min. Na grę premium to krótko; Tryb Zleceń potrzebuje "
        f"więcej zleceń (cel ≥ 60) albo powtórek, a nie grindu monet.",
    ]
    return out


def PROPOSALS():
    ch = SCENARIOS["C"]["changes"]
    L = ["## 6. Proponowane zmiany liczb (do decyzji; danych nie zmieniam)", "",
         "| gdzie | pole | jest | propozycja | po co |", "|---|---|---|---|---|",
         "| `game/data/jobs/*.json` | `family` 7 zleceń „zapadkowych” | `lever` | `warded` | zgodność z `JOBS.md`; rozdział 1 bez korby za 500 |",
         "| `job.liege_bakery.json` | `family` | `lever` | `lever_detector` | `JOBS.md`: „dźwigniowy z detektorem, T2” |",
         "| `job.drummer_locker.json` | `family` | `unknown` | `tubular` | `JOBS.md`: „rurkowy, T1” |",
         "| `progression.json` | `tier_curve.formula` | `0.55 * ln(1+n)` | `1.2 * ln(1+n)` | wzór zgodny z tabelą §2.2 |"]
    for tid, price in ch["price"].items():
        L.append(f"| `tools.json` | `{tid}.price` | (dane) | {price} | koszt narzędzi do zleceń w zasięgu ~2 sesji grindu na narzędzie |")
    for tid, cond in ch["unlock"].items():
        L.append(f"| `tools.json` | `{tid}.unlock` | (dane) | `{cond}` | warunek osiągalny tierami zleceń / Trybu Ciągłego |")
    L += ["| `JOBS.md` / dane | zapadkowy T3 (3 zlecenia) | lockcore t2 max | dodać `warded` t3 albo zmienić na T2 | dziś T3 = t2, „mistrzowskie” zlecenie jest łatwiejsze od rozdziału 1 wkładki |",
          "| `progression.json` | `economy.session_income` | 300 | wartość z symulacji C (tabela §5) | dokument ma mówić prawdę o tempie |",
          "", "Ceny w tabeli §5 (kolumna „dane / C”) pokazują stan dzisiejszy i propozycję obok siebie."]
    return L


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--careers", type=int, default=200)
    ap.add_argument("--out", default=os.path.join(ROOT, "docs", "ECONOMY.md"))
    args = ap.parse_args()
    balance = load_balance()
    jobs, tools, prog = load_data()
    results = {s: {p: simulate(s, p, args.careers, balance, jobs, tools, prog) for p in PROFILES}
               for s in SCENARIOS}
    cont = continuous_check(balance, tools, prog)
    text = report(results, jobs, tools, prog, cont, args.careers)
    with open(args.out, "w", encoding="utf-8") as f:
        f.write(text)
    print(f"wrote {args.out}")


if __name__ == "__main__":
    main()
