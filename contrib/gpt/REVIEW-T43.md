# Odbiór T43 (rozdziały 9–12, 30 zleceń) + T52, T61, T62, T63

2026-11-06 · sesja A (agent integracji T43). Źródła: `contrib/gpt/T43/`, `T52/`, `T61/`, `T62/`, `T63/`; kryteria: `CLAUDE.md`, `docs/CLIENTS.md` §1 i §4, D-57…D-68.

## Werdykt
Pakiet dobry: ciepły ton, brak marek i instrukcji, ceny wypowiadane przed pracą, każda kwestia ≤ 90 znaków, brak wykrzykników, rodziny i tiery w zakresach lockcore. Wymagał poprawek fabuły (2 sceny), mówców (1), kart weryfikacji (1), meta-słowa „wymyślony” w sytuacjach oraz obsługi dwóch nowych zakończeń w grze. Wszystko wprowadzone; dane w `game/data/jobs/`, teksty dopisane na końcu `game/i18n/content.csv` (PL/EN po korekcie, DE/FR/ES napisane od zera, rejestr D-67).

## Poprawki treści

| zlecenie | było | jest | powód |
|---|---|---|---|
| `refuse_t43_12_surprise_key` | Darek (z `refuse_ex_partner`) **drugi raz** próbuje wejść do mieszkania byłej partnerki, „z prezentem” | Darek chce wieczorem wejść do zamkniętej **świetlicy wspólnoty** i rozwiesić girlandę; nie chce telefonu do Elżbiety, „bo to niespodzianka”. Ślusarz: „Tu nie otworzę. Zapytajmy ją po cichu, niespodzianka przeżyje.” Dzień po: Elżbieta (udawała zaskoczenie), Stefan | Powrót do byłej partnerki po rozstaniu i odebraniu rzeczy przy policji czyta się jak nękanie (ciężar niezgodny z tonem i z łukiem Darka w CLIENTS §4.3). Nowa scena ma wszystkie 3 takty §4.2 i zostaje odmową, ale lekką, na finał |
| `t43_12_03_community_store` l.4 | mówczyni `zosia`: „Zgoda. Halinko, …” | `elzbieta`: „Zgoda. Pani Halino, garnek też już policzony.” | „Zgoda” na cenę mówi osoba upoważniona (Elżbieta), nie świadek |
| `t43_09_03_wooden_postbox` karty | `invoice`, `witness` | `invoice`, `institution` | w sytuacji jest pismo kuratorki, nie świadek |
| `t43_09_06_draughty_hall` | „boczne wejście **kamienicy**” | „boczne wejście **do bloku**” | Roman administruje blokami Osiedla Słonecznego (CLIENTS §3) |
| `t43_10_01_renovator_bureau` l.4 | „A biurko na nową pracę. Pasuje nam obu.” | „Stary zamek zostaje. Dorobię do niego klucz.” | kwestia była niezrozumiała po polsku |
| `t43_09_08_spare_key_hook` after | „Tym razem bez klucza do mojego mieszkania.” | „Koperta wróciła do mojej szuflady. Pan Kazimierz podpisał ją tym razem dwa razy.” | stara sugerowała, że wcześniej w kopercie był klucz Teresy |
| `t43_10_05_porters_drawer` after | „Kluczy się zgadza.” | „Klucze się zgadzają.” | gramatyka |
| sytuacje 09_02, 10_01, 10_04, 11_01 | „z **wymyślonym** zamkiem …” / *fictional* | bez tego słowa | meta-komentarz dla gracza; „wymyślone mechanizmy” to zasada pisania, nie tekst w grze |
| EN całość | *community room*, pisownia brytyjska | *common room* (jak rozdz. 7), pisownia US (*neighbor, authorization, labeled, practice, Mom, draft*) | spójność z istniejącymi kluczami i normalizacją EN (koordynator) |

## Zgodność z zasadami
- **Odmowy (CLIENTS §4):** 4 sceny (Oskar, Dorota, Alicja, Darek), każda: zgrzyt → propozycja świadka/telefonu → odmowa klienta → „Tu nie otworzę” + inna droga; bez oskarżeń i policji w dialogu; 0 monet, +5 reputacji (prefiks `job.refuse`). Dorota uczy, że **własność nie zastępuje zgody lokatora** — dobra, nowa lekcja.
- **Bez otwierania (2):** `t43_09_08_spare_key_hook`, `t43_11_07_wrong_delivery` — wzór `wrong_floor` (§4.4). Opłata 40 monet za przyjazd.
- **Naprawa zegara (2):** `t43_10_03_exhibit_clock`, `t43_12_07_clock_back_home` — zgodne z D-60 (time_lock = naprawa, drzwi odłączone, „nie przyspieszamy godziny otwarcia”).
- **Legalność weryfikacji:** karty wyłącznie z typów gry (`verify.card.*`), wszystkie obecne w `strings.csv`. `threshold` 2–3 jak w istniejących JSON-ach; gra go nie egzekwuje (karty są rekwizytem, D-04/N-04) — bez zmian, zapisane jako znane ograniczenie.
- **Miejsca/pory:** `place` ∈ {apartment, gate, kiosk, locker, workshop}, `time` ∈ {day, evening, rainy} — wszystkie mają tła G07 i tabliczki (`job_arrival.gd`).
- **Rodziny i tiery** (lockcore `min_tier/max_tier`): magnetic t2, egyptian t2, time_lock t2 (max 2); dial_safe/dimple/disc_detainer/axial_slider t2–t3 (max 3); combo t2–t4 (max 4); lever t3–t5; lever_detector t5; pin t2–t6. Pokrycie płatnych zamków: pin 3, combo 3, lever 3, oraz po 2: magnetic, egyptian, dial_safe, dimple, disc_detainer, axial_slider, time_lock; lever_detector 1. `wafer` tylko w odmowie.

