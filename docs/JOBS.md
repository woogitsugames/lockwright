# Zlecenia (Tryb Zleceń) — biblia treści

Status: szkic do przeglądu · 2026-11-04 · tryb po MVP.
Teksty dla gracza poniżej to **robocze** stringi PL + EN; w produkcji trafią do plików i18n pod kluczami
`job.<id>.title`, `job.<id>.line.<n>` itd. Identyfikatory są stabilne, teksty nie.

> **Uwaga w grze (stały ekran „O grze”)**: „To gra, nie kurs. Mechanizmy są wymyślone i uproszczone.
> Prawdziwy ślusarz zawsze sprawdza, czy klient ma prawo wejść do lokalu.” / „This is a game, not a course.
> The mechanisms are invented and simplified. A real locksmith always checks that the customer has the right to enter.”

> **Zastrzeżenie dla zespołu**: rozdział „Zawód w praktyce” jest informacyjny, zebrany z publicznych źródeł
> (stan na 2026-11-04). To nie jest porada prawna.

---

## 1. Zawód w praktyce

### 1.1 Polska

| Ustalenie | Co mówią źródła | Pewność |
|---|---|---|
| Ślusarz nie jest zawodem regulowanym (brak licencji na otwieranie drzwi) | Ślusarz to zawód szkolny/rzemieślniczy (symbol 722204, III poziom PRK), z dobrowolnym egzaminem czeladniczym i mistrzowskim w izbach rzemieślniczych. Ustawa o rzemiośle nie uzależnia prowadzenia działalności od dyplomu. W przeglądanych materiałach o deregulacji i zawodach regulowanych ślusarza nie ma. Nie znaleźliśmy żadnego przepisu, który wymagałby osobnego zezwolenia na usługi awaryjnego otwierania. | wysoka (brak regulacji); średnia (nie sprawdziliśmy bezpośrednio unijnej bazy Regulated Professions) |
| Brak ustawowego obowiązku weryfikacji klienta | Żaden znaleziony przepis nie nakazuje ślusarzowi sprawdzać dokumentów. Weryfikacja to **standard branżowy** i zabezpieczenie samego ślusarza: kto świadomie pomaga komuś wejść do cudzego lokalu, naraża się na odpowiedzialność (np. naruszenie miru domowego, art. 193 k.k., w związku z pomocnictwem, art. 18 § 3 k.k.). To nasza interpretacja, nie wykładnia prawnika. | średnia |
| Dowód osobisty nie wystarczy jako „dokument z adresem” | Dowody wydawane od 1 III 2015 nie zawierają adresu zameldowania. W aplikacji mObywatel mDowód jest dokumentem tożsamości. Od 1 VII 2025 aplikacja pokazuje dane i historię zameldowania. **Meldunek nie dowodzi prawa do lokalu**, jest tylko jedną z poszlak. | wysoka (dowód, mDowód); wysoka (zameldowanie w aplikacji, wg spidersweb.pl) |
| Wycena przed pracą jest obowiązkiem wobec konsumenta | Umowa zawarta poza lokalem przedsiębiorstwa: przy naprawie lub konserwacji do 600 zł, wykonywanej od razu, przedsiębiorca musi m.in. podać wynagrodzenie lub sposób jego obliczenia i dać kosztorys na papierze albo, za zgodą klienta, na innym trwałym nośniku (art. 16 u.p.k.). Gdy klient sam wezwał fachowca do pilnej naprawy, nie przysługuje mu prawo odstąpienia od umowy, chyba że dotyczy ono usług dodatkowych (art. 38 pkt 8 u.p.k.; dyrektywa 2011/83/UE art. 16 lit. h). | wysoka |
| Noc i święta drożej | To praktyka rynkowa, nie przepis. Cenniki pogotowia zamkowego zwykle mają dopłatę nocną i świąteczną. Wartości nie są nam potrzebne, w grze używamy monet. | wysoka (że jest taka praktyka) |
| Otwarcie bezinwazyjne jako standard | Program kształcenia i opisy kwalifikacji ślusarza obejmują montaż i naprawę zamków, ale nie opisują procedury awaryjnej. Tę zasadę bierzemy z belgijskich wymagań certyfikacyjnych (niżej) i z praktyki branży: otwierasz bez zniszczeń, a metodę niszczącą stosujesz dopiero po uprzedzeniu klienta. | średnia |

Źródła PL:
- Ustawa z 30 maja 2014 r. o prawach konsumenta, art. 16 i art. 38 pkt 8 — ISAP: https://isap.sejm.gov.pl/isap.nsf/DocDetails.xsp?id=WDU20140000827 (sprawdzone na tekście jednolitym Dz.U. 2017 poz. 683: https://api.sejm.gov.pl/eli/acts/DU/2017/683/text.pdf; nowsze teksty jednolite mogą mieć zmienioną numerację punktów)
- Dyrektywa 2011/83/UE, art. 16 lit. h — https://eur-lex.europa.eu/eli/dir/2011/83/oj
- Kodeks karny, art. 18 § 3 i art. 193 — https://isap.sejm.gov.pl/isap.nsf/DocDetails.xsp?id=WDU19970880553
- Ustawa z 22 marca 1989 r. o rzemiośle — https://isap.sejm.gov.pl/isap.nsf/DocDetails.xsp?id=WDU19890170092
- Opis zawodu ślusarz 722204 (ORE/MEN) — https://doradztwo.ore.edu.pl/wp-content/uploads/slusarz.pdf
- Zameldowanie w mObywatelu od 1 VII 2025 — https://spidersweb.pl/2025/07/nowosc-w-mobywatelu-adres-zameldowania.html
- Ustawa z 26 maja 2023 r. o aplikacji mObywatel (Dz.U. 2023 poz. 1234): mDowód jako dokument tożsamości (pewność wysoka; numer pozycji do sprawdzenia w ISAP)

### 1.2 Belgia

| Ustalenie | Co mówią źródła | Pewność |
|---|---|---|
| Ustawa o bezpieczeństwie prywatnym **nie obejmuje** ślusarzy | Ustawa z 2 X 2017 (*loi réglementant la sécurité privée et particulière*) wymaga zezwoleń od firm ochroniarskich, firm od systemów alarmowych i kamer, firm konsultingu bezpieczeństwa oraz ochrony morskiej (art. 3–12). Słowo „serrur*” nie pada w tekście. Konsulting związany z inną główną działalnością jest wyłączony (art. 9 1°). **Ślusarz, który montuje alarmy lub kamery, potrzebuje zezwolenia na tę część działalności.** | wysoka (tekst ustawy) |
| Projekt z 2016 r., żeby włączyć ślusarzy do ustawy z 1990 r., nie przeszedł | Franky Demon (CD&V) proponował agrément ministra spraw wewnętrznych na 5 lat i kartę identyfikacyjną. Ustawa z 2017 r. tego nie zawiera. | wysoka |
| Od 1 I 2022 istnieje identyfikacyjna karta ślusarza wydawana przez FOD Economie / SPF Économie | Mechanizm samoregulacji: ślusarz podpisuje kodeks postępowania FOD Economie i ma certyfikat jakości. Dostaje kartę, którą klient może zobaczyć, a firma trafia na listę FOD. Inspekcja ekonomiczna może sprawdzać karty. To **nie jest licencja ustawowa**, nikt nie zabrania pracy bez karty. | średnia-wysoka (prasa 2021–2022; aktualnego rejestru nie sprawdziliśmy) |
| Wymogi certyfikacji | Kodeks FOD. Dostępność pod podanym numerem. Szkolenie w uznanym ośrodku albo 5 lat działalności jako ślusarz. Oznakowane auta. **Zaświadczenie o niekaralności (model 595) dla pracowników, odnawiane co 2 lata.** Ubezpieczenie OC. Belgijski adres i konto. Wśród kompetencji: znajomość technik otwierania, dyskrecja w sprawach klientów i ich mienia, informowanie klienta o czasie oczekiwania i koszcie. Ciekawostka: oznakowania nie wymaga się od aut używanych przy otwarciach z komornikiem (*deurwaarder*) i policją. | średnia (dokument procedury z 2022 r. znamy z kopii na stronie firmy, nie z FOD) |
| Brak obowiązku weryfikacji klienta w przepisach | Ani kodeks, ani prasa o karcie nie wspominają o sprawdzaniu prawa do lokalu. Tak jak w PL to praktyka zawodowa. | średnia |
| eID | W Belgii obywatele od 12. roku życia mają eID, a od 15 lat muszą ją nosić przy sobie. Adres zapisano w chipie, na karcie nie jest wydrukowany. W grze potraktujemy to symbolicznie: klient pokazuje adres w aplikacji czy na wydruku z gminy. | średnia-wysoka |
| Wycena i prawo odstąpienia | Obowiązuje ta sama dyrektywa 2011/83/UE (wyjątek dla pilnych napraw na wezwanie klienta). Do Europejskiego Centrum Konsumenckiego w Belgii trafiają skargi na zawyżone rachunki ślusarzy. | wysoka |

Źródła BE:
- Loi du 2 octobre 2017 réglementant la sécurité privée et particulière — https://www.ejustice.just.fgov.be/eli/loi/2017/10/02/2017031388/justel (tekst skonsolidowany w PDF: https://law.obspol.org/BEL/Loi_2017.10.02_2017031388_Securite.Privee.Et.Particuliere.pdf)
- DH, 6 XII 2016, „Vers une loi pour enfin encadrer les serruriers!” — https://www.dhnet.be/actu/faits/2016/12/06/vers-une-loi-pour-enfin-encadrer-les-serruriers-5YGC44UOEBFMLLSEONMXZQ7KP4/
- RTBF, 2 IX 2021, „900 euros pour ouvrir une porte…” — https://www.rtbf.be/article/900-euros-pour-ouvrir-une-porte-les-serruriers-peu-scrupuleux-bientot-dehors-10834672
- VRT NWS, 2 IX 2021 — https://www.vrt.be/vrtnws/nl/2021/09/02/eindelijk-betrouwbare-slotenmakers-krijgen-vanaf-volgend-jaar-e/
- New Security, 6 I 2022, „Identificatiekaart voor betrouwbare slotenmakers” — https://www.newsecurity.be/nl/nieuws/identificatiekaart-voor-betrouwbare-slotenmakers
- Procedura certyfikacji (kopia z I 2022) — https://eddyslotenmakerij.be/assets/files/NL-certificatieproceduredefinitief1122021.pdf
- ECC Belgia, „Opgelet voor oneerlijke slotenmakers” — https://www.eccbe.eu/in-de-kijker/opgelet-voor-oneerlijke-slotenmakers/

### 1.3 Co z tego wynika dla mechaniki

1. **Weryfikacja to sprawa sumienia i reputacji, nie przepisu.** Gra nie pokazuje „licencji” jako bramki. Weryfikacja chroni klienta, sąsiadów i samego ślusarza, a gracz podejmuje decyzję jako fachowiec.
2. **Jeden dokument niczego nie przesądza.** W Polsce dowód nie ma adresu, a meldunek nie jest tytułem do lokalu. Ślusarz zbiera **poszlaki** (karty dowodów), które razem dają pewność.
3. **Wycena przed pracą.** Bez zaakceptowanej wyceny zlecenie się nie zaczyna. Rachunek wyższy od wyceny obniża reputację.
4. **Najpierw bez zniszczeń.** Metoda niszcząca wymaga osobnej zgody klienta, pokazanej w dialogu. Bez zgody tracisz reputację i sam płacisz za część.
5. **Karta ślusarza (Belgia).** W rozdziale belgijskim gracz zdobywa „kartę” przez kodeks postępowania (scena z wyborami). Kodeks daje dostęp do zleceń od zarządców budynków, nie jest bramką kar.
6. **Policja i komornik.** W Belgii otwarcia z komornikiem i policją wymieniono jako osobną kategorię pracy. W grze to **późny typ zlecenia**: ślusarz otwiera na wezwanie urzędu, a weryfikację przejmuje urzędnik. Bez dramatyzmu: zwykle chodzi o zalanie albo starszą osobę, która nie otwiera.
7. **Dyskrecja.** Po otwarciu ślusarz nie komentuje tego, co zobaczył w środku. W dialogach mamy opcję „nie dopytuję”, która lekko podnosi reputację w dzielnicy.

---

## 2. Mini-scena weryfikacji prawa do lokalu

