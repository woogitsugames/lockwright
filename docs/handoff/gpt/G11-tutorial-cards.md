# Zlecenie G11 — Kartki samouczka

**Dla:** ChatGPT z dostępem do GitHuba (jedna sesja = jedno zlecenie).
**Repo:** `woogitsugames/lockwright` (GitHub), gałąź `main`.
**Twój katalog (jedyny, w którym zapisujesz):** `contrib/gpt/G11/`
**Czas:** jedna sesja; oddaj, gdy spełnisz „Kryteria odbioru”.

## 1. O projekcie (przeczytaj, zanim zaczniesz)
**Lockwright** (PL: „Lockwright: Pogotowie Zamkowe”, EN w sklepach: „Lockwright: Locksmith on Call”) to mobilna gra premium (iOS, Android, silnik Godot 4.7). Gracz jest **legalnym ślusarzem z pogotowia zamkowego**: otwiera zamki ludziom zatrzaśniętym za drzwiami w starej kamienicy. Zawsze najpierw sprawdza prawo do lokalu (dokument, sąsiad, zarządca), a czasem grzecznie odmawia. Sterowanie: lewy kciuk dawkuje napięcie napinacza, prawy prowadzi wytrych. Sednem są wyczucie, dźwięk i haptyka. Wygląd: **maksymalny fotorealizm** (proceduralne modele w Blenderze, światło ciepłej żarówki z klatki schodowej i chłodnego okna), interfejs **diegetyczny**, czyli bez pływających paneli: życia to wytrychy w skórzanej zwijce, napięcie widać po kącie napinacza.

Przeczytaj w repo (wystarczy szybko): `CLAUDE.md`, `docs/styles/realizm.md`, `docs/DESIGN.md` (kod stanów i zakazy), `docs/HUD.md`, `docs/ONBOARDING.md`, `mockups/realizm/png/06-tutorial-s1.portrait.png`, `07-tutorial-s2.portrait.png`.

## 2. Zasady obowiązkowe
- **Ton:** ciepły, spokojny, trochę suchego humoru, legalny. Pomagamy ludziom. **Zero estetyki złodzieja** (kominiarki, łomy, „włam”, noc + latarka jako motyw przestępstwa).
- **Mechanizmy wymyślone, bez marek.** Zero nazw producentów zamków, samochodów i narzędzi. Zero logotypów, zero czytelnych napisów firm na przedmiotach. Zero instrukcji do realnych, nazwanych produktów.
- **Zakazane klisze wizualne:** gradienty fiolet-niebieski i teal-orange, glassmorphism, neon, bloom na metalu, chrom, karty w stylu SaaS, emoji jako ikony, „Welcome!”/„Get Started”, dziurka od klucza na czarnym tle, złota kłódka na ciemnym tle, złoty blask na pinie, zielony ptaszek / czerwony X, pasek wytrzymałości, szare muzeum, pastisz (sepia, steampunk z martwymi zębatkami, faktury ze stocku).
- **Nie kopiuj** grafik, nazw, UI ani muzyki innych gier i firm. Żadnych prawdziwych osób (portrety to fikcyjne postaci).
- **Teksty:** zawsze PL i EN. Bez nadmiaru wykrzykników.
- **Grafiki i dźwięki generowane przez AI są dozwolone** (decyzja właściciela D-42), ale każdy plik musi mieć wpis w `contrib/gpt/G11/ASSETS.md`: nazwa pliku, narzędzie (np. generator obrazów ChatGPT), data, pełny prompt, licencja/warunki narzędzia, czy był edytowany.
- **Nie zmieniaj niczego poza `contrib/gpt/G11/`.** Inne katalogi należą do innych zespołów (sesje A, B, C). Uwagi do nich wpisz do swojego `README.md`.


