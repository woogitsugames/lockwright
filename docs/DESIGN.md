# Design — kod stanów, zasady ekranu, kryteria akceptacji

Ten dokument nie zależy od kierunku wizualnego. Każdy kierunek z `docs/styles/` musi zrealizować poniższy kod stanów własnymi środkami, ale **bez zmiany kształtu i ruchu**, które przenoszą znaczenie.

## 1. Kod stanów elementu (3 kanały, czytelny w skali szarości)

Zasada: **znaczenie niesie geometria i ruch, a nie kolor.** Kolor może wzmacniać, ale po zamianie obrazu na skalę szarości (i przy 50% jasności) każdy stan dalej musi być rozpoznawalny. Haptyka nigdy nie jest jedynym kanałem (XAG 103/110). Nazwy wzorców haptycznych i dźwiękowych odpowiadają bibliotece w `TECH.md`.

| Stan / zdarzenie | Kształt i ruch (obraz) | Dźwięk | Haptyka | Tryb „w ciemności” |
|---|---|---|---|---|
| **swobodny** (element nie wiąże) | Element stoi w osi komory, sprężyna ma równe zwoje, cień rzucony prosto w dół. Na nacisk reaguje sprężyście (opada w 120 ms). | Ciche, miękkie tarcie wytrycha (`pick_drag`, nisko). | Bardzo słaby ciągły szum tarcia. | Tarcie słychać, element jest „miękki”. |
| **binding** (element wiąże) | Element **przesuwa się w bok** o 2–3 dp i dociska do krawędzi komory. Po stronie docisku pojawiają się **3 krótkie ukośne kreski tarcia** na linii podziału. Ruch zamiera i reaguje z oporem (bez sprężynowania). | Chropawe, ziarniste skrobanie, które gęstnieje razem z napięciem. | Ciągły opór (`tension_resistance`) wyraźnie rośnie, sharpness średnia. | Najgłośniejszy ze stojących elementów. Panorama audio wskazuje pozycję komory. |
| **near_shear** (blisko linii podziału) | **Klin szczeliny** między elementem a linią podziału widocznie się zwęża (dwa trójkąty zbliżają się do siebie). Jedna kreska tarcia znika. | Ziarno skrobania drobnieje, wysokość lekko rośnie. | Rośnie sharpness ciągłego oporu. Pojedynczy bardzo lekki „tik” przy wejściu w okno. | Słyszalne „zwężenie” dźwięku. |
| **set** (prawdziwe ustawienie) | Element **siada na półce**: górna część zostaje nad linią i dostaje płaską „stopkę”, a rdzeń **obraca się o jedną podziałkę** względem wygrawerowanej skali na czole. Szczelina klina się zamyka. Ruch 120 ms, bez odbicia. | Krótki, suchy, jasny klik (2–4 kHz, 30–60 ms) z materiałową barwą. | Ostry transient (intensity wysokie, sharpness wysokie). Potem chwilowy spadek oporu. | Klik i obrót rdzenia czuć jako „krok”. |
| **false set** (fałszywe ustawienie) | Rdzeń obraca się **głębiej niż przy set** (dwie podziałki), ale element ma **talię (klepsydrę) zaklinowaną na linii podziału**. Obrys elementu staje się **przerywany**. Na czole skali pojawia się kreska „za daleko”. | Klik **głuchszy i podwójny** („klak-trrt”), niższa barwa, z krótkim grzechotem. | Transient o niższej sharpness, po 40–60 ms drugi słabszy. Potem opór o **innym rytmie** (pulsujący). | Podwójny klik i pulsujący opór odróżniają go od set. |
| **counter_rotate** (kontrrotacja) | Rdzeń **cofa się pod kciukiem**, a napinacz w świecie gry odchyla się w stronę zera. Strzałka-łuk wyryta na czole cofa się. Element zabezpieczający unosi się mimo braku nacisku. | Niski skrzyp, narastający przez cały czas trwania. | Ciągły wzorzec „pchający wstecz” (narastająca intensity, niska sharpness). | Skrzyp i pchanie są wyraźnie dłuższe niż każdy klik. |
| **overset** (przepchnięcie) | Dolny element **przekracza linię podziału** i blokuje rdzeń. Sprężyna jest **ściśnięta do pełnej czarnej bryły** (zwoje się stykają). Element nie wraca przy puszczeniu. Pojawia się znacznik „klamra” (dwie poziome kreski) nad komorą. | Martwy, tępy stuk bez dźwięczenia sprężyny. Dalej cisza tej komory. | Krótki, tępy transient o niskiej sharpness, potem **brak** odpowiedzi elementu na ruch (martwy). | Komora milknie. To sygnał, że trzeba poluzować napięcie. |
| **drop** (zrzut) | Ustawione elementy spadają kaskadowo (40 ms odstępu), rdzeń wraca do zera na skali. | Szybka seria drobnych stuków, potem brzęk sprężyn. | Seria 2–5 krótkich, słabych transientów. | Seria stuków. |
| **stress** (blisko złamania) | **Wytrych i napinacz wyginają się widocznie**: krzywizna rośnie liniowo ze stresem. Na zgięciu pojawiają się **poprzeczne rysy** (1→3). Przy 90% wytrych drga z amplitudą 1 dp. | Wysoki, cienki jęk metalu z narastającą chropowatością. | Narastające drżenie (szybkie, słabe transienty 20–30/s na ciągłym tle). | Jęk metalu i drżenie. To najgłośniejszy sygnał ostrzegawczy. |
| **break** (złamanie) | Wytrych pęka na rysie: końcówka zostaje w kanale, a uchwyt odskakuje 6 dp. Kawałek metalu ląduje na stole warsztatowym w HUD. | Ostry trzask, potem brzęk o blat. | Najmocniejszy transient w grze, potem 150 ms ciszy. | Trzask. |
| **wear** (zużycie) | Na końcówce narzędzia przybywa **zadziorów i nacięć** (0–4 stopnie). Widać je w przekroju i w warsztacie. | Tarcie robi się bardziej szorstkie. | Ciągłe tarcie ma większą chropowatość. | Szorstkość tarcia. |
| **gate_align** (dźwignia, tarcza lub pierścień w bramce) | Wycięcie bramki i trzpień **zrównują się w jednej linii**. Między nimi zostaje wąska jasna szczelina (prześwit), bez kolorowania. | Miękki, niski „tuk” drewniany lub mosiężny. | Średni transient, niska sharpness. | Tuk. |
| **detector_trip** | Zapadka detektora **opada i zachodzi** na rygiel, wyraźnie zmieniając sylwetkę. | Metaliczne „klank” i zgrzyt zablokowania. | Dwa mocne transienty w odstępie 80 ms. | Klank. |
| **open** | Rygiel przesuwa się do końca (250 ms), a rdzeń obraca do pełnej podziałki. | Ciężki, satysfakcjonujący szczęk mechanizmu i oddech ulgi tła. | Długi, ciepły wzorzec (rosnący, potem gasnący). | Szczęk. |

