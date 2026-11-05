# T15 — Raport wykonania tłumaczenia PT-BR

**Repozytorium:** `woogitsugames/lockwright` · **źródło:** `main` · **data opracowania:** 2026-11-05  
**Status:** kompletny **szkic do przeglądu przez native speakera**, bez integracji ze źródłowym i18n.

## Co zostało zrobione

- Przetłumaczono z angielskiego na portugalski brazylijski **125/125 kluczy interfejsu** oraz **629/629 kluczy treści** (łącznie **754/754**).
- Zachowano istniejące identyfikatory i kolejność; wyjściowe CSV mają nagłówek `key,pt_br`.
- Wszystkie parametry i18n w nawiasach `{...}` zachowano bez zmian. Żadne pole PT-BR nie jest puste. Brak powtórzonych kluczy.
- Przygotowano lokalizację metadanych **App Store i Google Play**, w tym osobne warianty opisów różniące się zdaniem o haptyce, oraz liczby znaków/bajtów przy każdym polu. **12/12 pól** i **2/2 opisy z opcjonalną wariantą A** mieszczą się w limitach źródłowych.
- Sporządzono słowniczek **73 terminów** (EN → PL → PT-BR) i zasady stylistyczne.
- Zgodnie z D-06 i D-51 **nie przesądzono modelu biznesowego, ceny, terminu premiery ani dostępności**. Wariant A jest opisany osobno, nie do automatycznej publikacji.
- Tytuł PT-BR **„Lockwright Chaveiro de Plantão”** ma dokładnie 30 znaków. Forma z dwukropkiem miałaby 31 i przekroczyłaby limit.
- Zasady: legalne zlecenia, ostrożna weryfikacja prawa wejścia, mechanizmy fikcyjne, żadnych instrukcji dotyczących rzeczywistych produktów.

## Pliki

| Plik | Zawartość |
|---|---|
| `strings_pt_br.csv` | 125 kluczy interfejsu |
| `content_pt_br.csv` | 629 kluczy fabuły, historii, osiągnięć i podpowiedzi |
| `store_pt_br.md` | metadane sklepowe, limity, bajty UTF-8, wariant A |
| `GLOSSARY_pt_br.md` | 73 terminy i zasady narracji |
| `README.md` | ten raport i pełna lista ryzyk długości |

## Weryfikacja jakości

- Porównano liczbę kluczy, ich nazwy i kolejność oraz wszystkie parametry `{n}` / `{0}`.
- Zbadano każdy ciąg PT-BR pod kątem przekroczenia długości EN o **więcej niż 30%** (warunek: `len(pt_br) > 1.30 * len(en)`; liczone znaki Unicode). Wynik: **109 kluczy**, z tego **48 w interfejsie** i **61 w treści**.
- Dodatkowo orientacyjne progi z `docs/CLIENTS.md`: linie dialogu do 90 znaków, notatki do 130 znaków. W PT-BR przekroczone: **4 linii dialogu** i **1 notatek**; nie jest to wymóg językowy PL/EN, lecz sygnał do sprawdzenia w layoucie.
- Nie znaleziono referencji do konkurencyjnej platformy Apple w pełnym opisie Google Play.

## Ryzyka długości — pełna lista (109)

Kolumny: długość EN, długość PT-BR, wzrost w procentach. Krótkie etykiety mogą mieć wysoką wartość procentową nawet przy wzroście o kilka znaków.

