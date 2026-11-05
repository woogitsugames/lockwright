# Zlecenie GEM4 — Warianty przekroju: 1, 3, 6 i 7 pinów oraz pełny napinacz

**Dla:** Gemini w Google Antigravity, jedna sesja agenta na jedno zlecenie. Pracujesz na komputerze właściciela: masz terminal, pliki i git.
**Repo:** `https://github.com/woogitsugames/lockwright`, gałąź `main`. Sklonuj repo albo zrób `git pull`, jeśli już jest.
**Twoje katalogi (tylko tu zapisujesz):** `art/blender/variants/`, `art/renders/variants/`
**Raport:** `art/renders/variants/REPORT.md` (po polsku).

## 1. O projekcie
**Lockwright** to mobilna gra premium (iOS, Android, Godot 4.7.2 + biblioteka C++ `lockcore`). Gracz jest **legalnym ślusarzem z pogotowia**: otwiera zamki ludziom zatrzaśniętym za drzwiami w starej kamienicy i zawsze sprawdza prawo do lokalu. Wygląd: **maksymalny fotorealizm** (proceduralne modele w Blenderze 4.2 LTS, Cycles) i interfejs bez pływających paneli.

Przeczytaj: `CLAUDE.md`, `docs/styles/realizm.md`, `docs/DESIGN.md` (kod stanów i zakazy), `docs/HUD.md`, `contrib/gpt/T06/README.md` (krytyka wyglądu, ważna), `art/blender/cutaway.py`, `art/blender/lw_common.py`, `docs/ONBOARDING.md` (wkładki ćwiczebne S1–S3), `docs/LEVELS.md`, `lockcore/BALANCE.md` (liczba pinów w tierach).

## 2. Zasady
- Ciepły, legalny ton. Mechanizmy wymyślone. **Zero marek** zamków, samochodów i narzędzi. Zero instrukcji do realnych produktów. Zero estetyki złodzieja.
- Zakazane: neon, bloom na metalu, chrom (roughness ≥ 0,16), glassmorphism, gradienty fiolet-niebieski i teal-orange, emoji jako ikony, zielony ptaszek / czerwony X, pasek wytrzymałości.
- Każdy stan (binding, set, overset, false set, bliskie złamanie) musi być rozróżnialny w skali szarości.
- Zasoby: własne, CC0 albo generowane przez AI. Każdy wpisany do `docs/ASSETS.md` (sekcja „Gemini”) z narzędziem i promptem.
- **Nie zmieniaj plików poza swoimi katalogami.** Pozostałe katalogi należą do sesji A, B i C, które pracują równolegle i pushują na `main`. Wyjątek: dopisanie wpisów do `docs/ASSETS.md`.
- Kod, komentarze i nazwy plików po angielsku. Raport po polsku.

## 3. Zadanie
Obecny przekrój (`art/blender/cutaway.py`) ma na sztywno 5 komór i ramię napinacza poza kadrem. Potrzebne są warianty. **Nie zmieniaj `cutaway.py`**, zrób kopię i rozbuduj ją w `art/blender/variants/cutaway_n.py`:
1. Parametr `--pins N` (1–7) z poprawną geometrią korpusu i rdzenia. Komory nieużywane w wkładce ćwiczebnej są **zaślepione** (S1: 1 czynny pin, S2: 3 czynne).
2. Parametr `--wrench-in-frame`: kadr, w którym widać całe ramię napinacza, z kątem napięcia jako parametrem (0–14°). To ważne, bo napięcie czytamy z kąta napinacza (D-12).
3. Stany per pin jak w `cutaway.py` (a–e) plus parametry `--states` (np. `set,bind,free,overset,spool`).
4. Popraw jakość według `contrib/gpt/T06`, punkty 3 i 4: roughness ≥ 0,16, anizotropia w kierunku obróbki, zmatowione fazy, ciemna szczelina linii podziału bez jasnego paska, mniej identyczne sprężyny (losowe drobne różnice zwojów).
5. Rendery finalne (GPU, 2160×2880, 256 spp, denoise z albedo i normal, bez DOF) dla: 1, 3, 5, 6 i 7 pinów, w wersji z napinaczem w kadrze i bez. Zapisz je w `art/renders/variants/` (+ gray). Do tego płyty planu B (bez ruchomych części) według wzoru `game/assets/photoreal/tools/render_plate.py`, do `art/renders/variants/plates/`.

## 4. Jak oddać
1. Małe commity po angielsku, prefiks `gemini/GEM4: …`.
2. Przed każdym pushem `git pull --rebase origin main`. Konflikty rozwiązuj do końca, **nigdy nie commituj znaczników `<<<<<<<`**. Nie rób force-push.
3. Push na `main`. Jeśli nie masz uprawnień, gałąź `gemini/GEM4` i pull request.
4. Pliki binarne > 50 MB (wideo, sekwencje klatek) **nie idą do gita**. Wrzuć je jako zasób do GitHub Release `gemini-gem4` (`gh release create` / `gh release upload`) albo zostaw na dysku i podaj ścieżkę w raporcie.
5. Raport `art/renders/variants/REPORT.md`: co zrobione, liczby, ścieżki plików, co się nie udało, czas renderów i sprzęt (GPU/CPU).

## 5. Kryteria odbioru
- Wszystkie warianty renderują się jedną komendą (spisane w raporcie).
- Rendery i płyty w repo (PNG ≤ 15 MB, większe jako JPG 95 + PNG w Release).
- Porównanie przed i po z `art/renders/section.png` w raporcie.
