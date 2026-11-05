> **Stan repo:** Pliki WAV wymienione w rejestrze są częścią kompletnej paczki S01, lecz w GitHubie wymagają lokalnej regeneracji `python render_music.py`. Pozostałe wymienione zasoby znajdują się w repo.

# S01 — rejestr pochodzenia zasobów i warunków użycia

**Data wytworzenia wszystkich pozycji:** 2026-11-05. **Narzędzie:** `render_music.py` (autorska deterministyczna synteza Python/numpy/scipy, soundfile, pyloudnorm, mido, matplotlib, ffmpeg/libvorbis) opracowane z pomocą modelu ChatGPT GPT-6. **Nie użyto modeli audio AI, sampli, SoundFontów ani materiałów kompozycyjnych innych autorów.**

## Warunki prawne narzędzi — obowiązują dla każdej pozycji poniżej

**L1 — ChatGPT / treści wygenerowane:** wynik modelu stanowi Output w rozumieniu warunków usługi OpenAI. Między użytkownikiem a OpenAI, w zakresie dozwolonym prawem, użytkownik jest właścicielem Output, a OpenAI przenosi ewentualne swoje prawa do Output. Użytkownik odpowiada za używanie i ocenę wyniku zgodnie z prawem i zasadami usługi; wynik może nie być unikalny i inni użytkownicy mogą otrzymać podobną treść. Nie gwarantuje się, że jest wolny od wad prawnych lub dopasowany do zastosowania. Pełny dokument obowiązujących warunków usługi: https://openai.com/policies/terms-of-use/ oraz (dla organizacji/Team/Business, jeśli dotyczy) https://openai.com/policies/business-terms/. Niniejszy rejestr streszcza istotne klauzule, nie zastępuje wersji prawnie wiążącej.

**L2 — autorski syntezator i skomponowane nuty:** wszystkie zjawiska akustyczne stworzono z funkcji matematycznych, a nuty wpisano w skrypcie; **nie ma licencji stock/audio/sampli do wykupienia**. Pliki są przeznaczone do użycia w komercyjnej grze Lockwright, dalszej edycji i dystrybucji przez właściciela projektu; bez obowiązku oznaczania źródła utworu. Zastosowanie podlega L1.

