# Aplikacje pomiarowe dla właściciela (D-33) — specyfikacja wspólna

Cel: właściciel (nie programista) sam mierzy opóźnienia haptyki i dźwięku na swoich telefonach, bez dodatkowego sprzętu.
Metoda: **akcelerometr telefonu** (wibracja i stuknięcie palcem w ekran widoczne jako drgania obudowy), **mikrofon telefonu** (kliknięcie z głośnika i odgłos stuknięcia) oraz **znaczniki wewnętrzne** (zegar monotoniczny przy wywołaniu API). Telefon leży ekranem do góry na twardym stole.

## Kroki (aplikacja prowadzi po polsku; EN gdy system nie jest po polsku)
0. **Start**: krótko, co się stanie (ok. 4 min), że to narzędzie testowe, nie gra. Klasa telefonu wykryta automatycznie (`pixel` / `samsung_a` / `budget` / `iphone_new` / `iphone_se`), z możliwością zmiany jednym dotknięciem.
1. **Przygotowanie**: połóż telefon ekranem do góry na twardym stole (nie na kolanach, nie na miękkim), wyłącz tryb cichy, głośność multimediów ok. 70%, wyłącz „wibracja przy dotyku” jeśli się da. Przycisk „Gotowe”.
2. **Haptyka automatycznie** (nie dotykaj telefonu, 30 prób co 400 ms): aplikacja woła API wibracji (transient) i z akcelerometru wykrywa początek drgań → `haptic_call` = API→drgania [ms].
3. **Opór ciągły** (Android A3/A2/A1, iOS Core Haptics; 4 s): włącza ciągły opór i mierzy najdłuższą przerwę w drganiach → `continuous_max_gap_ms`.
4. **Dźwięk automatycznie** (nie dotykaj, cisza w pokoju; pozwolenie na mikrofon): 30 kliknięć ścieżką szybką (Android: Oboe; iOS: AVAudioEngine) i 30 ścieżką silnika (Android: `AudioStreamPlayer` Godota) — od wywołania do onsetu w mikrofonie → `audio_call_fast`, `audio_call_engine`. Różnica (p50) to zysk ścieżki szybkiej.
5. **Stuknięcia** (20 razy w zaznaczone koło, spokojnie, co ok. 1 s): każde stuknięcie wyzwala jednocześnie wibrację i kliknięcie ścieżką szybką. Akcelerometr: onset stuknięcia → onset wibracji → `haptic_tap`. Mikrofon: onset odgłosu stuknięcia → onset kliknięcia → `audio_tap`. Synchronizacja: |onset kliknięcia − onset wibracji| (po przeliczeniu zegarów) → `audio_haptic_sync`.
6. **Wynik**: dla każdej miary p50/p95, liczba prób i **werdykt słowami**: „Przechodzi”, „Na granicy”, „Nie przechodzi”, „Brak danych” (kolor tylko jako dodatek; ikona/kształt różny dla każdego werdyktu). Przyciski: **„Udostępnij wynik”** (systemowy arkusz udostępniania z plikiem JSON) i „Powtórz”.

## Progi
`spikes/measure/thresholds.json` (z `docs/TECH.md` §4). Werdykt dla miary z progiem `pass` (i opcjonalnie `fail`): p95 ≤ pass → Przechodzi; p95 ≤ (fail ?? pass×1,25) → Na granicy; większe → Nie przechodzi. Dla `audio_oboe_gain_ms`: ≥ min → Przechodzi, ≥ 0,75×min → Na granicy.

## Plik wyniku (JSON, UTF-8) — `lockwright-pomiar-<platform>-<model>-<YYYYMMDD-HHMM>.json`
```json
{
  "schema": "lockwright.measure/1",
  "app": "android-godot" | "ios-native",
  "app_version": "0.2.0",
  "created_utc": "2026-11-05T21:14:00Z",
  "device": {"platform": "android"|"ios", "manufacturer": "...", "model": "...", "os": "16", "class": "pixel"|"samsung_a"|"budget"|"iphone_new"|"iphone_se",
             "haptic_tier": "A3"|"A2"|"A1"|"A0"|"H3"|"H0", "accel_hz": 412.0, "audio": {"sample_rate": 48000, "frames_per_burst": 192, "sharing": "Exclusive", "estimated_output_latency_ms": 12.3}},
  "metrics": {
    "haptic_call":        {"n": 30, "p50_ms": 11.2, "p95_ms": 14.9, "samples_ms": [ ... ]},
    "haptic_tap":         {...}, "audio_call_fast": {...}, "audio_call_engine": {...}, "audio_tap": {...},
    "audio_haptic_sync":  {...},
    "continuous_max_gap_ms": 8.5,
    "audio_oboe_gain_ms": 41.0
  },
  "verdicts": {"haptic_tap_p95_ms": "pass"|"border"|"fail"|"no_data", "...": "..."},
  "notes": ["dowolne ostrzeżenia, np. 'akcelerometr tylko 100 Hz: dokładność ±10 ms'"]
}
```
Miary, których platforma nie ma, pomijamy (np. `audio_call_engine` na iOS). Werdykty liczy aplikacja, ale skrypt `spikes/measure/tools/ingest.py` liczy je ponownie z `samples_ms` (źródło prawdy).

## Wykrywanie onsetów (wspólne)
- Akcelerometr: moduł wektora minus średnia krocząca 50 ms (usuwa grawitację), wartość bezwzględna; próg = mediana szumu z 300 ms przed zdarzeniem × 6 (min. 0,02 m/s²); onset = pierwsza próbka powyżej progu; do czasu bierzemy znacznik czasu zdarzenia sensora (Android `SensorEvent.timestamp` = elapsedRealtimeNanos; iOS `CMAccelerometerData.timestamp` = uptime), nie czas dostarczenia.
- Mikrofon: obwiednia |x| z oknem 0,5 ms, próg = szum × 8 (min. −40 dBFS); czas próbki = znacznik `AudioRecord.getTimestamp` / `AVAudioTime` przeliczony na zegar monotoniczny.
- Stuknięcie vs wibracja w akcelerometrze: stuknięcie = pierwszy onset po pokazaniu koła; wibracja = pierwszy onset ≥ 3 ms po stuknięciu z energią w paśmie ≥ 100 Hz utrzymaną ≥ 5 ms (stuknięcie gaśnie szybciej). Gdy rozdzielenie się nie uda → próba odrzucona i policzona w `rejected`.
