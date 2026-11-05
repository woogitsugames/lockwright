# T12 — raport lokalizacji francuskiej

**Status:** tłumaczenie przygotowane jako szkic do przeglądu przez native speakera, bez zmian poza `contrib/gpt/T12/`.

## Zakres i pliki

| Plik | Zawartość | Wynik |
|---|---|---|
| `strings_fr.csv` | Interfejs (`key,fr`) | **125/125** kluczy |
| `content_fr.csv` | Fabuła, zlecenia, dialogi, gablota, osiągnięcia, wskazówki (`key,fr`) | **629/629** kluczy |
| `store_fr.md` | App Store i Google Play: FR/BE, wariant A tylko warunkowo | Pola w limitach |
| `GLOSSARY_fr.md` | Słownik EN–PL–FR i reguły grzecznościowe | **84** terminów |
| `README.md` | Ten raport, QA i pełna lista ryzyk długości | Zapisano |

Łącznie: **754 / 754 kluczy przetłumaczonych**. Kolejność kluczy źródłowych zachowana. Tłumaczono z angielskiego, w razie potrzeby korzystając z polskiego kontekstu.

## Decyzje językowe

- Forma wobec gracza: **`vous`**, neutralna płciowo i właściwa w relacji ślusarz–klient w Belgii i Francji; bezokoliczniki na przyciskach. Dialogi bliskich sobie bohaterów mogą używać `tu`.
- `tendeur` (napinacz), `crochet` (wytrych), `goupille` (pin), `ligne de césure` (linia podziału), `faux placement` (fałszywe osadzenie), `surélévation` (przepchnięcie), `rotor` (rdzeń).
- Brak współczesnych marek mechanizmów lub wskazówek dotyczących realnych produktów. Zachowano własne imiona i historyczne odniesienia zgodnie ze źródłem.
- Francuski tytuł sklepowy **`Lockwright: Serrurier de garde`** ma 30 znaków. Zapis dwukropka bez typograficznej spacji to świadomy kompromis z limitem Apple/Google.

## Kontrole automatyczne

- Brak pominiętych, pustych i dodatkowych kluczy; brak powtórzonych kluczy w plikach źródłowych i wynikowych.
- Żadna zmienna `{n}` ani `{0}` nie została zgubiona lub zmieniona.
- **0 dialogów FR dłuższych niż 90 znaków** po korekcie.
- Opisy App Store i Google Play nie przekraczają limitów: tytuł 30, podtytuł 30, promo 170, opis krótszy niż 4000, krótki opis Play 80; słowa kluczowe Apple 85/100 bajtów. Długości i bajty podane przy każdym polu w `store_fr.md`.
- **185 kluczy** ma wariant francuski dłuższy od angielskiego o ponad 30% (51 UI + 134 content). Wszystkie wymieniono niżej; nie oznacza to automatycznego błędu, ale wymaga testu ekranów.

## Co nie zostało wykonane / pozostaje do sprawdzenia

1. Nie zmieniano `game/i18n/strings.csv`, `game/i18n/content.csv`, konfiguracji Godot ani sklepu: **zakaz pracy poza katalogiem T12**. Integracja FR wymaga osobnego zadania, w tym dopisania `settings.language_fr`, locale i testów fontów/podziału linii.
2. Native speaker z Francji lub Belgii powinien przejrzeć styl dialogów, regionalizmy i terminologię `faux placement`, `surélévation`, `encoche de passage`. Przy dialogach zachowano maks. 90 znaków; nadal wymagany test urządzeń i czytników ekranu.
3. Model biznesowy **D-06 pozostaje otwarty**, zgodnie z **D-51**. Wariant A w `store_fr.md` jest opcjonalny, **nie do publikacji bez decyzji właściciela**. Nie zadeklarowano ceny, daty premiery ani dostępności.
4. Twierdzenia w opisach sklepowych (tryb offline, brak reklam, gablota, kreska kredowa, tryb czasowy, prywatność) wymagają potwierdzenia względem ostatecznego zakresu 1.0 przed wysyłką metadanych.
5. Test wizualny gry w ekranach pionowym i poziomym nie jest dostępny w ramach tego zlecenia; klucze ryzyka poniżej wymagają sprawdzenia w UI.

## Lista ryzyk długości: FR większe niż EN o ponad 30%

Wartości liczone jako liczba znaków Unicode (nie bajtów); klucze krótkie mogą przekroczyć próg z powodu odmiany francuskiej.

