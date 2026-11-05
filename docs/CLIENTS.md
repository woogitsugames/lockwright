# Klienci, sąsiedzi i głos zeszytu — biblia narracyjna

Status: szkic do przeglądu · 2026-11-05 · uzupełnia `docs/JOBS.md` (zlecenia, weryfikacja, wycena).
Dane źródłowe: `game/data/jobs/*.json` i `game/i18n/content.csv` (własność sesji B, tu tylko czytane).
Gotowy blok CSV do wklejenia jest w **Załączniku A**, a mapa mówców w **Załączniku B**.

> To gra, nie kurs. Rozdział o prawie to nasza interpretacja z `JOBS.md` §1, a nie porada prawna.

---

## 1. Zasady pisania (skrót)

- **Ton:** ciepły, rzeczowy, z suchym humorem. Ślusarz mówi krótko, nie poucza, nie mówi „jestem profesjonalistą”.
- **Długość:** linia dialogu ≤ 90 znaków w PL i w EN. Wpis w zeszycie ≤ 130 znaków.
- **Wykrzykniki:** w 116 liniach nie ma ani jednego. Emocję niesie treść, a nie interpunkcja.
- **Bez marek** zamków, samochodów, aplikacji i urzędów. Nie piszemy „mObywatel”, tylko „aplikacja” / *the app*.
  Wyjątek: nazwy miejsc (Kazimierz, Saint-Gilles, Piccadilly) i instytucji kultury w gablocie.
- **Bez instrukcji.** Linie mówią, *że* zamek jest trudny albo stary, a nigdy *jak* go otworzyć.
- **Podejrzane historie** rozpadają się na zachowaniu i sprzecznościach, nigdy na szczegółach dokumentu.
- **EN to nie kalka.** Gry słów zastępujemy innym żartem. Polskie formy grzecznościowe (pani/pan) oddajemy jako
  *Mrs/Mr + imię*, bo tak mówi się w kamienicy: „pani Halina” = *Mrs Halina*.
- **Forma „pan” wobec ślusarza.** W PL klienci zwracają się do ślusarza „pan”, tak jak w `JOBS.md`. Gdy dodamy
  wybór postaci, linie z „pan” dostaną wariant „pani” (klucz `…line.N.f`). Tam, gdzie się dało, linie omijają formę adresu.

## 2. Miasto i tabliczki

Miasto robocze **Zameczno** (`JOBS.md` §4, nazwa do sprawdzenia): stare kamienice w Śródmieściu, bloki na Osiedlu
Słonecznym, kampus, Nocny Rynek, wille, ogródki nad rzeką i port z Muzeum Techniki.

**Emaliowane tabliczki** to motyw wizualny i narracyjny:
- Każde zlecenie otwiera się kartą w kształcie emaliowanej tabliczki z numerem mieszkania lub nazwą miejsca
  („m. 7”, „Pokój 412”, „Szafka 8”). Kształt i podpis, a nie kolor, więc karta jest czytelna w skali szarości.
- Warsztat ślusarza ma nad drzwiami starą, obtłuczoną tabliczkę „POGOTOWIE ZAMKOWE” po poprzedniku, mistrzu
  Henryku. W rozdziale 2 Marta przynosi nową, którą sama zaprojektowała (nagroda fabularna, przedmiot w warsztacie).
- Tabliczka na skrzynce lub drzwiach bywa **poszlaką** (inne nazwisko w `job.wrong_floor`, jedno nazwisko w
  `job.refuse_ex_partner`). Gra nigdy nie robi z niej zagadki o fałszerstwie.

## 3. Obsada stała (12 osób)

Imiona działają w obu językach. Polskie znaki zostają (Władysław, Zuzanna), bo font je obsługuje, a gracz EN
czyta je jak nazwy własne.

| # | Postać (`cast.*`) | Kim jest | Głos | Czego potrzebuje | Gdzie wraca |
|---|---|---|---|---|---|
| 1 | **Pani Halina** (`halina`), 81 | Emerytka ze Śródmieścia, kapcie, rosół, „synku”. | Ciepły, stanowczy w sprawach jedzenia. Krótkie zdania z dygresją. | Żeby ktoś przyszedł szybko i został na talerz. | Rozdz. 1 (rosół), finał (kartka „Rosół czeka”). |
| 2 | **Pani Zosia** (`zosia`), ok. 75 | Sąsiadka Haliny „przez ścianę” od 40 lat. Wzorcowy sąsiad-świadek. | Rzeczowy, z czułą irytacją („nie denerwuj się, Halinko”). | Spokoju na klatce. | Rozdz. 1, rozdz. 3 (poleca ślusarza pani Irenie). |
| 3 | **Pan Stefan** (`stefan`), 67 | Kiosk przy przystanku na Osiedlu, od 1994 r. Barometr reputacji. | Gawędziarz. Wie wszystko, mówi o połowie. | Otworzyć kiosk przed pierwszym autobusem. | Rozdz. 1 (kiosk), potem komentarze „dzień po” przy odmowach. |
| 4 | **Pan Roman** (`roman`), 58 | Administrator bloków Osiedla Słonecznego. Ma listę lokatorów „w systemie”. | Przez domofon. Sucho, sprawnie, bez zbędnych słów. | Żeby nikt obcy nie wchodził do jego bloków. | Rozdz. 1 (proponowany świadek przy Darku), rozdz. 2 (pielęgniarka). |
| 5 | **Aspirant Lena Sowa** (`lena`), 39 | Dzielnicowa. Uprzejma, zwyczajna, bez pościgów. | Spokojny, konkretny, dziękuje za telefon. | Żeby ludzie dzwonili, zanim coś się stanie. | Wszystkie odmowy (rozdz. 1–3). |
| 6 | **Marta** (`marta`), 34 | Graficzka, kot Ziemniak. Była w klasie 3b. | Ironiczny, ciepły pod spodem. | Uwolnić kota, który zamknął się sam. | Rozdz. 1 (kot), rozdz. 2 (nowa tabliczka warsztatu), finał (kapsuła). |
| 7 | **Zuzanna Wilk** (`zuzanna`), 20 | Studentka konserwacji zabytków. Pyta o wszystko. | Szybki, ciekawy, trochę przemądrzały, i o tym wie. | Wrócić do pokoju przed egzaminem z zamków historycznych. | Rozdz. 1 (pokój 412), rozdz. 4 (praktyka przy bramie), rozdz. 6 (staż w muzeum). |
| 8 | **Pan Edek** (`edek`), 63 | Portier akademika. Lista lokatorów i pamięć do twarzy. | „Mam na liście i mam w głowie”. | Porządku w kluczach („ktoś nie oddał”). | Rozdz. 1 (akademik), rozdz. 2 (poleca ślusarza Idze). |
| 9 | **Ola** (`ola`), 38, i **pani Krystyna** (`krystyna`) | Nauczycielka biologii i jej mama. Wątek listów dziadka Józefa. | Ola tłumaczy mamie świat. Krystyna mówi mało i dokładnie. | Otworzyć skrzynię, a potem znaleźć adres z listów. | Rozdz. 3 (skrzynia), rozdz. 5 (Charleroi). |
| 10 | **Pan Władysław** (`wladyslaw`), 84 | Absolwent szkoły ślusarskiej w Świątnikach. Uczył mistrza Henryka. | Krótko, z błyskiem. Sprawdza, nie chwali. | Zobaczyć, „czy młodzi jeszcze umieją”. | Rozdz. 4. Od tej pory zeszyt cytuje „pana W.”. |
| 11 | **Dr Anna Rygiel** (`rygiel`) | Kuratorka Muzeum Techniki. Rękawiczki nawet do kawy. | Pedantyczny, wszystko w trzech egzemplarzach. | Otworzyć skarbiec na wystawę bez jednej rysy. | Rozdz. 6. |
| 12 | **Pani Jadwiga** (`jadwiga`) | Emerytowana wychowawczyni klasy 3b. | Pewna siebie, dopóki nie trzeba sobie czegoś przypomnieć. | Kod do kapsuły czasu, który „zapisała w bezpiecznym miejscu”. | Finał. |

Postacie jednorazowe (Kuba, Iga, Renata, Agnieszka, Kazimierz, Zbyszek, Irena, Leopold, Magda, Nadia, Aino i inni)
mają opisy w `JOBS.md` §5. Ich wypowiedzi są niżej w §8, a imiona do wyświetlania są w Załączniku A (`cast.*.name`).

### 3.1 Jak każda postać stała przechodzi weryfikację

Weryfikacja zależy od tego, **co** otwieramy (`JOBS.md` §2.3), a nie od tego, jak miła jest postać.

| Postać | Obiekt | Dowody w scenie | Co uczy |
|---|---|---|---|
| Halina | mieszkanie | sąsiadka-świadek (Zosia) + list na nazwisko w skrzynce, potem szczegół z wnętrza (zdjęcie wnuka) | Sąsiad to najcieplejszy dowód. |
| Zosia | (świadek) | sama jest dowodem: „czterdzieści lat przez ścianę” | Kim jest dobry świadek. |
| Stefan | lokal firmy (próg 4) | świadek (Krysia) + list z hurtowni, a gdy zabraknie: zdjęcie z otwarcia w 1994 | Przy firmie warto dopytać. |
| Roman | (zarządca) | lista lokatorów przez domofon | Zarządca rozstrzyga szybko i bez dyskusji. |
| Lena Sowa | (urzędnik) | przejmuje weryfikację przy otwarciach z policją | Policja to pomoc, a nie kara. |
| Marta | łazienka we własnym mieszkaniu | brak (próg 0) | Weryfikacja zależy od sytuacji. |
| Zuzanna | pokój w akademiku | portier z listą + dowód | Portier wie najlepiej. |
| Edek | (świadek) | lista lokatorów i pamięć | Jak wygląda świadek instytucjonalny. |
| Ola i Krystyna | dom po dziadku | akt notarialny „pod obrusem” + posiadanie | Dom należy do mamy, więc to ona jest klientką. |
| Władysław | jego własna kłódka | właściciel i twórca | Rzecz w posiadaniu, próg niski. |
| Rygiel | skarbiec muzeum | pismo instytucji + kuratorka | Instytucja daje pismo, nie słowo. |
| Jadwiga | kapsuła na terenie szkoły | dyrekcja + dwudziestu świadków | Najwięcej świadków w grze. |

## 4. Kiedy ślusarz odmawia (przypadki graniczne)

### 4.1 Postawa
- Ślusarz **nie jest sędzią**. Nie oskarża, nie przesłuchuje, nie grozi. Mówi „tu nie otworzę” i proponuje inną drogę.
- Wejście do cudzego lokalu wbrew woli lokatora to sprawa karna (naruszenie miru domowego). Kto w tym pomaga,
  też za to odpowiada. Dlatego weryfikacja chroni lokatora, sąsiadów i samego ślusarza (`JOBS.md` §1.1, interpretacja, nie wykładnia).
- **Zawsze jest legalna droga:** policja pomaga odebrać rzeczy, notariusz i sąd rozstrzygają spadki,
  właściciel albo zarządca może przyjechać, a lokator może zadzwonić. Ślusarz ją wskazuje.
- Odmowa **nie przynosi monet**, ale przynosi spokojną scenę „dzień po” (Lena Sowa, Stefan, sąsiadka) i reputację.
- Policja w grze jest uprzejma i zwyczajna. Telefon to jedna linia dialogu, bez syren.

### 4.2 Wzór sceny odmowy (3 takty)
1. **Zgrzyt widać** (inne nazwisko, pośpiech, sprzeczność). Ślusarz proponuje świadka: sąsiada, zarządcę albo telefon do lokatora.
2. **Klient odmawia świadka** albo historia się sypie. Ślusarz mówi wprost: `notebook.refuse.line` („Tu nie otworzę. Mogę za to pomóc inaczej.”).
3. **Inna droga:** telefon do dzielnicowej albo zarządcy, spokojnie. Następnego dnia krótka scena z Załącznika A (`job.*.after.*`).

