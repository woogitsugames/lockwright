# T08 — Plan playtestów Android / Android playtest plan

Wersja 1.0 · 2026-11-05 · status: protokół do wykonania, **nie wyniki testów**. Właściciel przekazuje APK znajomym; moderator może być osobą bez przygotowania UX. Gra: Lockwright: Pogotowie Zamkowe / Lockwright: Locksmith on Call.

## 0. Instrukcja na jednej stronie / Quick start

1. Zdobądź APK z oznaczeniem buildu, telefon z Androidem, ładowarkę, spokojne pomieszczenie i dwie kopie: arkusz obserwacji i właściwą ankietę PL/EN. **Nie proś o imię, e-mail, numer telefonu ani dane medyczne**.
2. Wybierz ścieżkę A (pierwsze uruchomienie, A1/A2 i stany) albo B (trudność, decyzje, ekonomia), zgodnie z harmonogramem poniżej. Każdy tester ma **30 minut** i anonimowy kod losowy, np. T08-017; nie prowadź tabeli kod → osoba.
3. Wgraj ten sam build, ustaw język PL albo EN, ustaw jasność i dźwięk; przy A użyj świeżego profilu i nie pokazuj zasad gry.
4. Przeczytaj dosłownie skrypt z §5, nie ucz gestów, obserwuj i zapisuj zdarzenia kodami z observation_sheet.md.
5. Wypełnij ankietę na tym samym urządzeniu lub udostępnij formularz bez logowania. Pytania mają te same identyfikatory Q01–Q20 w PL i EN. Pola niedotyczące danej ścieżki oznacz „N/D”.
6. Po każdej partii wpisz wyłącznie zanonimizowane odpowiedzi i pomiary do zbiorczej tabeli; zastosuj §10, nie podejmuj decyzji z jednego komentarza.

**Bezpieczna granica:** testujemy wyłącznie wymyślone mechanizmy w grze. Nie demonstruj realnych zamków, nie podawaj instrukcji otwierania rzeczywistych zabezpieczeń. Nie odtwarzaj numerów mieszkań lub danych prawdziwych klientów.

## 1. Co dokładnie mierzymy

| Obszar | Zadanie i miernik | Kryterium / status |
|---|---|---|
| Pierwsze uruchomienie i S1–S3 | sekundy do pierwszego dotyku S1; czas każdego kroku; maksymalne H0–H4; ukończenie 3 etapów | cel startu ≤25 s; cel mediany S1–S3 ≤3 min; wskaźniki diagnostyczne |
| **A1**: nauka sterowania bez tekstowych instrukcji w zamku | nowicjusz: pin.s1–s3, potem pin.a1 bez wskazówek H1–H4; czas od pierwszego dotyku do open | **mediana <90 s oraz ≥75% otwarć w <90 s; minimum 12 ważnych osób** |
| **A2**: gra bez obrazu | ci sami nowicjusze, pin.a2 z czarną nakładką, dźwięk i haptyka; czas od pierwszego dotyku | **≥60% otwiera w <180 s** |
| **A7**: stany bez koloru | rozpoznanie 8 stanów z niezależnych ujęć przy 50% jasności w skali szarości, bez audio i drgań; osobno wariant bez kredy i „Pomoc w czytaniu” | **≥90% poprawnych odpowiedzi dla każdego stanu i wariantu**, ≥8 testerów na wariant |
| **A9**: alternatywa dla haptyki | ukończenie S1, S2 i S3 z wyłączoną haptyką, obraz+dźwięk; próby z pomocą w czytaniu i bez | **wszystkie 3 poziomy możliwe do ukończenia**; raportuj użycie H4, nie ukrywaj barier |
| Haptyka | wynik kalibracji dwa/jedno/nic; rozpoznanie set vs false_set; subiektywna pomoc Q13; różnica po wyłączeniu | kierunkowe, **nie** formalny dowód skuteczności bez grupy kontrolnej |
| Trudność t1–t7 | ukończenie, czas, overset, drop, stress, break, H4, trudność Q14–Q15; rozdzielaj rodzinę i tier | diagnostyczne, bez gotowego progu zaliczenia; porównuj wewnątrz rodzin |
| Ekonomia | zrozumiałość rachunku i nagród, możliwości zakupu, napraw, skutki odmowy, blokady; Q16–Q17 | jakościowe w 30 min; **nie** deklaruj zrównoważenia całej kariery |
| Ton i legalność | scena sprawdzenia uprawnienia do lokalu i odmowy; Q19–Q20, wybór i uzasadnienie | P0: brak akcji otwierania bez weryfikacji, jeśli scenariusz jej wymaga |

