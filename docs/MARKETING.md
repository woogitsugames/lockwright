# Lockwright — marketing: zwiastuny, press kit, krótkie wideo, lista renderów

Status: szkic do akceptacji właściciela · 2026-11-05. Nazwy: PL „Lockwright: Pogotowie Zamkowe”, EN w sklepach
„Lockwright: Locksmith on Call” (D-32). Model biznesowy nieustalony (D-06), więc **żaden materiał nie podaje ceny ani
słowa „darmowy/free”**. Teksty sklepowe: `store/listing.md` (właściciel: sesja C), zrzuty: `store/screenshots/PLAN.md`.

## 0. Zasady wspólne dla wszystkich materiałów

**Ton.** Głos ślusarza z `store/listing.md`: spokojny, praktyczny, trochę suchego humoru. Pomagamy komuś, kto stoi pod
własnymi drzwiami. Nie ma tu napadu, sejfu z łupem, kominiarki ani nocnego skradania.

**Zakazane w materiałach** (oprócz listy z `CLAUDE.md` i `docs/DESIGN.md`):
- Frazy-wytrychy: „epicki”, „ultimate”, „najbardziej realistyczny”, „#1”, „rewolucja”, „Unlock your potential”,
  „Get Started”, „Are you ready?”, „Can you crack it?”, odliczanie „3… 2… 1…”, dramatyczny lektor zwiastunowy.
- Twierdzenie „pierwsza gra w ciemności”. Mamy prawo powiedzieć tylko „całą grę da się przejść bez patrzenia”
  (`RESEARCH.md` §1.3: Vale & Daughter ma „Blind mode”).
- Marki zamków, samochodów, telefonów (telefon w kadrze jest bez logo i bez rozpoznawalnej wyspy/aparatu), nazwy konkurentów.
- Cena, „za darmo”, „free”, „sale” (D-06). Obietnice spoza zakresu 1.0 (Tryb Zleceń, wyzwania z timerem), chyba że
  materiał wyraźnie mówi „w przygotowaniu”.
- Instruktaż: nie pokazujemy realnego narzędzia w realnym zamku, nie podajemy kolejności ruchów jako „poradnika”.
  Każdy materiał dłuższy niż 10 s ma na końcu linię „To gra, nie kurs. Zamki są wymyślone.” / „A game, not a course. The locks are invented.”
- Wizualnie: kamera nie trzęsie się „od haptyki”, nie ma bloomu, poświaty, złotego blasku na pinie, zielonego ptaszka,
  dziurki od klucza na czerni, chromu. Ruchy elementów 100–250 ms jak w grze.

**Jak pokazać haptykę, której nie widać w wideo.** Trzy środki, zawsze razem:
1. **Dźwięk** jest nagrany i zmiksowany tak, jak w grze, plus delikatna, niska warstwa (40–90 Hz, -18 dB względem kliku),
   która oddaje „uderzenie w kciuk”. Na telefonie bez słuchawek jej nie słychać i to jest w porządku: ma tylko dopełniać.
2. **Makro** na element, który właśnie „mówi”: pin, szczelina na linii podziału, kąt napinacza.
3. **Napisy opisowe w stylu SDH** (jak dla niesłyszących), w nawiasach kwadratowych, opisujące dźwięk i dotyk:
   `[suchy klik w kciuku]` / `[a dry click under the thumb]`. To jest rozpoznawalny element serii: mówi o czuciu
   uczciwie i jednocześnie robi z napisów funkcję dostępności, nie ozdobnik. Wszystkie materiały mają je włączone na stałe
   (wideo w mediach społecznościowych zwykle gra bez dźwięku).

**Dźwięk.** Bez muzyki z biblioteki. Tło: cisza klatki schodowej (szum żarówki, tyknięcie automatu minutnika, daleki
tramwaj bez rozpoznawalnych komunikatów), potem tylko mechanizm. Ewentualna muzyka: jedna własna, cicha fraza na końcu.
Każdy dźwięk własny albo CC0 i wpisany do `docs/ASSETS.md`.

