# Odbiór V03 (Mistral Vibe): lockviz — schematy 8 rodzin v0.6 + testy

**Data:** 2026-11-06 · **Odbiera:** sesja A (Claude) · **Brief:** `docs/handoff/mistral/V03-lockviz-new-families.md`
**Raport dostawcy:** `docs/handoff/mistral/V03-REPORT.md`

## Werdykt
**Przyjęte z drobnymi poprawkami.** Każda z 8 rodzin ma własny, czytelny schemat (`families_v06.js`,
dispatch w `drawSchematic()`), stare rodziny bez zmian, testy działają, zakres plików zgodny z briefem.

## Sprawdzone
- **Testy:** `cd mockups && node --test "tools/lockviz/test/*.test.mjs"` → **3/3 zielone** (spójność
  `index.json` ↔ pliki ↔ `lockwright.trace/1`, testy jednostkowe `LOCKVIZ_GEOM`, Playwright: 29 trace'ów ×
  klatki 0 / środek / koniec, bez `pageerror`, `data-ready="1"`, oczekiwany `data-schematic`). U nas Chromium
  działa bez obejść `LD_LIBRARY_PATH`/`FONTCONFIG_FILE` z raportu (to była specyfika ich środowiska).
- **Trace'y:** 16 plików odtworzonych z obecnego `lockcore` (`replay_tool trace` na złotych powtórkach) —
  **bajt w bajt identyczne** z dostarczonymi.
- **Zrzuty:** przejrzane wszystkie 9 (8 rodzin + regresja `pin_tumbler_t7_s4242`). Stany rozróżnialne
  w szarości (wypełnienie, kreskowanie, grubość linii jak w `body()`/`patterns`), bez gradientów i poświaty.

## Poprawki (sesja A)
| Rodzina | Błąd | Poprawka |
|---|---|---|
| `dial_safe` | pokrętło (crank) rysowane **dokładnie w miejscu wskaźnika rdzenia** `drawCore()` (prawy górny róg) — dwa koła i dwa podpisy na sobie | pokrętło przesunięte 120 px w lewo od wskaźnika |
| `dial_safe` | podpis „fence line” nachodził na belkę płotka | podpis na prawym końcu linii |
| `combo` | podpis „cable pull” na linii linki | pod linką |
| `dimple` | rząd boczny i główny dzieliły pionowo to samo miejsce: **podpisy elementów rzędu bocznego wypadały wewnątrz komór rzędu głównego**, etykieta „main row” stała przy złym rzędzie | każdy rząd ma własny pas (komory, pod nimi trzy linie podpisu); etykiety rzędów przy swoich komorach |
| `axial_slider` | podpis elementu na 12:00 nachodził na kółko popychacza i napis „pusher”, na 6:00 na wskaźniki pod schematem | mniejszy pierścień, blok podpisu wyśrodkowany na zewnątrz, „pusher” w podpisie elementu; „press …” w lewym dolnym rogu |
| test | komentarz `node --test tools/lockviz/test/` (na Node 22 nie działa — raport to zauważył) | wzorzec glob w komentarzu |

Zrzuty `dial_safe`, `combo`, `dimple`, `axial_slider` w `docs/handoff/mistral/V03-shots/` podmienione na
wersje po poprawkach. Akapit z raportu wpisany do `lockcore/README.md` (sekcja „Replay debugger (lockviz)”).

## Pozostaje (niekrytyczne)
- `egyptian`: pozioma linia narzędzia (`drawPick`, wspólna z `drawLift`) przecina podpisy elementów 0–1 pod
  ryglem; do rozwiązania razem z `drawLift` (ten sam wzór), nie ruszałem wspólnej funkcji starych rodzin.
- `egyptian`: x narzędzia liczony z ciągłego `pick_depth`, więc w chwili przełączania wypada między kołkami —
  tak samo jak u pinów; zgodne z danymi.
- Braki w trace'ach z raportu V03 (słuszne, do lockcore przy najbliższej zmianie formatu): pasmo
  `band_lo/band_hi` (`dial_safe`) i `[run_lo, tau_safe]` (`time_lock`) poza `frame_fields`; odczyt pokrętła
  `ViewModel::dial` nie jest w trace (lockviz całkuje `view_pick_lift`, działki z tieru); pasy zdarzeń pokazują
  bazowy kind, pod-nazwy tylko na liście zdarzeń.
- `time_lock`: oś `time.tick` jest pusta do chwili, gdy wszystkie koła są zazębione (zgodne z mechaniką, ale
  warto dodać podpis „czeka na zazębienie”).
