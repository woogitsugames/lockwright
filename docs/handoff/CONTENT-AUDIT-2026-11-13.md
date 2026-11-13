# Audyt treści rozdziałów 13–15 — 2026-11-13

Niezależna redakcja 30 zleceń napisanych w trzech sesjach (D-111, D-119, D-123), według zasad audytu D-104
(`CONTENT-AUDIT-2026-11-09.md`). Przeczytana pełna ścieżka gracza w każdym zleceniu, we wszystkich pięciu językach:
tytuł, klient, sytuacja, cztery kwestie rozmowy, karty z `card_detail` i ich wymiany zdań (własne i ogólne ze
`strings.csv`), kwestie „dzień po”, opis `verification`, miejsce, pora, `arrival_from` i tabliczka. Ciągłość
sprawdzona z tekstami rozdziałów 1–12 w `content.csv` (nie z pamięci): wszystkie wcześniejsze zlecenia postaci, które
wracają, oraz finały rozdziałów 4 i 12.

**Wynik:** 17 × OK, 13 × poprawione (46 komórek w `content.csv`, 6 pól w plikach zleceń). Żadna kwestia nie jest
jeszcze nagrana (`voice_pending`), więc nic nie trafia do `REVOICE.md`. `tts_inputs_ch13/14/15.json` i tabela
w `contrib/voice/PENDING.md` są zsynchronizowane ze zmienionymi kwestiami (wygenerowane tym samym kodem:
`voice_lines.tts_payload`; przed zmianami generator odtwarzał wszystkie trzy pliki co do znaku).

## Najważniejsze poprawki

### 1. `job.refuse_ch15_08_no_answer` — pani Zosia pod drzwiami pani Haliny

Scena była ułożona dobrze: ślusarz nie otwiera na samo zmartwienie sąsiadki i wskazuje drogę szybszą niż wytrychy,
czyli klucz, który pani Halina **sama** zostawiła w kopercie z nazwiskiem pani Zosi (uchwała z rozdz. 14: klucz
wydaje zarządczyni właścicielowi albo osobie wskazanej na kopercie). Brakowało jednego: przy 81-letniej sąsiadce, która
od rana nie odpowiada, odpowiedzialny fachowiec mówi wprost, że w razie czego wzywa pomoc. „Telefon mam w ręku” tego
nie mówiło.

| kwestia | było | jest |
|---|---|---|
| `line.2` (ślusarz) | „…a na kopercie stoi pani nazwisko.” | „…a na kopercie **sama wpisała** pani nazwisko.” (wola lokatorki, nie przypadek) |
| `line.4` (ślusarz) | „…Idę z panią, telefon mam w ręku.” | „…Idę z panią. **Gdyby coś było nie tak, od razu wzywam pogotowie.**” |

W pięciu językach (EN *I call an ambulance*, DE *Notruf*, FR *les secours*, ES *emergencias*; bez numeru telefonu,
bo ten zależy od kraju). Opis `verification` w pliku zlecenia dostał zdanie o drodze zastępczej: gdyby wskazanego
klucza nie było, dzwoni się pod numer alarmowy, a drzwi otwiera się tylko przy służbach. Zasada z `CLIENTS.md` §4.1
(„zawsze jest legalna droga”) jest zachowana, a odmowa dalej zaczyna się od „Tu nie otworzę.” i nikogo nie oskarża.
Na stole leży tylko dokument pani Zosi. Scena przyjazdu to drzwi nr 7 bez postaci (`arrival_from: job.grandma_broth`,
sam kadr), więc obraz nie przeczy temu, że pani Halina śpi w środku.

### 2. `job.ch15_01_wrong_envelope` — sprzeczność z rozdziałem 9

W rozdz. 9 (`job.t43_09_08_spare_key_hook`) klucz z koperty u pani Teresy został sprawdzony w drzwiach („Sprawdźmy go
razem”), a koperta wróciła do szuflady podpisana dwa razy. W rozdz. 15 pan Kazimierz mówił, że „kiedyś włożył” do niej
kluczyk od piwnicy, a pani Teresa, że „do środka nikt nie zajrzał”. To nie mogło być prawdą jednocześnie.

