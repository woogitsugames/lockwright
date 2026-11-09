# Audyt treści zleceń — 2026-11-09

Sesja redakcji narracyjnej (worktree `wt-content`). Przeczytana pełna ścieżka gracza we wszystkich 83 zleceniach,
po polsku i po angielsku (DE/FR/ES sprawdzone tam, gdzie coś zmieniałem, a DE dodatkowo w opisach klienta i
sytuacji). Sprawdzone elementy: tytuł, klient, sytuacja, cztery kwestie rozmowy, przycisk i tytuł weryfikacji
(`verify_kind`, D-103), karty z treścią z `card_detail` (D-95) i ich wymiany zdań, decyzje, kwestie „dzień po” (D-78),
`wrong_open`, miejsce i pora przyjazdu, numer drzwi i tabliczka (D-84, D-91, D-94, D-102). Zrzut ścieżek zrobiłem
skryptem, który składa teksty tak samo jak `job_verify.gd`: `card_detail`, warianty `exchange`, przyrostek
`verify_kind` i notatkę świadka.

**Wynik:** 37 × OK, 45 × poprawione (dane albo teksty bez nagrań), 1 × do ponownego nagrania
(`contrib/voice/REVOICE.md`: 5 plików). Nagrania nie zmieniły się w żadnym zleceniu.

## Zmiany ogólne (dotyczą wielu zleceń, `strings.csv`, 5 języków)

| klucz | było | jest | dlaczego |
|---|---|---|---|
| `verify.paper.witness.body` (notatka świadka, lokal) | „Znam tę osobę od lat. Mieszka pod tym adresem.” | „Znam tę osobę od lat i za nią ręczę.” | Kartkę świadka pokazują też kiosk, altana, pracownia, pizzeria i kiosk na targu. Nikt tam nie mieszka. |
| `verify.reply.witness.1` | „Sąsiadka z naprzeciwka. Zna mnie od lat.” | „Sąsiedzi. Znają mnie od lat.” | Świadkami byli też mężczyźni (Waldek, Jacques, Mietek, sąsiad w szlafroku). Zosia mieszka „przez ścianę”, nie naprzeciwko. |
| `verify.reply.witness.2` | „Zapukam obok. Tam zawsze wcześnie wstają.” | „Zapukam obok. Ktoś na pewno otworzy.” | Kwestia padała o 4:00, o 23:30 i na działce. |
| `verify.reply.institution.2` | „Dyrekcja. Jest podpis i pieczątka.” | „Osoba upoważniona. Podpis i pieczątka są na dole.” | „Dyrekcję” miały pisma rady parafii, uczelni, firmy serwisowej i wspólnoty. |

Zlecenia, które dalej korzystają z ogólnej wymiany przy świadku (bo nie mają własnej), czytają się teraz poprawnie.
Test `test_verify_kind` wymaga, żeby rosół zachował wymianę ogólną: zachował ją.

## Zlecenia

Legenda: **OK** = bez sprzeczności. **Poprawione** = zmiana danych albo napisów (nienagranych). **Nagranie** = wpis w
`REVOICE.md`. „Własna wymiana” to nowe klucze `job.<id>.<karta>.ask/.reply` (5 języków) w `card_detail.<karta>`.
W tym mechanizmie przy zdjęciach działało to już od D-95.

