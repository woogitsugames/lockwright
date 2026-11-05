# T21 — Lockwright: granie bez wzroku / Blind play

**Status:** specyfikacja projektowa (nie wdrożenie), 2026-11-05. **Platformy:** Android/TalkBack oraz iOS/VoiceOver. **Języki:** PL i EN. **Słownik:** `a11y_strings.csv` (key,en,pl). Parametry `{n}`, `{total}`, `{client}`, `{place}`, `{state}`, `{value}`, `{amount}` itp. są podstawiane przez grę.

## 1. Cel, zakres, stan faktyczny

Pełna ścieżka musi być dostępna bez patrzenia: start, wybór trybu, odczyt zlecenia, rozmowa z klientem, **weryfikacja prawa do lokalu**, wycena, samouczek, obsługa fikcyjnego mechanizmu, pauza, rachunek, warsztat i gablota. Czytnik nigdy nie ma odsłaniać ukrytego rozwiązania. Ton: życzliwy, spokojny, legalny, bez estetyki włamania.

Projekt opisuje interfejs z `docs/HUD.md` (zwłaszcza §§3–10) oraz rzeczywiste sceny `game/scenes/*.tscn`. Istniejący audyt `docs/handoff/A11Y-AUDIT.md` (A-09) wskazuje brak pełnej obsługi czytników. **Godot 4.7 dokumentuje obsługę czytników ekranowych na Windows, macOS i Linux, lecz nie natywną obsługę TalkBack/VoiceOver w mobilnych eksportach.** Samo `accessibility_name` lub opis kontrolki nie wystarczy. **Mostek do natywnych API systemów jest wymaganiem blokującym** (§8). To zlecenie nie zmienia kodu gry.

Rozdzielamy trzy niezależne funkcje:
1. **Sterowanie dostępne**: własne semantyczne elementy i alternatywa dla dwóch kciuków, aktywowane na życzenie lub proponowane, gdy systemowy czytnik jest włączony. Nie zmienia solvera.
2. **Komunikaty głosowe zdarzeń**: osobny, opcjonalny TTS (Wyłączone / Kluczowe / Rozszerzone). Wyłączenie go nie może wyłączać TalkBack/VoiceOver ani fizycznych SFX.
3. **Tryb „w ciemności”**: wizualne wyzwanie z `docs/HUD.md` §10; **nie** jest synonimem ustawienia dostępności. Dostępność działa przy włączonym i wyłączonym świetle.

## 2. Kontrakt semantyczny i zasady etykiet

Każdy aktywny obiekt ma: identyfikator, krótką nazwę, rolę, dostępny stan/wartość, ewentualną wskazówkę oraz możliwe działania. Nazwa nie zawiera słów „przycisk” ani „suwak”, jeśli rolę ogłosi system. Używać rodzimego `accessibilityLabel/value/hint/traits` (Apple) lub `contentDescription/text/stateDescription/AccessibilityAction` (Android), a nie składać całego zdania w jedną etykietę.

| Przedmiot w scenie | Co czytnik ma udostępnić | Czy osobno fokusować |
|---|---|---|
| Emaliowana tabliczka numeru | Nagłówek lokalu / etapu | Tak, raz |
| Telefon dyspozytorni | Nadawcę, godzinę, adres/piętro, klienta, sytuację, sens zdjęcia wkładki | Czytać kolejno jako grupę |
| Rozmowa / drzwi / korytarz | Mówcę, dialog i jawny fakt fabularny | Tak dla treści i decyzji |
| Karta dowodowa | Typ, podany fakt, stan oceny; **bez** nauki weryfikowania autentyczności dokumentu | Każda karta w zestawie |
| Kartka wyceny | Pozycja, stawka, suma, odpowiedź klienta | Tak |
| Kartka dyżuru | Miejsce, pora, długość serii w słowach | Tak |
| Przekrój fikcyjnego mechanizmu | Odczyt bieżącego jawnego stanu, element, napięcie, uniesienie, zapas, pauza | Tylko **kontrolki wirtualne** |
| Skórzana napa | „Pauza” | Tak; nawet gdy nie ma ikony |
| Zwijka i kieszenie | Łączna liczba zapasowych narzędzi i narzędzia faktycznie dostępne | Nie fokusować nieaktywnych kieszeni |
| Lupa/mikroskop/wziernik | Typ narzędzia, funkcję, aktualny widoczny stan, dostępne przesunięcia | Tak, gdy aktywne |
| Rachunek i stemple | Pozycje, sumę, premie „bez śladów”, „w ciemności”, „mistrz”, napiwek, odłamek | Grupować monety/kreski w wyniki |
| Rysy, szwy, kreda, ślad kciuka | Tylko semantyczny odpowiednik **zauważalnego** stanu, nie opis faktury | Nie, dekoracja |

