# T32 — hiszpański: druga korekta

Źródło: `contrib/gpt/T13/`. Kontrola wszystkich kluczy EN/PL `game/i18n/*.csv`; założono wariant es-ES, formę `tú`, terminologię ze słowniczka T02 i styl T11.

| Plik | Klucze | Zmienione | Dłuższe >130% EN | Dialogi >90 |
|---|---:|---:|---:|---:|
| strings | 125 | 8 | 19 | 0 |
| content | 629 | 7 | 79 | 0 |

Sprawdzono unikalność identyfikatorów, kompletność oraz zgodność placeholderów z EN. Zmiany z uzasadnieniem w kolumnie `note`. Wymóg skracania nie może eliminować charakteru postaci; krótkie EN często rozszerza się naturalnie w es-ES. Najważniejsze poprawki: zmniejszenie długości dialogu, prostsze etykiety, trafniejsze opisy osiągnięć i zredukowanie bezwzględnego sformułowania o prawie wstępu.

**Ryzyka:** część naturalnych fraz jest >130% długości EN; konieczny przegląd UI na małym ekranie i recenzja es-ES przez niezależnego redaktora. Wariant A nie publikować bez D-06; opisy prywatności i funkcjonalności zweryfikować z wydaniem.