**Typografia.** Bona Nova Bold (tytuł, podpisy główne), Atkinson Hyperlegible Next (napisy SDH, informacje), oba OFL.
Tekst kredowy `#F1EEE6` na ciepłej prawie-czerni `#14110E` albo bezpośrednio na renderze z lekkim cieniem (bez obrysu
neonowego). Napisy w strefie bezpiecznej: 9:16, margines boczny 7,5%, **górne 14% i dolne 20% kadru wolne** (interfejs
TikToka, Reels i Shorts zasłania te pasy).

**Dwie wersje każdego zwiastuna.**
- **Wersja filmowa** (YouTube, media społecznościowe, prasa, strona): rendery Blendera z §4.
- **Wersja sklepowa** (App Store App Preview, Google Play): Apple wymaga materiału nagranego z aplikacji, więc ta wersja
  powstanie z nagrania ekranu gry, gdy będzie ekran zamka w planie B (D-31). Scenariusz jest ten sam, kadry S1–S2
  i S9 zastępuje nagranie z gry albo się je wycina. Do sprawdzenia przed wysyłką: aktualne rozmiary App Preview
  (pion, 15–30 s) i wymóg Google Play (link do YouTube).

**Język.** Każdy materiał w dwóch osobnych wersjach, PL i EN (nie dwujęzyczne napisy w jednym kadrze). Teksty z tabel
niżej trafią później do plików i18n materiałów (`marketing/i18n/*.json`, gdy powstanie montaż), nie do i18n gry.

---

## 1. Zwiastun 30 s (pion 9:16, 1080 × 1920, master 2160 × 3840, 30 kl./s)

Oś: wezwanie → sprawdzenie → dwa kciuki → pin siada → szpulka kłamie → ciemność → drzwi otwarte bez szkody.
Kadry `R..` odsyłają do listy renderów w §4.

| # | Czas | Obraz (render) | Dźwięk | Tekst PL | Tekst EN |
|---|---|---|---|---|---|
| S1 | 0:00–0:02.5 | Klatka schodowa nocą, drzwi z emaliowaną tabliczką „12”. Automat minutnika zapala żarówkę; powolny najazd na drzwi. (R01) | klak wyłącznika minutnika, brzęczenie żarówki, daleki tramwaj | Ktoś stoi pod drzwiami bez kluczy. | Someone's locked out of their own flat. |
| S2 | 0:02.5–0:05 | Skórzana zwijka rozwija się na wycieraczce: napinacz, trzy wytrychy w kieszeniach, lupa. Widok z góry. (R02) | skóra, metal o metal, cichy brzęk | Dzwonią po ciebie. | You're the one they call. |
| S3 | 0:05–0:07 | Zbliżenie na kartę leżącą na zwijce: koperta z nadrukowanym adresem „ul. … 12/4” (adres wymyślony, nieczytelny poza numerem). (R03) | szelest papieru | Najpierw: czy to na pewno jej mieszkanie. | First: is this really her flat? |
| S4 | 0:07–0:10 | Pełny przekrój wkładki, powolny najazd. Napinacz obraca się o 2°, czoło rdzenia odpowiada. (R04, R05) | niski skrzyp stali, `[napięcie]` | Lewy kciuk napina. `[opór pod kciukiem]` | Left thumb holds tension. `[resistance under the thumb]` |
| S5 | 0:10–0:13 | Wytrych unosi pin trzeci: pin górny przechyla się o 2–3° i drga przy ruchu wytrycha (binding). (R06) | chropawe, suche skrobanie | Prawy szuka. `[chropawe skrobanie]` | Right thumb searches. `[a dry scrape]` |
| S6 | 0:13–0:15 | Makro linii podziału: pin górny siada na krawędzi rdzenia, pod nim otwiera się jasna szczelina (set). Ruch 150 ms. (R07) | krótki, suchy klik + niska warstwa | Klik. Ten siedzi. `[suchy klik w kciuku]` | Click. That one's set. `[a dry click under the thumb]` |
| S7 | 0:15–0:18 | Szpulka: rdzeń obraca się wyraźnie głębiej, talia szpulki stoi na linii podziału (false set). Pauza 0,5 s bez ruchu. (R08) | głębszy, pusty stuk, potem cisza | A ten udaje. `[za łatwo]` | This one's pretending. `[too easy]` |
| S8 | 0:18–0:20 | Napinacz i czoło rdzenia cofają się pod naciskiem (counter-rotate), szpulka przechodzi przez linię. (R09) | miękki, cofający się zgrzyt | Popuść. Poczuj, jak oddaje. | Ease off. Feel it give back. |
| S9 | 0:20–0:24 | Minutnik gaśnie: ten sam przekrój ściemnia się do ok. 5% w 400 ms, potem 2,5 s prawie czerni z ledwie widocznym odblaskiem sprężyny. Dwa kliki w ciemności. (R10) | klak minutnika, cisza, klik, klik | Zgaś światło. Graj dotykiem i słuchem. | Lights out. Play by touch and ear. |
| S10 | 0:24–0:26.5 | Światło wraca: rdzeń obraca się do końca, ryglowanie się cofa; cięcie na drzwi uchylające się do ciepłego wnętrza. (R11, R12) | pełny obrót rdzenia, rygiel, skrzypnięcie drzwi, z mieszkania radio za ścianą | Otwarte. Bez jednej rysy. | Open. Not a scratch. |
| S11 | 0:26.5–0:30 | Plansza końcowa: tytuł na emaliowanej tabliczce na drewnie drzwi (R13). Pod spodem znaczki sklepów (oficjalne, zgodnie z wytycznymi Apple i Google) albo „Wkrótce na iOS i Androida”. | jedna cicha fraza, zamknięcie drzwi | **Lockwright: Pogotowie Zamkowe** · Bez reklam. Działa offline. · To gra, nie kurs. Zamki są wymyślone. | **Lockwright: Locksmith on Call** · No ads. Works offline. · A game, not a course. The locks are invented. |

