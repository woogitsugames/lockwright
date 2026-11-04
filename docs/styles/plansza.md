# Kierunek: „Plansza cechowa” (współczesna rycina techniczna)

Status: makiety etapu kierunków wizualnych (2026-11-04). Makiety: `mockups/plansza/`. Render: `cd mockups && node tools/render.mjs plansza`.
EN: *Guild Plate*.

## 1. Idea

**„Plansza cechowa”**: każdy ekran gry to plansza z encyklopedii rzemiosł, narysowana dziś. Materiał oddaje szraf, stan oddaje kształt, a cynober to zawsze twoja ręka.

Dlaczego pasuje do gry z czytelnym przekrojem:
- **Przekrój to rodzimy gatunek tej konwencji.** Plansze „Serrurier” z *Encyclopédie* i rysunki patentowe XIX w. powstały po to, żeby pokazać wnętrze zamka. Nie stylizujemy więc gry na coś obcego, tylko wracamy do źródła.
- **Szraf koduje materiał walorem i kierunkiem, nie barwą.** Mosiądz to drobne poziome linie, stal szraf krzyżowy, żelazo gęsty krzyżowy, drewno słoje. Po zamianie na szarość, przy 50% jasności i przy każdym typie daltonizmu informacja zostaje (DESIGN.md §1).
- **Jeden kolor znaczy jedno.** Cynober mają tylko narzędzia i kciuki gracza. Gracz od pierwszego ekranu wie, co jest „jego”, a co należy do zamka.
- **Litery figur (a–e)** to gotowy, diegetyczny system odwołań: samouczek, notka kustosza i menu mówią „pin c”, „fig. g”, „A — Tryb Ciągły” tym samym językiem.

Ryzyko pastiszu (sepia, „stary papier”, ozdobniki) omijamy świadomie: papier jest czysty i płaski, bez plam i bez winiety. Linia ma stałą grubość, kompozycja jest asymetryczna, z dużą ilością powietrza, a typografia współczesna (Brygada 1918 to cyfrowa rewitalizacja z 2018 r., a nie font „na stare”).

## 2. Paleta

| Nazwa | HEX | Rola |
|---|---|---|
| `paper` | #EFEBE1 | tło każdego ekranu, prześwity, linia podziału (jasna szczelina) |
| `paper_deep` | #DED7C6 | pola (tablica cieni, fascia, strefy pomocnicze), nigdy pod tekstem w ochrze |
| `ink` | #1C1A17 | kontur, szraf, tekst, przycisk główny (pełny tusz) |
| `ink_soft` | #57514A | tekst drugorzędny, cień na tablicy, plan dalszy (sąsiednia kamienica) |
| `hand` | #B3311D | **wyłącznie ręka gracza**: wytrych, napinacz, kciuki, klamry wyboru (palec na pozycji). Nigdy tekst, nigdy element zamka, nigdy litera znaku |
| `seal` | #24476B | pieczęcie zleceń i mapa (np. stempel „wkrótce” przy Zleceniach) |
| `ochre` | #8A5A14 | monety, ceny, numery katalogowe gabloty. Tylko linia, bez blasku i bez wypełnień „złotem” |

Wynik `node tools/contrast.mjs plansza/palette.json` (WCAG + CVD Machado 2009): **0 FAIL**.

```
fg               bg               use      ratio  protan deutan tritan  ok
ink              paper            text     14.59  14.54  14.61  14.57  ✓
ink_soft         paper            text      6.58   6.62   6.55   6.58  ✓
ink              paper_deep       text     12.11  12.00  12.17  12.08  ✓
ink_soft         paper_deep       text      5.46   5.47   5.46   5.46  ✓
ochre            paper            text      4.96   5.49   4.68   5.01  ✓
seal             paper            text      8.06   7.52   8.43   7.80  ✓
paper            ink              text     14.59  14.54  14.61  14.57  ✓
hand             paper            graphic   5.23   6.92   4.51   5.14  ✓
hand             paper_deep       graphic   4.34   5.71   3.76   4.26  ✓
ink              paper            graphic  14.59  14.54  14.61  14.57  ✓
ink_soft         paper_deep       graphic   5.46   5.47   5.46   5.46  ✓
ink_soft         paper            graphic   6.58   6.62   6.55   6.58  ✓
paper            hand             graphic   5.23   6.92   4.51   5.14  ✓
seal             paper            graphic   8.06   7.52   8.43   7.80  ✓
ochre            paper            graphic   4.96   5.49   4.68   5.01  ✓
```

