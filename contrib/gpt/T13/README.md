# T13 — lokalizacja hiszpańska (es-ES)

**Status:** kompletne tłumaczenie robocze do weryfikacji przez native speakera. Źródłem jest angielska wersja gry, z pomocniczym sprawdzaniem tekstów polskich. Nie dokonano zmian poza planowanym katalogiem `contrib/gpt/T13/`.

## Pliki

| Plik | Zawartość |
|---|---|
| `strings_es.csv` | 125/125 kluczy UI; format `key,es` |
| `content_es.csv` | 629/629 kluczy treści, dialogów, notek, osiągnięć i podpowiedzi; format `key,es` |
| `store_es.md` | Opisy App Store i Google Play po hiszpańsku, liczba znaków i bajtów przy każdym polu, wariant A oznaczony jako nieaktywny |
| `GLOSSARY_es.md` | 90 terminów EN–PL–ES, zasady stosowania i decyzja o formie zwracania się do gracza |
| `README.md` | Niniejszy raport QA i pełna lista ryzyk długości |

## Wybory językowe

W interfejsie stosujemy **tú** (forma bezpośrednia w liczbie pojedynczej). To neutralne dla europejskiego odbiorcy gier mobilnych i pasuje do osobistego tonu opowieści. W dialogach z osobami starszymi i klientami może pojawiać się **usted**, gdy wynika to z sytuacji. Bez regionalnego `vos`, bez slangu złodziejskiego. W fikcyjnych mechanizmach: `tension wrench` → **tensor**, `pick` → **ganzúa**, `pin` → **perno**, `shear line` → **línea de corte**, `false set` → **falso asentamiento**, `overset` → **sobrelevación**. Drewniany pin historyczny to `pasador de madera`.

## Walidacja

- **Kompletność:** UI 125/125, treść 629/629, łącznie **754 / 754**; zachowana kolejność i tożsamość kluczy, bez duplikatów i pustych tłumaczeń.
- **Wzorce dynamiczne:** wszystkie placeholdery `{n}`, `{0}` itd. zgodne ze źródłem EN.
- **Limity biblii narracyjnej:** wszystkie dialogi `job.*.line.*` mają maksymalnie **90 znaków**, a wpisy `*.note` i `notebook.*` — maksymalnie **130 znaków**.
- **Metadane sklepowe:** każde z 12 pól głównych i 2 wariantów złożonych mieści się w limicie; tytuł **30/30** znaków, podtytuł **26/30**, tekst promocyjny **169/170**, słowa kluczowe **79/100 bajtów UTF-8**, krótki opis Google Play **75/80** znaków. Nazwa App Store/Play jest wspólna.
- **Model biznesowy:** decyzja D-06 pozostaje otwarta, a D-51 zabrania obiecywania ceny, terminu premiery i dostępności. Wariant A jest wyraźnie opcjonalny; w żadnym aktywnym tekście nie pada cena ani data.
- **Zakres bezpieczny:** role ślusarza i weryfikacja prawa wejścia pozostają wyraźne; nazwy historycznych wynalazców w notkach gabloty nie są instrukcjami otwierania realnych wyrobów.

### Limity sklepów — podsumowanie

| Pole | Znaki | Bajty UTF-8 | Limit |
|---|---:|---:|---:|
| `as.es.name` | 30 | 30 | 30 |
| `as.es.subtitle` | 26 | 27 | 30 |
| `as.es.promo` | 169 | 172 | 170 |
| `as.es.keywords` | 76 | 79 | 100 |
| `as.es.description` | 2074 | 2124 | 4000 |
| `as.es.variant_a` | 137 | 139 | 4000 |
| `as.es.whatsnew` | 137 | 143 | 4000 |
| `gp.es.title` | 30 | 30 | 30 |
| `gp.es.short` | 75 | 76 | 80 |
| `gp.es.haptics_line` | 166 | 174 | 4000 |
| `gp.es.description` | 2097 | 2147 | 4000 |
| `gp.es.whatsnew` | 137 | 143 | 500 |

## Ryzyko niezmieszczenia się w UI: tekst ES dłuższy od EN o ponad 30%

