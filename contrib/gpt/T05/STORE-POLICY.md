# T05 — Przegląd zgodności Lockwright z App Store i Google Play

> **To nie jest porada prawna.** Jest to redakcyjno-produktowy przegląd zasad sklepów, sporządzony 5 listopada 2026 r. Decyzję o akceptacji podejmują operatorzy sklepów, a ocenę prawną w poszczególnych jurysdykcjach należy przeprowadzić osobno.

**Zakres:** iOS/Android, gra Lockwright: Pogotowie Zamkowe / Lockwright: Locksmith on Call. Ocena na podstawie repozytorium i oficjalnych polityk dostępnych 2026-11-05; nie jest to test gotowego builda ani wydana ocena IARC.

## 1. Wniosek i decyzje przed wysyłką

**Sam motyw otwierania zamków w fikcyjnej grze o legalnym ślusarzu nie jest automatycznym naruszeniem regulaminów.** Nie ma w zweryfikowanych politykach uniwersalnego zakazu gier o wytrychach. Ryzyko rośnie, jeśli produkt pokazuje użyteczne procedury otwierania realnych zabezpieczeń, premiuje wejście bez uprawnienia lub przedstawia otwieranie zamków jako sposób dokonania kradzieży. Apple zakazuje promowania przestępstw w **sekcji 5 (wstęp)**; Google Play zakazuje ułatwiania lub promowania nielegalnych działań w **Illegal activities**.

**Werdykt: WARUNKOWO DO DALSZYCH PRAC; NIE GOTOWE DO SUBMISSION.** Najpierw trzeba naprawić weryfikację uprawnień w interakcji, rozstrzygnąć model zakupowy, dokończyć politykę prywatności i potwierdzić, że obrazy i opisy pokazują wyłącznie funkcje rzeczywiście obecne w wydaniu. Nie ma podstaw do zagwarantowania oceny 4+ / PEGI 3 przed sprawdzeniem końcowej zawartości i formularzy.

**Najważniejsza różnica względem dotychczasowego audytu:** komentarz w **game/scripts/ui/job_verify.gd** mówi, że otwarcie zleceń typu odmowa jest niemożliwe, ale metoda **_accept()** bez warunku przechodzi do **JobRun.lock_scene_path()**, bez sprawdzenia typu zlecenia, kart ani progu. Dane **job.refuse_aunt_alive**, **job.refuse_ex_partner**, **job.refuse_rush_bribe** istnieją. To jest wykryta luka w warstwie UI, wymagająca sprawdzenia całego przepływu w działającym buildzie. Samo tekstowe zapewnienie „ślusarz zawsze weryfikuje” nie wystarczy.

## 2. Materiał repozytorium i ograniczenia

Przeczytano: **CLAUDE.md**, **docs/styles/realizm.md**, **docs/DESIGN.md**, **docs/HUD.md**, **store/listing.md**, **store/privacy.md**, **store/rating.md**, **docs/COMPLIANCE-AUDIT.md**, pomocniczo **docs/DECISIONS.md** i **docs/JOBS.md**. Zweryfikowano też **game/scripts/ui/job_verify.gd**, **game/scripts/ui/boot.gd**, **game/scripts/ui/main_menu.gd**, scenę **game/scenes/job_verify.tscn** oraz trzy pliki danych odmowy.

- Ustalone: fotorealizm z przekrojami fikcyjnych zamków; brak marek użytkowych; w opisie i ekranie „O grze” notka „to gra, nie kurs”; w modelu fabularnym sprawdzanie prawa do lokalu i odmowy; zgodnie z D-06 model płatności jeszcze nie wybrany.
- Z dokumentów wynika: wersje PL/EN, brak reklam i kont, zapisy lokalne, docelowo bez telemetrii. **Nie weryfikowano skompilowanego pakietu ani faktycznych transmisji danych.**
- **docs/DESIGN.md §2** zawiera starszy schemat HUD-u z paskiem, podczas gdy **docs/HUD.md** i D-12 wymagają interfejsu diegetycznego. Dla publikacji i screenshotów przyjąć nowszy HUD; rozbieżność rozwiązać poza T05.
- **docs/COMPLIANCE-AUDIT.md** jest migawką wcześniejszego stanu; nie zastępuje testu ścieżek odmowy i finalnych plików sklepowych.

