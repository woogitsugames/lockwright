# HUD — interfejs diegetyczny w fotorealizmie

Status: specyfikacja, 2026-11-04. Zastępuje wszystkie wcześniejsze szkice HUD-u z paskami, kartami i nakładkami („wygląda jak AI”). Obowiązuje kierunek `docs/styles/realizm.md` (D-05) i zasada ekranu bez paneli (D-12). Powiązane: `DESIGN.md` (kod stanów, układ, kryteria A7/A9), `ONBOARDING.md` (wskazówki bez tekstu), `TECH.md` §3 (język haptyki i dźwięku), `TOOLS.md` (zużycie), D-13 (lupa), D-24 (strefy kciuków), D-25 (przedmioty przed i po zamku).

Spis treści
1. Zasada
2. Warstwy ekranu
3. Co pokazuje sama scena (tabela danych)
4. Zwijka
5. Dotyk: strefy kciuków i odcisk kciuka
6. Pauza
7. Wejście do zamka: zlecenie jako przedmiot
8. Wyjście z zamka: rachunek i napiwek jako przedmioty
9. Dostępność: „Pomoc w czytaniu” i reszta opcji
10. Tryb „w ciemności”
11. Układ: pion, poziom, safe-area, cele dotyku
12. Ruch, światło, typografia, materiał
13. Zasady anty-slop
14. Kontrola jakości ekranu
15. Wpływ na kod i i18n

---

## 1. Zasada

**W trakcie otwierania zamka interfejsem jest sam przedmiot.** Każda informacja, której gracz potrzebuje, jest stanem fizycznej rzeczy w kadrze: kątem napinacza, obrotem rdzenia, ugięciem wytrycha, zadziorem na grocie, pustą kieszenią zwijki. Nie ma liczb, pasków, ikon, nagłówków ani kart. Wyjątek systemowy jest jeden: pauza (§6). Tekst pojawia się tylko **przed** zamkiem i **po** nim, i to też na przedmiotach (kartka, telefon, rachunek), a nie w panelach.

Test na każdy element: *czy ślusarz w prawdziwym warsztacie miałby to przed oczami?* Jeśli nie, to element nie istnieje albo jest przedmiotem, który by miał (kreda, ołówek, pieczątka).

## 2. Warstwy ekranu

| Warstwa | Zawartość | Kiedy |
|---|---|---|
| **Scena** | przekrój wkładki w drzwiach (albo w imadle warsztatu w samouczku), szyld, skrzydło drzwi, napinacz i wytrych w kanale | zawsze w zamku |
| **Zwijka** | skórzana zwijka narzędzi pod przekrojem: kieszenie z zapasowymi wytrychami (życia), lupa, napinacz zapasowy; w skórze wytłoczone strefy kciuków | zawsze w zamku (w ciemności niewidoczna, §10) |
| **Kreda** | znaki kodu stanów z `DESIGN.md` §1, rysowane kredą na metalu i skórze | samouczek S1–S2, wskazówka H3, opcja „Pomoc w czytaniu” |
| **Widmo** | cień kciuka lub dłoni (wskazówki H2/H4, `ONBOARDING.md` §2) | tylko samouczek i eskalacja |
| **Pauza** | klapka zwijki w rogu (§6) | zawsze |
| **Napisy dźwięków** | papierowy pasek nad zwijką (§9.3) | tylko z opcją |

Nic poza tym. W szczególności brak: licznika monet, numeru zamka w serii, nazwy klienta, timera (poza wyzwaniem „Na czas”, §3), wskaźnika napięcia, wskaźnika naprężenia, „życia” jako ikon.

## 3. Co pokazuje sama scena (tabela danych)

Źródło danych: `ViewModel` z lockcore (`tension`, `core_rotation`, `stress`, `elements[].state/position`, `pick_element`, `pick_lift`) i zdarzenia (`LockEvent`). Wartości w dp dotyczą układu pionowego 412×915 (§11).

