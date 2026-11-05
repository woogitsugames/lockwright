> **Uwaga o zawartości repozytorium:** W repo zapisano źródła, wszystkie OGG, MIDI i raport QA. Długie oraz krótkie WAV PCM24 są w pełnej paczce dostarczonej z wykonaniem S01 i można je odtworzyć lokalnie komendą `python render_music.py`; nie przesłano WAV przez interfejs GitHub z powodu ograniczeń transferu plików binarnych. W poniższej liście wymieniono również pliki generowane lokalnie.

# S01 — oryginalna muzyka: temat główny, warsztat i zamek

**Projekt:** Lockwright: Pogotowie Zamkowe  
**Data przygotowania:** 2026-11-05  
**Autor opracowania / generowanie:** oryginalna kompozycja algorytmiczna, opracowana w ChatGPT i zsyntetyzowana skryptem Python `render_music.py`.  
**Status:** gotowe pliki audio i MIDI; niezależny raport QA w `qa/measurements.json`.

## Rezultat i nastrój

Ciepła, nieepicka kameralistyka w tempie 80 BPM: syntetyczne wyciszone pianino (matowy atak), kontrabas pizzicato, spokojne szczotki i miękki klarnet. Harmonika z łagodnymi nonami i subtelnym zapożyczonym akordem molowym. Skojarzenie: **rzetelny fachowiec pomagający sąsiadom w starej kamienicy**, nie skradanie się i nie włamanie.

| Materiał | Czas | Opis PL / EN | MIDI | OGG |
|---|---:|---|---|---|
| `main_theme` | 1:12 | Motyw główny / Main theme — oryginalny, ośmiotaktowy motyw, 3 frazy; fortepian, kontrabas, dyskretne szczotki, epizody klarnetu | `score/main_theme.mid` | `audio/main_theme.ogg` |
| `menu_workshop` | 2:24 | Warsztat / Workshop — łagodne zagrywki fortepianu, zmienne akordy i bardzo miękki puls; zaprojektowana pętla 48 taktów | `score/menu_workshop.mid` | `audio/menu_workshop.ogg` |
| `lock_harmony` | 2:00 | W zamku / Inside lock — osiem bardzo powolnych, przenikających się akordów; bez perkusji, rytmu, melodii w wysokim rejestrze | `score/lock_harmony.mid` | `audio/lock_harmony.ogg` |
| `jingle_door_open` | 0:03.20 | Otwarte drzwi / Door opened — dyskretna ulga i jasne domknięcie | `score/jingle_door_open.mid` | `audio/jingle_door_open.ogg` |
| `jingle_dignified_refusal` | 0:03.10 | Odmowa / Respectful refusal — krótka, niekarząca kadencja | `score/jingle_dignified_refusal.mid` | `audio/jingle_dignified_refusal.ogg` |
| `jingle_new_chapter` | 0:03.65 | Nowy rozdział / New chapter — delikatne wejście w wyższy rejestr | `score/jingle_new_chapter.mid` | `audio/jingle_new_chapter.ogg` |
| `jingle_new_tool` | 0:02.65 | Nowe narzędzie / New tool — dwa lekkie, ciekawskie gesty fortepianowe | `score/jingle_new_tool.mid` | `audio/jingle_new_tool.ogg` |
| `jingle_showcase_exhibit` | 0:03.45 | Eksponat w gablocie / Showcase item — powściągliwy akord odkrycia | `score/jingle_showcase_exhibit.mid` | `audio/jingle_showcase_exhibit.ogg` |
| `jingle_end_of_day` | 0:03.75 | Koniec dnia / End of day — spokojna, opadająca fraza | `score/jingle_end_of_day.mid` | `audio/jingle_end_of_day.ogg` |

