# S04 — Diegetyczne dźwięki interfejsu / Diegetic UI sounds

**Status:** gotowe zasoby do integracji. **Data:** 2026-11-05. **Zakres:** wyłącznie `contrib/gpt/S04/` w repozytorium `woogitsugames/lockwright`.

## Rezultat

- **90 krótkich plików WAV:** 15 zdarzeń × 6 wariantów. Lista zdarzeń w zleceniu obejmuje 15 pozycji, mimo kryterium „min. 84”.
- **6 dodatkowych plików WAV:** oddzielna, 1-sekundowa, bezszwowa pętla szumu elektrycznego boroskopu; dzięki rozdzieleniu klik włączenia **nie** powtarza się w pętli.
- Razem **96 WAV**, `manifest.json` (parametry każdego pliku), `ASSETS.md` (pełne briefy/proweniencja), `generate.cjs` (deterministyczny syntezator) i `verify.py` (walidator).
- Żaden dźwięk nie zawiera mowy, melodii, marek, sampli ani zasobów innych gier. Warstwy: skóra, stal, mosiądz, papier, kreda, drewno, szkło, plastik, monety; fizyczne tarcie, rezonans i krótkie uderzenia, bez „sztucznych” dźwięków przycisków.

## Lista plików i funkcja (PL / EN)

Każda pozycja tabeli oznacza sześć fizycznych plików WAV: warianty `_01.wav` do `_06.wav`. Pełne ścieżki do wszystkich 96 pozycji są także w `manifest.json` i `ASSETS.md`.

| ID zdarzenia | Krótki opis (PL / EN) | Pliki | Czas wariantów |
|---|---|---|---|
| `tool_roll_open` | Rozwinięcie skórzanej zwijki / Unroll leather tool wrap | `ui/tool_roll_open/tool_roll_open_01.wav` … `_06.wav` | 493–560 ms |
| `tool_roll_close` | Zwinięcie skórzanej zwijki / Roll up leather tool wrap | `ui/tool_roll_close/tool_roll_close_01.wav` … `_06.wav` | 463–542 ms |
| `pick_remove` | Wyjęcie wytrycha z kieszeni / Take pick from leather pocket | `ui/pick_remove/pick_remove_01.wav` … `_06.wav` | 206–276 ms |
| `pick_insert` | Włożenie wytrycha do kieszeni / Return pick to leather pocket | `ui/pick_insert/pick_insert_01.wav` … `_06.wav` | 222–288 ms |
| `brass_snap_pause` | Mosiężna napa klapki pauzy / Brass pause-flap press stud | `ui/brass_snap_pause/brass_snap_pause_01.wav` … `_06.wav` | 148–185 ms |
| `notebook_page_turn` | Przewrócenie kartki zeszytu / Turn notebook page | `ui/notebook_page_turn/notebook_page_turn_01.wav` … `_06.wav` | 403–484 ms |
| `chalk_on_metal` | Kreda po metalu / Chalk rubbing on metal | `ui/chalk_on_metal/chalk_on_metal_01.wav` … `_06.wav` | 334–432 ms |
| `loupe_set_down` | Odłożenie lupy na skórę / Place loupe on leather | `ui/loupe_set_down/loupe_set_down_01.wav` … `_06.wav` | 190–235 ms |
| `loupe_apply` | Przyłożenie lupy / Raise loupe to eye | `ui/loupe_apply/loupe_apply_01.wav` … `_06.wav` | 211–277 ms |
| `borescope_power_on` | Włączenie boroskopu / Switch on inspection scope | `ui/borescope_power_on/borescope_power_on_01.wav` … `_06.wav` | 399–462 ms |
| `phone_job_vibrate` | Wibracja telefonu ze zleceniem na blacie / Job phone vibrates on wooden counter | `ui/phone_job_vibrate/phone_job_vibrate_01.wav` … `_06.wav` | 489–565 ms |
| `showcase_drawer` | Szuflada gabloty / Showcase drawer | `ui/showcase_drawer/showcase_drawer_01.wav` … `_06.wav` | 521–572 ms |
| `showcase_glass_door` | Szklane drzwiczki gabloty / Showcase glass door | `ui/showcase_glass_door/showcase_glass_door_01.wav` … `_06.wav` | 397–488 ms |
| `coins_on_counter` | Monety na blacie / Coins on wooden counter | `ui/coins_on_counter/coins_on_counter_01.wav` … `_06.wav` | 345–414 ms |
| `stamp_cancel` | Kasownik pieczątki / Self-inking receipt stamp | `ui/stamp_cancel/stamp_cancel_01.wav` … `_06.wav` | 252–327 ms |
| `borescope_hum_loop` | Pętla szumu boroskopu / Inspection scope electrical hum loop | `ui/borescope_hum_loop/borescope_hum_loop_01.wav` … `_06.wav` | 1000–1000 ms |

