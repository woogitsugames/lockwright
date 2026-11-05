# T16 — tłumaczenie gry Lockwright na czeski (CS)

**Status:** gotowy szkic do korekty przez rodzimego użytkownika czeskiego (cs-CZ). Data: 5 listopada 2026.

**Repozytorium:** `woogitsugames/lockwright` · źródła z `main` · zapis wyłącznie w `contrib/gpt/T16/`.

## Wykonane

- `strings_cs.csv` — **125 z 125 kluczy** interfejsu, format `key,cs`.
- `content_cs.csv` — **629 z 629 kluczy** dialogów, zleceń, gabloty, zeszytu, narzędzi, osiągnięć i wskazówek, format `key,cs`.
- `store_cs.md` — komplet proponowanych pól App Store i Google Play, osobny opis Google Play, liczba znaków i bajtów UTF-8 przy każdym polu, podsumowanie limitów; wariant monetyzacji A oznaczony jako wyłącznie opcjonalny.
- `GLOSSARY_cs.md` — **90 terminów** EN–PL–CS wraz z decyzją o sposobie zwracania się do gracza.
- `README.md` — niniejszy raport, walidacja, lista ryzyk długości i otwarte kwestie.

**Suma:** 754 / 754 kluczy (100%), bez zmian kluczy i bez utraty placeholderów `{n}` / `{0}`.

## Styl i terminologia

- **Interfejs oraz opis sklepowy: tykanie** (czeskie `tykání`) — naturalne w grze, zwięzłe i spójne z EN/PL.
- **Dorośli bohaterowie w dialogach: forma grzecznościowa** (`vykání`), z wyjątkiem relacji bliskich lub wypowiedzi do dzieci. Notatki ślusarza w 1. osobie.
- Mechanika: `napinacz → napínák`, `wytrych → planžeta`, `pin → stavítko`, `linia podziału → dělicí rovina`, `fałszywe osadzenie → falešné usazení`, `przepchnięcie → přetlačení stavítka`.
- Imię kota `Potato / Ziemniak` lokalizowane jako `Brambora`. Polskie imiona i toponimy zachowane z polskimi znakami.
- Kwoty liczone w monetach w UI otrzymały konstrukcję z etykietą jednostki przed wartością (`Odměna (v mincích): {n}`), aby uniknąć błędnego czeskiego mianownika przy 1, 2–4 i 5+.
- Brak haseł marketingowych z ceną, datą premiery lub potwierdzeniem dostępności (D-06, D-51). Wariant A z IAP ma status warunkowy.

## Walidacja techniczna

| Kontrola | Wynik |
|---|---|
| Klucze interfejsu | 125/125 |
| Klucze treści | 629/629 |
| Nagłówek obu plików CSV | `key,cs` |
| Brak duplikatów i brakujących kluczy | OK |
| Placeholdery w porównaniu z EN | OK |
| Limit nazw w App Store i Google Play | 29/30 znaków |
| Apple subtitle / promotional | 25/30, 160/170 znaków |
| Apple keywords | 87/100 bajtów UTF-8 |
| Google Play krótki opis | 62/80 znaków |
| Opisy pełne, wariantowe i „Co nowego” | W limitach; kompletna tabela w `store_cs.md` |
| Słowniczek | 90 terminów (minimum 40) |
| Dialogi ponad 90 znaków lub notatki ponad 130 | 0 w czeskich wersjach |

## Ryzyka długości: CS dłuższy niż EN o ponad 30%

Wykaz obejmuje **50 kluczy**: 29 w interfejsie i 21 w treści. Długość liczona w znakach Unicode (praktycznie code units UTF-16; czeskie znaki mieszczą się w jednym). Przekroczenie oznacza ryzyko niedopasowania do UI — **nie** potwierdza faktycznego obcięcia.