Uwagi:
- S3 to sygnał „legalny ślusarz” bez obiecywania Trybu Zleceń. Jeśli Tryb Zleceń wejdzie do 1.0, S3 można zastąpić kartą
  weryfikacji z `JOBS.md` §2 (symboliczna karta, nigdy dokument z detalami).
- S9 jest „momentem” zwiastuna: obraz znika, a gra trwa. Montaż nie może go skrócić poniżej 3 s.
- Wersja bez dźwięku musi się bronić samymi napisami SDH; sprawdzić przed publikacją z wyciszonym telefonem.
- Kontrola skali szarości: S5–S8 muszą być rozróżnialne w czerni i bieli (ta sama zasada co A7 w `DESIGN.md`).

## 2. Zwiastun 15 s (pion 9:16, te same parametry)

Krótsza wersja do reklam i Shorts: hak dźwiękiem w pierwszej sekundzie, bez wstępu na klatce.

| # | Czas | Obraz (render) | Dźwięk | Tekst PL | Tekst EN |
|---|---|---|---|---|---|
| T1 | 0:00–0:02 | Makro linii podziału: pin siada (set) od pierwszej klatki. (R07) | suchy klik + niska warstwa | `[suchy klik w kciuku]` | `[a dry click under the thumb]` |
| T2 | 0:02–0:04.5 | Pełny przekrój, wytrych pod pinem trzecim, pin górny drga (binding). (R06) | skrobanie | Lewy kciuk napina, prawy szuka. | Left thumb tensions. Right thumb searches. |
| T3 | 0:04.5–0:07 | Szpulka w false set, rdzeń głębiej, pauza. (R08) | pusty stuk, cisza | A ten kłamie. `[za łatwo]` | This one lies. `[too easy]` |
| T4 | 0:07–0:10 | Ściemnienie do ok. 5%, klik w ciemności. (R10) | klak minutnika, klik | Zgaś ekran. Graj dotykiem i słuchem. | Screen off. Play by touch and ear. |
| T5 | 0:10–0:12 | Drzwi uchylają się do ciepłego wnętrza. (R12) | rygiel, skrzypnięcie | Ktoś znowu jest w domu. | Someone's home again. |
| T6 | 0:12–0:15 | Plansza końcowa (R13). | cicha fraza | **Lockwright: Pogotowie Zamkowe** · To gra, nie kurs. | **Lockwright: Locksmith on Call** · A game, not a course. |

