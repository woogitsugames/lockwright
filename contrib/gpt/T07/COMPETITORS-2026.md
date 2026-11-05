# Lockwright — analiza konkurencji i kolizji nazwy (T07)

**Stan badania: 5 listopada 2026 r.** Zakres: gry na telefon/PC/przeglądarkę, aplikacje pokrewne, urządzenia noszone, wzorce „cozy job sim”, wstępny screening nazwy. **29 pozycji w tabeli** oraz osobno konkurent dokładnie o nazwie Lockwright. To **aneks aktualizujący** [`docs/RESEARCH.md`](../../../../docs/RESEARCH.md) z 4.11.2026; dokumentu źródłowego nie zmieniono, zgodnie z granicą katalogu T07. Nie jest analizą prawną ani dowodem braku kolizji.

## 1. Zakres, definicje i jakość danych

- **Data odczytu i waluta:** 05.11.2026 dla bieżących kart sklepowych (źródło przy tytule), wiersze oznaczone „częściowo” zawierają też liczbę/cenę z bazowego badania 04.11.2026. Ceny i oceny są **migawką**, mogą zmieniać się z regionem/promo; USD = amerykański App Store, GBP = brytyjska karta Steam, EUR = widok regionalny Steam. Nie przeliczano kursów.
- **Pobrania:** Google Play podaje **próg liczby instalacji** (np. 100 000+), a nie dokładną liczbę czy aktywnych użytkowników. App Store, Steam i większość itch.io nie udostępniają publicznie pobrań ani sprzedaży. Wpis **n/p** znaczy „brak wiarygodnej estymacji z dostępnych źródeł”, a nie 0. Nie wymyślano przelicznika recenzji na sprzedaż; szacunek bez danych bazowych byłby mylący.
- **Oceny:** ułamek/5 dotyczy sklepu mobilnego; procent oznacza **pozytywne opinie na Steam** (nie ocena 1–5). „Zbyt mało ocen” nie oznacza, że w aplikacji nie ma żadnej opinii. Dane są przybliżone i zależne od lokalizacji.
- **Test gry bez wzroku:** „Blind mode” (wyłączenie obrazu), etykiety VoiceOver/TalkBack, wibracje i **ukończenie całego przepływu bez wzroku** to cztery **różne** rzeczy. „Brak deklaracji” nie dowodzi braku funkcji. Funkcjonalności nie testowano na urządzeniach. Opis dewelopera to deklaracja, nie audyt WCAG/APG.
- **Ocena strategiczna** w kolumnie „Plus/Brak” jest własną analizą T07, nie cytatem producenta. Wiersze edukacyjne i PC cozy są analogiami, nie bezpośrednimi rywalami o tę samą mechanikę.
- **CSV:** `competitors.csv` przechowuje te same 29 pozycje z oddzielnymi polami, URL-ami, datą i stopniem weryfikacji; kodowanie UTF-8, separator przecinek, wartości w cudzysłowach.

## 2. Porównanie rynku

### A. Mobilne gry o zamkach, sejfach i wyczuciu (15)

