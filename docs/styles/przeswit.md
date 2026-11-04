# Kierunek „Prześwit” — wycinanka pod lampą

Status: makiety kierunku (4.11.2026). Pliki: `mockups/przeswit/`, render: `cd mockups && node tools/render.mjs przeswit`.

## 1. Idea

**Prześwit** (EN: *Light-through*). Mechanizm wycięty z kartonu i blachy leży na ciepłej, podświetlanej tafli, a stan zamka czyta się z tego, **gdzie i jak światło przechodzi przez szczeliny**.

Dlaczego to pasuje do gry z czytelnym przekrojem:
- Linia podziału nie jest narysowaną kreską. To **szczelina, przez którą widać lampę**, więc z natury ma najwyższy kontrast na ekranie (15:1) i nie ginie w skali szarości, przy 50% jasności ani po rozmyciu.
- Każdy stan to ta sama sylwetka z jedną zmienną (gramatyka Isotype, ART.md §2.7). Zmienia się położenie sylwetki albo kształt plamy światła, nigdy kolor.
- Wycinanka à la Lotte Reiniger (ART.md §2.12) czyta się bez wnętrza. Dzięki temu przekrój jest „encyklopedyczny” i ciepły, a nie techniczny czy złodziejski.
- Od „Planszy cechowej” różni się zasadniczo: tam jest linia i szraf tuszem na papierze, a tu **pełne płaszczyzny kartonu i dziury w nich**. Nie ma ani jednej kreski szrafu. Materiał oddaje perforacja, czyli światło przechodzące przez sylwetkę.

Sygnatura: ciepła biel tafli, czarny karton, **jeden kolor ręki gracza (minia)**, znaczniki pasowania w rogach ekranu (mata do cięcia) oraz etykiety na taśmie malarskiej.

## 2. Paleta

| Token | HEX | Rola |
|---|---|---|
| `light` | `#FFF4D6` | Tafla lampy: tło, **każda szczelina i perforacja** (w tym linia podziału) |
| `shade` | `#EADBB2` | Papier w cieniu: taśma, karty notek, płaskie cienie rzucone, podłoga |
| `ink` | `#1D1A16` | Karton „żelazo”: obudowa, ramy, tablice, tekst |
| `steel` | `#2B3236` | Karton „stal”: kołki górne, kabłąki |
| `brass` | `#47371A` | Karton „mosiądz”: rdzeń, kołki dolne, eksponaty |
| `wood` | `#46291B` | Karton „drewno”: drzwi, futryna, zwijka |
| `tool` | `#C9532A` | Minia: **wyłącznie ręka gracza** (wytrych, napinacz, kciuki, narzędzia w warsztacie) |
| `soft` | `#5C5142` | Tekst drugorzędny na tafli i taśmie |

Materiały metalowe są walorowo zbliżone (wszystkie ciemne) **celowo**. Rozróżnia je krawędź i perforacja (§5), a nie jasność. Dzięki temu każdy metal ma 10–12:1 do tafli i nie ma problemu „mosiądz na jasnym 1,7:1” z ART.md §4.1.

**Reguła szczeliny narzędzia:** minia nie ma 3:1 do mosiądzu ani stali (2,6 i 2,95), a w tritanopii do taśmy (2,86). Dlatego narzędzie zawsze leży na wierzchu z **1,5 dp jasną szczeliną** wokół, jak sylwetka wycięta z innego kartonu, i nigdy nie dotyka mosiądzu, stali ani taśmy bezpośrednio. Sprawdzana para to `tool`/`light`. Reguła jest zapisana w `palette.json` (`rules`).

Wynik `node tools/contrast.mjs przeswit/palette.json` (0 FAIL):

```
fg               bg               use      ratio  protan deutan tritan  ok
ink              light            text     15.82  15.61  15.94  15.53  ✓
soft             light            text      7.07   7.12   7.04   6.96  ✓
ink              shade            text     12.61  12.34  12.77  12.54  ✓
soft             shade            text      5.63   5.63   5.64   5.62  ✓
light            ink              text     15.82  15.61  15.94  15.53  ✓
light            wood             text     12.03  12.48  11.75  11.84  ✓
light            brass            text     10.48  10.68  10.35  10.34  ✓
ink              light            graphic  15.82  15.61  15.94  15.53  ✓
steel            light            graphic  11.89  11.55  12.10  11.65  ✓
brass            light            graphic  10.48  10.68  10.35  10.34  ✓
wood             light            graphic  12.03  12.48  11.75  11.84  ✓
tool             light            graphic   4.03   5.04   3.57   3.98  ✓
tool             ink              graphic   3.92   3.09   4.46   3.90  ✓
light            steel            graphic  11.89  11.55  12.10  11.65  ✓
light            brass            graphic  10.48  10.68  10.35  10.34  ✓
light            tool             graphic   4.03   5.04   3.57   3.98  ✓
ink              shade            graphic  12.61  12.34  12.77  12.54  ✓
```

