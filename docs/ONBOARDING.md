# Onboarding — pierwsze uruchomienie i samouczek bez tekstu

Status: projekt poziomów i doświadczenia gracza, 2026-11-04. Powiązane: `DESIGN.md` (kod stanów, A1/A2/A9), `LEVELS.md` (parametry zamków samouczka), `HUD.md` (scena jako interfejs), `TECH.md` §2.3 i §3 (kalibracja, język haptyki i dźwięku), `PROGRESSION.md` §1 (wzór S1–S3), decyzje D-12, D-13, D-21–D-25.

Spis treści
1. Zasady samouczka
2. Słownik wskazówek bez tekstu i eskalacja po 15 s
3. Pierwsze uruchomienie (język, kalibracja haptyki, notka „to gra, nie kurs”)
4. Wkładka bębenkowa S1–S3: storyboard
5. Pierwszy prawdziwy zamek (zamek testu A1)
6. Lupa (D-13)
7. Tryb „w ciemności”
8. Wkładka płytkowa S1–S3 (druga rodzina)
9. Lekcje wtrącone: szpulka, falownik, mikroskop, wziernik
10. Wzór samouczka dla każdej rodziny
11. Dostępność samouczka (A9)
12. Plan testu A1 i A2
13. Dane i i18n

---

## 1. Zasady samouczka

1. **Zero tekstu w zamku.** Gracz uczy się z obrazu, ruchu, dźwięku i haptyki. Jedyne dodatkowe środki to **odcisk kciuka** (miękkie wgłębienie w skórze zwijki, `HUD.md` §5) oraz **kreda**: znaki kodu stanów z `DESIGN.md` §1, rysowane jak kredą ślusarza na metalu, a przy wskazówkach gestu **kredowy pierścień dotyku i ślad ruchu** (D-83: bez widma dłoni).
2. **Jedno nowe pojęcie na krok.** Krok kończy się zdarzeniem logiki (`bind`, `set`, `open` …), a nie upływem czasu ani dotknięciem „dalej”.
3. **Sukces zawsze ma oddech.** Po każdym przejściu kroku scena trzyma stan 600 ms (bez nowych bodźców), żeby gracz połączył przyczynę i skutek.
4. **Nie da się utknąć.** Każdy krok ma eskalację wskazówek (§2), a ostatni stopień to demonstracja „ręką mistrza”. W samouczku nic nie ginie: złamany wytrych wraca do zwijki, a seria się nie zaczyna.
5. **Kara jest informacją.** Zrzut, przepchnięcie i ugięcie wytrycha pokazujemy wyraźnie i spokojnie, bez czerwieni i bez trzęsienia kamerą.
6. **Samouczek to wkładka ćwiczebna w imadle warsztatu.** Prawdziwe wkładki ćwiczebne mają wycięty przekrój, więc fotorealistyczny przekrój jest tu uzasadniony fabularnie. Drzwi i klient pojawiają się dopiero w pierwszym prawdziwym zamku (§5).
7. **Czas.** Cel dla nowicjusza to S1–S3 pinowej w medianie ≤ 3 min, a S1–S3 każdej kolejnej rodziny ≤ 2 min (zmiana względem `PROGRESSION.md` §1, patrz tam „Zmiany po ONBOARDING/LEVELS”).
8. **Kreda maleje.** S1: pełna kreda (linia podziału, kreski tarcia, klin, strzałka obrotu na czole rdzenia). S2: kreda tylko na linii podziału i klamra przy overset. S3: kreda tylko jako stopień H3 eskalacji. Zamek testu A1 nie ma kredy (D-23). Opcja „Pomoc w czytaniu” (`HUD.md` §9) przywraca pełną kredę wszędzie.
9. **Pomijanie.** Pierwsze przejście jest obowiązkowe. Przy powtórce (nowy profil, nowe urządzenie) S1–S3 można pominąć, przytrzymując klapkę zwijki 1 s (gest z `HUD.md` §6, bez napisu „Pomiń”).

## 2. Słownik wskazówek bez tekstu i eskalacja po 15 s

### 2.1 Stopnie (D-23)

> **D-83 (2026-11-07):** widmo dłoni (G23, D-76/D-77) usunięte. Gdzie storyboardy niżej (§3–§9) mówią „widmo kciuka / dłoni”, chodzi o kredę gestu z §2.2 (pierścień dotyku + ślad ruchu); „ręka mistrza” to gra poruszająca samym narzędziem, z kredą idącą za wirtualnym punktem dotyku.

Licznik „utknięcia” liczy czas od ostatniego **postępu** w bieżącym kroku. Postęp to zdarzenie, które przybliża do celu kroku (np. `bind` w kroku napięcia, `near_shear` lub `set` w kroku unoszenia). Licznik zeruje się po postępie, a nie po samym dotyku ekranu, więc machanie kciukiem nie wstrzymuje pomocy.

| Stopień | Od | Co się dzieje | Kanały |
|---|---|---|---|
| **H0** | 0 s | Nic. Gracz próbuje. | — |
| **H1 — trącenie** | 15 s | Element, którego dotyczy krok, robi jeden mały ruch fizyczny (np. wiążący kołek drga o 1 dp, napinacz kołysze się o 1°). W skórze zwijki pojawia się **odcisk kciuka** tam, gdzie trzeba położyć palec. | obraz + cichy dźwięk tego elementu (−12 dB względem gry). Bez haptyki, żeby nie mylić jej ze stanem zamka. |
| **H2 — kreda gestu** | 30 s | Kredowy pierścień dotyku dwa razy przechodzi drogę gestu, a za nim rysuje się kredą ślad ruchu: skąd, dokąd i jak szybko (D-83; bez dłoni). Po każdym przejściu ślad gaśnie. Scena **odpowiada** na gest (napinacz się obraca), a potem wraca do stanu gracza. | obraz + dźwięk sceny ściszony o 6 dB |
| **H3 — kreda** | 45 s | Kreda rysuje znak, którego brakuje w zrozumieniu: kreski tarcia przy wiążącym kołku, klin szczeliny, klamrę nad przepchniętym, strzałkę „w dół” przy napinaczu (za mocno) albo „w górę” (za słabo). Znak zostaje do końca kroku. | obraz + szelest kredy |
| **H4 — ręka mistrza** | 60 s | Gra sama wykonuje cały krok w zwolnionym tempie: rusza się samo narzędzie (wytrych, napinacz, tarcza, kółko), a zamek naprawdę wykonuje krok (np. kołek się ustawia). Dłoni nie rysujemy: kredowy pierścień i ślad idą za wirtualnym punktem dotyku (D-83). Potem kreda gaśnie, a sterowanie wraca do gracza w stanie po kroku. | wszystkie kanały, z haptyką |

