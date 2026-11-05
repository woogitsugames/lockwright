# T38 — proponowane poprawki zamków treningowych

Status: **propozycja do weryfikacji botami lockcore** (sesja A). Oryginalne pliki
`lockcore/practice/*.json` nie są modyfikowane. Zawartość tego katalogu
jest kompletną alternatywą 30 zamków.

## Pliki

- `practice/t01.json`–`practice/t30.json` — pełne definicje `lockwright.lock/1`,
  nowe `id` i `presentation.practice.order`, pole `presentation.practice.lesson_target`.
- `practice_goals.csv` — dokładnie 30 krótkich celów EN/PL (do 80 znaków).
- `MAPPING.md` — mapowanie starych i nowych identyfikatorów, źródłowa mediana P50.

`lesson_target` należy do `presentation.practice`, nie do korzenia JSON-a:
`check_locks` porównuje wszystkie pola poza `presentation` z kanonicznym
wynikiem parsera i odrzuca nieznane pola. `focus` pozostaje opisem dydaktycznym,
a `lesson_target` jest **konkretną nazwą zdarzenia lockcore**. Dla takich
zdarzeń jak `ring.detent`, `pin.serration`, `lever.false_gate` i
`detector.reset` zastosowano nazwy subzdarzeń obsługiwane przez rodzinę.

`goal_key` przechodzi na unikatowe `practice.t38.tNN.goal` — brak kolizji
z `contrib/gpt/T20/practice.csv`. `title_key` i `hint_key` zachowują
identyfikatory T20, aby stare tytuły i wskazówki nadal działały. Przy migracji
do i18n należy zaimportować `practice_goals.csv`.

## 1. Nowa kolejność

Uporządkowano zamki po **P50 bota czującego sprzed zmian**, uzyskanym
w `lockcore/practice/README.md` (1000 prób). Usunięto odwrócone sąsiedztwa:
stare `t06` przed `t05`, `t10` przed `t09`, `t19` przed `t18`,
`t28` przed `t27`, `t21` i `t23` przed `t20`.

Wyjątkiem jest stary **t25 → nowy t26**: po podniesieniu trudności do
profilu tieru 5 umieszczono go za trzema zamkami pin-tumbler tieru 4
(stare t21/t23/t20; nowe t23/t24/t25), a przed starym t26.
Pierwotne P50 starego t25 to 15,7 s; P50 losowych zamków tieru 5 w
`BALANCE.md` wynosi 22,2 s. **22,2 s nie jest wynikiem nowego t25**,
a jedynie punktem odniesienia dla doboru parametrów. Trzeba wykonać
nowy pomiar i w razie potrzeby zmienić kolejność ponownie.

Ścieżka celowo przeplata rodziny i tiery: celem T38 jest globalnie rosnący
czas, nie monotoniczny numer tieru. Równe wartości P50 są dopuszczalne
jako niemalejące (9,2; 11,9; 14,9; 15,5; 16,9 s). Korekty parametrów
mogą zmienić mediany również pozostałych lekcji.

## 2. Zmiany parametrów — stare ID, nowe ID

| Stary → nowy | Zmiana | Uzasadnienie i przewidywany efekt |
|---|---|---|
| t07 → t09 | `overset_margin_q16` 4915 → **3277** (7,5% → 5%), w `spec` i `difficulty` | Mniejszy margines po ustawieniu płytki zwiększa szansę na `overset` przy zbyt długim nacisku. Cel wymaga świadomego przekroczenia kliku; bot czujący zwykle kończy wcześniej. |
| t08 → t15 | `overset_margin_q16` 4588 → **2949** (7% → 4,5%), w obu miejscach | Przepchnięcie łatwiej wywołać, a `t_release > t_hold` nadal pozwala je odblokować bez zrzucenia innych płytek. Sprawdzić odsetek otwarć. |
| t15 → t20 | `overset_margin_q16` 4588 → **3277** (7% → 5%), w obu miejscach | Jedna nadmierna poprawka ręki łatwiej blokuje stos i pokazuje powrót po zwolnieniu nacisku. |
| t22 → t13 | `spec.levers[0].false_gates_q16: [] → [23593]` | Fałszywa bramka pojawia się także na pierwszej wiążącej zapadce. Każda zapadka ma nadal co najwyżej jeden fałszywy rowek (tier 4); więcej okazji do `lever.false_gate` niż bazowe 62% u bota czującego. |
| t25 → t26 | `stacks` 5 → **6**, dodano standardowy stos `target=39977, order=32768, band_lo=16384`; `difficulty.n_min/n_max` 5 → 6 | Tier 5 dopuszcza 5–6 stosów; dodatkowy stos wymusza kolejny etap rozpoznawania oporu. |
| t25 → t26 | `win_shear_q16` 6226 → **5898**, `tension_band_q16` 12124 → **11796**, `overset_margin_q16` 5243 → **4588**; w `spec` i `difficulty` | Docelowo 9% / 18% / 7%: wartości tabeli pin-tumbler tier 5 z generatora (`BALANCE.md`, `pin_tumbler.cpp`). Węższe okno, trudniejszy nacisk i mniejszy margines przepchnięcia. |
| t25 → t26 | `noise_q16` 3932 → **6554** (6% → 10%) w obu miejscach; `drop_grace_ms` 210 → **200** i `drop_grace_steps` 25 → **24** | Profil tieru 5: mniej czytelne wskazówki i krótsza tolerancja przerwania nacisku; nadal spójne 120 Hz. |
| t27 → t22 | `win_shear_q16` 6226 → **5898** (`difficulty`) i `win_gate_q16` 6226 → **5898** (`spec`); `detector_margin_q16` 6554 → **6095** (10% → 9,3%) | Mniej bezpiecznego skoku nad bramką. Detektor pozostaje powyżej marginesu `overset` 5898 (9%), więc przy kontrolowanym ruchu najpierw pojawia się ostrzeżenie o przepchnięciu. |
| t28 → t19 | `detector_margin_q16` 6554 → **5898** (10% → 9%), `reset_steps` 180 → **150** (1,5 s → 1,25 s) | Większa szansa na zdarzenie i szybszy świadomy reset; margines detektora wciąż przekracza `overset_margin` 5571 (8,5%). |
| t30 → t29 | `detector_margin_q16` 5439 → **5374** (8,3% → 8,2%); `reset_steps` 300 → **240** (2,5 s → 2 s); `max_trips` 3 → **4** | Delikatnie łatwiejsze wywołanie zdarzenia, krótszy powrót i dodatkowa próba chronią przed zamknięciem ćwiczenia po trzecim sygnale. `5374 > overset_margin=5243` (8%), zachowuje rozdział progów. Odstęp jest mały — konieczna weryfikacja. |