### 4.3 Trzy przypadki do odmowy

**`job.refuse_ex_partner` — „To przecież też moje” (rozdz. 1).** Darek chce wejść do mieszkania byłej partnerki „po swoje
rzeczy”. Na skrzynce jest jedno nazwisko, nie jego. Odmawia, gdy ślusarz chce zawołać pana Romana.
*Lekcja:* nawet jeśli ktoś *kiedyś* tu mieszkał, bez zgody obecnej lokatorki drzwi zostają zamknięte. Rzeczy
odbiera się przy policji. Dzień po: Lena Sowa mówi, że rzeczy odebrał przy niej, za zgodą lokatorki. Bez dramatu
i bez wyjaśniania, co Darek chciał zrobić (ton z `JOBS.md`).

**`job.refuse_rush_bribe` — „Siostra kazała” (rozdz. 2).** O 1:00 w nocy mężczyzna w garniturze chce wejść do mieszkania
„siostry za granicą”. Na pytanie o sąsiada proponuje dopłatę.
*Lekcja:* procedur nie da się dopłacić. Ktoś, kto płaci za brak pytań, płaci za nie swoje drzwi (`notebook.rule.3`).
Ślusarz czeka 5 minut na telefon od siostry, a potem mówi dobranoc i daje znać dzielnicowej.

**`job.refuse_aunt_alive` — „Ciotka, która ma się dobrze” (rozdz. 3).** Kobieta chce „zabezpieczyć rzeczy” zmarłej ciotki.
Sąsiadka wychodzi na klatkę: pani Lucyna żyje i jest w sanatorium.
*Lekcja:* spadek to papiery od notariusza albo sądu, a nie słowo „jestem jedyną spadkobierczynią”. Ślusarz nie
oskarża. Proponuje wspólny telefon do pani Lucyny, a potem do aspirant Sowy.

### 4.4 Przypadki pokrewne (nie odmowa, ale ta sama postawa)
- `job.wrong_floor`: pan Kazimierz pomylił piętra. Najlepszy wynik to **nic nie otwierać**. Dzień po pani Teresa piecze ciasto
  „za to, że pan nie otworzył”.
- `job.uncle_safe_heirs`: czekamy na komplet spadkobierców. Odmowa jest tylko na teraz.
- `job.krakow_antiquarian`: częściowa odmowa. Kasę klienta otwieramy, kasetki cudzego klienta nie.

## 5. Łuk miasta przez 29 zleceń

Lekki, bez złoczyńcy. Ślusarz przejmuje warsztat po mistrzu Henryku, razem z obtłuczoną tabliczką i zeszytem,
którego pierwsza strona mówi: „Najpierw zapytaj, czyje to. Potem patrz na zamek.” Miasto uczy się ufać ślusarzowi,
a ślusarz uczy się, że zaufanie buduje się odmową tak samo jak otwarciem.

| Rozdz. | Co się dzieje w mieście | Nitki postaci |
|---|---|---|
| 1 · Pierwsza zmiana | Pierwsze zlecenia z polecenia. Sąsiedzi ręczą, portier ręczy, kiosk ręczy. Pierwsza odmowa i pierwsze spotkanie z Leną Sową. | Halina, Zosia, Marta, Zuzanna, Edek, Stefan, Roman. Zeszyt: zasady 1–2. |
| 2 · Nocne dyżury | Stawki nocne, zmęczeni ludzie, pomyłki. Pan Roman zaczyna dzwonić do ślusarza pierwszy. Marta przynosi nową tabliczkę. Druga odmowa: Stefan przeprasza, że odesłał „garnitur” do warsztatu. | Roman, Edek (poleca Igę), Marta, Lena, Stefan. Zeszyt: zasada 3. |
| 3 · Strychy i spadki | Rodziny, pamięć, sprawiedliwość. Skrzynia dziadka Józefa otwiera wątek listów z Charleroi. Zosia poleca ślusarza pani Irenie. Trzecia odmowa. | Ola i Krystyna, Zosia, Lena. Zeszyt: zasada 5 (dyskrecja). |
| 4 · Małopolska | Wyjazd do korzeni zawodu. Zuzanna na praktyce przy bramie na Kazimierzu. Pan Władysław rozpoznaje pismo Henryka w zeszycie. Pan Leopold uczy częściowej odmowy. | Zuzanna, Władysław. Zeszyt zaczyna cytować „pana W.”. |
| 5 · Pociąg do Brukseli | Inny kraj, ta sama uczciwość. Karta ślusarza (kodeks). W Charleroi kasetka dziadka Józefa wraca do rodziny. To jedyne zlecenie, w którym obie strony chcą otwarcia. | Ola, Martine. Zeszyt: zasada 4 (wycena). |
| 6 · Skarbiec | Historia zamków w porcie i muzeum. Zuzanna na stażu u dr Rygiel. Finał pod kasztanowcem: kapsuła klasy 3b, w której była Marta. Na wycieraczce kartka od Haliny: „Rosół czeka”. | Rygiel, Zuzanna, Marta, Jadwiga, Halina. |

Kolejność zleceń w rozdziałach jest taka jak w `JOBS.md` §5. Nitki nie wymagają ścisłej kolejności: każda linia
z odwołaniem (Zuzanna w rozdz. 4 i 6, Edek w `drummer_locker`, Zosia w `widow_bureau`) ma sens także bez wcześniejszej sceny.

## 6. Głos zeszytu ślusarza

Zeszyt to dziennik warsztatowy, który gracz czyta po zleceniu i w Ustawieniach (zeszyt warsztatowy, `HUD.md`).
Wpis pojawia się jako odręczna animacja na rachunku (`job.<id>.note`).

**Zasady głosu:**
- Pierwsza osoba, czas przeszły, równoważniki zdań. Ton notatki fachowca, a nie pamiętnika.
- Struktura: **kto i gdzie → czym się wylegitymował → jeden ludzki szczegół**. Czasem także zapłata w naturze.
- Suchy humor wynika z faktów („Kot nie przeprosił.”), a nie z puenty na siłę.
- Nigdy: techniki otwierania, oceny klientów, opisu tego, co było w środku, poza tym, co klient sam pokazał
  (dyskrecja, `JOBS.md` §1.3 p. 7).
- Odmowy zapisuje tak samo krótko: „Nie otworzyłem. Zgłosiłem. Spałem dobrze.”

**Zasady z pierwszej strony** (`notebook.rule.*`, odblokowywane w kolejnych rozdziałach):
1. Najpierw zapytaj, czyje to. Potem patrz na zamek. *(Henryk, a wcześniej pan Władysław.)*
2. Jeden papier to poszlaka. Dwa to rozmowa. Sąsiad to pewność.
3. Kto płaci za brak pytań, płaci za nie swoje drzwi.
4. Wycena przed robotą. Rachunek bez niespodzianek.
5. Co widziałem w środku, zostaje w środku.

## 7. Uwagi dla sesji B

- **Klucze:** `job.<id>.line.<n>` (n od 1, kolejność wyświetlania), `job.<id>.note` (zeszyt),
  `job.<id>.after.<n>` (scena „dzień po”, tylko 4 zlecenia), `cast.<id>.name` (imię mówcy), `notebook.rule.<n>`,
  `notebook.refuse.line`. Format CSV taki sam jak w `content.csv`: nagłówek `keys,en,pl`, UTF-8, cudzysłowy RFC 4180.
- **Mówcy** nie są tekstem do tłumaczenia, więc są w Załączniku B jako dane do JSON-ów zleceń (`"lines": [...]`).
- **Do rozstrzygnięcia w danych (nie zmieniałem):**
  1. Dwie postacie o imieniu **Ola**: panna młoda w `job.newlyweds_4am` i nauczycielka w `job.grandpa_chest` /
     `job.charleroi_letters`. Proponuję zmienić pannę młodą na **Kasia** w `job.newlyweds_4am.client`. Linie tutaj
     jej nie nazywają (mówca `bride`).
  2. `job.drummer_locker.json` ma `"family": "unknown"`. Według `JOBS.md` to zamek rurkowy.
  3. `job.kiosk_shutter`: w `JOBS.md` scena mówi o „umowie dzierżawy”, a w danych o „liście z hurtowni”. Linie idą za danymi.
  4. Fragmenty w `JOBS.md` §5 („mObywatel”, „od Gierka”) łamią zasadę „bez nazw urzędów i aplikacji”. Linie tutaj ich nie używają.
- Linie z §8 **zastępują** robocze sceny z `JOBS.md` §5. Są krótsze, mieszczą się w limicie 90 znaków i trzymają się obsady stałej.

## 8. Dialogi zleceń (29)

Mówca w nawiasie to id z `cast.*`. Klucz linii: `job.<id>.line.<n>`.


### Rozdział 1 — Pierwsza zmiana


#### `job.grandma_broth` — Rosół na gazie / *Broth on the Stove*

| n | Mówca | PL | EN |
|---|---|---|---|
| 1 | halina | Synku, ja tylko na chwilkę wyszłam. Ze śmieciami. | I only stepped out for a moment, dear. With the rubbish. |
| 2 | zosia | Gaz zakręciłam na klatce. Czterdzieści lat mieszkamy przez ścianę. | I turned the gas off on the landing. Forty years we've lived wall to wall. |
| 3 | locksmith | To mi wystarczy za papiery. List w skrzynce też jest na panią? | That's as good as paperwork. And the letter in the mailbox is yours? |
| 4 | halina | Makaron sama robiłam. Talerz zostaje dla pana, nie dyskutujemy. | I made the noodles myself. There's a bowl for you, no arguing. |

**Zeszyt** (`job.grandma_broth.note`): Pani Halina, Śródmieście. Ręczy pani Zosia, 40 lat przez ścianę. Rosół w stanie „trochę wyparował”. Zjadłem.  
*Mrs Halina, Old Town. Mrs Zosia vouches: forty years through the wall. Broth status: slightly reduced. I ate it.*


#### `job.cat_bathroom` — Ziemniak w łazience / *Potato in the Bathroom*

| n | Mówca | PL | EN |
|---|---|---|---|
| 1 | marta | On to zrobił specjalnie. Patrzył mi w oczy, kiedy skakał na klamkę. | He did it on purpose. He looked me in the eye when he jumped on the handle. |
| 2 | locksmith | Pani jest u siebie, a on w łazience. Dokumentów tym razem nie trzeba. | You're in your own home, he's in the bathroom. No papers needed this time. |
| 3 | marta | A jak się przestraszy? | What if he gets scared? |
| 4 | locksmith | Niech pani do niego mówi. Ja będę cichszy od niego. | Keep talking to him. I'll be quieter than he is. |

**Zeszyt** (`job.cat_bathroom.note`): Ziemniak, kot. Weryfikacja: zbędna, klientka była w środku. Kot nie przeprosił. Marta obiecała mi nową tabliczkę.  
*Potato, cat. Check: not needed, the client was inside. The cat did not apologise. Marta promised me a new sign.*


#### `job.bike_interview` — Rozmowa o 9:30 / *Interview at 9:30*

| n | Mówca | PL | EN |
|---|---|---|---|
| 1 | kuba | Zmieniłem kod na bezpieczniejszy. Taki bezpieczny, że sam go nie znam. | I changed it to a safer code. So safe that even I don't know it. |
| 2 | locksmith | Rower stoi na ulicy. Ma pan coś, co mówi, że jest pana? | The bike's out on the street. Anything that says it's yours? |
| 3 | kuba | Zdjęcie z wakacji i paragon w mailu. Rower wyszedł na nim lepiej niż ja. | A holiday photo and the receipt in my email. The bike looks better than I do. |
| 4 | locksmith | Wystarczy. Niech pan w tym czasie poprawi krawat. | That'll do. Fix your tie while I work. |

