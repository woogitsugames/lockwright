# Kwestie czekające na nagranie (lektor AI, D-57 / D-100)

**Stan 2026-11-17: nic nie czeka** (`python3 tools/voice_lines.py missing` → 0). Rozdziały 13–16 (212 kluczy × EN/PL/DE/FR/ES =
1060 plików) nagrane w D-142; pole `voice_pending` usunięte ze wszystkich 40 zleceń w `game/packs/ch13…ch16/jobs/`.

Gdy kiedyś zlecenie powstanie bez nagrań: pole `"voice_pending": true` w pliku zlecenia, gra gra same napisy
(`DialoguePlayer`: brak klipu = brak odtwarzania; „dzień po” przechodzi po stuknięciu). Po nagraniu:
`python3 tools/voice_lines.py manifest`/`tts-payload` → TTS → `finish` → usuń `voice_pending`; testy `test_chapter1x_jobs.gd`
przypominają, że zlecenie z klipami nie może mieć tego pola.