Tekstu na minii nie stawiamy (`light`/`tool` ma 4,03, poniżej progu 4,5). Przyciski to karton `ink` z jasnym napisem albo tafla z obwódką `ink`.

## 3. Typografia (OFL, polskie znaki)

| Krój | Użycie | Rozmiary (dp) |
|---|---|---|
| **Big Shoulders Stencil** 700–800, opsz 28–72 | Wordmark, nagłówki ekranów, etykiety przycisków, cyfry (monety, „51 h”), litery komór | wordmark 80 / 40 / min. 23 (100 px szer.) · tytuł ekranu 27 · przycisk 19–28 · cyfry 17–26 · litery komór 13–15 |
| **Lato** 400/700/italic (Łukasz Dziedzic) | Tekst, opisy, taśmy, kicker (700, wersaliki, +0,12 em) | tekst 14–15 · notka 15/1,45 · podpisy 11–13 · minimum 10,5 (tylko etykiety tablicy) |

Szablon (stencil) jest tu treścią, a nie ozdobą: litery to dziury wycięte w kartonie. Na ciemnej ścianie świecą tafla i lampa (menu), a na jasnej tafli są ciemne.

## 4. Materiały UI i język ikon

- **Wszystko jest kartonem albo dziurą w kartonie.** Ikona = sylwetka `ink` z jasnymi nacięciami, np. pauza to dwie szczeliny, moneta to podkładka z kwadratowym otworem, a „wróć” to wycięty klin.
- **Przyciski** mają postać zawieszek na klucze z dziurką (menu) albo kartonu ze ściętym rogiem. Główna akcja to tafla z grubą obwódką `ink`, a pozostałe są pełnym kartonem. Cel ≥ 56 dp (min. 48).
- **Taśma malarska** (`shade`, poszarpane końce) niesie podpowiedzi ślusarza i numery eksponatów. Zaklejona sylwetka w warsztacie oznacza „jeszcze nie teraz”.
- **Linia perforacji** (jasne kropki lub kreski na kartonie) znaczy „do wycięcia”, czyli zablokowane albo niekupione. **Pusty jasny otwór w kształcie** znaczy „brak” (złamany wytrych, wolna kieszeń). To odwrócona tablica cieni 5S z ART.md §2.16.
- **Cień rzucony** jest płaski, w kolorze `shade`, przesunięty o 2–3 dp w dół: karton leży 2 dp nad szkłem. Nie ma rozmycia ani poświaty.
- **Faktura i zużycie** są proceduralne i oszczędne: `feTurbulence`/`feDisplacementMap` tylko na zewnętrznej krawędzi żelaza (poszarpany brzeg), kilka ręcznie położonych otarć (jasne kreski 0,9 dp, krycie 55%), nacięcia zużycia na trzonie i zadziory na grocie. Przy linii podziału obowiązuje strefa czysta ±10 dp bez perforacji i otarć.
- **Radełkowanie rękojeści** to drugi kanał rozpoznania narzędzi, wycięty w minii: kreski (haczyk, napinacz kątowy), kropki (falownik), krzyżyki (klin, napinacz listwowy), słoje (podważka). Sylwetki: `mockups/przeswit/tools.js`.

## 5. Wygląd mechanizmu (walor + faktura, nie barwa)