**Zeszyt** (`job.bike_interview.note`): Kuba, kłódka rowerowa. Zdjęcie i paragon, rzecz w posiadaniu. Krawat poprawiony dwa razy. Autobus 8:52.  
*Kuba, bike padlock. Photo and receipt: it's in his hands. Tie straightened twice. Bus at 8:52.*


#### `job.student_dorm` — Pokój 412 / *Room 412*

| n | Mówca | PL | EN |
|---|---|---|---|
| 1 | zuzanna | Legitymacja jest w pokoju. Klucz też. Ja jestem na korytarzu. | My student card is in the room. So is the key. I'm in the corridor. |
| 2 | edek | Wilk Zuzanna, czterysta dwanaście. Mam na liście i mam w głowie. | Wilk, Zuzanna, four-twelve. It's on my list and in my head. |
| 3 | locksmith | Pan Edek ręczy, nazwisko się zgadza. Otwieramy. | Mr Edek vouches, the name matches. We're opening. |
| 4 | zuzanna | Jutro mam egzamin z zamków historycznych. To się liczy jako praktyka? | I've an exam on historical locks tomorrow. Does this count as practice? |

**Zeszyt** (`job.student_dorm.note`): Pokój 412, kampus. Portier z listą lokatorów: najlepszy dowód, jaki istnieje. Zuzanna pytała o wszystko.  
*Room 412, campus. A porter with a tenant list: the best proof there is. Zuzanna asked about everything.*


#### `job.kiosk_shutter` — Kiosk przed szóstą / *The Kiosk Before Six*

| n | Mówca | PL | EN |
|---|---|---|---|
| 1 | stefan | Trzydzieści dwa lata ta kłódka tu wisi. Ani razu jej nie oliwiłem. | Thirty-two years this padlock's hung here. Never oiled it once. |
| 2 | locksmith | Pani Krysia ręczy, list z hurtowni jest. Brakuje mi jeszcze jednej rzeczy. | Mrs Krysia vouches, the letter's here. I still need one more thing. |
| 3 | stefan | Zdjęcie z otwarcia, dziewięćdziesiąty czwarty. Wąsy miałem lepsze niż kiosk. | Opening day photo, ninety-four. My moustache was in better shape than the kiosk. |
| 4 | krysia | Stefan stoi tu dłużej niż przystanek. Autobus to potwierdzi. | Stefan's been here longer than the bus stop. The bus will back me up. |

**Zeszyt** (`job.kiosk_shutter.note`): Kiosk pana Stefana. Lokal firmy, więc dopytałem. Zdjęcie z 1994, wąsy autentyczne. Gazeta gratis do końca tygodnia.  
*Mr Stefan's kiosk. A business, so I asked for more. Photo from 1994, moustache genuine. Free paper all week.*


#### `job.refuse_ex_partner` — „To przecież też moje” / *"It's Half Mine Anyway"*

| n | Mówca | PL | EN |
|---|---|---|---|
| 1 | darek | Mieszkałem tu trzy lata. Mam prawo wejść po swoje rzeczy. | I lived here three years. I've a right to go in and get my things. |
| 2 | locksmith | Na skrzynce jest jedno nazwisko, nie pana. Zawołam administratora. | There's one name on the mailbox, and it isn't yours. I'll call the manager. |
| 3 | darek | Po co administrator? To prywatna sprawa. | Why the manager? This is a private matter. |
| 4 | locksmith | Tu nie otworzę. Policja pomaga odebrać rzeczy, spokojnie. Zadzwonić? | I can't open this one. The police can help you collect your things. Shall I call? |

**Zeszyt** (`job.refuse_ex_partner.note`): Nie otworzyłem. Jedno nazwisko na drzwiach i to nie jego. Przekazałem sprawę aspirant Sowie. Nie żałuję.  
*Didn't open. One name on the door, not his. Passed it to Officer Sowa. No regrets.*

**Dzień po** (`job.refuse_ex_partner.after.n`):

- 1. (lena) Dobrze, że pan zadzwonił. Rzeczy odebrał przy mnie, lokatorka się zgodziła. / *Good that you called. He collected his things with me there; the tenant agreed.*
- 2. (stefan) Słyszałem na przystanku. Porządny z pana człowiek. Gazeta? / *Heard it at the bus stop. You're a decent sort. Paper?*


### Rozdział 2 — Nocne dyżury


#### `job.newlyweds_4am` — Czwarta nad ranem po weselu / *4 a.m., After the Wedding*

| n | Mówca | PL | EN |
|---|---|---|---|
| 1 | bartek | Dowód mam, ale adresu na nim nie ma. Wiem, wiem. Teraz nikt nie ma. | I've got ID, but there's no address on it. I know. Nobody's has one now. |
| 2 | bride | Meldunek mam w aplikacji. Tu, widzi pan? Z welonem trudno celować. | My registered address is in the app. See? Hard to aim with a veil on. |
| 3 | neighbour_robe | Znam ich. Pobrali się dziś. Całe osiedle słyszało oczepiny. | I know them. They got married today. The whole estate heard the party. |
| 4 | locksmith | Wszystkiego najlepszego. Dwie minuty i jesteście w domu. | Congratulations. Two minutes and you're home. |

**Zeszyt** (`job.newlyweds_4am.note`): Nowożeńcy, 4:12. Dowód bez adresu to norma, dlatego meldunek i sąsiad w szlafroku. Tort trzypiętrowy, wziąłem kawałek.  
*Newlyweds, 4:12 a.m. ID without an address is normal, hence the app and a neighbour in a robe. Three-tier cake. I took a slice.*


#### `job.pizzeria_pays_pizza` — Zapłata w pizzy / *Paid in Pizza*

| n | Mówca | PL | EN |
|---|---|---|---|
| 1 | renata | Utarg jest w kasie, kasa w środku. Płacę w pizzy. Ile pan zje? | The takings are in the till, the till's inside. I'll pay in pizza. How hungry are you? |
| 2 | locksmith | Najpierw wycena, potem menu. Umowa najmu lokalu jest? | Quote first, menu second. Do you have the lease? |
| 3 | mietek | Znam ją dwadzieścia lat, kebab mam przez ścianę. Jej margherita to sztuka. | Known her twenty years, my kebab shop's next door. Her margherita is art. |
| 4 | renata | Ciasto rośnie, ja maleję. Byle przed świtem. | The dough is rising, I'm sinking. Any time before dawn. |

**Zeszyt** (`job.pizzeria_pays_pizza.note`): Pizzeria „U Renaty”. Umowa najmu i sąsiad z lokalu obok. Zapłata: margherita. Pudełko stoi na półce.  
*Renata's pizzeria. Lease plus the neighbour next door. Paid in margherita. The box is on my shelf.*


#### `job.night_nurse` — Po dwunastu godzinach / *After a Twelve-Hour Shift*

| n | Mówca | PL | EN |
|---|---|---|---|
| 1 | agnieszka | Dwanaście godzin na oddziale. Klucz został w szafce w szpitalu. | Twelve hours on the ward. My key's in my locker at the hospital. |
| 2 | roman | Pani Agnieszka spod czternastki, zgadza się. Umowę mam w systemie. | Mrs Agnieszka, flat fourteen, that's right. Her lease is on my system. |
| 3 | locksmith | Administrator potwierdza, dowód się zgadza. Zaraz pani śpi. | The manager confirms, the ID matches. You'll be asleep in no time. |
| 4 | agnieszka | Przepraszam, że nie rozmawiam. Ja już mówię przez sen. | Sorry I'm not chatty. I'm talking in my sleep already. |

**Zeszyt** (`job.night_nurse.note`): Pani Agnieszka, po nocce. Pan Roman przez domofon, sprawnie jak zawsze. Rabat sąsiedzki, bez dyskusji.  
*Mrs Agnieszka, after a night shift. Mr Roman on the intercom, efficient as ever. Neighbour discount, no question.*


#### `job.wrong_floor` — Piętro niżej / *One Floor Down*

| n | Mówca | PL | EN |
|---|---|---|---|
| 1 | kazimierz | Klucz nie wchodzi. Zamek się zepsuł, jak mnie nie było. | The key won't go in. The lock broke while I was out. |
| 2 | locksmith | Panie Kazimierzu, na skrzynce jest inne nazwisko. I ten wieniec? | Mr Kazimierz, there's another name on the mailbox. And this wreath? |
| 3 | teresa | Kto tam? Mieszkam tu dwanaście lat. Wieniec sama wiłam. | Who's there? I've lived here twelve years. I made that wreath myself. |
| 4 | kazimierz | O, piętro wyżej klucz wchodzi. Naprawił pan. | Oh, one floor up the key fits. You've fixed it. |

**Zeszyt** (`job.wrong_floor.note`): Pan Kazimierz po imieninach. Drzwi piętro niżej. Nic nie otwierałem, a i tak się udało. Najlepsza robota tygodnia.  
*Mr Kazimierz after a name-day party. Wrong floor. I opened nothing and it still worked. Best job of the week.*

**Dzień po** (`job.wrong_floor.after.n`):

- 1. (teresa) To pan wczoraj nie otworzył? Upiekłam drożdżowe. Za to, że pan nie otworzył. / *You're the one who didn't open my door? I baked you a cake. For not opening it.*


#### `job.refuse_rush_bribe` — „Siostra kazała” / *"My Sister Said It's Fine"*

| n | Mówca | PL | EN |
|---|---|---|---|
| 1 | stranger | Podwójna stawka. Potrójna. Tylko bez tych wszystkich procedur. | Double the rate. Triple. Just skip all the procedures. |
| 2 | locksmith | Procedur nie da się dopłacić. Proszę zadzwonić do siostry, poczekam. | Procedures aren't for sale. Call your sister, I'll wait. |
| 3 | stranger | Nie odbiera. Sąsiadów nie budźmy, po co ten cyrk. | She's not answering. Let's not wake the neighbours, no need for a circus. |
| 4 | locksmith | To dobranoc. A dla porządku dam znać dzielnicowej. | Then good night. And for the record, I'll let the local officer know. |

**Zeszyt** (`job.refuse_rush_bribe.note`): 1:00, garnitur, pośpiech, dopłata zamiast sąsiada. Nie otworzyłem. Zgłosiłem. Spałem dobrze.  
*1 a.m., a suit, a rush, cash instead of a witness. Didn't open. Reported it. Slept well.*

**Dzień po** (`job.refuse_rush_bribe.after.n`):

- 1. (lena) Siostra nic nie wiedziała o żadnych dokumentach. Dziękuję za telefon. / *The sister knew nothing about any documents. Thank you for the call.*
- 2. (stefan) Ktoś w garniturze pytał wczoraj o ślusarza. Odesłałem go do pana. Przepraszam. / *Someone in a suit asked about a locksmith yesterday. I sent him to you. Sorry.*


#### `job.drummer_locker` — Pałki w szafce / *Drumsticks in the Locker*

| n | Mówca | PL | EN |
|---|---|---|---|
| 1 | iga | Mogę zagrać łyżkami, ale wolałabym nie. Koncert za godzinę. | I could play with spoons, but I'd rather not. Gig's in an hour. |
| 2 | hall_manager | Szafka numer osiem, Iga płaci co miesiąc. Mam w zeszycie. | Locker eight, Iga pays monthly. It's in my notebook. |
| 3 | locksmith | Zeszyt mi wystarczy. Pan Edek mówił, że u pana wszystko jest zapisane. | Your notebook will do. Mr Edek said you write everything down. |
| 4 | iga | Jak pan zdąży, gramy numer dla pana. Głośno. | If you make it in time, we'll play one for you. Loudly. |

