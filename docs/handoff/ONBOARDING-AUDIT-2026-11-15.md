# Audyt pierwszych 10 minut — 2026-11-15 (D-134)

Zakres: świeża instalacja od uruchomienia do powrotu na listę po trzech pierwszych zleceniach
(start → karta pierwszego uruchomienia → menu → wybór sterowania → samouczek S1–S3 → lista zleceń →
przyjazd, weryfikacja, zamek, rachunek, „następnego dnia” × 3). Język PL (źródłowy) i EN, oba tryby sterowania.
Powiązane: `docs/ONBOARDING.md` §3–§4, `docs/HUD.md`, D-52, D-83, D-95, D-120, D-121, D-129, D-130,
`CLOSED-TEST-PLAN.md` (metryki T1/T2).

## 1. Jak mierzone

- **Przejście skryptowe:** `qa/run_onboarding.sh` (bot `qa/bot/onboarding.gd`) uruchamia grę z pustym
  katalogiem zapisu (`XDG_DATA_HOME`), krokiem 120 Hz, i idzie prawdziwymi ekranami. Liczy: stuknięcia,
  ekrany, sekundy, w których nie da się nic zrobić („czekanie”), słowa widoczne na ekranie (tylko to,
  co mieści się w oknie), czas do pierwszego otwartego zamka. Z oknem (`QA_SHOTS=katalog`, xvfb) zapisuje
  zrzut każdego ekranu w kolejności, w jakiej widzi je gracz.
- **Zamki:** S1–S3 (zamki autorskie) gra „cierpliwy gracz” z `qa_sampler.gd`; zamki zleceń grają boty
  lockcore `--feel` i `--clumsy` (`replay_tool record`), te same co w bocie kariery.
- **Szacunek „człowiek”:** czas bota + czytanie 180 słów/min + 0,8 s na stuknięcie. To wskaźnik do
  porównań przed/po, nie prognoza T1 z testu z ludźmi (bot otwiera S1 w 0,8 s; `check_locks --feel 200`
  dla `s1.json`: 100 %, mediana 1,1 s — człowiek będzie potrzebował kilkunastu sekund).
- Scenka przyjazdu na klatce (2,5 s) kończy się po stuknięciu, więc nie liczy się do „czekania”.

## 2. Wyniki przed / po

PL, napięcie automatyczne, bot „feel” (zamki zleceń). W nawiasie bot „clumsy”, gdy wynik jest inny.

| Punkt | | czas bota | stuknięcia | ekrany | czekanie | słowa | szacunek „człowiek” |
|---|---|---|---|---|---|---|---|
| Pierwszy zamek na ekranie | przed | 11,0 s | 4 | 5 | 8,8 s | 106 | 49,5 s |
| | **po** | **1,8 s** | **3** | **3** | **0,1 s** | **70** | **27,6 s** |
| Pierwszy zamek otwarty (T1 bota) | przed | 12,3 s | 4 | 6 | 10,6 s | 118 | 54,8 s |
| | **po** | **3,1 s** | **3** | **4** | **2,0 s** | **82** | **32,9 s** |
| Pierwszy zamek zlecenia na ekranie | przed | 37,1 s | 11 | 15 | 12,4 s | 338 | 158,5 s |
| | **po** | **27,3 s** | **9** | **12** | **3,7 s** | **298** | **133,8 s** |
| Pierwszy zamek zlecenia otwarty (T2 bota) | przed | 62,5 s (43,0 s) | 11 | 16 | 14,3 s | 350 | 187,9 s (168,5 s) |
| | **po** | **52,7 s (33,2 s)** | **9** | **13** | **5,5 s** | **310** | **163,2 s (143,7 s)** |
| Lista po 3 zleceniach | przed | 109,6 s (65,7 s) | 23 | 31 | 15,9 s | 922 | 435 s (389 s) |
| | **po** | **99,8 s (55,9 s)** | **21** | **28** | **7,2 s** | **882** | **411 s (364 s)** |

