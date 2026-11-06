# V03 — lockviz: schematy 8 nowych rodzin lockcore v0.6 + testy (raport)

Data: 2026-11-06. Zakres: tylko `mockups/tools/lockviz/**` i `docs/handoff/mistral/V03-*`.

## Co zrobione

1. **Trace'y.** `lockcore` zbudowany (`cmake -S lockcore -B lockcore/build && cmake --build lockcore/build`),
   16 złotych powtórek nowych rodzin przekonwertowanych przez `replay_tool trace`
   (wszystkie hashe `matches`) do `mockups/tools/lockviz/traces/*.trace.json`;
   `traces/index.json` zaktualizowany (29 nazw, posortowane).
2. **Schematy.** Nowy plik `mockups/tools/lockviz/families_v06.js` z ośmioma funkcjami rysującymi
   (`FAMILY_DRAW_V06`) podłączonymi w `drawSchematic()` w `lockviz.js`; `index.html` ładuje skrypt
   przed `lockviz.js`. Każde rysowanie ustawia `document.body.dataset.schematic` na nazwę funkcji
   (stare rodziny: `drawRings` / `drawWarded` / `drawLevers` / `drawLift` — bez zmian w wyglądzie).
   Czyste funkcje geometrii w `LOCKVIZ_GEOM` (moduł testowany jednostkowo z Node).
   `drawGauges()` i oś czasu bez zmian — działają dla nowych rodzin (krzywe `view_pick_lift`, pasy
   zdarzeń; nowe pod-zdarzenia pokazują się z nazwami, np. `safe.detent`, `combo.detent`,
   `disc.detent`, `slider.false_notch`, `time.tick`).
3. **Testy.** `mockups/tools/lockviz/test/lockviz.test.mjs` (`node --test`): spójność `index.json`
   ↔ pliki ↔ `schema == 'lockwright.trace/1'`, testy jednostkowe `LOCKVIZ_GEOM`, oraz test
   Playwright: każdy z 29 trace'ów na klatkach 0 / środkowa / end — brak `pageerror`,
   `data-ready="1"`, `data-schematic` zgodny z mapą (nowe rodziny nie wpadają w `drawLift`,
   stare mają ten sam schemat co przed zmianą). **Wynik: 3/3 testy zielone**
   (87 stron, 1440×1000). Uwaga środowiskowa: w tym sandboxie Chromium wymaga
   `LD_LIBRARY_PATH` + `FONTCONFIG_FILE` wskazujących na lokalnie wypakowane biblioteki;
   uruchomienie: `cd mockups && npm install && node --test "tools/lockviz/test/*.test.mjs"`
   (forma katalogowa `node --test tools/lockviz/test/` na Node 22.23 traktuje katalog jako
   moduł — używaj wzorca glob).
4. **Zrzuty.** `docs/handoff/mistral/V03-shots/*.png` — po jednym na rodzinę w ciekawym momencie
   (środkowe zdarzenie set/false_set/overset) + regresja starej rodziny (`pin_tumbler_t7_s4242`).

## Jak czytać każdy schemat (2–3 zdania na rodzinę)

- **dial_safe** (`drawDialSafe`): pakiet kół o stopniowanych średnicach (koło 0 najdalej od
  pokrętła), bramka każdego koła jako wycięcie na obwodzie — przy stanie `set` stoi na 12:00 pod
  płotkiem; płotek opada (i dalej przesuwa się rygiel wraz z `hold_progress`), gdy wszystkie
  bramki stoją pod nim. Po prawej pokrętło z podziałką (kąt = scałkowana prędkość z
  `view_pick_lift`, odczyt cyfry = kąt × działki), łuk „listening" na słuchanym kole
  (`pick_element`) z aktualnym dociskiem klamki.
- **combo** (`drawCombo`): rząd kółek z przodu, cyfra przy linii odczytu (przerywana linia u
  góry) = `wheelDigit(position)`, wcięcie tulejki na obwodzie koła, stan `overset` = poślizg
  (`combo.slip`, opis „slip”), linka z ostatniego koła do zatrzasku (core rotation).