Reguła wynikła z testu: `ochre` na `paper_deep` daje 4,12 (deutan 3,90), więc cena na tablicy cieni stoi zawsze na papierowej plakietce z ochrową ramką (02-workshop). Cynober nie dotyka szrafu bez 1 dp jasnej szczeliny.

## 3. Typografia (OFL)

- **Brygada 1918** (Variable, OFL): nagłówki, nazwy narzędzi, litery figur (*a–e*, kursywa 600), liczby (cyfry nautyczne `oldstyle-nums` dla monet i numerów katalogowych). Polski krój z 1918 r., odtworzony w 2018 r. (Polska Fundacja Fontów). Ma pełne polskie znaki i `ı` (U+0131), z którego korzysta znak słowny.
- **Source Serif 4** (opsz, OFL): tekst ciągły, notki kustosza, podpisy osi i źródła. Kursywa dla głosu postaci („Ramię trzyma rygiel…”).
- Skala: 24 (tytuł menu) / 22 (nagłówek karty) / 19 (pozycja menu) / 15–14,5 (tekst) / 13–12 (podpisy, minimum). Interlinia tekstu ciągłego 1,42.
- Kluczowe napisy EN: *Continuous Mode*, *Jobs — soon*, *Showcase*, *Workshop*, *Settings*, *Shadow Board*, *Buy*, *Repair*, *Play this lock*, *Emergency Locksmith*.

## 4. Materiały UI i język ikon

- **Ramka planszy**: podwójna linia (1,5 dp + 1 dp, odstęp 5 dp) na każdym ekranie. Ta sama podwójna linia na przycisku głównym i na pierwszej pozycji menu. Nie ma kart z zaokrągleniami ani cieni rzucanych.
- **Przyciski**: prostokąt z podwójną linią, min. 56 dp wysokości. Główny jest wypełniony tuszem z papierowym tekstem, drugorzędny ma papier i tusz. Nieaktywny ma przerywaną literę figury i stempel w błękicie pruskim.
- **Wybór = ręka**: cynobrowe klamry narożne (3,5 dp) wokół pozycji, na której gracz trzyma palec (tablica cieni, gablota). To ten sam kolor co wytrych w przekroju, czyli jeden sygnał: „tu działasz ty”.
- **Piktogramy rodzin** (16 dp, linia 1,5 dp, siatka 45/90°, za Aicherem): wooden, warded, ring, wafer, wafer2, pin, lever, levdet, tubular, sidebar, dimple. Jeden znak = jedna rodzina we wszystkich ekranach.
- **Moneta**: okrąg z sylwetką bródki klucza, linia ochrowa 1,6 dp. Bez wypełnienia i bez połysku.
- **Szraf jest proceduralny** (`mockups/plansza/defs.js`): wzory `h-brass`, `h-steel`, `h-iron`, `h-wood`, radełka `k-*` i tablica `h-board` są zdefiniowane raz, a każdy ekran tylko się do nich odwołuje.

## 5. Wygląd mechanizmu

