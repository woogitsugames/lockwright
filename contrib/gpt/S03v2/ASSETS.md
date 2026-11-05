# S03-v2 — karta techniczna głosów

## Metoda i prawa

- **Generator:** własny generator DSP w Node.js 18+, bez pakietów zewnętrznych. Synteza addytywna 30 harmonicznych ze zmienną F0, trzema szczytami formantowymi, szumem oddechu, tremolem, jitterem i obwiedniami wielopulsowymi; po syntezie normalizacja K-weighted EBU R128 momentary.
- **Użyte modele AI / klonowanie:** żadne. Brak słów, fonemów, imitacji konkretnych realnych osób, próbek aktorów, bibliotek sampli i nagrań osób trzecich.
- **Licencja narzędzia:** kod generatora stanowi część oryginalnego wkładu do projektu Lockwright. Node.js jest udostępniany na licencji MIT; użyto wyłącznie jego modułów wbudowanych. WAV-y zostały wytworzone matematycznie od podstaw, bez licencji na cudze sample. Zasady rozpowszechniania tych nowych assetów wynikają z licencji repozytorium.
- **Zgodność:** każda osoba jest fikcyjna; parametry estetyczne to decyzje artystyczne oparte na `docs/handoff/MAGNIFIC-PORTRETY.md`, `docs/CLIENTS.md` i `game/i18n/content.csv`.
- **Uwaga artystyczna:** proceduralne wokalizacje są prototypami, nie realistycznym aktorstwem. Nie przeprowadzano jeszcze testu zewnętrznego ASR ani odsłuchu w grze.

## Przypisanie emocji

| Nazwa pliku | Funkcja | Bazowa długość (s) | Prompt niemy / charakter artykulacji |
|---|---|---:|---|
| `greeting.wav` | powitanie | 0.76 | One friendly closed-mouth rising-then-settling hum |
| `surprise.wav` | zdziwienie | 0.66 | A quick open-vowel gasp with pitch jump; no words |
| `relief.wav` | ulga | 1.12 | Long fading, breath-inflected vocal sigh |
| `thanks.wav` | podziękowanie | 0.87 | Two small nonverbal hum pulses, no phonemes |
| `impatient.wav` | zniecierpliwienie | 0.8 | Two low tense nasal grunts, no words |
| `sad.wav` | smutek | 1.18 | Slow, small mournful hum into a sigh |
| `laugh.wav` | śmiech | 1.14 | Three breathy voiced chuckle bursts; no words |
| `goodbye.wav` | pożegnanie | 0.83 | Brief lowering humming acknowledgement |

## Parametry i prompt każdej z 39 postaci

Prompt dla każdej postaci: **"Create the eight abstract non-lexical voiced hums and breaths described above, with no intelligible syllables, at profile pitch F0 and three vocal tract resonances F1/F2/F3; match the personality below; no celebrity resemblance."** Parametry określają indywidualne brzmienie, a nasiona FNV są deterministyczne dla `id|emotion|S03v2|2026-11-05`. Jednostki F0 i formantów: Hz. Współczynniki oddechu, chropowatości, vibrato, tempa i voicing są bezwymiarowe.