- **dimple** (`drawDimple`): dwa rzędy pinów widziane z boku (bit `DIMPLE_SIDE_ROW` = górny
  rząd „side row"); pin teleskopowy (wariant spool) ma dwa okna — zewnętrzne (tuleja) i węższe
  wewnętrzne (środkowy pin, biały prostokąt wewnątrz).
- **disc_detainer** (`drawDiscs`): stos tarcz w przekroju (elipsy), 8 zapadek na obwodzie,
  wycięcie tarczy jako białe kółko na krawędzi (u góry przy `set`), listwa boczna nad stosem
  z zębami wpadającymi w ustawione tarcze; obrót w obie strony (znak `pick_lift`), `overset` =
  przekręcenie.
- **egyptian** (`drawEgyptian`): drewniany rygiel (szary pas) przesuwający się w prawo z
  `core_rotation`/`hold_progress`, otwory w ryglu, kołki opadające grawitacyjnie (pozycja =
  wysokość, okno = przerywane linie), klin = stan `overset`.
- **axial_slider** (`drawSliders`): widok z czoła — suwaki jako promieniowe klocki wciskane do
  środka (głębokość = pozycja), okno na płytce zamykającej jako przerywane znaczniki
  głębokości, fałszywe wcięcia jako krótkie kreski nad oknem, wybrany suwak zaznaczony
  kółkiem „pusher".
- **time_lock** (`drawTimeLock`): przekładnia z kół zębatych w kolejności (koło 0 pierwsze),
  głębokość osadzenia koła jako znacznik pod osią; na dole oś czasu ze znacznikami `time.tick`
  do kursora i ciemny pasek postępu biegu (`hold_progress`).
- **magnetic** (`drawMagnetic`): rząd pinów jak w pin_tumbler, plus sondą: kciuk (`pick_lift`)
  i linia pola (`view_pick_lift`, przerywana) — odstęp między nimi to widoczne opóźnienie pola
  (podpis „lag").

## Czego brakuje w trace'ach

- **Pasmo nasłuchu / biegu** (`band_lo`/`band_hi` dla `dial_safe`, `[run_lo, tau_safe]` dla
  `time_lock`) nie jest w `frame_fields` — na schemacie pokazujemy sam docisk (`tension`)
  i słuchane koło, bez zaznaczonego pasma. Do rozważenia: dopisanie `band_lo`/`band_hi` do
  `ViewModel`/trace.
- **Dial reading** (`ViewModel::dial`, `dial_divisions`) nie jest w trace — kąt pokrętła
  liczymy przez całkowanie `view_pick_lift`, działki bierzemy z `tier` (20/30/40).
- `time.beat_off`, `combo.slip`, `disc.overturn`, `safe.fence_drop` występują jako bazowe
  kindy z pod-nazwami — widać je w pasach i liście zdarzeń, ale lane pokazują tylko nazwę
  bazowego kindu (istniejące zachowanie, bez zmian).

## Propozycja akapitu do `lockcore/README.md` (dla sesji A)

> `mockups/tools/lockviz/` rysuje teraz osobnym schematem także rodziny v0.6: `dial_safe`
> (pakiet kół + płotek + pokrętło), `combo` (rzad kółek z cyframi przy linii odczytu),
> `dimple` (dwa rzędy pinów, teleskop = dwa okna), `disc_detainer` (stos tarcz + listwa
> boczna), `egyptian` (rygiel z kołkami), `axial_slider` (suwaki promieniowe, widok z czoła),
> `time_lock` (przekładnia + oś taktu `time.tick`), `magnetic` (sonda: kciuk vs opóźnione
> pole). Trace'y złotych powtórek tych rodzin są w `traces/` (16 plików, `index.json`);
> testy: `node --test "tools/lockviz/test/*.test.mjs"` w `mockups/`.
