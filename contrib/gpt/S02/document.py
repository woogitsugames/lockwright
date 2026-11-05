#!/usr/bin/env python3
"""Regenerate the two attribution/readme documents from the checked manifest."""
from __future__ import annotations
import json
from collections import Counter
from pathlib import Path
root=Path(__file__).resolve().parent
m=json.loads((root/'manifest.json').read_text(encoding='utf8'))
files=m['files'];assert len(files)==44
bytes_all=sum(r['size_bytes'] for r in files)
readme='''# S02 — Kamienica: tła i dźwięki foley

**Projekt:** Lockwright: Pogotowie Zamkowe / Lockwright: Locksmith on Call  
**Data:** 2026-11-05  
**Zakres:** `contrib/gpt/S02/` — bez zmian w pozostałych katalogach.

## Rezultat

- **44 oryginalne pliki WAV**: 39 efektów mono i 5 teł stereo po dokładnie 60 sekund; bez źródeł nagranych, cudzej muzyki, rozpoznawalnych słów lub marek.
- **Format:** 48 000 Hz, signed PCM 24-bit WAV; maksymalny plik: 17,28 MB (poniżej limitu 20 MB).
- **Foley:** 16 kroków (8 drewno + 8 lastryko), 6 sekwencji pukania (2 nieśmiałe, 2 stanowcze, 2 pilne/autorytatywne bez syren), 3 oryginalne dzwonki mieszkań, 2 kliknięcia włącznika minutnika, 2 pętle tykania, 2 wygaśnięcia światła, 5 zawiasów, 3 klamki.
- **Tła:** klatka w dzień, wieczorem, nocą; mokre podwórko; warsztat z zegarem i dalekim tramwajem. Zawierają metadane zapętlenia RIFF `smpl`, od próbki 0 do ostatniej.
- **Głośność:** wszystkie foley: peak −12 dBFS; tła: −18,00 LUFS I (EBU R128/BS.1770, obie ścieżki), nie występuje clipping PCM.
- **Onset:** najpóźniej 0,167 ms w foley przy progu −30 dB względem szczytu (limit zamówienia ≤ 5 ms).
- **Odbiór automatyczny:** `python validate.py` → 44/44 PASS (format, pętle, liczniki, LUFS, onset, szew, hash SHA-256, poziom szczytu).

## Metoda i pochodzenie

Dźwięki są **autorską syntezą proceduralną**, a nie nagraniami lub modelowymi klonami cudzych próbek. `synthesize.py` tworzy modalne rezonanse drewna/metalu/lastryko, impulsy uderzeń, tarcie *stick-slip*, przestrzenne wczesne odbicia i barwiony szum stochastyczny. Nie używa pakietów sampli, rozpoznawalnej muzyki, głosów ani komercyjnych nazw urządzeń. Używany jest deterministyczny generator NumPy PCG64 z seedem `20261105`; warianty mają odmienne proporcje i timingi, nie są tylko przestrojeniem jednego pliku.

Tła otrzymują 0,9-sekundową pętlę zachodzącą na siebie przed dodaniem zdarzeń modulo 60 s; dzięki temu ich koniec łączy się z początkiem bez dodatkowego kliku. Różnice na szwie mieszczą się w normalnej dynamice sąsiednich próbek (test p99,99). Foley dostają bardzo krótki fade-in (12 próbek), fade-out, usunięcie składowej stałej i normalizację peaku. Bębniące w stare drewno uderzenia i brzęk dzwonków są wymyślone, bez odniesień do rzeczywistych producentów.

Pies dzienny jest proceduralnym niskim dźwiękiem o szczekającej obwiedni. „Radio” to tylko przytłumiony za ścianą, nieregularny szum o charakterze mowy, **bez głosu, słów ani muzyki**. Tramwaj to model toczącego się, oddalonego pojazdu, bez sygnałów rozpoznawalnej firmy.

### Odtworzenie i test

```bash
python -m pip install -r requirements.txt
python synthesize.py  # wypełnia ./foley, ./ambience i manifest.json
python document.py    # odtwarza README.md i ASSETS.md
python validate.py    # weryfikacja, 44/44 PASS
```

Do integracji: nie ustawiać `edit/normalize` ani `edit/trim` w Godot (zniszczy poziomy i opóźnienia); wykrywanie loop z `smpl` albo ręcznie `loop_begin=0` i `loop_end=60s`. Dla tykania `timer_ticking_01/02` stosować pętle programu audio z plikiem WAV; nie są to 60-sekundowe tła.

**Ważny konflikt specyfikacji:** S02 wymaga teł `−18 LUFS`, natomiast `audio/v2/README.md` i `docs/FEEL.md` opisują domyślny miks otoczenia `−35 LUFS`. Surowy plik spełnia S02; przy wpięciu do istniejącej szyny ambience należy zastosować wstępną redukcję około **−17 dB**, skorygowaną odsłuchem, zachowując ducking `−6 dB` przy aktywnym zamku. Inaczej szum kamienicy zagłuszy mechanikę.

## Spis plików audio (PL / EN)

| Plik | Opis PL / EN | Czas |
|---|---|---:|
'''
for x in files:
 readme+=f"| `{x['file']}` | {x['description_pl']} / {x['description_en']} | {x['duration_s']:.2f} s |\n"
