# S03v2 — ASSETS / pochodzenie i ustawienia

## Metoda

Narzędzie: własny skrypt `generate_voices.py` (Python 3, NumPy, SciPy, SoundFile, pyloudnorm). Nie używa generatora mowy ani cudzych głosów.

Parametry globalne: 48 000 Hz / mono / PCM16, cel około −28 LUFS, generator deterministyczny, 8 odgłosów na osobę. W każdym dźwięku jest jedna utrzymywana barwa samogłoskowa / pomruk bez rozpoznawalnej struktury słów. Kontur wysokości i rytm odpowiadają emocji. Zero klonowania oraz zero materiałów źródłowych od innych osób.

**Licencja próbek:** autorskie zasoby stworzone do projektu Lockwright, udzielone do używania w tym projekcie; brak materiału licencjonowanego od osób trzecich. **Kod:** własny generator, zależności open source: numpy (BSD-3-Clause), scipy (BSD-3-Clause), soundfile (BSD-3-Clause), pyloudnorm (MIT).

## Profile dźwiękowe postaci

Podany wiek jest **wytyczną obsadową dla brzmienia**, a nie informacją kanoniczną o fabule, jeśli scenariusz nie podaje wieku. Hania 7, Leopold 70, inne wieku z opisów źródłowych przybliżono tam, gdzie potrzebne.

