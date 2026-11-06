# Zlecenie G24: 5 portretów nowych postaci (rozdziały 9–12, T43)

**Dla:** ChatGPT z generatorem obrazów. Repo `woogitsugames/lockwright`, ale **nie musisz nic wypychać**. Oddaj ZIP właścicielowi.

## Najważniejsze zasady pracy
1. **Jeden obraz na jedną wiadomość.** Generuj po kolei, w osobnych wiadomościach. **Nigdy** nie rób kolaży, arkuszy, „asset packów” ani kilku kadrów obok siebie.
2. Każdy obraz to **jedno zdjęcie** opisane w prompcie: bez napisów, logo, ramek, podpisów i znaków wodnych.
3. Wszystkie osoby są **wymyślone** i nie mogą przypominać nikogo znanego. To zwykli sąsiedzi z miasta w grze o ślusarzu, który pomaga ludziom (ton ciepły, codzienny; zero estetyki „włamywacza”, zero kostiumów).
4. Rozmiar **1024×1024** (kwadrat). Twarz mniej więcej na środku, głowa i ramiona, trochę luzu nad głową (gra przycina do koła/kwadratu 256 px i do miniatury 48 dp — twarz musi być czytelna w małej skali).
5. Styl jak dotychczasowe portrety epizodyczne (G09/G21): realistyczne zdjęcie, ciepłe miękkie światło klatki schodowej starej kamienicy, rozmyte tło, naturalna skóra. **Bez** sepii, filtrów „vintage”, neonów i mocnego bokehu.
6. Gdy obraz wyjdzie źle (kolaż, napis, dziwne dłonie, dwie osoby), powtórz ten sam prompt. Gdy coś zostanie zablokowane, pomiń to i zapisz w raporcie.

## Wspólny początek (wklej przed każdym opisem)
```
Square realistic photo portrait, head and shoulders, of an invented ordinary person, standing in an old tenement stairwell with warm soft daylight and a softly blurred background. Natural skin, calm friendly expression, eye-level camera. One person only. No text, no logos, no frames.
```

## Obrazy (5 sztuk, w tej kolejności)
Opisy na podstawie `contrib/gpt/T63/portrait_prompts.csv` (po przeglądzie: usunięte „consistent with the existing Lockwright portraits” — generator nie zna gry; dodany wiek i nastrój z charakteru postaci, przedmiot w kadrze tylko gdy mieści się w ujęciu głowa–ramiona).

1. **`portrait_celina.png`** (Celina, 44, kierowniczka remontu, konkretna):
   `Woman, about 44, short dark hair with one grey streak, olive work jacket, holding a canvas-covered notebook at chest height, focused and decisive but kind.`
2. **`portrait_dorota.png`** (Dorota, 49, właścicielka mieszkania, niecierpliwa, nie agresywna):
   `Woman, about 49, straight shoulder-length brown hair, beige coat, a burgundy ring binder under her arm, slightly impatient polite half-smile.`
3. **`portrait_seweryn.png`** (Seweryn, 61, instruktor plastyki, cierpliwy):
   `Man, about 61, short silver beard, round matte-frame glasses, linen apron with a small blue paint stain over a plain shirt, gentle patient smile.`
4. **`portrait_borys.png`** (Borys, 46, renowator rowerów, autoironiczny):
   `Man, about 46, shaved head, thick eyebrows, navy work shirt with rolled-up sleeves, a faint smudge of bicycle grease on one forearm, wry good-humoured smile.`
5. **`portrait_alicja.png`** (Alicja, 40, sprzedawczyni ceramiki, energiczna):
   `Woman, about 40, black curly hair tied up high, brick-red knitted sweater, a linen tote bag on her shoulder with a cloth sticking out, lively bright smile.`

(Opcjonalnie) 6. druga wersja najlepszego obrazu z dopiskiem `_alt`.

## Oddanie
ZIP `Lockwright_G24.zip` o strukturze `contrib/gpt/G24/images/<nazwa>.png` oraz:
- `ASSETS.md`: przy każdym pliku narzędzie, data, pełny użyty prompt (wspólny początek + opis) i czy był edytowany (D-42);
- `README.md` po polsku: co powstało, czego nie udało się zrobić i dlaczego.

## Dla sesji A (integracja, nie dla ChatGPT)
- Konwersja: `game/assets/ui/gpt/cast/episodic/portrait_<id>.webp`, 256×256, jak istniejące (np. `portrait_janka.webp`), `.import` force-add, wpis w `docs/ASSETS.md`.
- Do czasu dostawy gra pokazuje tabliczkę z inicjałem (`job_arrival.gd` → `initial_plate`), bez błędów; `test_t43_jobs.gd` i `test_ui_layout.gd` to tolerują.
- Janka, Leon, Mila i Oskar mają już portrety z G21; Elżbieta z G20.
