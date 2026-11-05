# Sesja B — etap 3 (programista gry, długa praca)

Kontynuujesz pracę jako **sesja B** nad grą **Lockwright** (repo `woogitsugames/lockwright`, gałąź `main`). Etapy 1 i 2 masz za sobą. Obowiązują zasady z `SESSION-B-PROMPT.md`, `SESSION-B-PROMPT-2.md` i `CLAUDE.md`:
- pracujesz na `main`, w małych commitach po angielsku;
- przed każdym pushem robisz `git pull --rebase origin main`; jeśli rebase stanie na konflikcie, rozwiąż go do końca i **nigdy nie commituj znaczników `<<<<<<<` / `>>>>>>>`**;
- po każdym zadaniu wpis do `docs/handoff/SESSION-B-LOG.md` (zrobione, liczby, otwarte);
- CI musi być zielone po każdym zadaniu;
- nikt nie odpowie na pytania: rozstrzygasz sam i zapisujesz w `docs/DECISIONS.md` jako kolejne wolne D-NN (najpierw sprawdź najwyższy numer; teraz to D-40).

Zadania wykonuj **jedno po drugim, w tej kolejności**, aż do końca listy. Nie przerywaj po kilku.

## Najpierw przeczytaj
`docs/handoff/SESSION-B-LOG.md` (sekcje „Od sesji A: …” to zlecenia dla ciebie), `docs/handoff/SESSION-C-REVIEW.md` (uwagi N-01…N-12 z drugiego przeglądu), `docs/handoff/A11Y-AUDIT.md`, `docs/COMPLIANCE-AUDIT.md`, `docs/FEEL.md`, `docs/CLIENTS.md`, `docs/ECONOMY.md`, `docs/TOOLS.md`, `docs/HUD.md`, `docs/DECISIONS.md` od D-31 w górę, `lockcore/README.md` („API changes” v0.3 i v0.4), `audio/v2/README.md`.

## Kto jest właścicielem jakich katalogów
- **Twoje:** `game/` (bez `game/*/photoreal/`), `platform/`, `data/`, workflowy `game-*.yml`.
- **Sesja A:** `lockcore/`, `art/`, `mockups/`, `game/*/photoreal/`, `tools/econ_sim.py`.
- **Sesja C:** `spikes/`, `store/`, `audio/v2/`, `haptics/`, `qa/`, `site/`.

Z cudzych katalogów tylko czytasz i kopiujesz. Jeśli coś w nich jest złe, opisz to w swoim logu.

## Zadania

1. **Uwagi High z drugiego przeglądu.** N-09: samouczek nigdy się nie kończy. N-02: Android ucina transient segmentem oporu. Do tego pozostałe N-01…N-12. Przy każdej dopisz w `SESSION-C-REVIEW.md` linijkę `→ naprawione w <hash>`.
2. **lockcore v0.4 w grze.** Przebuduj `game/addons/lockcore_gd/bin/*` (linux, Android arm64, iOS xcframework). Wystaw w GDExtension `hold_progress` i `reset_progress`. Dodaj test GUT, że gra dostaje reguły lever v2 (`RULES_VERSION` 2).
3. **Wyczucie według `FEEL.md`.** Nałóż łatkę z §9 na `game/data/haptics_patterns.json`. Napraw 6 błędów z §7:
   1. odwrócony warunek przerwania w `feedback_director.gd`;
   2. ignorowane pod-zdarzenia;
   3. łączenie zdarzeń po samym typie;
   4. ducking oporu;
   5. podwójne skalowanie intensywności;
   6. liczba wariantów SFX.

   Do każdego dodaj test GUT. Wprowadź budżet intensywności z FEEL.md.
4. **Dźwięki `audio/v2`.** Podmień SFX według `audio/v2/README.md` (6 wariantów, 4 materiały, pętle tarcia i oporu). `check_sfx.py` ma przechodzić. Stare pliki usuń z buildu.
5. **Fotorealistyczny ekran zamka.** Podepnij scenę z `game/scenes/photoreal/` według sekcji „Od sesji A: ekran zamka photoreal” w twoim logu (D-37). Ma być domyślnym ekranem zamka dla `pin_tumbler`. Pozostałe rodziny zostają na obecnym widoku, dopóki sesja A nie dostarczy ich scen. Menu i zlecenia mają otwierać nową scenę (N-10).
6. **Dane zleceń i ekonomia (D-38, D-39).**
   - Popraw rodziny w JSON zleceń: zapadkowe → `warded`, `liege_bakery` → `lever_detector`, `drummer_locker` → `wafer` t1.
   - Usuń warunki `after_t8`.
   - Wprowadź liczby scenariusza C z `ECONOMY.md` §6.
   - Uruchom `python3 tools/econ_sim.py` i wpisz do logu, że wynik to 0 zablokowanych zleceń.
