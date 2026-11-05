# T07 — Aktualizacja analizy konkurencji

**Wykonano 05.11.2026.** Raport uzupełnia `docs/RESEARCH.md` (stan tego dokumentu: 04.11.2026), nie zmieniając go, ponieważ zlecenie ogranicza zapisy do `contrib/gpt/T07/`.

## Co zrobiłem

- Porównałem **29 tytułów** z grup: mobilny lockpicking, sejfy i gry haptyczne; audio-first / dostępność; PC symulatory zamków i zawodu ślusarza; benchmarki „cozy job sim”.
- Zestawiłem platformy, modele biznesowe, ceny z walutami i regionami, oceny z liczbą recenzji, **publiczne progi instalacji** (gdy istnieją), mechanizmy sprzężenia zwrotnego, dostępność bez wzroku oraz zalety/braki.
- Dla każdej pozycji dodałem bezpośredni URL źródła, datę i pole stopnia weryfikacji w CSV.
- Osobno oceniłem **kolizję nazwy Lockwright**: grę przeglądarkową `lockwright.app`, podobnie brzmiące oznaczenia LOCKWRITE/LOCKRIGHT, zawód ślusarza LockWright, dostępność domen, rejestry znaków i opłaty.
- Zdefiniowałem sekcję **„Luki rynkowe, które Lockwright zajmuje”** wraz z testami niezbędnymi do uczciwego deklarowania przewag.

## Pliki

| Plik | Zawartość |
|---|---|
| [`COMPETITORS-2026.md`](COMPETITORS-2026.md) | Pełna analiza 29 pozycji, rozróżnienie faktów i hipotez, luka rynkowa, sekcja nazwy/znaków/domen, źródła i daty. |
| [`competitors.csv`](competitors.csv) | 29 wierszy danych + nagłówki, 15 kolumn; UTF-8, przecinek i cytowane wartości dla importu do arkuszy. |
| [`README.md`](README.md) | Ten opis dostawy, ograniczenia i zalecane następne działania. |

**`ASSETS.md` nie utworzono:** nie powstały żadne grafiki, dźwięki ani inne wygenerowane zasoby. Brak plików binarnych.

## Kluczowe ustalenia i ostrzeżenia

1. **Unlokee** posiada już najbliższy Lockwright dwukciukowy rdzeń mechaniczny; nie można reklamować samego ruchu napinacza/wytrycha jako unikalnego.
2. **Vale & Daughter: Safecracker** deklaruje **Blind mode**, a **SafeCracker: Vault Puzzle** etykiety VoiceOver. Przewaga Lockwright wymaga rzeczywiście **całej gry przechodzalnej bez wzroku** z VoiceOver/TalkBack, a nie samego wygaszenia ekranu lub haptyki.
3. **Identyczna nazwa „Lockwright”** występuje według istniejącego researchu na `lockwright.app`. Kolizja marketingowa/ASO jest poważna; sytuacja prawna **nie została rozstrzygnięta**. Nie zgłaszać znaku przed niezależnym clearance.
4. **EUIPO SME Fund 2026 – Voucher 2**: oficjalna strona informuje, że nowe wnioski o wsparcie znaków/wzorów są obecnie zamknięte po wyczerpaniu środków. Nie planować refundacji bez ponownego sprawdzenia.
5. **Niespójność podtytułu EN** między zleceniem (`Locksmith on Call`) a repo `CLAUDE.md` (`Emergency Locksmith`). Ujednolicić przed zgłoszeniami i publikacją.

## Czego nie udało się wiarygodnie potwierdzić

- **Dokładne pobrania i sprzedaż**: brak ich w publicznych kartach iOS/Steam/itch.io. Podano `n/p` zamiast bezpodstawnych szacunków. Dla Androida użyto tylko publicznych progów instalacji Google Play. To nie są miesięczne pobrania ani aktywni gracze.
- **Bieżące zgłoszenia i statusy znaków** w oficjalnych bazach EUIPO/TMview, WIPO, BOIP, UKIPO, UPRP oraz kompleksowy aktualny clearance USPTO. Zapytanie USPTO „0 dokładnych LOCKWRIGHT” pochodzi **wyłącznie z bazowego researchu 04.11**, nie zostało samodzielnie potwierdzone w tym zadaniu.
- **Dostępność domen na 05.11**: tabela wskazuje wyraźnie stany z badania RDAP z **04.11**, a nie gwarantowany bieżący stan rejestracji. `lockwright.games`, `lockwright.eu` i Instagram pozostają nieustalone.
- **Realna gra bez wzroku i haptyka**: sprawdzono publiczne deklaracje sklepowe, ale nie instalowano aplikacji i nie przeprowadzono testów sprzętowych z użytkownikami.
- **Pełna populacja gier**: przegląd skupiał się na najbliższych rywalach i analogiach, nie jest kompletnym katalogiem sklepów.

## Rekomendowane dalsze działania (kolejność)

1. **Przed zapowiedzią nazwy**: wykonać ręczny / profesjonalny search w EUIPO/TMview, WIPO, BOIP, USPTO, UKIPO i UPRP dla klas 9 i 41, pomocniczo 28; zebrać dowody pierwszeństwa użycia `lockwright.app`. W równoległym wariancie przygotować 3–5 alternatywnych tytułów.
2. **Zweryfikować aktualne domeny u rejestratora**, nie na podstawie wczorajszego RDAP, i ujednolicić oficjalny podtytuł EN.
3. **Prototypować trudne sygnały gameplayu** (`binding` / `set` / `false_set` / `overset`) tak, by były czytelne bez samego koloru i bez haptyki.
4. **Przeprowadzić test całej pętli z niewidomymi graczami** na iOS/Android, VoiceOver/TalkBack, a także urządzeniami bez precyzyjnej haptyki.
5. **Zweryfikować ceny lokalne i konwersję** modelu bezpłatny rozdział + jednorazowy unlock; nie wyprowadzać forecastu sprzedaży z liczby recenzji konkurentów.

## Zakres zmian

Zmienione/utworzone **wyłącznie pliki w `contrib/gpt/T07/`**. Żadnych zmian w kodzie gry, dokumentach wspólnych, cudzych zasobach, historii gałęzi ani mechanikach nazwanych istniejących produktów.

Badanie informacyjne. Analiza ryzyka znaków towarowych i domen **nie zastępuje opinii prawnej**.