### 2.1 Zasada nadrzędna
Scena jest **symboliczna**. Dowody to karty z ikoną i jednym zdaniem. Gra nigdy nie pokazuje, jak podrobić dokument, ani jak „przejść” weryfikację u prawdziwego ślusarza. Podejrzane zlecenia rozpoznaje się po **zachowaniu i sprzecznościach w historii** klienta, a nie po technicznych szczegółach dokumentów. Gracz nie ma narzędzia do „badania autentyczności” dokumentu, ma tylko zdrowy rozsądek.

### 2.2 Przebieg (15–40 s)
1. **Telefon / przyjazd**: krótka scenka. Klient mówi, co się stało.
2. **Wycena** (patrz rozdz. 3): karta z ceną, którą klient akceptuje albo o nią pyta.
3. **Stół dowodów**: klient kładzie 1–3 karty. Gracz może poprosić o kolejną (patrz akcje).
4. **Decyzja** (4 przyciski, cele ≥ 48 dp):
   - **Otwieram** / *I'll open it*
   - **Poproszę o coś jeszcze** / *I need one more thing*
   - **Odmawiam** / *I can't do this one*
   - **Dzwonię na policję** / *I'm calling the police* (w PL: 112 / dzielnicowy; w scenie zawsze spokojnie, bez akcji)
5. **Po otwarciu**: „potwierdzenie w środku”, czyli drobny szczegół, który zgadza się z historią klienta (kot, rosół, zdjęcie ślubne na ścianie). Gdy szczegół się nie zgadza, gracz wychodzi, a gra rozlicza to jak odmowę po fakcie.

### 2.3 Karty dowodów (wartość pewności 1–3)

| Klucz i18n | PL | EN | Pewność | Uwagi |
|---|---|---|---|---|
| `proof.id_doc` | Dowód osobisty (bez adresu) | ID card (no address) | 1 | Potwierdza tylko tożsamość. W BE: eID (adres w chipie, odczytany w aplikacji). |
| `proof.mobywatel_address` | mObywatel: dane zameldowania | Government app: registered address | 2 | Meldunek ≠ prawo do lokalu. |
| `proof.lease` | Umowa najmu (w telefonie lub na papierze) | Lease agreement | 2 | Musi się zgadzać z nazwiskiem z dowodu. |
| `proof.deed` | Akt notarialny / wypis z księgi wieczystej | Title deed | 3 | Rzadko ktoś ma go przy sobie, nagroda za zapobiegliwość. |
| `proof.letter` | List lub rachunek na nazwisko i adres | Letter or bill with name & address | 1 | Często leży w skrzynce, do której klient ma kluczyk. |
| `proof.neighbour` | Sąsiad świadek | Neighbour vouches | 2 | Najcieplejsze sceny gry. Sąsiad może też powiedzieć coś, co wszystko zmienia. |
| `proof.manager` | Zarządca, administrator, portier | Building manager / porter | 2–3 | Lista lokatorów. |
| `proof.inside_detail` | Szczegół z wnętrza („na lodówce magnes z Helu”) | Detail from inside | 1 | Sprawdzany **po** otwarciu. |
| `proof.photo_home` | Zdjęcie w telefonie: klient w tym mieszkaniu | Photo of the customer at home | 1 | |
| `proof.key_holder` | Telefon do osoby z zapasowym kluczem | Call to whoever holds a spare key | 2 | Czasem rozwiązuje sprawę bez otwierania (patrz „mniejsze zło”). |
| `proof.officer` | Policjant / komornik na miejscu | Police officer / bailiff present | 3 | Weryfikację przejmuje urzędnik. |
| `proof.possession` | Przedmiot jest u klienta (rower, skrzynia, sejf w jego domu) | It's in the customer's hands | 1–2 | Dla rzeczy ruchomych próg jest niższy. |

**Próg pewności** zależy od obiektu: mieszkanie lub dom ≥ 4, lokal firmy ≥ 4, piwnica, altana lub komórka ≥ 3, rzecz w posiadaniu klienta ≥ 2, łazienka od środka mieszkania klienta 0.
Gra **nie wyświetla liczb** w trybie podstawowym. Zamiast tego jest wskaźnik „Czuję się pewnie / Coś mi nie pasuje / Za mało wiem” (kształt i podpis, a nie sam kolor), żeby decyzja była ludzka, a nie arytmetyczna. W ustawieniach dostępności można włączyć liczby.

### 2.4 Sygnały podejrzane (karty „zgrzyt”)

Zgrzyt odejmuje pewność **albo** blokuje „Otwieram”, dopóki gracz nie zada pytania.

| Klucz | PL | EN |
|---|---|---|
| `flag.contradiction` | Historia się nie klei (inne nazwisko, inne piętro, inna wersja po minucie) | The story keeps changing |
| `flag.rush_bribe` | „Dopłacę, tylko bez pytań” | "I'll pay extra, just no questions" |
| `flag.ex_partner` | „To mieszkanie mojego byłego / mojej byłej” | "It's my ex's place" |
| `flag.absent_owner` | Właściciel „wyjechał” i nie odbiera, a klient chce wejść | Owner is "away" and not answering |
| `flag.no_witness` | Odmawia, gdy proponujesz zawołanie sąsiada czy zarządcy | Refuses any witness |
| `flag.extra_key` | „A przy okazji dorobi pan klucz?” do cudzego zamka | "Could you cut me a key while you're at it?" |
| `flag.neighbour_denies` | Sąsiad mówi coś sprzecznego z historią | The neighbour says otherwise |

Zgrzyt **nie oznacza od razu przestępcy**. Część zleceń ma zgrzyt, który się wyjaśnia (np. nazwisko panieńskie na skrzynce), i wtedy „Poproszę o coś jeszcze” daje najlepszy wynik. Gra uczy, że warto dopytać, a nie że wszyscy kłamią.

### 2.5 Konsekwencje (reputacja 0–100 na dzielnicę + globalne „Zaufanie”)

| Sytuacja | Otwieram | Proszę o więcej | Odmawiam | Policja |
|---|---|---|---|---|
| Uczciwy klient, pewność ≥ próg | +3 rep, napiwek możliwy | +1 rep (klient docenia staranność), czas fabularny +1 | −4 rep, klient dzwoni do kogoś innego | −6 rep, scenka zakłopotania i przeprosin |
| Uczciwy klient, pewność < próg (zgrzyt do wyjaśnienia) | +0 rep, brak napiwku, „miał pan szczęście” | **+4 rep**, zgrzyt się wyjaśnia | −2 rep | −4 rep |
| Podejrzane zlecenie | **−25 rep**, scena następnego dnia (sąsiad, dzielnicowy), zlecenie znika z historii jako „nie powinienem był” | +0 rep, klient się wycofuje | **+5 rep**, napis „Dobrze, że pan odmówił” (później, od sąsiada) | **+6 rep**, chyba że klient był tylko zdenerwowany, wtedy +3 |

Zasady:
- **Brak ekranu „Game Over”.** Złe otwarcie kosztuje reputację i daje cichą, smutną scenkę, bez kar w stylu zręcznościówek.
- Podejrzanych zleceń nie da się „wygrać” otwarciem: nie przynoszą monet, nagrody ani wpisu do gabloty.
- Policja w grze jest uprzejma i zwyczajna. Żadnych pościgów.
- **Scena „dzień po” (V04, D-78):** każde zlecenie ma pole `after` (mówcy) i kwestie `<job_id>.after.N`. Po zakończeniu (otwarcie, naprawa, rozmowa, odmowa) przy następnym wejściu w listę zleceń gra pokazuje jedną krótką scenkę: zdjęcie miejsca za dnia, portret mówcy, kwestia; stuknięcie zamyka. Każda scenka tylko raz.

### 2.6 Bezpieczeństwo w scenach
- Gdy w historii pojawia się **zapach gazu, dym, osoba nieprzytomna albo dziecko samo w środku**, gra najpierw pokazuje kartę „Najpierw 112 / *Call emergency services first*”. Dopiero potem jest zamek. Takie sytuacje nie są zagadką na czas.
- Rosół, piekarnik czy wanna to **liczniki fabularne**: zmieniają dialog i najwyżej napiwek, nigdy nie przegrywasz przez nie poziomu. Domyślnie są włączone, a ustawienie „Spokojne zlecenia” je wyłącza.

### 2.7 Co sprawdzamy: lokal, rzecz czy zgoda (`verify_kind`, D-103)
Przycisk na przyjeździe (`job.verify`) i tytuł weryfikacji (`verify.title`) mówią, **co** ślusarz sprawdza — zależnie od tego, co otwiera. Pole danych `verify_kind` w każdym `game/data/jobs/*.json`:

| `verify_kind` | Kiedy | PL | EN | DE | FR | ES |
|---|---|---|---|---|---|---|
| `premises` | czyjeś mieszkanie, pokój, piwnica, altana, kiosk, wynajęty lokal — prawo do miejsca | Sprawdź prawo do lokalu | Check right of entry | Zutrittsrecht prüfen | Vérifier le droit d'accès | Comprobar derecho de entrada |
| `object` | rzecz: rower, skrzynia, szuflada, sekretarzyk, puszka, sejf, kłódka na przedmiocie — czy należy do klienta | Sprawdź, czyja to rzecz | Check who owns it | Prüfen, wem es gehört | Vérifier le propriétaire | Comprobar de quién es |
| `shared` | wspólne lub instytucjonalne miejsce albo rzecz otwierana w czyimś imieniu — zgoda, upoważnienie | Sprawdź zgodę na otwarcie | Check permission to open | Erlaubnis zum Öffnen prüfen | Vérifier l'autorisation | Comprobar la autorización |

Klucze: `premises` → `job.verify`, `verify.title` (bez zmian); pozostałe → `job.verify.<kind>`, `verify.title.<kind>`. Ten sam przyrostek (`JobRun.verify_key`) wybiera wariant notatki świadka (`verify.paper.witness.body.<kind>`) i ogólnych wymian przy kartach (`verify.ask/reply.<karta>.<n>.<kind>`: świadek, akt, faktura i list instytucji), gdy taki klucz istnieje. Odmowy mają rodzaj tego, o co klient prosi. Brak pola = `premises`.

Klasyfikacja 123 zleceń (36 × premises, 38 × object, 49 × shared; rozdział 13 dodany w D-111, rozdział 14 w D-119, rozdział 15 w D-123, rozdział 16 w D-126):

