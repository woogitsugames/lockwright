# Audyt dostępności 2026-11-08 (D-90) — dowody

Opis i wnioski: `docs/ACCESSIBILITY.md`. Desktop Windows, Godot 4.7.2, okno opengl3 (nie telefon).

- `states/` — prawdziwe ekrany 13 rodzin, wszystkie elementy w jednym stanie (free, bound, near, set, false_set,
  overset, stress 0,95, open), z ograniczeniem ruchu; `<rodzina>__caption_set.jpg` = pasek napisów dźwięków po kliku set.
  Źródło: `game/tests/a11y_state_shots.tscn -- --reduce=1 --captions=1`.
- `report/` — `report.md` (odsetek pikseli zmienionych między parami stanów: szarość / deuteranopia / protanopia) i
  `sheet_<rodzina>.jpg` (kolor / szarość / deutan / protan). Źródło: `qa/a11y/state_report.py states --out report`.
  Wynik: 0 par z pięciu stanów nierozróżnialnych bez koloru.
- `text_scale/` — ekrany menu przy 100/150/200 % tekstu w PL/EN/DE/FR/ES, 412×915, 360×800, 915×412
  (`game/tests/shot_scene.tscn -- --text-scale=… --lang=…`); `contact_text_scale.jpg` = zestawienie.

Pliki zapisane jako JPEG q85 (rozmiar repo); `report.md` policzono z oryginalnych PNG — ponowne uruchomienie
`state_report.py` na JPEG da wartości różne o setne procenta.
