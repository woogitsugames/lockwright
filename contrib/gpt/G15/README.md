# G15 — Mapa dzielnicy dla Lockwright

## Wynik

Przygotowano **mapę fikcyjnego Zameczna 4096×4096** bez kółek przy zleceniach oraz **sześć wariantów z narastającymi oznaczeniami rozdziałów 1–6**. Każdy ukończony rozdział dodaje obrys swojego rejonu i trzy odręczne kółka ołówkiem przy adresach. Osobno dostarczono **dwie pinezki i pięć znaczków grafitowych 512×512 PNG z kanałem przezroczystości**, dwujęzyczne dane etykiet i skrypt generujący. Wszystkie nazwy ulic i miejsc są fikcyjne. Mapy nie odnoszą się do prawdziwego miasta.

Styl: papierowa mapa przypięta w warsztacie, naturalny odcień matowego papieru, ślady zagięć, szare kreski kreślarskie, stonowana roślinność i rzeka. Nie wprowadzono estetyki przestępstwa ani gotowych rozwiązań UI. To **ilustracja kartograficzna będąca teksturą rekwizytu**, nie finalny fotorealistyczny render całego warsztatu; oświetlenie i fizyczny materiał papieru powinny być dodane w scenie Godot/Blender.

## Lista plików

| Plik | Opis |
|---|---|
| `maps/zameczno_base.png` | Czysta mapa bez zakreślonych adresów, 4096×4096. |
| `maps/zameczno_chapter_1.png` | Oznaczenia rozdziałów 1–1 narastająco, 4096×4096. |
| `maps/zameczno_chapter_2.png` | Oznaczenia rozdziałów 1–2 narastająco, 4096×4096. |
| `maps/zameczno_chapter_3.png` | Oznaczenia rozdziałów 1–3 narastająco, 4096×4096. |
| `maps/zameczno_chapter_4.png` | Oznaczenia rozdziałów 1–4 narastająco, 4096×4096. |
| `maps/zameczno_chapter_5.png` | Oznaczenia rozdziałów 1–5 narastająco, 4096×4096. |
| `maps/zameczno_chapter_6.png` | Oznaczenia rozdziałów 1–6 narastająco, 4096×4096. |
| `overlays/pin_red.png`, `overlays/pin_brass.png` | Osobne pinezki emaliowana / mosiężna z alfą, 512×512. |
| `overlays/pencil_circle.png` | Ręczne kółko ołówkiem, przezroczystość. |
| `overlays/pencil_arrow.png` | Strzałka ołówkiem, przezroczystość. |
| `overlays/pencil_tick.png` | Znacznik ołówkiem, bez zielonego checkmarka. |
| `overlays/pencil_scribble.png` | Krótkie kreskowanie grafitowe, przezroczystość. |
| `overlays/pencil_dashed_area.png` | Przerywany obrys obszaru, przezroczystość. |
| `labels.json` | Współrzędne na mapie i pełne etykiety PL/EN: 6 rozdziałów, 16 ulic i 13 miejsc. |
| `generate.js` | Deterministyczny generator Node.js bez zależności, do odtworzenia obrazów. |
| `ASSETS.md` | Pełny rejestr pochodzenia i promptów każdej grafiki. |

## Obszary rozdziałów (PL / EN)

| Nr | PL | EN |
|---|---|---|
| 1 | Pierwsza zmiana | First shift |
| 2 | Nocne dyżury | Night calls |
| 3 | Strychy i spadki | Attics and inheritances |
| 4 | Szlak rzemiosła | Craft trail |
| 5 | Droga na dworzec | Road to the station |
| 6 | Skarbiec | The vault |

## Ulice (PL / EN)

| PL | EN |
|---|---|
| Lipowa | Linden Street |
| Wąska | Narrow Street |
| Młynarska | Mill Street |
| Kamienna | Stone Street |
| Zaułek Sąsiadów | Neighbours Lane |
| Targowa | Market Street |
| Podcienia | Arcades Street |
| Nadbrzeżna | Riverside Street |
| Działkowa | Allotment Street |
| Wierzbowa | Willow Street |
| Cechowa | Guild Street |
| Kowalska | Smith Street |
| Torowa | Rail Street |
| Dworcowa | Station Street |
| Portowa | Harbour Street |
| Muzealna | Museum Street |

## Miejsca (PL / EN)

| PL | EN | Rozdział |
|---|---|---|
| Warsztat Henryka | Henryk's Workshop | 1 |
| Stary Rynek | Old Market Square | 1 |
| Osiedle Słoneczne | Sunny Estate | 1 |
| Nocny Rynek | Night Market | 2 |
| Gospoda pod Lipą | Linden Inn | 2 |
| Dębowe Wzgórze | Oak Hill | 3 |
| Ogrody nad Kanałkiem | Canal Gardens | 3 |
| Dziedziniec Cechowy | Guild Courtyard | 4 |
| Stara Kuźnia | Old Forge | 4 |
| Dworzec Dolny | Lower Station | 5 |
| Plac Kolejowy | Railway Yard | 5 |
| Muzeum Mechanizmów | Museum of Mechanisms | 6 |
| Port Rzeczny | River Port | 6 |

## Integracja

- Importować tekstury jako obrazy mapy **4096×4096**, nie wczytywać naraz wszystkich wariantów do pamięci telefonu (rozpakowany RGBA pojedynczego obrazu to około 64 MiB). Przełączać jedną teksturę albo nakładać osobne znaczniki na `zameczno_base.png`.
- Znaczniki przezroczyste mają rozmiar **512×512** i paletę PNG z przeźroczystością `tRNS`; Godot 4.7 powinien wczytać je jako tekstury 2D. Dostosować skalę i punkt zaczepienia do widoku papieru.
- Współrzędne `labels.json` są w pikselach oryginału, początek `(0,0)` w lewym górnym rogu. Etykiety są po polsku i angielsku i nie zostały trwale wrysowane w obrazy (wymóg i18n). Nazwa miasta „Zameczno” jest nazwą własną w obu językach.
- Powtórne generowanie od początku repozytorium: `node contrib/gpt/G15/generate.js`. Skrypt nadpisuje wyłącznie pliki PNG we własnym katalogu `contrib/gpt/G15/`.

## Ustalenia fabularne i zakres

**Rozbieżność źródeł:** `docs/CLIENTS.md` i `docs/PROGRESSION.md` opowiadają o wyjazdach w rozdziałach 4 (Małopolska) i 5 (Belgia), podczas gdy treść zlecenia G15 każe pokazać wszystkie sześć rejonów **jednego fikcyjnego miasta**. Zgodnie z G15 zastosowano obszary umowne: IV = dzielnica rzemieślnicza, V = dojazd do dworca. Nie sugerujemy, że Kraków czy Bruksela leżą w Zamecznie. W finalnym HUD można uzupełnić mapę o fizyczną kartkę z trasami podróży, osobną od mapy miasta; wymaga to decyzji zespołu scenariuszowego.

**Nie udało się / ograniczenia:** pojedyncza tekstura mapy nie jest jeszcze fotorealistycznym zdjęciem kartki na ścianie; nie zawiera światła 3D, cieni od prawdziwych pinezek ani papierowych zagnieceń w geometrii. Nazwy ulic nie są wypalone w PNG z uwagi na lokalizację, ale komplet znajduję się w `labels.json` i powyższych tabelach. Zalecany następny krok: montaż rekwizytu w scenie warsztatu z fizycznym materiałem papieru oraz dynamiczny wybór języka PL/EN.
