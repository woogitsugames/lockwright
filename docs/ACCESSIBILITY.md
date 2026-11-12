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
| Kanał mowy | `UiA11y.announce()`: na Androidzie z TalkBack — TalkBack (most D-97); gdzie indziej TTS silnika, gdy jest włączony i ma głos języka gry, inaczej żywy region AccessKit (czyta go czytnik gracza). |

### 1.1 Android: AccessKit nie działa, gra ma własny most do TalkBack (D-97, N-93)

**Godot 4.7.2 nie ma AccessKit na Androidzie.** Szablon eksportu `android_release.apk` (`libgodot_android.so`) nie zawiera
serwera `AccessibilityServerAccessKit` ani adaptera `accesskit_android` — jest w nim tylko wspólny kod drzewa i tekst
pomocy linii poleceń. Szablon Windows ma `AccessibilityServerAccessKit` i `accesskit_windows-0.34.0`. Ustawienie projektu
`accessibility/general/accessibility_support` niczego tu nie włącza, a eksport Androida nie ma odpowiedniej opcji. Bez
mostu TalkBack widział tylko `SurfaceView` (test a088601, N-93): wszystko z §1 działało tylko na desktopie.

**Most** (wtyczka `LockwrightHaptics`, `platform/android/lockwright-haptics/.../A11yBridge.kt`): przezroczysty widok nad
widokiem gry (`GodotPlugin.onMainCreate`) z wirtualnym `AccessibilityNodeProvider`. Nigdy nie zabiera dotyku
(`dispatchTouchEvent` = false), więc bez TalkBack gra dostaje każdy dotyk jak dotąd.
- `UiA11y` co 0,3 s, gdy słucha jakakolwiek usługa dostępności (`a11y_active`), wysyła widoczne kontrolki jako JSON:
  nazwa (jak w §1), rola (przycisk / przełącznik ze stanem / suwak z wartością w % / lista z wybraną pozycją / tekst
  etykiety / obszar zamka), prostokąt w pikselach okna, przycięty do przewijanych list. Wysyła tylko po zmianie. Etykiety
  wewnątrz przycisku są częścią jego nazwy. Przy pauzie publikowany jest tylko panel pauzy.
- TalkBack: dotyk-eksploracja trafia w węzeł pod palcem, podwójne stuknięcie = `ACTION_CLICK` → sygnał `a11y_activate`
  → `UiA11y.activate()`: przycisk naciśnięty, przełącznik przełączony, lista przechodzi do następnej pozycji (okno listy
  nie jest wystawione), rysowane cele (pauza, lupa, sonda) — ich akcja z D-90. Suwaki: przewijanie w górę / w dół = krok.
- Ogłoszenia (stany zamka, linie kredy, wskazówki H2–H4) idą przez `TYPE_ANNOUNCEMENT` do TalkBack, gdy działa czytnik
  (`a11y_screen_reader`: dotyk-eksploracja albo usługa z mową).
- Zamek to jeden nazwany obszar z opisem kciuków i dopiskiem „Z TalkBack: stuknij dwa razy i przytrzymaj, potem przesuwaj”.
  Android nie daje aplikacjom przepuszczania dotyku dla wybranego obszaru (to robi tylko usługa), więc kciuki działają
  standardowym gestem TalkBack (podwójne stuknięcie z przytrzymaniem przekazuje dotyk do gry). Na ekranie zamka jest
  jeden kciuk naraz — przy dwóch kciukach z TalkBack trzeba napięcia automatycznego (§6).

**Sprawdzone na SM-A165F (2026-11-08, zrzuty w `docs/handoff/device-tests/n93_talkback_2026-11-08/`):**
- `uiautomator dump` z TalkBack: menu = 6 przycisków z nazwami („Zacznij dyżur” … „O grze”) w miejscach liter na tablicy.
  Ustawienia = 23 węzły: „‹ Wstecz”, nagłówki jako tekst, „Haptyka włączona” jako `Switch` (checked), suwaki jako
  `SeekBar` z wartością („Głośność główna, 85%”), przyciski.
- Linia kredy ćwiczenia ogłoszona przez TalkBack (`announce: Szukaj płytki z oporem…` w logcat). Na zamku 3 węzły
  (obszar, pauza, lupa), na pauzie 4 (tytuł + 3 przyciski).
- **Nie sprawdzone na telefonie:** podwójne stuknięcie TalkBack (adb wstrzykuje dotyk poza TouchExplorerem, a skróty
  klawiaturowe TalkBack z `input keycombination` nie przesuwały fokusu; ścieżka aktywacji jest w testach GUT), ogłaszanie
  stanów zamka (właściciel gra dwoma kciukami, a adb ma jeden wskaźnik; ta sama ścieżka co ogłoszona linia kredy) i gest
  przekazania dotyku na zamku. To pierwszy punkt testu ręcznego palcem.
- iOS: VoiceOver nie sprawdzony; czy szablon iOS 4.7.2 ma AccessKit — nie badane w tym zadaniu.

Paragon zapłaty i napisy na przedmiotach (D-25/D-41) są częścią zdjęcia, nie kontrolkami.

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