Zasady:
- H4 jest wykonywane najwyżej raz na krok. Telemetria samouczka zapisuje każdy stopień (§12), bo test A1 liczy „otwarcie bez H4” osobno.
- W kroku, w którym gracz **robi coś przeciwnego** (np. trzyma napięcie za mocno, aż kołek „nie idzie”), H1–H3 wskazują na ten błąd, a nie na ogólny gest. Diagnoza błędu jest w każdym kroku storyboardu, w kolumnie „Utknięcie”.
- W trybie „w ciemności” H1–H3 grają tylko dźwiękiem i haptyką (np. H2: cichy „wzorzec widmowy” napięcia odtwarzany w lewej części ekranu), a H4 zapala na chwilę światło (minutnik, §7).
- Przy włączonym VoiceOver/TalkBack wskazówki H2–H4 mają też krótki opis głosowy (§11).

### 2.2 Wygląd kredy gestu (D-83, zastępuje widmo dłoni z D-76/D-77)

- **Tylko kreda**, ta sama co w liniach lekcji i znakach stanu (`ChalkLayer`: kreska z kilku przejść, krój Caveat w napisach, wspólny materiał „ziarna” — alfa łamana stałą fakturą powierzchni, więc kreska ma suchą, poszarpaną krawędź prawdziwej kredy). Bez czystych linii wektorowych, bez poświaty, bez koloru, bez dłoni i sylwetek. Pod kreską gestu cienki ciemny podcień (jak pod pismem), żeby trzymała się na jasnym mosiądzu (kontrast, nie poświata).
- **Pierścień dotyku**: odręczne kółko kredą, 48 dp średnicy (rozmiar celu dotyku), w miejscu, gdzie gracz kładzie palec. Przy przytrzymaniu (gest „połóż i trzymaj”) w środku pojawia się drugie, mniejsze kółko.
- **Ślad ruchu**: kredowa linia rysuje się za pierścieniem w tempie gestu (to tempo jest częścią lekcji: napięcie 0→0,3 w 0,6 s, uniesienie 0,2/s), starsza część śladu jest jaśniejsza, ślad kończy się na krawędzi pierścienia. Po przejściu ślad gaśnie (200 ms, out-cubic, bez odbicia). Pojawienie 200 ms.
- **H4**: gra porusza narzędzie (autopilot steruje wejściem zamka), a pierścień i ślad idą za wirtualnym punktem dotyku: napięcie i uniesienie z prawdziwej wartości wejścia (200 dp drogi kciuka na jednostkę), gesty „tempem” (obrót tarczy, kółko, cofnięcie) po zaplanowanej drodze w czasie gestu.
- **Gdzie**: tam, gdzie gracz naprawdę kładzie palec — kotwice kciuków (`thumb_anchors()`), lewy kciuk w lewej strefie, prawy nad kolumną elementu. Wszystko mieści się w strefie bezpiecznej (N-73: prawy kciuk wystawał za krawędź): kotwice i każdy punkt kredy są przycinane do safe area, a cała droga gestu przesuwa się, jeśli wchodziłaby na napinacz, przekrój zamka albo (H4) lupę. Strefy kciuków to całe połówki ekranu, więc przesunięty gest dalej działa.
- **Ograniczenie ruchu**: kreda statyczna — cała droga od razu, grot na końcu, pierścień na starcie; nic się nie przesuwa (także w H4, gdzie narzędzie i tak rusza się, bo to stan zamka).
- Leworęczni (opcja „zamień kciuki”, `HUD.md` §9) widzą kredę gestu w lustrzanym odbiciu.
- W trybie „w ciemności” kredy nie ma (H1–H3 tylko dźwięk i haptyka); w H4 pojawia się na czas zapalonego światła.

## 3. Pierwsze uruchomienie

Cel: od dotknięcia ikony do pierwszego dotyku zamka ≤ 25 s. Jedyny tekst przed samouczkiem to nazwa języka, jedno pytanie kalibracji i notka „to gra, nie kurs”. Każdy z nich ma też obraz zrozumiały bez czytania.

### 3.0 Zimne otwarcie (0–4 s)

Czarny ekran. Słychać kroki na klatce schodowej i suchy klik minutnika. Zapala się ciepła żarówka, a z ciemności wychodzi blat warsztatu: imadło z wkładką ćwiczebną, zwinięta skórzana zwijka i bloczek zleceń. Bez logo poza tym, czego wymaga platforma (ekran startowy iOS/Androida to ta sama klatka blatu w ciemności, więc przejście jest płynne).

### 3.1 Język (2 s, zwykle bez dotyku)

- Język wybieramy z ustawień systemu: `pl*` → PL, wszystko inne → EN (D-19: fallback EN).
- Na bloczku zleceń leży emaliowana tabliczka z dwiema połówkami **„Polski | English”**. Aktywna połówka jest wciśnięta (głębszy cień), a druga wystaje. Dotknięcie drugiej przełącza język natychmiast, z cichym mosiężnym kliknięciem. Nazwy języków piszemy zawsze w ich własnym języku.
- Tabliczka zostaje na bloczku do końca pierwszej sesji, a potem przenosi się do Ustawień.

### 3.2 Kalibracja haptyki: „Czujesz dwa stuknięcia?” (8–15 s)

Na podstawie `TECH.md` §2.3, krok 1. Na urządzeniach bez haptyki (iPad, H0, A–) krok jest pomijany bez komunikatu.

| Faza | Co widzi | Co czuje / słyszy | Interakcja |
|---|---|---|---|
| Bodziec | Na blacie leży **mosiężna płytka kalibracyjna**, a widmo palca dotyka jej raz. | **Tylko haptyka**: dwa transienty `set` w odstępie 120 ms. Bez dźwięku i bez ruchu obrazu, bo inaczej test mierzyłby wzrok. | — |
| Pytanie | Nad płytką krótki tekst w wybranym języku: **„Czujesz dwa stuknięcia?” / „Feel two taps?”**. Pod spodem trzy mosiężne żetony z wybitymi kropkami: **●●**, **●**, **○**, a pod każdym słowo „dwa / jedno / nic” (EN: „two / one / none”). Kropki niosą znaczenie dla osób, które nie czytają. | — | Dotknięcie żetonu. Dotknięcie płytki powtarza bodziec. |
| Wynik | Żeton zapada się w blat (jak przycisk). | „dwa”: krótkie potwierdzenie haptyczne. | Logika z `TECH.md` §2.3: „dwa” → tier bez zmian; „jedno” → tier niżej, `minTransientGapMs = 150` i powtórka z odstępem 200 ms; „nic” → A0, a jeśli i to nie, haptyka wyłączona. Gra mówi wtedy jednym zdaniem: „Dobrze. Będzie słychać i widać.” / „Fine. You'll hear and see it.” |