| Materiał | Szraf | Walor (szarość) |
|---|---|---|
| mosiądz (rdzeń, kołki dolne) | drobne poziome linie 0,55 dp co 4 dp | jasny |
| stal (kołki górne, narzędzia) | krzyżowy 0,7 dp co 4 dp | średni |
| żelazo (obudowa) | gęsty krzyżowy 1,5 + 0,9 dp co 5 dp | ciemny |
| drewno (skrzydło drzwi, gablota, Podważka) | słoje, linie falowe 0,8 dp | jasny, kierunkowy |
| sprężyna | falista linia 1,6 dp; overset = pełna czarna bryła | — |
| narzędzie gracza | pełny cynober 5–7 dp z jasnym rdzeniem 1 dp | średni, ale zawsze z jasną szczeliną |

Linia podziału to podwójna linia tuszu z jasną szczeliną 2–4 dp, bez faktury w promieniu 1 dp (DESIGN.md §2). Rdzeń pod napięciem jest przesunięty w bok o 5 dp, więc widać, że „pracuje”.

## 6. HUD diegetyczny

- **Czoło rdzenia** z wygrawerowaną skalą: 1 podziałka = set, gruba kreska „za daleko” = false set. Napinacz w czole jest cynobrowy.
- **Tablica cieni** (w zamku: 3 wytrychy, w warsztacie: 10 narzędzi). Brak narzędzia = pusty kontur. Zużycie to zadziory na grocie (0–4), widoczne na sylwetce, a nie na pasku.
- **Winieta „fig. 1”** nad przekrojem: drzwi klienta w elewacji, z cynobrowym okręgiem na wkładce, czyli „tu pracujesz”.
- Strefy kciuków: lewa to pionowa skala napięcia ze szrafem żelaza na strefie stresu (bez czerwieni), prawa to pad 2D z siatką i osiami „unies.” / „głęb.”.

## 7. Realizacja kodu stanów z DESIGN.md

| Stan | Realizacja w „Planszy” (kształt, w szarości) | Kolor (tylko wzmocnienie) |
|---|---|---|
| swobodny | kołek w osi komory, sprężyna o równych zwojach | — |
| binding | kołek przesunięty 2–3 dp do ściany, **3 ukośne kreski tarcia** tuszem na linii podziału | — |
| near_shear | **pionowy klin na ścianie komory tego pinu**: trójkąt w dół od linii podziału i trójkąt w górę od spodu kołka, z dwiema liniami odniesienia. Odstęp czubków maleje z odległością od linii; jedna kreska tarcia znika | — |
| set | płaska czarna **stopka** na linii podziału, skala czoła +1 podziałka | — |
| false set | kołek-szpulka z **talią** zaklinowaną na linii, **obrys przerywany**, skala +2 i gruba kreska „za daleko” | — |
| counter_rotate | łuk na czole cofa się, napinacz odchyla się w stronę zera | cynober napinacza |
| overset | sprężyna jako **pełna czarna bryła** z jasnymi szczelinami zwojów, **klamra** (2 kreski) nad komorą | — |
| drop | kaskada kołków (40 ms), skala wraca do zera | — |
| stress | wytrych się wygina, na zgięciu **1→3 poprzeczne rysy** tuszem | cynober wytrycha |
| break | grot zostaje w kanale, rękojeść odskakuje; na tablicy zostaje **pusty kontur** | — |
| wear | zadziory na grocie 0–4 (ten sam znak w przekroju, na tablicy i w karcie narzędzia) | — |
| gate_align | wycięcie i trzpień w jednej linii, wąska jasna szczelina papieru | — |
| detector_trip | zapadka detektora opada i zmienia sylwetkę rygla (jak Nr 07 w gablocie) | — |
| open | rygiel do końca (250 ms), skala na pełnej podziałce | — |

Poprawka w 01-lock (ta iteracja): klin near_shear stał między komorami b i c i wyglądał jak strzałka wskazująca pin b. Teraz to pionowy „wymiar” przyklejony do ściany komory c, z liniami odniesienia do linii podziału i spodu kołka. Kierunek trójkątów nie wskazuje żadnego innego pinu. Litery a–e dostały jasne podkładki, żeby szraf drewna ich nie przecinał (szczególnie w poziomie).

## 8. Ruch i dźwięk

