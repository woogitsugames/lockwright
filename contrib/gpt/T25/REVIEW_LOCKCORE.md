# T25 — Przegląd kodu `lockcore` (C++20)

**Data:** 2026-11-05  
**Repozytorium:** `woogitsugames/lockwright`, `main`  
**Zakres:** `lockcore/include/`, `lockcore/src/` (7 rodzin / 6 implementacji), `lockcore/tests/`, `lockcore/tools/`, `CMakeLists.txt` i dokumentacja projektu.  
**Metoda:** statyczna inspekcja kodu źródłowego i istniejących testów, bez zmian w `lockcore`. **Nie wykonywano** kompilacji, sanitizerów ani benchmarków: lokalna próba pobrania repozytorium nie przeszła z powodu niedostępnego DNS. Nie przypisuję usterkom statusu „reprodukowanej awarii” bez uruchomienia testu.

## Podsumowanie

**24 uwagi**: 14 o priorytecie P1, 9 P2 i 1 P3. Priorytet P1 oznacza błąd istotny przy niepoprawnych/zewnętrznych danych lub naruszenie kontraktu weryfikacji; nie oznacza, że zwykła rozgrywka zawsze się wywraca. Źródła problemów grupują się wokół **brakującej granicy zaufania na wejściu do `LockSession`**, **niedostatecznej walidacji plików replay** oraz **przypadków granicznych arytmetyki 32/64-bitowej**. Dodatkowo metryka naprężenia może być resetowana przez operację zużycia narzędzia.

W istniejącym kodzie widać istotne zabezpieczenia: PCG32 ma wektor referencyjny, FNV-1a jest karmiony polami w little-endian, JSON przechowuje Q16 jako liczby całkowite, są testy golden, fuzz 100k kroków/rodzinę, ASan/UBSan w CI oraz osobne workflow porównujące replaye Linux x86_64/arm64, Android i macOS. **Nie stwierdzono potwierdzonego wycieku pamięci.** Brak `float` w ścieżce symulacji nie usuwa jednak UB i konwersji zależnych od implementacji.

### Skala priorytetów
- **P1:** poprawić przed wpuszczeniem niezaufanych plików lub przed uznaniem wyniku weryfikatora za wiarygodny.
- **P2:** naprawić przed stabilizacją schematu replay i bitowej zgodności platform.
- **P3:** utwardzenie narzędzi/raportowania.

## Ustalenia (każde z lokalizacją, ryzykiem i proponowanym diffem)

### T25-01 [P1] Brak egzekwowania posiadanych narzędzi w symulacji
**Plik:linia:** `lockcore/src/session.cpp:14-21, 31-36`; przykładowo `lockcore/src/families/warded.cpp:177-193` i `lockcore/src/families/wooden_pin.cpp:126-136`.  
**Opis:** `LockSession` zapisuje `ToolSet` i umieszcza `ctx.tools` w `StepCtx`, ale żadna z rodzin nie używa `ctx.tools`. Weryfikację wyposażenia wykonuje `oracle()`, nie `step()`. W efekcie publiczna sesja skonstruowana z `ToolSet{}` może symulować nawet rodzinę wymagającą `TOOL_WARD_PROBE` lub `TOOL_PEG_LIFTER`. Testy rodzin korzystają z domyślnego `LockSession(..., ToolSet{})`, więc nie wykrywają tej różnicy.  
**Ryzyko:** ominięcie progresji wyposażenia; replay akceptuje działania bez wymaganych narzędzi.  
**Proponowany diff:**
```diff
--- a/lockcore/src/session.cpp
+++ b/lockcore/src/session.cpp
@@ konstrukcja lub walidowana fabryka sesji
+ if (!tools_.has(family_.required_tools(spec_).bits))
+   throw std::invalid_argument("missing required tools");
```
Po wyborze strategii błędów bez wyjątków użyć wyniku fabryki; dodać test dla wszystkich rodzin i `ToolSet{0}`.