| zlecenie | wynik | co było nie tak → co zmieniłem |
|---|---|---|
| `allotment_shed` | Poprawione | Świadek to pan Waldek z sąsiedniej działki. Wymiana mówiła „sąsiadka z naprzeciwka”, „zapukam obok”, a notatka „mieszka pod tym adresem”. → własna wymiana (Waldek zza płotu) i ogólna notatka świadka. |
| `attic_drying_room` | OK | |
| `bike_interview` | OK | „Rower stoi na ulicy” (l.2) i „przy stojaku pod blokiem” to to samo miejsce. |
| `bramah_bureau` | Poprawione | Karta „Akt własności” pokazywała AKT NOTARIALNY dla mebla z aukcji, a Gosia mówi „faktura, opis i zdjęcia”. → karty `invoice`, `photo` (portret Gosi, „zdjęcie z dnia odbioru, zamek w rogu”). |
| `brussels_townhouse` | Poprawione | Świadek to monsieur Jacques z parteru. Wymiana: „sąsiadka z naprzeciwka”. → własna wymiana. |
| `carol_singers_chest` | Poprawione | Elżbieta pokazuje uchwałę wspólnoty, a na stole leżało „Pismo instytucji” podpisane przez „Dyrekcję”. → karta `resolution`. |
| `cat_bathroom` | Poprawione | Ślusarz mówi „dokumentów tym razem nie trzeba”, a karta dowodu pytała „czy nazwisko zgadza się z drzwiami”. → własna wymiana („Dowód tylko dla porządku.” / „Ziemniak swojego nie ma.”). |
| `charleroi_letters` | Poprawione | W PL opisie klienta był klucz kodu i słowo „gracz” („Ola z `job.grandpa_chest` … dzwoni do gracza”). W DE opisie klienta była metainformacja „aus dem Auftrag…”. DE sytuacja przeczyła reszcie („die Geldkassette soll nicht geöffnet werden”). Karta listu mówiła „w tym tygodniu, data na stemplu”, a chodzi o 70-letnie listy dziadka. → nowy opis PL/DE, nowa sytuacja DE, własna wymiana (adres z listów). |
| `christmas_eve_heat` | Nagranie | Elżbieta mówi „grzejniki znowu są ciepłe” (l.4) na przyjeździe, zanim szafka zostanie otwarta. Nowy tekst w 5 językach jest w `REVOICE.md`. Ogólna wymiana „Dyrekcja” naprawiona zmianą ogólną. |
| `community_notice_case` | Poprawione | Zarządczyni pokazuje podpisaną uchwałę, a karta była „Pismo instytucji”. → `resolution`. |
| `dollhouse_wooden_lock` | Poprawione | Jedyną kartą był dowód osobisty 7-letniej Hani („Zdjęcie stare, ale to ja”). → karta `photo`: portret Hani, która trzyma lalkę („To ta lalka, która siedzi w domku?” / „Tak, Lala. Zdjęcie z niedzieli…”). |
| `drummer_locker` | Poprawione | Kierownik sali potwierdza szafkę ze swojego zeszytu, a na stole leżał tylko dowód. → karty `manager` (kierownik sali, wykaz użytkowników, własna wymiana o szafce 8) i `id`. |
| `edek_rehearsal_store` | Poprawione | Tytuł „Krzesła na próbę” / *Chairs for Rehearsal*, a krzesła są na zebranie mieszkańców. → „Krzesła na zebranie” / *Chairs for the Meeting* (5 języków). |
| `finnish_sailor` | Poprawione | Miejsce: klatka z drzwiami nr 5 (numer Agnieszki) przy statku w porcie. Karta kapitana mówiła „jest pod naszą opieką”, choć skrzynia należy do Aino. → `place: yard` (plener, bez tabliczki) i własna wymiana (kapitan na piśmie, odpływają o szóstej). |
| `frozen_cellar_padlock` | OK | |
| `ghent_beguinage` | Poprawione | Pismo rady parafii podpisane przez „Dyrekcję”. Poprawione zmianą ogólną. Zostaje: tabliczka „Administracja” przy bramie (grafika). |
| `gosia_workbench_drawer` | Poprawione | Gosia i ślusarz mówią o fakturze, a karta była „Paragon”. Odpowiedź EN/DE/FR/ES przy zdjęciu mówiła „stół” zamiast „stół warsztatowy”. → karta `invoice`, „the bench / Werkbank / établi / banco de trabajo”. |
| `grandma_broth` | Poprawione | „Sąsiadka z naprzeciwka” przy pani Zosi, która mieszka przez ścianę. Poprawione zmianą ogólną (wymiana zostaje ogólna, wymaga tego test). |
| `grandpa_chest` | Poprawione | Wymiana przy akcie: „Czy dokument obejmuje tę rzecz? Tak, jest w nim wymieniona.” Akt dotyczy domu, nie skrzyni. Miejsce: klatka z drzwiami 7, choć skrzynia stoi na strychu domu po dziadku. DE sytuacja zdradzała listy i miała błąd („Opas Józefs Truhe”). → własna wymiana („Dom i wszystko na strychu, po tacie”), `place: attic`, nowa sytuacja DE. |
| `halina_christmas_tin` | OK | |
| `halina_recipe_box` | Poprawione | Zosia: „Na zdjęciu stoi obok jej kubka”. Karta pokazywała klatkę pod siódemką, a podpis brzmiał „Pod moimi drzwiami”. → zdjęcie: portret pani Haliny, odpowiedź „W mojej kuchni. Skrzynka stoi obok kubka…”. |
| `heating_service_cupboard` | OK | Ogólna wymiana „Dyrekcja” poprawiona zmianą ogólną. |
| `kiosk_shutter` | Poprawione | Świadek to pani Krysia z przystanku. Wymiana mówiła „sąsiadka z naprzeciwka”, a notatka „mieszka pod tym adresem” (kiosk). → własna wymiana („Kupuje u mnie gazetę od dziewięćdziesiątego czwartego”). |
| `krakow_antiquarian` | OK | Zostaje: sklep pokazuje zdjęcie klatki z drzwiami 12 (grafika). |
| `krakow_tenement_gate` | OK | |
| `krystyna_wooden_album` | Poprawione | Kwestia 2 (EN/DE/FR/ES: „a photo of him holding it”) nie zgadzała się z kartą: portret Oli i Krystyny z podpisem „Moja córka Ola i ja, w domu”. → podpis: „Ola i ja. Za nami, na kredensie, stoi zdjęcie taty z tą skrzynką.” Bez ponownego nagrania. |
| `liege_bakery` | OK | Zostaje: piekarnia pokazuje klatkę z drzwiami 5 (grafika). |
| `marta_poster_studio` | Poprawione | Notatka świadka „mieszka pod tym adresem” przy pracowni. Poprawione zmianą ogólną. |
| `museum_time_lock` | OK | |
| `newlyweds_4am` | Poprawione | Świadkiem jest sąsiad w szlafroku, który już stoi na klatce. Wymiana mówiła „sąsiadka z naprzeciwka” i „tam zawsze wcześnie wstają” (o 4:00). → własna wymiana. |
| `night_nurse` | Poprawione | Pan Roman potwierdza przez domofon (l.2), a karta pytała „Możemy zadzwonić do zarządcy? Numer jest na tablicy”. → własna wymiana („Lokal pięć, jestem w wykazie”). Tabliczka 5 i pole „Lokal 5” bez zmian. |
| `pizzeria_pays_pizza` | Poprawione | Świadkiem jest pan Mietek z kebabu obok (23:30). Wymiana mówiła „sąsiadka z naprzeciwka”. → własna wymiana. |
| `refuse_aunt_alive` | Poprawione | DE sytuacja zdradzała zwrot akcji („Die betreffende Tante lebt allerdings noch”). → DE jak EN. |
| `refuse_ex_partner` | Poprawione | Na stole leżała kartka świadka, który ręczył za Darka („mieszka pod tym adresem”, „sąsiadka zna mnie od lat”). Przy zgrzycie „brak świadka” to podważało odmowę. → karty tylko `id`. |
| `refuse_rush_bribe` | Poprawione | DE sytuacja opisywała inną historię (zgoda siostry, inne nazwisko w dowodzie). → DE jak EN (1:00, siostra za granicą, dopłata). Pole `time: evening` zostaje, bo test go wymaga; scenka i tak jest nocna. |
| `refuse_sisters_flat` | OK | |
| `refuse_t43_09_empty_flat` | OK | |
| `refuse_t43_10_early_clearance` | OK | Po „dniu po” mówi pan Roman (osiedle), a dzielnica w danych to Śródmieście. Gracz dzielnicy nie widzi. |
| `refuse_t43_11_other_stall` | Poprawione | Umowa najmu odpowiadała „Tak, adres jest na pierwszej stronie”, choć dotyczy stoiska Alicji, a nie sąsiedniego. → własna wymiana („Nie, moje jest obok. Ale to tylko przedłużacz.”). |
| `refuse_t43_12_surprise_key` | OK | Darek wraca celowo (REVIEW-T43). |
| `refuse_unapproved_repair` | Poprawione | Niepodpisana wiadomość wyglądała jak list polecony („data na stemplu”). → własna wymiana („Kto podpisał tę wiadomość?” / „Nikt. Ale napisali, że pilne.”). |
| `refuse_unapproved_stockroom` | Poprawione | List przewozowy kuriera odpowiadał „Do mnie, na ten adres”. → własna wymiana („Na sklep. Ja tylko przywiozłem paczki.”). |
| `refuse_wrong_letterbox` | OK | |
| `roman_service_cupboard` | Poprawione | Uchwała wspólnoty (l.2) leżała jako „Pismo instytucji”. → `resolution`. |
| `shared_room_door` | Poprawione | Pisemna uchwała wspólnoty leżała jako „Pismo instytucji”. → `resolution`. |
| `stefan_book_tin` | OK | |
| `student_dorm` | Poprawione | Zuzanna: „Legitymacja jest w pokoju”, a na stole leżała LEGITYMACJA STUDENCKA. Portiera Edka przedstawiała ogólna kartka sąsiada („sąsiadka z naprzeciwka”). → dowód osobisty (`doc: id`), karta `manager` (administracja akademika, lokal 412, własna wymiana z Edkiem). Zostaje: tabliczka „Pralnia” przy szafkach (grafika). |
| `swiatniki_journeyman_padlock` | Poprawione | DE sytuacja miała metakomentarz „(erfundener Mechanismus)”. → DE jak EN. |
| `t43_09_01_winter_keys` | Poprawione | Roman potwierdza przez domofon, a karta proponowała „zadzwońmy do zarządcy”. → własna wymiana. |
| `t43_09_02_blanket_cupboard` | OK | |
| `t43_09_03_wooden_postbox` | OK | |
| `t43_09_04_choir_case` | OK | |
| `t43_09_05_receipt_safe` | OK | |
| `t43_09_06_draughty_hall` | OK | |
| `t43_09_08_spare_key_hook` | Poprawione | Świadek pani Teresa mieszka piętro niżej i stoi obok, a wymiana mówiła „sąsiadka z naprzeciwka”, „zapukam obok”. → własna wymiana („Piętro nad nią. Tym razem sprawdziłem.”). Zostaje: zdjęcie dzienne ma drzwi 12, a pan Kazimierz mieszka pod 21 (`wrong_floor`); pasującego zdjęcia nie ma (grafika). |
| `t43_10_01_renovator_bureau` | OK | |
| `t43_10_02_scaffold_store` | Poprawione | „Kierowniczka remontu kamienicy”, a potwierdza administrator bloków osiedla (Roman). → „kierowniczka ekipy remontowej” (5 języków). |
| `t43_10_03_exhibit_clock` | OK | Naprawa ma przycisk „Sprawdź zgodę na otwarcie”, bo tak działa wybór tekstu w kodzie. Drobiazg. |
| `t43_10_04_design_cabinet` | Poprawione | Pracownia Marty miała tabliczkę „Warsztat ślusarski”, a w „Plakatach za drzwiami” ta sama pracownia ma drzwi 12. → `place: apartment`, `time: day` (drzwi 12, jak w „Plakatach”). |
| `t43_10_05_porters_drawer` | OK | |
| `t43_10_06_shared_room_entry` | OK | |
| `t43_11_01_wooden_market` | OK | Zostaje: targ pokazuje drzwi warsztatu ślusarza (grafika). |
| `t43_11_02_bicycle_stand` | Poprawione | Borys: „Na zdjęciu ma pan też mój dawny wąs” (l.3–4), a zdjęcie to rower bez ludzi (stop-klatka z `bike_interview`). → podpis: „Mój, sprzed renowacji. Ta sama rama. Wąs widać w dzwonku, w odbiciu.” Bez ponownego nagrania. Zostaje: to ten sam kadr co rower Kuby z rozdz. 1 (wybór D-95). |
| `t43_11_03_tool_exchange` | OK | |
| `t43_11_04_sailors_stall` | OK | |
| `t43_11_05_rehearsal_chest` | OK | |
| `t43_11_07_wrong_delivery` | Poprawione | Kurier odpowiadał przy fakturze „Na mnie, z moim adresem”. Pan Stefan był „sąsiadką z naprzeciwka”, która „mieszka pod tym adresem”. → dwie własne wymiany (dokument dostawy na odbiorcę, Stefan zna każdy numer). |
| `t43_12_01_letters_archive` | OK | |
| `t43_12_02_detective_cabinet` | Poprawione | Skrzynia muzeum stała w „szatni” z tabliczką „Pralnia”. → `place: museum`, `arrival_from: job.museum_time_lock` (sala skarbca, D-102). |
| `t43_12_03_community_store` | OK | |
| `t43_12_04_school_box` | OK | |
| `t43_12_05_tea_fund_case` | OK | |
| `t43_12_07_clock_back_home` | OK | Uwaga jak przy `t43_10_03`. |
| `t43_12_08_henryks_bench` | Poprawione | Dokument przekazania należy do ślusarza, a pan Władysław odpowiadał „Na mnie” i „wiem, że to moje”. → własne wymiany przy akcie („Henryk sam ją wpisał, znam jego pismo”) i świadku („Była Henryka, teraz jest pańska”). |
| `time_capsule` | Poprawione | Kapsuła spod kasztanowca na terenie szkoły pokazywała klatkę z drzwiami 12. → `place: yard` (plener, bez tabliczki). |
| `uncle_safe_heirs` | OK | |
| `warm_room_for_neighbours` | Poprawione | Uchwała mieszkańców (l.2) leżała jako „Pismo instytucji”. Zgoda zarządczyni była „przez telefon”, a karta mówiła „Zarząd. Jest podpis i pieczątka.” → `resolution` i własna wymiana przy zarządczyni („Można do niej zadzwonić, utknęła w śniegu”). |
| `widow_bureau` | OK | |
| `wigilia_table_drawer` | Poprawione | Uchwała (l.3) leżała jako „Pismo instytucji”. → `resolution`. |
| `winter_bicycle_cellar` | OK | |
| `wooden_winter_village` | OK | |
| `wrong_floor` | Poprawione | Sytuacja EN/DE/FR/ES zdradzała rozwiązanie („He is one floor down from his own flat”), zanim gracz dopyta o numer. → sytuacja jak w PL (klucz nie pasuje, wieniec, inne nazwisko). |
| `zuzanna_catalogue_drawer` | Poprawione | Szuflada muzeum pokazywała klatkę z drzwiami 12. → `place: museum`, `arrival_from: job.museum_time_lock`. |

