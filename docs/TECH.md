# Lockwright — plan techniczny (silnik, haptyka, dźwięk, spike'i, CI)

Stan na 2026-11-04. To dokument planistyczny. Kodu gry jeszcze nie ma, a szkice API poniżej to sygnatury, nie implementacja.
Decyzja o silniku należy do właściciela (zob. CLAUDE.md). Sekcja 1 zawiera rekomendację i warunki, przy których należy ją zmienić.

Oznaczenia: **[zweryfikowane]** = sprawdzone w źródle w XI 2026 (link w „Źródłach”); **[szacunek]** = liczba robocza do potwierdzenia w spike'u; **[do sprawdzenia]** = nie udało się potwierdzić.

---

## 0. Streszczenie

- **Rekomendacja: Godot 4.7.x (obecnie 4.7.2-stable, MIT) i własne cienkie mostki natywne** dla haptyki (iOS: Core Haptics, Android: VibratorManager) oraz **dla dźwięku kliknięć na Androidzie (Oboe/AAudio)**. Logikę zamka umieszczamy w **osobnej bibliotece C++20 bez zależności od Godota** („lockcore”), z arytmetyką stałoprzecinkową. Godot dostaje ją jako GDExtension, a CI na Linuksie testuje ją natywnie.
- Wcześniejszy research potwierdził się, z poprawkami:
  1. Aktualna gałąź stabilna to 4.7, nie 4.6. 4.6.3 to ostatnia łatka 4.6, a master jest już na 4.8-beta.
  2. **Godot na Androidzie wciąż używa OpenSL ES** z zakodowanymi na sztywno 44,1 kHz i buforem 2 × 1024 ramek. Sam bufor aplikacji to ok. 46 ms, a do tego dochodzi resampling do natywnej częstotliwości 48 kHz i HAL. Celu „dotyk→dźwięk < 30 ms” na Androidzie nie osiągniemy bez własnej ścieżki audio. To największe nowe ryzyko.
  3. Android ma nowe API `VibrationEffect.Builder` (dokumentacja: „Android 16 (26Q4)”, w referencji „added in version 37.2”) z **automatycznym fallbackiem** prymitywów i obwiedni podstawowych. Nie obejmuje ono `WaveformEnvelopeBuilder`.
  4. Unity: aktualne LTS to 6.3 (6000.3.x, wsparcie do XII 2027). Pro kosztuje od 12.01.2026 2310 $/stanowisko/rok, a Personal jest darmowy do 200 tys. $.
  5. Apple od 28.04.2026 wymaga Xcode 26+ i SDK iOS 26. Google Play od 31.08.2026 wymaga targetSdk 36.
- Największe ryzyka: (a) opóźnienie dźwięku na Androidzie, (b) ciągły opór na Androidzie, bo nie ma tam odpowiednika `CHHapticAdvancedPatternPlayer.sendParameters` i trzeba skleić krótkie obwiednie, (c) stabilność eksportu GDExtension na iOS (zgłoszenia problemów z 4.5), (d) wydajność oświetlonego metalu na tanich GPU Mali/PowerVR, (e) rozróżnialność set/false_set wyłącznie z dźwięku (iPad, tanie ERM).

---

## 1. Weryfikacja silnika

### 1.1 Stan wersji (XI 2026)

| Silnik | Wersja bieżąca | Licencja / koszt | Uwagi |
|---|---|---|---|
| **Godot** | **4.7.2-stable** (4.7 wydane VI 2026, 4.7.1 VII, 4.7.2 VIII); 4.6.3 = ostatnia łatka 4.6; master = 4.8-beta **[zweryfikowane: tagi w repo]** | MIT, 0 zł | 4.7: GABE (budowanie Androida z Androida), Mobile renderer „dorównuje lub przewyższa” Compatibility w części benchmarków, HDR na iOS, kontrolery iOS przez SDL3 |
| **Unity** | 6.3 LTS (6000.3.x, wsparcie do XII 2027); 6.6 w Supported; 6.7 w becie **[6.3 zweryfikowane; 6.6/6.7 z jednego źródła wtórnego]** | Personal 0 $ do 200 tys. $ przychodu+finansowania; Pro 2310 $/rok/stanowisko (od 12.01.2026); Runtime Fee odwołany | Nice Vibrations jako osobny produkt wycofany; Feel (More Mountains) płatny |
| **Natywnie** | Xcode 26.x / iOS 26 SDK; Android Studio, AGP 8.x, compileSdk 36 | 0 | Dwa kody UI/renderu; najlepszy dostęp do haptyki i audio |
| Defold | 1.x (aktualna linia) | Defold License (na bazie Apache 2.0) | Lua, małe buildy, dobre 2D, rozszerzenia natywne C++/ObjC/Java; brak gotowej haptyki |
| Bevy | 0.x | MIT/Apache | Rust; wsparcie iOS/Android dojrzewa, brak edytora, za duże ryzyko na premium mobile |
| Flutter + Flame | Flutter 3.x | BSD | Dart (nie JS); haptyka przez platform channels; słaby wybór dla oświetlonego 2,5D i niskiej latencji audio |

### 1.2 Godot na iOS — jak zrobić wtyczkę (Core Haptics)

Są trzy ścieżki. Wszystkie wymagają macOS z Xcode do zbudowania aplikacji.

1. **Klasyczna „iOS plugin” (.gdip + .xcframework ze statycznymi .a)**. W dokumentacji 4.7 opisana dalej jako podstawowa, choć strona ma ostrzeżenie, że nie została zaktualizowana do 4.7. Biblioteka to Objective-C++ budowane z nagłówkami silnika (SCons), rejestrująca singleton (`Engine.get_singleton("LockwrightHaptics")`). Zależności systemowe (`CoreHaptics.framework`) deklaruje się w `[dependencies] system=` w .gdip. **Wada:** trzeba kompilować na tej samej wersji nagłówków Godota co silnik.
2. **GDExtension (godot-cpp) jako .xcframework**. W pliku `.gdextension` podaje się `ios.release = "res://bin/libhaptics.ios.xcframework"`. Kod w Objective-C++ woła Core Haptics bezpośrednio, bo CHHapticEngine ma API ObjC i Swift nie jest konieczny. Kod w Swift można dołączyć przez `@objc`. **Zaleta:** jedna technologia z lockcore i Androidem (C++ w AAR), stabilne ABI GDExtension. **Ryzyko:** na forum są zgłoszenia problemów z eksportem GDExtension na iOS w 4.5 [do sprawdzenia w 4.7, spike 1].
3. **SwiftGodot (GDExtension w Swift)**. Ten model stosuje **GodotApplePlugins** (Miguel de Icaza, MIT, iOS 17+, xcframework „mergeable library”, +2,5 MB do buildu release). Pakiet obejmuje GameCenter, StoreKit2, Sign in with Apple, iCloud KV, ARKit i CoreMotion. **Core Haptics nie ma**, więc i tak piszemy swój mostek. Sam SwiftGodot nazywa się „eksperymentalnym”, a wszystkie wtyczki muszą być zbudowane na tej samej rewizji SwiftGodot, inaczej aplikacja pada przy starcie.

**Rekomendacja:** ścieżka 2 (godot-cpp + ObjC++). GodotApplePlugins traktujemy jako źródło gotowych integracji GameCenter/StoreKit, jeśli będą potrzebne (wtedy z tym samym SwiftGodot). Jeśli spike 1 wykaże problemy z GDExtension na iOS, przechodzimy na ścieżkę 1.

### 1.3 Godot na Androidzie — plugin v2 (AAR)

- Plugin v2 istnieje od Godota 4.2 (v1 wycofany). To biblioteka Android (AAR) zależna od `org.godotengine:godot` (Maven Central). Ma wpis w manifeście `org.godotengine.plugin.v2.[Nazwa]`, klasę dziedziczącą po `GodotPlugin`, metody z adnotacją `@UsedByGodot` (nazwy 1:1, bez konwersji snake_case) i sygnały przez `getPluginSignals()`/`emitSignal()`. Pakuje ją `EditorExportPlugin` (skrypt `@tool` + `plugin.cfg`). **[zweryfikowane]**
- GDExtension w AAR: `android_aar_plugin = true` w `.gdextension`. Klasa init zwraca ścieżki `.gdextension` przez `getPluginGDExtensionLibrariesPaths()`. Tak spakujemy C++ z Oboe (audio) razem z Kotlinem (haptyka).
- Istniejąca wtyczka **Mobuos/godot-android-haptics** (MIT) daje prymitywy, efekty, kompozycję i waveform z krzywej. Ostatni push był w I 2025, więc nie ma w niej obwiedni z Androida 16 ani `VibrationEffect.Builder`. Posłuży jako referencja. Własny mostek i tak jest potrzebny, choćby dla wspólnego interfejsu z iOS (sekcja 2.4).
- Konfiguracja szablonu Gradle w **4.7.2-stable** **[zweryfikowane: config.gradle]**: AGP 8.6.1, Gradle 8.11.1, compileSdk 36, targetSdk 36, minSdk 24 (domyślnie), build-tools 36.1.0, Kotlin 2.1.21, Java 17, NDK 29.0.14206865. Na masterze (4.8) AGP podniesiono do 8.13.2.
- Minimalny iOS deployment target w eksporcie 4.7.2: 15.0 **[zweryfikowane]**. My ustawiamy wyżej (sekcja 6).

### 1.4 Rozmiar buildu [szacunek]

