# T30 — README

## Co zrobiono

1. Przeprowadzono niezależny audyt ekonomii, trudności, nagród, grindu i Trybu Ciągłego gry **Lockwright** na podstawie repozytorium `woogitsugames/lockwright`, `main` (analizowany stan `152f95cdda04b17f8554d9f44aa0bbb460c93bbb`).
2. Porównano dokumentację ekonomii z aktualnymi JSON-ami, 29 zleceniami, symulatorem `tools/econ_sim.py` i `lockcore/BALANCE.md`.
3. Zestawiono **historyczne wyniki symulacji** (B i C) oraz policzono **dwa nowe, deterministyczne warianty salda**: premium (1520 monet za zestaw fabularny) i demo + odblokowanie (1350 monet). Dodatkowo sprawdzono stres napraw 10/15 monet na zamek i wariant wypożyczenia narzędzi.
4. Udokumentowano konflikty między danymi, fabułą i symulatorem oraz zaproponowano mierzalne kryteria playtestów.
5. Nie podejmowano decyzji o modelu biznesowym, cenie rynkowej, terminie premiery ani dostępności (D-06/D-51).

## Lista plików

- `contrib/gpt/T30/ECONOMY_REVIEW.md` — raport, aktualne liczby, porównanie, dwa warianty, ryzyka, plan walidacji.
- `contrib/gpt/T30/README.md` — niniejszy wykaz i ograniczenia.

## Co się nie udało / ograniczenia

- Nie uruchomiono oryginalnego `tools/econ_sim.py`. Dostęp przez połączenie GitHub umożliwił odczyt plików, ale kontener lokalny nie miał łączności z `github.com`; nie było pełnego lokalnego checkoutu z 29 plikami zleceń i modułem `lockcore`. **Nie podaję nowych median Monte Carlo** jako zweryfikowanych.
- Testy P/D są **arytmetycznym modelem przepływów pieniężnych**, a nie symulacją rozkładu rozgrywek. Założenia wyszczególniono w raporcie.
- Nie zmieniano danych gry ani kodu symulatora — jedynym dozwolonym miejscem zapisu był `contrib/gpt/T30/`.

## Zalecany następny krok (dla właściciela / sesji odpowiedzialnej za `tools/`)

Najpierw poprawić w symulatorze odczyt bieżącego `tier_curve.formula`, koszt naprawy z JSON, brak środków na naprawę, odblokowania z sufiksami i ścieżkę wypożyczenia. Dopiero potem ponowić bazowe testy, np.:

`python3 tools/econ_sim.py --careers 1000 --out /tmp/lockwright-T30-economy-rerun.md`

Nie zapisywać tego raportu do `docs/` w ramach T30. Wszelkie przyszłe zmiany poza katalogiem T30 wymagają osobnego zlecenia.