| Informacja | Nośnik w scenie | Mapowanie | Dźwięk / haptyka | W ciemności |
|---|---|---|---|---|
| **Napięcie T** | **kąt ramienia napinacza** wystającego z dołu kanału + **czoło rdzenia** | ramię obraca się 0° → 14° przy T 0 → 1 (liniowo; ≥ 2 dp ruchu końca ramienia na każde 0,05 T). Stopka napinacza ugina się sprężyście o 0–3 dp proporcjonalnie do `tension_resistance` (opór, a nie samo T) | ciągły opór `tension_resistance` (L1 + kanał haptyczny „Tension”) | tylko dźwięk i haptyka |
| **Obrót rdzenia** | **wygrawerowana skala na czole rdzenia** (12 kresek co 7,5°, rysa „0” na obudowie) | `set` = +1 podziałka (pin) / +1 (płytka, 15 tysięcznych obrotu); `false_set` = +2 i kreska „za daleko” wybita na obudowie; `counter_rotate` = cofanie się skali; `open` = 90° | `set`, `false_set`, `counter_rotate`, `open` | kroki czuć w haptyce |
| **Element pod wytrychem** | grot wytrycha w kanale pod danym stosem; aktywny stos przybliżony 1,1× (`LOCKS.md` §2.6) | `pick_element`, `pick_lift` → wysokość grotu | `contact` (tik przy każdym stosie) | tik |
| **Stan elementu** | kształt i ruch elementu (`DESIGN.md` §1): przechył przy binding, klin szczeliny przy near_shear, stopka przy set, talia przy false_set, czarna bryła sprężyny przy overset | `elements[].state`, `position` | pełny słownik `TECH.md` §3.3 | dźwięk i haptyka |
| **Ugięcie wytrycha (stress)** | **krzywizna trzonu wytrycha** między rękojeścią a kanałem | łuk 0 → 6 dp przy `stress` 0 → 1 (liniowo), od 0,6: poprzeczne rysy 1 → 3, od 0,9: drżenie 1 dp | `stress` (jęk metalu, narastające drżenie) | jęk i drżenie |
| **Złamanie** | grot zostaje w kanale, rękojeść odskakuje 6 dp, odłamek ląduje na progu/blacie i zostaje tam do końca zamka | `break` | trzask, potem 150 ms ciszy | trzask |
| **Zużycie narzędzia** | **zadziory i nacięcia na grocie** w 5 stopniach (integralność 100 / 80 / 60 / 40 / 20), widoczne w scenie i wyraźnie w lupie/mikroskopie; trzon dostaje patynę | `ToolCondition.wear` (0–100) | tarcie bardziej szorstkie | szorstkość tarcia |
| **Życia (zapasowe wytrychy)** | **wytrychy w kieszeniach zwijki**: 3 kieszenie, pełna = wystaje rękojeść, pusta = zapadnięta skóra z odciśniętym kształtem | po `break` widmo dłoni (lub sam gracz w 0,5 s automatycznie) wyjmuje nowy wytrych z kieszeni; kieszeń pustoszeje | szelest skóry | szelest |
| **Lupa / mikroskop / wziernik** | lupa leży w kieszeni zwijki; wziernik zwinięty w ostatniej kieszeni; mikroskop stoi na blacie (tylko w warsztacie) | dotyk → okular lub ekran wziernika (§4.1, `ONBOARDING.md` §6) | szklany brzęk; wziernik: szelest oplotu i cichy klik diod | niedostępne (kieszenie zapięte) |
| **Czas (tylko wyzwanie „Na czas”)** | mechaniczny minutnik kuchenny / stoper na progu obok drzwi, wskazówka biegnie | czas zamka | ciche tykanie (wyłączalne) | tykanie |
| **Seria, monety, klient** | **brak w zamku**. Są na karcie zlecenia przed (§7) i na rachunku po (§8) | — | — | — |

Reguły:
- **Linia podziału jest czysta**: ±1 dp bez odblasku i bez faktury o wysokim kontraście (`DESIGN.md` §2). Szczelina ciemna, krawędzie sfazowane matowo.
- **Wszystko, co się rusza, rusza się z powodu.** Brak animacji „idle” na metalu (żadnego pulsowania, migotania, unoszenia). Jedyny ruch bez akcji gracza to fizyka (sprężyna wraca, rdzeń cofa się przy kontrrotacji, odłamek spada).
- **Kolor wzmacnia, nie niesie**: każdy wiersz tabeli działa w skali szarości i przy 50% jasności (A7).

## 4. Zwijka

- Skóra (ziarno, przetarcia, przeszycia), rozwinięta na progu lub blacie, zajmuje dolne ~30% ekranu w pionie.
- **Kieszenie** (od lewej): napinacz zapasowy · 3 kieszenie wytrychów (życia) · lupa · wziernik (od kroku 4b, `TOOLS.md` §4; zwinięty oplot, wystaje stalowa główka). Każda ≥ 48 dp szerokości. Rękojeści mają radełkowanie z `TOOLS.md` §3 (kreski, kropki, krzyżyki), więc rozróżnia się je bez koloru.
- **Strefy kciuków** są wytłoczone w skórze jako dwa bardzo płytkie, szerokie owale (relief, kontrast ≤ 1,3:1 do reszty skóry), widoczne tylko pod światłem jak naturalne wgniecenia od używania. Nie są przyciskami i nie mają obrysu.
- Zwijka nie jest menu. Dotknięcie kieszeni wytrycha nic nie robi (wymiana narzędzia w zamku to `tool_swap`, który w v0.1 rodzin pin/wafer nie występuje). Dotknięcie lupy otwiera okular. Klapka w rogu to pauza.
- Klient z Trybu Zleceń nie „wchodzi” do zwijki. Jeśli trzeba pokazać upływ czasu zlecenia, robi to scena (ktoś stoi za plecami: cień na drzwiach, kroki) i to tylko poza mechaniką.