| | Android (AAB, arm64, pobranie) | iOS (pobranie z App Store) |
|---|---|---|
| Godot 4.7, szablon standardowy | ~25–35 MB | ~30–45 MB |
| Godot, własny szablon (`disable_3d`, wycięte moduły, LTO) | ~15–22 MB | ~20–30 MB |
| Unity 6 URP (IL2CPP, stripping) | ~25–40 MB | ~35–50 MB |
| Defold | ~4–8 MB | ~6–10 MB |

GodotApplePlugins podaje dla „pustego” eksportu Godota 93 MB release (rozmiar przed thinningiem/kompresją App Store), a sama ta wtyczka dodaje +2,5 MB. Właściwy rozmiar zmierzymy w spike'u 4 (App Store Connect → „App Thinning Size Report”, Play Console → „App size”). Zasoby audio i tekstury dominują nad silnikiem, więc ten sam budżet obowiązuje dla każdego wyboru.

### 1.5 Wydajność 2,5D na tanim Androidzie

- **Mobile renderer (Vulkan)**: lepsze oświetlenie i (od 4.7) wydajność porównywalna z Compatibility. Ryzykiem są sterowniki Vulkan na tanich Mali-G52/G57 i PowerVR (Unisoc, MediaTek Helio).
- **Compatibility (OpenGL ES 3.0)**: najszersza zgodność. Światła 2D z normal mapami (`CanvasTexture` + `PointLight2D`) działają w obu rendererach.
- **Proponowany model sceny:** 2D canvas z normal mapami i mapą „specular/roughness” na metalu, 2–3 światła punktowe, bez dynamicznych cieni (cień namalowany lub jako sprite), widok przekroju zamka. Prawdziwe 3D (ortho camera + PBR) tylko wtedy, gdy spike 4 pokaże zapas wydajności. Zasada z DESIGN: bez bloomu na metalu, co i tak oszczędza pass.
- Na urządzeniach z czarnej listy (sterownik Vulkan, profil wydajności) wybieramy renderer w runtime przez `rendering/renderer/rendering_method.mobile` i fallback na Compatibility. Godot sam przełącza się na GLES3, gdy Vulkan jest niedostępny (`fallback_to_opengl3`).

### 1.6 Opóźnienie audio w Godocie [zweryfikowane w źródle 4.7.2]

| Platforma | Sterownik | Bufor | Konsekwencja |
|---|---|---|---|
| Android | **OpenSL ES** (`audio_driver_opensl.cpp`), brak sterownika AAudio/Oboe | `buffer_size = 1024` ramek, `BUFFER_COUNT = 2`, **44,1 kHz na sztywno**, `audio/driver/output_latency` ignorowane | ≥ 46 ms samego bufora aplikacji, do tego resampling i HAL. Typowo 60–120 ms dotyk→dźwięk [szacunek]. Propozycja przejścia na Oboe (2021) nie została scalona |
| iOS | CoreAudio RemoteIO; częstotliwość = `AVAudioSession.sampleRate` | `output_latency` liczone, ale na iOS **nie ustawia** rozmiaru bufora (właściwość tylko na macOS); Godot nie woła `setPreferredIOBufferDuration` | Domyślny bufor sesji ~5–23 ms [do sprawdzenia]. Nasz mostek może ustawić `preferredIOBufferDuration = 0.005` i kategorię `Ambient` |

**Plan:** krytyczne krótkie dźwięki (`set`, `false_set`, `contact`, `drop`, `break`, `gate_align`) idą przez **ClickAudioBridge**:
- Android: Oboe (C++, AAudio z trybem `PerformanceMode::LowLatency`, `SharingMode::Exclusive`, natywna częstotliwość urządzenia, sample wstępnie zdekodowane do PCM float);
- iOS: AVAudioEngine z buforami PCM albo `CHHapticAudioResource` w tym samym wzorcu co transient, co daje synchronizację dźwięk–haptyka z dokładnością do próbki.

Tło, ambient i muzyka zostają w `AudioServer` Godota. Alternatywa (gorsza, bo własny fork silnika): łatka OpenSL (48 kHz, 256 ramek, `SL_ANDROID_PERFORMANCE_LATENCY`, bez reverbu w miksie).

### 1.7 Determinizm i testy logiki

- **Wymaganie:** stały krok logiki (proponowane 120 Hz), seed, wejście jako strumień próbek (tick, napięcie, głębokość, uniesienie), wynik niezależny od FPS renderu.
- `float` w GDScript to IEEE 754 double. Proste operacje są powtarzalne, ale `sin`/`pow`/`exp` zależą od libm danej platformy, a kompilatory mogą łączyć mnożenie z dodawaniem (FMA na ARM). C#/IL2CPP ma ten sam problem. **Wniosek: logika zamka w liczbach całkowitych / stałym przecinku (Q16.16 lub Q32.32 w int64)**, z tablicami zamiast funkcji przestępnych i własnym PRNG (np. PCG32 albo xoshiro128**).
- **Gdzie trzymać logikę:**

| Opcja | Determinizm | Testy w CI Linux | Mobile | Ocena |
|---|---|---|---|---|
| **C++20 „lockcore” (bez Godota) + nakładka GDExtension (godot-cpp)** | pełny (int) | natywnie: doctest/Catch2, sanitizery, libFuzzer, odtwarzanie replayów; bez silnika | godot-cpp stabilne na iOS (xcframework) i Androidzie (AAR/.so) | **rekomendowane**; rdzeń przenośny także do Unity/natywnego |
| Czysty GDScript (int) | pełny, jeśli bez float | Godot headless + GUT | bez kompilacji natywnej | dobry na prototyp tygodniowy, gorszy na fuzzing, wydajność i przenośność |
| C# (Godot .NET) | jw. przy fixed-point | dotnet test | Android i iOS (NativeAOT) wciąż oznaczone jako **eksperymentalne** | odrzucone dla Godota |
| Rust + gdext | pełny | cargo test | README gdext: „mało wsparcia dla Androida/iOS” | odrzucone na teraz |

Rdzeń wystawia czyste API: `step(input) -> Vec<Event>` i `state_hash()`. Godot tylko renderuje i przekazuje zdarzenia do FeedbackDirector (sekcja 3).

### 1.8 Porównanie

| Kryterium | **Godot 4.7** | Unity 6.3 LTS | Natywnie (Swift+Kotlin) | Defold |
|---|---|---|---|---|
| Licencja / koszt | MIT, 0 | 0 do 200 tys. $, potem 2310 $/os./rok | 0 | 0 (Defold License) |
| Haptyka iOS | własny mostek (GDExtension ObjC++) | własny plugin albo płatny Feel | **natywna, pełna** | rozszerzenie natywne (własne) |
| Haptyka Android | własny mostek (AAR) + referencja MIT | własny plugin / Feel | **natywna, pełna** | rozszerzenie natywne |
| Audio low-latency | **iOS ok; Android: OpenSL 2×1024 → potrzebny Oboe-plugin** | wbudowany DSP (FMOD), ustawienie „Best latency” [do sprawdzenia na Androidzie] | Oboe / AVAudioEngine bezpośrednio | silnik własny (OpenAL/OpenSL) [do sprawdzenia] |
| 2,5D oświetlone na tanim Androidzie | dobre (Compatibility/Mobile) | bardzo dobre (URP 2D Lights) | dużo pracy (Metal + Vulkan/GLES) | dobre 2D, oświetlenie ręcznie (shadery) |
| Rozmiar buildu | średni | średni/duży | mały | **najmniejszy** |
| Determinizm / CI Linux | lockcore C++ natywnie; Godot headless export na Linuksie | lockcore jw.; licencja Unity w CI (aktywacja) | lockcore jw. | lockcore jw. (C++ ext) |
| Jeden kod UI/sceny | tak | tak | **nie (×2)** | tak |
| Ryzyko vendor lock-in | niskie (MIT, źródło) | średnie (historia zmian cennika) | brak | niskie |
| Główne ryzyko | audio Android, GDExtension iOS | koszt, zależność od Unity | 2× praca, 2× błędy | mniejsza społeczność, Lua |

### 1.9 Rekomendacja i warunki zmiany

**Godot 4.7.x**, wersja przypięta w repo (`.godot-version`). Migracja na 4.8 nastąpi dopiero po wydaniu łatki 4.8.1 i ponownym przejściu spike'ów 1–5. Uzasadnienie: koszt 0 i MIT, jeden kod sceny i UI, Linux-owy export Androida w kontenerze, wystarczający renderer 2D z normal mapami. Najważniejsze elementy (haptyka i dźwięk kliknięć) i tak piszemy natywnie, więc silnik ich nie ogranicza. Rdzeń logiki w C++ jest niezależny od silnika, więc zmiana decyzji później kosztuje „tylko” warstwę prezentacji.

**Decyzję zmieniamy, jeśli:**
1. Spike 1 lub 2: opóźnienie od zdarzenia logiki do wywołania API haptyki w Godocie jest o > 8 ms (p95) gorsze niż w natywnej aplikacji kontrolnej na tym samym urządzeniu i nie da się tego naprawić (np. przez `agile_event_flushing`, wątek mostka). Wtedy przechodzimy na **natywnie Swift+Kotlin z lockcore**.
2. Spike 3: ścieżka Oboe w AAR nie osiąga progów albo destabilizuje Godot AudioServer, wtedy rozważamy natywny Android lub Unity (po pomiarze).
3. Eksport GDExtension na iOS w 4.7 jest niestabilny i ścieżka .gdip też zawodzi.
4. Spike 4: żaden renderer Godota nie utrzymuje 60 FPS na tanim urządzeniu przy minimalnej wersji sceny. Wtedy porównujemy Unity URP 2D i Defold na tym samym zestawie.
5. Do zespołu dołączają ludzie z dużym doświadczeniem w Unity, a budżet zakłada licencje Pro. Wtedy Unity 6.3 LTS.

