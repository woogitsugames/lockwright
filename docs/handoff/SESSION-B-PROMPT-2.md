# Sesja B — etap 2 (programista gry)

Kontynuujesz pracę jako **sesja B** nad grą **Lockwright** (repo `woogitsugames/lockwright`, gałąź `main`). Etap 1 masz zakończony (log: `docs/handoff/SESSION-B-LOG.md`). Zasady z `docs/handoff/SESSION-B-PROMPT.md` i `CLAUDE.md` nadal obowiązują: pracujesz bezpośrednio na `main`, robisz małe commity po angielsku, przed każdym pushem wykonujesz `git pull --rebase origin main`, a po każdym zadaniu wpisujesz raport do `SESSION-B-LOG.md`. Nikt nie będzie ci odpowiadał na pytania. Decyzje rozstrzygasz sam i zapisujesz je w `docs/DECISIONS.md` jako kolejne wolne D-NN. Najpierw sprawdź najwyższy numer w pliku.

## Najpierw przeczytaj
`CLAUDE.md`, `docs/DECISIONS.md` (nowe: D-31 zaakceptowana, czyli ekran zamka w planie B; D-32, czyli nazwa EN „Lockwright: Locksmith on Call”; D-33), `docs/handoff/SESSION-C-REVIEW.md` (50 uwag do twojego kodu), `docs/styles/realizm.md`, `docs/HUD.md`, `docs/ONBOARDING.md`, `docs/LEVELS.md`, `docs/JOBS.md`, `docs/PROGRESSION.md`, `docs/DESIGN.md`, `lockcore/README.md` (sekcja „API changes”).

## Kto jest właścicielem jakich katalogów (nie dotykaj cudzych)
- **Twoje:** `game/` (z wyjątkiem `game/scenes/photoreal/`, `game/scripts/photoreal/` i `game/assets/photoreal/`), `platform/`, `data/`, workflowy `game-*.yml`.
- **Sesja A (Claude):**
  - `lockcore/` i `art/`;
  - `mockups/`;
  - `game/*/photoreal/`: tam powstaje fotorealistyczny ekran zamka w planie B. Gdy będzie gotowy, sesja A dopisze w twoim logu sekcję „Od sesji A: ekran zamka photoreal” z instrukcją podpięcia.
- **Sesja C (Claude):** `spikes/`, `store/`, `audio/v2/`.

## Zadania (w tej kolejności)
1. **Poprawki z przeglądu.** Napraw wszystkie uwagi **High** (R-01…R-42 oznaczone High), a potem Medium z `SESSION-C-REVIEW.md`. Przy każdej uwadze dopisz w tym pliku pod nią linijkę `→ naprawione w <hash>` albo `→ odrzucone: <powód>`. Do każdej poprawki logiki dodaj test GUT, jeśli da się go napisać.
2. **D-32.** Nazwa EN gry w i18n i w presetach eksportu to „Lockwright: Locksmith on Call”. PL zostaje bez zmian.
3. **Pętla zlecenia (rdzeń gry)** według `JOBS.md` i `PROGRESSION.md`:
   1. lista zleceń;
   2. przyjazd;
   3. weryfikacja prawa do lokalu (dokument / sąsiad / zarządca; gra uczy, że ślusarz zawsze sprawdza);
   4. zamek;
   5. zapłata i notatka;
   6. zapis postępu.

   Wszystkie 29 zleceń z `data/` mają być grywalne od początku do końca na prawdziwym `lockcore` przez GDExtension.
4. **Sterowanie wszystkich 7 rodzin.** Pin_tumbler i wafer już działają. Dodaj mapowania wejścia i stany widoku dla: wooden_pin, warded (sonda po obwodzie), lever i lever_detector (unoszenie dźwigni, rygiel), ring_combo (obrót pierścieni, wyczucie bramki). Do każdej rodziny dodaj test GUT, w którym scripted bot z lockcore otwiera zamek przez warstwę Godota.
5. **Samouczek S1–S3** według `ONBOARDING.md`. Domyślnie włączona jest warstwa „kreda”, czyli znaki stanów z `DESIGN.md`. Po samouczku dostępna jest w opcji „Pomoc w czytaniu”. Na pierwszym ekranie gry pokaż krótką notkę „to gra, nie kurs” (PL i EN przez i18n).
6. **HUD diegetyczny** (D-12, `HUD.md`):
   - bez pasków i liczników;
   - napięcie pokazują kąt napinacza i czoło rdzenia;
   - życia to wytrychy w zwijce;
   - lupa leży na zwijce: dotknięcie powiększa widok;
   - pauza ma 48 dp i leży w safe-area.

   Tła zwijki i ekranów bierz z `mockups/realizm/img/*.jpg`. Skopiuj je do `game/assets/ui/` i wpisz do `docs/ASSETS.md`.
7. **Tryb „w ciemności”**, czyli gaśnie światło na minutnik: obraz ściemnia się do minimum, a gra prowadzi tylko dźwięk i haptyka. Do tego ustawienia dostępności z `DESIGN.md` (rozmiar, kontrast, wyłączenie haptyki z zachowaniem dźwięku i obrazu).
8. **Zrzuty ekranu.** Spróbuj renderu programowego: `godot --headless` nie rysuje, ale możesz uruchomić `xvfb-run` z `--rendering-driver opengl3` i Mesa llvmpipe (zainstaluj `xvfb mesa-utils libgl1-mesa-dri`). Zapisuj zrzuty ekranów (412×915 i 915×412) do `docs/handoff/screens/` i commituj je. Jeśli się nie da, opisz w logu dokładnie, co próbowałeś.
9. **Zielone CI na każdym pushu.** Jeśli `game-ios` lub `game-android` padnie, naprawiasz to przed kolejnym zadaniem.

Pracuj, dopóki nie skończysz wszystkich zadań. Potem wróć do listy uwag Low z przeglądu.