### 4.1 Narzędzia obserwacji: lupa, mikroskop, wziernik (D-13, D-35)

Wspólna gramatyka: dotknięcie narzędzia → czarne otoczenie i **jedno okrągłe pole** obrazu z tej samej sceny 3D (inna kamera, nie rysunek), klapka „X” 48 dp w rogu jako jedyne wyjście poza ponownym dotknięciem narzędzia. Wejście i wyjście 180 ms (przesłona). Wytrych zamrożony, napięcie działa. Bez poświaty, neonu, ramek „HUD”, liczb i podpisów w kadrze. Zdanie ślusarza pod polem (głos z `DESIGN.md` §3) pojawia się tylko w samouczku i lekcjach wtrąconych.

| | Lupa | Mikroskop | Wziernik |
|---|---|---|---|
| Makieta | `mockups/realizm/02-loupe.html` | `08-microscope.html` | `09-borescope.html` |
| Render | `art/renders/loupe.png` | `art/renders/microscope_view.png` | `art/renders/borescope_view.png` |
| Kamera | przed płaszczyzną cięcia, pole ~8 mm, f/22 | przed cięciem, pole ~5 mm, płytka głębia (ostre pasmo linii podziału), pierścień LED wokół obiektywu | w kanale nieprzeciętej wkładki, boczne oko pod stosem z wytrychem, pierścień 6 LED, lekka beczka |
| Optyka (postprodukcja) | winieta okularu w CSS | lekka aberracja barwna rosnąca ku brzegowi + winieta (kompozytor) | lekka beczka + winieta LED (kompozytor) |
| Drugi gest | brak | przeciąganie prawym kciukiem = przesuw stolika wzdłuż linii podziału; szyna z podziałką pod polem pokazuje, gdzie jesteśmy | przeciąganie prawym kciukiem = wsuwanie/wysuwanie sondy (obraz przesuwa się pod kolejny stos, bez kontrolki na ekranie) |
| Czytanie w skali szarości | ciemna szczelina między jasnym mosiądzem a niklem | ciemna linia podziału ciągnie się przez całą szerokość pola; talia szpulki to ciemna przewężka **na** tej linii | wiszący koniec pinu = jasna kopułka; uniesiony = kopułka w ciemnym pierścieniu otworu; overset = otwór bez kopułki |
| Dźwięk / haptyka przy otwarciu | szklany brzęk / brak | stuk metalu o blat, cichy szum zębatki ostrości / brak | szelest oplotu, klik diod / brak |

Mikroskop jest **meblem warsztatu**, nie kieszenią: w terenie go nie ma, więc ekran zamka przy drzwiach nigdy go nie pokazuje. W warsztacie stoi obok imadła i dotyka się go tak jak lupy. Ekran zakupu w warsztacie to blat z przedmiotami i papierowymi metkami (`10-workshop-optics.html`, D-25): bez kart, bez cen „w kafelkach”.

## 5. Dotyk: strefy kciuków i odcisk kciuka

### 5.1 Strefy (D-24)

| | Pion | Poziom |
|---|---|---|
| **Lewa (napięcie)** | lewa połowa ekranu, dolne 45% wysokości (bez górnej sceny) | lewe 30% szerokości, cała wysokość safe-area |
| **Prawa (wytrych)** | prawa połowa, dolne 45% | prawe 30% szerokości, cała wysokość |
| **Martwy pas** | 24 dp przy krawędziach bocznych i dolnej (gesty systemowe) | jw. |

Mapowanie (propozycja zmiany `game/scripts/lock/input_sampler.gd`, który dziś mapuje bezwzględnie na całą wysokość):
- **Napięcie: względne od miejsca przyłożenia kciuka.** Przyłożenie = T 0, przesunięcie w górę o 240 dp = T 1 (w poziomie 200 dp). Gracz kładzie kciuk tam, gdzie mu wygodnie, a nie „na dole ekranu”.
- **Uniesienie: względne** od przyłożenia (160 dp w górę = lift 1, w dół = ujemny dla rodzin dwustronnych).
- **Głębokość: bezwzględna** wzdłuż kanału. Pozycja X kciuka w prawej strefie odwzorowuje się na stosy przekroju (magnes ±30% podziałki, `LOCKS.md` §1.3). Dzięki temu wybór stosu jest bezpośredni, a nie „na pamięć”.
- Strefa martwa 10 px i wygładzanie jak dziś. Kwantyzacja 1/256 w lockcore.
- **Przejęcie po przerwie** (pauza, lupa, powrót z tła): wartość trzymana przez grę zostaje, dopóki kciuk nie wróci. Nowe przyłożenie ustawia punkt odniesienia tak, żeby wartość ciągnęła się dalej od zatrzymanej (bez skoku). Dzięki temu pauza nie wywołuje zrzutu.
- **Gesty systemowe:** Android `setSystemGestureExclusionRects` na obu strefach (limit 200 dp na krawędź, więc wykluczamy pasy na wysokości stref), iOS `preferredScreenEdgesDeferringSystemGestures = .bottom` i `prefersHomeIndicatorAutoHidden` w zamku.
- **Odrzucanie dłoni:** dotyk o promieniu > 2× typowego kciuka w strefie ignorujemy. Trzeci palec ignorujemy.

