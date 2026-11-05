# Zlecenie V01 (Mistral Vibe): automatyczne sprawdzanie tłumaczeń i spisu zasobów

**Repo:** `woogitsugames/lockwright`, gałąź `main`. Przeczytaj najpierw `CLAUDE.md`: kod i komentarze po angielsku, raport po polsku.
**Zasada pracy:** zrób, wypchnij na `main` małymi commitami i skończ. Integrację, sprawdzenie i scalanie robi sesja A (Claude).
**Twoje pliki (tylko te):** `tools/i18n_lint.py`, `tools/assets_lint.py`, `tools/tests/` (testy tych skryptów), `.github/workflows/lint.yml` (nowy plik), `docs/handoff/mistral/V01-REPORT.md`. **Nie zmieniaj niczego innego.** W `game/` i w innych workflowach pracują równolegle inni agenci. Jeśli lint znajdzie błędy w plikach gry, **nie poprawiaj ich**, tylko wypisz je w raporcie.

## 1. `tools/i18n_lint.py`
Sprawdza `game/i18n/strings.csv` i `game/i18n/content.csv` (nagłówek `keys,en,pl,de`, UTF-8, pola z przecinkami w cudzysłowie):
1. poprawny CSV, brak duplikatów kluczy, brak pustych wartości w `en`, `pl`, `de`;
2. te same placeholdery `{nazwa}` we wszystkich językach;
3. każdy klucz użyty w kodzie (`I18n.t(&"klucz")` i `I18n.t("klucz")` w `game/**/*.gd`) istnieje w CSV. Klucze budowane dynamicznie (np. `"cast.%s.name"`) wypisz jako ostrzeżenie, nie błąd;
4. limit długości: klucze `tutorial.*` i `lock.*` mają ≤ 56 znaków w każdym języku, `menu.*` ≤ 28;
5. **ostrzeżenia** (nie błędy): proste cudzysłowy `"` w PL zamiast „…”, angielskie słowa zostawione w PL/DE (wartość identyczna jak `en`, dłuższa niż 3 znaki i nie nazwa własna), słowo „włam” w dowolnej formie (zakazane tonem gry).

Wyjście: czytelna lista (plik:linia, klucz, problem), na końcu podsumowanie. Kod wyjścia 1 tylko przy błędach.

## 2. `tools/assets_lint.py`
1. Każdy plik binarny w `game/assets/**` (png, jpg, webp, wav, ogg, ttf, otf, glb), z pominięciem `.import`, jest wymieniony w `docs/ASSETS.md`. Wystarczy wpis pliku albo jego katalogu; dopasowanie po ścieżce lub nazwie katalogu, czytelnie udokumentowane.
2. Każdy font w repo ma licencję OFL. Sprawdź obecność `OFL.txt` lub wpisu „OFL” w ASSETS.md przy tym foncie.
3. Żaden plik w `game/assets` nie przekracza 8 MB. Wypisz 20 największych.

## 3. Testy i CI
- `tools/tests/test_i18n_lint.py`, `test_assets_lint.py` (pytest, małe dane testowe w `tools/tests/data/`).
- `.github/workflows/lint.yml`: na push i PR, Python 3.12, uruchamia testy i oba linty. Na start zostaw `continue-on-error: true` dla samych lintów (żeby obecne błędy nie blokowały CI), testy skryptów muszą przechodzić. Dodaj `concurrency` z `cancel-in-progress: true` i `timeout-minutes: 10`, jak w pozostałych workflowach.

## 4. Raport `docs/handoff/mistral/V01-REPORT.md` (po polsku)
- co zrobiłeś, jak uruchomić lokalnie;
- **pełna lista znalezionych błędów i ostrzeżeń** w obecnym repo, pogrupowana: i18n błędy, i18n ostrzeżenia, zasoby bez wpisu, za duże pliki.

## Kryteria odbioru
- `python tools/i18n_lint.py` i `python tools/assets_lint.py` działają z katalogu głównego repo;
- testy przechodzą;
- workflow jest poprawnym YAML;
- poza swoimi plikami niczego nie zmieniłeś.

Commity: `mistral/V01: <opis>`.