## Ekonomia (D-62)
Nagrody 40–200 (suma 3 433 za rozdz. 9–12, 2 340 za rozdz. 1–6). `tools/econ_sim.py` (C, average): dochód ze zleceń 6 318, narzędzia 2 320 (13/13 osiągalnych kupione do ok. zlecenia 27), **ok. 3 900 monet niewydanych na koniec**. Narzędzia `after_t5` (piórko flagowe, trzpień, obrotnik tarcz) odblokowują się dopiero ok. zlecenia 24–30, czyli po pierwszych zleceniach dimple/axial/disc z rozdz. 9–10 (narzędzia są opcjonalne, więc nic się nie blokuje). Cen wypowiadanych w dialogach nie zmieniałem. **Do decyzji właściciela:** cel dla monet w końcówce (np. kosmetyka warsztatu, gablota) albo spłaszczenie nagród rozdz. 11–12 do ok. 120–160 — wtedy trzeba przegrać ok. 14 kwestii z kwotą.

Dip krzywej: rozdz. 6 płaci 135–150, rozdz. 9 zaczyna od 40–90 (małe sąsiedzkie sprawy). Fabularnie uzasadnione; zostawione.

## Integracja w grze (co zmieniono w kodzie)
- `game/data/jobs/` (nie osobny katalog): lista zleceń, `JobRun.job_by_id`, bot kariery, e2e i walidatory czytają ten katalog; rozdział 7 zostaje w `jobs_ch7` za flagą „po premierze”. Nowe pola: `order` (kolejność w rozdziale, z `flow_t43.json`) i `outcome` (`open`/`talk`/`repair`).
- `jobs_list.gd`: sortowanie po numerze rozdziału (liczbowo), potem `order`, potem id.
- `outcome: talk`: przycisk „Załatw na miejscu”, z weryfikacji prosto do rachunku („Załatwione bez otwierania”, usługa „Konsultacja na miejscu”), bez napiwku, bez dźwięku drzwi, nie liczy się do `locks_opened`.
- `outcome: repair`: zwykła scena `time_lock` → `Events.lock_opened` (osiągnięcie `clock_repaired`), rachunek „Zegar naprawiony” (wspólne z T54).
- `flow_t43.json` nie jest czytany przez grę (zastąpiony polami `order`/`outcome`).

## Znane braki (poza tym zleceniem)
- Rozdział 8 (T18) nadal tylko w `contrib`; rozdział 7 za flagą. W karierze po rozdz. 6 od razu jest 9 — w tekstach T43 są odwołania do sąsiedzkiej Wigilii i świetlicy (rozdz. 7–8). Rekomendacja: włączyć T18 i zdjąć flagę z rozdz. 7.
- Sceny „dzień po” (`after`) są w danych, ale gra ich jeszcze nie wyświetla (także po odmowie).
- Portrety 5 nowych postaci: zlecenie `docs/handoff/gpt6/G24-portraits-t43.md`; do tego czasu tabliczka z inicjałem.
- Wokalizacje bez słów S03v2 (8 emocji) dla 9 nowych postaci: brak (kwestie mówione D-57 są).

## T52 (dzień po, 34 zlecenia)
Mówcy zgodni z dialogami. Ok. połowa kwestii była zbyt ogólna („W domu znów spokojnie.”) — przepisane z konkretnym szczegółem z zlecenia (np. Kuba: „Dostałem tę pracę. Rower zostaje, kod zapiszę.”, Agnieszka: „Spałam jedenaście godzin.”). FR/ES dopisane. Klucze `job.<id>.after.1`, JSON `after: [mówca]`.

## T61 / T62 / T63
- T61: 33 tagi kwestii dopisane do `contrib/voice/tags.json` (tagi `after` pominięte — nie są nagrywane). Tagi oszczędne, pasują.
- T62: prompty poprawne, ale ogólnikowe („neutral Polish accent” przy każdym); rozszerzone o charakter z `cast_t43.csv`. Dodane 4 postacie z T18 (Janka, Leon, Mila, Oskar), które w T43 pierwszy raz mówią. Głosy wybrane z 3 próbek wg F0 i czytelności ASR (`game/data/voice_cast.json`).
- T63: usunięte „consistent with the existing Lockwright portraits” (generator nie zna gry), dodany wiek/nastrój; brief w G24.