### Interfejs (51 kluczy)

| Klucz | EN | FR | Przyrost |
|---|---:|---:|---:|
| `boot.calib_title` | 54 | 84 | +56% |
| `boot.calib_two` | 3 | 4 | +33% |
| `boot.calib_none` | 4 | 6 | +50% |
| `boot.calib_skip` | 4 | 6 | +50% |
| `settings.feel_section` | 14 | 28 | +100% |
| `settings.quality_high` | 4 | 6 | +50% |
| `settings.quality_low` | 18 | 25 | +39% |
| `settings.report_empty` | 13 | 20 | +54% |
| `common.back` | 4 | 6 | +50% |
| `common.on` | 2 | 6 | +200% |
| `common.off` | 3 | 9 | +200% |
| `menu.play` | 11 | 19 | +73% |
| `menu.jobs` | 4 | 13 | +225% |
| `jobs.title` | 4 | 13 | +225% |
| `job.refuse` | 15 | 22 | +47% |
| `job.reward_fmt` | 17 | 23 | +35% |
| `job.tip_fmt` | 30 | 42 | +40% |
| `verify.ask_more` | 21 | 30 | +43% |
| `verify.card.deed` | 4 | 17 | +325% |
| `verify.card.receipt` | 7 | 16 | +129% |
| `verify.card.police` | 15 | 25 | +67% |
| `verify.card.bailiff` | 7 | 19 | +171% |
| `verify.refused` | 39 | 58 | +49% |
| `tutorial.title` | 24 | 33 | +38% |
| `settings.haptics` | 7 | 15 | +114% |
| `settings.haptics_enabled` | 15 | 22 | +47% |
| `settings.haptics_test` | 10 | 17 | +70% |
| `settings.haptics_calibration_two_clicks_yes` | 3 | 4 | +33% |
| `settings.volume_ambience` | 8 | 15 | +88% |
| `settings.language_system` | 15 | 20 | +33% |
| `settings.language_de` | 13 | 23 | +77% |
| `settings.wide_windows` | 13 | 17 | +31% |
| `settings.reset` | 14 | 28 | +100% |
| `settings.text_scale` | 9 | 15 | +67% |
| `settings.reduce_motion` | 13 | 22 | +69% |
| `settings.dark_mode_note` | 51 | 73 | +43% |
| `run.lock_n` | 8 | 11 | +38% |
| `run.lives_left` | 11 | 20 | +82% |
| `run.rubber_band` | 35 | 59 | +69% |
| `optics.loupe` | 19 | 32 | +68% |
| `optics.borescope` | 13 | 25 | +92% |
| `pause.title` | 6 | 8 | +33% |
| `pause.resume` | 6 | 9 | +50% |
| `pause.restart` | 17 | 25 | +47% |
| `workshop.buy` | 3 | 7 | +133% |
| `workshop.owned` | 5 | 7 | +40% |
| `workshop.repair_cost` | 17 | 23 | +35% |
| `workshop.reward` | 19 | 25 | +32% |
| `dev.haptics_lab.title` | 11 | 20 | +82% |
| `dev.haptics_lab.tier` | 4 | 6 | +50% |
| `dev.haptics_lab.force_fallback` | 12 | 25 | +108% |

### Treść (134 kluczy)