**Granica zakresu:** Androidowy playtest nie dowodzi progów A4/A5/A6/A8 ani pełnej zgodności iOS. Wyniki symulacji botów z BALANCE.md nie są wynikami ludzi. Obecne docs/ECONOMY.md opisuje wykryte blokady i grind; test nie może uznać ich za naprawione.

## 2. Liczebność i profile, bez danych identyfikacyjnych

- **Pilotaż:** 3 dorosłe osoby spoza próby głównej; sprawdź formularz, nagrania i przełączniki. Nie wliczaj pilotażu do A1–A9.
- **Ścieżka A:** cel 16 nowicjuszy na Androidzie, co najmniej 12 ważnych pomiarów. Nowicjusz: nigdy nie otwierał wytrychem fizycznego zamka, nie korzystał z poradników na ten temat i przez ostatni rok grał w mechaniki otwierania zamków <1 h. W miarę możliwości: 4 osoby grające na telefonie <1 h/tydzień, 4 osoby 50+, 2 osoby leworęczne, około połowa PL i połowa EN. Bez rejestrowania wieku dokładnego, płci, adresu i diagnoz.
- **Dostępność / A9:** dodatkowe 4–6 sesji, w tym ≥2 osoby, które na co dzień potrzebują powiększenia lub mocniejszego kontrastu, ≥2 z haptyką wyłączoną oraz osoby rzadko grające. Rekrutuj przez opis potrzeb interfejsu, nie pytaj o chorobę ani nie przechowuj statusu niepełnosprawności. Jeśli ktoś z tej grupy spełnia A1, wynik dostępności analizuj oddzielnie od standaryzowanej próby A1.
- **Ścieżka B:** na początek 14 dodatkowych sesji (2 zadania tierowe/osobę = 28 prób, po 4 na tier), dobór graczy o różnym doświadczeniu; osoby na t6–t7 muszą znać gesty po krótkiej rozgrzewce. Cztery próby/tier to tylko wykrywanie dużych problemów; przed decyzją o balansie zwiększ próbę (docelowo ≥10 prób/tier/rodzinę).
- Tester może przerwać w dowolnym momencie. Nie wymuszaj odpowiedzi ani gry w ciemności u osoby, dla której jest to niedostępne; oznacz „nie badano” zamiast „porażka”.

## 3. Przygotowanie APK i urządzenia: checklista przed każdym testem

| Sprawdzenie | Jak sprawdzić / zapis w arkuszu |
|---|---|
| Identyczność | wersja APK/build, data i wersja zasad zamka (rules_version); stabilny seed zadania; żadne debugowe ułatwienie przypadkiem aktywne |
| Gotowość zadań | na ścieżkę A dostępne pin.s1, s2, s3, **pin.a1** (3 stosy, seed 1, bez H1–H4) i **pin.a2** (t2, seed 2, czarny ekran); na B selektor tieru/rodziny lub przygotowane zapisy |
| Jasność i dźwięk | jasność 70% (auto wyłączona), orientacja pion, dźwięk ok. 60% systemowego przy bezpiecznej głośności; brak słuchawek na bazowej ścieżce A; wyłącz powiadomienia i oszczędzanie energii |
| Haptyka | Android H0/brak drgań albo zgodny telefon z prymitywami — zapisz wyłącznie klasę i wynik kalibracji, **nie numer seryjny/IMEI** |
| Dostępność | sprawdź działanie przełączników „Pomoc w czytaniu”, kreda, kontrast, napisy, zamiana kciuków, blokada napięcia, szersze okna, Reduce Motion, TalkBack; zapisz tylko włączone opcje |
| Zgoda | ustna dobrowolna na udział; **nagrywanie wyłącznie po osobnej świadomej zgodzie**, domyślnie wyłączone. Wariant bez nagrania musi być pełnoprawny |
| Dane | wyłącz analitykę reklamową, automatyczne wysyłanie identyfikatorów i chmurę w wersji testowej; logi/replay zbieraj lokalnie pod losowym kodem, bez łączenia z osobą |
| Test formularza | przetestuj link/QR bez wymogu konta; sprawdź, czy usługa nie udostępnia moderatorowi e-maili/IP, nie wymusza logowania i nie pozwala przesłać nazwisk w tekście |

