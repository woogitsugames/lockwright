# T03 — szkic lokalizacji niemieckiej (DE)

Data: 2026-11-05. Źródło: `woogitsugames/lockwright`, `main`, commit `1b5bc475609fca5484e0bf485427396c3f887d44`. Wszystkie zmiany znajdują się wyłącznie w `contrib/gpt/T03/`.

## Wynik

- **Interfejs:** 105/105 kluczy z `game/i18n/strings.csv` → `strings_de.csv`.
- **Treści:** 356/356 kluczy z `game/i18n/content.csv` → `content_de.csv`. Dotyczy opisów zleceń, tekstów gabloty, nazw narzędzi i obsady, dialogów oraz notatek.
- **Załącznik A `docs/CLIENTS.md`:** 207 kluczy obecnych już w `content.csv`; wszystkie uwzględniono bez powtarzania. Brak pominiętych kluczy z załącznika.
- **Metadane sklepowe:** App Store i Google Play, wariant pełnopłatny oraz opcjonalny wariant A (demo + jednorazowy zakup), z wyliczonymi limitami pól.
- **Walidacja automatyczna:** zgodność kluczy 1:1, brak pustych wartości, brak utraconych lub zmienionych placeholderów (np. `{n}`, `{0}`), poprawny dwukolumnowy CSV, kontrola długości względem EN. Łącznie **461 przetłumaczonych kluczy**.

## Pliki

| Plik | Zawartość |
|---|---|
| `strings_de.csv` | 105 napisów interfejsu, kolumny `key,de`. |
| `content_de.csv` | 356 tekstów i dialogów, kolumny `key,de`. |
| `store_de.md` | Niemieckie opisy i pola obu sklepów, limity i decyzje redakcyjne. |
| `README.md` | Decyzje językowe, słowniczek, kompletna lista ryzyk i uwagi wdrożeniowe. |
| `ASSETS.md` | Informacja o braku plików graficznych i audio w zadaniu T03. |

## Decyzje językowe i tonalne

1. **Formy grzecznościowe:** wobec osoby grającej używamy **`du`** w instrukcjach, komunikatach i sklepie (naturalny ton mobilnej gry). W dialogach ślusarza z klientami domyślnie stosujemy **`Sie`** — to relacja zawodowa i potwierdzanie prawa do lokalu. Dzieci mówią naturalnym `du`, a rozmowy rodzinne zachowują swój rejestr. Nie mieszamy `du` i `Sie` wobec tego samego adresata w jednej scenie.
2. **Wzorzec znaczenia:** kolumna `en` źródłowego CSV, z kolumną `pl` jako kontekstem charakteru postaci i humoru. Rozbieżności EN–PL nie zostały samowolnie scalone. Przykład: w `job.allotment_shed.situation` EN akcentuje pomidory w szopie, a PL rdzę i materiały do siewu — przekład jest oparty na EN.
3. **Imiona:** pozostają w zapisie oryginalnym (np. Zbyszek, Władysław, Świątniki). Przydomek kota `Potato` / `Ziemniak` został zlokalizowany jako `Kartoffel` dla zachowania dowcipu. Francuskie wtręty `Monsieur`, `Madame`, `C'est à votre famille`, `Depuis toujours` pozostają, ponieważ służą realiom Belgii.
4. **Kontekst legalny:** `Zutrittsberechtigung prüfen`, `Nachweis`, `Mietvertrag`, `Hausverwaltung`, `Auftrag ablehnen` — rzeczowy język usługowego ślusarza, bez słownictwa włamania. Wszystkie mechanizmy w grze są fikcyjne; nazwy historycznych osób w gablocie są częścią treści źródłowej, a nie markami narzędzi w rozgrywce.
5. **Stylistyka:** zdania krótkie, spokojne i lekko ironiczne. Łamanie tekstu należy testować na fizycznych przedmiotach UI (kartki, etykiety, tabliczki), bez dodawania pływających paneli.

## Słowniczek DE