**Zeszyt** (`job.drummer_locker.note`): Szafka nr 8, sala prób. Kierownik ma zeszyt jak ja. Szanuję. Zagrali dla mnie numer, było głośno.  
*Locker 8, rehearsal room. The manager keeps a notebook like mine. Respect. They played me a song. It was loud.*


### Rozdział 3 — Strychy i spadki


#### `job.grandpa_chest` — Skrzynia dziadka Józefa / *Grandpa Józef's Chest*

| n | Mówca | PL | EN |
|---|---|---|---|
| 1 | krystyna | Tato nigdy nie mówił, co tam trzyma. Nawet nam. | Dad never said what he kept in there. Not even to us. |
| 2 | ola | Mamo, pan nie pyta o skrzynię. Pyta, czy dom jest twój. | Mum, he's not asking about the chest. He's asking if the house is yours. |
| 3 | krystyna | Mój. Akt notarialny leży w kredensie, pod obrusem. | It's mine. The deed is in the dresser, under the tablecloth. |
| 4 | ola | Listy. Z Charleroi. Do babci, po polsku, z belgijskimi znaczkami. | Letters. From Charleroi. To Grandma, in Polish, with Belgian stamps. |

**Zeszyt** (`job.grandpa_chest.note`): Skrzynia dziadka Józefa. Akt pod obrusem, tam gdzie zawsze. W środku listy z Belgii. Ola mówi, że pojedzie.  
*Grandpa Józef's chest. Deed under the tablecloth, where they always are. Letters from Belgium inside. Ola says she'll go.*


#### `job.uncle_safe_heirs` — Sejf wujka Bogdana / *Uncle Bogdan's Safe*

| n | Mówca | PL | EN |
|---|---|---|---|
| 1 | marek | Pan otworzy, ja popatrzę i powiem reszcie. Przecież się podzielimy. | You open it, I'll have a look and tell the others. We'll share anyway. |
| 2 | locksmith | Otworzę, gdy będą wszyscy spadkobiercy albo ich zgoda na piśmie. | I'll open it when all the heirs are here, or their consent is in writing. |
| 3 | piotr | Ewa będzie za godzinę. Marek, nastaw wodę. | Ewa's an hour away. Marek, put the kettle on. |
| 4 | ewa | Wujek by się śmiał, że się kłócimy o pudło z tarczą. | Uncle would laugh to see us fight over a box with a dial. |

**Zeszyt** (`job.uncle_safe_heirs.note`): Sejf wujka Bogdana. Czekaliśmy na Ewę, godzina i trzy herbaty. Otwarte przy wszystkich. Nikt się nie obraził.  
*Uncle Bogdan's safe. We waited for Ewa: an hour and three teas. Opened in front of everyone. Nobody sulked.*


#### `job.dollhouse_wooden_lock` — Domek pradziadka / *Great-Grandpa's Dollhouse*

| n | Mówca | PL | EN |
|---|---|---|---|
| 1 | hania | Lala siedzi tam od wtorku. Ona się nudzi. | Lala's been stuck in there since Tuesday. She's bored. |
| 2 | tomasz | Dziadek mówił, że to zamek egipski. Nie wiem, ile w tym prawdy. | Grandpa called it an Egyptian lock. I'm not sure how true that is. |
| 3 | locksmith | Taka nazwa się przyjęła. Prawdziwa historia jest lepsza. Opowiem po robocie. | That's the name that stuck. The real story's better. I'll tell you after. |
| 4 | hania | A zrobi pan nowy klucz? Drewniany? Tata ma deskę. | Will you make a new key? A wooden one? Dad has a plank. |

**Zeszyt** (`job.dollhouse_wooden_lock.note`): Domek pradziadka. Zamek drewniany na kołki. Lala uwolniona. Tomasz wystruga nowy klucz, Hania nadzoruje.  
*Great-grandpa's dollhouse. Wooden pin lock. Lala released. Tomasz will carve a new key, Hania supervises.*


#### `job.allotment_shed` — Altana pana Zbyszka / *Mr Zbyszek's Shed*

| n | Mówca | PL | EN |
|---|---|---|---|
| 1 | zbyszek | Działka jest na żonę, ale kopię ja. Żona siedzi w domu z kolanem. | The plot's in my wife's name, but I do the digging. She's home with her knee. |
| 2 | locksmith | Legitymacja działkowca jest? I ktoś z sąsiedniej działki? | Got your allotment card? And someone from the next plot? |
| 3 | waldek | Zbyszek tu jest dłużej niż ta altana. I dłużej niż ja. | Zbyszek's been here longer than that shed. Longer than me. |
| 4 | zbyszek | Ogórki pan weźmie? Na działkę pieniędzy nie noszę. | Will you take cucumbers? I don't bring money to the allotment. |

**Zeszyt** (`job.allotment_shed.note`): Altana pana Zbyszka. Inne nazwisko w umowie: żona. Zgrzyt wyjaśniony. Zapłata: słoik ogórków.  
*Mr Zbyszek's shed. Different name on the lease: his wife. Mystery solved. Paid in a jar of pickles.*


#### `job.widow_bureau` — Sekretarzyk / *The Writing Desk*

| n | Mówca | PL | EN |
|---|---|---|---|
| 1 | irena | Pani Zosia mówiła, że pan nie wierci. Mąż nie znosił wiercenia. | Mrs Zosia said you don't drill. My husband couldn't stand drilling. |
| 2 | locksmith | Otworzę tak, że nikt nie pozna. Mebel zostanie jego. | I'll open it so no one can tell. It stays his desk. |
| 3 | irena | Bilety do opery. Osiemdziesiąty siódmy. | Opera tickets. Nineteen eighty-seven. |
| 4 | irena | Mówił, że je zgubił. Trzymał je. | He told me he'd lost them. He kept them. |

**Zeszyt** (`job.widow_bureau.note`): Pani Irena, z polecenia pani Zosi. Sekretarzyk w jej domu, bez śladów. W środku bilety. Nie dopytywałem.  
*Mrs Irena, sent by Mrs Zosia. The bureau is in her home; no marks left. Tickets inside. I didn't ask.*


#### `job.refuse_aunt_alive` — Ciotka, która ma się dobrze / *The Aunt Who's Doing Fine*

| n | Mówca | PL | EN |
|---|---|---|---|
| 1 | claimant | Ciocia zmarła w zeszłym tygodniu. Papiery są w trakcie, to dopiero co. | Auntie passed away last week. The papers are in progress, it's so recent. |
| 2 | neighbour_lucyna | Pani Lucyna? Jest w sanatorium. Wczoraj dzwoniła, że jej lepiej. | Mrs Lucyna? She's at a health resort. She rang yesterday, she's feeling better. |
| 3 | claimant | Musiałam coś pomylić. | I must have got something mixed up. |
| 4 | locksmith | To zadzwońmy do pani Lucyny razem. A potem do aspirant Sowy. | Then let's ring Mrs Lucyna together. And then Officer Sowa. |

**Zeszyt** (`job.refuse_aunt_alive.note`): Ciotka, która ma się dobrze. Sąsiadka wyszła na klatkę w porę. Pani Lucyna przesyła pozdrowienia z sanatorium.  
*The aunt who is doing fine. The neighbour stepped out just in time. Mrs Lucyna sends regards from her resort.*

**Dzień po** (`job.refuse_aunt_alive.after.n`):

- 1. (lena) Pani Lucyna wraca w piątek. Zamek wymieni sama, z pana pomocą. / *Mrs Lucyna is back on Friday. She'll have the lock changed, with your help.*
- 2. (neighbour_lucyna) Dobrze, że pan odmówił. Ja bym nie spała. / *Good thing you said no. I wouldn't have slept a wink.*


### Rozdział 4 — Małopolska


#### `job.krakow_tenement_gate` — Brama na Kazimierzu / *The Gate in Kazimierz*

| n | Mówca | PL | EN |
|---|---|---|---|
| 1 | wanda | Konserwator powiedział: ani jednej dziury. Ani jednej. | The conservator said: not a single hole. Not one. |
| 2 | locksmith | Słusznie. Ktoś się tu sto trzydzieści lat temu napracował. | Quite right. Somebody worked hard on this a hundred and thirty years ago. |
| 3 | zuzanna | Dzień dobry. Mam tu praktykę. Egzamin zdałam, pokój 412 pomógł. | Hello again. I'm interning here. I passed that exam. Room 412 helped. |
| 4 | wanda | Uchwała wspólnoty i zlecenie na piśmie. Proszę. | The residents' resolution and a written order. Here you are. |

**Zeszyt** (`job.krakow_tenement_gate.note`): Brama na Kazimierzu. Pierwsza uchwała wspólnoty w mojej karierze, chyba ją oprawię. Zuzanna robi notatki szybciej ode mnie.  
*A gate in Kazimierz. My first residents' resolution, I might frame it. Zuzanna takes notes faster than I do.*


#### `job.swiatniki_journeyman_padlock` — Kłódka czeladnicza pana Władysława / *Mr Władysław's Journeyman Padlock*

| n | Mówca | PL | EN |
|---|---|---|---|
| 1 | wladyslaw | Siedemdziesiąt lat ją trzymam. Klucz był jeden. Wnuk go zgubił. | I've kept it seventy years. There was one key. My grandson lost it. |
| 2 | locksmith | A pan wie, jak ją otworzyć? | And you know how to open it? |
| 3 | wladyslaw | Wiem. Ale chcę zobaczyć, czy młodzi jeszcze umieją. | I do. But I want to see if the young ones still can. |
| 4 | wladyslaw | To pismo w zeszycie znam. Henryk. Uczyłem go. Dobrze trafił ten zeszyt. | I know the handwriting in that notebook. Henryk. I taught him. It found the right hands. |

**Zeszyt** (`job.swiatniki_journeyman_padlock.note`): Pan Władysław, Świątniki. Rozpoznał pismo Henryka w moim zeszycie. Pierwszej zasady to on nauczył Henryka.  
*Mr Władysław, Świątniki. He knew Henryk's hand in my notebook. He taught Henryk that first rule.*


#### `job.krakow_antiquarian` — Kasa antykwariusza / *The Antiquarian's Strongbox*

| n | Mówca | PL | EN |
|---|---|---|---|
| 1 | leopold | Kasa moja, najem mam od miasta, pani z kawiarni obok potwierdzi. | The safe's mine, I rent from the city, the café lady next door will confirm. |
| 2 | leopold | A przy okazji ta kasetka. Klient zostawił ją do wyceny. | And while you're at it, this little box. A customer left it for valuation. |
| 3 | locksmith | Kasę otworzę. Kasetki nie. Niech właściciel przyjdzie sam. | The safe, yes. The box, no. Let its owner come in person. |
| 4 | leopold | Ma pan rację. Starzeję się i robię się niecierpliwy. | You're right. I'm getting old, and impatient with it. |

**Zeszyt** (`job.krakow_antiquarian.note`): Pan Leopold. Kasa jego, kasetka nie. Jedno zlecenie, dwie decyzje. W zamian opowieść o cechu.  
*Mr Leopold. The safe is his, the box is not. One job, two decisions. Paid extra in guild stories.*


### Rozdział 5 — Pociąg do Brukseli


#### `job.brussels_townhouse` — Kamienica w Saint-Gilles / *A Townhouse in Saint-Gilles*

