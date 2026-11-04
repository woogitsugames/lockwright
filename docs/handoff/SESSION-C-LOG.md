# Sesja C — log nocny (spike'i, sklep)

Format: data i godzina (UTC), zadanie, co zrobione, liczby, linki, blokady.

## 2026-11-04 23:30 — C5: sklep i marka (`store/`)
- `store/listing.md`: nazwa, podtytuł, tekst promocyjny, słowa kluczowe, krótki i pełny opis, „Co nowego” — PL i EN, App Store i Google Play. Limity sprawdza `store/tools/check_lengths.py` (wszystkie pola mieszczą się).
- **Do decyzji właściciela:** „Lockwright: Emergency Locksmith” ma **31 znaków** (limit 30 w obu sklepach). Rekomendacja: „Lockwright Emergency Locksmith” (30). Alternatywa: „Lockwright: Locksmith on Call” (29). PL „Lockwright: Pogotowie Zamkowe” = 29, bez zmian.
- `store/rating.md`: kwestionariusz Apple (cel 4+) i IARC (PEGI 3 / ESRB E / USK 0), ryzyko odbioru tematu, notatka dla recenzenta.
- `store/privacy.md`: polityka prywatności PL/EN (offline, brak danych), App Privacy „Data Not Collected”, Data safety, manifest prywatności (powody API do weryfikacji na eksporcie Godota).
- `store/screenshots/`: plan 8 kadrów + generator Pillow; 32 makiety (PL/EN × iPhone 6,9" 1320×2868 i Android 1080×1920), 24,8 MB (wersje 256-kolorowe; do wysyłki generować pełne RGB bez `--quantize`). Kadry 06 i 07 to zaślepki — potrzebne nowe rendery (lista w `PLAN.md`).
- Otwarte pytania: nazwa EN, zakres 1.0, model biznesowy (D-06), dane administratora i domena, iPad (D-10), grupa docelowa Play (rekomendacja 13+, bez programu rodzinnego).

## 2026-11-04 23:55 — C3: spike 5, determinizm na ARM (`spikes/determinism/`)
- `lockcore/` budowany z zewnątrz (`add_subdirectory`), bez zmian w katalogu. Buildy: x86_64 gcc 13.3, x86_64 clang 18.1, Linux aarch64 gcc 13.3 (statycznie, qemu-user), Android arm64 NDK 29 clang 21 (statycznie z bionic, qemu-user).
- Wynik lokalny: **100% zgodności** — `ctest` zielony na 4 buildach, 5 złotych powtórek z identycznym hashem (np. `pin_tumbler_t7_s4242` = `6179e59ebde7514b`), CSV `verify_seeds --seeds 1000` identyczny (`c9e38026f430bbc7`), `replay_fuzz` **10 000/10 000** (13,9 mln kroków, hash zdarzeń i stanu co 60 kroków).
- `step()` natywnie x86_64: p99 118–161 ns; Android arm64 w emulacji p99 2,3 µs (kryterium 0,2 ms).
- Rozjazdów brak. Brak pokrycia `gate_align` / `detector_trip` (nie ma jeszcze takich rodzin w lockcore v0.1).
- Workflow `spike-determinism.yml` (ubuntu + qemu, macOS arm64 natywnie). Szczegóły: `spikes/determinism/RESULTS.md`.
