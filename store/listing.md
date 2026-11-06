# Opisy sklepowe — App Store i Google Play (PL + EN)

Status: szkic do akceptacji właściciela · 2026-11-04.

Zasady pisania: głos ślusarza (spokojny, praktyczny, trochę suchego humoru), bez sloganów, bez wykrzykników,
bez rankingów, bez marek zamków i samochodów, bez ceny w nazwie i podtytule (Apple 2.3.7). Model biznesowy
nie jest rozstrzygnięty (D-06), więc teksty działają w obu wariantach. Jedyne miejsce zależne od modelu to
opcjonalny akapit „Wariant A” w pełnym opisie.

Pola z limitem są oznaczone komentarzem `<!-- field: … max=N -->` i w całości zawarte w bloku kodu pod nim.
Liczby znaków sprawdza `python3 store/tools/check_lengths.py` (liczy znaki Unicode i bajty UTF-8).

---

## 0. Nazwa w sklepach (D-32)

| Sklep | PL | EN |
|---|---|---|
| App Store, Google Play | `Lockwright: Pogotowie Zamkowe` (29 znaków) | `Lockwright: Locksmith on Call` (29 znaków) |

Decyzja właściciela **D-32** (2026-11-05): pełna nazwa EN z D-01 („Lockwright: Emergency Locksmith”, 31 znaków) przekracza limit 30 znaków
obu sklepów, więc w sklepach EN używamy „Lockwright: Locksmith on Call”. Dopisek dalej odróżnia nas od escape roomu z lockwright.app (D-03).
Tytuł gry w i18n EN zmienia sesja B (`game/i18n`, uwaga w `docs/handoff/SESSION-C-REVIEW.md`).

---

## 1. App Store — polski (pl)

**Nazwa**
<!-- field: as.pl.name max=30 -->
```
Lockwright: Pogotowie Zamkowe
```

**Podtytuł**
<!-- field: as.pl.subtitle max=30 -->
```
Otwieraj zamki na wyczucie
```

**Tekst promocyjny** (można zmieniać bez nowej wersji)
<!-- field: as.pl.promo max=170 -->
```
Wieczorny dyżur ślusarza: pin, który wiąże, pin, który siada, i szpulka, która kłamie. Każdy zamek otwierasz dotykiem i słuchem. Bez reklam, gra działa offline.
```

**Słowa kluczowe** (bez spacji po przecinkach, bez słów z nazwy i podtytułu: lockwright, pogotowie, zamkowe, otwieraj, zamki, wyczucie)
<!-- field: as.pl.keywords max=100 bytes -->
```
ślusarz,wytrych,wkładka,łamigłówka,haptyka,mechanizm,klucz,kłódka,dotyk,warsztat,lockpicking
```

**Opis** — wspólny dla App Store i Google Play (wersja Play: patrz §3, różni się jednym akapitem)
<!-- field: as.pl.description max=4000 -->
```
Ktoś stoi pod drzwiami bez kluczy. Dzwonią po ciebie.

Lockwright to gra o otwieraniu zamków na wyczucie. Na ekranie widzisz fotorealistyczny przekrój mechanizmu, ale najważniejsze dociera przez kciuki i uszy. Lewy kciuk trzyma napięcie, prawy prowadzi wytrych. Kołek, który wiąże, stawia opór i chropawo skrobie. Kołek, który siada, daje krótki, suchy klik. Szpulka udaje, że siadła, i kłamie. Nauczysz się je odróżniać.

Co robisz
• Otwierasz zamki dwoma kciukami: napięcie po lewej, wytrych po prawej.
• Czytasz każdy kołek przez haptykę, dźwięk i obraz przekroju.
• Otwierasz zamek za zamkiem. Trzy zapasowe wytrychy w zwijce to cały twój margines błędu.
• Za zarobione monety kupujesz i naprawiasz narzędzia w warsztacie. Nowe narzędzie to nowy rodzaj zamka, a nie „+10%”.
• Sięgasz po lupę zegarmistrzowską, kiedy oko ma potwierdzić to, co już poczuły palce.
• Grasz „w ciemności”: ekran gaśnie, a zamek otwierasz samym dotykiem i słuchem.
• Odblokowujesz notki w gablocie: krótkie, sprawdzone w źródłach kawałki historii zamków, od starożytnych zamków drewnianych po Wielką Wystawę z 1851 roku.

Dla każdego
• Haptyka nigdy nie jest jedynym sygnałem. To, co czujesz, także słyszysz i widzisz, więc da się grać z wyłączoną haptyką, również na iPadzie.
• Opcjonalne znaki kredą na przekroju pomagają odczytać stan każdego kołka.
• Bez reklam, bez energii, bez konta. Gra działa offline (opcjonalnie pobierasz głosy w innych językach). Monet nie da się kupić za pieniądze.
• Nikt cię nie pogania. Timer jest tylko w osobnym wyzwaniu, jeśli go chcesz.

Uczciwie
Każdy zamek w grze jest wymyślony i nie ma marki. Mechanizmy są celowo uproszczone, żeby dało się je czytać. To gra, nie kurs. Prawdziwy ślusarz zawsze sprawdza, czy klient ma prawo wejść do lokalu. W grze też.

Prywatność: gra nie zbiera żadnych danych. Postęp zapisuje się tylko na twoim urządzeniu.
```