| Plik | Klucz | EN | CS | Wzrost |
|---|---|---:|---:|---:|
| `strings_cs.csv` | `boot.calib_one` | 3 | 5 | +67% |
| `strings_cs.csv` | `boot.calib_skip` | 4 | 9 | +125% |
| `strings_cs.csv` | `settings.quality_high` | 4 | 6 | +50% |
| `strings_cs.csv` | `common.on` | 2 | 7 | +250% |
| `strings_cs.csv` | `common.off` | 3 | 7 | +133% |
| `strings_cs.csv` | `menu.jobs` | 4 | 7 | +75% |
| `strings_cs.csv` | `jobs.title` | 4 | 7 | +75% |
| `strings_cs.csv` | `job.reward_fmt` | 17 | 23 | +35% |
| `strings_cs.csv` | `job.tip_fmt` | 30 | 44 | +47% |
| `strings_cs.csv` | `verify.card.deed` | 4 | 16 | +300% |
| `strings_cs.csv` | `verify.card.photo` | 5 | 10 | +100% |
| `strings_cs.csv` | `verify.card.bailiff` | 7 | 18 | +157% |
| `strings_cs.csv` | `settings.haptics` | 7 | 14 | +100% |
| `strings_cs.csv` | `settings.haptics_enabled` | 15 | 22 | +47% |
| `strings_cs.csv` | `settings.haptics_test` | 10 | 15 | +50% |
| `strings_cs.csv` | `settings.haptics_calibration_two_clicks_one` | 3 | 5 | +67% |
| `strings_cs.csv` | `settings.volume_ambience` | 8 | 11 | +38% |
| `strings_cs.csv` | `settings.wide_windows` | 13 | 21 | +62% |
| `strings_cs.csv` | `settings.text_scale` | 9 | 14 | +56% |
| `strings_cs.csv` | `run.lives_left` | 11 | 17 | +55% |
| `strings_cs.csv` | `run.finished` | 22 | 37 | +68% |
| `strings_cs.csv` | `optics.borescope` | 13 | 22 | +69% |
| `strings_cs.csv` | `pause.title` | 6 | 11 | +83% |
| `strings_cs.csv` | `pause.resume` | 6 | 10 | +67% |
| `strings_cs.csv` | `workshop.buy` | 3 | 6 | +100% |
| `strings_cs.csv` | `workshop.owned` | 5 | 8 | +60% |
| `strings_cs.csv` | `dev.haptics_lab.title` | 11 | 24 | +118% |
| `strings_cs.csv` | `dev.haptics_lab.tier` | 4 | 6 | +50% |
| `strings_cs.csv` | `dev.haptics_lab.force_fallback` | 12 | 22 | +83% |
| `content_cs.csv` | `job.dollhouse_wooden_lock.title` | 25 | 33 | +32% |
| `content_cs.csv` | `job.refuse_rush_bribe.title` | 26 | 35 | +35% |
| `content_cs.csv` | `showcase.roman_wards.title` | 11 | 23 | +109% |
| `content_cs.csv` | `tool.pk_peg.name` | 10 | 14 | +40% |
| `content_cs.csv` | `tool.pk_hook.name` | 9 | 16 | +78% |
| `content_cs.csv` | `tool.pk_ward.name` | 10 | 24 | +140% |
| `content_cs.csv` | `tool.pk_ripple.name` | 11 | 16 | +45% |
| `content_cs.csv` | `tool.pk_crown.name` | 10 | 18 | +80% |
| `content_cs.csv` | `tool.pk_flag.name` | 9 | 19 | +111% |
| `content_cs.csv` | `tool.tl_drill.name` | 5 | 7 | +40% |
| `content_cs.csv` | `notebook.rule.1` | 45 | 64 | +42% |
| `content_cs.csv` | `tool.ob_borescope.name` | 9 | 18 | +100% |
| `content_cs.csv` | `ach.achievement.first_open.name` | 12 | 18 | +50% |
| `content_cs.csv` | `ach.achievement.false_note.desc` | 42 | 57 | +36% |
| `content_cs.csv` | `ach.achievement.wooden_creak.name` | 15 | 21 | +40% |
| `content_cs.csv` | `ach.achievement.wooden_creak.desc` | 46 | 61 | +33% |
| `content_cs.csv` | `ach.achievement.dark_clean.name` | 12 | 16 | +33% |
| `content_cs.csv` | `ach.achievement.museum_papers.name` | 13 | 21 | +62% |
| `content_cs.csv` | `job.krystyna_wooden_album.situation` | 117 | 160 | +37% |
| `content_cs.csv` | `job.krystyna_wooden_album.title` | 17 | 26 | +53% |
| `content_cs.csv` | `job.stefan_book_tin.title` | 19 | 31 | +63% |

## Co pozostało / czego nie wykonano

1. **Nie wykonano native-speaker review.** Priorytet: nazwy techniczne `cívkové stavítko`, `přetlačení stavítka`, `bekináž`; odmiana polskich nazw osobowych; idiomatyczność żartów i fraz formalnych.
2. **Nie testowano fontów i rzeczywistego łamania tekstu na telefonie.** Szczególnie widoki z krótkimi etykietami narzędzi i osiągnięć wymienione w tabeli.
3. **Nie wdrożono CS do runtime Godota**, zgodnie z zakazem zmian poza katalogiem T16. Integrator musi zaimportować oba CSV, dodać wybór `Čeština` do ustawień i przeprowadzić testy lokalizacji.
4. **Nie zweryfikowano faktycznej realizacji funkcji obiecanych w opisie 1.0.** Teksty bazują na EN z `store/listing.md`; przed publikacją właściciel powinien potwierdzić zakres gry, prywatność, offline, brak reklam i ewentualny model zakupu. D-06 i D-51 pozostawiają model otwarty.
5. Nie modyfikowano żadnych plików spoza `contrib/gpt/T16/`.

### Źródła

- `CLAUDE.md`, `docs/DESIGN.md`, `docs/CLIENTS.md`, `docs/JOBS.md`, `docs/DECISIONS.md` (D-06, D-32, D-51).
- `game/i18n/strings.csv`, `game/i18n/content.csv`, `store/listing.md`.
