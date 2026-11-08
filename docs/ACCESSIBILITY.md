# Dostępność — co gra wspiera i jak to sprawdzamy

Stan na 2026-11-08 (audyt D-90, następca `docs/handoff/A11Y-AUDIT.md` z 2026-11-05). Zasady nadrzędne: `CLAUDE.md`
(stany rozróżnialne w skali szarości, trzy kanały: kształt/ruch + dźwięk + haptyka; haptyka nigdy jedynym kanałem — XAG
103/110; cele ≥ 48 dp; kontrast metal/tło ≥ 3:1; animacje 100–250 ms), `docs/DESIGN.md` §1 (kod stanów), `docs/HUD.md` §9
(opcje dostępności). Dowody: `docs/handoff/device-tests/a11y_2026-11-08/`.

Cała warstwa siedzi w autoloadzie `UiA11y` (`game/scripts/autoload/ui_a11y.gd`); teksty gracza tylko przez i18n
(`game/i18n/strings.csv`, klucze `a11y.*` i `settings.*`, PL/EN/DE/FR/ES).

## 1. Czytnik ekranu (TalkBack / VoiceOver / NVDA przez AccessKit w Godot 4.7)

| Co | Jak |
|---|---|
| Nazwy kontrolek | Przyciski z tekstem są czytane po tekście. Kontrolki bez tekstu dostają `accessibility_name`: suwaki w Ustawieniach (nazwa wiersza), kafle dokumentów w weryfikacji (nazwa + „stuknij, żeby zapytać”), akcje Warsztatu (akcja: przedmiot. stan), „Pomiń wszystko”, tabliczki wyboru sterowania. |
| Ekran zamka | Klapka pauzy, lupa i główka sondy (warded) to rysowane cele dotyku — `UiA11y.name_button()` daje im nazwę, rolę „przycisk” i akcję aktywacji (podwójne stuknięcie czytnika robi to samo, co dotyk). Sam ekran ma nazwę „Zamek” i opis, co robią kciuki w wybranym trybie (auto / dwa kciuki, z zamianą kciuków). |
| Stany zamka | `Events.lock_event` → krótka kwestia, np. „3: wiąże”, „3: siada na miejscu”, „1: fałszywie siada — za głęboko”, „5: za wysoko — popuść napięcie”, „Narzędzie się wygina — odpuść”, „Wytrych pękł”, „Otwarte” (też detektor, kontrrotacja, bramka, zrzut). Tylko gdy działa czytnik ekranu i włączone „Ogłaszaj stany zamka” (domyślnie tak). `near_shear`, `contact`, `wear` milczą (za częste; zostaje ich obraz i dźwięk). Ten sam element/rodzaj nie powtarza się szybciej niż co 0,25–3 s (bind 2,5 s, stress 3 s); po zrzucie/otwarciu licznik się zeruje. Pilne (overset, stress, break, false set, detektor, open) idą jako „assertive”. |
| Wskazówki | H2–H4 drabiny wskazówek mówią swój tekst (bez zmian z D-83, teraz przez wspólny `UiA11y.announce`). Linie kredą na zamku (lekcje, cele, podpowiedzi rodzin) są rysowane, więc `ChalkLayer` niesie je jako nazwę i ogłasza każdą nową linię (grzecznie). |
| Dialogi | Z czytnikiem ekranu dialog nie odtwarza klipów (tekst czyta czytnik), scenka przyjazdu pokazuje od razu stop-klatkę. |
| Kanał mowy | `UiA11y.announce()`: TTS silnika, gdy jest włączony i ma głos języka gry, inaczej żywy region AccessKit (czyta go czytnik gracza). |

Ograniczenie: AccessKit na Androidzie/iOS w 4.7 nie był sprawdzony na urządzeniu (TalkBack/VoiceOver) — to pierwszy punkt
testu ręcznego (§7). Paragon zapłaty i napisy na przedmiotach (D-25/D-41) są częścią zdjęcia, nie kontrolkami.

## 2. Ograniczenie ruchu

`UiA11y.reduce_motion()` = ustawienie „Ogranicz ruch” **albo** ustawienie systemu
(`DisplayServer.accessibility_should_reduce_animation()`, odświeżane po powrocie do gry). Każde miejsce w kodzie czyta tę
jedną funkcję:

| Ruch | Z ograniczeniem ruchu |
|---|---|
| Przyjazd do klienta (D-58/D-74): przejazd flipbooka + oddech postaci | od razu stop-klatka, bez oddechu (też przy czytniku ekranu) |
| „Dzień po” (D-78): wejście kart i portretu, wyjście | bez przenikań |
| Wejście ekranów (ScreenFrame.enter), pauza, dialog, wyposażenie warsztatu | bez przenikań |
| Kreda gestu (D-83) | statyczna: cała droga, grot na końcu, pierścień na starcie |
| Drżenie wytrycha przy stress ≥ 0,9, drżenie sondy warded, drżenie ramienia napinacza na czole rdzenia, drżenie tarczy sejfu | brak; zostaje wygięcie i (nowe) rysy 1→3 na ramieniu napinacza |
| Ząb kombinacji przy „slip” (overset) | stoi w najgłębszym punkcie zamiast drgać |
| Lupa (okular) | otwiera się od razu |
| Klapka pauzy | bez uniesienia 4 dp; klik mosiądzu i haptyka zostają |

Zostają (to informacja, nie ozdoba, i są krokowe, nie płynne): skok rdzenia o podziałkę przy set (≤ 250 ms), tykanie
koła zamka czasowego (rytm to mechanika).

## 3. Kolor, skala szarości, daltonizm

Metoda: `game/tests/a11y_state_shots.tscn` otwiera prawdziwy ekran każdej rodziny (pin + 12 rodzin planu B) w oknie
412×915 i zamraża pozę, w której **wszystkie** elementy mają jeden stan: free, bound, near, set, false_set, overset,
stress 0,95 (blisko złamania), open. `qa/a11y/state_report.py` liczy dla każdej pary stanów odsetek pikseli kadru zamka
(górne 75 % ekranu w pionie: przekrój + czoło rdzenia z napinaczem, bez zwijki),
których wartość zmienia się o > 12/255 w skali szarości (luma Rec. 709) oraz po symulacji deuteranopii i protanopii
(Machado 2009, jak `mockups/tools/contrast.mjs`) i składa arkusze (kolor / szarość / deutan / protan).
Próg „rozróżnialne”: ≥ 0,25 % pikseli kadru.

Wynik (2026-11-08, z ograniczeniem ruchu, czyli same nieruchome kadry): **0 par z pięciu stanów (binding, set, false set,
overset, blisko złamania) nierozróżnialnych bez koloru** w 13 rodzinach; kolor nie niesie żadnego stanu (wartości
szarość ≈ deutan ≈ protan). Przed poprawką warded bound / stress dawał 0,05 % (przekrój) — blisko złamania pokazywało
tam tylko drżenie, które znika przy ograniczeniu ruchu. Poprawki: rysy 1→3 i mocniejsze wygięcie ramienia napinacza na
czole rdzenia, wspólne dla wszystkich rodzin (`PlugFace._draw_cracks`, DESIGN §1 „stress”), oraz w warded sonda
odchylona o ≤ 3° pod oporem (`STRAIN_DEG`); po nich 0,59 %. Najsłabsze pary pozostałych rodzin: 1,1–4,3 %. Tabela i arkusze: `docs/handoff/device-tests/a11y_2026-11-08/report/`.

Kontrast metal/tło planu B (7,8:1) i tekstu menu (≥ 7:1) — bez zmian od audytu 2026-11-05.

## 4. Rozmiar tekstu

Ustawienia → Dostępność → „Rozmiar tekstu” 100–200 % (krok 25). `UiA11y` skaluje **każdy** rozmiar fontu motywu
(Label, Button, CheckButton, OptionButton, PopupMenu, Caption, Heading, Title, MenuTitle — wcześniej tylko trzy),
a kod, który ustawia własny rozmiar, używa `UiA11y.fs()` (tytuły `fit_title`, zakładki `fit_button_text`, wybór
sterowania, pauza, samouczek, Warsztat). Przy dużym tekście listy wyboru (język, jakość) i tabliczki akcji Warsztatu
łamią tekst zamiast poszerzać ekran. Nagłówek każdego ekranu menu (`ScreenFrame._fit_header`): „‹ Wstecz” rośnie do
swojego tekstu, tytuł zmniejsza się i najwyżej łamie na dwie linie (wcześniej przy 150–200 % było „‹ Ws” i
„Ustawie…”). Jedyny dopuszczony skrót: zakładki Warsztatu przy 200 % („Furnishi…”, pełna nazwa zostaje dla czytnika).

Nie skalujemy: tekstu na zdjęciach przedmiotów (paragon, kartki — D-25/D-41; HUD §9.2: przewijają się, nie rosną),
kredy na zamku (Caveat 26 dp, część obrazu) i dużych inicjałów na portretach.