## 3. Rejestr ryzyk (priorytet i odniesienie do reguł)

Oceny **wysokie / średnie / niskie** oznaczają priorytet dla premiery (połączenie skutku i prawdopodobieństwa), a nie przewidywaną decyzję recenzenta. Google Play w większości używa **nazw sekcji**, nie numerów; nie należy dopisywać fikcyjnych numerów.

| ID | Priorytet | Ryzyko / obserwacja | Zalecenie i właściciel | Wytyczna |
|---|---|---|---|---|
| R01 | **Wysokie** | Fikcyjne przekroje i realistyczne sprzężenie zwrotne mogą zostać odebrane jako praktyczny instruktaż do realnych zamków. | Utrzymać mechanizmy wymyślone, bez parametrów realnych modeli, instrukcji przejścia konkretnych zamków i porad obchodzenia zabezpieczeń; przegląd końcowego gameplayu (A/B). | Apple **§5 wstęp**, warunkowo **1.1.3**; Google **Illegal activities**. |
| R02 | **Wysokie** | **_accept()** w job_verify.gd przechodzi do zamka nawet dla zleceń **job.refuse_***; nie widać tu walidacji uprawnień ani progu. Deklaracja „zawsze sprawdza” jest nieudowodniona i może być fałszywa w buildzie. | Zablokować akceptację zleceń odmowy, egzekwować próg dla pozostałych i dodać test ścieżek, także po wznowieniu stanu; **zmiana poza T05 — sesja B**. | Apple **§5 wstęp**, **2.3**, **2.3.1**; Google **Illegal activities**, **Store Listing and Promotion / Misleading Claims**. |
| R03 | **Wysokie** | Sama notka „to gra, nie kurs” nie neutralizuje ewentualnych rzeczywistych instrukcji lub nagradzania nielegalnego wejścia. | Traktować notkę jako kontekst pomocniczy, a bezpieczeństwo egzekwować regułami i zawartością gry (A/B/C). | Apple **§5 wstęp**, **2.3**; Google **Illegal activities**. |
| R04 | **Średnie** | W **store/listing.md** opis detalicznie mówi o ustawianiu pinów i „nauczysz się je odróżniać”; wyrażenie **lockpicking** jest w słowach kluczowych. Może marketingowo przesłonić ramę legalnej usługi. | W pierwszych dwóch zdaniach podać rolę ślusarza, prawo do lokalu, fikcyjny charakter symulacji; zamienić słowo „nauczysz” na „w grze odczytujesz”; rozważyć usunięcie lockpicking z keywords (C). | Apple **§5 wstęp**, **2.3.7**; Google **Illegal activities**, **Metadata**. |
| R05 | **Średnie** | Screenshot ciemnej klatki / samej wkładki może sugerować włamanie mimo bezpiecznego scenariusza. | Pierwszy screenshot: zlecenie + potwierdzenie prawa do wejścia, drugi: fikcyjny mechanizm, trzeci: warsztat; żadnej narracji o łupie, pościgu lub nocnym „włamie” (A/C). | Apple **2.3.3**, **2.3.8**, **§5 wstęp**; Google **Store Listing and Promotion**, **Illegal activities**. |
| R06 | **Średnie** | Opis obiecuje szpulki, gablotę, lupę, kredę, wyzwanie „w ciemności”, timer i pełny Tryb Zleceń, ale zakres 1.0 nadal nie jest zamknięty. | Sprawdzić każdy punkt na finalnym buildzie; niewdrożone funkcje usunąć z metadanych i materiałów (C/B). | Apple **2.3.1**, **2.3.3**, **2.3.4**; Google **Metadata**, **Misleading Claims**. |
| R07 | **Średnie** | Rating 4+ / PEGI 3 / USK 0 to hipoteza. Sceny z nieuprawnionym wejściem i próbą przekupstwa mogą wymagać odpowiedzi „odniesienie do działania nielegalnego”, jeśli formularz tak pyta. | Przejść rzeczywiste formularze na podstawie builda; nie wpisywać automatycznie „No” dla wszelkich odniesień do przestępstw. Zachować potwierdzenia odpowiedzi (C). | Apple **2.3.6**, **2.3.8**; Google **Content ratings / IARC**, **Families** (uczciwe deklaracje). |
| R08 | **Średnie** | Gra może trafić do dzieci mimo pozycjonowania 13+; nieprawdziwa deklaracja grupy docelowej lub dziecięcego charakteru rodzi obowiązki Families / Kids. | Wybór 13–15, 16–17, 18+ tylko jeśli faktycznie te grupy są targetowane; ocenić ikony, zwiastun, język i promocję. Nie oznaczać automatycznie „Made for Kids” (C/właściciel). | Apple **1.3**, **5.1.4**, **2.3.6**; Google **Families Policy Requirements**, **Target audience and content**. |
| R09 | **Wysokie** | **store/privacy.md** zawiera nieuzupełnione pola administratora, adresu, dostawcy poczty, retencji i strony hostującej. Takiego dokumentu nie należy publikować. | Uzupełnić PL/EN, utrzymać dostępny publiczny URL i kontakt wewnątrz aplikacji; sprawdzić zasady RODO (C/właściciel). | Apple **5.1.1(i)**, **1.5**, **2.1(a)**; Google **Privacy Policy**. |
| R10 | **Średnie** | Deklaracje „No data collected”, „offline” i brak INTERNET są zgodne tylko z dokładnym eksportem i realnym SDK. IAP, diagnostyka lub natywne dodatki mogą zmienić sytuację. | Audyt uprawnień, SDK i ruchu sieciowego w release iOS/Android; zaktualizować App Privacy, Data safety, privacy manifest i teksty przed publikacją (B/C). | Apple **5.1.1**, **5.1.2**, **1.6**; Google **Data safety**, **User Data / Privacy Policy**. |
| R11 | **Średnie** | D-06 jest nierozstrzygnięte. Demo + odblokowanie bez natywnych płatności, przywracania zakupów lub jawnego paywalla spowoduje problem. | Wybrać model przed submission; dla odblokowania użyć StoreKit IAP + Play Billing, odtwarzać uprawnienie i testować offline/ponowną instalację (B/C). | Apple **3.1.1**, **2.1(b)**, **3.2**; Google **Payments §1–2, §4, §6**. |
| R12 | **Niskie** | Monety i napiwki mogą pomylić odbiorcę, jeśli opisywać je jak zakłady lub mikropłatności. Obecnie brak hazardu i kupowanych losowych nagród. | Używać „waluta zdobywana w grze”; nie dodawać płatnych losowych skrzynek bez nowego przeglądu (A/C). | Apple **5.3**, **3.1.1**; Google **Content ratings / IARC**, **Payments §7**. |
| R13 | **Niskie** | Portrety, nazwy historyczne, materiały i fonogramy mogą naruszać prawa, jeśli do builda trafią cudze zasoby / współczesne znaki. | Audyt nazw i praw/licencji wszystkich finalnych assetów i screenshotów, także AI i czcionek; zero realnych osób i marek użytkowych (A/C). | Apple **5.2.1**, **2.3.9**; Google **Intellectual Property**. |
| R14 | **Średnie** | Zgodność z normą prawną może różnić się geograficznie; ślusarz w fabule nie musi mieć ustawowej licencji, ale nie wolno obiecywać takiej licencji uniwersalnie. | Stosować „professional locksmith / zawodowy ślusarz”, nie „licensed”; unikać twierdzeń o skutecznej metodzie prawdziwego otwierania. Weryfikować lokalne obostrzenia przed dystrybucją (C/prawnik). | Apple **§5 wstęp**, **2.3.1**; Google **Illegal activities**, **Misleading Claims**. |

