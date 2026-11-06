# Zlecenie V03 (Mistral Vibe): lockviz — schematy 8 nowych rodzin lockcore v0.6 + testy

**Repo:** `woogitsugames/lockwright`, gałąź `main`. Najpierw przeczytaj `CLAUDE.md` i `lockcore/README.md`
(sekcja „Replay debugger (lockviz)” i „v0.6”). Kod i komentarze po angielsku, raport po polsku.
**Zasada pracy:** zrób, wypchnij na `main` małymi commitami i skończ. Odbiór robi sesja A (Claude).

## Twoje pliki (tylko te)
- `mockups/tools/lockviz/lockviz.js`, `mockups/tools/lockviz/index.html` (tylko jeśli musisz dodać skrypt/atrybut),
- nowy `mockups/tools/lockviz/families_v06.js` (jeśli wolisz rysowanie nowych rodzin w osobnym pliku),
- `mockups/tools/lockviz/traces/` — **nowe** pliki `*.trace.json` dla nowych rodzin + `traces/index.json`,
- nowy katalog `mockups/tools/lockviz/test/`,
- `docs/handoff/mistral/V03-REPORT.md`, `docs/handoff/mistral/V03-shots/*.png`.

**Nie zmieniaj niczego innego**: ani `lockcore/**` (także README), ani `game/**`, `art/**`, `tools/**`, CI, istniejących
trace'ów. Równolegle pracują tam inni. Jeśli trace nie ma czegoś, czego potrzebujesz, napisz to w raporcie.

Push: `git -c rebase.autoStash=true pull --rebase origin main && git push origin main`. Każdy commit z `[skip ci]`
(zmieniasz tylko `mockups/` i `docs/`).

## Po co
`lockviz` to przeglądarka powtórek lockcore dla projektantów i do debugowania (nie kod gry). Rysuje schemat dla
pin_tumbler / wooden_pin / wafer, lever(+detector), warded i ring_combo. Nowe rodziny v0.6 (`dial_safe`, `combo`,
`dimple`, `disc_detainer`, `egyptian`, `axial_slider`, `time_lock`, `magnetic`) wpadają dziś do ogólnego `drawLift`
(piny), co jest mylące. Każda rodzina ma mieć własny, czytelny schemat.

## 1. Trace'y nowych rodzin
Zbuduj lockcore i wygeneruj trace'y ze złotych powtórek (16 plików):
```bash
cmake -S lockcore -B lockcore/build && cmake --build lockcore/build
for f in lockcore/tests/golden/{dial_safe,combo,dimple,disc_detainer,egyptian,axial_slider,time_lock,magnetic}_*.replay.json; do
  b=$(basename "$f" .replay.json); lockcore/build/replay_tool trace "$f" mockups/tools/lockviz/traces/$b.trace.json; done
```
Dopisz nazwy do `traces/index.json` (posortowane). Format `lockwright.trace/1`: `frame_fields`, `frame_element_fields`,
`elements` (okna `[lo, hi, x]` w Q16), `element_states`, `event_sub_names` (np. `safe.detent`, `combo.detent`,
`disc.detent`, `slider.false_notch`, `time.tick`, `time.rattle`).

## 2. Schematy (w `drawSchematic()` dispatch po `T.family`)
Znaczenie pozycji elementów i wejść sprawdź w kodzie (`lockcore/include/lockcore/*.hpp`, `lockcore/src/families/`) i w
kartach `docs/LOCKS.md` §2.18–2.25. Część rodzin to flagi istniejących modułów (`combo`, `disc_detainer` → ring_combo;
`dimple`, `magnetic` → pin_tumbler; `egyptian` → wooden_pin; `axial_slider` → lever; `time_lock` → wafer;
`dial_safe` to nowy moduł) — tabela w `docs/research/new-families.md` §„Stan implementacji”. Minimum na rodzinę:

| rodzina | co pokazać |
|---|---|
| `dial_safe` | pakiet kół (koła o stopniowanej średnicy lub kółka obok siebie), bramka każdego koła względem płotka, kąt pokrętła, docisk klamki (pasmo nasłuchu), zdarzenia `safe.*` |
| `combo` | rząd kółek z cyframi przy linii odczytu; wcięcie tulejki vs ząbek; ciąg kabłąka; poślizg (`overset`) wyraźnie inny kształt |
| `dimple` | dwa rzędy pinów widziane z boku; pin teleskopowy = dwa okna (tuleja, potem wewnętrzny pin) |
| `disc_detainer` | stos tarcz w przekroju, wycięcie każdej tarczy vs listwa boczna, obrót w obie strony, przekręcenie |
| `egyptian` | drewniany rygiel z otworami, kołki opadające grawitacyjnie, klin (`overset`), przesunięcie rygla z `hold_progress` |
| `axial_slider` | widok z czoła: suwaki na okręgu, wciśnięcie promieniowe (znak ruchu ujemny), fałszywe wcięcia |
| `time_lock` | koła zazębiane po kolei, pasmo naciągu sprężyny, rytm `time.tick` (np. znaczniki na osi czasu), postęp biegu `hold_progress` |
| `magnetic` | piny i pozycja sondy; opóźnienie pola widoczne jako odstęp między pozycją docelową a faktyczną |

Zasady rysowania (jak dotychczasowe schematy, `docs/DESIGN.md`):
- stany (`free`, `bound`, `near`, `set`, `false_set`, `overset`, `jammed`) rozróżnialne **w skali szarości**: kształt,
  wzór i grubość linii z istniejących `body()`/`patterns`, kolor tylko jako drugi kanał;
- element ≥ 28 px przy szerokości okna 1440, podpis elementu jak `elementLabel()`;
- bez gradientów, neonów, poświaty; ta sama paleta i krój co reszta narzędzia;
- `drawGauges()` i oś czasu działają bez zmian dla nowych rodzin (sprawdź, czy nowe `event_sub_names` mają czytelne
  etykiety na pasach zdarzeń).
- Dodaj atrybut `document.body.dataset.schematic = '<nazwa_rysującej_funkcji>'` ustawiany przy każdym rysowaniu
  (do testów). Istniejące rodziny i ich wygląd zostają bez zmian.

## 3. Testy (`mockups/tools/lockviz/test/`, `node --test`)
- `lockviz.test.mjs` (Playwright z `mockups/node_modules` lub `/opt/node-tools/node_modules`, jak `shot.mjs`):
  dla **każdego** trace'u z `traces/index.json` otwórz stronę na klatkach `0`, środkowej i `end`; sprawdź brak
  `pageerror`, `data-ready="1"` i że `data-schematic` dla nowych rodzin **nie** jest ogólnym schematem pinów
  (dla starych — ten sam co przed zmianą);
- test spójności: każda nazwa w `index.json` ma plik i odwrotnie; każdy trace ma `schema == 'lockwright.trace/1'`;
- jeśli wydzielisz czyste funkcje geometrii (np. kąt koła → pozycja bramki) do modułu, dodaj im testy jednostkowe.
Uruchomienie: `cd mockups && npm install && node --test tools/lockviz/test/`.

## 4. Zrzuty i raport
- `node mockups/tools/lockviz/shot.mjs <trace> <klatka> docs/handoff/mistral/V03-shots/<trace>.png` — po jednym
  zrzucie na rodzinę w ciekawym momencie (wiązanie, ustawienie, pułapka) + jeden zrzut starej rodziny (regresja).
- `docs/handoff/mistral/V03-REPORT.md` (po polsku): co zrobiłeś, jak czytać każdy schemat (2–3 zdania na rodzinę),
  wynik testów, czego brakuje w trace'ach, propozycja jednego akapitu do `lockcore/README.md` (wpisze sesja A).