**Kryterium:** `len(ES) > 1,30 × len(EN)`, znaki Unicode, nie bajty; porównywane są kompletne wartości tekstowe, nie klucze. Lista obejmuje również krótkie etykiety, gdzie procent względny bywa bardzo wysoki. Ryzyko nie oznacza automatycznie przekroczenia faktycznej szerokości kontrolki — należy sprawdzić makiety i typografię na urządzeniach.

### Interfejs — 45 kluczy

| Klucz | EN | ES | Zmiana |
|---|---:|---:|---:|
| `boot.calib_none` | 4 | 7 | +75.0% |
| `boot.calib_skip` | 4 | 6 | +50.0% |
| `settings.feel_section` | 14 | 21 | +50.0% |
| `settings.quality_low` | 18 | 24 | +33.3% |
| `about.post_release_unlocked` | 34 | 49 | +44.1% |
| `settings.report_problem` | 16 | 23 | +43.8% |
| `settings.report_empty` | 13 | 23 | +76.9% |
| `common.on` | 2 | 8 | +300.0% |
| `common.off` | 3 | 11 | +266.7% |
| `common.coins` | 5 | 7 | +40.0% |
| `menu.jobs` | 4 | 8 | +100.0% |
| `jobs.title` | 4 | 8 | +100.0% |
| `job.verify` | 20 | 28 | +40.0% |
| `job.opened` | 26 | 34 | +30.8% |
| `job.reward_fmt` | 17 | 23 | +35.3% |
| `verify.title` | 20 | 28 | +40.0% |
| `verify.card.lease` | 15 | 20 | +33.3% |
| `verify.card.deed` | 4 | 22 | +450.0% |
| `verify.card.police` | 15 | 21 | +40.0% |
| `verify.card.bailiff` | 7 | 15 | +114.3% |
| `settings.haptics_test` | 10 | 15 | +50.0% |
| `settings.volume_sfx` | 13 | 17 | +30.8% |
| `settings.volume_ambience` | 8 | 15 | +87.5% |
| `settings.language_system` | 15 | 22 | +46.7% |
| `settings.wide_windows` | 13 | 20 | +53.8% |
| `settings.reset` | 14 | 19 | +35.7% |
| `settings.text_scale` | 9 | 16 | +77.8% |
| `settings.reduce_motion` | 13 | 18 | +38.5% |
| `settings.dark_mode_note` | 51 | 68 | +33.3% |
| `run.lock_n` | 8 | 13 | +62.5% |
| `run.lives_left` | 11 | 19 | +72.7% |
| `run.rubber_band` | 35 | 50 | +42.9% |
| `optics.loupe` | 19 | 28 | +47.4% |
| `optics.borescope` | 13 | 18 | +38.5% |
| `pause.title` | 6 | 8 | +33.3% |
| `pause.resume` | 6 | 8 | +33.3% |
| `pause.restart` | 17 | 24 | +41.2% |
| `pause.quit` | 14 | 21 | +50.0% |
| `workshop.coins` | 5 | 7 | +40.0% |
| `workshop.buy` | 3 | 7 | +133.3% |
| `workshop.owned` | 5 | 12 | +140.0% |
| `workshop.integrity` | 14 | 24 | +71.4% |
| `workshop.repair_cost` | 17 | 23 | +35.3% |
| `dev.haptics_lab.title` | 11 | 22 | +100.0% |
| `dev.haptics_lab.force_fallback` | 12 | 16 | +33.3% |

### Treści — 100 kluczy

