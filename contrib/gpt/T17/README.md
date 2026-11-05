# T17 — szkic lokalizacji ukraińskiej (uk-UA)

**Data:** 2026-11-05  
**Status:** komplet tłumaczeń do recenzji przez native speakera.  
**Repo / gałąź:** `woogitsugames/lockwright`, `main`.  
**Zakres zapisu:** wyłącznie `contrib/gpt/T17/`.

## Co zrobiono

- Przetłumaczono z EN, z kontrolą PL, **125/125** kluczy interfejsu i **629/629** kluczy treści (łącznie **754/754 — 100%**).
- Zachowano oryginalne klucze, kolejność i symbole zastępcze (`{n}`, `{0}`). CSV mają nagłówki dokładnie `key,uk` i kodowanie UTF-8.
- Przygotowano **12 pól sklepowych UK**, w tym wersje App Store i Google Play; wszystkie mieszczą się w limitach określonych w `store/listing.md` (słowa kluczowe App Store liczone w bajtach UTF-8). Wersja A jest **wyłącznie warunkowa** i nie może być publikowana przed decyzją D-06.
- Uzgodniono **81 haseł słowniczka** z konsekwentnym użyciem m.in. `натягувач`, `відмичка`, `штифт`, `лінія розділу`, `хибне встановлення`, `надмірне підняття`.
- Zalecana forma kontaktu z graczem: **grzecznościowe „ви” (małą literą)**, czasowniki w liczbie mnogiej. Krótkie przyciski pozostają bezosobowe. Dialogi zachowują własny rejestr postaci; zeszyt narratora ma osobny głos.
- Automatycznie sprawdzono brak brakujących/zdublowanych kluczy, niepuste tłumaczenia, identyczne placeholdery, limity sklepu i listę przyrostów długości. Po redakcji kontrolnej maksymalny dialog ma **90** znaków (limit narracyjny 90), a wpis zeszytu **126** (limit 130).

## Pliki

| Plik | Zawartość |
|---|---|
| `strings_uk.csv` | 125 kluczy UI, kolumny `key,uk` |
| `content_uk.csv` | 629 kluczy treści, kolumny `key,uk` |
| `store_uk.md` | Opisy sklepowe UK z liczbą znaków przy każdym polu, wersje App Store / Google Play |
| `GLOSSARY_uk.md` | 81 terminów EN–PL–UK, zalecenia językowe |
| `README.md` | Ten raport i lista ryzyk długości |

## Ryzyka długości — >30% względem EN

Porównanie liczby znaków Unicode w każdym oryginalnym polu EN i UK: **44 klucze UI i 44 klucze treści** (łącznie **88**). Krótkie etykiety z EN mogą mieć wysoki przyrost procentowy mimo niewielkiej liczby znaków UK. To **lista do kontroli wizualnej**, nie dowód przepełnienia widoku.

