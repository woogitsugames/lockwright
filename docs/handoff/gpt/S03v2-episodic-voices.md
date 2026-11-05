# Zlecenie S03-v2: bezsłowne głosy 39 postaci epizodycznych

**Dla:** ChatGPT z dostępem do GitHuba (jedna sesja). **Repo:** `woogitsugames/lockwright`, `main`. **Katalog:** `contrib/gpt/S03v2/`.

## O projekcie
Lockwright to mobilna gra o legalnym ślusarzu z pogotowia. Postacie nie mówią słowami. Przy linii dialogu słychać tylko krótki, bezsłowny odgłos: „hm”, westchnienie ulgi, śmiech, „ojej”. Dzięki temu działa w każdym języku. Wzór jest w `contrib/gpt/S03/` (12 postaci stałej obsady) i w `docs/CLIENTS.md`. Opisy postaci epizodycznych są w tekstach zleceń (`game/i18n/content.csv`, klucze `job.<id>.*`) i w promptach portretów `docs/handoff/MAGNIFIC-PORTRETY.md`.

## Zadanie
Dla każdej z **39 postaci** przygotuj **8 odgłosów**: powitanie, zdziwienie, ulga, podziękowanie, zniecierpliwienie, smutek, śmiech, pożegnanie.
- Wiek, płeć i charakter mają pasować do opisu. Hania ma 7 lat, pan Leopold 70.
- **Bez zrozumiałych słów** w żadnym języku.
- **Bez imitowania prawdziwych, znanych osób.**
- Możesz użyć generatora głosu AI (podaj nazwę narzędzia i ustawienia) albo zsyntetyzować głosy w Pythonie. Opisz metodę.

Postacie (id = nazwa katalogu):
- `agnieszka`
- `aino`
- `bartek`
- `basia`
- `bride`
- `captain`
- `claimant`
- `darek`
- `elzbieta`
- `ewa`
- `gosia`
- `hall_manager`
- `hania`
- `headteacher`
- `iga`
- `irena`
- `jacques`
- `kazimierz`
- `krysia`
- `kuba`
- `leopold`
- `magda`
- `marcel`
- `marek`
- `martine`
- `mietek`
- `nadia`
- `neighbour_lucyna`
- `neighbour_robe`
- `norbert`
- `pieter`
- `piotr`
- `renata`
- `stranger`
- `teresa`
- `tomasz`
- `waldek`
- `wanda`
- `zbyszek`

## Format i nazwy (ważne: gra szuka dokładnie takich ścieżek)
- `contrib/gpt/S03v2/voices/<id>/greeting.wav`, `surprise.wav`, `relief.wav`, `thanks.wav`, `impatient.wav`, `sad.wav`, `laugh.wav`, `goodbye.wav` (dokładnie te nazwy, małe litery).
- WAV 48 kHz mono, 0,3–1,5 s, głośność ok. −28 LUFS (momentary), początek dźwięku ≤ 20 ms od początku pliku, bez ciszy na końcu dłuższej niż 100 ms.
- `manifest.json`: id → lista plików, czas trwania, LUFS.
- `ASSETS.md`: narzędzie, ustawienia lub prompt dla każdej postaci, licencja narzędzia.
- `README.md` po polsku.

## Oddanie
Commit na `main` z wiadomością `contrib/gpt/S03v2: <opis>`. Jeśli nie możesz pisać do `main`, zrób gałąź `gpt/S03v2` i pull request. Jeśli nie masz dostępu do zapisu, spakuj katalog do ZIP-a dla właściciela.

## Kryteria odbioru
- 39 × 8 = 312 plików, nazwy jak wyżej.
- Zero zrozumiałych słów (sesja C sprawdza to automatycznym rozpoznawaniem mowy).
- Głośność i początek dźwięku w normie.
