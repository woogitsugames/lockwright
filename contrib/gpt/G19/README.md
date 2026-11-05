# G19 — dwa szkice wyboru sterowania

Dostawa: **2026-11-05**. Dwie wersje beztekstowych szkiców nawiązujących do uproszczonych, grafitowo-kredowych ilustracji notesu mistrza Henryka (G10). Ten sam kadr i proporcje telefonu. Brak marek, logotypów, nazw i wskazówek do mechanizmów konkretnych zamków. Gesty są ilustracją interfejsu gry, nie instrukcją ślusarską.

## Pliki

| Plik | Treść |
|---|---|
| `controls_auto.png` | 768×768; kremowy papier; prawy kciuk, ruch w górę, kredowa kotwica wskazująca samoczynne trzymanie napięcia |
| `controls_auto_alpha.png` | 768×768; ta sama grafika, prawdziwa przezroczystość RGBA |
| `controls_two_thumbs.png` | 768×768; kremowy papier; oba kciuki, dwie strzałki w górę, dwustronny ruch poziomy przy prawym |
| `controls_two_thumbs_alpha.png` | 768×768; ta sama grafika, prawdziwa przezroczystość RGBA |
| `contact-sheet.jpg` | Arkusz porównania czterech wariantów (przezroczystość pokazana szachownicą tylko na arkuszu) |
| `preview_auto_192.png`, `preview_two_thumbs_192.png` | Miniatury 192×192 |
| `preview_auto_96.png`, `preview_two_thumbs_96.png` | Dodatkowe miniatury 96×96, użyte do weryfikacji czytelności |
| `auto.svg`, `two_thumbs.svg` | Edytowalne, beztekstowe grafiki źródłowe z kodu |
| `generate.py` | Deterministyczny generator kompozycji i faktury |
| `ASSETS.md` | Pochodzenie zasobów, pełny prompt i SHA-256 |

## Odbiór i integracja

- Obie ilustracje wykorzystują ten sam obrys telefonu (x=198–568, y=73–701) i ten sam przekrój wymyślonego mechanizmu.
- Nie ma liter, cyfr, etykiet ani emoji na obrazach. Nazwy opcji PL/EN powinny zostać naniesione **w UI gry**, a nie zaszyte w PNG.
- Test pomniejszenia do 96×96: schemat telefonu i liczba kciuków pozostają rozróżnialne; drobne elementy przekroju są celowo drugorzędne.
- Używać `*_alpha.png` na emaliowanych tabliczkach tylko przy wystarczającym kontraście; na ciemnym tle rozważyć jasne przefarbowanie stroke'ów lub jasną podkładkę.
- **Nie modyfikowano** kodu gry ani `docs/DECISIONS.md`. Implementacja D-52 i napisy do przycisków należą do zespołu UI.

## Reprodukcja

```bash
python -m pip install numpy pillow cairosvg
python contrib/gpt/G19/generate.py
```

Grafiki wykonano programowo na bazie autorskich ścieżek SVG, nie z cudzych materiałów. Nie użyto wyników generatora obrazów do produkcji dostarczonych PNG. Przejście przez model obrazowy dało makietę niezwiązaną z tym zleceniem i zostało odrzucone.