**Kolejność blokad:** R02 → R09 → R11 → R01/R03 → R06/R07/R08 → reszta.

## 4. Teksty PL/EN rekomendowane do sklepu i gry

Teksty są **propozycją do wdrożenia w innych katalogach**, nie zmianą tamtych plików. Obejmują oba języki. Nie sugerują prawdziwych technik otwierania.

| Lokalizacja | PL — proponowany tekst | EN — proposed wording |
|---|---|---|
| Pierwszy akapit opisu | „Ktoś zatrzasnął drzwi do własnego mieszkania. Jako ślusarz pogotowia zamkowego najpierw sprawdzasz prawo klienta do wejścia. Potem rozwiązujesz zagadkę fikcyjnego zamka, słuchając i obserwując jego sygnały.” | “Someone has been locked out of their own home. As an emergency locksmith, you first check that the customer has the right to enter. Then you solve a fictional lock puzzle through sound, touch and visual clues.” |
| Zastąpienie „Nauczysz się je odróżniać” | „W grze uczysz się rozpoznawać sygnały wymyślonego mechanizmu.” | “In the game, you learn to read the clues of an invented mechanism.” |
| Notka „O grze” | „To fikcyjna gra logiczna, nie instrukcja otwierania prawdziwych zamków. Wszystkie mechanizmy są wymyślone. Ślusarz pomaga tylko osobom uprawnionym do wejścia.” | “This is a fictional puzzle game, not a guide to opening real locks. All mechanisms are invented. The locksmith helps only people entitled to enter.” |
| Tekst dla sceny odmowy | „Bez potwierdzenia prawa do lokalu nie mogę otworzyć drzwi. Mogę pomóc skontaktować się z zarządcą lub właściwymi służbami.” | “Without proof of the right to enter, I can't open this door. I can help contact the building manager or the appropriate authorities.” |
| Demo + unlock (tylko jeśli zatwierdzono D-06) | „Pierwsze zlecenia są dostępne bezpłatnie. Jednorazowy zakup w aplikacji odblokowuje całą grę. Bez subskrypcji.” | “The first jobs are free to play. A single in-app purchase unlocks the full game. No subscription.” |
| Premium (tylko jeśli wybrany model płatny) | „Pełna gra dostępna po jednorazowym zakupie w sklepie. Bez reklam i zakupów w aplikacji.” | “The complete game is included in the one-time store purchase. No ads or in-app purchases.” |