- **Animacja 100–250 ms, `out-cubic` lub krokowo, bez sprężynek i bez overshoot.** Ruch jak rycina „przerysowana” o krok: kołek przeskakuje na półkę w 120 ms, klamry wyboru pojawiają się w 100 ms (bez skalowania), karta katalogowa wysuwa się 200 ms z dołu jak arkusz z teczki. Przejścia między ekranami to cięcie albo przesunięcie arkusza, bez przenikania.
- **Szraf się nie animuje.** Stan zmienia geometrię, a faktura zostaje stała. To tani i spokojny obraz, a przy okazji brak migotania przy 60 FPS.
- **Brzmienie**: suche, bliskie, „papierowe”: drewniany blat, mosiądz o mosiądz, ołówek po papierze przy przewracaniu arkusza (menu, gablota). Set to jasny suchy klik, false set głuchy i podwójny, overset martwy stuk (TECH.md). Zakup w warsztacie to krótki metaliczny dźwięk zawieszenia narzędzia na haczyku tablicy, bez „kaching”.
- **Haptyka**: zgodnie z DESIGN.md; na ekranach menu tylko lekki tik przy wyborze (sharpness niska). Nigdy jedyny kanał.

## 9. Marka

- **Znak słowny** (`05-brand.html`, `Plansza.wordmark()` w `defs.js`): Brygada 1918 Bold, **przecięta linią podziału** na wysokości połowy x. Dolna połowa liter jest przesunięta w prawo o 4,5–5% em, jak rdzeń pod napięciem. Kropka nad „ı” to **pin** (prostokąt 0,13 × 0,25 em) siedzący nad linią, czyli moment „set”. Krótkie podwójne kreski po obu stronach to dalszy ciąg linii podziału. Działa w tuszu na papierze i w papierze na tuszu. Cynober nie wchodzi w litery. Bez kłódki, dziurki i złota.
- **Ikona** (`Plansza.icon()`): jedna komora w chwili „set”. Żelazna obudowa (gruby szraf krzyżowy), czarny kołek ze stopką na linii, mosiężny rdzeń przesunięty o 4% i **cynobrowy wytrych od dołu** jako jedyny akcent. Jasne tło wyróżnia ją w siatce sklepu, gdzie archetypy konkurencji są ciemne, złote albo fioletowe (`store-grid.js`). Przy 48 px czyta się: ciemny pas, jasna komora, czarny blok, czerwona krzywa. Poniżej 32 px wariant bez zwojów sprężyny.
- **Menu** (`04-menu.html`): plansza tytułowa. Rycina kamienicy przy Ślusarskiej 7 z przekrojem ściany, Pani Halina w oknie iii piętra (A), furgonetka „Pogotowie Zamkowe” (B), witryna-gablota (C), drzwi warsztatu z tablicą cieni (D) i domofon (E). Litery figur w rycinie odpowiadają pozycjom legendy w dolnych 40% ekranu, więc menu jest objaśnieniem planszy, a nie listą przycisków. Bez „Welcome” i bez „Get Started”: pierwsza pozycja mówi, gdzie czeka następny klient.

## 10. Ocena unikalności