- `line.1`: „…Klucze zostały w jeziorze. A zapasowy pożyczyłem wiosną z koperty i oddałem pani Teresie kluczyk od piwnicy.”
- `line.2`: „…Kopertę podpisał dwa razy i leżała u mnie w szufladzie. Tylko od wiosny nikt do niej nie zajrzał.”

Pięć języków. „Dzień po” („Sprawdziliśmy go w drzwiach, zanim ją zakleiłam”) pasuje bez zmian.

### 3. `job.refuse_ch14_08_early_present` — tata stał przy szafce

Prezent leży w szafce „w warsztacie taty”, Hania prosi, żeby tacie nie mówić, a ślusarz odpowiadał „zapytamy go, jest
w warsztacie”. Tata byłby więc obok szafki. → „…jest w kuchni” (5 języków).

## Zlecenia

Legenda jak w audycie D-104: **OK** = bez sprzeczności. **Poprawione** = zmiana napisów (nienagranych) albo danych.

| zlecenie | wynik | co było nie tak → co zmieniłem |
|---|---|---|
| `ch13_01_balcony_boxes` | OK | Komórka nr 7 = numer drzwi pani Haliny; „czterdzieści lat” jak w rozdz. 1. |
| `ch13_02_first_ice_cream` | OK | |
| `ch13_03_allotment_gate` | OK | Działka na żonę (rozdz. 3) nie wchodzi w grę: brama jest wspólna, zgoda zarządu ogrodu. |
| `refuse_ch13_04_winter_bike` | Poprawione | EN/ES mówiły, że pani Teresa miała nogę w gipsie „całą zimę”, a w rozdz. 9 (zima) stoi na klatce i schodzi po kopertę. PL/DE/FR mówią „zimą”. → EN *this winter*, ES *este invierno*. |
| `ch13_05_planted_key` | OK | Lala, „zamek jak u pradziadka” i Willowa Górka zgodne z rozdz. 3. |
| `ch13_06_bike_repair_stand` | OK | Kuba w „dniu po” jak w rozdz. 11. |
| `ch13_07_museum_night_case` | OK | EN/DE/FR w polu klienta mówią „Noc Muzeów” bez „przed” (limit 40 znaków); sytuacja to wyjaśnia. |
| `refuse_ch13_08_found_cashbox` | OK | Trzecia odmowa wobec Oskara (rozdz. 8 i 9) działa jak żart powracający; pani Janka wynajmuje piwnicę u pani Elżbiety (rozdz. 8). „Znaleźne” zgodne z tonem i z prawem. |
| `ch13_09_pizzeria_terrace` | Poprawione | EN *the float* (brytyjskie) → *the opening cash*. |
| `ch13_10_courtyard_door` | OK | Świetlica otwarta w rozdz. 7, więc „tylne drzwi nieotwierane od trzydziestu lat” się zgadza. |
| `ch14_01_summer_storage` | Poprawione | EN *placement* (brytyjskie) → *internship* (sytuacja, „dzień po”). Kwestia pana Edka cytuje rozdz. 1 celowo. |
| `ch14_02_ship_time` | OK | Aino jest oficerem mechanikiem (rozdz. 6); „naprawiam chód, godziny otwarcia nie ruszam” trzyma ton. |
| `ch14_03_books_under_linden` | OK | Pani Irena: emerytowana bibliotekarka, wdowa, „bez wiercenia” (rozdz. 3). |
| `refuse_ch14_04_paid_week` | Poprawione | Dokument na „Magda” przy konwencji imion urzędowych w dowodach (Dariusz, Zbigniew, Bartłomiej). → `holder: Magdalena`. Tekst bez zmian. |
| `ch14_05_cat_passport` | OK | |
| `ch14_06_suitcase_flew_on` | OK | Kalisz, czwarta rano, sąsiad w szlafroku, komplet kart jak w rozdz. 2. Kasia nie mówi (w obsadzie „Panna młoda”), pada tylko jej imię. |
| `ch14_07_prize_cupboard` | Poprawione | FR gubiło powrót żartu z kapsuły czasu („data, tylko czyja?”): *je ne sais plus laquelle* → *je ne sais plus de qui* (jak w rozdz. 6 FR). |
| `refuse_ch14_08_early_present` | Poprawione | Patrz wyżej, pkt 3. Legitymacja szkolna na „Hania” → `holder: Hanna`. |
| `ch14_09_summer_cinema` | Poprawione | Ślusarz mówił „zgoda sali”, a kartę wystawia kierownik sali. → „Zgoda kierownika sali i pismo uczelni się zgadzają.” (5 języków). |
| `ch14_10_holiday_keys` | OK | Treść uchwały niesie potem odmowę z rozdz. 15. |
| `ch15_01_wrong_envelope` | Poprawione | Patrz wyżej, pkt 2. EN klient: *back from the lakes* → *straight from the lake*. |
| `ch15_02_apple_press` | OK | Klucz „na szyi” pana Waldka od rozdz. 13. |
| `ch15_03_charleroi_box` | OK | Kasetka z piwnicy (rozdz. 5) i szkatułka ze strychu rozróżnione w kwestii pani Martine; drzwi nr 14 (D-117); pani Krystyna to córka Józefa, Ola wnuczka. |
| `refuse_ch15_04_closed_attic` | OK | Leon wynajmuje u pani Elżbiety (rozdz. 8), więc strych zamyka ona. Odmowa jest rzeczowa: zamknięcia dla bezpieczeństwa nie zdejmuje ślusarz, a ślusarz od razu proponuje przyspieszenie terminu. Uwaga niżej o strażakach. |
| `ch15_05_first_vacation` | OK | „Nowy sejf” obok małego sejfu z rozdz. 9 się nie gryzie. |
| `ch15_06_bike_by_train` | Poprawione | PL: „wróciła z urlopu na rowerze. Rower wrócił pociągiem” czytało się jak sprzeczność. → „wróciła z rowerowego urlopu. Rower przyjechał pociągiem…”, klient „prosto z rowerowego urlopu”; FR i ES tak samo. |
| `ch15_07_skeleton_cupboard` | Poprawione | EN *caretaker* (brytyjskie) → *janitor* (3 komórki). Dokument na „Ola” → `holder: Aleksandra`. |
| `refuse_ch15_08_no_answer` | Poprawione | Patrz wyżej, pkt 1. `holder: Zofia`. |
| `ch15_09_key_board` | Poprawione | EN *placement* → *internship*. `holder: Edward`. |
| `ch15_10_exam_lock` | Poprawione | EN *placement* → *internship* (sytuacja). Finał nie przeczy rozdz. 4 ani 12, szczegóły niżej. |