Każdy utwór ma **OGG Vorbis**, **WAV PCM 48 kHz / 24-bit / stereo** oraz **MIDI**. Ze względu na limit **20 MB na pojedynczy plik**, długie WAV-y są podzielone *wyłącznie w miejscu granicy próbki* na poniższe części (bez przycięć, fade'ów ani przerw między częściami):

- `main_theme_part01.wav` (60 s) i `main_theme_part02.wav` (12 s);
- `menu_workshop_part01.wav` (60 s), `menu_workshop_part02.wav` (60 s), `menu_workshop_part03.wav` (24 s);
- `lock_harmony_part01.wav` (60 s) i `lock_harmony_part02.wav` (60 s).

Ścieżki krótkie mają pojedyncze `audio/jingle_*.wav`. Wszystkie pliki są w `audio/`, a żaden WAV nie przekracza 20 MB. Pełna pętla OGG jest jednym plikiem.

**Odtwarzanie i scalanie WAV:** do Godot użyj pełnych `*.ogg`, a do pracy masteringowej scal bezstratnie części PCM: `python assemble_wav.py menu_workshop /tmp/menu_workshop.wav` (przykład; wynikowy plik >20 MB należy trzymać poza repozytorium).

## Synteza i odtwarzalność

Nie użyto gotowych próbek, soundfontów, modeli generujących audio, melodii istniejących utworów ani zewnętrznych plików MIDI. `render_music.py` tworzy samodzielnie:

1. oryginalne zdarzenia nutowe, harmonie i partie instrumentów (stałe tempo 80 BPM; stałe ziarno losowości);
2. barwy za pomocą funkcji sinusoidalnych, widm harmonicznych, wygasania drgań strun, modulacji fazy i filtrowanego szumu szczotek;
3. stereo i dyskretne opóźnienia cykliczne (bez pobranych impulsów IR);
4. normalizację według EBU R128: **−16 LUFS** (trzy długie materiały) i **−14 LUFS** (sześć jingli);
5. pliki WAV 24-bit/48 kHz/stereo, OGG Vorbis, partytury MIDI, pomiary oraz spektrogram wersji do zamka.

Zależności: Python 3.11+, `numpy`, `scipy`, `soundfile`, `pyloudnorm`, `mido`, `matplotlib` i `ffmpeg` z enkoderem `libvorbis`.

```bash
python -m pip install numpy scipy soundfile pyloudnorm mido matplotlib
python render_music.py
python verify_assets.py
```

Pliki generowane ponownie w tym samym środowisku są deterministyczne. Numery i nazwy programów instrumentów w MIDI to przybliżenie barw — **dokładny dźwięk** zapewnia autorski syntezator w `render_music.py`, nie ogólny odtwarzacz MIDI.

## Pętle i miksowanie w grze

- Pętla warsztatu ma dokładnie **144 s** i kończy się przejściem dominanty do początku. Ogon instrumentu, jeśli zachodzi na granicę, jest zawijany próbkowo na początek. Ścieżka zamka ma dokładnie **120 s**, a sinusoidy zestrojono z całkowitą liczbą cykli na ten okres i użyto okresowego przenikania akordów.
- Test odcinka przejścia obejmuje wartość próbki oraz ciągłość lokalnego nachylenia fali (`seam_slope_mismatch_vs_diff_rms` w raporcie). Nie należy używać samej różnicy pierwszej i ostatniej próbki jako miary „kliku” — próbki fali sinusoidalnej na ogół są różne także przy bezszwowym przejściu.
- Sygnał **„w zamku”** nie zawiera szczotek, wyrazistej melodii, wyższych harmonicznych ani ataków. Filtr dolnoprzepustowy zapewnia bardzo małą energię **2–6 kHz**. W `qa/lock_harmony_spectrogram.png` widać puste pasmo ponad 2 kHz. Pomiar Welch: **około −138 dB** energii 2–6 kHz względem 60–2000 Hz.
- Ze względu na semantykę rozgrywki i pierwszeństwo klików zamka (DESIGN, FEEL), w trybie pracy z mechanizmem **muzykę odtwarzać na busie Music co najmniej 12–16 dB ciszej** niż poziom pliku. Zaproponowane −16 LUFS dotyczy *mastera ścieżki*, nie końcowej głośności w scenie. Przy zdarzeniach `set`, `false_set`, `stress`, `break` i `open` należy automatycznie ściszać lub wyłączyć muzykę, ale nie ograniczać SFX.
- OGG dekoduje się do tej samej liczby ramek co WAV; przy integracji trzeba wymusić **loop start = 0, loop end = koniec** i sprawdzić zachowanie importera Godot na iOS/Android.
- Jingle są warstwą **po rozstrzygnięciu zdarzenia**, nie zamiennikiem mechanicznego `open`, odgłosów zestawiania pinów ani wzorców haptycznych. Odmowa jest spokojna, nie oskarżycielska.

## Kontrola jakości

`python verify_assets.py` wykonał testy automatyczne **PASS**: 9 plików MIDI, 9 OGG, 13 WAV, poprawny format 48k/24bit/stereo, granice 20 MB, docelowy LUFS z tolerancją 0,1, kontrola ciągłości pętli oraz osłabienia energii 2–6 kHz. Weryfikacja dotyczy plików PCM faktycznie zapisanych, nie tylko wewnętrznego bufora syntezatora. `qa/verification.log` zawiera wyniki, `qa/measurements.json` pomiary, `qa/lock_harmony_spectrogram.png` wykres.

**Ograniczenia:** nie wykonano odsłuchu kontrolnego na telefonach i w kontekście rzeczywistych efektów zamków, testu miksu na wbudowanych głośnikach ani pomiarów true peak / limiterów urządzenia. Materiał wymaga oceny artystycznej w kontekście gry. Brak odtwarzaczy MIDI w Godot oznacza, że MIDI służy wyłącznie dokumentacji i ewentualnym dalszym aranżacjom.

## Uwagi do innych zespołów (bez zmian poza S01)

- `CLAUDE.md` nazywa tytuł EN „Emergency Locksmith”, a opis zlecenia S01 „Locksmith on Call”. Należy ujednolicić nazewnictwo przed wydaniem; nie zmieniałem plików innych zespołów.
- Warstwa audio gry powinna mieć osobny Music bus i ducking priorytetu SFX. Nie zmieniałem kodu Godot, `docs/ASSETS.md` ani globalnych ustawień miksu.
- Ze względu na rozmiar PCM i limit repozytorium, dostarczone fragmenty WAV należy połączyć lokalnie dopiero przy potrzebie edycji. Dla runtime zalecam pojedyncze OGG.

## Licencje i pochodzenie

Każdy plik zasobu, pełne polecenia twórcze oraz warunki licencji narzędzi: `ASSETS.md`. Brak cudzych sampli i licencji do zakupienia.
