# Raport V01 (Mistral Vibe): lint i18n + lint zasobów + CI

Zlecenie: `docs/handoff/mistral/V01-i18n-assets-lint.md`. Pliki zmienione wyłącznie z zakresu zlecenia:
`tools/i18n_lint.py`, `tools/assets_lint.py`, `tools/tests/`, `.github/workflows/lint.yml`, ten raport.

## Co zrobiono

- `tools/i18n_lint.py` — sprawdza `game/i18n/strings.csv` i `game/i18n/content.csv`:
  błędy (duplikaty kluczy, puste wartości `en`/`pl`/`de`, niezgodne placeholdery `{nazwa}`,
  brak klucza używanego w kodzie, przekroczone limity długości) oraz ostrzeżenia
  (klucze dynamiczne typu `cast.%s.name`, proste cudzysłowy w PL, wartość PL/DE identyczna
  jak EN, słowo „włam”). Kod wyjścia 1 tylko przy błędach.
- `tools/assets_lint.py` — każdy plik binarny w `game/assets/**` (bez `.import`) musi być
  wpisany w `docs/ASSETS.md` (dopasowanie po ścieżce, wzorcu glob, nazwie pliku/sufiksie
  ścieżki lub katalogu-rodzicu; wpisy z `{a,b}`, listami rozdzielonymi przecinkiem, ` i `,
  ` + ` i alternacją rozszerzeń `png|webp`); każdy font w repo musi mieć OFL
  (`OFL*.txt` obok fontu albo wiersz z „OFL” w ASSETS.md obejmujący ten font);
  limit 8 MB na plik + lista 20 największych.
- `tools/tests/` — 15 testów pytest z małymi fixture'ami w `tools/tests/data/`.
- `.github/workflows/lint.yml` — push/PR, Python 3.12, testy + oba linty
  (`continue-on-error: true` dla lintów), `concurrency` z `cancel-in-progress: true`,
  `timeout-minutes: 10`.

## Jak uruchomić lokalnie

```bash
python tools/i18n_lint.py       # exit 1 tylko przy błędach
python tools/assets_lint.py     # exit 1 tylko przy błędach
python -m pytest tools/tests -q # testy skryptów (wymaga: pip install pytest)
```

## Znalezione błędy i ostrzeżenia w obecnym repo

### i18n — błędy (3)

Przekroczenia limitów długości w `game/i18n/strings.csv` (limit `tutorial.*`/`lock.*` = 56 znaków):

- `strings.csv:188` `tutorial.frame_lift_auto` — `en` 70, `pl` 66, `de` 74 znaki

Pozostałe kategorie (CSV, duplikaty, puste wartości, placeholdery, brakujące klucze z kodu): bez błędów — 824 klucze OK.

### i18n — ostrzeżenia (3)

Klucze dynamiczne w kodzie (nie jako błąd, do ręcznej weryfikacji):

- `game/scripts/ui/job_arrival.gd:142` (i :144) `cast.%s.name`
- `game/scripts/ui/job_arrival.gd:147` `%s.line.%d`
- `game/scripts/ui/job_verify.gd:54` `verify.card.%s`

Ostrzeżenia stylu (cudzysłowy, nieprzetłumaczone wartości, „włam”): brak trafień.

### Zasoby bez wpisu w `docs/ASSETS.md` (16)

- `game/assets/fonts/BonaNova-Regular.ttf`
- `game/assets/fonts/Caveat-wght.ttf`
- `game/assets/ui/plates/button_bottle_green_normal.png`
- `game/assets/ui/plates/button_bottle_green_pressed.png`
- `game/assets/ui/plates/button_burgundy_normal.png`
- `game/assets/ui/plates/button_burgundy_pressed.png`
- `game/assets/ui/plates/button_ivory_normal.png`
- `game/assets/ui/plates/button_ivory_pressed.png`
- `game/assets/ui/plates/button_navy_normal.png`
- `game/assets/ui/plates/button_navy_pressed.png`
- `game/assets/ui/plates/initial_bottle_green.png`
- `game/assets/ui/plates/initial_burgundy.png`
- `game/assets/ui/plates/initial_ivory.png`
- `game/assets/ui/plates/initial_navy.png`
- `game/assets/ui/plates/primary_navy_normal.png`
- `game/assets/ui/plates/primary_navy_pressed.png`

(W trakcie prac innych agentów — pliki `game/assets/ui/plates/*` pojawiły się po pierwszym uruchomiu lints.)

### Fonty bez OFL

Brak — wszystkie fonty w repo mają `OFL*.txt` obok lub wpis OFL w ASSETS.md.

### Pliki ponad 8 MB

Brak. 20 największych plików w `game/assets` (maks. 4.08 MB — `game/assets/photoreal_families/wafer/wafer_baked.glb`):

```
4.08 MB  game/assets/photoreal_families/wafer/wafer_baked.glb
3.42 MB  game/assets/photoreal/cutaway_baked.glb
2.83 MB  game/assets/photoreal/plate/plate_1236x1650.png
2.68 MB  game/assets/photoreal_families/warded/plate/plate_1236x1650.png
2.17 MB  game/assets/photoreal_families/lever/plate/plate_1236x1650.png
2.16 MB  game/assets/photoreal_families/wafer/plate/plate_1236x1650.png
2.01 MB  game/assets/photoreal_families/wooden_pin/plate/plate_1236x1650.png
1.83 MB  game/assets/audio/ambience/workshop.wav
1.83 MB  game/assets/audio/ambience/stairwell.wav
1.83 MB  game/assets/audio/ambience/rain_window.wav
1.83 MB  game/assets/audio/ambience/night_timer.wav
1.69 MB  game/assets/photoreal_families/lever/lever_baked.glb
1.31 MB  game/assets/photoreal/tray/tray_full.png
1.30 MB  game/assets/photoreal/tray/tray_empty.png
1.28 MB  game/assets/photoreal_families/lever/tex/stump_orm.png
1.20 MB  game/assets/photoreal_families/wafer/tex/spring2_orm.png
1.20 MB  game/assets/photoreal/tex/spring_orm.png
1.19 MB  game/assets/photoreal_families/warded/tex/tumb_iron_normal.png
1.18 MB  game/assets/photoreal_families/warded/tex/drillpin_orm.png
1.17 MB  game/assets/photoreal_families/warded/tex/probe_orm.png
```

## Weryfikacja

- `python tools/i18n_lint.py` → exit 1, 3 błędy / 3 ostrzeżenia (lista powyżej)
- `python tools/assets_lint.py` → exit 1, 16 zasobów bez wpisu, 0 fontów bez OFL, 0 plików > 8 MB
- `python -m pytest tools/tests -q` → 15 passed
- `.github/workflows/lint.yml` → poprawny YAML (sprawdzone `yaml.safe_load`)
- `git status` po zmianach — tylko pliki z zakresu zlecenia
