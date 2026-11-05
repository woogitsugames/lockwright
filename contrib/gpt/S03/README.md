# S03 — Głosy postaci bez słów

## Wynik

Przygotowano **96 oryginalnych syntetycznych nagrań** (12 banków × 8 emocji) do reakcji towarzyszących liniom dialogów w grze Lockwright. Nagrania są bezsłownymi wokalizami: hum, westchnienie, śmiech i modulowany oddech. Nie są syntezą zdań ani klonami głosów rzeczywistych osób. Nie wykorzystano cudzych nagrań, sampli, utworów muzycznych ani modeli TTS.

**Format:** WAV (RIFF), PCM signed 16-bit, 48 kHz, mono, 0,59–1,38 s, **–16 LUFS** EBU R128. Te same pliki są używane przy tekście PL i EN — nazwy kategorii zapisano w obu językach.

**Istotna niespójność źródła:** `docs/CLIENTS.md` opisuje 12 *numerowanych pozycji obsady*, ale 13 rzeczywistych osób: w pozycji 9 są **Ola i pani Krystyna**. Aby zachować ściśle wymagane 96 WAV-ów, obie używają jednego banku `ola_krystyna`. Nie jest to 13 unikalnych głosów; rekomenduję rozdzielenie ich w następnej iteracji (104 pliki dla 13 indywidualnych banków).

## Tabela postać → pliki

| Postać (cast.*) | Powitanie / greeting | Zdziwienie / surprise | Ulga / relief | Podziękowanie / thanks | Zniecierpliwienie / impatience | Smutek / sadness | Śmiech / laughter | Pożegnanie / farewell |
|---|---|---|---|---|---|---|---|---|
| Pani Halina (`halina`) | [`greeting.wav`](voices/halina/greeting.wav) | [`surprise.wav`](voices/halina/surprise.wav) | [`relief.wav`](voices/halina/relief.wav) | [`thanks.wav`](voices/halina/thanks.wav) | [`impatience.wav`](voices/halina/impatience.wav) | [`sadness.wav`](voices/halina/sadness.wav) | [`laughter.wav`](voices/halina/laughter.wav) | [`farewell.wav`](voices/halina/farewell.wav) |
| Pani Zosia (`zosia`) | [`greeting.wav`](voices/zosia/greeting.wav) | [`surprise.wav`](voices/zosia/surprise.wav) | [`relief.wav`](voices/zosia/relief.wav) | [`thanks.wav`](voices/zosia/thanks.wav) | [`impatience.wav`](voices/zosia/impatience.wav) | [`sadness.wav`](voices/zosia/sadness.wav) | [`laughter.wav`](voices/zosia/laughter.wav) | [`farewell.wav`](voices/zosia/farewell.wav) |
| Pan Stefan (`stefan`) | [`greeting.wav`](voices/stefan/greeting.wav) | [`surprise.wav`](voices/stefan/surprise.wav) | [`relief.wav`](voices/stefan/relief.wav) | [`thanks.wav`](voices/stefan/thanks.wav) | [`impatience.wav`](voices/stefan/impatience.wav) | [`sadness.wav`](voices/stefan/sadness.wav) | [`laughter.wav`](voices/stefan/laughter.wav) | [`farewell.wav`](voices/stefan/farewell.wav) |
| Pan Roman (`roman`) | [`greeting.wav`](voices/roman/greeting.wav) | [`surprise.wav`](voices/roman/surprise.wav) | [`relief.wav`](voices/roman/relief.wav) | [`thanks.wav`](voices/roman/thanks.wav) | [`impatience.wav`](voices/roman/impatience.wav) | [`sadness.wav`](voices/roman/sadness.wav) | [`laughter.wav`](voices/roman/laughter.wav) | [`farewell.wav`](voices/roman/farewell.wav) |
| Aspirant Lena Sowa (`lena`) | [`greeting.wav`](voices/lena/greeting.wav) | [`surprise.wav`](voices/lena/surprise.wav) | [`relief.wav`](voices/lena/relief.wav) | [`thanks.wav`](voices/lena/thanks.wav) | [`impatience.wav`](voices/lena/impatience.wav) | [`sadness.wav`](voices/lena/sadness.wav) | [`laughter.wav`](voices/lena/laughter.wav) | [`farewell.wav`](voices/lena/farewell.wav) |
| Marta (`marta`) | [`greeting.wav`](voices/marta/greeting.wav) | [`surprise.wav`](voices/marta/surprise.wav) | [`relief.wav`](voices/marta/relief.wav) | [`thanks.wav`](voices/marta/thanks.wav) | [`impatience.wav`](voices/marta/impatience.wav) | [`sadness.wav`](voices/marta/sadness.wav) | [`laughter.wav`](voices/marta/laughter.wav) | [`farewell.wav`](voices/marta/farewell.wav) |
| Zuzanna Wilk (`zuzanna`) | [`greeting.wav`](voices/zuzanna/greeting.wav) | [`surprise.wav`](voices/zuzanna/surprise.wav) | [`relief.wav`](voices/zuzanna/relief.wav) | [`thanks.wav`](voices/zuzanna/thanks.wav) | [`impatience.wav`](voices/zuzanna/impatience.wav) | [`sadness.wav`](voices/zuzanna/sadness.wav) | [`laughter.wav`](voices/zuzanna/laughter.wav) | [`farewell.wav`](voices/zuzanna/farewell.wav) |
| Pan Edek (`edek`) | [`greeting.wav`](voices/edek/greeting.wav) | [`surprise.wav`](voices/edek/surprise.wav) | [`relief.wav`](voices/edek/relief.wav) | [`thanks.wav`](voices/edek/thanks.wav) | [`impatience.wav`](voices/edek/impatience.wav) | [`sadness.wav`](voices/edek/sadness.wav) | [`laughter.wav`](voices/edek/laughter.wav) | [`farewell.wav`](voices/edek/farewell.wav) |
| Ola / pani Krystyna (wspólny bank) (`ola_krystyna`) | [`greeting.wav`](voices/ola_krystyna/greeting.wav) | [`surprise.wav`](voices/ola_krystyna/surprise.wav) | [`relief.wav`](voices/ola_krystyna/relief.wav) | [`thanks.wav`](voices/ola_krystyna/thanks.wav) | [`impatience.wav`](voices/ola_krystyna/impatience.wav) | [`sadness.wav`](voices/ola_krystyna/sadness.wav) | [`laughter.wav`](voices/ola_krystyna/laughter.wav) | [`farewell.wav`](voices/ola_krystyna/farewell.wav) |
| Pan Władysław (`wladyslaw`) | [`greeting.wav`](voices/wladyslaw/greeting.wav) | [`surprise.wav`](voices/wladyslaw/surprise.wav) | [`relief.wav`](voices/wladyslaw/relief.wav) | [`thanks.wav`](voices/wladyslaw/thanks.wav) | [`impatience.wav`](voices/wladyslaw/impatience.wav) | [`sadness.wav`](voices/wladyslaw/sadness.wav) | [`laughter.wav`](voices/wladyslaw/laughter.wav) | [`farewell.wav`](voices/wladyslaw/farewell.wav) |
| Dr Anna Rygiel (`rygiel`) | [`greeting.wav`](voices/rygiel/greeting.wav) | [`surprise.wav`](voices/rygiel/surprise.wav) | [`relief.wav`](voices/rygiel/relief.wav) | [`thanks.wav`](voices/rygiel/thanks.wav) | [`impatience.wav`](voices/rygiel/impatience.wav) | [`sadness.wav`](voices/rygiel/sadness.wav) | [`laughter.wav`](voices/rygiel/laughter.wav) | [`farewell.wav`](voices/rygiel/farewell.wav) |
| Pani Jadwiga (`jadwiga`) | [`greeting.wav`](voices/jadwiga/greeting.wav) | [`surprise.wav`](voices/jadwiga/surprise.wav) | [`relief.wav`](voices/jadwiga/relief.wav) | [`thanks.wav`](voices/jadwiga/thanks.wav) | [`impatience.wav`](voices/jadwiga/impatience.wav) | [`sadness.wav`](voices/jadwiga/sadness.wav) | [`laughter.wav`](voices/jadwiga/laughter.wav) | [`farewell.wav`](voices/jadwiga/farewell.wav) |