**Dodatkowe poprawki:** 
- Zachować nazwy z D-32: **Lockwright: Pogotowie Zamkowe** i **Lockwright: Locksmith on Call**; nie używać 31-znakowego „Emergency Locksmith” w tytule EN.
- Rozważyć zastąpienie słowa **lockpicking** w słowach kluczowych neutralnym określeniem symulacji / łamigłówki; to ostrożność marketingowa, **nie zakaz słowa przez sklep**.
- Jeśli finalny build nie wymusza sprawdzenia prawa do wejścia przed każdą pracą, poprawić grę **przed** publikacją powyższych twierdzeń, a nie tylko opis.
- W opisie premiery nie pisać o konkretnym trybie, mechanice lub dźwięku, którego nie da się zademonstrować recenzentowi.

## 5. Ocena wiekowa: Apple i IARC

| Kategoria | Uzasadnienie i rekomendowana odpowiedź (weryfikować z realnym formularzem) | Podstawa |
|---|---|---|
| Apple — przemoc realistyczna / fantastyczna | **None**, jeżeli jedynie pęka narzędzie, bez krzywdy ludzi/zwierząt, broni lub brutalnej sceny. | Apple **2.3.6**, opis progów w **Age ratings values and definitions**. |
| Apple — hazard / losowość | **None**, o ile monety pochodzą wyłącznie z rozgrywki, nie ma zakładów, kupowanych loot boxów ani konkursów z nagrodami. Proceduralny generator zagadek nie jest hazardem. | Apple **2.3.6**, **5.3**. |
| Apple — groza / sugestywne wątki | **None** tylko po przeglądzie wszystkich scen i dźwięków (nocne zlecenia bez straszenia, zero jump scare). | Apple **2.3.6**. |
| Apple — wynik | **4+ to roboczy cel**, a nie przyznany certyfikat. Apple stosuje obecnie progi 4+, 9+, 13+, 16+, 18+ na nowszych systemach. | Apple **Age ratings values and definitions**, **2.3.6**. |
| Google/IARC — przemoc / strach / hazard / substancje | Najpewniej **No / None**, jeśli finalna treść pozostanie zgodna z założeniami; osobno sprawdzić brzmienie pytań. | Google **Content ratings**, **Families Policy Requirements**. |
| Google/IARC — czyny nielegalne / przekupstwo | **Nie deklarować automatycznie „No”.** Sceny odmowy i proponowania dopłaty mogą być **odniesieniem** do potencjalnie nielegalnego czynu, nawet gdy nie ma jego popełnienia ani nagrody. Jeśli pytanie dotyczy wyłącznie czynów nagradzanych — opisać brak; jeśli także samych odniesień — ujawnić je zgodnie z formularzem. | Google **Content ratings / IARC**, **Families Policy Requirements**. |
| Google/IARC — wynik | **PEGI 3 / ESRB E / USK 0 tylko prognoza**. PEGI 7 lub wyższe może być wynikiem odpowiedzi o scenach i lęku; nie deklarować gwarantowanego wyniku. | Google **Apps & Games content ratings on Google Play**. |
| Oba — zakupy | Model premium: brak IAP; demo + zakup: wskazać zakupy cyfrowe / in-game purchases w wymaganych polach. Nie mylić monet earned-in-game z płatnymi loot boxami. | Apple **2.3.6**, **3.1.1**; Google **Payments**, **Content ratings**. |

