# Audyt zgodności z zasadami CLAUDE.md

2026-11-05 · stan `main` po 480603f (+ niezacommitowane WIP innych sesji, oznaczone niżej). Zakres: `docs/`, `game/data`, `game/i18n`, `game/scripts` (wybiórczo), `store/`, `mockups/`, `art/`, `audio/`, `spikes/`.

Właściciele poprawek: **A** = lockcore / art / mockups / docs, **B** = game / platform / data, **C** = spikes / store / audio / v2.

## Metoda

- **Marki zamków i narzędzi** (grep, wielkość liter ma znaczenie tam, gdzie słowo jest pospolite): Abloy, Assa, Medeco, Mul-T-Lock, Kwikset, Schlage, Yale, Master Lock, Abus, EVVA, Gerda, Lob, DOM, Kaba, Dorma, Winkhaus, Cisa, Mottura, Iseo, Fichet, Bricard, Vachette, Keso, Ikon, BKS, Corbin, Sargent, Best, Primus, BiLock, Lips, Chubb, Union, Ingersoll, Squire, ERA, Banham, Mauer, Kale, Sesamee, Brinks, Kryptonite, OnGuard, Trelock, Stanley, Ilco, Silca, Keil, Peterson, Sparrows, SouthOrd, Multipick, HPC, Lishi, Covert Instruments, LockPickingLawyer, BosnianBill, TOOOL.
- **Marki samochodów**: Toyota, VW/Volkswagen, Ford, BMW, Mercedes, Audi, Opel, Škoda, Fiat, Renault, Peugeot, Citroën, Honda, Nissan, Mazda, Hyundai, Kia, Volvo, Saab, Porsche, Ferrari, Lamborghini, Chevrolet, Jeep, Dodge, Chrysler, Tesla, Subaru, Mitsubishi, Suzuki, Lexus, Seat, Dacia, Polonez, Syrena, Maluch, Trabant, Wartburg, Lada, Mini, Land Rover, Jaguar, Alfa Romeo, Lancia, Cadillac, Buick.
- **Ton i „instrukcje”**: włam*, złodziej*, kradzie*, heist, burglar, thief, bypass, obejś*, bump/udarowy, shim, slim jim, impressioning, rake, decod*, drill/wiercen*, karta kredytowa, „bez śladu”, „niezauważ*”.
- **Zasoby**: `git ls-files` wszystkich obrazów, dźwięków, modeli i fontów, porównane z `docs/ASSETS.md`; licencje fontów sprawdzone w plikach OFL obok.
- **Klisze UI**: `backdrop-filter`, emoji, ✓/✗, Inter/Roboto/system-ui, „Welcome”/„Get Started”, neon/bloom w śledzonych plikach makiet.

## Wynik w skrócie

- **Marki samochodów: 0 trafień.** Marki narzędzi i kanałów lockpickingowych: 0.
- **Marki zamków:** tylko nazwiska historyczne (Yale, Chubb, Sargent, Bramah, Hobbs) w notkach Gabloty ze źródłem i w dokumentach, zgodnie z D-08; jedno wymienienie „Master Lock” w researchu rynku (dopuszczalne, nie trafia do gry). Wcześniejsze naruszenie R-31 („Bramah lock.” w zleceniu) jest naprawione.
- **Ton:** w `game/i18n` i `store/` brak słownictwa złodziejskiego; `store/tools/check_lengths.py` ma nawet czarną listę (heist, burglar, włam, napad). Słowa „heist/złodziej” występują tylko w researchu konkurencji.
- **„To gra, nie kurs”**: jest — `game/i18n/strings.csv:67` (`about.notice`, PL + EN), pokazywane przy pierwszym uruchomieniu (`game/scripts/ui/boot.gd:11`) i w „O grze” (`main_menu.gd:32`), także w opisie sklepu (`store/listing.md:76`, `:144`).
- **Wiertarka i metody niszczące**: opisane odpowiedzialnie (`docs/TOOLS.md:89–90`, D-09: mini-gra abstrakcyjna, bez miejsc wiercenia). Nie znaleziono opisów technik obchodzenia realnych, nazwanych produktów.
- **Klisze UI w makietach:** 0 trafień w śledzonych plikach.
- **Fonty:** wszystkie śledzone fonty to OFL; jedna luka w nocie licencyjnej (C-05).
- **ASSETS.md:** brakowało 8 grup plików i jedna licencja była „do weryfikacji” — **naprawione w tym commicie** (A-01, A-02).

## Ustalenia

