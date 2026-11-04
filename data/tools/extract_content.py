#!/usr/bin/env python3
"""Extracts content data from docs/JOBS.md and docs/SHOWCASE.md into
game/data/jobs/*.json, game/data/showcase/*.json and game/i18n/content.csv.

Texts for players are i18n keys; PL/EN strings live in content.csv.
Run: python3 data/tools/extract_content.py
"""

import csv
import json
import os
import re

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
JOBS_MD = os.path.join(ROOT, "docs", "JOBS.md")
SHOWCASE_MD = os.path.join(ROOT, "docs", "SHOWCASE.md")
OUT_JOBS = os.path.join(ROOT, "game", "data", "jobs")
OUT_SHOWCASE = os.path.join(ROOT, "game", "data", "showcase")
OUT_CSV = os.path.join(ROOT, "game", "i18n", "content.csv")

FAMILY_MAP = {
    "zapadkowy": "lever", "kłódka szyfrowa": "combo", "wkładka bębenkowa": "pin_tumbler",
    "płytkowy": "wafer", "dźwigniowy": "lever", "egipski": "egyptian",
    "magnetyczny": "magnetic", "rurowy": "tubular", "sejf z tarczami": "dial_safe",
    "dimple": "dimple", "zamek czasowy": "time_lock", "bramah": "bramah",
    "tarczowy": "disc_detainer",
}

# Short EN renderings of the PL client/situation blurbs (authored for the game).
EN_OVERRIDES = {
    "job.grandma_broth": ("Mrs Halina, 81.", "The door slammed; a pot of broth is on the stove. Neighbour Zosia already turned the gas off."),
    "job.cat_bathroom": ("Marta, 34, graphic designer, works from home, has a cat named Potato.", "The cat jumped on the handle and locked itself in the bathroom."),
    "job.bike_interview": ("Kuba, 23, just graduated, borrowed a blazer, off to his first job interview.", "He changed his bike lock code and forgot it. The interview is at 9:30 across town."),
    "job.student_dorm": ("Zuzanna, 20, conservation student, brought a bag full of brushes.", "The key is inside; the roommate is on an internship in Toruń."),
    "job.kiosk_shutter": ("Mr Stefan, 67. Has run the kiosk since 1994.", "The padlock on the shutter is rusted and the first bus arrives in half an hour."),
    "job.refuse_ex_partner": ("A man around 40, introduces himself as Darek, agitated, phone face-down.", "He wants into his ex-partner's flat to get his things. The mailbox has one surname, and it isn't his."),
    "job.newlyweds_4am": ("Ola and Bartek; she in a crooked veil, he with the bouquet.", "The keys are in the maid of honour's bag, which drove off to Kalisz."),
    "job.pizzeria_pays_pizza": ("Mrs Renata, 52, owner of the \"U Renaty\" pizzeria.", "She needs in fast; the evening rush starts soon."),
    "job.night_nurse": ("Agnieszka, 45, internal-medicine nurse, jacket over her uniform.", "Twelve-hour shift over, keys left at the ward."),
    "job.wrong_floor": ("Mr Kazimierz, 60, coming home from his brother-in-law's name day, in great spirits.", "He is one floor down from his own flat."),
    "job.refuse_rush_bribe": ("A man in a suit, polite and very fast.", "He says his sister said it's fine to open the flat. The ID shows a different surname than on the door."),
    "job.drummer_locker": ("Iga, 27, drummer of \"Sour Apples\".", "Her drumsticks are locked in the rehearsal-room locker."),
    "job.grandpa_chest": ("Ola, 38, biology teacher, and her mother Krystyna.", "Grandpa Józef's chest won't open; letters from Charleroi are inside."),
    "job.uncle_safe_heirs": ("Siblings Ewa, Marek and Piotr, each with their own theory about the safe.", "Uncle Bogdan's safe; the inheritance paper is needed first."),
    "job.dollhouse_wooden_lock": ("Hania, 7, and her dad Tomasz, a third-generation carpenter.", "Great-grandpa's dollhouse has a wooden lock."),
    "job.allotment_shed": ("Mr Zbyszek, 74, allotment gardener.", "His shed padlock; his tomatoes are inside."),
    "job.widow_bureau": ("Mrs Irena, 79, retired librarian, a widow for a year.", "The writing desk won't open."),
    "job.refuse_aunt_alive": ("A woman around 30.", "She claims to be the sole heir; the aunt in question is doing fine."),
    "job.krakow_tenement_gate": ("Mrs Wanda, manager of the 1890 tenement on Kazimierz.", "The big gate lock has many wards."),
    "job.swiatniki_journeyman_padlock": ("Mr Władysław, 84.", "His journeyman padlock from the 1950s, with a hidden latch (fictional mechanism)."),
    "job.krakow_antiquarian": ("Mr Leopold, 70, antiquarian.", "The strongbox; the cashbox inside is not his."),
    "job.brussels_townhouse": ("Magda, 41, translator in Brussels for 15 years.", "A townhouse in Saint-Gilles; dimple lock."),
    "job.ghent_beguinage": ("Brother Pieter, 66, caretaker of a Ghent béguinage.", "A door in the béguinage; 18th-century books inside."),
    "job.liege_bakery": ("Nadia, 29, took over the bakery from her uncle.", "The bakery at four in the morning; detector lock."),
    "job.charleroi_letters": ("Ola from job.grandpa_chest, now in Belgium, calling for advice, not an opening.", "Grandpa's letters hold an address; the cashbox is not for opening."),
    "job.museum_time_lock": ("Dr Anna Rygiel, curator at the Port Museum of Technology.", "The time lock guarding the vault."),
    "job.bramah_bureau": ("Gosia, 36, furniture restorer with her own workshop at the Port.", "The English bureau; Bramah lock."),
    "job.finnish_sailor": ("Aino, 50, chief engineer on a Finnish ship docked for two days.", "The sailor's sea chest; disc detainer."),
    "job.time_capsule": ("Mrs Jadwiga, retired form teacher, with her class of thirty-somethings.", "Class 3b's time capsule; combination padlock."),
}


