# Paczka GPT10 dla ChatGPT (G10A–G10D), 2026-11-08

Zastępuje niewykonane zlecenia z `docs/handoff/gpt8/PACZKA-50-ZLECEN.md` (T75–T124) i anuluje G26
(`docs/handoff/gpt9/`). Właściciel zdecydował, że widmo dłoni znika (D-83, podpowiedzi samą kredą).
Większość T75–T124 zrobiły w międzyczasie sesje Claude, więc **nie rób T75–T124 ani G26**.

## Repo i zasady (twarde)
- Repo `woogitsugames/lockwright`, gałąź `main`. **Wypchnij wszystko na GitHub sam**: każde zlecenie
  to osobny commit, wiadomość zaczyna się od ID, np. `G10A: rozdział 13, zlecenia 1–5 [skip ci]`.
  Zawsze dodawaj `[skip ci]` na końcu pierwszej linii.
- **Zapis tylko do `contrib/gpt/<ID>/`** (np. `contrib/gpt/G10A/`). Nie zmieniaj niczego w `game/`,
  `docs/`, `lockcore/`, `.github/`. Integrację do gry robi sesja Claude (koordynator).
- Każdy katalog ma `README.md` po polsku: co zrobione, decyzje, wątpliwości, czego nie zrobiłeś.
- Przed pushem `git pull --rebase origin main`. Nie przepisuj historii (bez `--force`).
- Zasady treści: `CLAUDE.md`. Ton ciepły i legalny: ślusarz pomaga i weryfikuje prawo do lokalu,
  nie włamuje się. Zero marek zamków, samochodów i sklepów, zero instrukcji do prawdziwych produktów.
  PL „pin” (słowo „kołek” tylko dla drewnianego/egipskiego). EN pisownia amerykańska (*neighbor*).
- Teksty zawsze w 5 językach: `en,pl,de,fr,es`. Ślusarz jest mężczyzną (formy „pan”, D-59).
- Grafiki: jeden obraz = jedna wiadomość/odpowiedź (bez kolaży), bez napisów i znaków wodnych,
  w README zapisz prompt dla każdego pliku (wymóg D-42).

---

## G10A — Rozdział 13: 10 nowych zleceń (najważniejsze)
Cel: pierwsza paczka treści do pobrania (D-99). Gra ma rozdziały 1–12 i 83 zlecenia.
- **Format:** jeden plik `contrib/gpt/G10A/jobs/job.<id>.json` na zlecenie, **dokładnie** w schemacie
  plików z `game/data/jobs/` (przykłady w ZIP: `examples/jobs/*.json`). Wymagane pola: `id`, `chapter`
  (13), `district`, `family`, `tier`, `verification` (opis po polsku), `reward_coins`, `tone`, `i18n`,
  `lines` (2–4 mówców po kolei, `locksmith` to ślusarz), `after` (1 mówca), `cards`, `threshold`,
  `place`, `time`. `card_detail` dodaj, gdy karta ma konkretne fakty (imię na dowodzie, rodzaj pisma).
- **Teksty:** `contrib/gpt/G10A/content.csv` w formacie `game/i18n/content.csv` (`keys,en,pl,de,fr,es`).
  Dla każdego zlecenia: `.title`, `.client`, `.situation`, `.line.1…N` (tyle, ile mówców w `lines`),
  `.after.1`, nazwa rozdziału `chapter.13.name` i `chapter.13.desc`.
- **Rodziny zamków:** tylko spośród grywalnych: `pin_tumbler, warded, wafer, lever, lever_detector,
  dial_safe, combo, magnetic, dimple, disc_detainer, egyptian, time_lock, axial_slider`. Wymieszaj je,
  maks. 2 zlecenia z tej samej rodziny. Tier 2–4 (rozdział 13 jest po 12).
- **Miejsca (`place`):** `apartment, gate, cellar, locker, workshop, kiosk, attic, yard, museum`.
  Pora (`time`): `day, evening, night`.
- **Karty weryfikacji (`cards`):** typy używane w grze: `id, lease, manager, witness, institution,
  invoice, receipt, deed, inheritance, resolution, letter, photo, address_app`. Kwestie rozmowy muszą
  zgadzać się z kartami (np. nie mów „na dowodzie nie ma adresu”, jeśli karta pokazuje adres). Co
  najmniej 2 z 10 zleceń to **odmowy** (`id` zaczyna się od `job.refuse_`): klient nie ma prawa do
  lokalu, ślusarz uprzejmie odmawia (wzorce w `docs/CLIENTS.md` §4, nie powtarzaj starych motywów).