Elementy przestrzenne mają zachować diegetyczną formę wizualną (D-12/D-25); semantyczne kontrolki nie wymagają widzialnych, pływających paneli. Nie tworzyć węzła fokusu na każdą komorę, rysę czy monetę, jeśli nie da się wykonać na niej osobnej akcji. Nie dublować napisów dźwięków z odczytem SFX.

## 3. Mapa ekranów i kolejność fokusu

Reguła: nagłówek → informacja główna → treść → akcje → Wstecz. Jedna kolejność w pionie i poziomie; po modalnym widoku fokus wraca do wywołującego elementu. Pojawienie się automatycznego zdarzenia zamka **nie** przenosi fokusu.

| ID / widok | Kolejność czytania i działania; klucze w CSV | Implementacja / dokument |
|---|---|---|
| B01 Uruchomienie/kalibracja | `a11y.screen.boot` → `a11y.boot.intro` → `a11y.boot.question` → two / one / none / skip | `boot.tscn`; bez przymusu haptyki |
| B02 Menu | `a11y.screen.main` → `a11y.menu.tip` (jeśli) → start → jobs → workshop → showcase → settings → about | `main_menu.tscn` |
| B03 Lista zleceń | `a11y.screen.jobs` → `a11y.jobs.item_fmt` (każdy, numer pozycji) → back | `jobs_list.tscn` |
| B04 Telefon | `a11y.screen.dispatch` → `a11y.dispatch.sender` → time_fmt → address_fmt → client_fmt → situation_fmt → photo → continue → back | HUD §7.1, docelowy |
| B05 Przyjazd i rozmowa | `a11y.screen.arrival` → place_fmt → speaker_fmt (kolejne) → verify → back | `job_arrival.tscn`, JOBS §2 |
| B06 Dowody i decyzja | `a11y.screen.verify` → client_fmt → situation_fmt → evidence_fmt/status_fmt (1–3 karty) → confidence_enough/uncertain/not_enough → ask_more → accept / refuse / police (gdy przewidziane) → back | `job_verify.tscn`; żadnego ujawnienia ukrytej prawdy |
| B07 Wycena | `a11y.screen.quote` → `a11y.quote.line_fmt` (każda) → rate → total_fmt → client_response_fmt → confirm → back | HUD §7.1, JOBS §3; interfejs docelowy |
| B08 Bloczek dyżuru | `a11y.screen.run` → `a11y.run.location_fmt` → time_fmt → streak_fmt → ready / workshop_break | `run_loop.tscn`, HUD §7.2 |
| B09 Samouczek | `a11y.screen.tutorial` → stage_fmt → goal_fmt → repeat → start/next/skip → back | `tutorial.tscn`, `ONBOARDING.md`; cel da się usłyszeć |
| B10 Główna scena zamka | `a11y.screen.lock` → `a11y.lock.summary` → element → tension → lift → hold → precision → release → spares_fmt → tool_fmt → loupe/microscope/borescope (jeśli dostępne) → timer_fmt (tylko Na czas) → pause | `lock.tscn` i `photoreal/lock_photoreal.tscn`; HUD §§3–6 |
| B11 Lupa | `a11y.screen.loupe` → `a11y.optics.readout_fmt` → close | HUD §4.1 |
| B12 Mikroskop | `a11y.screen.microscope` → readout_fmt → move_previous/next → close | Tylko warsztat, HUD §4.1 |
| B13 Wziernik | `a11y.screen.borescope` → readout_fmt → move_previous/next → close | Odblokowywany, HUD §4.1 |
| B14 Pauza | `a11y.screen.pause` → `a11y.pause.resume` → light/value → reading_aid → audio → skip_tutorial (warunkowo) → quit | Skórzana klapka HUD §6; docelowo zamiast tymczasowego PauseMenu |
| B15 Dźwięk/haptyka w pauzie | `a11y.screen.audio` → `a11y.audio.master` → sfx → ambience → voice_events → speech_rate → haptics → resistance → back | HUD §§6, 9 |
| B16 Rachunek | `a11y.screen.receipt` → `a11y.receipt.client_fmt` → line_fmt (pozycje) → total_fmt → stamp_clean/dark/master (tylko należne) → tip_fmt → damage_fmt → save → next | HUD §8; akcja „zachowaj” nie wymaga przytrzymania |
| B17 Wynik/odmowa | `a11y.screen.result` → `a11y.result.reason_fmt` → reputation_fmt (jeśli znane) → continue → back | `job_payment.tscn`, JOBS §2 |
| B18 Koniec dyżuru | `a11y.screen.shift_end` → `a11y.shift_end.locks_fmt` → coins_fmt → best_fmt → line → continue | HUD §8 pkt 6 |
| B19 Warsztat | `a11y.screen.workshop` → coins_fmt → `a11y.workshop.item_fmt` (każdy z opisem/condition/price) → buy lub repair → back | `workshop.tscn`, HUD §4.1 |
| B20 Gablota/zeszyt | `a11y.screen.showcase` → `a11y.showcase.item_fmt` → note_fmt/source_fmt lub locked → back | `showcase.tscn` |
| B21 Ustawienia | `a11y.screen.settings` → kolejno elementy z §3.1 → reset → report → back | `settings.tscn`, HUD §9 |
| B22 O grze | `a11y.screen.about` → `a11y.about.notice` → licenses → close | AboutPanel w `main_menu.tscn` |
| B23 Alerty / potwierdzenia | `a11y.screen.alert` → `a11y.alert.message_fmt` → cancel → confirm | Wszystkie sceny; XAG 115 |
| B24 W ciemności | **Wciąż B10** z `a11y.dark.entered`, pauzą i kontrolką światła; **żadna wirtualna kontrolka nie znika z powodu czarnej grafiki** | HUD §10 |