## Finał rozdziału 15 a rozdziały 4 i 12

- Rozdz. 4: pan Władysław „chce zobaczyć, czy młodzi jeszcze umieją” i rozpoznaje pismo Henryka w zeszycie. Rozdz. 15:
  wpisuje do tego samego zeszytu „umie”. Tłumaczenia trzymają to echo (*if the young ones still can* → *she can do it*,
  *ob die Jungen es noch können* → *Sie kann es*, *savent encore faire* → *elle sait*, *saben hacerlo* → *sabe*).
- Rozdz. 12: Władysław mówi Zuzannie „Siadaj. Najpierw zapytaj, czyje to.” (na ty). W rozdz. 15 mówi o niej w trzeciej
  osobie, a do ślusarza „Teraz pan”. Ślusarz zaczyna od „Najpierw pytam, czyje to i czy wolno”. Zgodne.
- „Stół Henryka” / *Henryk's bench* jak w rozdz. 12. „Egzamin bez rosołu się nie liczy” odpowiada na „Rosół czeka. Tym
  razem proszę zabrać też uczennicę.”
- „Dwanaście kopert wróciło do właścicieli. Żadnych z tych drzwi nie musiałem otwierać.” To prawda w danych: koperta pana
  Kazimierza leżała u pani Teresy, nie w świetlicy, a klucz pani Haliny wyszedł z szafki do osoby wskazanej na kopercie.

## Sprawdzone i zostawione

