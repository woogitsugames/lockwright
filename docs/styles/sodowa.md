# Kierunek: „Sodowa noc” (linoryt i risografia nocnego pogotowia)

Status: makiety etapu kierunków wizualnych (2026-11-04). Makiety: `mockups/sodowa/`. Render: `cd mockups && node tools/render.mjs sodowa`.

## 1. Idea

**„Sodowa noc”**: świat nocnego pogotowia wycięty dłutem w linoleum i odbity na risografie trzema farbami na papierze gazetowym. **Światło jest tym, co dłuto wycięło.**

Dlaczego pasuje do gry z czytelnym przekrojem:
- **Lampa sodowa daje światło prawie jednobarwne** (589 nm), więc w świecie gry nie ma barw, jest tylko walor. Paleta, która musi działać w skali szarości, ma uzasadnienie w fabule, a nie wygląda jak ograniczenie dostępności.
- **Linoryt to technika dwuwartościowa**: farba albo papier. Każdy element dostaje twardy kontur i jedną płaską plamę, więc stany mechanizmu czytamy kształtem (ligne claire, Isotype), a nie cieniowaniem.
- Materiał rozróżniamy **kierunkiem i rytmem nacięć**, czyli kanałem, który zostaje po zamianie na szarość, przy 50% jasności i przy każdym typie daltonizmu.
- Ton: ciepłe kamienice, sąsiadki w szlafrokach i wałkach, furgonetka pod latarnią. Noc oznacza tu dyżur, a nie włamanie.

Różnica wobec „Planszy cechowej”: tam jest jasny papier, miedziorytowy szraf i cynober jako ręka gracza. Tu przeważa noc (atrament), środek ekranu zajmuje żółta plama światła sodowego, a faktura pochodzi z dłuta i z ziarna risografu. Nie ma szrafu krzyżowego jako cieniowania ani literowanych tablic.

## 2. Paleta

Trzy farby risograficzne (atrament, cegła, sodowa) na papierze gazetowym. Dwa kolory są nadrukami (`noc`, `zelazo`), dwa to raster atramentu (`stal`, `popiol`). W produkcji to nadal 3 bębny plus papier.

| Nazwa | HEX | Skąd w druku | Rola |
|---|---|---|---|
| `papier` | #EEE4CB | niezadrukowany papier gazetowy | światło wycięte dłutem, mosiądz, linia podziału (pasek środkowy), tekst na nocy |
| `atrament` | #1C1719 | bęben czarny | noc, kontury, sprężyny, tekst na papierze i na żółtym |
| `noc` | #2C2326 | atrament + cegła 20% | panele, przyciski drugorzędne, strefy kciuków |
| `sodowa` | #EBAE3E | bęben żółty (pasowanie przesunięte o 1,2/−0,8 dp) | światło latarni na scenie, komory i kanał w przekroju, sterowanie gracza (kciuki, przycisk główny), monety |
| `cegla` | #9E3B29 | bęben ceglany | drewno (słoje), drzwi, wycieraczka, pieczątki („NOC”), ceny |
| `zelazo` | #4A2D29 | atrament na cegle | żelazo (obudowa wkładki, pierścień czoła rdzenia) |
| `stal` | #8D8379 | raster atramentu 45% | stal (kołki górne) |
| `popiol` | #B9AE9C | raster atramentu 25% | tekst drugorzędny na nocy, siatka pada |

**Dlaczego te farby.** Wszystkie trzy leżą w jednym ciepłym łuku barwnym (żółć, cegła, ciepła czerń), czyli tak, jak widzi się świat pod lampą sodową. Nie ma pary dopełniającej, więc nie powstaje teal-orange ani fiolet z niebieskim. Jedyny „zimny” akcent to niezadrukowany papier (okna z domowym światłem). Żółć jest światłem padającym na scenę i kolorem rąk gracza, ale **nigdy nie jest kolorem pinu**: piny są stalowe (raster) i mosiężne (papier z nacięciami), płaskie, bez połysku.

**Kontrast** (`node tools/contrast.mjs sodowa/palette.json`, WCAG + symulacja CVD Machado 2009). Wynik: 0 FAIL.

