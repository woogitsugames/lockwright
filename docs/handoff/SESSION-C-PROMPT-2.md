# Sesja C — etap 2 (noc, 1 agent naraz)

Kontynuujesz pracę jako **sesja C** nad grą **Lockwright** (repo `woogitsugames/lockwright`, gałąź `main`). Etap 1 masz zakończony (log: `docs/handoff/SESSION-C-LOG.md`). Zasady z `docs/handoff/SESSION-C-PROMPT.md` i `CLAUDE.md` nadal obowiązują:
- pracujesz bezpośrednio na `main`, w małych commitach po angielsku;
- przed każdym pushem robisz `git pull --rebase origin main`;
- co godzinę dopisujesz krótki wpis do `SESSION-C-LOG.md`;
- naraz pracuje najwyżej 1 agent;
- nikt nie będzie ci odpowiadał na pytania, więc decyzje zapisujesz w `docs/DECISIONS.md` jako kolejne wolne D-NN (najpierw sprawdź najwyższy numer).

## Nowe decyzje właściciela
- **D-31 zaakceptowana:** ekran zamka powstaje w planie B.
- **D-32:** nazwa EN w sklepach to „Lockwright: Locksmith on Call” (29 znaków).
- **D-33:** pomiary opóźnień robimy na telefonach właściciela, bez zakupu piezo, interfejsu audio ani dodatkowych urządzeń. Metoda: akcelerometr telefonu plus znaczniki wewnętrzne.

## Kto jest właścicielem jakich katalogów
- **Twoje:** `spikes/`, `store/`, `audio/v2/` (nowy) i `docs/handoff/POMIARY.md` (nowy).
- **Sesja B (Mistral):**
  - `game/` (bez `*/photoreal/`), `platform/`, `data/`;
  - naprawia teraz uwagi z twojego przeglądu.
- **Sesja A (Claude):** `lockcore/`, `art/`, `mockups/`, `game/*/photoreal/`.

Cudzego kodu nie zmieniasz. Uwagi do niego zapisujesz w `SESSION-C-REVIEW.md`.

## Zadania (w tej kolejności)
1. **Pomiary na telefonach właściciela (D-33).** Przerób aplikacje ze spike'ów 1–3 tak, żeby właściciel, który nie jest programistą, przeprowadził pomiar sam:
   - aplikacja prowadzi krok po kroku po polsku;
   - używa metody akcelerometrem i znaczników wewnętrznych;
   - na końcu pokazuje werdykt (zielony / na granicy / nie przechodzi według progów z `TECH.md`, opisany słowami, nie samym kolorem);
   - wynik zapisuje do pliku JSON i udostępnia go jednym przyciskiem przez systemowy arkusz udostępniania.

   Napisz `docs/handoff/POMIARY.md`: jak pobrać APK z artefaktów CI, jak zainstalować na Androidzie, jak zainstalować na iPhonie (TestFlight albo instalacja deweloperska; opisz uczciwie, czego brakuje, np. konta Apple Developer), co kliknąć i gdzie wkleić wynik. Zrób też skrypt, który wczyta te JSON-y i dopisze tabelę wyników do `TECH.md`.
2. **Sklep (`store/`).** Zaktualizuj opisy pod D-32 i uruchom `check_lengths.py`. Przygotuj szablon zrzutów sklepowych z renderów (`art/renders/`, `mockups/realizm/png/`): rozmiary iPhone 6,9" / 6,5" i Android, opisy klatek w PL i EN, bez fałszywych obietnic. Dokończ ankiety: age rating (IARC / Apple), etykiety prywatności i Data safety dla wariantu „bez zbierania danych”.
3. **Dźwięk realistyczny (`audio/v2/`).** Obecne SFX są syntezowane prosto. Zbuduj offline'owy generator dźwięków metalu metodą syntezy modalnej (Python i numpy, własny kod, bez cudzych sampli): kliknięcia pinów (mosiądz, stal), set, false set, overset, sprężyna, tarcie wytrycha, pęknięcie wytrycha, dźwignie, zapadki, pierścienie szyfru. Każde zdarzenie ma mieć 4–6 wariantów, normalizację i znaczniki onsetu ≤ 2 ms od początku pliku (opóźnienie!). Format jak w `game/` (sprawdź, co czyta autoload `Sfx`). Dołącz README, jak sesja B ma je podmienić, i wpisz zasoby do `docs/ASSETS.md`.
4. **Wydajność planu B.** Gdy w `game/scenes/photoreal/` pojawi się scena sesji A, zbuduj z niej APK testowe z licznikiem FPS i czasu klatki (artefakt CI w osobnym workflow `spike-*.yml`) i opisz pomiar w `POMIARY.md`.
5. **Drugi przegląd.** Po poprawkach sesji B (wpisy `→ naprawione w <hash>` w `SESSION-C-REVIEW.md`) sprawdź każdą poprawkę i dopisz, czy jest zweryfikowana. Przejrzyj też nowy kod (pętla zlecenia, 7 rodzin, samouczek) i dopisz nowe uwagi.
6. **Audyt dostępności** gry i makiet według `DESIGN.md` i XAG: cele dotyku ≥ 48 dp, kontrasty, stany rozróżnialne bez koloru, haptyka nigdy jako jedyny kanał, safe-area, poziom. Wynik zapisz w `docs/handoff/A11Y-AUDIT.md`.

Pracuj, dopóki nie skończysz wszystkich zadań. Na końcu zrób wpis w logu z tabelą statusów taką jak w etapie 1.
