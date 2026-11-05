# Sesja B — etap 5: zielone CI naprawdę, potem grafiki, dźwięki i teksty z dostaw zewnętrznych

Kontynuujesz pracę jako **sesja B** nad grą **Lockwright** (repo `woogitsugames/lockwright`, `main`). Obowiązują zasady z `SESSION-B-PROMPT*.md` i `CLAUDE.md`.

**Zasada nr 1 (nie była przestrzegana w etapach 3 i 4):** zadanie **nie jest skończone**, dopóki ostatni run na `main` każdego z workflowów `game-android`, `game-ios`, `game-tests`, `game-screens` i `qa-career` nie jest zielony. Po każdym pushu otwórz GitHub Actions, poczekaj na wynik i przeczytaj log czerwonego joba. W logu wpisuj link do zielonego runu. Nie oznaczaj zadania ✅ przy czerwonym CI.

Własność katalogów bez zmian: Twoje są `game/` (bez `*/photoreal*`), `platform/`, `data/` i `game-*.yml`. Z `contrib/` tylko czytasz i kopiujesz.

## Zadania (po kolei)
1. **CI na zielono.**
   - `qa-career` pada na błędach GDScript w grze. Przeczytaj raport w artefakcie i N-29 (regresja High z gotowym diffem) w `docs/handoff/SESSION-C-REVIEW.md`.
   - Napraw `game-ios` i `game-tests`.
   - Każdą przyczynę opisz w logu.
2. **Grafiki ChatGPT (D-43, `docs/DECISIONS.md`).** Kopiuj do `game/assets/ui/gpt/` (JPG/WebP ≤ 1 MB, PNG z alfą tam, gdzie jest alfa), wpisz do `docs/ASSETS.md` i podepnij:
   - **G07** `contrib/gpt/G07/images/*.jpg`: tła ekranu przyjazdu wg miejsca i pory (dodaj pola `place`, `time` w danych zleceń);
   - **G01** `contrib/gpt/G01/plate_*.png`: tabliczki mieszkań i pomieszczeń (PL/EN wg języka);
   - **G08** `contrib/gpt/G08/images/`: tło warsztatu wg pory dnia;
   - **G09** `contrib/gpt/G09/`: portrety i awatary postaci przy liniach dialogu (`docs/CLIENTS.md`, mapa mówców);
   - **G11** `contrib/gpt/G11/png/`: kartki samouczka S1–S3 (wersja wg języka, `clean` przy „bez tekstu”), pieczątka ze `stamps/`;
   - **G14** `contrib/gpt/G14/png/`: rekwizyty na ekranie weryfikacji (umowa, pismo administracji, karta lokatora) i zapłaty (pokwitowanie). Jeśli pojawi się `contrib/gpt/G14/v2/`, użyj v2;
   - **G15** `contrib/gpt/G15/`: mapa dzielnicy w warsztacie, ze znaczkami rozdziałów;
   - **G16** `contrib/gpt/G16/`: zdjęcia eksponatów i karteczki w gablocie;
   - **G10** `contrib/gpt/G10/pages-jpg/`: strony zeszytu w gablocie i notatkach (v2, jeśli się pojawi).
3. **Dźwięki ChatGPT.** Najpierw przeczytaj uwagi sesji C w `contrib/REVIEW.md`.
   - **S01**, muzyka: menu, warsztat, cicha wersja w zamku, jingle. Do miksu według `audio/v2/README.md`: w zamku −2…6 kHz wolne, ducking.
   - **S02**: tła i foley kamienicy (kroki, stuk, dzwonek, minutnik).
   - **S03**: bezsłowne odgłosy postaci przy liniach dialogu, znormalizowane do ok. −28 LUFS M według uwagi C.
   - **S04**: porównaj z `audio/v2/out/ui` i wybierz lepsze.
   - `check_sfx.py` musi przechodzić.
4. **Teksty ChatGPT.**
   - **T01** i **T02**: zastosuj poprawki EN (`content_en_reviewed.csv`, `strings_en_reviewed.csv`) tam, gdzie `en_new` różni się od `en_old`.
   - **T03**: dodaj język DE za flagą deweloperską.
   - **T04**: podmień notki gabloty na `showcase_notes_fixed.md` (PL/EN).
   - **T10**: jeśli istnieje `contrib/gpt/T10/v2/`, podmień osiągnięcia (bez „master lock”).
   - `loc_qa.py` musi przechodzić.
5. **Zrzuty z prawdziwej gry.** Z artefaktu `game-screens` (zielonego) skopiuj aktualne PNG do `docs/handoff/screens/` i opisz w logu, co widać na każdym ekranie.
6. **Test na telefonie (gdy pojawią się wyniki).** Jeśli w `docs/handoff/device-tests/` pojawi się raport z telefonu właściciela (Gemini GEM3), napraw każdy błąd z listy, od najpoważniejszego.

Na końcu dodaj tabelę statusów z linkami do zielonych runów.
