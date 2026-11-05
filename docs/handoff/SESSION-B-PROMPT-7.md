# Sesja B, etap 7: poprawki po pierwszym teście właściciela na telefonie (APK run 92)

Kontynuujesz jako **sesja B** (repo `woogitsugames/lockwright`, `main`). Zasady z poprzednich promptów obowiązują. Priorytet ma Android (D-51).

Właściciel przetestował APK z runu 92. Zrzuty są w `docs/handoff/device-tests/run92/`. Pełne opisy z gotowymi wskazówkami są w `docs/handoff/SESSION-B-LOG.md` (wpisy „Od sesji A”, N-52…N-61, plus głosy S03v2).

Wykonuj **po kolei**:
0. **N-61 (najpierw):** samouczek S1 jako prowadzone kroki z kredą w widoku planu B (ONBOARDING §4). Teraz gracz po „Zacznij ćwiczenie” nie dostaje żadnej instrukcji.
1. **N-52:** przycisk „wstecz” Androida zamyka grę. Ma prowadzić o krok w tył, a z menu wychodzić dopiero po potwierdzeniu.
2. **N-59 + N-53:** brak scrolla poziomego i marginesy na wszystkich ekranach:
   - wspólny `MarginContainer` 16 dp + safe-area;
   - wiersze warsztatu jako karty na 2 linie;
   - test minimalnej szerokości przy 360/412/915 px.
3. **N-55:** sprawdź poprawkę VIBRATE (sesja A, bd8f9dc). Haptyka ma działać na telefonie, a CI ma sprawdzać manifest.
4. **N-58:** dźwięk i haptyka przy każdym kontakcie wytrycha. Kredowa podpowiedź „lewy kciuk = napięcie”. Samouczek nie przepuszcza dalej bez napięcia.
5. **N-57:** lupa w zwijce jako działający przycisk z okrągłym okularem.
6. **N-60:** rozmowa przy przyjeździe:
   - pusta tabliczka zamiast `plate_01` z cyfrą;
   - wszystkie 39 portretów;
   - jeden wiersz na linię;
   - Ślusarz po prawej, bez tabliczki.
7. **Głosy S03v2:** podłącz `contrib/gpt/S03v2/voices/<id>/` w `Sfx.play_voice` dla mówców epizodycznych i dodaj je do ASSETS.md.
8. **N-56:** klapka pauzy jako skórzany język z napą (nie kwadrat). Sprawdź też puste komory 4–5 na płycie i brak napinacza.
9. **N-54:** menu główne, a w ślad za nim ustawienia i reszta ekranów:
   - tło warsztatu, tytuł Bona Nova, przyciski jako emaliowane tabliczki;
   - pełny motyw `theme/main.tres` (Button, Panel, HSlider, CheckButton, OptionButton).
10. **Przekazanie właścicielowi:** zielone `game-android`, `game-tests`, `game-screens` i `qa-career`. W logu link do runu z APK, zrzuty 412×915 i 915×412 każdego poprawionego ekranu oraz tabela statusów N-52…N-61.

Kryterium „gotowe”: właściciel przechodzi menu → ustawienia → zlecenie → rozmowa → zamek → pauza → warsztat bez przewijania w poziomie, z wibracją, dźwiękiem i działającym „wstecz”.
