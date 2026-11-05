# T25 — raport z wykonania

**Data:** 2026-11-05  
**Repozytorium:** `woogitsugames/lockwright`, gałąź `main`.  
**Status:** audyt statyczny wykonany; kod źródłowy pozostawiony bez zmian.

## Co zrobiono

- Przejrzano kod `lockcore`: C++20, Q16, PCG32, generowanie specyfikacji, siedem rodzin, sesję, boty `scripted/clumsy/feeling`, JSON i replay, weryfikator, testy oraz konfigurację CI.
- Przeczytano kontekst projektu (`CLAUDE.md`, `docs/DESIGN.md`, `CLIENTS.md`, `JOBS.md`, `DECISIONS.md`, szczególnie D-06 i D-51) oraz `lockcore/README.md`.
- Przygotowano **24 uwagi** z `plik:linia`, analizą ryzyka i propozycją diffu. Wskazano testy regresyjne i kolejność wdrożenia.
- Nie zmodyfikowano plików poza katalogiem `contrib/gpt/T25/`.

## Lista oddanych plików

1. `contrib/gpt/T25/REVIEW_LOCKCORE.md` — właściwy przegląd biblioteki.
2. `contrib/gpt/T25/README.md` — ten opis wykonania.

## Co się nie udało / ograniczenia

- **Nie uruchomiono lokalnego builda, `ctest` ani ASan/UBSan.** Próba `git ls-remote` zakończyła się błędem rozpoznania DNS `github.com` w środowisku kompilacji. Przegląd oparto na kodzie odczytanym bezpośrednio z GitHub przez dostępny konektor.
- Nie potwierdzono eksperymentalnie reprodukcji wszystkich usterek; są to ustalenia audytu statycznego z konkretnymi punktami zaczepienia.
- Ze względu na zasadę zlecenia żaden proponowany diff **nie został zastosowany** do `lockcore`.

## Następne działanie dla właściciela

Rozdzielić uwagi P1 na issues i wdrażać po testach granicznych, zachowując kontrolę `rules_version` oraz hashy golden replay.
