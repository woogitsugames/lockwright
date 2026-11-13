# Postęp, trudność i tryby

Dokument łączy `LOCKS.md` (wektor trudności, tiery, weryfikator), `TOOLS.md` (kolejność narzędzi, ceny), `JOBS.md` (rozdziały, dzielnice) i `SHOWCASE.md` (notki). Liczby to punkt startowy do playtestów i leżą w danych (`progression/*.json`), a nie w kodzie.

## 1. Zasada wejścia każdej nowej rodziny

Każda rodzina, w MVP i w każdym przyszłym dodatku, wchodzi tą samą ścieżką:

| Etap | Liczba | Charakter | Źródło zamków |
|---|---|---|---|
| **Samouczek S1–S3** | 3 | pokazy bez tekstu. S1: jeden element, szerokie okna, wszystkie sygnały ×1,5. S2: kolejność wiązania na 2–3 elementach. S3: pierwsza pułapka rodziny (np. szpulka, overset, fałszywa bramka) | `authored` |
| **Proceduralne** | 10–20 | rosnący wektor trudności, maks. 2 osie w górę naraz (`LOCKS.md` §1.8) | `generated` + weryfikator |
| **Mistrzowskie** | 3–5 | ręcznie ułożone „łamigłówki” rodziny, czasem z notką gabloty jako nagrodą | `authored` + weryfikator |

- Samouczek można pominąć przy powtórce. Pierwszy raz jest obowiązkowy, ale trwa poniżej 2 minut.
- Rodzina pojawia się w puli Trybu Ciągłego dopiero po S3.
- Przegrana w samouczku nie kosztuje wytrycha.

## 2. Tryb Ciągły (MVP)

### 2.1 Reguły
- Seria zamków bez przerw. **Trzy wytrychy to trzy życia:** złamanie zabiera jeden, a seria kończy się po trzecim.
- Monety: `10 × tier`, +50% za otwarcie „czysto” (bez `drop` i `break`), +20% w trybie „w ciemności”.
- Co 5 zamków jest **przystanek w warsztacie**: zakup i naprawa narzędzi, jeden wytrych do odkupienia za monety (maks. 3).
- Seria zapisuje się między zamkami, więc sesja 5–10 minut jest naturalna.
- **Bez timerów domyślnie.** Opcja „na czas” to osobny ranking.

### 2.2 Krzywa trudności (zamek n w serii)

Tier docelowy rośnie płynnie i jest ograniczony narzędziami gracza:

```
tier(n) = min( tier_max(narzędzia),  1 + 0.55 · ln(1 + n) · skill )
skill   = 0.8 … 1.25   (średnia krocząca z 5 ostatnich zamków: czas / czas docelowy, liczba dropów)
```

| Zamek w serii | Tier (gracz średni) | Typowe rodziny | Cel czasu |
|---|---|---|---|
| 1–3 | 1–2 | egipski, zapadkowy, płytkowy | 30–60 s |
| 4–8 | 2–3 | wkładka 3–4 piny, kłódka szyfrowa | 45–90 s |
| 9–15 | 3–4 | wkładka 4–5 pinów + 1 szpulka, dźwigniowy | 60–120 s |
| 16–25 | 4–5 | wkładka 5 pinów + 2 zabezpieczenia, dźwigniowy 4–5 dźwigni | 60–150 s |
| 26+ | 5–7 (MVP: do 6) | mieszanka, „wąski kanał”, detektor (F1) | 90–180 s |

- **Elastyczność („rubber band”) jest jawna:** po dwóch złamaniach z rzędu następny zamek ma −1 tier i komunikat ślusarza („Weź oddech. Prostszy zamek.”). Nie ukrywamy tego przed graczem.
- Rodziny nie powtarzają się więcej niż 2 razy z rzędu.

### 2.3 Narzędzia a pula (szczegóły w `TOOLS.md` §4)
Start: napinacz kątowy, podważka kołkowa i haczyk (egipski, wkładka t2, płytkowy). Kolejne zakupy MVP to sonda przelotowa (0, dar z samouczka), ciągadło (60), falownik (110) i korba dźwigniowa (120). Każde narzędzie dodaje nową logikę i nową rodzinę do puli. Żadne nie jest „+10% obrażeń”. **D-62:** narzędzie jest wygodą i lepszym feedbackiem, nigdy bramką: gra nie sprawdza narzędzi przy przyjęciu zlecenia, a zamek rodziny bez jej narzędzia da się otworzyć (wolniej, ze słabszym sygnałem).