## Parametry i walidacja

- **48 000 Hz**, 1 kanał, PCM 16-bit little-endian (WAV RIFF).
- **Peak −14,000 dBFS** (maksymalna wartość pojedynczej próbki, tolerancja ±0,1 dB; nie jest to poziom LUFS).
- **Onset:** pierwsza próbka o amplitudzie co najmniej −30 dB względem lokalnego peaku pliku. Pomiar wszystkich 96 wariantów: **maks. 0.2708 ms** (limit 2 ms, 96 próbek). Krótki kontakt fizyczny znajduje się na samym początku, bez pustego lead-in.
- **Maks. długość one-shot:** **572.3 ms** (limit 600 ms); pętle boroskopu: 1000 ms, forward, WAV `smpl` loop 0…47999.
- Kontrola zakresu peaku: -14.0001…-14.0001 dBFS. Próbki nie są kompresowane stratnie; wszystkie pliki mniejsze niż 20 MB (cały bank: 3.63 MiB).
- Krótki fade-in 0,22 ms (one-shot), fade-out 8 ms; usuwanie DC. Pętle są konstruowane okresowo, bez fade-out; nie zawierają powtórzonego kliknięcia.

Weryfikacja po pobraniu katalogu:

```bash
python3 contrib/gpt/S04/verify.py
node contrib/gpt/S04/generate.cjs  # opcjonalny ponowny render (Node 18+; zapis WYŁĄCZNIE w S04)
python3 contrib/gpt/S04/verify.py
```

Skrypt sprawdza liczebność, nazwy, RIFF PCM16/48k/mono, peak, onset, długość, składową DC, wygaszenie końca oraz znacznik `smpl` i brak nietypowego skoku na szwie pętli.

## Mapowanie do gry (propozycja dla zespołu runtime)

- Zwijka (`HUD.md` §4): `tool_roll_open/close`; wytrych z kieszeni: `pick_remove/insert`; klapka pauzy (§6): `brass_snap_pause`.
- Zeszyt i dostępność: `notebook_page_turn`, `chalk_on_metal` (opcjonalna warstwa „Pomoc w czytaniu”). Lupa: `loupe_set_down` przy odkładaniu oraz `loupe_apply` przy podnoszeniu/przyłożeniu.
- Boroskop: odegrać `borescope_power_on` **raz**, a następnie uruchomić `borescope_hum_loop` jako osobny, cicho zmiksowany `AudioStreamPlayer`; zatrzymać przy wyłączeniu. Jeśli importer WAV nie rozpoznaje `smpl`, skonfigurować pętlę 0…47999 ręcznie.
- Telefon ze zleceniem: `phone_job_vibrate` na drewnianym blacie; warsztat: `showcase_drawer` i `showcase_glass_door`; rachunek: `coins_on_counter`, `stamp_cancel`.
- Wybierać warianty round-robin bez natychmiastowych powtórzeń (nie odtwarzać sześciu jednocześnie). Dźwięk i haptykę uruchamiać z tego samego zdarzenia, respektując budżet synchronizacji `FEEL.md`. Brak UI w postaci paneli, komunikatów sukcesu czy melodii.

## Co nie zostało wykonane / ograniczenia

- **Nie podłączono dźwięków do scen ani skryptów Godota**, ponieważ zlecenie zakazuje zmian poza `contrib/gpt/S04/`.
- To **oryginalna synteza proceduralna**, nie nagrany Foley w studio. Zautomatyzowano pomiary techniczne, ale **nie przeprowadzono odsłuchów na docelowych iPhone'ach i Androidach** ani testów miksu w trakcie rozgrywki.
- Peak jest wspólny, ale słyszalna głośność różnych materiałów zależy od obwiedni i widma. Konieczne jest ustawienie gainów po odsłuchu (zwłaszcza cicha pętla boroskopu, telefon, monety) oraz ograniczenie sumowania głosów.

**Rekomendacja:** po integracji przeprowadzić ślepy test rozpoznawania 15 zdarzeń na małym głośniku telefonu i zweryfikować, że skrzypienie/kreda nie maskują kluczowych klików `set`/`false_set` z `docs/FEEL.md`. Testy symulacyjne i dokumentacja są tu; integrację i tuning powinien wykonać właściciel warstwy audio/runtime.

## Pochodzenie

Generator `generate.cjs` został napisany z pomocą ChatGPT; synteza DSP jest wykonywana lokalnie w JavaScript, **bez zewnętrznego modelu text-to-audio i bez pobranych nagrań**. W `ASSETS.md` zapisano **każdy plik osobno**, datę, narzędzie, pełny brief syntezy, zasady użycia i postprodukcję. Docelową licencję dystrybucji zasobów ustala właściciel repozytorium.