**Jeśli APK nie ma selektora zadań i powtarzalnych seedów**, nie udawaj testu A2/A7/t1–t7. Można zrobić próbę użyteczności, a brakujące pomiary oznaczyć „blokada techniczna”. Wymagane flagi przekaż zespołowi implementacji; nie modyfikuj cudzych katalogów.

## 4. Harmonogram ścieżek — dokładnie 30 minut

### A. Pierwszy kontakt, nowicjusze (A1, A2, A7; 00:00–30:00)

| Minuty | Co robi moderator i tester | Co zapisujesz |
|---|---|---|
| 00:00–02:00 | skrypt zgody; losowy kod; telefon na stole, bez tłumaczenia mechaniki | kod, build, język, klasa Android/haptyki |
| 02:00–10:00 | pierwsze uruchomienie, kalibracja, pin.s1–s3; moderator milczy; H1–H4 działają normalnie | do pierwszego dotyku, S1/S2/S3, H0–H4, przypadki utknięcia |
| 10:00–15:00 | pin.a1 z pomocą H wyłączoną; limit 300 s | sukces? czas open; drop/overset/stress/break; limit |
| 15:00–16:00 | odpoczynek; **bez rozmowy o zasadach** | przerwy techniczne |
| 16:00–21:00 | pin.a2 z czarną nakładką i zapowiedzią z §5; limit 300 s | sukces? <180 s?; kanały dźwięk/haptyka |
| 21:00–24:00 | A7: 8 szarych statycznych zrzutów, losowa kolejność, jedna odp. na stan; przypomnienie legendy | liczba trafień na KAŻDY stan, wariant z/bez kredy |
| 24:00–28:00 | ankieta Q01–Q20, „N/D” tam gdzie brak ekspozycji | odpowiedzi, brak wymuszonych pól |
| 28:00–30:00 | dwa pytania retrospektywne: „Po czym poznał(a) Pan/Pani postęp?”; „Co było niejasne?” | skrót bez dosłownych cytatów z danymi o osobie |

**Jeśli samouczek nie kończy się do 10:00, nie przeskakuj sztucznie do pin.a1.** Zapisz „A1/A2 niebadane — nieukończony tutorial”, pozostały czas poświęć obserwacji i ankiecie. A1 z brakiem dostępu nie jest sukcesem ani automatycznie porażką; osobno policz odsetek nieukończonych tutoriali. Przy A1 i A2 pomiary 90/180 s są wewnątrz 300 s limitu. W ścieżce A nie stosuj myślenia na głos podczas gry (zmienia czas).

### B. Trudność, ekonomia, legalność (00:00–30:00)

| Minuty | Czynność | Zapis |
|---|---|---|
| 00:00–02:00 | zgoda i kod | build, profil próby |
| 02:00–06:00 | krótkie, jednakowe przypomnienie sterowania na zadaniu ćwiczebnym, nie licz do pomiarów | czy tester rozumie sterowanie |
| 06:00–15:00 | **dwa przypisane** zamki tierowe, do 4 min każdy; bez pomocy moderatora, standardowe wskazówki gry; 1 min przejścia | tier, rodzina, seed, czasy i błędy |
| 15:00–21:00 | karta zlecenia: wariant „dokument/sąsiad/zarządca” i wariant „brak potwierdzenia”; wybór „pytam o dokumenty / odmawiam”; rachunek, naprawa, zakup, nagroda po zadaniu (tylko jeśli build ma te ekrany) | czy odmówił bez uprawnienia, czy zrozumiał bilans; blokady ekonomiczne |
| 21:00–25:00 | krótka próba z haptyką wyłączoną (w osobnej próbie A9: cały S1–S3, zamiast zadań tierowych) | czy obraz i dźwięk wystarczają; jakie opcje |
| 25:00–29:00 | ankieta Q01–Q20 | N/D przy elementach nieobecnych |
| 29:00–30:00 | jeden komentarz i zakończenie | kod kategorii problemu |