| Klucz | EN | ES | Zmiana |
|---|---:|---:|---:|
| `job.allotment_shed.client` | 35 | 48 | +37.1% |
| `job.allotment_shed.title` | 17 | 30 | +76.5% |
| `job.charleroi_letters.client` | 67 | 89 | +32.8% |
| `job.dollhouse_wooden_lock.situation` | 127 | 174 | +37.0% |
| `job.drummer_locker.client` | 34 | 50 | +47.1% |
| `job.drummer_locker.situation` | 110 | 159 | +44.5% |
| `job.finnish_sailor.client` | 63 | 89 | +41.3% |
| `job.kiosk_shutter.title` | 20 | 28 | +40.0% |
| `job.krakow_antiquarian.client` | 28 | 44 | +57.1% |
| `job.liege_bakery.situation` | 122 | 165 | +35.2% |
| `job.liege_bakery.title` | 18 | 25 | +38.9% |
| `job.museum_time_lock.situation` | 110 | 169 | +53.6% |
| `job.night_nurse.client` | 64 | 97 | +51.6% |
| `job.night_nurse.title` | 25 | 33 | +32.0% |
| `job.refuse_ex_partner.title` | 23 | 33 | +43.5% |
| `job.refuse_rush_bribe.situation` | 125 | 165 | +32.0% |
| `job.student_dorm.situation` | 118 | 163 | +38.1% |
| `job.student_dorm.title` | 8 | 14 | +75.0% |
| `job.swiatniki_journeyman_padlock.client` | 67 | 99 | +47.8% |
| `job.time_capsule.title` | 23 | 30 | +30.4% |
| `job.uncle_safe_heirs.title` | 19 | 29 | +52.6% |
| `job.widow_bureau.client` | 53 | 73 | +37.7% |
| `showcase.amen_padlock.title` | 18 | 33 | +83.3% |
| `showcase.barron_1778.title` | 28 | 38 | +35.7% |
| `showcase.roman_wards.title` | 11 | 19 | +72.7% |
| `showcase.swiatniki_armourers.title` | 23 | 31 | +34.8% |
| `tool.pk_peg.name` | 10 | 19 | +90.0% |
| `tool.pk_hook.name` | 9 | 16 | +77.8% |
| `tool.pk_ward.name` | 10 | 16 | +60.0% |
| `tool.pk_ripple.name` | 11 | 15 | +36.4% |
| `tool.pk_lever.name` | 11 | 20 | +81.8% |
| `tool.pk_crown.name` | 10 | 16 | +60.0% |
| `tool.pk_flag.name` | 9 | 17 | +88.9% |
| `tool.pk_plunger.name` | 12 | 16 | +33.3% |
| `tool.pk_disc.name` | 11 | 17 | +54.5% |
| `tool.tl_notes.name` | 16 | 21 | +31.3% |
| `tool.tl_drill.name` | 5 | 7 | +40.0% |
| `cast.hall_manager.name` | 22 | 29 | +31.8% |
| `cast.irena.name` | 9 | 12 | +33.3% |
| `cast.mietek.name` | 9 | 12 | +33.3% |
| `cast.rygiel.name` | 14 | 19 | +35.7% |
| `cast.stefan.name` | 9 | 12 | +33.3% |
| `cast.waldek.name` | 9 | 12 | +33.3% |
| `cast.wanda.name` | 9 | 12 | +33.3% |
| `cast.zosia.name` | 9 | 12 | +33.3% |
| `job.allotment_shed.note` | 84 | 111 | +32.1% |
| `job.bike_interview.line.4` | 38 | 53 | +39.5% |
| `job.bramah_bureau.line.1` | 62 | 83 | +33.9% |
| `job.charleroi_letters.line.4` | 65 | 89 | +36.9% |
| `job.drummer_locker.line.1` | 63 | 83 | +31.7% |
| `job.pizzeria_pays_pizza.line.2` | 48 | 74 | +54.2% |
| `job.widow_bureau.line.3` | 37 | 54 | +45.9% |
| `ach.achievement.first_open.name` | 12 | 18 | +50.0% |
| `ach.achievement.pin_school.desc` | 39 | 52 | +33.3% |
| `ach.achievement.wafer_school.name` | 15 | 20 | +33.3% |
| `ach.achievement.wafer_school.desc` | 38 | 53 | +39.5% |
| `ach.achievement.false_note.desc` | 42 | 60 | +42.9% |
| `ach.achievement.after_drop.name` | 14 | 19 | +35.7% |
| `ach.achievement.after_overset.name` | 15 | 23 | +53.3% |
| `ach.achievement.counter_sense.name` | 16 | 25 | +56.3% |
| `ach.achievement.hard_clean.name` | 16 | 31 | +93.8% |
| `ach.achievement.wafer_master.name` | 13 | 22 | +69.2% |
| `ach.achievement.pin_plain.desc` | 56 | 87 | +55.4% |
| `ach.achievement.first_gate.desc` | 40 | 55 | +37.5% |
| `ach.achievement.detector_return.name` | 14 | 19 | +35.7% |
| `ach.achievement.ring_false.desc` | 35 | 57 | +62.9% |
| `ach.achievement.wooden_creak.name` | 15 | 21 | +40.0% |
| `ach.achievement.wooden_creak.desc` | 46 | 62 | +34.8% |
| `ach.achievement.iron_no_drop.name` | 13 | 19 | +46.2% |
| `ach.achievement.lever_true.desc` | 37 | 56 | +51.4% |
| `ach.achievement.dark_clean.name` | 12 | 16 | +33.3% |
| `ach.achievement.daily_lock.name` | 12 | 16 | +33.3% |
| `ach.achievement.daily_lock.desc` | 47 | 70 | +48.9% |
| `ach.achievement.timed_care.name` | 16 | 24 | +50.0% |
| `ach.achievement.tool_care.name` | 16 | 24 | +50.0% |
| `ach.achievement.permission.name` | 15 | 22 | +46.7% |
| `ach.achievement.witness.name` | 19 | 25 | +31.6% |
| `ach.achievement.bribe.name` | 20 | 27 | +35.0% |
| `ach.achievement.heirs.desc` | 52 | 81 | +55.8% |
| `ach.achievement.capsule.name` | 13 | 17 | +30.8% |
| `tip.ethics_01` | 51 | 67 | +31.4% |
| `tip.ethics_04` | 67 | 90 | +34.3% |
| `tip.feel_03` | 53 | 71 | +34.0% |
| `tip.feel_05` | 57 | 80 | +40.4% |
| `tip.feel_11` | 56 | 75 | +33.9% |
| `tip.people_04` | 54 | 76 | +40.7% |
| `tip.calm_07` | 61 | 84 | +37.7% |
| `notebook.extra.ring_clicks` | 71 | 96 | +35.2% |
| `job.community_notice_case.client` | 70 | 92 | +31.4% |
| `job.community_notice_case.line.4` | 48 | 70 | +45.8% |
| `job.gosia_workbench_drawer.title` | 20 | 29 | +45.0% |
| `job.halina_recipe_box.client` | 44 | 59 | +34.1% |
| `job.krystyna_wooden_album.situation` | 117 | 173 | +47.9% |
| `job.krystyna_wooden_album.title` | 17 | 25 | +47.1% |
| `job.marta_poster_studio.line.3` | 56 | 75 | +33.9% |
| `job.refuse_sisters_flat.note` | 86 | 114 | +32.6% |
| `job.refuse_unapproved_stockroom.client` | 53 | 75 | +41.5% |
| `job.roman_service_cupboard.client` | 44 | 64 | +45.5% |
| `job.stefan_book_tin.client` | 49 | 79 | +61.2% |
| `job.stefan_book_tin.title` | 19 | 26 | +36.8% |

