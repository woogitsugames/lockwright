# S03v2 — 39 bezsłownych głosów postaci epizodycznych

Wydanie: 2026-11-05. Zestaw **312 plików WAV** w 39 katalogach. Do każdego ID przypisano osiem odgłosów: `greeting`, `surprise`, `relief`, `thanks`, `impatient`, `sad`, `laugh`, `goodbye`. Jest to **synteza bezsłownych ekspresji**, a nie dialogi i nie generowanie mowy w jakimkolwiek języku.

## Integracja

Wszystkie pliki mają ścieżkę `contrib/gpt/S03v2/voices/<id>/<event>.wav` i są w formacie **PCM 16-bit, 48 kHz, mono**. Podstawą jest dokładna nazwa pliku, szczególnie `impatient.wav`, `sad.wav`, `laugh.wav` (nie: `impatience`, `sadness`, `laughter`). `manifest.json` opisuje czas, głośność, początek i koniec każdej próbki. Żaden zapis poza katalogiem S03v2 nie jest potrzebny do korzystania z plików.

## Regeneracja

```
python -m pip install numpy scipy soundfile pyloudnorm
python contrib/gpt/S03v2/generate_voices.py
```

Synteza jest powtarzalna (stałe ziarno losowe). Każde nagranie składa się z harmonicznego, modulowanego tonu źródłowego z formantami, szumem oddechu i obwiednią odpowiadającą emocji. Nie zawiera fonemów słów ani cudzych nagrań. **Nie klonowano żadnego prawdziwego głosu**, nie korzystano z bibliotek nagrań i nie używano sieciowego TTS. Głosy są celowo stylizowane, a nie fotorealistyczne.

## Kontrola jakości

W trakcie generacji sprawdzane jest dla każdego z 312 plików:

- dokładnie 48 000 próbek/s, jeden kanał, PCM 16-bit;
- czas od 0,3 do 1,5 s;
- docelowy zintegrowany LUFS klipu ok. −28 (pomiar EBU R128, okno pomiarowe 400 ms);
- wykrywalny start do 20 ms, cisza na końcu do 100 ms (względny próg −38 dB względem szczytu);
- wszystkie 39 × 8 ścieżek i identyfikatorów.

**Ograniczenie:** znormalizowano głośność według zintegrowanego LUFS krótkiego klipu. Miara „momentary” z EBU R128 w analizatorze konkretnego silnika może różnić się nieco od deklarowanej. Brak zrozumiałych słów wynika z konstrukcji generatora, ale nie zastępuje zewnętrznego testu ASR i odsłuchu przez testerów. Aby spełnić ostateczne kryterium sesji C, przeprowadźcie test automatyczny oraz odsłuch próbny na urządzeniu.

## Licencje

Źródło generatora i wygenerowane próbki są oryginalne dla Lockwright, bez cudzych sampli i bez imitacji rozpoznawalnych osób. Próbki można użytkować i modyfikować w projekcie Lockwright. Biblioteki NumPy, SciPy, SoundFile i pyloudnorm użyte do tworzenia nie są dołączone do paczki (licencje odpowiednio BSD-3-Clause, BSD-3-Clause, BSD-3-Clause, MIT; patrz aktualne pakiety zależności). Szczegóły parametrów każdej postaci zawiera `ASSETS.md`.
