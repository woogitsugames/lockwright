# T08 — Plan playtestów prototypu (raport przekazania)

**Status:** oddana dokumentacja gotowa do przeprowadzenia badań, nie przeprowadzone badania ani przetestowany APK. **Data opracowania:** 2026-11-05. **Repo:** woogitsugames/lockwright, gałąź main. **Zakres zmian:** wyłącznie contrib/gpt/T08/.

## Co zrobiłem

Opracowałem kompletny, 30-minutowy protokół dla osoby bez przygotowania UX, obejmujący naukę sterowania, wskazówki H0–H4, rozpoznawanie stanów bez koloru, odczuwalność haptyki, test w ciemności, dostępność przy wyłączonych wibracjach, poziomy trudności t1–t7, ekonomię oraz ciepły i legalny ton gry.

Dodałem również opcjonalny, kontrolowany wariant D: dwa porównywalne zamki na jednym Androidzie przy haptyce ON/OFF, ze zrównoważoną kolejnością i identycznym dźwiękiem/obrazem. Pozwala odróżnić pierwsze oznaki wpływu haptyki od samej deklaracji w ankiecie, choć mała próba pozostaje pilotażowa.

Protokół rozdziela **twarde kryteria projektu A1/A2/A7/A9** od eksploracyjnych sygnałów jakościowych. Ustala rekrutację, przygotowanie Androida, scenariusze testów, neutralne wypowiedzi moderatora po polsku i po angielsku, zasady ochrony prywatności, dokumentację prób nieudanych i prostą procedurę podjęcia decyzji po agregacji wyników. Dostarcza równoległe ankiety o wspólnych kodach Q01–Q20.

## Pliki

| Plik | Zawartość |
|---|---|
| **PLAYTEST-PLAN.md** | cele i progi; 30-minutowe ścieżki A/B/C; próba 16+14+4–6 osób, opcjonalnie 8–12 do haptyki ON/OFF, oraz pilot; testy A1/A2/A7/A9; pomiary, anonimizacja, agregacja i priorytety decyzji |
| **survey_pl.md** | gotowa polska ankieta po sesji — dokładnie 20 pytań, odpowiedzi 1–5/N/D i kody jednolite z EN |
| **survey_en.md** | zgodna znaczeniowo wersja angielska — 20 pytań, odpowiedzi 1–5/N/A |
| **observation_sheet.md** | arkusz sesji PL/EN: metadane bez danych osobowych, oś czasu, samouczek, A1/A2, test stanów, zadania t1–t7, legalność i ekonomia |

**ASSETS.md:** nie tworzono, ponieważ T08 nie zawiera wygenerowanych ani dodanych grafik, dźwięków, fontów ani plików binarnych. Wszystkie dostarczone pliki są autorskimi dokumentami tekstowymi; nie używano zewnętrznych zasobów.

## Co się nie udało / czego nie można potwierdzić

- Nie przeprowadzono playtestów z ludźmi ani nie sprawdzano działania APK na fizycznym Androidzie. Pliki zawierają **plan i puste wzorce**, nie wyniki.
- Nie potwierdzono w działającym APK dostępności flag testowych (pin.a1 bez H1–H4, pin.a2 z czarną nakładką), selektora tierów i seedów, eksportu zdarzeń ani kompletu ośmiu par ujęć do A7. Jeżeli brakuje tych funkcji, odpowiednie wskaźniki pozostają „niebadane”.
- 30 minut nie pozwala zmierzyć pełnej ekonomii kariery ani całej krzywej t1–t7 u jednego gracza. Zaproponowano odrębne sesje rotacyjne; cztery próby na tier są diagnostyczne, nie statystycznie rozstrzygające.
- Playtest wyłącznie na Androidzie nie może być traktowany jako zaliczenie testów iOS, precyzyjnych opóźnień czy wydajności wymaganych w DESIGN.md.
- Obecne ECONOMY.md opisuje **niezaimplementowane propozycje** i znane błędy danych. Nie wolno przypisywać im statusu naprawionych.

## Uwaga o niespójnościach dokumentacji poza T08

- docs/HUD.md jest nowszą specyfikacją diegetycznego interfejsu niż starszy rysunek pasków/monet w docs/DESIGN.md §2; testy zakładają **brak pływających paneli** podczas otwierania zamka.
- docs/PROGRESSION.md opisuje w starej sekcji krzywą z parametrem 0,55, a docs/ECONOMY.md wykazuje jej niezgodność z tabelą progresji. Nie zmieniałem danych ani cudzych dokumentów.
- lockcore/BALANCE.md v0.3 ma pin_tumbler t2–t7, a t1 pochodzi z innej rodziny, np. wafer. T1 nie może być porównywany z pinowymi t2–t7 bez zastrzeżenia o różnicy rodzin.
- CLAUDE.md opisuje stan przedprodukcyjny. Zlecenie dotyczy przyszłego prototypu Android; plan jest używalny, gdy APK z potrzebnymi funkcjami będzie dostępny.

## Proponowane następne kroki

1. Sprawdzić, czy APK udostępnia techniczne przełączniki i eksport lokalnych zdarzeń, a w razie braku zlecić je właściwemu zespołowi (bez zmian w tym zleceniu).
2. Zorganizować trzy sesje pilotażowe, skorygować czas i pytania bez zmiany definicji progów w trakcie serii.
3. Zebrać minimum 12 ważnych sesji A1/A2 (cel 16) i po 8 ocen A7 na wariant, a dodatkowo badania dostępności i rotacyjne poziomy t1–t7.
4. Najpierw usunąć potwierdzone blokady legalności/dostępności i błędy danych ekonomii; po każdej zmianie jednego elementu powtórzyć test na nowych osobach.

**English summary:** T08 provides the Android playtest protocol, matched 20-question Polish/English surveys and a bilingual observation sheet. No APK, human subjects or third-party media were tested or generated. Acceptance gates, accessibility, privacy and known economy limitations are documented.