| Klucz | EN | PT-BR | Wzrost |
|---|---:|---:|---:|
| `boot.calib_two` | 3 | 4 | +33% |
| `boot.calib_none` | 4 | 6 | +50% |
| `settings.feel_section` | 14 | 24 | +71% |
| `settings.quality_low` | 18 | 25 | +39% |
| `about.post_release_unlocked` | 34 | 50 | +47% |
| `settings.report_empty` | 13 | 22 | +69% |
| `common.back` | 4 | 6 | +50% |
| `common.on` | 2 | 6 | +200% |
| `common.off` | 3 | 9 | +200% |
| `menu.play` | 11 | 15 | +36% |
| `menu.settings` | 8 | 13 | +63% |
| `menu.jobs` | 4 | 8 | +100% |
| `jobs.title` | 4 | 8 | +100% |
| `job.verify` | 20 | 27 | +35% |
| `job.opened` | 26 | 37 | +42% |
| `verify.title` | 20 | 27 | +35% |
| `verify.card.id` | 17 | 23 | +35% |
| `verify.card.deed` | 4 | 19 | +375% |
| `verify.card.invoice` | 7 | 11 | +57% |
| `verify.card.police` | 15 | 22 | +47% |
| `verify.card.bailiff` | 7 | 18 | +157% |
| `settings.title` | 8 | 13 | +63% |
| `settings.haptics_intensity` | 15 | 22 | +47% |
| `settings.haptics_test` | 10 | 14 | +40% |
| `settings.haptics_calibration_two_clicks_yes` | 3 | 4 | +33% |
| `settings.haptics_calibration_two_clicks_none` | 9 | 13 | +44% |
| `settings.volume_ambience` | 8 | 14 | +75% |
| `settings.language_system` | 15 | 21 | +40% |
| `settings.wide_windows` | 13 | 19 | +46% |
| `settings.reset` | 14 | 23 | +64% |
| `settings.text_scale` | 9 | 16 | +78% |
| `settings.reduce_motion` | 13 | 17 | +31% |
| `run.lock_n` | 8 | 13 | +63% |
| `run.lives_left` | 11 | 17 | +55% |
| `run.finished` | 22 | 30 | +36% |
| `optics.loupe` | 19 | 34 | +79% |
| `optics.borescope` | 13 | 23 | +77% |
| `pause.settings` | 8 | 13 | +63% |
| `pause.restart` | 17 | 24 | +41% |
| `workshop.buy` | 3 | 7 | +133% |
| `workshop.repair` | 6 | 9 | +50% |
| `workshop.owned` | 5 | 9 | +80% |
| `workshop.integrity` | 14 | 20 | +43% |
| `workshop.broken` | 6 | 8 | +33% |
| `workshop.reward` | 19 | 25 | +32% |
| `dev.haptics_lab.title` | 11 | 22 | +100% |
| `dev.haptics_lab.force_fallback` | 12 | 21 | +75% |
| `dev.haptics_lab.caps` | 12 | 20 | +67% |
| `job.allotment_shed.client` | 35 | 53 | +51% |
| `job.allotment_shed.title` | 17 | 25 | +47% |
| `job.drummer_locker.client` | 34 | 48 | +41% |
| `job.newlyweds_4am.title` | 25 | 36 | +44% |
| `job.pizzeria_pays_pizza.title` | 13 | 18 | +38% |
| `job.refuse_ex_partner.client` | 60 | 86 | +43% |
| `job.refuse_ex_partner.situation` | 101 | 132 | +31% |
| `job.refuse_ex_partner.title` | 23 | 35 | +52% |
| `job.time_capsule.title` | 23 | 30 | +30% |
| `showcase.amen_padlock.title` | 18 | 32 | +78% |
| `showcase.egyptian_name.title` | 21 | 28 | +33% |
| `showcase.roman_wards.title` | 11 | 27 | +145% |
| `tool.pk_peg.name` | 10 | 16 | +60% |
| `tool.pk_hook.name` | 9 | 15 | +67% |
| `tool.pk_ward.name` | 10 | 19 | +90% |
| `tool.pk_lever.name` | 11 | 20 | +82% |
| `tool.pk_crown.name` | 10 | 14 | +40% |
| `tool.tl_polar.name` | 14 | 19 | +36% |
| `tool.pk_flag.name` | 9 | 17 | +89% |
| `tool.pk_plunger.name` | 12 | 17 | +42% |
| `tool.pk_disc.name` | 11 | 16 | +45% |
| `tool.tl_drill.name` | 5 | 9 | +80% |
| `cast.hall_manager.name` | 22 | 31 | +41% |
| `job.bramah_bureau.line.3` | 19 | 25 | +32% |
| `job.cat_bathroom.line.4` | 48 | 69 | +44% |
| `job.charleroi_letters.line.1` | 73 | 98 | +34% |
| `job.charleroi_letters.line.4` | 65 | 86 | +32% |
| `job.grandma_broth.line.4` | 62 | 81 | +31% |
| `job.krakow_tenement_gate.line.1` | 53 | 71 | +34% |
| `job.pizzeria_pays_pizza.line.2` | 48 | 67 | +40% |
| `job.pizzeria_pays_pizza.line.3` | 73 | 100 | +37% |
| `job.widow_bureau.line.4` | 40 | 60 | +50% |
| `tool.ob_microscope.name` | 16 | 22 | +38% |
| `ach.achievement.first_open.name` | 12 | 17 | +42% |
| `ach.achievement.false_note.desc` | 42 | 61 | +45% |
| `ach.achievement.after_overset.name` | 15 | 23 | +53% |
| `ach.achievement.counter_sense.name` | 16 | 22 | +38% |
| `ach.achievement.clean_receipt.name` | 8 | 17 | +113% |
| `ach.achievement.clean_receipt.desc` | 56 | 73 | +30% |
| `ach.achievement.hard_clean.name` | 16 | 29 | +81% |
| `ach.achievement.wafer_master.name` | 13 | 22 | +69% |
| `ach.achievement.pin_plain.desc` | 56 | 88 | +57% |
| `ach.achievement.first_gate.desc` | 40 | 56 | +40% |
| `ach.achievement.detector_return.desc` | 57 | 87 | +53% |
| `ach.achievement.ring_false.name` | 17 | 24 | +41% |
| `ach.achievement.ring_false.desc` | 35 | 55 | +57% |
| `ach.achievement.wooden_creak.name` | 15 | 21 | +40% |
| `ach.achievement.wooden_creak.desc` | 46 | 64 | +39% |
| `ach.achievement.iron_no_drop.desc` | 41 | 65 | +59% |
| `ach.achievement.lever_true.desc` | 37 | 57 | +54% |
| `ach.achievement.daily_lock.desc` | 47 | 62 | +32% |
| `ach.achievement.tool_care.name` | 16 | 21 | +31% |
| `ach.achievement.permission.desc` | 61 | 82 | +34% |
| `ach.achievement.first_no.name` | 12 | 21 | +75% |
| `ach.achievement.capsule.name` | 13 | 17 | +31% |
| `tip.feel_09` | 51 | 67 | +31% |
| `tip.calm_07` | 61 | 86 | +41% |
| `job.krystyna_wooden_album.line.4` | 42 | 60 | +43% |
| `job.krystyna_wooden_album.title` | 17 | 25 | +47% |
| `job.stefan_book_tin.client` | 49 | 65 | +33% |
| `job.stefan_book_tin.title` | 19 | 31 | +63% |

