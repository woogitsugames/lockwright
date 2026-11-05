# Zlecenie GEM2 — Fotorealistyczne ekrany zamka dla 4 rodzin (Godot, plan B)

**Dla:** Gemini w Google Antigravity, jedna sesja agenta na jedno zlecenie. Pracujesz na komputerze właściciela: masz terminal, pliki i git.
**Repo:** `https://github.com/woogitsugames/lockwright`, gałąź `main`. Sklonuj repo albo zrób `git pull`, jeśli już jest.
**Twoje katalogi (tylko tu zapisujesz):** `game/scenes/photoreal_families/`, `game/scripts/photoreal_families/`, `game/assets/photoreal_families/`, `art/blender/plates/`
**Raport:** `game/scenes/photoreal_families/REPORT.md` (po polsku).

## 1. O projekcie
**Lockwright** to mobilna gra premium (iOS, Android, Godot 4.7.2 + biblioteka C++ `lockcore`). Gracz jest **legalnym ślusarzem z pogotowia**: otwiera zamki ludziom zatrzaśniętym za drzwiami w starej kamienicy i zawsze sprawdza prawo do lokalu. Wygląd: **maksymalny fotorealizm** (proceduralne modele w Blenderze 4.2 LTS, Cycles) i interfejs bez pływających paneli.

Przeczytaj: `CLAUDE.md`, `docs/styles/realizm.md`, `docs/DESIGN.md` (kod stanów i zakazy), `docs/HUD.md`, `contrib/gpt/T06/README.md` (krytyka wyglądu, ważna), `docs/DECISIONS.md` (D-31, D-37: plan B), `game/scenes/photoreal/` i `game/scripts/photoreal/` (gotowy wzór dla wkładki bębenkowej), `spikes/lit-metal/README.md`, `art/blender/wafer.py`, `lever.py`, `warded.py`, `wooden_pin.py`, `docs/LOCKS.md`, `lockcore/README.md`.

## 2. Zasady
- Ciepły, legalny ton. Mechanizmy wymyślone. **Zero marek** zamków, samochodów i narzędzi. Zero instrukcji do realnych produktów. Zero estetyki złodzieja.
- Zakazane: neon, bloom na metalu, chrom (roughness ≥ 0,16), glassmorphism, gradienty fiolet-niebieski i teal-orange, emoji jako ikony, zielony ptaszek / czerwony X, pasek wytrzymałości.
- Każdy stan (binding, set, overset, false set, bliskie złamanie) musi być rozróżnialny w skali szarości.
- Zasoby: własne, CC0 albo generowane przez AI. Każdy wpisany do `docs/ASSETS.md` (sekcja „Gemini”) z narzędziem i promptem.
- **Nie zmieniaj plików poza swoimi katalogami.** Pozostałe katalogi należą do sesji A, B i C, które pracują równolegle i pushują na `main`. Wyjątek: dopisanie wpisów do `docs/ASSETS.md`.
- Kod, komentarze i nazwy plików po angielsku. Raport po polsku.

## 3. Zadanie
Ekran zamka bębenkowego działa już w planie B (`game/scenes/photoreal/`): nieruchome części to render z Cycles rzutowany przez kamerę, ruchome to matcap z Cyclesa. Zero świateł. Zrób to samo dla rodzin **wafer, lever (z lever_detector), warded i wooden_pin**:
1. W `art/blender/plates/` napisz skrypty (na bazie kopii `wafer.py` itd.), które z jednej stałej kamery renderują płytę bez ruchomych części, matcapy ruchomych materiałów i GLB z ruchomymi częściami jako osobnymi węzłami. Wzór: `game/assets/photoreal/tools/render_plate.py`. Renderuj na GPU.
2. W Godot 4.7.2 (zainstaluj, jeśli trzeba) zbuduj sceny `lock_photoreal_<family>.tscn`, które podłączają się do tego samego interfejsu co `lock_photoreal.tscn` (LockcoreSession lub FakeLockSession, `present(vm, input, delta)`, `on_event`). Pozy elementów biorą się ze stanu lockcore. Klasa wzorcowa: `LockPhotorealView`.
3. Zrzuty 824×1830 i 1830×824 (+ gray i dim) dla każdej rodziny w stanach: swobodny, wiąże, ustawiony, fałszywe, przepchnięty, detektor (lever_detector). Zapisz je w `game/scenes/photoreal_families/shots/`.
4. Testy GUT wzorem `game/tests/gut/test_photoreal.gd`, ale we własnym pliku `game/scenes/photoreal_families/test_photoreal_families.gd` (nie w katalogu testów sesji B). Opisz w raporcie, jak sesja B ma je podpiąć.
5. Popraw przy okazji uwagi z `contrib/gpt/T06`: metal mniej lustrzany, płaszczyzny cięcia z kierunkiem obróbki.

## 4. Jak oddać
1. Małe commity po angielsku, prefiks `gemini/GEM2: …`.
2. Przed każdym pushem `git pull --rebase origin main`. Konflikty rozwiązuj do końca, **nigdy nie commituj znaczników `<<<<<<<`**. Nie rób force-push.
3. Push na `main`. Jeśli nie masz uprawnień, gałąź `gemini/GEM2` i pull request.
4. Pliki binarne > 50 MB (wideo, sekwencje klatek) **nie idą do gita**. Wrzuć je jako zasób do GitHub Release `gemini-gem2` (`gh release create` / `gh release upload`) albo zostaw na dysku i podaj ścieżkę w raporcie.
5. Raport `game/scenes/photoreal_families/REPORT.md`: co zrobione, liczby, ścieżki plików, co się nie udało, czas renderów i sprzęt (GPU/CPU).

## 5. Kryteria odbioru
- 4 rodziny grywalne w Godot w planie B, zrzuty w 6 stanach, wszystkie czytelne w szarości.
- Czas klatki zmierzony na Twoim komputerze i, jeśli możesz, na telefonie (adb, `--lw-bench 10`).
- Raport z instrukcją podpięcia dla sesji B.