> **WERSJA 2 (po blokadach generatora obrazów).** Generator obrazów ChatGPT odrzuca obrazy, na których narzędzie jest włożone do zamka albo ktoś „otwiera zamek” (traktuje to jako działanie niedozwolone). Dlatego w tym zleceniu:
> - **nie pokazuj** wytrycha ani napinacza włożonego w zamek, dłoni manipulujących przy zamku, przekroju zamka z narzędziem w kanale;
> - w promptach **nie używaj** słów: lockpick, picking, pick the lock, break in, bypass, tension wrench, wytrych, włam;
> - pokazuj zamiast tego: ślusarza jako fachowca w kontakcie z klientem, narzędzia **schowane w zwiniętej skórzanej zwijce**, mosiężną wkładkę lub klucz **same w sobie**, drzwi, tabliczki, światło, warsztat.
> Jeśli mimo to generator odmówi, **narysuj grafikę kodem** (SVG lub Python: Pillow, cairo, matplotlib) i wyrenderuj ją do PNG. Wpisz to w `ASSETS.md` jako „wygenerowane kodem”.

## 3. Zadanie
Samouczek uczy przez **kartki mistrza wsunięte w zwijkę**: prosty szkic plus krótki dopisek. **Nie używaj generatora obrazów do szkiców.** Narysuj je kodem (SVG, a potem PNG przez cairosvg lub Pillow), w stylu szkicu ołówkiem: nierówna linia, lekkie drżenie, szare grafitowe kreski, kreskowanie cieni.

Szkice są **abstrakcyjnymi diagramami gestów i stanów z gry**, nie rysunkami prawdziwych zamków:
- kciuk lewy: kółko odcisku i strzałka „dociśnij i trzymaj” oraz skala nacisku 0–100%;
- kciuk prawy: strzałka „w bok i w górę”;
- „kolumny” z gry: prostokąty w rurce z kreską poziomą (linia podziału);
- stany w znakach z `docs/DESIGN.md` §1: stopka (ustawiony), talia/klepsydra (fałszywe), 3 ukośne kreski (wiąże), klamra (przepchnięty), klin (blisko).

**12 kartek** według etapów S1–S3 z `docs/ONBOARDING.md`. Każda w 3 wersjach: dopisek PL, dopisek EN, bez dopisku. Dopisek pismem odręcznym: font OFL, np. „Caveat” albo „Kalam” z Google Fonts; podaj font w ASSETS.md.

Tło karteczki możesz wygenerować generatorem obrazów jako **pustą** pożółkłą kartkę z bloczka, z pinezką albo bez (bez żadnych zamków na obrazie), albo zrobić proceduralnie.

Do tego pieczątka „TO GRA, NIE KURS. / Mechanizmy są wymyślone.” i EN „THIS IS A GAME, NOT A COURSE. / The mechanisms are invented.”, też kodem: tusz, nierówny odcisk, PNG z alfą.

Format: PNG z alfą, 1200×1500. Dołącz źródła SVG i skrypt.

## 4. Jak oddać
1. Wszystkie pliki zapisz w `contrib/gpt/G11/` (podkatalogi dowolne). Pliki binarne do 20 MB sztuka; jeśli większe, zmniejsz.
2. Utwórz `contrib/gpt/G11/README.md` z raportem **po polsku**: co zrobiłeś, lista plików z krótkim opisem, co się nie udało, propozycje.
3. Utwórz `contrib/gpt/G11/ASSETS.md` (jeśli są grafiki, dźwięki lub inne zasoby), jak w zasadach wyżej.
4. **Commit bezpośrednio na `main`**, tylko pliki z Twojego katalogu. Wiadomość commita po angielsku: `contrib/gpt/G11: <krótki opis>`. Nie zmieniaj historii, nie rób force-push.
5. Jeśli nie możesz pisać do `main`, utwórz gałąź `gpt/G11` i otwórz pull request do `main` z tytułem `contrib/gpt/G11: Tutorial cards`.
6. Na koniec napisz w czacie: „Oddane: G11” i link do commita lub PR.

## 5. Kryteria odbioru
- 12 × 3 kartki + 2 pieczątki + arkusz.
- Szkic zrozumiały bez tekstu (sprawdź na osobie, która nie zna gry, i opisz wynik w README).
- Wpisy w `ASSETS.md`.