| Klucz | EN | FR | Przyrost |
|---|---:|---:|---:|
| `job.cat_bathroom.title` | 22 | 29 | +32% |
| `job.dollhouse_wooden_lock.situation` | 127 | 182 | +43% |
| `job.dollhouse_wooden_lock.title` | 25 | 44 | +76% |
| `job.drummer_locker.client` | 34 | 48 | +41% |
| `job.drummer_locker.situation` | 110 | 150 | +36% |
| `job.finnish_sailor.client` | 63 | 83 | +32% |
| `job.grandpa_chest.situation` | 116 | 154 | +33% |
| `job.grandpa_chest.title` | 21 | 28 | +33% |
| `job.kiosk_shutter.title` | 20 | 27 | +35% |
| `job.krakow_antiquarian.client` | 28 | 37 | +32% |
| `job.krakow_antiquarian.situation` | 112 | 146 | +30% |
| `job.liege_bakery.title` | 18 | 30 | +67% |
| `job.newlyweds_4am.title` | 25 | 40 | +60% |
| `job.pizzeria_pays_pizza.title` | 13 | 18 | +38% |
| `job.refuse_aunt_alive.situation` | 112 | 148 | +32% |
| `job.refuse_ex_partner.situation` | 101 | 132 | +31% |
| `job.refuse_ex_partner.title` | 23 | 34 | +48% |
| `job.refuse_rush_bribe.client` | 49 | 69 | +41% |
| `job.student_dorm.situation` | 118 | 160 | +36% |
| `job.student_dorm.title` | 8 | 11 | +38% |
| `job.swiatniki_journeyman_padlock.client` | 67 | 93 | +39% |
| `job.time_capsule.title` | 23 | 30 | +30% |
| `job.uncle_safe_heirs.situation` | 127 | 179 | +41% |
| `job.uncle_safe_heirs.title` | 19 | 32 | +68% |
| `job.widow_bureau.client` | 53 | 71 | +34% |
| `job.wrong_floor.situation` | 39 | 52 | +33% |
| `showcase.amen_padlock.title` | 18 | 25 | +39% |
| `showcase.chubb_detector.title` | 19 | 29 | +53% |
| `showcase.roman_wards.title` | 11 | 23 | +109% |
| `tool.pk_hook.name` | 9 | 13 | +44% |
| `tool.pk_ward.name` | 10 | 18 | +80% |
| `tool.pk_lever.name` | 11 | 19 | +73% |
| `tool.pk_crown.name` | 10 | 16 | +60% |
| `tool.pk_flag.name` | 9 | 15 | +67% |
| `tool.pk_plunger.name` | 12 | 16 | +33% |
| `tool.pk_feather.name` | 12 | 16 | +33% |
| `tool.tl_cup.name` | 13 | 17 | +31% |
| `tool.tl_drill.name` | 5 | 8 | +60% |
| `cast.captain.name` | 7 | 12 | +71% |
| `cast.claimant.name` | 17 | 24 | +41% |
| `cast.hall_manager.name` | 22 | 40 | +82% |
| `cast.headteacher.name` | 16 | 23 | +44% |
| `cast.irena.name` | 9 | 12 | +33% |
| `cast.kazimierz.name` | 12 | 18 | +50% |
| `cast.leopold.name` | 10 | 16 | +60% |
| `cast.locksmith.name` | 9 | 12 | +33% |
| `cast.mietek.name` | 9 | 15 | +67% |
| `cast.roman.name` | 26 | 36 | +38% |
| `cast.stefan.name` | 9 | 15 | +67% |
| `cast.stranger.name` | 13 | 18 | +38% |
| `cast.waldek.name` | 9 | 15 | +67% |
| `cast.wanda.name` | 9 | 12 | +33% |
| `cast.wladyslaw.name` | 12 | 18 | +50% |
| `cast.zbyszek.name` | 10 | 16 | +60% |
| `cast.zosia.name` | 9 | 12 | +33% |
| `job.bike_interview.line.4` | 38 | 64 | +68% |
| `job.bramah_bureau.line.3` | 19 | 31 | +63% |
| `job.cat_bathroom.note` | 94 | 132 | +40% |
| `job.dollhouse_wooden_lock.line.2` | 66 | 86 | +30% |
| `job.dollhouse_wooden_lock.note` | 105 | 152 | +45% |
| `job.finnish_sailor.line.2` | 62 | 87 | +40% |
| `job.ghent_beguinage.line.1` | 51 | 68 | +33% |
| `job.ghent_beguinage.line.2` | 25 | 34 | +36% |
| `job.grandma_broth.line.1` | 56 | 73 | +30% |
| `job.grandma_broth.line.4` | 62 | 81 | +31% |
| `job.krakow_antiquarian.line.3` | 53 | 75 | +42% |
| `job.museum_time_lock.line.3` | 54 | 78 | +44% |
| `job.newlyweds_4am.line.1` | 68 | 90 | +32% |
| `job.refuse_aunt_alive.after.2` | 53 | 70 | +32% |
| `job.refuse_ex_partner.after.2` | 54 | 75 | +39% |
| `job.refuse_rush_bribe.note` | 88 | 115 | +31% |
| `job.student_dorm.line.1` | 67 | 88 | +31% |
| `job.swiatniki_journeyman_padlock.line.1` | 67 | 88 | +31% |
| `job.time_capsule.line.1` | 38 | 51 | +34% |
| `job.time_capsule.line.2` | 56 | 73 | +30% |
| `job.time_capsule.line.3` | 58 | 76 | +31% |
| `job.widow_bureau.line.3` | 37 | 55 | +49% |
| `job.wrong_floor.line.4` | 47 | 63 | +34% |
| `notebook.rule.1` | 45 | 69 | +53% |
| `notebook.rule.4` | 54 | 72 | +33% |
| `notebook.rule.5` | 31 | 49 | +58% |
| `ach.achievement.first_open.name` | 12 | 17 | +42% |
| `ach.achievement.first_open.desc` | 42 | 56 | +33% |
| `ach.achievement.pin_school.name` | 13 | 21 | +62% |
| `ach.achievement.pin_school.desc` | 39 | 55 | +41% |
| `ach.achievement.wafer_school.desc` | 38 | 56 | +47% |
| `ach.achievement.false_note.desc` | 42 | 69 | +64% |
| `ach.achievement.counter_sense.name` | 16 | 23 | +44% |
| `ach.achievement.steel_warning.name` | 17 | 26 | +53% |
| `ach.achievement.clean_receipt.desc` | 56 | 73 | +30% |
| `ach.achievement.hard_clean.name` | 16 | 25 | +56% |
| `ach.achievement.wafer_master.name` | 13 | 21 | +62% |
| `ach.achievement.pin_plain.desc` | 56 | 79 | +41% |
| `ach.achievement.first_gate.desc` | 40 | 71 | +77% |
| `ach.achievement.detector_return.name` | 14 | 19 | +36% |
| `ach.achievement.detector_return.desc` | 57 | 84 | +47% |
| `ach.achievement.ring_false.desc` | 35 | 53 | +51% |
| `ach.achievement.wooden_creak.desc` | 46 | 74 | +61% |
| `ach.achievement.iron_no_drop.desc` | 41 | 59 | +44% |
| `ach.achievement.lever_true.desc` | 37 | 49 | +32% |
| `ach.achievement.first_dark.name` | 19 | 25 | +32% |
| `ach.achievement.dark_clean.name` | 12 | 21 | +75% |
| `ach.achievement.one_pick.name` | 15 | 23 | +53% |
| `ach.achievement.daily_lock.name` | 12 | 16 | +33% |
| `ach.achievement.timed_care.name` | 16 | 24 | +50% |
| `ach.achievement.tool_care.name` | 16 | 22 | +38% |
| `ach.achievement.partial_refusal.name` | 18 | 28 | +56% |
| `ach.achievement.museum_papers.name` | 13 | 20 | +54% |
| `ach.achievement.kazimierz.name` | 12 | 16 | +33% |
| `ach.achievement.capsule.name` | 13 | 17 | +31% |
| `tip.ethics_01` | 51 | 71 | +39% |
| `tip.ethics_02` | 73 | 104 | +42% |
| `tip.feel_05` | 57 | 77 | +35% |
| `tip.workshop_02` | 67 | 92 | +37% |
| `tip.workshop_05` | 52 | 68 | +31% |
| `tip.workshop_08` | 56 | 87 | +55% |
| `tip.calm_07` | 61 | 90 | +48% |
| `tip.calm_08` | 52 | 72 | +38% |
| `notebook.extra.wafer_rattle` | 72 | 94 | +31% |
| `cast.elzbieta.name` | 26 | 36 | +38% |
| `job.community_notice_case.line.4` | 48 | 75 | +56% |
| `job.edek_rehearsal_store.line.4` | 59 | 78 | +32% |
| `job.edek_rehearsal_store.title` | 20 | 30 | +50% |
| `job.krystyna_wooden_album.line.1` | 61 | 80 | +31% |
| `job.krystyna_wooden_album.line.4` | 42 | 60 | +43% |
| `job.krystyna_wooden_album.title` | 17 | 26 | +53% |
| `job.marta_poster_studio.line.3` | 56 | 75 | +34% |
| `job.marta_poster_studio.title` | 23 | 30 | +30% |
| `job.refuse_sisters_flat.note` | 86 | 116 | +35% |
| `job.roman_service_cupboard.client` | 44 | 67 | +52% |
| `job.shared_room_door.title` | 19 | 28 | +47% |
| `job.stefan_book_tin.client` | 49 | 86 | +76% |
| `job.stefan_book_tin.line.1` | 56 | 76 | +36% |
| `job.stefan_book_tin.title` | 19 | 27 | +42% |
