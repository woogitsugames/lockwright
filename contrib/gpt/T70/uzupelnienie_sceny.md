# T70 — uzupełnienie przeglądu scen

Metoda: tekstowo odczytano na HEAD 14 głównych plików `game/scenes/*.tscn`: `boot`, `control_choice`, `job_arrival`, `job_payment`, `job_verify`, `jobs_list`, `lock`, `lock_job`, `main_menu`, `run_loop`, `settings`, `showcase`, `tutorial`, `workshop`. Przeszukano deklaracje `Button`, `TextureButton`, `CheckButton`, `HSlider`, `OptionButton` i jawne właściwości `accessibility_*`. Żadna z tych 14 scen nie deklaruje takiej właściwości w samym pliku. **Nie oznacza to braku nazw:** sceny mogą mieć tekst, skrypty przypisują właściwości, a kontrolki mogą być instancjami albo powstawać w czasie działania. Wcześniejszy README opisuje potwierdzone przypisanie nazw menu w `main_menu.gd`.

| Ekrany | Znalezione deklaracje i dalsza kontrola |
|---|---|
| Boot | Cztery przyciski odpowiedzi i pominięcia: sprawdzić nazwy, pytanie w kontekście i fokus wyniku. |
| Wybór sterowania; płatność; dyżur | Po jednym przycisku kontynuacji/startu: sprawdzić widoczną nazwę, kolejność i informację o wyniku. |
| Przyjazd | Powrót, pominięcie i weryfikacja: sprawdzić etykiety oraz dostępność wypowiedzi klienta. |
| Weryfikacja | Pięć przycisków, w tym zgoda/odmowa i powrót: sprawdzić treść i stan wybieranych kart, nie tylko przyciski. |
| Lista zleceń; gablota; warsztat | W samej scenie tylko przycisk powrotu; lista/karty mogą być tworzone dynamicznie, potrzebna kontrola skryptów i ich stanów. |
| Stary ekran zamka | Pauza, lupa, wznowienie, tryb ciemny i wyjście: sprawdzić nazwy oraz opis aktualnego stanu i możliwość sterowania. |
| Ekran zamka `lock_job` | W głównej scenie brak bezpośrednich kontrolek wymienionych typów; sprawdzić sceny potomne i elementy rysowane/skryptowe. |
| Menu | Siedem przycisków; nazwy sześciu stref ustawiane warunkowo w skrypcie; zamknięcie panelu też wymaga sprawdzenia. |
| Ustawienia | Przyciski, przełączniki, sześć suwaków i dwie listy wyboru; szczegóły i proponowane nazwy suwaków w README. |
| Samouczek | Start i powrót; dodatkowo sprawdzić cel, instrukcję, wynik i dostępność sterowania. |

Lista kolejnych kandydatów do sprawdzenia: `lock.pause.a11y` — „Pauza”; `lock.tension.a11y` — „Napięcie”; `lock.tool.a11y` — „Narzędzie”; `verify.card.a11y` — „Karta: {card}”. To robocze nazwy, nie stwierdzenie, że już brakuje osobnych kluczy lub że ich dodanie samo uczyni grę dostępną. Rola, stan, fokus, alternatywa gestów i odczyt zmian muszą być zapewnione przez implementację.

Osobny plik `analiza_dynamiczna.md` poszerza przegląd o 17 scen potomnych `photoreal*` i wskazane kontrolki tworzone skryptowo. Nie zbadano urządzenia ani wszystkich ścieżek działania, więc nie można stwierdzić, że każdy ekran i przycisk jest dostępny. Test TalkBack/VoiceOver na urządzeniu nadal wymagany. To raport bez nowych kluczy gry; lint nie dotyczy.