- Próg odczuwalności oporu (krok 2 w `TECH.md`) **nie** jest w pierwszym uruchomieniu. Domyślne `continuousFloor` bierzemy z tabeli urządzeń, a test jest w Ustawieniach → Haptyka.
- Rozróżnianie set / false_set (krok 3) jest wbudowane w lekcję szpulki (§9.1).

### 3.3 Notka „to gra, nie kurs” (3 s)

Wymóg z `CLAUDE.md`. Pokazujemy ją jak przedmiot, a nie jak okno dialogowe:

- Na pierwszej kartce bloczka zleceń (to ta sama kartka, na której leży tabliczka języka) ląduje **pieczątka** ślusarza: słychać tępy stuk, czuć jeden średni transient (`gate_align`), a na papierze zostaje odcisk z lekko nierównym tuszem.
- Treść pieczątki (dwa wiersze, Atkinson Hyperlegible Next, ≥ 15 sp):
  - PL: **„To gra, nie kurs. Mechanizmy są wymyślone.”** / drugi wiersz mniejszy: „Ślusarz zawsze sprawdza, czy pomaga właścicielowi.”
  - EN: **„A game, not a course. The mechanisms are invented.”** / „A locksmith always checks they're helping the rightful owner.”
- Kartka zostaje na blacie przez cały samouczek (gracz może ją przeczytać, ale nie musi). Potem trafia do zeszytu w Ustawieniach → O grze, gdzie jest też dłuższa wersja z D-08 (nazwy ogólne, historia tylko w gablocie).
- Bez przycisku „OK”. Kartka nie blokuje gry: zwijka rozwija się obok niej.

### 3.4 Przejście do S1 (2 s)

Zwijka rozwija się z dźwiękiem skóry i brzękiem narzędzi. Kamera zbliża się do imadła (500 ms, `out-cubic`). Pierwszy krok S1 zaczyna się, gdy kamera stanie.

## 4. Wkładka bębenkowa S1–S3: storyboard

Parametry zamków: `LEVELS.md` §2 (`pin.s1`, `pin.s2`, `pin.s3`). Sygnały: `DESIGN.md` §1, `TECH.md` §3.3. W S1–S3 warstwa prezentacji wzmacnia sygnały (`fb_gain`: S1 ×1,5, S2 ×1,3, S3 ×1,15), a w zamku A1 wraca do ×1,0.

Oznaczenia: **L** = lewy kciuk (napięcie), **P** = prawy kciuk (wytrych), **T** = napięcie 0..1.

### S1 — „Jeden kołek” (`pin.s1`, cel 20–40 s)

Uczy: napięcie + unoszenie = ustawienie; ustawienie = obrót rdzenia = otwarcie. Jeden stos, okno 20% skoku, pasmo T 0,15–0,60, `tau_safe` 1,0 (nie da się złamać).

| Krok | Widzi | Słyszy | Czuje | Warunek przejścia | Utknięcie > 15 s |
|---|---|---|---|---|---|
| **1.1 Narzędzia same wchodzą** (2 s, bez gracza) | Widmo dłoni wsuwa napinacz w dół kanału, a haczyk pod kołek. Kołek stoi luźno, sprężyna ma równe zwoje. Kreda: linia podziału jako cienka biała kreska. | metal o metal, cichy | — | koniec animacji | — |
| **1.2 Napięcie** | Odcisk kciuka w lewej części zwijki od razu (wyjątek: w S1 H1 jest od początku). Gdy L dotyka i jedzie w górę, **ramię napinacza obraca się**, a czoło rdzenia drga o ułamek podziałki. Przy T ≥ 0,15 kołek **przesuwa się w bok** o 2–3 dp i dociska do ścianki. Kreda rysuje 3 kreski tarcia. | narastający szum tarcia rdzenia; przy `bind` krótkie „zacięcie” | ciągły opór rośnie z T; `bind` = transient 0,45 | `bind` i T w paśmie przez 0,5 s | **L nie dotyka:** H1 odcisk pogłębia się dwa razy; H2 widmo kciuka jedzie w górę o 120 dp, a napinacz się obraca; H3 kreda: strzałka-łuk przy napinaczu; H4 ręka mistrza ustawia T = 0,3 i **trzyma**, dopóki L nie dotknie (potem płynne przejęcie). **L puszcza co chwilę:** H2 widmo pokazuje „połóż i trzymaj” (kciuk leży 1,5 s). |
| **1.3 Unoszenie** | Odcisk kciuka po prawej. P w górę → grot haczyka unosi kołek dolny; klin szczeliny przy linii podziału się zwęża (kreda: dwa trójkąty). Przy wejściu w okno: kołek górny siada na półce, rdzeń obraca się o jedną podziałkę wygrawerowanej skali. | skrobanie gęstnieje i drobnieje (`near_shear`), potem jasny, suchy **klik** | `near_shear`: wyostrzenie oporu i lekki „tik”; `set`: ostry transient, chwilowy spadek oporu | `set` | **P nie dotyka:** H1 odcisk po prawej; H2 widmo unosi wytrych. **T za duże (> 0,60, kołek „nie idzie”):** H1 kołek drży przy każdym ruchu P, słychać zgrzyt; H2 widmo **lewego** kciuka zjeżdża w dół o 30 dp; H3 strzałka „w dół” przy napinaczu. **T za małe (kołek luźny, odskakuje):** H2 widmo lewego kciuka w górę; H3 kreski tarcia mrugają raz i znikają (brak wiązania). H4: ręka mistrza ustawia kołek. |
| **1.4 Otwarcie** (bez gracza) | Ostatni (jedyny) stos jest ustawiony, więc rdzeń obraca się do 90° (250 ms), a rygiel wysuwa się z wkładki. Kamera odjeżdża 10%. Oddech 600 ms. | ciężki szczęk mechanizmu, oddech tła | długi ciepły wzorzec `open` | `open` | — |

Po S1: widmo dłoni wyjmuje wkładkę z imadła i wkłada następną. Zwijka zostaje rozwinięta.

### S2 — „Trzy po kolei” (`pin.s2`, cel 30–60 s)