| n | Mówca | PL | EN |
|---|---|---|---|
| 1 | magda | Stoję na balkonie jak Julia. Tylko Romeo ma sześćdziesiąt lat i klucz od bramy. | I'm on the balcony like Juliet. Only Romeo is sixty and has the gate key. |
| 2 | jacques | Madame Magda mieszka tu od zawsze. Depuis toujours. | Madame Magda has lived here forever. Depuis toujours. |
| 3 | locksmith | Umowa najmu, adres z gminy i sąsiad. Komplet. Proszę się nie wychylać. | Lease, address from the commune and a neighbour. That's the set. Don't lean out. |
| 4 | magda | Pelargonie podlane. To był cel misji. | The geraniums are watered. That was the mission. |

**Zeszyt** (`job.brussels_townhouse.note`): Saint-Gilles. Inny kraj, ta sama zasada. Umowa, gmina, monsieur Jacques. Pelargonie mają się dobrze.  
*Saint-Gilles. Different country, same rule. Lease, commune, Monsieur Jacques. The geraniums are fine.*


#### `job.ghent_beguinage` — Drzwi w beginażu / *A Door in the Béguinage*

| n | Mówca | PL | EN |
|---|---|---|---|
| 1 | pieter | Po polsku umiem tylko „dzień dobry” i „pierogi”. | In Polish I only know "dzień dobry" and "pierogi". |
| 2 | locksmith | To już połowa języka. | That's half the language. |
| 3 | pieter | Pismo od rady parafii. Klucz poszedł z poprzednim opiekunem do nieba. | A letter from the parish council. The key went to heaven with my predecessor. |
| 4 | locksmith | Bez śladów, obiecuję. Ten zamek jest starszy niż moja kamienica. | No marks, I promise. This lock is older than my building. |

**Zeszyt** (`job.ghent_beguinage.note`): Beginaż w Gandawie. Pismo instytucji i opiekun. Bez śladów, jak obiecałem. Brat Pieter umie już „rosół”.  
*Ghent béguinage. A letter from the institution and its caretaker. No marks, as promised. Brother Pieter now knows "rosół".*


#### `job.liege_bakery` — Piekarnia o czwartej / *The Bakery at Four*

| n | Mówca | PL | EN |
|---|---|---|---|
| 1 | nadia | Wujek miał trzydzieści kluczy i żadnego nie podpisał. | My uncle had thirty keys and labelled none of them. |
| 2 | locksmith | Zamek wyczuł obcy klucz i się obraził. Taki ma zawód. | The lock felt a stranger's key and took offence. That's its job. |
| 3 | nadia | Papiery przejęcia i umowa najmu. Ciasto rośnie bez pozwolenia. | Handover papers and the lease. The dough rises without permission. |
| 4 | locksmith | Papiery wystarczą. Gofry o szóstej będą. | The papers will do. Waffles at six, as promised. |

**Zeszyt** (`job.liege_bakery.note`): Liège, 3:50. Zamek z detektorem miał rację, że się zablokował. Papiery przejęcia w porządku. Gofr z perłowym cukrem.  
*Liège, 3:50 a.m. The detector lock was right to lock up. Handover papers in order. One pearl-sugar waffle.*


#### `job.charleroi_letters` — Adres z listów dziadka / *The Address in Grandpa's Letters*

| n | Mówca | PL | EN |
|---|---|---|---|
| 1 | ola | Nie dzwonię po otwarcie, tylko po radę. Pani Martine ma kasetkę dziadka. | I'm not calling for an opening, just advice. Mrs Martine has Grandpa's box. |
| 2 | martine | C'est à votre famille. Ja tylko pilnowałam. | C'est à votre famille. I only looked after it. |
| 3 | ola | Pani pilnowała przez siedemdziesiąt lat? | You looked after it for seventy years? |
| 4 | locksmith | Obie chcecie, żeby się otworzyła. Najprostsza weryfikacja w mojej karierze. | You both want it open. Easiest check of my career. |

**Zeszyt** (`job.charleroi_letters.note`): Charleroi. Kasetka dziadka Józefa u pani Martine. Obie strony chciały otwarcia. Pierwszy raz płakałem w pracy. Trochę.  
*Charleroi. Grandpa Józef's box, kept by Mrs Martine. Both sides wanted it open. First time I cried on a job. A little.*


### Rozdział 6 — Skarbiec


#### `job.museum_time_lock` — Zegar, który pilnuje skarbca / *The Clock That Guards the Vault*

| n | Mówca | PL | EN |
|---|---|---|---|
| 1 | rygiel | Tu nie chodzi o szyfr. Tu chodzi o czas. | It's not about the combination. It's about time. |
| 2 | locksmith | Zamek czasowy nie pyta, kto przyszedł. Pyta, która godzina. | A time lock doesn't ask who's there. It asks what time it is. |
| 3 | rygiel | Pismo dyrekcji, protokół przekazania. Wszystko w trzech egzemplarzach. | Director's letter, transfer protocol. All in triplicate. |
| 4 | zuzanna | Pani doktor, rękawiczki dla pana ślusarza też są. Rozmiar L. | Doctor, there are gloves for the locksmith too. Size L. |

**Zeszyt** (`job.museum_time_lock.note`): Muzeum Techniki. Dr Rygiel, trzy egzemplarze wszystkiego. Zegar przekonany. Zuzanna jest tu na stażu, oczywiście.  
*Museum of Technology. Dr Rygiel, triplicate everything. The clock was persuaded. Zuzanna interns here, of course.*


#### `job.bramah_bureau` — Angielski sekretarzyk / *The English Bureau*

| n | Mówca | PL | EN |
|---|---|---|---|
| 1 | gosia | Faktura z aukcji, opis i zdjęcia. Zamek ma zostać nietknięty. | Auction invoice, listing and photos. The lock stays untouched. |
| 2 | locksmith | Taki zamek wisiał kiedyś w oknie sklepu w Londynie. Z nagrodą. | A lock like this once hung in a London shop window. With a reward. |
| 3 | gosia | I ktoś go otworzył? | Did anyone open it? |
| 4 | locksmith | Po ponad sześćdziesięciu latach. Opowiem, jak skończę. | After more than sixty years. I'll tell you when I'm done. |

**Zeszyt** (`job.bramah_bureau.note`): Sekretarzyk pani Gosi. Faktura i posiadanie. Zamek zostaje oryginalny. Opowiedziałem jej o oknie przy Piccadilly.  
*Gosia's bureau. Invoice and possession. The lock stays original. I told her about the Piccadilly window.*


#### `job.finnish_sailor` — Skrzynia marynarza / *The Sailor's Sea Chest*

| n | Mówca | PL | EN |
|---|---|---|---|
| 1 | aino | W Finlandii każdy ma taką kłódkę. Bez klucza nikt jej nie otworzy. | In Finland everyone has a padlock like this. Nobody opens it without the key. |
| 2 | captain | Skrzynia jest Aino, ręczę. Odpływamy jutro o szóstej. | The chest is Aino's, I vouch for her. We sail at six tomorrow. |
| 3 | locksmith | Kapitan ręczy, książeczka żeglarska się zgadza. To zobaczymy. | The captain vouches, the seaman's book matches. Let's see, then. |
| 4 | aino | Jeśli pan otworzy, opowiem, skąd ten wynalazek. | If you open it, I'll tell you where this invention came from. |

**Zeszyt** (`job.finnish_sailor.note`): Aino, statek z Finlandii. Kapitan i książeczka. Zdążyliśmy przed szóstą. Chochla z brzozy wisi nad warsztatem.  
*Aino, a Finnish ship. Captain and seaman's book. Done before six. A birch cup now hangs over my bench.*


#### `job.time_capsule` — Kapsuła czasu klasy 3b / *Class 3b's Time Capsule*

| n | Mówca | PL | EN |
|---|---|---|---|
| 1 | jadwiga | Wiem, że kodem była jakaś data. Tylko czyja? | I know the code was a date. But whose? |
| 2 | headteacher | Szkoła się zgadza. Proszę otwierać, przy wszystkich. | The school agrees. Please open it, in front of everyone. |
| 3 | marta | Pani Jadwigo, my mieliśmy wtedy dziewięć lat. Pamiętam tylko kasztany. | Miss, we were nine. All I remember is conkers. |
| 4 | marta | Mój list: „Mam nadzieję, że masz psa”. Mam kota. Też się liczy. | My letter: "I hope you have a dog." I have a cat. That counts. |

**Zeszyt** (`job.time_capsule.note`): Klasa 3b, kasztanowiec. Dyrekcja i dwudziestu świadków. Marta była w tej klasie. Na wycieraczce kartka: „Rosół czeka”.  
*Class 3b, the chestnut tree. The school and twenty witnesses. Marta was in that class. A card on my doormat: "Broth's waiting."*


---

## Załącznik A — blok CSV dla `game/i18n/content.csv`

207 wierszy. Nagłówek `keys,en,pl` jest tu tylko dla porządku: przy wklejaniu do istniejącego pliku pomiń pierwszą linię. Klucze nie kolidują z obecnymi (`content.csv` nie ma jeszcze `*.line.*`, `*.note`, `cast.*`, `notebook.*`).

