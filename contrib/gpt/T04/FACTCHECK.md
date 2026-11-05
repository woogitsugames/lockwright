# T04 — fact-check historii zamków i notek gabloty

Weryfikacja: 2026-11-05. Materiały porównane: docs/SHOWCASE.md (20 notek) i sekcje „Epoka”/„Zasada działania” w docs/LOCKS.md (17 rodzin), z kontekstem CLAUDE.md, docs/styles/realizm.md, docs/DESIGN.md i docs/HUD.md.

## Metoda i granice

- Oceny odnoszą się do **całego oryginalnego akapitu**, nie tylko jednej daty. „Zgodne” oznacza, że zasadnicze twierdzenia mają wsparcie, choć wersję dla gracza można skrócić. „Do poprawy” oznacza pomyłkę, nieprecyzyjność, zbyt pewny ton albo anegdotę bez dowodu. „Nie do zweryfikowania” oznacza niewystarczającą dokumentację **konkretnego roszczenia**, zwykle daty pierwszeństwa.
- Każdy rekord ma **dwa odnośniki** do katalogu źródeł poniżej: publikacji historycznej/naukowej, patentu archiwalnego, muzeum lub niezależnej instytucji. Dwa odnośniki nie zawsze dowodzą każdej pobocznej tezy; wówczas poprawka usuwa tezę lub jawnie opisuje brak weryfikacji.
- Publikacje autorów historycznie związanych z zawodem ślusarskim (Tomlinson, Chubb) traktowano jako dawne opracowania źródłowe, **nie** jako współczesne strony producentów. Nie korzystano ze stron producentów jako podstawy ustaleń. Patenty traktowano jako **źródła pierwotne dokumentujące konkretny projekt, nie dowód, że był pierwszy w świecie**.
- Teksty dla gracza są PL/EN, nie zawierają procedur manipulacji realnym zamkiem, specyfikacji narzędzi, modeli, marek ani porad o obejściu zabezpieczeń. Wnioski nie zmieniają parametrów fikcyjnej symulacji.

**Bilans notek:** zgodne 3, do poprawy 17, nie do zweryfikowania 0. **Bilans rodzin:** zgodne 2, do poprawy 11, nie do zweryfikowania 4.

## A. Gablota — 20/20 notek

