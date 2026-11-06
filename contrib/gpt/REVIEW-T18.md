# Odbiór T18 (rozdział 8 „Zima w kamienicy”) + integracja rozdziału 7 (T09) w karierze

2026-11-06 · sesja B (zadanie D-71). Źródła: `contrib/gpt/T18/` (12 JSON, `content_ch8.csv`, `CHARACTERS.md`), portrety `contrib/gpt/G21/` (już w grze, 0019af3), kryteria: `CLAUDE.md`, `docs/CLIENTS.md` §1 i §4, D-57…D-71.

## Werdykt
Pakiet dobry w tonie (ciepło, sąsiedzka Wigilia, ślusarz nie dotyka instalacji grzewczej, ceny przed pracą, brak marek i instrukcji, bez wykrzykników, ≤ 90 znaków). Wymagał jednak poprawek: **jedna odmowa była trzecim powtórzeniem tego samego wzoru** (i z Oskarem z rozdz. 9 dawała drugą próbę wejścia do mieszkania krewnej), dwie rodziny zamków nie miały ekranu w grze, pani Teresa trafiła do złej dzielnicy, a kilka scen nie tłumaczyło, czemu potrzebny jest ślusarz. EN był w pisowni brytyjskiej. Wszystko poprawione; dane w `game/data/jobs/`, teksty na końcu `game/i18n/content.csv` (PL/EN po korekcie, DE/FR/ES napisane przeze mnie, rejestr D-67: postacie per Sie/vous/usted, Halina „mein Junge / mon petit / hijo”).

## Poprawki treści

| zlecenie | było | jest | powód |
|---|---|---|---|
| `refuse_visiting_relative` → **`refuse_wrong_letterbox`** | Oskar chce wejść do mieszkania nieobecnej krewnej z prezentami | Oskar wrzucił kartkę z bonem do skrzynki pod 16 (lokatorzy wyjechali na święta) i chce, żeby ją otworzyć „na minutę”. Ślusarz proponuje zapytać ich albo zarządczynię; Oskar: „nikt nie zauważy”; „Tu nie otworzę. Zostawmy im liścik”. Dzień po: Elżbieta — szesnastka oddała kartkę, babcia Oskara dostała ją w drugi dzień świąt | „Mieszkanie krewnej bez zgody” to już rozdz. 1 (Darek), 2 (garnitur), 3 (ciotka), 7 (Norbert, kwiaty siostry) i **9 (ten sam Oskar, paczka dla krewnej)**. Dwie próby Oskara z rzędu czytały się jak nękanie lokatorki (por. D-70, Darek). Nowa lekcja: cudza skrzynka i cudza korespondencja, nawet po własną kartkę. Pełne 3 takty §4.2, wafer t1 (skrzynka) |
| `refuse_unapproved_repair` l.2/l.4 | „Potrzebuję jej zgody.” / „Szafka zostaje zamknięta, aż sprawa się wyjaśni.” | „Zadzwońmy najpierw do niej.” / „Dziękuję, nie. Tu nie otworzę, dopóki zarządczyni nie potwierdzi.” | brak taktu 1 (propozycja świadka/telefonu) i jasnego „tu nie otworzę” (§4.2); dzień po: „technik **był** już na miejscu” (czas) |
| `halina_christmas_tin` | przepis na pierniki w puszce, „spalona partia” | **pierniki leżakują w puszce od listopada**, kluczyk zniknął; „Rozsądnie, synku. Pierwszy piernik i tak jest pański.” | rozdz. 7 ma już „przepisy Haliny w zamkniętej skrzynce” (`halina_recipe_box`) — drugi raz to samo; leżakowanie pierników to prawdziwy polski zwyczaj; Halina mówi „synku” (CAST) |
| `attic_drying_room` | Teresa i **Elżbieta** w Śródmieściu | Teresa i **pan Roman**, suszarnia na ostatnim piętrze **bloku**, Osiedle Słoneczne | pani Teresa mieszka obok pana Kazimierza na Osiedlu Słonecznym (`wrong_floor`); suszarnia w bloku to typowo polski szczegół; Roman „mało słów” pasuje do „Potwierdzam dostęp.” EN: „The children won't sing in icicles” → „Nobody's caroling in icicles” (zgodnie z PL, chór Mili jest dorosły) |
| `warm_room_for_neighbours` | zarządczyni się zgodziła, ale nie wiadomo, czemu sama nie otworzy | klucz ma Elżbieta, która **utknęła w śniegu za miastem** i zgadza się przez telefon; Basia: „Zarządczyni zgodziła się przez telefon.” | logika sceny (zarządczyni z kluczem nie potrzebuje ślusarza); zima jako przyczyna |
| `heating_service_cupboard` | brak powodu, l.3 bez ceny | klucz zabrał poprzedni gospodarz domu; l.3 „Szafka za ustaloną cenę jest moja. Instalacja należy do pana.” | logika + zasada „cena przed pracą” (CLIENTS §1, zeszyt zasada 4) |
| `wooden_winter_village` l.2 | tylko weryfikacja | „… się zgadzają. Cena jak w wycenie.” | cena przed pracą |
| `wigilia_table_drawer` | tytuł „Nakrycia do stołu”; świadek Basia, a mówi Zosia | „Miejsca przy stole”; świadek Zosia (ona mówi l.2) | w szufladzie są winietki, nie nakrycia; świadek = mówiąca osoba |
| `carol_singers_chest` | karta „manager + institution” przy Mili | bez zmian kart; w `verification` dopisane, że Mila nie decyduje o dostępie | skrzynia należy do wspólnoty |
| EN całość | *organiser, authorised, neighbours, community room, biscuits, boot* | pisownia US (*organizer, authorized, neighbors*), *common room* (jak rozdz. 7 i 9–12), *gingerbread*; słownictwo europejskie (*flat, letterbox*) zostaje | normalizacja EN (REVIEW-T44-T73) |
| PL drobne | „jedna zimna zagadka na raz”, „Chór gotowy jest od wtorku” | „naraz”, „Chór jest gotowy od wtorku” | ortografia, szyk |

