# T06 — Krytyka wizualna Lockwright

**Data:** 2026-11-05  
**Rola:** niezależny art direction / visual quality gate  
**Podstawa dokumentacyjna:** CLAUDE.md, docs/styles/realizm.md, docs/DESIGN.md, docs/HUD.md  
**Punkt odniesienia dla materiałów:** [commit 1deaa0006337efc7bdcaf16e0716b15c4d297cb3](https://github.com/woogitsugames/lockwright/tree/1deaa0006337efc7bdcaf16e0716b15c4d297cb3). Repozytorium jest równolegle zmieniane; ocena dotyczy widocznych wersji, nie hipotetycznego przyszłego buildu.

## 1. Werdykt: czy wygląda jak gra za miliony?

**Nie. W tej chwili wygląda jak obiecujący prototyp o wyrazistej idei, ale nie jak ukończona, wysokobudżetowa produkcja fotorealistyczna.** Najsilniejsza jest opowieść miejsca (kamienica, dyżur, rzemieślniczy warsztat). Najsłabszy jest absolutny punkt centralny produktu: przekrój zamka. To często dobrze wymodelowana *demonstracja CAD z renderem studyjnym*, nie sfotografowany przedmiot w realnym świetle. Odbiór psują także zbyt jednorodne sprężyny i faktury, lustrzane odbicia metalu, martwa czerń wokół powiększeń oraz etykiety i przyciski, które wyglądają na doklejone w przeglądarce.

**To nie dowód wykorzystania generatorów obrazów.** Określenie „AI slop” opisuje tu *ryzyko percepcji*: powtarzalność, bezosobowy połysk, oderwane teksty i brak śladów użytkowania, niezależnie od faktycznego narzędzia produkcji.

**Subiektywna ocena pojedynczych kadrów, nie grywalności:** oprawa klatki 5/10; warsztat 4/10; główny mechanizm 3/10; wiarygodność materiałów 3/10; zgodność bieżących makiet z docelowym HUD 4/10. Nie oceniam animacji, dźwięku ani haptyki na podstawie statycznych plików.

### Granica audytu — ważna

Przeprowadzono inwentaryzację wszystkich trzech wskazanych folderów. W stanie repozytorium z początku audytu jest **40 obrazów makiet**, **8 zrzutów z Godota** i **11 obrazów renderów** (łącznie 59); podczas pracy na main doszedł także art/renders/stairwell.png, więc aktualna lista obejmuje **60 obrazów**. Bezpośredni podgląd był możliwy dla **39 obrazów**: 36 wariantów makiet (10 poziomych, 10 szarych, 10 przyciemnionych i 6 kolorowych pionowych), dwóch zrzutów silnika oraz art/renders/section.jpg. Pozostałe pliki są zinwentaryzowane, ale połączenie GitHub zwracało pustą zawartość dla części większych obrazów, a bezpośrednie pobranie binarne nie było dostępne. **Nie przedstawiam diagnoz pikselowych dla nieobejrzanych renderów.**

Niedostępne bezpośrednio do oglądu, choć analogiczne kadry i ich warianty zostały ocenione:
- Makiety (4 pionowe pełnokolorowe): mockups/realizm/png/01-lock.portrait.png, 05-chalk.portrait.png, 06-tutorial-s1.portrait.png, 07-tutorial-s2.portrait.png. Dla wszystkich obejrzano landscape, gray i dim.
- Zrzuty Godota (6): game/scenes/photoreal/shots/compare_cycles_vs_godot.png, landscape_play.png, portrait_play.dim.png, portrait_play.png, portrait_reference_pose.png, portrait_tension_max.png.
- Renderery (stan początkowy, 10 pozostałych): art/renders/lever.png, loupe.png, microscope_view.png, section.png, section_v1.png, section_v2.png, tray.png, wafer.png, warded.png, wooden_pin.png. Dodatkowo dodany w toku prac art/renders/stairwell.png pozostawał nieobejrzany. Pliki JSON nie są obrazami.

To ogranicza przede wszystkim ocenę **różnicy Cycles–Godot** i **pozostałych rodzin mechanizmów**. Nie należy uznawać tej części zlecenia za zamknięty pełny visual QA wszystkich rodzin.

## 2. Co naprawdę działa

1. **Kontekst legalnej pomocy jest mocny.** [03-job.portrait.png](../../../mockups/realizm/png/03-job.portrait.png) pokazuje zwykłe drzwi, numer, lamperię i kartę dyżuru. To życie mieszkańców, a nie romantyzowanie włamania. Zatrzymać ten kierunek.
2. **Ciepła żarówka i chłodniejsze otoczenie budują narrację**, szczególnie na [03-job.landscape.png](../../../mockups/realizm/png/03-job.landscape.png). Nie potrzeba dekoracyjnych gradientów ani neonów.
3. **Warsztat jako mapa interakcji przez realne przedmioty** jest znacznie ciekawszy niż siatka przycisków. [04-workshop.portrait.png](../../../mockups/realizm/png/04-workshop.portrait.png) ma imadło, kartki, gablotę i telefon; to właściwy fundament.
4. **Przekrój jest mechanicznie zrozumiały jako obiekt.** [section.jpg](../../../art/renders/section.jpg) pozwala intuicyjnie odróżnić sprężyny, ruchome elementy, korpus i narzędzie. Problemem jest wykończenie, nie samo istnienie przekroju.
5. **Rozdzielenie skali szarości i przyciemnienia** jest dobrym nawykiem kontroli jakości. To narzędzie diagnostyczne, nie dowód, że wszystkie stany już przechodzą test A7.
6. **Kartka zamiast okna systemowego** w samouczku daje się obronić; [06-tutorial-s1.landscape.png](../../../mockups/realizm/png/06-tutorial-s1.landscape.png) ma zwięzły, wyważony ton. Trzeba jednak fizycznie osadzić kartkę w świecie.

## 3. Krytyka konkretnych plików

| Plik / obszar kadru | Diagnoza i dlaczego wygląda tanio |
|---|---|
| [art/renders/section.jpg](../../../art/renders/section.jpg), płaszczyzny cięcia, pięć komór | Geometrycznie idealne równoległe ściany, długie pasy światła i niemal identyczne sprężyny. Obrabiany metal przypomina wypełniony shaderem plastik i części ekspozycyjnego modelu CAD. Brak subtelnych różnic mikronierówności i śladów montażu. |
| [01-lock.landscape.png](../../../mockups/realizm/png/01-lock.landscape.png), całe centrum | Wystylizowany połysk cylindrów, idealnie gładkie wytrychy i regularna „tapeta” słojów za przekrojem. Szerokie czarne skrzydła w poziomie są puste; biały symbol pauzy „II” przeczy HUD.md §6. |
| [01-lock.portrait.gray.png](../../../mockups/realizm/png/01-lock.portrait.gray.png), linia podziału | W szarości widać mechanizm, lecz pięć podobnych połysków, pięć podobnych sprężyn i drobne szczeliny konkurują o uwagę. Na nieruchomym obrazie nie widać dostatecznie wyraźnego kodu: która komora naprawdę wiąże i czym różni się od poprawnie ustawionej. Test dynamiczny nadal wymagany. |
| [game/scenes/photoreal/shots/portrait_play.gray.png](../../../game/scenes/photoreal/shots/portrait_play.gray.png), dół ekranu | Jest lepsza ciągłość sceny niż w mockupie poziomym, ale dolna zwijka wygląda jak jednolita płyta z powtarzalnym ściegiem; puste kieszenie i kształty narzędzi są zbyt podobne. Wzrok wraca do seryjnych sprężyn, nie do punktu oporu. |
| [game/scenes/photoreal/shots/portrait_dark.png](../../../game/scenes/photoreal/shots/portrait_dark.png), cały kadr | **Błąd zgodności P0:** mechanizm, napinacz i fragment tła nadal są słabo widoczne. HUD.md §10 wymaga czerni OLED i jedynie reliefu pauzy oraz opcjonalnego odcisku dotyku. Obecny kadr jest „bardzo ciemny”, nie „w ciemności”. |
| [02-loupe.portrait.png](../../../mockups/realizm/png/02-loupe.portrait.png), okrąg i dolny podpis | Lupa wygląda jak perfekcyjnie wycięte koło z katalogu produktu na absolutnej czerni, bez fizycznej wskazówki, że gracz patrzy przez szkło. Chromopodobne refleksy zlewają mikrokrawędź. Podpis szeryfowy na dole jest niemal osobnym UI. |
| [03-microscope.portrait.png](../../../mockups/realizm/png/03-microscope.portrait.png), prawa komora | Lustrzany czarny metal i jasny „refleks w kształcie oka” wyglądają syntetycznie. Podziałka pod obrazem nie jest przekonująco związana z mechaniczną szyną stolika. Długie czarne pole między narzędziem a zdaniem marnuje kompozycję. |
| [04-borescope.portrait.png](../../../mockups/realizm/png/04-borescope.portrait.png), obraz wnętrza | Jednolity bursztynowo-złoty kolor, symetryczne hotspoty i bardzo wygładzony detal dają efekt renderu dekoracyjnego, nie małej kamery w ciasnym kanale. Odbicia dominują nad informacją, która część mechanizmu się porusza. |
| [03-job.portrait.png](../../../mockups/realizm/png/03-job.portrait.png), drzwi i karta zlecenia | Wiarygodny układ klatki, ale drzewny rysunek obu płycin jest zbyt równy, ściana sterylna, żarówka za mocno wypalona. Prostokąty „Pytam o dokumenty / Odmawiam” przypominają przyciski formularza; dolna część podkładki ma zbyt dużo pustego, gładkiego drewna. Ocena kolorowego kadru dotyczy wersji z bazowego commita; na main plik zmieniono w czasie audytu. |
| [04-workshop.portrait.png](../../../mockups/realizm/png/04-workshop.portrait.png), blat i tablica | Wiarygodny plan warsztatu, ale przedmioty stoją z katalogową regularnością, a powierzchnie nie pokazują miejsc pracy. Maszyna w prawym dolnym polu ma uproszczone, zabawkowe płaszczyzny. Duża, ciemna tablica perforowana jest martwą strefą, podczas gdy drobny tekst na kartkach trudno dostrzec. |
| [05-workshop-optics.portrait.png](../../../mockups/realizm/png/05-workshop-optics.portrait.png), metki | Papierowe etykiety mają otwory, lecz wyglądają bardziej jak płaskie nakładki niż metki zaczepione do przedmiotów (brak widocznego mocowania i spójnego cienia kontaktowego). „8ØØ / 1 1ØØ” wizualnie mylą cyfry z literą Ø; obowiązkowy QA glifów ceny i obu języków. |
| [05-chalk.landscape.png](../../../mockups/realizm/png/05-chalk.landscape.png), znaki nad pinami | Kontrast jest lepszy, ale kontury kredy przypominają kreskowanie w zewnętrznym programie. Część znaków wisi nad materiałem bez kontaktu, grubość i przestrzenne osadzenie linii są niestałe. Symbol ma opisywać stan, nie stać się drugim „HUD-em”. |
| [06-tutorial-s1.portrait.gray.png](../../../mockups/realizm/png/06-tutorial-s1.portrait.gray.png), kartka w dolnej połowie | Notatka jest za bardzo „planszą szkoleniową”: ciemne ramki, graficzny stempel, brak wyraźnego mocowania do zwijki. Duży komunikat ostrzegawczy konkuruje z pierwszym ruchem kciuka. |
| [07-tutorial-s2.landscape.png](../../../mockups/realizm/png/07-tutorial-s2.landscape.png), prawa strona | Kartka jest zawieszona w czarnej przestrzeni bez czytelnego podłoża. Mamy dobrą treść, ale ułożoną jak slide prezentacji. W poziomie wizualnie rozszczepia środek uwagi: mechanizm kontra napis. |
| [02-loupe.portrait.dim.png](../../../mockups/realizm/png/02-loupe.portrait.dim.png) i [03-microscope.portrait.dim.png](../../../mockups/realizm/png/03-microscope.portrait.dim.png), podpisy | Przy 50% jasności kursywne zdania i najdrobniejsze krawędzie prawie giną. Jeśli tekst ma pozostać włączony w samouczku, musi być czytelny jako fizyczny nośnik; poza nim powinien zniknąć zgodnie z HUD.md §4.1. |
| [04-workshop.portrait.dim.png](../../../mockups/realizm/png/04-workshop.portrait.dim.png), etykiety i telefon | Test przyciemnienia ujawnia, że hierarchia informacji opiera się na najjaśniejszych kartkach, podczas gdy detale warsztatu są niewidoczne. Trzeba poprawić lokalne światło i wielkość pism, nie rozjaśniać wszystkiego globalnie. |

### Rozbieżności specyfikacja ↔ widoczny materiał

- **HUD.md §6 i §13:** pauza jako skórzana klapka z napą, nie „II” lub samotny „X”. Występuje na makietach 01-lock, 02-loupe, 03-microscope.
- **HUD.md §10:** w ciemności ukryte są wszystkie elementy zamka i narzędzia. portrait_dark.png temu przeczy; to błąd projektowy, nie kwestia gustu.
- **HUD.md §1 i §4.1:** w zamku bez tekstów i paneli, poza uzasadnionymi wyjątkami samouczka. Dopiski pod okularami nie powinny być obecne w zwykłej rozgrywce.
- **docs/styles/realizm.md:** satynowy metal, roughness ≥ 0,16, brak chromu i poświaty; section.jpg i zbliżenia narzędzi ujawniają optycznie zbyt „lustrzane” strefy.
- **DESIGN.md §1:** rozpoznawalność stanów przez geometrię, ruch, dźwięk i haptykę. Z obrazów da się ocenić czytelność statycznych sylwetek, **nie** można potwierdzić reakcji ruchowej, dźwięku ani haptyki.
- **CLAUDE.md / HUD.md:** wymagane PL i EN. W widocznych przykładach są polskie napisy, ale zrzuty nie dowodzą kompletnego angielskiego wariantu ani poprawnego skalowania obu wersji.

## 4. Piętnaście poprawek według opłacalności

Kolejność oznacza **oczekiwany przyrost jakości / koszt zmiany**, z pierwszeństwem dla błędów dyskwalifikujących. Pracochłonność jest szacunkowa: S = mała, M = średnia, L = duża. To rekomendacje dla innych właścicieli katalogów; **T06 nie zmienia ich plików**.

| # | Poprawka i nakład | Uzasadnienie / konkret | Warunek odbioru |
|---|---|---|---|
| **1** | **Naprawić prawdziwą ciemność** (S, P0) | portrait_dark.png. Zamiast przygaszać scenę, wyłączyć jej renderowanie w tym trybie; nie tworzyć taktycznej przewagi z widocznych pinów. | Poza dopuszczonym reliefem napy i opcjonalnym odciskiem dotyku kadr ma RGB 0/0/0; żadne krawędzie zamka ani narzędzia nie są widoczne. |
| **2** | **Zastąpić „II” i „X” rzeczywistą klapką skórzaną** (S–M, P0) | 01-lock.landscape.png i 02-loupe.portrait.png. Pojedyncza napa jest unikatowym znakiem produktu, ikony systemowe są tanie. | Jedno fizyczne zamknięcie, cel ≥ 48 dp / 44 pt, obsługa pion/poziom i safe-area; bez unoszących się ikon. |
| **3** | **Przestawić metal z lustrzanego na narzędziowy** (S–M) | section.jpg, 02-loupe, 03-microscope. Światło musi rozróżnić satynowy nikiel, toczenie mosiądzu i stal sprężynową. | Roughness nie niższa niż 0,16, anizotropia zgodna z obróbką, brak chromowych białych pasów, brak bloomu. Podgląd przy naturalnej ekspozycji i w szarości. |
| **4** | **Zróżnicować płaszczyzny cięcia i krawędzie** (M) | section.jpg. Obecne ściany są jednakowo gładkie jak bryły CAD. Subtelne ślady frezu powinny istnieć tylko tam, gdzie powstają w procesie, a szczelina nie może świecić. | Widoczny kierunek obróbki i lokalne zmatowienia faz; ciemna szczelina ≥ 2 dp bez jasnego paska przecinającego linię podziału. |
| **5** | **Pokazać różnice stanów geometrią, nie shaderem** (M, P0 dla UX) | 01-lock.gray i portrait_play.gray. Zwłaszcza binding / near_shear / set / false set / overset wymagają oddzielnych sylwetek. | Zestaw sześciu sparowanych kadrów z tej samej kamery; poprawne wskazanie stanu przez testerów w szarości i przy 50% jasności. Ruch/dźwięk/haptyka w osobnym QA. |
| **6** | **Wykonać relighting pod tani ekran telefonu** (M) | 01-lock.dim, 02-loupe.dim i warsztat.dim. Nie rozjaśniać całej sceny: pracować odbiciem i lokalnym światłem krawędziowym na elementach funkcyjnych. | Kontrast metal–tło ≥ 3:1, w pressecie pomocy ≥ 4,5:1; wymagana czytelność na 412×915 dp i po obniżeniu jasności. |
| **7** | **Zbudować jedną logiczną kompozycję pion/poziom** (M) | 01-lock.landscape, tutorial S1/S2, widoki optyki. Puste czarne skrzydła i „wyspy” informacji przypominają układ z prototypu webowego. | Pion jako master; w poziomie strefy kciuków po bokach, mechanizm i skórzana zwijka wizualnie połączone, brak pływających kartek. |
| **8** | **Nadać okularom fizyczne cechy optyczne** (M) | 02-loupe, 03-microscope i 04-borescope. Zamiast idealnego koła na czerni: subtelna krawędź szkła, poprawny winiet i kontrast zależny od źródła światła. | Lupa, mikroskop i wziernik wyraźnie odróżnialne *optycznie*, bez dekoracyjnej poświaty; widoczna szczelina jest czytelna. |
| **9** | **Dodać lokalne ślady użytkowania, nie losowy brud** (M) | 03-job i 04-workshop. Zabrudzenia powinny skupiać się wokół kontaktów dłoni, progów, imadła i krawędzi przedmiotów. | Kontrolowana mapa zużycia: przetarcia przy klamce, skóra na uchwytach, drobne opiłki przy narzędziach; żadnej powtarzalnej faktury „stockowej”. |
| **10** | **Osadzić kartki i akcje fizycznie** (S–M) | 03-job oraz S1/S2. Treść jest dobra, ale przyciski i notatki mają grafikę płaskiej nakładki. | Kartka/klips/ręka/cień kontaktowy tworzą wspólną perspektywę; pola dotyku istnieją na papierze, nie w powietrzu. Tekst PL/EN nie wychodzi poza papier. |
| **11** | **Przerobić skórzaną zwijkę i sylwetki wytrychów** (M) | portrait_play.gray i 01-lock.gray. Skóra nie może wyglądać jak powtarzalny panel tekstury; kieszenie muszą komunikować liczbę narzędzi bez ikonek. | Każda kieszeń ma cień, zagięcie, ślad nacisku i czytelny kontur; pełna i pusta dają jednoznaczną różnicę w szarości. |
| **12** | **Zreżyserować warsztat jak miejsce pracy** (M) | 04-workshop i 05-workshop-optics. Uporządkować punkt skupienia, zróżnicować kąty małych obiektów i powiązać metki z narzędziami. | Ścieżka wzroku: narzędzie → dotykalna metka → następna czynność; mniej „rozstawionych modeli”, więcej śladów realnej pracy, bez chaosu. |
| **13** | **Urealnić kredę i uprościć jej semantykę** (S–M) | 05-chalk.landscape.png. Kreda powinna być przyczepiona do powierzchni i nie udawać kolejnej warstwy HUD. | Kreska o nierównej grubości ≥ 2 dp, spójna perspektywa, kontrast ≥ 4,5:1 w trybie pomocy; brak znaków podających rozwiązanie. |
| **14** | **Zrobić jeden audyt typografii PL/EN** (S–M) | 05-workshop-optics, 03-job, 02-loupe.dim. Unikać dekoracyjnej kursywy i błędnie rozpoznawanych glifów cen. | Bona Nova + Atkinson Hyperlegible Next zgodnie ze spec.; tekst użytkowy ≥ 17 sp tam, gdzie dotyczy; prawidłowe 0/O/Ø, diakrytyki, łamanie w obu językach, cele ≥ 48 dp. |
| **15** | **Wprowadzić bramkę jakości renderu Cycles → Godot** (L, konieczne przed sklepem) | compare_cycles_vs_godot.png oraz rodziny w art/renders. Sam elegancki Cycles nie dowodzi fotorealizmu w rendererze Mobile. | Identyczny kadr, światło, ekspozycja i dwa urządzenia docelowe; porównania A/B materiałów, stanów, tekstu; 60 FPS na docelowym tanim Androidzie jako cel wydajnościowy. |

**Najszybszy pakiet o dużym efekcie:** #1, #2, #3, #6 i #10. Następnie #5 jest warunkiem, aby gra *działała wizualnie*, a nie tylko atrakcyjnie wyglądała. #15 jest kosztowny, ale stanowi warunek uczciwego marketingu „fotorealizmu” i screenshotów sklepowych.

## 5. Trzy autorskie referencje stylu (bez kopiowania gier)

1. **Fotografia dokumentalna korytarza o siódmej rano.** Kamera na wysokości człowieka, piony proste, wyblakła zielona lamperia, ślad palca na włączniku minutnika, jedna ciepła żarówka, chłodna refleksja z okna. Kolor należy do realnych materiałów, nie do gradingu reklamowego. Klient potrzebuje pomocy, nic nie sugeruje przestępstwa.
2. **Makrofotografia obróbki metalu w używanym warsztacie.** Miękkie, boczne światło prześlizguje się po satynowym frezowaniu. Ciemna linia podziału jest *brakiem światła*. Mosiądz nosi kontaktowe ślady, stal ma własny charakter, a mały ruch jednego elementu jest bardziej dramatyczny niż złoty błysk pięciu.
3. **Spokojny stół rzemieślnika po długim dyżurze.** Bukowy blat, skórzana zwijka z odciśniętymi narzędziami, rachunek z kalką, przetarta metalowa napa, ołówek i telefon dyspozytorni. Osobowość sceny wynika z organizacji pracy, nie z ozdobnych ikon, plakatów czy sztucznego vintage.

## 6. Decyzje i następne kroki

**Zachować:** kierunek realistyczny, zwyczajne ludzkie historie, ciepłą klatkę, warsztat jako fizyczne menu i mechanikę opartą na odczuwaniu. **Nie zatwierdzać jeszcze** obecnego przekroju ani obecnego wyglądu trybu ciemności jako finalnego materiału promocyjnego.

**Bramki akceptacji proponowane art directorowi:**

- **A — hero shot:** jeden docelowy pionowy screenshot zamka z prawdziwym materiałem, zrozumiałą linią podziału, narzędziem i zwijką. Test na telefonie, nie tylko na monitorze.
- **B — mechanika bez barw:** na tych samych współrzędnych kamery zebrać stany: binding, near_shear, set, false_set, overset, stress. Eksport gray + dim; weryfikacja z ludźmi, nie wyłącznie automatem.
- **C — legalność narracji:** każde wejście do zlecenia nadal pokazuje weryfikację prawa do lokalu, bez rekwizytów i stylistyki przestępczej.
- **D — UI fizyczny i lokalizacja:** pauza, kartki, rachunki, metki; wszystkie nowe teksty gracza w PL i EN, cele dotykowe i safe-area zgodne z HUD.md.
- **E — produkcja:** dopiero po ustaleniu hero shotu wykonać porównanie Cycles/Godot i ostateczną kontrolę wydajności oraz kadrów sklepowych.

**Zakres prac T06:** audyt dokumentów i dostępnych obrazów; brak zmian w kodzie, plikach źródłowych i zasobach innych zespołów. Nie tworzono paintoverów, bo bez pełnego podglądu dużych plików łatwo byłoby przedstawić manipulację jako wierną korektę istniejącego renderu. Nie przeprowadzono testów na urządzeniu, porównania ruchu, audio/haptyki ani oglądu wszystkich renderów; te nieukończone czynności są jawnie opisane powyżej.

## 7. Pliki tego zlecenia

| Plik | Zawartość |
|---|---|
| README.md | Pełny raport art direction: werdykt, granice materiału, mocne strony, krytyka konkretnych kadrów, 15 poprawek, 3 referencje i bramki akceptacji. |
| ASSETS.md | Manifest: w T06 nie dodano nowych grafik, dźwięków ani innych zasobów binarnych. |
