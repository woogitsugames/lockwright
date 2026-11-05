# T18 — Rozdział 8: Zima w kamienicy / Winter in the Tenement

## Wykonane

Przygotowano **12 nowych zleceń**: 10 legalnych interwencji oraz 2 uprzejme odmowy. Każda karta ma rodzinę i tier mechanizmu zgodne z `docs/LOCKS.md`, scenę weryfikacji uprawnienia, cztery kwestie dialogowe po polsku i angielsku, dwujęzyczną notatkę do zeszytu i nagrodę w monetach (0 przy odmowie). Każde zlecenie przewiduje zaakceptowanie wyceny przed pracą. Teksty nie zawierają instrukcji otwierania ani marek producentów.

## Łuk fabularny

**Akt I — Pierwszy mróz (1–4):** zamarznięta kłódka piwniczna, puszka z przepisem i skrzynia kolędników. Oskar prosi o otwarcie mieszkania bez zgody lokatorki — gracz uprzejmie odmawia. Zasada: świąteczne intencje nie zastępują uprawnienia.

**Akt II — Zimne grzejniki (5–8):** mieszkańcy szykują sąsiedzką Wigilię. W kamienicy psuje się ogrzewanie, zarządczyni Elżbieta okazuje dokumentację, a uprawniony technik Paweł zajmuje się instalacją. Druga odmowa dotyczy osoby bez potwierdzonego zlecenia serwisowego. W świetlicy powstaje tymczasowe miejsce dla zmarzniętych sąsiadów.

**Akt III — Ciepłe drzwi (9–12):** druga przemarznięta kłódka, muzealna makieta zimowej ulicy i suszarnia kolędników. Finał: po naprawie systemu ślusarz otwiera legalnie zleconą szafkę kontrolną, a technik kończy przegląd. Ciepło wraca na Wigilię. Bohater nie dotyka urządzeń grzewczych.

## Pliki

1. `jobs/job.frozen_cellar_padlock.json` — Pierwszy mróz; `ring_combo` t2.
2. `jobs/job.halina_christmas_tin.json` — Puszka na pierniki; `warded` t1.
3. `jobs/job.carol_singers_chest.json` — Skrzynia kolędników; `wooden_pin` t1.
4. `jobs/job.refuse_visiting_relative.json` — Krewny pod drzwiami; `pin_tumbler` t2, odmowa.
5. `jobs/job.wigilia_table_drawer.json` — Nakrycia do stołu; `lever` t3.
6. `jobs/job.heating_service_cupboard.json` — Rejestr ogrzewania; `pin_tumbler` t3.
7. `jobs/job.refuse_unapproved_repair.json` — Naprawa bez zgody; `wafer` t2, odmowa.
8. `jobs/job.warm_room_for_neighbours.json` — Ciepła sala dla sąsiadów; `pin_tumbler` t3.
9. `jobs/job.winter_bicycle_cellar.json` — Rowerownia pod śniegiem; `ring_combo` t3.
10. `jobs/job.wooden_winter_village.json` — Drewniane miasteczko zimowe; `wooden_pin` t1.
11. `jobs/job.attic_drying_room.json` — Suszarnia na poddaszu; `lever` t3.
12. `jobs/job.christmas_eve_heat.json` — Ciepło na Wigilię; `lever_detector` t5.

- `content_ch8.csv` — klucze `key,en,pl`, teksty tytułów, klientów, sytuacji, 4 dialogów i notatek; także dialogi następcze dwóch odmów i nazwy nowych postaci.
- `CHARACTERS.md` — 7 nowych postaci epizodycznych: wiek, wygląd, jednozdaniowy charakter.
- `README.md` — niniejszy raport i informacje integracyjne.

## Kontrola

- 12 JSON-ów z poprawną składnią; wszystkie mają `chapter: 8`, `lines.length = 4`, `i18n`, `verification`, `cards`, `threshold`, `reward_coins`.
- 105 unikatowych kluczy PL/EN w CSV, nagłówek dokładnie `key,en,pl`, dane UTF-8 z cudzysłowami zgodnymi z CSV.
- Wszystkie linie dialogów i scen następczych ≤ 90 znaków w każdym języku; notatki do zeszytu ≤ 130 znaków.
- Rodziny i tiery sprawdzone z `docs/LOCKS.md`, w szczególności `lever_detector` t5 (w starszym T09 jest t2, poniżej zakresu dokumentacji).
- Wszyscy mówcy istnieją w `docs/CLIENTS.md` / `contrib/gpt/T09/` lub są opisani w `CHARACTERS.md`.
- Obie odmowy mają 0 monet i wskazują legalne rozwiązanie bez otwierania.

## Co się nie udało / integracja

- Celowo nie zmieniono niczego poza `contrib/gpt/T18/`: ten pakiet **nie jest automatycznie wczytywany w grze**.
- `game/i18n/content.csv` ma kolumnę `keys`, natomiast zlecenie wymagało `key`. Przed scaleniem danych należy zmienić nagłówek na `keys`.
- Istniejący schemat JSON z T09 podaje mówców w `lines`, a teksty dialogów są w CSV. Do działania trzeba scalić dane i18n, zarejestrować rozdział 8 i obsłużyć flagi odmów.
- Pole `threshold` zachowuje skalę 2–3 z danych T09; narracyjne poszlaki w `verification` odpowiadają progom prawa dostępu w `docs/JOBS.md`. Wymaga to sprawdzenia i ewentualnej normalizacji przy integracji.
- Nagrody w monetach i zróżnicowanie świątecznych cen mają charakter projektowy; nie są obietnicą ceny produktu ani terminu wydania (D-06, D-51).
- Nie wykonywano testu runtime Godot ani playtestu; potrzebna jest integracja w katalogach produkcyjnych i walidacja w silniku.
- Nie powstały nowe zasoby graficzne, dźwiękowe ani binarne. Żaden model zamka nie odnosi się do konkretnych produktów.