### 3.1 Wszystkie ustawienia

Kolejność sekcji w B21:
1. **Dostępność (nowe):** `a11y.settings.blind_controls`, voice_events, speech_rate, announce_detail, captions, left_handed, hold_tension.
2. **Wyczucie:** `a11y.settings.haptics`, haptics_strength, haptics_test, calibration, continuous.
3. **Dźwięk:** `a11y.settings.volume_master`, volume_sfx, volume_ambience.
4. **Obraz i tekst:** `a11y.settings.language`, reading_aid, high_contrast, wide_windows, text_scale, reduce_motion, quality, dark_note.
5. **Pozostałe:** `a11y.settings.reset`, report i Wstecz.

Każdy przełącznik czytnik opisuje z wartością Włączone/Wyłączone, każdy suwak z bieżącą wartością, a język z nazwą wybranego języka. „Pomoc w czytaniu” (kreda, kontrast, napisy dźwięków) pozostaje opcją dla czytających wzrokiem; **nie** zastępuje czytnika. „Zgłoś problem” po skopiowaniu logu ma wyraźnie oznajmić, że **nic nie zostało wysłane**. Nie wprowadzać obietnic cen ani dat premiery (D-06/D-51).

## 4. Fokus i gesty, bez konfliktów z systemem

- **TalkBack:** przesuwanie w prawo/lewo przechodzi po elementach, eksploracja dotykiem je znajduje, dwukrotne stuknięcie aktywuje. Regulacja przez natywne akcje dostępności, a w skomplikowanych elementach — akcje niestandardowe w menu TalkBack. Nie przechwytywać gestów TalkBack na „strefie kciuka”.
- **VoiceOver:** przesuwanie w prawo/lewo zmienia fokus, dwukrotne tapnięcie aktywuje; na elemencie adjustable gest góra/dół zmienia wartość. Wiele działań jednego elementu udostępnić jako UIAccessibilityCustomAction/rotor. Umożliwić gest systemowy cofania i osobny Wstecz.
- **Oba:** nie nakładać własnych gestów na systemowe gesty wielopalcowe. Gdy aktywny czytnik, wyłączyć zwykłe przechwytywanie lewego/prawego kciuka i ograniczenia krawędziowe przeszkadzające technologii wspomagającej. Opcjonalny profil bez czytnika może używać krokowych dostępnych przycisków i własnego TTS, ale **nie udawać** TalkBack/VoiceOver.
- Po otwarciu/zamknięciu pauzy, optyki lub modalu fokus wraca do wywołującej kontrolki; po wznowieniu gry wraca do ostatniej wirtualnej kontrolki. Modal blokuje fokus tła. Obrót telefonu nie gubi fokusu. Zmiana języka aktualizuje wszystkie etykiety.
- Zdarzenie gry **nie przenosi fokusu** z regulowanego elementu; krytyczny komunikat jest ogłaszany bez przestawiania na „niewidoczny toast”. Focus/Value/state nie powinny być nadpisywane w każdej klatce 120 Hz.

