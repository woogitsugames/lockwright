# Zlecenie T40: dosynchronizowanie 7 tłumaczeń z bieżącym main

**Dla:** ChatGPT z dostępem do GitHuba (jedna sesja = jedno zlecenie). Repo `woogitsugames/lockwright`, gałąź `main`.
**Kontekst i zasady obowiązkowe:** jak w `docs/handoff/gpt/G01-enamel-apartment-number-plates.md` §1–§2: legalny ślusarz, fotorealizm, zero marek, lista zakazanych klisz, AI dozwolone (D-42) z wpisem w `ASSETS.md` (narzędzie, data, pełny prompt, edycje). Zapisuj **tylko** w swoim katalogu `contrib/gpt/T40/`. Raport `README.md` po polsku. Commit `contrib/gpt/T40: <opis>`; jeśli nie możesz pisać do `main`, oddaj ZIP właścicielowi.

**Uwaga:** zapisujesz w istniejących pakietach `contrib/gpt/T31/` … `contrib/gpt/T37/` (to Twoje wcześniejsze katalogi), plus raport w `contrib/gpt/T40/`.

## Po co
Twój audyt (`contrib/gpt/QA-LOCALIZATIONS-SNAPSHOT-2026-11-05.md`) pokazał 65 nowych kluczy UI bez tłumaczeń we wszystkich 7 pakietach (fr, es, it, pt_br, cs, uk, de). Sesja A dopisuje teraz kolejne:
- sekcje ustawień;
- wybór sterowania (D-52 w `docs/DECISIONS.md`);
- samouczek z kredą (`tutorial.*`, `lock.*`);
- cele zamków ćwiczebnych (`practice.tNN.goal`);
- nawigacja (`nav.*`).

## Zadanie
1. **Pobierz najnowszy `main` w chwili rozpoczęcia pracy** i zapisz hash commita w raporcie. Źródło: `game/i18n/strings.csv` i `game/i18n/content.csv` (`keys,en,pl,de`). EN jest wzorcem, a PL pomaga zrozumieć ton.
2. Uruchom `python contrib/gpt/validate_v2_localizations.py` i weź **wszystkie** brakujące klucze, nie tylko 65 z audytu.
3. Przetłumacz je w każdym z 7 pakietów (`strings_<lang>_v2.csv`, `content_<lang>_v2.csv`). Zasady:
   - **limity długości:**
     - `tutorial.*` i `lock.*`: ≤ 56 znaków, czyli 2 linie na ekranie 412 dp;
     - `menu.*`: ≤ 28;
     - `ui.controls.*_desc`: ≤ 80;
     - pozostałe: nie dłużej niż EN + 30%;
   - placeholdery `{…}` bez zmian;
   - terminologia jak w Twoich pakietach (pin bębenkowy, napinacz, wytrych, linia podziału);
   - ton ciepły, spokojny, z lekkim humorem;
   - bez instruktażu do realnych zamków i bez słów oznaczających włamanie;
   - **nie wstawiaj tekstu EN jako tłumaczenia.** Jeśli czegoś nie jesteś pewien, oznacz to w raporcie.
4. **DE** w grze jest w `game/i18n/strings.csv` (kolumna `de`) i pisze ją sesja A. W pakiecie T37 zrób tylko **korektę** kolumny DE z main: lista proponowanych poprawek `klucz | obecnie | proponuję | dlaczego`. Nie przepisuj wszystkiego.
5. Ponownie uruchom walidator. Wynik: 0 brakujących kluczy i 0 błędów dla migawki z pkt 1.

## Oddanie
- zaktualizowane CSV w `contrib/gpt/T31`…`T37`;
- `contrib/gpt/T40/README.md` (po polsku):
  - hash źródła;
  - liczba dodanych kluczy na język;
  - wynik walidatora;
  - lista niepewnych miejsc;
  - poprawki DE.

Commity: `contrib/gpt/T40: <opis>`.

## Kryteria odbioru
- walidator zielony dla zapisanej migawki;
- limity spełnione;
- żadnych wartości skopiowanych z EN, poza nazwami własnymi i `Lockwright`.