Bez zmian (dobre): finał `christmas_eve_heat` (ślusarz „zajmie się zamkiem, niczym więcej”, technik odpowiada za instalację, „Przy stole nadal czeka na pana miejsce” spina się z winietkami), `frozen_cellar_padlock` (Janka i koce → rozdz. 9 „Jeszcze jeden koc”), `winter_bicycle_cellar` (Leon-kurier → rozdz. 11), `wooden_winter_village` (makieta → rozdz. 9 „skrzynka na listy w zimowym miasteczku”), Mila i kolędnicy (→ rozdz. 9 „Kolędy po kolędach”, Teresa szyła pokrowiec).

## Zgodność z zasadami
- **Odmowy (CLIENTS §4):** 2 sceny, obie z taktami zgrzyt → propozycja telefonu/zarządczyni → odmowa klienta → „Tu nie otworzę” + inna droga; bez oskarżeń i policji w dialogu; 0 monet, +5 reputacji (prefiks `job.refuse`), dzień po: Elżbieta. Karol (dopłata) powtarza lekcję rozdz. 2 („procedur nie da się dopłacić”), ale w nowym kontekście: obok jest prawdziwy, upoważniony technik Paweł — zostawione.
- **Legalność weryfikacji:** karty tylko z typów gry (`lease`, `manager`, `institution`, `witness`, `photo`, `id`, `letter`). `threshold` 2–3 jak w innych zleceniach (gra go nie egzekwuje, N-04).
- **Ślusarz nie dotyka urządzeń grzewczych** (szafka z dziennikiem, szafka kontrolna) — zgodnie z T18 i tonem „pomagamy, nie majstrujemy”.
- **Miejsca/pory:** `cellar` (5), `apartment` (6), `attic` (1) — wszystkie mają tła G07 i tabliczki.

## Rodziny i tiery (plan B, lockcore)
`wooden_pin` i `ring_combo` **nie mają ekranu planu B** (gra je ukrywa, N-63), a T09/T18 miały ich 5 zleceń. Przemapowane na rodziny z ekranem i lekcją D-68, zgodnie z nazwą widoczną na przyjeździe:
- `wooden_pin` → **`egyptian`** („Zasuwa drewniana”, D-60: moduł wooden_pin z opadającymi kołkami): `carol_singers_chest` t1, `wooden_winter_village` t1, rozdz. 7 `krystyna_wooden_album` t1;
- `ring_combo` → **`combo`** („Zamek z kółkami”): `frozen_cellar_padlock` t2, `winter_bicycle_cellar` t3, rozdz. 7 `stefan_book_tin` t3.
Tiery w zakresach lockcore: `lever_detector` t5 (T18 słusznie zauważył, że T09 miał t2; poprawione też w rozdz. 7 `edek_rehearsal_store` 2→5), `lever` t3 (rozdz. 7 `zuzanna_catalogue_drawer` 2→3), pin t3, warded t1, wafer t1–t2. Test `test_job_families_playable_or_known_hidden` nie dopuszcza już żadnej ukrytej rodziny.

## Kolejność i pola D-70
`order` 1–12 z łuku T18 (Akt I mróz, II zimne grzejniki, III ciepłe drzwi), `outcome: open` wszędzie (odmowy rozpoznaje prefiks `job.refuse`), `source`. Rozdział 7 dostał te same pola (`order` z łuku T09).

## Obsada i głosy
- Portrety: janka, mila, oskar, pawel, karol, leon z G21 są w grze (`assets/ui/gpt/cast/episodic/`); Teresa, Elżbieta, Basia, Marta, Zuzanna, Halina, Zosia, Roman mają swoje.
- Głosy: istnieją dla wszystkich poza **Pawłem i Karolem** — nowe głosy Voice Design (eleven_ttv_v3, 3 próbki, wybór wg F0 i czytelności ASR; Karol 137 Hz, żeby odróżniał się od Oskara 156 Hz). 48 kwestii × PL/EN/DE = 144 pliki `eleven_v4_turbo`, tagi w `contrib/voice/tags.json`.
- `cast.pawel.name`, `cast.karol.name` dopisane; `cast.teresa.name` z T18 („Teresa”) odrzucone — w grze jest „Pani Teresa”.

## Nie przyjęte z T18
- `content_ch8.csv` nagłówek `key` (gra: `keys`) — nieistotne, teksty wpisane skryptem.
- `CHARACTERS.md` Teresa 69 lat — w grze ok. 70 (`voice_lines.py`), bez zmiany.
- Sceny „dzień po” dla 10 zleceń nieodmownych — T18 ich nie miał; gra jeszcze ich nie wyświetla (REVIEW-T43), do osobnego zlecenia (V04 Mistral obejmuje dni po).
