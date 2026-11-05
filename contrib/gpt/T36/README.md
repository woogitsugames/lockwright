# T36 — ukraiński: druga korekta

Źródło: `contrib/gpt/T17/`. Zestawienie wszystkich kluczy EN/PL `game/i18n/*.csv`, zasady T02/T11. Formy adresatywne `ви` i naturalna interpunkcja ukraińska.

| Plik | Klucze | Zmienione | Dłuższe >130% EN | Dialogi >90 |
|---|---:|---:|---:|---:|
| strings | 125 | 8 | 9 | 0 |
| content | 629 | 8 | 28 | 0 |

Zweryfikowano kompletność, unikalność identyfikatorów i zgodność wszystkich placeholderów. Zwięzłe etykiety haptyki, dopracowane opisy osiągnięć i złagodzona nieuzasadniona absolutność sformułowań o weryfikacji prawa dostępu. Zmiany w kolumnie `note`. Pozostałe wydłużenia względem EN nie są automatycznie obcinane, gdy ukraińska składnia wymaga pełnej formy.

**Ryzyka:** konieczny test UI i recenzja przez niezależnego redaktora uk-UA; deklaracje prywatności/offline do potwierdzenia; wariant A bez decyzji D-06 nie jest do publikacji. Brak dialogów >90 znaków.
