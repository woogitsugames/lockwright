# Przegląd dostaw ChatGPT (`contrib/gpt/`)

Prowadzi: sesja C (etap 4, zadanie 2). Plików nie przenoszę do gry — robi to sesja A po statusie **przyjęte**.
Statusy: **przyjęte** · **do poprawki** (lista braków, autor może poprawić w tym samym katalogu) · **odrzucone** (powód) · *brak dostawy*.

Sprawdzam każdą dostawę według: (1) kryteriów odbioru ze zlecenia `docs/handoff/gpt/<ID>-*.md`; (2) zasad: zero marek i logotypów, zero podobieństwa do prawdziwych osób i dokumentów, zakazane klisze z `DESIGN.md`/`CLAUDE.md`, ton bez estetyki złodzieja; (3) `ASSETS.md` z narzędziem i pełnym promptem dla każdego pliku (D-42); (4) jakości technicznej: rozdzielczość, bezszwowość (podgląd 2×2), onset i LUFS dźwięków, poprawność CSV/JSON.

Automat dowodów: `python3 qa/contrib/check_gpt.py [ID…]` → `qa/out/contrib/<ID>/` (arkusz miniatur `contact.jpg`, podglądy `*_2x2.jpg`, `report.json`: rozmiary, wskaźnik szwu, onset/LUFS/true peak, łączenie pętli, CSV/JSON, słowa marek i tonu). Werdykt wpisuję ręcznie po obejrzeniu arkuszy.

## Stan

| ID | Zlecenie | Status | Runda | Powód / braki |
|---|---|---|---|---|
| G01 | Emaliowane tabliczki mieszkań | *brak dostawy* | 2026-11-05 10:40 | — |
| G02 | Faktury skóry zwijki narzędziowej | *brak dostawy* | 2026-11-05 10:40 | — |
| G03 | Faktury drewna drzwi i ramiaków | *brak dostawy* | 2026-11-05 10:40 | — |
| G04 | Ściany klatki schodowej | *brak dostawy* | 2026-11-05 10:40 | — |
| G05 | Posadzki: lastryko, deski, płytki | *brak dostawy* | 2026-11-05 10:40 | — |
| G06 | Zbliżenia metalu: obróbka i zużycie | *brak dostawy* | 2026-11-05 10:40 | — |
| G07 | Koncepty: przyjazd do klienta | *brak dostawy* | 2026-11-05 10:40 | — |
| G08 | Koncepty: warsztat ślusarza | *brak dostawy* | 2026-11-05 10:40 | — |
| G09 | Portrety postaci (fikcyjne) | *brak dostawy* | 2026-11-05 10:40 | — |
| G10 | Zeszyt mistrza Henryka | *brak dostawy* | 2026-11-05 10:40 | — |
| G11 | Kartki samouczka | *brak dostawy* | 2026-11-05 10:40 | — |
| G12 | Ikona aplikacji | *brak dostawy* | 2026-11-05 10:40 | — |
| G13 | Grafiki sklepowe i key art | *brak dostawy* | 2026-11-05 10:40 | — |
| G14 | Rekwizyty papierowe: zlecenia, rachunki, dokumenty | *brak dostawy* | 2026-11-05 10:40 | — |
| G15 | Mapa dzielnicy | *brak dostawy* | 2026-11-05 10:40 | — |
| G16 | Gablota: karty eksponatów | *brak dostawy* | 2026-11-05 10:40 | — |
| S01 | Muzyka: motyw główny i menu | *brak dostawy* | 2026-11-05 10:40 | — |
| S02 | Dźwięki otoczenia i foley kamienicy | *brak dostawy* | 2026-11-05 10:40 | — |
| S03 | Głosy postaci bez słów | *brak dostawy* | 2026-11-05 10:40 | — |
| S04 | Dźwięki interfejsu diegetycznego | *brak dostawy* | 2026-11-05 10:40 | — |
| T01 | Korekta angielskich dialogów | *brak dostawy* | 2026-11-05 10:40 | — |
| T02 | Korekta EN: interfejs i sklep | *brak dostawy* | 2026-11-05 10:40 | — |
| T03 | Lokalizacja na niemiecki (szkic) | *brak dostawy* | 2026-11-05 10:40 | — |
| T04 | Sprawdzenie faktów: notki gabloty | *brak dostawy* | 2026-11-05 10:40 | — |
| T05 | Zgodność z zasadami sklepów | *brak dostawy* | 2026-11-05 10:40 | — |
| T06 | Krytyka wizualna: czy wygląda na grę za miliony | *brak dostawy* | 2026-11-05 10:40 | — |
| T07 | Aktualizacja analizy konkurencji | *brak dostawy* | 2026-11-05 10:40 | — |
| T08 | Plan playtestów | *brak dostawy* | 2026-11-05 10:40 | — |
| T09 | Nowe zlecenia: rozdział 7 | *brak dostawy* | 2026-11-05 10:40 | — |
| T10 | Osiągnięcia, wskazówki ekranu ładowania, wpisy zeszytu | *brak dostawy* | 2026-11-05 10:40 | — |

## Rundy

- **2026-11-05 10:40** — `contrib/gpt/` zawiera tylko `README.md`; dostaw 0 z 30.