| Materiał | Sylwetka i krawędź | Perforacja (światło przez karton) | Gdzie |
|---|---|---|---|
| **Żelazo** | Poszarpana, kuta krawędź (displacement 5 dp) | gęste okrągłe otwory Ø 3,4 dp co 6 dp (siatka skośna) | obudowa wkładki, płyty zamków zapadkowych |
| **Stal** | Ostra, prosta krawędź, fazy 3 dp | perforacja w **romby** 5 dp co 10 dp | kołki górne, kabłąki, trzpienie |
| **Mosiądz** | Gładka, zaokrąglona krawędź | **krótkie równoległe nacięcia** 8×1,2 dp, mijankowo | rdzeń, kołki dolne, tarcze |
| **Drewno** | Sylwetka warstwowa (rama + skrzydło) | **słoje jako długie faliste szczeliny** 0,9–1,1 dp | drzwi, futryna, zasuwy, podważka |
| **Sprężyna** | Zawsze zygzak z drutu 2,4 dp, światło między zwojami | — | komory |

Skala faktur wynosi ≥ 3 dp (ART.md §4.4). Na kołku o szerokości 30 dp mieszczą się 2–3 romby albo 2 nacięcia, więc faktura nie zamienia się w szum przy 412 dp szerokości.

## 6. HUD diegetyczny (`01-lock.html`)

- **Napięcie, w świecie:** kąt napinacza w kanale (nóżka „L” i ramię z podziałką 6 kresek przy wejściu do kanału) oraz **czoło rdzenia** w HUD-zie. Rdzeń to tarcza z mosiądzu z wyciętym kanałem, obrócona o liczbę podziałek. Podziałki to szczeliny w żelaznym pierścieniu, a podziałka „za daleko” jest dłuższa i wcina się w pierścień.
- **Napięcie, sterowanie (lewy kciuk):** rękojeść napinacza (minia, 68×56 dp, radełko w kreski) przesuwa się w wyciętym torze. Strefa ryzyka na górze toru ma **ząbkowane brzegi** (bez czerwieni). Podpisy „mocno / luźno” są wycięte w kartonie.
- **Wytrych (prawy kciuk):** okno wycięte w kartonie, linijki to szczeliny na ramie („głębiej →”, „↑ unieś”). U góry są litery komór a–e ze strzałką wskazującą bieżącą głębokość. Pierścień kciuka ma średnicę 62 dp.
- **Zużycie wytrycha:** nacięcia na trzonie (co 20 pkt, tu 2) i zadziory na grocie, widoczne w przekroju i w warsztacie.
- **Życia:** tablica „ZAPAS 2/3” z trzema otworami w kształcie wytrycha. Dwa wytrychy leżą w otworach (drugi z zadziorem), a trzeci otwór jest **pusty i jasny**.
- **Postęp:** rząd 5 okienek a–e. Ustawiona komora ma **otwarte okienko** (tafla, ciemna litera, stopka pod spodem), pozostałe są zamknięte (karton, jasna litera). Obok widnieje licznik „1/5”.
- **Głos ślusarza** na taśmie: „Szpulka. Popuść i daj jej wrócić.” (EN: *Spool. Ease off and let it come back.*)

Pomiary: kołki mają 30 dp (pion), a w poziomie ok. 28,7 dp, bo przekrój jest kadrowany do części roboczej (viewBox 0 36 412 286). Linia podziału ma 4 dp, komora 38 dp. Wszystkie akcje leżą w dolnych ~36% ekranu (pion) albo w bocznych kolumnach na całej wysokości (poziom). Safe-area: górny margines `max(env(safe-area-inset-top), 24px)`, dolny 16 px, a w poziomie boczne 28 px.

## 7. Kod stanów z DESIGN.md → Prześwit

