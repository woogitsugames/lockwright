# T01 — korekta angielskich dialogów

Data: 2026-11-05  
Repozytorium: `woogitsugames/lockwright`  
Źródło: `docs/CLIENTS.md`, Załącznik A (`keys,en,pl`; 638e3924c5b5801253055d1de2dce5b495319769).

## Wykonane

- Przejrzano **wszystkie 207 kluczy** z Załącznika A: **116 linii dialogów**, **7 wypowiedzi „dzień po”**, **29 wpisów zeszytu**, **49 nazw mówców** i **6 zasad / wypowiedzi zeszytu**.
- Wprowadzono **80 korekt EN**. Pozostałe **127 wpisów** zachowano bez zmian; puste pole `note` oznacza brak potrzeby korekty.
- Każda zmiana ma osobne, krótkie uzasadnienie po polsku w kolumnie `note`.
- Nie modyfikowano żadnego tekstu PL, klucza, pliku produkcyjnego ani dokumentacji poza katalogiem T01.
- Sprawdzono parserem CSV: **207 unikalnych kluczy, bez braków i duplikatów, 4 poprawne kolumny, bez nowych wykrzykników**. Żaden nowy dialog ani nazwa nie przekracza **90 znaków**; żaden wpis `.note` nie przekracza **130 znaków**. Zachowano zapis CSV zgodny z RFC 4180 (UTF-8; cudzysłowy i przecinki escapowane).
- Korekta utrzymuje ton gry (ciepły, spokojny, lekko ironiczny), spokojny język odmów, konwencję **Mrs/Mr + imię** i brytyjską pisownię tam, gdzie występowała w materiale źródłowym.

## Pliki

- `content_en_reviewed.csv` — pełne porównanie `key,en_old,en_new,note` dla wszystkich 207 kluczy.
- `README.md` — niniejszy raport i zagadnienia do dalszego sprawdzenia.

Nie tworzono obrazów, dźwięków ani innych zasobów; rejestr `ASSETS.md` nie jest w tym zleceniu wymagany.

## Uwagi redakcyjne i możliwe dalsze działania (poza zakresem T01)

1. **Kalki i angielski nienaturalny:** `aunt who is doing fine`, `is certainty`, `transfer protocol`, `getting old, and impatient with it`; część kwestii miała niepoprawne łączenie zdań przecinkiem (comma splice). Poprawki zawiera CSV.
2. **Znaczenie:** `job.finnish_sailor.note` miał `birch cup`, choć w PL jest **chochla z brzozy**; poprawiono na `birchwood ladle`. `job.grandma_broth.note` zamieniał **Śródmieście** na **Old Town**; poprawiono na `city centre`.
3. **Nazewnictwo:** `Mrs/Mr + imię` jest nietypowe w codziennej angielszczyźnie, ale stanowi **świadomą konwencję** z `docs/CLIENTS.md`, więc zostało zachowane. `Monsieur/Madame` pozostają w scenach belgijskich jako koloryt miejsca.
4. **Niezgodności dokumentacji (nie zmieniano):** `CLAUDE.md` używa angielskiego podtytułu `Lockwright: Emergency Locksmith`, podczas gdy zlecenie T01 wskazuje `Lockwright: Locksmith on Call`. Do ujednolicenia przez właściciela projektu.
5. **Zastrzeżenie o markach:** klucze `job.bramah_bureau.*` zawierają nazwę realnie kojarzoną z marką/mechanizmem. **Nie zmieniano kluczy** zgodnie z kryterium odbioru; w widocznych kwestiach EN nie dodano żadnej marki. Warto osobno zdecydować o neutralizacji identyfikatora w całym projekcie.
6. **Spójność danych:** `docs/CLIENTS.md` §7 sygnalizuje dwie postacie `Ola`, rodzinę `unknown` w `drummer_locker` oraz różnicę dokumentów w `kiosk_shutter`; do rozstrzygnięcia w sesji odpowiedzialnej za dane, bez zmian PL.
7. **Realizm zdarzeń:** `job.grandma_broth.line.2` mówi o zakręceniu gazu na klatce. Zachowano sens PL, ale scenograf i autor powinni potwierdzić zgodność z lokalizacją licznika i zaworu.
8. **Miejsca drobnej niejednoznaczności:** `job.refuse_ex_partner` ma nazwisko na skrzynce w dialogu, lecz na drzwiach w notatce. Ponieważ rozbieżność jest także w materiale PL, nie poprawiano jej samodzielnie.

## Kryteria odbioru

- [x] Wszystkie klucze z Załącznika A zachowane; kolejność bez zmian.
- [x] Każda zmiana uzasadniona w `note`.
- [x] Brak nowych wykrzykników.
- [x] Limity długości zachowane (90 dialog / 130 zeszyt).
- [x] Wyłącznie pliki `contrib/gpt/T01/`.

**Co się nie udało:** brak problemów w zakresie korekty; ewentualne aktualizacje źródłowego `game/i18n/content.csv` i plików poza T01 są celowo pozostawione odpowiednim zespołom.
