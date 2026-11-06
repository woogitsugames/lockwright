# Zlecenie V04 (Mistral Vibe): sceny „dzień po”

**Repo** `woogitsugames/lockwright`, `main`. Kod/komentarze po angielsku, raport po polsku `docs/handoff/mistral/V04-REPORT.md`. Zrób, wypchnij małymi commitami, skończ.

**Kontekst:** zlecenia w `game/data/jobs/*.json` mają pole `after` (lista mówców), a teksty to klucze `<job_id>.after.N` w `game/i18n/content.csv`. Gra ich jeszcze nie pokazuje.

**Zadanie:** gdy gracz wraca do listy zleceń po skończonym zleceniu (otwarte, naprawione, rozmowa, odmowa), następnym razem przy wejściu w listę zleceń pokaż krótką scenkę „dzień po” dla **jednego** z ostatnio zakończonych zleceń, które ma `after` i jeszcze jej nie pokazano: portret mówcy (`game/assets/ui/gpt/cast/**`, fallback tabliczka z inicjałem jak w `game/scripts/ui/job_arrival.gd`), kwestia, stuknięcie zamyka. Bez głosu (są tylko napisy). Zapis „pokazane” w Save.

**Twoje pliki (tylko):** nowe `game/scripts/ui/day_after.gd`, `game/scenes/day_after.tscn`, `game/tests/gut/test_day_after.gd`; w `game/scripts/ui/jobs_list.gd` (lub ekranie listy zleceń) **tylko** minimalny hook (kilka linii). Nie ruszaj CSV, danych zleceń ani innych skryptów. Styl wg `docs/DESIGN.md` (bez kart SaaS, cele ≥ 48 dp, safe-area przez `SafeArea`).

**Testy:** scena pokazuje się raz na zlecenie, zamyka się stuknięciem, brak portretu nie wywala błędu, Save pamięta.