**Uwagi:** Sam rating opisuje treść, a nie potwierdza zgodności z zakazem ułatwiania przestępstw. Zaznaczenie 13+ jako grupy marketingowej w Play Console nie nadaje automatycznie oceny PEGI 13 ani nie uchyla Families, jeżeli gra jest faktycznie kierowana do młodszych.

## 6. Dzieci i prywatność

1. **Apple Kids Category:** 4+ nie oznacza automatycznie „Made for Kids”. Nie wybierać Kids Category, jeśli gra naprawdę jest kierowana do starszych odbiorców. Jeśli projekt i marketing będą skierowane do dzieci, obowiązują dodatkowe bariery rodzicielskie dla zakupów/odnośników i silniejsze zasady prywatności (Apple **1.3**, **5.1.4**).
2. **Google Target audience:** wskazywane w **store/privacy.md** grupy 13–15, 16–17, 18+ są uzasadnione jedynie, jeśli rzeczywiście są odbiorcą gry. Google może analizować atrakcyjność dla dzieci na podstawie grafiki i promocji (Google **Target audience and content**, **Families Policy Requirements**). Nie omijać Families przez formalne wybranie 13+ przy wyraźnie dziecięcym produkcie.
3. **Obecny minimalizm danych to atut, lecz nie dowód:** brak kont, reklam, analityki i lokalne zapisy zmniejszają ryzyko. Potwierdzić w końcowych paczkach uprawnienia, SDK, backup, ewentualne tokeny rozliczeń i telemetrię. Dopiero potem podpisać deklaracje Apple App Privacy i Google Data safety (Apple **5.1.1**, Google **Data safety**).
4. **Dokument prywatności PL/EN:** uzupełnić nazwę podmiotu, adres, e-mail, dostawcę poczty, termin retencji, datę, publiczny URL i właściwy organ nadzoru; urealnić informację o diagnostyce, zakupach i backupach. Link ma działać również z ekranu „O grze” lub ustawień (Apple **5.1.1(i)**, Google **Privacy Policy**).
5. **Kontakt z dzieckiem:** wiadomość e-mail wysłana do wsparcia nie jest równoznaczna z transmisją telemetrii przez grę, lecz stanowi przetwarzanie danych przez operatora kontaktu; nie wolno deklarować absolutnego braku jakichkolwiek danych, nie wyjaśniając obsługi e-maili (Apple **5.1.1(i)**, Google **Privacy Policy**).
6. **Gdy zmieni się produkt:** jakakolwiek analityka, crash SDK, rankingi online, UGC, linki, multiplayer lub profil użytkownika oznaczają ponowną ocenę prywatności, targetu i ratingów przed aktualizacją (Apple **1.2**, **5.1**, Google **User Data**, **Families**).