| ID | Postać | Brzmienie | F0 (Hz) | Oddech | Chropowatość | Charakter |
|---|---|---|---:|---:|---:|---|
| `agnieszka` | Agnieszka | f, cel wieku ok. 45 | 183 | 0.22 | 0.10 | spokojna, opiekuńcza pielęgniarka |
| `aino` | Aino | f, cel wieku ok. 50 | 174 | 0.15 | 0.16 | rzeczowa fińska mechanik okrętowa |
| `bartek` | Bartek | m, cel wieku ok. 29 | 138 | 0.17 | 0.04 | roześmiany pan młody |
| `basia` | Basia | f, cel wieku ok. 42 | 205 | 0.13 | 0.07 | dokładna sekretarka wspólnoty |
| `bride` | Panna młoda | f, cel wieku ok. 28 | 234 | 0.17 | 0.06 | poruszona, pogodna |
| `captain` | Kapitan | m, cel wieku ok. 55 | 111 | 0.15 | 0.23 | stanowczy, opanowany |
| `claimant` | Kobieta przy drzwiach | f, cel wieku ok. 34 | 201 | 0.18 | 0.17 | niepewna, zdenerwowana |
| `darek` | Darek | m, cel wieku ok. 40 | 148 | 0.23 | 0.19 | zdenerwowany, natarczywy |
| `elzbieta` | Elżbieta | f, cel wieku ok. 47 | 184 | 0.11 | 0.08 | rzeczowa zarządczyni |
| `ewa` | Ewa | f, cel wieku ok. 46 | 202 | 0.16 | 0.08 | zdecydowana siostra |
| `gosia` | Gosia | f, cel wieku ok. 36 | 197 | 0.13 | 0.07 | spokojna renowatorka |
| `hall_manager` | Kierownik sali | m, cel wieku ok. 44 | 136 | 0.18 | 0.11 | nieco zniecierpliwiony |
| `hania` | Hania | child, cel wieku ok. 7 | 341 | 0.12 | 0.01 | dziecko, radosna i ciekawa |
| `headteacher` | Dyrektorka szkoły | f, cel wieku ok. 54 | 174 | 0.12 | 0.13 | uprzejma, zdecydowana |
| `iga` | Iga | f, cel wieku ok. 27 | 223 | 0.12 | 0.06 | energiczna perkusistka |
| `irena` | Irena | f, cel wieku ok. 79 | 151 | 0.30 | 0.24 | starsza, cicha bibliotekarka |
| `jacques` | Jacques | m, cel wieku ok. 58 | 133 | 0.18 | 0.16 | uprzejmy, przyjazny sąsiad |
| `kazimierz` | Kazimierz | m, cel wieku ok. 60 | 127 | 0.24 | 0.24 | wesoły i nieco zamyślony |
| `krysia` | Krysia | f, cel wieku ok. 65 | 177 | 0.23 | 0.22 | doświadczona, serdeczna |
| `kuba` | Kuba | m, cel wieku ok. 23 | 166 | 0.15 | 0.08 | młody, nieco zdenerwowany |
| `leopold` | Leopold | m, cel wieku ok. 70 | 111 | 0.26 | 0.28 | starszy antykwariusz, łagodny |
| `magda` | Magda | f, cel wieku ok. 41 | 202 | 0.17 | 0.09 | żywa tłumaczka |
| `marcel` | Marcel | m, cel wieku ok. 29 | 150 | 0.18 | 0.13 | zabiegany kurier |
| `marek` | Marek | m, cel wieku ok. 43 | 142 | 0.11 | 0.12 | ostrożny spadkobierca |
| `martine` | Martine | f, cel wieku ok. 64 | 177 | 0.19 | 0.20 | dostojna, serdeczna |
| `mietek` | Mietek | m, cel wieku ok. 62 | 124 | 0.23 | 0.26 | starszy rzemieślnik |
| `nadia` | Nadia | f, cel wieku ok. 29 | 224 | 0.12 | 0.06 | energiczna piekarka |
| `neighbour_lucyna` | Sąsiadka Lucyny | f, cel wieku ok. 61 | 170 | 0.22 | 0.16 | troskliwa, dyskretna |
| `neighbour_robe` | Sąsiad w szlafroku | m, cel wieku ok. 52 | 135 | 0.29 | 0.19 | zaspany, zirytowany |
| `norbert` | Norbert | m, cel wieku ok. 43 | 147 | 0.17 | 0.10 | zaniepokojony o siostrę |
| `pieter` | Pieter | m, cel wieku ok. 66 | 122 | 0.19 | 0.19 | spokojny opiekun domu |
| `piotr` | Piotr | m, cel wieku ok. 38 | 146 | 0.17 | 0.11 | praktyczny brat |
| `renata` | Renata | f, cel wieku ok. 52 | 218 | 0.16 | 0.13 | szybka i rezolutna właścicielka pizzerii |
| `stranger` | Mężczyzna w garniturze | m, cel wieku ok. 39 | 132 | 0.10 | 0.08 | grzeczny, naciskający |
| `teresa` | Teresa | f, cel wieku ok. 68 | 174 | 0.22 | 0.19 | serdeczna, powściągliwa |
| `tomasz` | Tomasz | m, cel wieku ok. 37 | 141 | 0.17 | 0.11 | cierpliwy stolarz, ojciec Hani |
| `waldek` | Waldek | m, cel wieku ok. 59 | 121 | 0.18 | 0.21 | rzeczowy sąsiad |
| `wanda` | Wanda | f, cel wieku ok. 63 | 165 | 0.16 | 0.16 | konkretna zarządczyni kamienicy |
| `zbyszek` | Zbyszek | m, cel wieku ok. 74 | 114 | 0.29 | 0.26 | starszy działkowiec, pogodny |

## Matryca ośmiu ekspresji

| Plik | Emocja | Kontur (półtony) | Barwa | Liczba wydechów |
|---|---|---|---|---:|
| `greeting.wav` | greeting | (0, 2, 0) | m | 1 |
| `surprise.wav` | surprise | (0, 5, 3) | a | 1 |
| `relief.wav` | relief | (2, 0, -3) | u | 1 |
| `thanks.wav` | thanks | (0, 2, -1) | o | 2 |
| `impatient.wav` | impatient | (1, -1, -3) | m | 2 |
| `sad.wav` | sad | (0, -2, -5) | u | 1 |
| `laugh.wav` | laugh | (1, 3, 0) | a | 4 |
| `goodbye.wav` | goodbye | (1, 0, -3) | o | 1 |

### Powtarzalność

Ziarno szumu zależy wyłącznie od indeksów postaci i emocji. Formanty zależą od rejestru oraz indywidualnych przesunięć. F0 jest modulowane wibratem i lekką nieregularnością (wiek/charakter). Zawartość nie zawiera słów ani próbek osób rzeczywistych.