```
fg               bg               use      ratio  protan deutan tritan  ok
atrament         papier           text     13.99  13.83  14.09  13.94  ✓
papier           atrament         text     13.99  13.83  14.09  13.94  ✓
papier           noc              text     12.06  12.00  12.10  12.01  ✓
sodowa           atrament         text      8.99   8.15   9.51   8.86  ✓
sodowa           noc              text      7.75   7.07   8.16   7.63  ✓
atrament         sodowa           text      8.99   8.15   9.51   8.86  ✓
cegla            papier           text      5.33   6.51   4.78   5.34  ✓
papier           cegla            text      5.33   6.51   4.78   5.34  ✓
popiol           atrament         text      8.09   7.98   8.16   8.06  ✓
atrament         popiol           text      8.09   7.98   8.16   8.06  ✓
zelazo           sodowa           graphic   6.27   5.96   6.45   6.20  ✓
papier           zelazo           graphic   9.77  10.12   9.55   9.75  ✓
atrament         stal             graphic   4.77   4.71   4.81   4.76  ✓
atrament         sodowa           graphic   8.99   8.15   9.51   8.86  ✓
papier           noc              graphic  12.06  12.00  12.10  12.01  ✓
sodowa           zelazo           graphic   6.27   5.96   6.45   6.20  ✓
papier           cegla            graphic   5.33   6.51   4.78   5.34  ✓
cegla            sodowa           graphic   3.42   3.83   3.23   3.39  ✓
stal             atrament         graphic   4.77   4.71   4.81   4.76  ✓
```

Pary celowo nieużywane (bo za słabe): `stal`/`sodowa` (≈1,9), `papier`/`sodowa` (≈1,5), `cegla`/`atrament` (≈2,6). Tam, gdzie te materiały się stykają, **zawsze jest kontur atramentowy 2–2,4 dp** (9:1 na żółtym, 14:1 na papierze). Żelazo na tle żółtym ma 6,3:1 samym wypełnieniem, a na nocy (czoło rdzenia w HUD) dostaje obwódkę z papieru 2 dp (9,8:1). Zasada z ART.md 4.1 jest spełniona konturem, a nie wypełnieniem.

**CVD.** Wszystkie pary trzymają próg w protanopii, deuteranopii i tritanopii (najniższy wynik: cegła na papierze w deuteranopii, 4,78). Żaden stan ani funkcja nie jest kodowany parą czerwień/zieleń.

## 3. Typografia (OFL)

| Rola | Krój | Ustawienia | Rozmiary (dp) |
|---|---|---|---|
| Wordmark, nagłówki, imiona w dialogach, podpisy stref kciuków | **Fraunces** (variable) | `SOFT 100`, `WONK 1`, `opsz` 24–144, 500–700. Miękkie, lekko krzywe szeryfy wyglądają jak odbitka z klocka | wordmark 64–74, tytuł ekranu 22, nagłówek karty 15–24, kursywa podpisów 14–16 |
| Tekst, liczby, przyciski | **Bitter** (variable) | 400–700, cyfry `lining tabular` w wycenie i monetach | tekst 14–14,5, opisy 12–13, minimum 11 (podpisy osi i siatki) |

Rozstrzelone wersaliki Bittera (letter-spacing 0,2–0,24 em) służą tylko do haseł szyldowych („POGOTOWIE ZAMKOWE”). Polskie znaki sprawdzone w renderach (ą, ę, ł, ś, ź, ż, ó, ń, ć).

## 4. Materiały UI i język ikon

- **Odbitka z klocka**: przyciski i panele to płaskie plamy z konturem 2 dp. Rogi są lekko nierówne (asymetryczny `border-radius`), jak krawędź wyciętego linoleum. Nie ma cieni miękkich ani rozmyć.
- **Przycisk główny** = żółty bęben z konturem atramentowym i przesuniętym pasowaniem (twardy „cień” atramentu 1,2 dp, a nie rozmyty). **Drugorzędny** = noc z obrysem papieru. **Na sprzedaż** = pasek cegły na zawieszce.
- **Papierowe kartki** (wycena, dowody, zawieszki narzędzi) mają poszarpaną górną krawędź (clip-path), czyli kartkę z bloczka. To nie są karty SaaS: brak zaokrągleń, brak cieni, tekst do lewej.
- **Faktura**: (1) słoje i nacięcia jako wypełnione, zwężające się „soczewki” (ślad dłuta), (2) obwódki-echo wokół obiektów (klasyczne „halo” linorytu), (3) lekkie falowanie konturów tła (`feDisplacementMap`, skala 2–2,6), (4) ziarno risografu (`feTurbulence`, krycie 0,08–0,22). Wszystko jest proceduralne, bez tekstur ze stocku.
- **Ikony UI**: kreska 2,4 dp, kwadratowe zakończenia, bez wypełnień, w kafelku 48 dp z nierównym obrysem. Zestaw: pauza, wróć, zlecenie (słuchawka), furgonetka, gablota, moneta (krążek z wybitym kluczem płaskim), naprawa (pilnik). Patrz `05-brand`.
- **Wskaźnik pewności weryfikacji** = poziomica: pęcherzyk między kreskami oznacza „Czuję się pewnie”, przesunięty oznacza „Coś mi nie pasuje”, przy krawędzi „Za mało wiem”. Zawsze z podpisem, więc działa kształtem, a nie kolorem.