| Stan | Realizacja w tym stylu (kształt i światło) | Komora w makiecie |
|---|---|---|
| **swobodny** | Kołek w osi komory, **równe pasy światła 4 dp po obu stronach**, sprężyna z równymi prześwitami między zwojami, płaski cień prosto w dół. Kołek górny przecina szczelinę. | e |
| **binding** | Kołek przesunięty o 3 dp i lekko pochylony, więc **światło prześwituje klinem tylko z jednej strony**. Po stronie docisku w obudowie są wycięte **3 ukośne szczeliny tarcia**. | c |
| **near_shear** | Klin się zwęża: dwa **wycięte trójkąty** (nad i pod szczeliną) zbliżają się do siebie, a jedna szczelina tarcia znika (zostają 2). Fazy na styku kołków tworzą mały jasny „V” tuż nad szczeliną. | c |
| **set** | Styk kołków leży dokładnie na szczelinie, więc **światło przechodzi prosto przez całą komorę**, a szczelina jest ciągła. Kołek górny dostaje płaską **stopkę** (pełna szerokość komory). Rdzeń obraca się o 1 podziałkę, okienko postępu się otwiera. | a |
| **false set** | Talia szpulki siedzi w szczelinie, więc wokół talii powstaje **„oko” światła** (dwie soczewki po bokach przewężenia). Obrys szpulki jest **perforowany** (przerywany jasny brzeg), a rdzeń obraca się o **2 podziałki**, do dłuższej szczeliny „za daleko”. | b |
| **counter_rotate** | Tarcza rdzenia cofa się o podziałkę, ramię napinacza odchyla się ku zeru, a szpulka unosi się sama i „oko” się zamyka. | (opis) |
| **overset** | Kołek dolny przecina szczelinę, więc **szczelina jest zatkana**. Sprężyna jest **pełną czarną bryłą**, bo między zwojami nie ma światła. Nad komorą widać **klamrę** (dwie wycięte poziome szczeliny). | d |
| **drop** | Ustawione kołki spadają kaskadą co 40 ms, otwarte okienka postępu zamykają się kolejno, a rdzeń wraca do zera. | (opis) |
| **stress** | Wytrych **wygina się** łukiem, a na zgięciu pojawiają się **jasne poprzeczne pęknięcia** (rysy, 1→3, tu 2). Przy 90% wytrych drga z amplitudą 1 dp. | wytrych pod c |
| **break** | Wytrych pęka na rysie: grot zostaje w kanale, a uchwyt odskakuje 6 dp. Na tablicy zapasu jeden otwór staje się pusty i jasny. | tablica zapasu |
| **wear** | Zadziory na grocie i nacięcia na trzonie (0–4 stopnie). | wytrych, warsztat |
| **gate_align** | Wycięcie bramki i trzpień zrównują się, więc **wąski prześwit biegnie prosto** przez pakiet (ilustracja suwaków w gablocie). | 03 (diagram) |
| **detector_trip** | Zapadka detektora (karton) opada i zachodzi na rygiel, zasłaniając prześwit bramki. Zmiana sylwetki jest wyraźna. | (opis) |
| **open** | Rygiel wysuwa się (250 ms), a przez rdzeń przechodzi **pełny pas światła** na całej długości. | (opis) |

Test bez koloru: zrzuty `.gray` i `.dim` pokazują, że a–e różnią się kształtem plamy światła (ciągła szczelina, oko, klin, zatkana szczelina z czarną bryłą, równe marginesy).

## 8. Ruch i dźwięk

- **Ruch:** jak wycinanka animowana na stole, czyli przesunięcia sztywnych sylwetek bez deformacji. Wyjątkiem jest wytrych pod stresem, który się wygina. Czasy: set 120 ms (`out-cubic`, bez odbicia), binding 100 ms (krok), false set 160 ms (obrót o 2 podziałki), drop 40 ms na kołek, open 250 ms. Plama światła nie „rozbłyska”, tylko zmienia kształt razem z sylwetką. Zero poświaty, zero sprężynek.
- **Tryb „w ciemności”:** tafla gaśnie do `ink`, a lampa zostaje tylko w szczelinie linii podziału (wąski pas). Gracz widzi tylko to, czy szczelina jest ciągła. Ruch i dźwięk niosą resztę.
- **Dźwięk:** sucha, „kartonowo-metalowa” akustyka małego stołu. Set: jasny, krótki klik blaszki (2–4 kHz, 40 ms). False set: podwójny, głuchszy „klak-trrt”. Binding: ziarniste skrobanie blachy o blachę. Overset: tępy stuk bez dźwięczenia sprężyny, potem cisza komory. W tle cichy brum transformatora lampy (−40 LUFS, wyłączalny), który znika w trybie „w ciemności”.
- **Haptyka:** zgodnie z DESIGN.md §1 (`tension_resistance`, transient set/false set). Haptyka nigdy nie jest jedynym kanałem.

## 9. Marka