---

## 2. Warstwy haptyki z fallbackami

### 2.1 iOS

| Poziom | Warunek | Co gra |
|---|---|---|
| **H3 Core Haptics** | `CHHapticEngine.capabilitiesForHardware().supportsHaptics == true` (iPhone 8+) | ciągły opór (`CHHapticAdvancedPatternPlayer` w pętli + `sendParameters` dynamicznych `hapticIntensityControl`/`hapticSharpnessControl` co klatkę, maks. 60 Hz), transienty w **osobnym** playerze |
| H1 UIFeedbackGenerator | brak Core Haptics, ale jest Taptic (rzadkie) | `UIImpactFeedbackGenerator(style:).impactOccurred(intensity:)` tylko dla zdarzeń kluczowych; bez ciągłego oporu |
| **H0 brak** | iPad (brak Core Haptics), wyłączone w ustawieniach systemu/gry | wyłącznie dźwięk + obraz; tryb „w ciemności” = tylko dźwięk |

Uwagi:
- Aktywna krzywa intensywności (`CHHapticParameterCurve`) i parametr dynamiczny przeskalowują też transienty w **tym samym** playerze. Dlatego opór (`tension_resistance`, `pick_drag`) i kliknięcia trzymamy w oddzielnych playerach, a ducking robimy tylko na playerze oporu.
- Obsługujemy `stoppedHandler` / `resetHandler` (wyjście do tła, przerwanie audio): odtwarzamy engine i playery, ponownie wysyłamy bieżące parametry. Ustawiamy `playsHapticsOnly = false` tylko wtedy, gdy przez CH gra też dźwięk kliknięć.
- Sesję audio ustawiamy na `.ambient` (respektuje przełącznik wyciszenia; zgodnie z oczekiwaniem gracza w grze premium można dać opcję „graj dźwięk mimo wyciszenia” → `.playback`).

### 2.2 Android

| Poziom | Warunek wykrycia | Co gra |
|---|---|---|
| **A4 Builder** | `SDK_INT_FULL ≥ 37.2` (API `VibrationEffect.Builder` dostępne) | presety + `BasicEnvelopeBuilder` z automatycznym fallbackiem frameworka; `WaveformEnvelopeBuilder` tylko jeśli `areEnvelopeEffectsSupported()` i częstotliwości w `VibratorFrequencyProfile` |
| **A3 Envelope (PWLE)** | API 36 + `vibrator.areEnvelopeEffectsSupported()` | ciągły opór jako łańcuch krótkich obwiedni `BasicEnvelopeBuilder` (intensity/sharpness 0–1) wysyłanych co 50–80 ms; transienty jako kompozycja prymitywów |
| **A2 Composition** | API ≥ 30 + `areAllPrimitivesSupported(CLICK, TICK)`; opcjonalnie `LOW_TICK`, `THUD`, `QUICK_RISE`, `SLOW_RISE`, `QUICK_FALL` (API 31: `LOW_TICK`, `THUD`, `SPIN`) | transienty z prymitywów. **Każdą kompozycję budujemy tylko z prymitywów zgłoszonych jako wspierane**, bo jeden nieobsługiwany blokuje całość. Opór: waveform z amplitudą (A1) |
| **A1 Waveform z amplitudą** | `vibrator.hasAmplitudeControl()` | `createWaveform(timings, amplitudes, repeat)`. Opór jako powtarzany segment 40 ms z amplitudą aktualizowaną co 80–120 ms (każde `vibrate()` przerywa poprzednie, więc rzadziej). Transienty: `createOneShot(12–20 ms, amp)` lub `EFFECT_CLICK`/`EFFECT_TICK` (`areAllEffectsSupported`) |
| **A0 on/off** | brak kontroli amplitudy (tanie ERM, opóźnienie 50–100 ms) | tylko zdarzenia kluczowe (`set`, `false_set`, `drop`, `break`, `open`, `detector_trip`), impulsy 25–40 ms, odstęp ≥ 150 ms; **bez ciągłego oporu** |
| **A– brak** | `!vibrator.hasVibrator()`, tablety, wyłączone | dźwięk + obraz |

Źródło wibratora: `VibratorManager.getDefaultVibrator()` (API 31+), na API 30 `Context.VIBRATOR_SERVICE`. Atrybuty: `VibrationAttributes.USAGE_MEDIA` lub `USAGE_TOUCH`, do sprawdzenia w spike'u, bo `USAGE_TOUCH` respektuje systemowy suwak „haptyka dotyku”, który wielu graczy ma wyłączony.

### 2.3 Wykrywanie i kalibracja przy pierwszym uruchomieniu

```text
detect():
  iOS:     supportsHaptics ? H3 : (hasTaptic ? H1 : H0)
  Android: if !hasVibrator -> A–
           if builderAvailable -> A4
           elif api>=36 && areEnvelopeEffectsSupported -> A3
           elif api>=30 && areAllPrimitivesSupported(CLICK,TICK) -> A2
           elif hasAmplitudeControl -> A1
           else -> A0
  zapisz profil: {tier, primitives{}, primitiveDurations, envelope{maxSize,minCtrlMs,maxMs}, model, osVersion}
```

**Kalibracja (≈ 40 s, pomijalna, powtarzalna w Ustawieniach → Haptyka):**
1. **„Czujesz dwa kliknięcia?”**: dwa transienty `set` w odstępie 120 ms; odpowiedzi „jedno / dwa / nic”.
   - „dwa”: tier bez zmian, `minTransientGapMs` = 40 (iOS) / 60 (Android);
   - „jedno”: rozmyte ERM, tier w dół o jeden, `minTransientGapMs = 150`, powtórka z odstępem 200 ms;
   - „nic”: tier A0, a jeśli i to nie, haptyka wyłączona z komunikatem (dźwięk i obraz zostają).
2. **Próg odczuwalności oporu** (tylko H3/A3/A2): rampa intensywności 0→1 przez 4 s, gracz dotyka w momencie, gdy poczuje. Wynik → `continuousFloor` (minimalna intensywność „essential”).
3. **Rozróżnianie set / false_set** (opcjonalnie, w tutorialu): 6 losowych prób, gracz wskazuje. Wynik < 4/6 nie blokuje gry. Wtedy podpowiedź wizualna kontrrotacji w tutorialu trwa dłużej.

Profil zapisujemy lokalnie i kluczujemy modelem urządzenia + wersją OS, a po aktualizacji OS proponujemy powtórkę. Do telemetrii (jeśli będzie zgoda) idą: tier, wynik testu 1, model. Brak publicznych statystyk obsługi prymitywów na Androidzie to luka, którą częściowo wypełnimy w ten sposób.

### 2.4 Jak mierzyć opóźnienie (szczegóły w spike'ach 1–3)

- **Wewnętrznie:** znaczniki czasu monotonicznego: `UITouch.timestamp` / `MotionEvent.getEventTimeNanos()` → tick logiki → wywołanie API mostka → (iOS) callback zakończenia playera. Mierzy to tylko część programową.
- **Zewnętrznie (prawda):** piezo kontaktowe (mikrofon kontaktowy, ~5–15 €) przyklejone do tylnej ścianki telefonu + mikrofon pomiarowy przy głośniku → 2-kanałowy interfejs audio 48 kHz → analiza w Audacity lub skrypcie. Uderzenie palca lub rysika w ekran daje szerokopasmowy impuls w kanale piezo, haptyka daje burst ~150–230 Hz w tym samym kanale, dźwięk widać w kanale mikrofonu. Rozdzielczość < 0,1 ms. Do opóźnienia obrazu służy kamera 240 fps (4,17 ms/klatkę) filmująca palec i ekran z polem, które zmienia kolor na zdarzenie.
- **Pomocniczo (automat):** akcelerometr samego telefonu (200–500 Hz próbkowania) wykrywa początek własnej wibracji względem `touchDown`. Rozdzielczość 2–5 ms wystarcza do testów regresji na farmie urządzeń.

### 2.5 Szkic interfejsu `HapticsBridge` (wspólny dla iOS/Android)

Klasa GDExtension (C++) wystawiona do GDScript. Na iOS deleguje do ObjC++ (Core Haptics), na Androidzie przez JNI do Kotlin (`VibratorManager`). Sygnatury:

```cpp
// lockwright/native/haptics_bridge.h  (szkic, nie implementacja)
enum class HapticTier : uint8_t { None, OnOff, Amplitude, Primitives, Envelope, Builder, CoreHaptics, UIKitGenerator };
enum class HapticChannel : uint8_t { Tension = 0, PickDrag = 1 };   // kanały ciągłe

struct HapticCaps {
  HapticTier tier;
  bool has_amplitude_control;
  uint32_t supported_primitives_mask;      // bit per Android primitive / iOS: all
  std::array<int16_t, 16> primitive_duration_ms;
  bool envelopes; int16_t envelope_max_points; int16_t envelope_min_ctrl_ms; int32_t envelope_max_ms;
  float estimated_latency_ms;              // z kalibracji / tabeli urządzeń
};

struct HapticEventSpec {                   // z banku wzorców (sekcja 3), już po rozwiązaniu materiału
  StringName id; float intensity; float sharpness; int16_t duration_ms;
  uint8_t priority; bool essential;        // essential => nie spada poniżej continuousFloor
};

class HapticsBridge : public godot::Object {
public:
  HapticCaps get_caps() const;
  godot::Error prepare(const godot::Ref<HapticBank>& bank);   // prebuild CHHapticPattern / VibrationEffect
  void play_event(const HapticEventSpec& e, int64_t logic_tick);          // transient lub krótki wzorzec
  void continuous_start(HapticChannel ch, float intensity, float sharpness);
  void continuous_update(HapticChannel ch, float intensity, float sharpness); // ≤ 60 Hz, koalescencja
  void continuous_stop(HapticChannel ch, int16_t release_ms);
  void duck(HapticChannel ch, float factor, int16_t hold_ms, int16_t release_ms);
  void set_master(bool enabled, float scale);                 // suwak 0..1 (XAG 110)
  void stop_all();
  godot::Dictionary get_latency_stats() const;                // p50/p95 call→ack
  // sygnały: engine_reset(), engine_stopped(reason:int), tier_changed(tier:int)
};

class ClickAudioBridge : public godot::Object {               // niskie opóźnienie: Oboe / AVAudioEngine
public:
  godot::Error preload(StringName id, const godot::PackedFloat32Array& pcm, int sample_rate);
  void play(StringName id, float gain_db, float pitch, float pan, int64_t logic_tick);
  float get_output_latency_ms() const;                        // AAudio getTimestamp / AVAudioSession.outputLatency
};
```

---

## 3. Język haptyki i dźwięku

### 3.1 Architektura sygnału

```text
lockcore (120 Hz) ─► Event{type, element, magnitude, tick} ─► FeedbackDirector ─┬─► HapticsBridge
                     ciągłe: tension_resistance, pick_drag (0..1)                ├─► ClickAudioBridge (krytyczne SFX)
                                                                                 ├─► AudioServer (tło, ciągłe tekstury)
                                                                                 └─► Render (kształt/ruch)
```
FeedbackDirector stosuje priorytety, limity transientów, ducking, skalowanie suwakiem i mapowanie materiału. Kosmetyczne losowanie (warianty sampli, ±pitch) używa **osobnego** PRNG, nigdy PRNG logiki.

### 3.2 Modyfikatory materiału

| Materiał | Haptyka: Δsharpness / ×intensity | Dźwięk: charakter |
|---|---|---|
| Mosiądz (baza) | 0 / ×1,0 | ciepły, jasny środek, rezonans ~2–4 kHz, wybrzmienie ~60–90 ms |
| Stal | +0,10 / ×1,05 | twardy, wysoki 5–8 kHz, krótki „dzwon” 40–60 ms, wyraźny atak |
| Żelazo (kute/żeliwo) | −0,10 / ×1,10 | matowy, ziarnisty, niższy 1–2 kHz, krótki 30–50 ms, szum tarcia |
| Drewno (obudowa/rygiel) | −0,25 / ×0,9 | głuchy „tok” 300–800 Hz, 20–35 ms, bez dzwonienia |

Wartości w tabeli 3.3 dotyczą mosiądzu, a pozostałe materiały wynikają z modyfikatorów (clamp 0..1).

### 3.3 Tabela zdarzeń

Skróty: T = transient, C = continuous (iOS); I = intensity, S = sharpness. Android: prymityw (skala 0–1) → fallback A1 (oneShot ms/amplituda 0–255) → A0. Warstwy audio: **L1** mechanika ciągła, **L2** zdarzenia (ClickAudioBridge), **L3** otoczenie, **L4** UI. Priorytet: 1 = najwyższy.

| Zdarzenie | iOS Core Haptics | Android A2–A4 | Fallback A1 / A0 | Dźwięk | Prio |
|---|---|---|---|---|---|
| `tension_resistance` (ciągły) | C, I 0,10–0,55 (mapowane z oporu), S 0,20–0,35; player w pętli, `sendParameters` ≤ 60 Hz | A3/A4: obwiednie po 60 ms; A2: jak A1 | A1: segment 40 ms w pętli, amp 30–140, aktualizacja co 100 ms / A0: brak | L1: niski szum tarcia rdzenia, głośność ∝ opór, -24…-14 dBFS | 14 |
| `pick_drag` (ciągły) | C (drugi player), I 0,05–0,25 ∝ prędkość, S 0,55–0,75; + mikro-T przy krawędziach (I 0,15, S 0,7) z limitem 20/s | mikro-`TICK` 0,15 z limitem 12/s | A1: brak ciągłego, `EFFECT_TICK` ≤ 6/s / A0: brak | L1: drapanie, tekstura zależna od materiału, pitch ∝ prędkość | 13 |
| `contact` | T I 0,30 S 0,70 | `TICK` 0,35 | 10 ms/70 / – | L2: cichy „tik” 10–15 ms | 12 |
| `bind` | T I 0,45 S 0,35 + C rośnie o +0,2 w 80 ms | `LOW_TICK` 0,5 (fallback `TICK` 0,4) + obwiednia | 15 ms/110 / – | L2: krótkie „zacięcie” 20 ms, L1 opór rośnie | 10 |
| `near_shear` | C: S +0,15 przez 150 ms, potem powoli powrót; brak T | obwiednia S +0,15 (A3+); A2: `QUICK_RISE` 0,2 | A1: amp oporu +20% / – | L1: subtelne pojaśnienie tarcia (filtr HP rośnie), bez kliknięcia | 11 |
| **`set`** | T I 0,90 S 0,85 (≈ 0 ms) + **C oporu: dip ×0,5 przez 110 ms** („luz” rdzenia ~2°) | `CLICK` 0,9 | 18 ms/255 / 30 ms on | L2: ostre kliknięcie 15–25 ms + krótki „ślizg” rdzenia 60 ms | 5 |
| **`false_set`** | T I 0,85 S 0,75 + **T2 +28 ms I 0,25 S 0,30** (cichy „podwójny”) + C dip ×0,35 przez 260 ms (głębszy luz ~6°) | `CLICK` 0,85 + `LOW_TICK` 0,25 po 28 ms (lub `TICK` 0,2) | 18 ms/240 + 10 ms/70 po 40 ms / 30 ms on | L2: kliknięcie jak set (ta sama rodzina), ale z niskim „bodym” (−4 półtony, +20 ms ogon) | 5 |
| `counter_rotate` | C I 0,35→0,15, S 0,15 + T co 110 ms I 0,30 S 0,20 („zgrzyt zapadki”) dopóki trwa | `LOW_TICK` 0,35 co 120 ms (lub `TICK`) | 15 ms/100 co 150 ms / 25 ms co 250 ms | L1+L2: niski skrzyp cofającego się rdzenia, rytm = T | 6 |
| `overset` | T I 0,60 S 0,10 („głuchy”) + C S → 0,05 („martwy” opór, bez modulacji) | `THUD` 0,6 (fallback `CLICK` 0,4) | 25 ms/160 / 30 ms on | L2: głuchy stuk 30–40 ms, bez dzwonienia; L1: tarcie cichnie | 7 |
| `drop` | 3–6 T co 40 ms, I 0,7→0,4, S 0,6; C oporu → 0 przez 200 ms | sekwencja `TICK` 0,7→0,4 co 50 ms | 12 ms/200 ×3, odstęp 70 ms / 1× 60 ms | L2: grzechot pinów i sprężyn 150–300 ms | 3 |
| `stress` | C (kanał oporu) I +0,1…+0,35, S 0,85, modulacja T co 70 ms I 0,2 S 0,9 | `TICK` 0,3 co 80 ms + obwiednia | 10 ms/90 co 120 ms / – | L1: rosnące „śpiewanie” metalu wytrycha, pitch ∝ naprężenie | 8 |
| `break` | T I 1,00 S 1,00 + C → 0 natychmiast | `CLICK` 1,0 + `QUICK_FALL` 0,6 | 40 ms/255 / 60 ms on | L2: suchy trzask 40 ms + odbicie odłamka 120 ms | 1 |
| `wear` | brak w trakcie gry (meta) | – | – | L4: cichy szlif po zakończeniu próby; UI | 15 |
| `gate_align` | T I 0,50 S 0,50 + C dip ×0,7 przez 60 ms | `CLICK` 0,5 (lub `TICK` 0,6) | 15 ms/140 / 25 ms on | L2: miękki „tok” dźwigni/tarczy 20 ms | 9 |
| `detector_trip` | wzór rytmiczny: C 80 ms I 0,7 S 0,3, przerwa 60 ms, C 80 ms | `THUD` 0,7, 140 ms, `THUD` 0,7 | 60 ms/220, 80 ms off, 60 ms/220 / to samo on/off | L2: podwójne „klak-klak” zatrzasku | 2 |
| `open` | C 300 ms I 0,3→0 (obrót) + T I 1,0 S 0,6 (rygiel) | `SLOW_RISE` 0,3 + `CLICK` 1,0 | 30 ms/255 / 50 ms on | L2: obrót + zasuwanie rygla (warstwy materiału), 400–700 ms | 1 |

### 3.4 Set vs false_set — uczciwa rozróżnialność

- Na pierwszy kontakt false_set **ma mylić**: to ta sama rodzina kliknięcia i podobna siła. Obraz pokazuje obrót rdzenia, który jest tylko trochę większy.
- **Rozpoznanie zawsze jest możliwe**, różnicę niosą trzy kanały:
  1. **luz**: po false_set opór spada głębiej i na dłużej (260 vs 110 ms), a rdzeń obraca się o ok. 6° zamiast 2°;
  2. **podpis**: drugi, cichy, niski impuls po 28 ms, w haptyce i w dźwięku (niski „body”). Uczy się go w tutorialu, a ekspert rozpozna go od razu;
  3. **potwierdzenie**: po naciśnięciu fałszywie ustawionego elementu pojawia się `counter_rotate` z rytmem zapadki (haptyka, dźwięk i animacja cofającego się rdzenia). Nie da się go pomylić z niczym innym.