```csv
keys,en,pl
cast.agnieszka.name,Agnieszka,Agnieszka
cast.aino.name,Aino,Aino
cast.bartek.name,Bartek,Bartek
cast.bride.name,The bride,Panna młoda
cast.captain.name,Captain,Kapitan
cast.claimant.name,Woman at the door,Kobieta przy drzwiach
cast.darek.name,Darek,Darek
cast.edek.name,"Mr Edek, porter","Pan Edek, portier"
cast.ewa.name,Ewa,Ewa
cast.gosia.name,Gosia,Gosia
cast.halina.name,Mrs Halina,Pani Halina
cast.hall_manager.name,Rehearsal room manager,Kierownik sali
cast.hania.name,Hania,Hania
cast.headteacher.name,Headteacher,Dyrektorka szkoły
cast.iga.name,Iga,Iga
cast.irena.name,Mrs Irena,Pani Irena
cast.jacques.name,Monsieur Jacques,Monsieur Jacques
cast.jadwiga.name,Mrs Jadwiga,Pani Jadwiga
cast.kazimierz.name,Mr Kazimierz,Pan Kazimierz
cast.krysia.name,Mrs Krysia,Pani Krysia
cast.krystyna.name,Mrs Krystyna,Pani Krystyna
cast.kuba.name,Kuba,Kuba
cast.lena.name,Officer Lena Sowa,Aspirant Lena Sowa
cast.leopold.name,Mr Leopold,Pan Leopold
cast.locksmith.name,Locksmith,Ślusarz
cast.magda.name,Magda,Magda
cast.marek.name,Marek,Marek
cast.marta.name,Marta,Marta
cast.martine.name,Madame Martine,Pani Martine
cast.mietek.name,Mr Mietek,Pan Mietek
cast.nadia.name,Nadia,Nadia
cast.neighbour_lucyna.name,Mrs Lucyna's neighbour,Sąsiadka pani Lucyny
cast.neighbour_robe.name,Neighbour in a robe,Sąsiad w szlafroku
cast.ola.name,Ola,Ola
cast.pieter.name,Brother Pieter,Brat Pieter
cast.piotr.name,Piotr,Piotr
cast.renata.name,Mrs Renata,Pani Renata
cast.roman.name,"Mr Roman, building manager","Pan Roman, administrator"
cast.rygiel.name,Dr Anna Rygiel,Dr Anna Rygiel
cast.stefan.name,Mr Stefan,Pan Stefan
cast.stranger.name,Man in a suit,Mężczyzna w garniturze
cast.teresa.name,Mrs Teresa,Pani Teresa
cast.tomasz.name,Tomasz,Tomasz
cast.waldek.name,Mr Waldek,Pan Waldek
cast.wanda.name,Mrs Wanda,Pani Wanda
cast.wladyslaw.name,Mr Władysław,Pan Władysław
cast.zbyszek.name,Mr Zbyszek,Pan Zbyszek
cast.zosia.name,Mrs Zosia,Pani Zosia
cast.zuzanna.name,Zuzanna,Zuzanna
job.allotment_shed.line.1,"The plot's in my wife's name, but I do the digging. She's home with her knee.","Działka jest na żonę, ale kopię ja. Żona siedzi w domu z kolanem."
job.allotment_shed.line.2,Got your allotment card? And someone from the next plot?,Legitymacja działkowca jest? I ktoś z sąsiedniej działki?
job.allotment_shed.line.3,Zbyszek's been here longer than that shed. Longer than me.,Zbyszek tu jest dłużej niż ta altana. I dłużej niż ja.
job.allotment_shed.line.4,Will you take cucumbers? I don't bring money to the allotment.,Ogórki pan weźmie? Na działkę pieniędzy nie noszę.
job.allotment_shed.note,Mr Zbyszek's shed. Different name on the lease: his wife. Mystery solved. Paid in a jar of pickles.,Altana pana Zbyszka. Inne nazwisko w umowie: żona. Zgrzyt wyjaśniony. Zapłata: słoik ogórków.
job.bike_interview.line.1,I changed it to a safer code. So safe that even I don't know it.,"Zmieniłem kod na bezpieczniejszy. Taki bezpieczny, że sam go nie znam."
job.bike_interview.line.2,The bike's out on the street. Anything that says it's yours?,"Rower stoi na ulicy. Ma pan coś, co mówi, że jest pana?"
job.bike_interview.line.3,A holiday photo and the receipt in my email. The bike looks better than I do.,Zdjęcie z wakacji i paragon w mailu. Rower wyszedł na nim lepiej niż ja.
job.bike_interview.line.4,That'll do. Fix your tie while I work.,Wystarczy. Niech pan w tym czasie poprawi krawat.
job.bike_interview.note,"Kuba, bike padlock. Photo and receipt: it's in his hands. Tie straightened twice. Bus at 8:52.","Kuba, kłódka rowerowa. Zdjęcie i paragon, rzecz w posiadaniu. Krawat poprawiony dwa razy. Autobus 8:52."
job.bramah_bureau.line.1,"Auction invoice, listing and photos. The lock stays untouched.","Faktura z aukcji, opis i zdjęcia. Zamek ma zostać nietknięty."
job.bramah_bureau.line.2,A lock like this once hung in a London shop window. With a reward.,Taki zamek wisiał kiedyś w oknie sklepu w Londynie. Z nagrodą.
job.bramah_bureau.line.3,Did anyone open it?,I ktoś go otworzył?
job.bramah_bureau.line.4,After more than sixty years. I'll tell you when I'm done.,"Po ponad sześćdziesięciu latach. Opowiem, jak skończę."
job.bramah_bureau.note,Gosia's bureau. Invoice and possession. The lock stays original. I told her about the Piccadilly window.,Sekretarzyk pani Gosi. Faktura i posiadanie. Zamek zostaje oryginalny. Opowiedziałem jej o oknie przy Piccadilly.
job.brussels_townhouse.line.1,I'm on the balcony like Juliet. Only Romeo is sixty and has the gate key.,Stoję na balkonie jak Julia. Tylko Romeo ma sześćdziesiąt lat i klucz od bramy.
job.brussels_townhouse.line.2,Madame Magda has lived here forever. Depuis toujours.,Madame Magda mieszka tu od zawsze. Depuis toujours.
job.brussels_townhouse.line.3,"Lease, address from the commune and a neighbour. That's the set. Don't lean out.","Umowa najmu, adres z gminy i sąsiad. Komplet. Proszę się nie wychylać."
job.brussels_townhouse.line.4,The geraniums are watered. That was the mission.,Pelargonie podlane. To był cel misji.
job.brussels_townhouse.note,"Saint-Gilles. Different country, same rule. Lease, commune, Monsieur Jacques. The geraniums are fine.","Saint-Gilles. Inny kraj, ta sama zasada. Umowa, gmina, monsieur Jacques. Pelargonie mają się dobrze."
job.cat_bathroom.line.1,He did it on purpose. He looked me in the eye when he jumped on the handle.,"On to zrobił specjalnie. Patrzył mi w oczy, kiedy skakał na klamkę."
job.cat_bathroom.line.2,"You're in your own home, he's in the bathroom. No papers needed this time.","Pani jest u siebie, a on w łazience. Dokumentów tym razem nie trzeba."
job.cat_bathroom.line.3,What if he gets scared?,A jak się przestraszy?
job.cat_bathroom.line.4,Keep talking to him. I'll be quieter than he is.,Niech pani do niego mówi. Ja będę cichszy od niego.
job.cat_bathroom.note,"Potato, cat. Check: not needed, the client was inside. The cat did not apologise. Marta promised me a new sign.","Ziemniak, kot. Weryfikacja: zbędna, klientka była w środku. Kot nie przeprosił. Marta obiecała mi nową tabliczkę."
job.charleroi_letters.line.1,"I'm not calling for an opening, just advice. Mrs Martine has Grandpa's box.","Nie dzwonię po otwarcie, tylko po radę. Pani Martine ma kasetkę dziadka."
job.charleroi_letters.line.2,C'est à votre famille. I only looked after it.,C'est à votre famille. Ja tylko pilnowałam.
job.charleroi_letters.line.3,You looked after it for seventy years?,Pani pilnowała przez siedemdziesiąt lat?
job.charleroi_letters.line.4,You both want it open. Easiest check of my career.,"Obie chcecie, żeby się otworzyła. Najprostsza weryfikacja w mojej karierze."
job.charleroi_letters.note,"Charleroi. Grandpa Józef's box, kept by Mrs Martine. Both sides wanted it open. First time I cried on a job. A little.",Charleroi. Kasetka dziadka Józefa u pani Martine. Obie strony chciały otwarcia. Pierwszy raz płakałem w pracy. Trochę.
job.dollhouse_wooden_lock.line.1,Lala's been stuck in there since Tuesday. She's bored.,Lala siedzi tam od wtorku. Ona się nudzi.
job.dollhouse_wooden_lock.line.2,Grandpa called it an Egyptian lock. I'm not sure how true that is.,"Dziadek mówił, że to zamek egipski. Nie wiem, ile w tym prawdy."
job.dollhouse_wooden_lock.line.3,That's the name that stuck. The real story's better. I'll tell you after.,Taka nazwa się przyjęła. Prawdziwa historia jest lepsza. Opowiem po robocie.
job.dollhouse_wooden_lock.line.4,Will you make a new key? A wooden one? Dad has a plank.,A zrobi pan nowy klucz? Drewniany? Tata ma deskę.
job.dollhouse_wooden_lock.note,"Great-grandpa's dollhouse. Wooden pin lock. Lala released. Tomasz will carve a new key, Hania supervises.","Domek pradziadka. Zamek drewniany na kołki. Lala uwolniona. Tomasz wystruga nowy klucz, Hania nadzoruje."
job.drummer_locker.line.1,"I could play with spoons, but I'd rather not. Gig's in an hour.","Mogę zagrać łyżkami, ale wolałabym nie. Koncert za godzinę."
job.drummer_locker.line.2,"Locker eight, Iga pays monthly. It's in my notebook.","Szafka numer osiem, Iga płaci co miesiąc. Mam w zeszycie."
job.drummer_locker.line.3,Your notebook will do. Mr Edek said you write everything down.,"Zeszyt mi wystarczy. Pan Edek mówił, że u pana wszystko jest zapisane."
job.drummer_locker.line.4,"If you make it in time, we'll play one for you. Loudly.","Jak pan zdąży, gramy numer dla pana. Głośno."
job.drummer_locker.note,"Locker 8, rehearsal room. The manager keeps a notebook like mine. Respect. They played me a song. It was loud.","Szafka nr 8, sala prób. Kierownik ma zeszyt jak ja. Szanuję. Zagrali dla mnie numer, było głośno."
job.finnish_sailor.line.1,In Finland everyone has a padlock like this. Nobody opens it without the key.,W Finlandii każdy ma taką kłódkę. Bez klucza nikt jej nie otworzy.
job.finnish_sailor.line.2,"The chest is Aino's, I vouch for her. We sail at six tomorrow.","Skrzynia jest Aino, ręczę. Odpływamy jutro o szóstej."
job.finnish_sailor.line.3,"The captain vouches, the seaman's book matches. Let's see, then.","Kapitan ręczy, książeczka żeglarska się zgadza. To zobaczymy."
job.finnish_sailor.line.4,"If you open it, I'll tell you where this invention came from.","Jeśli pan otworzy, opowiem, skąd ten wynalazek."
job.finnish_sailor.note,"Aino, a Finnish ship. Captain and seaman's book. Done before six. A birch cup now hangs over my bench.","Aino, statek z Finlandii. Kapitan i książeczka. Zdążyliśmy przed szóstą. Chochla z brzozy wisi nad warsztatem."
job.ghent_beguinage.line.1,"In Polish I only know ""dzień dobry"" and ""pierogi"".",Po polsku umiem tylko „dzień dobry” i „pierogi”.
job.ghent_beguinage.line.2,That's half the language.,To już połowa języka.
job.ghent_beguinage.line.3,A letter from the parish council. The key went to heaven with my predecessor.,Pismo od rady parafii. Klucz poszedł z poprzednim opiekunem do nieba.
job.ghent_beguinage.line.4,"No marks, I promise. This lock is older than my building.","Bez śladów, obiecuję. Ten zamek jest starszy niż moja kamienica."
job.ghent_beguinage.note,"Ghent béguinage. A letter from the institution and its caretaker. No marks, as promised. Brother Pieter now knows ""rosół"".","Beginaż w Gandawie. Pismo instytucji i opiekun. Bez śladów, jak obiecałem. Brat Pieter umie już „rosół”."
job.grandma_broth.line.1,"I only stepped out for a moment, dear. With the rubbish.","Synku, ja tylko na chwilkę wyszłam. Ze śmieciami."
job.grandma_broth.line.2,I turned the gas off on the landing. Forty years we've lived wall to wall.,Gaz zakręciłam na klatce. Czterdzieści lat mieszkamy przez ścianę.
job.grandma_broth.line.3,That's as good as paperwork. And the letter in the mailbox is yours?,To mi wystarczy za papiery. List w skrzynce też jest na panią?
job.grandma_broth.line.4,"I made the noodles myself. There's a bowl for you, no arguing.","Makaron sama robiłam. Talerz zostaje dla pana, nie dyskutujemy."
job.grandma_broth.note,"Mrs Halina, Old Town. Mrs Zosia vouches: forty years through the wall. Broth status: slightly reduced. I ate it.","Pani Halina, Śródmieście. Ręczy pani Zosia, 40 lat przez ścianę. Rosół w stanie „trochę wyparował”. Zjadłem."
job.grandpa_chest.line.1,Dad never said what he kept in there. Not even to us.,"Tato nigdy nie mówił, co tam trzyma. Nawet nam."
job.grandpa_chest.line.2,"Mum, he's not asking about the chest. He's asking if the house is yours.","Mamo, pan nie pyta o skrzynię. Pyta, czy dom jest twój."
job.grandpa_chest.line.3,"It's mine. The deed is in the dresser, under the tablecloth.","Mój. Akt notarialny leży w kredensie, pod obrusem."
job.grandpa_chest.line.4,"Letters. From Charleroi. To Grandma, in Polish, with Belgian stamps.","Listy. Z Charleroi. Do babci, po polsku, z belgijskimi znaczkami."
job.grandpa_chest.note,"Grandpa Józef's chest. Deed under the tablecloth, where they always are. Letters from Belgium inside. Ola says she'll go.","Skrzynia dziadka Józefa. Akt pod obrusem, tam gdzie zawsze. W środku listy z Belgii. Ola mówi, że pojedzie."
job.kiosk_shutter.line.1,Thirty-two years this padlock's hung here. Never oiled it once.,Trzydzieści dwa lata ta kłódka tu wisi. Ani razu jej nie oliwiłem.
job.kiosk_shutter.line.2,"Mrs Krysia vouches, the letter's here. I still need one more thing.","Pani Krysia ręczy, list z hurtowni jest. Brakuje mi jeszcze jednej rzeczy."
job.kiosk_shutter.line.3,"Opening day photo, ninety-four. My moustache was in better shape than the kiosk.","Zdjęcie z otwarcia, dziewięćdziesiąty czwarty. Wąsy miałem lepsze niż kiosk."
job.kiosk_shutter.line.4,Stefan's been here longer than the bus stop. The bus will back me up.,Stefan stoi tu dłużej niż przystanek. Autobus to potwierdzi.
job.kiosk_shutter.note,"Mr Stefan's kiosk. A business, so I asked for more. Photo from 1994, moustache genuine. Free paper all week.","Kiosk pana Stefana. Lokal firmy, więc dopytałem. Zdjęcie z 1994, wąsy autentyczne. Gazeta gratis do końca tygodnia."
job.krakow_antiquarian.line.1,"The safe's mine, I rent from the city, the café lady next door will confirm.","Kasa moja, najem mam od miasta, pani z kawiarni obok potwierdzi."
job.krakow_antiquarian.line.2,"And while you're at it, this little box. A customer left it for valuation.",A przy okazji ta kasetka. Klient zostawił ją do wyceny.
job.krakow_antiquarian.line.3,"The safe, yes. The box, no. Let its owner come in person.",Kasę otworzę. Kasetki nie. Niech właściciel przyjdzie sam.
job.krakow_antiquarian.line.4,"You're right. I'm getting old, and impatient with it.",Ma pan rację. Starzeję się i robię się niecierpliwy.
job.krakow_antiquarian.note,"Mr Leopold. The safe is his, the box is not. One job, two decisions. Paid extra in guild stories.","Pan Leopold. Kasa jego, kasetka nie. Jedno zlecenie, dwie decyzje. W zamian opowieść o cechu."
job.krakow_tenement_gate.line.1,The conservator said: not a single hole. Not one.,Konserwator powiedział: ani jednej dziury. Ani jednej.
job.krakow_tenement_gate.line.2,Quite right. Somebody worked hard on this a hundred and thirty years ago.,Słusznie. Ktoś się tu sto trzydzieści lat temu napracował.
job.krakow_tenement_gate.line.3,Hello again. I'm interning here. I passed that exam. Room 412 helped.,"Dzień dobry. Mam tu praktykę. Egzamin zdałam, pokój 412 pomógł."
job.krakow_tenement_gate.line.4,The residents' resolution and a written order. Here you are.,Uchwała wspólnoty i zlecenie na piśmie. Proszę.
job.krakow_tenement_gate.note,"A gate in Kazimierz. My first residents' resolution, I might frame it. Zuzanna takes notes faster than I do.","Brama na Kazimierzu. Pierwsza uchwała wspólnoty w mojej karierze, chyba ją oprawię. Zuzanna robi notatki szybciej ode mnie."
job.liege_bakery.line.1,My uncle had thirty keys and labelled none of them.,Wujek miał trzydzieści kluczy i żadnego nie podpisał.
job.liege_bakery.line.2,The lock felt a stranger's key and took offence. That's its job.,Zamek wyczuł obcy klucz i się obraził. Taki ma zawód.
job.liege_bakery.line.3,Handover papers and the lease. The dough rises without permission.,Papiery przejęcia i umowa najmu. Ciasto rośnie bez pozwolenia.
job.liege_bakery.line.4,"The papers will do. Waffles at six, as promised.",Papiery wystarczą. Gofry o szóstej będą.
job.liege_bakery.note,"Liège, 3:50 a.m. The detector lock was right to lock up. Handover papers in order. One pearl-sugar waffle.","Liège, 3:50. Zamek z detektorem miał rację, że się zablokował. Papiery przejęcia w porządku. Gofr z perłowym cukrem."
job.museum_time_lock.line.1,It's not about the combination. It's about time.,Tu nie chodzi o szyfr. Tu chodzi o czas.
job.museum_time_lock.line.2,A time lock doesn't ask who's there. It asks what time it is.,"Zamek czasowy nie pyta, kto przyszedł. Pyta, która godzina."
job.museum_time_lock.line.3,"Director's letter, transfer protocol. All in triplicate.","Pismo dyrekcji, protokół przekazania. Wszystko w trzech egzemplarzach."
job.museum_time_lock.line.4,"Doctor, there are gloves for the locksmith too. Size L.","Pani doktor, rękawiczki dla pana ślusarza też są. Rozmiar L."
job.museum_time_lock.note,"Museum of Technology. Dr Rygiel, triplicate everything. The clock was persuaded. Zuzanna interns here, of course.","Muzeum Techniki. Dr Rygiel, trzy egzemplarze wszystkiego. Zegar przekonany. Zuzanna jest tu na stażu, oczywiście."
job.newlyweds_4am.line.1,"I've got ID, but there's no address on it. I know. Nobody's has one now.","Dowód mam, ale adresu na nim nie ma. Wiem, wiem. Teraz nikt nie ma."
job.newlyweds_4am.line.2,My registered address is in the app. See? Hard to aim with a veil on.,"Meldunek mam w aplikacji. Tu, widzi pan? Z welonem trudno celować."
job.newlyweds_4am.line.3,I know them. They got married today. The whole estate heard the party.,Znam ich. Pobrali się dziś. Całe osiedle słyszało oczepiny.
job.newlyweds_4am.line.4,Congratulations. Two minutes and you're home.,Wszystkiego najlepszego. Dwie minuty i jesteście w domu.
job.newlyweds_4am.note,"Newlyweds, 4:12 a.m. ID without an address is normal, hence the app and a neighbour in a robe. Three-tier cake. I took a slice.","Nowożeńcy, 4:12. Dowód bez adresu to norma, dlatego meldunek i sąsiad w szlafroku. Tort trzypiętrowy, wziąłem kawałek."
job.night_nurse.line.1,Twelve hours on the ward. My key's in my locker at the hospital.,Dwanaście godzin na oddziale. Klucz został w szafce w szpitalu.
job.night_nurse.line.2,"Mrs Agnieszka, flat fourteen, that's right. Her lease is on my system.","Pani Agnieszka spod czternastki, zgadza się. Umowę mam w systemie."
job.night_nurse.line.3,"The manager confirms, the ID matches. You'll be asleep in no time.","Administrator potwierdza, dowód się zgadza. Zaraz pani śpi."
job.night_nurse.line.4,Sorry I'm not chatty. I'm talking in my sleep already.,"Przepraszam, że nie rozmawiam. Ja już mówię przez sen."
job.night_nurse.note,"Mrs Agnieszka, after a night shift. Mr Roman on the intercom, efficient as ever. Neighbour discount, no question.","Pani Agnieszka, po nocce. Pan Roman przez domofon, sprawnie jak zawsze. Rabat sąsiedzki, bez dyskusji."
job.pizzeria_pays_pizza.line.1,"The takings are in the till, the till's inside. I'll pay in pizza. How hungry are you?","Utarg jest w kasie, kasa w środku. Płacę w pizzy. Ile pan zje?"
job.pizzeria_pays_pizza.line.2,"Quote first, menu second. Do you have the lease?","Najpierw wycena, potem menu. Umowa najmu lokalu jest?"
job.pizzeria_pays_pizza.line.3,"Known her twenty years, my kebab shop's next door. Her margherita is art.","Znam ją dwadzieścia lat, kebab mam przez ścianę. Jej margherita to sztuka."
job.pizzeria_pays_pizza.line.4,"The dough is rising, I'm sinking. Any time before dawn.","Ciasto rośnie, ja maleję. Byle przed świtem."
job.pizzeria_pays_pizza.note,Renata's pizzeria. Lease plus the neighbour next door. Paid in margherita. The box is on my shelf.,Pizzeria „U Renaty”. Umowa najmu i sąsiad z lokalu obok. Zapłata: margherita. Pudełko stoi na półce.
job.refuse_aunt_alive.after.1,"Mrs Lucyna is back on Friday. She'll have the lock changed, with your help.","Pani Lucyna wraca w piątek. Zamek wymieni sama, z pana pomocą."
job.refuse_aunt_alive.after.2,Good thing you said no. I wouldn't have slept a wink.,"Dobrze, że pan odmówił. Ja bym nie spała."
job.refuse_aunt_alive.line.1,"Auntie passed away last week. The papers are in progress, it's so recent.","Ciocia zmarła w zeszłym tygodniu. Papiery są w trakcie, to dopiero co."
job.refuse_aunt_alive.line.2,"Mrs Lucyna? She's at a health resort. She rang yesterday, she's feeling better.","Pani Lucyna? Jest w sanatorium. Wczoraj dzwoniła, że jej lepiej."
job.refuse_aunt_alive.line.3,I must have got something mixed up.,Musiałam coś pomylić.
job.refuse_aunt_alive.line.4,Then let's ring Mrs Lucyna together. And then Officer Sowa.,To zadzwońmy do pani Lucyny razem. A potem do aspirant Sowy.
job.refuse_aunt_alive.note,The aunt who is doing fine. The neighbour stepped out just in time. Mrs Lucyna sends regards from her resort.,"Ciotka, która ma się dobrze. Sąsiadka wyszła na klatkę w porę. Pani Lucyna przesyła pozdrowienia z sanatorium."
job.refuse_ex_partner.after.1,Good that you called. He collected his things with me there; the tenant agreed.,"Dobrze, że pan zadzwonił. Rzeczy odebrał przy mnie, lokatorka się zgodziła."
job.refuse_ex_partner.after.2,Heard it at the bus stop. You're a decent sort. Paper?,Słyszałem na przystanku. Porządny z pana człowiek. Gazeta?
job.refuse_ex_partner.line.1,I lived here three years. I've a right to go in and get my things.,Mieszkałem tu trzy lata. Mam prawo wejść po swoje rzeczy.
job.refuse_ex_partner.line.2,"There's one name on the mailbox, and it isn't yours. I'll call the manager.","Na skrzynce jest jedno nazwisko, nie pana. Zawołam administratora."
job.refuse_ex_partner.line.3,Why the manager? This is a private matter.,Po co administrator? To prywatna sprawa.
job.refuse_ex_partner.line.4,I can't open this one. The police can help you collect your things. Shall I call?,"Tu nie otworzę. Policja pomaga odebrać rzeczy, spokojnie. Zadzwonić?"
job.refuse_ex_partner.note,"Didn't open. One name on the door, not his. Passed it to Officer Sowa. No regrets.",Nie otworzyłem. Jedno nazwisko na drzwiach i to nie jego. Przekazałem sprawę aspirant Sowie. Nie żałuję.
job.refuse_rush_bribe.after.1,The sister knew nothing about any documents. Thank you for the call.,Siostra nic nie wiedziała o żadnych dokumentach. Dziękuję za telefon.
job.refuse_rush_bribe.after.2,Someone in a suit asked about a locksmith yesterday. I sent him to you. Sorry.,Ktoś w garniturze pytał wczoraj o ślusarza. Odesłałem go do pana. Przepraszam.
job.refuse_rush_bribe.line.1,Double the rate. Triple. Just skip all the procedures.,Podwójna stawka. Potrójna. Tylko bez tych wszystkich procedur.
job.refuse_rush_bribe.line.2,"Procedures aren't for sale. Call your sister, I'll wait.","Procedur nie da się dopłacić. Proszę zadzwonić do siostry, poczekam."
job.refuse_rush_bribe.line.3,"She's not answering. Let's not wake the neighbours, no need for a circus.","Nie odbiera. Sąsiadów nie budźmy, po co ten cyrk."
job.refuse_rush_bribe.line.4,"Then good night. And for the record, I'll let the local officer know.",To dobranoc. A dla porządku dam znać dzielnicowej.
job.refuse_rush_bribe.note,"1 a.m., a suit, a rush, cash instead of a witness. Didn't open. Reported it. Slept well.","1:00, garnitur, pośpiech, dopłata zamiast sąsiada. Nie otworzyłem. Zgłosiłem. Spałem dobrze."
job.student_dorm.line.1,My student card is in the room. So is the key. I'm in the corridor.,Legitymacja jest w pokoju. Klucz też. Ja jestem na korytarzu.
job.student_dorm.line.2,"Wilk, Zuzanna, four-twelve. It's on my list and in my head.","Wilk Zuzanna, czterysta dwanaście. Mam na liście i mam w głowie."
job.student_dorm.line.3,"Mr Edek vouches, the name matches. We're opening.","Pan Edek ręczy, nazwisko się zgadza. Otwieramy."
job.student_dorm.line.4,I've an exam on historical locks tomorrow. Does this count as practice?,Jutro mam egzamin z zamków historycznych. To się liczy jako praktyka?
job.student_dorm.note,"Room 412, campus. A porter with a tenant list: the best proof there is. Zuzanna asked about everything.","Pokój 412, kampus. Portier z listą lokatorów: najlepszy dowód, jaki istnieje. Zuzanna pytała o wszystko."
job.swiatniki_journeyman_padlock.line.1,I've kept it seventy years. There was one key. My grandson lost it.,Siedemdziesiąt lat ją trzymam. Klucz był jeden. Wnuk go zgubił.
job.swiatniki_journeyman_padlock.line.2,And you know how to open it?,"A pan wie, jak ją otworzyć?"
job.swiatniki_journeyman_padlock.line.3,I do. But I want to see if the young ones still can.,"Wiem. Ale chcę zobaczyć, czy młodzi jeszcze umieją."
job.swiatniki_journeyman_padlock.line.4,I know the handwriting in that notebook. Henryk. I taught him. It found the right hands.,To pismo w zeszycie znam. Henryk. Uczyłem go. Dobrze trafił ten zeszyt.
job.swiatniki_journeyman_padlock.note,"Mr Władysław, Świątniki. He knew Henryk's hand in my notebook. He taught Henryk that first rule.","Pan Władysław, Świątniki. Rozpoznał pismo Henryka w moim zeszycie. Pierwszej zasady to on nauczył Henryka."
job.time_capsule.line.1,I know the code was a date. But whose?,"Wiem, że kodem była jakaś data. Tylko czyja?"
job.time_capsule.line.2,"The school agrees. Please open it, in front of everyone.","Szkoła się zgadza. Proszę otwierać, przy wszystkich."
job.time_capsule.line.3,"Miss, we were nine. All I remember is conkers.","Pani Jadwigo, my mieliśmy wtedy dziewięć lat. Pamiętam tylko kasztany."
job.time_capsule.line.4,"My letter: ""I hope you have a dog."" I have a cat. That counts.","Mój list: „Mam nadzieję, że masz psa”. Mam kota. Też się liczy."
job.time_capsule.note,"Class 3b, the chestnut tree. The school and twenty witnesses. Marta was in that class. A card on my doormat: ""Broth's waiting.""","Klasa 3b, kasztanowiec. Dyrekcja i dwudziestu świadków. Marta była w tej klasie. Na wycieraczce kartka: „Rosół czeka”."
job.uncle_safe_heirs.line.1,"You open it, I'll have a look and tell the others. We'll share anyway.","Pan otworzy, ja popatrzę i powiem reszcie. Przecież się podzielimy."
job.uncle_safe_heirs.line.2,"I'll open it when all the heirs are here, or their consent is in writing.","Otworzę, gdy będą wszyscy spadkobiercy albo ich zgoda na piśmie."
job.uncle_safe_heirs.line.3,"Ewa's an hour away. Marek, put the kettle on.","Ewa będzie za godzinę. Marek, nastaw wodę."
job.uncle_safe_heirs.line.4,Uncle would laugh to see us fight over a box with a dial.,"Wujek by się śmiał, że się kłócimy o pudło z tarczą."
job.uncle_safe_heirs.note,Uncle Bogdan's safe. We waited for Ewa: an hour and three teas. Opened in front of everyone. Nobody sulked.,"Sejf wujka Bogdana. Czekaliśmy na Ewę, godzina i trzy herbaty. Otwarte przy wszystkich. Nikt się nie obraził."
job.widow_bureau.line.1,Mrs Zosia said you don't drill. My husband couldn't stand drilling.,"Pani Zosia mówiła, że pan nie wierci. Mąż nie znosił wiercenia."
job.widow_bureau.line.2,I'll open it so no one can tell. It stays his desk.,"Otworzę tak, że nikt nie pozna. Mebel zostanie jego."
job.widow_bureau.line.3,Opera tickets. Nineteen eighty-seven.,Bilety do opery. Osiemdziesiąty siódmy.
job.widow_bureau.line.4,He told me he'd lost them. He kept them.,"Mówił, że je zgubił. Trzymał je."
job.widow_bureau.note,"Mrs Irena, sent by Mrs Zosia. The bureau is in her home; no marks left. Tickets inside. I didn't ask.","Pani Irena, z polecenia pani Zosi. Sekretarzyk w jej domu, bez śladów. W środku bilety. Nie dopytywałem."
job.wrong_floor.after.1,You're the one who didn't open my door? I baked you a cake. For not opening it.,"To pan wczoraj nie otworzył? Upiekłam drożdżowe. Za to, że pan nie otworzył."
job.wrong_floor.line.1,The key won't go in. The lock broke while I was out.,"Klucz nie wchodzi. Zamek się zepsuł, jak mnie nie było."
job.wrong_floor.line.2,"Mr Kazimierz, there's another name on the mailbox. And this wreath?","Panie Kazimierzu, na skrzynce jest inne nazwisko. I ten wieniec?"
job.wrong_floor.line.3,Who's there? I've lived here twelve years. I made that wreath myself.,Kto tam? Mieszkam tu dwanaście lat. Wieniec sama wiłam.
job.wrong_floor.line.4,"Oh, one floor up the key fits. You've fixed it.","O, piętro wyżej klucz wchodzi. Naprawił pan."
job.wrong_floor.note,Mr Kazimierz after a name-day party. Wrong floor. I opened nothing and it still worked. Best job of the week.,"Pan Kazimierz po imieninach. Drzwi piętro niżej. Nic nie otwierałem, a i tak się udało. Najlepsza robota tygodnia."
notebook.refuse.line,I can't open this one. But I can help another way.,Tu nie otworzę. Mogę za to pomóc inaczej.
notebook.rule.1,First ask whose it is. Then look at the lock.,"Najpierw zapytaj, czyje to. Potem patrz na zamek."
notebook.rule.2,One paper is a hint. Two is a conversation. A neighbour is certainty.,Jeden papier to poszlaka. Dwa to rozmowa. Sąsiad to pewność.
notebook.rule.3,Whoever pays to skip questions is paying for someone else's door.,"Kto płaci za brak pytań, płaci za nie swoje drzwi."
notebook.rule.4,Quote before work. No surprises on the bill.,Wycena przed robotą. Rachunek bez niespodzianek.
notebook.rule.5,What I saw inside stays inside.,"Co widziałem w środku, zostaje w środku."
```


