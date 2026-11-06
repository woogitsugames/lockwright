# Przegląd V02 (Mistral Vibe): HintLadder + GhostHand

Przeglądający: sesja A (agent planu B), przy wpięciu do ekranu zamka (`game/scripts/tutorial/tutorial_hints.gd`).

## Ocena ogólna
Kod jest czytelny, zgodny ze zleceniem i z ONBOARDING §2.1–2.2: czysta logika drabinki bez węzłów, czas tylko przez `delta`, widmo z `mouse_filter = IGNORE`, cień zamiast poświaty, testy pokrywają API. Wpięcie poszło bez zmian w API. Poniżej błędy i uwagi.

## Błędy (poprawione)
1. **`GhostHand` przerysowywał się w każdej klatce, gdy nic nie grał.** `_process` był włączony od startu (domyślnie dla węzła z `_process`), więc bezczynne widmo co klatkę wołało `_apply_layout()` i `queue_redraw()`. Na tanim telefonie to zbędna praca na ekranie zamka. Poprawka: `set_process(false)` w `_init`; `play_gesture()` włącza przetwarzanie, koniec gestu je wyłącza (tak jak było).

## Błędy wykryte przy wpięciu (po stronie integracji, nie w kodzie V02)
2. Pseudokod z raportu robi `ladder.start_step(coach.text_key())`. Klucz tekstu nie jest krokiem: w S2–S3 i w pierwszych zleceniach `text_key()` jest zwykle pusty, więc drabinka nigdy by się nie zerowała między krokami. W integracji krok wyznacza `TutorialHints._step_id()` (krok trenera w S1 albo „napięcie / unoszenie” + liczba osadzonych elementów), a każde osadzenie zaczyna nowy krok.
3. Pseudokod zeruje drabinkę warunkiem „gracz ma bind albo set” w **każdej** klatce, w której element jest związany. To trzymałoby H0 bez końca, gdy gracz trzyma napięcie i nic nie robi. Postęp to **zdarzenie** (`bind`, `set`, `gate_align` z lockcore), nie stan.

## Uwagi (bez zmian, do decyzji)
4. `HintLadder.history` rośnie bez limitu. W samouczku to kilkadziesiąt wpisów, więc nie przeszkadza; zapis do `Save` (`tutorial/hint_history`) przycina do 400 wpisów po stronie integracji.
5. `thresholds` nie są walidowane (zakłada się rosnącą kolejność). Przy malejących progach `update()` przeskoczy poziomy w dziwnej kolejności. Wystarczy komentarz albo `sort()` w setterze.
6. Owal zastępczy jest zawsze pionowy. Dla gestu „w bok” (wybór pinu) i dla dłoni mistrza będzie potrzebny obrót sylwetki; do zrobienia razem z teksturami dłoni od Magnific (`texture` + kąt).
7. Opcja „zamień kciuki” (`mirror`) jest gotowa, ale w grze nie ma jeszcze ustawienia dla leworęcznych (`HUD.md` §9), więc integracja jej nie włącza.

## Co zostało wpięte
- `TutorialHints` (węzeł pod sceną zamka) dla S1–S3 i pierwszych 3 zleceń (tam, gdzie działa `TutorialCoach`), w obu trybach D-52, dla pinów, wafer, lever i warded.
- H1: odcisk kciuka w skórze zwijki tam, gdzie trzeba położyć palec, drgnięcie tarczy rdzenia i cichy dźwięk (−12 dB). H2: widmo kciuka 2× w tempie lekcji (napięcie 0→0,3 w 0,6 s, unoszenie 0,2/s), a tarcza rdzenia odpowiada na widmo. H3: pełna kreda + strzałka przy kciuku, który ma się ruszyć. H4: dłoń mistrza raz na krok, a zamek naprawdę wykonuje krok (autopilot wejścia lockcore); w trybie dwóch kciuków napięcie zostaje, dopóki gracz nie położy lewego kciuka.
- Tryb „w ciemności”: H1–H3 tylko dźwięk i haptyka, H4 zapala światło na 2 s.
- Telemetria: `Save["tutorial/hint_history"]` (zlecenie, krok, poziom, czas).
- Testy: `game/tests/gut/test_tutorial_hints.gd` (eskalacja na prawdziwej scenie przy bezczynności, postęp zeruje, widmo nie przechwytuje dotyku, H4 najwyżej raz na krok, tryb w ciemności).