- EN: te same czasy i stuknięcia; słowa do pierwszego zamka 127 → 84.
- Dwa kciuki: jedno stuknięcie więcej (wybór tabliczki), reszta bez zmian.
- Czasy zamków bez zmian (balansu lockcore i danych zleceń nie ruszałem): S1 0,8 s, S2 3,2 s, S3 10,1 s
  („cierpliwy”); zlecenia 1–3 „feel”: 24,9 s (zamek z kółkami), 21,6 s i 6,6 s (zamki z przegrodami);
  „clumsy”: 5,5 s, 1,9 s, 1,9 s.
- Czekanie, które zostało (7,2 s na całej drodze): pochwała po S1 1,8 s, otwarty zamek 0,85 s × 4
  (D-130), zdanie zamykające lekcji zamka z kółkami 1,8 s, animacja wciśnięcia tabliczki menu 0,12 s × 2.
  To są chwile nagrody, nie puste ekrany.
- Cel z `ONBOARDING.md` §3 („od ikony do pierwszego dotyku zamka ≤ 25 s”): szacunek „człowiek” 49,5 s → 27,6 s.

Zrzuty (PL, 412×915): `docs/handoff/device-tests/fixes/onboarding/`
`before_to_first_lock_pl_412x915.jpg`, `after_to_first_lock_pl_412x915.jpg`,
`before_tutorial_end_and_verify_pl_412x915.jpg`, `after_tutorial_end_and_verify_pl_412x915.jpg`,
`after_first_job_pl_412x915.jpg`.

## 3. Uwagi — ranking

Waga: **W** wysoka (gracz traci czas albo nie wie, co dalej), **Ś** średnia, **N** niska.