Uczy: **wiąże zawsze tylko jeden kołek**. Trzeba go znaleźć, ustawić, a potem następny zaczyna wiązać. Kolejność od przodu (0 → 1 → 2). Okno 16%, pasmo T ~0,15–0,55. `drop_all = false`, więc puszczenie napięcia zrzuca tylko ostatni ustawiony kołek (łagodna lekcja zrzutu).

| Krok | Widzi | Słyszy | Czuje | Warunek | Utknięcie > 15 s |
|---|---|---|---|---|---|
| **2.1 Napięcie** (znane) | jak 1.2, ale bez odcisku od startu (odcisk dopiero na H1); wiąże kołek 0 | jak 1.2 | jak 1.2 | `bind` kołka 0 | jak 1.2, skrócone (H2 → H4 po 30 s) |
| **2.2 Szukanie** | P przesuwa się w bok (głębokość) i haczyk przeskakuje „magnesem” od kołka do kołka. **Luźne kołki** unoszą się lekko i spadają ze sprężystym odbiciem. **Wiążący** stoi twardo, przechylony, z kreskami tarcia (kreda tylko w S1, tu tylko kształt). | przy każdym kołku cichy „tik” (`contact`); luźny: brzęk sprężyny (`pin.spring_bounce`); wiążący: chropawe skrobanie | luźny: lekki; wiążący: ciężki opór wytrycha | `near_shear` na wiążącym kołku | **P podnosi luźne kołki:** H1 wiążący kołek drga o 1 dp przy każdej zmianie T; H2 widmo prawego kciuka przesuwa haczyk pod wiążący i unosi; H3 kreda: kreski tarcia przy wiążącym; H4 ręka mistrza ustawia go. |
| **2.3 Ustawienie i „następny”** | `set` kołka 0, rdzeń +1 podziałka. Od razu kołek 1 przesuwa się w bok (zaczyna wiązać). | klik, potem nowe skrobanie w innym miejscu panoramy stereo | klik, potem `bind` | `set` kołka 1, potem kołka 2 | jak 2.2 dla kolejnego kołka |
| **2.x Zrzut (incydent, nie krok)** | Jeśli L puści na > 500 ms: ostatni ustawiony kołek **spada**, rdzeń cofa się o podziałkę. | drobny stuk i brzęk sprężyny | 2 słabe transienty | — | Jeśli zrzut powtórzy się 2× w 20 s: H2 widmo lewego kciuka „leży i trzyma”, H3 kreda rysuje drogę spadku kołka. |
| **2.4 Otwarcie** | jak 1.4 | | | `open` | — |

### S3 — „Nie od przodu” (`pin.s3`, cel 40–90 s)

Uczy: kolejność wiązania jest **nieoczywista** (tył → przód → środek) i **przepchnięcie** (overset). Pierwsza pułapka rodziny: dolny kołek pchnięty za wysoko blokuje rdzeń, a wyjście to puszczenie napięcia, które tu zrzuca **wszystko** (`drop_all = true`). Okno 12%, zapas do overset tylko 8%. Tu pojawia się lupa (§6). Kreda tylko jako H3.

| Krok | Widzi | Słyszy | Czuje | Warunek | Utknięcie > 15 s |
|---|---|---|---|---|---|
| **3.1 Znajdź wiążący z tyłu** | wiąże kołek 2 (najgłębszy); kołki 0 i 1 luźne | jak 2.2; panorama: skrobanie słychać bardziej z prawej | jak 2.2 | `set` kołka 2 | H1 kołek 2 drga; H2 widmo przesuwa haczyk w głąb; H3 kreski tarcia; H4 ręka mistrza. |
| **3.2 Przód, potem środek** | jak 2.3 | | | `set` kołków 0 i 1 → `open` | jak 3.1 dla kolejnego |
| **3.x Przepchnięcie (pułapka)** | Gracz pcha dalej po kliknięciu: kołek dolny przechodzi przez linię podziału, **sprężyna ściska się w czarną bryłę**, kołek nie wraca, a komora milknie. Lupa na zwijce przetacza się o 2 mm z cichym brzękiem (afordancja §6). | martwy, tępy stuk; potem cisza tej komory | tępy transient, potem „martwy” opór bez modulacji | **wyjście:** T < 0,05 (wszystko spada, `drop`), potem od nowa | **Gracz dalej pcha lub kręci napięciem:** H1 lupa przetacza się drugi raz; H2 widmo lewego kciuka **unosi się z ekranu i wraca** (gest „puść i zacznij lżej”); H3 kreda rysuje klamrę nad komorą i strzałkę „w dół” przy napinaczu; H4 ręka mistrza puszcza napięcie, kołki spadają, ręka kładzie napięcie ponownie i **ustawia jeden kołek wolniej**, pokazując tempo. |
| **3.3 Otwarcie** | jak 1.4, ale kamera odjeżdża dalej i pokazuje, że imadło stoi w warsztacie, a za nim drzwi zaplecza | | | `open` | — |

## 5. Pierwszy prawdziwy zamek (zamek testu A1)

Po S3 drzwi zaplecza trzaskają (przeciąg), a klucz zostaje w środku. To **własne drzwi warsztatu**, więc nie ma sceny weryfikacji (JOBS §2) ani klienta, a ton pozostaje ciepły i legalny.

- Zamek: `pin.a1` (`LEVELS.md` §2.5): kopia wygenerowanego `pin_tumbler` t2, seed 1, zapisana jako `authored`, żeby test A1 był powtarzalny. 3 stosy, kolejność środek → tył → przód, bez kredy, `fb_gain` ×1,0, bez H1–H4 w teście (w zwykłej grze eskalacja działa, ale tylko H1–H3, bez ręki mistrza).
- Wejście: kamera przejeżdża od imadła do drzwi, przekrój wkładki pojawia się w drzwiach (fotorealistyczny przekrój jak w całej grze). Zwijka jest ta sama.
- Wyjście: drzwi się otwierają, gracz widzi swój klucz na haczyku. Pierwszy **rachunek-przedmiot** (`HUD.md` §8) jest wypisany „dla siebie”: 0 zł i dopisek ołówkiem „kawa”. To jedyny żart, a przy okazji pokazuje, jak wygląda rachunek.
- Potem otwiera się Tryb Ciągły (pierwsza karta zlecenia z bloczka).

## 6. Lupa (D-13)

### 6.1 Wprowadzenie

