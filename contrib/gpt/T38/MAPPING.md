# T38 — mapowanie identyfikatorów zamków

Nowe pliki są w `contrib/gpt/T38/practice/`. Każdy ma nowe `id=practice.tNN`,
odpowiadające nazwie `tNN.json`, i `presentation.practice.order=NN`.
Identyfikatory `title_key` i `hint_key` pozostają **ze starego T20**, ponieważ
wskazują na istniejące tłumaczenia. Jedynie `goal_key` wskazuje na nowy
klucz `practice.t38.tNN.goal` z `practice_goals.csv`.

## Stary ID → nowy ID

| Stary | Nowy | P50 przed zmianami [s] | `lesson_target` |
|---|---|---:|---|
| `practice.t01` | `practice.t01` | 2.8 | `open` |
| `practice.t02` | `practice.t07` | 8.8 | `bind` |
| `practice.t03` | `practice.t04` | 6.1 | `bind` |
| `practice.t04` | `practice.t08` | 9.1 | `set` |
| `practice.t05` | `practice.t03` | 4.0 | `gate_align` |
| `practice.t06` | `practice.t02` | 3.2 | `gate_align` |
| `practice.t07` | `practice.t09` | 9.2 | `overset` |
| `practice.t08` | `practice.t15` | 14.9 | `overset` |
| `practice.t09` | `practice.t14` | 13.0 | `bind` |
| `practice.t10` | `practice.t12` | 11.9 | `set` |
| `practice.t11` | `practice.t05` | 6.3 | `ring.detent` |
| `practice.t12` | `practice.t18` | 15.5 | `bind` |
| `practice.t13` | `practice.t06` | 8.6 | `set` |
| `practice.t14` | `practice.t16` | 14.9 | `set` |
| `practice.t15` | `practice.t20` | 16.9 | `overset` |
| `practice.t16` | `practice.t17` | 15.4 | `bind` |
| `practice.t17` | `practice.t28` | 23.8 | `false_set` |
| `practice.t18` | `practice.t11` | 11.9 | `gate_align` |
| `practice.t19` | `practice.t10` | 9.2 | `set` |
| `practice.t20` | `practice.t25` | 21.2 | `false_set` |
| `practice.t21` | `practice.t23` | 18.1 | `counter_rotate` |
| `practice.t22` | `practice.t13` | 12.5 | `lever.false_gate` |
| `practice.t23` | `practice.t24` | 20.9 | `pin.serration` |
| `practice.t24` | `practice.t21` | 16.9 | `gate_align` |
| `practice.t25` | `practice.t26` | 15.7 | `false_set` |
| `practice.t26` | `practice.t27` | 22.2 | `lever.false_gate` |
| `practice.t27` | `practice.t22` | 17.9 | `detector_trip` |
| `practice.t28` | `practice.t19` | 15.5 | `detector.reset` |
| `practice.t29` | `practice.t30` | 26.5 | `set` |
| `practice.t30` | `practice.t29` | 26.4 | `detector_trip` |

## Kolejność nowego ścieżkowania

`01` ← `01` (2.8 s) · `02` ← `06` (3.2 s) · `03` ← `05` (4.0 s) · `04` ← `03` (6.1 s) · `05` ← `11` (6.3 s) · `06` ← `13` (8.6 s) · `07` ← `02` (8.8 s) · `08` ← `04` (9.1 s) · `09` ← `07` (9.2 s) · `10` ← `19` (9.2 s) · `11` ← `18` (11.9 s) · `12` ← `10` (11.9 s) · `13` ← `22` (12.5 s) · `14` ← `09` (13.0 s) · `15` ← `08` (14.9 s) · `16` ← `14` (14.9 s) · `17` ← `16` (15.4 s) · `18` ← `12` (15.5 s) · `19` ← `28` (15.5 s) · `20` ← `15` (16.9 s) · `21` ← `24` (16.9 s) · `22` ← `27` (17.9 s) · `23` ← `21` (18.1 s) · `24` ← `23` (20.9 s) · `25` ← `20` (21.2 s) · `26` ← `25` (15.7 s; po korekcie parametry wymagają ponownego pomiaru) · `27` ← `26` (22.2 s) · `28` ← `17` (23.8 s) · `29` ← `30` (26.4 s) · `30` ← `29` (26.5 s)

**Uwaga:** wartości P50 pochodzą z tabeli `lockcore/practice/README.md`
(przed poprawkami) i nie są wynikami testu nowych JSON-ów. Kolejność rośnie
niemalejąco według wyjściowego P50 poza starym t25, celowo przeniesionym
za trzy lekcje t4, bo jego parametry zostały wzmocnione. Nowe P50 i
monotoniczność wymagają pomiaru botami.
