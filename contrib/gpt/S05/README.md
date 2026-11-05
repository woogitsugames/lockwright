# S05 — dźwięki emaliowanych tabliczek menu

Dostawa: **2026-11-05**. **18 oryginalnych dźwięków**, utworzonych wyłącznie syntezą numeryczną. Nie korzystano z cudzych sampli ani bibliotek nagrań. Dźwięk krótkiego, matowego stuknięcia w tabliczkę na drewnie; delikatne metaliczne rezonanse przy aktywacji; nieaktywny przycisk bez metalicznego dzwonienia; zmiana ekranu jak ledwo słyszalny szelest skóry/papieru. Bez echa i pogłosu.

## Pliki

- `sfx/plate_press_01.wav` … `_06.wav` — lekkie naciśnięcie blachy.
- `sfx/plate_release_01.wav` … `_06.wav` — krótszy i cichszy powrót.
- `sfx/plate_disabled_01.wav` … `_03.wav` — matowy, stłumiony klik.
- `sfx/screen_whoosh_soft_01.wav` … `_03.wav` — bardzo cichy szelest.
- `generate.py` — generator ze stałym ziarnem RNG.
- `manifest.json` — **każdy WAV:** czas, LUFS, peak, RMS, start, końcowa cisza, SHA-256 i parametry formatu.
- `verify.py` — niezależna kontrola bajtów i parametrów z manifestu.
- `ASSETS.md` — szczegółowy opis źródeł i pełny brief syntezy.

## Zmierzone parametry WAV

Każdy plik: **48 kHz / mono / PCM signed 16-bit / WAV**. Wyniki pomiarów po zapisie do PCM:

| Rodzina | Liczba | Czas [ms] | LUFS, 400 ms z dopełnieniem | Peak [dBFS] |
|---|---:|---:|---:|---:|
| `plate_press` | 6 | 109–154 | -24.5 do -23.6 | -12.5 do -12.5 |
| `plate_release` | 6 | 66–106 | -27.7 do -26.5 | -15.0 do -15.0 |
| `plate_disabled` | 3 | 71–87 | -28.9 do -28.7 | -17.0 do -17.0 |
| `screen_whoosh_soft` | 3 | 176–212 | -28.0 do -27.7 | -18.2 do -18.0 |

Wszystkie próbki: wykrywalny początek **< 5 ms**, cisza na końcu **< 50 ms**, brak clippingu. Naciśnięcia są głośniejsze od zwolnień, a szelesty są wyraźnie cichsze od aktywacji. Warianty mają nieznaczne różnice wysokości i barwy, wynikające z oddzielnego seed i małej modulacji częstotliwości.

**O LUFS:** każde nagranie jest krótsze niż standardowe okno **400 ms** EBU R128, dlatego standardowej zintegrowanej LUFS dla takiej próbki nie da się wyznaczyć bez arbitralnego wydłużenia. W raporcie zastosowano **ważone K okno 400 ms, z dopełnieniem zerami do końca** (pyloudnorm). Wymagane „około −24 LUFS” osiągają aktywacje (`plate_press`); zwolnienie i wyciszone sygnały są celowo o ~2–5 LU cichsze. Nie należy porównywać tej liczby bezpośrednio z wynikami innego okna pomiarowego.

## Reprodukcja i test

```bash
python -m pip install numpy scipy pyloudnorm
python contrib/gpt/S05/generate.py
python contrib/gpt/S05/verify.py
```

Do odtwarzania w grze nie są potrzebne zależności Pythona. Polecam losować wariant z ograniczeniem bezpośredniego powtórzenia tej samej próbki. Referencje stylistyczne z istniejącego `game/assets/audio/ui/` (GitHub): `brass_snap_pause_01` ma ~148 ms, peak −14.0 dBFS; `paper_slide_1` ma ~243 ms, peak −19.2 dBFS. Zestaw nowy jest podobnie krótki i cichy, choć cel „−24 LUFS” jest tutaj mierzony inną metodą (400 ms padded).

**Nie zmieniono żadnego pliku** `game/assets/audio/ui/`; to materiały źródłowe do integracji przez właściciela. Brak odsłuchu na docelowym telefonie i testu haptyki; pomiary i zgodność plików wykonano automatycznie.