| ID | Ocena | Wynik i zalecana poprawka | Dwa źródła |
|---|---|---|---|
| showcase.khorsabad_gate | **do poprawy** | Kontekst to koniec VIII w. p.n.e., nie 4000 lat temu. Botta opisał bramę; konkretny drewniany zamek znamy z dziewiętnastowiecznej relacji, nie z zachowanego artefaktu. | [POTTS](#potts), [PITT](#pitt) |
| showcase.egyptian_name | **do poprawy** | Nazwa tradycyjna nie dowodzi egipskiego pierwszeństwa; Pitt-Rivers kwestionował dostateczne dowody starożytnego zastosowania nad Nilem. Nie przypisywać wynalazku konkretnemu narodowi. | [PITT](#pitt), [POTTS](#potts) |
| showcase.roman_ring_key | **do poprawy** | Istnienie pierścieni-kluczy potwierdzają katalogi muzeów. Usunąć absolutne „nikt nie miał kieszeni” i nie przedstawiać płci ani związku z małżeństwem jako faktu. | [VAM](#vam), [LONDON](#london) |
| showcase.roman_wards | **do poprawy** | W terminologii rozdzielić nieruchome zastawki (wards) od ruchomych zapadek/dźwigni (tumblers). Nie uogólniać jednej metody zamykania na wszystkie drzwi w Pompejach. | [PITT](#pitt), [TOM](#tom) |
| showcase.amen_padlock | **do poprawy** | Tomlinson cytuje wiersze i sztukę, a opracowanie Kruh powtarza tradycję literacką. Bez autorytatywnej edycji źródłowej nie potwierdzamy dosłownego brzmienia cytatów, wystawienia sztuki ani rytownictwa z 1682. | [TOM](#tom), [KRUH](#kruh) |
| showcase.barron_1778 | **zgodne** | Robert Barron i patent z 31 X 1778 potwierdzone historycznymi zestawieniami patentowymi; wyeliminować kategoryczne „większość wszystkich późniejszych zamków” jako trudne do udowodnienia. | [TOM](#tom), [CHUBB](#chubb) |
| showcase.chubb_detector | **do poprawy** | Patent Jeremiaha Chubba 1818 i wcześniejsza koncepcja Ruxtona 1816; anegdota o skazańcu z Portsmouth nie jest niezależnie udokumentowana, więc pominięta. | [TOM](#tom), [LHLH](#lhlh) |
| showcase.hobbs_westminster | **do poprawy** | Nie mylić wstępnego pokazu w Crystal Palace ze świadkowanym testem 22 VII 1851 przy Great George Street w Westminsterze. Otworzenie 25 minut, ponowne zamknięcie 7 minut w oświadczeniu z epoki. | [TOM](#tom), [LHLH](#lhlh) |
| showcase.bramah_window | **do poprawy** | Patent Bramaha 1784, nagroda 200 gwinei. Popularne ok. 1790 dla konkretnej kłódki nie odpowiada katalogowi Science Museum (eksponat datowany na 1801); nie przypisywać Maudslayowi bezpośrednio wykonania eksponatu. | [SCI](#sci), [TOM](#tom) |
| showcase.hobbs_51_hours | **zgodne** | Raport arbitrów z 2 IX 1851 podaje 51 godzin w ciągu 16 dni pracy Hobbsa, lecz nie należy utożsamiać ich z 16 kolejnymi dniami kalendarzowymi. | [TOM](#tom), [SCI](#sci) |
| showcase.stansbury_1805 | **do poprawy** | Abraham O. Stansbury patent brytyjski 1805; 1807 USA, utracenie całego patentu w 1836 i brak zachowanych egzemplarzy nie zostały osobno wiarygodnie potwierdzone. Usunąć. | [TOM](#tom), [CHUBB](#chubb) |
| showcase.yale_senior | **do poprawy** | Newport w stanie Nowy Jork, nie Rhode Island. Patent US 18,169 z 1857 potwierdza miejsce i nazwisko. Pierwszy burmistrz/prezydent wioski oraz absolutna data 1848 bez dokumentacji usunięte. | [YALESR](#yalesr), [MIT](#mit) |
| showcase.yale_flat_key | **do poprawy** | Patent US 48,475 datowany 27 VI 1865; biografia młodszego i lekki klucz w źródłach niezależnych. Nie twierdzić, że każdy wcześniejszy klucz kołkowy był wielki ani podawać spornego dnia śmierci. | [YALEJR](#yalejr), [OXF](#oxf) |
| showcase.yale_dial | **do poprawy** | 1851 dotyczy projektu zamka bankowego, nie udowodnionego pierwszego zamka na pokrętło. Unikać fałszywego wniosku, że brak otworu gwarantuje odporność na wszelkie ataki. | [MIT](#mit), [ASME](#asme) |
| showcase.sargent_time_lock | **do poprawy** | Wniosek patentowy 1873 i instalacja Morrison Illinois w 1874 są w nekrologu z epoki oraz opracowaniu czasopiśmienniczym. Nie utrwalać spornego dnia instalacji (2 kontra 26 V), twierdzenia o pierwszym na świecie ani relacji o maskach. | [SARGARCH](#sargarch), [HORO](#horo) |
| showcase.henriksson_disc | **do poprawy** | Emil Henriksson 1907 i patent 1919 opisuje niezależne stowarzyszenie inżynierskie; opowieść o naprawianej kasie jest przekazem retrospektywnym, a nie potwierdzonym dziennikiem wynalazcy. Nie sugerować, że patent 1907. | [TEK](#tek), [KALEVA](#kaleva) |
| showcase.swiatniki_armourers | **do poprawy** | Historia Świątnik jako osady służebnej i przejścia od płatnerstwa do ślusarstwa dobrze poświadczona regionalnie. Włoskich mistrzów i liczby warsztatów nie przedstawiać bez kwalifikacji; zrezygnować z nieudokumentowanego „znaku jakości”. | [PTTK](#pttk), [VISIT](#visit) |
| showcase.swiatniki_school | **do poprawy** | Akt założycielski 1887, działalność 1888; 1891 zamówienie na 500 kłódek wg dziedzictwa regionalnego. Oddzielić szkolne zbiory od późniejszej izby i muzeum; źródła różnią się co do formalnej daty utworzenia muzeum. | [TWIERDZA](#twierdza), [PTTK](#pttk) |
| showcase.krakow_guild_seal | **zgodne** | Statut cechu ślusarzy i zegarmistrzów zatwierdzony 12 III 1633, rozdzielenie 1797. Opis pieczęci i symbolika węża pochodzą z badania A. Chmiela; interpretacja nie jest dowodem poglądów wszystkich mistrzów. | [CHMIEL](#chmiel), [RAK](#rak) |
| showcase.wroclaw_iron_world | **do poprawy** | Oficjalny katalog MNWr: 5 VII–30 XII 2022 i pełny podtytuł. Zamek skrzynkowy Alberta Nicolausa Spihrmana 1720 potwierdzony bezpośrednio przez muzeum. Liczebność 450 eksponatów to liczba przybliżona, nie łączna wielkość zbiorów. | [MNWR](#mnwr), [MNWR450](#mnwr450) |

## B. LOCKS — 17/17 wstępów rodzin

| Rodzina | Ocena | Wynik i zalecana poprawka | Dwa źródła |
|---|---|---|---|
| 2.x / wooden_pin | **do poprawy** | Nie istnieje zachowany „zamek z Chorsabadu” o wieku 4000 lat. Koniec VIII w. p.n.e. oznacza kontekst budowli, sam zamek znamy z opisu. Opis kołków ogólny. | [POTTS](#potts), [PITT](#pitt) |
| 2.x / warded | **do poprawy** | Termin warded dotyczy stałych zastawek/przegród, nie ruchomych zapadek; epoka rzymska udokumentowana, starożytne Chiny bez równorzędnego potwierdzenia w wykorzystanych źródłach. | [PITT](#pitt), [TOM](#tom) |
| 2.x / ring_combo | **do poprawy** | Antyczne datowanie egzemplarza z Keramejkosu i dokładny opis Cardana nie zostały tu niezależnie sprawdzone. Pewne świadectwa średniowiecznych zamków szyfrowych dostarcza al-Dżazari i obiekty muzealne; nie mylić z identyczną współczesną kłódką. | [EURO](#euro), [KRUH](#kruh) |
| 2.x / wafer | **do poprawy** | P. S. Felter 1868 skonstruował rozwiązanie DWUSTRONNE, a wczesną odmianę jednostronną opisuje Pulford przy H. S. Shepardsonie, 1870. Usunąć błędny związek Feltera z jednostronną pierwszą wkładką. | [PUL](#pul), [FELTER](#felter) |
| 2.x / wafer_double | **do poprawy** | Dwustronnej odmiany nie należy datować dopiero na 1913 lub połowę XX w.; patent Feltera US 76,066 dokumentuje taki układ już w 1868. Twierdzenia o roku 1962 i zastosowaniu motoryzacyjnym usunąć jako niezweryfikowane. | [FELTER](#felter), [PUL](#pul) |
| 2.x / pin_tumbler | **do poprawy** | Nie przypisywać „pierwszego zamka dwustronnego” Stansbury'emu bez definicji. Patent Stansbury 1805 to prekursor; daty 1848 i 1861 pozostają niejednoznaczne, 1865 Yale Jr. potwierdzone patentem. | [TOM](#tom), [YALEJR](#yalejr) |
| 2.x / lever | **zgodne** | Barron 1778 i idea dwustronnego ograniczenia ruchu potwierdzone. Liczb 3–5 i 7+ dźwigni nie traktować jako stałej historycznej ani normy wszystkich zamków. | [TOM](#tom), [CHUBB](#chubb) |
| 2.x / lever_detector | **do poprawy** | Chubb 1818 i poprzednik Ruxton 1816. Demonstracja Hobbsa miała nieformalny etap na Wystawie, ale poświadczony test odbył się 22 VII 1851 w Westminsterze, nie „na Wystawie”. | [TOM](#tom), [LHLH](#lhlh) |
| 2.x / tubular | **nie do zweryfikowania** | 1933 jako rok upowszechnienia przez określonego producenta nie znajduje dwóch niezależnych źródeł. Pozostawić XX wiek bez podawania pierwszeństwa ani liczby standardowych stosów jako reguły. | [PUL](#pul), [BRIT](#brit) |
| 2.x / magnetic | **nie do zweryfikowania** | Rok ok. 1970 jako początek pasywnych zamków magnetycznych nie jest miarodajną datą wynalazku; historyczne patenty świadczą o starszych pomysłach magnetycznych, ale nie dowodzą tożsamości konstrukcji. | [PUL](#pul), [MAGPAT](#magpat) |
| 2.x / axial_slider | **do poprawy** | Bramah patent 1784; muzealny egzemplarz wyzwania datowany 1801, nie bezspornie wykonany w 1790; Hobbs 51 godzin w 16 dni w 1851. Oddzielić historyczny pomysł od wymyślonych fałszywych wycięć i narzędzi gry. | [TOM](#tom), [SCI](#sci) |
| 2.x / disc_detainer | **do poprawy** | Początek idei Henrikssona 1907 i patent 1919 według niezależnego źródła inżynierskiego. 1918 można wiązać z uruchamianiem produkcji, lecz nie mieszać tego z datą patentu. Historia kasy to przekaz wtórny. | [TEK](#tek), [PUL](#pul) |
| 2.x / safe_wheels | **do poprawy** | Zamki szyfrowe do sejfów rozwijano w XIX w.; sprzeczne roszczenia do pierwszeństwa 1857/1862 i rzekomą pierwszą kłódkę z 1910 usunąć. Mechanizm wyłącznie encyklopedycznie, bez metody dekodowania. | [BRIT](#brit), [TOM](#tom) |
| 2.x / time_lock | **do poprawy** | Wczesne konstrukcje przed Sargentem; jego zgłoszenie 1873, instalacja 1874. W źródłach rozbieżny dzień maja, bez potwierdzenia wcześniejszych 1831/1858 w dwóch źródłach specjalistycznych; nie podawać dnia. | [SARGARCH](#sargarch), [HORO](#horo) |
| 2.x / dimple | **nie do zweryfikowania** | Pierwsze użycie i datę „druga połowa XX w.” nie potwierdzają dwa niezależne źródła; zachować jedynie typologiczną definicję i jawny brak daty. | [PUL](#pul), [BRIT](#brit) |
| 2.x / sidebar | **nie do zweryfikowania** | Wymieniana w szkicu data lat 30. XX wieku i kategoria „wyższa klasa” są bez dostatecznej weryfikacji. Źródło patentowe z 1977 potwierdza istniejący wariant, nie pierwszeństwo. | [PUL](#pul), [SIDEPAT](#sidepat) |
| 2.x / hybrid | **zgodne** | To kategoria projektowa gry, nie udokumentowany pojedynczy wynalazek ani era. Źródła pokazują istnienie różnych rodzin; liczba 2–3 modułów pozostaje wyłącznie regułą gry. | [PUL](#pul), [BRIT](#brit) |

## Ustalenia przekrojowe wymagające decyzji redakcji

1. **Bramah:** Science Museum datuje zachowany egzemplarz kłódki-wyzwania na **1801**, podczas gdy tradycja wtórna przypisuje ekspozycji około 1790. Nie ma podstaw, by uznać obie daty za datę wykonania tego samego zachowanego przedmiotu. Wersja PL/EN operuje datą muzealną i 1784 rokiem patentu.
2. **Felter:** patent **US 76,066 z 31 marca 1868** dokumentuje odmianę płytkową **dwustronną**. W szkicach rodzin 2.4 i 2.5 historyczne datowanie pojedynczej/dwustronnej konstrukcji było odwrócone. Publikacja Pulforda rozróżnia Feltera (1868) i H. S. Shepardsona (1870).
3. **Khorsabad:** 4000 lat i „najstarszy zachowany zamek” nie są uzasadnione; jest to **opis bramy** w mieście z końca VIII wieku p.n.e., a nie przechowywany drewniany eksponat. Dane wtórne wymagają ostrożności, gdy starsze encyklopedie powielają błędne datowanie.
4. **Chubb/Hobbs:** świadkowany test zamka Chubba odbył się **22 lipca 1851 w Westminsterze**, a nie w Crystal Palace. Historia detektora obejmuje również patent Ruxtona z 1816.
5. **Świątniki:** rozdzielić akt założycielski szkoły w **1887** od rozpoczęcia nauki w **1888**. Izba regionalna, szkolne zbiory i późniejsze Muzeum Ślusarstwa nie są jedną instytucją z jedną datą powstania. Źródła regionalne nie są w pełni zgodne co do formalnej daty muzeum, więc celowo jej nie wprowadzono.
6. **Wrocław:** oficjalna strona muzeum podaje daty wystawy **5 lipca–30 grudnia 2022** oraz dokładny tytuł i podtytuł; wczesne zapowiedzi sugerowały październik. Muzeum potwierdza imię i nazwisko **Alberta Nicolausa Spihrmana** oraz datę **1720** na zabytku.
7. **Sargent:** niezależny nekrolog z 1910 i periodyk zegarmistrzowski potwierdzają lata **1873/1874** oraz lokalizację Morrison; sporny jest dokładny dzień majowej instalacji. Nie przedstawiać Sargenta jako autora pierwszej koncepcji zamka czasowego na świecie.
8. **Daty bez wiarygodnego pierwszeństwa:** tubular 1933, magnetic ok. 1970, dimple druga połowa XX w. i sidebar lata 30. XX w. — w poprawionych tekstach nie przypisano pewnej daty wynalazku.
9. **Słownictwo:** warded = zamek z **nieruchomymi zastawkami/przegrodami**; lever/tumbler = **ruchome dźwignie/zapadki**. Łączenie obu pod polskim słowem „zapadkowy” zaciera różnicę historyczną.
10. **Pozostaje do zrobienia:** krytyczne wydania fragmentów Beaumonta/Fletchera i Carewa; przegląd źródeł archeologicznych dla Keramejkosu; kwerenda patentowa najwcześniejszych tubular/dimple/sidebar/magnetic; lokalna konsultacja muzealna w Świątnikach. **Niedostateczna dokumentacja nie została maskowana fikcyjną datą.**

## Bibliografia i linki (wyłącznie nieproducenckie podstawy faktów)

### POTTS

D. T. Potts, Lock and Key in Ancient Mesopotamia, Mesopotamia 25 (1990). https://researchprofiles.ku.dk/en/publications/lock-and-key-in-ancient-mesopotamia/

### PITT

A. Pitt-Rivers, On the Development and Distribution of Primitive Locks and Keys (1883). https://www.gutenberg.org/ebooks/44022

### TOM

C. Tomlinson / A. C. Hobbs, Rudimentary Treatise on the Construction of Locks (1853). https://www.gutenberg.org/ebooks/63128

### CHUBB

G. H. Chubb, Protection from Fire and Thieves (1875), history and patent lists; author linked to lock trade. https://www.gutenberg.org/ebooks/49704

### BRIT

Encyclopaedia Britannica, Lock (historical overview; includes disputed Khorsabad chronology). https://www.britannica.com/technology/lock-security

### LONDON

London Museum, Roman key-ring, object catalogue. https://www.londonmuseum.org.uk/collections/v/object-7358/key-ring-key/

### VAM

Victoria and Albert Museum, Roman key ring, object O122113. https://api.vam.ac.uk/v2/object/O122113

### KRUH

L. Kruh, The Genesis of the Jefferson/Bazeries Cipher Device, Cryptologia 5:4 (1981), pp. 193-208. https://www.cs.umd.edu/~gasarch/TOPICS/miscrypto/jefferson.pdf

### SCI

Science Museum Group, Bramah padlock and key, object 1972-290, catalogued 1801. https://collection.sciencemuseumgroup.org.uk/objects/co50473/bramah-padlock-and-key-lock

### SCIP

Science Museum Group, challenge board for Bramah padlock, museum inventory. https://collection.sciencemuseumgroup.org.uk/objects/co50474/challenge-board-for-bramah-padlock

### LHL

Linda Hall Library, Joseph Bramah, independent history of science note. https://www.lindahall.org/about/news/scientist-of-the-day/joseph-bramah/

### LHLH

Linda Hall Library, Alfred Charles Hobbs, history of science note. https://www.lindahall.org/about/news/scientist-of-the-day/alfred-charles-hobbs/

### YALESR

US patent 18,169, Linus Yale Sr., Newport NY (1857), original patent text. https://patents.google.com/patent/US18169A/en

### YALEJR

US patent 48,475, Linus Yale Jr. (27 June 1865), original patent text. https://patents.google.com/patent/US48475A/en

### MIT

Lemelson-MIT, Linus Yale, independent inventor biography. https://lemelson.mit.edu/resources/linus-yale

### OXF

Oxford University Press, American National Biography: Linus Yale Jr.. https://academic.oup.com/american-national-biography/reference/63042/reference-article-abstract/570582807

### ASME

American Society of Mechanical Engineers, Linus Yale Jr., historical profile. https://www.asme.org/topics-resources/content/linus-yale-jr

### SARGARCH

James Sargent obituary, Rochester press, 1910 (historical clipping at NYSCU archive). https://nyscu.org/Archives/Universalist%20Memory%20Garden/Universalist%20Memory%20Garden%20SA-SL/Sargent,%20James%201910.pdf

### HORO

D. A. Christianson, Timelocks, Horological Times (June 1993), pp. 24 ff., watchmaking professional journal. https://www.awci.com/wp-content/uploads/ht/1993/1993-06-web.pdf

### SMITH

Smithsonian National Museum of American History, Sargent 1877 lock-and-time mechanism patent model. https://americanhistory.si.edu/collections/object/nmah_850669

### TEK

Tekniikan akateemiset TEK, Maailman paras lukko (2017), Finnish engineering association. https://www.tek.fi/fi/uutiset-blogit/maailman-paras-lukko

### KALEVA

Kaleva, Satavuotias suomalainen keksintö (2007), independent historical journalism. https://www.kaleva.fi/satavuotias-suomalainen-keksinto/2313774

### PUL

G. W. Pulford, High-Security Mechanical Locks: An Encyclopedic Reference (Elsevier/Butterworth-Heinemann, 2007). https://books.google.com/books?id=7m41LA8WsvUC

### FELTER

US patent 76,066, P. S. Felter, 31 March 1868, original patent document. https://patents.google.com/patent/US76066A/en

### EURO

Europeana, Ismail al-Jazari: historical combination locks, with museum objects. https://www.europeana.eu/eu/stories/ismail-al-jazari-the-muslim-inventor-who-may-have-inspired-leonardo-da-vinci

### TWIERDZA

Twierdza Kraków, Szkoła Ślusarska w Świątnikach Górnych, municipal heritage record. https://twierdza.krakow.pl/oum-location/szkola-slusarska-w-swiatnikach-gornych/

### PTTK

PTTK, Świątniki Górne, regional heritage inventory. https://malopolska.szlaki.pttk.pl/2685-pttk-malopolska-swiatniki-gorne

### VISIT

Małopolska official tourism, Muzeum Ślusarstwa im. Marcina Mikuły. https://visitmalopolska.pl/-/swiatniki-gorne-muzeum-slusarstwa

### CHMIEL

A. Chmiel, Godła rzemieślnicze i przemysłowe krakowskie, historical study. https://bcpw.bg.pw.edu.pl/Content/6522/download

### RAK

E. Rak, Z historii firmy zegarmistrzowskiej Józefa Płonki, Krzysztofory, scholarly paper. https://journals.akademicka.pl/krzysztofory/article/download/6918/6505/9489

### MNWR

Muzeum Narodowe we Wrocławiu, Żelazny świat, official exhibition catalogue, 2022. https://mnwr.pl/zelazny-swiat-zabytki-slusarskie/

### MNWR450

Muzeum Narodowe we Wrocławiu, Żelazny świat, exhibition opening and objects. https://mnwr.pl/zelazny-swiat-fotorelacja-z-konferencji-prasowej-i-wernisazu/

### WRO

Wrocław municipal cultural news, Żelazny świat, 14 July 2022. https://www.wroclaw.pl/kultura/klodki-zamki-zelazny-swiat-wystawa-muzeum-narodowe

### MAGPAT

US patent 1,669,115 (1928), early magnetic key technology, primary record, not origin of all passive locks. https://patents.google.com/patent/US1669115A/en

### SIDEPAT

US patent 4,015,458 (1977), historical example of sidebar and wafer configuration, not first-invention evidence. https://patents.google.com/patent/US4015458A/en


## Uwagi o bezpieczeństwie treści

Teksty przeznaczone do gry są opowieściami o historii, rzemiośle i ogólnych zasadach działania. Żaden tekst nie wyjaśnia kolejności używania narzędzi, tolerancji, reakcji zamka na manipulację ani metod obejścia współczesnych zabezpieczeń. Fikcyjne sterowanie i uproszczenia dokumentacji projektowej pozostają odrębne od historii techniki.