7. **Dialogi i obsada (`CLIENTS.md`).** Wklej załącznik A (207 wierszy) do `game/i18n/content.csv` i wepnij mapę mówców z załącznika B do zleceń. Ekrany przyjazdu, weryfikacji i zapłaty mają pokazywać te linie z imieniem mówcy na emaliowanej tabliczce. Zmień pannę młodą w `newlyweds_4am` na „Kasia”.
8. **Weryfikacja prawa do lokalu po ludzku.** Ekran `job_verify` pokazuje dziś surową notatkę z biblii, tylko po polsku (N-04, COMPLIANCE). Zrób z tego scenkę: dokument, sąsiad, zarządca, umowa albo pismo, z wyborem gracza i konsekwencjami. Dodaj 3 sceny odmowy z `CLIENTS.md` (`refuse_ex_partner`, `refuse_rush_bribe`, `refuse_aunt_alive`): odmowa daje reputację, a otwarcie mimo braków jest niemożliwe. Wszystko PL i EN.
9. **Typografia i dostępność.**
   - Motyw z Bona Nova (nagłówki) i Atkinson Hyperlegible Next (tekst, cyfry) z `mockups/fonts/` (OFL, wpis w ASSETS.md). Wbudowany font Godota znika.
   - Safe-area we wszystkich menu.
   - Poziom bez ucięć.
   - Skalowanie tekstu 100–200%.
   - Wszystkie punkty High i Medium z `A11Y-AUDIT.md`.
10. **Narzędzia obserwacji (D-13, D-35, `TOOLS.md`).** Lupa, mikroskop warsztatowy i wziernik (boroskop) jako mechanika: co odsłaniają, koszt, odblokowanie, zużycie czasu. Widoki optyczne bierz z makiet `mockups/realizm/02-loupe`, `03-microscope`, `04-borescope` (obrazy w `mockups/realizm/img/`).
11. **Warsztat i ekran zlecenia jako sceny.** Na podstawie makiet `mockups/realizm/03-job.html`, `04-workshop.html`, `05-workshop-optics.html`: warsztat jest menu głównym (telefon ze zleceniami, zeszyt, gablota, sklep z metkami), zlecenie jest kartą na klatce schodowej. Bez pływających paneli (D-12). Obrazy kopiuj do `game/assets/ui/` i wpisz do ASSETS.md.
12. **Gablota i Tryb Ciągły.** Gablota według `SHOWCASE.md` (otwarte zamki i notki ze źródłem; usuń link do strony działającego producenta i notatki redakcyjne z `showcase.*.source`). Tryb Ciągły z krzywą 1,2 (D-39).
13. **Zrzuty ekranu w CI.** Dodaj job `game-screens` na `ubuntu-latest`: `xvfb-run` i Mesa llvmpipe (`sudo apt-get install -y xvfb mesa-utils libgl1-mesa-dri`), Godot z `--rendering-driver opengl3`. Skrypt przechodzi po wszystkich ekranach w 412×915 i 915×412 i zapisuje PNG jako artefakt. Gdy działa, dodaj commit z kopią do `docs/handoff/screens/` (bot CI albo ręcznie, z artefaktu przez `gh run download`).
14. **Testy end-to-end.** Test GUT, w którym bot lockcore przechodzi całą karierę: samouczek, 29 zleceń, zakupy i gablotę, bez soft-locków. Zapis i odczyt w każdym kroku. Migracja `save/1` → `save/2`, jeśli zmieniłeś format.
15. **Lokalizacja QA.** Skrypt sprawdzający, że każdy klucz ma PL i EN, że nie ma polskich słów w kolumnie EN i że teksty mieszczą się w kontenerach przy skali 200%. Napraw wszystko, co znajdzie.
16. **Uwagi Low** z obu przeglądów i z `COMPLIANCE-AUDIT.md` (m.in. noty OFL w dodatku GUT).
17. **Wydajność.** Profil klatki na ekranie zamka (CPU, rysowania, pamięć). Zapisz wynik do logu. Usuń alokacje w pętli 120 Hz.

Na końcu dopisz do logu tabelę statusów wszystkich 17 zadań. Potem wróć do każdego zadania oznaczonego jako częściowe.