## 7. Zakupy — dwa zgodne warianty

| Aspekt | **Wariant P: płatna aplikacja (premium)** | **Wariant D: bezpłatny początek + odblokowanie** |
|---|---|---|
| Dostęp | Cała gra po zakupie aplikacji w App Store / Google Play. | Jedna darmowa aplikacja; kilka w pełni działających zleceń, reszta za jedną opłatą. |
| Zakup w aplikacji | Nie jest wymagany do dostępu; opłata za pobranie rozliczana przez sklep. | **Apple StoreKit non-consumable IAP** + **Google Play Billing one-time product**; jawna cena i zawartość. |
| Odzyskiwanie | Standardowe ponowne pobranie przez konto sklepu. | Odtwarzanie/restorowanie uprawnienia na urządzeniu i po ponownej instalacji; nie polegać wyłącznie na lokalnym fladze. |
| Metadane | Brak obietnicy darmowego demo; deklaracja **No IAP**, o ile rzeczywiście brak. | Jasne „free to start, one-time full unlock”; IAP w deklaracjach sklepu i formularzu ratingowym. |
| Ryzyka | Przypadkowo zablokowany poziom lub niedziałający zakup pełnej aplikacji. | Brak dostępności zakupu podczas review, brak restore, błędne paywall/entitlement, nieprawdziwe „w pełni offline” przy pobieraniu uprawnienia. |
| Polityki | Apple **2.1(a)**, **2.3**; Google **Payments §1**, **Metadata**. | Apple **3.1.1**, **2.1(b)**, **2.2** (nie tworzyć osobnej aplikacji tylko „demo”), **2.3**; Google **Payments §2, §4, §6**. |

**Rekomendacja zgodności, nie decyzja biznesowa:** wariant P jest prostszy wdrożeniowo i prywatnościowo, ale utrudnia graczom test wyczucia i haptyki przed zakupem. Wariant D jest sensowny dla tej gry, **pod warunkiem** pełnego, poprawnego natywnego rozliczenia. Nie uznawać żadnego z wariantów za zatwierdzony — **D-06 nadal otwarta**. Brak subskrypcji, pay-to-win i płatnych monet pozostaje regułą produktu.

## 8. Notatka dla zespołu recenzyjnego (PL + EN)

**English — App Review Notes / Google Play reviewer notes (use only after R02 is fixed):**

> Lockwright is a fictional puzzle game about an emergency locksmith helping customers who are locked out of premises they are entitled to enter. The player must verify the customer's right to enter before opening a lock; suspicious requests are refused. Every depicted mechanism is invented and simplified for gameplay. The game does not provide instructions for bypassing real branded locks or security products. The About screen explicitly states that this is a game, not a training course. There are no ads or user accounts. Please review the verification and refusal scenes as well as the lock puzzle. In-app purchases: [select premium/no IAP OR free start with one non-consumable full unlock before submission].

**Polski — odpowiednik do kontroli znaczenia:**

> Lockwright to fikcyjna gra logiczna o ślusarzu pogotowia zamkowego, pomagającym klientom uprawnionym do wejścia do lokalu. Gracz musi zweryfikować prawo klienta do wejścia przed otwarciem zamka; podejrzane zlecenia kończą się odmową. Wszystkie pokazane mechanizmy są wymyślone i uproszczone na potrzeby gry. Gra nie zawiera instrukcji obchodzenia zabezpieczeń rzeczywistych zamków ani produktów określonych marek. Ekran „O grze” zawiera informację, że to gra, nie kurs. Nie ma reklam ani kont użytkowników. Prosimy o ocenę scen weryfikacji i odmowy oraz zagadek z zamkami. Zakupy: [uzupełnić wybrany wariant przed wysyłką].