- Lupa zegarmistrzowska leży w zwijce od S1 (w kieszeni obok wytrychów), ale do S3 jest „uśpiona”: nie reaguje na dotyk i nie ma afordancji.
- W S3, przy pierwszym `overset` albo gdy gracz przez 15 s krąży wokół linii podziału (`near_shear` bez `set`), lupa **przetacza się w kieszeni o 2 mm** z cichym szklanym brzękiem. To jedyna afordancja.
- Jeśli gracz jej nie dotknie, stopień H2 pokazuje widmo prawego kciuka, które stuka w lupę, a H3 rysuje kredą kółko wokół lupy.

### 6.2 Zasady gry

- Dotknięcie lupy (P) **zamraża wytrych** w bieżącej pozycji (głębokość i uniesienie) i otwiera **okrągłe pole okularu** (Ø 60% szerokości ekranu w pionie, środek nad stosem pod wytrychem). W okularze widać makro linii podziału tego stosu: szczelinę, krawędź kołka górnego, fazki. To ten sam model 3D, inna kamera, a nie rysunek.
- **L dalej trzyma napięcie**, a napięcie dalej działa (drop, stress i binding liczą się normalnie). Lupa nie zatrzymuje czasu.
- Zamknięcie: dotknięcie w dowolnym miejscu prawej strefy albo ponowne dotknięcie lupy. Wytrych wraca pod kontrolę P od pozycji zamrożonej (prawe uniesienie jest względne od przyłożenia kciuka, D-24), więc nie ma skoku.
- Wejście i wyjście okularu: 180 ms, przesłona jak przy przyłożeniu oka (winieta zwęża się), bez efektu soczewki „rybie oko”, bez poświaty na krawędzi.
- W trybie „w ciemności” lupy nie ma (kieszeń jest zapięta na napę). W samouczku S1–S3 lupa nie liczy się do żadnych statystyk.

## 7. Tryb „w ciemności”

### 7.1 Wprowadzenie (jednorazowe, skryptowane)

- Kiedy: **drugi** zamek Trybu Ciągłego po zamku A1, jeśli to wkładka bębenkowa t2 lub płytkowa t1–t2 (inaczej pierwszy taki).
- Moment: tuż po pierwszym `set`. Minutnik na klatce schodowej klika i **światło gaśnie** (400 ms, jak prawdziwa żarówka: krótkie przygaśnięcie, potem czerń). Zostaje tylko słaby relief klapki pauzy (`HUD.md` §10).
- Dźwięk i haptyka grają dalej bez zmian, a okna rosną ×1,15 (`LOCKS.md` §1.7). Rampa `near_shear` w dźwięku jest wyraźniejsza.
- Jeśli gracz otworzy zamek w ciemności, światło zapala się w chwili `open` i gracz **widzi**, co zrobił (to nagroda). Na rachunku pojawia się pieczątka „w ciemności” / „in the dark” i dostaje +20% monet (`PROGRESSION.md` §2.1).
- Jeśli gracz przez 20 s nie robi postępu, na ścianie po lewej (nad strefą L) pojawia się **relief włącznika minutnika** z odciskiem kciuka (H1). Dotknięcie zapala światło na resztę zamka bez kary (bez premii).
- Od tej chwili minutnik jest stałym przełącznikiem: przed każdym zamkiem włącznik na ścianie klatki jest w kadrze. Wciśnięty = światło, zostawiony = „w ciemności”. To samo jest w pauzie (`HUD.md` §6).

### 7.2 Co znika i co zostaje

Szczegóły w `HUD.md` §10. Skrót: znika cały obraz przekroju, zwijki, wytrychów i lupy; zostają dźwięk, haptyka, relief pauzy i (opcjonalnie) miękki odcisk kciuka, który potwierdza tylko, że dotyk jest zarejestrowany.

## 8. Wkładka płytkowa S1–S3 (druga rodzina)

Płytkowa korzysta z tego samego modelu napięcia, więc jej samouczek uczy **różnic**, a nie podstaw. Wchodzi przed pierwszym zamkiem płytkowym w serii. Parametry: `LEVELS.md` §4.

| Poziom | Uczy | Przebieg (skrót) | Pułapka i eskalacja |
|---|---|---|---|
| **S1 „Lżejsze kliknięcia”** (`wafer.s1`, 15–30 s) | Płytka to jedna ramka, a nie stos. Kliknięcia są wyższe i lżejsze, a płytki luźne grzechoczą (`wafer.rattle`). Kolejność: środek → przód → tył. | Narzędzia wchodzą same. L napina, P szuka wiążącej płytki (kształt: ramka z prostokątnym oknem przesuwa się w bok i dociska). Trzy `set`, potem `open`. Kreda pełna. | Gracz trzyma tempo z pinowej i za szybko przeciąga wytrych: grzechot. H1 płytka wiążąca drga; H2 widmo przesuwa wytrych wolniej; H4 ręka mistrza. |
| **S2 „Za wysoko i co dalej”** (`wafer.s2`, 25–50 s) | Przepchnięta płytka (overset) **nie wymaga zrzutu**: wystarczy lekko odpuścić (T między 0,08 a 0,16), a ustawione płytki zostają. Zapas do overset jest mały (6%), więc gracz prawie na pewno przepchnie. | Po pierwszym `set` gracz zwykle pcha dalej, płytka wchodzi w rowek po drugiej stronie, komora milknie. | **Nawyk z pinowej: puszcza do zera** → spadają wszystkie. H1 napinacz kołysze się o 1° w dół (nie do zera); H2 widmo lewego kciuka zjeżdża o 25 dp i zatrzymuje się, a widz widzi, że płytka wraca, a reszta stoi; H3 kreda: dwie kreski na łuku napinacza (dolna i górna granica „odpuść tu”); H4 ręka mistrza. |
| **S3 „Za mocno”** (`wafer.s3`, 30–60 s) | Górna granica pasma: za duże napięcie **ugina wytrych** (`stress`), a w końcu go łamie. W samouczku złamanie jest „na niby”: nowy wytrych wysuwa się z kieszeni zwijki, nic nie ginie. `tau_safe` 0,44 i podwójny `stress_gain`, więc ugięcie pojawia się szybko i jest dobrze widoczne. | Płytki wiążą przy T ≥ 0,22–0,24. Do ok. 0,44 wszystko jest bezpieczne. Powyżej 0,44 płytki dalej idą (do 0,52–0,54), ale wytrych się wygina, rosną rysy i słychać jęk metalu. | **Gracz „dociska, bo szybciej”:** H1 wytrych drga z amplitudą 1 dp przy każdym nacisku; H2 widmo lewego kciuka zjeżdża w dół; H3 kreda: strzałka „w dół” i poprzeczne rysy na wytrychu. Po złamaniu: końcówka zostaje w kanale, uchwyt odskakuje, odłamek ląduje na blacie, a widmo dłoni wyjmuje końcówkę i podaje nowy wytrych (2 s). Zamek nie resetuje się. |