- Kryterium testów z graczami: po tutorialu ≥ 80% graczy rozpoznaje false_set przed upływem 3 s (po kontrrotacji), a ≥ 40% od razu z podpisu, w każdym z trybów: pełny, tylko dźwięk (iPad), tylko haptyka + dźwięk („w ciemności”).
- **Tylko dźwięk musi wystarczyć** (iPad, A–). Podpis false_set jest więc zawsze obecny w audio, a nie tylko w haptyce (XAG 103/110: haptyka nigdy jedynym kanałem).

### 3.5 Zasady miksu

- **Limit transientów**: globalnie ≤ 25/s na iOS, ≤ 12/s na A2–A4, ≤ 6/s na A1, ≤ 3/s na A0. Minimalny odstęp `minTransientGapMs` pochodzi z kalibracji (40 / 60 / 150 ms). Nadmiar odrzucamy wg priorytetu, a zdarzenia o tym samym priorytecie w oknie 30 ms łączymy w jedno o max(I).
- **Kolizje**: wyższy priorytet wygrywa. Niższy transient w oknie `minGap` jest odrzucany (nie kolejkowany, bo spóźniona haptyka kłamie). Priorytety 1–3 przerywają wszystko, łącznie z wzorcami w toku.
- **Ducking**: na każdy transient prio ≤ 10 kanał oporu dostaje ×0,3 przez 35 ms, potem rampę powrotu 60 ms. Na Androidzie A1/A3 zamiast tego pomijamy jedną aktualizację segmentu. Ducking audio L1 wynosi −6 dB / 50 ms.
- **Suwak intensywności (0–100%) i wyłącznik** (XAG 110): `I' = I · s`. Dla zdarzeń `essential` (set, false_set, drop, break, open, detector_trip, counter_rotate) obowiązuje `I' = max(I·s, continuousFloor)`, o ile s > 0. Sharpness nie jest skalowana. Na iOS ciągłe kanały skalujemy przez `hapticIntensityControl`, a transienty przy tworzeniu zdarzenia. Osobny suwak „opór ciągły” pozwala wyłączyć sam szum bez utraty kliknięć (zgłaszane jako męczące).
- **Synchronizacja**: dźwięk i haptyka tego samego zdarzenia mają |Δ| ≤ 15 ms. Na iOS dźwięk L2 może grać przez `CHHapticAudioResource` w tym samym wzorcu. Na Androidzie kompensujemy znane opóźnienie wibratora z profilu, opóźniając audio, nigdy haptykę.
- **Dźwięk**: sample L2 w PCM 48 kHz (nie OGG strumieniowo), wstępnie zdekodowane, 4–6 wariantów na zdarzenie i materiał, ±3% pitch, ±1,5 dB.

---

## 4. Plan spike'ów (kryteria przeszło / nie przeszło)

Wspólne: build release, jasność 50%, tryb samolotowy, naładowane > 50%, 3 serie × 50 prób, raport p50/p95. Każdy spike ma natywną aplikację kontrolną (Swift/Kotlin, minimalną), żeby oddzielić koszt Godota od kosztu platformy.

### Spike 1 — ciągły opór + opóźnienie haptyki, iPhone (≈ 4 dni)
- Scena: lewy kciuk = napięcie, opór ciągły zależny od napięcia, kliknięcie `set` przy przekroczeniu progu, plus test „tap → transient”.
- Metoda: piezo na obudowie + mikrofon → interfejs 48 kHz (sekcja 2.4); kamera 240 fps do obrazu; znaczniki wewnętrzne.
- **Przeszło:** dotyk→transient p95 ≤ 25 ms (iPhone 12+), ≤ 30 ms (SE 3); zmiana napięcia→zmiana intensywności C p95 ≤ 40 ms; różnica Godot vs natywna kontrola ≤ 8 ms p95; 10 min ciągłej gry bez zerwania engine (reset obsłużony < 200 ms); CPU wątku haptyki < 3%; GDExtension xcframework przechodzi eksport i walidację App Store Connect (TestFlight).
- **Nie przeszło:** p95 > 35 ms lub różnica vs natywna > 12 ms, albo słyszalne/odczuwalne „schodki” przy aktualizacji 60 Hz (≥ 3/5 testerów).

### Spike 2 — ten sam efekt na Androidzie (≈ 5 dni)
- Urządzenia: Pixel (A3/A4), Samsung Galaxy A (A2/A3?), tani z ERM (A0/A1).
- Metoda jw. + logowanie tieru i `getPrimitiveDurations`. Test ciągłości: obwiednie 60 ms kontra waveform 40 ms.
- **Przeszło:** dotyk→transient p95: Pixel ≤ 35 ms, Samsung A ≤ 50 ms, tani ≤ 100 ms; ciągły opór na A3+ bez przerw > 15 ms (pomiar piezo) i oceniony „ciągły” przez ≥ 4/5 testerów; test „dwa kliknięcia” poprawnie rozpoznany przez ≥ 80% testerów na każdym urządzeniu po kalibracji; żadna kompozycja nie zawodzi po cichu (log `false` z `arePrimitivesSupported` → fallback).
- **Nie przeszło:** Pixel > 45 ms p95, ciągły opór „rwany” na Pixelu, albo na Samsungu A brak jakiegokolwiek rozróżnienia set/false_set w samej haptyce (wtedy zostają tylko audio + obraz, co jest dopuszczalne, ale trzeba to zapisać jako ograniczenie).

### Spike 3 — dźwięk kliknięcia < 30 ms (≈ 4 dni)
- Warianty: (a) Godot AudioServer (baza), (b) ClickAudioBridge: Oboe/AAudio (Android) i AVAudioEngine / `CHHapticAudioResource` (iOS).
- Metoda: mikrofon przy głośniku + piezo (impuls dotyku) → interfejs 48 kHz. Opóźnienie liczymy od impulsu piezo do początku sampla (próg −30 dBFS). Sample ma ostry atak (impuls 1 ms) i przy pomiarze kanał audio jest bez wyciszenia. Dodatkowo „Larsen test”, z którego wyliczamy samo opóźnienie wyjścia.
- Fakt fizyczny: na Androidzie samo przetwarzanie dotyku to typowo 15–35 ms [szacunek], więc **< 30 ms dotyk→dźwięk jest realne tylko na iOS i Pixelu**. W grze kliknięcie wynika z ruchu ciągłego, więc gracz bardziej czuje synchronizację kanałów niż absolutne opóźnienie.
- **Przeszło:** iPhone p95 ≤ 30 ms; Pixel ≤ 35 ms; Samsung A ≤ 50 ms; tani ≤ 80 ms; |audio − haptyka| ≤ 15 ms na wszystkich; wariant (b) poprawia Androida o ≥ 30 ms względem (a); brak trzasków/underrunów w 10 min (licznik `getXRunCount` = 0 po rozgrzaniu).
- **Nie przeszło:** iPhone > 35 ms, Pixel > 45 ms, albo Oboe w AAR koliduje z OpenSL Godota (dwa strumienie → błędy fokusu/trzaski). Wtedy rozważamy łatkę sterownika Godota (fork) lub warunek zmiany silnika nr 2.

### Spike 4 — oświetlony metal 2,5D przy 60 FPS na tanim Androidzie (≈ 5 dni)
- Scena: przekrój zamka 5 pinów + sprężyny + rdzeń, normal mapy 1024², 3 światła punktowe, mapa połysku, cząstki opiłków (≤ 200), UI. Bez bloomu. 1080p natywnie i 0,85 skali.
- Warianty: Compatibility vs Mobile; 2D canvas vs 3D ortho.
- **Przeszło (tani Android, Mali-G52/G57 lub PowerVR):** 10 min, czas klatki p95 ≤ 16,7 ms, 1% low ≥ 55 FPS, po 10 min bez spadku < 55 FPS (throttling), RAM ≤ 450 MB, pobór baterii ≤ 15%/h, start do menu ≤ 4 s, AAB ≤ 60 MB z zasobami spike'a; iPhone SE 3 i iPad 60 FPS stale, ProMotion 120 FPS p95 ≤ 8,3 ms na najnowszym iPhonie (opcjonalnie).
- **Nie przeszło:** p95 > 20 ms w obu rendererach w wariancie minimalnym (2 światła, normal mapy 512²).

### Spike 5 — determinizm (≈ 3 dni, równolegle)
- lockcore C++ (fixed-point, PCG32), 3 zamki prototypowe, rejestrator wejścia (tick, napięcie u16, głębokość u16, uniesienie u16).
- Korpus: 10 000 replayów (generowanych fuzzerem + 50 nagranych ręcznie), skrót stanu (xxHash64) co 60 ticków i na końcu.
- **Przeszło:** 100% zgodności skrótów między Linux x86_64 (GCC i Clang), Android arm64 (urządzenie) i x86_64 (emulator), iOS arm64 (urządzenie); wynik niezależny od FPS renderu (30/60/120 Hz ten sam skrót); `step()` ≤ 0,2 ms p99 na tanim Androidzie; flagi `-ffp-contract=off` / brak `float` w rdzeniu sprawdzane w CI (grep + test).
- **Nie przeszło:** jakakolwiek rozbieżność, bo determinizm wymaga zera rozbieżności.

