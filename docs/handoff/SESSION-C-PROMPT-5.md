# Sesja C — etap 5 (1 agent naraz)

Kontynuujesz pracę jako **sesja C** nad grą **Lockwright** (repo `woogitsugames/lockwright`, `main`). Obowiązują zasady z `SESSION-C-PROMPT*.md` i `CLAUDE.md`, a własność katalogów się nie zmienia. Dokończ niezamknięte zadania etapu 4, potem wykonuj te zadania po kolei:

1. **Strażnik CI.** Co 30–60 min sprawdzaj wszystkie workflowy na `main`. Dla każdego czerwonego wpisz N-xx z linijkami logu i gotowym diffem do `SESSION-C-REVIEW.md`. Sesja B ma w etapie 5 zakaz kończenia zadań przy czerwonym CI (`SESSION-B-PROMPT-5.md`). Sprawdzaj, czy go przestrzega, i zgłaszaj każde ✅ przy czerwonym runie.
2. **Odbiór dostaw z zewnątrz.**
   - Przejrzyj wszystkie katalogi w `contrib/gpt/`: nowe dostawy G01, G04, G05, G09, G12–G16 i poprawki `v2/` (zlecenia `docs/handoff/gpt/fix/*.md`). Uzupełnij `contrib/REVIEW.md`.
   - Odsłuchaj S03 automatycznie: rozpoznawanie mowy, np. Whisper offline, jeśli się da. Wykrycie słów oznacza „do poprawki”.
   - Przejrzyj dostawy Gemini (`docs/handoff/gemini/*.md`, katalogi `art/marketing/`, `game/scenes/photoreal_families/`, `art/renders/variants/`, `docs/handoff/device-tests/`) według tych samych zasad i wpisz je do `contrib/REVIEW.md` w osobnej sekcji.
3. **Sklep, część 3.** Gdy w `contrib/gpt/G13/` (lub `v2/`) są przyjęte grafiki, złóż kompletne zestawy sklepowe w `store/` w wymiarach Apple i Google: feature graphic, zrzuty z `game-screens`, ikona (G12 v2, jeśli przyjęta). Sprawdź, czy wymiary i limity są spełnione.
4. **Raport z telefonu właściciela.** Gdy pojawią się `docs/handoff/measurements/*.json` lub `docs/handoff/device-tests/REPORT.md` (Gemini GEM3), uruchom `ingest.py`, uzupełnij `TECH.md` §8, wydaj werdykt go/no-go i zamień błędy z raportu na N-xx dla sesji B.
5. **Bot QA, część 3.** Bot kariery ma przechodzić z nowymi grafikami i dźwiękami. Dodaj kontrolę, że każdy ekran przyjazdu ma tło G07, każda postać ma portret G09 i każdy plik dźwiękowy z `data` istnieje.
6. **Ciągły przegląd** do końca limitu.
