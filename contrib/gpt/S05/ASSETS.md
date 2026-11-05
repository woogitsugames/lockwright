# S05 — źródła efektów dźwiękowych

Data: **2026-11-05**. Narzędzie: **własna synteza proceduralna Python 3 / NumPy / SciPy + pomiar pyloudnorm**. Nie użyto modelu TTS, gotowego dźwięku ani cudzych sampli. `generate.py` i WAV-y są oryginalnym opracowaniem przeznaczonym dla projektu Lockwright. Oprogramowanie do tworzenia: NumPy i SciPy (BSD-3-Clause), pyloudnorm (MIT); biblioteki nie są dołączone do gry.


## Pełny prompt / brief — plate_press

> Synthesize from scratch without samples: a subtle fingertip tap on a rigid enamel-coated plate mounted on wood, 80–180 ms. Dry low-mid wooden body (about 205 Hz), muted non-harmonic enamel resonances (about 805, 1340 and 2110 Hz), short bandwidth-limited contact noise. No reverb, no echo, no harsh click, no electronic tones, no recognisable melody. Six mildly detuned, individually seeded variants. WAV mono 48 kHz PCM16, immediate attack, quiet tail, low-volume UI aesthetic; nominal loudness around -24 LUFS on 400ms zero-padded frame, peak below 0 dBFS.


## Pełny prompt / brief — plate_release

> Synthesize from scratch without samples: a shorter, quieter return/rebound of an enamel-coated plate fixed to wood, 40–120 ms. Soft contact and shorter resonant decay, less energy and narrower spectral content than press. No reverb, no echo, no electronic UI beep. Six mildly detuned seeded variants, WAV mono 48k PCM16, start within 5ms, tail silence shorter than 50ms. Aim roughly -26.5 LUFS on a 400ms zero-padded frame, so release is audibly quieter than press.


## Pełny prompt / brief — plate_disabled

> Synthesize from scratch without samples: a muffled fingertip contact through a cloth onto an enamel plate that cannot move, 40–120ms. Dull 137Hz body, low-pass contact texture under 680Hz, no metallic ring, dry and very soft. Three seeded variants; WAV mono 48k PCM16, start within 5ms, trailing silence below 50ms, quieter than release, target about -28.5 LUFS on 400ms padded frame.


## Pełny prompt / brief — screen_whoosh_soft

> Synthesize from scratch without samples: a restrained short rustle of paper/leather as a menu screen switches, 150–250ms. Use only band-limited soft noise, a hand-shaped smooth one-stroke envelope and sparse soft irregular surface scratch grains; no cinematic swoosh, no thunder, no reverberation, no music. Three seeded variants, subtle spectral change, low-volume texture, WAV mono 48k PCM16, onset within 5ms, fading tail shorter than 50ms, about -28 LUFS measured on a 400ms padded frame.


## Sposób edycji / postprocessing

Sygnał powstaje od zera w deterministycznym skrypcie (`seed=5051905`, osobne seedy dla wariantów). Filtracja Butterwortha, łączone składowe harmoniczne i transjenty losowe, bramki wejścia/wyjścia, miękkie modelowanie amplitudy sygnału, normalizacja/ograniczenie wartości szczytowych, kwantyzacja do PCM16. Po zapisie wykonano pomiar zdekodowanego WAV-a i SHA-256. Bez bibliotek efektów i bez dodatkowych sampli.

## Wykaz 18 plików