---

## 5. Budowanie i CI

### 5.1 Android w kontenerze Linux (GitHub Actions `ubuntu-24.04` lub własny obraz)

| Składnik | Wersja (przypięta) |
|---|---|
| Godot | 4.7.2-stable, editor `linux.x86_64` + export templates 4.7.2 (`--headless`) |
| JDK | Temurin 17 (wymóg szablonu 4.7: `JavaVersion.VERSION_17`) |
| Android SDK | cmdline-tools (latest), `platforms;android-36`, `build-tools;36.1.0`, `platform-tools` |
| NDK | 29.0.14206865 (kompilacja lockcore/Oboe/godot-cpp) |
| Gradle / AGP | wrapper 8.11.1 / AGP 8.6.1 (z szablonu Godota 4.7.2; nie podbijać osobno) |
| CMake / SCons | CMake 3.30+ (lockcore), SCons 4.x (godot-cpp) |

Kroki: `godot --headless --import` → build GDExtension (`scons platform=android arch=arm64 target=template_release`) → build AAR pluginów (Gradle) → `godot --headless --export-release "Android" build/lockwright.aab`. Keystore uploadu w sekretach (base64) z `export_presets.cfg` czytanym ze zmiennych środowiskowych (`GODOT_ANDROID_KEYSTORE_RELEASE_*`). Cache: `~/.gradle`, `.godot/imported`.

### 5.2 Testy logiki na Linuksie
- lockcore: CMake + doctest, ASan/UBSan, libFuzzer (nocą 30 min), golden replays (spike 5) przy każdym PR. Czas < 5 min.
- Warstwa Godota: GUT w headless (FeedbackDirector, priorytety, limity transientów z atrapą `HapticsBridge`).
- Lint: `gdlint`, `clang-format`, `clang-tidy`.

