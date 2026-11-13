#!/usr/bin/env python3
"""Career economy simulator for Lockwright (Jobs mode + Continuous-mode grinding).

Plain Python stdlib. Reads game/data (read only) and lockcore/BALANCE.md, simulates
all jobs in game/data/jobs (JOBS.md order, then every later chapter by chapter / order) for three player profiles
under four scenarios and writes docs/ECONOMY.md.

    python3 tools/econ_sim.py                 # writes docs/ECONOMY.md
    python3 tools/econ_sim.py --careers 400 --out /tmp/eco.md

Model (all assumptions are listed in the report, section "Model"):
- job order = order in docs/JOBS.md; refusal jobs are played as refusals (no lock);
- lock time = feeling-bot p50 (BALANCE.md) x human factor x learning factor;
- tool wear per lock from TOOLS.md §2 event costs and per-profile event counts;
- gated scenarios (A, B, D = before D-62): a missing tool (price or unlock condition) -> the
  player grinds Continuous-mode sessions (8 min, PROGRESSION.md §2) until it can be bought;
  capped, then "blocked".
- optional scenario (C = current data, D-62): tools never block a job. The player buys what
  coins allow (look-ahead 3 jobs, then anything unlocked with a 50-coin reserve); a family played
  without its tool is slower (MISSING_TOOL_X, the "convenience / feedback" effect) and never
  triggers grinding.
- furnishings (D-71, game/data/furnishings.json, scenario C only): cosmetic, no effect on play. After the tools,
  the player buys every furnishing whose chapter is reached, oldest chapter / cheapest first, keeping the same
  repair reserve; the report shows what each profile owns and the coins left at the end of chapter 12 (the career
  D-71 sized them for) and at the end of the career as it is now, and section 6b follows the coins chapter by
  chapter (D-124: where the shop runs out).
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
    "A": dict(label="data as is, old curve (JSON families, tier coef 0.55), tools gate jobs", families="json",
              coef=0.55, optional=False, changes={}),
    "B": dict(label="JOBS.md families, old curve (coef 0.55), tools gate jobs", families="md", coef=0.55,
              optional=False, changes={}),
    # C = what the game ships now: tools.json as is (D-62 cheaper prices), tools optional.
    "C": dict(label="current data (D-62 prices), tools optional, coef 1.2", families="md", coef=1.2,
              optional=True, changes={}),
    # D = frozen snapshot of the prices before D-62 (the old scenario C), tools gate jobs.
    "D": dict(label="before D-62 (frozen old prices), tools gate jobs, coef 1.2", families="md", coef=1.2,
              optional=False,
              changes={"price": {"tl_shackle": 150, "pk_lever": 300, "tw_bar": 450, "pk_crown": 600,
                                 "tl_polar": 700, "pk_flag": 900, "pk_plunger": 1000, "pk_disc": 1100,
                                 "tl_cup": 1200, "pk_ripple": 350, "pk_wedge": 700, "pk_feather": 2000,
                                 "ob_microscope": 250, "ob_borescope": 400, "tl_drill": 1000},
                       "unlock": {}}),
}
SCEN_ORDER = "ABCD"
MISSING_TOOL_X = 1.15  # optional tools: family played without its tool takes 15 % longer (weaker feedback)
BUY_RESERVE = 50       # optional tools: coins kept back for repairs when buying "just because"

STALE_CAP = 10  # grinding sessions without tier progress before a job counts as blocked
GRIND_CAP_SESSIONS = 60  # after this many grinding sessions for one job, the job is "blocked"
SESSION_S = 8 * 60
NEVER = 10 ** 6  # "not bought" index in the unlock tables (was 99: lower than the last job since chapter 13)
D71_CHAPTER = 12  # D-71 sized the furnishings for a career of chapters 1-12
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


# Jobs added after JOBS.md (chapters 7 and up): family from the JSON, tier = lockcore tier as written in the
# JSON (the game passes it through, N-05). Stored as ("lt", n) so lock_stats() skips the JOBS.md tier map.
LOCKCORE_DIRECT = {"pin_tumbler", "wafer", "warded", "lever", "lever_detector"}


def load_data():
    jobs = {}
    for f in glob.glob(os.path.join(ROOT, "game", "data", "jobs", "*.json")):
        d = json.load(open(f, encoding="utf-8"))
        jobs[d["id"]] = d
    order = list(JOBS_MD_FAMILY)  # JOBS.md order (chapters 1-6)
    assert set(order) <= set(jobs), set(order) - set(jobs)
    extra = sorted((j for i, j in jobs.items() if i not in JOBS_MD_FAMILY),
                   key=lambda j: (int(j["chapter"]), int(j.get("order", 0)), j["id"]))
    for j in extra:
        JOBS_MD_FAMILY[j["id"]] = (j["family"], ("lt", int(j["tier"])))
        if j["id"].startswith("job.refuse") or j.get("outcome") == "talk":
            NO_LOCK_JOBS.add(j["id"])
        order.append(j["id"])
    tools = {t["id"]: t for t in json.load(open(os.path.join(ROOT, "game", "data", "tools.json"),
                                                encoding="utf-8"))["tools"]}
    prog = json.load(open(os.path.join(ROOT, "game", "data", "progression.json"), encoding="utf-8"))
    return [jobs[i] for i in order], tools, prog


def load_furnishings():
    path = os.path.join(ROOT, "game", "data", "furnishings.json")
    if not os.path.exists(path):
        return []
    return json.load(open(path, encoding="utf-8"))["furnishings"]


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
        self.totals = dict(missing_locks=0, job_income=0, grind_income=0, repair=0, tools=0, breaks=0,
                           grind_sessions=0, job_time=0.0, grind_time=0.0)
        self.unlock_curve = []  # (job_index, tool_id)
        self.furn = []           # (job_index, furnishing id), D-71
        self.totals["furnishings"] = 0

    # --- lock model ----------------------------------------------------------------
    def lock_stats(self, family, tier):
        """Returns (lockcore family, lockcore tier, feel_p50, clumsy_ok)."""
        if isinstance(tier, tuple):  # T43: lockcore tier straight from the JSON
            lt = tier[1]
            if family in LOCKCORE_DIRECT and (family, lt) in self.bal:
                feel, cok, _ = self.bal[(family, lt)]
                return family, lt, feel, cok
            return family, lt, EST_FEEL.get(min(lt, 3), 30.0) * (1 + 0.15 * max(0, lt - 3)), EST_CLUMSY_OK
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
        if any(x not in self.owned for x in tool_ids):
            t *= MISSING_TOOL_X  # tools are optional (D-62): slower without, never blocked
            self.totals["missing_locks"] += 1
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
            if tool["kind"] in ("tensioner", "notebook", "kit", "optics"):
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

    def buy_furnishings(self, idx, furnishings):
        """D-71: cosmetic only. Oldest chapter first, then cheapest; keep the repair reserve."""
        owned = {f for _, f in self.furn}
        for f in sorted(furnishings, key=lambda x: (x["chapter"], x["price"])):
            if f["id"] in owned or self.st["chapter"] < f["chapter"]:
                continue
            if self.st["coins"] >= f["price"] + BUY_RESERVE:
                self.st["coins"] -= f["price"]
                self.totals["furnishings"] += f["price"]
                self.furn.append((idx, f["id"]))

    def run(self, jobs, furnishings=()):
        for idx, job in enumerate(jobs, 1):
            self.st["chapter"] = job["chapter"]
            fam, tier = self.family_of(job), self.tier_of(job)
            sessions = 0
            lock_needed = job["id"] not in NO_LOCK_JOBS
            need = self.need_tools(job) if lock_needed else []
            self.try_buy(idx, need)
            stale = 0  # sessions in a row without reaching a missing unlock condition
            optional = self.s.get("optional", False)
            while not optional and lock_needed and self.need_tools(job) and sessions < GRIND_CAP_SESSIONS:
                locked = [t for t in self.need_tools(job)
                          if not unlock_ok(self.tools[t]["unlock"], self.st)]
                before = self.st["max_tier"]
                self.grind_session()
                sessions += 1
                self.try_buy(idx, self.need_tools(job))
                stale = stale + 1 if locked and self.st["max_tier"] == before else 0
                if stale >= STALE_CAP:
                    break  # the condition does not move: dead zone, not grind
            blocked = not optional and lock_needed and bool(self.need_tools(job))
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
            if optional:  # buy anything unlocked that is left, cheapest first, keeping a repair reserve
                for tid in sorted(self.tools, key=lambda k: self.tools[k]["price"]):
                    t = self.tools[tid]
                    if (tid not in self.owned and t["price"] > 0 and not t.get("jobs_only")
                            and self.st["coins"] >= t["price"] + BUY_RESERVE):
                        self.try_buy(idx, [tid])
                self.buy_furnishings(idx, furnishings)
            row["coins_end"] = self.st["coins"]  # after the purchases that follow the job (D-124)
        return self


def simulate(scen, prof, n, balance, jobs, tools, prog, furnishings=()):
    out = []
    for i in range(n):
        rng = random.Random(f"{scen}-{prof}-{i}")
        out.append(Career(prof, scen, balance, tools, prog, rng).run(jobs, furnishings))
    return out


def med(xs):
    return statistics.median(xs) if xs else 0


def fmt_min(s):
    return f"{s / 60:.1f}"


def continuous_check(balance, tools, prog, n=300):
    """Income per lock and per session in Continuous mode with start tools only."""
    rows = []
    for scen in ("B", "C", "D"):
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


def report(results, jobs, tools, prog, cont, careers, furnishings=()):
    L = []
    w = L.append
    w("# Ekonomia kariery — symulacja (tools/econ_sim.py)")
    w("")
    w(f"Wygenerowane przez `python3 tools/econ_sim.py` ({careers} karier na profil i scenariusz, "
      "seed deterministyczny). Dane wejściowe: `game/data/jobs/*.json`, `game/data/tools.json`, "
      "`game/data/progression.json`, `lockcore/BALANCE.md`, `docs/JOBS.md`. Scenariusz C = dane gry "
      "bez zmian (ceny D-62); D = zamrożone ceny sprzed D-62 z narzędziem jako bramką zlecenia; A i B to diagnostyka starej krzywej.")
    w("")
    w("## 1. Wnioski w skrócie")
    w("")
    def tot(res, prof, key):
        return med([x.totals[key] for x in res[prof]])

    def blocked(res, prof):
        return med([sum(r["blocked"] for r in x.log) for x in res[prof]])

    def grind_h(res, prof):
        return med([x.totals["grind_time"] for x in res[prof]]) / 3600

    for line in FINDINGS(results, jobs, tools, prog, cont):
        w(line)
    if furnishings:
        c = results["C"]
        n = len(furnishings)
        trio = lambda f: "/".join("{:.0f}".format(med([f(x) for x in c[p]])) for p in PROFILES)
        ends = chapter_ends(jobs)
        last_ch, end12 = max(ends), ends.get(D71_CHAPTER, len(jobs))
        prices = {f["id"]: f["price"] for f in furnishings}
        w(f"7. **Wyposażenie (D-71):** {n} przedmiotów kosmetycznych za {sum(prices.values())} monet; "
          f"careful/average/clumsy kupują {trio(lambda x: snapshot(x, end12, prices)[1])} z {n} do końca rozdz. {D71_CHAPTER} "
          f"(zostaje im {trio(lambda x: snapshot(x, end12, prices)[0])} monet) i {trio(lambda x: len(x.furn))} z {n} do końca "
          f"rozdz. {last_ch}, wydają {trio(lambda x: x.totals['furnishings'])} (sekcja 6a).")
        if last_ch > D71_CHAPTER:
            w(f"8. **Po rozdz. {D71_CHAPTER} sklep się kończy (D-124):** ostatni zakup (narzędzie albo wyposażenie) wypada po zleceniu nr "
              f"{trio(lambda x: last_purchase(x, n))} z {len(jobs)}; potem nie ma już nic do kupienia poza naprawami, a na koniec "
              f"rozdz. {last_ch} zostaje {trio(lambda x: x.st['coins'])} monet (careful/average/clumsy). Przebieg rozdział po "
              f"rozdziale: sekcja 6b.")
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
    for s in SCEN_ORDER:
        for prof in PROFILES:
            res = results[s]
            w(f"| {s} | {prof} | {blocked(res, prof):.0f} / {len(jobs)} | {tot(res, prof, 'job_income'):.0f} | "
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
    for s in "CD":
        w(f"### Scenariusz {s}")
        w("")
        w("| # | zlecenie | rozdz. | rodzina T | czas [min] | zarobek | sesje grindu | monety po | stan |")
        w("|---|---|---|---|---|---|---|---|---|")
        res = results[s]["average"]
        for i, job in enumerate(jobs):
            rows = [x.log[i] for x in res]
            blk = sum(r["blocked"] for r in rows) / len(rows)
            w(f"| {i + 1} | `{job['id'][4:]}` | {job['chapter']} | {rows[0]['fam']} T{rows[0]['tier'][1] if isinstance(rows[0]['tier'], tuple) else rows[0]['tier']} | "
              f"{fmt_min(med([r['time'] for r in rows]))} | {med([r['earned'] for r in rows]):.0f} | "
              f"{med([r['grind'] for r in rows]):.0f} | {med([r['coins_after'] for r in rows]):.0f} | "
              f"{'zablokowane' if blk > 0.5 else ('odmowa/bez zamka' if job['id'] in NO_LOCK_JOBS else 'ok')} |")
        w("")
    w("## 5. Krzywa odblokowań (narzędzie kupione po zleceniu nr, mediana; — = nigdy)")
    w("")
    tids = [t for t in tools if tools[t]["price"] > 0 and not tools[t].get("jobs_only")]
    w("| narzędzie | cena przed D-62 / dane (C) | warunek | " +
      " | ".join(f"{s}:{p[:3]}" for s in "BCD" for p in PROFILES) + " |")
    w("|---|---|---|" + "---|" * 9)
    for tid in tids:
        cells = []
        for s in "BCD":
            for prof in PROFILES:
                idxs = []
                for x in results[s][prof]:
                    got = [i for i, t in x.unlock_curve if t == tid]
                    idxs.append(got[0] if got else NEVER)
                m = med(idxs)
                cells.append("—" if m >= NEVER else f"{m:.0f}")
        old = SCENARIOS["D"]["changes"]["price"].get(tid, tools[tid]["price"])
        w(f"| `{tid}` | {old} / {tools[tid]['price']} | {tools[tid]['unlock']} | " + " | ".join(cells) + " |")
    w("")
    w("Krzywa (average): liczba posiadanych narzędzi płatnych po każdym zleceniu, mediana.")
    w("")
    w("```")
    for s in "BCD":
        res = results[s]["average"]
        counts = []
        for i in range(1, 30):
            counts.append(med([sum(1 for j, t in x.unlock_curve if j <= i) for x in res]))
        w(f"{s} " + "".join(f"{int(cn):>3d}" for cn in counts))
    w("  " + "".join(f"{i:>3d}" for i in range(1, 30)) + "   <- zlecenie nr")
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
    for line in PROPOSALS(tools):
        w(line)
    w("")
    for line in FURNISHINGS(results, jobs, furnishings):
        w(line)
    w("")
    for line in CHAPTERS(results, jobs, furnishings):
        w(line)
    w("")
    w("## 7. Model i założenia")
    w("")
    w("- Kolejność zleceń jak w `docs/JOBS.md` (rozdz. 1–6), dalsze rozdziały wg pól `chapter` i `order` w danych. Odmowy (`refuse_*`) i `wrong_floor` grane najlepszą ścieżką, bez zamka.")
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
    w(f"- Scenariusz C (D-62): narzędzia opcjonalne. Gracz kupuje, co pozwalają monety (zlecenia z wyprzedzeniem 3, potem "
      f"wszystko odblokowane od najtańszego, z rezerwą {BUY_RESERVE} monet na naprawy); zamek rodziny bez jej narzędzia trwa "
      f"×{MISSING_TOOL_X}; brak grindu i blokad.")
    w("- To model, nie pomiar: liczby profili trzeba zastąpić danymi z playtestów (telemetria czasu i zdarzeń `wear`).")
    return "\n".join(L) + "\n"


def FINDINGS(results, jobs, tools, prog, cont):
    """Concrete findings; numbers are taken from the simulation results."""
    c, d = results["C"], results["D"]

    def m(res, prof, f):
        return med([f(x) for x in res[prof]])

    def trio(res, f, fmt="{:.0f}"):
        return "/".join(fmt.format(m(res, p, f)) for p in PROFILES)

    blocked = lambda x: sum(r["blocked"] for r in x.log)
    income = lambda x: x.totals["job_income"] + x.totals["grind_income"]
    bought = lambda x: sum(1 for _, t in x.unlock_curve if x.tools[t]["price"] > 0)
    paid = [t for t in tools.values() if t["price"] > 0 and not t.get("jobs_only")]
    in_reach = [t for t in paid if t["id"] != "pk_feather"]  # feather: after_t7_F3, post-chapter-6
    job_need = [t for t in in_reach if t["id"] in NEEDED_BY_JOBS]
    cost_all = sum(t["price"] for t in paid)
    cost_need = sum(t["price"] for t in job_need)
    cost_need_old = sum(SCENARIOS["D"]["changes"]["price"].get(t["id"], t["price"]) for t in job_need)
    cost_all_old = sum(SCENARIOS["D"]["changes"]["price"].get(t["id"], t["price"]) for t in paid)
    job_sum = sum(j["reward_coins"] for j in jobs)
    cont_c = {p: inc for s, p, inc, _ in cont if s == "C"}
    ends = chapter_ends(jobs)
    last_ch = max(ends)
    end12 = ends.get(D71_CHAPTER, len(jobs))
    out = [
        f"1. **D-62: tańsze narzędzia, nigdy blokada zlecenia.** Ceny w `tools.json` (C) spadły z {cost_all_old} do {cost_all} monet "
        f"za wszystkie {len(paid)} płatne narzędzia, a z {cost_need_old} do {cost_need} za te, które mają użycie w zleceniach "
        f"({len(job_need)} szt.). Suma nagród {len(jobs)} zleceń to {job_sum} monet, plus napiwki. Gra nie sprawdza narzędzi przy "
        f"przyjęciu zlecenia; model C też nie: brak narzędzia daje wolniejszy zamek (×{MISSING_TOOL_X}) i słabszy feedback, "
        f"ale nie grind.",
        f"2. **Przed (D, stare ceny, narzędzie bramką):** zablokowanych zleceń careful/average/clumsy "
        f"{trio(d, blocked)}; sesji grindu {trio(d, lambda x: x.totals['grind_sessions'])}; "
        f"dochód ze zleceń {trio(d, lambda x: x.totals['job_income'])} + grind {trio(d, lambda x: x.totals['grind_income'])} monet "
        f"wobec {trio(d, lambda x: x.totals['tools'])} wydanych na narzędzia.",
        f"3. **Po (C, nowe ceny, narzędzia opcjonalne):** zablokowanych {trio(c, blocked)}; sesji grindu "
        f"{trio(c, lambda x: x.totals['grind_sessions'])}; dochód ze zleceń {trio(c, lambda x: x.totals['job_income'])} monet, "
        f"wydane na narzędzia {trio(c, lambda x: x.totals['tools'])} (kupione: {trio(c, bought)} z {len(in_reach)} "
        f"osiągalnych płatnych); monety niewydane na koniec kariery {trio(c, lambda x: x.st['coins'])}; "
        f"zamków granych bez własnego narzędzia {trio(c, lambda x: x.totals['missing_locks'])}.",
        f"4. **Dochód a koszt narzędzi (C):** dochód ze zleceń / łączny koszt wszystkich płatnych narzędzi ({cost_all}) = "
        f"{'/'.join('{:.0%}'.format(m(c, p, lambda x: x.totals['job_income']) / cost_all) for p in PROFILES)} "
        f"(careful/average/clumsy); wobec stanu sprzed D-62: "
        f"{'/'.join('{:.0%}'.format(m(d, p, lambda x: x.totals['job_income']) / cost_all_old) for p in PROFILES)}.",
        f"5. **Naprawy (C):** {trio(c, lambda x: x.totals['repair'])} monet (careful/average/clumsy), złamań "
        f"{trio(c, lambda x: x.totals['breaks'])}; naprawa liczy się od ceny, więc tańsze narzędzia tańsze też w serwisie.",
        f"6. **Czas gry:** ścieżka zleceń (C, bez grindu, bo go nie ma) trwa careful/average/clumsy "
        f"{trio(c, lambda x: x.totals['job_time'] / 60)} min ({len(jobs)} zleceń, rozdz. 1–{last_ch}; do końca rozdz. {D71_CHAPTER}: "
        f"{trio(c, lambda x: sum(r['time'] for r in x.log[:end12]) / 60)} min przy celu D-71 ok. 2 h dla average). Długość "
        f"regulujemy liczbą zleceń, nie cenami. Tryb Ciągły (sesja 8 min, start) daje {cont_c['careful']:.0f}/{cont_c['average']:.0f}/"
        f"{cont_c['clumsy']:.0f} monet i pozostaje dodatkiem, nie warunkiem postępu.",
    ]
    return out


def PROPOSALS(tools):
    old = SCENARIOS["D"]["changes"]["price"]
    L = ["## 6. Ceny narzędzi: przed i po D-62 (zastosowane w `game/data/tools.json`)", "",
         "| narzędzie | przed | po | warunek |", "|---|---|---|---|"]
    for tid, price in old.items():
        L.append(f"| `{tid}` | {price} | {tools[tid]['price']} | `{tools[tid]['unlock']}` |")
    L += ["", "Warunki odblokowania bez zmian (tylko pacing sklepu; zlecenie nigdy nie wymaga narzędzia). "
          "Naprawa: 15 % ceny (złamane: 15 % + 10, maks. 150), więc spada razem z cenami."]
    return L


def chapter_ends(jobs):
    """chapter -> 1-based index of its last job in the career order."""
    out = {}
    for i, j in enumerate(jobs, 1):
        out[int(j["chapter"])] = i
    return out


def snapshot(x, idx, prices):
    """Career x after job idx and the purchases that follow it: (coins, furnishings owned, coins spent on them)."""
    got = [f for i, f in x.furn if i <= idx]
    return x.log[idx - 1]["coins_end"], len(got), sum(prices[f] for f in got)


def last_purchase(x, n_furnishings):
    """Job index of the last tool / furnishing bought, when nothing is left to buy afterwards; else NEVER."""
    if len(x.furn) < n_furnishings:
        return NEVER
    return max([i for i, _ in x.furn] + [i for i, _ in x.unlock_curve] + [0])


def FURNISHINGS(results, jobs, furnishings):
    """D-71: cosmetic furnishings bought from career coins (scenario C = the game as shipped)."""
    if not furnishings:
        return []
    c = results["C"]
    prices = {f["id"]: f["price"] for f in furnishings}
    total = sum(prices.values())
    n = len(furnishings)
    ends = chapter_ends(jobs)
    last_ch = max(ends)
    marks = [D71_CHAPTER] + ([last_ch] if last_ch > D71_CHAPTER else [])
    L = ["## 6a. Wyposażenie warsztatu (D-71, `game/data/furnishings.json`, scenariusz C)", "",
         f"{n} przedmiotów kosmetycznych (bez wpływu na trudność), razem {total} monet. Gracz w modelu kupuje je po narzędziach: "
         f"każdy przedmiot z osiągniętego rozdziału, najpierw starsze rozdziały i tańsze, z rezerwą {BUY_RESERVE} monet na naprawy. "
         f"Ostatni przedmiot odblokowuje rozdz. {max(f['chapter'] for f in furnishings)}.", "",
         f"| Profil | stan na koniec rozdz. | monety przed wyposażeniem | wydane na wyposażenie | kupione (mediana) | wszystkie {n}/{n} [% karier] | monety zostają |",
         "|---|---|---|---|---|---|---|"]
    for prof in PROFILES:
        res = c[prof]
        for ch in marks:
            snaps = [snapshot(x, ends.get(ch, len(jobs)), prices) for x in res]
            allp = sum(1 for sn in snaps if sn[1] == n) / len(snaps)
            L.append(f"| {prof} | {ch} | {med([sn[0] + sn[2] for sn in snaps]):.0f} | {med([sn[2] for sn in snaps]):.0f} | "
                     f"{med([sn[1] for sn in snaps]):.0f} / {n} | {allp:.0%} | {med([sn[0] for sn in snaps]):.0f} |")
    L += ["", "| przedmiot | cena | od rozdz. | " + " | ".join(f"kupiony po zleceniu nr ({p})" for p in PROFILES) + " |",
          "|---|---|---|" + "---|" * len(PROFILES)]
    end12 = ends.get(D71_CHAPTER, len(jobs))
    for f in furnishings:
        cells = []
        for prof in PROFILES:
            idxs = [next((i for i, fid in x.furn if fid == f["id"]), NEVER) for x in c[prof]]
            share = sum(1 for i in idxs if i <= end12) / len(idxs)
            m = med(idxs)
            cells.append("—" if m >= NEVER else f"{m:.0f} ({jobs[int(m) - 1]['chapter']}; {share:.0%})")
        L.append(f"| `{f['id']}` | {f['price']} | {f['chapter']} | " + " | ".join(cells) + " |")
    L += ["", f"Komórka: mediana numeru zlecenia, po którym przedmiot jest kupiony (rozdział; odsetek karier, w których "
          f"kupiono go do końca rozdz. {D71_CHAPTER}; — = mediana: nie kupiony). Cel D-71: przeciętny gracz kupuje większość do końca "
          f"rozdz. {D71_CHAPTER}, staranny wszystko, a najdroższa półka zostaje celem na końcówkę."]
    return L


def CHAPTERS(results, jobs, furnishings):
    """D-124: coins chapter by chapter (scenario C), to see where the shop runs out."""
    c = results["C"]
    prices = {f["id"]: f["price"] for f in furnishings}
    n = len(furnishings)
    ends = chapter_ends(jobs)
    trio = lambda f: " / ".join("{:.0f}".format(med([f(x) for x in c[p]])) for p in PROFILES)
    L = ["## 6b. Monety rozdział po rozdziale (scenariusz C, careful / average / clumsy, mediany)", "",
         "| rozdz. | zleceń | suma nagród | dochód z napiwkami | wydane w rozdziale (narzędzia, wyposażenie, naprawy) | "
         f"monety na koniec | wyposażenie posiadane (z {n}) |",
         "|---|---|---|---|---|---|---|"]
    start = 0
    for ch in sorted(ends):
        end = ends[ch]
        rows = jobs[start:end]
        earned = lambda x, a=start, b=end: sum(r["earned"] for r in x.log[a:b])
        spent = lambda x, a=start, b=end: ((x.log[a - 1]["coins_end"] if a else 0) + sum(r["earned"] for r in x.log[a:b])
                                           - x.log[b - 1]["coins_end"])
        L.append(f"| {ch} | {len(rows)} | {sum(j['reward_coins'] for j in rows)} | {trio(earned)} | {trio(spent)} | "
                 f"{trio(lambda x, b=end: x.log[b - 1]['coins_end'])} | {trio(lambda x, b=end: snapshot(x, b, prices)[1])} |")
        start = end
    L += ["", "Rozdział, w którym „wydane” spada do kosztu napraw, a „monety na koniec” rosną o cały dochód, to rozdział bez celu "
          "dla monet: wszystkie narzędzia i całe wyposażenie są już kupione."]
    return L


NEEDED_BY_JOBS = {"tl_shackle", "pk_lever", "tl_polar", "pk_crown", "tl_cup", "tw_bar", "pk_flag",
                  "pk_plunger", "pk_disc"}  # tools whose family appears in a job (FAMILY_TOOLS)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--careers", type=int, default=200)
    ap.add_argument("--out", default=os.path.join(ROOT, "docs", "ECONOMY.md"))
    args = ap.parse_args()
    balance = load_balance()
    jobs, tools, prog = load_data()
    furnishings = load_furnishings()
    results = {s: {p: simulate(s, p, args.careers, balance, jobs, tools, prog, furnishings) for p in PROFILES}
               for s in SCENARIOS}
    cont = continuous_check(balance, tools, prog)
    text = report(results, jobs, tools, prog, cont, args.careers, furnishings)
    with open(args.out, "w", encoding="utf-8") as f:
        f.write(text)
    print(f"wrote {args.out}")


if __name__ == "__main__":
    main()