Przy braku zleceń/rachunku/sklepu nie pokazuj fikcyjnych wyników jako realnych zachowań; można przedstawić **wyraźnie oznaczoną makietę** w celach jakościowych i zanotować „prototyp, bez transakcji”.

### Rozkład 14 par dla t1–t7 (każdy tier występuje 4 razy)

| Testerzy B | Zadanie 1 | Zadanie 2 |
|---|---|---|
| B01–B02 | t1 wafer | t4 pin_tumbler |
| B03–B04 | t2 pin_tumbler | t5 pin_tumbler |
| B05–B06 | t3 pin_tumbler | t6 pin_tumbler |
| B07–B08 | t4 pin_tumbler | t7 pin_tumbler |
| B09–B10 | t5 pin_tumbler | t1 wafer |
| B11–B12 | t6 pin_tumbler | t2 pin_tumbler |
| B13–B14 | t7 pin_tumbler | t3 pin_tumbler |

Dla porównywalności trzymaj po jednym ustalonym seedzie na tier i build, zamień kolejność wewnątrz połowy par, zapisuj kolejność (uczenie/zmęczenie). **Uwaga:** lockcore/BALANCE.md ma pin_tumbler dopiero od t2, natomiast t1 występuje m.in. we wkładce płytkowej (wafer). Dlatego t1/wafer **nie jest bezpośrednim punktem na krzywej pin_tumbler t2–t7**. Każdą rodzinę porównuj osobno. Nie podstawiaj czasów botów za czasy testerów.

### C. Dostępność (osobne 30 min)

02:00–05:00 wybór potrzebnych opcji (bez pytań o diagnozę); 05:00–20:00 pin.s1–s3 **z wyłączoną haptyką** (najpierw ustawienia domyślne, następnie na życzenie „Pomoc w czytaniu” i inne pomoce); 20:00–25:00 próby rozpoznawania stanów w skali szarości; 25:00–29:00 ankieta; 29:00–30:00 koniec. Jeśli instrukcja głosowa TalkBack jest potrzebna, dopuszczaj ją i oznacz opcję. Dla A9 zapisz sukces każdego S1–S3, H4 oraz to, czy gracz potrzebował opcji. Nie zestawiaj tych czasów wprost z A1 bez rozdzielenia warunków.

## 5. Dosłowne skrypty / Read aloud

**Początek PL:** „To gra o ślusarzu, który pomaga ludziom zgodnie z zasadami. Proszę po prostu grać. Nie będę podpowiadać, jak używać narzędzi. Można przerwać w każdej chwili. Nie zbieramy nazwiska ani kontaktu. Czy chce Pan/Pani wziąć udział?”

**Start EN:** “This is a game about a locksmith helping people within the rules. Please just play. I won't explain how to use the tools. You can stop at any time. We won't collect your name or contact details. Would you like to take part?”

**Pytanie o nagranie PL / EN (tylko jeśli planowane):** „Czy osobno zgadza się Pan/Pani na nagranie samego ekranu i dłoni? Odmowa nic nie zmienia.” / “Separately, may we record only the game screen and your hands? Saying no changes nothing.”

**Gdy tester prosi o podpowiedź PL / EN:** „Proszę spróbować dalej.” / “Please keep trying.”

**Przed A2 PL / EN:** „Teraz ekran będzie czarny. Zamek działa tak samo.” / “The screen will now be black. The lock works the same way.”

**Po zadaniach PL / EN:** „Po czym poznał(a) Pan/Pani, że coś się udało albo że trzeba spróbować inaczej?” / “How did you tell that something worked, or that you needed to try differently?”

**Dla sceny legalnej PL / EN:** „Proszę podjąć taką decyzję, jaką podjąłby bohater gry. Nie ma obowiązku otwarcia drzwi.” / “Please make the decision the character should make. You don't have to open the door.”

## 6. A7 — procedura bez koloru, nie zgadywanie po kolorze