- **Strażacy przy szerszeniach** (`refuse_ch15_04`). W Polsce straż usuwa gniazda głównie tam, gdzie jest zagrożenie
  (w innych przypadkach zarządca zamawia firmę), a „termin na czwartek” brzmi bardziej jak firma. Gracz to przyjmie,
  a scena mówi rzecz ważniejszą (zamknięcie zdejmuje ten, kto je założył). Zmiana na „firmę od gniazd” to 10 komórek
  i inne słowa w DE (szerszenie pod ochroną, przenosiny gniazda). Do decyzji przy nagraniach.
- **Marek** (`refuse_ch13_04`) to brat ze „Sejfu wujka Bogdana” (rozdz. 3): ten sam pośpiech, ale tu „upatrzył sobie”
  cudzy rower. Scena go nie oskarża, a w „dniu po” nie wraca. Zostaje.
- **Motyw „zapomniany kod / szyfr”** wraca trzy razy w trzech rozdziałach (Renata, pani Jadwiga, pan Stefan), a
  „próbował wszystkich kluczy po kolei” dwa razy z rzędu (kino letnie, gablota pana Edka: ta sama rodzina zamka).
  To nie błąd, ale przy rozdz. 16 warto dać inne powody.
- **„Jutro wraca stu studentów”** pod koniec sierpnia (`ch15_09`): rok akademicki zaczyna się później. Zdanie nie
  podaje daty, a rozdział jest „o powrotach”. Zostaje.
- **Pora a obraz:** `ch14_01` (dzień) i `ch13_04` (wieczór) biorą przez `arrival_from` kadr zrobiony o innej porze
  (akademik nocą, stojak za dnia), `ch13_10` (dzień) kadr wieczorny. Tekst nie mówi o porze, więc nie ma sprzeczności;
  nowych renderów nie było.
- **Tabliczka „Pralnia”** przy szkolnych szafkach (`ch14_07`, `ch15_07`, miejsce `locker` bez `arrival_from`): znane
  ograniczenie z D-104, czeka na scenę szkolnego korytarza (lista D-119).
- **Drzwi nr 5 nocą w Śródmieściu** (`refuse_ch14_04`): numer z nocnego kadru, ten sam co u Agnieszki na Osiedlu. Inny
  budynek, inna dzielnica. Zostaje (D-119).
- **„Synku”** po angielsku: w rozdz. 13–15 konsekwentnie *son*, jak w rozdz. 7–12 (nagrane *dear* w rosole to znany
  wyjątek z D-104).
- **Rejestr:** PL: postacie do ślusarza „pan”, ślusarz do Hani na ty. DE *Sie*, FR *vous*, ES *usted* wobec ślusarza,
  *du / tu / tú* wobec Hani. Bez wykrzykników. Długości: tytuł ≤ 32, klient ≤ 40, sytuacja ≤ 140, kwestie ≤ 160 we
  wszystkich pięciu językach, także po poprawkach.
- **Ton:** żadna kwestia nie opisuje techniki ponad poziom gry („słucham tarczy”, „ten zamek pamięta złe klucze”,
  „bez wiercenia” to stwierdzenia, nie instrukcje). Sześć odmów pokazuje tylko dokument klienta, wskazuje legalną
  drogę i kończy się dobrze dla wszystkich.

## Sprawdzenie

- `tools/i18n_lint.py`: 0 błędów. `data/tools/validate.py`: 113 zleceń, OK. `data/tools/loc_qa.py`: OK.
  `pytest tools/tests`: 96/96. `tools/build_content_packs.py --check`: OK. `tools/voice_lines.py missing`: 795 (bez zmian).
- GUT (Godot 4.7.2 headless, pliki dotknięte zmianą): `test_chapter13_jobs` 7/7, `test_chapter14_jobs` 7/7, `test_chapter15_jobs` 7/7, `test_verify_kind` 7/7, `test_day_after` 14/14, `test_job_places_props` 13/13, `test_job_verify` 9/9 — razem 64 testy, 11 848 asercji, wszystko zielone (te pliki nie potrzebują lockcore_gd; pełny GUT i bot kariery zostają dla CI).