- **Wordmark „LOCKWRIGHT”:** Big Shoulders Stencil 800, wersaliki. Jedna **ciągła pozioma szczelina** tnie słowo na wysokości 44% (linia podziału), a dolna połowa jest przesunięta **o jedną podziałkę w prawo**: zamek „zaskoczył”. Na ciemnym tle litery są wycięte (tafla prześwieca), na jasnym są ciemne. Minimum 100 px szerokości. Podtytuł: „POGOTOWIE ZAMKOWE” (EN: *EMERGENCY LOCKSMITH*), Lato 700, +0,32 em.
- **Ikona aplikacji:** jasna tafla, a na niej przekrój z jedną komorą. Ustawiony kołek ze stopką stoi na szczelinie, a minia‑napinacz „L” wchodzi do kanału. Ikona nie ma kłódki, dziurki, złota ani ciemnego tła. W siatce sklepu (`05-brand`, `shared/store-grid.js`) jako jedyna jest jasna, co zgadza się z wnioskiem ART.md §1.4. W 48 px czyta się blok, jasna szczelina i kołek, a w 29 px blok i szczelina.
- **Menu (`04-menu`):** scena z gry, czyli klatka schodowa. Ściana jest z żelaznego kartonu, a wordmark wycięty w niej świeci taflą. Uchylone drzwi nr 12 wpuszczają płaski klin światła na podłogę i na tym świetle leżą zawieszki menu w zasięgu kciuka. Na ścianie wisi ulotka ślusarza z odrywanymi karteczkami (jedna oderwana): „Zatrzasnęło się? Pogotowie zamkowe, całą dobę. Dowód z adresem.” Kapcie pani Haliny stoją pod drzwiami.

Kluczowe napisy PL → EN:

| PL | EN |
|---|---|
| Lockwright: Pogotowie Zamkowe | Lockwright: Emergency Locksmith |
| Ktoś stoi pod drzwiami w kapciach. | Someone's standing outside in slippers. |
| Dalej w serię · Zamek ósmy · zapas 2/3 | Keep going · Lock eight · spares 2/3 |
| Zlecenia — Pani Halina czeka. Rosół też. | Jobs — Mrs Halina is waiting. So is the broth. |
| Warsztat — Haczyk do naprawy | Workshop — Hook needs a fix |
| Gablota — 7 z 31 pod lampą | Showcase — 7 of 31 under the lamp |
| To gra, nie kurs. Zamki są wymyślone. | It's a game, not a course. The locks are made up. |
| Zatrzasnęło się? … Dowód z adresem. | Locked out? … ID with your address, please. |
| Szpulka. Popuść i daj jej wrócić. | Spool. Ease off and let it come back. |
| Wszystko ma swoje miejsce. Jak czegoś brak, widać od razu. | Everything has its place. If something's missing, you see it. |
| Grot ma zadziory. Jeszcze pociągnie, ale sejfu bym nim nie ruszał. | The tip's got burrs. It'll do, but I wouldn't take it near a safe. |
| Napraw · 5 / Do zwijki | Repair · 5 / To the roll |
| Wyzwanie w witrynie | The Challenge in the Window |
| Kustosz: Hobbs miał szesnaście dni. Pani Halina ma rosół na gazie. | Curator: Hobbs had sixteen days. Mrs Halina has broth on the stove. |

**Ekran 3: gablota, nie karta zlecenia. Uzasadnienie:** podświetlana tafla jest dosłownie gablotą (lightbox muzealny, przeglądarka negatywów), więc kierunek jest tu najbardziej „u siebie”. Ten ekran też najlepiej sprawdza, czy język perforacji skaluje się na **inne rodziny** (zapadkowy, dźwigniowy, suwakowy, szyfrowa), czego przekrój wkładki bębenkowej nie pokazuje. Notka Bramaha pozwoliła narysować zasadę `gate_align` jako prześwit przez suwaki, czyli mechanikę wprost w języku stylu. Ciepła tafla, taśmy i głos kustosza odsuwają gablotę od „szarego muzeum”. Pani Halina pojawia się w zamku, w menu i w puencie kustosza.

## 10. Ocena unikalności

| Porównanie | Ich klisza | Prześwit |
|---|---|---|
| Minigry z dużych RPG (Skyrim/Fallout, Oblivion, KCD) | dziurka na czerni, brąz-czerń, ukryty mechanizm | jasna tafla, cały mechanizm odsłonięty, stan = kształt światła |
| Thief Simulator | piny na ciemnym, estetyka włamania | ciepła klatka schodowa, ulotka „dowód z adresem”, kapcie |
| Museum of Mechanics | szara galeria, białe ściany | gablota jako stół z lampą, taśmy, puenta kustosza |
| Lockpick 101 | chrom i turkus, fotoreal | zero połysku, płaski karton |
| Lock Pick 3D | plastikowa tęcza, fiolet | 1 kolor ręki + walory |
| **Unlokee** | niebieski blueprint, drewniany blat, kłódka w centrum | brak błękitu i blatu. „Plan” jest tu cieniem i światłem, nie kreską na niebieskim |
| **Shear Line** | granat, świecące złote piny | piny ciemne, światło **między** pinami, płaskie, bez blasku |
| **Key Master** | skeuomorficzny brąz warsztatu | graficzna wycinanka, brąz tylko jako karton drewna |

