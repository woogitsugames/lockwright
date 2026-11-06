# Pomiary na Twoich telefonach (D-33) — instrukcja krok po kroku

Ta instrukcja jest dla Ciebie, nie dla programisty. Mierzymy, jak szybko telefon odpowiada **drganiem** i **dźwiękiem** — od tego zależy, czy zostajemy przy Godocie (`docs/TECH.md` §4, spike'i 1–3). Nie trzeba kupować żadnego sprzętu: aplikacja „LW Pomiary” używa akcelerometru i mikrofonu samego telefonu.

Czas: ok. 10 minut na pierwszy telefon (z instalacją), potem ok. 4 minuty na każdy kolejny.

---

## 1. Pobierz aplikację z GitHuba

1. Wejdź na **github.com/woogitsugames/lockwright** i zaloguj się.
2. Kliknij zakładkę **Actions** (u góry), a po lewej workflow **spike-measure**.
3. Kliknij najnowszy wiersz z zieloną ikoną (✓ przy nazwie commita).
4. Przewiń na dół do sekcji **Artifacts**:
   - **`measure-android-apk`** — Android,
   - **`measure-ios-unsigned`** — iPhone (patrz punkt 3, tu jest haczyk).
5. Kliknij nazwę. Pobierze się plik `.zip`. Rozpakuj go (na komputerze albo od razu na telefonie w aplikacji „Pliki”).

Artefakty są dostępne przez 90 dni od zbudowania. Jeśli lista jest pusta, napisz do mnie (następna sesja) — zbuduję ponownie.

## 2. Android — instalacja

1. Przenieś plik **`lw-pomiary.apk`** na telefon (kabel, Dysk Google, mail do siebie) albo pobierz ZIP od razu na telefonie.
2. Na telefonie otwórz aplikację **Pliki** i dotknij `lw-pomiary.apk`.
3. Telefon zapyta, czy pozwolić tej aplikacji (np. „Pliki” albo „Chrome”) **instalować nieznane aplikacje**. Wybierz **Ustawienia → Zezwalaj z tego źródła**, wróć i dotknij **Zainstaluj**.
4. Play Protect może pokazać ostrzeżenie „Nieznany deweloper” — to normalne dla aplikacji testowej spoza sklepu. Wybierz **Zainstaluj mimo to** (czasem pod „Więcej szczegółów”).
5. Na ekranie pojawi się ikona **LW Pomiary**.

Po pomiarach możesz ją odinstalować jak każdą aplikację.

## 3. iPhone — instalacja (uczciwie: tu potrzebny jest Mac albo płatne konto)

Apple nie pozwala zainstalować aplikacji spoza App Store bez podpisu. Artefakt `measure-ios-unsigned` jest **niepodpisany**, więc sam w sobie na iPhone'a nie wejdzie. Są trzy drogi:

| Droga | Czego potrzeba | Ile kosztuje | Uwagi |
|---|---|---|---|
| **A. Xcode na Macu, darmowe Apple ID** | Mac z Xcode 26, kabel USB, Twoje Apple ID | 0 zł | Aplikacja działa 7 dni, potem trzeba powtórzyć. Kroki niżej. |
| **B. TestFlight** | Konto **Apple Developer Program** (99 USD/rok) + klucz API w sekretach repo | 99 USD/rok | Najwygodniejsze: instalacja z aplikacji TestFlight jednym dotknięciem. Konto i tak będzie potrzebne do publikacji gry. Ustawienie CI: `docs/TECH.md` §5.4. |
| C. Pominąć iPhone'a na razie | — | 0 | Spike 1 (iPhone) zostaje niezmierzony; Android daje odpowiedź dla spike'ów 2–3. |

**Droga A (darmowa, z Maca), krok po kroku:**
1. Na Macu zainstaluj **Xcode** z App Store i **XcodeGen** (`brew install xcodegen` w Terminalu; jeśli nie masz Homebrew, instrukcja: brew.sh).
2. Pobierz repo (zielony przycisk **Code → Download ZIP** na GitHubie) i rozpakuj.
3. W Terminalu: `cd ~/Downloads/lockwright-main/spikes/measure/ios && xcodegen generate && open LWMeasure.xcodeproj` (nazwę pliku `.xcodeproj` zobaczysz w katalogu).
4. W Xcode: kliknij projekt po lewej → zakładka **Signing & Capabilities** → **Team: Add an Account…** → zaloguj się swoim Apple ID → wybierz „(Personal Team)”. Jeśli Xcode zgłosi zajęty identyfikator, dopisz cokolwiek na końcu **Bundle Identifier** (np. `.mateusz`).
5. Podłącz iPhone'a kablem, odblokuj go, u góry Xcode wybierz swój telefon i kliknij ▶ (Run).
6. Na iPhonie: **Ustawienia → Ogólne → VPN i urządzenia** → Twoje Apple ID → **Ufaj**. Przy pierwszym uruchomieniu iOS 18 może też poprosić o włączenie **Trybu dewelopera** (Ustawienia → Prywatność i ochrona → Tryb dewelopera → włącz, restart).

## 4. Pomiar — co kliknąć

Przygotuj: **twardy stół**, ciszę w pokoju, wyłączony tryb cichy, głośność multimediów ok. 70%. Nie trzymaj telefonu w ręku (poza krokiem ze stuknięciami — wtedy telefon nadal leży, tylko stukasz palcem).

| Ekran | Co robisz |
|---|---|
| **Pomiar opóźnień** | Sprawdź, czy typ telefonu się zgadza (Pixel / flagowiec, średnia półka, tani). Jeśli nie, dotknij **Zmień typ**. Potem **Zaczynamy**. |
| **Przygotowanie** | Połóż telefon ekranem do góry na stole i dotknij **Gotowe**. |
| **Krok 1: drgania** | Nic nie dotykasz. Telefon ok. 15 s krótko wibruje. |
| **Krok 2: ciągły opór** | Nic nie dotykasz. 4 s lekkiego drżenia. |
| **Krok 3: dźwięk** | Telefon zapyta o **mikrofon** → **Zezwól** (tylko podczas używania aplikacji). Potem 60 kliknięć; nie mów i nie dotykaj telefonu. Nic nie jest nagrywane na stałe ani wysyłane. |
| **Krok 4: stuknięcia** | Stuknij opuszką palca w środek koła **20 razy**, spokojnie, mniej więcej raz na sekundę. Licznik pokazuje, ile zostało. |
| **Wynik** | Lista wyników ze słowami: **Przechodzi**, **Na granicy**, **Nie przechodzi**, **Brak danych** (kształt obok: koło, trójkąt, ośmiokąt, pusty pierścień). |

![Ekran startowy](../../spikes/measure/screens/android_intro.png) ![Ekran wyniku (przykładowe liczby)](../../spikes/measure/screens/android_demo.png)

Jeśli wynik wygląda dziwnie (dużo „Brak danych”), powtórz pomiar na twardszym stole i w cichszym pokoju — przycisk **Powtórz pomiar**.

## 5. Gdzie wkleić wynik

1. Na ekranie wyniku dotknij **Udostępnij wynik**. Otworzy się systemowe okno udostępniania.
2. Wybierz **Gmail / Mail** i wyślij do siebie, albo **Dysk Google / Pliki** — to tekst w formacie JSON (zaczyna się od `{"schema": "lockwright.measure/1"`).
   - Android dodatkowo sam zapisuje plik w **Pobrane/Lockwright/** (`lockwright-pomiar-android-<model>-<data>.json`).
3. Wrzuć plik do repo — najprościej przez stronę GitHuba:
   - wejdź w katalog **`spikes/measure/results/`** (jeśli go nie ma: **Add file → Create new file**, w nazwie wpisz `spikes/measure/results/` i nazwę pliku),
   - **Add file → Upload files** (albo wklej tekst JSON przy „Create new file”, nazwa pliku `telefon-data.json`),
   - na dole **Commit changes** (bez zmian w opcjach).
4. Następna sesja (albo ktokolwiek) uruchomi `python3 spikes/measure/tools/ingest.py spikes/measure/results/*.json` — skrypt sam przeliczy werdykty i dopisze tabelę do `docs/TECH.md` (rozdział „Wyniki pomiarów na telefonach właściciela”).

## 6. Co dokładnie mierzymy (dla ciekawych)

| Wynik | Co to znaczy | Próg (TECH §4) |
|---|---|---|
| Stuknięcie → drganie | Od uderzenia palca w szybę (widać je w akcelerometrze) do początku wibracji. Obejmuje ekran dotykowy, aplikację i silnik wibracji. | Pixel ≤ 35 ms, średnia półka ≤ 50 ms, tani ≤ 100 ms (p95) |
| Polecenie → drganie | Od wywołania funkcji wibracji do drgań — sam silnik wibracji. | pomocniczo |
| Stuknięcie → kliknięcie | Od odgłosu stuknięcia (mikrofon) do kliknięcia z głośnika (szybka ścieżka Oboe). | Pixel ≤ 35 ms, średnia ≤ 50 ms, tani ≤ 80 ms (p95) |
| Zysk szybkiej ścieżki dźwięku | O ile nasza ścieżka (Oboe) gra szybciej niż zwykły dźwięk Godota. | ≥ 30 ms |
| Przerwy w ciągłym oporze | Najdłuższa przerwa w „ciągłym” drżeniu (czy opór się rwie). | ≤ 15 ms |
| Dźwięk a drganie | Rozjazd kliknięcia i wibracji tego samego zdarzenia. | ≤ 15 ms |

Dokładność: Android z akcelerometrem ≥ 200 Hz — ok. 2–5 ms (wystarcza na decyzję zgodnie z D-33). iPhone ma akcelerometr ok. 100 Hz — dokładność ok. ±10 ms; przy wynikach „na granicy” wracamy do pomiaru piezo (D-33).

## 7. Dodatkowo: wydajność planu B (spike 4)

Plan B (ekran zamka z wypieczonym renderem, D-31) mierzymy osobną aplikacją: artefakt **`spike-lit-metal-debug-apk`** (workflow **spike-lit-metal**). Instalacja jak w punkcie 2. Po uruchomieniu:
- prawy górny róg ekranu przełącza wariant A ⇄ B (napis w lewym górnym rogu),
- na ekranie widać FPS i czas klatki; zostaw telefon na 10 minut w wariancie B,
- zrób zrzut ekranu po 1 minucie i po 10 minutach (przyciski zasilania + głośność w dół) i wrzuć oba do `spikes/lit-metal/results/` tak jak JSON w punkcie 5.

### 7a. Prawdziwy ekran zamka w planie B (scena sesji A)

Artefakt **`planb-perf-apk`** (workflow **spike-planb**) to ekran zamka z gry (`game/scenes/photoreal/lock_photoreal.tscn`) z małym licznikiem w lewym górnym rogu. Instalacja jak w punkcie 2 (plik `lw-planb-perf.apk`).

1. Uruchom, połóż telefon i nie wychodź z aplikacji. Aplikacja sama nie pozwala ekranowi zgasnąć; telefon nie powinien być podłączony do ładowarki (inaczej nie widać spadków przy nagrzaniu).
2. Przez pierwszą minutę licznik pokazuje „Rozgrzewka”, potem „Pomiar: zostało … s” (10 minut). Możesz w tym czasie ruszać kciukami jak w grze, ale nie musisz.
3. Po 10 minutach pojawi się wiersz **„Wynik 10 min: Przechodzi / Na granicy / Nie przechodzi”** z liczbami (p95 czasu klatki i „1% low”). **Zrób zrzut ekranu** i wrzuć go do `spikes/lit-metal/results/` (jak JSON w punkcie 5).

Progi (TECH §4, spike 4): czas klatki p95 ≤ 16,7 ms i 1% low ≥ 55 FPS przez 10 minut na tanim Androidzie.

## 8. Budżety wydajności (progi dla gry)

Te progi obowiązują grę od teraz (sesja C, etap 3). „Tani” = klasa urządzeń ze spike'u 4 (Android ok. 4 GB RAM,
Mali-G52/G57 lub PowerVR, ekran 720p–1080p, haptyka A0/A1); „średni” = Samsung Galaxy A-klasy / iPhone sprzed 4–5 lat
(6 GB RAM, Mali-G68/Adreno 6xx/A13–A14, haptyka A2/A3 lub Core Haptics). Wartości na telefonie mierzy właściciel
(aplikacja z punktu 7a dla FPS; reszta w tabeli niżej), w CI pilnujemy tego, co da się zmierzyć bez telefonu.

| Miara | Tani Android | Średni (Android / iPhone) | Skąd próg | Jak mierzymy |
|---|---|---|---|---|
| FPS ekranu zamka (plan B) | p95 czasu klatki ≤ 16,7 ms, 1% low ≥ 55 FPS przez 10 min | to samo + ≤ 8,3 ms na 120 Hz (ProMotion) — opcjonalnie | TECH §4 spike 4; haptyka i dźwięk w kroku fizyki 120 Hz nie mogą czekać na klatkę | `planb-perf-apk` (7a), 10 min, bez ładowarki |
| FPS menu | ≥ 55 FPS, brak przycięć > 50 ms przy przewijaniu list | ≥ 58 FPS | płynność przewijania | ten sam licznik, przewijanie listy zleceń |
| Logika na krok (lockcore + describe + feedback) | ≤ 0,5 ms (p95) | ≤ 0,25 ms | 8,3 ms budżetu kroku 120 Hz, logika ≤ 6% | GUT `test_perf.gd` (sesja B: 5,7 µs/krok na CI) |
| Pamięć (PSS całej aplikacji) | ≤ 350 MB w ekranie zamka, ≤ 300 MB w menu | ≤ 450 MB | system ubija aplikacje w tle powyżej ok. 400 MB na 4 GB RAM | `adb shell dumpsys meminfo <pakiet>` / Xcode Memory gauge |
| VRAM / tekstury | ≤ 150 MB | ≤ 250 MB | plan B: 110 MB przy 1320×2868 (LW_PERF) | licznik `vram_mb` w `planb-perf-apk` |
| Rozmiar APK (pobranie z Google Play, arm64) | **≤ 80 MB** (ostrzeżenie), twardo ≤ 150 MB | — | tanie telefony mają mało miejsca; Play: limit modułu bazowego AAB 200 MB (sprawdzić aktualny) | artefakt `game-android`, `check_budget.py --apk` |
| Rozmiar IPA (pobranie z App Store) | — | **≤ 100 MB** pobrania | powyżej 200 MB iOS pyta o pobranie przez sieć komórkową | App Store Connect → „App Store File Sizes” |
| Zasoby gry (pck z presetem Android) | ≤ 120 MB (ostrzeżenie), ≤ 150 MB (błąd CI, D-64) | — | dziś 26,5 MB; większość APK to zasoby + silnik (ok. 15–20 MB skompresowany) | CI: `qa/budget/check_budget.py` |
| Czas startu do menu (zimny start) | ≤ 4 s (bez 3-sekundowej noty przy pierwszym starcie) | ≤ 2 s | wytyczne Androida: zimny start > 5 s to „wolny” (Android vitals) | `adb shell am start -W` (TotalTime) / Xcode Instruments „App Launch” |
| Czas startu headless (CI, proxy) | ≤ 1,0 s ostrzeżenie, ≤ 2,0 s błąd | — | dziś 0,36 s (mediana z 5, kontener CI) | CI: `check_budget.py` |
| Wejście do ekranu zamka headless (CI, proxy) | ≤ 1,2 s ostrzeżenie, ≤ 2,5 s błąd | — | dziś 0,55 s | CI: `check_budget.py` |
| RSS startu headless (CI, proxy wycieków i zbyt dużych zasobów) | ≤ 200 MB ostrzeżenie, ≤ 300 MB błąd | — | dziś 105 MB | CI: `check_budget.py` |
| Temperatura / dławienie | 1% low nie spada o > 10% między 1. a 10. minutą | to samo | gra na wyczucie trwa długo | `planb-perf-apk`: zrzut po 1 i 10 min |

**Automat CI:** workflow `perf-budget` (`.github/workflows/perf-budget.yml`) przy każdym pushu do `game/**` i co noc:
eksport zasobów z presetem Android, pomiar startu headless i wejścia do ekranu zamka, raport `budget.md` w podsumowaniu
joba (artefakt `perf-budget`). Przekroczenie „ostrzeżenia” daje adnotację ⚠ w runie, przekroczenie „błędu” — czerwony
run. Progi: `qa/budget/budgets.json`. Rozmiar samego APK sprawdzi ten sam skrypt z `--apk`, gdy `game-android` znowu
będzie dawał artefakt (na 2026-11-05 runy 62–65 kończą się błędem).

Uwaga: czasy headless z CI nie są czasem startu na telefonie (brak GPU, szybki dysk) — służą do wykrywania regresji
(np. ktoś ładuje wszystkie tekstury w autoloadzie), nie do oceny wrażeń.