Ustawienia → Dostępność → „Rozmiar tekstu” 100–200 % (krok 25). **Domyślnie jak w systemie** (D-107): przełącznik
„Jak w systemie (N%)” pod suwakiem bierze rozmiar czcionki Androida (`Configuration.fontScale` przez wtyczkę
`LockwrightHaptics.font_scale()`, Godot nie ma na to API), zaokrąglony do kroku suwaka (85 % → 100 %, 130 % → 125 %,
powyżej 200 % → 200 %), odświeżany po powrocie do gry. Przesunięcie suwaka = własny rozmiar (przełącznik się wyłącza).
Gracz, który wcześniej ustawił własny rozmiar inny niż 100 %, go zachowuje. Na iOS (D-113) ten sam przełącznik
czyta Dynamic Type: `LockwrightHaptics.font_scale()` w GDExtension iOS zwraca rozmiar tekstu podstawowego dla
kategorii wybranej w systemie podzielony przez domyślne 17 pt (xSmall–Large → 100 %, xxLarge i xxxLarge → 125 %,
pierwszy rozmiar dostępności 28 pt → 175 %, większe → 200 %). Po powrocie z ustawień systemu otwarte Ustawienia gry
od razu pokazują nowy procent (`UiA11y.system_scale_changed`). Na desktopie system = 100 %. `UiA11y` skaluje **każdy** rozmiar fontu motywu
(Label, Button, CheckButton, OptionButton, PopupMenu, Caption, Heading, Title, MenuTitle — wcześniej tylko trzy),
a kod, który ustawia własny rozmiar, używa `UiA11y.fs()` (tytuły `fit_title`, zakładki `fit_button_text`, wybór
sterowania, pauza, samouczek, Warsztat). Przy dużym tekście listy wyboru (język, jakość) i tabliczki akcji Warsztatu
łamią tekst zamiast poszerzać ekran. Nagłówek każdego ekranu menu (`ScreenFrame._fit_header`): „‹ Wstecz” rośnie do
swojego tekstu, tytuł zmniejsza się i najwyżej łamie na dwie linie (wcześniej przy 150–200 % było „‹ Ws” i
„Ustawie…”). Zakładki Warsztatu (D-107): obok siebie, dopóki ich słowa mieszczą się w jednej trzeciej rzędu w najmniejszym
rozmiarze zakładki; inaczej jedna pod drugą na całą szerokość (np. 200 % na 360 dp) — bez skrótów „Furnishi…”.

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
- **Blokada napięcia** (HUD §9.2, D-107, Ustawienia → Sterowanie, domyślnie wył.; tylko przy dwóch kciukach — w trybie
  automatycznym gra i tak trzyma napięcie, a stuknięcie lewej połowy dalej je puszcza). Po puszczeniu kciuka napięcia T
  zostaje przez 0,45 s; dwa stuknięcia lewej połowy (prawej przy zamianie kciuków) w tym czasie zatrzaskują je i kciuk
  może odpocząć. Zatrzaśnięte T zmienia się przesunięciem (względnie, zostaje zatrzaśnięte). Jedno stuknięcie puszcza
  (T → 0) — tak samo wychodzi się z overset; złamanie kończy zamek jak zawsze. Bez opcji wszystko po staremu (T spada od
  razu). Trzy kanały: na ramieniu napinacza (czoło rdzenia) pojawia się zacisk — ciemny klocek ze szczękami i śrubą,
  czytelny w szarości; miękki „tuk” i haptyka przy zatrzaśnięciu i puszczeniu; czytnik ekranu mówi „Napięcie
  zablokowane” / „puszczone”, a opis ekranu zamka (też przez most TalkBack D-97) mówi, jak blokada działa. Z TalkBack
  blokada pomaga szczególnie: gest przekazania dotyku daje jeden palec naraz, więc napięcie można zatrzasnąć i potem
  prowadzić wytrych. Kreda wskazówek bez zmian (zatrzaśnięte T liczy się jak trzymane). Warded: obrót sondy (napięcie ze
  znakiem) blokada nie trzyma.

## 7. Jak testujemy

| Test | Gdzie |
|---|---|
| GUT: nazwy wszystkich kontrolek na 11 ekranach (PL/EN), nazwy i akcje na 13 ekranach zamka, ogłoszenia stanów (filtr, dławik, wyłącznik), kwestie i napisy w 5 językach, napisy dźwięków, ścieżki ograniczenia ruchu, skala tekstu w motywie i układy 3 rozmiarów × 5 języków, zamiana kciuków i tekstów, nowe przełączniki | `game/tests/gut/test_accessibility.gd` |
| Istniejące: kreda statyczna (Reduce Motion), mówione H2–H4, stop-klatka przyjazdu, „dzień po” bez ruchu, cele ≥ 48 dp | `test_chalk_hint.gd`, `test_tutorial_hints.gd`, `test_arrival_scene.gd`, `test_day_after.gd`, `test_ui_layout.gd` |
| Zrzuty stanów + raport szarość/daltonizm | `game/tests/a11y_state_shots.tscn` → `qa/a11y/state_report.py` (GPU ok. 1 min) |
| Zrzuty ekranów z dużym tekstem / opcjami | `game/tests/shot_scene.tscn -- --text-scale=1.5 --setting=sound_captions:1` |
| Most TalkBack (D-97) | `game/tests/gut/test_android_a11y_bridge.gd` (atrapa wtyczki: węzły, role, stany, aktywacja, suwaki, pauza, ogłoszenia); na telefonie `uiautomator dump` z włączonym TalkBack + `logcat -s LockwrightA11y` |
| Ręcznie na telefonie (do zrobienia) | TalkBack palcem: podwójne stuknięcie na przyciskach, stany zamka, gest przekazania dotyku; VoiceOver: przejście menu → zlecenie → zamek tylko czytnikiem; systemowe „usuń animacje”; rozmiar czcionki Androida jako domyślny (D-107, nie sprawdzony na telefonie — był zablokowany); blokada napięcia palcem; Dynamic Type na iOS (D-113: kod zbudowany w CI `game-ios`, na iPhonie nie sprawdzony) |
