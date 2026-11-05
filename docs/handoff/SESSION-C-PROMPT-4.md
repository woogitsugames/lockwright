# Sesja C — etap 4 (długa praca, 1 agent naraz)

Kontynuujesz pracę jako **sesja C** nad grą **Lockwright** (repo `woogitsugames/lockwright`, gałąź `main`). Obowiązują zasady z poprzednich promptów (`SESSION-C-PROMPT*.md`) i `CLAUDE.md`:
- pracujesz na `main`, w małych commitach po angielsku;
- przed pushem `git pull --rebase origin main`, bez znaczników konfliktu w commitach;
- co godzinę wpis do `docs/handoff/SESSION-C-LOG.md`;
- naraz pracuje najwyżej 1 agent;
- decyzje zapisujesz jako kolejne wolne D-NN.

Najpierw dokończ zadania z `SESSION-C-PROMPT-3.md`, których nie oznaczyłeś jako gotowe (sprawdź swoją tabelę w logu). Potem wykonuj poniższe **po kolei**.

## Własność katalogów
- **Twoje:** `spikes/`, `store/`, `audio/v2/`, `haptics/`, `qa/`, `site/`, `qa-career.yml`, `docs/handoff/POMIARY.md`, `A11Y-AUDIT.md`, `SESSION-C-REVIEW.md`, nowe `contrib/REVIEW.md`, nowe `docs/handoff/RELEASE-CHECKLIST.md`.
- **Sesja B:** `game/` (bez `*/photoreal/`), `platform/`, `data/`, `game-*.yml`. W etapie 4 naprawia CI i robi build wydaniowy (`SESSION-B-PROMPT-4.md`).
- **Sesja A:** `lockcore/`, `art/`, `mockups/`, `game/*/photoreal/`, `tools/`, `contrib/gpt/`.

## Zadania
1. **Pilnowanie zielonego CI.** Co godzinę sprawdzaj wszystkie workflowy na `main`. Dla każdego czerwonego wpisz do `SESSION-C-REVIEW.md` jako N-xx: dokładną przyczynę z logu (linie), plik i proponowaną poprawkę (diff w bloku kodu). Cudzego kodu nie zmieniasz. `qa-career.yml` jest Twój: utrzymuj go zielonym albo wyraźnie oddziel błędy gry (raport) od błędów samego workflowu.
2. **Przegląd dostaw ChatGPT (`contrib/gpt/`).** Do `contrib/gpt/` trafia do 30 dostaw od zewnętrznych sesji ChatGPT (zlecenia: `docs/handoff/gpt/*.md`). Dla każdej dostawy sprawdź:
   - zgodność z kryteriami odbioru zlecenia;
   - zasady: zero marek i logotypów, zero podobieństwa do prawdziwych osób i dokumentów, zakazane klisze z `DESIGN.md`, ton bez estetyki złodzieja;
   - czy jest `ASSETS.md` z promptami i narzędziem;
   - jakość techniczną: rozdzielczość, bezszwowość tekstur (podgląd 2×2), onset i LUFS dźwięków, poprawność CSV i JSON.

   Wynik zapisz w `contrib/REVIEW.md`: tabela ID → przyjęte / do poprawki / odrzucone, z powodem. Nie przenoś plików do gry, to robi sesja A. Rób to w każdej rundzie, gdy pojawią się nowe dostawy.
3. **Testy wewnętrzne w sklepach, instrukcja dla właściciela.** Napisz `docs/handoff/TESTY-SKLEPY.md`, krok po kroku po polsku:
   - **Google Play:** konto dewelopera, internal testing, wgranie AAB z CI, testerzy przez e-mail lub link;
   - **App Store:** Apple Developer, App Store Connect, TestFlight, certyfikaty i profile, wgranie z CI po dodaniu sekretów;
   - kolejność kroków, koszty, czasy weryfikacji kont.

   Uczciwie zaznacz, czego nie da się zrobić bez właściciela.
4. **Lista kontrolna przed wydaniem.** `docs/handoff/RELEASE-CHECKLIST.md`: technika (CI, rozmiar, start, FPS, pamięć, crash-free), treść (i18n 100%, notka „to gra, nie kurs”, licencje i `THIRD-PARTY-NOTICES`), sklep (opisy, zrzuty, rating, prywatność, kontakt), prawo (regulamin, polityka prywatności), dostępność (A11Y-AUDIT), marketing (strona, press kit). Każdy punkt: stan, odpowiedzialny (A/B/C/właściciel), link do dowodu.
5. **Bot QA, część 2.** Rozszerz `qa/`:
   - profile gracza „niezdarny” i „średni” (boty lockcore z `--clumsy` i `--feel`) w całej karierze;
   - raport ekonomii z gry porównany z `tools/econ_sim.py` (rozbieżności > 10% jako N-xx);
   - test języka EN (cała kariera po angielsku: brakujące klucze, ucięte teksty na zrzutach);
   - test trybu „w ciemności” (czy kariera jest przechodnia bez obrazu: same zdarzenia dźwięku i haptyki z logów).
6. **Pomiary właściciela.** Gdy w repo pojawią się pliki JSON z pomiarów (`docs/handoff/measurements/`), uruchom `ingest.py`, uzupełnij tabelę w `TECH.md` §8 i zapisz werdykt go / no-go dla Godota według kryteriów porzucenia z `TECH.md`.
7. **Strona gry, część 2 (`site/`).** Gdy w `contrib/gpt/` pojawią się przyjęte (zadanie 2) grafiki G12 (ikona) i G13 (key art), przygotuj z nich wersję strony (kopie w `site/assets/` z wpisem w ASSETS.md). Dodaj stronę „Jak gramy uczciwie” (weryfikacja prawa do lokalu, odmowy, „to gra, nie kurs”) PL i EN. Publikacja dalej wyłączona.
8. **Audyt licencji zależności.** Lista wszystkich zależności (Godot, godot-cpp, GUT, biblioteki Androida i iOS, narzędzia w CI, fonty) z licencjami i obowiązkami (np. teksty licencji w aplikacji). Wynik w `store/legal/DEPENDENCIES.md`. Rozbieżności z `THIRD-PARTY-NOTICES` sesji B zgłaszaj jako N-xx.
9. **Ciągły przegląd** commitów sesji B i dostaw `contrib/gpt/` do końca limitu.

Na końcu dopisz do logu tabelę statusów.