## 5. Dostępne sterowanie fikcyjnym zamkiem

| Kontrolka (CSV) | Rola, wartość | Akcje i skutki |
|---|---|---|
| `a11y.lock.summary` | Ostatni **jawny** stan, dostępny zapas; odczyt na żądanie | Powtórz stan, nie przestawiaj symulacji |
| `a11y.lock.element` | „Element {n} z {total}” | Następny/poprzedni element; kontaktowy „tik”, bez automatycznego wyboru poprawnego |
| `a11y.lock.tension` | Regulowana wartość 0–100% lub słownie niski/średni/wysoki | Krok +/-5 punktów procentowych (do walidacji), aktualizuje ten sam parametr T co kciuk (D-24/D-51) |
| `a11y.lock.lift` | Uniesienie 0–100%, kierunek dla rodzin dwustronnych | Regulacja +/-1/16 zakresu; precyzyjny krok +/-1/128; clamp i brak auto-snap do okna |
| `a11y.lock.hold` | Włączone/wyłączone | Blokada bieżącego napięcia: ruchy można wykonać sekwencyjnie bez trzymania dwóch kciuków |
| `a11y.lock.precision` | Zwykły/precyzyjny | Zmienia wielkość kroku, nie zmienia mechaniki i nie ujawnia rozwiązania |
| `a11y.lock.release` | Dostępna akcja | Świadomie zwalnia napięcie; może wyzwolić `drop` |
| `a11y.lock.spares_fmt` | Liczba zapasowych wytrychów | Odczyt; wybór egzemplarza tylko tam, gdzie obsługuje go tryb gry |
| `a11y.lock.tool_fmt` | Nazwa i jawne zużycie | Odczyt, narzędzia obserwacyjne jako osobne kontrolki |
| `a11y.lock.pause` | Przycisk | Otwiera skórzaną klapkę (nie wymaga znalezienia 14 dp napy) |

**Kroki to propozycja interfejsu, a nie zatwierdzony balans.** Weryfikator dla wszystkich seedów/tierów i siedmiu rodzin w `docs/FEEL.md` §3 musi wykazać, że krokowo da się osiągnąć potrzebne stany. Przy wąskich oknach zastosować mniejszy **jawny** krok, nigdy automatyczne ustawianie odpowiedniej wartości. „Szersze okna” pozostają oddzielną, dobrowolną opcją. `lockcore` emituje te same zdarzenia i liczy te same punkty co dla sterowania dotykowego.

