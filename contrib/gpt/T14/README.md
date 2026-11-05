# T14 — włoska lokalizacja Lockwright (IT)

**Status:** kompletny szkic do przeglądu przez native speakera; nie jest zintegrowany z grą ani zatwierdzony do publikacji sklepowej. Tłumaczono z kolumny EN z pomocniczą kontrolą PL. Wszystkie nowe pliki mieszczą się wyłącznie w `contrib/gpt/T14/`.

## Pliki i zakres

| Plik | Wykonano |
|---|---|
| `strings_it.csv` | 125 kluczy UI, format `key,it` |
| `content_it.csv` | 629 kluczy: zlecenia, dialogi, notatki, gablota, postacie, osiągnięcia i porady; format `key,it` |
| `store_it.md` | 12 włoskich pól App Store i Google Play z liczbami znaków i bajtów oraz limitami |
| `GLOSSARY_it.md` | 88 terminów, rejestr i uwagi dla native speakera |
| `README.md` | Raport QA i pełna lista ryzyk długości |

**Forma adresowania:** w interfejsie, opisach i samouczku **`tu`**, zwykle w domyślnym trybie rozkazującym. Jest naturalniejsze dla włoskiej gry mobilnej, krótsze od `Lei` i pasuje do spokojnego, konkretnego narratora. W dialogach zachowano grzecznościowe tytuły `signor`, `signora`, `dottoressa` i imiona własne postaci. Ton pozostaje legalny: weryfikacja prawa do lokalu, dyskretne odmowy, zero instrukcji do rzeczywistych urządzeń.

## Kontrole automatyczne

- **100% tłumaczeń:** 125/125 UI i 629/629 treści; brak pustych, brak nadmiarowych kluczy, zachowana kolejność.
- **CSV:** prawidłowe cytowanie pól zawierających przecinki i cudzysłowy; nagłówki `key,it`.
- **Placeholdery:** `{n}`, `{0}` itd. zachowane bez zmiany nazwy i liczności; błędów: **0**.
- **Sklepy:** 12/12 pól w limicie. App Store: tytuł 29/30, podtytuł 27/30, promocja 155/170, słowa kluczowe 90/100 **bajtów**; pełny opis 2117/4000. Google Play: krótki opis 79/80, pełny 2173/4000. Z opcjonalnym wariantem A opisy liczą odpowiednio 2235 i 2291 znaków (limit 4000).
- **Dialogi ponad 90 znaków IT:** 12. **Notatki `.note` ponad 130 znaków IT:** 8. To dodatkowe progi zaczerpnięte z zaleceń długości PL/EN w `docs/CLIENTS.md`; nie są oficjalnymi twardymi limitami języka IT.

## Ograniczenia i dalsze kroki

1. **D-06 jest nierozstrzygnięta.** W `store_it.md` wariant A (demo + jeden zakup) jest wydzielony i **nieprzeznaczony do publikacji bez decyzji właściciela**. Brak obietnicy ceny, daty premiery i dostępności.
2. **Native review IT** pozostaje do zrobienia. Zweryfikować zwłaszcza `fabbro a chiamata`, `falso scatto`, `rotore/cilindro`, nazwy wymyślonych narzędzi, rejestr i skrótowość etykiet.
3. **Integracja i18n nie została wykonana** zgodnie z zakazem zapisu poza `contrib/gpt/T14/`. Potrzebne późniejsze podłączenie `it-IT` w aplikacji i dodanie `settings.language_it` (nie było go w EN źródłowym CSV, więc nie dodano nadmiarowego klucza).
4. **Deklaracje sklepowe do weryfikacji względem wydania 1.0:** funkcje gablota/wyzwania/tryb ciemny, oznaczenia kredą, brak zbierania danych, reklamy, offline, brak zakupu monet za realne pieniądze. iOS jest na końcu harmonogramu (D-51); pola App Store są szkicem, nie zapewnieniem dostępności.
5. **Nie wykonano testu na urządzeniu ani przeglądu przez native speakera.** To pozostałe elementy kontroli jakości, nie błędy pakietu.

## Klucze dłuższe od EN o ponad 30%

Liczba znaków Unicode, warunek **IT > 1,30 × EN** bez zaokrąglania. Dłuższy napis nie przesądza o obcięciu w UI; jest sygnałem do testu. Krótkie etykiety EN generują czasem wysokie procenty z powodu zaledwie kilku dodatkowych znaków.

**Łącznie: 183 kluczy**, z czego **53 UI**, **130 treści**.

### Interfejs (53)