### T25-02 [P1] `LockSession` dereferencjonuje niewalidowany blok parametrów
**Plik:linia:** `lockcore/src/session.cpp:14-21`, `lockcore/src/families/pin_tumbler.cpp:163-168`; analogicznie `lever.cpp:170-175`.  
**Opis:** konstruktor wywołuje `family.init_state(spec_)` bez `family.validate(spec_)`. Implementacje stosują `static_pointer_cast<const Params>` do `spec.params` i dereferencję. Brak parametrów lub parametry innej rodziny prowadzą do dereferencji null / niezdefiniowanego zachowania. `lock_from_json()` waliduje, ale publiczne API i `run_replay()` nie wymuszają jego użycia.  
**Ryzyko:** crash/UB przy wywołaniu z zewnętrznego kodu lub danych.  
**Proponowany diff:**
```diff
--- a/lockcore/src/session.cpp
+++ b/lockcore/src/session.cpp
@@ inicjalizacja
- state_(family.init_state(spec_)),
+ state_(nullptr),
@@ body
+ const auto errors = family_.validate(spec_);
+ if (!errors.empty()) throw std::invalid_argument(errors.front().message);
+ state_ = family_.init_state(spec_);
```
Dla buildów bez wyjątków preferowana fabryka `expected<LockSession, SpecError>`.

### T25-03 [P1] Generator zwraca niezaakceptowany zamek po 16 próbach
**Plik:linia:** `lockcore/src/families/pin_tumbler.cpp:105-111`; ten sam wzorzec w `wafer.cpp:81-87`, `wooden_pin.cpp:78-84`, `lever.cpp:113-119`, `warded.cpp:127-133`, `ring_combo.cpp:95-101`.  
**Opis:** po 16 negatywnych wynikach `oracle()` funkcja nadal zwraca ostatni `spec`. Dla dowolnych `DifficultyVector` podanych przez API (np. `win_shear=0`) gwarancja „generated = solvable” jest fałszywa. `run_replay` traktuje wynik jako poprawny.  
**Ryzyko:** niespełniona twarda bramka, potencjalna symulacja specyfikacji, której wyrocznia odmawia.  
**Proponowany diff:**
```diff
@@ w każdym generate()
- if (oracle(spec, required_tools(spec)).ok) break;
+ if (oracle(spec, required_tools(spec)).ok) return spec;
@@ po pętli
- return spec;
+ throw std::runtime_error("generation exhausted 16 attempts");
```
Alternatywa: typ `Result<LockSpec, GenerationError>`, propagowany do replay i bridge'u Godot.

### T25-04 [P1] Seed powtórki jest liczony bez kontroli znaków i zakresu
**Plik:linia:** `lockcore/src/replay.cpp:105-107` kontra poprawny parser w `lockcore/src/lockfile.cpp:60-70`.  
**Opis:** parser replay nie sprawdza, czy seed składa się z cyfr, nie wykrywa overflow `uint64_t` ani pustego napisu. Mnożenie zawija się modulo 2^64; np. znak spoza `0..9` uczestniczy w obliczeniach.  
**Ryzyko:** różne ziarno niż deklarowane, błędna identyfikacja replay, myląca diagnostyka.  
**Proponowany diff:**
```diff
- out.seed = 0;
- for (char c : seed) out.seed = out.seed * 10 + static_cast<std::uint64_t>(c - '0');
+ if (!parse_u64_decimal(seed, out.seed))
+   errs.push_back({"seed", "invalid decimal uint64"});
```
Przenieść istniejący sprawdzony algorytm z `lockfile.cpp` do współdzielonego helpera.