**Sekwencja przykładowa wyłącznie w fikcyjnej grze:** fokus na indeksie elementu → wybór indeksu → zmiana napięcia → blokada napięcia → zmiana uniesienia → odsłuchanie rezultatu → ewentualny odczyt stanu → ponowna decyzja. Bez użycia dwóch palców jednocześnie i bez instrukcji do prawdziwych produktów.

Dla rodzin `pin_tumbler`, `wafer`, `wooden_pin`, `warded`, `lever`, `lever_detector`, `ring_combo` pola nazywają rzeczywistą czynność w danej fikcyjnej rodzinie: „Pozycja elementu”, „Wybierz dźwignię”, „Wybierz pierścień” zamiast pustego „Uniesienia”, jeśli dany mechanizm nie ma takiej osi. Zdanie z nazwą wybranego elementu nie zdradza, czy jest poprawny.

**Zatrzymanie/symulacja:** zmiana fokusu nie jest gestem fizycznym i niczego nie puszcza; ustawione T i uniesienie nie zmieniają się przez samo czytanie etykiet. W pauzie, w tle aplikacji oraz podczas przejścia do optyki gra nie generuje stresu/zrzutu; po powrocie wartości przejmowane są bez skoku (HUD §5.1, pierwsze 2 s ochrony po pauzie). Zwolnienie napięcia jest wyraźną akcją z konsekwencją. Tryb z limitem czasu ma opcję bez limitu / wydłużenia przed startem (XAG 116). Samo włączenie czytnika nie przyznaje premii.

## 6. Dźwięk, mowa i audiodeskrypcja

Trzy warstwy: **SFX mechaniczny** (istniejące `FeedbackDirector`/FEEL.md; zawsze słyszalne przy włączonym audio), **TalkBack/VoiceOver** (obsługa UI, niezależna od gry), **opcjonalny głos zdarzeń** (TTS przez `a11y.event.*`). Czwarta, opcjonalna warstwa to audiodeskrypcja scen fabularnych `a11y.scene.*`: widoczny gest klienta, przedmiot-napiwek, odsłonięcie drzwi. TTS nie zastępuje fizycznego odczucia zamka, a haptyka nie jest jedynym kanałem (XAG 103/110). Przy braku wibracji na iPadzie i Androidzie informacja pozostaje słyszalna.

| Zdarzenie FEEL.md §2 | Klucz CSV | Kiedy mówić |
|---|---|---|
| `contact` | a11y.event.contact | Tylko profil rozszerzony, nie co tick |
| `bind` | a11y.event.bind | Rozszerzony, wejście w stan |
| `near_shear` | a11y.event.near_shear | Rozszerzony, jedno ogłoszenie stanu |
| `set` | a11y.event.set | Kluczowe; pojedynczy klik |
| `false_set` | a11y.event.false_set | Kluczowe; głuchy podwójny klik, odróżnić od set |
| `counter_rotate` | a11y.event.counter_rotate | Rozszerzony, raz na początek zdarzenia |
| `overset` | a11y.event.overset | Kluczowe; tępy stuk, cisza komory |
| `drop` | a11y.event.drop | Kluczowe; kaskada = jedna wypowiedź |
| `stress` | a11y.event.stress | Rozszerzony, przekroczenie progu |
| `break` | a11y.event.break | Pilne; dodać pozostały zapas na żądanie |
| `wear` | a11y.event.wear | Tylko po zamku / na żądanie |
| `gate_align` | a11y.event.gate_align | Rozszerzony, nie podawać dalszej akcji |
| `detector_trip` | a11y.event.detector_trip | Pilne |
| `open` | a11y.event.open | Pilne, potem rachunek |
| `tension_resistance` | a11y.event.tension_resistance | Sygnał ciągły; **tylko na żądanie** |
| `pick_drag` | a11y.event.pick_drag | Sygnał ciągły; **tylko na żądanie** |

