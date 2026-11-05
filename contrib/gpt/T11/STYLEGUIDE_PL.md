# Lockwright — STYLEGUIDE PL

## Ton i świat gry

Ciepło, spokój, konkret, odrobina suchego humoru. Żadnego krzyku, marketingowych wykrzykników ani estetyki włamania. Gracz jest legalnym ślusarzem; przy zleceniach rozpoznaje uprawnienia, a odmowa jest życzliwa i stanowcza: „Tu nie otworzę. Mogę za to pomóc inaczej”. Nie oskarża klientów; wskazuje kontakt z lokatorem, zarządcą lub policją. Nie komentuje cudzych rzeczy zobaczonych po otwarciu. Nie przedstawiaj praktyki weryfikacji jako jednolitego obowiązku ustawowego. Wszystkie mechanizmy są wymyślone i bezmarkowe; nie podawaj instrukcji do rzeczywistych, nazwanych produktów.

## Głosy postaci (`docs/CLIENTS.md`)

| Postać | Głos i rekwizyty narracyjne |
|---|---|
| Ślusarz | krótkie zdania, cierpliwość, brak obietnic czasu i wyniku; prowadzi zeszyt z notatkami |
| Pani Halina | ciepło, „synku”, rosół, gościnność i stanowcze poczucie humoru |
| Pani Zosia | praktyczny świadek, troskliwa irytacja, blisko Haliny |
| Pan Stefan | gawędziarz, kiosk, przystanek i lekki dystans do siebie |
| Pan Roman | administrator rzeczowy, rozmowy przez domofon, lista lokatorów |
| Aspirant Lena Sowa | spokojna dzielnicowa, rzeczowość, żadnego tonu przesłuchania |
| Marta | ironiczna, ale serdeczna; kot Ziemniak |
| Zuzanna | szybka, ciekawa, lubi szczegóły i pytania |
| Pan Edek | dokładny portier, lista i pamięć do twarzy |
| Ola i pani Krystyna | Ola objaśnia, Krystyna mówi mało i celnie; ton rodzinny bez patosu |
| Pan Władysław | lakoniczny, z błyskiem, dawny nauczyciel mistrza Henryka |
| Dr Anna Rygiel | kuratorka, protokoły, trzy egzemplarze, formalna precyzja |
| Pani Jadwiga | pewna siebie, dopóki pamięć nie zawiedzie; bez farsy |

Dokładną obsadę linii `.line.N` i `.after.N` sprawdzaj w Załączniku B do `docs/CLIENTS.md`. Postacie zwracają się do ślusarza „pan”; warianty „pani” wymagają osobnych kluczy, gdy gra udostępni wybór postaci.

## Słownik terminologii

| Pojęcie / EN | Zalecany polski termin | Uwagi |
|---|---|---|
| locksmith | ślusarz, pogotowie zamkowe | nie „włamywacz” |
| lock / padlock | zamek / kłódka | rozróżniać przedmioty |
| pin / wafer / lever | kołek / płytka / dźwignia | nie „pin” w tekście gracza |
| core / shear line | rdzeń / linia podziału | konsekwentnie |
| tension wrench / pick | napinacz / wytrych | bez anglicyzmów |
| binding | element wiąże, opór | stan z `docs/DESIGN.md` |
| near shear | blisko linii podziału, klin szczeliny | nie „klin prześwitu” |
| set / false set | ustawienie / fałszywe ustawienie | nie sprowadzać do koloru |
| overset / drop | przepchnięcie / zrzut | rozróżniać zdarzenia |
| counter rotate | kontrrotacja | jedno określenie |
| detector | detektor | „zadziałanie”, „zresetowanie” |
| dark mode | tryb „w ciemności” | nie „tryb nocny” ani „tryb ciemny” |
| endless / jobs | tryb ciągły / tryb zleceń | „seria”, nie „bieg” |
| haptics / sound | haptyka / dźwięk | obraz i dźwięk też przekazują stan |
| tool roll / notebook / showcase | zwijka / zeszyt / gablota | słownictwo diegetyczne |
| credentials / evidence | potwierdzenie uprawnień, dokument, świadek | sam dokument nie przesądza o prawie |

Nazwiska historycznych wynalazców tylko w sprawdzonych notkach gabloty, nigdy jako współczesne marki lub nazwy rodzin zamków (`docs/DECISIONS.md`, D-08).

## Ortografia i typografia

Używaj polskich cudzysłowów „…”; dla cytatu wewnątrz cytatu — »…«. Wtrącenia oddzielaj półpauzą (–) ze spacjami, a dywiz (-) zostaw w złożeniach („XIX-wieczny”). Wielokropek: „…”. Po jednoliterowych spójnikach i przyimkach **a, i, o, u, w, z** wstawiaj spację nierozdzielającą U+00A0. Zachowaj polskie znaki w imionach i nazwach własnych. W zdaniach pisz „tryb ciągły”, a nie „Tryb Ciągły”, chyba że cytujesz nazwę ekranu. Godziny „o 9:30”, daty „w 1888 roku”. Obce wtrącenia zostają wyłącznie jako cecha konkretnego mówcy.

Zmienna `{n}` nie daje poprawnej odmiany `monet` dla wszystkich wartości. Preferuj „Zdobyte monety: {n}” albo implementację odmiany liczebników. Zachowuj dosłownie placeholdery `{n}`, `{0}` itd. oraz identyfikatory kluczy.

## Limity, sklepy i kontrola

Dialog oraz scena następnego dnia (`.after.N`): **maks. 90 znaków**. Wpis do zeszytu: **maks. 130 znaków**. Przycięcie nie może usuwać głosu postaci ani informacji o zgodzie na otwarcie. Format plików i18n: `keys,en,pl,de`; korekta T11: `key,pl_old,pl_new,note`. Bez zmiany kluczy; w CSV cudzysłów zapisujemy jako `""`.

App Store: nazwa 30 znaków, podtytuł 30, promo 170, keywords 100 **bajtów UTF-8**, opis 4000. Google Play: tytuł 30, krótki opis 80, pełny 4000. Bez obiecywania ceny, daty premiery i dostępności (D-06, D-51). W Play nie wspominaj iPada. Wariant zakupowy A tylko po zatwierdzeniu przez właściciela.

**Procedura:** ustal mówcę i kontekst → porównaj ze słownikiem, DESIGN/JOBS i źródłem EN → popraw możliwie oszczędnie → zapisz uzasadnienie w `note` → sprawdź brak pustych kluczy, duplikatów, zmian placeholderów i przekroczonych limitów → zobacz wynik na ekranie urządzenia. Po zaakceptowaniu zmian zsynchronizuj także inne materiały narracyjne poza T11, w osobnym zadaniu.