### T25-05 [P1] UB podczas dekodowania jednostek Q16 z replay
**Plik:linia:** `lockcore/src/replay.cpp:120-139` (zwłaszcza 133-137).  
**Opis:** `it[k].as_int() * 256` jest liczone jako `int64_t` bez limitu wartości. Wystarczy poprawna składniowo liczba poza `INT64_MAX/256`, żeby wywołać signed overflow (UB). Następny `static_cast<q16>` może też konwertować wartość niemieszczącą się w `int32_t` zależnie od implementacji.  
**Ryzyko:** awaria pod UBSan, niespójności między platformami, uszkodzona powtórka.  
**Proponowany diff:**
```diff
- f.tension = static_cast<q16>(it[1].as_int() * kUnit);
+ if (!in_units_range(it[1].as_int(), 0, Q16_ONE / kUnit))
+   return fail_replay(error, "tension: out of range");
+ f.tension = static_cast<q16>(it[1].as_int() * kUnit);
```
Analogicznie dla czterech pozostałych osi; sprawdzić zakres **przed** mnożeniem.

### T25-06 [P1] Dekompresja RLE replay bez globalnego limitu pamięci
**Plik:linia:** `lockcore/src/replay.cpp:115-139`.  
**Opis:** pojedynczy `run` może mieć 100 000 000 klatek, a każda kolejna linia RLE dodaje kolejne tyle; `vector::insert` przyjmuje wszystko. Limit per rekord nie chroni całkowitej liczby klatek.  
**Ryzyko:** DoS/out-of-memory podczas otwierania obcego replay.  
**Proponowany diff:**
```diff
+ constexpr std::size_t MAX_REPLAY_STEPS = 3600u * SIM_HZ;
+ const auto count = static_cast<std::size_t>(run);
+ if (count > MAX_REPLAY_STEPS - out.inputs.size())
+   return fail_replay(error, "inputs: total frame limit exceeded");
- out.inputs.insert(out.inputs.end(), static_cast<std::size_t>(run), f);
+ out.inputs.insert(out.inputs.end(), count, f);
```
Limit dobrać do kontraktu produktu, a parser dodatkowo ograniczyć rozmiarem pliku i liczbą rekordów.

### T25-07 [P2] Replay przyjmuje niedozwolone osie i zawija identyfikator narzędzia
**Plik:linia:** `lockcore/src/replay.cpp:132-139` oraz `lockcore/src/session.cpp:36`.  
**Opis:** nie ma sprawdzenia zakresu `tension/depth/push` 0–1, `lift/rotate` −1..1 ani `tool` 0–255. `tool=256` staje się 0, za duża oś bywa obcięta albo później cicho skwantyzowana przez `LockSession::step`.  
**Ryzyko:** niejednoznaczność formatu, nielokalne błędy replay, możliwość zaakceptowania pliku o innym znaczeniu niż autor zamierzał.  
**Proponowany diff:**
```diff
- f.tool = static_cast<std::uint8_t>(it[6].as_int());
+ if (it[6].as_int() < 0 || it[6].as_int() > UINT8_MAX)
+   return fail_replay(error, "tool: out of range");
+ f.tool = static_cast<std::uint8_t>(it[6].as_int());
+ if (quantize(f) != f) return fail_replay(error, "non-canonical input");
```
Kontrola kanoniczności następuje po bezpiecznym zdekodowaniu osi.

### T25-08 [P1] Nieobowiązkowe krytyczne pola nagłówka i `expected`
**Plik:linia:** `lockcore/src/replay.cpp:98-109, 141-152`.  
**Opis:** brak `difficulty` nie powoduje błędu; brak całego `expected` lub jego `event_hash_fnv1a64` także. `input_unit` i `input_fields` nigdy nie są sprawdzane. Co więcej, parser wypełnia przekazany `out` w trakcie walidacji zamiast pracować na tymczasowym obiekcie.  
**Ryzyko:** akceptacja niepełnych/niezgodnych replay i użycie wartości domyślnych lub starych pól; cichy zjazd schematu danych.  
**Proponowany diff:**
```diff
- if (const Value* d = v.find("difficulty")) difficulty_from_json(*d, out.difficulty, errs);
+ if (const Value* d = v.find("difficulty")) difficulty_from_json(*d, tmp.difficulty, errs);
+ else errs.push_back({"difficulty", "missing"});
+ require_literal(v, "input_unit", "1/256", errs);
+ require_input_fields(v, errs);
- if (const Value* e = v.find("expected"); e != nullptr && e->is_object()) {
+ if (const Value* e = v.find("expected"); e != nullptr && e->is_object()) {
@@
+ } else errs.push_back({"expected", "missing"});
```
Dodać wymagany `event_hash_fnv1a64` i `out = std::move(tmp)` tylko po braku błędów.

