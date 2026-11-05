# T35 — czeski: druga korekta

Źródło: `contrib/gpt/T16/`. Porównanie wszystkich kluczy względem EN/PL w `game/i18n/*.csv`, z wytycznymi T02 i T11.

| Plik | Klucze | Zmienione | Dłuższe >130% EN | Dialogi >90 |
|---|---:|---:|---:|---:|
| strings | 125 | 7 | 1 | 0 |
| content | 629 | 8 | 6 | 0 |

Zweryfikowano unikalność, kompletność i placeholdery. Zmieniono niektóre formy wymagające odmiany zależnej od `{n}`, co jest bezpieczniejsze niż dołączanie zmiennej do przypadku rzeczownika. Poprawiono znaczenie tokenów bibliotecznych i skrócono notatkę. Wszystkie dialogi mieszczą się w 90 znakach. `note` zawiera uzasadnienia zmian.

**Ryzyka:** skrótowe nazwy wymagają sprawdzenia w UI gry; dodatkowy redaktor cs-CZ powinien wykonać recenzję końcową. Deklaracje sklepowe, prywatność, offline i wariant A (D-06) wymagają zatwierdzenia przed publikacją.