| EN / termin źródłowy | Zalecane DE | Uwagi |
|---|---|---|
| locksmith / locksmith on call | Schlüsseldienst / Schlosser | `Schlüsseldienst` dla usługi i nazwy sklepowej; `Schlosser` tylko dla osoby w odpowiednim kontekście historycznym. |
| tension wrench / tensioner | Spanner / Spannwerkzeug | Narzędzie lewego kciuka; `Winkelspanner`, `Leistenspanner` jako nazwy modeli gry. |
| pick / lock pick | Pick | Fachowe określenie w UI; `Dietrich` tylko jako słowo kluczowe sklepu. |
| pin | Stift | `Unterstift` i `Oberstift` w opisie przekroju. |
| core / plug | Schlosskern / Kern | Element obracany przez napięcie. |
| shear line | Scherlinie | Granica między rdzeniem a korpusem. |
| binding | klemmender Stift / Klemmen | Stift wyraźnie stawia opór. |
| set | gesetzter Stift / gesetzt | Prawidłowe osadzenie stiftu. |
| near shear | nahe der Scherlinie | Stan przejściowy. |
| false set | Scheinsatz | Pozorne osadzenie, szczególnie przy `Spulenstift`. |
| spool pin | Spulenstift | Stift zabezpieczający o przewężonym profilu. |
| counter-rotation | Gegenrotation | Cofanie obrotu rdzenia i spanneru. |
| overset | Überhub / überhobener Stift | Za mocno podniesiony stift. |
| stress / break | Überlastung / Bruch | Odnosi się do deformacji i pęknięcia picka. |
| lever tumbler | Hebelzuhaltung | Przy zamkach z rodziną `lever`. |
| ward / warded lock | Sperrbesatz / Sperrbesatzschloss | Element blokujący w historycznych zamkach. |
| detector lock | Detektorschloss | Nazwa fikcyjnej rodziny mechanizmu gry. |
| disc detainer | Scheibenzuhaltungsschloss | Zamek z obrotowymi tarczami. |
| dimple lock | Bohrmuldenschloss | Zamek z bocznymi/zagłębionymi elementami. |
| tool roll | Werkzeugrolle | Skórzana zwijka na picki, fizyczny HUD. |
| showcase | Sammlung / Vitrine | Etykieta menu: `Sammlung`; fizyczna gablota: `Vitrine`. |
| chalk reading aid | Kreidemarkierungen | Opcjonalna warstwa czytelności, nie neonowa nakładka. |

## Ryzyka długości względem EN

Metoda: liczba znaków Unicode w pojedynczym polu (bez klucza, bez cudzysłowów CSV i bez kodowania bajtowego). Klucz trafia na listę wtedy i tylko wtedy, gdy `DE > 1,30 × EN`. To **flagi do testu łamania**, nie błędy tłumaczenia; szczególnie krótkie wyrazy mogą mieć wysoki procent przy niewielkiej różnicy bezwzględnej.

**Interfejs:** 33 z 105 kluczy powyżej +30%:

| Klucz | EN | DE | Przyrost |
|---|---:|---:|---:|
| `common.back` | 4 | 6 | +50.0% |
| `common.close` | 5 | 9 | +80.0% |
| `common.on` | 2 | 3 | +50.0% |
| `menu.play` | 9 | 15 | +66.7% |
| `menu.settings` | 8 | 13 | +62.5% |
| `menu.jobs` | 4 | 8 | +100.0% |
| `jobs.title` | 4 | 8 | +100.0% |
| `verify.ask_more` | 16 | 33 | +106.3% |
| `verify.card.manager` | 16 | 25 | +56.3% |
| `verify.card.deed` | 4 | 16 | +300.0% |
| `verify.card.bailiff` | 7 | 18 | +157.1% |
| `verify.refused` | 34 | 49 | +44.1% |
| `tutorial.done` | 30 | 50 | +66.7% |
| `settings.title` | 8 | 13 | +62.5% |
| `settings.haptics_calibration_two_clicks_yes` | 3 | 4 | +33.3% |
| `settings.haptics_calibration_two_clicks_one` | 3 | 5 | +66.7% |
| `settings.volume_ambience` | 8 | 18 | +125.0% |
| `settings.reading_aid` | 11 | 18 | +63.6% |
| `settings.wide_windows` | 13 | 20 | +53.8% |
| `settings.reset` | 14 | 26 | +85.7% |
| `settings.reduce_motion` | 13 | 21 | +61.5% |
| `run.lock_n` | 8 | 11 | +37.5% |
| `run.lives_left` | 10 | 21 | +110.0% |
| `optics.loupe` | 16 | 26 | +62.5% |
| `optics.borescope` | 13 | 19 | +46.2% |
| `pause.title` | 6 | 8 | +33.3% |
| `pause.resume` | 6 | 10 | +66.7% |
| `pause.settings` | 8 | 13 | +62.5% |
| `pause.restart` | 12 | 19 | +58.3% |
| `pause.quit` | 5 | 9 | +80.0% |
| `workshop.buy` | 3 | 6 | +100.0% |
| `workshop.repair` | 6 | 10 | +66.7% |
| `workshop.owned` | 5 | 9 | +80.0% |