### T25-09 [P1] `replay_tool play` sprawdza jedynie hash
**Plik:linia:** `lockcore/tools/replay_tool.cpp:238-246`.  
**Opis:** plik zawiera `expected.steps` i `expected.open`, ale polecenie `play` porównuje wyłącznie FNV. Testy golden porównują wszystkie trzy pola (`tests/test_replay.cpp:65-71`), co pokazuje rozbieżność kontraktu.  
**Ryzyko:** narzędzie raportuje „matches” i kod 0 mimo rozbieżności liczby kroków lub nieprawdziwego oczekiwanego otwarcia.  
**Proponowany diff:**
```diff
- const bool match = res.hash == rp.expected_hash;
+ const bool match = res.hash == rp.expected_hash &&
+                    res.steps == rp.expected_steps &&
+                    res.open == rp.expected_open;
```
To samo ujednolicić w `trace` (linia 166-172) i wypisać, które pole nie pasuje.

### T25-10 [P1] `verify_seeds --seeds 0`/ujemne przechodzi bez testu
**Plik:linia:** `lockcore/tools/verify_seeds.cpp:69-97, 122-123, 259-260`.  
**Opis:** `std::atoll` nie kontroluje poprawności ani dodatniości `--seeds`. Dla 0 lub liczb ujemnych pętla nie rusza, `total_failures==0` i proces zwraca sukces.  
**Ryzyko:** fałszywa pozytywna bramka CI lub ręcznego audytu.  
**Proponowany diff:**
```diff
- if (a == "--seeds") n_seeds = std::atoll(next().c_str());
+ if (a == "--seeds" && !parse_positive_i64(next(), n_seeds))
+   return usage_error("--seeds must be a positive integer");
```
Tak samo walidować `--replays >= 0` i `--feel >= 0` z osobną semantyką domyślną.

### T25-11 [P1] Niewystępująca rodzina/tier daje weryfikatorowi kod sukcesu
**Plik:linia:** `lockcore/tools/verify_seeds.cpp:112-116, 251-260`.  
**Opis:** `--family does_not_exist` lub `--tier 999` usuwa wszystkie przebiegi, ale brak sprawdzenia, czy cokolwiek uruchomiono.  
**Ryzyko:** green build mimo zerowej liczby sprawdzonych zadań.  
**Proponowany diff:**
```diff
+ std::int64_t selected_tiers = 0;
@@ po filtrach tieru
+ ++selected_tiers;
@@ przed return
+ if (selected_tiers == 0) {
+   std::fprintf(stderr, "no family/tier selected\n");
+   return 2;
+ }
```

### T25-12 [P2] Próbka seedów weryfikatora zawęża `uint64` do 48 bitów
**Plik:linia:** `lockcore/tools/verify_seeds.cpp:57-58`.  
**Opis:** maska `& 0xffffffffffffULL` odcina 16 najstarszych bitów po SplitMix64. Generator i zapis seedów deklarują pełne 64 bity; bramka A3 nie bada wielu istotnych stanów wejścia.  
**Ryzyko:** niedoszacowane pokrycie błędów zależnych od górnych bitów seeda.  
**Proponowany diff:**
```diff
- return splitmix64(0x4c4f434bULL + i) & 0xffffffffffffULL;
+ return splitmix64(0x4c4f434bULL + i);
```
Po zmianie porównać metryki i odtworzyć regresyjne seed-listy.