### 5.2 Odcisk kciuka (feedback dotyku)

- Pod każdym aktywnym kciukiem skóra zwijki **ugina się miękko**: okrągłe wgłębienie Ø 56 dp z cieniem wewnętrznym (ok. 15% przyciemnienia w środku, rozmyta krawędź 8 dp) i delikatnym fałdowaniem ziarna skóry na brzegu. Wgłębienie pojawia się w 60 ms i znika w 250 ms po puszczeniu.
- Przy przesuwaniu wgłębienie **jedzie za kciukiem**, a w miejscu przyłożenia zostaje słabszy ślad (punkt odniesienia z §5.1), który gaśnie po 400 ms. To jedyna wskazówka „gdzie jest zero” i działa bez tekstu.
- Bez koloru, bez obwódki, bez cząsteczek, bez „fali”. Na blacie (samouczek w imadle) zamiast skóry ugina się filcowa mata.
- Haptyka dotyku: brak osobnego „tapnięcia” przy przyłożeniu, bo kanał haptyczny należy do zamka.
- Opcja „pokaż dotyk mocniej” (dla osób słabowidzących): wgłębienie 25% ciemniejsze i ślad punktu odniesienia na stałe.

## 6. Pauza

- **Afordancja:** w prawym górnym rogu safe-area (pion) / lewym górnym (poziom, z dala od strefy wytrycha) **skórzana klapka zwijki z mosiężną napą**, 48×48 dp celu dotyku, wizualnie ~36 dp. Bez ikony „II”, bez kółka, bez cienia „przycisku”.
- **Działanie:** dotknięcie odpina napę (klik), klapka zwija się w dół i **zakrywa przekrój** skórą (300 ms). Zakrycie jest celowe: w pauzie nie da się podglądać zamka ani planować bez czasu.
- **Na wewnętrznej stronie klapki** są wpisane ręcznie (atrament na naszytej płóciennej metce, Atkinson Hyperlegible Next ≥ 17 sp): **Wróć · Światło · Pomoc w czytaniu · Dźwięk i haptyka · Wyjdź z zamka**. Każda pozycja ≥ 48 dp wysokości. „Światło” to włącznik minutnika (tryb „w ciemności”, §10). „Dźwięk i haptyka” otwiera dwie mosiężne gałki (głośność, siła haptyki) i przełącznik „opór ciągły” (`TECH.md` §3.5).
- **Wyjście z pauzy:** „Wróć” albo ponowne dotknięcie napy. Klapka odwija się, a napięcie i wytrych są trzymane do ponownego przyłożenia kciuków (§5.1). W ciągu pierwszych 2 s po pauzie zrzut nie może nastąpić.
- **Automatycznie:** przejście aplikacji w tło, połączenie przychodzące, utrata fokusu. Po powrocie klapka jest zamknięta.
- **Przytrzymanie napy 1 s** (bez otwierania klapki) w samouczku przy powtórce = pomiń samouczek (`ONBOARDING.md` §1.9).
- Obecne `PauseMenu` w `lock.tscn` (tytuł, przyciski, checkbox) jest tymczasowe i ma zostać zastąpione tym opisem.

## 7. Wejście do zamka: zlecenie jako przedmiot

Cel: wszystkie informacje „kto, gdzie, za ile” gracz dostaje **zanim** przekrój się pojawi, a każda z nich jest napisana na rzeczy, którą ślusarz trzyma w ręce (D-25).

### 7.1 Tryb Zleceń: telefon w dłoni, potem drzwi

1. **Telefon w dłoni** (pierwsza osoba, dłoń od dołu kadru): wiadomość z dyspozytorni jako zwykły widok wiadomości w stylu systemowym, ale bez marki i bez interfejsu prawdziwego komunikatora (własny, prosty: nadawca „Dyspozytornia”, godzina, 2–4 linijki). Treść: adres i piętro, kto dzwoni, jedno zdanie sytuacji („Pani Halina, 3. piętro. Zatrzasnęła drzwi, rosół na gazie.”). Pod spodem zdjęcie wkładki z zewnątrz, przysłane przez klienta (szyld i kanał, bez marki). Z niego gracz domyśla się rodziny zamka.
2. **Klatka schodowa i drzwi**: klient, scena weryfikacji prawa do lokalu (`JOBS.md` §2) jako karty-dowody na dłoni lub na wycieraczce.
3. **Wycena**: kartka z bloczka wycen przy drzwiach, gracz przesuwa ołówek po stawce (`JOBS.md` §3).
4. **Przejście do zamka** (600 ms): kamera zjeżdża do szyldu, drzwi „otwierają się w przekroju” (cięcie przechodzi przez wkładkę), zwijka rozwija się od dołu. Telefon chowa się do kieszeni (dłoń wychodzi z kadru).