### 5.3 iOS na macOS
- **GitHub-hosted:** obraz `macos-26` (arm64). W VII 2026 domyślny Xcode to 26.6, a Xcode 27 był w obrazie jako preview. `macos-latest` przeszedł na `macos-26` w VI 2026 [stan na XI do sprawdzenia w runner-images]. Przypinamy Xcode przez `xcode-select` / `maxim-lobanov/setup-xcode`.
- **Wymóg Apple:** od **28.04.2026** wysyłki do App Store Connect muszą być zbudowane **Xcode 26+ z SDK iOS 26** [zweryfikowane]. Od 9.09.2026 obowiązuje minimum target iOS 13 (nas nie ogranicza). Wymogu Xcode 27 jeszcze nie ogłoszono. Historycznie przychodzi w kwietniu następnego roku, więc należy się go spodziewać ok. IV 2027.
- **Oszczędzanie minut macOS:** eksport projektu Xcode przez Godota („Export Project Only”) na Linuksie, a na macOS tylko `xcodebuild archive` + upload [możliwość eksportu z Linuksa do sprawdzenia w spike'u CI].
- **Koszty:**

| Opcja | Koszt | Uwagi |
|---|---|---|
| GitHub Actions macOS | 0,062 $/min (od 1.01.2026; Linux 0,006 $/min) [ceny ze źródeł wtórnych] | build iOS ~20 min ≈ 1,25 $; 100 buildów/mies. ≈ 125 $ |
| Codemagic | M2 0,095 $/min, M4 0,114 $/min; 500 darmowych min M2/mies. na koncie osobistym; plan roczny z nielimitowanymi minutami | wygodne podpisywanie, TestFlight out-of-the-box |
| Bitrise | plany kredytowe [cennik do sprawdzenia] | dojrzałe kroki iOS |
| Własny Mac mini (M4, ~700–800 €) jako self-hosted runner | jednorazowo + prąd; opłata 0,002 $/min za self-hosted została przez GitHub odłożona | zwrot po ~6–8 mies. przy 100 buildach; daje też urządzenie do debugowania. **Rekomendacja od fazy produkcji**; w fazie spike'ów GitHub-hosted |

### 5.4 Podpisywanie i dystrybucja testowa
- **iOS:** klucz **App Store Connect API (.p8)** w sekretach. Dla małego zespołu wystarczy automatyczne podpisywanie (`xcodebuild -allowProvisioningUpdates` z kluczem API). Przy > 2 maszynach budujących lepszy jest **fastlane match** (certyfikaty w zaszyfrowanym repo). Upload: `fastlane pilot` / `xcrun altool --upload-app` → **TestFlight** (testerzy wewnętrzni do 100 bez review, zewnętrzni do 10 000 po beta review).
- **Android:** Play App Signing (Google trzyma klucz aplikacji, my klucz uploadu). Upload: `fastlane supply` lub Gradle Play Publisher → ścieżka **Internal testing** (do 100 testerów, bez review). **Uwaga:** nowe konta osobiste deweloperów muszą przed produkcją przejść test zamknięty (12 testerów przez 14 dni) [do potwierdzenia aktualnych liczb], więc konto firmowe zakładamy wcześnie.
- **Play:** od 31.08.2026 nowe aplikacje i aktualizacje muszą mieć targetSdk 36 [zweryfikowane]. Szablon Godota 4.7 już ma 36. Kolejny wymóg (37) można przewidywać na VIII 2027.

---

## 6. Urządzenia testowe i minimalne OS

### 6.1 Minimalne wersje
- **iOS 18.0** (deployment target). Dane Apple z 7.06.2026: 79% kompatybilnych iPhone'ów na iOS 26, 14% na iOS 18, 7% starsze. iOS 18+ to więc ≈ 93% aktywnych. Najstarsze urządzenia na iOS 18 to iPhone XS/XR (A12), wszystkie z Core Haptics. Gra premium ma odbiorców z nowszym sprzętem, a każda starsza wersja to dodatkowa macierz testów. Godot 4.7 pozwala zejść do 15.0, gdyby wydawca chciał zasięgu (koszt: test na iOS 17).
- **Android API 30 (Android 11)**, targetSdk 36. Rozkład wersji z 19.10.2026 (dane Google via heise): 16: 25,4%, 14: 15,3%, 15: 14,7%, 13: 11,8%, **11: 10,5%**, 12: 9,6%, 17: 1%. **Android 11+ ≈ 88%**. API 30 to minimum dla `VibrationEffect.Composition`, więc ucina najgorszy segment ERM i upraszcza macierz fallbacków. Warunek zmiany: jeśli wydawca wymaga zasięgu, schodzimy do API 26 (AAudio, `createWaveform` z amplitudą), tylko z tierami A0/A1.

### 6.2 Lista urządzeń (zakup / farma)

| # | Urządzenie | Klasa / haptyka | Po co |
|---|---|---|---|
| 1 | **iPhone SE (3. gen.)** | A15, Taptic, 4,7" LCD, iOS 26 | najmniejszy ekran (safe-area, cele 44 pt), przycisk Home, wydajność ≥ 60 FPS; próg spike 1 (≤ 30 ms) |
| 2 | **iPhone 12** (lub 11) | A14, Taptic | dolna granica wydajności „typowego” iPhone'a; ciągły opór 60 Hz; termika |
| 3 | iPhone XR/XS na iOS 18 (używany) | A12 | najstarszy wspierany OS (iOS 18): zgodność API, Core Haptics na starym Tapticu |
| 4 | **Najnowszy iPhone Pro** (17 Pro / 18 Pro) | ProMotion 120 Hz, najnowszy Taptic | wzorcowe strojenie haptyki, 120 Hz input/render, referencja opóźnień |
| 5 | **iPad (A16, 11. gen.)** + iPad mini | **brak Core Haptics** | tier H0: gra wyłącznie dźwiękiem i obrazem, tryb „w ciemności” audio-only, układ poziomy |
| 6 | **Google Pixel 10** (lub 9) | dobry LRA, pełne prymitywy, obwiednie | referencja Androida: A3/A4, `VibrationEffect.Builder` (beta Androida 17 QPR), Oboe low-latency |
| 7 | **Samsung Galaxy A37 / A57** (2026, Exynos 1480/1680) | LRA średniej klasy, One UI | najpopularniejsza średnia półka w EU; zgodność prymitywów Samsunga, Vulkan Mali |
| 8 | **Samsung Galaxy A17** (4G/5G) | budżet Samsunga, ~150–200 € | masowy rynek; sprawdzenie, czy ma kontrolę amplitudy |
| 9 | **Tani z ERM ~100–150 €**: Xiaomi Redmi A5 (lub Redmi 15C) **i** Motorola moto g05/g06/g15 | ERM, często bez amplitudy, Mali-G52 / PowerVR, Unisoc/Helio | A0/A1, kalibracja „dwa kliknięcia”, spike 4 (60 FPS), opóźnienie 50–100 ms. **Przed zakupem** sprawdzić w sklepie/recenzji, a po zakupie testerem: `hasAmplitudeControl`, `arePrimitivesSupported` |
| 10 | Urządzenie z Androidem 11 (używane, np. Galaxy A52 / Pixel 4a) | API 30 | dolna granica OS: Composition bez prymitywów API 31 (`LOW_TICK`, `THUD`) |
| 11 | **Tablet Android**: Samsung Galaxy Tab A9+ lub Tab S10 FE | słaby lub brak wibratora | tier A–, układ poziomy, duży ekran, renderer na tanim tablecie |

Do regresji wydajności i opóźnień zalecamy dodać chmurową farmę urządzeń (Firebase Test Lab / AWS Device Farm, test automatyczny z akcelerometrem, sekcja 2.4). Ręczna ocena haptyki odbywa się zawsze na fizycznych urządzeniach z listy.

---

## 7. Otwarte pytania do właściciela
1. Akceptacja rekomendacji Godot 4.7 + lockcore C++ (decyzja właściciela → wpis D-NN w DECISIONS.md).
2. Minimalne OS: iOS 18 / API 30. Czy wydawca/rynek wymaga szerszego zasięgu?
3. Budżet urządzeń (≈ 11 sztuk; część używanych) i Mac mini na CI od fazy produkcji.

---

## Źródła

**Godot**
- Godot 4.7 — informacje o wydaniu: https://godotengine.org/releases/4.7/
- Źródło 4.7.2-stable: konfiguracja Gradle Androida: https://github.com/godotengine/godot/blob/4.7.2-stable/platform/android/java/app/config.gradle
- Sterownik audio Android (OpenSL ES, bufor 1024×2, 44,1 kHz): https://github.com/godotengine/godot/blob/4.7.2-stable/platform/android/audio_driver_opensl.cpp
- Sterownik CoreAudio: https://github.com/godotengine/godot/blob/4.7.2-stable/drivers/coreaudio/audio_driver_coreaudio.mm
- Eksport iOS (minimum deployment target): https://github.com/godotengine/godot/blob/4.7.2-stable/platform/ios/export/export_plugin.h
- Wtyczki iOS (.gdip): https://docs.godotengine.org/en/stable/tutorials/platform/ios/ios_plugin.html
- Wtyczki Android v2 (AAR): https://docs.godotengine.org/en/stable/tutorials/platform/android/android_plugin.html
- Forum: opóźnienie audio na Androidzie (4.6): https://forum.godotengine.org/t/audio-latency-on-android-devices/134704
- Forum: GDExtension na iOS (4.5): https://forum.godotengine.org/t/gd-extension-in-ios/132963
- godot-cpp: https://github.com/godotengine/godot-cpp
- SwiftGodot: https://github.com/migueldeicaza/SwiftGodot
- GodotApplePlugins (MIT): https://github.com/migueldeicaza/GodotApplePlugins
- Android Haptics plugin (MIT): https://github.com/Mobuos/godot-android-haptics
- godot-rust gdext: https://github.com/godot-rust/gdext

**Apple**
- Core Haptics: https://developer.apple.com/documentation/corehaptics
- CHHapticAdvancedPatternPlayer: https://developer.apple.com/documentation/corehaptics/chhapticadvancedpatternplayer
- CHHapticDynamicParameter: https://developer.apple.com/documentation/corehaptics/chhapticdynamicparameter
- UIFeedbackGenerator: https://developer.apple.com/documentation/uikit/uifeedbackgenerator
- AVAudioSession.setPreferredIOBufferDuration: https://developer.apple.com/documentation/avfaudio/avaudiosession/setpreferrediobufferduration(_:)
- Wymagania SDK dla App Store Connect: https://developer.apple.com/news/upcoming-requirements/
- Udział iOS 26 (9to5Mac, VI 2026): https://9to5mac.com/2026/06/10/ios-26-adoption-grows-but-still-lags-slightly-behind-ios-18/
- MacRumors (II 2026): https://www.macrumors.com/2026/02/17/how-popular-is-ios-26

**Android**
- Haptics: niestandardowe efekty (Builder, obwiednie, fallback): https://developer.android.com/develop/ui/views/haptics/custom-haptic-effects
- VibrationEffect.Builder: https://developer.android.com/reference/android/os/VibrationEffect.Builder
- Haptics API: https://developer.android.com/develop/ui/views/haptics/haptics-apis
- Aktuatory (FOAM, ERM/LRA): https://developer.android.com/develop/ui/views/haptics/actuators
- Oboe: https://github.com/google/oboe
- Wymóg target API Google Play: https://developer.android.com/google/play/requirements/target-sdk
- Rozkład wersji Androida (X 2026): https://gadgets.beebom.com/news/google-android-17-adoption-figures-october-2026

**Unity**
- Unity 6 / 6.3 LTS: https://unity.com/releases/unity-6
- Zmiany cennika 2026: https://unity.com/products/pricing-updates
- Odwołanie Runtime Fee: https://unity.com/blog/unity-is-canceling-the-runtime-fee

**CI**
- GitHub runner-images (macos-26): https://github.com/actions/runner-images/releases
- Ceny runnerów GitHub 2026 (źródło wtórne): https://itbrief.news/story/github-cuts-actions-runner-prices-adds-new-usage-fee
- Codemagic — ceny: https://docs.codemagic.io/billing/pricing/
- fastlane match: https://docs.fastlane.tools/actions/match/
- App Store Connect API: https://developer.apple.com/documentation/appstoreconnectapi

**Urządzenia**
- Galaxy A37/A57 (Notebookcheck): https://www.notebookcheck.net/Galaxy-A37-and-Galaxy-A57-Samsung-s-new-affordable-phones-coming-March-25.1256904.0.html
- Najlepsze telefony do 150 € (Kimovil): https://www.kimovil.com/en/best-smartphones-under-150-euros

## 8. Wyniki pomiarów na telefonach właściciela (D-33)

<!-- MEASURE:BEGIN -->

Aktualizacja: 2026-11-05 (`spikes/measure/tools/ingest.py`). Metoda D-33: akcelerometr i mikrofon telefonu + znaczniki wewnętrzne; dokładność 2–5 ms (akcelerometr ≥ 200 Hz) albo ±10 ms (100 Hz, iPhone). Progi: `spikes/measure/thresholds.json` (= §4). „Stuknięcie→…” liczone od drgania obudowy przy uderzeniu palca, więc obejmuje opóźnienie ekranu dotykowego.

| Telefon | System | Klasa | Tier haptyki | Akcel. [Hz] | Stuknięcie→drganie p50/p95 | Polecenie→drganie p50/p95 | Stuknięcie→klik p50/p95 | Dźwięk: szybka vs silnik (p50) | Przerwa w oporze | Dźwięk↔drganie p95 | Data | Plik |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| samsung SM-A165F | android 16 | budget (aplikacja: samsung_a) | A0 | 250.0 | brak danych (odrzucone 20/20) | brak danych (odrzucone 30/30) | brak danych (odrzucone 20/20) | 52 vs 126 ms → 73 ms (przechodzi) | 716 ms (nie dotyczy: A0 bez oporu ciągłego, TECH §2.2) | brak danych | 2026-11-05 | lockwright-pomiar-android-SM-A165F-20261105-1221.json |

<!-- MEASURE:END -->

### 8.1 Spike 4 na telefonie właściciela (`planb-perf-apk`, 10 min, GEM3)

Samsung SM-A165F (Helio G99, Mali-G57 MC2, 4 GB, ekran 60 Hz), scena planu B, 60 s rozgrzewki + 600 s pomiaru. Surowe dane: `docs/handoff/device-tests/planb_perf_*.log`, raport `docs/handoff/device-tests/REPORT.md` §3.

| Kryterium spike'u 4 (§4) | Wynik | Werdykt |
|---|---|---|
| Czas GPU (nie kryterium, diagnostyka) | p50 5,69 ms / p95 6,43 ms, 47 draw calli | GPU zajęte w ok. 38% budżetu 16,7 ms |
| Czas klatki p95 ≤ 16,7 ms | 18,18 ms (stałe 55 FPS) | **na granicy**: przyczyną jest tempo klatek (physics 120 Hz bez `physics_jitter_fix`, kolejka Samsunga), a nie renderer; N-33 |
| 1% low ≥ 55 FPS | 30,3 FPS (pojedyncze podwójne klatki co ok. 11 klatek) | **nie przechodzi**, ta sama przyczyna co wyżej |
| Brak spadku po 10 min (throttling) | 1. min = 10. min; `SKIN` 30,9 °C, status termiczny 0 | **przechodzi** |
| RAM ≤ 450 MB | PSS 598 MB (Graphics 317 MB) w spike'u; 388 MB w grze na menu | **nie przechodzi** (tekstury planu B, wczytywanie wszystkich WAV przy starcie); N-35 |
| Start do menu ≤ 4 s | ok. 4,4 s (1,3 s aktywność + ok. 3,1 s `Sfx._preload_all()`) | **nie przechodzi**, do naprawienia w kodzie; N-35 |
| Bateria ≤ 15%/h, AAB ≤ 60 MB | nie mierzono; paczka zasobów dziś 289 MB (N-30) | brak danych / nie przechodzi |

### 8.2 Werdykt go / no-go dla Godota (warunki zmiany z §1.9), 2026-11-05

**GO, warunkowo: zostajemy przy Godocie 4.7.2.** Żaden z warunków zmiany z §1.9 nie jest spełniony:

1. **Warunek 1 (haptyka Godot vs natywnie, > 8 ms):** nie rozstrzygnięty. Na A16 z silnikiem ERM `MOTOR_COIN_DC` (A0) akcelerometr nie wykrył żadnego impulsu 30 ms (30/30 i 20/20 odrzuconych), a natywnej aplikacji kontrolnej nie mierzono. Aplikacja pomiarowa ma poprawione progi detekcji i impuls A0 40 ms; pomiar trzeba powtórzyć, najlepiej także na telefonie z LRA (A2+). **Ryzyko projektowe:** jeśli impuls 40 ms na tym ERM nadal jest niewyczuwalny, impulsy A0 25–40 ms z §2.2 trzeba wydłużyć do 60–80 ms (decyzja po pomiarze).
2. **Warunek 2 (Oboe):** nie zachodzi. Ścieżka Oboe/AAudio: p50 52,5 ms, p95 54,9 ms, rozrzut 2,4 ms. Ścieżka silnika: p50 125,7 ms, rozrzut 12 ms. Zysk 73 ms przy progu ≥ 30 ms, bez trzasków. **Natywny mostek audio jest obowiązkowy** (AudioStreamPlayer Godota na tym telefonie jest za wolny na klik zamka).
3. **Warunek 3 (iOS GDExtension):** nie rozstrzygnięty. Brak pomiaru na iPhonie, a `game-ios` w CI jest czerwone (N-24, poprawka sesji B w toku).
4. **Warunek 4 (60 FPS na tanim telefonie):** nie zachodzi. Renderer Mobile robi scenę w 6,4 ms (p95) na Mali-G57, a brakujące FPS wynikają z ustawień tempa klatek, nie z renderera.
5. **Warunek 5:** nie dotyczy.

Do zamknięcia GO: pomiar na iPhonie, powtórzony pomiar haptyki (A0 i A2+), naprawy N-33 (tempo klatek), N-35 (RAM i start) oraz N-30 (rozmiar paczki).

## 9. Języki głosów na żądanie (D-62)

2026-11-06 · sesja A (agent głosów). Decyzja właściciela D-62: kwestie PL+EN w paczce, pozostałe języki głosów pobierane przy wyborze języka. Zastępuje tymczasowe D-61 (DE dalej w `exclude_filter` presetów Android/iOS; to teraz implementacja, nie obejście).

### 9.1 Ocena dwóch dróg

**(a) Google Play Asset Delivery (on-demand / fast-follow).** Godot 4.7 nie ma wbudowanej obsługi PAD: eksport Androida buduje AAB przez Gradle, ale pakiety zasobów wymagają osobnego modułu `asset-pack` w szablonie Gradle, biblioteki `com.google.android.play:asset-delivery` i własnej wtyczki Java/Kotlin (żądanie pobrania, stan, ścieżka do plików), a dopiero potem `ProjectSettings.load_resource_pack()`. Nie znaleźliśmy utrzymywanego, oficjalnego pluginu dla 4.7 (są tylko narzędzia do dzielenia pck, np. GodotAssetBundle, bez PAD). Wady: działa tylko w AAB z Google Play (nie w APK debug, nie w sideloadzie, nie na iOS); iOS musiałby osobno mieć On-Demand Resources (Godot ich też nie obsługuje). Zaleta: hosting i CDN Google, brak własnego serwera, rozmiar wliczany osobno od paczki bazowej. **Werdykt:** za drogo na 8 MB na język; dwie natywne integracje zamiast jednej.

**(b) Pck na język, HTTP do `user://`, SHA-256, `load_resource_pack`.** Jedna ścieżka dla Androida i iOS, czysty GDScript (`HTTPClient`), działa też w APK debug i na desktopie. Pck zawiera tylko dane (zremapowane `.ogg.import` + `.oggvorbisstr` + cztery pliki porządkowe Godota: `project.binary`, `uid_cache.bin`, `global_script_class_cache.cfg`, `icon.svg`); narzędzie budujące odrzuca pck z czymkolwiek innym. Montujemy z `replace_files=false`: pack tylko **dodaje** `res://assets/audio/lines/<lang>/…`, nigdy nie podmienia plików z paczki głównej. **Werdykt: wybrane.**

**Zasady sklepów.** Google Play (Device and Network Abuse): zakaz pobierania kodu wykonywalnego (dex, JNI, natywne biblioteki) spoza Google Play; pobieranie zasobów gry jest dozwolone. Apple (App Review 2.5.2): aplikacja nie może pobierać kodu zmieniającego działanie; dane/treści są dozwolone, a przy dodatkowych pobraniach (4.2.3) podaje się rozmiar i pyta użytkownika. Nasz pck jest data-only (sprawdzane w CI), gra działa bez niego (napisy), a rozmiar jest pokazany przed pobraniem. Android potrzebuje uprawnienia `INTERNET` (zwykłe, bez okna zgody; dodane w presecie Android). iOS: tylko HTTPS (ATS) — GitHub i Cloudflare to spełniają.

**Prywatność.** Jedno zwykłe `GET` statycznego pliku: bez identyfikatorów, ciasteczek, nagłówków śledzących i analityki. Hosting (GitHub, później Cloudflare) widzi tylko adres IP w logach serwera — do wzmianki w polityce prywatności i w Data safety / App Privacy jako „brak zbieranych danych przez aplikację”. Godot nie daje odczytu typu sieci (Wi-Fi/komórkowa), więc zamiast „tylko Wi-Fi” pytamy raz (z rozmiarem).

### 9.2 Implementacja

- **Budowanie:** `python3 tools/build_voice_packs.py --godot <godot> [--import] [--langs de] [--write-game-manifest]`. Dla każdego języka spoza PL/EN uruchamia `--export-pack "Voice <lang>"` (preset w `game/export_presets.cfg`: `export_filter="resources"` bez wybranych plików, `include_filter="assets/audio/lines/<lang>/*.ogg"`, `exclude_filter` na skrypty), parsuje katalog pck (format 4 w Godot 4.7), sprawdza „tylko dane” i komplet kwestii, liczy SHA-256 i pisze `voice_packs.json` (`schema`, `version`, `base_url`, `packs.<lang>: file, url, size, sha256, lines, godot`). Nowy język: skopiować preset jako „Voice fr”.
- **Wersja:** skrót SHA-256 źródłowych `.ogg` wszystkich języków + `major.minor` silnika. Bajty pck **nie są powtarzalne** między commitami (Godot dokłada `project.binary` i cache), więc każda wersja jest budowana i wydawana raz, a manifest gry bierzemy z wydania.
- **Manifest w grze:** `game/data/voice_packs.json` (w paczce). Hash jest częścią podpisanej aplikacji: pobrany plik musi się zgadzać co do bajtu; pack od innego builda (inny sha) jest przy starcie usuwany i proponowany na nowo.
- **Autoload `VoicePacks`** (`game/scripts/autoload/voice_packs.gd`): przy starcie montuje pobrane packi pasujące do manifestu; `ensure(lang)` pobiera do `user://voice_packs/voice_<lang>.pck.part` (wznowienie przez `Range`, plik pomocniczy `.part.json` z sha, obsługa przekierowań GitHub → CDN, 200 zamiast 206 = od zera, 20 s bez postępu = `timeout`), potem SHA-256 po 1 MB na klatkę, `rename`, `load_resource_pack(…, false)`. Sygnały: `state_changed`, `progress`, `installed`, `failed(reason)` (`offline`, `timeout`, `interrupted`, `checksum`, `http_<kod>`, `storage`, `mount`). Nic na to nie czeka: bez packa `DialoguePlayer` pokazuje same napisy, jak dotąd. `file://`, `res://`, `user://` w URL kopiują lokalnie (testy, dev).
- **Ustawienie `voice_download`:** `ask` (domyślne: przy pierwszym wyborze języka bez głosów oferta „Głosy po niemiecku: 8,2 MB — Pobierz / Nie teraz”), `auto` (po zgodzie albo przełącznikiem „Pobieraj głosy automatycznie”: pobiera od razu po wyborze języka), `manual` (po „Nie teraz”: tylko przycisk Pobierz, bez ponownego pytania).
- **UI:** blok pod wyborem języka w Ustawieniach (zwykłe wiersze, bez karty), przyciski-tabliczki 52 dp, stan tekstem (rozmiar / „pobieranie 42%” / „gotowe” / „Brak sieci. Napisy zostają.”), notka o prywatności. Klucze `settings.voice_pack.*` PL/EN/DE.
- **CI:** `.github/workflows/voice-packs.yml` (push zmieniający kwestie spoza PL/EN, narzędzie lub workflow; ręcznie z `base_url`). Buduje packi, tworzy GitHub Release `voice-packs-<version>` z `voice_<lang>.pck` + `voice_packs.json` (raz na wersję; gdy wydanie istnieje, bierze jego manifest), commituje `game/data/voice_packs.json` do `main`, więc następny build aplikacji pinuje te pliki. Baza URL: input `base_url` → zmienna repo `VOICE_PACKS_BASE_URL` → GitHub Releases. Cloudflare dopiero po sygnale właściciela (D-51): wystarczy wgrać te same pliki i ustawić zmienną; sha się nie zmienia.
- **Rozmiary (2026-11-06):** `voice_de.pck` 8,2 MB (8 164 916 B, 164 kwestie). Dla porównania źródła w paczce: PL 7,6 MB, EN 7,5 MB. Paczka mobilna bez DE jak w D-61.
- **Testy:** `game/tests/gut/test_voice_packs.gd` — fixture pck pakowany w teście (`PCKPacker`), pobieranie przez `file://` i przez lokalny serwer HTTP (zerwanie w połowie + wznowienie `Range`), zły sha (nie montuje, kasuje `.part`), offline i 404 (same napisy), ponowne uruchomienie (montuje / usuwa nieaktualny), blok w Ustawieniach (rozmiar, 48 dp, „Nie teraz” zapamiętane, etykiety ≤ 28 znaków).
- **Ograniczenia:** Godot nie umie odmontować packa — usunięcie języka działa po restarcie. Pack zbudowany starszym Godotem ładuje się w nowszym, odwrotnie nie; wersja zawiera `major.minor`, więc zmiana silnika daje nowe wydanie.