| Zlecenie | `verify_kind` | Dlaczego |
|---|---|---|
| `job.allotment_shed` | premises | własna altana na działce (legitymacja działkowca, działka na żonę) |
| `job.attic_drying_room` | shared | wspólna suszarnia bloku; dostęp potwierdza administrator |
| `job.bike_interview` | object | kłódka szyfrowa jego roweru; zdjęcie i paragon |
| `job.bramah_bureau` | object | sekretarzyk kupiony na aukcji; faktura |
| `job.brussels_townhouse` | premises | jej mieszkanie w Saint-Gilles; najem i sąsiad |
| `job.carol_singers_chest` | shared | skrzynia świetlicy; zgoda zarządczyni i uchwała, Mila nie decyduje |
| `job.cat_bathroom` | premises | łazienka we własnym mieszkaniu Marty |
| `job.ch13_01_balcony_boxes` | premises | komórka piwniczna pani Haliny; wykaz użytkowników i pani Zosia |
| `job.ch13_02_first_ice_cream` | object | zamrażarka Stefana przed kioskiem; faktura i pani Krysia |
| `job.ch13_03_allotment_gate` | shared | wspólna brama ogródków; uchwała zarządu ogrodu i gospodarz |
| `job.ch13_05_planted_key` | object | skrzynka Hani na nasiona; zdjęcie i tata, który ją zrobił |
| `job.ch13_06_bike_repair_stand` | shared | szafka z narzędziami pod opieką administracji osiedla; Borys jako wykonawca |
| `job.ch13_07_museum_night_case` | shared | gablota muzeum przed Nocą Muzeów; pismo dyrekcji |
| `job.ch13_09_pizzeria_terrace` | object | mały sejf Renaty w jej pizzerii; najem i faktura |
| `job.ch13_10_courtyard_door` | shared | tylne drzwi świetlicy na podwórko; jednogłośna uchwała i zarząd |
| `job.ch14_01_summer_storage` | premises | schowek Zuzanny w przechowalni akademika; wykaz portiera i legitymacja |
| `job.ch14_02_ship_time` | shared | skrzynka statku z księgą gości; potwierdzenie kapitana i Aino (naprawa chodu zegara) |
| `job.ch14_03_books_under_linden` | object | biblioteczka męża pani Ireny; dokument i pani Zosia |
| `job.ch14_05_cat_passport` | object | kuferek Marty z targu, odnawiany u Gosi; paragon i Gosia |
| `job.ch14_06_suitcase_flew_on` | premises | mieszkanie Kasi i Bartka; dowód, adres w aplikacji i sąsiad |
| `job.ch14_07_prize_cupboard` | shared | szkolna szafka z nagrodami; pismo dyrekcji i potwierdzenie sekretariatu |
| `job.ch14_09_summer_cinema` | shared | kabina projektora przy sali prób, własność uczelni; zgoda kierownika sali i pismo uczelni |
| `job.ch14_10_holiday_keys` | shared | szafka na zapasowe klucze w świetlicy; uchwała wspólnoty i zarząd |
| `job.ch15_01_wrong_envelope` | premises | mieszkanie pana Kazimierza; dowód i pani Teresa z piętra niżej |
| `job.ch15_02_apple_press` | shared | skrzynia z prasą do soku ogrodu działkowego; faktura na ogród i gospodarz ogrodu |
| `job.ch15_03_charleroi_box` | object | szkatułka dziadka Józefa przywieziona z Charleroi; dokument dziedziczenia i pani Martine |
| `job.ch15_05_first_vacation` | object | nowy sejf pana Stefana w jego kiosku; faktura i pani Krysia |
| `job.ch15_06_bike_by_train` | object | rower Agnieszki z zapięciem bez kluczyka; paragon z numerem ramy i rejestr osiedla |
| `job.ch15_07_skeleton_cupboard` | shared | szkolna szafa ze szkieletem z pracowni biologicznej; pismo dyrekcji i dokument Oli |
| `job.ch15_09_key_board` | shared | gablota z kluczami w portierni akademika; zgoda administracji i dokument portiera |
| `job.ch15_10_exam_lock` | object | zamek zrobiony przez Zuzannę na praktykach; legitymacja i pan Władysław |
| `job.ch16_01_bookmark_key` | object | kasetka pani Ireny z kartami czytelników biblioteczki spod lipy; dokument i pani Halina |
| `job.ch16_02_auction_safe` | object | sejf kupiony przez Gosię na licytacji, sprzedany zamknięty; faktura z licytacji i zdjęcie |
| `job.ch16_03_spare_in_the_lake` | premises | mieszkanie pani Teresy; dowód i pan Kazimierz z piętra wyżej |
| `job.ch16_05_wrong_padlock` | shared | schowek Igi w przechowalni akademika z cudzą kłódką; wykaz ze zgodą administracji i legitymacja |
| `job.ch16_06_salt_before_frost` | shared | osiedlowa szopa z solą i łopatami; zgoda administracji i faktura na kłódkę |
| `job.ch16_07_hour_back` | shared | drzwiczki mechanizmu zegara nad bramą kamienicy; uchwała wspólnoty i zgoda zarządu |
| `job.ch16_09_almost_right_key` | shared | szafka z dokumentami statku; zgoda armatora przy kapitanie i Aino |
| `job.ch16_10_thirteenth_envelope` | premises | warsztat ślusarza: uczennica sprawdza mistrza; pani Halina i list polecony na adres warsztatu |
| `job.charleroi_letters` | object | żelazna kasetka; znalazczyni przekazuje ją rodzinie |
| `job.christmas_eve_heat` | shared | szafka kontrolna we wspólnej kotłowni; zgoda zarządczyni |
| `job.community_notice_case` | shared | wspólna gablota ogłoszeń; zarządczyni i uchwała |
| `job.dollhouse_wooden_lock` | object | domek dla lalek pradziadka; rzecz w posiadaniu |
| `job.drummer_locker` | shared | szafka w sali prób; otwiera za zgodą kierownika sali |
| `job.edek_rehearsal_store` | shared | magazyn teatru uczelni; pismo administracji i portier |
| `job.finnish_sailor` | object | skrzynia marynarska Aino; kapitan potwierdza, że jej |
| `job.frozen_cellar_padlock` | premises | jej piwnica; aneks do najmu i wykaz lokatorów |
| `job.ghent_beguinage` | shared | magazyn zabytkowego beginażu; pismo instytucji i opiekun |
| `job.gosia_workbench_drawer` | object | szuflada kupionego stołu; paragon i zdjęcie odbioru |
| `job.grandma_broth` | premises | mieszkanie pani Haliny; sąsiadka i list |
| `job.grandpa_chest` | object | kufer dziadka Józefa; rzecz w domu matki (akt) |
| `job.halina_christmas_tin` | object | puszka z piernikami Haliny; zdjęcie i sąsiadka |
| `job.halina_recipe_box` | object | własna skrzynka z przepisami Haliny |
| `job.heating_service_cupboard` | shared | szafka z dziennikiem we wspólnym korytarzu kotłowni |
| `job.kiosk_shutter` | premises | kiosk Stefana (lokal firmy) |
| `job.krakow_antiquarian` | object | sejf szyfrowy antykwariusza i cudza kasetka |
| `job.krakow_tenement_gate` | shared | brama kamienicy; zarządca i uchwała |
| `job.krystyna_wooden_album` | object | skrzynka na zdjęcia zrobiona przez ojca Krystyny |
| `job.liege_bakery` | premises | tylne drzwi piekarni; najem i przejęcie firmy |
| `job.marta_poster_studio` | premises | wynajęta pracownia Marty |
| `job.museum_time_lock` | shared | skarbiec muzeum; pismo dyrekcji |
| `job.newlyweds_4am` | premises | mieszkanie nowożeńców; dowód, meldunek, sąsiad |
| `job.night_nurse` | premises | mieszkanie Agnieszki; zarządca i dowód |
| `job.pizzeria_pays_pizza` | premises | zaplecze pizzerii Renaty; najem i sąsiad |
| `job.refuse_aunt_alive` | premises | odmowa: mieszkanie ciotki, która żyje |
| `job.refuse_ch13_04_winter_bike` | object | odmowa: cudzy rower „niczyj”, przypięty od jesieni przy stojaku |
| `job.refuse_ch13_08_found_cashbox` | object | odmowa: znaleziona w piwnicy cudza kasetka („znalezione nie kradzione”) |
| `job.refuse_ch14_04_paid_week` | premises | odmowa: opłacone z góry wynajęte mieszkanie bez gospodarza („zapłaciłam, więc moje”) |
| `job.refuse_ch14_08_early_present` | object | odmowa: szafka taty z prezentem, którego Hania jeszcze nie dostała |
| `job.refuse_ch15_04_closed_attic` | shared | odmowa: strych zamknięty przez zarządczynię do czasu usunięcia gniazda szerszeni |
| `job.refuse_ch15_08_no_answer` | premises | odmowa: mieszkanie sąsiadki, która nie otwiera („martwię się, więc otwierać”) |
| `job.refuse_ch16_04_borrowed_barrow` | premises | odmowa: cudza altana, w której stoi własna, pożyczona taczka („wezmę tylko swoje”) |
| `job.refuse_ch16_08_roommates_room` | premises | odmowa: zamknięty pokój współlokatora we wspólnie wynajmowanym mieszkaniu |
| `job.refuse_ex_partner` | premises | odmowa: mieszkanie byłej partnerki |
| `job.refuse_rush_bribe` | premises | odmowa: mieszkanie siostry, dopłata za brak pytań |
| `job.refuse_sisters_flat` | premises | odmowa: mieszkanie siostry bez jej zgody |
| `job.refuse_t43_09_empty_flat` | premises | odmowa: cudze mieszkanie z ciemnymi oknami |
| `job.refuse_t43_10_early_clearance` | premises | odmowa: wynajęte mieszkanie przed terminem wydania |
| `job.refuse_t43_11_other_stall` | premises | odmowa: sąsiednie stoisko, cudzy lokal na targu |
| `job.refuse_t43_12_surprise_key` | shared | odmowa: świetlica wspólnoty bez zgody zarządczyni |
| `job.refuse_unapproved_repair` | shared | odmowa: wspólna szafka serwisowa, zarządczyni nie zna wizyty |
| `job.refuse_unapproved_stockroom` | premises | odmowa: magazyn cudzego sklepu |
| `job.refuse_wrong_letterbox` | object | odmowa: skrzynka na listy sąsiadów spod szesnastki |
| `job.roman_service_cupboard` | shared | szafka gospodarcza na klatce; zarządca i protokół wspólnoty |
| `job.shared_room_door` | shared | pomieszczenie wspólne po głosowaniu mieszkańców |
| `job.stefan_book_tin` | object | przenośna puszka Stefana na kłódkę szyfrową |
| `job.student_dorm` | premises | pokój 412 w akademiku; portier z listą |
| `job.swiatniki_journeyman_padlock` | object | kłódka czeladnicza, właściciel i twórca |
| `job.t43_09_01_winter_keys` | premises | mieszkanie Agnieszki; Roman potwierdza lokatorkę |
| `job.t43_09_02_blanket_cupboard` | shared | wspólna szafa na koce; zlecenie wspólnoty |
| `job.t43_09_03_wooden_postbox` | shared | rekwizyt muzeum; zlecenie kuratorki |
| `job.t43_09_04_choir_case` | object | skrzynka z nutami Mili; paragon, Teresa potwierdza czyja |
| `job.t43_09_05_receipt_safe` | object | mały sejf Stefana; faktura na niego |
| `job.t43_09_06_draughty_hall` | shared | boczne wejście bloku; zarządca i uchwała |
| `job.t43_09_08_spare_key_hook` | premises | mieszkanie Kazimierza (właściwe piętro) |
| `job.t43_10_01_renovator_bureau` | object | sekretarzyk kupiony przez Gosię; faktura |
| `job.t43_10_02_scaffold_store` | premises | wynajęty magazyn ekipy; najem i zarządca |
| `job.t43_10_03_exhibit_clock` | shared | wymontowany zegar muzeum; pismo i protokół przekazania |
| `job.t43_10_04_design_cabinet` | object | szafka Marty z próbkami; faktura szafki |
| `job.t43_10_05_porters_drawer` | shared | szuflada dyżurki; zlecenie administracji akademika |
| `job.t43_10_06_shared_room_entry` | shared | drzwi wspólnej sali; uchwała i zarządczyni |
| `job.t43_11_01_wooden_market` | shared | skrzynia muzeum na targu; zlecenie kuratorki |
| `job.t43_11_02_bicycle_stand` | object | rower wystawowy Borysa; paragon i zdjęcie |
| `job.t43_11_03_tool_exchange` | object | skrzynia z narzędziami Władysława; faktura |
| `job.t43_11_04_sailors_stall` | object | prywatna skrzynia Aino; faktura i kapitan |
| `job.t43_11_05_rehearsal_chest` | shared | skrzynia sceniczna sali; pismo organizatora i opiekun |
| `job.t43_11_07_wrong_delivery` | premises | kiosk pod złym numerem; konsultacja bez otwierania |
| `job.t43_12_01_letters_archive` | object | sejf Krystyny z listami; dokument własności i spadku |
| `job.t43_12_02_detective_cabinet` | shared | skrzynia pokazowa muzeum; pismo dyrekcji |
| `job.t43_12_03_community_store` | shared | wspólny magazynek z krzesłami; uchwała |
| `job.t43_12_04_school_box` | shared | skrzynia szkoły; pisemna zgoda szkoły |
| `job.t43_12_05_tea_fund_case` | shared | kasetka funduszu wspólnoty; uchwała, dwoje opiekunów |
| `job.t43_12_07_clock_back_home` | shared | zegar muzeum po transporcie; pismo dyrekcji |
| `job.t43_12_08_henryks_bench` | object | skrzynia ćwiczebna Henryka przekazana z warsztatem |
| `job.time_capsule` | shared | kapsuła czasu klasy 3b; zgoda szkoły przy wszystkich |
| `job.uncle_safe_heirs` | shared | sejf trojga spadkobierców; potrzebna zgoda wszystkich |
| `job.warm_room_for_neighbours` | shared | świetlica wspólnoty; zgoda zarządczyni przez telefon |
| `job.widow_bureau` | object | sekretarzyk zmarłego męża w domu pani Ireny |
| `job.wigilia_table_drawer` | shared | kredens świetlicy; zgoda zarządczyni i uchwała |
| `job.winter_bicycle_cellar` | premises | miejsce w piwnicznej rowerowni; aneks do najmu |
| `job.wooden_winter_village` | shared | kaseta muzeum w depozycie świetlicy; upoważnienie |
| `job.wrong_floor` | premises | mieszkanie piętro niżej (cudze drzwi) |
| `job.zuzanna_catalogue_drawer` | shared | szuflada muzeum; protokół użyczenia kopii |


