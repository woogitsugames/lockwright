# Paczka 30 zleceń dla ChatGPT (T44–T73), 2026-11-06

**Repo:** `woogitsugames/lockwright`, gałąź `main`. **Zapisujesz tylko do `contrib/gpt/<ID>/`** (nigdy do `game/`, `docs/`, `tools/` itp.); integrację robi sesja A. Każde zlecenie oddaj osobnym commitem `contrib/gpt/<ID>: …` z `README.md` (po polsku: co zrobione, czego nie, wątpliwości).

## Zasady wspólne (obowiązują w każdym zleceniu)
- Przeczytaj `CLAUDE.md`. Ton ciepły i legalny: ślusarz pomaga i weryfikuje prawo do lokalu. Zero marek zamków i samochodów, zero instrukcji do prawdziwych produktów, mechanizmy wymyślone.
- Terminy: PL pin bębenkowy = **„pin”** („kołek” tylko zamek drewniany/egipski); słowniczek rodzin w `contrib/gpt/REVIEW-T41.md`, `REVIEW-T42.md`.
- Forma: interfejs mówi do gracza **na „ty”** (PL ty, DE du, FR tu, ES tú — D-67); postacie w dialogach do ślusarza **per pan/Sie/vous/usted**.
- Limity: `tutorial.*`, `lock.*` ≤ 56 znaków; `menu.*` ≤ 28; teksty czytane przez lektora: liczby słownie, bez skrótów.
- Format tekstów: CSV `keys,en,pl,de,fr,es` (puste kolumny zostaw puste, nie wpisuj angielskiego zastępczo). Sprawdź swoim plikiem: `python3 tools/i18n_lint.py` na kopii z dopisanymi kluczami (opisz wynik).
- Nie zmieniaj znaczenia istniejących kluczy; poprawki istniejących tekstów oddawaj jako tabelę „klucz | było | jest | powód”.

## A. Korekta istniejących tekstów
1. **T44 Korekta PL UI** — `game/i18n/strings.csv` kolumna `pl`: gramatyka, interpunkcja, naturalność, spójność terminów i formy „ty”. Wynik: `T44/fixes_pl.csv` + tabela zmian.
2. **T45 Korekta EN UI** — to samo dla `en` (brytyjska czy amerykańska pisownia: amerykańska, konsekwentnie).
3. **T46 Korekta DE UI** — to samo dla `de` (du, Zuhaltung/Stift itp. wg słowniczka).
4. **T47 Korekta FR/ES UI** — `fr`, `es` w `strings.csv`.
5. **T48 Korekta dialogów PL/EN** — `game/i18n/content.csv` klucze `*.line.N`, `*.after.N`, `*.note`: naturalna mowa pod lektora, spójność postaci (`contrib/voice/CAST.md`).
6. **T49 Korekta dialogów DE/FR/ES** — j.w. dla `de`, `fr`, `es`.
7. **T50 Brakujące tłumaczenia FR/ES UI** — wypełnij puste `fr`/`es` w `strings.csv` (ok. 77 kluczy). Wynik: `T50/fill_fr_es.csv`.
8. **T51 Spójność imion i nazw** — przejdź `content.csv`, `game/data/jobs*/*.json`, `docs/CLIENTS.md`, `contrib/voice/CAST.md`: lista niespójności (imiona, odmiana, płeć, wiek, adresy, nazwy dzielnic). Tylko raport.

