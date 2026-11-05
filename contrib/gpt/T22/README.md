# T22 — raport oddania

**Data:** 2026-11-05  
**Repozytorium:** `woogitsugames/lockwright`  
**Zakres zmian:** wyłącznie `contrib/gpt/T22/`.

## Wykonano

- Przygotowano jakościowy research ASO w pięciu lokalizacjach PL, EN, DE, FR i ES: klastry intencji, 30 hipotez dłuższych fraz, rekomendowane pola keywords, krótkie opisy i 3 wersje otwarcia opisu na język (15 wariantów).
- Uzasadniono wybór słów w kontekście legalnej pracy ślusarza, wymyślonych mechanizmów i rozgrywki opartej na dotyku, słuchu oraz obrazie.
- Zweryfikowano zasady Apple i Google oraz rozdzielono rzeczywiste przykłady opisu od niezweryfikowanych hipotez popytu.
- Zautomatyzowano kontrolę limitów 100 **bajtów UTF-8** w App Store i 80 **znaków** w Google Play, bez przekroczeń.
- Nie obiecano ceny, daty premiery, modelu biznesowego, dostępności, nauki realnych zamków ani funkcji odłożonych poza MVP.

## Pliki

| Plik | Opis |
|---|---|
| `ASO.md` | Badanie, pięć lokalizacji, gotowe pola sklepowe z licznikami, uzasadnienia, 15 wariantów, plan testów, ryzyka i źródła. |
| `aso_keywords.csv` | UTF-8 z BOM, 55 rekordów danych (5 ×: keywords, Google Play short, A/B/C i sześć hipotez fraz); nagłówki i oddzielne liczniki znaków/bajtów. |
| `README.md` | Ten raport oddania. |

## Wyniki walidacji

| Lokalizacja | App Store: znaki | App Store: bajty / 100 | Google Play: znaki / 80 |
|---|---:|---:|---:|
| pl-PL | 88 | 94 / 100 | 63 / 80 |
| en-US | 95 | 95 / 100 | 70 / 80 |
| de-DE | 92 | 94 / 100 | 70 / 80 |
| fr-FR | 90 | 94 / 100 | 78 / 80 |
| es-ES | 91 | 93 / 100 | 64 / 80 |

Walidacja obejmuje też brak pustych fraz, spacji wokół przecinków, powtórzeń i nazw konkurencji w gotowych polach keywords. Limity wykonano dla literalnych pól w pliku, nie dla hipotetycznych przyszłych tytułów.

## Czego nie udało się potwierdzić

- **Realne wolumeny, trudność i pozycje zapytań w sklepach:** brak pomiarów z paneli ASO, Apple Search Ads i konsol publikacji. P1/P2/P3 to kolejność redakcyjna, nie wyniki analityczne.
- **Pełna zgodność językowa DE/FR/ES i trafność fraz regionalnych:** wymagana konsultacja native speakera i pomiary po pierwszych testach; projektowy i18n jest obecnie PL+EN.
- **Tryb Zleceń i pełna dostępność audio/haptyczna:** zakres 1.0 wymaga potwierdzenia. Wariant B opisów jest jawnie wstrzymany do wdrożenia Trybu Zleceń.
- **Zgodność pozostałych plików repo:** `CLAUDE.md` ma stary tytuł EN, lecz decyzja D-32 i `store/listing.md` używają *Locksmith on Call*. Zgodnie ze zleceniem nie poprawiano dokumentów poza T22.
- **Natywny test A/B tekstów Apple:** oficjalne strony nie są całkowicie spójne; zakres dostępnych kontrolek należy potwierdzić w App Store Connect.

## Zgodność z ograniczeniami repo

Nie zmieniano `store/listing.md`, `docs/DECISIONS.md`, plików i18n, kodu ani materiałów T07. Nie tworzyłem grafik, dźwięków czy innych zasobów. Materiały są propozycjami badawczymi do zatwierdzenia przed publikacją.