**Nie deklarować** „the player must verify” dopóki przepływ kodu nie zostanie naprawiony i przetestowany. Opisać recenzentowi wszystkie nietypowe funkcje, pełny dostęp do odpowiednich scen i ewentualny zakup (Apple **2.1**, **2.3.1**). Nie przedstawiać tej notatki jako gwarancji akceptacji.

## 9. Lista kontrolna przed wysłaniem (36 kroków)

**Mechanika i bezpieczeństwo**
- [ ] 01. Zlecenia **job.refuse_*** nie pozwalają otworzyć zamka ani przyjąć łapówki; test automatyczny + ręczny.
- [ ] 02. Wszystkie pozostałe zlecenia wymagają rzeczywistego potwierdzenia prawa do lokalu według zasad gry.
- [ ] 03. Weryfikacji nie da się ominąć przez cofnięcie ekranu, restart, zapis/odczyt ani bezpośrednie wejście do sceny zamka.
- [ ] 04. Gracz otrzymuje czytelny skutek odmowy i nie jest za nią karany fabularnie.
- [ ] 05. Sceny nie zawierają taktyk skutecznego oszukiwania prawdziwego ślusarza.
- [ ] 06. Nie ma instrukcji do prawdziwych, nazwanych zamków, wkładek, samochodów ani sejfów.
- [ ] 07. Rozgrywka i materiały promocyjne nie nagradzają kradzieży lub wejścia bez uprawnienia.
- [ ] 08. Metody niszczące są abstrakcyjne, bez miejsc wiercenia i prawdziwych procedur; w fabule wymagają zgody klienta.
- [ ] 09. Pierwsza notka „to gra, nie kurs” wyświetla się po PL i EN; dostępna też później w „O grze”.
- [ ] 10. Kontrola wszystkich dialogów PL/EN pod kątem gróźb, przemocy, treści seksualnych, alkoholu, hazardu i wulgaryzmów.

**Strona sklepowa i grafiki**
- [ ] 11. Nazwy PL/EN są zgodne z D-32 i mają maks. 30 znaków.
- [ ] 12. Opisy zaczynają się od legalnego zlecenia i fikcyjnej zagadki, nie od sugestii włamania.
- [ ] 13. Usunięto instruktażowe sformułowania i rozważono neutralne keywords.
- [ ] 14. Każda obietnica funkcji w opisie jest dostępna w buildzie wysyłanym do recenzji.
- [ ] 15. Apple screenshots pokazują **autentyczne** działanie aplikacji, a nie same rendery koncepcyjne.
- [ ] 16. Screenshots/preview przedstawiają weryfikację prawa do lokalu, warsztat i fikcyjny mechanizm bez estetyki złodzieja.
- [ ] 17. Ikony i metadane dla App Store są odpowiednie także dla szerokiej publiczności (Apple 2.3.8).
- [ ] 18. Nie ma nazw innych gier, znaków, cudzych osób, marek i nieudokumentowanych zasobów.
- [ ] 19. Limity pól App Store/Play oraz poprawność obu lokalizacji zostały sprawdzone na ostatecznych tekstach.
- [ ] 20. Kontakty Support URL i widoczne dane dewelopera są aktualne.

**Rating i odbiorcy**
- [ ] 21. Ankieta Apple age rating została wypełniona z finalnym scenariuszem i dźwiękiem (nie z projektem).
- [ ] 22. Ankieta Google IARC uwzględnia każde pytanie o **odniesienie** do czynu nielegalnego, nie tylko jego nagradzanie.
- [ ] 23. Wyniki Apple/IARC zapisano; sklepowe oceny i deskryptory zgadzają się z treścią.
- [ ] 24. Rzeczywiste targetowanie wiekowe w Google Play odzwierciedla projekt i materiały marketingowe.
- [ ] 25. Jeżeli gra jest kierowana do dzieci, wdrożono odpowiednie Kids/Families safeguards; jeżeli nie — nie sugerujemy „for kids”.
- [ ] 26. Wszystkie ewentualne reklamy, łączność, UGC i konkursy są zgodnie zadeklarowane; przy obecnym projekcie powinny być nieobecne.