| # | Waga | Gdzie | Co było nie tak | Stan |
|---|---|---|---|---|
| 1 | W | Start, pytanie o haptykę | Po odpowiedzi ekran zostawał pusty do końca 6-sekundowego licznika (5,6 s). Dwa stuknięcia grały w chwili pokazania karty, zanim dało się przeczytać pytanie, i nie dało się ich powtórzyć. Po 6 s karta sama znikała z odpowiedzią „dwa”. Tekst z żargonem („120 ms od siebie”). | **Poprawione** |
| 2 | W | Start, notka „to gra, nie kurs” | Osobna karta na 3 s: nie do pominięcia i za krótko na 22 słowa (ok. 7 s czytania). Ta sama treść potem jeszcze raz na ekranie etapu 1 i w „O grze”. | **Poprawione** (jedna karta razem z pytaniem, czeka na gracza) |
| 3 | W | Koniec samouczka | Ekran mówił „Pierwsze prawdziwe zlecenie!”, a „Kontynuuj” prowadziło do menu głównego. Tam „Zacznij dyżur” — tabliczka, którą gracz zaczął samouczek — otwierało tryb ciągły („Zamek 1 · życia: 3”), a zlecenia były pod inną tabliczką. | **Poprawione** |
| 4 | W | Notka o pobieraniu głosów (D-100) | Przez całe pobieranie (minuta i więcej przy pierwszym uruchomieniu) pasek z procentami leżał na dole ekranu: na głównej tabliczce każdego ekranu („Sprawdź…”, „Odmów”, „Zacznij ćwiczenie”) i w zamku na strefie kciuków. | **Poprawione** (4 s u góry, nigdy na zamku) |
| 5 | W | Weryfikacja | Nic nie mówiło, że kartę można stuknąć i o nią zapytać („Klient kładzie karty na stole. Ty decydujesz.”). Karty wyglądały jak obrazki. Test zamknięty mierzy właśnie to („czy gracz otworzył karty, czy zadał pytanie”). | **Poprawione** (podpowiedź do pierwszego pytania) |
| 6 | Ś | Ekran etapu 1 | Trzecie objaśnienie tego samego: karty przed zamkiem, potem trener w zamku mówi to samo innymi słowami („podnoszenie” / „unoszenie” / „unieś”; „Prawy:” / „Prawy kciuk:” / „Kciuk”). Przy zamku z jednym pinem karta mówiła „Szukaj następnego”. | **Poprawione** (pierwsze uruchomienie idzie prosto do zamka; karty mają zdania trenera; osobny podpis dla jednego pinu) |
| 7 | Ś | Wybór sterowania | Tytuł „Jak chcesz trzymać napięcie?” pyta o pojęcie, którego gracz jeszcze nie zna. Opis trybu miał 14 słów. „Kontynuuj” nie mówiło, co dalej. | **Poprawione** („Jeden kciuk czy dwa?”, opis 8 słów, „Zacznij ćwiczenie”) |
| 8 | Ś | Samouczek | Nie dało się go pominąć (ponowna instalacja, drugi telefon). Etap przepadał po zamknięciu gry (S2 → znowu S1). | **Poprawione** (pauza → „Pomiń samouczek”; etap w zapisie) |
| 9 | Ś | Otwarcie zamka ćwiczebnego | Jedyne otwarcie w grze bez frazy „drzwi otwarte” (zlecenia mają ją na rachunku). Koniec samouczka bez żadnego dźwięku. | **Poprawione** (istniejące dżingle, bez nowych plików) |
| 10 | W | Dane zleceń — kolejność rodzin | Samouczek uczy zamka bębenkowego (3 zamki), a trzy pierwsze zlecenia to zamek z kółkami i dwa z przegrodami. Pierwszy zamek bębenkowy jest piąty–szósty na liście. Każda rodzina ma swoją lekcję, więc gracz sobie poradzi, ale to, czego się właśnie nauczył, nie przydaje się od razu. | **Do decyzji właściciela** (dane zleceń — nie ruszałem) |
| 11 | W | `job.cat_bathroom` | Ślusarz mówi „Dokumentów tym razem nie trzeba”, po czym przycisk brzmi „Sprawdź prawo do lokalu”, a na stole leży „Dokument tożsamości”. | **Do decyzji właściciela** (dane zlecenia i kwestia nagrana — zmiana słów wymaga nagrania) |
| 12 | Ś | Lista zleceń | Nowy gracz widzi od razu całą karierę (12 rozdziałów, ponad 80 tabliczek) bez wskazania, od czego zacząć. | **Przekazane** — plik `jobs_list.gd` zmienia równolegle inny agent (kafelki zleceń) |
| 13 | N | Rachunek | Kwoty trzy razy: na pokwitowaniu, w „Razem” i pod spodem („Nagroda: 65 monet”, „Napiwek…”). | Zostawione (czytelne, nie blokuje) |
| 14 | N | Etapy 2 i 3 | Po otwarciu S2 i S3 nie ma zdania pochwały (jest tylko po S1). | Zostawione (to samo zdanie trzy razy byłoby gorsze; S3 kończy ekran „Samouczek ukończony” z dżinglem) |
| 15 | N | Ekran „Samouczek ukończony” | Pusty: tytuł, zdanie i tabliczka u góry ekranu, poza strefą kciuka. | Zostawione |
| 16 | N | Pytanie o haptykę na komputerze / iPadzie | Pytanie pada także tam, gdzie nie ma silnika wibracji (`ONBOARDING.md` §3.2 każe je pominąć). | Zostawione (wymaga wykrywania sprzętu; odpowiedź „Nic” robi to, co trzeba) |

Ślepych zaułków nie znalazłem: każdy ekran ma wyjście (tabliczka albo Wstecz), bot przechodzi całość
bez zatrzymania w obu trybach sterowania i w obu językach.

## 4. Co zmieniłem

1. **Jedna karta pierwszego uruchomienia** (`boot.gd`, `boot.tscn`). Pytanie „Czujesz dwa kliknięcia?”
   (to samo zdanie co w Ustawieniach → Haptyka → Kalibracja), trzy tabliczki z kropkami ●● / ● / ○
   i słowem, „Jeszcze raz” powtarza bodziec, pod spodem notka „To gra, nie kurs…”. Bodziec gra 0,6 s
   po pokazaniu karty i jest tylko haptyczny (jak w Ustawieniach; z dźwiękiem każdy „słyszy dwa”).
   Karta czeka na odpowiedź, a po niej gra idzie dalej w tej samej klatce. Gdy haptyka jest już
   ustawiona (plik ustawień z wcześniejszej instalacji), karta ma samą notkę i „Kontynuuj”.