**Treści:** 62 z 356 kluczy powyżej +30%:

| Klucz | EN | DE | Przyrost |
|---|---:|---:|---:|
| `job.allotment_shed.situation` | 42 | 63 | +50.0% |
| `job.allotment_shed.title` | 17 | 26 | +52.9% |
| `job.bike_interview.situation` | 82 | 123 | +50.0% |
| `job.bike_interview.title` | 17 | 32 | +88.2% |
| `job.charleroi_letters.client` | 79 | 106 | +34.2% |
| `job.drummer_locker.client` | 34 | 47 | +38.2% |
| `job.finnish_sailor.client` | 63 | 89 | +41.3% |
| `job.museum_time_lock.situation` | 33 | 44 | +33.3% |
| `job.newlyweds_4am.title` | 25 | 34 | +36.0% |
| `job.night_nurse.situation` | 46 | 72 | +56.5% |
| `job.pizzeria_pays_pizza.title` | 13 | 18 | +38.5% |
| `job.refuse_aunt_alive.situation` | 67 | 95 | +41.8% |
| `job.refuse_ex_partner.client` | 72 | 101 | +40.3% |
| `job.refuse_ex_partner.title` | 23 | 33 | +43.5% |
| `job.time_capsule.client` | 71 | 93 | +31.0% |
| `job.widow_bureau.client` | 53 | 71 | +34.0% |
| `job.widow_bureau.situation` | 28 | 37 | +32.1% |
| `job.wrong_floor.situation` | 39 | 52 | +33.3% |
| `showcase.henriksson_disc.title` | 26 | 34 | +30.8% |
| `showcase.swiatniki_armourers.title` | 23 | 35 | +52.2% |
| `showcase.wroclaw_iron_world.title` | 19 | 27 | +42.1% |
| `showcase.yale_dial.title` | 17 | 23 | +35.3% |
| `showcase.yale_flat_key.title` | 12 | 20 | +66.7% |
| `cast.locksmith.name` | 9 | 15 | +66.7% |
| `job.allotment_shed.line.2` | 56 | 74 | +32.1% |
| `job.bike_interview.line.1` | 64 | 84 | +31.3% |
| `job.bike_interview.line.2` | 60 | 80 | +33.3% |
| `job.bike_interview.line.4` | 38 | 59 | +55.3% |
| `job.charleroi_letters.line.4` | 50 | 74 | +48.0% |
| `job.dollhouse_wooden_lock.line.3` | 73 | 103 | +41.1% |
| `job.drummer_locker.line.1` | 63 | 84 | +33.3% |
| `job.grandpa_chest.line.3` | 60 | 79 | +31.7% |
| `job.krakow_antiquarian.line.2` | 74 | 97 | +31.1% |
| `job.krakow_antiquarian.note` | 97 | 131 | +35.1% |
| `job.krakow_tenement_gate.line.3` | 69 | 103 | +49.3% |
| `job.liege_bakery.line.1` | 51 | 67 | +31.4% |
| `job.liege_bakery.line.2` | 64 | 84 | +31.3% |
| `job.museum_time_lock.line.3` | 56 | 77 | +37.5% |
| `job.newlyweds_4am.line.4` | 45 | 66 | +46.7% |
| `job.night_nurse.line.3` | 66 | 88 | +33.3% |
| `job.pizzeria_pays_pizza.line.2` | 48 | 76 | +58.3% |
| `job.refuse_aunt_alive.line.3` | 35 | 46 | +31.4% |
| `job.refuse_ex_partner.after.1` | 79 | 112 | +41.8% |
| `job.refuse_ex_partner.after.2` | 54 | 76 | +40.7% |
| `job.refuse_ex_partner.line.1` | 66 | 92 | +39.4% |
| `job.refuse_rush_bribe.after.2` | 78 | 107 | +37.2% |
| `job.refuse_rush_bribe.line.1` | 54 | 79 | +46.3% |
| `job.refuse_rush_bribe.line.2` | 56 | 78 | +39.3% |
| `job.refuse_rush_bribe.line.4` | 69 | 93 | +34.8% |
| `job.swiatniki_journeyman_padlock.line.1` | 67 | 90 | +34.3% |
| `job.swiatniki_journeyman_padlock.line.4` | 88 | 122 | +38.6% |
| `job.time_capsule.line.1` | 38 | 51 | +34.2% |
| `job.time_capsule.line.3` | 46 | 66 | +43.5% |
| `job.uncle_safe_heirs.line.4` | 57 | 83 | +45.6% |
| `job.widow_bureau.line.2` | 51 | 74 | +45.1% |
| `job.widow_bureau.line.4` | 40 | 65 | +62.5% |
| `job.widow_bureau.note` | 101 | 133 | +31.7% |
| `job.wrong_floor.after.1` | 79 | 114 | +44.3% |
| `job.wrong_floor.line.1` | 52 | 87 | +67.3% |
| `job.wrong_floor.line.4` | 47 | 66 | +40.4% |
| `notebook.rule.4` | 44 | 76 | +72.7% |
| `notebook.rule.5` | 31 | 45 | +45.2% |