| Gra (źródło) | Platforma · model · cena | Ocena · pobrania/sprzedaż | Dźwięk/haptyka · bez wzroku | Co działa i czego brakuje |
|---|---|---|---|---|
| [Unlokee – Lock picking puzzle](https://apps.apple.com/us/app/unlokee-lock-picking-puzzle/id6808786210) ([2](https://play.google.com/store/apps/details?id=com.dmitriyrozhkov.unlokee)) | iOS; Android (wg RESEARCH 04.11). Free chapter + one-off full-game IAP; **USD 7.99 (US App Store)** | iOS 5.0/5 (1); Google Play: n/p; **Android 50+ (próg z 04.11; 05.11 niezweryfikowany)** | tak; dwa kciuki i dźwięk. **Bez wzroku:** brak udokumentowanego trybu bez obrazu | **Plus:** Bardzo bliski rdzeń: napięcie + wytrych; przekrój; 42 zamki i 10 wyzwań. **Brak:** Brak klientów, legalnej weryfikacji i pełnej narracji; mały ślad ocen. |
| [Vale & Daughter: Safecracker](https://apps.apple.com/us/app/vale-daughter-safecracker/id6820067476) | iOS. Darmowy warsztat + jednorazowy unlock; **USD 4.99 (US App Store)** | zbyt mało ocen, bez średniej; **n/p – App Store nie publikuje pobrań** | tak; dźwięk, haptyka, manipulacja fizyczna. **Bez wzroku:** TAK: Blind mode, ekran czarny; nie dowodzi pełnej zgodności z VoiceOver | **Plus:** Ciepła opowieść w listach; gra na wyczucie; no-ads. **Brak:** Sejfy, nie wkładki drzwi; iOS/EN; nieudowodniona pełna dostępność interfejsu. |
| [Shear Line: Lockpicking Game](https://apps.apple.com/us/app/shear-line-lockpicking-game/id6816888965) | iOS. Free-to-play; reklamy i zakupy w aplikacji; **IAP USD 0.99–9.99 (US)** | zbyt mało ocen, bez średniej; **n/p – App Store** | tak; dźwięk i haptyka. **Bez wzroku:** brak deklaracji pełnego grania bez wzroku | **Plus:** Dużo zadań, zwięzłe sterowanie; świeża podaż iOS. **Brak:** Ton heist, monety, boostery i reklamy; mniej fachu i empatii. |
| [Lockpick 101](https://play.google.com/store/apps/details?id=com.Avarice.Lockpick101) | Android. Free-to-play; reklamy i IAP; **bezpłatny start (Google Play)** | 4.4/5 (~1.25 tys. ocen); **100 000+ (publiczny próg Google Play)** | tak; wibracje. **Bez wzroku:** brak opublikowanego trybu bez wzroku | **Plus:** Największy bezpośredni widoczny zasięg w Google Play; prosty feedback. **Brak:** Reklamy, stara oprawa; bliżej ćwiczeń niż fabularnej legalnej usługi. |
| [Key Master: Locksmith Sim](https://apps.apple.com/us/app/key-master-locksmith-sim/id6809031242) | iOS. Free-to-play; IAP / reklamy; **IAP USD 1.99–5.99; usunięcie reklam USD 3.99 (US)** | zbyt mało ocen, bez średniej; **n/p – App Store** | niezweryfikowana. **Bez wzroku:** brak opublikowanego trybu bez wzroku | **Plus:** Praca ślusarza, dorabianie kluczy, dzielnice, rozwój zakładu. **Brak:** Podejrzani klienci i ryzyko policji; brak dwukciukowego symulatora wkładki. |
| [The Impossible Safe – Crack it](https://apps.apple.com/us/app/the-impossible-safe-crack-it/id1573468310) | iOS. Free-to-play; **bezpłatna (US)** | 3.1/5 (187 ocen); **n/p – App Store** | tak; mechanika pokrętła / wrażenia dotykowe. **Bez wzroku:** brak opublikowanego trybu bez wzroku | **Plus:** Krótka pętla z natychmiastowym feedbackiem. **Brak:** Sejf na czas; heist zamiast pomocy klientowi; niskie oceny. |
| [Lock Pick 3D](https://apps.apple.com/us/app/lock-pick-3d/id1517044820) | iOS. Free-to-play / hyper-casual; **bezpłatna (US)** | 4.1/5 (9 ocen); **n/p – App Store** | ASMR w opisie; haptyka niepotwierdzona. **Bez wzroku:** brak deklaracji | **Plus:** Natychmiastowa, przystępna łamigłówka. **Brak:** Płytka mechanika, złodziejski motyw; mało aktualizacji. |
| [Unlocking!](https://apps.apple.com/us/app/unlocking/id6455174981) | iOS. Free-to-play; **bezpłatna (US)** | 4.0/5 (1 ocena); **n/p – App Store** | ASMR w marketingu; haptyka niepotwierdzona. **Bez wzroku:** brak deklaracji | **Plus:** Krótki, abstrakcyjny problem mechaniczny. **Brak:** Brak symulacji pracy, głębi fabularnej i widocznego rozwoju. |
| [12 LOCKS](https://apps.apple.com/us/app/12-locks/id1504871805) | iOS; Android (wg RESEARCH 04.11). Bezpłatna; reklamy raportowane w recenzjach; **bezpłatna (US)** | 4.6/5 (~3.2 tys. ocen); **n/p – App Store; Android bez potwierdzonego progu** | nie potwierdzono. **Bez wzroku:** brak deklaracji | **Plus:** Przyjazny puzzle-room; mocne rodzinne pozycjonowanie. **Brak:** Brak mechaniki wyczuwania wkładki i zawodu ślusarza. |
| [The Vault: Logic Puzzle Box / Open the Safe](https://play.google.com/store/apps/details?id=com.peaksel.openthesafebox_3dsafebreaker_thevault) | Android; iOS (wg RESEARCH 04.11). Free-to-play; reklamy i IAP; **bezpłatna (Google Play)** | 4.5/5 (~66.2 tys. ocen); **5 000 000+ (publiczny próg Google Play)** | interakcja mechaniczna; haptyka w opisie. **Bez wzroku:** brak deklaracji pełnego grania bez obrazu | **Plus:** Duży rynek łamigłówek z mechaniką skrzynek; fabularność. **Brak:** Puzzle-box, nie napięcie narzędzi i legalne zlecenia. |
| [Safe Cracker: Feel the Hinge](https://apps.apple.com/us/app/safe-cracker-feel-the-hinge/id6814453821) | iOS (urządzenia z obsługiwanym mechanizmem). Premium / płatna aplikacja; **USD 0.99 (US App Store)** | zbyt mało ocen, bez średniej; **n/p – App Store** | tak; hinge/haptic feedback. **Bez wzroku:** brak potwierdzenia pełnego trybu bez wzroku | **Plus:** Eksperyment z fizycznym czuciem urządzenia. **Brak:** Wąski sprzętowy gimmick, nie rozbudowane zlecenia. |
| [Safecracker: The Hinge Heist](https://apps.apple.com/us/app/safecracker-the-hinge-heist/id6825358652) | iOS (urządzenia z obsługiwanym mechanizmem). Premium / płatna aplikacja; **USD 5.99 (US App Store)** | zbyt mało ocen, bez średniej; **n/p – App Store** | tak; zawias i haptyka. **Bez wzroku:** brak deklaracji pełnego trybu bez wzroku | **Plus:** Rozszerza eksperymenty z fizyczną manipulacją sejfem. **Brak:** Heist, zależność od sprzętu; brak narracji legalnej usługi. |
| [Crown Heist: Safe Cracker](https://apps.apple.com/us/app/crown-heist-safe-cracker/id6762077725) | Apple Watch; iPhone companion. Free-to-play + subskrypcja; **Royal Pass USD 1.99/tydz. lub 14.99/rok (US)** | zbyt mało ocen, bez średniej; **n/p – App Store** | tak; Digital Crown. **Bez wzroku:** brak deklaracji pełnego trybu bez wzroku | **Plus:** Dotykowe pokrętło na zegarku, bardzo małe sesje. **Brak:** Subskrypcja i heist; brak narzędzi dwóch kciuków. |
| [Pick Lock: Unlock & Learn](https://play.google.com/store/apps/details?id=com.brotherhoodapp.picklock) | Android. Bezpłatna; reklamy; **bezpłatna (Google Play)** | ~4.0/5 (27 ocen; odczyt zależny od regionu); **5 000+ (publiczny próg Google Play)** | deklarowany dźwięk/wibracje. **Bez wzroku:** brak deklaracji | **Plus:** Wyraźny sygnał zainteresowania ćwiczeniem mechanik. **Brak:** Aplikacja edukacyjna, nie pełna gra; zbyt blisko realnych instrukcji dla marki Lockwright. |
| [How to Pick Lock](https://play.google.com/store/apps/details?id=com.mmdevstudio.picklock) | Android. Bezpłatna; reklamy; **bezpłatna (Google Play)** | brak wiarygodnego agregatu ocen; **1 000+ (publiczny próg Google Play; 04.11)** | niezweryfikowana. **Bez wzroku:** brak deklaracji | **Plus:** Popyt na mechaniczne ćwiczenia i przekroje. **Brak:** Nie jest narracyjną grą; pozycjonowanie szkoleniowe sprzeczne z fikcyjnymi zamkami. |

### B. Dostępność i audio-first (cross-platform) (3)

| Gra (źródło) | Platforma · model · cena | Ocena · pobrania/sprzedaż | Dźwięk/haptyka · bez wzroku | Co działa i czego brakuje |
|---|---|---|---|---|
| [Safe Cracker – Watch Game](https://apps.apple.com/us/app/safe-cracker-watch-game/id1638618972) | Apple Watch. Premium / płatna aplikacja; **USD 0.99 (US App Store)** | 5.0/5 (2 oceny); **n/p – App Store** | Digital Crown + głosowy feedback. **Bez wzroku:** TAK: VoiceOver opisuje ruchy pokrętła (deklaracja twórcy); cały przepływ bez wzroku nieprzetestowany | **Plus:** Ważny dowód, że dostępność audio w tej niszy już istnieje. **Brak:** Ograniczona platforma i krótki obieg; sejf zamiast pracy ślusarza. |
| [SafeCracker: Vault Puzzle](https://apps.apple.com/us/app/safecracker-vault-puzzle/id6826062840) | iOS. Premium / płatna aplikacja; **USD 1.99 (US App Store)** | zbyt mało ocen, bez średniej; **n/p – App Store** | tak; sterowanie i haptyka. **Bez wzroku:** CZĘŚCIOWO: deklarowane etykiety VoiceOver i Reduce Motion; brak dowodu ukończenia całej gry bez wzroku | **Plus:** Nowy punkt odniesienia dla dostępności mobilnej. **Brak:** Sejfy i elementy UI zamiast pogotowia; nieustalona głębia dostępności. |
| [Lock Craker (MAGES Institute)](https://magesinstitute.itch.io/lockcraker) | PC: Windows / itch.io. Darmowy projekt studencki; **0 (itch.io)** | brak reprezentatywnych ocen; **n/p – itch.io nie publikuje liczby pobrań na stronie** | audio jako główny kanał. **Bez wzroku:** TAK deklaracja tagu blind-accessible; nie testowano praktycznie | **Plus:** Próba pełnej gry zorientowanej na słuch. **Brak:** Prototyp, PC, sejf; brak zawodowej narracji. |

### C. PC i symulatory mechaniki / zawodu (7)

| Gra (źródło) | Platforma · model · cena | Ocena · pobrania/sprzedaż | Dźwięk/haptyka · bez wzroku | Co działa i czego brakuje |
|---|---|---|---|---|
| [Sophie's Safecracking Simulator](https://store.steampowered.com/app/1651780/) | PC: Steam (Windows/macOS/Linux). Premium / zakup jednorazowy; **EUR 2.39 (odczyt sklepu; lokalna waluta)** | 96% pozytywnych (64 recenzje); **n/p – Steam nie podaje sprzedaży** | feedback mechaniczny; haptyka sprzętowa niepotwierdzona. **Bez wzroku:** brak deklaracji | **Plus:** Głębia manualnego rozumienia mechanizmu. **Brak:** Mała otoczka fabularna; PC zamiast telefonu; niezweryfikowana dostępność. |
| [Museum of Mechanics: Lockpicking](https://store.steampowered.com/app/1735110/) | PC: Steam. Premium / zakup jednorazowy; **EUR 9.75 (odczyt sklepu; lokalna waluta)** | 71% pozytywnych (52 recenzje); **n/p – Steam** | nie dotyczy mobilnej haptyki. **Bez wzroku:** brak deklaracji | **Plus:** Historyczny przegląd pomysłów na mini-gry zamkowe. **Brak:** Brak jednolitej własnej pętli zawodowej i haptyki telefonu. |
| [Shear line (TheNakedCat; nie gra iOS Shear Line)](https://store.steampowered.com/app/5069860/) | PC: Steam. Premium / zakup jednorazowy; **USD 0.99 (odczyt z 04.11; region niejednoznaczny)** | 1 recenzja, bez stabilnej średniej; **n/p – Steam** | fizyka wizualna; brak mobilnych wibracji. **Bez wzroku:** brak deklaracji | **Plus:** Zróżnicowane mechanizmy, wczesny eksperyment PC. **Brak:** Mały zasięg; brak klientów i skupienia na etyce. |
| [Thief Simulator](https://store.steampowered.com/app/704850/) ([2](https://apps.apple.com/us/app/thief-simulator-sneak-steal/id6456607771)) | PC: Steam; konsole; iOS spin-off. Premium PC; mobile F2P; **GBP 1.50 w promocji (UK Steam, 05.11; regularnie GBP 16.75)** | 88% pozytywnych (~11 457 recenzji); **n/p – Steam nie podaje sprzedaży** | minigry zamków; brak mobilnej haptyki potwierdzonej. **Bez wzroku:** brak deklaracji | **Plus:** Silna pętla zadań i świata symulowanego. **Brak:** Temat kradzieży, nielegalność i rozproszenie minigier; brak bezwzrokowej gry. |
| [Locksmith Simulator](https://store.steampowered.com/app/1487060/) | PC: Steam (Coming soon). Nieogłoszony / jeszcze niedostępny; **n/d – brak ceny** | n/d – przed premierą; **n/d – przed premierą** | niezweryfikowana. **Bez wzroku:** brak informacji | **Plus:** Legalny zawód i pomoc klientom – najbliższy motyw formalny. **Brak:** Brak premiery, recenzji i potwierdzonej grywalności; nie mobile. |
| [True Thief](https://store.steampowered.com/app/3188360/) | PC: Steam (Coming soon). Nieogłoszony / jeszcze niedostępny; **n/d – brak ceny** | n/d – przed premierą; **n/d – przed premierą** | niezweryfikowana. **Bez wzroku:** brak informacji | **Plus:** Zawodowa, proceduralna struktura działań. **Brak:** Stealth i przestępczy kontekst; projekt przedpremierowy. |
| [Lobsterpunk](https://store.steampowered.com/app/3414920/) | PC: Steam. Premium; dostępne demo; **GBP 9.09 (UK Steam; 05.11)** | 9 recenzji (bez stabilnej średniej); **n/p – Steam** | niezweryfikowana. **Bez wzroku:** brak deklaracji | **Plus:** Eksploracja świata i przedmiotowe zagadki. **Brak:** Daleka konkurencja, nie wytrych jako centralny system. |

### D. Benchmark cozy / premium (4)

| Gra (źródło) | Platforma · model · cena | Ocena · pobrania/sprzedaż | Dźwięk/haptyka · bez wzroku | Co działa i czego brakuje |
|---|---|---|---|---|
| [PowerWash Simulator](https://store.steampowered.com/app/1290000/) | PC: Steam; konsole. Premium / zakup jednorazowy; **GBP 19.99 (UK Steam; 05.11)** | 97% pozytywnych (~38 628 recenzji EN); **n/p – Steam nie podaje sprzedaży** | mocna pętla bodźców dźwiękowych; brak informacji o haptyce telefonu. **Bez wzroku:** brak deklaracji pełnej gry bez obrazu | **Plus:** Uspokajający rytm usług, natychmiastowa satysfakcja, czytelne zlecenia. **Brak:** Brak zamków i decyzji o legalnej autoryzacji; inny poziom produkcji. |
| [Unpacking](https://store.steampowered.com/app/1135690/) | PC: Steam; konsole; mobile (wg wydawcy). Premium / zakup jednorazowy; **GBP 15.49 (UK Steam; 05.11)** | 93% pozytywnych (~23 123 recenzji EN); **n/p – Steam nie podaje sprzedaży** | audio jako nośnik satysfakcji; mobilna haptyka niebadana. **Bez wzroku:** brak potwierdzenia pełnego trybu bez wzroku | **Plus:** Cicha opowieść przedmiotami; gracz rekonstruuje życie postaci. **Brak:** Bez zleceń interwencyjnych, napięcia dwóch kciuków i legalnej weryfikacji. |
| [A Little to the Left](https://apps.apple.com/us/app/a-little-to-the-left/id1613352146) ([2](https://store.steampowered.com/app/1629520/)) | iOS; PC: Steam. Darmowy początek + IAP na iOS; premium PC; **iOS unlock USD 9.99 (US App Store)** | iOS 4.6/5 (~5.9 tys. ocen); **n/p – App Store i Steam** | precyzyjne przesuwanie przedmiotów; haptics niepotwierdzone. **Bez wzroku:** brak pełnego trybu bez wzroku; dostępność koloru nie równa się VoiceOver | **Plus:** Płatne puzzle „zrelaksowane”, mikrofeedback, rozwiązania alternatywne. **Brak:** Nie ma mechaniki wytrycha ani klienta; premium to benchmark cenowy. |
| [Strange Horticulture](https://apps.apple.com/us/app/strange-horticulture/id6450008138) | iOS; PC i inne platformy. Premium / zakup jednorazowy; **iOS USD 5.99 (US App Store)** | iOS 4.9/5 (~1.5 tys. ocen); **n/p – App Store i Steam** | przedmioty i rytm pracy; haptyka niepotwierdzona. **Bez wzroku:** brak opublikowanej pełnej gry bez wzroku | **Plus:** Spokojny sklep, narracja klientów, decyzje z konsekwencjami. **Brak:** Brak dwukciukowej fizyki i legalnej weryfikacji dostępu. |


## 3. Wnioski z bezpośrednich porównań

| Para | Co już jest zajęte | Co może pozostać charakterystyczne dla Lockwright | Poziom ryzyka |
|---|---|---|---|
| **Unlokee** → Lockwright | Dwa palce, przekrój, ustawianie elementów i haptyka; darmowa próbka + jednorazowy unlock za 7,99 USD | Rzeczywiste zadania pogotowia, weryfikacja uprawnienia przed pracą, rozpoznawalna kamienica, konsekwentny styl diegetyczny | **Wysoki** w rdzeniu mechanicznym |
| **Vale & Daughter** → Lockwright | Gra na słuch i haptykę, ciepły ton oraz **jawny Blind mode** | Wkładki drzwi, dwa niezależne kciuki i pełny interfejs możliwy do obsługi z czytnikiem ekranu | **Wysoki** w komunikacji o „ciemności” |
| **SafeCracker: Vault Puzzle** i **Safe Cracker – Watch Game** | Etykiety **VoiceOver** w pierwszej i opisowe odczyty w drugiej | Wykazanie **kompletnie przechodzalnej gry**, z menu, dokumentami klientów, odmową i samym otwarciem bez patrzenia | **Średni**, brak monopolu na VoiceOver |
| **Key Master: Locksmith Sim** i zapowiedziany **Locksmith Simulator** | Motyw ślusarza jako zawodu / usług | Legalna autoryzacja i empatia wobec mieszkańców jako główna oś; realistyczny manualny „feel” | **Średni** w narracji |
| **The Vault / Lockpick 101** | Mechaniczne puzzle osiągają publiczne progi od 100 tys. do 5 mln instalacji na Androidzie | Bez reklam, bez walut premium, krótkie zlecenia i zapłata raz | **Średni** w odkrywalności i cenie |
| **PowerWash / Unpacking / Strange Horticulture** | Spokojna powtarzalna praca, emocje przez małe gesty i przedmioty | Ten rytm połączony z trudną mikrofizyką dwukciukową i decyzją „czy wolno otwierać” | **Niski** mechanicznie, **wysoki** jako wzorzec jakości |

### 3.1 Trendy na 5.11.2026

1. Podaż niedużych, świeżych gier iOS o sejfach rośnie, ale **mała liczba ocen nie pozwala stwierdzić sukcesu sprzedażowego**. Nie liczyć z liczby nowych aplikacji wielkości rynku płacącego.
2. **Haptyka i dźwięk nie są wyróżnikiem same w sobie**: Unlokee, Vale & Daughter i aplikacje o sejfach już je reklamują. Siłą może być projektowanie *wielokanałowego* feedbacku od początku.
3. **„Pierwsza gra w ciemności” byłoby nieprawdziwe** (Vale & Daughter deklaruje Blind mode; istnieją gry audio-first). Także „jedyna gra zgodna z VoiceOver” nie jest uzasadnione bez audytów konkurentów.
4. W Google Play istnieje duży, ale głównie reklamowy segment puzzle-boxów. **5 mln+ instalacji The Vault nie znaczy 5 mln potencjalnych klientów premium**.
5. Cena odblokowania wśród najbliższych mobilnych przykładów to **4,99 USD** (Vale) i **7,99 USD** (Unlokee); kwoty w segmencie premium cozy wykraczają poza ten zakres. Nie deklarować przychodów bez testu konwersji.

## 4. Luki rynkowe, które Lockwright zajmuje

**Warunek:** poniżej chodzi o możliwe **pozycjonowanie i plan produktu**, a nie obiektywnie dowiedzioną wyłączność funkcji na świecie.

1. **Legalne pogotowie zamkowe zamiast włamania.** Gracz odpowiada na zgłoszenie zatrzaśniętych drzwi, ustala uprawnienie do lokalu (dokument, sąsiad, zarządca), a **odmowa jest poprawnym rozwiązaniem**. To rzadki, sensowny konflikt moralny bez przestępczej estetyki.
2. **Pełna dostępność całej usługi bez wzroku.** Sterowanie oboma kciukami + niezależne dźwięki i haptyka; dostępne także menu, podkładka klienta, weryfikacja, napisy i wyniki przez **VoiceOver/TalkBack**. Test z prawdziwymi niewidomymi graczami **musi potwierdzić** całkowitą przechodzalność. Sam ekran w ciemności nie wystarczy.
3. **Fotorealizm informacyjny i UI osadzone w świecie.** Wymyślone, bezmarkowe mechanizmy z materiałami przypominającymi metal, skórzana zwijka jako HUD, praca w kamienicy; bez pływających liczników, paska wytrzymałości i klisz złodzieja. Każdy stan rozpoznawalny po kształcie/ruchu, dźwięku i wibracji (DESIGN/HUD).
4. **Cozy job sim w mikroskali premium.** Małe, dające się ukończyć zlecenia, rytm pracy i warsztat, historie klientów, opanowanie fachu. Krótkie sesje mobilne bez pay-to-win, reklam i energii.
5. **Jeden mechanizm, wiele stopni mistrzostwa.** Faktyczne zachowanie sygnałów `binding`, `near_shear`, `set`, `false_set`, `overset`, `counter_rotate` w **wymyślonym** układzie, bez instrukcji do istniejących produktów.

### 4.1 Minimalny plan dowodu przewagi (nie hasło reklamowe)

- **Prototyp A/B rdzenia:** sprawdzić, czy gracze rozróżniają `set` i `false_set` oraz `stress` i `break` bez obrazu, wyłącznie dźwiękiem, oraz tylko obrazem. Nagrywać błędy, nie tylko satysfakcję.
- **Dwa urządzenia Android i iPhone:** zweryfikować rytm wibracji przy różnej jakości aktuatorów; brak haptyki nie może blokować postępu.
- **Test VoiceOver i TalkBack:** od startu po raport końcowy bez zaglądania na ekran; z niewidomymi użytkownikami, nie wyłącznie testerem w opasce.
- **Test etyki zleceń:** objaśnienie weryfikacji prawa do lokalu powinno poprzedzać pierwszy mechanizm; odmowa nie może być „przegraną”.
- **Monetyzacja:** wspólny pobieralny starter, uczciwy permanentny zakup, Family Sharing gdy dostępne; test A/B opisu i progu cenowego, nie fikcyjny forecast przychodów.

## 5. Tytuł, kolizje, znaki towarowe, domeny

> **Ważne: screening, nie clearance.** Wymagane jest samodzielne sprawdzenie aktualnych zgłoszeń i klas w oficjalnych rejestrach i decyzja prawnika/rzecznika. Dane historyczne z `docs/RESEARCH.md` sprawdzono w nim **04.11.2026**; niektórych rejestrów ani RDAP **nie udało się odpytać ponownie 05.11.2026**. Nie należy tłumaczyć „brak wyniku w naszej próbie” jako „brak praw”.

### 5.1 Istniejące nazwy i podobieństwo

| Oznaczenie / miejsce | Znaczenie dla nazwy | Stan dowodu i źródło |
|---|---|---|
| **Lockwright — lockwright.app** | **Identyczna nazwa** gry przeglądarkowej 3D escape-room, również o mechanicznych zagadkach i pokojach. Wg researchu: 9 pokoi + trening, PWA, bezpłatna. Ryzyko pozycjonowania i pomyłek w wyszukiwaniu, nawet bez potwierdzonej rejestracji znaku. | Opis i daty z [bazowego researchu 04.11.2026](../../../../docs/RESEARCH.md), [domena](https://lockwright.app/). Dostępność strony **niepotwierdzona ponownie 05.11**. |
| **LockWright — usługi ślusarskie** | Tożsame fonetycznie i branżowo skojarzenie; zarezerwowany @LockWright na X; **usługa fizyczna ≠ automatycznie konflikt z grą**, ale domeny/SEO/ASO mogą się mieszać. | [X](https://x.com/LockWright), źródłowy wpis 04.11; dziś bez odrębnego potwierdzenia. |
| **LOCKWRITE** (US) | Podobieństwo wizualno-fonetyczne; w źródłach wtórnych figuruje znak dotyczący przedmiotów piśmienniczych (kl. 16), **nie potwierdza blokady gier**. | [Justia – LockWrite LLC](https://trademarks.justia.com/owners/lockwrite-llc-1501232), serial **77396378**; bieżący status i zgłoszenia trzeba sprawdzić w [USPTO](https://tmsearch.uspto.gov/). |
| **LOCKRIGHT** (US) | Podobne brzmienie; dawne zgłoszenie kredytów hipotecznych (kl. 36). Historycznie **porzucone 04.05.2001**, wg źródła wtórnego. | Serial **75358158**; [Justia – właściciel](https://trademarks.justia.com/owners/pnc-mortgage-corp-of-america-439156/); [status historyczny](https://www.trademarkia.com/docket-report/high-five-74543569) wymaga rozstrzygnięcia w USPTO dla właściwego numeru. |
| **Lockwright: Locksmith on Call** / **Lockwright: Emergency Locksmith** | **Sprzeczność wewnętrzna:** opis zlecenia posługuje się „Locksmith on Call”, `CLAUDE.md` używa „Emergency Locksmith”; przed ASO i filingiem ustalić jeden angielski podtytuł (mieszanie wariantów pogarsza wyszukiwanie). | [CLAUDE.md](../../../../CLAUDE.md), zlecenie T07 05.11. |

**Słowny screening rejestrów (sprawdzać również znaki podobne):** LOCKWRIGHT, LOCK WRIGHT, LOCKWRIGHTS, LOCKRIGHT, LOCKWRITE, LOKWRIGHT, warianty z łącznikiem i fonetyczne. Priorytet: **klasy nicejskie 9 (oprogramowanie/granie), 41 (usługi rozrywki); klasę 28 (gry/zabawki) ocenić osobno pod plan licencji/merch**. Uwzględnić znaki unijne i krajowe, Madrid (WIPO), US/UK/BE/PL, kolizje niezarejestrowane oraz podobieństwo kanałów sprzedaży.

| Rejestr | Aktualny stan dowodu na 05.11.2026 | Następny krok / oficjalny punkt wejścia |
|---|---|---|
| **USPTO (USA)** | Research repo **04.11** podał 0 dokładnych wpisów LOCKWRIGHT w ówczesnym zapytaniu API; **nie jest to wynik nowego pełnego wyszukania**. Wtórne bazy dokumentują LOCKWRITE i LOCKRIGHT. | [Trademark Search](https://tmsearch.uspto.gov/): dokładne/zbliżone formy, status **live/dead**, goods/services, serial/application date, klasy. |
| **EUIPO/TMview (UE)** | **Niezweryfikowane:** automatyczne wyszukiwanie było blokowane, nie odczytano wszystkich aktualnych zgłoszeń. | [EUIPO Search IP](https://www.euipo.europa.eu/en/search-ip) i [TMview](https://www.tmdn.org/tmview/): kl. 9, 28, 41, wszystkie podobne oznaczenia. |
| **WIPO (globalnie)** | **Niezweryfikowane** z powodu ograniczenia dostępu. | [Global Brand Database](https://branddb.wipo.int/): znaki międzynarodowe i krajowe, warianty. |
| **BOIP (Beneluks)** | **Niezweryfikowane osobno**, ważne dla Belgii/Beneluksu. | [BOIP Register](https://www.boip.int/en/trademarks-register): wyszukanie słowne i warianty. |
| **UKIPO (UK)** | **Niezweryfikowane osobno**, w tym ryzyko wcześniejszego używania usług LockWright. | [UK search for a trade mark](https://www.gov.uk/search-for-trademark). |
| **UPRP (Polska)** | **Niezweryfikowane:** aplikacja zewnętrzna wymaga ręcznego zapytania. | [e-Wyszukiwarka](https://ewyszukiwarka.pue.uprp.gov.pl/). |

**Koszt zgłoszenia EUTM:** oficjalny cennik EUIPO dla zgłoszenia online wynosi **850 EUR za pierwszą klasę, 50 EUR za drugą i 150 EUR za trzecią**, czyli **1 050 EUR** dla 9+28+41 przed wynagrodzeniem pełnomocnika i pozostałymi kosztami. [EUIPO – Fees & Payments](https://www.euipo.europa.eu/en/trade-marks/before-applying/fees-payments), sprawdzono 05.11.2026. **Nie rekomendować opłaty przed clearance.**

**Korekta wobec `docs/RESEARCH.md`:** oficjalna strona [EUIPO SME Fund 2026](https://www.euipo.europa.eu/en/sme-corner/sme-fund/2026) wskazuje, że **Voucher 2 (trade marks/designs) nie przyjmuje nowych wniosków, bo środki się wyczerpały** (odczyt 05.11). Nie zakładać refundacji 2026 bez ponownej aktualnej kontroli.

### 5.2 Domeny i konta — migawka źródłowa, a nie dzisiejsza dostępność

| Adres / uchwyt | Stan według `docs/RESEARCH.md` **04.11.2026** | Pewność na 05.11 i działanie |
|---|---|---|
| [lockwright.app](https://lockwright.app/) | **Zajęta; aktywna gra o tej samej nazwie** (RDAP rejestracja 09.10.2026) | Kluczowa kolizja; potrzebne otwarcie strony w przeglądarce i archiwizacja stanu |
| [lockwright.com](https://lockwright.com/) | **Zajęta** (RDAP rejestracja 22.01.2026; szablon strony) | Nie zakładać wolnej domeny; zbadać WHOIS i ewentualną ofertę przejęcia |
| lockwright.game | Wolna wg RDAP 04.11 | **Niepotwierdzone 05.11**; sprawdzić registrar/registry przed zakupem |
| lockwright.games | **Nieustalone**, 429 przy RDAP | Sprawdzić w rejestratorze |
| lockwright.pl / lockwright.be | Wolne wg RDAP/API 04.11 | **Niepotwierdzone 05.11**; sprawdzić tuż przed rejestracją |
| lockwright.eu | **Nieustalone** | Potwierdzić przez EURid/rejestratora |
| lockwrightgame.com / playlockwright.com | Wolne wg RDAP 04.11 | **Niepotwierdzone 05.11**; po clearance rozważyć zakup |
| lockwright.net / lockwright.io | Wolne wg RDAP 04.11 | **Niepotwierdzone 05.11** |
| X @lockwright | Zajęte przez firmę ślusarską | Zweryfikować nazwę, kontakt i klasę działalności przed strategią znaku |
| TikTok @lockwright / YouTube @lockwright | Zajęte wg 04.11 | Sprawdzić ręcznie; nazwy kont nie są znakami z rejestru |
| X/TikTok/YouTube @lockwrightgame | Według 04.11 dostępne | **Niepotwierdzone dziś**; sprawdzić i ewentualnie zabezpieczyć |
| Instagram @lockwright / @lockwrightgame | Nieustalone (ograniczenia serwisu) | Sprawdzić w zalogowanej aplikacji |

Dane RDAP/stanów z 04.11: [RDAP lookup .com/.app](https://rdap.org/domain/lockwright.app), [RDAP .com](https://rdap.org/domain/lockwright.com), [NASK](https://rdap.dns.pl/domain/lockwright.pl), [DNS Belgium](https://api.dnsbelgium.be/whois/registration/lockwright.be) oraz [`docs/RESEARCH.md`](../../../../docs/RESEARCH.md). Brak ponownego odczytu 05.11 nie pozwala gwarantować dostępności nawet przez 24 godziny.

### 5.3 Ocena ryzyka i decyzja

- **ASO/SEO/rozpoznawalność: WYSOKIE ryzyko.** Identyczny tytuł w pokrewnej grze internetowej (`lockwright.app`) oraz zajęta nazwa .com i konta mogą dzielić ruch, mylić graczy i utrudnić prasę.
- **Prawne: NIEUSTALONE (istotne, wymaga pilnego clearance).** Brak potwierdzonej rejestracji we wcześniejszym zapytaniu USPTO **nie** usuwa wcześniejszych praw i nie rozstrzyga UE/UK/Beneluksu. Nie nadawać liczbowej oceny ryzyka prawnego bez aktualnego przeszukania i analizy używania znaków.
- **Rekomendacja przed zapowiedzią:** uruchomić równolegle (a) pełny screening rzecznik/prawnik + dowody pierwszeństwa używania istniejącej gry; (b) **3–5 alternatywnych roboczych nazw** z wolną domeną i kontami. Decyzję, czy pozostać przy Lockwright, podjąć przed płatnymi materiałami marketingowymi. Sama dopisana część tytułu **nie musi** usuwać podobieństwa znaków.
- **Nie robić jeszcze:** płatnego EUTM/USPTO zgłoszenia, zakupu dużego pakietu domen, obiecywania „pierwszego blind mode” ani importu grafik/UI konkurentów przed weryfikacją.

## 6. Mapa źródeł i ograniczenia

- **Sklepy gier** (daty odczytu 05.11.2026, z wyjątkami wskazanymi w CSV): każdy tytuł w tabeli §2 jest linkiem do odpowiedniej karty Apple App Store, Google Play, Steam albo itch.io; dodatkowy link oznaczony [2] łączy drugą platformę. Szczegółowe adresy i indywidualne daty są w CSV.
- **Materiały repo** (odczyt 05.11.2026): [`CLAUDE.md`](../../../../CLAUDE.md), [`docs/RESEARCH.md`](../../../../docs/RESEARCH.md) (treść 04.11), [`docs/DESIGN.md`](../../../../docs/DESIGN.md), [`docs/HUD.md`](../../../../docs/HUD.md), [`docs/styles/realizm.md`](../../../../docs/styles/realizm.md).
- **IP i domeny** (daty wskazane w §5): EUIPO [fees](https://www.euipo.europa.eu/en/trade-marks/before-applying/fees-payments), [SME Fund 2026](https://www.euipo.europa.eu/en/sme-corner/sme-fund/2026), [Search IP](https://www.euipo.europa.eu/en/search-ip), [USPTO](https://tmsearch.uspto.gov/), [WIPO](https://branddb.wipo.int/), [TMview](https://www.tmdn.org/tmview/), [BOIP](https://www.boip.int/en/trademarks-register), [UKIPO](https://www.gov.uk/search-for-trademark), [UPRP](https://ewyszukiwarka.pue.uprp.gov.pl/). Źródła domen i social zob. §5.2.
- **Bez audytu sprzętowego:** nie instalowano ani nie testowano aplikacji, VoiceOver/TalkBack, urządzeń dotykowych. „Brak deklaracji” oznacza wyłącznie brak potwierdzenia w analizowanych źródłach.
- **Bez gwarancji kompletności rejestrów:** automatyczny dostęp do TMview/WIPO/UPRP/BOIP i bieżącego RDAP/mediów społecznościowych był niepełny; **nie znaleziono dowodu aktualnych zgłoszeń** to nie to samo co **potwierdzono brak zgłoszeń**.

**Priorytet na następny dzień pracy:** prawnicza weryfikacja nazwy > dostępność pełnej pętli bez obrazu w prototypie > test premium z pierwszym rozdziałem.
