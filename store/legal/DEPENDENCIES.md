> **Szkic do konsultacji z prawnikiem.** Audyt licencji zależności (sesja C, etap 4, zadanie 8), stan repo 2026-11-05.
> Wersje i licencje sprawdzone w plikach repo (Gradle, CMake, workflowy, `game/addons/*/LICENSE*`) i w dokumentacji
> projektów; przed wydaniem porównać z plikami licencji w wydanym buildzie (lista komponentów Godota zmienia się między wersjami).

# Zależności i obowiązki licencyjne

## 1. Co trafia do aplikacji (APK / IPA) — obowiązki dotyczą wydania

| Komponent | Wersja (repo) | Licencja | Skąd | Obowiązek w aplikacji |
|---|---|---|---|---|
| **Godot Engine** (runtime w szablonach eksportu) | 4.7.2-stable | MIT | szablony eksportu | Tekst licencji MIT Godota + nota „Portions of this software are copyright © the Godot Engine contributors” w aplikacji (ekran „Licencje”/„O grze” albo plik dostępny z menu). Treść: `Engine.get_license_text()`. |
| Komponenty firm trzecich wbudowane w Godota (m.in. FreeType, HarfBuzz, ICU, libpng, zlib, mbedTLS, Brotli, libwebp, Zstandard, Recast/Detour, xatlas…) | jak w 4.7.2 | różne liberalne: FreeType License (FTL, wybór zamiast GPLv2), MIT, BSD, zlib, Apache-2.0 (mbedTLS), Unicode/ICU | wewnątrz silnika | **Wymagane noty copyright i teksty licencji** (szczególnie FTL: wzmianka o FreeType w dokumentacji/kredytach; Apache-2.0: tekst licencji i NOTICE). Najprościej: wygenerować w grze listę z `Engine.get_copyright_info()` + `Engine.get_license_info()` (zawsze zgodna z użytą wersją silnika). |
| **godot-cpp** (wiązania GDExtension w `lockcore_gd`, `lockwright_haptics` iOS) | master (klonowany w CI, bez przypiętej wersji) | MIT | `github.com/godotengine/godot-cpp` | nota copyright + tekst MIT. **Ryzyko:** brak przypiętego commitu → build nieodtwarzalny; przypiąć tag/commit (np. `--branch 4.5`/SHA zgodny z 4.7 API). |
| **lockcore**, `lockcore_gd`, wtyczki `lockwright_haptics` (Android/iOS), `lockwright_click_audio` | własne | własne (bez licencji zewnętrznej) | repo | — (opcjonalnie: „© właściciel”) |
| **Oboe** (w `lockwright-click-audio`, linkowane statycznie) | 1.9.3 (`FetchContent`, `platform/android/lockwright-click-audio/src/main/cpp/CMakeLists.txt:8`) | Apache-2.0 | `github.com/google/oboe` | Tekst Apache-2.0 + nota copyright Google; NOTICE, jeśli projekt go ma. |
| Biblioteki Androida w szablonie Godota (AndroidX, Kotlin stdlib w AAR wtyczek) | wg szablonu 4.7.2 / Kotlin 2.1.21 | Apache-2.0 | Maven (Google, JetBrains) | Teksty Apache-2.0 / noty — zbiorczo w ekranie licencji. Wtyczki mają `compileOnly 'org.godotengine:godot:4.7.2.stable'` (nie dokładają kopii Godota). |
| iOS: Core Haptics, AVFoundation, UIKit | systemowe | warunki Apple SDK | Xcode | brak (frameworki systemowe) |
| **Atkinson Hyperlegible Next**, **Bona Nova** (`game/assets/fonts/`) | — | SIL OFL 1.1 | Google Fonts | Licencja OFL dołączona (`OFL-*.txt` są w `game/assets/fonts/`) ✅; fontów nie wolno sprzedawać osobno — w grze OK. |
| Dźwięki `audio/v2` → `game/assets/audio` | własne (synteza) | własne | `docs/ASSETS.md` | — |
| Grafiki: rendery Blendera, makiety, (wkrótce) dostawy ChatGPT | własne / AI (D-42) | własne; AI zgodnie z warunkami narzędzia | `docs/ASSETS.md`, `contrib/REVIEW.md` | wpis w ASSETS z narzędziem i promptem (D-42); warunki narzędzia AI sprawdzić pod kątem użycia komercyjnego |

