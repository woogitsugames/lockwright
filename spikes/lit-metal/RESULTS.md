# Spike 4 — wyniki (stan: 2026-11-05, noc)

Wygląd mierzony w kontenerze bez GPU (Mesa lavapipe, Vulkan na CPU). Liczby wydajności z telefonu wpisuje właściciel (procedura: README).

## 1. Zgodność z Cyclesem (1236×1650, `tools/compare.py`)

Referencja: `screens/cycles_1236x1650.png` (Cycles, 64 próbki, denoise, AgX Medium High Contrast, ekspozycja +0,15). Metryki liczone na całym kadrze: MAE w skali 0–255, PSNR, SSIM luminancji (okna 8×8).

| Iteracja | Zmiana | MAE ↓ | PSNR ↑ | SSIM ↑ | Śr. luminancja (Cycles 89,9) |
|---|---|---|---|---|---|
| it0/it1 | pierwszy rig: omni ×60, sonda w punkcie celu (wewnątrz brył) | 57,1 | 11,0 dB | 0,44 | 74,3 |
| it2 | sonda przed przekrojem | 59,7 | 10,7 dB | 0,42 | 74,8 |
| it3 | **fizyczne przeliczenie świateł** (P/π; 1 jednostka Blendera = 1 m dla światła), HDRI obrócone −90° | 77,9 | 8,6 dB | 0,28 | 28,2 |
| it4 | HDRI +90° (z sondą) | 66,1 | 9,8 dB | 0,43 | 36,4 |
| it5 | bez sondy, HDRI −90° | 70,1 | 9,7 dB | 0,39 | 38,5 |
| **it6** | **bez sondy, HDRI +90°** (zmierzone mapowanie Blender↔Godot) | **16,3** | **20,6 dB** | **0,80** | 85,4 |
| it8 (A, bieżący) | + AO wypieczone w albedo metali (okluzja odbić nieba) | 16,7 | 21,0 dB | 0,80 | 80,5 |
| it7 (B) | plan B: płyta Cycles + matcap (matcapy puste — błąd kamery) | 8,8 | 18,2 dB | 0,87 | 81,1 |
| **it9 (B, bieżący)** | **plan B z poprawionymi matcapami** | **3,65** | **25,7 dB** | **0,93** | 90,8 |

Porównania obrazowe (lewa połowa Cycles, prawa Godot): **`screens/compare.png`** (lewa para: wariant A, prawa para: plan B), osobno `screens/compare_A_1236x1650.png`, `screens/compare_planB_1236x1650.png`, historia `screens/compare_it6_split.png`. Surowe zrzuty: `screens/godot_{a,b}_1236x1650.png`, referencja `screens/cycles_1236x1650.png`.

### Najważniejsze ustalenia
1. **Wygląd renderów Cycles pochodzi prawie w całości z HDRI.** W `cutaway.py` scena jest w milimetrach, ale Cycles liczy światło w metrach, więc cztery lampy obszarowe stoją „150 m” od zamka i dają natężenie ~P/(π d²) ≈ 0,016 — o rząd mniej niż niebo (siła 0,25). Chłodny, niebieskawy połysk płaskiego niklu to odbicie jasnego okna w HDRI `interior` (radiancja 4–9 w kierunku odbicia). Konsekwencja dla gry: żeby zachować wygląd, wystarczy niebo + odbicia nieba; lampy są prawie niewidoczne. Wniosek dla sesji art: jeśli światło klucza ma grać, trzeba je przeskalować (×10⁴) albo przejść na jednostki metryczne (zgłoszone w logu).
2. **Mapowanie panoramy**: Blender `u = 0,5 − atan2(y, x)/2π`, Godot `u = atan2(x, −z)/2π` (wyciągnięte z shadera w binarce 4.7.2). Po konwersji osi glTF różnica to obrót nieba o **+90°** wokół Y (`Environment.sky_rotation`). Zły znak obrotu dawał MAE 66–78.
3. **ReflectionProbe pogarsza wynik**: nie ma okluzji, więc wnętrza komór kołków odbijały jasne otoczenie. Bez sondy odbicia idą wprost z nieba; AO wypieczone w albedo metali (`tools/ao_into_albedo.py`) zastępuje okluzję odbić. Sonda zostaje dostępna (`--probe 1`).
4. **Tekstury**: import VRAM (ASTC 4×4 na telefonie, BPTC na desktopie), mipmapy, normal mapy RG, filtr chropowatości z normal mapy (mniej iskrzenia). Bez tego Godot importował 2K jako nieskompresowane bez mipmap.

### Co nadal odstaje (wariant A)
- **Brak cieni miękkich z HDRI** (punktowe źródło 32 000 w panoramie daje w Cyclesie kierunkowe światło z cieniami); w Godocie niebo daje tylko oświetlenie otoczenia bez cieni. Widać to na sprężynach i dnie komór (u nas jaśniejsze, mniej kontrastowe).
- **Krawędzie i fazki**: Cycles ma odbicia wielokrotne (8 odbić) — fazki niklu łapią światło z mosiądzu i odwrotnie; w Godocie fazki są płaskie w tonie.
- **Wytrych**: w Cyclesie bardzo jasny (odbija okno pod kątem), w Godocie ciemniejszy — wąskie, mocno zakrzywione odbicie, które radiance map 256 px rozmywa.
- **Drewno drzwi**: ziarno i ton zgodne; lakier (clearcoat 0,25) nieco słabszy.

## 2. Plan B — wszystko wypieczone
Statyczne części rysują piksel z renderu Cycles (`assets/plate/plate_*.png`) rzutowany przez kamerę, z prawdziwą głębią (siatki są te same, shader `unshaded`). Ruchome części: matcap z Cyclesa + wypieczona normal mapa i AO. Koszt: zero świateł, zero sondy, jedna próbka tekstury płyty na piksel statycznego tła (+ 3 próbki na piksel ruchomych części).

Ograniczenia: płyta pasuje tylko do jednej kamery i jednej rozdzielczości proporcji (3:4); cienie ruchomych kołków na tle są „zapieczone” w pozycji spoczynkowej; zmiana kadru (lupa D-13) wymaga drugiej płyty.

## 3. Wydajność
| Pomiar | Wariant A | Wariant B |
|---|---|---|
| Draw calle / prymitywy (Godot, ten kadr) | *(uzupełnione niżej)* | |
| Tekstury w VRAM | 10 materiałów: 3 × 2K + 5 × 1K + 2 × 512 (albedo, ORM, normal) | płyta 1236×1650 (lub 2160×2880) + 4 matcapy 512 + mapy ruchomych części |
| Telefon (p95 czasu klatki, 1% low, temperatura, bateria) | **do zmierzenia przez właściciela** (APK z CI) | |

lavapipe (CPU) nie mierzy GPU telefonu, dlatego nie podajemy FPS z kontenera jako wyniku.
