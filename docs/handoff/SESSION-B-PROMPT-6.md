# Sesja B — etap 6: grywalny APK na telefonie właściciela (Android)

Kontynuujesz jako **sesja B** (repo `woogitsugames/lockwright`, `main`). Zasady z poprzednich promptów obowiązują. **Priorytet to Android** (D-51). iOS robimy na końcu, a `game-ios` nie blokuje zamykania zadań. Zadanie jest skończone dopiero przy zielonych runach `game-android`, `game-tests`, `game-screens` i `qa-career` (link do runu w logu).

Najpierw dokończ zadania 5 i 6 z `SESSION-B-PROMPT-5.md`. Potem wykonuj poniższe **po kolei**. Gotowe diffy i opisy są w `docs/handoff/SESSION-C-REVIEW.md` pod numerami N-xx.

## Zadania
1. **N-44:** `workshop_screen.gd:21` ma `OS.get_time()` z Godota 3, więc warsztat się nie ładuje. Użyj `Time.get_time_dict_from_system()`. Sprawdź: `godot --headless --path game --quit-after 5 res://scenes/workshop.tscn`.
2. **N-48:** `Sfx.play_voice` szuka plików `greeting_NN.wav`, a w repo są `greeting.wav`. Do tego katalogi Oli i Krystyny mają inne nazwy niż te, których szuka gra. Popraw, żeby głosy S03 grały przy liniach dialogu.
3. **Release AAB bez sekretów:** gdy nie ma keystore, eksportuj niepodpisany AAB albo pomiń job zamiast go wywalać (wpis CI z rundy 3 w przeglądzie).
4. **N-30, rozmiar paczki** (próg 70 MB):
   - grafiki GPT i Magnific importuj z kompresją (VRAM compressed / lossy WebP);
   - zrzuty kontrolne Gemini (`game/scenes/photoreal_families/shots/`) wyłącz z eksportu;
   - niepodłączone sceny wyłącz z presetów.
5. **Błędy z telefonu (GEM3, N-31…N-43):** wszystkie, od najpoważniejszych. W szczególności:
   - **BUG-03:** wyjście z zamka przez pauzę zostawia `paused=true`. Potwierdź, że naprawione, i dodaj test.
   - **BUG-06:** pamięć RAM 598 MB przy limicie 350 MB.
   - **BUG-07:** puste przyciski.
   - **BUG-08:** otwarcie jest aktywne w zleceniach odmownych.
   - **BUG-09:** lupa na całą szerokość, szare kieszenie, ciemny tryb nie gasi światła.
   - **BUG-10:** panel „O grze” jest półprzezroczysty.
   - **BUG-11:** gablota jest odblokowana od startu, widać gwiazdki Markdown, sonda kosztuje 0, brak „Wstecz” w samouczku.
   - **BUG-14:** stały `debug.keystore` w CI, żeby aktualizacje APK instalowały się na telefonie.
   - **zimny start 4,4 s:** asynchroniczne wczytywanie SFX.
   - **rytm klatek:** 18,2 ms przy GPU 6,4 ms. Sprawdź `physics_jitter_fix`, interpolację fizyki i frame pacing.
6. **Pauza diegetyczna (HUD §6):** zamiast „II” skórzana klapka z mosiężną napą. Użyj `art/textures/photo/objects/leather_brass_snap_1k.png` i `leather_stitching_strip`. Cel dotyku co najmniej 48 dp, w safe-area.
7. **Zwijka i materiały ze zdjęć (D-48):** HUD zwijki na `art/textures/photo/leather_brown_worn` (wersje `_1k`), puste kieszenie z `objects/tool_roll_pocket_empty_closeup`, wgniecenie kciuka z `objects/thumb_dent`. Wpisz wszystko do ASSETS.md.
8. **Postacie bez portretu (D-50, N-49):** zamiast pustego miejsca emaliowana tabliczka z inicjałem (wygenerowana z G01). Portrety z Magnific dojdą później do `contrib/incoming/magnific/selected/portraits/`.
9. **Sterowanie (D-24 zatwierdzona):** napięcie i uniesienie liczone względnie od punktu dotyku. Sprawdź `input_sampler.gd` i samouczek i dodaj test GUT.
10. **APK dla właściciela:** gdy wszystko powyżej jest zielone, wpisz do logu link do runu `game-android` z artefaktem i listę „co sprawdzić w 10 minut”.

Na końcu dodaj tabelę statusów z linkami do zielonych runów.