def split_title(raw: str):
    m = re.match(r"(.+?)\s*/\s*\*(.+?)\*", raw)
    if m:
        return m.group(1).strip(), m.group(2).strip()
    return raw.strip(), raw.strip()


def field(block: str, name: str) -> str:
    m = re.search(r"\*\*%s:\*\*\s*(.+)" % re.escape(name), block, re.S)
    if not m:
        return ""
    return m.group(1).strip().split("\n")[0].strip()


def parse_jobs():
    text = open(JOBS_MD, encoding="utf-8").read()
    sec = text.split("## 5. Zlecenia")[1].split("## 6.")[0]
    jobs = []
    for chunk in re.split(r"\n#### ", sec)[1:]:
        m = re.match(r"`(job\.[a-z0-9_]+)`", chunk)
        if not m:
            continue
        jid = m.group(1)
        title_pl, title_en = split_title(field(chunk, "Tytuł"))
        client_pl = field(chunk, "Klient")
        sit_pl = field(chunk, "Sytuacja")
        zamek = field(chunk, "Zamek")
        fam = "unknown"
        for k, v in FAMILY_MAP.items():
            if zamek.lower().startswith(k):
                fam = v
                break
        tier = (re.search(r"T([123])", zamek) or [None, "1"])[1]
        reward = re.search(r"(\d+)\s*monet", field(chunk, "Nagroda"))
        roz = field(chunk, "Rozdział / dzielnica")
        chapter = roz.split(",")[0].strip()
        district = roz.split(",")[1].strip().rstrip(".") if "," in roz else ""
        en_client, en_sit = EN_OVERRIDES.get(jid, (client_pl, sit_pl))
        jobs.append({
            "id": jid, "chapter": int(chapter), "district": district,
            "family": fam, "tier": int(tier),
            "verification": field(chunk, "Weryfikacja"),
            "reward_coins": int(reward.group(1)) if reward else 0,
            "tone": field(chunk, "Ton").rstrip("."),
            "i18n": {"title": f"{jid}.title", "client": f"{jid}.client", "situation": f"{jid}.situation"},
            "texts": {"title": [title_pl, title_en], "client": [client_pl, en_client], "situation": [sit_pl, en_sit]},
        })
    return jobs


def parse_showcase():
    text = open(SHOWCASE_MD, encoding="utf-8").read()
    sec = text.split("## Notki (20)")[1].split("## Mapa")[0]
    notes = []
    for chunk in re.split(r"\n### ", sec)[1:]:
        m = re.match(r"\d+\.\s*`(showcase\.[a-z0-9_]+)`", chunk)
        if not m:
            continue
        nid = m.group(1)
        title_pl, title_en = split_title(field(chunk, "Tytuł"))
        pl = re.search(r"\*\*PL:\*\*\s*(.+)", chunk, re.S)
        en = re.search(r"\*\*EN:\*\*\s*(.+)", chunk, re.S)
        src = re.search(r"\*\*Źródła?:\*\*\s*(.+)", chunk, re.S)
        conf = re.search(r"\*\*Pewność:\*\*\s*(.+)", chunk, re.S)
        unl = field(chunk, "Odblokowuje")
        body_pl = pl.group(1).strip().split("\n-")[0].strip() if pl else ""
        body_en = en.group(1).strip().split("\n-")[0].strip() if en else ""
        notes.append({
            "id": nid,
            "unlocks": unl,
            "source": src.group(1).strip() if src else "",
            "confidence": conf.group(1).strip() if conf else "",
            "i18n": {"title": f"{nid}.title", "body": f"{nid}.body"},
            "texts": {"title": [title_pl, title_en], "body": [body_pl, body_en]},
        })
    return notes


def write_csv(rows: dict) -> None:
    os.makedirs(os.path.dirname(OUT_CSV), exist_ok=True)
    with open(OUT_CSV, "w", encoding="utf-8", newline="") as f:
        w = csv.writer(f)
        w.writerow(["keys", "en", "pl"])
        for key in sorted(rows):
            en, pl = rows[key]
            w.writerow([key, en, pl])


def main() -> None:
    os.makedirs(OUT_JOBS, exist_ok=True)
    os.makedirs(OUT_SHOWCASE, exist_ok=True)
    rows = {}
    jobs = parse_jobs()
    for j in jobs:
        jid = j["id"]
        with open(os.path.join(OUT_JOBS, jid + ".json"), "w", encoding="utf-8") as f:
            json.dump({k: v for k, v in j.items() if k != "texts"}, f, ensure_ascii=False, indent=2)
        for part in ("title", "client", "situation"):
            rows[f"{jid}.{part}"] = (j["texts"][part][1], j["texts"][part][0])
    notes = parse_showcase()
    for n in notes:
        nid = n["id"]
        with open(os.path.join(OUT_SHOWCASE, nid + ".json"), "w", encoding="utf-8") as f:
            json.dump({k: v for k, v in n.items() if k != "texts"}, f, ensure_ascii=False, indent=2)
        rows[f"{nid}.title"] = (n["texts"]["title"][1], n["texts"]["title"][0])
        rows[f"{nid}.body"] = (n["texts"]["body"][1], n["texts"]["body"][0])
    write_csv(rows)
    print(f"jobs={len(jobs)} showcase={len(notes)} i18n_rows={len(rows)}")


if __name__ == "__main__":
    main()