### 7.2 Tryb Ciągły: kartka z bloczka dyżuru

- **Kartka z bloczka zleceń** przypięta do podkładki z klipsem: adres (wymyślony, z miasta gry), godzina dyżuru, a w rogu **kreski ołówkiem** (seria: jedna kreska na zamek, co piąta przekreśla cztery, a na piątej rysunek klucza płaskiego = przystanek w warsztacie).
- Tier nie jest liczbą. Zamiast tego **ślad zużycia kartki**: czym głębiej w dyżur, tym późniejsza godzina i więcej ołówkowych dopisków dyspozytora („pilne”, „noc”).
- Przejście: kartka zsuwa się w dół (200 ms), kamera wjeżdża w drzwi (400 ms).

### 7.3 Samouczek

Imadło na blacie warsztatu, bez karty (patrz `ONBOARDING.md` §3–4).

## 8. Wyjście z zamka: rachunek i napiwek jako przedmioty

1. **Otwarcie** (`open`): rygiel do końca, oddech 600 ms, kamera odjeżdża od przekroju do drzwi, drzwi się uchylają.
2. **Rachunek z bloczka z kalką** wypisywany ołówkiem na oczach gracza (ręka ślusarza od dołu kadru, 1,2–2 s, przyspieszalne dotknięciem): pozycje (otwarcie, dojazd, stawka nocna), suma i **pieczątki**:
   - „bez śladów” / „no marks” (otwarcie bez `drop` i `break`, premia +50%),
   - „w ciemności” / „in the dark” (+20%),
   - „mistrz” przy zamku mistrzowskim.
   Pieczątka spada ze stukiem i jednym średnim transientem (`gate_align`).
3. **Monety**: w Trybie Ciągłym monety są metalowymi krążkami odliczanymi na rachunek (jeden krążek = 10 monet, przy dużych kwotach słupki), z dźwiękiem metalu na papierze. Suma jest wpisana ołówkiem na dole rachunku i to jedyna liczba na ekranie.
4. **Napiwek** w Trybie Zleceń to **przedmiot od klienta**, zgodny z kartą zlecenia (`JOBS.md`): talerz rosołu, pudełko pizzy, słoik ogórków, pocztówka. Ląduje obok rachunku. Wartość w monetach dopisana ołówkiem małym pismem.
5. **Seria**: ołówek dopisuje kreskę na karcie dyżuru (§7.2). Złamania w tym zamku: odłamek leży na rachunku (nie pomijamy porażek, ale bez czerwieni).
6. **Koniec dyżuru** (trzeci wytrych złamany): zwijka jest pusta, ślusarz ją zwija. Rachunek zbiorczy z całej serii (liczba zamków, monety, najlepszy czas) i jedno zdanie ślusarza z puli (`DESIGN.md` §3: „Weź oddech. Jutro też są drzwi.”). Bez „GAME OVER”.
7. **Dalej**: dotknięcie rachunku (cały rachunek jest celem dotyku) przechodzi do następnej kartki. Przytrzymanie = zachowaj rachunek do gabloty (opcjonalne „Twój egzemplarz”, `PROGRESSION.md` §4).

## 9. Dostępność: „Pomoc w czytaniu” i reszta opcji

Opcje są w Ustawieniach (zeszyt warsztatowy) i w pauzie. Żadna nie odbiera premii poza „Szerszymi oknami” (decyzja o premii otwarta, `LOCKS.md` §1.7).

### 9.1 „Pomoc w czytaniu” (jeden przełącznik, trzy składniki, każdy też osobno)

