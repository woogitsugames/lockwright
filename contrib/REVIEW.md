# Przegląd dostaw ChatGPT (`contrib/gpt/`)

Prowadzi: sesja C (etap 4, zadanie 2). Plików nie przenoszę do gry — robi to sesja A po statusie **przyjęte**.
Statusy: **przyjęte** · **do poprawki** (lista braków, autor może poprawić w tym samym katalogu) · **odrzucone** (powód) · *brak dostawy*.

Sprawdzam każdą dostawę według: (1) kryteriów odbioru ze zlecenia `docs/handoff/gpt/<ID>-*.md`; (2) zasad: zero marek i logotypów, zero podobieństwa do prawdziwych osób i dokumentów, zakazane klisze z `DESIGN.md`/`CLAUDE.md`, ton bez estetyki złodzieja; (3) `ASSETS.md` z narzędziem i pełnym promptem dla każdego pliku (D-42); (4) jakości technicznej: rozdzielczość, bezszwowość (podgląd 2×2), onset i LUFS dźwięków, poprawność CSV/JSON.

Automat dowodów: `python3 qa/contrib/check_gpt.py [ID…]` → `qa/out/contrib/<ID>/` (arkusz miniatur `contact.jpg`, podglądy `*_2x2.jpg`, `report.json`: rozmiary, wskaźnik szwu, onset/LUFS/true peak, łączenie pętli, CSV/JSON, słowa marek i tonu). Werdykt wpisuję ręcznie po obejrzeniu arkuszy.

## Stan