Wariant 6 s (bumper YouTube): T1 + T4 + tytuł, bez dodatkowego tekstu poza napisem SDH.

---

## 3. Press kit — karta informacyjna

Pola w nawiasach kwadratowych uzupełnia właściciel. Nie wpisujemy danych osobowych do repo bez jego zgody.

### 3.1 PL

**Lockwright: Pogotowie Zamkowe**

| | |
|---|---|
| Twórca / wydawca | [nazwa studia lub imię i nazwisko właściciela] |
| Siedziba | [miasto, kraj] |
| Platformy | iOS / iPadOS (wiodąca), Android |
| Data premiery | [do ustalenia] |
| Cena / model | [do ustalenia, D-06]. Pewne już dziś: bez reklam, bez energii, bez kupowania monet. |
| Języki | polski, angielski |
| Gatunek | gra zręcznościowo-logiczna o otwieraniu zamków na wyczucie |
| Sterowanie | dwa kciuki: napięcie po lewej, wytrych po prawej; pion |
| Działa offline | tak; nie zbiera danych, nie wymaga konta |
| Kontakt dla prasy | [adres e-mail] |
| Strona / materiały | [adres strony press kitu] |

**Krótko (1 zdanie).** Ciepła gra o ślusarzu z pogotowia: każdy wymyślony zamek otwierasz dwoma kciukami, czując
i słysząc, co dzieje się w środku, a całą grę da się przejść bez patrzenia na ekran.

**Opis (ok. 100 słów).** Ktoś stoi pod własnymi drzwiami bez kluczy i dzwoni po ciebie. W Lockwright widzisz
fotorealistyczny przekrój mechanizmu, ale najważniejsze dociera przez kciuki i uszy. Pin, który wiąże, stawia opór
i skrobie. Pin, który siada, daje krótki, suchy klik. Szpulka udaje, że siadła. Między zleceniami kupujesz i naprawiasz
narzędzia w warsztacie, a każde nowe narzędzie otwiera nowy rodzaj zamka. Tryb „w ciemności” gasi ekran: zostaje dotyk
i dźwięk. Haptyka nigdy nie jest jedynym sygnałem, więc gra działa też bez niej. Wszystkie zamki są wymyślone i bez marki.
To gra, nie kurs.

**Cechy**
- Otwieranie zamków na wyczucie: haptyka, dźwięk i obraz mówią o tym samym, fizycznym przedmiocie.
- Fotorealistyczne przekroje z obrobionego mosiądzu i stali, generowane proceduralnie w Blenderze.
- Kilka rodzin wymyślonych mechanizmów, każda wymaga innej ręki [lista rodzin w 1.0 do potwierdzenia].
- Tryb „w ciemności”: cała gra przechodzalna bez patrzenia.
- Warsztat zamiast ulepszeń za pieniądze; zapasowe wytrychy w skórzanej zwijce zamiast paska życia.
- Gablota z krótkimi, sprawdzonymi w źródłach notkami z historii zamków [zakres w 1.0 do potwierdzenia].
- Dostępność od pierwszego dnia: trzy kanały informacji, opcjonalne znaki kredą na przekroju, napisy, cele dotyku ≥ 48 dp.

**Uczciwie.** Mechanizmy są wymyślone i celowo uproszczone, żeby dało się je czytać. Gra nie uczy otwierania
prawdziwych zamków. Prawdziwy ślusarz zawsze sprawdza, czy klient ma prawo wejść do lokalu; w grze też.