### T25-13 [P2] Ścieżka `verify_seeds` nie sprawdza zapisanego `expected`
**Plik:linia:** `lockcore/tools/verify_seeds.cpp:142-159`.  
**Opis:** obiekt `Replay rp` dostaje inputy i parametry, ale nie `expected_hash`/`expected_steps`/`expected_open`. Serializator zapisuje zera i false; weryfikator porównuje hash replaya wyłącznie z osobnym `SolveReport`. Prawidłowo sprawdza deterministyczne odtworzenie, ale **nie** pełen round-trip pól oczekiwanych.  
**Ryzyko:** regresja serializacji metadanych golden może pozostać niewykryta.  
**Proponowany diff:**
```diff
  rp.inputs = r.inputs;
+ rp.expected_hash = r.event_hash;
+ rp.expected_steps = r.steps;
+ rp.expected_open = true;
@@ po replay_from_json
+ if (parsed.expected_hash != r.event_hash ||
+     parsed.expected_steps != r.steps || !parsed.expected_open)
+   { fail(seed, "replay expected metadata mismatch"); continue; }
```

### T25-14 [P1] Bot czujący omija walidację specyfikacji i wyposażenia
**Plik:linia:** `lockcore/src/bot.cpp:565-581`, `lockcore/src/families/warded.cpp:434-445`, `lockcore/src/families/ring_combo.cpp:379-390`.  
**Opis:** bazowy `FamilyModule::run_bot(BotKind::feeling)` wywołuje `run_feel_bot` bez `oracle/validate`. Dwie rodziny specjalne wprost przepuszczają bot czujący przy `!o.ok`, w tym przy brakujących narzędziach lub niewalidowanych parametrach.  
**Ryzyko:** nieporównywalna miękka metryka, możliwy UB w `init_state` przy błędnym `spec`.  
**Proponowany diff:**
```diff
- if (!o.ok && kind != BotKind::feeling) {
+ if (!o.ok) {
@@ bot.cpp, przed switch(kind)
+ if (!validate(spec).empty() || !tools.has(required_tools(spec).bits))
+   return SolveReport{.reason = "invalid spec or missing tools"};
```
Zachować brak *bramkowania wyniku sukcesu* feeling, ale nie dopuszczać błędnego wejścia.

### T25-15 [P1] Reset detektora kasuje historię maksymalnego stresu
**Plik:linia:** `lockcore/src/families/lever.cpp:194-206`, `lockcore/include/lockcore/components.hpp:67-68`, `lockcore/src/components.cpp:5-19`.  
**Opis:** po udanym resecie `S.tool.set_wear(S.tool.wear() + P.reset_wear)` wywołuje `ToolStress::init`. To resetuje nie tylko `wear`/`s_max`, ale `s_`, `wear_acc_`, `peak_ratio_` i historię ostrzeżeń. Bot odczytuje `session.state().tool.peak_ratio()` dopiero na koniec, więc wcześniejszy pik znika z metryki limitu `S < 0.8 S_max`.  
**Ryzyko:** zafałszowana bramka stresu dla `lever_detector`, reset zamiast naturalnego spadku obciążenia.  
**Proponowany diff:**
```diff
- S.tool.set_wear(S.tool.wear() + P.reset_wear);
+ S.tool.add_wear_preserving_stress(P.reset_wear);
```
Nowa operacja przelicza limit po zużyciu, ale zachowuje `s_`, `peak_ratio_` i licznik zużycia; test: „peak przed/po reset identyczny”.

### T25-16 [P2] Jedna klatka może zakończyć się zarazem `open` i `break`
**Plik:linia:** `lockcore/src/families/pin_tumbler.cpp:344-353`, `wafer.cpp:233-240`, `lever.cpp:364-372`.  
**Opis:** rodziny ustawiają `S.open=true` i emitują `open` **przed** `S.tool.end_step()`; ten sam krok może potem ustawić `FailureKind::break_`. Kontrakt końcowego stanu (`LockSession::finished()`) nie określa, czy sukces i porażka mogą współistnieć.  
**Ryzyko:** sprzeczny wynik sesji, różne interpretacje w interfejsie/replay/haptyce.  
**Proponowany diff:**
```diff
- // 5. Open.
- if (...) { S.open = true; emit_open(...); }
  S.tool.end_step(t, out, pick, MaterialId::steel);
  if (S.tool.broken()) S.failure = FailureKind::break_;
+ if (S.failure == FailureKind::none && ...) {
+   S.open = true;
+   emit_open(...);
+ }
```
Przed zmianą ustalić regułę „break ma pierwszeństwo”; zmiana kolejności hashy wymaga `rules_version` i regeneracji golden.