**Wariant A (tylko jeśli D-06 = demo + jednorazowy zakup)** — wstawić jako drugi akapit opisu:
<!-- field: as.pl.variant_a max=4000 -->
```
Pierwsze zamki otworzysz bez płacenia. Jeden zakup w aplikacji odblokowuje całą grę. Bez subskrypcji.
```

**Co nowego (1.0)**
<!-- field: as.pl.whatsnew max=4000 -->
```
Pierwsze wydanie. Torba spakowana, wytrychy w zwijce. Jeśli coś zgrzyta, napisz do nas, adres jest w ustawieniach gry.
```

---

## 2. App Store — angielski (en-US, en-GB)

**Name**
<!-- field: as.en.name max=30 -->
```
Lockwright: Locksmith on Call
```

**Subtitle**
<!-- field: as.en.subtitle max=30 -->
```
Open locks by feel and sound
```

**Promotional text**
<!-- field: as.en.promo max=170 -->
```
A locksmith's evening shift: a pin that binds, a pin that sets, and a spool that lies to you. Open every lock by touch and ear. No ads, works offline.
```

**Keywords** (no spaces after commas; not repeating the name/subtitle words: lockwright, locksmith, on, call, open, locks, feel, sound)
<!-- field: as.en.keywords max=100 bytes -->
```
lockpicking,pick,emergency,haptic,tactile,puzzle,mechanism,pin,tumbler,key,cylinder,padlock,offline
```

**Description**
<!-- field: as.en.description max=4000 -->
```
Someone's stuck outside their own door. You're the locksmith they called.

Lockwright is a game about opening locks by feel. You see a photoreal cutaway of the mechanism, but the important part comes through your thumbs and your ears. The left thumb holds tension, the right one works the pick. A pin that binds pushes back and scrapes. A pin that sets gives a short, dry click. A spool pin pretends to set and lies to you. You'll learn to tell them apart.

What you do
• Open locks with two thumbs: tension on the left, pick on the right.
• Read every pin through haptics, sound and the cutaway itself.
• Work through one lock after another. Three spare picks in the tool roll are all the margin you get.
• Spend the coins you earn on tools and repairs in the workshop. A new tool means a new kind of lock, not a +10% bonus.
• Reach for the watchmaker's loupe when your eyes need to confirm what your fingers already know.
• Play "in the dark": the screen goes black and you open the lock by touch and sound alone.
• Unlock notes in the showcase: short, sourced pieces of lock history, from ancient wooden locks to the Great Exhibition of 1851.

For everyone
• Haptics are never the only signal. What you feel, you can also hear and see, so the game plays fine with haptics off, iPad included.
• Optional chalk marks on the cutaway help you read each pin's state.
• No ads, no energy, no account. Plays offline (optional voice downloads for other languages). Coins can't be bought with money.
• Nobody's rushing you. There's a timer only in a separate challenge, if you want one.

The honest part
Every lock in the game is invented and has no brand. The mechanisms are simplified on purpose so you can read them. This is a game, not a course. A real locksmith always checks that the customer has the right to enter. So do you.

Privacy: the game collects no data. Your progress is saved only on your device.
```

