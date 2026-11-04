# TOOLS — narzędzia gry

Status: szkic etapu researchu (2026-11-04). Wszystkie narzędzia to **wymyślone, ogólne kategorie**; sylwetki
i nazwy są własne gry, bez nawiązań do produktów i marek. Logika rodzin: `docs/LOCKS.md`. Ekonomia monet:
do uzgodnienia z `docs/PROGRESSION.md` (ceny poniżej to propozycja względna).

## 1. Zasady balansowania

1. **Każde narzędzie odblokowuje nową logikę, nie lepsze statystyki.** Narzędzie otwiera nową rodzinę albo nową
   technikę w istniejącej rodzinie. Nie ma „Haczyka +10% do okna”.
2. **Bez pay-to-win i bez grind-to-win.** Gra premium: monety tylko z gry, brak IAP na monety. Zakup narzędzia nie
   czyni starszych zamków trywialnymi (np. Falownik nie skończy zamka ze szpulką).
3. **Trudność zamka nie zależy od posiadanego narzędzia** w obrębie rodziny — weryfikator (`LOCKS.md` 1.9) zawsze
   sprawdza zamek **minimalnym** zestawem narzędzi wymaganym przez rodzinę.
4. **Kosmetyka oddzielnie:** wykończenia rękojeści (drewno, róg, owijka) zmieniają tylko wygląd i barwę dźwięku
   w ramach tej samej sygnatury czytelności.
5. **Utrata życia ≠ utrata zakupu.** Złamanie zużywa jedno z trzech „zapasowych ostrzy” w biegu Trybu Ciągłego;
   kupione narzędzie wraca do warsztatu do naprawy, nie znika.

## 2. Model zużycia (wspólny)

- **Integralność** `I ∈ [0, 100]` dla każdego narzędzia z ostrzem (wytrychy, obrotniki, sondy). Napinacze i narzędzia
  pomiarowe zużywają się tylko kosmetycznie (patyna).
- **Ubytki** (na zdarzenie, wartości bazowe):

  | Zdarzenie | ΔI | Uwagi |
  |---|---|---|
  | `contact` pod napięciem T > 0,5 | −0,1 | sumowane, max −2 na zamek |
  | `overset` | −1 | |
  | `stress` (każde wejście w strefę) | −2 | |
  | `counter_rotate` przy T > `cr_band` | −1 | uczy luzowania |
  | `detector_trip` / `detector.reset` | −1 | |
  | `break` | I → 0 | strata życia |

- **Wpływ:** `S_max(tool) = S_base × (0,7 + 0,3 × I/100)` — zużyte narzędzie łamie się wcześniej, do −30%.
  Zużycie jest **widoczne** na sylwetce (nacięcia na trzonie co 20 pkt) i emituje `wear` co 10 pkt — nigdy ukryte.
- **Naprawa w warsztacie:** przywraca `I = 100` za 15% ceny narzędzia (min. 5 monet); narzędzie złamane — 35% ceny.
  Naprawa jest nieograniczona. Między zamkami w biegu: brak naprawy (decyzja biegu = zarządzanie ryzykiem).
- **Zapasowe ostrza (Tryb Ciągły):** 3 na bieg = 3 życia. `break` dowolnego narzędzia z ostrzem zużywa jedno ostrze;
  bieżący zamek zostaje (postęp elementów `set` spada, czas biegnie dalej).

## 3. Lista narzędzi

Sylwetki projektujemy tak, by były rozróżnialne **sam kształtem** w skali szarości przy 48 dp (ikona) i przy
pełnym rozmiarze na ekranie. Dodatkowo każda rękojeść ma inny **wzór radełkowania** (kreski, kropki, krzyżyki,
pierścienie) — drugi kanał niezależny od koloru.

### 3.1 Nieniszczące — napinacze i siła

| ID | PL / EN | Sylwetka | Cena | Odblokowanie | Rodziny |
|---|---|---|---|---|---|
| `tw_angle` | Napinacz kątowy / Angle Tensioner | płaski pasek zgięty w „L” pod 90°, krótka stopka; rękojeść z kreskami | 0 (start) | start | pin_tumbler (t2–5), wafer, wafer_double, tubular* |
| `tw_bar` | Napinacz listwowy / Top Bar Tensioner | prosty, gruby pręt ze skręconą o 90° końcówką, bez zagięcia „L”; radełko krzyżyk | 600 | po t4 | pin_tumbler t5–7 („wąski kanał”), dimple, sidebar |
| `tl_shackle` | Ciągadło kabłąka / Shackle Puller | „U” z długim ramieniem i oczkiem na palec | 150 | po pierwszym zamku t2 | ring_combo |

\* koronka do zamków rurkowych ma napinacz wbudowany.

**Nowa logika `tw_bar`:** zajmuje górę kanału, więc w zamkach „wąskich” (atrybut generatora od t5) narzędzie dolne
nie mieści się z napinaczem kątowym. Dodatkowo napinacz listwowy ma **łagodniejszą** krzywą `k_tool` (0,85) —
to nie bonus, tylko inna charakterystyka: potrzeba większego wychylenia kciuka.

