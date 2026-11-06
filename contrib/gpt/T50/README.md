# T50 — brakujące tłumaczenia FR/ES UI

Sprawdzono `game/i18n/strings.csv` z gałęzi `main`: 310 rekordów, zero pustych lub zawierających wyłącznie białe znaki komórek w kolumnie `fr` i zero w `es`. Wbrew przybliżeniu w zleceniu w sprawdzonej wersji nie znaleziono brakujących tłumaczeń. `fill_fr_es.csv` zawiera więc wyłącznie wymagany nagłówek; nie zmieniono żadnych istniejących tłumaczeń.

Na lokalnej kopii obu plików CSV uruchomiono `python3 tools/i18n_lint.py`: 948 kluczy, 0 błędów i 2 ostrzeżenia o identycznym z angielskim zapisie zmiennych `{title}: {state}` w PL i DE dla `settings.voice_pack.line`. Wynik: OK (warnings only). Nie wykonywano korekty jakości istniejących tłumaczeń.