readme+='''
## Pozostałe pliki

- `synthesize.py` — deterministyczny generator dźwięków (wyłącznie wewnątrz S02).
- `document.py` — odtwarzanie spisu i rejestru praw do zasobów.
- `validate.py` — automatyczny test formatów, onsetów, poziomów i szwów.
- `manifest.json` — parametry każdego pliku, SHA-256, metoda, opis PL/EN.
- `ASSETS.md` — wpis dla każdego z 44 zasobów, licencja/warunki oraz specyfikacja generacji.
- `requirements.txt` — zależności wyłącznie do syntezy offline.
- `push_to_github.sh` — opcjonalne, bezpieczne wdrożenie wyłącznie katalogu S02 z lokalnego sklonowanego repozytorium; brak force-push.

## Nieukończone / decyzje do podjęcia

Brak nagrań z terenu i testu odsłuchowego na fizycznym telefonie. Synteza zawiasów, lastryko i dalekich odgłosów wymaga odsłuchu w rzeczywistej grze z aktywnym zamkiem, zwłaszcza przy słuchawkach i na głośniku telefonu. W razie potrzeby można wymienić wybrane zasoby na autorskie nagrania, z opisem ich pochodzenia i nowymi wpisami w `ASSETS.md`.

Po stronie zespołu integracyjnego: ustalić czy tła mają być celowo głośniejsze niż istniejąca biblioteka, czy ich pliki bazowe pozostają na −18 LUFS z tłumieniem na szynie, oraz zweryfikować ustawienia importu Godot 4.7. **Nie zmieniono** `audio/v2/`, `game/` ani żadnego kodu innych zespołów.
'''
(root/'README.md').write_text(readme,encoding='utf8')

assets='''# S02 — ASSETS: pochodzenie dźwięków i parametry generacji

**Data:** 2026-11-05. **Zakres:** tylko `contrib/gpt/S02/`.

Wszystkie pliki zostały wygenerowane w tym zleceniu oryginalną syntezą proceduralną (kod `synthesize.py` przygotowany z pomocą ChatGPT). **Nie uruchamiano modelu generującego audio, nie używano zewnętrznych sampli, głosów, utworów ani sampli z bibliotek SFX.** Kolumna „pełne polecenie” podaje dokładne zadanie syntezy i parametry konkretnego przebiegu, a nie zmyślony prompt wysłany do nieużywanego modelu audio. Kod ziarna losowego i parametrów zapisano także w `synthesize.py`, co umożliwia odtworzenie.

**Narzędzie i warunki:** Python 3 z NumPy (BSD), SciPy (BSD), SoundFile (BSD) i pyloudnorm (licencja projektu, sprawdzić przy dystrybucji kodu). Efekty są wytworzone od zera bez materiałów osób trzecich; wykorzystanie wyników generowanych z pomocą ChatGPT podlega obowiązującym warunkom OpenAI i zasadom projektu. Licencji cudzych nagrań: **nie dotyczy**. Pliki są przewidziane do wykorzystania i edycji w projekcie Lockwright. Nie twierdzimy, że nagrania pochodzą od prawdziwego psa, tramwaju lub instrumentu.

**Edycja:** tak, wyłącznie automatyczna postprodukcja w kodzie: foley — usuwanie DC, mikro-fade, normalizacja peaku do −12 dBFS; tła — przeszycie 0,9 s, normalizacja EBU R128 do −18 LUFS, wpis `smpl`. Brak późniejszej ręcznej edycji.

| Plik | Narzędzie, data | Pełne polecenie / parametry syntezy (PL, EN) | Warunki / edycja |
|---|---|---|---|
'''
for x in files:
 q=f"Wytwórz z zerowych próbek, wyłącznie syntezą proceduralną, bez mowy, muzyki i sampli osób trzecich: {x['description_pl']} / {x['description_en']}. Użyj 48 kHz, PCM 24-bit, {'stereo, 60 s, pętla smpl, -18 LUFS I' if x['channels']==2 else 'mono, onset <=5 ms, peak -12 dBFS'}. Dokładny wariant: {x['method']}; deterministyczny seed 20261105."
 q=q.replace('|','\\|')
 assets+=f"| `{x['file']}` | `Python 3 / NumPy / SciPy / SoundFile / pyloudnorm`<br>2026-11-05 | {q} | Autorska synteza; zasady OpenAI + projektu; edycja automatyczna: tak |\n"
(root/'ASSETS.md').write_text(assets,encoding='utf8')
print('Wrote README.md, ASSETS.md for',len(files),'files; bytes',bytes_all)
