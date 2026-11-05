# T08 — Arkusz obserwacji / Observation sheet

**Jeden egzemplarz na jedną sesję / One sheet per session.** Przygotowany do druku lub kopiowania do formularza/arkusza. Wpisuj **wyłącznie losowe kody**, nie imię, adres, kontakt, dokładny wiek, diagnozę, identyfikator urządzenia ani cytaty z prywatnymi informacjami. Brak zgody na nagrywanie nie wyklucza z testu.

## A. Metadane sesji / Session metadata

| Pole / Field | Wpis / Value |
|---|---|
| Losowy kod / Random session code (bez tabeli powiązań z osobą) | __________ |
| Ścieżka / Track | A — first contact / B — tiers and economy / C — accessibility |
| Numer partii / Batch number (nie identyfikator osoby) | __________ |
| APK build + rules_version | __________ |
| Język / Language | PL / EN |
| Android: ogólna klasa urządzenia / broad device class | low-end / mid-range / high-end / unspecified |
| Haptyka / Haptic capability | H0 / compatible / unknown |
| Kalibracja / Calibration | 2 taps / 1 tap / none / not offered |
| Wibracje podczas testu / Haptics | on / off |
| Dźwięk podczas testu / Sound | on / off |
| Opcje / Accessibility settings enabled | none / chalk / contrast / captions / wide windows / swapped thumbs / tension lock / reduce motion / screen reader / other built-in |
| Wariant A7 / A7 variant | no chalk / reading help / not tested |
| Zgoda na udział / Participation | yes (no personal data recorded) / declined (do not test) |
| Nagrywanie (opcjonalne, osobna zgoda) / Optional recording consent | no / screen+hands only / not applicable |
| Status sesji / Session status | valid / interrupted / technical failure / protocol deviation |
| Przyczyna wyłączenia z konkretnej analizy / Reason metric invalid (if any) | _____________________ |

Warianty: **A**: włączona standardowa kalibracja oraz H0–H4 tylko w S1–S3, **H1–H4 wyłączone w pin.a1**; A2 ma czarną nakładkę. **C**: haptyka wyłączona przez całą próbę A9; wolno włączyć pomoce dostępności na prośbę.

## B. Krótki zapis w czasie / Timeline

| Minuta sesji / Relative minute | Zadanie / Task | Co zrobił gracz / Behaviour (krótko, bez nazw i cytatów) | Kod problemu / Issue code |
|---|---|---|---|
| 00–05 | | | |
| 05–10 | | | |
| 10–15 | | | |
| 15–20 | | | |
| 20–25 | | | |
| 25–30 | | | |

**Kody / Codes:** STUCK (brak postępu ≥15 s / no progress), WRONG_TENSION (nietrafione napięcie / wrong tension), LOST_PICK (chaotyczne szukanie / lost tool position), MISREAD_STATE (błędny odczyt / misread signal), FALSE_SUCCESS (false set taken as set), HAPTIC_NONE (brak czucia / no haptic sensation), ACCESS_BLOCK (bariera / accessibility blocker), UI_TOUCH (niedostępny dotyk / touch target), ECON_LOCK (zablokowany zakup/zlecenie / inaccessible purchase/job), ECON_CONFUSION (niejasny rachunek / unclear economy), LEGAL_SKIP (próba otwarcia bez potwierdzenia / unverified opening), LEGAL_REFUSE (świadoma odmowa / correct refusal), TONE_COLD (ton odebrany jako chłodny / cold tone), CRASH (błąd gry / app error), OTHER (opisz krótko / describe briefly).

## C. Samouczek / Tutorial (A lub C)

| Wskaźnik / Metric | S1 | S2 | S3 |
|---|---|---|---|
| Ukończony / Completed (1/0/NT) | __ | __ | __ |
| Czas od wejścia do open / Duration in seconds | __ | __ | __ |
| Najwyższa wskazówka / Highest hint H0–H4 | __ | __ | __ |
| H4 liczba / H4 count | __ | __ | __ |
| Najdłuższe utknięcie / Longest stall (s) | __ | __ | __ |
| Drop / overset / stress / break (liczby / counts) | __ / __ / __ / __ | __ / __ / __ / __ | __ / __ / __ / __ |
| Dodatkowe ustawienia / Extra accessibility settings | __ | __ | __ |

- Start aplikacji → pierwszy dotyk S1 / App launch → first S1 touch: ____ s (cel ≤25 s / target ≤25 s).
- Mediana S1–S3 to wynik **całej próby**, nie pojedynczej sesji / Report group median, not a single-session “median”.
- Czy S1–S3 ukończono bez haptyki? / All S1–S3 completed with haptics off? yes / no / NT. Jeśli no: który krok zablokował? / Which step? __________
- Czy moderator udzielił niedozwolonej wskazówki? / Moderator offered prohibited instruction? no / yes; jeśli tak, A1 nieważne / if yes, invalidate A1.

## D. Zadania zamków / Lock attempts (A1, A2, tiers)

Wpisz **oddzielny wiersz na każdy zamek**; nie wpisuj 300 s jako „czas otwarcia”, jeśli nie otwarto zamka. / One row per lock; do not treat a timeout as an opening time.