| Plik | Klucz | EN | UK | Przyrost |
|---|---|---:|---:|---:|
| strings | `boot.calib_one` | 3 | 4 | +33% |
| strings | `boot.calib_none` | 4 | 7 | +75% |
| strings | `boot.calib_skip` | 4 | 10 | +150% |
| strings | `settings.feel_section` | 14 | 28 | +100% |
| strings | `settings.quality_auto` | 15 | 22 | +47% |
| strings | `settings.quality_high` | 4 | 6 | +50% |
| strings | `settings.quality_low` | 18 | 30 | +67% |
| strings | `settings.report_problem` | 16 | 23 | +44% |
| strings | `common.close` | 5 | 7 | +40% |
| strings | `common.on` | 2 | 9 | +350% |
| strings | `common.off` | 3 | 8 | +167% |
| strings | `menu.settings` | 8 | 12 | +50% |
| strings | `menu.jobs` | 4 | 10 | +150% |
| strings | `jobs.title` | 4 | 10 | +150% |
| strings | `verify.card.deed` | 4 | 28 | +600% |
| strings | `verify.card.invoice` | 7 | 15 | +114% |
| strings | `verify.card.bailiff` | 7 | 18 | +157% |
| strings | `settings.title` | 8 | 12 | +50% |
| strings | `settings.haptics` | 7 | 17 | +143% |
| strings | `settings.haptics_enabled` | 15 | 27 | +80% |
| strings | `settings.haptics_intensity` | 15 | 24 | +60% |
| strings | `settings.haptics_test` | 10 | 15 | +50% |
| strings | `settings.haptics_calibration_two_clicks_one` | 3 | 4 | +33% |
| strings | `settings.volume_ambience` | 8 | 14 | +75% |
| strings | `settings.language_pl` | 6 | 8 | +33% |
| strings | `settings.language_en` | 7 | 10 | +43% |
| strings | `settings.language_de` | 13 | 19 | +46% |
| strings | `settings.dark_mode_assist` | 13 | 20 | +54% |
| strings | `settings.reset` | 14 | 20 | +43% |
| strings | `settings.text_scale` | 9 | 13 | +44% |
| strings | `settings.dark_mode_note` | 51 | 72 | +41% |
| strings | `run.title` | 13 | 17 | +31% |
| strings | `run.lives_left` | 11 | 16 | +45% |
| strings | `run.workshop_stop` | 14 | 19 | +36% |
| strings | `optics.borescope` | 13 | 25 | +92% |
| strings | `pause.resume` | 6 | 10 | +67% |
| strings | `pause.settings` | 8 | 12 | +50% |
| strings | `pause.restart` | 17 | 25 | +47% |
| strings | `workshop.buy` | 3 | 6 | +100% |
| strings | `workshop.repair` | 6 | 14 | +133% |
| strings | `workshop.owned` | 5 | 11 | +120% |
| strings | `dev.haptics_lab.title` | 11 | 31 | +182% |
| strings | `dev.haptics_lab.tier` | 4 | 6 | +50% |
| strings | `dev.haptics_lab.force_fallback` | 12 | 26 | +117% |
| content | `job.drummer_locker.client` | 34 | 48 | +41% |
| content | `job.finnish_sailor.client` | 63 | 82 | +30% |
| content | `job.student_dorm.title` | 8 | 11 | +38% |
| content | `showcase.roman_wards.title` | 11 | 16 | +45% |
| content | `showcase.swiatniki_armourers.title` | 23 | 33 | +43% |
| content | `tool.pk_peg.name` | 10 | 27 | +170% |
| content | `tool.pk_hook.name` | 9 | 14 | +56% |
| content | `tool.pk_ward.name` | 10 | 17 | +70% |
| content | `tool.pk_ripple.name` | 11 | 17 | +55% |
| content | `tool.pk_wedge.name` | 10 | 14 | +40% |
| content | `tool.pk_lever.name` | 11 | 17 | +55% |
| content | `tool.pk_crown.name` | 10 | 19 | +90% |
| content | `tool.pk_flag.name` | 9 | 18 | +100% |
| content | `tool.pk_plunger.name` | 12 | 16 | +33% |
| content | `tool.pk_disc.name` | 11 | 15 | +36% |
| content | `cast.hall_manager.name` | 22 | 29 | +32% |
| content | `cast.rygiel.name` | 14 | 20 | +43% |
| content | `cast.stranger.name` | 13 | 17 | +31% |
| content | `job.bike_interview.line.4` | 38 | 55 | +45% |
| content | `job.bramah_bureau.line.3` | 19 | 27 | +42% |
| content | `job.widow_bureau.line.3` | 37 | 51 | +38% |
| content | `notebook.rule.5` | 31 | 41 | +32% |
| content | `ach.achievement.first_set.desc` | 47 | 65 | +38% |
| content | `ach.achievement.first_open.name` | 12 | 18 | +50% |
| content | `ach.achievement.after_overset.desc` | 46 | 71 | +54% |
| content | `ach.achievement.steel_warning.desc` | 55 | 76 | +38% |
| content | `ach.achievement.clean_receipt.name` | 8 | 13 | +63% |
| content | `ach.achievement.hard_clean.name` | 16 | 22 | +38% |
| content | `ach.achievement.wafer_master.name` | 13 | 19 | +46% |
| content | `ach.achievement.pin_plain.desc` | 56 | 88 | +57% |
| content | `ach.achievement.ring_false.desc` | 35 | 53 | +51% |
| content | `ach.achievement.wooden_creak.name` | 15 | 21 | +40% |
| content | `ach.achievement.iron_no_drop.desc` | 41 | 60 | +46% |
| content | `ach.achievement.lever_true.desc` | 37 | 50 | +35% |
| content | `ach.achievement.daily_lock.name` | 12 | 17 | +42% |
| content | `ach.achievement.bench_stop.desc` | 50 | 67 | +34% |
| content | `ach.achievement.first_no.name` | 12 | 17 | +42% |
| content | `ach.achievement.museum_papers.name` | 13 | 19 | +46% |
| content | `notebook.extra.near_shear` | 81 | 115 | +42% |
| content | `job.krystyna_wooden_album.situation` | 117 | 161 | +38% |
| content | `job.krystyna_wooden_album.title` | 17 | 26 | +53% |
| content | `job.roman_service_cupboard.client` | 44 | 61 | +39% |
| content | `job.stefan_book_tin.title` | 19 | 33 | +74% |
| content | `job.zuzanna_catalogue_drawer.line.3` | 62 | 81 | +31% |

## Czego nie wykonano / pozostałe kroki

1. **Brak recenzji native speakera** (szczególnie terminologia techniczna, fleksja nazw polskich, nazwy historyczne oraz zwięzłość etykiet).
2. **Nie wykonano wizualnego testu UI na telefonach** ani kompilacji gry; raport długości jest statyczny. W pierwszej kolejności zweryfikować przyciski i nazwy narzędzi, etykiety z największym przyrostem oraz opisy osiągnięć.
3. **Nie zintegrowano języka z plikami produkcyjnymi `game/i18n/*.csv` ani nie dodano pozycji ukraińskiego w selektorze języka**, bo zlecenie zabrania zmian poza `contrib/gpt/T17/`. Integrator powinien dopiąć kolumnę `uk`, sprawdzić import CSV w Godot, pluralizację liczb (monet) oraz fallback językowy.
4. **Nie modyfikowano `store/listing.md`** (tylko szkic w `store_uk.md`). Teksty dotyczące funkcji i prywatności pochodzą z EN; przed publikacją należy potwierdzić ich zgodność z rzeczywistym buildem 1.0. Model biznesowy D-06 pozostaje nierozstrzygnięty. Nie dodano ceny, daty premiery ani obietnicy dostępności.
5. Dodatkowa kontrola merytoryczna nazw historycznych i faktów z notek gabloty wykracza poza samo tłumaczenie; nie zastępuje pierwotnego fact-checkingu projektu.

## Źródła projektu

- `CLAUDE.md`, `docs/DESIGN.md`, `docs/CLIENTS.md`, `docs/JOBS.md`, `docs/DECISIONS.md` (D-06, D-32, D-51);
- `game/i18n/strings.csv` (blob `b50865b3b3556106a7b315c3004bc675c67c473d`);
- `game/i18n/content.csv` (blob `680e248e3ca36d02c275ddf9afef7c0800b6548c`);
- `store/listing.md` (przekład z EN).
