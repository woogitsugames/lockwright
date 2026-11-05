# Zlecenie T05 — Zgodność z zasadami sklepów

**Dla:** ChatGPT z dostępem do GitHuba (jedna sesja = jedno zlecenie).
**Repo:** `woogitsugames/lockwright` (GitHub), gałąź `main`.
**Twój katalog (jedyny, w którym zapisujesz):** `contrib/gpt/T05/`
**Czas:** jedna sesja; oddaj, gdy spełnisz „Kryteria odbioru”.

## 1. O projekcie (przeczytaj, zanim zaczniesz)
**Lockwright** (PL: „Lockwright: Pogotowie Zamkowe”, EN w sklepach: „Lockwright: Locksmith on Call”) to mobilna gra premium (iOS, Android, silnik Godot 4.7). Gracz jest **legalnym ślusarzem z pogotowia zamkowego**: otwiera zamki ludziom zatrzaśniętym za drzwiami w starej kamienicy. Zawsze najpierw sprawdza prawo do lokalu (dokument, sąsiad, zarządca), a czasem grzecznie odmawia. Sterowanie: lewy kciuk dawkuje napięcie napinacza, prawy prowadzi wytrych. Sednem są wyczucie, dźwięk i haptyka. Wygląd: **maksymalny fotorealizm** (proceduralne modele w Blenderze, światło ciepłej żarówki z klatki schodowej i chłodnego okna), interfejs **diegetyczny**, czyli bez pływających paneli: życia to wytrychy w skórzanej zwijce, napięcie widać po kącie napinacza.

Przeczytaj w repo (wystarczy szybko): `CLAUDE.md`, `docs/styles/realizm.md`, `docs/DESIGN.md` (kod stanów i zakazy), `docs/HUD.md`, `store/listing.md`, `store/privacy.md`, `docs/COMPLIANCE-AUDIT.md`.

## 2. Zasady obowiązkowe
- **Ton:** ciepły, spokojny, trochę suchego humoru, legalny. Pomagamy ludziom. **Zero estetyki złodzieja** (kominiarki, łomy, „włam”, noc + latarka jako motyw przestępstwa).
- **Mechanizmy wymyślone, bez marek.** Zero nazw producentów zamków, samochodów i narzędzi. Zero logotypów, zero czytelnych napisów firm na przedmiotach. Zero instrukcji do realnych, nazwanych produktów.
- **Zakazane klisze wizualne:** gradienty fiolet-niebieski i teal-orange, glassmorphism, neon, bloom na metalu, chrom, karty w stylu SaaS, emoji jako ikony, „Welcome!”/„Get Started”, dziurka od klucza na czarnym tle, złota kłódka na ciemnym tle, złoty blask na pinie, zielony ptaszek / czerwony X, pasek wytrzymałości, szare muzeum, pastisz (sepia, steampunk z martwymi zębatkami, faktury ze stocku).
- **Nie kopiuj** grafik, nazw, UI ani muzyki innych gier i firm. Żadnych prawdziwych osób (portrety to fikcyjne postaci).
- **Teksty:** zawsze PL i EN. Bez nadmiaru wykrzykników.
- **Grafiki i dźwięki generowane przez AI są dozwolone** (decyzja właściciela D-41), ale każdy plik musi mieć wpis w `contrib/gpt/T05/ASSETS.md`: nazwa pliku, narzędzie (np. generator obrazów ChatGPT), data, pełny prompt, licencja/warunki narzędzia, czy był edytowany.
- **Nie zmieniaj niczego poza `contrib/gpt/T05/`.** Inne katalogi należą do innych zespołów (sesje A, B, C). Uwagi do nich wpisz do swojego `README.md`.

## 3. Zadanie
Zrób **przegląd zgodności z wytycznymi App Store Review Guidelines i Google Play Developer Policy** dla gry o otwieraniu zamków: czy temat może być uznany za „ułatwianie przestępstwa”, jak notka „to gra, nie kurs” i weryfikacja prawa do lokalu pomagają, jak opisać grę w sklepie, rating (IARC/Apple: przemoc? hazard? brak), prywatność dzieci (jeśli gra może trafić do młodszych), zakupy (model jeszcze nieustalony: opisz warianty premium / demo + odblokowanie). Podaj konkretne punkty wytycznych (numery) i ryzyka.
Oddaj `STORE-POLICY.md`: ryzyka (wysokie/średnie/niskie), rekomendowane zmiany w tekstach i w grze, lista kontrolna przed wysłaniem do recenzji. Na górze: „to nie jest porada prawna”.

## 4. Jak oddać
1. Wszystkie pliki zapisz w `contrib/gpt/T05/` (podkatalogi dowolne). Pliki binarne do 20 MB sztuka; jeśli większe, zmniejsz.
2. Utwórz `contrib/gpt/T05/README.md` z raportem **po polsku**: co zrobiłeś, lista plików z krótkim opisem, co się nie udało, propozycje.
3. Utwórz `contrib/gpt/T05/ASSETS.md` (jeśli są grafiki, dźwięki lub inne zasoby), jak w zasadach wyżej.
4. **Commit bezpośrednio na `main`**, tylko pliki z Twojego katalogu. Wiadomość commita po angielsku: `contrib/gpt/T05: <krótki opis>`. Nie zmieniaj historii, nie rób force-push.
5. Jeśli nie możesz pisać do `main`, utwórz gałąź `gpt/T05` i otwórz pull request do `main` z tytułem `contrib/gpt/T05: Store policy review`.
6. Na koniec napisz w czacie: „Oddane: T05” i link do commita lub PR.

## 5. Kryteria odbioru
- Każde ryzyko z odnośnikiem do wytycznej.
- Lista kontrolna ≥ 20 punktów.