## 9. Lekcje wtrącone

Lekcja wtrącona to jeden krótki zamek autorski (15–45 s), który pojawia się **przed pierwszym zamkiem serii** z nowym elementem albo przy pierwszym użyciu nowego narzędzia. Ma ten sam słownik wskazówek (§2) i nie kosztuje wytrycha.

### 9.1 Szpulka (`pin.l_spool`, przed pierwszym profilem z zabezpieczeniem, P06)

- 3 stosy, środkowy to szpulka. Uczy: **fałszywe ustawienie** (`false_set`: rdzeń obraca się o 2 podziałki zamiast 1, klik głuchy i podwójny, talia szpulki na linii podziału, obrys przerywany w kredzie) i **kontrrotacji** (`counter_rotate`: przy dalszym unoszeniu napinacz cofa się pod kciukiem, skrzyp i rytmiczne pchanie). Wyjście: lekko odpuścić napięcie do pasma 0,12–0,21 i dopchnąć.
- Eskalacja: H1 napinacz cofa się wyraźniej (×1,5); H2 widmo lewego kciuka **ustępuje razem z napinaczem** (gest „daj mu się cofnąć”); H3 kreda: dwie kreski na łuku napinacza (pasmo kontrrotacji); H4 ręka mistrza.
- Na koniec (opcjonalnie, 20 s, pomijalne) test rozróżniania z `TECH.md` §2.3 krok 3: 6 kliknięć w imadle, gracz dotyka jednej z dwóch leżących na blacie części: **kołka prostego** (set) albo **szpulki** (false_set). Wynik < 4/6 nie blokuje gry, tylko wydłuża podpowiedź kontrrotacji w następnych zamkach.
- Uwaga: generator v0.1 losuje w t4–t6 szpulkę albo kołek ząbkowany po równo. Jeśli pierwszym zabezpieczeniem w serii będzie kołek ząbkowany, gra pokazuje mini-lekcję „ząbki” (ten sam zamek z kołkiem ząbkowanym zamiast szpulki, `LEVELS.md` §2.4), a szpulkę przy pierwszym spotkaniu.

### 9.2 Falownik (przy zakupie, `TOOLS.md` §4 krok 3)

Zamiast pierwotnego S3 płytkowej („falownik kontra haczyk”, D-22). W warsztacie, po zakupie: wkładka płytkowa W03 w imadle. Widmo dłoni pokazuje ruch falą (kilka szybkich przeciągnięć), a 2–3 płytki ustawiają się naraz. Potem ta sama wkładka z jedną szpulką (pinowa ≤ t3): fala zawsze kończy się `false_set`, a haczyk musi dokończyć. Wymaga narzędzia `TOOL_RAKE` w lockcore (w v0.1 jeszcze nieobsługiwanego przez rodziny).

### 9.3 Mikroskop i wziernik (D-13)

Przy zakupie w warsztacie: mikroskop stoi na blacie obok imadła. Pierwsze użycie pokazuje zadziory na grocie własnego wytrycha (zużycie, `TOOLS.md` §2) i talię szpulki w powiększeniu. Wziernik pojawia się z pierwszą rodziną głębokiego kanału (dźwigniowa) i ma lekcję wtrąconą w samouczku tej rodziny. Oba działają jak lupa (§6.2): zamrażają wytrych, napięcie działa dalej, w ciemności są niedostępne. Role, ceny i co dokładnie pokazują: `TOOLS.md` §3.4a, `HUD.md` §4.1 (D-35).

### 9.4 Przestroga o narzędziu: pierwszy zamek z fałszywą bramką (D-120)

Bot „ciężkiej ręki” (D-118) pokazał, że narzędzia zaczynają pękać nagle, na pierwszym tierze rodziny z fałszywą bramką: `pin_tumbler` t4, `lever` t4, `lever_detector` t5, `dimple` t2, `axial_slider` t2, a w `warded` na t2 (pierwsza sonda, która może pęknąć). Tabela: `game/data/tool_caution.json`.

- **Kiedy:** pierwszy zamek rodziny na tym tierze lub wyższym, w zleceniach i w trybie ciągłym (nie w samouczku ani w ćwiczeniach). Jednorazowo: zapis `lessons/<rodzina>/caution` po otwarciu zamka; złamane narzędzie i porażka nie kasują przestrogi, pojawi się przy następnej próbie.
- **Co widać (kreda trenera, ten sam `TutorialCoach` i ta sama linia co lekcje, także przy wyłączonej „Warstwie kredy”):**
  1. od początku do pierwszego ustawienia (i nie krócej niż 3 s): „Trudniejszy zamek. Tu siła łamie narzędzie.” (`lock.caution_intro`; `warded`: `lock.caution_warded`);
  2. gdy element siedzi w fałszywym ustawieniu (i 2 s dłużej): „Głuchy podwójny klik? Pułapka. Odpuść, nie dociskaj.” (`lock.caution_false_set`);
  3. gdy narzędzie się wygina (`stress` ≥ 0,6 S_max, próg zdarzenia `stress` w lockcore; linia zostaje 2 s po odpuszczeniu): „Narzędzie się wygina. Odpuść.” (`lock.caution_stress`) i **kredowa strzałka „w dół” przy napinaczu** (znak z kroku przepchnięcia, H3 z §2.1). Przy napięciu automatycznym sama linia, bez strzałki (napinacz trzyma gra).
- **Kanały stanu `stress` bez zmian** (`DESIGN.md` §1): ugięcie wytrycha i napinacza, 1→3 poprzeczne rysy, drżenie od 90 % (znika przy ograniczeniu ruchu), jęk metalu, narastające drżenie haptyczne, napis dźwięku `[jęk metalu]`, komunikat czytnika ekranu. Przestroga dokłada do obrazu trzeci, nieruchomy znak (strzałkę) i zdanie; nie ma paska ani koloru.
- **Lekcja rodziny ma pierwszeństwo.** `dimple` i `axial_slider` trafiają na ten tier już w pierwszym zleceniu, czyli w lekcji z §8/T42. Lekcja zostawia swoje linie (jej pułapka uczy fałszywego ustawienia: „Odpuść lekko…”), a przestroga dokłada tylko linię i strzałkę wyginania.
- **Bez drabiny H1–H4:** gracz zna rodzinę; trener istnieje wtedy wyłącznie dla przestrogi i nie pokazuje linii pierwszych zleceń.
- Ćwiczenia, które utrwalają to samo: t15 (przepchnięcie), t20, t21, t23 (fałszywe ustawienie, kontrrotacja, ząbki), t27–t28 (detektor).