## Pozostałe pliki i instrukcja

- `generate_voices.js` — deterministyczny generator w Node.js 18+, bez zewnętrznych bibliotek i internetu; synteza harmoniczno-formantowa z oddechem, wahaniami intonacji, normalizacją EBU R128 i zapisem WAV. Nie odczytuje plików z innych katalogów projektu.
- `ASSETS.md` — ewidencja **każdego** WAV-a, data, narzędzie, pełny prompt techniczny z parametrami, zasady wykorzystania, edycje.
- `QA.md` — lista parametrów technicznych i poziomów wszystkich 96 plików.
- `voices/<id>/<emotion>.wav` — dźwięki gotowe do importu w Godot.

Odtworzenie z katalogu repozytorium:

```sh
node contrib/gpt/S03/generate_voices.js contrib/gpt/S03/voices
```

Skrypt nadpisuje WAV-y i dodaje lokalny plik `voices/qa.json` z raportem (nie jest częścią oddanego zestawu). Nagrania deterministyczne, łączny rozmiar około 8,7 MB. Wszystkie pliki w tym zleceniu są zapisane **wyłącznie w `contrib/gpt/S03/`**.

## Weryfikacja i ograniczenia

Parametry wszystkich 96 plików przeszły kontrolę nagłówków, czasu, liczby kanałów, próbkowania, poziomu dźwięku oraz szczytów. Nie było materiału językowego do transkrypcji, ponieważ generator tworzy wyłącznie nieleksykalne wokalizy bez artykulacji wyrazów. Nie wykonywano odsłuchu artystycznego w buildzie iOS/Android.

**Co się nie udało / co dalej:** te głosy są proceduralnymi prototypami, a nie realistyczną grą aktorską. Do gry premium wskazany jest odsłuch przez reżysera dźwięku i ewentualne zastąpienie części odgłosów nagraniami fikcyjnych aktorów lub bardziej naturalną syntezą. Nie modyfikowano `game/` (należy do innego zespołu), zatem powiązanie `cast.*` z nazwami plików pozostaje po stronie integracji. Podczas integracji trzeba zadbać o priorytet sygnałów mechanizmu zamka i tekstową alternatywę do głosów.