### 3.2 Nieniszczące — wytrychy i manipulatory

| ID | PL / EN | Sylwetka | Cena | Odblokowanie | Rodziny | Nowa logika |
|---|---|---|---|---|---|---|
| `pk_peg` | Podważka kołkowa / Peg Lifter | drewniany patyk z jednym ściętym czopem | 0 (start) | start | wooden_pin | unoszenie |
| `pk_hook` | Haczyk / Hook Pick | długi trzon, pojedynczy zadarty grot pod ~60°; radełko kreski | 0 (start) | po samouczku t1 | pin_tumbler, wafer, sidebar, (lever — nie) | pojedynczy element |
| `pk_ward` | Sonda przelotowa / Ward Probe | cienki drut z kwadratową chorągiewką na końcu; 3 wymienne groty (kwadrat, hak, widełki) jako ikony | 80 | po t1 | warded | wybór profilu + labirynt |
| `pk_ripple` | Falownik / Ripple Pick | trzon zakończony trzema łagodnymi garbami (fala), symetryczny; radełko kropki | 350 | po 5 zamkach t2 | wafer, pin_tumbler bez zabezpieczeń (≤ t3) | ruch wielu elementów naraz kosztem kontroli: na elementach zabezpieczających zawsze `false_set` |
| `pk_wedge` | Klin dwustronny / Twin Wedge | symetryczny romb na końcu (ostry z obu stron) | 700 | po t3 | wafer_double | ±lift, zmiana strony |
| `pk_lever` | Korba dźwigniowa / Lever Crank | dwuczęściowe: gruby pręt z kolankiem (ramię) + cienki pręt z flagą (podnośnik); w ikonie skrzyżowane | 500 | po t3 | lever, lever_detector | rozdzielenie siły i podnoszenia w głąb pakietu |
| `pk_crown` | Koronka / Crown Pick | rurka z jednym wystającym ząbkiem na krawędzi + obrotowy pierścień; sylwetka „korony” z jednym zębem | 900 | po t4 | tubular | wybór na okręgu, wciskanie, wiele obrotów |
| `tl_polar` | Sonda biegunowa / Polarity Probe | gruby walec z asymetryczną końcówką (ostry / tępy biegun) | 1 200 | po t5 | magnetic | pole zamiast momentu |
| `pk_flag` | Chorągiewka / Flag Pick | płaskie, szerokie ostrze z bocznym wypustkiem pod kątem | 1 500 | po t6 | dimple | rzędy, kąt natarcia |
| `pk_plunger` | Trzpień szczelinowy / Slot Plunger | rurka ze szczeliną wzdłuż i ruchomym bolcem; rękojeść okrągła z pierścieniami | 1 600 | po t6 | axial_slider | wciskanie suwaków, fałszywe wycięcia |
| `pk_disc` | Obrotnik tarcz / Disc Turner | dwie współosiowe części: długi pręt z półokrągłą końcówką + krótka tuleja z „noskiem”; sylwetka teleskopu | 1 800 | po t7 | disc_detainer | obrót tarcz bez sprężyn |
| `pk_feather` | Piórko boczne / Side Feather | bardzo cienki trzon z bocznym, poprzecznym „piórkiem” (płetwą) | 2 000 | po t7 (F3) | sidebar | obrót elementów (warstwa 2) |
| `tl_cup` + `tl_notes` | Słuchawka + Notes kontaktów / Listening Cup + Contact Notebook | okrągła czasza z krótkim pałąkiem + notes z ołówkiem | 2 200 (komplet) | po t8 | safe_wheels | odczyt punktów kontaktu, wykres |
| `kit_clock` | Zestaw zegarmistrza / Clockmaker's Kit | zwinięty skórzany futerał z pęsetą i kluczykiem zegarowym | nagroda wydarzenia | wydarzenie F2 | time_lock | naprawa, rytm |

### 3.3 Niszczące

| ID | PL / EN | Sylwetka | Cena | Dostępność | Koszt użycia |
|---|---|---|---|---|---|
| `tl_drill` | Wiertarka / Drill | pistoletowa bryła z krótkim wiertłem | 1 000 | **Tylko Tryb Zleceń** (F1+) | Zamek zniszczony (klient płaci za nową wkładkę/zamek — gracz zarabia mniej o koszt części), **−reputacja** (np. −10 przy t ≤ 5, −5 przy t ≥ 8 i przy sejfach, gdzie to bywa uzasadnione), czas 45–90 s mini-gry „stabilny docisk” bez zdradzania technik |

Zasady wiertarki:
- W Trybie Ciągłym **niedostępna** (propozycja; alternatywa w pytaniach otwartych).
- Mini-gra jest abstrakcyjna (utrzymanie docisku i chłodzenie), nie pokazuje miejsc wiercenia w realnych zamkach.
- Gra zawsze proponuje najpierw metody nieniszczące; dialog klienta przypomina, że wiercenie to ostateczność.

### 3.4 Świadomie wykluczone