| Klucz | EN | IT | Wzrost |
|---|---:|---:|---:|
| `boot.calib_title` | 54 | 73 | +35% |
| `boot.calib_none` | 4 | 7 | +75% |
| `settings.feel_section` | 14 | 28 | +100% |
| `settings.quality_auto` | 15 | 21 | +40% |
| `settings.quality_low` | 18 | 26 | +44% |
| `settings.report_empty` | 13 | 20 | +54% |
| `common.back` | 4 | 8 | +100% |
| `common.on` | 2 | 6 | +200% |
| `common.off` | 3 | 9 | +200% |
| `menu.play` | 11 | 15 | +36% |
| `menu.settings` | 8 | 12 | +50% |
| `menu.about` | 14 | 22 | +57% |
| `menu.jobs` | 4 | 9 | +125% |
| `jobs.title` | 4 | 9 | +125% |
| `job.verify` | 20 | 30 | +50% |
| `verify.title` | 20 | 30 | +50% |
| `verify.card.lease` | 15 | 22 | +47% |
| `verify.card.deed` | 4 | 17 | +325% |
| `verify.card.address_app` | 20 | 27 | +35% |
| `verify.card.police` | 15 | 24 | +60% |
| `verify.card.bailiff` | 7 | 21 | +200% |
| `hud.magnifier` | 9 | 21 | +133% |
| `settings.title` | 8 | 12 | +50% |
| `settings.haptics` | 7 | 15 | +114% |
| `settings.haptics_enabled` | 15 | 22 | +47% |
| `settings.haptics_intensity` | 15 | 29 | +93% |
| `settings.haptics_test` | 10 | 16 | +60% |
| `settings.volume_ambience` | 8 | 16 | +100% |
| `settings.language_system` | 15 | 22 | +47% |
| `settings.dark_mode_assist` | 13 | 17 | +31% |
| `settings.wide_windows` | 13 | 18 | +38% |
| `settings.reset` | 14 | 23 | +64% |
| `settings.text_scale` | 9 | 20 | +122% |
| `settings.reduce_motion` | 13 | 19 | +46% |
| `run.lock_n` | 8 | 13 | +63% |
| `run.lives_left` | 11 | 22 | +100% |
| `run.rubber_band` | 35 | 56 | +60% |
| `optics.loupe` | 19 | 31 | +63% |
| `optics.borescope` | 13 | 22 | +69% |
| `pause.title` | 6 | 8 | +33% |
| `pause.resume` | 6 | 8 | +33% |
| `pause.settings` | 8 | 12 | +50% |
| `pause.restart` | 17 | 27 | +59% |
| `pause.quit` | 14 | 19 | +36% |
| `workshop.buy` | 3 | 6 | +100% |
| `workshop.owned` | 5 | 7 | +40% |
| `workshop.integrity` | 14 | 19 | +36% |
| `workshop.repair_cost` | 17 | 23 | +35% |
| `workshop.reward` | 19 | 26 | +37% |
| `about.title` | 14 | 22 | +57% |
| `dev.haptics_lab.title` | 11 | 18 | +64% |
| `dev.haptics_lab.tier` | 4 | 7 | +75% |
| `dev.haptics_lab.force_fallback` | 12 | 27 | +125% |

### Treść (130)