1. Przygotuj w tym samym buildzie po **dwa różne obrazy** każdego stanu: swobodny, binding, near_shear, set, false_set, counter_rotate, overset, stress. Jedne jako podpisany wzorzec do poznania znaczenia, drugie z innym seedem jako pytanie. Wyłącz audio/haptykę podczas A7. Nie pokazuj „break” zamiast „stress”.
2. Testuj na ekranie telefonu lub na jednolitym nośniku: szarość, 50% jasności; żadnych kolorowych etykiet. Obraz ma pokazywać geometrię, ruch reprezentuj dwoma kadrami lub krótką bezdźwięczną animacją, bo statyczny kadr nie oddaje counter_rotate. Zastosuj tę samą metodę dla obu wariantów.
3. Rozdziel 16 uczestników A na dwie grupy 8: **A7-0 bez kredy** i **A7-1 pełna pomoc w czytaniu**. W obu: jedna odpowiedź na każdy z 8 stanów, bez podpowiedzi. Jeśli prototyp nie ma 8 rozróżnialnych stanów, oznacz „niebadane”, nie licz 100%.
4. Pokaż legendę: nazwy stanów i krótkie neutralne opisy, bez wskazywania rozwiązania obrazka. Zapisz kategorię wybraną na każde pytanie, nie tylko sumę. Pomyłki set ↔ false_set, set ↔ overset i stress ↔ binding traktuj priorytetowo.
5. **Próg A7 liczymy osobno dla każdego stanu**: trafienia / ważne odpowiedzi ≥0,90. Przy n=8 oznacza to 8/8; w próbie tak małej pojedynczy błąd daje 87,5%, więc wynik graniczny wymaga ponownego testu na większej próbie.

## 7. Co obserwować (bez instruowania gracza)

- **Sterowanie**: kciuk L trzyma T w paśmie czy co chwilę odrywa? P szuka elementu czy bez celu „machnie”? Czy tablet/duży telefon zasłania linię podziału? Zwróć uwagę na zamianę kciuków i blokadę napięcia.
- **Samouczek**: najdłuższy krok; czy H1 po 15 s, H2 po 30, H3 po 45, H4 po 60 rzeczywiście następują; czy H4 nie wykonuje pracy zamiast gracza w A1 (musi być wyłączone).
- **Sygnały**: czy tester zauważa przechył binding, szczelinę near_shear, „stopkę” set, talię i podwójny klik false_set, ściśniętą sprężynę overset, odgięcie stress; czy umie nazwać przyczynę bez wskazywania koloru.
- **Kanały**: gdy kalibracja „nic”, nie zakładaj, że haptyka zadziałała; jeśli z dźwiękiem wyciszonym tester trafia w ścianę, zanotuj jako osobną próbę, nie jako A1.
- **Ekonomia**: czy wie, że w serii są 3 zapasowe wytrychy w skórzanej zwijce, a nie pasek życia; rozumie rachunek i koszt naprawy; musi grać dodatkowe sesje, aby w ogóle przyjąć zlecenie; czy rozpoznaje opcję odmowy.
- **Ton**: czy dialog o dowodzie lokalu wygląda jak pomoc klientowi, czy jak zachęta do wejścia bez zgody. Zanotuj **działanie**, nie ocenę domniemanego charakteru testera.

Kody obserwacji: STUCK (bez postępu ≥15 s), WRONG_TENSION, LOST_PICK, MISREAD_STATE, FALSE_SUCCESS, HAPTIC_NONE, ACCESS_BLOCK, UI_TOUCH, ECON_LOCK, ECON_CONFUSION, LEGAL_SKIP, LEGAL_REFUSE, TONE_COLD, CRASH, OTHER. Przy każdym podaj zadanie, minutę, skutek, wariant i kod problemu — bez nazwiska lub dosłownych rozmów.

## 8. Formularz i minimalne dane

Załóż formularz PL i EN z tymi samymi polami Q01–Q20 i wartościami kodowymi. Wyłącz „zbieraj adresy e-mail”, logowanie, jedną odpowiedź na konto, geolokalizację, analitykę marketingową i zbędne metadane. Nie dodawaj pól imię, płeć, adres, dokładny wiek, zawód, diagnoza, zdjęcie, telefon ani nieograniczonego pola tekstowego. Pytania opcjonalne; N/D przy braku ekspozycji. W formularzu **nie umieszczaj kodu testera**, jeśli ankieta ma być w pełni niezwiązana z obserwacjami. Jeśli badanie wymaga sparowania ankiety z czasami, użyj losowego kodu bez klucza do osoby i traktuj dane jako **pseudonimowe, a nie gwarantowanie anonimowe**.