- **Obsada:** możesz użyć stałych postaci (Halina, Stefan, Roman, Lena, Marta, Zuzanna, Edek, Ola i
  Krystyna, Władysław, Kazimierz, Teresa; opisy w `docs/CLIENTS.md`) albo dodać maks. 3 nowe postaci
  epizodyczne. Każdą nową opisz w README (wiek, charakter, sposób mówienia, płeć dla głosu).
- **Ciągłość:** rozdział 13 dzieje się wiosną, po finale rozdziału 12 („Miejsce przy stole”).
  Sprawdź imiona, dzielnice i fakty z rozdziałów 1–12 (`content.csv` w ZIP).
- **Długości:** `title` ≤ 32 znaki, `client` ≤ 40, `situation` ≤ 140, kwestie ≤ 160 (FR/DE też).
- Uruchom `python contrib/gpt/validate_v2_localizations.py contrib/gpt/G10A/content.csv`, jeśli
  działa z tym plikiem, i wpisz wynik do README.

## G10B — Pełne sylwetki 6 stałych klientów do scenek przyjazdu
Scenki przyjazdu mają dziś sylwetki tylko Kazimierza i Teresy (`examples/figures/*.png` w ZIP: wzór).
- Postaci: Halina, Stefan, Roman, Lena, Zuzanna, Edek. Referencja twarzy i stroju: ich portret
  (`examples/cast/<nr>_<imię>/portrait.jpg`). Twarz, wiek i strój mają się zgadzać z portretem.
- Kadr: **cała postać od czubka głowy do butów**, stoi swobodnie, lekko bokiem (¾), patrzy w bok lub
  na coś w dłoni, ręce widoczne. Pion, ok. 1024×1536, postać zajmuje ~85% wysokości.
- Tło: **jednolite jasnoszare, bez cieni na tle i bez podłogi** (wycinamy je u siebie). Światło ciepłe,
  miękkie, z góry z lewej, jak w kamienicy nocą.
- Styl: fotografia, naturalne proporcje i skóra, realne ubrania (bez logo). Bez napisów i bez rekwizytów,
  które zasłaniają nogi.
- Pliki: `contrib/gpt/G10B/<imię>.png`, po 2 warianty pozy na postać (`<imię>_a.png`, `<imię>_b.png`).
  Jeden obraz na odpowiedź.

## G10C — Korekta native DE/FR/ES nowych tekstów
Lista 177 kluczy dodanych lub zmienionych 7–8 listopada: `G10C-keys.txt` (w ZIP, razem z pełnymi
`strings.csv` i `content.csv`).
- Sprawdź DE, FR i ES: naturalność, rejestr (du/tu/tú jak w reszcie gry — sprawdź istniejące klucze),
  zgodność z PL, rodzaj gramatyczny, długość w UI (nie dłużej niż obecny tekst w danym języku +15%).
- Wynik: `contrib/gpt/G10C/fixes.csv` (`key,lang,old,new,reason`) — tylko zmiany, i `README.md`.
- **Nie zmieniaj kluczy z nagranym głosem** (`job.*.line.*`, `job.*.after.*`, `job.*.wrong_open.*`),
  chyba że to rażący błąd; wtedy oznacz w `reason`: `VOICED`.

## G10D — Dokumenty dla testów zamkniętych (nie marketing)
- `contrib/gpt/G10D/FAQ.md` (PL i EN): sterowanie dwoma kciukami i automatyczne napięcie, podpowiedzi
  kredą, haptyka, pobieranie głosów (EN w grze, inne języki pobierane), profil jakości, dostępność
  (TalkBack, ograniczenie ruchu, większy tekst), prywatność (bez reklam i śledzenia — sprawdź w
  `docs/` czy tak jest, nie zgaduj).
- `contrib/gpt/G10D/TEST-PLAN.md`: plan testu z 5–8 graczami (scenariusz 45 min, zadania, co
  obserwować, metryki: czas pierwszego otwarcia zamka, porzucenia, użycie podpowiedzi).
- `contrib/gpt/G10D/SURVEY.md`: ankieta po teście, 10 pytań (skala 1–5 + 3 otwarte), PL i EN.

## Kolejność i raport
G10A → G10C → G10B → G10D. Po każdym zleceniu commit i push. Na końcu krótki raport w
`contrib/gpt/G10-REPORT.md`: co zrobione, ile plików, otwarte pytania do właściciela.