## Załącznik B — mówcy linii (do JSON-ów zleceń)

Indeks w tablicy `lines` odpowiada `job.<id>.line.<n>` (n = indeks + 1). To samo dla `after`.

```json
{
 "job.grandma_broth": { "lines": [  "halina",  "zosia",  "locksmith",  "halina" ]
 },
 "job.cat_bathroom": { "lines": [  "marta",  "locksmith",  "marta",  "locksmith" ]
 },
 "job.bike_interview": { "lines": [  "kuba",  "locksmith",  "kuba",  "locksmith" ]
 },
 "job.student_dorm": { "lines": [  "zuzanna",  "edek",  "locksmith",  "zuzanna" ]
 },
 "job.kiosk_shutter": { "lines": [  "stefan",  "locksmith",  "stefan",  "krysia" ]
 },
 "job.refuse_ex_partner": { "lines": [  "darek",  "locksmith",  "darek",  "locksmith" ], "after": [  "lena",  "stefan" ]
 },
 "job.newlyweds_4am": { "lines": [  "bartek",  "bride",  "neighbour_robe",  "locksmith" ]
 },
 "job.pizzeria_pays_pizza": { "lines": [  "renata",  "locksmith",  "mietek",  "renata" ]
 },
 "job.night_nurse": { "lines": [  "agnieszka",  "roman",  "locksmith",  "agnieszka" ]
 },
 "job.wrong_floor": { "lines": [  "kazimierz",  "locksmith",  "teresa",  "kazimierz" ], "after": [  "teresa" ]
 },
 "job.refuse_rush_bribe": { "lines": [  "stranger",  "locksmith",  "stranger",  "locksmith" ], "after": [  "lena",  "stefan" ]
 },
 "job.drummer_locker": { "lines": [  "iga",  "hall_manager",  "locksmith",  "iga" ]
 },
 "job.grandpa_chest": { "lines": [  "krystyna",  "ola",  "krystyna",  "ola" ]
 },
 "job.uncle_safe_heirs": { "lines": [  "marek",  "locksmith",  "piotr",  "ewa" ]
 },
 "job.dollhouse_wooden_lock": { "lines": [  "hania",  "tomasz",  "locksmith",  "hania" ]
 },
 "job.allotment_shed": { "lines": [  "zbyszek",  "locksmith",  "waldek",  "zbyszek" ]
 },
 "job.widow_bureau": { "lines": [  "irena",  "locksmith",  "irena",  "irena" ]
 },
 "job.refuse_aunt_alive": { "lines": [  "claimant",  "neighbour_lucyna",  "claimant",  "locksmith" ], "after": [  "lena",  "neighbour_lucyna" ]
 },
 "job.krakow_tenement_gate": { "lines": [  "wanda",  "locksmith",  "zuzanna",  "wanda" ]
 },
 "job.swiatniki_journeyman_padlock": { "lines": [  "wladyslaw",  "locksmith",  "wladyslaw",  "wladyslaw" ]
 },
 "job.krakow_antiquarian": { "lines": [  "leopold",  "leopold",  "locksmith",  "leopold" ]
 },
 "job.brussels_townhouse": { "lines": [  "magda",  "jacques",  "locksmith",  "magda" ]
 },
 "job.ghent_beguinage": { "lines": [  "pieter",  "locksmith",  "pieter",  "locksmith" ]
 },
 "job.liege_bakery": { "lines": [  "nadia",  "locksmith",  "nadia",  "locksmith" ]
 },
 "job.charleroi_letters": { "lines": [  "ola",  "martine",  "ola",  "locksmith" ]
 },
 "job.museum_time_lock": { "lines": [  "rygiel",  "locksmith",  "rygiel",  "zuzanna" ]
 },
 "job.bramah_bureau": { "lines": [  "gosia",  "locksmith",  "gosia",  "locksmith" ]
 },
 "job.finnish_sailor": { "lines": [  "aino",  "captain",  "locksmith",  "aino" ]
 },
 "job.time_capsule": { "lines": [  "jadwiga",  "headteacher",  "marta",  "marta" ]
 }
}
```