| Test | Family / tier / seed | Kolejność / Order | Czas do open [s] / Time to open | Open (1/0) | Limit [s], censored (1/0) | drop / overset / stress / break | Najwyższa H / Max hint | Komentarz kodowany / Coded note |
|---|---|---|---|---|---|---|---|---|
| A1 pin.a1 | pin_tumbler / t2 / seed 1 | 1 | ___ | ___ | 300 / ___ | __ / __ / __ / __ | H0 (obowiązkowo) | ___ |
| A2 pin.a2 | pin_tumbler / t2 / seed 2 | 2 | ___ | ___ | 300 / ___ | __ / __ / __ / __ | ___ | ___ |
| Tier zadanie 1 / Tier task 1 | ___ / t__ / seed __ | ___ | ___ | ___ | 240 / ___ | __ / __ / __ / __ | ___ | ___ |
| Tier zadanie 2 / Tier task 2 | ___ / t__ / seed __ | ___ | ___ | ___ | 240 / ___ | __ / __ / __ / __ | ___ | ___ |

**A1:** open przed 90 s? / Open before 90 s? yes / no / NT. **A2:** open przed 180 s? / Open before 180 s? yes / no / NT. „Przed” oznacza ścisłe <, nie ≤. Jeśli pomiar się nie odbył, oznacz NT (not tested) i podaj dlaczego; nie licz jako sukces.

**Zachowanie L i P / Thumb behaviour:** L utrzymuje napięcie / holds tension: yes / intermittent / no; P szuka celowo / scans deliberately: yes / no; zauważono zasłonięcie widoku / screen occluded: yes / no.

## E. A7 — odczyt stanów bez barwy / State recognition without colour

**Warunek / Condition:** grayscale + 50% brightness, no audio/haptics. Pokaż krótką legendę i niezależny kadr/animację z innym seedem niż przykład; zapisuj odpowiedź i wynik. / Present a labelled reference, then a different-seed test image or motion clip; record the answer and correctness.

| Stan / State | Wybrana odpowiedź / Chosen category | Poprawnie / Correct (1/0/NT) | Przyczyna błędu — kod / Reason code |
|---|---|---|---|
| free / swobodny | ____ | ____ | ____ |
| binding / wiąże | ____ | ____ | ____ |
| near_shear / blisko ustawienia | ____ | ____ | ____ |
| set / ustawiony | ____ | ____ | ____ |
| false_set / fałszywie ustawiony | ____ | ____ | ____ |
| counter_rotate / kontrrotacja | ____ | ____ | ____ |
| overset / przepchnięty | ____ | ____ | ____ |
| stress / blisko złamania | ____ | ____ | ____ |

A7: suma poprawnych / correct count: __ / 8. **Nie stosuj łącznej średniej jako kryterium A7:** oblicz trafność **każdego stanu** wśród ≥8 osób osobno dla wariantu kredy.

## F. Zlecenia, pieniądze, legalność / Jobs, money, legality (B)

| Próba / Scenario | Wybór / Choice | Wynik / Outcome |
|---|---|---|
| Potwierdzone prawo do lokalu / Verified entitlement | ask for proof / accept after proof / refuse / NT | ____ |
| Brak potwierdzenia / Entitlement not verified | ask for proof / refuse / open without proof / NT | ____ |
| Rachunek i nagroda / Receipt and reward | understood / unclear / not shown | ____ |
| Zakup i naprawa / Purchase and repair | purchased / deferred / blocked / not shown | ____ |

- Zapisano kwotę nagrody **tylko z gry** / Reward displayed by game (optional): ____ coins; koszt naprawy z gry / repair price shown: ____ coins.
- Czy do pierwszego zlecenia był wymagany grind? / Extra runs required before first job? yes / no / not observable.
- Czy zlecenie było zablokowane przez narzędzie/tier? / Job blocked by tool/tier gate? yes / no / not observable.
- Czy interfejs dawał możliwość odmowy? / Was refusal available? yes / no / not shown.
- Ton oceniaj **na podstawie zachowania i Q19**, a nie wniosków o testerze / Tone from observed interface and Q19, not presumed personality.

## G. Wynik sesji i decyzja / Session summary and action

| Pytanie / Summary | Wynik / Value |
|---|---|
| Najważniejszy problem / Biggest problem (code + task + relative time) | ______________________________ |
| Liczba podobnych zdarzeń w tej sesji / Count of repetitions | ___ |
| Wpływ / Severity | P0 legal/safety/access blocker / P1 acceptance failure / P2 usability / no issue |
| Czy przyczyna jest potwierdzona? / Evidence | observed / log-confirmed / hypothesis |
| Jedna propozycja poprawki / One candidate fix | ______________________________ |
| Czy trzeba powtórzyć test? / Retest needed | yes / no / unknown |
| Brakująca funkcja APK / Missing prototype support | ______________________________ |

**Nie zaliczaj / Do not mark PASS from one sheet.** A1/A2/A7/A9 wymagają agregacji wielu sesji zgodnie z PLAYTEST-PLAN.md §9–10. Ankieta PL/EN jest niezależnym formularzem Q01–Q20; niewyświetlone funkcje = N/D lub N/A, nie zero.