**Prywatność i zakup**
- [ ] 27. Polityka prywatności PL/EN ma prawidłowego administratora, adresy, datę, retencję i dostawcę poczty.
- [ ] 28. Publiczny privacy URL działa bez logowania, na telefonie, po PL/EN i z poziomu gry.
- [ ] 29. Audyt eksportów iOS/Android potwierdza brak nieujawnionych SDK, identyfikatorów, analityki i uprawnień.
- [ ] 30. Formularze App Privacy, Data safety i manifest iOS odzwierciedlają **rzeczywisty** release.
- [ ] 31. Właściciel jednoznacznie zatwierdził D-06 (premium albo free start + unlock).
- [ ] 32. Dla unlock: skonfigurowano produkty StoreKit/Play Billing, cenę, mechanizm restore i test zakupów/odwołań.
- [ ] 33. Dla unlock: recenzent może zademonstrować pełny przebieg i zakup bez niedostępnych usług.
- [ ] 34. Treść w obu językach uczciwie wyjaśnia co jest darmowe, co kupowane i czego zakup nie obejmuje.
- [ ] 35. Przetestowano działanie offline, lokalny zapis, reinstalację, ewentualne przywrócenie zakupu i systemowy backup.
- [ ] 36. Wszystkie placeholdery w opisach, polityce prywatności, linkach, e-mailach i notatkach dla recenzenta usunięto.

## 10. Oficjalne źródła i mapowanie punktów (dostęp 2026-11-05)

**Apple — numerowane podpunkty**, użyte powyżej:
- App Store Review Guidelines, sekcja **5 — Legal (wstęp: promowanie przestępstwa)**, **1.1.3**, **1.3**, **1.5**, **1.6**, **2.1(a/b)**, **2.2**, **2.3.1**, **2.3.3/4/6/7/8/9**, **3.1.1**, **3.2**, **5.1.1**, **5.1.2**, **5.1.4**, **5.2.1**, **5.3**: https://developer.apple.com/app-store/review/guidelines/
- App Store Connect, Age ratings values and definitions: https://developer.apple.com/help/app-store-connect/reference/app-information/age-ratings-values-and-definitions/
- App Store Connect, Set a price: https://developer.apple.com/help/app-store-connect/manage-app-pricing/set-a-price/

**Google Play — dokładne tytuły sekcji** (Google nie numeruje większości zasad):
- **Illegal activities**: https://support.google.com/googleplay/android-developer/answer/9878877?hl=en
- **Developer Program Policy** — odpowiednio **Payments**, **Privacy Policy**, **Data safety**, **Intellectual Property**, **Metadata**, **User Data**: https://support.google.com/googleplay/android-developer/answer/18265346
- **Understanding Google Play’s Payments policy**: https://support.google.com/googleplay/android-developer/answer/10281818?hl=en
- **Families Policy Requirements**: https://support.google.com/googleplay/android-developer/answer/9893335?hl=en
- **Manage target audience and app content settings**: https://support.google.com/googleplay/android-developer/answer/9867159?hl=en
- **Apps & Games content ratings on Google Play** (IARC/PEGI): https://support.google.com/googleplay/answer/6209544?hl=en
- **Best practices for your store listing**: https://support.google.com/googleplay/android-developer/answer/13393723?hl=en

**Metoda:** źródła pierwotne sklepów sprawdzone 2026-11-05; fakty o grze i kodzie pochodzą z dokumentów i plików repozytorium. Regulaminy są aktualizowane, dlatego przed finalnym wysłaniem należy ponownie sprawdzić ich brzmienie. Powyższa lista kontrolna jest praktycznym planem weryfikacji, nie potwierdzeniem, że gra już ją przeszła.