## 10. Wzór samouczka dla każdej rodziny

Każdy dodatek dostarcza S1–S3 według tego szablonu (uzupełnia `PROGRESSION.md` §1 i §6):

| Poziom | Musi nauczyć | Elementy | Okna i sygnały | Kreda | Pułapka |
|---|---|---|---|---|---|
| **S1** | podstawowy ruch rodziny i to, jak wygląda i brzmi sukces | 1 (lub minimum rodziny) | okna ≥ 1,6× t-minimalnego tieru rodziny, `fb_gain` ×1,5, **bez możliwości złamania** (`tau_safe` = 1,0 lub odpowiednik) | pełna | brak |
| **S2** | kolejność albo podstawowy wybór (który element teraz) | 2–3 | okna ≥ 1,3×, `fb_gain` ×1,3, łagodny zrzut (tylko ostatni element) | tylko linia podziału / bramka | brak lub łagodna (zrzut) |
| **S3** | **pierwsza pułapka** rodziny i wyjście z niej | 3 | okna jak t-minimalny tier, `fb_gain` ×1,15 | tylko jako H3 | 1 (overset, fałszywa bramka, detektor …) |
| **Lekcje wtrącone** | każdy nowy element zabezpieczający i każde nowe narzędzie | 1–3 | jak S2 | jak S2 | dokładnie ta jedna |

Checklista storyboardu każdego poziomu (tabela jak w §4): krok, widzi, słyszy, czuje, warunek przejścia (zdarzenie logiki), diagnoza „utknięcia” z H1–H4 dla **każdego typowego błędu**, wersja „w ciemności” (dźwięk i haptyka niosą krok sami?), wersja bez haptyki (A9), czas docelowy.

Przewidywane pułapki S3 przyszłych rodzin (do potwierdzenia w ich kartach): `warded` — zły profil grotu (zablokowanie na zapadce); `lever` — przepchnięta dźwignia; `lever_detector` — detektor i sekwencja resetu; `ring_combo` — fałszywa bramka pierścienia; `tubular` — overset przy wciskaniu; `disc_detainer` — tarcza obrócona za daleko; `wooden_pin` — kołek wpada z powrotem przy puszczeniu.

## 11. Dostępność samouczka (A9)

- **Bez haptyki** (wyłączona, iPad, A–): każdy krok S1–S3 jest do przejścia samym obrazem i dźwiękiem. Sprawdzamy to w teście A9 (`DESIGN.md` §4). Wskazówki H1–H3 nie używają haptyki nigdy (§2.1).
- **Bez dźwięku** (wyciszony telefon): obraz + haptyka wystarczą w S1–S3 dzięki kredzie. Jeśli system jest wyciszony, gra w pierwszym uruchomieniu nie prosi o dźwięk, tylko sama włącza napisy dźwięków na czas samouczka (`HUD.md` §9) i wyłącza je po S3, chyba że gracz je zostawi.
- **„Pomoc w czytaniu”** (kreda wszędzie, większe kontrasty, napisy dźwięków): przełącznik w pauzie, działa od razu, także w samouczku.
- **Czytniki ekranu**: H2–H4 mają krótki opis głosowy (np. „Przytrzymaj lewy kciuk i przesuń w górę.”), a kalibracja i notka mają etykiety. Zamek sam w sobie jest i tak „dźwiękowy”.
- **Motoryka**: opcja „blokada napięcia” (`HUD.md` §9) działa w samouczku. Kreda H2 pokazuje wtedy gest blokady zamiast przytrzymania.
- **Ograniczenie ruchu** (systemowe „Reduce Motion”): kreda gestu jest statyczna (cała droga, grot, pierścień na starcie), nic nie jedzie (§2.2).

## 12. Plan testu A1 i A2

### 12.1 Cel i progi (z `DESIGN.md` §4)

- **A1:** nowicjusz otwiera 3-pinową wkładkę (`pin.a1`) bez czytania tekstu, po samouczku S1–S3. Próg: **mediana < 90 s i ≥ 75% osób < 90 s**.
- **A2:** ci sami testerzy, inna 3-pinowa wkładka t2 (`pin.a2`: generator t2, seed 2, zapisany jako `authored`), ekran zgaszony (czarna nakładka, tryb „w ciemności”). Próg: **≥ 60% otwiera w < 3 min**.

### 12.2 Uczestnicy

- **N = 16** (DESIGN wymaga ≥ 12; 16 daje zapas na 2–3 odrzucone sesje i pozwala oceniać 75% jako 12/16). Do decyzji „przeszło” potrzeba co najmniej 12 ważnych sesji.
- Kryterium „nowicjusz”: nigdy nie otwierał zamka wytrychem ani nie oglądał poradników o tym. W ostatnich 12 miesiącach nie grał w gry o otwieraniu zamków dłużej niż godzinę.
- Rozkład: wiek 16–70 (co najmniej 4 osoby 50+), co najmniej 6 kobiet, co najmniej 2 osoby leworęczne, 4 osoby rzadko grające na telefonie (< 1 h tygodniowo). Połowa sesji po polsku, połowa po angielsku (osoby anglojęzyczne lub z ustawieniem EN), bo A1 nie może zależeć od języka.
- Wykluczenia: zaburzenia słuchu lub czucia w kciukach (te osoby testujemy osobno w A9, nie w A1/A2).

### 12.3 Sprzęt

- 2 urządzenia referencyjne z `TECH.md` §6.2: iPhone 12 (H3) i średni Android z prymitywami (A2). Przydział naprzemienny: 8 + 8.
- Głośność stała (60% systemowej, sprawdzona miernikiem: ok. 65 dB(A) z 30 cm), bez słuchawek. Jasność 70%, wyłączona automatyczna jasność.
- Świeża instalacja, kalibracja haptyki wykonywana przez testera (część pierwszego uruchomienia, mierzymy ją).

### 12.4 Protokół (ok. 25 min na osobę)

