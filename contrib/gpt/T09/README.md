# T09 — Rozdział 7: Wspólny klucz / A Shared Key

## Co zrobiłem

Przygotowałem 12 samodzielnych zleceń po premierze (rozdział 7): po cztery linie dialogu
PL/EN, dwujęzyczny wpis do zeszytu, sytuację, postać, rodzinę zamka, tier,
weryfikację prawa dostępu i nagrodę. Teksty są oryginalne, bez instrukcji otwierania.
Sceny weryfikacji wymagają podanej wyceny przed wykonaniem usługi.

## Łuk fabularny

**Akt I (1–4):** Znani sąsiedzi zbierają przepisy, stare tabliczki, plakaty i kopie
zdjęć do wspólnej świetlicy. Powrót po finale kapsuły czasu jest codzienny, nie sensacyjny.
**Akt II (5–9):** Ślusarz odmawia otwarcia mieszkania bez zgody lokatorki i później
magazynu bez zgody sklepu. Oba przypadki mają legalne, spokojne rozwiązania.
Między nimi Stefan, Edek i rodzina Oli pomagają zebrać wyposażenie.
**Akt III (10–12):** Gosia przekazuje stół, wspólnota udostępnia gablotę, a zarządczyni
Elżbieta z podpisaną uchwałą zleca otwarcie świetlicy. Bohaterem pozostaje zaufanie.

## Pliki

- `jobs/job.halina_recipe_box.json` — Halina i Zosia; skrzynka z przepisami, rodzinny świadek.
- `jobs/job.roman_service_cupboard.json` — Roman; zgoda zarządcy i wspólnoty, emaliowane numerki.
- `jobs/job.marta_poster_studio.json` — Marta; pracownia z plakatami, najem i świadek.
- `jobs/job.zuzanna_catalogue_drawer.json` — Zuzanna i dr Rygiel; kopie z muzeum, pisemny protokół.
- `jobs/job.refuse_sisters_flat.json` — odmowa bez zgody lokatorki, wskazanie zarządcy.
- `jobs/job.stefan_book_tin.json` — Stefan; puszka na numerki, paragon i zdjęcie.
- `jobs/job.edek_rehearsal_store.json` — Edek i Iga; uczelniane krzesła na zebranie.
- `jobs/job.krystyna_wooden_album.json` — Krystyna i Ola; rodzinna drewniana skrzynka.
- `jobs/job.refuse_unapproved_stockroom.json` — odmowa kurierowi bez zgody właściciela sklepu.
- `jobs/job.gosia_workbench_drawer.json` — Gosia; stół do świetlicy, faktura i zdjęcie odbioru.
- `jobs/job.community_notice_case.json` — Basia i Elżbieta; zgoda na wspólną gablotę.
- `jobs/job.shared_room_door.json` — otwarcie świetlicy na podstawie uchwały i listy uprawnionych.
- `content_ch7.csv` — 103 kluczy `key,en,pl`: tytuły, klienci, sytuacje,
  cztery linie i notatki każdego zlecenia, sceny po wydarzeniu oraz nowe nazwy mówców.
- `ASSETS.md` — potwierdzenie braku nowych grafik, dźwięków i zasobów binarnych.
- `README.md` — opis rozdziału, zasady integracji i niniejszy raport.

## Kontrola i ograniczenia

- Wszystkie 12 plików zachowuje klucze istniejących `game/data/jobs/*.json`.
- `chapter` = 7; `tier` = 1–3 według skali fabularnej istniejących zleceń.
- Rodziny: `pin_tumbler`, `wafer`, `wooden_pin`, `warded`, `lever`,
  `lever_detector`, `ring_combo` (wyłącznie lista z zamówienia).
- Wszystkie dialogi i sceny `after` mają nie więcej niż 90 znaków w obu językach;
  notatki nie przekraczają 130 znaków.
- Dwie odmowy (`refuse_*`) dają 0 monet; sceny następcze pokazują rozwiązanie
  bez otwierania. Zadania z zarządcami korzystają z pisemnej zgody.
- Skala `threshold` pozostaje 2–3 zgodnie z istniejącymi plikami; opis
  `verification` podaje faktyczne źródła uprawnienia. Blokady związane
  z `flag.*` wymagają obsługi w logice sceny weryfikacyjnej.

## Co się nie udało / integracja i propozycje

- Nie zmieniałem plików gry ani jej globalnego CSV: zadanie zabrania zapisu poza T09.
  Z tego powodu nowy rozdział nie jest automatycznie wczytywany w grze.
- Zamówienie wymaga nagłówka `key,en,pl`; istniejący `game/i18n/content.csv`
  ma `keys,en,pl`. Przy scalaniu należy zmienić pierwszy nagłówek na `keys`.
- Przed wdrożeniem: przenieść dane do katalogów produkcyjnych, scalić i18n,
  zarejestrować rozdział 7, podłączyć flagi odmów oraz przeprowadzić playtest
  wycen i weryfikacji. Nie zmieniać lokalizacji ani postaci bez aktualizacji i18n.