## 2. Tylko w repo / edytorze / CI — **nie** trafiają do aplikacji

| Komponent | Wersja | Licencja | Gdzie | Uwagi |
|---|---|---|---|---|
| **GUT** (Godot Unit Test) | 9.7.1 | MIT | `game/addons/gut/` | wykluczony z eksportu (`exclude_filter`); fonty GUT (Anonymous Pro, Courier Prime, Lobster Two) — OFL, noty uzupełnione w ed5dfda (C-05) |
| Blender | 4.2.9 | GPL-2.0+ | `art/` (generowanie renderów) | GPL nie obejmuje wyników renderu ani naszych skryptów uruchamianych w Blenderze jako osobne pliki danych; skrypty `art/blender/*.py` korzystają z API Blendera — jeśli kiedyś będą dystrybuowane, traktować jako GPL |
| SCons | z PyPI | MIT | CI | — |
| CMake, Ninja | systemowe | BSD-3 / Apache-2.0 | CI | — |
| Android SDK, NDK 29, Gradle 8.14, AGP 8.6.1, Kotlin | — | Android SDK License / Apache-2.0 | CI | warunki SDK akceptowane `sdkmanager --licenses` |
| Xcode 26 | — | Xcode/Apple SDK Agreement | CI macOS | — |
| Python, numpy, Pillow | — | PSF / BSD-3 / MIT-CMU | narzędzia `audio/`, `store/`, `site/`, `qa/` | — |
| Playwright, three.js | 1.63.0 / ^0.170.0 | Apache-2.0 / MIT | `mockups/` (D: tylko makiety) | three.js ma zakres `^` → przypiąć wersję |
| GitHub Actions: checkout, setup-python, setup-java, cache, upload/download-artifact | v4/v5 | MIT | `.github/workflows` | — |
| `reactivecircus/android-emulator-runner` | v2 | Apache-2.0 | `spike-determinism-apk.yml` | — |
| Fonty makiet (Brygada 1918, Fraunces, Bitter, Big Shoulders Stencil, Lato, Source Serif 4) | — | OFL 1.1 | `mockups/fonts/` | licencje obok plików ✅ |
| Strona `site/` | — | — | kopie fontów OFL + licencje (`site/public/fonts/OFL-*.txt`) ✅ | |

## 3. Obowiązki — co musi być w wydaniu (lista dla sesji B)
1. **Ekran „Licencje”** (z „O grze”), przewijany, przez i18n tylko nagłówki: teksty licencji zostają w oryginale (EN).
   Zawartość: (a) MIT Godota + `Engine.get_copyright_info()` / `get_license_info()` (komponenty silnika i ich licencje);
   (b) godot-cpp (MIT); (c) Oboe (Apache-2.0, Android); (d) AndroidX/Kotlin (Apache-2.0, Android); (e) OFL 1.1 dla
   Atkinson Hyperlegible Next i Bona Nova z notami copyright.
2. Plik **`THIRD-PARTY-NOTICES.txt`** w `game/` (eksportowany, `include_filter`) z tym samym tekstem — przydatny też dla
   sklepów i prawnika.
3. Przypięcie wersji: godot-cpp (commit/tag), three.js (dokładna wersja).
4. Dla wariantu D-06 A (IAP): brak dodatkowych bibliotek (StoreKit / Play Billing przez wtyczkę — dopisać licencję
   wtyczki, gdy zostanie wybrana).

## 4. Rozbieżności (zgłoszone w `docs/handoff/SESSION-C-REVIEW.md`)
- **N-27:** w repo nie ma `THIRD-PARTY-NOTICES` ani ekranu licencji (przeszukane: `find -iname "*third*party*"`, `grep -ri licen game/scenes game/scripts`) — wydanie naruszałoby MIT Godota i Apache-2.0 Oboe.
- **N-28:** godot-cpp klonowany z `master` bez przypięcia (`game-tests.yml`, `game-android.yml`, `game-ios.yml`, moje `qa-career.yml`, `perf-budget.yml`, `spike-determinism-apk.yml` przypięte 2026-11-05 do `e103d348c4b2`) — nieodtwarzalny build i ryzyko zmiany API/NDK (jak N-21).
