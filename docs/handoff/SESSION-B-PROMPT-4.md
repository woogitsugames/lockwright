# Sesja B — etap 4 (najpierw zielone CI i grywalny APK, potem kolejne prace)

Kontynuujesz pracę jako **sesja B** nad grą **Lockwright** (repo `woogitsugames/lockwright`, gałąź `main`). Obowiązują zasady z poprzednich promptów (`SESSION-B-PROMPT*.md`) i `CLAUDE.md`:
- pracujesz na `main`, w małych commitach po angielsku;
- przed pushem `git pull --rebase origin main`; konflikty rozwiązujesz do końca, **bez znaczników konfliktu w commitach**;
- po każdym zadaniu wpis do `docs/handoff/SESSION-B-LOG.md`;
- decyzje zapisujesz jako kolejne wolne D-NN w `docs/DECISIONS.md` (sprawdź najwyższy numer).

**Najważniejsza zasada tego etapu:** zadanie jest skończone dopiero wtedy, gdy **wszystkie workflowy na `main` są zielone**: `game-android`, `game-ios`, `game-tests`, `game-screens` i `qa-career` (ostatni należy do sesji C, ale pada przez grę). Po każdym pushu sprawdź wynik w GitHub Actions. Jeśli coś jest czerwone, naprawiasz to przed następnym zadaniem. Nie oznaczaj etapu jako skończonego przy czerwonym CI.

Zadania wykonuj **po kolei**, aż do końca listy.

## Własność katalogów (bez zmian)
- **Twoje:** `game/` (bez `game/*/photoreal/`), `platform/`, `data/`, `game-*.yml`.
- **Sesja A:** `lockcore/`, `art/`, `mockups/`, `game/*/photoreal/`, `tools/`, `contrib/`.
- **Sesja C:** `spikes/`, `store/`, `audio/v2/`, `haptics/`, `qa/`, `site/`, `qa-career.yml`.

## Zadania
1. **Zielone CI.**
   - `plugin-aar`: `:lockwright-click-audio` nie kompiluje się (BUILD FAILED w run 65). Napraw kod Kotlin/C++ i gradle.
   - `export-pack-test`: pack nie znajduje `addons/lockcore_gd/bin/liblockcore_gd.linux.template_debug.so` ani `res://tests/smoke.tscn`.
   - `game-screens`: napraw wszystko, co pada.
   - `qa-career`: przeczytaj raport sesji C (N-13 i dalej w `SESSION-C-REVIEW.md`) i napraw przyczyny po stronie gry.

   Na koniec wpisz do logu link do zielonego runu `game-android` z artefaktem APK.
2. **Grywalny APK dla właściciela.** Właściciel instaluje APK na swoim telefonie. Sprawdź ścieżkę od uruchomienia:
   1. notka „to gra, nie kurs”;
   2. samouczek S1–S3;
   3. warsztat;
   4. pierwsze zlecenie z fotorealistycznym zamkiem;
   5. zapłata;
   6. kolejne zlecenie.

   Nie może być zablokowań, czarnych ekranów ani ekranów bez wyjścia (przycisk wstecz Androida też ma działać). W logu dodaj krótką instrukcję „co przetestować w 10 minut” dla właściciela.
3. **Uwagi z przeglądów.** Wszystkie otwarte N-xx z `SESSION-C-REVIEW.md` i punkty z drugiej rundy `docs/handoff/A11Y-AUDIT.md`. Przy każdej dopisz `→ naprawione w <hash>`.
4. **Wzorce haptyki z plików sesji C.** Podmień wzorce z `game/data/haptics_patterns.json` na pliki z `haptics/` (AHAP na iOS, kompozycje Androida z łańcuchem zastępczym A4→A0) według `haptics/README.md`. Walidator budżetu ma przechodzić w CI.
5. **Dźwięk, część 2.** Podepnij nowe pliki z `audio/v2/`: tła (klatka, warsztat, noc, deszcz), dźwięki przedmiotów interfejsu, nagrody. Zrób miks według README: głośność w LUFS, ducking tła przy zamku.
6. **Kalibracja urządzenia przy pierwszym uruchomieniu.**
   - Krótki test haptyki i dźwięku według `TECH.md` (poziomy możliwości urządzenia A0–A4 / H0–H3), który dobiera wzorce.
   - Ekran „Wyczucie” w ustawieniach: intensywność, test i reset.
   - Przełącznik języka PL/EN w ustawieniach. Gdy istnieje `contrib/gpt/T03/` (szkic DE), dodaj DE ukryte za flagą deweloperską.
7. **Jakość grafiki pod tanie telefony.** Profile jakości: `render_scale`, MSAA i rozmiar płyty planu B. Profil dobiera się automatycznie po pierwszych 10 s (średni czas klatki) i można go zmienić w ustawieniach. Dodaj nakładkę deweloperską z FPS i czasem klatki (tylko w buildzie debug).
8. **Build wydaniowy Androida.**
   - Gradle release i AAB.
   - Podpis kluczem z GitHub Secrets (`ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`). Jeśli sekretów brak, krok się pomija bez błędu.
   - Numer wersji z tagu.
   - Raport rozmiaru paczki w CI.
   - W logu instrukcja dla właściciela, jak wygenerować keystore i wpisać sekrety.
9. **iOS.** Artefakt IPA bez podpisu z CI (już się kompiluje). Opisz w logu, czego brakuje do TestFlight (konto Apple Developer, certyfikaty, profile) i przygotuj workflow `game-ios-release.yml`, który zadziała po dodaniu sekretów. Do tego czasu wyłączony (`workflow_dispatch`).
10. **Osiągnięcia i wskazówki.** Gdy istnieje `contrib/gpt/T10/`, wczytaj osiągnięcia lokalnie (bez Game Center i Play Games na razie, za interfejsem gotowym na nie) oraz wskazówki mistrza na ekranie ładowania i wpisy do zeszytu. Wszystko przez i18n PL/EN.
11. **Rozdział 7.** Gdy istnieje `contrib/gpt/T09/` (12 zleceń), sprawdź JSON-y walidatorem, dodaj je jako rozdział 7 za flagą „po premierze” i uruchom `python3 tools/econ_sim.py` (wynik do logu).
12. **Lokalny dziennik błędów bez telemetrii.** Zapis do `user://logs/` z rotacją, ekran „Zgłoś problem” w ustawieniach, który kopiuje ostatni log do schowka lub udostępnia go przez systemowe menu udostępniania. Bez wysyłania czegokolwiek z urządzenia.
13. **Napisy końcowe i licencje.** Ekran „O grze”: autorzy, fonty OFL, biblioteki (Godot MIT, godot-cpp, GUT MIT) i zasoby z `docs/ASSETS.md`. Plik `THIRD-PARTY-NOTICES` generowany skryptem.
14. **Test regresji wyglądu.** Zrzuty z `game-screens` porównuj z poprzednim zielonym runem (SSIM lub prosta różnica pikseli). Workflow raportuje ekrany, które zmieniły się o więcej niż próg, z miniaturami w artefakcie.

Na końcu dodaj do logu tabelę statusów wszystkich 14 zadań z linkami do zielonych runów.