---

## 3. Wycena (mechanika)

Monety gry (ikona: krążek z wybitym kluczem płaskim, nie złoto). Liczby są robocze.

**Cena bazowa (B)** według tieru zamka: T1 = 60, T2 = 90, T3 = 130. Do tego **dojazd** 15 (poza rozdziałem miejskim 30).

**Mnożnik pory (M)**:

| Pora | Godziny w grze | M |
|---|---|---|
| Dzień | 7:00–19:59 | ×1,0 |
| Wieczór | 20:00–22:59 | ×1,25 |
| Noc | 23:00–6:59 | ×1,5 |
| Niedziela / święto | cały dzień | ×1,75 |
| Noc świąteczna (Wigilia, Sylwester, Wielkanoc) | 23:00–6:59 | ×2,0 |

**Wycena = (B × M) + dojazd**, zaokrąglona do 5.

Zasady:
- Wycenę gracz pokazuje **przed** stołem dowodów. Klient może ją zaakceptować, zapytać („dlaczego tyle?”) albo się wycofać (rzadko: emeryci, studenci). Gracz może dać **rabat sąsiedzki** (−20%), co daje +1 rep i mniej monet.
- **Rachunek końcowy ≤ wycena + 10%**. Więcej oznacza −5 rep i komentarz klienta. Gra nie pozwala „zdzierać” i promuje uczciwą cenę.
- **Metoda niszcząca** (wymiana wkładki itp.): dodatkowa karta „Uprzedzam: koszt części 40” / *"Heads-up: the part costs 40"*. Klient zgadza się albo odmawia. Bez zgody część idzie na koszt gracza i jest −6 rep.
- **Napiwek**: 0–30% za otwarcie bez śladów, szybkie (wg licznika fabularnego, jeśli włączony) i ze spokojnym dialogiem. Napiwek nigdy nie zależy od wyglądu klienta.
- **Płatność w naturze** (pizza, gofry, ogórki) zastępuje monety przedmiotem kosmetycznym do warsztatu ślusarza (np. pudełko po pizzy na półce). W statystykach to pełna zapłata.

---

## 4. Miasto, dzielnice, rozdziały

Miasto jest **fikcyjne**, polskie i średniej wielkości (robocza nazwa: **Zameczno**, do sprawdzenia kolizji). Wyjazdy w rozdziałach 4–5 to realne miejsca: Kraków, Świątniki Górne i Belgia (Bruksela, Gandawa, Liège). Pokazujemy je z szacunkiem, bez kpin i stereotypów.

| Dzielnica (klucz) | PL | EN | Typowi klienci | Typowe zamki |
|---|---|---|---|---|
| `district.oldtown` | Śródmieście (kamienice) | Old Town | emeryci, studenci, antykwariusze | zapadkowe, dźwigniowe, wkładki |
| `district.sunny_estate` | Osiedle Słoneczne (bloki) | Sunny Estate | rodziny, pielęgniarki, kierowcy | wkładki, magnetyczne, dimple |
| `district.campus` | Kampus | Campus | studenci, portierzy, zespoły muzyczne | wkładki, rurkowe, szyfrowe |
| `district.night_market` | Nocny Rynek (gastronomia, kluby) | Night Market | restauratorzy, DJ-e, piekarze | dźwigniowe, płytkowe kłódki |
| `district.villa_hill` | Willowa Górka (domy, strychy) | Villa Hill | spadkobiercy, wdowy, kolekcjonerzy | skrzynie, sekretarzyki, sejfy |
| `district.allotments` | Ogródki działkowe nad rzeką | Allotments | działkowcy | kłódki płytkowe i szyfrowe |
| `district.port` | Port i Muzeum Techniki | Harbour & Museum | marynarze, kuratorzy | tarczowe, czasowe, Bramah |

| Rozdział | PL | EN | Dzielnice | Nowe rodziny | Temat |
|---|---|---|---|---|---|
| 1 | Pierwsza zmiana | First Shift | Śródmieście, Osiedle, Kampus | zapadkowy, szyfrowa, wkładka T1, płytkowy | Uczysz się weryfikacji i wyceny. Pierwsza odmowa. |
| 2 | Nocne dyżury | Night Calls | Nocny Rynek, Osiedle, Kampus | magnetyczny, rurkowy, wkładka T2 | Stawki nocne, zmęczeni ludzie, pomyłki. |
| 3 | Strychy i spadki | Attics and Inheritances | Willowa Górka, Ogródki | egipski (zabawka), dźwigniowy, sejf z tarczami | Rodziny, pamięć, sprawiedliwość. |
| 4 | Małopolska | Lesser Poland | Kraków, Świątniki Górne | zapadkowy T3, kłódka świątnicka | Tradycja zawodu, gablota polska. |
| 5 | Pociąg do Brukseli | Train to Brussels | Bruksela, Gandawa, Liège | dimple / listwa boczna, dźwigniowy z detektorem | Karta ślusarza (kodeks FOD), inny język, ta sama uczciwość. |
| 6 | Skarbiec | The Vault | Port, Muzeum, Śródmieście | Bramah, tarczowy, zamek czasowy, szyfrowa T3 | Historia zamków, finał z kapsułą czasu. |

---

## 5. Zlecenia (28)

Format: **id** · tytuł PL / EN · klient · sytuacja · scena (PL, EN) · zamek (rodzina, tier) · weryfikacja · presja · nagroda · rozdział, dzielnica · ton.
Tier: T1 wprowadzenie, T2 rozwinięcie, T3 mistrzowski. Nagrody w monetach podane orientacyjnie, według wzoru z rozdz. 3.
T1–T3 to skala fabularna tego dokumentu (i cennika). Pole `tier` w `game/data/jobs/*.json` to **tier lockcore** danej
rodziny i musi mieścić się w jej zakresie z `lockcore/tiers.json` (D-118, pilnuje tego `data/tools/validate.py`):
np. „dźwigniowy, T1” to w danych `lever` 3, „zapadkowy, T3” to `warded` 2, „dźwigniowy z detektorem, T2” to `lever_detector` 5.

### Rozdział 1 — Pierwsza zmiana

#### `job.grandma_broth`
- **Tytuł:** Rosół na gazie / *Broth on the Stove*
- **Klient:** pani Halina, 81 lat. Wyszła wyrzucić śmieci w kapciach, mówi „synku” i jest pewna, że wszystko pamięta.
- **Sytuacja:** Drzwi się zatrzasnęły, a w środku na małym ogniu stoi rosół. Sąsiadka pani Zosia już zakręciła gaz głównym zaworem na klatce, więc nikomu nic nie grozi. Chodzi tylko o rosół.
- **Scena:**
  - PL — **Halina:** Synku, ja tylko na chwilkę wyszłam. / **Zosia:** Gaz zakręciłam, Halinko, nie denerwuj się. / **Ślusarz:** To spokojnie. Pani Zosiu, pani zna sąsiadkę? / **Zosia:** Czterdzieści lat przez ścianę! / **Halina:** Makaron sama robiłam, niech pan zostanie na talerz.
  - EN — **Halina:** I only stepped out for a moment, dear. / **Zosia:** I turned the gas off, Halina, don't fret. / **Locksmith:** Then no rush. Mrs Zosia, you know your neighbour? / **Zosia:** Forty years through the wall! / **Halina:** I made the noodles myself — stay for a bowl.
- **Zamek:** zapadkowy, T1 (stare drzwi z zamkiem wpuszczanym).
- **Weryfikacja:** sąsiadka-świadek (2) i list na nazwisko w skrzynce (1), do tego szczegół z wnętrza: „na kredensie zdjęcie z wnukiem w mundurku”. Haczyk: brak.
- **Presja:** licznik fabularny „rosół” w 3 etapach (pyrka, bulgocze, „trochę wyparował”). Nie wpływa na wynik, tylko na dialog. Pierwsza karta „Najpierw 112” pojawia się w tutorialu jako przykład, bo gaz został zakręcony.
- **Nagroda:** 75 monet (stawka dzienna) i talerz rosołu (przedmiot w warsztacie: termos).
- **Rozdział / dzielnica:** 1, Śródmieście.
- **Ton:** ciepły.

#### `job.cat_bathroom`
- **Tytuł:** Ziemniak w łazience / *Potato in the Bathroom*
- **Klient:** Marta, 34 lata, grafik, pracuje z domu, ma kota Ziemniaka.
- **Sytuacja:** Kot skoczył na klamkę i zamknął się od środka w łazience na zasuwkę z zapadką. Marta stoi w swoim mieszkaniu, a kot miauczy przez drzwi z coraz większym oburzeniem.
- **Scena:**
  - PL — **Marta:** On to zrobił specjalnie. Patrzył mi w oczy. / **Ślusarz:** Koty tak mają. Weryfikacji nie robimy, pani jest w środku. / **Marta:** A jak on się przestraszy? / **Ślusarz:** Niech pani do niego mówi. Ja będę cicho.
  - EN — **Marta:** He did it on purpose. He looked me in the eye. / **Locksmith:** Cats do that. No ID check needed — you're already inside. / **Marta:** What if he panics? / **Locksmith:** Keep talking to him. I'll be quiet.
- **Zamek:** zapadkowy, T1 (zamek łazienkowy), wariant samouczka.
- **Weryfikacja:** próg 0, bo klient jest w swoim mieszkaniu. Zlecenie uczy, że weryfikacja zależy od sytuacji.
- **Presja:** brak. Miauczenie jest ambientem (z napisami dla niesłyszących).
- **Nagroda:** 60 monet, rabat sąsiedzki proponowany domyślnie i zdjęcie Ziemniaka na lodówce w warsztacie.
- **Rozdział / dzielnica:** 1, Osiedle Słoneczne.
- **Ton:** zabawny.

#### `job.bike_interview`
- **Tytuł:** Rozmowa o 9:30 / *Interview at 9:30*
- **Klient:** Kuba, 23 lata, świeżo po studiach, ma pożyczoną marynarkę i jedzie na pierwszą rozmowę o pracę.
- **Sytuacja:** Zmienił kod w kłódce rowerowej „na bezpieczniejszy” i go zapomniał. Rower stoi przy stojaku pod jego blokiem, a rozmowa jest o 9:30 na drugim końcu miasta.
- **Scena:**
  - PL — **Kuba:** Zmieniłem kod wczoraj. Na pewno było tam siedem. Albo dwa. / **Ślusarz:** Ma pan zdjęcie z tym rowerem? / **Kuba:** Mam, z wakacji. I paragon w mailu. / **Ślusarz:** Wystarczy. Niech pan w tym czasie poprawi krawat.
  - EN — **Kuba:** I changed the code yesterday. There was definitely a seven. Or a two. / **Locksmith:** Got a photo with this bike? / **Kuba:** From the holidays. And the receipt in my email. / **Locksmith:** That'll do. Fix your tie while I work.
- **Zamek:** kłódka szyfrowa, T1.
- **Weryfikacja:** zdjęcie (1) i paragon (1), czyli rzecz w posiadaniu, próg 2. Haczyk: brak.
- **Presja:** licznik „autobus 8:52” (opcjonalny). Gdy się spóźni, Kuba jedzie taksówką i i tak dostaje pracę, tylko z innym dialogiem.
- **Nagroda:** 65 monet. W rozdziale 3 przychodzi kartka: „Dostałem! Pracuję w biurze projektowym. Kuba.”
- **Rozdział / dzielnica:** 1, Osiedle Słoneczne.
- **Ton:** ciepły, zabawny.