### T25-17 [P1] `q16_ratio`: signed overflow i dzielenie przez zero
**Plik:linia:** `lockcore/include/lockcore/fixed.hpp:23-26`.  
**Opis:** `num * Q16_ONE` jest wykonywane w `int64_t` bez weryfikacji mnożenia, `den` może wynosić 0, a końcowe rzutowanie na `q16` nie sprawdza zakresu. Publiczny helper nie ma formalnie ograniczonej domeny argumentów.  
**Ryzyko:** UB i niedeterministyczne wyniki przy niepoprawnych parametrach.  
**Proponowany diff:**
```diff
- return static_cast<q16>((num * Q16_ONE) / den);
+ // Sprawdzić den!=0 i num w [INT64_MIN/Q16_ONE, INT64_MAX/Q16_ONE]
+ // przed mnożeniem; wynik zweryfikować na przedziale int32.
+ return checked_ratio_to_q16(num, den);
```
`checked_ratio_to_q16` musi zwracać jawny błąd lub kontrolowaną saturację; testy wartości granicznych.

### T25-18 [P2] `ToolStress::ratio` obcina wynik do int32 przed ograniczeniem do 1
**Plik:linia:** `lockcore/include/lockcore/components.hpp:76-80`, `lockcore/include/lockcore/fixed.hpp:33-35`.  
**Opis:** `q_min(Q16_ONE, q_div(s_, s_max_))` wywołuje wcześniej `q_div` zwracający `int32_t`. Przy małej, legalnej dodatniej `s_max_` i dużym `s_` wynik dzielenia nie mieści się w `int32_t`. Rzutowanie jest zależne od implementacji, a obcięcie odbywa się za późno.  
**Ryzyko:** błędny lub nawet ujemny stres, błędy `peak_ratio` i progów.  
**Proponowany diff:**
```diff
- q16 ratio() const { return s_max_ > 0 ? q_min(Q16_ONE, q_div(s_, s_max_)) : 0; }
+ q16 ratio() const {
+   if (s_max_ <= 0) return 0;
+   if (s_ >= s_max_) return Q16_ONE;
+   return q_max(0, q_div(s_, s_max_));
+ }
```

### T25-19 [P2] `q_abs(INT32_MIN)` powoduje UB
**Plik:linia:** `lockcore/include/lockcore/fixed.hpp:40`.  
**Opis:** negacja `INT32_MIN` nie mieści się w `int32_t`. Publiczny helper jest używany przez symulację i boty. Normalne osie wejścia są clampowane, ale sam helper ma niezabezpieczoną domenę.  
**Ryzyko:** UB i zależne od kompilatora zachowanie w danych granicznych.  
**Proponowany diff:**
```diff
- constexpr q16 q_abs(q16 a) { return a < 0 ? -a : a; }
+ constexpr q16 q_abs(q16 a) {
+   return a == INT32_MIN ? INT32_MAX : (a < 0 ? -a : a);
+ }
```
Udokumentować saturację lub zamiast tego użyć funkcji na `int64_t`.