Tabela pomiarów (1 wiersz na próbę): session_code, track, build, rules_version, locale, device_haptics_class, accessibility_flags, task_id, family, tier, seed, order, started_at_relative_s, duration_s, opened_0_1, right_censored_0_1, hint_max_H0_H4, calibration_2_1_0_skip, drop_n, overset_n, stress_n, break_n, refusal_0_1_NA, notes_codes. Czas zapisuj względem startu sesji, **bez daty urodzenia, IP, identyfikatora reklamowego, numeru telefonu, lokalizacji GPS lub nazwiska**. Odpowiedzi ankiety agreguj osobno albo według losowego kodu.

Nagrania nie są konieczne. Gdy naprawdę potrzebne: osobna zgoda, tylko ekran i dłonie (bez twarzy, głosu i powiadomień), lokalny zapis, minimalny dostęp, usunięcie po kodowaniu wyników, np. po 14 dniach. Nagranie głosu lub twarzy wymaga osobnej, wyraźnej decyzji organizatora i informacji o przetwarzaniu danych; nie zakładaj, że anonimowość obejmuje wideo. Zgodność z RODO wymaga ustalenia administratora, celu, podstawy i terminu retencji **przed** testem, jeśli jakiekolwiek dane osobowe powstaną.

## 9. Wklej do arkusza — obliczenia

Przygotuj tabelę w Excel/Sheets lub CSV. Oddziel ścieżki i wersje APK; nie łącz prób z różnych buildów w jedną statystykę zaliczeniową.

| Wskaźnik | Sposób policzenia | Przykład N=16 |
|---|---|---|
| A1_success90 | liczba open=1 i duration_s <90 / wszystkie ważne próby A1 (także nieudane) | 12/16 =75%; próg odsetka spełniony |
| A1_median | mediana czasu do open uwzględniająca prawostronne cenzurowanie przy 300 s; gdy nieoszacowalna, kryterium niezaliczone | samych sukcesów **nie** używaj do zaniżania mediany |
| A2_success180 | liczba open=1 i duration_s <180 / wszystkie ważne próby A2 | 10/16 =62,5%; próg spełniony |
| A7_state_variant | dla każdego z 8 stanów oraz wariantu: correct / valid | 7/8=87,5% — poniżej progu, 8/8=100% |
| A9_levels | dla każdej osoby przy haptics_off: S1/S2/S3 completed, H4 i ustawienia | wszystkie poziomy muszą być możliwe do ukończenia |
| Trudność | % ukończeń w 240 s, mediana tylko z poprawnym oznaczeniem cenzurowania, zdarzenia/zamek | porównuj tier po tierze i w tej samej rodzinie |
| Q04–Q20 | rozkład 1–5, mediana, % 4–5, liczba N/D, osobno PL/EN i ścieżki | bez sztucznej „średniej z N/D” |
| Frustracja | problemy STUCK i MISREAD_STATE / liczba ważnych prób zadania | wybierz 2–3 najczęstsze miejsca |

Do progów A1/A2 raportuj **przedział Wilsona 95%** dla odsetka: przy małym N próg liczbowy może być osiągnięty, ale niepewność pozostaje duża. Dla czasów cenzurowanych do 300 s użyj Kaplan–Meier lub napisz uczciwie „mediana nieoszacowalna”; nie wpisuj 300 s jako czasu otwarcia. Zestawienie PL vs EN, lewo-/praworęcznych czy klas urządzeń wyłącznie opisowo do czasu zwiększenia próby.

## 10. Przepis na decyzję po sesjach (najpierw błąd, potem poprawka)