| Konkurent | Ich klisza | „Plansza” |
|---|---|---|
| Minigry z dużych RPG (Skyrim, Fallout, Oblivion, KCD) | czoło z dziurką na ciemnym tle, mechanizm ukryty albo w brudnym brązie | jasny papier, przekrój z kontekstem drzwi i kamienicy, mechanizm w pełni czytelny |
| Thief Simulator | piny na czerni, fantazja włamania | ciepły i legalny ślusarz, klient z imieniem i rosołem |
| Museum of Mechanics: Lockpicking | białe ściany, gabloty, tabliczki („szare muzeum”) | gablota jako plansza katalogowa z ochrowymi numerami, drewnianą ramą i notką ze źródłem, a nie sala z cokołami |
| Lockpick 101 | chromowana kłódka na turkusie | brak chromu i połysku; materiał to szraf |
| Lock Pick 3D | plastikowa tęcza, zębatki, fiolet | dwie barwy funkcjonalne plus tusz; bez zębatek |
| **Unlokee** (najbliższy) | niebieski blueprint z odręcznymi strzałkami, drewniany blat, mosiężna kłódka | kremowy papier zamiast niebieskiego, miedziorytowy szraf zamiast odręcznego szkicu, litery figur zamiast strzałek, kamienica i drzwi klienta zamiast kłódki na blacie. Błękit pruski tylko na pieczęciach zleceń |
| Shear Line | granat, świecące złote piny, heist | zero blasku, złoto zakazane; ochra tylko na monetach jako linia |
| Key Master | skeuomorficzny brązowy warsztat, paragony | warsztat jako tablica cieni w furgonetce (diegetyczny ekwipunek bez liczników) |

Najbliższe ryzyko to skojarzenie „rysunek techniczny = blueprint jak Unlokee”. Bronią się trzy rzeczy: jasny papier, szraf jako materiał (nie kontur na niebieskim) i cynober jako ręka.

## 11. Ryzyka i koszt produkcji

- **Zaleta kosztowa: szraf proceduralny jest tani przy rozbudowie latami.** Nowa rodzina zamka to geometria (ścieżki) plus nazwa materiału. Faktury nie trzeba malować ani teksturować. Ten sam zestaw 4 szrafów, 7 radełek i jednego filtra cienia (feMorphology) obsługuje przekrój, warsztat, gablotę, menu i ikonę. W silniku: shader szrafu w przestrzeni ekranu (kąt, gęstość, grubość) albo wektor z wzorem, który skaluje się bez utraty jakości na każdym DPI.
- **Moiré i aliasing** szrafu przy małych skalach i ruchu. Środki: szraf w przestrzeni ekranu (nie obiektu), gęstość zależna od DPI, przy < 1 px linia przechodzi w ton (ikona już tak robi).
- **Pastisz Diderota**: pilnować czystego papieru, stałej linii i współczesnej, asymetrycznej kompozycji. Żadnych plam, bordiur roślinnych ani długiej s.
- **Gęstość informacji** na tablicy cieni (10 slotów × nazwa, status, rodziny, cena): na granicy przy 12 dp. W produkcji status można pokazać ikoną, a nazwę dopiero po dotknięciu.
- **Cynober i protanopia**: na `paper_deep` deutan 3,76 (≥ 3, OK). Cynober nigdy nie niesie sam znaczenia, bo ręka ma też kształt i pozycję.
- **Ilustracje scen** (kamienica, furgonetka) wymagają ilustratora z dyscypliną linii. To koszt jednorazowy na dzielnicę, a nie na zamek.

## 12. Lista PNG

`mockups/plansza/png/` (każdy ekran: `portrait` 412×915 @2x, `landscape` 915×412 @2x, `portrait.gray`, `portrait.dim`):

- `01-lock.*`: ekran zamka (poprawiony klin near_shear, podkładki liter, etykieta osi pada, niższy HUD w poziomie)
- `02-workshop.*`: tablica cieni w furgonetce, 10 narzędzi (5 na tablicy, 1 w naprawie, 2 na sprzedaż, 2 zablokowane), karta Korby dźwigniowej, przyciski Napraw / Kup
- `03-showcase.*`: gablota 9 pól (Nr 01–12), karta Nr 10 „51 godzin w 16 dni” ze źródłem
- `04-menu.*`: plansza tytułowa z kamienicą i legendą A–E
- `05-brand.*`: znak słowny w 4 wariantach, ikona 120/72/48/29, siatka sklepu, menu w miniaturze

Pliki źródłowe: `01-lock.html`, `02-workshop.html`, `03-showcase.html`, `04-menu.html`, `05-brand.html`, `plansza.css`, `defs.js` (biblioteka szrafów, sylwetek, piktogramów i znaku), `palette.json`.