2. **„Zacznij dyżur” → wybór sterowania → od razu zamek S1** (`control_choice.gd`). Ekran etapu 1
   zostaje dla gracza, który wraca do przerwanego samouczka.
3. **Koniec samouczka prowadzi do zleceń** (`tutorial.gd`, `main_menu.gd`): ekran „Samouczek ukończony /
   Trzy zamki otwarte. Teraz pierwsze prawdziwe zlecenie.” z tabliczką „Pierwsze zlecenie” → lista
   zleceń. „Zacznij dyżur” w menu otwiera listę zleceń, dopóki gracz nie ukończy 3 zleceń; potem tryb
   ciągły jak dotąd (N-64).
4. **Notka o pobieraniu głosów** (`voice_packs.gd`): raz na początku pobierania, 4 s, u góry pod paskiem
   stanu; „gotowe” / „brak sieci” tak samo; nigdy na ekranie zamka. Postęp jest w Ustawieniach → Głosy.
5. **Weryfikacja** (`job_verify.gd`): „Stuknij kartę, żeby o nią zapytać. Potem zdecyduj.” — do
   pierwszego zadanego pytania (zapis `verify/card_asked`), potem dotychczasowe zdanie.
6. **Teksty** (`strings.csv`, 5 języków; 7 nowych kluczy na końcu, 6 zmienionych): tytuł i opis wyboru
   sterowania, podpisy kart samouczka zrównane ze zdaniami trenera, podpis dla zamka z jednym pinem.
   Żaden klucz nagrany głosem się nie zmienił (nagrane są tylko `*.line.N` i `*.after.N` z `content.csv`).
7. **Samouczek do pominięcia i do wznowienia** (`lock_photoreal.gd`, `job_run.gd`): tabliczka „Pomiń
   samouczek” w pauzie zamka ćwiczebnego → lista zleceń; etap zapisany (`tutorial_stage`).
8. **Otwarcie zamka ćwiczebnego** gra frazę `jingle_door_open` (−8 dB), ekran końca samouczka
   `jingle_new_chapter` — istniejące pliki.
9. **Bot kariery** naciska odpowiedź na karcie startowej (wcześniej czekał, aż zniknie sama).

Testy: `game/tests/gut/test_onboarding_flow.gd` (16 testów). Pełny GUT: 556 testów, 555 zielonych
(czerwony tylko znany z D-130 `test_tutorial_hints.gd::test_progress_resets_the_ladder`). Bot kariery
(`qa/run_career.sh`, profil „feel”): `career_complete`, 103 + 19 ze 123 zleceń, 0 soft-locków.

## 5. Do sprawdzenia na telefonie przez właściciela

- Karta startowa: czy dwa kliknięcia 0,6 s po pokazaniu karty są wyraźne, i czy „Jeszcze raz” wystarcza.
- Fraza „drzwi otwarte” przy otwarciu zamka ćwiczebnego (−8 dB): czy nie za głośno przy kliku zamka.
- Notka o głosach u góry przez 4 s: czy nie przeszkadza na ekranie menu.
- Uwagi 10 i 11 (kolejność rodzin w rozdziale 1, kwestia ślusarza przy kocie) — decyzja o danych zleceń.

## 6. Jak powtórzyć

```bash
qa/run_onboarding.sh <godot>                         # liczby (headless), raport w qa/out/onboarding/
QA_PROFILE=clumsy QA_LANG=en qa/run_onboarding.sh <godot>
QA_SHOTS=/tmp/onb QA_JOBS=1 qa/run_onboarding.sh <godot>   # zrzuty każdego ekranu (xvfb)
```