**W paczce** (`press/`, powstanie przy premierze): logo (jasne i ciemne tło), ikona, 8 zrzutów PL i EN
(`store/screenshots`), zwiastuny 30 s i 15 s (PL, EN), 6 renderów 4K z §4 (R04, R06, R07, R08, R10, R13), GIF-y
z §5 bez dźwięku. Licencja na materiały: do publikacji w recenzjach i zapowiedziach gry.

### 3.2 EN

**Lockwright: Locksmith on Call**

| | |
|---|---|
| Developer / publisher | [studio name or owner's name] |
| Based in | [city, country] |
| Platforms | iOS / iPadOS (lead), Android |
| Release date | [TBA] |
| Price / model | [TBA, D-06]. Already certain: no ads, no energy, coins can't be bought. |
| Languages | English, Polish |
| Genre | tactile puzzle game about opening locks by feel |
| Controls | two thumbs: tension on the left, pick on the right; portrait |
| Offline | yes; collects no data, no account needed |
| Press contact | [e-mail address] |
| Website / assets | [press kit URL] |

**One line.** A warm game about an emergency locksmith: you open every invented lock with two thumbs, feeling and
hearing what happens inside, and the whole game can be played without looking at the screen.

**About (approx. 100 words).** Someone is stuck outside their own door, and they call you. In Lockwright you see a
photoreal cutaway of the mechanism, but the important part comes through your thumbs and your ears. A pin that binds
pushes back and scrapes. A pin that sets gives a short, dry click. A spool pin pretends to set. Between jobs you buy and
repair tools in the workshop, and every new tool opens a new kind of lock. "In the dark" mode turns the screen off:
touch and sound are all you have. Haptics are never the only signal, so the game plays fine without them. Every lock
is invented and unbranded. It's a game, not a course.

**Features**
- Lock picking by feel: haptics, sound and image all describe the same physical object.
- Photoreal cutaways of machined brass and steel, generated procedurally in Blender.
- Several families of invented mechanisms, each asking for a different hand [1.0 list to be confirmed].
- "In the dark" mode: the whole game is playable without looking.
- A workshop instead of paid upgrades; spare picks in a leather tool roll instead of a health bar.
- A showcase of short, sourced notes from the history of locks [1.0 scope to be confirmed].
- Accessible from day one: three information channels, optional chalk marks on the cutaway, captions, touch targets ≥ 48 dp.

**The honest part.** The mechanisms are invented and simplified on purpose so you can read them. The game does not
teach you to open real locks. A real locksmith always checks that the customer has the right to enter; so do you.

**In the kit** (`press/`, at launch): logo (light and dark), icon, 8 screenshots EN and PL, 30 s and 15 s trailers
(EN, PL), six 4K renders from §4, silent GIFs from §5. Licence: for use in reviews and coverage of the game.

---

## 4. Lista renderów dla art (Blender 4.2, Cycles)

Wspólne ustawienia: AgX (jak w skryptach), bez bloomu i glare, `--samples` co najmniej 256 dla stopklatek i 128
z odszumianiem dla animacji. Wideo: klatki PNG 16-bit, **2160 × 3840 (9:16), 30 kl./s**, montaż skaluje do 1080 × 1920.
Stopklatki do prasy: 2160 × 3840 i dodatkowo poziomo 3840 × 2160 tam, gdzie zaznaczono. Każdy plik wpisać do
`docs/ASSETS.md`. Wyjście: `art/renders/marketing/<ID>_<nazwa>.<ext>` (sekwencje w podkatalogach, poza repo, jeśli
przekroczą rozsądny rozmiar; w repo trzymamy pierwszą klatkę i plik `.json` z parametrami).

Czasy animacji pinów jak w grze (100–250 ms = 3–8 klatek przy 30 kl./s). Stany pinów zgodne z kodem stanów
z `docs/DESIGN.md` i tabelą „Jak realizm tłumaczy mechanikę” w `docs/styles/realizm.md`.

**Potrzebne zmiany w skryptach** (zanim powstaną animacje):
- `cutaway.py`: dziś stany pinów a–e są na sztywno (a set, b false set, c binding, d overset, e swobodny). Potrzebny
  parametr `--states` (np. `--states e,e,c,e,e`) i `--anim <nazwa>` z kluczami dla: `bind_c`, `set_c`, `spool_b`,
  `counter_b`, `open` (obrót rdzenia o 90°). Plus `--tension <stopnie>` dla kąta napinacza i czoła rdzenia,
  `--dim <0..1>` dla zgaszenia światła oraz `--fps 30 --frames N`.
- `cutaway.py`: nowy `--shot push` (najazd kamery od pełnego przekroju do pinu c) i `--shot macro_shear` (dziś `loupe`
  ma optykę lupy; do zwiastuna potrzebne czyste makro bez winiety lupy).
- `tray.py`: animacja rozwijania zwijki `--anim unroll` i kamera z góry na wycieraczce.
- `stairwell.py`: animacja zapalania i gaszenia minutnika (`--anim timer_on`, `--anim timer_off`), najazd na drzwi,
  drzwi uchylone z ciepłym wnętrzem (`--door_open <stopnie>`).

| ID | Do | Skrypt / ujęcie | Kamera | Stan / animacja | Rozdzielczość, długość | Status |
|---|---|---|---|---|---|---|
| R01 | S1 | `stairwell.py --night`, nowa animacja `timer_on` | z wysokości oczu (160 cm), 35 mm, najazd 0,4 m w 2,5 s na drzwi z tabliczką „12” | minutnik: ciemno → żarówka zapala się w 6 klatek | 2160×3840, 75 kl. | nowa animacja; kadr bazowy jest (`test_stair.png`) |
| R02 | S2 | `tray.py --anim unroll` | z góry (pitch 85°), 50 mm, zwijka na wycieraczce | rozwijanie w 30 klatek, pełny komplet: napinacz, 3 wytrychy, lupa | 2160×3840, 75 kl. | nowa scena (wycieraczka) i animacja |
| R03 | S3 | `tray.py` + nowy obiekt: koperta z wymyślonym adresem | z góry, 85 mm, płytka GO (f/2,8) | statyczna, lekki najazd | 2160×3840, 60 kl. | nowy obiekt; tekst adresu wymyślony, bez kodu pocztowego |
| R04 | S4, prasa | `cutaway.py --shot push` | od pełnego przekroju (jak `section.png`) do kadru 0,7 na pin c, 90 kl. | wszystkie piny swobodne (`--states e,e,e,e,e`), napinacz 0° → 2° | 2160×3840, 90 kl.; stopklatka 3840×2160 | nowy shot i parametry |
| R05 | S4 | `cutaway.py` | stała, kadr 0,7 na czoło rdzenia i napinacz | `--anim tension` 0° → 2°, czoło rdzenia obraca się razem z napinaczem | 2160×3840, 30 kl. | nowa animacja |
| R06 | S5, T2, prasa | `cutaway.py` | stała, kadr 0,5 na pin c | `--anim bind_c`: pin dolny unosi się, pin górny przechyla 2,5° i drga (±0,3°, 3 cykle) | 2160×3840, 90 kl.; stopklatka 3840×2160 | nowa animacja; stan c statycznie już istnieje |
| R07 | S6, T1, prasa | `cutaway.py --shot macro_shear` | makro, 180 mm, cel: linia podziału pinu c, dystans 42 (jak `loupe`) bez optyki lupy | `--anim set_c`: pin górny siada na krawędzi rdzenia w 5 klatek (≈170 ms), pod nim otwiera się jasna szczelina; 15 klatek spokoju po | 2160×3840, 45 kl.; stopklatka 3840×2160 | nowy shot i animacja; stan a (set) statycznie już istnieje |
| R08 | S7, T3, prasa | `cutaway.py --shot macro_shear` na pin b | makro, 180 mm, cel: talia szpulki | `--anim spool_b`: rdzeń obraca się o dodatkowe 4° w 6 klatek, talia na linii podziału, 15 klatek bez ruchu | 2160×3840, 60 kl.; stopklatka 3840×2160 | nowa animacja; stan b statycznie już istnieje |
| R09 | S8 | `cutaway.py` | stała, kadr 0,6 obejmujący napinacz i pin b | `--anim counter_b`: napinacz i czoło rdzenia cofają się o 3°, szpulka przechodzi przez linię podziału, potem pin siada | 2160×3840, 60 kl. | nowa animacja |
| R10 | S9, T4, prasa | `cutaway.py --dim` | jak R04 (pełny przekrój) | światło 100% → 5% w 12 klatkach (minutnik gaśnie), potem 75 klatek ciemności; zostaje słaby odblask sprężyny, bez poświaty | 2160×3840, 90 kl.; stopklatka 2160×3840 | nowy parametr; dziś symulowane jasnością 10% w zrzutach |
| R11 | S10 | `cutaway.py --anim open` | jak R04 | wszystkie piny set, rdzeń obraca się o 90° w 20 klatek, krzywka cofa rygiel | 2160×3840, 45 kl. | nowa animacja i geometria krzywki/rygla |
| R12 | S10, T5 | `stairwell.py --door_open` | jak R01, kadr końcowy | drzwi 0° → 25° w 30 klatek, ciepłe światło z mieszkania (bez postaci) | 2160×3840, 60 kl. | nowa animacja i oświetlone wnętrze za drzwiami |
| R13 | S11, T6, prasa | `stairwell.py --crop` na tabliczkę | prosto na drzwi, 85 mm, emaliowana tabliczka bez numeru, miejsce na tytuł | statyczna; tytuł nakładany w montażu, nie w renderze | 2160×3840 i 3840×2160, stopklatka | wariant istniejącej sceny |
| R14 | §5 | `cutaway.py` | jak R07, na pin d | `--anim overset_d`: pin dolny przechodzi przez linię podziału, sprężyna prawie zwój w zwój, 8 klatek | 2160×3840, 45 kl. | nowa animacja; stan d statycznie już istnieje |
| R15 | §5 | `cutaway.py` | kadr 0,6 na grot wytrycha | `--anim break`: wytrych ugina się (stress, 15 klatek), końcówka zostaje w kanale | 2160×3840, 60 kl. | nowa animacja i geometria złamania |
| R16 | §5 | `cutaway.py --shot loupe`, `--shot microscope`, `--shot borescope` | jak w skrypcie | ten sam układ pinów a–e, trzy ujęcia do porównania | 2160×3840 każde, stopklatki | istnieją jako testy (`test_mic_prod.png`, `test_bor_prod.png`); przerenderować w 9:16 |
| R17 | §5 | `wafer.py`, `warded.py`, `lever.py`, `wooden_pin.py` | ujęcia jak w obecnych renderach | stan swobodny, potem jeden element w stanie set | 2160×3840, stopklatki | stopklatki istnieją w innych proporcjach; przerenderować 9:16 |

Kolejność pracy dla art: R07 → R06 → R08 → R10 (rdzeń obu zwiastunów i większości krótkich wideo), potem R04, R05,
R09, R11, potem sceny klatki R01, R12, R13, na końcu R02, R03, R14–R17.

---

## 5. Dziesięć pomysłów na krótkie wideo (9:16, 7–25 s)

Wspólne: napisy SDH na stałe, dźwięk z gry, hak w pierwszej sekundzie (dźwięk albo ruch, nie plansza), linia
„To gra, nie kurs.” w opisie posta, a w filmie, gdy trwa dłużej niż 10 s. Każde wideo pokazuje mechanikę taką, jaka jest
w grze, bez przyspieszania czasu otwarcia (wyjątek: nr 9, wyraźnie oznaczony).

| # | Tytuł roboczy | Długość | Co widać (rendery) | Hak / tekst PL | Hook / text EN | Uczciwość |
|---|---|---|---|---|---|---|
| 1 | Klik czy kłamstwo | 10 s | R07, potem R08, bez podpisu przez 2 s, potem odpowiedź | „Który siadł naprawdę?” → „Lewy. Prawy to szpulka.” | "Which one really set?" → "Left. The right one's a spool." | oba klipy w tym samym tempie co w grze |
| 2 | Ten sam klik trzy razy | 15 s | R07 trzy razy: (a) sam obraz bez dźwięku, (b) czarny ekran z dźwiękiem, (c) obraz + dźwięk + napis „[w kciuku]” | „Obraz. Dźwięk. Kciuk. Każdy mówi to samo.” | "Picture. Sound. Thumb. Each says the same thing." | pokazuje zasadę trzech kanałów |
| 3 | Zgaś ekran | 20 s | R10 przez całe wideo, prawie czerń; dźwięki kolejnych pinów i otwarcie (R11 dopiero na koniec) | „Ten zamek otwarto bez patrzenia.” | "This lock was opened without looking." | nagranie dźwięku z prawdziwej rozgrywki, bez montażu kolejności |
| 4 | Za wysoko | 8 s | R06 → R14 (overset), sprężyna zwój w zwój | „Za mocno. Teraz od nowa.” | "Too far. Start again." | pokazuje porażkę, nie tylko sukces |
| 5 | Zostało dwa | 12 s | R15 (złamanie), potem zwijka z jednym pustym miejscem (R02, ostatnia klatka) | „Wytrych został w kanale. W zwijce zostały dwa.” | "The pick stayed in the keyway. Two left in the roll." | życia = wytrychy (D-12), bez paska |
| 6 | Lupa, mikroskop, wziernik | 15 s | R16, trzy ujęcia jedno po drugim | „Trzy pytania, trzy narzędzia. Żadne nie powie, co robić.” | "Three questions, three tools. None tells you what to do." | zgodnie z D-35: narzędzia nie pokazują kolejności wiązania |
| 7 | Każdy zamek prosi o inną rękę | 20 s | R17: pinowy, płytkowy, zapadkowy, dźwigniowy, drewniany pinowy, po 3 s | „Wymyślone zamki. Prawdziwe zasady fizyki.” → nazwy rodzin z gry | "Invented locks. Real physics." → family names from the game | tylko rodziny, które są w 1.0; nazwy ogólne (D-08) |
| 8 | Z gabloty | 25 s | stopklatka R17 (drewniany zamek pinowy) + jedna notka z `SHOWCASE.md`, czytana napisem | treść notki, źródło w opisie posta | note text, source in the post caption | tylko notki zatwierdzone, ze źródłem; bez marek (D-08) |
| 9 | Jak powstaje zamek | 20 s | timelapse Blendera: skrypt `cutaway.py` buduje przekrój z parametrów, potem render (nagranie ekranu) | „Ani jednego modelu ręcznie. Każdy zamek to parametry.” | "Not a single hand-made model. Every lock is parameters." | oznaczone „przyspieszone ×20” |
| 10 | Najpierw pytam | 12 s | R01 → R03 (koperta z adresem) → R12 | „Zanim dotknę zamka, sprawdzam, czy to jej mieszkanie.” | "Before I touch the lock, I check it's her flat." | ton marki; jeśli Tryb Zleceń nie wchodzi do 1.0, opis posta mówi „tak pracuje prawdziwy ślusarz” zamiast obiecywać funkcję |

Odrzucone pomysły (zostawiamy jako przestrogę): „otwórz w 10 sekund” (wyścig = ton włamania i instruktaż),
„prawdziwy zamek vs gra” (sugeruje kurs, ryzyko marek), „ASMR 1 godzina” (obiecuje relaks bez gry, słaba retencja),
reakcje „nie uwierzysz” (clickbait).

## 6. Otwarte sprawy dla właściciela

1. Model biznesowy (D-06) decyduje o planszy końcowej i karcie press kitu: „Wkrótce” vs znaczki sklepów vs informacja o demie.
2. Czy zwiastun ma mieć lektora? Rekomendacja: nie (prościej w i18n, mocniejszy tryb „w ciemności”, ton spokojny).
3. Nazwa studia i kontakt do press kitu.
4. Czy w materiałach wolno pokazywać Tryb Zleceń jako „w przygotowaniu” (S3, wideo nr 10).
