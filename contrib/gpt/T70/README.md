# T70 — dostępność opisów i czytnika ekranu

## Zakres i ograniczenia

Analiza `game/i18n/strings.csv`, `game/scripts/ui/main_menu.gd`, `settings_screen.gd`, `screen_frame.gd` i `game/scripts/autoload/ui_a11y.gd`. Nie sprawdzono wszystkich ekranów, wszystkich scen `.tscn`, integracji natywnej ani działania TalkBack/VoiceOver. Brak klucza `*.a11y` nie dowodzi, że kontrolka nie ma nazwy: istniejący, widoczny tekst może być poprawną nazwą dostępną.

## Ustalenia

1. **Menu główne — zaimplementowane nazwy, wymagany test na urządzeniu.** `main_menu.gd` wymienia sześć stref i klucze `menu.play`, `menu.jobs`, `menu.workshop`, `menu.showcase`, `menu.settings`, `menu.about`. W `_refresh()` przypisuje przetłumaczony tekst do `accessibility_name` wyłącznie, jeśli właściwość istnieje, oraz do metadanych `label`. Metadane nie stanowią dowodu, że czytnik je wypowie. Przy niewidocznych przyciskach brak właściwości `accessibility_name` może oznaczać brak nazwy — sprawdzić eksportowaną wersję Godot z TalkBack i VoiceOver, także kolejność fokusu, zmianę języka i panel O grze.
2. **Ustawienia — ryzyko niepowiązanych etykiet suwaków.** `settings_screen.gd` osobno pobiera `HSlider` i odpowiadające mu tekstowe `Label` (np. `IntensitySlider` i `IntensityRow/Value`, analogicznie master, sfx, ambience, voice, text scale). Sam fakt wyświetlenia wartości nie dowodzi przypisania nazwy do suwaka ani automatycznego ogłaszania zmian. Sprawdzić nazwy, rolę i bieżącą wartość sześciu suwaków, pozycje list, stany przełączników, język, kolejność i zmiany wartości. W razie braku powiązania wykorzystać istniejące lokalizowane etykiety, a następnie jawnie ustawić nazwę dostępności.
3. **Pomoc w samouczku nie jest automatycznie opisem dostępności.** W CSV występują `tutorial.say_tension`, `tutorial.say_lift`, `tutorial.say_warded`, `tutorial.say_chalk`, `tutorial.say_master`; są to podpowiedzi, nie dowód udostępnienia przycisków, celu, aktualnego stanu i wyników mechaniki czytnikowi. Należy sprawdzić ekran samouczka i dostępność czynności dotykowych bez polegania wyłącznie na kolorze, wibracji lub pozycji obrazu.
4. **Skalowanie tekstu istnieje, ale nie jest czytnikiem ekranu.** `ui_a11y.gd` ustawia rozmiary czcionek po `Settings.changed`; `screen_frame.gd` oferuje zawijanie i ucinanie z wielokropkiem. Sprawdzić, czy dostępna nazwa zachowuje cały tekst przy ucięciu oraz czy duże litery nie blokują nawigacji i czytania.

## Propozycje brakujących opisów — do integracji po sprawdzeniu rzeczywistych kontrolek

To propozycje nowych kluczy, nie stwierdzenie, że funkcja czytnika już istnieje. Unikać duplikowania tekstu przycisków, jeśli nazwa widoczna jest prawidłowo przekazana czytnikowi. Wartości i stany muszą pochodzić z faktycznego stanu kontrolki, a nie ze statycznego ciągu.

| Proponowany klucz | Tekst PL | Zastosowanie |
|---|---|---|
| `settings.haptics_intensity.a11y` | Intensywność wibracji | Nazwa suwaka; wartość ogłasza kontrolka. |
| `settings.volume_master.a11y` | Głośność główna | Suwak głośności głównej. |
| `settings.volume_sfx.a11y` | Głośność efektów | Suwak efektów. |
| `settings.volume_ambience.a11y` | Głośność otoczenia | Suwak otoczenia. |
| `settings.volume_voice.a11y` | Głośność głosów | Suwak głosów. |
| `settings.text_scale.a11y` | Wielkość tekstu | Suwak skali tekstu. |
| `tutorial.goal.a11y` | Cel ćwiczenia | Etykieta obszaru celu; jego bieżąca treść musi być dostępna osobno. |
| `tutorial.result.a11y` | Wynik ćwiczenia | Etykieta wyniku, odczyt aktualnego rezultatu po zmianie. |

Przed dodaniem kluczy należy sprawdzić wszystkie istniejące nazwy, uniknąć kolizji i przetłumaczyć je do pięciu języków. Nie uruchomiono `i18n_lint`: audyt nie zmienia CSV. Priorytet testu: menu z niewidocznymi przyciskami, suwaki i samouczek; potem pozostałe ekrany, komunikaty, modale i powrót z fokusem.

Przegląd scen i dynamicznych kontrolek znajduje się w `uzupelnienie_sceny.md` i `analiza_dynamiczna.md`.