Reguły uzupełniające:
- **Set i false set nie mogą się różnić tylko barwą.** Różnią się głębokością obrotu (1 vs 2 podziałki), obrysem (pełny vs przerywany), sylwetką (płaska stopka vs talia) oraz rytmem dźwięku i haptyki.
- **Overset i set**: ściśnięta czarna bryła sprężyny vs równe zwoje. Klamra nad komorą jest wyłącznie przy overset.
- Animacje trwają 100–250 ms, bez odbijających się sprężynek (easing typu `out-cubic` lub krokowy, bez overshoot).
- Kreski tarcia, klin i klamra są tym samym słownikiem znaków we wszystkich rodzinach (piny, płytki, dźwignie).

## 2. Ekran gry: układ (pion 412×915 dp)

```
┌─────────────── safe-area top ───────────────┐
│  pasek: zlecenie/seria, monety (mały, płaski)│  ~56 dp
├──────────────────────────────────────────────┤
│                                              │
│   PRZEKRÓJ MECHANIZMU                         │  ~ 46–52% wysokości
│   (elementy ≥ 28 dp szer., linia podziału     │
│    ≥ 2 dp, kontrast metal/tło ≥ 3:1)          │
│                                              │
├──────────────────────────────────────────────┤
│  HUD diegetyczny: skala na czole rdzenia,     │  ~ 12%
│  napinacz w świecie, zapasowe wytrychy na     │
│  stole/w zwijce narzędzi                      │
├──────────────────────────────────────────────┤
│  STREFA LEWEGO KCIUKA │ STREFA PRAWEGO KCIUKA │  ~ 30% (≥ 48 dp cele)
│  napięcie (pion)      │ wytrych (2D)          │
└─────────────── safe-area bottom ─────────────┘
```