Sprawdzone testem (`test_accessibility.gd`): 9 ekranów menu × 360×800, 412×915, 915×412 × 150 % w PL/EN/DE/FR/ES,
125 % w PL/DE, 200 % w PL/EN/DE: nic nie wystaje w bok, brak przewijania w bok, cele ≥ 48 dp, żaden jednolinijkowy
tekst nie jest ucięty (poza zakładkami Warsztatu) i żadna etykieta nie zapada się do zera linii. Zrzuty: `text_scale/`.

## 5. Napisy

- **Kwestie mówione**: każda kwestia z lektorem (przyjazd, „dzień po”) ma tekst na ekranie zawsze — klip jest dodatkiem;
  bez paczki głosów (D-63) tylko tekst. Bezsłowne powitanie (S03) gra pod tekstem dialogu.
- **Napisy dźwięków** (HUD §9.1, nowe): Ustawienia → „Napisy dźwięków” (domyślnie wył.). Pasek papieru nad zwijką nazywa
  ostatni dźwięk zamka na 1,2 s: `[suchy klik]` (set), `[głuchy podwójny klik]` (false set), `[tępy stuk, cisza]`
  (overset), `[jęk metalu]` (stress), `[szczęk rygla]` (open) i reszta słownika HUD §9.1. Ważniejszy dźwięk nie jest
  przykrywany mniej ważnym. W trybie „w ciemności” pasek się nie pokazuje (wyzwanie).
- Klik ustawienia ma też stały odpowiednik w obrazie w każdej rodzinie: element siada (stopka/podziałka), rdzeń skacze
  o podziałkę, czoło rdzenia drgnie o 1,5° na 200 ms.

## 6. Jedna ręka, leworęczni

- **Napięcie automatyczne (D-52, domyślne)**: gra trzyma napięcie; jeden kciuk prowadzi wytrych (prawa połowa), a krótkie
  stuknięcie drugiej połowy puszcza napięcie (wyjście z overset) — da się to zrobić tym samym kciukiem, bo nic nie
  wymaga dwóch dotyków naraz. Sprawdzone testem (`test_auto_tension_one_thumb_path_with_swap`) i istniejącymi testami
  D-52 (kombinacja, sejf, detektor `_auto`).
- **Zamień kciuki** (HUD §9.2, nowe, Ustawienia → Sterowanie): napięcie po prawej, wytrych po lewej; scena się nie
  odbija, głębokość nadal rośnie w prawo w połowie wytrycha. Kreda gestu (lustro) i kredowe kciuki zamieniają strony,
  a teksty sterowania (`tutorial.*`, `lock.*`, `ui.controls.*`, opis ekranu zamka) mówią o drugim kciuku — zamiana słów
  lewy↔prawy we wszystkich 5 językach (`I18n.swap_hands`, z regułą rodzaju w FR; test sprawdza każdy klucz w obie
  strony). Razem z napięciem automatycznym to tryb „jeden lewy kciuk”.
- Nie ma jeszcze „blokady napięcia” z HUD §9.2 (podwójne stuknięcie zatrzaskuje T w trybie dwóch kciuków).

## 7. Jak testujemy

| Test | Gdzie |
|---|---|
| GUT: nazwy wszystkich kontrolek na 11 ekranach (PL/EN), nazwy i akcje na 13 ekranach zamka, ogłoszenia stanów (filtr, dławik, wyłącznik), kwestie i napisy w 5 językach, napisy dźwięków, ścieżki ograniczenia ruchu, skala tekstu w motywie i układy 3 rozmiarów × 5 języków, zamiana kciuków i tekstów, nowe przełączniki | `game/tests/gut/test_accessibility.gd` |
| Istniejące: kreda statyczna (Reduce Motion), mówione H2–H4, stop-klatka przyjazdu, „dzień po” bez ruchu, cele ≥ 48 dp | `test_chalk_hint.gd`, `test_tutorial_hints.gd`, `test_arrival_scene.gd`, `test_day_after.gd`, `test_ui_layout.gd` |
| Zrzuty stanów + raport szarość/daltonizm | `game/tests/a11y_state_shots.tscn` → `qa/a11y/state_report.py` (GPU ok. 1 min) |
| Zrzuty ekranów z dużym tekstem / opcjami | `game/tests/shot_scene.tscn -- --text-scale=1.5 --setting=sound_captions:1` |
| Ręcznie na telefonie (do zrobienia) | TalkBack (Pixel) i VoiceOver: przejście menu → zlecenie → zamek tylko czytnikiem; systemowe „usuń animacje”; Dynamic Type / rozmiar czcionki systemu (gra ma własny suwak, nie czyta systemowego) |