**Priorytety:** break/open/detector_trip > set/false_set/drop/overset > status i dialog > bind/contact. SFX wypada natychmiast, **zanim** TTS zacznie mówić (FEEL §1.2); ducking tła i mowy nie wycisza kliknięć decydujących. Maksymalnie jedno niepilne ogłoszenie na 1,5 s; scalaj serię w zdanie „Kilka elementów opadło”. Przerywaj wypowiedź o starym fokusie po zmianie; krytyczne zdarzenie wyprzedza opis. Po wyłączeniu komunikatów głosowych nadal zostają SFX, etykiety kontrolki i „Odczytaj stan”.

**Nie zdradzać:** seed/solver, ukrytych wartości docelowych, następnego poprawnego elementu, niewidocznej przyszłej pułapki i „prawidłowej” odpowiedzi na weryfikację dowodów. Opisywać wyłącznie to, co postać dostrzega już teraz obrazem, dźwiękiem lub legalną rozmową.

## 7. Tryb „w ciemności” dla osoby niewidomej

1. Wejście: semantycznie dostępny włącznik światła przed zamkiem lub w pauzie. Ogłoszenie `a11y.dark.entered` / `a11y.dark.exited`; status „Światło: włączone/wyłączone”. Nigdy nie trzeba widzieć żarówki, aby wyjść z ciemności.
2. Wizualnie **dokładnie HUD §10**: czerń OLED, poza dopuszczoną klapką i opcjonalnym odciskiem dotyku. Znikają rysunek, lupa, kreda i domyślnie napisy; **węzły semantyczne sterowania nadal istnieją**. Niedostępne narzędzia optyczne nie stają się martwymi przyciskami.
3. Dźwięk oraz haptyka (jeśli dostępna) pozostają i używają profilu „dark”, a TTS oraz odczyt stanu nie stają się mniej szczegółowe. Indeks aktualnego elementu dostępny bez stereo/panoramy.
4. Jeśli samouczek H4 na moment zapala światło, dać równoważny **dźwiękowy** opis bieżącej sytuacji; nie „spójrz na znak”. Po złamaniu ogłosić i odtworzyć wymianę narzędzia; gdy brak zapasu, przejść do dostępnego końca dyżuru. Po `open` od razu dostępny rachunek.
5. HUD §8 przewiduje pieczątkę i +20% za dobrowolną ciemność. To **nie** może być ekskluzywna fabuła/osiągnięcie wymagające widzenia; sam czytnik nie włącza tej premii automatycznie. Nie rozcieńczać równoważności informacji po włączeniu czerni.
6. **Ograniczenie:** przy jednoczesnym braku widzenia i słuchu albo na iPadzie bez haptyki tryb wyłącznie audio/haptyczny nie jest w pełni dostępny. Przed wyborem pokazać/odczytać ostrzeżenie; nie uzależniać od tego trybu podstawowej progresji.

## 8. Wymagana architektura mobilna

**AccessibilityBridge:** model semantyczny odseparowany od rysowania Godot, wspólne ID per ekran, role/labels/values/hints/actions, stabilny fokus, aktualizowany z jawnych zdarzeń `LockEvent` i `ViewModel`. Użytkownik nie ma „klikać niewidzialnej grafiki”; systemowy czytnik musi widzieć realne wirtualne węzły.