**Variant A (only if D-06 = demo + one-time purchase)** — insert as the second paragraph:
<!-- field: as.en.variant_a max=4000 -->
```
The first locks are yours to open at no cost. One in-app purchase unlocks the full game. No subscriptions.
```

**What's New (1.0)**
<!-- field: as.en.whatsnew max=4000 -->
```
First release. Bag packed, picks in the roll. If something grinds, write to us. The address is in the game's settings.
```

---

## 3. Google Play — polski i angielski

Google Play nie ma podtytułu ani pola słów kluczowych. Tytuł ma limit 30 znaków, krótki opis 80, pełny 4000.
Pełny opis = opis z App Store z dwiema zmianami: (1) zdanie o iPadzie zastąpione zdaniem o silnikach wibracji,
(2) bez słowa „iPad”/„App Store” (Play nie lubi odwołań do innych platform, Apple 2.3.10 odwrotnie).

**Tytuł PL**
<!-- field: gp.pl.title max=30 -->
```
Lockwright: Pogotowie Zamkowe
```

**Tytuł EN**
<!-- field: gp.en.title max=30 -->
```
Lockwright: Locksmith on Call
```

**Krótki opis PL**
<!-- field: gp.pl.short max=80 -->
```
Otwieraj wymyślone zamki na wyczucie: dwa kciuki, klik, haptyka i dźwięk.
```

**Short description EN**
<!-- field: gp.en.short max=80 -->
```
Open invented locks by feel: two thumbs, a real click, haptics and sound.
```

**Pełny opis PL — podmiana punktu o haptyce** (reszta jak §1):
<!-- field: gp.pl.haptics_line max=4000 -->
```
• Haptyka nigdy nie jest jedynym sygnałem. To, co czujesz, także słyszysz i widzisz. Najlepiej czuć ją na telefonie z precyzyjnym silnikiem wibracji, ale da się grać z wyłączoną haptyką.
```

**Full description EN — haptics bullet replacement** (rest as §2):
<!-- field: gp.en.haptics_line max=4000 -->
```
• Haptics are never the only signal. What you feel, you can also hear and see. They come through clearest on a phone with a precise vibration motor, but the game plays fine with haptics off.
```

Pełne opisy Play po podmianie: sprawdzone skryptem jako `gp.pl.description` i `gp.en.description` (składane automatycznie).

**Co nowego / What's new (1.0)**: jak w App Store (limit Play: 500 znaków).

---

## 4. Tabela znaków

Wygenerowana przez `python3 store/tools/check_lengths.py` (2026-11-04). „Bajty” = UTF-8; Apple liczy pole
słów kluczowych w bajtach, więc polskie znaki (ś, ł, ó…) zajmują po 2.

<!-- table:start -->
| Pole | Limit | Znaki | Bajty | OK |
|---|---|---|---|---|
| as.pl.name | 30 | 29 | 29 | tak |
| as.pl.subtitle | 30 | 26 | 26 | tak |
| as.pl.promo | 170 | 160 | 173 | tak |
| as.pl.keywords | 100 bytes | 92 | 99 | tak |
| as.pl.description | 4000 | 1814 | 1937 | tak |
| as.pl.variant_a | 4000 | 101 | 105 | tak |
| as.pl.whatsnew | 4000 | 118 | 120 | tak |
| as.en.name | 30 | 29 | 29 | tak |
| as.en.subtitle | 30 | 28 | 28 | tak |
| as.en.promo | 170 | 150 | 150 | tak |
| as.en.keywords | 100 bytes | 99 | 99 | tak |
| as.en.description | 4000 | 1861 | 1883 | tak |
| as.en.variant_a | 4000 | 106 | 106 | tak |
| as.en.whatsnew | 4000 | 118 | 118 | tak |
| gp.pl.title | 30 | 29 | 29 | tak |
| gp.en.title | 30 | 29 | 29 | tak |
| gp.pl.short | 80 | 73 | 76 | tak |
| gp.en.short | 80 | 73 | 73 | tak |
| gp.pl.haptics_line | 4000 | 186 | 199 | tak |
| gp.en.haptics_line | 4000 | 190 | 192 | tak |
| gp.pl.description | 4000 | 1858 | 1980 | tak |
| as.pl.description+A | 4000 | 1917 | 2044 | tak |
| gp.pl.description+A | 4000 | 1961 | 2087 | tak |
| gp.pl.whatsnew | 500 | 118 | 120 | tak |
| gp.en.description | 4000 | 1917 | 1939 | tak |
| as.en.description+A | 4000 | 1969 | 1991 | tak |
| gp.en.description+A | 4000 | 2025 | 2047 | tak |
| gp.en.whatsnew | 500 | 118 | 118 | tak |
<!-- table:end -->

