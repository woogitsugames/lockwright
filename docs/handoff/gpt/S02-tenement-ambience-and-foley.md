# Zlecenie S02 — Dźwięki otoczenia i foley kamienicy

**Dla:** ChatGPT z dostępem do GitHuba (jedna sesja = jedno zlecenie).
**Repo:** `woogitsugames/lockwright` (GitHub), gałąź `main`.
**Twój katalog (jedyny, w którym zapisujesz):** `contrib/gpt/S02/`
**Czas:** jedna sesja; oddaj, gdy spełnisz „Kryteria odbioru”.

## 1. O projekcie (przeczytaj, zanim zaczniesz)
**Lockwright** (PL: „Lockwright: Pogotowie Zamkowe”, EN w sklepach: „Lockwright: Locksmith on Call”) to mobilna gra premium (iOS, Android, silnik Godot 4.7). Gracz jest **legalnym ślusarzem z pogotowia zamkowego**: otwiera zamki ludziom zatrzaśniętym za drzwiami w starej kamienicy. Zawsze najpierw sprawdza prawo do lokalu (dokument, sąsiad, zarządca), a czasem grzecznie odmawia. Sterowanie: lewy kciuk dawkuje napięcie napinacza, prawy prowadzi wytrych. Sednem są wyczucie, dźwięk i haptyka. Wygląd: **maksymalny fotorealizm** (proceduralne modele w Blenderze, światło ciepłej żarówki z klatki schodowej i chłodnego okna), interfejs **diegetyczny**, czyli bez pływających paneli: życia to wytrychy w skórzanej zwijce, napięcie widać po kącie napinacza.

Przeczytaj w repo (wystarczy szybko): `CLAUDE.md`, `docs/styles/realizm.md`, `docs/DESIGN.md` (kod stanów i zakazy), `docs/HUD.md`, `docs/FEEL.md`, `audio/v2/README.md` (format dźwięków w grze).

## 2. Zasady obowiązkowe
- **Ton:** ciepły, spokojny, trochę suchego humoru, legalny. Pomagamy ludziom. **Zero estetyki złodzieja** (kominiarki, łomy, „włam”, noc + latarka jako motyw przestępstwa).
- **Mechanizmy wymyślone, bez marek.** Zero nazw producentów zamków, samochodów i narzędzi. Zero logotypów, zero czytelnych napisów firm na przedmiotach. Zero instrukcji do realnych, nazwanych produktów.
- **Zakazane klisze wizualne:** gradienty fiolet-niebieski i teal-orange, glassmorphism, neon, bloom na metalu, chrom, karty w stylu SaaS, emoji jako ikony, „Welcome!”/„Get Started”, dziurka od klucza na czarnym tle, złota kłódka na ciemnym tle, złoty blask na pinie, zielony ptaszek / czerwony X, pasek wytrzymałości, szare muzeum, pastisz (sepia, steampunk z martwymi zębatkami, faktury ze stocku).
- **Nie kopiuj** grafik, nazw, UI ani muzyki innych gier i firm. Żadnych prawdziwych osób (portrety to fikcyjne postaci).
- **Teksty:** zawsze PL i EN. Bez nadmiaru wykrzykników.
- **Grafiki i dźwięki generowane przez AI są dozwolone** (decyzja właściciela D-41), ale każdy plik musi mieć wpis w `contrib/gpt/S02/ASSETS.md`: nazwa pliku, narzędzie (np. generator obrazów ChatGPT), data, pełny prompt, licencja/warunki narzędzia, czy był edytowany.
- **Nie zmieniaj niczego poza `contrib/gpt/S02/`.** Inne katalogi należą do innych zespołów (sesje A, B, C). Uwagi do nich wpisz do swojego `README.md`.

## 3. Zadanie
Przygotuj **foley i tła** (nagrania własne, synteza lub generator AI; opisz metodę):
- kroki po drewnianych schodach i po lastryko (po 8 wariantów), stuk do drzwi (6 wariantów: nieśmiały, stanowczy, „policja” bez syren), dzwonek mieszkania (3 wymyślone, stare), klik włącznika światła na minutnik i jego tykanie, gaśnięcie żarówki;
- tła 60 s bezszwowe: klatka schodowa w dzień (daleki pies, radio za ścianą bez rozpoznawalnej muzyki), wieczór, noc (cisza, kapanie), podwórko z deszczem, warsztat (tykający zegar, przejeżdżający tramwaj w oddali);
- otwieranie drzwi: skrzypienie zawiasów (5 wariantów), szczęk klamki.
Format: WAV 48 kHz 24-bit (mono dla foley, stereo dla teł), onset ≤ 5 ms od początku pliku dla foley, normalizacja –18 LUFS tła, –12 dBFS peak foley.

## 4. Jak oddać
1. Wszystkie pliki zapisz w `contrib/gpt/S02/` (podkatalogi dowolne). Pliki binarne do 20 MB sztuka; jeśli większe, zmniejsz.
2. Utwórz `contrib/gpt/S02/README.md` z raportem **po polsku**: co zrobiłeś, lista plików z krótkim opisem, co się nie udało, propozycje.
3. Utwórz `contrib/gpt/S02/ASSETS.md` (jeśli są grafiki, dźwięki lub inne zasoby), jak w zasadach wyżej.
4. **Commit bezpośrednio na `main`**, tylko pliki z Twojego katalogu. Wiadomość commita po angielsku: `contrib/gpt/S02: <krótki opis>`. Nie zmieniaj historii, nie rób force-push.
5. Jeśli nie możesz pisać do `main`, utwórz gałąź `gpt/S02` i otwórz pull request do `main` z tytułem `contrib/gpt/S02: Tenement ambience and foley`.
6. Na koniec napisz w czacie: „Oddane: S02” i link do commita lub PR.

## 5. Kryteria odbioru
- Min. 40 plików + README z listą i metodą.
- Brak rozpoznawalnej muzyki, głosów z czytelnymi słowami i znaków firmowych.
- Wpisy w `ASSETS.md`.