1. **Kreda**: pełny słownik znaków kodu stanów (`DESIGN.md` §1) na wierzchu sceny: 3 kreski tarcia przy wiążącym, klin szczeliny przy near_shear, płaska kreska „stopki” przy set, przerywany obrys przy false_set, klamra nad overset, łuk-strzałka cofania przy counter_rotate, rysy przy stress. Kreda ma fakturę i lekko nierówną linię (ręka ślusarza), grubość ≥ 2 dp, kolor złamanej bieli (kontrast ≥ 4,5:1 do mosiądzu i stali w cieniu). Kreda nigdy nie wskazuje rozwiązania (gdzie jest okno, który kołek następny), tylko nazywa stan, który już jest.
2. **Większe kontrasty**: preset oświetlenia „warsztatowa lampa”: mocniejsze światło krawędziowe na elementach, ciemniejsze tło komór, matowe przyciemnienie korpusu, kontrast metal/tło ≥ 4,5:1 (zamiast ≥ 3:1), linia podziału 3 dp (zamiast 2). Bez zmiany geometrii, żeby zrzuty A7 dalej obowiązywały.
3. **Napisy dźwięków**: wąski pasek papieru (jak taśma do etykiet) nad zwijką, 1 linia, Atkinson Hyperlegible Next ≥ 16 sp, ciemny tusz na papierze. Słownik (krótki, opisowy, w nawiasach kwadratowych), np.:

   | Zdarzenie | PL | EN |
   |---|---|---|
   | `bind` | [zgrzyt — kołek wiąże] | [scrape — pin binds] |
   | `near_shear` | [zgrzyt drobnieje] | [scrape gets finer] |
   | `set` | [suchy klik] | [crisp click] |
   | `false_set` | [głuchy podwójny klik] | [dull double click] |
   | `pin.serration` | [drobne tyk] | [tiny tick] |
   | `counter_rotate` | [skrzyp — rdzeń się cofa] | [creak — core pushes back] |
   | `overset` | [tępy stuk, cisza] | [dead thud, silence] |
   | `drop` | [grzechot kołków] | [pins rattle down] |
   | `stress` | [jęk metalu] | [metal whines] |
   | `break` | [trzask] | [snap] |
   | `wafer.rattle` | [grzechot płytek] | [wafers rattle] |
   | `open` | [szczęk rygla] | [bolt clunks open] |

   Pasek pokazuje ostatnie zdarzenie przez 1,2 s. Napisy działają też w trybie „w ciemności” (wtedy pasek jest jedynym obrazem, więc w ciemności są domyślnie wyłączone i wymagają osobnego przełącznika, żeby nie zepsuć wyzwania).

### 9.2 Pozostałe opcje

- **Szersze okna** ×1,5 (`LOCKS.md` §1.7).
- **Zamień kciuki** (leworęczni): napięcie po prawej, wytrych po lewej. Scena się nie odbija (zamek ma swoją stronę), zmieniają się tylko strefy i widmo.
- **Blokada napięcia** (motoryka): podwójne dotknięcie lewej strefy zatrzaskuje bieżące T (napinacz dostaje widoczny zacisk-klamerkę na ramieniu), a pojedyncze dotknięcie zwalnia. Zmiana T dalej działa przesunięciem.
- **Haptyka**: suwak siły, wyłącznik, „opór ciągły” osobno (`TECH.md` §3.5); powtórka kalibracji.
- **Ograniczenie ruchu**: respektujemy systemowe Reduce Motion: bez przejazdów kamery (przenikanie 150 ms), bez drżenia wytrycha (zostaje krzywizna i rysy).
- **Rozmiar tekstu** poza zamkiem: Dynamic Type / skalowanie czcionki systemu do 200% na kartach, rachunkach i w zeszycie. Teksty na przedmiotach przewijają się na kolejną stronę kartki, a nie zmniejszają.
- **Czytniki ekranu**: karty, rachunki, pauza i Ustawienia mają etykiety. W zamku VoiceOver/TalkBack ogłasza tylko zdarzenia `set`, `false_set`, `overset`, `drop`, `break`, `open` (krótkie słowa z §9.1), z możliwością wyłączenia.

## 10. Tryb „w ciemności”

- **Wejście:** minutnik na klatce gaśnie (400 ms: przygaśnięcie, potem czerń). Przed zamkiem: włącznik minutnika w kadrze klatki (wciśnięty = światło). W pauzie: pozycja „Światło”.
- **Znika:** cały przekrój, napinacz, wytrych, zwijka (z życiami), lupa (kieszeń zapięta, D-13), kreda, widmo (H2/H4 grają dźwiękiem, a H4 na chwilę zapala światło, `ONBOARDING.md` §2.1), napisy dźwięków (chyba że osobno włączone, §9.1).
- **Zostaje:**
  - dźwięk i haptyka bez zmian, plus profil „dark” (`ARCHITECTURE.md`: mocniejsze różnice, wyraźniejsza rampa `near_shear`), okna ×1,15 (`LOCKS.md` §1.7);
  - **relief klapki pauzy**: ciemnoszary kształt klapki z napą na czerni, kontrast 3:1 do czerni (żeby dało się ją znaleźć, ale nie odciągała uwagi);
  - **odcisk kciuka** (opcja, domyślnie włączona): bardzo słabe wgłębienie (kontrast 1,5:1) tylko potwierdza, że dotyk jest zarejestrowany. Nie pokazuje stanu zamka.