---

## 5. Lista zgodności

| Reguła | Stan |
|---|---|
| Apple 2.3.7: brak ceny i „free” w nazwie, podtytule i słowach kluczowych | spełnione. Cena tylko w opcjonalnym akapicie opisu (wariant A), bez kwoty |
| Apple 2.3.7: brak nazw innych aplikacji, marek i fraz „best”, „#1” w metadanych | spełnione. Brak marek zamków i aut, brak nazw konkurencji w słowach kluczowych |
| Apple 2.3.7: słowa kluczowe nie powtarzają nazwy ani podtytułu (i nie zawierają nazw konkurentów) | spełnione (sprawdza skrypt) |
| Apple 2.3.1/2.3.3/2.3.4: opis i zrzuty pokazują grę w działaniu, bez obiecywania funkcji, których nie ma | **do potwierdzenia** z zakresem 1.0 (lista niżej) |
| Apple 2.3.10: brak odwołań do innych platform w metadanych App Store | spełnione (Android nie pada) |
| Apple 3.1.1: odblokowanie pełnej wersji przez IAP | dotyczy tylko wariantu A, tekst zgodny |
| Google Play Metadata: bez rankingów („najlepsza”, „nr 1”), bez opinii użytkowników, bez cen i promocji w tytule, ikonie, krótkim opisie | spełnione |
| Google Play Metadata: bez CAPS LOCK, bez emoji, bez nadmiaru znaków specjalnych | spełnione. Nagłówki zwykłą pisownią, punktory „•” tylko w liście |
| Google Play: tytuł ≤ 30, krótki opis ≤ 80, pełny ≤ 4000 | spełnione (tabela §4) |
| Odpowiedzialność (CLAUDE.md): legalny ślusarz, „to gra, nie kurs”, brak instrukcji do realnych produktów | spełnione (akapit „Uczciwie”) |
| Brak sloganów: „Welcome!”, „Get Started”, „Unlock your potential”, „epic”, „ultimate” | spełnione |

### Twierdzenia w opisie do potwierdzenia przed wysyłką (zakres 1.0)

| Twierdzenie | Źródło w dokumentach | Ryzyko |
|---|---|---|
| Szpulka (spool) w 1.0 | LOCKS.md, PROGRESSION §2.2 (tier 3+) | niskie |
| Zwijka z trzema zapasowymi wytrychami | D-12, PROGRESSION §2.1 | niskie |
| Warsztat, monety, narzędzie = nowy rodzaj zamka | PROGRESSION §2.3–2.4 | niskie |
| Lupa zegarmistrzowska | D-13 | niskie |
| Tryb „w ciemności” | PROGRESSION §5 | niskie |
| Gablota z notkami od starożytności do 1851 | SHOWCASE.md, PROGRESSION §4 | **średnie**: zależy, ile notek wejdzie do 1.0 |
| Znaki kredą (opcjonalne) | styles/realizm.md | średnie |
| Timer tylko w osobnym wyzwaniu | PROGRESSION §5 | średnie: wyzwania mogą wejść po 1.0 |
| Tryb Zleceń (klienci, weryfikacja) | JOBS.md (po MVP) | w opisie **celowo pominięty**. Dodać akapit, gdy wejdzie |