#### `job.student_dorm`
- **Tytuł:** Pokój 412 / *Room 412*
- **Klient:** Zuzanna, 20 lat, studentka konserwacji zabytków, przyniosła torbę pełną pędzli.
- **Sytuacja:** Klucz został w środku, a współlokatorka jest na praktykach w Toruniu. Portier ma listę lokatorów, ale nie ma zapasowego klucza, bo „ktoś nie oddał”.
- **Scena:**
  - PL — **Portier:** Zuzanna Wilk, czterysta dwanaście, zgadza się. / **Zuzanna:** Ja nawet legitymację mam w środku… / **Ślusarz:** Pan portier za panią ręczy, to wystarczy. / **Zuzanna:** Pan wie, że ja jutro mam egzamin z zamków? Z historycznych.
  - EN — **Porter:** Zuzanna Wilk, four-twelve, that's right. / **Zuzanna:** Even my student card's inside… / **Locksmith:** The porter vouches for you. That's enough. / **Zuzanna:** I've got an exam on locks tomorrow, you know. Historical ones.
- **Zamek:** wkładka bębenkowa, T1.
- **Weryfikacja:** portier z listą (3) i dowód (1). Haczyk: brak.
- **Presja:** brak.
- **Nagroda:** 70 monet. Zuzanna zostawia notatki, które odblokowują notkę gabloty `showcase.roman_ring_key`.
- **Rozdział / dzielnica:** 1, Kampus.
- **Ton:** ciepły.

#### `job.kiosk_shutter`
- **Tytuł:** Kiosk przed szóstą / *The Kiosk Before Six*
- **Klient:** pan Stefan, 67 lat. Kiosk prowadzi od 1994 r. i zna wszystkich na przystanku po imieniu.
- **Sytuacja:** Zardzewiała kłódka przy rolecie nie chce się otworzyć, a za pół godziny przyjedzie pierwszy autobus z ludźmi, którzy chcą gazetę i bilet.
- **Scena:**
  - PL — **Stefan:** Trzydzieści lat ta kłódka, nigdy jej nie oliwiłem. / **Ślusarz:** No to widać. Umowa dzierżawy jest? / **Stefan:** W segregatorze, w środku. Ale pani Krysia z piekarni panu powie. / **Krysia:** Stefan tu stoi dłużej niż przystanek!
  - EN — **Stefan:** Thirty years, this padlock. Never oiled it once. / **Locksmith:** It shows. Got the lease? / **Stefan:** In a binder, inside. But Krysia from the bakery will tell you. / **Krysia:** Stefan's been here longer than the bus stop!
- **Zamek:** płytkowy (kłódka), T1.
- **Weryfikacja:** świadek (2) i list z hurtowni prasy na nazwisko (1). Próg dla lokalu firmy to 4, więc zabraknie 1 pewności. Rozwiązanie: „Poproszę o coś jeszcze”, czyli Stefan pokazuje zdjęcie z otwarcia kiosku w 1994. Uczy dopytywania.
- **Presja:** licznik „pierwszy autobus 5:58” (opcjonalny).
- **Nagroda:** 80 monet (stawka nocna do 6:59) i darmowa gazeta co rano w warsztacie (przedmiot).
- **Rozdział / dzielnica:** 1, Osiedle Słoneczne.
- **Ton:** ciepły.

#### `job.refuse_ex_partner` ⚠ do odmowy
- **Tytuł:** „To przecież też moje” / *"It's Half Mine Anyway"*
- **Klient:** mężczyzna ok. 40 lat. Przedstawia się jako „Darek”, jest zdenerwowany i trzyma telefon ekranem do dołu.
- **Sytuacja:** Chce wejść do mieszkania byłej partnerki, „po swoje rzeczy”. Mówi, że ona „nie odbiera specjalnie”. Na skrzynce jest jedno nazwisko i nie jest to jego nazwisko.
- **Scena:**
  - PL — **Darek:** Mieszkałem tu trzy lata. Mam prawo. / **Ślusarz:** Rozumiem. Ma pan coś, co to potwierdza? Umowę, meldunek? / **Darek:** Wszystko jest w środku, dlatego pana wołam. / **Ślusarz:** W takich sprawach nie otwieram. Mogę zadzwonić na policję, oni pomogą odebrać rzeczy. / **Darek:** …Nie trzeba.
  - EN — **Darek:** I lived here three years. I have every right. / **Locksmith:** I hear you. Anything that shows it? A lease, an address? / **Darek:** It's all inside — that's why I called you. / **Locksmith:** I don't open in situations like this. I can call the police — they can help you collect your things. / **Darek:** …Forget it.
- **Zamek:** wkładka bębenkowa, T2 (nieważne, bo gracz nie powinien zaczynać).
- **Weryfikacja:** dowód (1). Zgrzyty: `flag.ex_partner` i `flag.no_witness` (odmawia, gdy proponujesz sąsiada).
- **Presja:** naciskanie słowne, bez timera.
- **Nagroda:** brak monet. Za odmowę +5 rep, a w rozdziale 2 sąsiadka z tego bloku zleca otwarcie piwnicy i mówi: „Dobrze, że pan wtedy nie otworzył”.
- **Rozdział / dzielnica:** 1, Osiedle Słoneczne.
- **Ton:** poważny, spokojny. Bez przemocy, bez wyjaśniania, co Darek chciał zrobić.

### Rozdział 2 — Nocne dyżury

#### `job.newlyweds_4am`
- **Tytuł:** Czwarta nad ranem po weselu / *4 a.m., After the Wedding*
- **Klient:** Ola i Bartek, ona w welonie przekrzywionym na bok, on z bukietem pod pachą.
- **Sytuacja:** Klucze zostały w torebce świadkowej, która pojechała z ciocią do Kalisza. Na wycieraczce stoi pudło z tortem, a oboje po oczepinach nie mają już siły na nic.
- **Scena:**
  - PL — **Bartek:** Dowód mam, ale tam nie ma adresu, wiem, wiem. / **Ola:** W mObywatelu mam meldunek! Tutaj, widzi pan? / **Sąsiad (w szlafroku):** Ja ich znam, oni się dziś pobrali, całe osiedle słyszało. / **Ślusarz:** Wszystkiego najlepszego. Dwie minuty. / **Ola:** Zostaje pan na tort? On jest trzypiętrowy.
  - EN — **Bartek:** I've got ID, but there's no address on it, I know. / **Ola:** My registered address is in the app! See? / **Neighbour (in a bathrobe):** I know them, they got married today — the whole block heard. / **Locksmith:** Congratulations. Two minutes. / **Ola:** Stay for cake? It's three tiers.
- **Zamek:** wkładka bębenkowa, T2.
- **Weryfikacja:** dowód (1), meldunek w aplikacji (2) i sąsiad (2). Haczyk: brak. Scena pokazuje, że dowód bez adresu to normalna rzecz.
- **Presja:** brak, tylko senność (ziewanie animowane).
- **Nagroda:** 150 monet (noc ×1,5), napiwek i kawałek tortu (przedmiot: talerzyk z różyczką z kremu).
- **Rozdział / dzielnica:** 2, Osiedle Słoneczne.
- **Ton:** zabawny, ciepły.

#### `job.pizzeria_pays_pizza`
- **Tytuł:** Zapłata w pizzy / *Paid in Pizza*
- **Klient:** pani Renata, 52 lata, właścicielka pizzerii „U Renaty”. Mówi szybko i ma mąkę na łokciach.
- **Sytuacja:** O 23:30, po zamknięciu, zatrzasnęło się zaplecze, a w środku jest ciasto na jutro i kasa fiskalna. Pani Renata ma przy sobie wszystko poza kluczem i nie ma pieniędzy, bo utarg jest w kasie.
- **Scena:**
  - PL — **Renata:** Pieniądze są w środku, więc… płacę w pizzy. Ile pan zje? / **Ślusarz:** Najpierw wycena, potem menu. Umowa najmu lokalu? / **Renata:** W telefonie. A pan Mietek z kebabu obok mnie zna od dwudziestu lat. / **Mietek:** Zna, zna. Jej margherita to jest sztuka.
  - EN — **Renata:** The cash is inside, so… I'll pay in pizza. How much can you eat? / **Locksmith:** Quote first, menu second. Lease for the place? / **Renata:** On my phone. And Mietek from the kebab shop next door has known me twenty years. / **Mietek:** True. Her margherita is a work of art.
- **Zamek:** dźwigniowy, T1.
- **Weryfikacja:** umowa najmu (2) i świadek-sąsiad z lokalu obok (2). Haczyk: brak.
- **Presja:** brak.
- **Nagroda:** płatność w naturze: karnet „10 pizz” (przedmiot kosmetyczny, pudełka piętrzą się w warsztacie). Gracz może też poprosić o monety, wtedy pani Renata płaci rano z utargu, a scena jest równie ciepła.
- **Rozdział / dzielnica:** 2, Nocny Rynek.
- **Ton:** zabawny.

#### `job.night_nurse`
- **Tytuł:** Po dwunastu godzinach / *After a Twelve-Hour Shift*
- **Klient:** Agnieszka, 45 lat, pielęgniarka z oddziału wewnętrznego, w kurtce narzuconej na uniform.
- **Sytuacja:** O 7:20 wraca z nocnego dyżuru, a klucz zostawiła w szafce w szpitalu. Nowy blok ma wkładkę z kluczem magnetycznym, którą zamontował deweloper.
- **Scena:**
  - PL — **Agnieszka:** Ja chcę tylko spać. Przepraszam, że tak mówię. / **Ślusarz:** Niech pani mówi, jak chce. Zarządca jest na miejscu? / **Zarządca (przez domofon):** Pani Agnieszka spod czternastki, tak. Umowę mam w systemie. / **Ślusarz:** No to idzie pani spać.
  - EN — **Agnieszka:** I just want to sleep. Sorry for being blunt. / **Locksmith:** Be as blunt as you like. Is the building manager around? / **Manager (on intercom):** Agnieszka in fourteen, yes. Lease is in the system. / **Locksmith:** Then off to bed you go.
- **Zamek:** magnetyczny, T1.
- **Weryfikacja:** zarządca (3) i dowód (1). Haczyk: brak.
- **Presja:** brak.
- **Nagroda:** 90 monet (stawka dzienna od 7:00). Gracz może dać rabat „dla służby zdrowia” (−20%). Nie ma kary za brak rabatu, a z rabatem jest +1 rep.
- **Rozdział / dzielnica:** 2, Osiedle Słoneczne.
- **Ton:** ciepły, cichy.

#### `job.wrong_floor`
- **Tytuł:** Piętro niżej / *One Floor Down*
- **Klient:** pan Kazimierz, 60 lat, wraca z imienin szwagra i jest w świetnym humorze.
- **Sytuacja:** Dzwoni, że „zamek się zepsuł, bo klucz nie pasuje”. Na drzwiach wisi wieniec z suszonych kwiatów, którego pan Kazimierz „nie pamięta”, a na skrzynce jest inne nazwisko.
- **Scena:**
  - PL — **Kazimierz:** Klucz nie wchodzi, cholerstwo. / **Ślusarz:** Panie Kazimierzu, a który to numer? / **Kazimierz:** Dwadzieścia… jeden? / **Ślusarz:** To jest dziewiętnaście. Chodźmy piętro wyżej. / **Kazimierz (otwiera swoim kluczem):** O! Naprawił pan!
  - EN — **Kazimierz:** Key won't go in, the blasted thing. / **Locksmith:** Mr Kazimierz, what number is yours? / **Kazimierz:** Twenty… one? / **Locksmith:** This is nineteen. Let's go up a floor. / **Kazimierz (opens with his own key):** Ha! You fixed it!
- **Zamek:** wkładka bębenkowa, T1. Nie jest potrzebny, bo zlecenie rozwiązuje się bez otwierania.
- **Weryfikacja:** zgrzyty `flag.contradiction` (inne nazwisko na skrzynce) i szczegół (wieniec). Najlepszy wynik daje „Poproszę o coś jeszcze”. Gdy gracz otworzy drzwi, ma −25 rep i scenę „to nie było jego mieszkanie”: mieszkająca tu pani Teresa jest w szoku.
- **Presja:** brak.
- **Nagroda:** sam dojazd (20 monet, noc) i +4 rep. Rano pan Kazimierz przynosi ciasto z imienin.
- **Rozdział / dzielnica:** 2, Osiedle Słoneczne.
- **Ton:** zabawny. Uczy, że weryfikacja chroni też klienta.