| ID | Zlecenie | Status | Runda | Powód / braki |
|---|---|---|---|---|
| G01 | Emaliowane tabliczki mieszkań | *brak dostawy* | 2026-11-05 10:25 | — |
| G02 | Faktury skóry zwijki narzędziowej | *brak dostawy* | 2026-11-05 10:25 | — |
| G03 | Faktury drewna drzwi i ramiaków | **do poprawki** | 2026-11-05 11:10 | W repo są tylko skrypty (`generate_textures.py`, `quality_checks.py`) i README; mapy PNG, referencje i podglądy 2×2 są „w ZIP-ie poza repozytorium” — nie da się ich sprawdzić ani odebrać. Wgrać 4×(albedo/height/roughness 2048²) + 2 referencje + podglądy do `contrib/gpt/G03/` (≤ 20 MB/plik); skryptów z zewnątrz nie uruchamiam. |
| G04 | Ściany klatki schodowej | *brak dostawy* | 2026-11-05 10:25 | — |
| G05 | Posadzki: lastryko, deski, płytki | *brak dostawy* | 2026-11-05 10:25 | — |
| G06 | Zbliżenia metalu: obróbka i zużycie | *brak dostawy* | 2026-11-05 10:25 | — |
| G07 | Koncepty: przyjazd do klienta | **przyjęte** | 2026-11-05 11:10 | 10 kadrów 1080×2340 (9:19,5) + arkusze; fotorealistyczne, spójne ciepłe światło, dół kadru spokojny; numery mieszkań czytelne (12, 7, 5, 9), brak marek i postaci; ASSETS z promptami ✅. Uwaga dla A: WebP → do gry przekonwertować. |
| G08 | Koncepty: warsztat ślusarza | **przyjęte** | 2026-11-05 11:10 | 11 obrazów + arkusz + opisy; warsztat ciepły, bez estetyki złodzieja; wytrychy na tablicy i gablota z wymyślonymi zamkami — kontekst fachu. Rozdzielczość pion 720×1560 (niska na 4K — do tła UI wystarczy, do key artu nie). Na kopiarce do kluczy nie widać marki (sprawdzić w pełnej rozdzielczości przy imporcie). |
| G09 | Portrety postaci (fikcyjne) | *brak dostawy* | 2026-11-05 10:25 | — |
| G10 | Zeszyt mistrza Henryka | **przyjęte** | 2026-11-05 11:10 | 20 stron SVG 1600×2200 (okładka, 5 zasad PL/EN, 10 diagramów, puste strony) + arkusz; teksty poprawne PL/EN, każdy diagram z dopiskiem „Schemat gry, nie instrukcja”; stany (stopka = set) zgodne z DESIGN §1. Format SVG zamiast PNG — lepiej (skalowalne); A wyeksportuje PNG. |
| G11 | Kartki samouczka | *brak dostawy* | 2026-11-05 10:25 | — |
| G12 | Ikona aplikacji | *brak dostawy* | 2026-11-05 10:25 | — |
| G13 | Grafiki sklepowe i key art | *brak dostawy* | 2026-11-05 10:25 | — |
| G14 | Rekwizyty papierowe: zlecenia, rachunki, dokumenty | *brak dostawy* | 2026-11-05 10:25 | — |
| G15 | Mapa dzielnicy | **przyjęte** | 2026-11-05 11:10 | Mapa 4096² „Zameczno” (fikcyjna) + 6 wariantów rozdziałów + 7 znaczków 512²; nie odwzorowuje prawdziwego miasta; `labels.json` poprawny. Słowa „burglar/thief” w ASSETS.md są w promptach negatywnych („no …”) — OK. |
| G16 | Gablota: karty eksponatów | *brak dostawy* | 2026-11-05 10:25 | — |
| S01 | Muzyka: motyw główny i menu | **przyjęte (odsłuch właściciela)** | 2026-11-05 11:10 | 9 utworów OGG + MIDI + render; pętle bez skoku na łączeniu (`seam_slope_mismatch` ≈ 0,04–0,06), wersja „w zamku” ma −32 dB w 2–6 kHz (spektrogram załączony); −16 LUFS I — przy imporcie ściszyć do szyny muzyki (`audio/v2/README.md`: otoczenie −35). Słowa „włamanie/łup” w README — w zakazach („bez …”). Nie odsłuchiwałem. |
| S02 | Dźwięki otoczenia i foley kamienicy | **przyjęte z uwagą** | 2026-11-05 11:10 | 39 WAV 48 kHz (zlecenie: min. 40 plików — brakuje 1 dźwięku; razem z dokumentacją 47 plików), onset ≤ 0,3 ms, M −35…−21 LUFS, bez przesterów; synteza skryptem (brak cudzych sampli). Do dorobienia 1 plik albo przyjąć 39. |
| S03 | Głosy postaci bez słów | **przyjęte warunkowo** | 2026-11-05 11:10 | 96 plików 48 kHz, tabela postać→pliki ✅. Głośność M −15,7…−13,8 LUFS — ok. 10 dB głośniej niż nagrody (−25) → normalizacja do ok. −28 M przy imporcie. **Wymaga odsłuchu**, czy nie da się usłyszeć słów (kryterium odbioru) — automat tego nie oceni. |
| S04 | Dźwięki interfejsu diegetycznego | **przyjęte** | 2026-11-05 11:10 | 96 WAV (min. 84), onset ≤ 1,4 ms (kryterium ≤ 2 ms ✅), M −35,6…−22,1 LUFS, bez przesterów, `manifest.json` poprawny. Przy imporcie zestawić z `audio/v2/out/ui` (te same kategorie — wybrać lepsze). |
| T01 | Korekta angielskich dialogów | **przyjęte** | 2026-11-05 11:10 | `content_en_reviewed.csv`: 207 kluczy, wszystkie istnieją w `content.csv`, kolumny key/en_old/en_new/note; uzasadnienia w `note`. |
| T02 | Korekta EN: interfejs i sklep | **przyjęte** | 2026-11-05 11:10 | 100% kluczy EN (356 + 105), słowniczek 79 terminów (≥ 40), opisy sklepu z policzonymi znakami. „Yale”, „Sargent” to nazwiska historyczne z istniejących notek gabloty (już w `content.csv`), nie nowe marki. |
| T03 | Lokalizacja na niemiecki (szkic) | **przyjęte** | 2026-11-05 11:10 | DE 100% (356 + 105, 0 pustych), lista ryzyk długości, słowniczek. Automat zgłosił „brak narzędzia w ASSETS” — fałszywy alarm (brak zasobów binarnych, tak zadeklarowano). |
| T04 | Sprawdzenie faktów: notki gabloty | **przyjęte** | 2026-11-05 11:10 | Każda notka oceniona ze źródłami; źródła muzealne/patentowe/encyklopedyczne (patents.google, Gutenberg, Science Museum, Europeana, Linda Hall…), bez stron producentów. |
| T05 | Zgodność z zasadami sklepów | **przyjęte** | 2026-11-05 11:10 | 98 punktów listy kontrolnej (≥ 20) z odnośnikami do wytycznych; słowa „łup/złodziej/loot” to opis ryzyk (czego unikać). Porównać z `store/rating.md` §3 przy następnej aktualizacji. |
| T06 | Krytyka wizualna: czy wygląda na grę za miliony | **przyjęte** | 2026-11-05 11:10 | 22 poprawki (≥ 15) z odniesieniami do plików i uzasadnieniem. |
| T07 | Aktualizacja analizy konkurencji | **przyjęte** | 2026-11-05 11:10 | 29 tytułów (≥ 15) ze źródłami, sekcja „Luki rynkowe…” jest; słowa „heist/thief” opisują konkurencję. |
| T08 | Plan playtestów | **przyjęte** | 2026-11-05 11:10 | Plan, arkusz obserwacji, ankiety PL/EN (20 pytań, wszystkie opcjonalne, bez e-maili, imion i dokładnego wieku). |
| T09 | Nowe zlecenia: rozdział 7 | **przyjęte** | 2026-11-05 11:10 | 12 plików JSON z tymi samymi polami co istniejące zlecenia (+ `after` w zleceniach odmowy), `content_ch7.csv` PL/EN, wszystkie linie ≤ 90 znaków. Alarm „ASSETS bez promptów” — fałszywy (brak zasobów binarnych). Przed importem: `data/tools/validate.py` na kopii z nowymi zleceniami (B). |
| T10 | Osiągnięcia, wskazówki ekranu ładowania, wpisy zeszytu | **do poprawki (drobne)** | 2026-11-05 11:10 | Limity znaków dotrzymane, zero instruktażu. Ale `achievement.pin_master` / `wafer_master` w EN: „…pin master lock…”, „…wafer master lock…” — „Master Lock” to nazwa prawdziwego producenta kłódek; zmienić na np. „master-tier pin lock” / „the fifth master pin lock” → lepiej „the fifth master-level pin tumbler”. |

## Rundy

- **2026-11-05 10:25** — `contrib/gpt/` zawiera tylko `README.md`; dostaw 0 z 30.
- **2026-11-05 11:10** — 19 dostaw (G03, G07, G08, G10, G15, S01–S04, T01–T10): przyjęte 17 (w tym warunkowo / z uwagą: S01, S02, S03), do poprawki 2 (G03 — brak plików w repo; T10 — „master lock”), odrzucone 0; bez dostawy 11 (G01, G02, G04–G06, G09, G11–G14, G16). Dowody: `qa/out/contrib/` (automat), arkusze obejrzane ręcznie.
