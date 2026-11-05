# Zlecenie S05: dźwięki przycisków-tabliczek w menu

**Dla:** ChatGPT z dostępem do GitHuba (jedna sesja = jedno zlecenie). Repo `woogitsugames/lockwright`, gałąź `main`.
**Kontekst i zasady obowiązkowe:** jak w `docs/handoff/gpt/G01-enamel-apartment-number-plates.md` §1–§2: legalny ślusarz, fotorealizm, zero marek, lista zakazanych klisz, AI dozwolone (D-42) z wpisem w `ASSETS.md` (narzędzie, data, pełny prompt, edycje). Zapisuj **tylko** w swoim katalogu `contrib/gpt/S05/`. Raport `README.md` po polsku. Commit `contrib/gpt/S05: <opis>`; jeśli nie możesz pisać do `main`, oddaj ZIP właścicielowi.

## Po co
Przyciski menu staną się emaliowanymi tabliczkami (N-54, G17). Potrzebne są do nich krótkie, ciche dźwięki. Istniejące dźwięki UI są w `game/assets/audio/ui/` (np. `brass_snap_pause_*`, `paper_slide_*`): przejrzyj je, żeby zachować spójność głośności i charakteru.

## Zadanie
Oryginalne dźwięki, bez cudzych sampli i bez bibliotek z licencją wymagającą podpisu. Możesz je syntetyzować (np. Python numpy/scipy jak przy S03v2) albo opisać nagranie. Format: WAV PCM 16-bit, 48 kHz, mono, początek ≤ 5 ms, ogon ciszy ≤ 50 ms, około −24 LUFS, bez przesterowania.
- `plate_press_01..06.wav`: lekkie stuknięcie palca w emaliowaną blachę przykręconą do drewna, krótkie (80–180 ms), matowe, z delikatnym metalicznym dzwonieniem, bez echa;
- `plate_release_01..06.wav`: cichsze, krótsze odbicie blachy (40–120 ms);
- `plate_disabled_01..03.wav`: głuche, stłumione stuknięcie dla nieaktywnego przycisku (palec w blachę przez szmatkę);
- `screen_whoosh_soft_01..03.wav`: bardzo cichy szelest papieru lub skóry przy zmianie ekranu (150–250 ms).

Każdy wariant ma się nieznacznie różnić wysokością i barwą, żeby powtarzanie nie męczyło. Dołącz generator (jeśli syntetyczne), `manifest.json` (czas, LUFS, peak, SHA-256), `ASSETS.md` i `README.md`.

## Kryteria odbioru
- 18 WAV w `contrib/gpt/S05/sfx/`;
- parametry spełnione, z raportem pomiarów;
- brak cudzych sampli.