| ID | Waga | Plik:linia | Problem | Sugerowana poprawka | Właściciel |
|---|---|---|---|---|---|
| C-01 | Medium | `game/scripts/ui/job_verify.gd:14`; `game/data/jobs/*.json` (29 pól `verification`) | Graczowi wyświetla się surowa notatka z biblii treści, tylko po polsku (np. „zdjęcie (1) i paragon (1)… próg 2. Haczyk: brak.”). Łamie zasadę „teksty gracza tylko przez i18n, PL + EN”; to samo co N-04 z przeglądu sesji C, nadal otwarte. | `verification` jako dane (`cards: [{id, weight}]`, `threshold`) + klucze i18n nazw dokumentów; graczowi same przedmioty, bez wag i progu. | B |
| C-02 | Low | `game/data/showcase/showcase.sargent_time_lock.json:4` | Źródło notki pokazywane w grze (`showcase_screen.gd:29`) zawiera domenę działającego producenta zamków do sejfów (`sargentandgreenleaf.com`). Notka jest historyczna (D-08), ale link do strony firmy to w praktyce reklama współczesnej marki. | W danych gry zostawić Britannikę i nekrolog z 1910; link firmowy tylko w `docs/SHOWCASE.md`. | B |
| C-03 | Low | `game/i18n/content.csv:148–211` (klucze `showcase.*.source`, 20 wpisów) | Pola `source` w i18n zawierają notatki redakcyjne z markdownem („- **Pewność:** średnia…”), a kolumna EN ma polskie słowa („historia firmy”, „jw.”). Gra ich dziś nie czyta (źródło idzie z JSON), ale trafiają do `content.*.translation` i są gotową pułapką. | Usunąć klucze `showcase.*.source` z `content.csv` albo wyciąć z nich linie „Pewność” i przetłumaczyć EN; generator i18n nie powinien przenosić metadanych z SHOWCASE.md. | B |
| C-04 | Medium | `game/project.godot` (brak `gui/theme/custom`) | Gra używa wbudowanego fontu Godota jako jedynego kroju (A-04 w `docs/handoff/A11Y-AUDIT.md`), wbrew zakazowi „Inter/Roboto/systemowy jako jedyny krój”. | Motyw projektu z Bona Nova + Atkinson Hyperlegible Next (OFL, skopiować z `mockups/fonts/` razem z plikami OFL) i dopisać kopie do `ASSETS.md`. | B |
| C-05 | Low | `game/addons/gut/fonts/OFL.txt:1–2` | Plik OFL ma notę copyright tylko dla Anonymous Pro; Courier Prime i Lobster Two (też OFL) leżą bez swoich not. OFL wymaga, by nota i licencja towarzyszyły fontowi. Addon jest poza eksportem, więc ryzyko tylko w repo. | Dopisać noty copyright Courier Prime i Lobster Two (z repo google/fonts) albo usunąć nieużywane fonty z addonu. | B |
| C-06 | Info | `.gitignore:2`; `art/renders/test_stair*.json`, `test_stairwell.json` | Testowe PNG renderów (18 plików) są poprawnie ignorowane, ale pliki `test_*.json` z parametrami kadru są śledzone w git. To nie zasoby, tylko dane robocze, więc ASSETS ich nie wymaga. | Przy porządkach zmienić nazwy na docelowe (np. `stairwell.json`) albo dopisać `art/renders/test*.json` do `.gitignore`. | A |
| C-07 | Info | `docs/RESEARCH.md:156` | „Master Lock” w tabeli sprawdzenia tytułu (wynik wyszukiwania App Store). Dokument wewnętrzny, nie trafia do gry ani sklepu. | Bez zmian; nie kopiować do `store/`. | A |
| C-08 | Info | `game/i18n/content.csv:99` (`showcase.henriksson_disc.body`) | Notka o Emilu Henrikssonie opisuje wynalazek, z którego wyrosła działająca marka zamków tarczowych; marka nie pada, opis jest encyklopedyczny. Zgodne z D-08. | Bez zmian; pilnować, by nie dopisać nazwy firmy. | B |
| A-01 | Low | `docs/ASSETS.md:23` | Licencja HDRI `interior.hdr` miała status „do weryfikacji”. | **Naprawione:** potwierdzone w `license.txt` Blendera 4.2.9 (CC0, Greg Zaal / Poly Haven). | A |
| A-02 | Medium | `docs/ASSETS.md` | Brak wpisów dla: `art/renders/section*.png/jpg`, `tray.png`, `loupe.png`; `mockups/realizm/img/*.jpg`; `mockups/*/png/*.png` i `mockups/compare/contact.png`; `game/assets/photoreal/**` (glb, tex, matcap, plate); `game/scenes/photoreal/shots/*.png`; `docs/handoff/img/*.png`; `store/screenshots/contact_*.png`; grafiki GUT (MIT). | **Naprawione:** dopisane wiersze na końcu tabeli. | A |

## Bez uwag

- `store/listing.md`, `store/rating.md`, `store/privacy.md`: rama „pomoc, nie włam”, notka „to gra, nie kurs”, słowa kluczowe bez marek i bez nazw cudzych gier.
- `game/data/jobs/*.json`, `game/data/progression.json`: brak nazwisk i marek (po naprawie R-31).
- `audio/`, `game/assets/audio/`, `spikes/audio-latency/samples/`: wszystkie WAV z własnej syntezy, wpisy w ASSETS kompletne.
- `spikes/**`: zasoby (lit-metal, measure, haptics-latency) mają wpisy; fonty w `spikes/measure` mają pliki OFL obok.
- `mockups/fonts/`: 8 rodzin, każda z plikiem OFL i wpisem w ASSETS.
- `docs/LOCKS.md`, `docs/TOOLS.md`: mechanizmy wymyślone i opisane ogólnie; przy zamku szyfrowym wprost „brak wskazówek o narzędziach dekodujących” (`LOCKS.md:669`).