### T25-20 [P2] `quantize_256` przepełnia dodawanie i negację na krańcach int32
**Plik:linia:** `lockcore/include/lockcore/fixed.hpp:50-54`.  
**Opis:** `v + INPUT_QUANTUM/2` przepełnia dla `v≈INT32_MAX`, a `-v` dla `INT32_MIN`. Samo `units * 256` także może przekroczyć zakres, jeśli zaokrąglenie wypada nad `INT32_MAX`. `InputFrame::quantize` clampuje najpierw, lecz helper jest publiczny.  
**Ryzyko:** UB i łamanie przenośności niskopoziomowego API.  
**Proponowany diff:**
```diff
- const std::int32_t units = (v >= 0) ? (v + INPUT_QUANTUM / 2) / INPUT_QUANTUM
-                                     : -((-v + INPUT_QUANTUM / 2) / INPUT_QUANTUM);
- return units * INPUT_QUANTUM;
+ const std::int64_t wide = v;
+ const std::int64_t units = wide >= 0 ? (wide + 128) / 256 : -((-wide + 128) / 256);
+ return static_cast<q16>(q16_clamp_i64(units * 256));
```
`q16_clamp_i64` powinno sprowadzić wynik do największej wielokrotności 256 mieszczącej się w `int32`.

### T25-21 [P2] `ms_to_steps` mnoży int32 bez poszerzenia
**Plik:linia:** `lockcore/include/lockcore/fixed.hpp:45-46`.  
**Opis:** argument `ms` i `SIM_HZ` są typu `int`; `ms*120` przepełnia dla czasu większego niż ok. 17,9 mln ms mimo że końcowy wynik po podzieleniu przez 1000 mieściłby się w int32.  
**Ryzyko:** UB dla dłuższych czasów wejściowych/nowych parametrów narzędzia.  
**Proponowany diff:**
```diff
- return (ms * SIM_HZ + 500) / 1000;
+ return static_cast<std::int32_t>((static_cast<std::int64_t>(ms) * SIM_HZ + 500) / 1000);
```
Dodatkowo ustalić semantykę ujemnych ms; obecne typowe wartości z walidacji są znacznie mniejsze.

### T25-22 [P1] `Pcg32::range`: przepełnienie przy szerokich przedziałach int32
**Plik:linia:** `lockcore/include/lockcore/prng.hpp:41-45`.  
**Opis:** `hi-lo` liczony jest jako signed int32. Dla `range(INT32_MIN, INT32_MAX)` to UB, a próba skonstruowania `bound=2^32` przez `uint32_t + 1` dałaby zero.  
**Ryzyko:** przekłamanie rozkładu lub UB w generatorze przy niekontrolowanych granicach przedziału.  
**Proponowany diff:**
```diff
- return lo + static_cast<std::int32_t>(below(static_cast<std::uint32_t>(hi - lo) + 1u));
+ const auto span = static_cast<std::uint64_t>(static_cast<std::int64_t>(hi) - lo) + 1u;
+ const std::uint32_t offset = span == (1ULL << 32)
+     ? next() : below(static_cast<std::uint32_t>(span));
+ return static_cast<std::int32_t>(static_cast<std::int64_t>(lo) + offset);
```

### T25-23 [P2] Parser JSON akceptuje samotny niski surogat UTF-16
**Plik:linia:** `lockcore/src/json.cpp:238-250`.  
**Opis:** wysoki surogat `\uD800..\uDBFF` wymaga pary, ale niski `\uDC00..\uDFFF` nie jest odrzucany i trafia do `put_utf8()` jako niedozwolony punkt kodowy. Parser kopiuje też surowe bajty non-ASCII bez walidacji UTF-8.  
**Ryzyko:** niekanoniczne pliki JSON, rozbieżna interpretacja w Godot/JS/narzędziach.  
**Proponowany diff:**
```diff
@@ po obsłudze wysokiego surogatu
+ if (cp >= 0xDC00 && cp <= 0xDFFF) return fail("lone low surrogate");
  put_utf8(out, cp);
```
Dodać walidację surowego UTF-8 i testy par/samotnych surogatów.

