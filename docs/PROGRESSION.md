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
Start: napinacz kątowy, podważka kołkowa i haczyk (egipski, wkładka t2, płytkowy). Kolejne zakupy MVP to sonda przelotowa (80), ciągadło (150), falownik (350) i korba dźwigniowa (500). Każde narzędzie dodaje nową logikę i nową rodzinę do puli. Żadne nie jest „+10% obrażeń”.

### 2.4 Ekonomia MVP (orientacyjnie)
- Średni dochód: ok. 40 monet na zamek w środkowej części serii, czyli ok. 300 monet na sesję 8 minut.
- Wszystkie narzędzia MVP (ok. 1 080 monet) kupuje się w ok. 4 sesjach. Pełna wersja odblokowuje rodziny i tryby, a nie monety.
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