- **Android:** natywna `View` obsługująca `AccessibilityNodeProvider` (wirtualni potomkowie nad `SurfaceView` Godota), `AccessibilityNodeInfo`, `contentDescription`, `stateDescription`, `RangeInfo`, `ACTION_CLICK`, akcje zwiększ/zmniejsz lub custom actions, `setTraversalBefore/After`; świadome zdarzenia zmian okna/treści, nie 120 notyfikacji/s. Test TalkBack i Switch Access.
- **iOS:** kontener `UIView` i `UIAccessibilityElement` z label/value/hint/traits, `accessibilityIncrement`/`accessibilityDecrement` na elemencie regulowanym i `UIAccessibilityCustomAction` dla następnego elementu, zwolnienia itd. `screenChanged` i `layoutChanged` na zmianie kontekstu; kontrola kolejności i przywracanie fokusu. Test VoiceOver i opcjonalnie Full Keyboard Access.
- **Godot 4.7:** desktopowa obsługa czytników ≠ działające mobilne TalkBack/VoiceOver. Plugin mobilny i test fizycznych urządzeń są **P0**. Zgodnie z D-51 Android przed iOS, ale słownik i zachowanie współdzielone. Kod, sceny i natywne pluginy pozostają poza zakresem T21.
- **i18n:** bieżący projekt ma format `game/i18n/strings.csv`: `keys,en,pl,de` (D-19), a T21 celowo ma `key,en,pl` zgodnie ze zleceniem; integrator ma zmergować klucze, nie zastępować istniejącej tabeli. Podmieniane parametry muszą mieć te same nazwy w PL/EN, osobny fallback dla brakujących wartości, test lokalizacji i poprawnej polskiej wymowy imion.
- **Stan i prywatność:** czytnik ujawnia tylko jawne fakty z fabuły, bez danych rzeczywistych osób/produktów. Powrót z tła automatycznie otwiera pauzę; skupienie na klapce, symulacja bez dodatkowego stresu i zrzutu (HUD §5.1/6). Raport QA może rejestrować błędny klucz i stan, nie dane gracza.

## 9. Testy akceptacyjne

**P0:** każdy ekran B01–B24 jest w 100% osiągalny z TalkBack/VoiceOver; każda kontrolka ma etykietę, rolę, poprawny stan i operację; żadna akcja wymagana do gry nie potrzebuje widzenia ani dwóch palców. Kluczowe przejścia: boot → menu → samouczek → zamek → rachunek; lista zleceń → rozmowa → dowody → decyzja/wycena → zamek lub odmowa → wynik; warsztat → zakup/naprawa; gablota; ustawienia; pauza.

| Test | Wymagany rezultat |
|---|---|
| T01 TalkBack, czysty start, brak haptyki | Wszystkie informacje i przyciski kalibracji/menu dostępne; pomiń działa |
| T02 VoiceOver, 200% tekstu, pion/poziom | Czytelny tytuł, brak znikającego lub osieroconego fokusu |
| T03 Weryfikacja z trzema kartami i zgrzytem | Każdy dowód i niepewność odczytane, bez spoilerów i kursu fałszerstwa |
| T04 Jedna ręka, ekran zakryty, H0 bez wibracji | Przejście podstawowego fikcyjnego zamka możliwe samym dźwiękiem i akcjami czytnika |
| T05 `set` vs `false_set` vs `overset` vs `drop` | Rozróżnialne SFX, opcjonalne słowo i odczyt na żądanie |
| T06 7 rodzin, wszystkie obsługiwane tiery i 10 000 seedów | Brak nieosiągalnych rozwiązań przez coarse/fine, solver i stan ten sam co dla dotyku |
| T07 Dark przed/w trakcie zamka i z pauzy | Bez niedostępnej „lampy”; węzły semantyczne i wynik obecne |
| T08 Słuchawki mono / jedno ucho / iPad bez haptyki | Stan nie zależy wyłącznie od panoramy albo wibracji |
| T09 Połączenie przychodzące, powrót z tła | Pauza, zachowane T, zero niezamierzonego zrzutu, fokus na pauzie |
| T10 20 s kontaktów i stresu | Brak zalewu TTS, krytyczne SFX nie giną |
| T11 Reset/wyjście/odmowa/zachowanie rachunku | Potwierdzenia i alternatywa do przytrzymania, fokus wraca |
| T12 PL/EN, różne locale czytnika | Wszystkie klucze, placeholdery i odmiana poprawne |
| T13 Czytnik on + komunikaty zdarzeń off | Interfejs i odczyt na żądanie nadal działają |
| T14 Optyka dostępna i nieodblokowana | Poprawne role, powrót fokusu, brak martwych interakcji |
| T15 Brak limitu czasu / dłuższy limit | Odczytywanie informacji nie powoduje nieodwracalnej porażki |