**L3 — narzędzia programowe, bez pożyczonych zasobów:** Python — PSF License (https://docs.python.org/3/license.html); NumPy — BSD-3-Clause (https://numpy.org/doc/stable/license.html); SciPy — BSD-3-Clause z licencjami zależności opisanymi na https://scipy.org/scipylib/license.html; soundfile — BSD-3-Clause (https://github.com/bastibe/python-soundfile/blob/master/LICENSE); pyloudnorm — MIT (https://github.com/csteinmetz1/pyloudnorm/blob/master/LICENSE); mido — MIT (https://github.com/mido/mido/blob/main/LICENSE); Matplotlib — Matplotlib License (https://matplotlib.org/stable/project/license.html); FFmpeg — LGPL 2.1+ albo GPL zależnie od opcji kompilacji i kodeków (https://ffmpeg.org/legal.html); libvorbis — BSD-style (https://xiph.org/vorbis/). Te licencje dotyczą **kodów narzędzi i ich dystrybucji**, nie narzucają opłat za użycie oryginalnego wygenerowanego dźwięku; jeśli programy są dalej redystrybuowane, należy spełnić ich wymogi dotyczące licencji, zachowania informacji copyright, a przy LGPL/GPL odpowiednie warunki kopyleft. W paczce nie są redystrybuowane binaria FFmpeg ani biblioteki.

**Ograniczenie dowodowe:** licencje oprogramowania wskazano przez pełne teksty źródłowe pod URL; projekt nie zawiera kopii bibliotek, więc ich pełne teksty prawne pozostają w podanych dokumentach. Wykaz jest informacją o pochodzeniu, nie opinią prawną.

## Rejestr każdej kompozycji i każdego pliku

Wpisy obejmują **pełny prompt kompozycyjny**, wszystkie formaty danego motywu, licencje **L1+L2+L3** i historię edycji: napisanie nut, render matematyczny, dodanie przestrzeni i pomiar/mastering LUFS; brak ręcznych zmian w edytorze DAW. MIDI zachowuje partyturę zdarzeń, zaś WAV i OGG są masterami tej samej syntezy.

### main_theme

**Każdy plik (osobny wpis w tym zestawie):** `audio/main_theme.ogg`, `audio/main_theme_part01.wav`, `audio/main_theme_part02.wav`, `score/main_theme.mid`.

**Narzędzie / data:** `render_music.py` + `ffmpeg/libvorbis` + `mido`, 2026-11-05. **Pełny prompt / polecenie twórcze:** Skomponuj 72-sekundowy, ciepły kameralny motyw główny dla legalnego pogotowia ślusarskiego w starej kamienicy. Autorskie pianino wyciszone filcem, pizzicato kontrabasu, ledwie słyszalne szczotki, dyskretny klarnet; 80 BPM, 4/4, harmonia z nonami i miękkim humorem, bez epickich i przestępczych skojarzeń. Trzy frazy oparte o oryginalny motyw ośmiotaktowy. Synth w Pythonie, bez sampli i inspiracji cudzą muzyką. 48 kHz 24-bit stereo WAV + OGG; −16 LUFS; MIDI.

**Licencja i warunki:** L1 + L2 + L3 powyżej. **Edycja po wygenerowaniu:** tak — automatyczne rozmieszczenie nut, barwy DSP, tłumienie harmonicznych, panorama, miks, normalizacja LUFS; WAV/OGG/MIDI nie podlegały późniejszej ręcznej edycji.

### menu_workshop

**Każdy plik (osobny wpis w tym zestawie):** `audio/menu_workshop.ogg`, `audio/menu_workshop_part01.wav`, `audio/menu_workshop_part02.wav`, `audio/menu_workshop_part03.wav`, `score/menu_workshop.mid`.

**Narzędzie / data:** `render_music.py` + `ffmpeg/libvorbis` + `mido`, 2026-11-05. **Pełny prompt / polecenie twórcze:** Skomponuj autorską, 144-sekundową bezszwową pętlę do warsztatu ślusarza. Łagodne pianino i bas akustyczny pizzicato, bardzo ciche szczotki, okazjonalny drewniany klarnet. Spokojny fachowiec w starym mieście, 80 BPM, 48 taktów, stonowany humor i ciepłe harmonie; ostatnia dominanta prowadzi bezszwowo do pierwszej toniki. Brak epickości i noir. Własny syntezator Python, 48 kHz PCM24 stereo + OGG, −16 LUFS, MIDI.

**Licencja i warunki:** L1 + L2 + L3 powyżej. **Edycja po wygenerowaniu:** tak — automatyczne rozmieszczenie nut, barwy DSP, tłumienie harmonicznych, panorama, miks, normalizacja LUFS; WAV/OGG/MIDI nie podlegały późniejszej ręcznej edycji.

### lock_harmony

**Każdy plik (osobny wpis w tym zestawie):** `audio/lock_harmony.ogg`, `audio/lock_harmony_part01.wav`, `audio/lock_harmony_part02.wav`, `score/lock_harmony.mid`.

**Narzędzie / data:** `render_music.py` + `ffmpeg/libvorbis` + `mido`, 2026-11-05. **Pełny prompt / polecenie twórcze:** Skomponuj wyłącznie harmoniczne tło bez pulsu i rytmu dla manipulowania fikcyjnym zamkiem: 120 sekund zapętlonej, bardzo spokojnej, pastelowej harmonii, 8 akordów po 15 sekund z miękkim, okresowym przejściem. Bez instrumentów perkusyjnych, bez ataków i z wolnym ruchem. Zachowaj całkowicie wolny zakres 2–6 kHz dla mechanicznych klików oraz wyrzuć wysokie harmoniczne filtrem dolnoprzepustowym. 48 kHz PCM24 stereo + OGG, −16 LUFS jako master; w grze znacznie ciszej, MIDI, spektrogram.

**Licencja i warunki:** L1 + L2 + L3 powyżej. **Edycja po wygenerowaniu:** tak — automatyczne rozmieszczenie nut, barwy DSP, tłumienie harmonicznych, panorama, miks, normalizacja LUFS; WAV/OGG/MIDI nie podlegały późniejszej ręcznej edycji.

### jingle_door_open

**Każdy plik (osobny wpis w tym zestawie):** `audio/jingle_door_open.ogg`, `audio/jingle_door_open.wav`, `score/jingle_door_open.mid`.

**Narzędzie / data:** `render_music.py` + `ffmpeg/libvorbis` + `mido`, 2026-11-05. **Pełny prompt / polecenie twórcze:** Skomponuj autorski 3,20-sekundowy łagodny jingle pozytywnego otwarcia drzwi przez legalnego ślusarza: trzy wznoszące się nuty pianina, dyskretna końcowa harmonia i ciepły, krótki klarnet; ulga, bez triumfalizmu. 48 kHz PCM24 stereo + OGG, −14 LUFS, MIDI, własna synteza Python bez próbek.

**Licencja i warunki:** L1 + L2 + L3 powyżej. **Edycja po wygenerowaniu:** tak — automatyczne rozmieszczenie nut, barwy DSP, tłumienie harmonicznych, panorama, miks, normalizacja LUFS; WAV/OGG/MIDI nie podlegały późniejszej ręcznej edycji.

### jingle_dignified_refusal

**Każdy plik (osobny wpis w tym zestawie):** `audio/jingle_dignified_refusal.ogg`, `audio/jingle_dignified_refusal.wav`, `score/jingle_dignified_refusal.mid`.

**Narzędzie / data:** `render_music.py` + `ffmpeg/libvorbis` + `mido`, 2026-11-05. **Pełny prompt / polecenie twórcze:** Skomponuj autorski 3,10-sekundowy niezwykle cichy, godny jingle poprawnej odmowy usługi ślusarskiej po weryfikacji prawa do lokalu: delikatna opadająca fraza pianina i spokojne basowe domknięcie; bez efektu porażki czy karania gracza. 48 kHz PCM24 stereo + OGG, −14 LUFS, MIDI, własny syntezator Python bez próbek.

**Licencja i warunki:** L1 + L2 + L3 powyżej. **Edycja po wygenerowaniu:** tak — automatyczne rozmieszczenie nut, barwy DSP, tłumienie harmonicznych, panorama, miks, normalizacja LUFS; WAV/OGG/MIDI nie podlegały późniejszej ręcznej edycji.

### jingle_new_chapter

**Każdy plik (osobny wpis w tym zestawie):** `audio/jingle_new_chapter.ogg`, `audio/jingle_new_chapter.wav`, `score/jingle_new_chapter.mid`.

**Narzędzie / data:** `render_music.py` + `ffmpeg/libvorbis` + `mido`, 2026-11-05. **Pełny prompt / polecenie twórcze:** Skomponuj autorski 3,65-sekundowy jingle nowego rozdziału: cztery łagodne stopnie pianina kierujące w górę, podtrzymany ciepłym klarnetem akord, nadzieja bez fanfar. 48 kHz PCM24 stereo + OGG, −14 LUFS, MIDI, własny syntezator Python bez sampli.

**Licencja i warunki:** L1 + L2 + L3 powyżej. **Edycja po wygenerowaniu:** tak — automatyczne rozmieszczenie nut, barwy DSP, tłumienie harmonicznych, panorama, miks, normalizacja LUFS; WAV/OGG/MIDI nie podlegały późniejszej ręcznej edycji.

### jingle_new_tool

**Każdy plik (osobny wpis w tym zestawie):** `audio/jingle_new_tool.ogg`, `audio/jingle_new_tool.wav`, `score/jingle_new_tool.mid`.

**Narzędzie / data:** `render_music.py` + `ffmpeg/libvorbis` + `mido`, 2026-11-05. **Pełny prompt / polecenie twórcze:** Skomponuj autorski 2,65-sekundowy jingle otrzymania nowego, fikcyjnego narzędzia: dyskretne, ciekawskie drobne gesty klawiszowe, krótka pozytywna harmonia, bez triumfu i bez skojarzeń z włamaniem. 48 kHz PCM24 stereo + OGG, −14 LUFS, MIDI, własny syntezator Python bez sampli.

**Licencja i warunki:** L1 + L2 + L3 powyżej. **Edycja po wygenerowaniu:** tak — automatyczne rozmieszczenie nut, barwy DSP, tłumienie harmonicznych, panorama, miks, normalizacja LUFS; WAV/OGG/MIDI nie podlegały późniejszej ręcznej edycji.

### jingle_showcase_exhibit

**Każdy plik (osobny wpis w tym zestawie):** `audio/jingle_showcase_exhibit.ogg`, `audio/jingle_showcase_exhibit.wav`, `score/jingle_showcase_exhibit.mid`.

**Narzędzie / data:** `render_music.py` + `ffmpeg/libvorbis` + `mido`, 2026-11-05. **Pełny prompt / polecenie twórcze:** Skomponuj autorski 3,45-sekundowy jingle gabloty z eksponatem fikcyjnej mechaniki: ciekawość, miękkie wyższe nuty pianina i drewniany klarnet, bez błysku złota, ostrego mechanicznego kliknięcia czy skojarzeń z łupem. 48 kHz PCM24 stereo + OGG, −14 LUFS, MIDI, własna synteza Python bez sampli.

**Licencja i warunki:** L1 + L2 + L3 powyżej. **Edycja po wygenerowaniu:** tak — automatyczne rozmieszczenie nut, barwy DSP, tłumienie harmonicznych, panorama, miks, normalizacja LUFS; WAV/OGG/MIDI nie podlegały późniejszej ręcznej edycji.

### jingle_end_of_day

**Każdy plik (osobny wpis w tym zestawie):** `audio/jingle_end_of_day.ogg`, `audio/jingle_end_of_day.wav`, `score/jingle_end_of_day.mid`.

**Narzędzie / data:** `render_music.py` + `ffmpeg/libvorbis` + `mido`, 2026-11-05. **Pełny prompt / polecenie twórcze:** Skomponuj autorski 3,75-sekundowy jingle zamknięcia dnia pracy legalnego ślusarza: opadająca spokojna fraza na pianinie i klarnetowe westchnienie, delikatny kontrabas, satysfakcja z pomocy ludziom bez dramatyzmu. 48 kHz PCM24 stereo + OGG, −14 LUFS, MIDI, własny syntezator Python bez sampli.

**Licencja i warunki:** L1 + L2 + L3 powyżej. **Edycja po wygenerowaniu:** tak — automatyczne rozmieszczenie nut, barwy DSP, tłumienie harmonicznych, panorama, miks, normalizacja LUFS; WAV/OGG/MIDI nie podlegały późniejszej ręcznej edycji.

### qa/lock_harmony_spectrogram.png

**Plik:** `qa/lock_harmony_spectrogram.png`. **Narzędzie / data:** scipy.signal, matplotlib przez `render_music.py`, 2026-11-05.

**Pełny prompt / polecenie:** „Stwórz spektrogram pełnej dwuminutowej ścieżki lock_harmony przy 48 kHz i zobrazuj całe 0–7 kHz; zaciemnieniem oznacz pasmo 2–6 kHz zarezerwowane dla mechanicznych klików zamka, opisz osie, barwy oraz poziom widma.”

**Licencja:** L1 + L2 + L3. **Edycja:** wygenerowany programowo, bez późniejszej edycji obrazu.

### qa/measurements.json oraz qa/verification.log

**Pliki:** `qa/measurements.json`, `qa/verification.log`. **Narzędzie / data:** `verify_assets.py`, scipy, soundfile, pyloudnorm; 2026-11-05.

**Pełny prompt / polecenie:** „Zweryfikuj każdy master: czas, kanały i format PCM 48k/24-bit, poziom LUFS względem −16 albo −14, peak, ciągłość na styku pętli na podstawie różnic pierwszych i drugich, porównanie mocy pasma 2–6 kHz do 60–2000 Hz, zgodność długości OGG i WAV oraz limit 20 MB na plik. Zapisz wynik bez dopisywania niezmierzonych danych.”

**Licencja:** L1 + L2 + L3. **Edycja:** wynik automatycznej weryfikacji, bez ręcznej korekty pomiarów.