W pozostałych 22 plikach nie zmieniono parametrów symulacji. Wszystkie 30
otrzymały nowe `id`, `order`, `goal_key` i `lesson_target`.
Pozostałe klucze `spec` i `difficulty` pozostawiono bez zmian.

## 3. Cele zdarzeń i ograniczenia

- `overset` dla dawnych t07, t08 i t15; `detector_trip` dla t27/t30;
  `detector.reset` dla t28; `lever.false_gate` dla t22.
- Pozostałym lekcjom przypisano zdarzenia rzeczywiście obsługiwane
  przez ich rodzinę (`bind`, `set`, `open`, `gate_align`,
  `false_set`, `counter_rotate`, `ring.detent`, `pin.serration`).
  Pełna tabela: `MAPPING.md`.
- Nawet po zmianie progów **bot czujący może poprawnie otworzyć zamek
  bez przepchnięcia i bez tripu**. Tego nie da się zagwarantować
  samym JSON-em bez sterowania próbą. Dlatego teksty dawnych
  t07/t08/t15/t27/t28/t30 każą graczowi raz sprowokować zdarzenie.
- Warunek w `check_locks.cpp` (D-52) sprawdza **clumsy target ≥30%**
  i **feeling open ≥95%** osobno; częstotliwości `focus seen` z
  `lockcore/practice/README.md` opisują bota czującego i **nie są**
  tym samym miernikiem.

## 4. Protokół walidacyjny dla sesji A

1. Zbudować aktualne `lockcore` i uruchomić w katalogu repo:
   ```bash
   cmake -S lockcore -B lockcore/build -G Ninja
   cmake --build lockcore/build
   lockcore/build/check_locks --feel 1000 --csv /tmp/t38-results.csv contrib/gpt/T38/practice/*.json
   ```
2. `check_locks` kontroluje składnię, parsowanie `lockwright.lock/1`,
   kanoniczny round-trip, oracle, scripted bot, clumsy event ≥30%
   i feeling open ≥95%. Dopiero kod wyjścia 0 potwierdza bramki.
3. Sprawdzić monotoniczność po nowych ID na `feel_p50_steps`:
   ```bash
   python3 - <<'PY'
   import csv
   rows = sorted(csv.DictReader(open('/tmp/t38-results.csv', newline='')),
                 key=lambda r: r['id'])
   pairs = [(a['id'], b['id'], a['feel_p50_steps'], b['feel_p50_steps'])
            for a, b in zip(rows, rows[1:])
            if int(b['feel_p50_steps']) < int(a['feel_p50_steps'])]
   print('inwersje:', pairs)
   raise SystemExit(bool(pairs))
   PY
   ```
4. Jeżeli wynik nie spełnia progów, stroić **tylko konkretne**
   `spec` i odpowiadające mu wspólne wartości `difficulty`, po każdej
   próbie powtórzyć test na 1000 nasionach. Przy zmianie median
   skorygować mapowanie, `id`, `order` i wszystkie `goal_key`.
5. Zweryfikować import `practice_goals.csv` i wyświetlenie starych
   `title_key`/`hint_key` z T20 przy nowych `id`.

**Ograniczenie tego oddania:** nie uruchomiono botów po modyfikacjach
w tej sesji. Wszystkie wartości docelowych odsetków i nowe mediany
pozostają hipotezą, nie potwierdzonymi wynikami. Zamierzoną rolą T38
jest umożliwienie szybkiej, odtwarzalnej weryfikacji w sesji A.