## 5. Wygląd mechanizmu

Przekrój jest „oświetlony lampą”: tło przekroju to żółty bęben (drewno drzwi ze słojami w cegle), a komory i kanał to wycięcia, przez które widać światło. Dzięki temu każdy metal leży na jasnym tle i ma kontur atramentowy.

| Materiał | Walor | Nacięcie (faktura) | Krawędź |
|---|---|---|---|
| **Mosiądz** (rdzeń, kołki dolne) | najjaśniejszy (papier) | **długie, gładkie, równoległe pociągnięcia**: poziome na rdzeniu, pionowe na kołkach | zaokrąglona końcówka kołka, kontur 2,4 |
| **Stal** (kołki górne, szpulka) | średni (raster 45%) | **drobne krzyżowe nacięcia** co 5 dp | ostra, kontur 2,4 |
| **Żelazo** (obudowa) | ciemny (atrament na cegle) | **grube, gęste, chropawe** krótkie wyrwy, w których widać cegłę | wewnętrzny rant z papieru 1,6 dp plus kontur 4 dp |
| **Drewno** (drzwi) | średni (cegła na żółtym) | **słoje dłutem**: zwężające się soczewki, falujące | brak (tło), obwódki-echo papierem wokół wkładki |
| **Sprężyna** | atrament | zygzak; przy overset pełna czarna bryła | — |

**Linia podziału:** podwójna (atrament 1,8 / papier 3 / atrament 1,8), razem 6 dp. Jest jedynym poziomym pasem papieru w przekroju i wychodzi poza wkładkę z „znacznikami pasowania”. W paśmie ±6 dp nie ma żadnej faktury: tekstura żelaza kończy się 6 dp nad linią, nacięcia mosiądzu zaczynają się 6 dp pod nią, a ziarno risografu jest tam wymaskowane.

Rozmiary: kołki 30 dp szerokości (≥ 28), komory 36 dp, podziałka 64 dp przy 5 stosach.

## 6. HUD diegetyczny

| Informacja | Gdzie w świecie | Jak czytać bez koloru |
|---|---|---|
| **Napięcie** | (1) kąt napinacza wystającego z kanału wobec skali wyrytej w drzwiach („trzecia kreska”); (2) czoło rdzenia w HUD: kreski na żelaznym pierścieniu, szczelina kanału obrócona o liczbę podziałek | kąt i liczba kresek. Set = 1 podziałka, false set = 2 podziałki + znacznik „T” („za daleko”) |
| **Zużycie wytrycha** | zadziory (ząbki) na grocie w przekroju; nacięcia na trzonie co 20 pkt na zapasowych wytrychach i w warsztacie | liczba ząbków i nacięć |
| **Życia** (3 zapasowe wytrychy) | leżą na wycieraczce pod drzwiami klienta | wytrych = pełna sylwetka; brak = przerywany „czysty ślad” w miejscu, gdzie leżał |
| **Postęp** | kreski kredą na futrynie: pełny prostokąt = set, przerywany = false set, pusty = jeszcze nie | wypełnienie i typ obrysu, plus podpis „1 z 5 siedzi” |
| **Stres wytrycha** | zgięcie trzonu (cienka przerywana prosta pokazuje, ile się wygiął) + 1–3 poprzeczne rysy | krzywizna i liczba rys |