#### `job.refuse_rush_bribe` ⚠ do odmowy
- **Tytuł:** „Siostra kazała” / *"My Sister Said It's Fine"*
- **Klient:** mężczyzna w garniturze, mówi uprzejmie i bardzo szybko.
- **Sytuacja:** O 1:00 w nocy chce wejść do mieszkania „siostry, która jest za granicą”, bo „zostawiła dokumenty, które muszę wysłać rano”. Siostra nie odbiera. Na pytanie o sąsiada odpowiada propozycją dopłaty.
- **Scena:**
  - PL — **Klient:** Podwójna stawka. Potrójna. Tylko bez tych procedur. / **Ślusarz:** Procedury to akurat jedyne, czego pan nie może dopłacić. / **Klient:** Siostra by się zgodziła. / **Ślusarz:** To niech zadzwoni. Poczekam pięć minut. / *(nikt nie dzwoni)* / **Ślusarz:** Dobranoc.
  - EN — **Customer:** Double rate. Triple. Just skip the formalities. / **Locksmith:** The formalities are the one thing you can't pay me to skip. / **Customer:** My sister would say yes. / **Locksmith:** Then she can call. I'll wait five minutes. / *(no call)* / **Locksmith:** Goodnight.
- **Zamek:** wkładka bębenkowa, T2.
- **Weryfikacja:** dowód (1), w którym inne nazwisko niż na drzwiach „ma wyjaśnić” rozwód siostry. Zgrzyty: `flag.rush_bribe`, `flag.absent_owner`, `flag.no_witness`.
- **Presja:** naciskanie słowne i pieniądze na ekranie (karta „×3”). To jedyne miejsce w grze, gdzie wycena rośnie sama, i to jest sygnał ostrzegawczy.
- **Nagroda:** odmowa daje +5 rep, policja +6. Otwarcie daje −25 rep i 0 monet: pieniądze „się nie zgadzają”, a następnego dnia przychodzi dzielnicowy z pytaniami. Scena jest symboliczna i nie pokazuje, co się stało w mieszkaniu.
- **Rozdział / dzielnica:** 2, Śródmieście.
- **Ton:** napięty, spokojny.

#### `job.drummer_locker`
- **Tytuł:** Pałki w szafce / *Drumsticks in the Locker*
- **Klient:** Iga, 27 lat, perkusistka zespołu „Kwaśne Jabłka”, z kolczykiem w brwi i bardzo dobrą punktualnością.
- **Sytuacja:** W sali prób na kampusie zatrzasnęła kluczyk w szafce z rurkowym zamkiem. Są tam pałki, odsłuchy i setlista, a koncert w klubie zaczyna się za godzinę.
- **Scena:**
  - PL — **Iga:** Mogę grać łyżkami, ale wolałabym nie. / **Kierownik sali:** Szafka numer osiem, Iga płaci za nią co miesiąc, mam w zeszycie. / **Ślusarz:** Zeszyt mi wystarczy. / **Iga:** Jak pan zdąży, gramy dla pana numer.
  - EN — **Iga:** I can play with spoons, but I'd rather not. / **Room manager:** Locker eight — Iga pays for it monthly, it's in my notebook. / **Locksmith:** The notebook's good enough for me. / **Iga:** Make it in time and we'll play you a song.
- **Zamek:** rurkowy, T1.
- **Weryfikacja:** kierownik sali (3). Haczyk: brak.
- **Presja:** licznik „próba dźwięku” (opcjonalny).
- **Nagroda:** 110 monet (wieczór ×1,25) i wejściówka. W warsztacie pojawia się plakat zespołu.
- **Rozdział / dzielnica:** 2, Kampus.
- **Ton:** zabawny.

### Rozdział 3 — Strychy i spadki

#### `job.grandpa_chest`
- **Tytuł:** Skrzynia dziadka Józefa / *Grandpa Józef's Chest*
- **Klient:** Ola, 38 lat, nauczycielka biologii, i jej mama Krystyna.
- **Sytuacja:** Na strychu domu po dziadku stoi okuta skrzynia, do której klucza nikt nie widział od pogrzebu. Dom należy teraz do mamy. Ola podejrzewa, że w skrzyni są listy z czasów, gdy dziadek pracował w Belgii w kopalni.
- **Scena:**
  - PL — **Krystyna:** Tato nigdy nie mówił, co tam trzyma. / **Ola:** Mamo, pan nie pyta o skrzynię, pan pyta, czy to twój dom. / **Krystyna:** Mój, akt mam w szufladzie. / **Ślusarz:** To zostaje tylko otworzyć bez rysy. Ten zamek jest starszy niż my wszyscy.
  - EN — **Krystyna:** Dad never said what he kept in there. / **Ola:** Mum, he's not asking about the chest, he's asking if it's your house. / **Krystyna:** It's mine — the deed's in the drawer. / **Locksmith:** Then all that's left is opening it without a scratch. This lock is older than all of us.
- **Zamek:** zapadkowy, T3 (zamek skrzyniowy z kilkoma ostrogami).
- **Weryfikacja:** akt (3) i rzecz w posiadaniu (1). Haczyk: brak.
- **Presja:** brak.
- **Nagroda:** 140 monet. W skrzyni leżą listy pisane z Charleroi w latach 50., co otwiera wątek do rozdziału 5. Gablota dostaje zdjęcie skrzyni (pamiątka osobista, nie notka historyczna).
- **Rozdział / dzielnica:** 3, Willowa Górka.
- **Ton:** wzruszający.

#### `job.uncle_safe_heirs`
- **Tytuł:** Sejf wujka Bogdana / *Uncle Bogdan's Safe*
- **Klient:** rodzeństwo Ewa, Marek i Piotr, każde z własną teorią, co jest w sejfie.
- **Sytuacja:** Wujek zostawił sejf z tarczami, a szyfr zabrał do grobu. Spadek jest wspólny. Marek przyjechał pierwszy i chce otworzyć „od razu, przecież i tak się podzielimy”. Ewa jedzie z Gdańska.
- **Scena:**
  - PL — **Marek:** Pan otworzy, ja popatrzę i powiem reszcie. / **Ślusarz:** Otworzę, kiedy wszyscy spadkobiercy będą przy stole albo dadzą zgodę na piśmie. / **Piotr:** Ewa będzie za godzinę. / **Marek:** …No dobra. Kawy? / **Ewa (później):** Wujek by się śmiał, że my się o to kłócimy.
  - EN — **Marek:** You open it, I'll take a look and tell the others. / **Locksmith:** I'll open it when all the heirs are at the table, or have agreed in writing. / **Piotr:** Ewa's an hour away. / **Marek:** …Fine. Coffee? / **Ewa (later):** Uncle would laugh at us fighting over this.
- **Zamek:** sejf z tarczami, T1 (pierwszy sejf w grze; do D-118 T2).
- **Weryfikacja:** postanowienie o stwierdzeniu nabycia spadku albo akt poświadczenia dziedziczenia (3), w scenie jako karta „dokument od notariusza”. Haczyk: zgrzyt „niepełny skład”. Wybór „Poproszę o coś jeszcze” (czekamy na Ewę) daje najlepszy wynik. Otwarcie przy samym Marku to −8 rep i kłótnia w rodzinie, w której gracz zostaje świadkiem.
- **Presja:** brak.
- **Nagroda:** 120 monet i dodatkowe 20 za czekanie (wycena „za godzinę oczekiwania”, uczciwie podana z góry). W sejfie jest klaser ze znaczkami i kartka „Dla całej trójki po równo. Nie kłóćcie się. B.”
- **Rozdział / dzielnica:** 3, Willowa Górka.
- **Ton:** zabawny, potem wzruszający.

#### `job.dollhouse_wooden_lock`
- **Tytuł:** Domek pradziadka / *Great-Grandpa's Dollhouse*
- **Klient:** Hania, 7 lat, i jej tata Tomasz, stolarz z trzeciego pokolenia.
- **Sytuacja:** Pradziadek zrobił domek dla lalek z drewnianym zamkiem na kołki, „takim jak w starożytności”. Drewniany klucz zginął w przeprowadzce, a w środku jest ulubiona lalka Hani.
- **Scena:**
  - PL — **Hania:** Pani Lala tam siedzi od wtorku. / **Tomasz:** Dziadek mówił, że to zamek egipski. Nie wiem, czy to prawda. / **Ślusarz:** Taka nazwa się przyjęła. Historia jest ciekawsza, opowiem po robocie. / **Hania:** A pan zrobi nowy klucz? Drewniany?
  - EN — **Hania:** Miss Lala's been stuck in there since Tuesday. / **Tomasz:** Grandpa called it an Egyptian lock. Not sure that's true. / **Locksmith:** The name stuck. The real story's better — I'll tell you after. / **Hania:** Will you make a new key? A wooden one?
- **Zamek:** egipski drewniany, T1.
- **Weryfikacja:** rzecz w posiadaniu (2). Haczyk: brak.
- **Presja:** brak.
- **Nagroda:** 50 monet (rabat dziecięcy w dialogu, a tata płaci pełną kwotę) i rysunek Hani. Odblokowuje notkę `showcase.egyptian_name`.
- **Rozdział / dzielnica:** 3, Willowa Górka.
- **Ton:** ciepły.

#### `job.allotment_shed`
- **Tytuł:** Altana pana Zbyszka / *Mr Zbyszek's Shed*
- **Klient:** pan Zbyszek, 74 lata, działkowiec. Pomidory „Malinowy Ożarowski” to jego duma.
- **Sytuacja:** Kłódka na altanie zarosła rdzą po zimie. W środku są konewki i nasiona na wysiew. Działka jest zapisana na żonę, która „siedzi w domu z kolanem”.
- **Scena:**
  - PL — **Zbyszek:** Działka na żonę, ale to ja tu kopię. / **Ślusarz:** Legitymacja działkowca jest? / **Zbyszek:** Jest! I pan Waldek z sąsiedniej. Waldek! / **Waldek:** Zbyszek tu jest od Gierka. / **Zbyszek:** Ogórki pan weźmie? Bo pieniędzy przy sobie nie noszę.
  - EN — **Zbyszek:** The plot's in my wife's name, but I'm the one digging. / **Locksmith:** Got your allotment card? / **Zbyszek:** I do! And Waldek next door. Waldek! / **Waldek:** Zbyszek's been here since the seventies. / **Zbyszek:** Take some pickles? I don't carry cash.
- **Zamek:** płytkowy (kłódka), T2.
- **Weryfikacja:** legitymacja działkowca (2) i świadek (2), próg 3. Zgrzyt „inne nazwisko w umowie” wyjaśnia się sam (żona).
- **Presja:** brak.
- **Nagroda:** słoik ogórków (płatność w naturze) albo 85 monet i +2 rep na Ogródkach.
- **Rozdział / dzielnica:** 3, Ogródki działkowe.
- **Ton:** zabawny, ciepły.

#### `job.widow_bureau`
- **Tytuł:** Sekretarzyk / *The Writing Desk*
- **Klient:** pani Irena, 79 lat, emerytowana bibliotekarka, wdowa od roku.
- **Sytuacja:** Mąż zamykał sekretarzyk na kluczyk, który zawsze nosił przy zegarku. Zegarek jest, kluczyka nie ma. Pani Irena nie chce niczego wiercić, bo „to jego mebel”.
- **Scena:**
  - PL — **Irena:** Nie wiem, co tam jest. Może nic. / **Ślusarz:** Otworzę tak, że nikt nie pozna. / *(po otwarciu)* / **Irena:** Bilety do opery. Osiemdziesiąty siódmy. „Halka”. / **Irena:** Mówił, że zgubił. Trzymał je.
  - EN — **Irena:** I don't know what's in there. Perhaps nothing. / **Locksmith:** I'll open it so no one will ever know. / *(after opening)* / **Irena:** Opera tickets. 1987. *Halka*. / **Irena:** He said he'd lost them. He kept them.
- **Zamek:** dźwigniowy, T2.
- **Weryfikacja:** rzecz w posiadaniu, w jej domu (2). Haczyk: brak.
- **Presja:** brak.
- **Nagroda:** 95 monet. Metoda niszcząca w ogóle nie jest dostępna, bo dialog z góry ją wyklucza. Jedyny wpis w grze bez napiwku, ale z +5 rep, bo pani Irena „powie koleżankom”.
- **Rozdział / dzielnica:** 3, Śródmieście.
- **Ton:** wzruszający.