1. **Sprawdź ważność:** poprawny build, flagi, seed, warunki, brak instrukcji od moderatora. Niekompletne sesje oznacz; nie wyrzucaj porażek tylko dlatego, że są słabe.
2. **Bramki:** A1: mediana <90 s i ≥75% <90 s, A2: ≥60% <180 s, A7: ≥90% w **każdym** stanie, A9: ukończenie wszystkich S1–S3 bez haptyki. Raportuj liczniki, N i niepewność, nie tylko „PASS”.
3. **Priorytet P0:** brak weryfikacji uprawnienia przed otwarciem w scenie z klientem, instrukcja niebezpiecznego zachowania w świecie rzeczywistym, niedostępna pauza lub trwale zablokowana droga dla korzystających z alternatywnych kanałów. Zablokuj wydanie wersji z P0, nawet jeśli średnia ankiety jest wysoka.
4. **Priorytet P1:** niespełnienie A1/A2/A7/A9. Powiąż z logami: najdłuższy krok S1–S3 i H3/H4 → popraw jedną wskazówkę; set/false_set mylone → zmień rytm/obrys; A2 słabe przy A1 dobrym → popraw dźwięk i sygnały ciemności, nie dokładaj tekstowego HUD-u.
5. **Priorytet P2 (eksploracyjne):** ≥25% odpowiedzi 1–2 na Q04, Q05, Q14, Q19 lub Q20; problem powtórzony u ≥3 osób; blokada zakupowa występująca w danych. Te progi to **lokalne sygnały do diagnozy**, nie kryteria z DESIGN.md.
6. **Ekonomia — warunek wstępny:** najpierw rozpatrz znane rozbieżności z ECONOMY.md (błędne family, wzór 0,55 vs tabela, próg after_t8, koszt naprawy 35%, niedostępne narzędzie pierwszego zlecenia). Dopiero potem oceniaj poczucie sprawiedliwości. Porównuj model A/B/C wyłącznie pod wyraźnym oznaczeniem, a nie jako już wdrożone zmiany.
7. **Decyzja:** dla każdej poprawki zapisz problem, dowód (licznik/N), proponowaną **jedną** zmianę, właściciela modułu, nową wersję buildu, termin ponownego testu. Pilot 5 **nowych** osób po zmianie, następnie powtórz właściwy test; nie poprawiaj definicji progów po poznaniu wyniku.

**Przykład decyzji:** A1 = 11/16 <90 s (68,75%) i mediana 98 s; w kroku S2 H4 wystąpiło u 9/16, a 7 osób puszczało lewy kciuk. Wynik A1: nie przeszedł; zmiana: w S2 wzmocnić demonstrację „trzymaj” na H2 (bez tekstu); ponowny pilot 5 osób, potem 16 nowych testerów. Nie zmieniaj jednocześnie pasma napięcia i ekonomii, bo utracisz interpretowalność.

## 11. Raport końcowy i warunki gotowości

Raport jednej strony: (1) build, Android i liczba ważnych sesji; (2) tabela A1/A2/A7/A9 z licznikami i statusem; (3) 3 najczęstsze bariery i dowody; (4) wyniki t1–t7 rozdzielone rodzinami, z zastrzeżeniem małej próby; (5) ekonomia oraz ton/legalność; (6) lista P0/P1/P2 i decyzja: TESTUJ PONOWNIE / POPRAW / AKCEPTUJ DANY OBSZAR.

Przed pierwszym playtestem potrzebujesz działającego APK, selektora zadań/seedów do trybu badawczego, dziennika zdarzeń bez identyfikatorów i ośmiu par wzorców A7. To **prerekwizyty**, a nie elementy stworzone w T08. T08 dostarcza plan i formularze, nie implementację gry ani rzeczywiste wyniki.

## 12. Podstawa i kolejność w razie konfliktu

- CLAUDE.md — język, bezpieczeństwo, faza projektu.
- docs/styles/realizm.md — wybrany fotorealizm i opcjonalna kreda.
- docs/DESIGN.md §§1,4 — kod stanów i progi A1–A9.
- docs/HUD.md — **nowszy** diegetyczny HUD (bez liczników/pasków w zamku), w szczególności §9 dostępność; zastępuje wcześniejszy schemat panelowy z DESIGN.md §2.
- docs/ONBOARDING.md §§2–5,12 — H0–H4, S1–S3, pin.a1 i pin.a2, standard A1/A2.
- lockcore/BALANCE.md v0.3 — bot feeling/clumsy; pin_tumbler ma t2–t7, wafer t1–t3.
- docs/ECONOMY.md — symulacja A/B/C i **propozycje**, których nie należy mylić z wdrożoną ekonomią.
- docs/PROGRESSION.md §7 — pierwsza rodzina to pinowa i obecna pula MVP; wcześniejsze akapity o rodzinach/krzywej mają udokumentowane niespójności.

W szczególności próg A1/A2 jest zdefiniowany do testu na co najmniej 12 nowicjuszach; plan Android-only nie udaje potwierdzenia iOS ani gotowej implementacji.
