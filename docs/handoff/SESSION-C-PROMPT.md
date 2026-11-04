# Prompt dla trzeciej sesji (sesja C, Claude Code, praca nocna)

Przed startem: konto GitHub tej sesji musi mieć dostęp do zapisu (push) w repo `woogitsugames/lockwright`. W Claude Code na webie: Settings → Connectors → GitHub, aplikacja Claude zainstalowana na tym repo albo konto dodane jako collaborator z prawem zapisu.

Skopiuj wszystko poniżej linii.

---

Pracujesz całą noc samodzielnie nad mobilną grą premium **Lockwright** („Lockwright: Pogotowie Zamkowe” / „Lockwright: Emergency Locksmith”). Gracz jest legalnym ślusarzem z pogotowia i otwiera zamki ludziom zatrzaśniętym za drzwiami. Ekran pokazuje fotorealistyczny przekrój zamka, a sterowanie odbywa się dwoma kciukami: lewy dawkuje napięcie, prawy prowadzi wytrych. Haptyka i dźwięk są sednem gry, jest też tryb „w ciemności”. Platformy: iOS (wiodący) i Android. Silnik: **Godot 4.7.2**. Logika zamka to biblioteka C++20 `lockcore/`. Wygląd to maksymalny fotorealizm (modele proceduralne w Blenderze, `art/blender/`).

Nie pytaj o zgodę. Pracuj zadanie po zadaniu i **wszystko wypychaj na GitHub**: właściciel nic nie robi ręcznie. Możesz używać **jednego subagenta Opus naraz** (np. do researchu albo równoległego kawałka). Agenci nie uruchamiają kolejnych agentów.

## 0. Git (obowiązkowe)
- `git clone https://github.com/woogitsugames/lockwright.git && cd lockwright`. Gałąź **`main`**, pracujemy bezpośrednio na niej (decyzja właściciela D-02).
- Przed każdym pushem `git pull --rebase origin main`, potem `git push origin main`. Konflikty rozwiązuj sam, bez kasowania cudzej pracy. Przy błędzie sieci ponów do 4 razy (2, 4, 8, 16 s).
- Małe, opisowe commity po angielsku. **Push po każdym skończonym kroku i co najmniej co 45 minut.** Nigdy nie zostawiaj niewypchniętej pracy.
- Zakaz `push --force`, `reset --hard` na `main` i przepisywania historii.
- Równolegle pracują inni, więc **nie ruszaj** (tylko czytaj): `lockcore/`, `art/`, `mockups/`, `game/`, `platform/`, `audio/`, `data/`, `docs/styles/`, `docs/ONBOARDING.md`, `docs/LEVELS.md`, `docs/HUD.md` i istniejących workflowów w `.github/workflows/`.
- **Twoje katalogi:** `spikes/`, `store/`, `docs/handoff/SESSION-C-LOG.md`, nowe workflowy `.github/workflows/spike-*.yml`.
- Decyzje dopisuj na końcu `docs/DECISIONS.md` jako kolejny wolny `D-NN` (sprawdź ostatni numer tuż przed commitem). Zasoby wpisuj do `docs/ASSETS.md`. Dozwolone tylko zasoby własne, CC0 albo fonty OFL.

