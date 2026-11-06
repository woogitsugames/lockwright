# Kwestie do ponownego nagrania (zmiana słów po nagraniu)

Lista kluczy `*.line.N` z `game/i18n/content.csv`, w których po nagraniu (D-57; PL/EN/DE w `game/assets/audio/lines/`) zmieniły się **słowa**. Same zmiany pisowni (np. EN brytyjska → amerykańska: *neighbour → neighbor*) i interpunkcji nie wymagają nagrania. Po nagraniu: `tools/voice_lines.py tts-payload --jobs <id> --lang <lang>` → `finish`, potem usuń wiersz z tej listy.

| klucz | język | było (nagrane) | jest (napis) | źródło |
|---|---|---|---|---|
| `job.grandma_broth.line.3` | pl | To mi wystarczy za papiery. List w skrzynce też jest na panią? | To pomaga. List w skrzynce też jest na panią? | T48 (zgodnie z EN/DE; ślusarz nie mówi, że zeznanie sąsiadki zastępuje dokumenty) |
| `job.refuse_rush_bribe.line.2` | pl | Procedur nie da się dopłacić. Proszę zadzwonić do siostry, poczekam. | Weryfikacji nie da się kupić. Proszę zadzwonić do siostry, poczekam. | T48 + T69 (zgodnie z EN „aren't for sale”) |

Razem: **2** pliki (PL). EN i DE bez zmian słów. Przegląd: `contrib/gpt/REVIEW-T44-T73.md`.