Ryzyko podobieństwa: dwa kciuki i przekrój są wspólne z Unlokee (to wymóg projektu). Odróżnia nas warstwa wizualna i idea „stanu jako światła”.

## 11. Ryzyka i koszt produkcji

- **Koszt: niski–średni.** 2D, unlit, płaskie wypełnienia plus maski. Perforacja to tekstura kafelkowa w masce sylwetki, więc nie ma oświetlenia, normal map ani bloomu. Bardzo tanio na Galaxy A1x. Animacja to transformacje sztywnych sylwetek. Najdroższe są wygięcie wytrycha (deformacja splajnu) i ilustracje scen (klatki, mieszkania), ale scena to kilka warstw kartonu.
- **Ryzyko „za graficznie / zimno”:** jeśli pominie się taśmy, cienie i ludzi, robi się z tego piktogram. Lekarstwem są ilustrowane sceny klientów jako sylwetki Reiniger. Ich jakość wymaga ilustratora, bo makieta pokazuje tylko proste rekwizyty.
- **Ryzyko ciemnej masy:** obudowa i rdzeń to duże ciemne plamy. Perforacja żelaza nie może zgęstnieć, żeby nie było „szumu” (pierwsza iteracja z filtrem otarć wyglądała jak śnieg na telewizorze, więc filtr został zastąpiony ręcznymi rysami).
- **Minia vs mosiądz:** wymaga dyscypliny reguły szczeliny 1,5 dp w kodzie (shader obrysu albo druga warstwa sylwetki).
- **Moiré / aliasing perforacji** przy skalowaniu i obrocie rdzenia: perforacja musi być wyrównana do pikseli albo mieć mipmapy z wyostrzeniem. Potrzebny spike na urządzeniu.
- **Tryb jasny w nocy:** jasna tafla razi przy niskiej jasności ekranu. Opcja „lampa przygaszona” (tafla `shade`) i tryb „w ciemności” zostają w ustawieniach.
- **Notka historyczna:** nazwisko Bramah pojawia się jako postać historyczna (wynalazca, 1790). W grze zamek nazywa się ogólnie „zamek suwakowy” (LOCKS.md 2.11). Do potwierdzenia przez właściciela, bo firma o tej nazwie nadal istnieje.

## 12. Lista PNG

W `mockups/przeswit/png/` każdy ekran występuje w 4 wariantach: `.portrait.png` (412×915 @2x), `.landscape.png` (915×412 @2x), `.portrait.gray.png`, `.portrait.dim.png`.

- `01-lock` — zamek w trakcie: a set, b false set, c binding+near_shear z wytrychem pod stresem, d overset, e swobodny; HUD: czoło rdzenia, taśma z podpowiedzią, postęp 1/5, zapas 2/3; kciuki
- `02-workshop` — tablica 9 narzędzi (6 posiadanych, 1 niekupione „brakuje 358”, 2 zaklejone „po zamkach t3/t4”), szczegół Haczyka (zużycie 62/100, naprawa 5), zwijka 3 kieszenie
- `03-showcase` — gablota 7/31 + notka „Wyzwanie w witrynie” (Bramah 1790, 200 gwinei, Hobbs 1851, 51 h w 16 dni, źródło) z diagramem prześwitu suwaków
- `04-menu` — klatka schodowa, wordmark wycięty w ścianie, uchylone drzwi, zawieszki menu na smudze światła
- `05-brand` — wordmark 80/40/23, ikona 96/72/48/29 + szara, siatka sklepu

Pliki źródłowe: `01-lock.html`, `02-workshop.html`, `03-showcase.html`, `04-menu.html`, `05-brand.html`, `przeswit.css`, `tools.js` (sylwetki narzędzi, wordmark, ikona), `palette.json`.
