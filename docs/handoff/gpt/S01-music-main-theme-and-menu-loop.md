# Zlecenie S01 — Muzyka: motyw główny i menu

**Dla:** ChatGPT z dostępem do GitHuba (jedna sesja = jedno zlecenie).
**Repo:** `woogitsugames/lockwright` (GitHub), gałąź `main`.
**Twój katalog (jedyny, w którym zapisujesz):** `contrib/gpt/S01/`
**Czas:** jedna sesja; oddaj, gdy spełnisz „Kryteria odbioru”.

## 1. O projekcie (przeczytaj, zanim zaczniesz)
**Lockwright** (PL: „Lockwright: Pogotowie Zamkowe”, EN w sklepach: „Lockwright: Locksmith on Call”) to mobilna gra premium (iOS, Android, silnik Godot 4.7). Gracz jest **legalnym ślusarzem z pogotowia zamkowego**: otwiera zamki ludziom zatrzaśniętym za drzwiami w starej kamienicy. Zawsze najpierw sprawdza prawo do lokalu (dokument, sąsiad, zarządca), a czasem grzecznie odmawia. Sterowanie: lewy kciuk dawkuje napięcie napinacza, prawy prowadzi wytrych. Sednem są wyczucie, dźwięk i haptyka. Wygląd: **maksymalny fotorealizm** (proceduralne modele w Blenderze, światło ciepłej żarówki z klatki schodowej i chłodnego okna), interfejs **diegetyczny**, czyli bez pływających paneli: życia to wytrychy w skórzanej zwijce, napięcie widać po kącie napinacza.

Przeczytaj w repo (wystarczy szybko): `CLAUDE.md`, `docs/styles/realizm.md`, `docs/DESIGN.md` (kod stanów i zakazy), `docs/HUD.md`, `docs/FEEL.md` (dźwięk zamka ma pierwszeństwo; muzyka nie może go zagłuszać).

## 2. Zasady obowiązkowe
- **Ton:** ciepły, spokojny, trochę suchego humoru, legalny. Pomagamy ludziom. **Zero estetyki złodzieja** (kominiarki, łomy, „włam”, noc + latarka jako motyw przestępstwa).
- **Mechanizmy wymyślone, bez marek.** Zero nazw producentów zamków, samochodów i narzędzi. Zero logotypów, zero czytelnych napisów firm na przedmiotach. Zero instrukcji do realnych, nazwanych produktów.
- **Zakazane klisze wizualne:** gradienty fiolet-niebieski i teal-orange, glassmorphism, neon, bloom na metalu, chrom, karty w stylu SaaS, emoji jako ikony, „Welcome!”/„Get Started”, dziurka od klucza na czarnym tle, złota kłódka na ciemnym tle, złoty blask na pinie, zielony ptaszek / czerwony X, pasek wytrzymałości, szare muzeum, pastisz (sepia, steampunk z martwymi zębatkami, faktury ze stocku).
- **Nie kopiuj** grafik, nazw, UI ani muzyki innych gier i firm. Żadnych prawdziwych osób (portrety to fikcyjne postaci).
- **Teksty:** zawsze PL i EN. Bez nadmiaru wykrzykników.
- **Grafiki i dźwięki generowane przez AI są dozwolone** (decyzja właściciela D-41), ale każdy plik musi mieć wpis w `contrib/gpt/S01/ASSETS.md`: nazwa pliku, narzędzie (np. generator obrazów ChatGPT), data, pełny prompt, licencja/warunki narzędzia, czy był edytowany.
- **Nie zmieniaj niczego poza `contrib/gpt/S01/`.** Inne katalogi należą do innych zespołów (sesje A, B, C). Uwagi do nich wpisz do swojego `README.md`.

## 3. Zadanie
Skomponuj **muzykę** do gry (możesz generować narzędziem AI lub zsyntetyzować w Pythonie, np. MIDI + prosty syntezator / sample CC0, opisz metodę):
- motyw główny 60–90 s (ciepły, kameralny: fortepian lub pianino wyciszone filcem, kontrabas pizzicato, szczotki, może klarnet; nastrój „spokojny fachowiec w starym mieście”, bez epickości);
- pętla menu/warsztatu 2–3 min, bezszwowa;
- wersja „w zamku”: bardzo cicha, sama harmonia, bez rytmu i bez wysokich częstotliwości (2–6 kHz zostaw wolne dla klików pinów), pętla 2 min;
- 6 jingli 2–4 s: otwarte drzwi, odmowa (cicha, z godnością), nowy rozdział, nowe narzędzie, eksponat w gablocie, koniec dnia.
Format: WAV 48 kHz 24-bit stereo + OGG; głośność –16 LUFS (pętle), –14 LUFS (jingle). Do każdego pliku MIDI lub partytura, jeśli możliwe.

## 4. Jak oddać
1. Wszystkie pliki zapisz w `contrib/gpt/S01/` (podkatalogi dowolne). Pliki binarne do 20 MB sztuka; jeśli większe, zmniejsz.
2. Utwórz `contrib/gpt/S01/README.md` z raportem **po polsku**: co zrobiłeś, lista plików z krótkim opisem, co się nie udało, propozycje.
3. Utwórz `contrib/gpt/S01/ASSETS.md` (jeśli są grafiki, dźwięki lub inne zasoby), jak w zasadach wyżej.
4. **Commit bezpośrednio na `main`**, tylko pliki z Twojego katalogu. Wiadomość commita po angielsku: `contrib/gpt/S01: <krótki opis>`. Nie zmieniaj historii, nie rób force-push.
5. Jeśli nie możesz pisać do `main`, utwórz gałąź `gpt/S01` i otwórz pull request do `main` z tytułem `contrib/gpt/S01: Music: main theme and menu loop`.
6. Na koniec napisz w czacie: „Oddane: S01” i link do commita lub PR.

## 5. Kryteria odbioru
- Komplet plików + README z metodą i opisem nastroju.
- Pętle są bezszwowe (sprawdź łączenie).
- Wersja „w zamku” ma pusto w 2–6 kHz (załącz spektrogram).
- Pełne warunki licencji narzędzia w `ASSETS.md`.