## Czego nie zmieniłem (poza zakresem albo wymaga grafiki)

- **Drzwi 7 z G07 (wieczór) to też numer pani Haliny.** Wieczorne zlecenia bez scenki pokazują tabliczkę 7: świetlica w
  Śródmieściu (kolędnicy, Wigilia, ciepła sala, niespodzianka), sekretarzyk pani Ireny, Bruksela, Charleroi, sejf
  wujka. Bez nowych zdjęć da się to zmienić tylko porą (dzień = 12, deszcz = 9, noc = 5), a ta wchodzi w tekst. Do
  decyzji przy następnym renderze: osobne drzwi świetlicy.
- **Tabliczki G01 przy miejscach zastępczych.** `locker` ma „Pralnia / Laundry” (sala prób, akademik, portiernia, skrzynie
  na targu i w szkole). `workshop` ma „Warsztat ślusarski” (warsztat Gosi). `gate` ma „Administracja” (beginaż). To
  stałe w `job_arrival.gd` i plikach grafiki, więc ich nie ruszałem. Zamówienie: zdjęcia G07 korytarza akademika,
  sali prób i nabrzeża albo miejsca bez tabliczki.
- **`t43_11_02_bicycle_stand`** używa tego samego kadru roweru co `bike_interview` (D-95). Lepiej byłoby dać mu własne
  zdjęcie roweru Borysa.
- **Dane bez wpływu na grę:** `threshold` nie zgadza się z opisem `verification` (np. `bike_interview` 3 vs „próg 2”,
  `cat_bathroom` 3 vs „próg 0”). Gra progu nie używa (REVIEW-T43). Klucze `job.*.note` (zeszyt) nie są dziś nigdzie
  wyświetlane.
- **Kwestie nagrane z drobnymi rozjazdami, bez potrzeby nagrania:** EN „Easiest permission check” w Charleroi (rodzaj
  `object`), „synku” jako *dear* / *son* w rosole, „Album” w „dniu po” Krystyny (to skrzynka na zdjęcia).

## Sprawdzenie

- `tools/i18n_lint.py`: 0 błędów.
- `tools/local/win_build_lockcore.sh` i pełny `tools/local/run_gut.sh`: import, lock_test, smoke i GUT zielone (387/387 testów, 46 116 asercji).
- Testy, które pilnują zmienionych danych: `test_job_places_props.gd` (karty z rekwizytem, zdjęcie z danych i
  wymianą, dowód i zarządca z danych), `test_verify_kind.gd` (świadek i wymiany według rodzaju; rosół zachowuje
  ogólną wymianę), `test_job_verify.gd`.