### 2.4 Ekonomia MVP (orientacyjnie)
- Średni dochód: ok. 40 monet na zamek w środkowej części serii, czyli ok. 300 monet na sesję 8 minut.
- **Ceny narzędzi (D-62, `game/data/tools.json`):** ciągadło 60, korba 120, napinacz listwowy 150, koronka 180, sonda biegunowa 200, klin 200, falownik 110, chorągiewka 240, trzpień 260, obrotnik tarcz 280, słuchawka 300, piórko 500, mikroskop 90, wziernik 130 (przed D-62: 150, 300, 450, 600, 700, 700, 350, 900, 1000, 1100, 1200, 2000, 250, 400). Razem 2 820 monet (było 10 100); narzędzia do rodzin ze zleceń (9 szt.) 1 790 (było 6 400).
- Główna kariera (103 zlecenia, rozdz. 1–14, `econ_sim.py` C; liczby zawsze w `docs/ECONOMY.md` §1, §6a i §6b): dochód ze zleceń ok. 11 200–13 100 monet wobec 2 820 za wszystkie narzędzia i 6 750 za wyposażenie warsztatu (D-71); gracz average kupuje 13 z 13 osiągalnych płatnych narzędzi, bez sesji Trybu Ciągłego i bez zablokowanego zlecenia. Tryb Ciągły (ok. 400 monet na sesję 8 min) jest dodatkiem, nie warunkiem postępu. Po rozdz. 12 sklep się kończy (D-124, §8).
- Pełna wersja odblokowuje rodziny i tryby, a nie monety.
- Monet **nie można kupić za pieniądze** (bez pay-to-win).

## 3. Tryb Zleceń (po MVP, faza 1)

Struktura z `JOBS.md` §4: miasto „Zameczno” (nazwa robocza) z 7 dzielnicami i 6 rozdziałami.

| Rozdział | Dzielnice | Nowe rodziny | Typy klientów | Mechanika meta |
|---|---|---|---|---|
| 1. Pierwsza zmiana | Śródmieście, Osiedle, Kampus | zapadkowy, szyfrowa, wkładka, płytkowy | emeryci, studenci, rodziny | weryfikacja prawa do lokalu, wycena, pierwsza odmowa |
| 2. Nocne dyżury | Nocny Rynek, Osiedle, Kampus | magnetyczny, rurkowy, wkładka T2 | restauratorzy, para po weselu, kot w łazience | stawka nocna ×1,5, zmęczenie (szersza panorama dźwięku) |
| 3. Strychy i spadki | Willowa Górka, Ogródki | egipski (zabawka), dźwigniowy, sejf | spadkobiercy, działkowcy | konflikty rodzinne, przedmioty do gabloty |
| 4. Małopolska | Kraków, Świątniki Górne | zapadkowy T3, kłódka świątnicka | rzemieślnicy, muzealnicy | ścieżka historyczna PL w gablocie |
| 5. Pociąg do Brukseli | Bruksela, Gandawa, Liège | dimple/listwa, dźwigniowy z detektorem | ekspaci, kamienice flamandzkie | inny kodeks (karta ślusarza), język |
| 6. Skarbiec | Port, Muzeum | Bramah, tarczowy, zamek czasowy | kuratorzy | finał: kapsuła czasu, naprawa zegara |

- **Reputacja** (0–100 na dzielnicę) i globalne **Zaufanie**. Otwarcie bez śladów daje napiwek i reputację. Wiertarka kosztuje części i reputację. Odmowa podejrzanego zlecenia daje reputację, a nie karę.
- Mapa miasta odsłania dzielnice reputacją, a nie czasem ani energią.

## 4. Gablota: ścieżka historyczna

Notki (`SHOWCASE.md`) odblokowuje **otwarcie danej rodziny lub konkretnego zlecenia**, a nie zakup. Kolejność ekspozycji idzie chronologicznie, niezależnie od kolejności odblokowania:

1. Starożytność: zamek kołkowy (Khorsabad, koniec VIII w. p.n.e., z korektą mitu „4000 lat”), rzymskie zamki zapadkowe.
2. Średniowiecze i cechy: krakowski cech ślusarzy i zegarmistrzów (statut 1633).
3. Wiek wynalazków: Barron 1778, Bramah 1784 i wyzwanie (200 gwinei), Chubb 1818 (detektor, po Ruxtonie 1816), Stansbury 1805, Yale 1848/1861–65.
4. Wielka Wystawa 1851: Hobbs — 51 godzin w 16 dni.
5. Bank i czas: Sargent (1873/1874).
6. Polska: Świątniki Górne (szkoła 1888, Muzeum im. Marcina Mikuły), wystawa „Żelazny świat” (MNWr 2022).

Każda gablota ma pole „Twój egzemplarz”: seed, czas i znaczek „w ciemności”.

## 5. Wyzwania

| Wyzwanie | Zasada | Nagroda |
|---|---|---|
| **W ciemności** | przekrój wygaszony, tylko dźwięk i haptyka (okna ×1,15, `LOCKS.md` §1.7). Dostępne dla każdej rodziny po S3 | +20% monet, znaczek w gablocie |
| **Jeden wytrych** | seria z jednym życiem | ranking lokalny, znaczek |
| **Zamek dnia** | wspólny seed z daty UTC (`hash("daily", YYYY-MM-DD, rules_version)`), ta sama rodzina i tier dla wszystkich. Bez serwera w MVP, wynik do udostępnienia jako tekst (czas, dropy, „w ciemności”) | znaczek dnia, passa |
| **Na czas** (opcja) | timer widoczny tylko w tym wyzwaniu | ranking lokalny |
| **Mistrz rodziny** | 3–5 zamków mistrzowskich rodziny bez złamania | notka specjalna |

Zasady stałe: żadne wyzwanie nie wymaga zakupu ani reklam. Timer nigdy nie jest domyślny.

## 6. Rozbudowa latami (szablon dodatku)

Dodatek „rodzina X” dostarcza:
1. moduł rodziny (`LOCKS.md`, karta z wzoru),
2. narzędzie lub narzędzia (`TOOLS.md`),
3. S1–S3, 10–20 profili proceduralnych i 3–5 zamków mistrzowskich,
4. 2–4 zlecenia (`JOBS.md` §6) i 1–2 notki gabloty ze źródłem,
5. mapowanie sygnałów w 3 kanałach,
6. klucze i18n PL i EN.

Bramka publikacji: weryfikator na 10 000 seedów, kompletność kanałów i kompletność i18n (`ARCHITECTURE.md` §7).

## 7. Zmiany po ONBOARDING/LEVELS

Dopisane 2026-11-04 po `ONBOARDING.md`, `LEVELS.md` i `HUD.md`. Powyższe sekcje obowiązują, z tymi zmianami:

1. **Kolejność pierwszej sesji (D-21):** pierwsze uruchomienie (język, kalibracja haptyki, notka „to gra, nie kurs”) → `pin.s1`–`pin.s3` w imadle warsztatu → `pin.a1` (własne drzwi warsztatu, zamek testu A1) → Tryb Ciągły. Wkładka bębenkowa jest pierwszą rodziną, bo na niej mierzymy A1. Płytkowa wchodzi z własnym S1–S3 przed pierwszym zamkiem płytkowym w serii.
2. **Pula MVP przy lockcore v0.1:** tylko `pin_tumbler` (profile P01–P17) i `wafer` (W01–W12) z `LEVELS.md` §5. Tabela §2.2 (egipski, zapadkowy, płytkowy na zamkach 1–3) obowiązuje, gdy te rodziny będą w lockcore. Do tego czasu zamki 1–3 serii biorą W01–W02 i P01.
3. **Wybór profilu w serii:** najniższy nieukończony profil rodziny o `tier ≤ tier(n)`. Gdy wszystkie z tego tieru są ukończone, losowy z nich. P17 nigdy bezpośrednio po P16 (`LEVELS.md` §5.1).
4. **S3 to pierwsza pułapka, a nowe zabezpieczenia mają lekcje wtrącone (D-22):** pinowa S3 uczy overset i zrzutu, a szpulka dostaje lekcję `pin.l_spool` przed pierwszym zamkiem z P06 (albo `pin.l_serrated`, jeśli pierwszy trafi się kołek ząbkowany). Płytkowa S3 to „Za mocno” (napięcie powyżej `tau_safe`, złamanie na niby), a falownik ma lekcję przy zakupie (`ONBOARDING.md` §9.2), bo na starcie gracz go nie ma.
5. **Czas samouczka:** zamiast „poniżej 2 minut” na każdą rodzinę: mediana ≤ 3 min dla pierwszej rodziny (pinowa, z nauką obu kciuków), ≤ 2 min dla kolejnych.
6. **„W ciemności” (§5):** dostępne po S3, ale gracz poznaje je raz, w skryptowanej scenie (minutnik gaśnie w drugim zamku serii, `ONBOARDING.md` §7). Potem włącznik minutnika przed każdym zamkiem.
7. **Mistrz rodziny (§5):** `pin_tumbler` ma 5 zamków mistrzowskich (`pin.m1`–`pin.m5`), `wafer` 3 (`wafer.m1`–`wafer.m3`, wbrew „nie dotyczy” w `LOCKS.md` §2.4). Zamek mistrzowski odblokowuje się po ukończeniu profilu tego samego tieru.
8. **Przegrana w samouczku i lekcjach wtrąconych** nie kosztuje wytrycha (bez zmian), a dotyczy też `wafer.s3`, gdzie złamanie jest częścią lekcji.

## 8. Stan w grze po rozdziale 14 (D-124)

Przegląd z 2026-11-13: co w grze naprawdę zależy od rozdziału i liczby zleceń. Sekcja 3 opisuje projekt (reputacja odsłania dzielnice); gra robi dziś mniej i to jest stan obowiązujący, dopóki właściciel nie zdecyduje inaczej.

1. **Rozdziały nie mają progów.** Lista zleceń pokazuje wszystkie rozdziały od początku, w kolejności `chapter` / `order`; nie ma progu reputacji, monet ani liczby zleceń. Nowy rozdział (13, 14, kolejne) jest grywalny od razu po dodaniu danych i niczego nie trzeba dopisywać w `progression.json` (plik opisuje Tryb Ciągły, nie rozdziały).
2. **Reputacja** jest tylko licznikiem w zapisie (odmowa +5, pole `reputation` zlecenia, złe drzwi −25). Nic jej nie czyta: nie odblokowuje i nie jest pokazywana.
3. **Osiągnięcia** (48) nie liczą zleceń ani rozdziałów, więc żadne nie zmieniło warunku po rozdz. 13–14. Gra przyznaje dziś tylko te z wyzwalaczem `result=open` i `event=` (31); pozostałych 17 (12 zleceniowych `result=job_completed / job_refused / job_resolved`, 3 wyzwania, 2 szkoły samouczka) ma dane i teksty, ale nic ich nie przyznaje. Żaden ekran gry nie pokazuje jeszcze osiągnięć.
4. **Gablota:** 23 notki, wszystkie odblokowują zlecenia z rozdz. 1–6 (albo tier ≥ 3). Rozdziały 7–14 nie dodają notek.
5. **Wyposażenie warsztatu:** ostatni przedmiot odblokowuje rozdz. 11. Rozdziały 13–14 niczego nie odblokowują, a monety z nich (ok. 3 000) nie mają celu: `docs/ECONOMY.md` §6b. Propozycja pięciu przedmiotów na rozdz. 13–15 czeka na sesję z grafiką (D-124). **Od D-127:** pięć przedmiotów (4 800 monet, rozdz. 13–15) jest w danych i tekstach; gra pokaże każdy, gdy dojdzie jego nakładka (`docs/handoff/LOCAL-GPU-TASKS.md`), do tego czasu stan w grze jest taki jak wyżej.
6. **Mapa dzielnicy w warsztacie** czyta klucz zapisu `chapter`, którego gra nie ustawia, więc zawsze pokazuje mapę rozdziału 1 (mapy są dla rozdz. 1–6).
