# Odbiór T42 (ChatGPT): teksty 8 nowych rodzin, lekcje, gablota

**Data:** 2026-11-06 · **Odbiera:** sesja A (Claude) · **Brief:** `docs/handoff/gpt5/T42-new-family-texts.md`
**Dostawa:** `contrib/gpt/T42/` (ZIP właściciela identyczny z `main`, patrz `REVIEW-T41.md`).

## Werdykt
**Przyjęte z poprawkami, zintegrowane w grze.** Limity znaków spełnione, „pin”/„kołek” zgodnie z regułą
(kołek tylko w `egyptian`), zero marek, `time_lock` wszędzie jako naprawa, każda podpowiedź mówi, co robi kciuk.
Źródła nowych notek sprawdzone (niżej).

## Poprawki w `family_texts.csv` (80 wierszy, było 78)
| Klucz | Problem → poprawka |
|---|---|
| `lock.dial_safe_hint_auto`, `lock.disc_detainer_hint_auto` | nazwa niezgodna z kluczem bazowym (`lock.dial_hint`, `lock.disc_hint`) → **`lock.dial_hint_auto`, `lock.disc_hint_auto`**; reguła: wariant auto = `<klucz podpowiedzi>_auto` |
| `time_lock` bez `_auto` | W grze tryb „Napięcie automatyczne” trzyma lewy kciuk **także** w `time_lock` (`InputSampler.auto_level`), więc „lewym nakręcaj” byłoby nieprawdą. Dodane `lock.time_lock_hint_auto` i `tutorial.time_lock.step1_auto` („Gra nakręca sprężynę…”). |
| `family.combo.name` EN | „Wheel lock” to w angielskim zamek kołowy broni palnej → **„Thumbwheel lock”** |
| `family.dimple.name` DE | „Bohrmuldenschloss” → **„Bohrmuldenzylinder”** (termin branżowy) |
| `family.dial_safe.*`, `lock.dial_hint*`, `tutorial.dial_safe.step1_auto/2` DE | „Rad” znaczyło raz pokrętło, raz koło → pokrętło = **„Drehscheibe”** (jak w `content.csv`), koła = „Räder” |
| `family.dimple.short` | „jeden skrywa pin” niejasne (rząd?) → „Dwa rzędy pinów; niektóre kryją węższy pin w tulei.” (EN/DE analogicznie) |
| `family.disc_detainer.short` EN | „Inside the game lock…” → „A stack of discs; each one turns on its own.” (PL/DE analogicznie) |
| `family.time_lock.short` DE | „braucht Pflege” → „wird repariert, nicht geöffnet” |
| `tutorial.dial_safe.step3` PL | „Usłysz cichy tik” (tryb rozkazujący od „usłyszeć”) → „Słuchaj cichego tyknięcia: rusza następne koło.” |
| `tutorial.dial_safe.step4` PL | „Minąłeś bramkę?” — rodzaj męski gracza → „Bramka za tobą? Zrób jeszcze obrót i stań.” |
| `tutorial.combo.step3` | krok 3 ma mówić, jak wygląda opór; „klik = wcięcie minęło” mylił z pułapką → „Jedno kółko stawia opór i klika we wcięciu.” (EN/DE) |
| `tutorial.disc_detainer.step3` | „Feel a small seat” → „A slight give and a clear click: it's in place.” (PL/DE) |
| `lock.combo_hint`, `lock.disc_hint`, `lock.egyptian_hint`, `lock.time_lock_hint` EN | „Pull lightly left” czytało się jak „ciągnij w lewo” → „Left pulls lightly; right rolls…” (kciuk jako podmiot, jak PL) |
| `tutorial.magnetic.step4` EN | „do not jerk” → „don't jerk” |

Walidator dostawy `validate_delivery.py` zaktualizowany do tych reguł (80 wierszy, `<hint>_auto` także dla
`time_lock`): **0 błędów, 0 ostrzeżeń**.