#### `job.refuse_aunt_alive` ⚠ do odmowy
- **Tytuł:** Ciotka, która ma się dobrze / *The Aunt Who's Doing Fine*
- **Klient:** kobieta ok. 30 lat. Mówi, że jest „jedyną spadkobierczynią”.
- **Sytuacja:** Chce otworzyć mieszkanie „świętej pamięci ciotki”, żeby „zabezpieczyć rzeczy przed rodziną”. Nie ma żadnego dokumentu od notariusza, bo „to dopiero co”. Sąsiadka zza ściany słyszy rozmowę i wychodzi na klatkę.
- **Scena:**
  - PL — **Klientka:** Ciocia zmarła w zeszłym tygodniu, papiery są w trakcie. / **Sąsiadka:** Pani Lucyna? Pani Lucyna jest w sanatorium w Ciechocinku. Dzwoniła wczoraj, że jej się poprawiło. / **Klientka:** …Musiałam coś pomylić. / **Ślusarz:** To ja zadzwonię do pani Lucyny. Razem z panią sąsiadką.
  - EN — **Customer:** Auntie passed last week, the paperwork's in progress. / **Neighbour:** Mrs Lucyna? Mrs Lucyna's at a spa in the countryside. She rang yesterday, said she's feeling better. / **Customer:** …I must have got mixed up. / **Locksmith:** Then I'll ring Mrs Lucyna. Together with you, ma'am.
- **Zamek:** dźwigniowy, T2.
- **Weryfikacja:** dowód (1). Zgrzyty: `flag.neighbour_denies`, `flag.absent_owner`.
- **Presja:** brak.
- **Nagroda:** odmowa daje +5 rep, a telefon do pani Lucyny razem z sąsiadką +6 rep. Pani Lucyna po powrocie zamawia u gracza nową wkładkę (zlecenie poboczne, 90 monet).
- **Rozdział / dzielnica:** 3, Willowa Górka.
- **Ton:** poważny, z ulgą na końcu.

### Rozdział 4 — Małopolska

#### `job.krakow_tenement_gate`
- **Tytuł:** Brama na Kazimierzu / *The Gate in Kazimierz*
- **Klient:** pani Wanda, zarządczyni wspólnoty mieszkaniowej kamienicy z 1890 r. Ma segregator z uchwałami.
- **Sytuacja:** Ogromny zamek w drewnianej bramie przestał chodzić po deszczu, a jedyny stary klucz utknął w środku. Brama jest pod opieką konserwatora, więc niczego nie wolno wymieniać ani wiercić. Lokatorzy wchodzą przez podwórko sąsiedniej kamienicy.
- **Scena:**
  - PL — **Wanda:** Konserwator powiedział: ani jednej dziury. / **Ślusarz:** Słusznie. Tu ktoś sto trzydzieści lat temu dobrze się napracował. / **Wanda:** Uchwała wspólnoty, proszę. Zlecenie na piśmie. / **Ślusarz:** Pierwszy raz ktoś mi dał uchwałę. Oprawię sobie.
  - EN — **Wanda:** The conservator said: not a single hole. / **Locksmith:** Quite right. Someone worked hard on this a hundred and thirty years ago. / **Wanda:** The residents' resolution. Your order in writing. / **Locksmith:** First time anyone's handed me a resolution. I'll frame it.
- **Zamek:** zapadkowy, T3 (duży zamek skrzynkowy bramy, wiele ostróg).
- **Weryfikacja:** zarządca (3) i uchwała (1). Haczyk: brak.
- **Presja:** brak.
- **Nagroda:** 160 monet. Odblokowuje notkę `showcase.krakow_guild_seal`. Metoda niszcząca jest zablokowana (zabytek).
- **Rozdział / dzielnica:** 4, Kraków.
- **Ton:** ciepły, z szacunkiem dla rzemiosła.

#### `job.swiatniki_journeyman_padlock`
- **Tytuł:** Kłódka czeladnicza pana Władysława / *Mr Władysław's Journeyman Padlock*
- **Klient:** pan Władysław, 84 lata. W latach 50. ukończył szkołę ślusarską w Świątnikach Górnych i ma dłonie jak imadło.
- **Sytuacja:** Na pracę czeladniczą zrobił kłódkę z „sekretem”. Klucz zgubił wnuk. Pan Władysław wie, jak ją otworzyć, ale „chce zobaczyć, czy młodzi jeszcze umieją”.
- **Scena:**
  - PL — **Władysław:** Siedemdziesiąt lat ją trzymam. Klucz był jeden. / **Ślusarz:** A pan wie, jak ją otworzyć? / **Władysław:** Wiem. Ale ja panu nie powiem. / **Władysław (po otwarciu):** No. Bruchnalski by pana przyjął. / **Ślusarz:** Kto? / **Władysław:** Pierwszy dyrektor szkoły. Chodź pan, pokażę muzeum.
  - EN — **Władysław:** I've kept it seventy years. There was only ever one key. / **Locksmith:** And you know how to open it? / **Władysław:** I do. I'm not telling. / **Władysław (after):** Well. Bruchnalski would've taken you on. / **Locksmith:** Who? / **Władysław:** The school's first headmaster. Come, I'll show you the museum.
- **Zamek:** zapadkowy T3, wariant „kłódka świątnicka” z ukrytą zasuwką (fikcyjna, mechanizm wymyślony).
- **Weryfikacja:** właściciel i twórca (3). Haczyk: brak.
- **Presja:** brak, za to pan Władysław komentuje każdy ruch gracza.
- **Nagroda:** 0 monet (gracz sam odmawia zapłaty w dialogu albo pan Władysław płaci 100, do wyboru). Kłódka trafia do gabloty osobistej. Odblokowuje notki `showcase.swiatniki_armourers` i `showcase.swiatniki_school`.
- **Rozdział / dzielnica:** 4, Świątniki Górne.
- **Ton:** wzruszający, z humorem.

#### `job.krakow_antiquarian`
- **Tytuł:** Kasa antykwariusza / *The Antiquarian's Strongbox*
- **Klient:** pan Leopold, 70 lat, antykwariusz z ulicy Józefa. Nosi muszkę i lupę na łańcuszku.
- **Sytuacja:** Stara kasa pancerna z tarczą szyfrową stoi w jego sklepie od 40 lat, a pan Leopold zapomniał szyfr po wakacjach. Przy okazji prosi, żeby otworzyć też „kasetkę, którą klient zostawił do wyceny”. Klienta nie ma.
- **Scena:**
  - PL — **Leopold:** Kasa moja, wynajem mam od miasta, sąsiadka z kawiarni potwierdzi. / **Ślusarz:** Kasę otworzę. Kasetki nie. Niech właściciel przyjdzie sam. / **Leopold:** Ma pan rację. Starzeję się, robię się niecierpliwy. / **Leopold:** W nagrodę opowiem panu o cechu ślusarzy i zegarmistrzów.
  - EN — **Leopold:** The strongbox is mine, I lease from the city, the café lady next door will confirm. / **Locksmith:** I'll open the strongbox. Not the casket. Its owner can come in himself. / **Leopold:** You're right. I'm getting old and impatient. / **Leopold:** As a reward, I'll tell you about the locksmiths' and clockmakers' guild.
- **Zamek:** sejf z tarczami, T2 (drugi sejf, rozdział później niż sejf wujka; do D-118 T1).
- **Weryfikacja:** umowa najmu (2), świadek (2) i posiadanie (1). Haczyk: **częściowa odmowa**. Kasetka cudzego klienta to osobna decyzja: otwarcie jej daje −10 rep, odmowa +3 rep.
- **Presja:** brak.
- **Nagroda:** 120 monet i stara mapa Krakowa (przedmiot do warsztatu).
- **Rozdział / dzielnica:** 4, Kraków.
- **Ton:** ciepły, z morałem bez moralizowania.

### Rozdział 5 — Pociąg do Brukseli

> W tym rozdziale gracz wypełnia scenę „kodeks postępowania”: 4 pytania o uczciwą cenę, informację o czasie oczekiwania, dyskrecję i odmowę podejrzanych zleceń. Nagrodą jest **karta ślusarza** w grze, która otwiera zlecenia od zarządców budynków. W tekście nie używamy logo ani nazwy urzędu. Mówimy ogólnie: „kodeks uczciwego ślusarza” / *"honest locksmith's code"*.

#### `job.brussels_townhouse`
- **Tytuł:** Kamienica w Saint-Gilles / *A Townhouse in Saint-Gilles*
- **Klient:** Magda, 41 lat. Od 15 lat jest tłumaczką w Brukseli i mówi po polsku z francuskimi wtrąceniami.
- **Sytuacja:** Wyszła na balkon podlać pelargonie, a drzwi tarasowe zatrzasnęły się z wiatrem. Telefon ma przy sobie. Na dole czeka sąsiad z parteru, monsieur Jacques, który ma klucz do bramy, ale nie do mieszkania.
- **Scena:**
  - PL — **Magda:** Stoję na balkonie jak Julia. Tylko Romeo ma sześćdziesiąt lat i klucz od bramy. / **Jacques:** Madame Magda habite ici depuis toujours. / **Ślusarz:** Umowę najmu ma pani w telefonie? / **Magda:** *Bail enregistré*, proszę bardzo. I adres z gminy.
  - EN — **Magda:** I'm on the balcony like Juliet. Only Romeo is sixty and has the street-door key. / **Jacques:** Madame Magda has lived here forever. / **Locksmith:** Got your lease on your phone? / **Magda:** Registered lease, here you go. And my address from the commune.
- **Zamek:** dimple / listwa boczna, T2.
- **Weryfikacja:** umowa najmu (2), adres z gminy (eID, 2) i sąsiad (2). Haczyk: brak.
- **Presja:** licznik „zaczyna padać” (opcjonalny, belgijski klasyk).
- **Nagroda:** 105 monet i zaproszenie na *gaufre* w rozdziale.
- **Rozdział / dzielnica:** 5, Bruksela.
- **Ton:** zabawny, ciepły.

#### `job.ghent_beguinage`
- **Tytuł:** Drzwi w beginażu / *A Door in the Béguinage*
- **Klient:** brat Pieter, 66 lat, opiekun domu wspólnoty w gandawskim beginażu. Jeździ na rowerze z wiklinowym koszykiem.
- **Sytuacja:** Do schowka z księgami parafialnymi nikt nie zaglądał od dziesięcioleci, a klucz „poszedł z poprzednim opiekunem do nieba”. Dom jest zabytkowy, więc wolno otworzyć tylko bez śladów.
- **Scena:**
  - PL — **Pieter:** Po polsku umiem tylko „dzień dobry” i „pierogi”. / **Ślusarz:** To już połowa języka. / **Pieter:** Pismo od rady fabrycznej parafii. I klucz do furty, jeśli pan potrzebuje. / **Ślusarz:** Ten zamek ma więcej lat niż mój dom.
  - EN — **Pieter:** The only Polish I know is "good morning" and "pierogi". / **Locksmith:** That's half the language. / **Pieter:** A letter from the parish council. And the gate key, if you need it. / **Locksmith:** This lock's older than my house.
- **Zamek:** zapadkowy, T2.
- **Weryfikacja:** pismo instytucji (2) i opiekun-zarządca (3). Haczyk: brak.
- **Presja:** brak.
- **Nagroda:** 100 monet. W schowku są księgi z XVIII w., które trafiają do archiwum miejskiego, a gracz dostaje podziękowanie na papierze czerpanym.
- **Rozdział / dzielnica:** 5, Gandawa.
- **Ton:** ciepły, spokojny.

#### `job.liege_bakery`
- **Tytuł:** Piekarnia o czwartej / *The Bakery at Four*
- **Klient:** Nadia, 29 lat. Przejęła piekarnię po wujku i piecze gofry z perłowym cukrem.
- **Sytuacja:** O 3:50 drzwi zaplecza nie chcą się otworzyć, bo zamek dźwigniowy „coś wyczuł” i się zablokował po tym, jak Nadia próbowała go otworzyć niewłaściwym kluczem z pęku wujka. Ciasto rośnie.
- **Scena:**
  - PL — **Nadia:** Wujek miał trzydzieści kluczy i żadnego nie podpisał. / **Ślusarz:** Zamek się obraził. To jego zawód. / **Nadia:** Papiery przejęcia mam w samochodzie. I listę klientów, którzy przyjdą o szóstej. / **Ślusarz:** Klienci nie są dowodem, ale papiery wystarczą.
  - EN — **Nadia:** My uncle had thirty keys and didn't label one. / **Locksmith:** The lock's in a huff. That's its job. / **Nadia:** Takeover papers are in the car. And a list of customers coming at six. / **Locksmith:** Customers aren't proof, but the papers will do.
