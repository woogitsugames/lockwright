# Przegląd V01 (Mistral Vibe): lint i18n + zasobów

## Przyjęte
- `tools/i18n_lint.py`, `tools/assets_lint.py`, `tools/tests/` (15 testów, zielone), `.github/workflows/lint.yml`.
- Kod czytelny, kody wyjścia poprawne (1 tylko przy błędach), ostrzeżenia o kluczach dynamicznych nie blokują.
- lint.yml: sensowny (Python 3.12, pytest, `concurrency`, timeout 10 min).

## Poprawki
- `tutorial.frame_lift_auto` skrócony (EN 48, PL 53, DE 46 znaków; limit 56). PL używa „pin”. Zniknęło zdanie „Napięcie trzyma gra” – tę informację niesie `tutorial.note_game`/ramka wcześniejsza.
- `docs/ASSETS.md`: dodany wpis dla `game/assets/fonts/BonaNova-Regular.ttf` i `BonaNova-Bold.ttf` (OFL). Pozostałe zasoby z raportu były już wpisane.
- `lint.yml`: usunięte `continue-on-error: true` – oba lintery są zielone (0 błędów), więc bramkują CI.

## Pozostałe
- `assets_lint.is_listed` dopuszcza dopasowanie samej nazwy pliku w dowolnym katalogu (wpis `mockups/fonts/X` w ASSETS.md może „pokryć” `game/assets/.../X`) – możliwy fałszywy negatyw. Do zaostrzenia przy następnym zleceniu.
- 3 ostrzeżenia o dynamicznych kluczach (`cast.%s.name`, `%s.line.%d`, `verify.card.%s`) – wymagają ręcznej weryfikacji, że klucze istnieją w CSV.
