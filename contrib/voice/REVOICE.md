# Kwestie do ponownego nagrania (zmiana słów po nagraniu)

Lista kluczy `*.line.N` z `game/i18n/content.csv`, w których po nagraniu (D-57; PL/EN/DE w `game/assets/audio/lines/`) zmieniły się **słowa**. Same zmiany pisowni (np. EN brytyjska → amerykańska: *neighbour → neighbor*) i interpunkcji nie wymagają nagrania. Po nagraniu: `tools/voice_lines.py tts-payload --jobs <id> --lang <lang>` → `finish`, potem usuń wiersz z tej listy.

| klucz | język | było (nagrane) | jest (napis) | źródło |
|---|---|---|---|---|

Razem: **0** plików — oba PL nagrane ponownie 2026-11-06 (tym samym głosem i seedem, wpis w `docs/ASSETS.md`). EN i DE bez zmian słów. Przegląd: `contrib/gpt/REVIEW-T44-T73.md`.