Strefy kciuków są poza światem (noc, dolne 35% ekranu): po lewej pionowy suwak napięcia (uchwyt 80×50 dp, strefa „pęka” zakreskowana grubymi nacięciami, a nie kolorem), po prawej pad wytrycha 2D z pozycjami komór a–e na osi głębokości.

## 7. Realizacja kodu stanów z DESIGN.md

| Stan | W tym stylu (geometria jak w DESIGN.md) |
|---|---|
| **swobodny** | Kołek w osi komory, sprężyna o równych zwojach, krótka kreska cienia prosto pod kołkiem dolnym (atrament 55%). Bez znaków. |
| **binding** | Kołek górny przesunięty o +3 dp i dociśnięty do prawej ścianki. Przy ściance, na linii podziału, są krótkie ukośne kreski tarcia (atrament 3 dp z wyciętym papierem w środku). |
| **near_shear** | Klin: dwa trójkąty po lewej stronie komory, górny papierowy na żelazie, dolny atramentowy na mosiądzu. Ich wierzchołki zbliżają się do siebie. Przy near_shear zostają 2 kreski tarcia zamiast 3. |
| **set** | Kołek górny stoi na rdzeniu z płaską, czarną **stopką** (36 dp, z wyciętą papierową linią). Kołek dolny opada. Czoło rdzenia obraca się o 1 podziałkę. |
| **false set** | Szpulka z **talią na linii podziału**, obrys **przerywany** (6/3,5). Czoło rdzenia: 2 podziałki + znacznik „T”. Tekst HUD: „Szpulka. Popuść.” |
| **counter_rotate** | Czoło rdzenia: szczelina wraca o podziałkę, wyryta strzałka-łuk na pierścieniu cofa się, napinacz w przekroju odchyla się ku zeru wobec skali w drzwiach. |
| **overset** | Kołek dolny przecina linię. Sprężyna jest pełną czarną bryłą z cienkimi stalowymi liniami styku zwojów. Nad komorą jest **klamra**: dwie papierowe kreski wycięte w żelazie. |
| **drop** | Stopki znikają kaskadowo (40 ms odstępu), kreski kredą na futrynie wracają do pustych, szczelina na czole wraca na zero. |
| **stress** | Trzon wytrycha wygięty (krzywizna rośnie liniowo), obok cienka przerywana prosta jako punkt odniesienia, 1→3 poprzeczne rysy. Przy 90% drganie 1 dp. |
| **break** | Grot zostaje w kanale, uchwyt odskakuje 6 dp. Na wycieraczce w HUD jeden wytrych zmienia się w przerywany ślad. |
| **wear** | 0–4 zadziory na grocie, nacięcia na trzonie co 20 pkt (przekrój, wycieraczka, tablica w furgonetce). |
| **gate_align** | Wycięcie i trzpień w jednej linii; między nimi wąska szczelina papieru (prześwit). |
| **detector_trip** | Zapadka (żelazo z papierowym rantem) opada na rygiel i zmienia sylwetkę. |
| **open** | Rygiel jedzie do końca (250 ms), czoło rdzenia obraca się o 90°. Na scenie zlecenia zapala się okno mieszkania (papier). |

Test w renderach `01-lock.portrait.gray.png` i `.dim.png`: stany a–e są rozróżnialne samym kształtem.

## 8. Ruch i dźwięk

- **Ruch**: krokowy, jak przekładanie odbitek. 100–250 ms, `out-cubic` albo `steps(2–3)` dla zmian znaków (kreski tarcia, klamra, stopka pojawiają się „wybite”, bez fade). Bez overshoot i bez sprężynek. Set: 120 ms. Open: 250 ms. Kaskada drop: 40 ms odstępu.
- **Przesunięcie pasowania jako sygnał**: przy *set* żółty bęben „przeskakuje” o 1 dp na 80 ms (drgnięcie odbitki). To jedyny efekt ozdobny i jest wyłączany razem z „Ogranicz ruch”.
- **Ziarno** jest statyczne (nie animujemy szumu: koszt i migotanie).
- **Dźwięk**: metal nagrany blisko, sucho, w małym pomieszczeniu (klatka schodowa). Set = suchy, jasny klik mosiądzu (2–4 kHz). False set = głuchszy „klak-trrt”. Overset = martwy stuk. W tle szum lampy sodowej (niski brzęk dławika) i automat schodowy, który co jakiś czas cyka. Bez muzyki „heist”.
- **Haptyka** wg biblioteki z TECH.md (`tension_resistance` itd.). Zawsze dubluje obraz i dźwięk, nigdy nie jest jedynym kanałem.