| ID | Fikcyjna postać | Wiek | F0 Hz | F1/F2/F3 Hz | breath/rough/vibrato/tempo/voicing | Wytyczna barwy i charakteru |
|---|---|---:|---:|---|---|---|
| `agnieszka` | Agnieszka | 45 | 187 | 610/1470/2830 | 0.28/0.09/0.004/1.03/0.96 | Tired but kind night-shift nurse; warm exhale |
| `aino` | Aino | 50 | 169 | 550/1390/2740 | 0.16/0.18/0.005/1.02/0.96 | Finnish marine engineer; assured and weathered |
| `bartek` | Bartek | 30 | 145 | 535/1310/2540 | 0.16/0.08/0.005/0.98/0.97 | Shy groom; modest, almost apologetic little chuckle |
| `basia` | Basia | 48 | 205 | 635/1570/2900 | 0.14/0.06/0.006/0.9/0.98 | Cheerful practical residents committee secretary |
| `bride` | Kasia (panna młoda) | 29 | 239 | 710/1800/3160 | 0.15/0.03/0.008/0.91/0.98 | Brisk delighted newlywed; lively light chuckle |
| `captain` | Kapitan statku | 60 | 107 | 475/1160/2370 | 0.16/0.24/0.007/1.05/0.98 | Steady older Nordic captain, low resonant growl |
| `claimant` | Rzekoma spadkobierczyni | 33 | 215 | 680/1570/2950 | 0.1/0.05/0.002/0.88/0.99 | Overconfident claimant; tightly controlled reaction |
| `darek` | Darek | 40 | 133 | 500/1240/2510 | 0.2/0.25/0.006/0.87/0.93 | Tense and frustrated, not threatening |
| `elzbieta` | Elżbieta | 55 | 181 | 570/1470/2810 | 0.13/0.11/0.004/0.97/0.98 | Warm, methodical building manager |
| `ewa` | Ewa | 50 | 186 | 595/1480/2910 | 0.17/0.14/0.004/0.86/0.98 | Decisive, always in a hurry |
| `gosia` | Gosia | 36 | 194 | 610/1600/2980 | 0.11/0.04/0.005/0.99/0.99 | Calm, self-confident furniture restorer |
| `hall_manager` | Kierownik sali | 45 | 139 | 530/1360/2570 | 0.12/0.07/0.004/1.03/0.98 | Easygoing rehearsal-room manager |
| `hania` | Hania | 7 | 338 | 815/2140/3540 | 0.22/0.01/0.01/0.84/0.97 | Seven-year-old girl; small bright breathy hum |
| `headteacher` | Dyrektor szkoły | 50 | 166 | 540/1430/2670 | 0.09/0.05/0.002/0.96/0.99 | Measured, welcoming school headteacher |
| `iga` | Iga | 27 | 232 | 715/1730/3210 | 0.12/0.06/0.009/0.87/0.98 | Energetic punctual indie drummer |
| `irena` | Pani Irena | 79 | 157 | 525/1270/2600 | 0.27/0.24/0.01/1.12/0.9 | Elderly gentle widow; tremulous quiet warmth |
| `jacques` | Monsieur Jacques | 72 | 123 | 510/1230/2440 | 0.22/0.23/0.008/1.06/0.95 | Courteous elderly Belgian neighbour |
| `kazimierz` | Pan Kazimierz | 60 | 126 | 520/1320/2550 | 0.14/0.17/0.007/0.96/0.97 | Cheerful after a family celebration |
| `krysia` | Krysia | 60 | 179 | 565/1400/2710 | 0.2/0.17/0.006/1/0.95 | Dry humour, newspaper-reading kiosk regular |
| `kuba` | Kuba | 23 | 158 | 570/1420/2740 | 0.24/0.07/0.008/0.87/0.95 | Nervous first job interview; hesitant |
| `leopold` | Pan Leopold | 70 | 115 | 500/1210/2470 | 0.22/0.23/0.011/1.11/0.95 | Seventy-year-old antiquarian; dignified amused gravel |
| `magda` | Magda | 41 | 202 | 630/1560/2910 | 0.19/0.04/0.006/1/0.96 | Slightly embarrassed bilingual translator |
| `marcel` | Marcel | 29 | 153 | 550/1330/2640 | 0.11/0.08/0.004/0.9/0.99 | Businesslike brisk courier |
| `marek` | Marek | 45 | 132 | 505/1340/2530 | 0.11/0.19/0.004/0.84/0.97 | Impatient heir, clipped exhale |
| `martine` | Madame Martine | 74 | 165 | 545/1280/2610 | 0.22/0.19/0.01/1.08/0.94 | Older Belgian woman, reserved elegance |
| `mietek` | Mietek | 30 | 148 | 530/1330/2600 | 0.18/0.11/0.006/0.92/0.97 | Busy friendly pizza cook |
| `nadia` | Nadia | 29 | 222 | 685/1710/3140 | 0.24/0.06/0.007/0.96/0.97 | Early-shift baker, sleepy friendly smile |
| `neighbour_lucyna` | Pani Lucyna | 70 | 161 | 540/1300/2650 | 0.17/0.22/0.008/1/0.95 | Vigilant elderly neighbour with dry scepticism |
| `neighbour_robe` | Sąsiad w szlafroku | 50 | 127 | 480/1250/2470 | 0.31/0.18/0.005/1.12/0.93 | Sleepy neighbour; stifled morning yawn |
| `norbert` | Norbert | 43 | 142 | 530/1290/2590 | 0.18/0.09/0.005/1.02/0.97 | Worried, courteous brother |
| `pieter` | Brat Pieter | 66 | 132 | 520/1280/2590 | 0.15/0.16/0.006/1.12/0.97 | Gentle, patient caretaker of beguinage |
| `piotr` | Piotr | 38 | 136 | 505/1260/2550 | 0.18/0.06/0.003/1.1/0.97 | Quiet, contemplative heir |
| `renata` | Pani Renata | 52 | 199 | 650/1590/2950 | 0.16/0.14/0.009/0.84/0.98 | Fast-talking spirited pizzeria owner; non-lexical only |
| `stranger` | Nieznajomy | 43 | 157 | 580/1510/2740 | 0.07/0.05/0.003/0.8/0.99 | Overly polite, hurried, tightly wound stranger |
| `teresa` | Pani Teresa | 65 | 171 | 585/1440/2750 | 0.17/0.13/0.007/1.04/0.98 | Amused older neighbour in dressing gown |
| `tomasz` | Tomasz | 40 | 137 | 525/1310/2620 | 0.14/0.13/0.005/1.08/0.98 | Kind carpenter and father, reassuring steady baritone |
| `waldek` | Pan Waldek | 70 | 119 | 480/1200/2480 | 0.2/0.22/0.009/1.07/0.94 | Older practical allotment neighbour |
| `wanda` | Pani Wanda | 62 | 172 | 550/1430/2750 | 0.14/0.11/0.005/0.99/0.98 | Decisive tenement manager with a binder |
| `zbyszek` | Pan Zbyszek | 74 | 109 | 475/1170/2420 | 0.25/0.26/0.011/1.11/0.93 | Elderly gardener, gently gravelly humor |

## Dostarczenie i pomiar

- 39 × 8 = **312** różnych mono PCM16 WAV / 48 kHz; po jednym na emocję i ID.
- Docelowy peak **-28 LUFS momentary**, mierzony oknem 400 ms co 10 ms z korekcją K-weight (nie jest to to samo co LUFS integrated).
- Każdy plik ma metryki i SHA-256 w `manifest.json`; walidator `verify_voices.js` sprawdza parametry niezależnie.
- Ustawienia syntezy i prawa są opisane w źródle `generate_voices.js`.
