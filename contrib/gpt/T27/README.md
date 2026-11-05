# T27 — GUT: testy scenariuszy brzegowych

**Repo:** \`woogitsugames/lockwright\` · **silnik:** Godot 4.7.x (w projekcie 4.7.2) · **zakres zmian:** tylko \`contrib/gpt/T27/\`.

## Wynik

Przygotowano **54 testów GUT** w siedmiu plikach testowych oraz wspólną klasę-fixture \`t27_fixture.gd\`. Testy celują w rzeczywiste sceny, autoloady i API z \`game/\`, zamiast używać niezależnych atrap logiki. Każda funkcja testowa ma komentarz opisujący sprawdzany warunek.

**Uwaga:** liczba w sekcji wynikowej poniżej jest automatycznie weryfikowana przez zliczenie funkcji \`test_*\` przed commitem; w przypadku rozbieżności prawidłowa jest liczba z weryfikacji. Testów nie uruchomiono w Godot w tej sesji (brak lokalnego binarium i zasobów/importu projektu). Nie oznacza to zielonego CI.

## Pliki

- \`tests/t27_fixture.gd\` — zapis/przywracanie danych \`user://\` i stanu singletonów, fabryka scen/zleceń;
- \`tests/test_t27_interruptions.gd\` — pauza, utrata fokusu, powrót, brak tyknięć w pauzie;
- \`tests/test_t27_save_migration.gd\` — zapis w czasie zlecenia, wypłaty, uszkodzony plik, migracje;
- \`tests/test_t27_language_runtime.gd\` — PL/EN w trakcie gry, odświeżenie UI, fallback;
- \`tests/test_t27_text_scale.gd\` — 200% w Theme, ustawieniach i minimalne cele dotykowe;
- \`tests/test_t27_dark_mode.gd\` — ciemność w obu ekranach zamka i ustawienia dostępności;
- \`tests/test_t27_refusal.gd\` — odmowa, zakaz otwierania, reputacja +5 jednokrotnie, brak zapłaty;
- \`tests/test_t27_no_haptics.gd\` — brak mostka natywnego, wyłączona haptyka i kanały zastępcze.

## Uruchomienie (integracja w sesji B)

Pliki są dostarczone **do wpięcia**. Godot traktuje \`game/\` jako katalog \`res://\`, dlatego sama ścieżka \`contrib/gpt/T27/tests/\` nie jest widoczna w projekcie. Sesja B powinna wykonać:

\`\`\`bash
cp contrib/gpt/T27/tests/*.gd game/tests/gut/
godot --headless --path game --import
godot --headless --path game -s res://addons/gut/gut_cmdln.gd -gdir=res://tests/gut -gprefix=test_t27_ -gexit
\`\`\`

Zalecana jest izolacja katalogu danych użytkownika w CI; fixture cofa zapis i ustawienia **po każdym teście**, odtwarzając dokładne bajty plików zastanych przed testem. Uruchomienie poza środowiskiem testowym na kopii projektu jest bezpieczniejszą praktyką.

## Oczekiwane regresje / ograniczenia

1. **R-03 — fotorealistyczny zamek i przejście w tło.** \`game/scripts/photoreal/lock_photoreal.gd\` nie łączy sygnału \`focus_exited\` z automatyczną pauzą, w przeciwieństwie do \`game/scripts/lock/lock_scene.gd\`. Test \`test_photoreal_background_event_is_connected\` jest świadomie **czerwonym testem regresyjnym** do naprawy w sesji B.
2. **PL/EN na ekranach już otwartych.** \`job_verify.gd\` i klasyczny \`lock_scene.gd\` przypisują napisy w \`_ready()\`, ale nie reagują na \`I18n.language_changed\`. Testy \`test_open_verification_relabels_on_language_change\` i \`test_legacy_pause_relabels_on_language_change\` powinny wykryć brak odświeżenia. \`main_menu.gd\` i \`settings_screen.gd\` mają już obsługę tego sygnału.
3. **Save nie zapisuje mechanizmu w połowie otwierania.** \`Save\` przechowuje progres kariery; \`JobRun.current_job\` jest w pamięci procesu, a nie w \`save.json\`. Test potwierdza aktualny kontrakt: brak wypłaty przed ukończeniem i brak serializacji bieżącej symulacji. Wymaganie „kontynuuj dokładnie z miejsca po zabiciu procesu” **nie jest zaimplementowane** i wymaga nowej decyzji architektonicznej; nie udajemy, że zostało przetestowane pozytywnie.
4. **Brak rzeczywistego urządzenia mobilnego.** GUT headless sprawdza logikę oraz kontrolki. Nie potwierdza zachowania Android lifecycle, wibracji silnika, czytelności na ekranie 200%, prawdziwego kontrastu ani safe-area w notch; to osobne testy urządzeniowe.
5. **Odmawianie:** testy wywołują \`_refuse()\` i sprawdzają zapis/wyłączenie przycisków **przed** 1,2-sekundowym opóźnieniem i przejściem sceny. Nie sprawdzają końcowej nawigacji, aby nie niszczyć drzewa testów GUT.

Nie wprowadzano poprawek do plików gry ani do dokumentów poza własnym katalogiem, zgodnie ze zleceniem.

## Zasady

Gry dotyczą legalnego ślusarza i abstrakcyjnych mechanizmów. Komentarze techniczne nie zawierają instrukcji dotyczących realnych, markowych zamków. Nie podano ceny, premiery ani obietnic dostępności (D-06, D-51). Nazwy i komunikaty testów są techniczne i nie są tekstami dla gracza.