## 1. Przeczytaj najpierw
`CLAUDE.md`, `docs/DECISIONS.md`, `docs/TECH.md` (szczególnie spike'i 1–5 z kryteriami „przeszło / nie przeszło”, warstwy haptyki, audio, CI, urządzenia), `docs/ARCHITECTURE.md`, `docs/DESIGN.md`, `docs/styles/realizm.md`, `docs/RESEARCH.md`, `lockcore/README.md`, `art/blender/*.py`. Obejrzyj też rendery w `art/renders/`.

## 2. Zasady gry
Ton ciepły i legalny. Mechanizmy wymyślone, **bez marek** i bez instrukcji do prawdziwych produktów. Teksty dla gracza zawsze PL i EN przez i18n. Kod po angielsku, raporty po polsku. Bez reklam, energii i pay-to-win. Na ekranie zamka **nie ma paneli UI** (D-12).

## 3. Zadania na noc (po kolei)

### Zadanie C1: spike 4, fotorealistyczny metal w Godot 4.7 (`spikes/lit-metal/`)
Cel: sprawdzić, czy wygląd z renderów Cycles (`art/renders/section*.png`) da się osiągnąć w czasie rzeczywistym na rendererze **Mobile** przy 60 FPS na tanim Androidzie.
1. Zainstaluj Blender 4.2 LTS (`https://download.blender.org/release/Blender4.2/blender-4.2.9-linux-x64.tar.xz`), Godot 4.7.2 (Linux i export templates) oraz Xvfb i mesa (Vulkan lavapipe albo OpenGL llvmpipe), żeby renderować bez GPU.
2. Wyeksportuj scenę przekroju do glTF: `blender -b -P art/blender/cutaway.py -- --glb spikes/lit-metal/assets/cutaway.glb --res 64x64 --samples 1`. Skrypt ma opcję `--glb`. Nie edytuj `art/`; jeśli eksport wymaga zmian, skopiuj skrypt do `spikes/lit-metal/tools/` i zmieniaj kopię. Materiały proceduralne z Blendera trzeba **wypiec do tekstur** (baked base color, roughness, normal, AO; 2K na obiekt lub atlas). Napisz skrypt bake w `spikes/lit-metal/tools/bake.py`.
3. Projekt Godot `spikes/lit-metal/project.godot` na rendererze Mobile. Ustaw `StandardMaterial3D` (metallic, roughness, normal i AO z wypieku), światło jak w Blenderze (klucz ciepły z lewej, wypełnienie, ReflectionProbe, opcjonalnie LightmapGI dla nieruchomych części) oraz kamerę jak w `cutaway.py` (ogniskowa 180 mm, yaw −22°, pitch 10°). Bez bloomu i glow. Tonemapping AgX lub Filmic dopasowany do Cyclesa.
4. Zrzuty z Godota (`--headless` z Xvfb albo `--write-movie`) do `spikes/lit-metal/screens/` w 1236×1650 i 2160×2880, obok porównanie z Cyclesem (`compare.png`, lewa i prawa połowa). Iteruj, aż różnica będzie trudna do zauważenia. Opisz w raporcie, co odstaje.
5. Wydajność: licznik klatek i czasu GPU w scenie, animowane piny (ruch góra–dół 1 Hz) i wytrych. Build debug APK (Android, arm64) z workflowem `.github/workflows/spike-lit-metal.yml` (artefakt APK do pobrania przez właściciela na tani telefon). Zapisz w `spikes/lit-metal/README.md`, jak zmierzyć FPS na telefonie i jakie są kryteria z TECH.md.
6. Wariant „plan B” w tym samym projekcie: wszystko wypieczone (lightmapa i matcap dla metalu), przełączane w scenie. Porównanie jakości i kosztu.
7. Commit i push po każdym punkcie. Raport do `docs/handoff/SESSION-C-LOG.md`.

### Zadanie C2: spike 3, dźwięk kliknięcia < 30 ms na Androidzie (`spikes/audio-latency/`)
1. Zainstaluj JDK 17, Android SDK (platform 36, build-tools 36) i NDK 29.0.14206865.
2. Plugin Godot Android v2 (AAR) **`LockwrightLowLatencyAudio`** na **Oboe** (Apache 2.0, wpis w ASSETS): strumień AAudio w trybie PerformanceMode::LowLatency i SharingMode::Exclusive z fallbackiem, prealokowane próbki PCM (mosiądz i stal: `set`, `false_set`, `break`, `contact`), wyzwalanie z wątku gry bez alokacji i miksowanie w callbacku. API: `load_sample(id, pcm_bytes, rate)`, `play(id, gain, pitch)`, `stats()` (framesPerBurst, bufferSize, sampleRate, performanceMode, estimated latency).
3. Próbki: wygeneruj własne kliknięcia (Python: numpy, synteza modalna), WAV 48 kHz. Nie kopiuj z `audio/` (to katalog innej sesji). Tymczasowo umieść je w `spikes/audio-latency/samples/`.
4. Aplikacja testowa Godot `spikes/audio-latency/`: pełnoekranowe pole dotyku. Dotyk gra klik dwiema ścieżkami do porównania (Oboe vs `AudioStreamPlayer` Godota) i pokazuje statystyki. Instrukcja pomiaru w README (mikrofon przy głośniku i mikrofon kontaktowy na ekranie, nagranie 48 kHz, analiza skryptem `tools/measure.py` z detekcją onsetów i raportem p50/p95).
5. Workflow `.github/workflows/spike-audio.yml` budujący APK jako artefakt. Commit i push.

### Zadanie C3: spike 5, determinizm na ARM (`spikes/determinism/`)
1. Cross-kompilacja `lockcore` (tylko czytasz katalog i budujesz go z zewnątrz przez CMake `-S ../../lockcore`) na **Android arm64** (NDK toolchain) i **Linux aarch64** (`aarch64-linux-gnu-g++`).
2. Uruchom testy i złote powtórki (`lockcore/tests/golden/`) przez **qemu-user** (`qemu-aarch64-static`) dla obu buildów i porównaj hashe strumienia zdarzeń z buildem x86_64 gcc i clang. Wynik zapisz w tabeli w `spikes/determinism/RESULTS.md`.
3. Dodatkowo `tools/replay_fuzz`: 10 000 losowych powtórek nagranych na x86_64, odtworzonych na arm64 (qemu), z porównaniem hashy (kryterium: 100% zgodności).
4. Workflow `.github/workflows/spike-determinism.yml` (ubuntu-latest z qemu oraz macos-latest arm64 natywnie z clang Apple). Pilnuj zielonego CI (sprawdzaj przez `gh run list` / `gh run view`, jeśli dostępne). Commit i push.
5. Jeśli znajdziesz rozjazd, **nie poprawiaj `lockcore/`**. Opisz minimalny przypadek w `RESULTS.md` i w logu (inna osoba poprawi).

### Zadanie C4: spike 1 i 2, aplikacje pomiarowe haptyki (`spikes/haptics-latency/`)
1. Projekt Godot z dwoma minimalnymi natywnymi modułami pomiarowymi (to spike, nie moduł produkcyjny z `platform/`):
   - **iOS:** Swift i Core Haptics, continuous z dynamic parameters plus transient;
   - **Android:** Kotlin z `VibrationEffect.Composition` i fallbackami.
   Ekran: dotyk wyzwala transient, przesuw zmienia ciągły opór. Pokaż znacznik czasu dotyku i wywołania API.
2. Natywne aplikacje kontrolne (bez Godota) z tym samym efektem, do porównania narzutu silnika: `spikes/haptics-latency/native-ios/` (SwiftUI) i `native-android/` (Kotlin, Compose).
3. Instrukcja pomiaru (piezo na obudowie, mikrofon, interfejs audio 48 kHz, kamera 240 fps) i `tools/analyze.py`. Kryteria z TECH.md w README.
4. Workflowy: Android APK (ubuntu) i iOS build bez podpisu (macos-latest, `CODE_SIGNING_ALLOWED=NO`). Commit i push.

### Zadanie C5: sklep i marka (`store/`)
1. `store/listing.md`: teksty sklepu PL i EN (App Store i Google Play): nazwa, podtytuł (≤ 30 znaków), krótki opis (≤ 80 dla Play), pełny opis, słowa kluczowe (≤ 100 znaków App Store), „Co nowego”. Głos ludzkiego ślusarza, bez marketingowego slopu („Unlock your potential!”), bez marek i bez sugerowania włamań. Zgodność z wytycznymi Apple 2.3.7 (bez „free to try” w nazwie).
2. `store/rating.md`: odpowiedzi na kwestionariusz oceny wiekowej (App Store age rating i IARC dla Google Play) z uzasadnieniem (cel 4+ / PEGI 3; tematyka to legalny ślusarz).
3. `store/privacy.md`: polityka prywatności (gra offline, brak zbierania danych osobowych, brak reklam i trackingu, lokalny zapis) w PL i EN, gotowa do hostingu, oraz odpowiedzi do App Privacy „Data Not Collected” i Data safety w Play.
4. `store/screenshots/`: plan 6–8 zrzutów do sklepu (kadry ze scen fotorealistycznych, krótkie podpisy PL i EN w głosie ślusarza, bez paneli UI). Jeśli w repo są już rendery i zrzuty z Godota, złóż makiety zrzutów w wymaganych rozmiarach (iPhone 6,9" 1320×2868, Android 1080×1920) skryptem Python (Pillow), z podpisem fontem OFL (np. Bona Nova, Atkinson Hyperlegible Next z `mockups/fonts/`). Nie dodawaj ramek telefonów ani gradientów.
5. Commit i push.

### Zadanie C6 (jeśli zostanie czas): przegląd i raport ryzyk
Przeczytaj, co nocą wypchnęły inne sesje (`git log`), i napisz w `docs/handoff/SESSION-C-REVIEW.md` przegląd techniczny:
- niezgodności między `lockcore/` API a `game/addons/lockcore_gd/`;
- brakujące testy;
- zagrożenia wydajności;
- naruszenia zasad z CLAUDE.md (np. teksty na sztywno, marki, panele UI na ekranie zamka).

Tylko raport, bez poprawiania cudzego kodu.

## 4. Raportowanie
Po każdym zadaniu dopisz wpis po polsku do `docs/handoff/SESSION-C-LOG.md`: data i godzina, co zrobione, wyniki liczbowe (np. FPS, ms, hashe), linki do zrzutów i artefaktów CI, co blokuje. Commit i push. Gdy coś blokuje, opisz to i przejdź do następnego zadania.

## 5. Definicja „gotowe”
Działa lokalnie albo w CI (zielone), wyniki są zapisane liczbami, zrzuty i artefakty dostępne, zasoby wpisane do ASSETS, jest **push na `main`** i wpis w logu.