- **Zamek:** dźwigniowy z detektorem, T2. To wprowadzenie mechaniki detektora jako „obrażonego zamka”, z odwołaniem do Chubba w gablocie.
- **Weryfikacja:** dokument przejęcia firmy (3) i umowa najmu (2). Haczyk: brak.
- **Presja:** licznik „ciasto rośnie” (opcjonalny).
- **Nagroda:** 130 monet (noc ×1,5) i torba gofrów. Odblokowuje `showcase.chubb_detector`.
- **Rozdział / dzielnica:** 5, Liège.
- **Ton:** zabawny.

#### `job.charleroi_letters`
- **Tytuł:** Adres z listów dziadka / *The Address in Grandpa's Letters*
- **Klient:** Ola z `job.grandpa_chest` przyjeżdża do Belgii i dzwoni do gracza po radę, nie po otwarcie.
- **Sytuacja:** Pod adresem z listów dziadka stoi dziś dom pani Martine. Pani Martine znalazła w piwnicy żelazną kasetkę z polskimi napisami i chce ją oddać rodzinie, ale kasetka jest zamknięta. Obie chcą ją otworzyć razem.
- **Scena:**
  - PL — **Martine:** C'est à votre famille. Ja tylko pilnowałam. / **Ola:** Pani pilnowała przez siedemdziesiąt lat? / **Martine:** Moja mama, potem ja. Nikt nie miał serca wyrzucić. / **Ślusarz:** To otwieramy we trzy. Znaczy we troje.
  - EN — **Martine:** It belongs to your family. I just kept it safe. / **Ola:** For seventy years? / **Martine:** My mother, then me. No one had the heart to throw it out. / **Locksmith:** Then we open it together, the three of us.
- **Zamek:** płytkowy, T2 (kasetka).
- **Weryfikacja:** właścicielka znaleziska (2), która z własnej woli przekazuje je rodzinie, i list z adresem (1). Haczyk: brak. To jedyne zlecenie, w którym obie strony chcą otwarcia.
- **Presja:** brak.
- **Nagroda:** 0 monet (gracz nie bierze pieniędzy, wybór w dialogu), +10 rep globalnie. W kasetce jest lampka górnicza i zdjęcie brygady.
- **Rozdział / dzielnica:** 5, okolice Charleroi.
- **Ton:** wzruszający.

### Rozdział 6 — Skarbiec

#### `job.museum_time_lock`
- **Tytuł:** Zegar, który pilnuje skarbca / *The Clock That Guards the Vault*
- **Klient:** dr Anna Rygiel, kuratorka Muzeum Techniki w porcie. Nosi rękawiczki bawełniane nawet do kawy.
- **Sytuacja:** Muzeum dostało drzwi skarbca z dawnej kasy oszczędności z zamkiem czasowym. Mechanizm zegarowy stanął w pozycji „zamknięte” i nie da się otworzyć wnętrza z tabliczką dawnego banku, potrzebną na wystawę.
- **Scena:**
  - PL — **Rygiel:** Tu nie chodzi o szyfr. Tu chodzi o czas. / **Ślusarz:** Zamek czasowy nie pyta, kto pan jest. Pyta, która godzina. / **Rygiel:** Pismo od dyrekcji, protokół przekazania. Wszystko jest. / **Ślusarz:** To zróbmy tak, żeby zegar sam uznał, że już pora.
  - EN — **Rygiel:** It's not about the combination. It's about time. / **Locksmith:** A time lock doesn't ask who you are. It asks what time it is. / **Rygiel:** Director's letter, transfer protocol. All in order. / **Locksmith:** Then let's convince the clock it's time.
- **Zamek:** zamek czasowy, T2.
- **Weryfikacja:** pismo instytucji (2) i kuratorka (3). Haczyk: brak.
- **Presja:** licznik „otwarcie wystawy w piątek” (opcjonalny).
- **Nagroda:** 150 monet. Odblokowuje `showcase.sargent_time_lock`.
- **Rozdział / dzielnica:** 6, Port.
- **Ton:** ciepły, z nutą muzealnej pedanterii.

#### `job.bramah_bureau`
- **Tytuł:** Angielski sekretarzyk / *The English Bureau*
- **Klient:** Gosia, 36 lat, renowatorka mebli z własną pracownią przy Porcie.
- **Sytuacja:** Na aukcji kupiła XIX-wieczny angielski sekretarzyk z zamkiem na klucz rurkowy z nacięciami. Klucza nie było, a ona chce mebel otworzyć, odnowić i zachować zamek w oryginale.
- **Scena:**
  - PL — **Gosia:** Faktura z aukcji, opis, zdjęcia. Zamek ma być nietknięty. / **Ślusarz:** Taki zamek kiedyś wisiał w oknie sklepu w Londynie z nagrodą dla tego, kto go otworzy. / **Gosia:** I ktoś otworzył? / **Ślusarz:** Po sześćdziesięciu latach. Opowiem, jak skończę.
  - EN — **Gosia:** Auction invoice, description, photos. The lock stays untouched. / **Locksmith:** A lock like this once hung in a London shop window with a reward for whoever could open it. / **Gosia:** Did anyone? / **Locksmith:** After sixty years. I'll tell you when I'm done.
- **Zamek:** Bramah, T2.
- **Weryfikacja:** faktura (2) i posiadanie (1). Haczyk: brak.
- **Presja:** brak.
- **Nagroda:** 140 monet. Odblokowuje `showcase.bramah_window` i `showcase.hobbs_51_hours`.
- **Rozdział / dzielnica:** 6, Port.
- **Ton:** ciepły.

#### `job.finnish_sailor`
- **Tytuł:** Skrzynia marynarza / *The Sailor's Sea Chest*
- **Klient:** Aino, 50 lat, oficer mechanik z fińskiego statku, który stoi w porcie dwa dni.
- **Sytuacja:** Na jej skrzyni z narzędziami wisi kłódka z obrotowymi tarczami, „taka jak u nas w domu”. Kluczyk wpadł między nabrzeże a burtę. Kapitan potwierdza, że skrzynia jest jej, i patrzy na zegarek.
- **Scena:**
  - PL — **Aino:** W Finlandii każdy ma taką kłódkę. Nikt nie umie jej otworzyć bez klucza. / **Ślusarz:** No to zobaczymy. / **Kapitan:** Skrzynia jest Aino, ja ręczę. Odpływamy jutro o szóstej. / **Aino:** Jeśli pan otworzy, opowiem panu, skąd ten wynalazek.
  - EN — **Aino:** In Finland everyone has a padlock like this. No one can open it without the key. / **Locksmith:** We'll see. / **Captain:** It's Aino's chest, I vouch for her. We sail tomorrow at six. / **Aino:** If you open it, I'll tell you where this invention came from.
- **Zamek:** tarczowy (disc detainer), T2.
- **Weryfikacja:** kapitan (3) i książeczka żeglarska (1). Haczyk: brak.
- **Presja:** licznik „odpływ 6:00” (opcjonalny, rozłożony na dwa dni gry).
- **Nagroda:** 135 monet i fińska mała drewniana chochla *kuksa* w warsztacie. Odblokowuje `showcase.henriksson_disc`.
- **Rozdział / dzielnica:** 6, Port.
- **Ton:** ciepły.

#### `job.time_capsule`
- **Tytuł:** Kapsuła czasu klasy 3b / *Class 3b's Time Capsule*
- **Klient:** pani Jadwiga, emerytowana wychowawczyni, i dwudziestu trzydziestoparolatków na zjeździe absolwentów.
- **Sytuacja:** W 2001 r. klasa zakopała pod kasztanowcem metalową skrzynkę z kłódką szyfrową. Kod znała tylko pani Jadwiga, która go „zapisała w bezpiecznym miejscu”, i to miejsce też już zapomniała. Dyrekcja szkoły zgadza się na otwarcie przy wszystkich.
- **Scena:**
  - PL — **Jadwiga:** Ja wiem, że to była jakaś data. Tylko czyja? / **Absolwent:** Pani Jadwigo, my wtedy mieliśmy dziewięć lat, my nic nie pamiętamy. / **Dyrektorka:** Szkoła się zgadza, proszę otwierać. / *(po otwarciu)* / **Absolwentka:** Mój list do siebie… „Mam nadzieję, że masz psa”. Mam! Mam psa!
  - EN — **Jadwiga:** I know it was a date. But whose? / **Former pupil:** Miss, we were nine. We remember nothing. / **Headteacher:** The school agrees — go ahead. / *(after opening)* / **Former pupil:** My letter to myself… "I hope you have a dog." I do! I have a dog!
- **Zamek:** kłódka szyfrowa, T3.
- **Weryfikacja:** dyrekcja (3) i świadkowie (2). Haczyk: brak.
- **Presja:** brak. Finał bez timera, za to z rosnącym tłumem i rosnącym ciepłem.
- **Nagroda:** 0 monet (szkoła), +15 rep globalnie i zdjęcie klasy z graczem w gablocie osobistej. Odblokowuje `showcase.amen_padlock`. Po napisach pojawia się kartka od babci Haliny z `job.grandma_broth`: „Rosół czeka”.
- **Rozdział / dzielnica:** 6, Śródmieście.
- **Ton:** wzruszający, zabawny.

### Pokrycie

| Rodzina | Zlecenia |
|---|---|
| egipski drewniany | `job.dollhouse_wooden_lock` |
| zapadkowy | `job.grandma_broth`, `job.cat_bathroom`, `job.grandpa_chest`, `job.krakow_tenement_gate`, `job.swiatniki_journeyman_padlock`, `job.ghent_beguinage` |
| kłódka szyfrowa | `job.bike_interview`, `job.time_capsule` |
| płytkowy | `job.kiosk_shutter`, `job.allotment_shed`, `job.charleroi_letters` |
| wkładka bębenkowa | `job.student_dorm`, `job.newlyweds_4am`, `job.wrong_floor`, `job.refuse_ex_partner`, `job.refuse_rush_bribe` |
| dźwigniowy (+ detektor) | `job.pizzeria_pays_pizza`, `job.widow_bureau`, `job.refuse_aunt_alive`, `job.liege_bakery` |
| rurkowy | `job.drummer_locker` |
| magnetyczny | `job.night_nurse` |
| Bramah | `job.bramah_bureau` |
| tarczowy | `job.finnish_sailor` |
| sejf z tarczami | `job.uncle_safe_heirs`, `job.krakow_antiquarian` |
| zamek czasowy | `job.museum_time_lock` |
| dimple / listwa boczna | `job.brussels_townhouse` |

Do odmowy: `job.refuse_ex_partner`, `job.refuse_rush_bribe`, `job.refuse_aunt_alive`. Bez otwierania: `job.wrong_floor`. Częściowa odmowa: `job.krakow_antiquarian`. Czekanie na komplet: `job.uncle_safe_heirs`.

---

## 6. Zasady pisania kolejnych zleceń
- Klient ma imię, zawód lub rolę i **jedną** charakterystyczną cechę. Bez karykatur narodowych ani wiekowych.
- Ślusarz mówi krótko, rzeczowo, z lekkim humorem. Nie poucza. Nie mówi „spokojnie, jestem profesjonalistą”.
- Każda podejrzana historia rozpada się na **zachowaniu i sprzecznościach**, nigdy na szczegółach dokumentu.
- Zero marek zamków i samochodów. Zero nazw realnych firm i urzędów w tekstach dla gracza (wyjątek: nazwy miejsc i instytucji kultury w gablocie).
- Każda presja to licznik fabularny z ustawieniem „Spokojne zlecenia”.
- Sceny po polsku i angielsku piszemy równolegle. Gry słów, których nie da się przetłumaczyć, zastępujemy w EN innym żartem, a nie tłumaczymy dosłownie.

## 7. Otwarte pytania
1. Robocza nazwa miasta „Zameczno”: sprawdzić kolizje i odbiór (może brzmieć infantylnie). Alternatywy: „Ryglów”, nazwa nieujawniona.
2. Czy rozdział belgijski ma być w MVP Zleceń, czy w aktualizacji? (decyzja właściciela)
3. Wartości monet trzeba zestroić z `docs/PROGRESSION.md`, kiedy powstanie.
4. Konsultacja z praktykującym ślusarzem (PL i BE), żeby zweryfikować realia sceny weryfikacji i stawek nocnych.
5. Aktualny status belgijskiej karty ślusarza i rejestru FOD Economie (źródła z lat 2021–2022).
