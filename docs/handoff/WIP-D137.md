# WIP D-137 — pierwsze zlecenia po samouczku (audyt D-134, uwagi 10 i 11)

Stan: 2026-11-16, przerwane na polecenie koordynatora (koniec limitu). Gałąź `wip/d137-early-jobs`, **nie na `main`**.
Wpisu D-137 w `docs/DECISIONS.md` jeszcze nie ma — treść decyzji jest poniżej, do przeniesienia.

## Zrobione

1. **Kolejność rozdz. 1 w danych (`order` 1–6):** `grandma_broth` → `cat_bathroom` → `student_dorm` → `kiosk_shutter` →
   `bike_interview` → `refuse_ex_partner` (było alfabetycznie: rower z kółkami pierwszy). Odmowa zostaje po kiosku
   (jej `after.2` mówi pan Stefan).
2. **`job.grandma_broth`: `warded` t1 → `pin_tumbler` t2** (najniższy tier rodziny w `lockcore/tiers.json`). Żadna
   kwestia, sytuacja ani karta w 5 językach nie nazywa zamka („drzwi się zatrzasnęły”). `cat_bathroom` zostaje
   `warded` (sytuacja PL: „zasuwka z zapadką”). Nagrania bez zmian, `content.csv` linii nagranych nie dotyka.
3. **Pierwsze zlecenie rodziny jest prowadzone (kod):** rodziny bez pliku lekcji (`warded`, `wafer`, `lever`,
   `lever_detector`) miały trenera tylko w trzech pierwszych zleceniach kariery; teraz także na pierwszym zleceniu
   rodziny (`TutorialCoach.family_met`, `LockPhotoreal.family_intro_due`, zapis `lessons/<rodzina>/met`). Tylko w
   zleceniach. Rodziny z plikiem lekcji bez zmian (lekcja na pierwszym zleceniu).
4. **`job.cat_bathroom`:** nagrana kwestia bez zmian; `verify_kind: home` (nowy rodzaj), `cards: []`, `threshold: 0`,
   bez `card_detail`. Przycisk przyjazdu „Wejdź do środka”, tytuł „U klienta w domu”, zdanie „Tu nie ma czego
   sprawdzać. Ty decydujesz.” (`job.verify.home`, `verify.title.home`, `verify.hint.home`, 5 języków, na końcu
   `strings.csv`). Usunięte nienagrane `job.cat_bathroom.id.ask/.reply`.
5. **Testy:** nowy `game/tests/gut/test_first_jobs_d137.gd` (8 testów, zielone); `test_verify_kind.gd` zna `home`.
6. **Dokumenty:** `JOBS.md` (§2.7, rozdz. 1 w nowej kolejności, pokrycie), `ONBOARDING.md` §5.1,
   `research/difficulty-curve-2026-11.md` §9, audyt D-134 (uwagi 10, 11 → poprawione), `ECONOMY.md` przeliczone.
7. **`tools/econ_sim.py`:** kolejność i rodzina rozdz. 1; poprawka wyświetlania mediany „—” (było `500062`).

## Liczby (`qa/run_onboarding.sh`, PL, napięcie automatyczne)

| | przed | po |
|---|---|---|
| pierwszy zamek zlecenia | `combo` t1 | `pin_tumbler` t2 |
| otwarcie tego zamka, bot czujący / niezdarny | 24,9 s / 5,5 s | 7,8 s / 2,4 s |
| T pierwszego otwartego zamka zlecenia (od startu), czujący / niezdarny | 52,7 s / 33,2 s | 35,6 s / 30,2 s |
| lista po 3 zleceniach, czujący / niezdarny | 99,8 s / 55,9 s | 84,5 s / 52,6 s |

Stuknięcia i ekrany bez zmian (9 / 13 do pierwszego zamka zlecenia). 5 zleceń (czujący): 7,8 – 21,6 – 9,2 – 12,6 – 24,9 s.

## Status testów

- `data/tools/validate.py`, `tools/i18n_lint.py`, `data/tools/loc_qa.py`, `tools/build_content_packs.py --check`: OK.
- `pytest tools/tests`: 100 / 100.
- `qa/run_onboarding.sh`: feel, clumsy (PL), EN + dwa kciuki, 5 zleceń — wszystkie `done`.
- **Pełny GUT: NIE dokończony.** Przerwany w ok. 60 % (do `test_planb_families.gd`, 376 testów), do tego miejsca
  0 czerwonych i 0 `SCRIPT ERROR`. Trzeba puścić cały jeszcze raz.
- **Bot kariery (`qa/run_matrix.sh`, 5 profili): NIE dokończony** (trwał pierwszy profil).

## Zostało

1. Pełny GUT i `qa/run_matrix.sh` do końca; poprawić, co wyjdzie (ryzyko: testy zakładające starą kolejność rozdz. 1
   albo `coach == null` po trzecim zleceniu dla `warded`/`wafer`/`lever`).
2. Wpis D-137 w `docs/DECISIONS.md` (ten plik jako źródło), potem usunąć ten plik.
3. Rebase na `main` i jeden push.
4. Do wiadomości właściciela: w `ECONOMY.md` profil „clumsy” kupuje teraz medianowo 14 z 15 przedmiotów do końca
   rozdz. 16 (było 15) — dochód ten sam (14 462), to przesunięcie strumienia losowego na granicy, nie zmiana nagród.