Nie wprowadzamy narzędzi, które w realnym świecie służą głównie obejściu zabezpieczeń bez umiejętności lub mają
charakter instruktażowy dla przestępstw: klucze udarowe (bump), narzędzia do łamania wkładek, podkładki do obejścia
zatrzasków, dekodery do konkretnych typów, klucze „uniwersalne/szkieletowe” jako przedmiot. Wyrabianie kopii klucza
(impressioning) — ewentualnie przyszła fabuła warsztatowa, poza zakresem tej biblii.

## 4. Kolejność odblokowania w Trybie Ciągłym (propozycja)

Monety (orientacyjnie, do PROGRESSION.md): zamek = `10 × tier` + premia „czysto” (bez `drop`/`break`) +50%.

| Krok | Warunek | Narzędzie | Cena | Co nowego |
|---|---|---|---|---|
| 0 | start | Napinacz kątowy, Podważka kołkowa, Haczyk | 0 | wooden_pin, pin_tumbler t2, wafer |
| 1 | po t1 | Sonda przelotowa | 80 | warded |
| 2 | po 1. zamku t2 | Ciągadło kabłąka | 150 | ring_combo |
| 3 | po 5 zamkach t2 | Falownik | 350 | technika „fali” na płytkach |
| 4 | po t3 | Korba dźwigniowa | 500 | lever (+ detektor w F1/MVP opc.) |
| 5 | po t3 (F1) | Klin dwustronny | 700 | wafer_double |
| 6 | po t4 | Napinacz listwowy | 600 | pin_tumbler „wąski” t5+ |
| 7 | po t4 (F1) | Koronka | 900 | tubular |
| 8 | po t5 (F2) | Sonda biegunowa | 1 200 | magnetic |
| 9 | po t6 (F2) | Trzpień szczelinowy | 1 600 | axial_slider |
| 10 | po t6 (F3) | Chorągiewka | 1 500 | dimple |
| 11 | po t7 (F2) | Obrotnik tarcz | 1 800 | disc_detainer |
| 12 | po t7 (F3) | Piórko boczne | 2 000 | sidebar |
| 13 | po t8 (F2) | Słuchawka + Notes | 2 200 | safe_wheels |

Generator serii losuje rodziny tylko spośród tych, dla których gracz ma minimalny zestaw narzędzi. Zakup narzędzia
dodaje rodzinę do puli od następnego zamku, poprzedzoną samouczkiem S1–S3 (pomijalnym przy powtórce).

## 5. Macierz narzędzie × rodzina

● wymagane (minimalny zestaw) · ○ działa, opcjonalne · ✕ nie działa / nie pasuje

| Narzędzie \ Rodzina | wooden | warded | ring | wafer | wafer2 | pin | lever | lev_det | tubular | magnetic | slider | disc | safe | time | dimple | sidebar |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Napinacz kątowy | ✕ | ✕ | ✕ | ● | ● | ● (t2–4) | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ |
| Napinacz listwowy | ✕ | ✕ | ✕ | ○ | ○ | ● (t5+) / ○ | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ | ● | ● |
| Ciągadło kabłąka | ✕ | ✕ | ● | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ |
| Podważka kołkowa | ● | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ |
| Haczyk | ✕ | ✕ | ✕ | ● | ✕ | ● | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ | ● |
| Sonda przelotowa | ✕ | ● | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ |
| Falownik | ✕ | ✕ | ✕ | ○ | ✕ | ○ (bez zab., ≤ t3) | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ |
| Klin dwustronny | ✕ | ✕ | ✕ | ○ | ● | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ |
| Korba dźwigniowa | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ | ● | ● | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ |
| Koronka | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ | ● | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ |
| Sonda biegunowa | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ | ● | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ |
| Trzpień szczelinowy | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ | ● | ✕ | ✕ | ✕ | ✕ | ✕ |
| Obrotnik tarcz | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ | ● | ✕ | ✕ | ✕ | ✕ |
| Chorągiewka | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ | ● | ✕ |
| Piórko boczne | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ | ● |
| Słuchawka + Notes | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ | ● | ✕ | ✕ | ✕ |
| Zestaw zegarmistrza | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ | ● | ✕ | ✕ |
| Wiertarka (Zlecenia) | ✕ | ○ | ○ | ○ | ○ | ○ | ○ | ○ | ○ | ○ | ○ | ○ | ○ | ✕ | ○ | ○ |

Hybrydy: suma minimalnych zestawów modułów.

Kontrola reguły „nowa logika”: każdy wiersz z ● ma co najmniej jedną rodzinę, której nie otwiera żadne tańsze
narzędzie (wyjątek: napinacze — dzielą rodziny według atrybutu „wąski kanał”, co jest osobną logiką).

## 6. Pytania otwarte (do właściciela / PROGRESSION.md)

1. Wiertarka w Trybie Ciągłym: całkowicie niedostępna (propozycja) czy „pomiń zamek” za utratę życia i zero monet?
2. Czy złamanie w Trybie Zleceń kosztuje coś poza naprawą (np. czas zlecenia)?
3. Ekonomia: tempo zarobku vs ceny (np. czy 2 200 monet za komplet sejfowy to ~3–4 h gry).
4. Czy Falownik zostaje (kojarzony z realną techniką), czy zamieniamy go na czysto fikcyjne narzędzie.