## B. Nowe teksty do gry
9. **T52 Notatki „dzień po”** — dla zleceń bez `after` w `game/data/jobs*/*.json` dopisz 1–2 krótkie kwestie (mówca + PL/EN/DE). `T52/after_lines.csv` + lista `id → mówca`.
10. **T53 Wpisy zeszytu dla 8 nowych rodzin** — w stylu `docs/CLIENTS.md` §6 (głos zeszytu): 2 wpisy na rodzinę (PL/EN/DE/FR/ES).
11. **T54 Rachunki: opisy usług** — krótkie opisy pozycji rachunku dla każdej rodziny zamków i typu zlecenia (otwarcie, naprawa zegara, odmowa = brak usługi), ≤ 32 znaki. Klucze `receipt.service.<family>`.
12. **T55 Ćwiczenia (praktyka) dla nowych rodzin** — cele lekcji ćwiczeniowych w stylu `practice.<tNN>.goal` (zob. D-54 i `lockcore/practice/README.md`): po 2 cele na rodzinę, PL/EN/DE/FR/ES.
13. **T56 Osiągnięcia dla nowych rodzin** — w stylu `game/data/achievements.json` (+ klucze i18n): 8–12 propozycji (np. „Sejf bez detektora”, „Zegar wrócił do życia”). Bez gamifikacji przemocy/włamań.
14. **T57 Opisy narzędzi** — `game/data/tools.json`: krótki opis każdego narzędzia (do czego służy, jaki daje feedback), ≤ 80 znaków, PL/EN/DE/FR/ES; ceny bez zmian.
15. **T58 Dzielnice rozdziałów 9–12** — 4 krótkie opisy dzielnic na mapę (nazwa + 1–2 zdania), spójne z T43.
16. **T59 Zdania trybu „Dyżur”** — 20 krótkich, różnorodnych linijek dyspozytora między zamkami (≤ 56 znaków), ciepło i rzeczowo.
17. **T60 Teksty ustawień i pomocy** — opisy pod przełącznikami w ustawieniach (haptyka, kreda, napięcie automatyczne, ograniczenie ruchu, pobieranie głosów, jakość obrazu), ≤ 80 znaków.

## C. Głosy i obsada
18. **T61 Tagi audio dla kwestii T43** — po dostawie T43: dla każdej kwestii 0–2 tagi ElevenLabs (`[tired]`, `[laughs softly]`…) jak w `contrib/voice/tags.json`. Wynik `T61/tags_t43.json`.
19. **T62 Opisy głosów nowych postaci** — dla postaci z T43: prompt do Voice Design (wiek, płeć, barwa, tempo, akcent neutralny; fikcyjne, bez naśladowania znanych osób) w formacie `game/data/voice_cast.json` → `design_prompt`.
20. **T63 Opisy wyglądu do portretów** — dla postaci z T43: prompt do portretu w stylu istniejących (klatka schodowa, ciepłe światło, głowa i ramiona), po angielsku.

## D. Dokumenty (nie marketing)
21. **T64 Polityka prywatności (szkic)** — gra bez kont i analityki; jedyne połączenie sieciowe: pobieranie paczek głosów (D-63, hosting widzi IP); zapisy lokalne; haptyka i dźwięk lokalnie. PL i EN, prosto. Oznacz miejsca do weryfikacji prawnej.
22. **T65 Ekran „O grze” i podziękowania** — tekst „O grze” (to gra, nie kurs) + lista licencji z `docs/ASSETS.md` (fonty OFL, zasoby AI z narzędziem) w formie do wyświetlenia.
23. **T66 Lista kontrolna testu na telefonie** — checklista dla właściciela (menu, samouczek S1–S3 w obu trybach, każda rodzina zamków, głosy, Back, wibracje, poziom, Fold), z miejscem na OK/błąd i nr zrzutu.
24. **T67 Szablon zgłoszenia błędu** — krótki szablon N-xx (urządzenie, wersja APK, kroki, oczekiwane/jest, zrzut/nagranie, log).
25. **T68 Słowniczek 5 języków** — tabela terminów zamków i UI (PL/EN/DE/FR/ES) na podstawie istniejących CSV i recenzji; zaznacz rozbieżności.

## E. Audyty (tylko raporty)
26. **T69 Audyt tonu odmów** — sceny odmowy (`refuse_*` i podobne) vs `docs/CLIENTS.md` §4: czy ślusarz jest uprzejmy, stanowczy, legalny; propozycje poprawek.
27. **T70 Audyt dostępności tekstów** — czy każdy przycisk/ekran ma opis dla czytnika ekranu (klucze `*.a11y`/`say_*` w CSV), brakujące klucze i propozycje.
28. **T71 Audyt długości** — wypisz teksty, które w FR/DE są > 30 % dłuższe od EN w kluczach UI (ryzyko ucięcia) i zaproponuj krótsze.
29. **T72 Audyt powtórzeń** — powtarzające się zwroty w dialogach (np. to samo powitanie w wielu zleceniach), propozycje urozmaicenia.
30. **T73 Pytania kontrolne weryfikacji** — dla każdej karty weryfikacji (`verify.card.*`) 2 dodatkowe warianty pytań/odpowiedzi klienta, żeby weryfikacja się nie powtarzała (PL/EN/DE).

**Kolejność sugerowana:** 44–50 (korekty), 52–60, 64–68, 69–73; 61–63 po dostawie T43.