| Plik | Narzędzie | Pełny brief | Edycja | SHA-256 |
|---|---|---|---|---|
| `sfx/plate_press_01.wav` | Python / NumPy / SciPy | plate_press (pełny prompt wyżej) + seed wariantu | synteza, filtracja, normalizacja, PCM16 | `31454067b43aa9462a13bc64ba7ef41bb2a80c7ba8a17954ebde0606bf149c49` |
| `sfx/plate_press_02.wav` | Python / NumPy / SciPy | plate_press (pełny prompt wyżej) + seed wariantu | synteza, filtracja, normalizacja, PCM16 | `3d52fc131745805f8cd07ae8fccc28970a6418746b4a1d7a6fd7f297c537a29a` |
| `sfx/plate_press_03.wav` | Python / NumPy / SciPy | plate_press (pełny prompt wyżej) + seed wariantu | synteza, filtracja, normalizacja, PCM16 | `81300efaae804155f831b30d450d52a923a23d779a006a2c51c223c82a875393` |
| `sfx/plate_press_04.wav` | Python / NumPy / SciPy | plate_press (pełny prompt wyżej) + seed wariantu | synteza, filtracja, normalizacja, PCM16 | `ad8167d732109a2179b21faaa125512a491d869d6fc8bc78afafd35cd0ceaeb8` |
| `sfx/plate_press_05.wav` | Python / NumPy / SciPy | plate_press (pełny prompt wyżej) + seed wariantu | synteza, filtracja, normalizacja, PCM16 | `ef947ba00eade9a1c13462e5fc70ee90311a2cc205bbea809af6c2dfd4c6b147` |
| `sfx/plate_press_06.wav` | Python / NumPy / SciPy | plate_press (pełny prompt wyżej) + seed wariantu | synteza, filtracja, normalizacja, PCM16 | `1805492609cecac1569d5d2665e10095fff8756f0b5cd177b0458e59a41ba888` |
| `sfx/plate_release_01.wav` | Python / NumPy / SciPy | plate_release (pełny prompt wyżej) + seed wariantu | synteza, filtracja, normalizacja, PCM16 | `b92097a3b15051b52720c7f8daac0be7b77fe26796bc351d995c4b6f498cc171` |
| `sfx/plate_release_02.wav` | Python / NumPy / SciPy | plate_release (pełny prompt wyżej) + seed wariantu | synteza, filtracja, normalizacja, PCM16 | `1f6552297bb067a7adde4e06c11b79c37af89f4a6735575311ee6c34151fcdac` |
| `sfx/plate_release_03.wav` | Python / NumPy / SciPy | plate_release (pełny prompt wyżej) + seed wariantu | synteza, filtracja, normalizacja, PCM16 | `698eee98cfd4d8e71da24124444fa3c20994bbb6c6e5d4f4580a6e072d8483c7` |
| `sfx/plate_release_04.wav` | Python / NumPy / SciPy | plate_release (pełny prompt wyżej) + seed wariantu | synteza, filtracja, normalizacja, PCM16 | `8237bf16c52511cc6b6c0f323cb548dd8f364da927db174dbf5e03a1cbcddc70` |
| `sfx/plate_release_05.wav` | Python / NumPy / SciPy | plate_release (pełny prompt wyżej) + seed wariantu | synteza, filtracja, normalizacja, PCM16 | `58ea538561348761e9549bbbfd55e5037e2f08dc01912efc58edf2090e2b4e4c` |
| `sfx/plate_release_06.wav` | Python / NumPy / SciPy | plate_release (pełny prompt wyżej) + seed wariantu | synteza, filtracja, normalizacja, PCM16 | `e3ace0c1482492ce3b7e40394755910dcd9db3d10c7ed994605c89d654551f31` |
| `sfx/plate_disabled_01.wav` | Python / NumPy / SciPy | plate_disabled (pełny prompt wyżej) + seed wariantu | synteza, filtracja, normalizacja, PCM16 | `222295b570940560c9a4a0d7e32a3ef7a2ae8b3553ffd4eb5f3be010a8a45661` |
| `sfx/plate_disabled_02.wav` | Python / NumPy / SciPy | plate_disabled (pełny prompt wyżej) + seed wariantu | synteza, filtracja, normalizacja, PCM16 | `7ad1c9d0edf2fca1d2dcd734ca4288c8ceb0d351237c152670e8e976e24e2323` |
| `sfx/plate_disabled_03.wav` | Python / NumPy / SciPy | plate_disabled (pełny prompt wyżej) + seed wariantu | synteza, filtracja, normalizacja, PCM16 | `108171b1abec136e092157af8c0905f7e7667c8f08ca4cf72e1e17047a2f8b19` |
| `sfx/screen_whoosh_soft_01.wav` | Python / NumPy / SciPy | screen_whoosh_soft (pełny prompt wyżej) + seed wariantu | synteza, filtracja, normalizacja, PCM16 | `88b662e75dd4a1c6104858e1d3f13a755bb10150057f1c1ad31ae7676cc2883c` |
| `sfx/screen_whoosh_soft_02.wav` | Python / NumPy / SciPy | screen_whoosh_soft (pełny prompt wyżej) + seed wariantu | synteza, filtracja, normalizacja, PCM16 | `e29dd5a664b65bdf2831b1841d4755a08458ba02117acbba84fa8e95d0279486` |
| `sfx/screen_whoosh_soft_03.wav` | Python / NumPy / SciPy | screen_whoosh_soft (pełny prompt wyżej) + seed wariantu | synteza, filtracja, normalizacja, PCM16 | `532433d35977937acef9ae28ae92b882dc3b200c9a1126ccc5138bab82d67eaa` |

**Licencje:** brak komponentów licencjonowanych osób trzecich w plikach WAV. Oryginalne efekty mogą być wykorzystane i modyfikowane w grze Lockwright przez zamawiającego. Wymienione biblioteki są narzędziami, nie dołączono ich kodu ani zasobów dźwiękowych.