**Najważniejsze miejsca do testów UI:** `verify.ask_more` (krótszy wariant: „Weiteren Nachweis“), `verify.card.deed`, `verify.card.bailiff`, `run.lives_left`, `settings.volume_ambience`, `job.bike_interview.title` i długie `job.*.line.*` / `notebook.*` na wąskim papierze. Przy zmianach skracających ponownie zweryfikować sens i ton.

## Uwagi do integracji i rzeczy niezrobione

- **Nie włączano DE do runtime**: zgodnie z granicą zadania nie zmieniano źródeł `game/i18n/`, loadera Godot ani `store/listing.md`. To pliki draftów do przejęcia przez właścicieli tych obszarów.
- **Brak źródłowego `settings.language_de`**: przed aktywacją DE należy dodać wybór `Deutsch` do systemu języków w części runtime i testach (poza zakresem T03).
- **Brak wizualnego QA na telefonach**: zalecany test tekstu na kartach zleceń, emaliowanych tabliczkach, zegarowych lupach i papierowych notkach w układzie pionowym oraz poziomym. Sama metryka długości nie wykryje wszystkich przepełnień.
- **Rozbieżności źródeł EN/PL**: wymagana decyzja zespołu treści o wersji kanonicznej; w tym szkicu punktem wyjścia jest EN.
- **Ryzyko prawne narracji**: `notebook.rule.2` mówi, że sąsiad daje pewność. To poetycki skrót źródła, nie wystarczająca reguła weryfikacji prawa do lokalu; przed publikacją rozważyć doprecyzowanie w PL/EN/DE.
- **Nie robiono fact-checkingu historycznych notek**: nazwy, daty i tezy przełożono ze źródła. Do publikacji potrzebny osobny przegląd historyczny.
- **Store:** wszystkie sprawdzone pola DE mieszczą się w limitach App Store i Google Play. Przed wysłaniem potwierdzić funkcje obiecane w opisach i faktyczną politykę prywatności; opcjonalny wariant A wymaga decyzji D-06.

## Kontrola przekazania

- [x] 100% kluczy DE: `strings` i `content`.
- [x] Klucze i placeholdery identyczne ze źródłem.
- [x] 207 kluczy z `CLIENTS.md` uwzględnionych.
- [x] Pełna lista pozycji z przyrostem >30%.
- [x] Słowniczek i zasady `du` / `Sie`.
- [x] Opisy sklepowe z kontrolą limitów.
- [x] Brak modyfikacji poza `contrib/gpt/T03/`.
