# S03-v2 — głosy epizodyczne Lockwright

**312 plików WAV** dla 39 postaci × 8 emocji, bez zrozumiałych słów. Wokalizacje z generatora syntezy harmoniczno-formantowej (bez TTS i bez klonowania). Wszystkie głosy są fikcyjne i różnicowane wysokością, chropowatością, tembrem, oddechem i tempem zależnie od wieku oraz charakteru.

## Struktura

- `voices/<id>/greeting.wav` — powitanie
- `voices/<id>/surprise.wav` — zdziwienie
- `voices/<id>/relief.wav` — ulga
- `voices/<id>/thanks.wav` — podziękowanie
- `voices/<id>/impatient.wav` — zniecierpliwienie
- `voices/<id>/sad.wav` — smutek
- `voices/<id>/laugh.wav` — śmiech
- `voices/<id>/goodbye.wav` — pożegnanie

Nazwy różnią się od katalogu `S03` (który używa m.in. `impatience.wav`, `sadness.wav`, `laughter.wav`, `farewell.wav`); tutaj obowiązują **dokładnie** nazwy z zamówienia S03-v2.

## Specyfikacja

WAV, PCM16 signed, mono, 48 000 Hz, długość 0,3–1,5 s, docelowo –28 LUFS EBU R128 momentary. Rozpoczęcie dźwięku do 20 ms, cisza na końcu maks. 100 ms. Weryfikacja automatyczna na etapie generacji i w `verify_voices.js`.

Metoda, przypisania postaci, parametry 39 profili i kwestia licencji: `ASSETS.md`. Dokładne czasy, głośność, początek, ogon, maksymalny poziom i SHA-256 każdego WAV-a: `manifest.json`.

## Odtworzenie (Node.js 18+)

Z katalogu głównego repozytorium:

```sh
node contrib/gpt/S03v2/generate_voices.js contrib/gpt/S03v2
node contrib/gpt/S03v2/verify_voices.js contrib/gpt/S03v2
```

Nie są wymagane npm ani połączenie internetowe. Skrypt tworzy 312 plików, manifest i odtwarza także README oraz ASSETS. Powtórna generacja daje identyczne SHA-256 pod tym samym środowiskiem Node.

## Kontrola jakości i ograniczenia

312 / 312 plików spełnia numeryczne warunki weryfikacji metadanych i poziomu. Zmierzone długości: 0.521–1.358 s; momentary: -28 do -28 LUFS; najpóźniejszy start: 8.04 ms; najdłuższa cisza na końcu: 39.08 ms.

Nie wykonano odsłuchu aktorskiego w grze ani sprawdzenia zewnętrznym ASR. Syntetyczne odgłosy nie zawierają wygenerowanych słów, ale zewnętrzny system rozpoznawania może czasem interpretować dźwięki bezsłowne jako tekst (fałszywe rozpoznania). Zalecany odsłuch losowej próby i kontrola na urządzeniach docelowych.