**P1:** minimum 6 osób regularnie korzystających z TalkBack i 6 z VoiceOver (w tym niewidomi), bez podpowiadania sposobu obsługi; cel: 100% ukończeń podstawowego samouczka, 0 ślepych zaułków i 0 utrat fokusu; osobny test braku haptyki. **P2:** utrzymać kontrast, safe-area, 200% tekst, Reduce Motion i odbiór przy niskiej jasności zgodnie z A11Y-AUDIT.md. Dotychczasowe A-10/A-11 opisano jako naprawione, ale trzeba zweryfikować fizyczne telefony.

## 10. Konkretnie ponumerowane wytyczne

**Xbox Accessibility Guidelines v3.2 (2023):** XAG **101** Text display, **102** Contrast, **103** Additional channels for visual and audio cues, **105** Audio accessibility, **106** Screen narration, **107** Input, **108** Game difficulty options, **109** Object clarity, **110** Haptic feedback, **111** Audio descriptions (filmowe/scenariuszowe), **112** UI navigation, **113** UI focus handling, **114** UI context, **115** Error messages and destructive actions, **116** Time limits, **117** Visual distractions and motion settings, **121** Accessible feature documentation. **Korekta:** XAG 106 to **Screen narration**, a nie wielkość celów dotyku (mylne skróty w audycie); sterowanie alternatywne to przede wszystkim XAG 107. XAG to wytyczne, nie certyfikacja prawna.

- XAG (spis): https://learn.microsoft.com/en-us/gaming/accessibility/guidelines
- XAG 106: https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/106
- XAG 107: https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/107
- XAG 111: https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/111
- XAG 112: https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/112
- XAG 113: https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/113
- XAG 114: https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/114
- XAG 115: https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/115
- Apple HIG / VoiceOver: https://developer.apple.com/design/human-interface-guidelines/voiceover
- Apple „Supporting VoiceOver in your app”: https://developer.apple.com/documentation/uikit/supporting-voiceover-in-your-app
- Apple UIAccessibilityElement: https://developer.apple.com/documentation/uikit/uiaccessibilityelement
- Apple adjustable/custom actions: https://developer.apple.com/documentation/swiftui/accessible-controls
- Android „Principles for improving app accessibility”: https://developer.android.com/guide/topics/ui/accessibility/principles
- Android AccessibilityNodeInfo i kolejność: https://developer.android.com/reference/android/view/accessibility/AccessibilityNodeInfo
- Android testy TalkBack: https://developer.android.com/guide/topics/ui/accessibility/testing
- Android gesty użytkownika: https://support.google.com/accessibility/android/answer/6006598?hl=en
- Godot 4.7 — lista funkcji: https://docs.godotengine.org/en/4.7/about/list_of_features.html

Apple i Google **nie nadają** ww. dokumentom analogicznych numerów XAG; podajemy ich właściwe tytuły/metody zamiast wymyślonych numerów. Pomocniczo WCAG 2.2 SC **1.1.1**, **1.3.2**, **2.1.1**, **2.4.3**, **4.1.2**, **4.1.3**, ale nie zastępują testowania mobilnej gry.

## 11. Granice wykonania

Pliki T21 są projektem do wdrożenia. W tym zleceniu **nie** zmieniamy `game/`, `docs/`, natywnych pluginów ani istniejącego CSV. Pełna grywalność bez wzroku **nie jest potwierdzona** bez natywnego mostka, testów na telefonach i walidacji kwantyzacji dla lockcore. Propozycje zmian poza T21 opisane są w README.md.