| Klucz | EN | IT | Wzrost |
|---|---:|---:|---:|
| `job.allotment_shed.title` | 17 | 29 | +71% |
| `job.bike_interview.situation` | 95 | 128 | +35% |
| `job.charleroi_letters.client` | 67 | 88 | +31% |
| `job.dollhouse_wooden_lock.situation` | 127 | 173 | +36% |
| `job.dollhouse_wooden_lock.title` | 25 | 34 | +36% |
| `job.krakow_antiquarian.client` | 28 | 39 | +39% |
| `job.krakow_tenement_gate.situation` | 113 | 150 | +33% |
| `job.liege_bakery.situation` | 122 | 162 | +33% |
| `job.museum_time_lock.client` | 94 | 129 | +37% |
| `job.newlyweds_4am.title` | 25 | 37 | +48% |
| `job.pizzeria_pays_pizza.title` | 13 | 18 | +38% |
| `job.refuse_ex_partner.client` | 60 | 84 | +40% |
| `job.refuse_ex_partner.situation` | 101 | 136 | +35% |
| `job.refuse_rush_bribe.client` | 49 | 71 | +45% |
| `job.refuse_rush_bribe.title` | 26 | 34 | +31% |
| `job.swiatniki_journeyman_padlock.client` | 67 | 97 | +45% |
| `job.swiatniki_journeyman_padlock.title` | 33 | 48 | +45% |
| `job.uncle_safe_heirs.title` | 19 | 30 | +58% |
| `job.widow_bureau.client` | 53 | 74 | +40% |
| `job.wrong_floor.situation` | 39 | 53 | +36% |
| `showcase.amen_padlock.title` | 18 | 31 | +72% |
| `showcase.egyptian_name.title` | 21 | 28 | +33% |
| `showcase.roman_wards.title` | 11 | 35 | +218% |
| `showcase.yale_dial.title` | 17 | 24 | +41% |
| `showcase.yale_flat_key.title` | 18 | 24 | +33% |
| `tool.pk_peg.name` | 10 | 20 | +100% |
| `tool.pk_hook.name` | 9 | 20 | +122% |
| `tool.pk_ward.name` | 10 | 18 | +80% |
| `tool.pk_ripple.name` | 11 | 20 | +82% |
| `tool.pk_lever.name` | 11 | 18 | +64% |
| `tool.pk_crown.name` | 10 | 20 | +100% |
| `tool.pk_flag.name` | 9 | 22 | +144% |
| `tool.pk_plunger.name` | 12 | 26 | +117% |
| `tool.pk_disc.name` | 11 | 18 | +64% |
| `tool.tl_cup.name` | 13 | 18 | +38% |
| `tool.tl_drill.name` | 5 | 7 | +40% |
| `cast.captain.name` | 7 | 11 | +57% |
| `cast.edek.name` | 15 | 24 | +60% |
| `cast.halina.name` | 10 | 17 | +70% |
| `cast.hall_manager.name` | 22 | 32 | +45% |
| `cast.irena.name` | 9 | 16 | +78% |
| `cast.jadwiga.name` | 11 | 18 | +64% |
| `cast.kazimierz.name` | 12 | 19 | +58% |
| `cast.krysia.name` | 10 | 17 | +70% |
| `cast.krystyna.name` | 12 | 19 | +58% |
| `cast.leopold.name` | 10 | 17 | +70% |
| `cast.mietek.name` | 9 | 16 | +78% |
| `cast.neighbour_lucyna.name` | 22 | 30 | +36% |
| `cast.renata.name` | 10 | 17 | +70% |
| `cast.rygiel.name` | 14 | 25 | +79% |
| `cast.stefan.name` | 9 | 16 | +78% |
| `cast.stranger.name` | 13 | 27 | +108% |
| `cast.teresa.name` | 10 | 17 | +70% |
| `cast.waldek.name` | 9 | 16 | +78% |
| `cast.wanda.name` | 9 | 16 | +78% |
| `cast.wladyslaw.name` | 12 | 19 | +58% |
| `cast.zbyszek.name` | 10 | 17 | +70% |
| `cast.zosia.name` | 9 | 16 | +78% |
| `job.bramah_bureau.line.3` | 19 | 27 | +42% |
| `job.charleroi_letters.line.1` | 73 | 102 | +40% |
| `job.charleroi_letters.line.4` | 65 | 93 | +43% |
| `job.charleroi_letters.note` | 118 | 154 | +31% |
| `job.dollhouse_wooden_lock.note` | 105 | 146 | +39% |
| `job.grandma_broth.line.4` | 62 | 81 | +31% |
| `job.grandma_broth.note` | 95 | 127 | +34% |
| `job.kiosk_shutter.note` | 108 | 144 | +33% |
| `job.liege_bakery.line.3` | 66 | 92 | +39% |
| `job.liege_bakery.note` | 91 | 133 | +46% |
| `job.museum_time_lock.note` | 118 | 160 | +36% |
| `job.refuse_ex_partner.note` | 82 | 110 | +34% |
| `job.refuse_rush_bribe.note` | 88 | 132 | +50% |
| `job.widow_bureau.line.3` | 37 | 49 | +32% |
| `job.widow_bureau.line.4` | 40 | 53 | +32% |
| `ach.achievement.first_open.name` | 12 | 17 | +42% |
| `ach.achievement.wafer_school.name` | 15 | 21 | +40% |
| `ach.achievement.wafer_school.desc` | 38 | 50 | +32% |
| `ach.achievement.false_note.desc` | 42 | 61 | +45% |
| `ach.achievement.after_drop.desc` | 53 | 72 | +36% |
| `ach.achievement.after_overset.desc` | 46 | 71 | +54% |
| `ach.achievement.counter_sense.name` | 16 | 26 | +63% |
| `ach.achievement.counter_sense.desc` | 49 | 64 | +31% |
| `ach.achievement.clean_receipt.name` | 8 | 12 | +50% |
| `ach.achievement.clean_receipt.desc` | 56 | 78 | +39% |
| `ach.achievement.hard_clean.name` | 16 | 32 | +100% |
| `ach.achievement.wafer_master.name` | 13 | 19 | +46% |
| `ach.achievement.wafer_master.desc` | 64 | 85 | +33% |
| `ach.achievement.wafer_clean.desc` | 48 | 63 | +31% |
| `ach.achievement.pin_plain.desc` | 56 | 90 | +61% |
| `ach.achievement.first_gate.name` | 11 | 17 | +55% |
| `ach.achievement.first_gate.desc` | 40 | 55 | +38% |
| `ach.achievement.detector_return.name` | 14 | 19 | +36% |
| `ach.achievement.detector_return.desc` | 57 | 80 | +40% |
| `ach.achievement.ring_false.name` | 17 | 25 | +47% |
| `ach.achievement.ring_false.desc` | 35 | 50 | +43% |
| `ach.achievement.wooden_creak.name` | 15 | 22 | +47% |
| `ach.achievement.wooden_creak.desc` | 46 | 70 | +52% |
| `ach.achievement.iron_no_drop.name` | 13 | 17 | +31% |
| `ach.achievement.iron_no_drop.desc` | 41 | 62 | +51% |
| `ach.achievement.dark_clean.name` | 12 | 19 | +58% |
| `ach.achievement.daily_lock.name` | 12 | 16 | +33% |
| `ach.achievement.daily_lock.desc` | 47 | 69 | +47% |
| `ach.achievement.timed_care.name` | 16 | 22 | +38% |
| `ach.achievement.tool_care.name` | 16 | 23 | +44% |
| `ach.achievement.permission.name` | 15 | 21 | +40% |
| `ach.achievement.witness.desc` | 65 | 92 | +42% |
| `ach.achievement.heirs.desc` | 52 | 69 | +33% |
| `ach.achievement.museum_papers.name` | 13 | 17 | +31% |
| `ach.achievement.kazimierz.name` | 12 | 18 | +50% |
| `tip.ethics_01` | 51 | 68 | +33% |
| `tip.feel_05` | 57 | 77 | +35% |
| `tip.feel_11` | 56 | 74 | +32% |
| `tip.feel_13` | 55 | 82 | +49% |
| `tip.workshop_08` | 56 | 80 | +43% |
| `tip.calm_07` | 61 | 85 | +39% |
| `notebook.extra.overset_twice` | 73 | 106 | +45% |
| `notebook.extra.two_breaks` | 76 | 103 | +36% |
| `notebook.extra.ring_clicks` | 71 | 100 | +41% |
| `notebook.extra.mixed_recovery` | 67 | 90 | +34% |
| `notebook.extra.worn_but_whole` | 82 | 108 | +32% |
| `job.halina_recipe_box.note` | 95 | 130 | +37% |
| `job.halina_recipe_box.title` | 17 | 23 | +35% |
| `job.krystyna_wooden_album.line.1` | 61 | 90 | +48% |
| `job.krystyna_wooden_album.title` | 17 | 30 | +76% |
| `job.marta_poster_studio.line.2` | 63 | 82 | +30% |
| `job.refuse_sisters_flat.note` | 86 | 129 | +50% |
| `job.roman_service_cupboard.client` | 44 | 72 | +64% |
| `job.stefan_book_tin.client` | 49 | 85 | +73% |
| `job.stefan_book_tin.line.1` | 56 | 92 | +64% |
| `job.zuzanna_catalogue_drawer.client` | 57 | 76 | +33% |
| `job.zuzanna_catalogue_drawer.line.3` | 62 | 83 | +34% |

