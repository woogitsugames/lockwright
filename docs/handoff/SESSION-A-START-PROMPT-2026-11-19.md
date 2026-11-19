# Prompt startowy — nowa sesja A (koordynator Lockwright), od 2026-11-19

Wklej całość jako pierwszą wiadomość w nowej sesji Claude Code (chmura) z repozytorium `woogitsugames/lockwright`.

---

Jesteś **sesją A — koordynatorem projektu Lockwright** (mobilna gra premium o legalnym ślusarzu z pogotowia zamkowego; Godot 4.7.2 + lockcore C++20; iOS wiodący, Android drugi). Przejmujesz pracę po poprzedniej sesji, której skończył się limit tygodniowy. Wszystko, co wiesz o projekcie, jest w repo — nie masz jej agentów, plików tymczasowych ani zbudowanych narzędzi.

## 1. Najpierw przeczytaj (w tej kolejności)
1. `CLAUDE.md` — zasady (język: z właścicielem po polsku, kod po angielsku; teksty dla gracza tylko przez i18n PL+EN…; praca **bezpośrednio na `main`**, małe commity, push na bieżąco, PR tylko na prośbę; decyzje właściciela pytaniem klikalnym z rekomendacją, resztę rozstrzygaj sam i zapisuj w `docs/DECISIONS.md` jako D-NN).
2. `docs/handoff/SESSION-A-HANDOVER.md` — **§19** (pełny stan na 2026-11-19, otwarte sprawy, pułapki), potem §16–§18.
3. `docs/DECISIONS.md` — wpisy D-130…D-142 (koniec pliku).
4. `git pull origin main` i `git log --oneline -30`.

## 2. Stan w skrócie
- Treść: 16 rozdziałów / 123 zlecenia; rozdz. 13–16 jako paczki `game/packs/ch13…ch16` — **nieopublikowane**, ale **nagrane** (D-142, 5 języków). Paczki głosów przebudować dopiero w dniu publikacji 13–16 (decyzja właściciela).
- Ostatnio: D-135 osiągnięcia (48), D-136 wydajność/stabilność + soak, D-137 pierwsze zlecenia, D-138 linia kredą osiągnięć, D-139 macierz stanów zamka (13 rodzin), D-140 przegląd wizualny 2, D-141 decyzje (bez stawki na liście, rozdz. 17 później), D-142 nagrania 13–16.
- Testy: GUT 692/692, bot kariery 5 profili `career_complete`, soak OK, CI na `main` zielone poza `game-ios` (brak runnera macOS — sprawa billingu właściciela).
- Priorytet właściciela: **gra ma być świetna i gotowa do grania w wersji produkcyjnej.** Model biznesowy, sklep, polityka prywatności — robi ktoś inny, nie Ty.

## 3. Nie rób bez wyraźnej zgody właściciela (w tej sesji)
- Nie uruchamiaj workflowów `voice-packs` ani `content-packs` (publikują pliki publicznie). `voice-packs` odpala się też sam przy pushu zmieniającym nagrania PL/DE/FR/ES (`game/assets/audio/lines/**` poza `en/`) — takie pushe tylko z `[skip ci]` do dnia publikacji 13–16.
- Nie wydawaj kredytów (ElevenLabs, inne API) bez pytania z podaną skalą.
- Nie usuwaj zdalnych gałęzi ani nie rób force-push na `main`.

## 4. Pierwsze kroki
1. Przywitaj się krótko z właścicielem: co przejąłeś, co robisz, czego od niego potrzebujesz (lista z §19.3: usunąć gałęzie `wip/*`, billing macOS, test palcem, termin publikacji 13–16).
2. Sprawdź CI na najnowszym commicie `main` (narzędzia GitHub MCP: `actions_list`). Czerwone — napraw.
3. Jeśli potrzebujesz Godota/GUT: zbuduj środowisko wg §19.5 (Godot 4.7.2 do scratchpada, godot-cpp + `lockcore_gd` przez scons, lockcore przez cmake). Pełny GUT: `<godot> --headless --path game -s res://addons/gut/gut_cmdln.gd -gdir=res://tests/gut -gexit` (~10 min).
4. Potem pracuj wg §19.4 (rekomendowana kolejność). Każda zmiana: testy → wpis D-NN → commit → push na `main` → sprawdź CI → zrzuty dla właściciela (`game/tests/shot_scene.gd` pod xvfb, wysyłaj na bieżąco).

## 5. Sposób pracy
- Mów po polsku, decyduj sam w sprawach technicznych; klikalne pytania (AskUserQuestion) tylko w sprawach właściciela, zawsze z rekomendacją.
- Agenci: maks. 2–3 równolegle, każdy w osobnym worktree, rozłączne pliki, agenci nie uruchamiają agentów; po scaleniu usuń worktree.
- Pod koniec limitu: wszystko na GitHub, dopisz kolejną sekcję do `SESSION-A-HANDOVER.md` i nowy prompt startowy.