1. **Przywitanie (2 min).** Zgoda na nagrywanie (RODO, osoby < 18 lat: zgoda opiekuna). Moderator czyta **dokładnie**: „To gra. Proszę po prostu grać. W trakcie nie mogę nic podpowiadać. Jeśli będzie Pani/Pan chciał(a) przerwać, wystarczy powiedzieć.”
2. **Pierwsze uruchomienie i S1–S3 (do 10 min).** Tester sam uruchamia aplikację z ekranu głównego. Moderator milczy. Jedyna dozwolona interwencja: jeśli tester odłoży telefon i zapyta, moderator mówi „Proszę spróbować dalej.” (zapisane w notatkach).
3. **A1 (do 5 min).** `pin.a1` zaczyna się od razu po S3 (zgodnie z §5). Eskalacja wskazówek w zamku A1 jest **wyłączona** (flaga testowa), żeby mierzyć umiejętność, a nie pomoc. Po 5 min przerywamy (wynik: nie otworzył, czas = cenzurowany).
4. **Przerwa (1 min).** Bez rozmowy o mechanice.
5. **A2 (do 5 min).** Moderator mówi: „Teraz ekran będzie czarny. Zamek działa tak samo.” (jedno zdanie, to samo dla wszystkich, bo czarny ekran bez zapowiedzi wygląda jak awaria). Zamek `pin.a2` w trybie „w ciemności”. Po 5 min przerywamy.
6. **Rozmowa po (5 min, retrospektywnie, z nagraniem).** Moderator odtwarza 3 fragmenty nagrania (pierwszy `set`, pierwszy błąd, otwarcie) i pyta: „Co tu się działo?” oraz „Po czym Pani/Pan poznał(a)…?”. Do tego 4 zrzuty w skali szarości (binding, set, overset, stress) z pytaniem „co to oznacza?” (wstępny sygnał dla A7). Krótka ankieta: 5-stopniowa skala „było jasne, co robić”, „haptyka pomagała”, „było przyjemnie”.

Nie stosujemy myślenia na głos w trakcie: mowa wydłuża czasy i zmienia uwagę, a A1 mierzy czas.

### 12.5 Metryki

| Metryka | Źródło | Uwagi |
|---|---|---|
| **Czas A1** od pierwszego dotyku zamka `pin.a1` do `open` | log zdarzeń lockcore (tick) | główna metryka A1 |
| **Czas A2** jw. dla `pin.a2` | log | główna metryka A2 |
| Czas pierwszego uruchomienia do pierwszego dotyku S1 | log UI | cel ≤ 25 s |
| Czas S1, S2, S3 osobno; czas każdego kroku storyboardu | log | szukamy kroku-wąskiego gardła |
| Najwyższy stopień wskazówki na krok (H0–H4), liczba H4 | log samouczka | „otwarcie bez H4” osobno |
| `drop`, `overset`, `stress`, `break`, `false_set` na zamek | log | |
| Liczba dotknięć i łączna droga kciuków L/P (dp) | log wejścia | „machanie” vs celowe ruchy |
| Średnie T w chwili `set` i odchylenie T w trakcie | log wejścia | czy gracz trzyma pasmo |
| Wynik kalibracji („dwa / jedno / nic”), czas odpowiedzi | log | |
| Pytania po teście: trafność opisu stanów, ankieta | notatki | jakościowo |

Analiza: mediana i odsetek < 90 s (A1), odsetek < 180 s (A2) z przedziałem ufności Wilsona 95% (przy N = 16 przedział jest szeroki, więc wynik „na granicy” traktujemy jako „powtórzyć z poprawkami”). Krzywe przeżycia (Kaplan–Meier) dla czasów cenzurowanych po 5 min. Porównanie iOS vs Android i PL vs EN tylko opisowo.

### 12.6 Co nagrywać

- **Ekran** z nakładką dotyków (natywne nagrywanie ekranu + warstwa debug pokazująca punkty dotyku L/P; w A2 nakładka czerni jest tylko na ekranie telefonu, a nagranie ma pełny obraz sceny).
- **Dłonie z góry**: kamera nad stołem (≥ 60 fps), żeby widzieć chwyt, kciuki i odkładanie telefonu.
- **Twarz** (opcjonalnie, za osobną zgodą): kamera przednia lub boczna. Frustracja i „aha” są czytelne z mimiki.
- **Dźwięk otoczenia** (mikrofon na stole), żeby wychwycić komentarze i to, czy dźwięk gry był słyszalny.
- **Powtórka lockcore**: każdy zamek zapisany jako `lockwright.replay/1` (wejścia + hash). Pozwala odtworzyć sesję bit w bit i policzyć metryki wejścia bez wideo.
- **Log samouczka**: kroki, stopnie H, czasy, wynik kalibracji (JSON, lokalnie, bez danych osobowych; plik nazwany numerem testera).

### 12.7 Decyzja po teście

- A1 i A2 przeszły: zamrażamy S1–S3 pinowej (zmiany tylko po kolejnym teście).
- A1 nie przeszło: patrzymy na krok-wąskie gardło (najdłuższy krok, najwięcej H3/H4) i poprawiamy **jeden** krok naraz. Pilot poprawki: 5 nowych osób, potem pełny test.
- A2 nie przeszło, a A1 tak: wzmacniamy rampę `near_shear` i kontrast set/overset w dźwięku (`TECH.md` §3.4), sprawdzamy okna ×1,15 → ×1,25.
- Pilot przed właściwym testem: 3 osoby (spoza puli), żeby sprawdzić protokół, nagrywanie i flagi testowe.

## 13. Dane i i18n

- Pierwsze lekcje 8 rodzin v0.6 (T42, D-68) są już danymi: `game/data/lessons/<family>.json` (schemat `lockwright.lesson/1`, opis w nagłówku sekcji lekcji `game/scripts/lock/tutorial_coach.gd`).
- Skrypty samouczka jako dane: `game/data/tutorial/<family>.s1.json` itd. (propozycja): lista kroków z warunkiem przejścia (`event`, `element`, czas trzymania), diagnozami błędów (warunek na wejściu i stanie, np. `T > t_stick && press > 0`) i przypisanymi wskazówkami H1–H4 (id animacji widma, id znaku kredy, id dźwięku). Logika zamka jest w lockcore, a skrypt samouczka tylko czyta zdarzenia i `ViewModel`.
- Klucze i18n (PL + EN od pierwszego dnia, D-19): `onboarding.lang.pl`, `onboarding.lang.en`, `onboarding.haptics.question`, `onboarding.haptics.two`, `onboarding.haptics.one`, `onboarding.haptics.none`, `onboarding.haptics.off_note`, `onboarding.notice.line1`, `onboarding.notice.line2`, `onboarding.receipt.self_note`, `tutorial.voice.<step>` (opisy dla czytników ekranu). Treści w §3.