### T25-24 [P3] Brak obsługi błędu otwarcia/zapisu plików wynikowych
**Plik:linia:** `lockcore/tools/verify_seeds.cpp:98-103, 244-250`; `lockcore/tools/replay_tool.cpp:220-223`.  
**Opis:** nieudane `csv.open(csv_path)` nie powoduje błędu ani ostrzeżenia; w `record` zapis odbywa się przez tymczasowy `ofstream` bez weryfikacji `is_open()/good()`, po czym drukowany jest komunikat sugerujący powodzenie.  
**Ryzyko:** cicha utrata CSV lub replaya, szczególnie gdy katalog nie istnieje lub jest tylko do odczytu.  
**Proponowany diff:**
```diff
  csv.open(csv_path);
+ if (!csv) { std::fprintf(stderr, "cannot open CSV\n"); return 2; }
@@ replay_tool record
- std::ofstream(argv[5], std::ios::binary) << replay_to_json(rp);
+ std::ofstream f(argv[5], std::ios::binary);
+ if (!f || !(f << replay_to_json(rp))) return 1;
```

## Zalecane testy regresyjne

1. **Granica sesji:** każda rodzina z błędnym typem `params`, brak `params`, niewłaściwym `ToolSet`; oczekiwany kontrolowany błąd, nigdy crash.
2. **Fuzz parsera `replay_from_json`:** pusty/zbyt duży seed, niecyfrowe znaki, `run=0/100000001`, wiele długich runów, liczby `INT64_MAX`, `tool=-1/256`, osie poza zakresem, brak `difficulty`/`expected`.
3. **Artymetyka:** `q16_ratio(INT64_MAX,1)`, mianownik 0, `q_abs(INT32_MIN)`, `quantize_256(INT32_MIN/MAX)`, `ms_to_steps(INT32_MAX)`, `Pcg32::range(INT32_MIN, INT32_MAX)`; wszystkie pod UBSan i z porównaniem GCC/Clang/arm64.
4. **Weryfikator:** `--seeds 0`, `--seeds nonsense`, `--family nonexistent`, `--tier 999` mają kończyć się niezerowo; metadane `expected` mają przejść round-trip.
5. **Stres:** wymusić pik przed resetem detektora; po dodaniu zużycia raportowany `peak_ratio` nie może maleć.
6. **Końcowy tick:** jednoczesne `set`/`break`; dokładnie jedna wybrana semantyka końca.
7. **JSON:** odrzucić `"\uDC00"` i źle zakodowane surowe UTF-8, przyjąć poprawne pary.

## Uwagi o determinizmie i kompatybilności

- Naprawy `fixed.hpp`, RNG, walidatorów i kolejności `open/break` mogą zmienić zachowanie tylko na brzegach, ale **mogą też zmienić hash replay**. Jeśli zmiana dotyka symulacji prawidłowych danych, zwiększyć `rules_version` rodziny i wygenerować na nowo golden files.
- Po każdym pakiecie poprawek uruchomić `ctest` (Release, ASan/UBSan), `verify_seeds --seeds 10000`, `spike-determinism` oraz `spike-determinism-apk`. CI zawiera już te mechanizmy; chodzi o rozszerzenie ich o negatywne przypadki, a nie zastępowanie.
- Raport celowo nie opisuje technik otwierania rzeczywistych produktów ani producentów; obejmuje wyłącznie kod fikcyjnej symulacji.
- **Testy nieuruchomione w tej sesji:** brak dostępu sieciowego w środowisku kompilacji. Wszystkie ustalenia są wnioskami ze wskazanych linii, a diffy szkicami do wdrożenia i zweryfikowania przez właściciela kodu.

## Kolejność wdrożenia

**Pierwszy pakiet:** T25-01, 02, 03, 04, 05, 06, 08, 09, 10, 11, 14 i 15 (granica zaufania, poprawność replay/weryfikatora). **Drugi:** T25-17–23 (bezpieczna arytmetyka i Unicode). **Trzeci:** T25-07, 12, 13, 16, 24 (kanoniczność, pokrycie i metryki).

**Zakres zmian w tym zleceniu:** wyłącznie dokumentacja w `contrib/gpt/T25/`; żaden kod produkcyjny ani testowy nie został zmodyfikowany.