## Gablota
- **Źródła sprawdzone 2026-11-06:** `combo` — Museum Wales: zamek z czterema obracanymi pierścieniami z literami,
  znalezisko przy wraku z 1583 r., strona wspomina liczne XVI-wieczne zamki szyfrowe — zgodne z notką.
  `magnetic` — US 2010/0050715 A1 „Magnetic coded lock mechanism”, publikacja 2010-03-04, piny + ruchome magnesy
  — zgodne; URL zmieniony na kanoniczny `…/US20100050715A1/en`. `dimple` — LockWiki, bez daty, notka jej nie podaje — OK.
- **Błąd odblokowania:** `showcase.combo` miał w `unlocks` dwa tokeny `job.*`, a ekran gabloty (N-40) wymaga
  **wszystkich** → notka otwierałaby się dopiero po kapsule czasu (T3). Zostaje tylko `job.bike_interview`.
- **Istniejące notki:** `bramah_window` nie miała żadnego tokenu `job.*`, więc była zawsze odblokowana → dostała
  `job.bramah_bureau` (zlecenie z biurkiem Bramaha, które obiecuje tę historię). Opisy tierów w `unlocks`
  pięciu notek (egyptian T1, disc T2, time_lock T2, dial_safe T1 + T2, axial_slider T2) poprawione do tabeli zleceń;
  tier w tekście nie jest w backtickach, więc nie zmienia logiki.
- Treść pięciu starych notek pasuje do rodzin (zgadzam się z tabelą w README dostawy).
- Pliki: `game/data/showcase/showcase.{combo,dimple,magnetic}.json`; teksty (tytuł, opis, źródło) w `content.csv`.
  Zdjęć G16 dla trzech nowych notek brak — karta pokazuje sam tekst (jak wcześniej bez zdjęcia).

## Integracja w grze
- `game/i18n/strings.csv`: `family.<id>.name/.short`, `lock.<id>_hint` (+`_auto`), `tutorial.<id>.step1–5`
  (+`step1_auto`) dla 8 rodzin. **Uzgodnienie istniejących kluczy:** `lock.dial_hint`, `lock.combo_hint`,
  `lock.disc_hint` zostały (nie dubluję `lock.dial_safe_hint` itd.), wartości EN/PL/DE zastąpione wersją T42
  (oba kciuki), FR/ES przetłumaczone na nowo (T41).
- **Gdzie gra je czyta:** `lock_job.gd` `family_hint_key()` + `_show_family_hint()` — jedna podpowiedź kredą
  przez pierwsze 6 zleceń, wariant `_auto` w trybie automatycznym, dla **wszystkich 8 rodzin**
  (wcześniej tylko dial/combo/disc w `planb_family_job.gd`, bez wariantu auto; teraz jedna ścieżka dla wszystkich). Widoki `pin_family_view` (dimple, magnetic)
  dostały `set_hint()` przez nowy hak `_chalk_line()` w `lock_photoreal_view.gd` (podpowiedź tylko, gdy nie ma linii
  trenera, nic nie jest ustawione i zamek zamknięty — jak w pozostałych widokach).
- `family.*` i `tutorial.<id>.step*` są w CSV, ale **gra ich jeszcze nie wyświetla**: nie ma listy rodzin
  w UI ani pierwszej lekcji dla nowych rodzin (`TutorialCoach` zna tylko pin/wafer/lever/warded). Kroki
  i `LESSONS.md` to gotowy materiał do zbudowania lekcji (osobne zadanie).
- `LESSONS.md` przyjęte jako specyfikacja; jedna korekta: w `time_lock` tryb automatyczny **przejmuje**
  nakręcanie (patrz wyżej), więc zdanie „przy naprawie zegara nakręcanie pozostaje działaniem gracza” jest
  nieaktualne wobec obecnej implementacji.
- FR/ES dla kluczy T42: brak (zakres T42 to EN/PL/DE) — 86 kluczy do zlecenia (patrz `REVIEW-T41.md`).

## Testy
GUT 205/205 (nowe: klucze podpowiedzi 8 rodzin × auto, długość ≤ 56, obecność kroków i nazw),
`tools/i18n_lint.py` 0 błędów, `data/tools/validate.py` i `loc_qa.py` OK, smoke OK.