## Teksty wymagające dodatkowego sprawdzenia w layoucie

**Dialogi dłuższe niż 90 znaków (4):** `job.brussels_townhouse.line.3` (100), `job.charleroi_letters.line.1` (98), `job.night_nurse.line.2` (94), `job.pizzeria_pays_pizza.line.3` (100).

**Notatki dłuższe niż 130 znaków (1):** `job.finnish_sailor.note` (147).

## Co się nie udało / pozostaje do zrobienia

- **Nie przeprowadzono recenzji przez rodzimego użytkownika PT-BR** — pliki są szkicem zgodnie ze zleceniem, a nie finalną certyfikowaną lokalizacją.
- **Nie przeprowadzono renderowania ekranów i testów gry na urządzeniu**; trzeba ocenić teksty w prawdziwych szerokościach widoków i przetestować zawijanie.
- **Nie zmieniano plików produkcyjnych** `game/i18n/*` ani `store/listing.md`, zgodnie z zakresem zadania. Integracja do repozytorium aplikacji pozostaje po stronie właściciela.
- **Nie potwierdzono implementacji funkcji** obiecanych w istniejącym angielskim copy sklepowym (np. tryb „w ciemności”, kreda, wyzwanie czasowe, gablota). Zweryfikować przed publikacją, zgodnie z listą w `store/listing.md`.

## Wskazówki dla reviewera

W pierwszej kolejności sprawdzić: naturalność formy **você**, terminy **chaveiro / gazua / tensionador**, idiomy humorystyczne, historyczne nazwy własne i wygodę odczytu dialogów w małym rozmiarze UI. Dopuszczalne jest skracanie tłumaczeń bez zmiany sensu i parametrów. Oryginał EN pozostaje źródłem rozstrzygającym, PL pomaga przy dwuznacznościach.