## 9. Marka

- **Wordmark**: „Lockwright” we Fraunces 700, SOFT 100, WONK 1, przecięty **linią podziału**. Górna połowa liter jest przesunięta o 3 dp (jak rdzeń pod napięciem), a w dolnej widać żółty bęben z przesuniętym pasowaniem. Krótkie żółte znaczniki po bokach przedłużają linię. Od 40 px z cięciem, poniżej bez cięcia. Podpis: **„POGOTOWIE ZAMKOWE”** (EN: **„EMERGENCY LOCKSMITH”**), w menu z dopiskiem „· NOCĄ TEŻ” (EN: „· NIGHTS TOO”).
- **Ikona**: drzwi uchylone na klatce w świetle sodowym. Z mieszkania na podłogę wypada klin domowego światła (papier), a próg to podwójna linia podziału. Bez kłódki, bez dziurki od klucza, bez złota. W siatce sklepu jest jedyną jasną ikoną wśród ciemnych archetypów. Czytelna przy 48 i 29 px oraz w szarości (`05-brand`).
- **Menu** jako scena: ulica kamienic nocą, latarnia sodowa (pełna plama + raster na brzegach + promienie dłutem), furgonetka „POGOTOWIE ZAMKOWE 24 h” w świetle, na III piętrze żółte okno klatki z dwiema sylwetkami (Halina i Zosia), obok zaparowane okno kuchni z rosołem, w sąsiedniej kamienicy sąsiad w szlafmycy z telefonem (następne zlecenie). Przyciski w dolnych 35%.

Kluczowe napisy PL → EN:

| PL | EN |
|---|---|
| Pani Halina czeka. Rosół też. | Mrs Halina is waiting. So is the broth. |
| Odbieram telefon | I'll take the call |
| Nocna zmiana — zamek za zamkiem | Night Shift — one lock after another |
| Furgonetka — narzędzia, naprawy | The Van — tools, repairs |
| Gablota — co już otwierałeś | Showcase — what you've opened so far |
| To gra, nie kurs. Zamki i narzędzia są wymyślone. | It's a game, not a course. Locks and tools are made up. |
| Co dziś bierzemy? | What are we taking tonight? |
| Grot zaczyna drapać. Za piątaka będzie jak nowy. | The tip's starting to scratch. A fiver and it's good as new. |
| Naprawię — 5 / Biorę jak jest | Fix it — 5 / Take it as is |
| Wycena — przed robotą, na piśmie | Quote — before the job, in writing |
| Rachunek nie wyjdzie wyżej niż 115. Słowo. | The bill won't go over 115. My word. |
| Czy to jej drzwi? | Is this her door? |
| Czuję się pewnie | I feel sure about this |
| Otwieram / Poproszę o coś jeszcze / Odmawiam | I'll open it / I need one more thing / I can't do this one |
| Szpulka. Popuść. | Spool. Ease off. |
| dwie kreski: za głęboko | two notches: too deep |

## 10. Ocena unikalności

| Porównanie | Oni | My |
|---|---|---|
| Minigry z dużych RPG (Skyrim, Fallout, Oblivion, KCD) | dziurka na czerni albo brązowy „lochowy” przekrój o niskim kontraście | jasny, oświetlony przekrój z twardym konturem; kontekst ludzki zamiast lochu |
| Thief Simulator | piny na ciemnym tle, fantazja włamania | noc jako dyżur pogotowia; sąsiedzi, wyceny i weryfikacja w kadrze |
| Museum of Mechanics: Lockpicking | białe „muzeum” | ciepła ulica i klatka schodowa, technika graficzna zamiast galerii |
| Lockpick 101 / Lock Pick 3D | generyczne 3D, chrom, złoto | 2D graficzne, płaskie farby, materiał w nacięciu |
| **Unlokee** | niebieski blueprint, drewniany blat, kursywa „handwritten” | żadnego niebieskiego; linoryt zamiast rysunku technicznego. Dwa kciuki są wspólne (to wymóg ergonomii), ale nasz HUD siedzi w świecie (wycieraczka, futryna, czoło rdzenia) |
| **Shear Line** | granat, świecące złote piny, heist | żółć jest światłem otoczenia, piny są matowe (stal w rastrze, mosiądz w papierze), zero poświaty |
| **Key Master** | skeuomorficzny brąz, drewno, paragony | inna technika (odbitka zamiast skeuomorfizmu), noc i miasto zamiast lady warsztatu. Papierowe kartki są u nas wyraźnie risograficzne (poszarpane, płaskie) |