Łącznie **145** kluczy wymaga kontroli długości w docelowym układzie. Najbardziej narażone są: przyciski i etykiety jedno-/dwuwyrazowe, nazwy narzędzi, tytuły osiągnięć i notek oraz karty krótkich zleceń. W pierwszej kolejności sprawdzić `common.on`, `common.off`, `verify.card.deed`, `workshop.owned` i `tool.pk_peg.name`.

## Niewykonane / do przeglądu

1. **Wymagany przegląd native speakera es-ES** — szczególnie tytuł `Cerrajero de turno`, nazewnictwo techniczne, belgijskie realia oraz naturalność dialogów.
2. **Nie wykonano testu renderowania UI w Godot ani testu interfejsu na małych ekranach.** Lista powyżej jest automatycznym sygnałem ryzyka, a nie wynikiem pomiaru szerokości tekstu.
3. **Nie publikowano metadanych w sklepach.** Przed publikacją należy potwierdzić zgodność obietnic funkcjonalnych i prywatności z implementacją 1.0 oraz wybrać model biznesowy (D-06).
4. **Nie zmieniono plików bazowych gry ani sklepu.** Dodanie ES jako aktywnego języka do loadera i18n pozostaje osobnym zadaniem właściciela/zespołu.

**Pliki źródłowe:** `game/i18n/strings.csv` (SHA blob `b50865b3b3556106a7b315c3004bc675c67c473d`), `game/i18n/content.csv` (`680e248e3ca36d02c275ddf9afef7c0800b6548c`), `store/listing.md` (`3e29d4bf8706802defce325469f6417f665fb291`). Opracowanie: 2026-11-05.