- Poziom (915×412): przekrój na środku, strefy kciuków po bokach na całej wysokości, a HUD w świecie pod przekrojem.
- Linia podziału nie może mieć odblasków. Przy linii podziału nie używamy speculara ani faktury o wysokim kontraście (±1 dp czystego tła).
- Cele dotyku: ≥ 48 dp (Android) / 44 pt (iOS). Wszystkie akcje w trakcie zamka są w dolnych 40% ekranu.

## 3. Głos tekstów

- Mówi ślusarz (ty, z warsztatu) albo kustosz gabloty. Krótko, konkretnie, z odrobiną humoru.
- Zakazane: „Welcome!”, „Get Started”, „Unlock your potential!”, wykrzykniki marketingowe.
- Przykłady: „Pani Halina czeka. Rosół też.” / „Szpulka. Popuść trochę i daj jej wrócić.” / „Ten zamek pamięta czasy, kiedy klucz ważył pół funta.”

## 4. Kryteria akceptacji prototypu (vertical slice)

| # | Kryterium | Metoda | Próg „przeszło” |
|---|---|---|---|
| A1 | Nowicjusz otwiera 3-pinową wkładkę bez czytania tekstu | Test z ≥ 12 osobami, które nigdy nie otwierały zamka, bez instrukcji tekstowych (tylko 3 poziomy samouczka pokazowego) | mediana < 90 s, ≥ 75% osób < 90 s |
| A2 | Tryb „w ciemności” | Ci sami testerzy, 3-pinowa wkładka, ekran zgaszony (czarna nakładka) | ≥ 60% otwiera w < 3 min |
| A3 | Generator nie tworzy zamków nieotwieralnych | `solver()` na 10 000 seedów na każdą rodzinę i tier w CI | 0 porażek. Raport rozkładu trudności |
| A4 | Wydajność | Profilowanie na iPhonie 12 i średnim Androidzie (lista w `TECH.md`), 5 min gry | 60 FPS, p99 czasu klatki < 20 ms, brak throttlingu do 30 FPS w 10 min |
| A5 | Opóźnienie dotyk → haptyka niewyczuwalne | Pomiar z `TECH.md` (kamera 240 fps + akcelerometr) | iOS p95 ≤ 30 ms. Android z prymitywami p95 ≤ 40 ms. Test ślepy: testerzy nie wskazują opóźnienia ponad przypadek |
| A6 | Dotyk → dźwięk kliknięcia | Pomiar mikrofonem i kamerą | p95 < 30 ms (iOS), < 45 ms (Android z niską latencją) |
| A7 | Stany rozróżnialne bez koloru | Zrzuty w skali szarości, 8 testerów rozpoznaje stan z obrazka | ≥ 90% trafień na każdy stan |
| A8 | Determinizm | Ta sama powtórka na iOS, Androidzie i Linuksie | identyczny hash strumienia zdarzeń |
| A9 | Dostępność | Haptyka wyłączona, a dźwięk i obraz pozwalają ukończyć poziomy samouczka | 100% poziomów samouczka do przejścia |