Najmocniejsze wyróżniki: (1) uzasadniona fabularnie paleta jednobarwna, (2) „światło = to, co wycięte”, (3) wordmark przecięty linią podziału, (4) jasna ikona z uchylonymi drzwiami w morzu ciemnych kłódek. Ryzyko zbieżności: drzwi w ikonie kojarzą się też z grami „escape room”. Łagodzimy to klinem światła i progiem z linii podziału. W razie potrzeby wariant B: sam monogram „L” z cięciem.

## 11. Ryzyka i koszt produkcji

| Ryzyko | Ograniczenie |
|---|---|
| **Koszt ilustracji ręcznej przy latach rozbudowy** (nowe dzielnice, klienci, rodziny zamków) | Styl jest **modułowy z natury linorytu**: płaskie plamy z 3 farb + kontur, więc rysuje się go w wektorze z biblioteki „klocków”: fasady (5–6 typów okien, gzymsów, bram), postacie z wymiennych części (głowa, fryzura/wałki/czapka, korpus z 6 wzorami szlafroków i kurtek, kapcie/buty), rekwizyty. Faktury (słoje, nacięcia, ziarno, echo) są **proceduralne** (shader/SVG filter), nie malowane. Nowy klient = kompozycja z części + 1 unikalny detal. |
| Czytelność faktur na małych ekranach | skala nacięć ≥ 3 dp, faktura nigdy w paśmie ±6 dp od linii podziału, ziarno ≤ 0,22 krycia |
| Monotonia (wszystko żółto-czarne) | dzielnice różnią się **źródłem światła**, a nie paletą: na Kampusie rtęciowe lampy (sam papier i atrament, bez żółci), neon zakazany, więc Nocny Rynek dostaje cegłę witryn. Dzień (rzadkie zlecenia) = negatyw: papier jako tło, atrament jako rysunek |
| `feDisplacementMap`/`feTurbulence` w czasie rzeczywistym na tanim Androidzie | w grze faktury i falowanie bake'ujemy do atlasów (statyczne). W runtime zostaje tylko płaski mesh + kontur |
| Postacie mogą zjechać w infantylność | zasada: twarz = 3 kreski, emocję niesie postawa i rekwizyt; ilustrator prowadzi arkusz typów |
| Drzwi w ikonie ≈ escape room | wariant B (monogram z cięciem) do testu A/B na stronie sklepu |

## 12. Lista PNG

`mockups/sodowa/png/` (każdy ekran: `portrait` 412×915 @2x, `landscape` 915×412 @2x, `portrait.gray`, `portrait.dim`):

- `01-lock.*`: zamek w trakcie, stany a–e, wytrych pod c (zgięcie, rysy, zadziory), napinacz ze skalą w drzwiach, czoło rdzenia, wycieraczka z 3 wytrychami (jeden brak), kreski postępu, strefy kciuków (poziom: kciuki po bokach)
- `02-workshop.*`: tablica narzędzi w furgonetce (8 sylwetek z TOOLS.md, malowane cienie 5S, ceny, „brakuje 188”, 2 narzędzia zablokowane jako same cienie), panel naprawy z powiększeniem zadziorów
- `03-job.*`: „Rosół na gazie”, klatka III piętra (Halina, Zosia, okno sodowe), licznik rosołu, wycena nocna (60 × 1,5 + 15 = 105, rabat sąsiedzki 85), dowody (sąsiadka, list, mObywatel), poziomica pewności, sprawdzenie po otwarciu, 3 decyzje
- `04-menu.*`: ulica nocą z wordmarkiem, latarnią, furgonetką i oknami klientów, przyciski w zasięgu kciuka
- `05-brand.*`: wordmark w 4 rozmiarach (noc i papier), ikona 112/64/48/29 + szarość, język ikon UI, siatka sklepu (`shared/store-grid.js`)
