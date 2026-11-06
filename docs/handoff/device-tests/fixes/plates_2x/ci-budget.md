# Budżety wydajności — CI

| Miara | Wartość | Próg ostrz. / błąd | Stan |
|---|---|---|---|
| `pck_android_mb` | 57.5 | 45 / 58 | ostrzeżenie |
| `startup_headless_s` | 0.44 | 1.0 / 2.0 | OK |
| `startup_rss_mb` | 119.0 | 200 / 300 | OK |
| `lock_scene_headless_s` | 0.82 | 1.2 / 2.5 | OK |

## Co zajmuje paczkę (przybliżenie: zasoby po imporcie, wg katalogu źródłowego)

| Katalog w `game/` | MB |
|---|---|
| `assets/audio/lines` | 22.8 |
| `assets/ui/gpt` | 15.6 |
| `assets/photoreal_families/warded` | 11.6 |
| `assets/photoreal_families/lever` | 10.6 |
| `assets/photoreal_families/wafer` | 7.6 |
| `assets/photoreal_families/wooden_pin` | 7.0 |
| `assets/audio/voices` | 6.3 |
| `assets/ui` | 5.3 |
| `assets/photoreal/tex` | 3.5 |
| `assets/photoreal` | 2.6 |
| `assets/audio/music` | 2.4 |
| `assets/audio/sfx` | 2.1 |
| `assets/photoreal_families/lever_detector` | 2.0 |
| `assets/audio/ambience` | 1.6 |
| `assets/audio/ui` | 1.2 |

Progi i uzasadnienie: `docs/handoff/POMIARY.md` §8, `qa/budget/budgets.json`.
