# T02 — Korekta EN: interfejs, fabuła i sklep

Data: 2026-11-05. Wszystkie pliki zapisane wyłącznie w `contrib/gpt/T02/`.

## Praca wykonana

- Przegląd repo: `CLAUDE.md`, `docs/styles/realizm.md`, `docs/DESIGN.md`, `docs/HUD.md`, `game/i18n/strings.csv`, `game/i18n/content.csv`, `store/listing.md`, `docs/DECISIONS.md` i `docs/PROGRESSION.md`.
- Zrewidowano komplet **105 kluczy EN interfejsu** — proponowanych zmian: **38**; komplet **356 kluczy EN treści** — proponowanych zmian: **61**. Wiersze bez zmian pozostają jawnie w raportach. `en_old` jest dosłowną zawartością źródeł, a placeholdery i klucze nie zostały zmienione.
- Poprawiono opisy App Store i Google Play EN, zachowując limity długości i odrębny warunkowy wariant A.
- Przygotowano słowniczek **78 terminów** PL ↔ EN z definicjami.
- Nie modyfikowano żadnego pliku poza własnym katalogiem.

## Pliki

| Nazwa | Funkcja |
|---|---|
| `strings_en_reviewed.csv` | Wszystkie 105 klucze EN interfejsu w formacie `key,en_old,en_new,note` |
| `content_en_reviewed.csv` | Wszystkie 356 klucze EN fabuły, gabloty i nazw w tym samym formacie |
| `store_en_reviewed.md` | Pełne opisy EN obu sklepów i tabela długości |
| `GLOSSARY.md` | 78 terminów PL ↔ EN z definicjami i zasadami |
| `ASSETS.md` | Brak nowo utworzonych zasobów graficznych/dźwiękowych |
| `README.md` | Niniejszy raport |

## Krytyczne rozbieżności wejścia

1. `job.charleroi_letters.client`: wewnętrzny identyfikator `job.grandpa_chest` trafił do widocznego EN.
2. `job.charleroi_letters.situation`: EN twierdził, że kasetka nie jest do otwarcia; PL mówi, że obie strony chcą otwarcia.
3. `job.allotment_shed.situation`: EN błędnie sugerował pomidory w altanie, choć PL wymienia konewki, nasiona i działkę na żonę.
4. `job.grandpa_chest.situation`: przypuszczenie Oli o listach zostało podane jako pewnik.
5. `job.pizzeria_pays_pizza.situation`: EN stawiał akcję przed wieczornym ruchem, a PL mówi o 23:30 po zamknięciu.
6. `job.newlyweds_4am.situation`: EN przypisywał jazdę samochodem torebce świadkowej.
7. `job.finnish_sailor.note`: zamiast brzozowej chochli EN opisywał kubek.
8. `job.refuse_rush_bribe.situation`: EN dopisywał sprzeczność nazwisk w dowodzie, której PL nie zawiera.
9. `strings.csv`: niespójność 'run' z dyżurem ślusarza, mało diegetyczne 'lives', wieloznaczne 'dark mode'.
10. D-08 zezwala na historyczne nazwiska w notkach gabloty, nie na nazwy producentów fikcyjnych mechanizmów.

## Weryfikacja i ryzyka

- Sprawdzono wszystkie klucze i brak duplikatów; odtworzono CSV i porównano `key` i `en_old` z oryginałami; placeholdery `{n}`, `{0}` zachowano; policzono znaki i bajty pól sklepowych.
- **Nie testowano gry na urządzeniach ani rzeczywistego wydania 1.0.** Opisy są szkicem publikacyjnym, nie potwierdzeniem funkcji. Należy sprawdzić w buildzie: workshop, łamanie narzędzi, dłuższe serie, sygnały audio/wizualne/haptykę.
- D-06 nadal nierozstrzygnięta: wariant A (demo + jednorazowy zakup) nie powinien być publikowany bez decyzji. Umyślnie pominięto niezweryfikowane obietnice o reklamach, offline, danych użytkowników, kontach i zawartości po MVP.
- Dokumentacja `PROGRESSION.md` umieszcza Tryb Zleceń po MVP. `tutorial.done` zachowuje zapowiedź pierwszego zlecenia zgodnie z PL, lecz należy ją ukryć w MVP albo skorygować **w obu językach**.
- W `game/i18n/strings.csv` wartość PL pod `verify.card.bailiff` to nadal angielskie `Bailiff`; wymaga korekty przez właściciela pliku źródłowego.
- Nie prowadzono weryfikacji historycznej gabloty w źródłach pierwotnych. Zalecany osobny fact-check nazwisk i dat.

## Integracja przez właścicieli innych katalogów

1. Zatwierdzić i scalić tylko wiersze z `en_new != en_old`; skontrolować rozmiary etykiet na ekranach.
2. Przenieść zatwierdzone pola z `store_en_reviewed.md` do `store/listing.md`; uruchomić `python3 store/tools/check_lengths.py --no-write` po integracji.
3. Wykonać kontrolę zakresu 1.0, zgodności polityk sklepów oraz dostępności i zależności monetizacji.
