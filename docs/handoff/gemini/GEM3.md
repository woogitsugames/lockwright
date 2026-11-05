# Zlecenie GEM3 — Testy na telefonie właściciela (adb)

**Dla:** Gemini w Google Antigravity, jedna sesja agenta na jedno zlecenie. Pracujesz na komputerze właściciela: masz terminal, pliki i git.
**Repo:** `https://github.com/woogitsugames/lockwright`, gałąź `main`. Sklonuj repo albo zrób `git pull`, jeśli już jest.
**Twoje katalogi (tylko tu zapisujesz):** `docs/handoff/measurements/`, `docs/handoff/device-tests/`
**Raport:** `docs/handoff/device-tests/REPORT.md` (po polsku).

## 1. O projekcie
**Lockwright** to mobilna gra premium (iOS, Android, Godot 4.7.2 + biblioteka C++ `lockcore`). Gracz jest **legalnym ślusarzem z pogotowia**: otwiera zamki ludziom zatrzaśniętym za drzwiami w starej kamienicy i zawsze sprawdza prawo do lokalu. Wygląd: **maksymalny fotorealizm** (proceduralne modele w Blenderze 4.2 LTS, Cycles) i interfejs bez pływających paneli.

Przeczytaj: `CLAUDE.md`, `docs/styles/realizm.md`, `docs/DESIGN.md` (kod stanów i zakazy), `docs/HUD.md`, `contrib/gpt/T06/README.md` (krytyka wyglądu, ważna), `docs/handoff/POMIARY.md` (cała instrukcja pomiarów), `docs/handoff/TESTY-SKLEPY.md`, `docs/handoff/SESSION-B-LOG.md` (ostatnie wpisy: co testować).

## 2. Zasady
- Ciepły, legalny ton. Mechanizmy wymyślone. **Zero marek** zamków, samochodów i narzędzi. Zero instrukcji do realnych produktów. Zero estetyki złodzieja.
- Zakazane: neon, bloom na metalu, chrom (roughness ≥ 0,16), glassmorphism, gradienty fiolet-niebieski i teal-orange, emoji jako ikony, zielony ptaszek / czerwony X, pasek wytrzymałości.
- Każdy stan (binding, set, overset, false set, bliskie złamanie) musi być rozróżnialny w skali szarości.
- Zasoby: własne, CC0 albo generowane przez AI. Każdy wpisany do `docs/ASSETS.md` (sekcja „Gemini”) z narzędziem i promptem.
- **Nie zmieniaj plików poza swoimi katalogami.** Pozostałe katalogi należą do sesji A, B i C, które pracują równolegle i pushują na `main`. Wyjątek: dopisanie wpisów do `docs/ASSETS.md`.
- Kod, komentarze i nazwy plików po angielsku. Raport po polsku.

## 3. Zadanie
Właściciel podłączy do komputera swój telefon z Androidem kablem USB, z włączonymi opcjami programisty i debugowaniem USB. Jeśli telefon nie jest podłączony, poproś o to właściciela w czacie Antigravity i poczekaj.
1. Zainstaluj platform-tools (adb) i `gh` (GitHub CLI) i zaloguj `gh` (właściciel potwierdzi). Pobierz z GitHub Actions najnowsze zielone artefakty: `lockwright-android-debug` (gra), `measure-android-apk` (pomiary), `planb-perf-apk` (wydajność). Komendy: `gh run list`, `gh run download`.
2. Zainstaluj je przez `adb install -r`. Zapisz model telefonu, wersję Androida i SoC (`adb shell getprop`).
3. **Pomiary (POMIARY.md):** przeprowadź właściciela przez kreator pomiarów. Wynikowe JSON-y pobierz `adb pull` do `docs/handoff/measurements/` i uruchom `ingest.py` według instrukcji.
4. **Wydajność:** uruchom planb-perf na 10 minut, zbierz `adb logcat` z liniami `LW_PERF` i temperaturę (`adb shell dumpsys thermalservice`). Zapisz wynik i werdykt.
5. **Gra:** nagraj ekran `adb shell screenrecord` (3 × 3 min): pierwsze uruchomienie, samouczek, pierwsze zlecenie. Zrób zrzuty (`adb exec-out screencap -p`) wszystkich ekranów. Zbierz logcat z błędami Godota. Spisz błędy jako listę: ekran, kroki, oczekiwane, faktyczne, zrzut.
6. Nagrania > 50 MB do Release `gemini-gem3`. Zrzuty i logi do `docs/handoff/device-tests/`.

## 4. Jak oddać
1. Małe commity po angielsku, prefiks `gemini/GEM3: …`.
2. Przed każdym pushem `git pull --rebase origin main`. Konflikty rozwiązuj do końca, **nigdy nie commituj znaczników `<<<<<<<`**. Nie rób force-push.
3. Push na `main`. Jeśli nie masz uprawnień, gałąź `gemini/GEM3` i pull request.
4. Pliki binarne > 50 MB (wideo, sekwencje klatek) **nie idą do gita**. Wrzuć je jako zasób do GitHub Release `gemini-gem3` (`gh release create` / `gh release upload`) albo zostaw na dysku i podaj ścieżkę w raporcie.
5. Raport `docs/handoff/device-tests/REPORT.md`: co zrobione, liczby, ścieżki plików, co się nie udało, czas renderów i sprzęt (GPU/CPU).

## 5. Kryteria odbioru
- JSON-y pomiarów w repo, tabela w raporcie, werdykt go/no-go według progów TECH.md.
- Wynik wydajności 10 min (p50/p95, temperatura).
- Lista błędów z zrzutami.
