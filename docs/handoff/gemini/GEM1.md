# Zlecenie GEM1 — Rendery marketingowe i animacje do zwiastuna

**Dla:** Gemini w Google Antigravity, jedna sesja agenta na jedno zlecenie. Pracujesz na komputerze właściciela: masz terminal, pliki i git.
**Repo:** `https://github.com/woogitsugames/lockwright`, gałąź `main`. Sklonuj repo albo zrób `git pull`, jeśli już jest.
**Twoje katalogi (tylko tu zapisujesz):** `art/blender/marketing/`, `art/marketing/`
**Raport:** `art/marketing/REPORT.md` (po polsku).

## 1. O projekcie
**Lockwright** to mobilna gra premium (iOS, Android, Godot 4.7.2 + biblioteka C++ `lockcore`). Gracz jest **legalnym ślusarzem z pogotowia**: otwiera zamki ludziom zatrzaśniętym za drzwiami w starej kamienicy i zawsze sprawdza prawo do lokalu. Wygląd: **maksymalny fotorealizm** (proceduralne modele w Blenderze 4.2 LTS, Cycles) i interfejs bez pływających paneli.

Przeczytaj: `CLAUDE.md`, `docs/styles/realizm.md`, `docs/DESIGN.md` (kod stanów i zakazy), `docs/HUD.md`, `contrib/gpt/T06/README.md` (krytyka wyglądu, ważna), `docs/MARKETING.md` (zwłaszcza §1, §2 i §4: lista ujęć R01–R17), `art/blender/cutaway.py`, `art/blender/tray.py`, `art/blender/stairwell.py`, `art/blender/lw_common.py`.

## 2. Zasady
- Ciepły, legalny ton. Mechanizmy wymyślone. **Zero marek** zamków, samochodów i narzędzi. Zero instrukcji do realnych produktów. Zero estetyki złodzieja.
- Zakazane: neon, bloom na metalu, chrom (roughness ≥ 0,16), glassmorphism, gradienty fiolet-niebieski i teal-orange, emoji jako ikony, zielony ptaszek / czerwony X, pasek wytrzymałości.
- Każdy stan (binding, set, overset, false set, bliskie złamanie) musi być rozróżnialny w skali szarości.
- Zasoby: własne, CC0 albo generowane przez AI. Każdy wpisany do `docs/ASSETS.md` (sekcja „Gemini”) z narzędziem i promptem.
- **Nie zmieniaj plików poza swoimi katalogami.** Pozostałe katalogi należą do sesji A, B i C, które pracują równolegle i pushują na `main`. Wyjątek: dopisanie wpisów do `docs/ASSETS.md`.
- Kod, komentarze i nazwy plików po angielsku. Raport po polsku.

## 3. Zadanie
Na Twoim komputerze jest prawdopodobnie GPU, więc renderujesz w Cycles na GPU (OptiX, CUDA, HIP albo Metal). Zainstaluj **Blender 4.2 LTS**, jeśli go nie ma. Ustal dostępny GPU i zapisz go w raporcie.

1. W `art/blender/marketing/` napisz skrypty animacji do ujęć z `docs/MARKETING.md` §4 (R01–R17). Skrypty `art/blender/*.py` **importuj albo kopiuj**, ale ich nie zmieniaj. Jeśli potrzebujesz parametrów (stany pinów w czasie, napięcie, przyciemnienie), dodaj je we własnej kopii, np. `art/blender/marketing/cutaway_anim.py`. Animacje: bind → set (klik), fałszywe osadzenie szpulki, kontrrotacja, przepchnięcie, ugięcie wytrycha przy stresie, otwarcie, rozwinięcie zwijki, minutnik światła na klatce.
2. Renderuj w 2160×3840 przy 30 kl./s (pion) i 3840×2160 (poziom) tam, gdzie MARKETING.md tego chce. Denoise OptiX lub OIDN z albedo i normal, bez głębi ostrości w kadrach mechanizmu. Najpierw podgląd 540 px, potem final.
3. Złóż wersje zwiastuna 30 s i 15 s z ujęć według storyboardu (ffmpeg), bez muzyki. Jeśli w `contrib/gpt/S01/` jest muzyka, podłóż ją w osobnej wersji. Napisy PL i EN jako osobne pliki SRT oraz wersje z napisami wypalonymi.
4. Zrób 12 stopklatek 4K do sklepu i prasy (PNG) do `art/marketing/stills/`.
5. Wideo i sekwencje do GitHub Release (punkt 4 w „Jak oddać”). Do gita trafiają tylko skrypty, stopklatki ≤ 10 MB i podglądy.

## 4. Jak oddać
1. Małe commity po angielsku, prefiks `gemini/GEM1: …`.
2. Przed każdym pushem `git pull --rebase origin main`. Konflikty rozwiązuj do końca, **nigdy nie commituj znaczników `<<<<<<<`**. Nie rób force-push.
3. Push na `main`. Jeśli nie masz uprawnień, gałąź `gemini/GEM1` i pull request.
4. Pliki binarne > 50 MB (wideo, sekwencje klatek) **nie idą do gita**. Wrzuć je jako zasób do GitHub Release `gemini-gem1` (`gh release create` / `gh release upload`) albo zostaw na dysku i podaj ścieżkę w raporcie.
5. Raport `art/marketing/REPORT.md`: co zrobione, liczby, ścieżki plików, co się nie udało, czas renderów i sprzęt (GPU/CPU).

## 5. Kryteria odbioru
- Skrypty odtwarzają każde ujęcie jedną komendą (zapisz komendy w raporcie).
- Min. 10 ujęć z listy R01–R17 wyrenderowanych w finalu.
- Zwiastun 30 s i 15 s (PL i EN) w Release.
- Stany czytelne, metal satynowy, zero zakazanych klisz.