- **Ekran jest naprawdę czarny** (#000 na OLED, oszczędność baterii), bez winiety i bez „szumu nocnego”.
- **Wyjście:** po `open` światło wraca i gracz widzi końcowy stan (nagroda). Przy porażce światło też wraca, żeby gracz zobaczył odłamek.
- **Złamanie w ciemności:** trzask i haptyka jak zwykle. Gracz nie widzi pustej kieszeni, więc po złamaniu słychać szelest skóry i stuk wyjmowanego wytrycha (informacja, że życie ubyło).

## 11. Układ: pion, poziom, safe-area, cele dotyku

### 11.1 Pion (podstawowy, 412×915 dp)

```
┌───────────── safe-area top ─────────────────┐
│ [scena: drzwi, szyld]               [klapka]│  klapka pauzy 48×48 dp, róg
│                                             │
│   PRZEKRÓJ WKŁADKI                          │  ~ 48% wysokości
│   (stosy ≥ 28 dp, podziałka 44 dp,          │
│    linia podziału ≥ 2 dp, kontrast ≥ 3:1)   │
│   napinacz wystaje z dołu kanału,           │
│   wytrych z prawej                          │
├─────────────────────────────────────────────┤  (opcjonalnie: pasek napisów, 28 dp)
│ ZWIJKA: [napinacz][wytr][wytr][wytr][lupa]  │  ~ 8%: kieszenie ≥ 48 dp
│ ┌──── strefa L ────┐┌──── strefa P ───────┐ │
│ │ napięcie         ││ wytrych             │ │  ~ 37%: dolne 45% ekranu
│ │ (wzgl. 240 dp)   ││ (głęb. bezwzgl.,    │ │  to strefy kciuków
│ │                  ││  uniesienie wzgl.)  │ │
│ └──────────────────┘└─────────────────────┘ │
└──────── martwy pas 24 dp + safe-area ───────┘
```

### 11.2 Poziom (sprawdzony, 915×412 dp)

```
┌ safe-area ──────────────────────────────────────────────────────┐
│[klapka]                                                         │
│ strefa L   │        PRZEKRÓJ WKŁADKI (środek, ~40% szer.)  │ strefa P │
│ (30% szer.,│        napinacz i wytrych w kanale             │ (30%,    │
│  cała wys.)│ ────────────────────────────────────────────── │ cała wys)│
│            │  ZWIJKA pod przekrojem: kieszenie ≥ 48 dp      │          │
└─────────────────────────────────────────────────────────────────┘
```

- W poziomie klapka pauzy idzie w lewy górny róg (prawy górny jest nad strefą wytrycha i bywa przypadkiem trącany).
- Wycięcia ekranu (notch, Dynamic Island, otwór kamery): przekrój nigdy nie wchodzi pod wycięcie; klapka pauzy omija je o ≥ 8 dp.

### 11.3 Liczby

- Cele dotyku: ≥ 48 dp (Android) / 44 pt (iOS); w praktyce wszystkie 48. Odstęp między celami ≥ 8 dp.
- Elementy zamka ≥ 28 dp szerokości, linia podziału ≥ 2 dp (3 dp przy „większych kontrastach”), kontrast metal/tło ≥ 3:1 (≥ 4,5:1 przy „większych kontrastach”).
- Safe-area zawsze respektowana. Wszystkie akcje w trakcie zamka są w dolnych 45% (pion), poza pauzą.
- Tablet (iPad): ta sama kompozycja, przekrój skalowany do max 520 dp szerokości, strefy kciuków przy dolnych rogach (dłonie trzymają tablet za boki), bez haptyki (D-10).

## 12. Ruch, światło, typografia, materiał

- **Ruch:** 100–250 ms w zamku, `out-cubic` lub krokowy, bez overshootu i bez sprężynek (`DESIGN.md` §1). Kamera poza zamkiem 400–600 ms. Brak efektu paralaksy z żyroskopu.
- **Światło:** ciepła żarówka klatki (klucz, góra z lewej) + chłodne okno (wypełnienie), jak w `realizm.md`. Brak bloomu, poświat, flar i „god rays”. Jedyne światło „z UI” to brak światła w trybie ciemności.
- **Typografia** (tylko poza zamkiem i w pauzie): Atkinson Hyperlegible Next dla tekstu, Bona Nova na emaliowanych tabliczkach i nagłówkach rachunku. Odręczne wpisy (rachunek, kreski serii) to **animacja ołówka po gotowym kroju** (Atkinson z lekką nierównością linii), a nie font „handwriting”. Oba kroje OFL, wpisane do `ASSETS.md` przy dodaniu.
- **Kolory** wynikają z materiałów: mosiądz, stal, skóra, papier, grafit, tusz pieczątki (ciemny granat lub brąz, nie czerwień), kreda (złamana biel). Nie ma „koloru interfejsu”.
- **Dźwięk UI (L4)** też jest materiałowy: papier, ołówek, napa, skóra, pieczątka. Żadnych „bipów” ani syntetycznych „ding”.

## 13. Zasady anty-slop

| Nie robimy | Zamiast tego |
|---|---|
| karty SaaS (zaokrąglone prostokąty z cieniem, „panel z wynikiem”) | kartka z bloczka, rachunek z kalką, metka na klapce |
| ikony z paczek (Material, SF Symbols, Font Awesome, „kłódka”, „zębatka”) | przedmiot w scenie (klapka z napą, włącznik minutnika) albo słowo na metce |
| gradienty dekoracyjne (fiolet-niebieski, teal-orange, „sunset”) | oświetlenie fizyczne sceny; papier i skóra mają własny walor |
| glow, bloom, neon, poświata na pinie, złoty blask, „sparkle” przy set | set to ruch (stopka, obrót o podziałkę) + klik + transient |
| glassmorphism, rozmyte tła pod panelem | pauza zakrywa scenę skórą klapki |
| emoji i emotikony (🔒 ✨ 🎉 ✅ ❌) | pieczątka z jednym słowem, kreda ze znakiem kodu stanów |
| zielony ptaszek / czerwony X, „SUCCESS!”, „FAILED” | otwarte drzwi i rachunek; odłamek wytrycha na rachunku |
| „Welcome!”, „Get Started”, „Let's go!”, „Unlock your potential” | zimne otwarcie bez słów (`ONBOARDING.md` §3.0); głos ślusarza (`DESIGN.md` §3) |
| pasek napięcia, pasek „HP” wytrycha, licznik żyć, procent postępu | kąt napinacza, krzywizna wytrycha, kieszenie zwijki, skala na czole rdzenia |
| konfetti, wybuchy monet, „combo x3”, wibracja kamery przy sukcesie | oddech 600 ms, szczęk rygla, krążki na rachunku |
| toasty i dymki z poradą („Tip: …”) | eskalacja H1–H4 bez tekstu |
| chrom, „sci-fi” hologram przekroju, linie skanowania | satynowy metal, ślady frezu, sfazowane krawędzie |
| ciemny „gamingowy” ekran z dziurką od klucza i złotą kłódką | klatka schodowa, drzwi, ciepła żarówka |
| Inter/Roboto/systemowy jako jedyny krój | Atkinson Hyperlegible Next + Bona Nova |
| pastisz: sepia, „steampunk”, faktury ze stocku | własne skany/rendery materiałów, CC0 z wpisem w `ASSETS.md` |

## 14. Kontrola jakości ekranu

Każdy zrzut ekranu zamka (makieta i gra) przechodzi przed pokazaniem właścicielowi:
1. **Skala szarości i 50% jasności** (`mockups/tools/render.mjs`): każdy stan z `DESIGN.md` §1 rozpoznawalny (A7).
2. **Kontrast** (`mockups/tools/contrast.mjs`): metal/tło ≥ 3:1, kreda ≥ 4,5:1, linia podziału bez odblasku.
3. **Test „wyrzuć tekst”**: zasłoń wszystkie napisy. Czy gracz wie, co ma zrobić? W zamku napisów ma nie być wcale.
4. **Test „czy to jest w warsztacie”** (§1) dla każdego widocznego elementu.
5. **Lista anty-slop** (§13) odhaczona.
6. **Pion i poziom**, safe-area na urządzeniu z wycięciem, cele ≥ 48 dp.
7. **Tryb „w ciemności”**: ekran czarny, pauza znajdowalna, nic nie zdradza stanu.

## 15. Wpływ na kod i i18n

- `game/scenes/lock.tscn`: `PauseMenu` (tytuł, przyciski, `DarkModeCheck`) i `PauseButton` z tekstem `lock.pause` zastąpić klapką zwijki (§6). Do zrobienia przez programistę gry, nie w tym etapie.
- `game/scripts/lock/input_sampler.gd`: strefy w dolnych 45% i mapowanie względne (§5.1, D-24).
- Klucze i18n (PL + EN): `hud.optics.loupe.hint`, `hud.optics.microscope.hint`, `hud.optics.borescope.hint`, `hud.optics.close` (etykieta dostępności klapki X), `tool.tl_microscope.name/note`, `tool.tl_borescope.name/note`, `hud.pause.resume`, `hud.pause.light`, `hud.pause.reading_aid`, `hud.pause.audio_haptics`, `hud.pause.quit`, `hud.stamp.clean`, `hud.stamp.dark`, `hud.stamp.master`, `hud.receipt.*` (pozycje rachunku), `hud.caption.<event>` (tabela §9.1), `hud.dispatch.sender`, `hud.run_end.*`. Teksty stempli i napisów są krótkie, bo muszą zmieścić się na pieczątce i pasku.