### Szczególny priorytet w interfejsie

- `run.rubber_band`: 35 → 56 znaków
- `boot.calib_title`: 54 → 73 znaków
- `dev.haptics_lab.force_fallback`: 12 → 27 znaków
- `settings.feel_section`: 14 → 28 znaków
- `verify.card.bailiff`: 7 → 21 znaków
- `settings.haptics_intensity`: 15 → 29 znaków
- `verify.card.deed`: 4 → 17 znaków
- `hud.magnifier`: 9 → 21 znaków
- `optics.loupe`: 19 → 31 znaków
- `settings.text_scale`: 9 → 20 znaków
- `run.lives_left`: 11 → 22 znaków
- `job.verify`: 20 → 30 znaków
- `verify.title`: 20 → 30 znaków
- `pause.restart`: 17 → 27 znaków

## Źródła i kontrola wersji

- Przeczytano: `CLAUDE.md`, `docs/DESIGN.md`, `docs/CLIENTS.md`, `docs/JOBS.md`, `docs/DECISIONS.md` (D-06, D-51, D-32), `game/i18n/strings.csv`, `game/i18n/content.csv`, `store/listing.md`.
- SHA blobów źródłowych: `strings.csv` `b50865b3b3556106a7b315c3004bc675c67c473d`; `content.csv` `680e248e3ca36d02c275ddf9afef7c0800b6548c`; `listing.md` `3e29d4bf8706802defce325469f6417f665fb291`.
- **Nie zmieniono nic poza katalogiem `contrib/gpt/T14/`.**
