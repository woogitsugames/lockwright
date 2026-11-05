# Zlecenie G03 — Faktury drewna drzwi i ramiaków

**Dla:** ChatGPT z dostępem do GitHuba (jedna sesja = jedno zlecenie).
**Repo:** `woogitsugames/lockwright` (GitHub), gałąź `main`.
**Twój katalog (jedyny, w którym zapisujesz):** `contrib/gpt/G03/`
**Czas:** jedna sesja; oddaj, gdy spełnisz „Kryteria odbioru”.

## 1. O projekcie (przeczytaj, zanim zaczniesz)
**Lockwright** (PL: „Lockwright: Pogotowie Zamkowe”, EN w sklepach: „Lockwright: Locksmith on Call”) to mobilna gra premium (iOS, Android, silnik Godot 4.7). Gracz jest **legalnym ślusarzem z pogotowia zamkowego**: otwiera zamki ludziom zatrzaśniętym za drzwiami w starej kamienicy. Zawsze najpierw sprawdza prawo do lokalu (dokument, sąsiad, zarządca), a czasem grzecznie odmawia. Sterowanie: lewy kciuk dawkuje napięcie napinacza, prawy prowadzi wytrych. Sednem są wyczucie, dźwięk i haptyka. Wygląd: **maksymalny fotorealizm** (proceduralne modele w Blenderze, światło ciepłej żarówki z klatki schodowej i chłodnego okna), interfejs **diegetyczny**, czyli bez pływających paneli: życia to wytrychy w skórzanej zwijce, napięcie widać po kącie napinacza.

Przeczytaj w repo (wystarczy szybko): `CLAUDE.md`, `docs/styles/realizm.md`, `docs/DESIGN.md` (kod stanów i zakazy), `docs/HUD.md`, `art/renders/section.png` (drzwi za wkładką), `docs/styles/realizm.md`.

## 2. Zasady obowiązkowe
- **Ton:** ciepły, spokojny, trochę suchego humoru, legalny. Pomagamy ludziom. **Zero estetyki złodzieja** (kominiarki, łomy, „włam”, noc + latarka jako motyw przestępstwa).
- **Mechanizmy wymyślone, bez marek.** Zero nazw producentów zamków, samochodów i narzędzi. Zero logotypów, zero czytelnych napisów firm na przedmiotach. Zero instrukcji do realnych, nazwanych produktów.
- **Zakazane klisze wizualne:** gradienty fiolet-niebieski i teal-orange, glassmorphism, neon, bloom na metalu, chrom, karty w stylu SaaS, emoji jako ikony, „Welcome!”/„Get Started”, dziurka od klucza na czarnym tle, złota kłódka na ciemnym tle, złoty blask na pinie, zielony ptaszek / czerwony X, pasek wytrzymałości, szare muzeum, pastisz (sepia, steampunk z martwymi zębatkami, faktury ze stocku).
- **Nie kopiuj** grafik, nazw, UI ani muzyki innych gier i firm. Żadnych prawdziwych osób (portrety to fikcyjne postaci).
- **Teksty:** zawsze PL i EN. Bez nadmiaru wykrzykników.
- **Grafiki i dźwięki generowane przez AI są dozwolone** (decyzja właściciela D-41), ale każdy plik musi mieć wpis w `contrib/gpt/G03/ASSETS.md`: nazwa pliku, narzędzie (np. generator obrazów ChatGPT), data, pełny prompt, licencja/warunki narzędzia, czy był edytowany.
- **Nie zmieniaj niczego poza `contrib/gpt/G03/`.** Inne katalogi należą do innych zespołów (sesje A, B, C). Uwagi do nich wpisz do swojego `README.md`.

## 3. Zadanie
Agent od grafiki w Blenderze ma problem z drewnem: wygląda jak regularne pasy albo plastik. Przygotuj **bezszwowe faktury drewna drzwi** z kamienicy:
- dąb lakierowany satynowo (stary, z patyną i drobnymi rysami), dąb malowany kryjąco farbą olejną w kolorze butelkowej zieleni z przetarciami do drewna, sosna malowana na kremowo z łuszczącą się farbą, orzech ciemny (drzwi lepszego mieszkania).
- Dla każdego: albedo 2048×2048 (bez cieni), height, roughness (jeśli możliwe). Słoje nieregularne, deski o różnym odcieniu, pory, ślady pędzla w farbie.
- Dodatkowo: 2 obrazy referencyjne (nie faktury) „idealne zbliżenie dębowych drzwi z szyldem i wkładką” w świetle ciepłej żarówki, bez marek, jako wzór dla agenta Blendera.

## 4. Jak oddać
1. Wszystkie pliki zapisz w `contrib/gpt/G03/` (podkatalogi dowolne). Pliki binarne do 20 MB sztuka; jeśli większe, zmniejsz.
2. Utwórz `contrib/gpt/G03/README.md` z raportem **po polsku**: co zrobiłeś, lista plików z krótkim opisem, co się nie udało, propozycje.
3. Utwórz `contrib/gpt/G03/ASSETS.md` (jeśli są grafiki, dźwięki lub inne zasoby), jak w zasadach wyżej.
4. **Commit bezpośrednio na `main`**, tylko pliki z Twojego katalogu. Wiadomość commita po angielsku: `contrib/gpt/G03: <krótki opis>`. Nie zmieniaj historii, nie rób force-push.
5. Jeśli nie możesz pisać do `main`, utwórz gałąź `gpt/G03` i otwórz pull request do `main` z tytułem `contrib/gpt/G03: Door wood textures`.
6. Na koniec napisz w czacie: „Oddane: G03” i link do commita lub PR.

## 5. Kryteria odbioru
- 4 zestawy faktur + 2 referencje + podglądy 2×2.
- Drewno wygląda jak prawdziwe (nieregularne słoje), nie jak paski.
- Wpisy w `ASSETS.md`.
