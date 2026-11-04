# Lockwright — research rynku

Stan na **2026-11-04** (wszystkie odczyty z tej daty, chyba że zaznaczono inaczej). Dokument informacyjny, nie porada prawna.
Uzupełnia i weryfikuje ustalenia wstępne z 4.11.2026; korekty oznaczone **[KOREKTA]**.

---

## UWAGA, najważniejsze na start: kolizja nazwy

**Pod domeną `lockwright.app` działa gra przeglądarkowa „Lockwright”** („Lockwright · Free Online 3D Escape Room Game”).
- Pierwszoosobowy escape room 3D w przeglądarce (komputer i telefon, PWA z manifestem `short_name: Lockwright`), 9 pokoi + pokój treningowy, w tym „The Lockmaker's House”, zamki szyfrowe/klawiatury, ranking, „daily”. Zapowiedź „nowy pokój co tydzień”.
- Domenę zarejestrowano **2026-10-09** (GoDaddy, Cloudflare DNS); polityka prywatności z 17.10.2026. Twórca: osoba prywatna (kontakt na stronie /privacy; nie kopiujemy danych osobowych do repo).
- Ta sama klasa towarów/usług, w której chcemy chronić nazwę (gry: klasa 9 i 41), ta sama tematyka (zamki, łamigłówki), ten sam rynek anglojęzyczny i telefon jako platforma. Dziś to darmowy projekt bez zarejestrowanego znaku (USPTO: 0 wyników; patrz §5), ale **wcześniejsze używanie nazwy w obrocie** może w niektórych porządkach prawnych (US common law, UK passing off) dawać jej twórcy argumenty, a na pewno utrudnia SEO, ASO i uchwyty w mediach społecznościowych.
- Do tego `lockwright.com` jest zajęta (rejestracja 2026-01-22, IONOS, strona-szablon „My Website”), a **@LockWright na X to firma ślusarska** („With over 25 years of experience LockWright offers a professional service to both Domestic and Commercial customers…”) — nasz motyw to dosłownie ślusarz, więc dla graczy i prasy to myląca zbieżność.

**Ocena ryzyka tytułu: ŚREDNIE → WYSOKIE dla marketingu, ŚREDNIE prawnie.** Rekomendacja: właściciel decyduje (D-01 jest „przyjęta”, ale warto ją potwierdzić po tym wyniku) — patrz §5.4: albo (a) szybkie zgłoszenie znaku EUIPO + wariant z dopiskiem w sklepie, albo (b) zmiana nazwy, póki nic nie jest opublikowane.

Druga ważna korekta: **tryb „w ciemności” nie jest już unikalny** — *Vale & Daughter: Safecracker* (iOS, X 2026) ma „Blind mode: the screen goes dark. Hands and ears only.” Szczegóły w §1 i §2.

---

## 1. Konkurencja

### 1.1 Tabela główna (mobile + PC)

Legenda: oceny App Store = US, średnia (liczba ocen); Google Play = instalacje / ocena; Steam = % pozytywnych (liczba recenzji). Odczyt 2026-11-04.

| Gra | Platforma | Model | Cena | Oceny / instalacje | Haptyka | Główna słabość |
|---|---|---|---|---|---|---|
| **[Unlokee – Lock picking puzzle](https://apps.apple.com/us/app/unlokee-lock-picking-puzzle/id6808786210)** (Dmitrii Rozhkov) · [Play](https://play.google.com/store/apps/details?id=com.dmitriyrozhkov.unlokee) | iOS (IX 2026), Android | **darmowy rozdział 1 + jednorazowy „Full Game” IAP**, bez reklam i subskrypcji | IAP **$7.99** | iOS 5,0 (1); Play 50+ | tak („on supported devices”) | **Najbliższy konkurent**: dwa palce (napięcie + wytrych), przekrój („cutaway”), spool/mushroom/serrated/T-pin, false set, 42 zamki + 10 wyzwań, 24 języki (w tym PL). Słabość: brak ramy fabularnej/klientów, brak trybu bez obrazu, generyczna estetyka 3D, prawie zero recenzji = mała odkrywalność. |
| **[Vale & Daughter: Safecracker](https://apps.apple.com/us/app/vale-daughter-safecracker/id6820067476)** (Pietro Messineo) | iOS (X 2026; iOS 26+) | darmowy „Workshop” + jedno IAP „The rest of the estate” | IAP **$4.99** | 0 ocen | **tak, rdzeń** (haptyka + dźwięk; zawias iPhone Duo/tilt/pokrętło) | Tylko sejfy szyfrowe, tylko EN, tylko iOS. **Ma „Blind mode” (ciemny ekran)** i ciepłą narrację w listach — najbliżej naszego tonu. |
| **[Shear Line: Lockpicking Game](https://apps.apple.com/us/app/shear-line-lockpicking-game/id6816888965)** (Djordje Subotic) | iOS (22.10.2026) | F2P: reklamy, „Remove Ads”, skrzynki, boostery | IAP $0.99–$9.99 | 0 ocen; rating **9+** | tak („built for sound and haptics, playable with the sound off”) | Napad/heist (zła rama dla nas = dobra dla kontrastu), jeden kciuk, łamigłówki logiczne zamiast czucia; reklamy i lootboksy. **[KOREKTA]** Była „zapowiedziana” — wyszła. |
| **[Shear line](https://store.steampowered.com/app/5069860/)** (TheNakedCat) — inna gra o tej samej nazwie | Steam PC (24.10.2026) | premium | $0.99 | 1 recenzja | n/d | Symulator fizyczny 2D (cylinder, szyfrowe, disc-detainer), edukacyjny, bez ramy i polotu; PC. |
| **[Lockpick 101](https://play.google.com/store/apps/details?id=com.Avarice.Lockpick101)** (-Avarice-) | Android | F2P + reklamy + IAP | 0 | **100 000+**, 4,4 (1,26 tys.) | tak (wibracje) | Lider instalacji, ale reklamy, przestarzała prezentacja; pokazuje, że popyt istnieje. |
| [The Impossible Safe – Crack it](https://apps.apple.com/us/app/the-impossible-safe-crack-it/id1573468310) | iOS | F2P | 0 | 3,11 (187) | tak (rdzeń, pokrętło) | Jeden sejf na czas, heist-owy ton, słabe oceny. |
| [Lock Pick 3D](https://apps.apple.com/us/app/lock-pick-3d/id1517044820) | iOS | F2P hyper-casual | 0 | 4,11 (9); ost. aktualizacja 2020 | „ASMR” | Martwy projekt, ton złodziejski („get rich”). |
| [Unlocking!](https://apps.apple.com/us/app/unlocking/id6455174981) (Feelcrafters) | iOS | F2P | 0 | 4,0 (1); ost. akt. 2023 | ASMR | Abstrakcyjna łamigłówka, porzucona. |
| [Tumbler Wizard](https://appgoblin.info/apps/6756764419) (JAMSoft) | iOS (I 2026) | F2P + IAP | — | — | tylko przy pokrętle | **[KOREKTA]** Usunięta z US App Store (AppGoblin: „removed… no longer live”; iTunes lookup 0 wyników w US/PL/GB/DE/CA). |
| [Tumbler: Lockpick Safe Cracker](https://play.google.com/store/apps/details?id=com.crystllabs.tumbler) (Crystl Labs) | Android | F2P + reklamy | 0 | 10+ | tak | „100 real locks” + fabuła „clear your father's name”; świeża (akt. 4.11.2026), reklamy. Obserwować. |
| [Key Master: Locksmith Sim](https://apps.apple.com/us/app/key-master-locksmith-sim/id6809031242) | iOS (IX 2026) | F2P | 0 | 0 ocen | ? | **Job-sim ślusarza** (dorabianie kluczy, sklep, dzielnice), roguelite; ale „podejrzani klienci = więcej kasy i ryzyko policji” — ton półlegalny. Najbliższy naszemu Trybowi Zleceń. |
| [Safe Cracker: Feel the Hinge](https://apps.apple.com/us/app/safe-cracker-feel-the-hinge/id6814453821) / [Safecracker: The Hinge Heist](https://apps.apple.com/us/app/safecracker-the-hinge-heist/id6825358652) | iOS (X–XI 2026), składany iPhone | premium | $0.99 / **$5.99** | 0 ocen | tak, rdzeń | Mikrogry pod jeden sprzęt (zawias iPhone Duo); pokazują falę „feel-based” sejfów. |
| [Crown Heist: Safe Cracker](https://apps.apple.com/us/app/crown-heist-safe-cracker/id6762077725) | Apple Watch (VII 2026) | F2P | 0 | 0 ocen | tak, Digital Crown | Zegarek-only, heist. |
| [Open the Safe / The Vault: Logic Puzzle Box](https://play.google.com/store/apps/details?id=com.peaksel.openthesafebox_3dsafebreaker_thevault) (Peaksel) | iOS/Android | F2P + reklamy | 0 | Play **5 mln+**, 4,5 (66,2 tys.) | tak | Puzzle-box, nie wytrych; skala pokazuje apetyt na „mechaniczne pudełka”. |
| [12 LOCKS](https://apps.apple.com/us/app/12-locks/id1504871805) (seria) | iOS/Android | F2P + reklamy | 0 | 4,65 (3,2 tys.) | nie | Escape-room dla dzieci; inna nisza, ale zajmuje frazę „locks”. |
| [How to Pick Lock](https://play.google.com/store/apps/details?id=com.mmdevstudio.picklock) / [Pick Lock](https://play.google.com/store/apps/details?id=com.brotherhoodapp.picklock) | Android | reklamy | 0 | 1 000+ / 5 000+ | tak | **„Kursy” wytrychowania** (105 zamków w przekroju, „field guide”, 51 lekcji) — dowód, że Google je dopuszcza, ale też przykład tonu, którego unikamy. |
| [Sophie's Safecracking Simulator](https://store.steampowered.com/app/1651780/) | Steam PC | premium | $2.99 | **96% (64)** | n/d | Realizm „edukacyjny”, mało treści, PC. **[KOREKTA]** ~97% → 96% (wszystkie języki). |
| [Museum of Mechanics: Lockpicking](https://store.steampowered.com/app/1735110/) (Dim Bulb) | Steam PC, [itch](https://dimbulbgames.itch.io/museum-of-mechanics-lockpicking) | premium | $9.99 | 71% (52) | n/d | Muzeum minigier z innych tytułów — brak własnego rdzenia. |
| [Thief Simulator](https://store.steampowered.com/app/704850/) (Noble Muffins/PlayWay) + [mobile](https://apps.apple.com/us/app/thief-simulator-sneak-steal/id6456607771) | PC/konsole, iOS | premium (PC), F2P (mobile) | PC $3.06 (promocja) | **88% (11 457)**; iOS 4,32 (264) | n/d | Wytrych to minigra; ton włamywacza. Pokazuje skalę „job sim” na PC. |
| [Lobsterpunk](https://store.steampowered.com/app/3414920/) | Steam PC (17.07.2026) | premium + [demo](https://store.steampowered.com/app/3957670/) | $9.99 | 9 recenzji (brak wyniku) | n/d | Walking sim z łamigłówkami-zamkami; niska sprzedaż/odbiór. |
| [True Thief](https://store.steampowered.com/app/3188360/) (Antelus) | Steam PC | premium | — | — | n/d | **Nadal „Coming soon”**, izometryczny stealth RPG; ton złodziejski. |
| [Lockpicks-11](https://www.pcgamer.com/games/puzzle/this-free-lockpicking-puzzler-you-can-play-in-your-browser-is-unexpectedly-one-of-the-most-thrilling-games-ive-encountered-this-year/) | przeglądarka (Ludum Dare 57) | darmowa | 0 | PC Gamer, 5.09.2026: „one of the most thrilling games I've encountered this year” | n/d | Jam; dowód, że „każdy zamek inny” zachwyca prasę. |

Inne znalezione, mniej istotne: [Locksmith Simulator](https://store.steampowered.com/app/1487060/) (Steam, „Coming soon”, ton „help damsels in distress”), [Lair of the Locksmith](https://store.steampowered.com/app/2607430/) (TBA, platformówka), [Unloop](https://apps.apple.com/us/app/unloop/id1632256862) (abstrakcyjna, „lock-picking” tylko w metaforze), [Lock Puzzle: Untangle Rings](https://apps.apple.com/us/app/lock-puzzle-untangle-rings/id6817707264), [Lockpicking (Anton Wimmer)](https://apps.apple.com/us/app/lockpicking/id6793054294) (Tetris z kluczami), [Lock Pick: Tap Master](https://apps.apple.com/us/app/lock-pick-tap-master/id6819757510) (2.11.2026), [Practice Lock](https://apps.apple.com/us/app/practice-lock-combination/id6466766612) (trener kłódki szyfrowej, 4,72/3,7 tys.), [D&D Lockpick](https://play.google.com/store/apps/details?id=com.fekent.dndlockpick), [Locksmith Master](https://play.google.com/store/apps/details?id=com.puzzlejay.locksmithmaster) („premium safecracking puzzle”, 10+ instalacji). itch.io: tag [lockpicking](https://itch.io/games/tag-lockpicking) = 19 projektów (głównie jamy: Night Latch, Intricacy, Pick the Lock…).

### 1.2 Wnioski z konkurencji
1. **Rynek gęstnieje szybko**: 8 nowych gier o zamkach/sejfach na iOS w VII–XI 2026. Haptyka + dźwięk przestały być wyróżnikiem samym w sobie.
2. **Unlokee robi już nasz MVP-owy rdzeń** (dwa palce, przekrój, typy pinów, demo + $7.99). Wyróżnić nas musi rama (pogotowie, klienci, Gablota z historią), ton i dostępność, nie sam mechanizm.
3. **Tryb „w ciemności”**: w sejfach już jest (Vale & Daughter „Blind mode”). Dla **zamków z wytrychem (pin tumbler) nie znaleźliśmy żadnej gry z trybem bez obrazu** ani gry zaprojektowanej pod VoiceOver/TalkBack.
4. Większość konkurentów ma ton „heist/złodziej”. Ciepły, legalny ślusarz pozostaje wolną pozycją (Key Master jest najbliżej, ale flirtuje z półświatkiem).
5. Najwięcej instalacji zbierają gry F2P z reklamami (Lockpick 101, The Vault). Premium w tej niszy dopiero się pojawia, bez potwierdzonego sukcesu.

### 1.3 Gry audio-only / dla niewidomych
- AudioGames.net (baza i forum) zwraca 403 dla automatów, więc nie dało się jej przeszukać bez przeglądarki. **Do sprawdzenia ręcznie**: `audiogames.net/db.php` (szukaj „lock”, „safe”) i forum.audiogames.net.
- [Lock Craker](https://magesinstitute.itch.io/lockcraker) (MAGES Institute, Windows, projekt studencki z modułu audio programming): tag „blind-accessible”, sejf, zamek obrotowy i sekwencja pinów. Jedyny znaleziony „dostępny” lockpicking, PC, prototyp.
- [Safe Cracker – Watch Game](https://apps.apple.com/us/app/safe-cracker-watch-game/id1638618972) (Apple Watch, $0.99): VoiceOver opisuje każdy ruch pokrętła.
- Ogólne gry audio na iOS: [A Blind Legend](https://apps.apple.com/gb/app/a-blind-legend/id973483154), [Blind Drive](https://apps.apple.com/us/app/id964294239) (ultra-fine haptics), [Audio Game Hub](https://apps.apple.com/gb/app/audio-game-hub/id1101972684) (Bomb Disarmer). Społeczność: [AppleVis – iOS Gaming](https://applevis.com/forum/ios-ipados-gaming-0).
- **Wniosek**: „pełny lockpicking pin-tumbler grywalny bez wzroku, na telefonie, z VoiceOver” to nadal **wolna nisza**, ale nie możemy już mówić „pierwsza gra w ciemności”. Komunikat: „cała gra przechodzalna bez patrzenia”, nie „jedyny tryb w ciemności”.

---

## 2. Luka i pozycjonowanie

**Zdanie pozycjonujące (robocze):**
> Lockwright to ciepła gra o ślusarzu z pogotowia: czujesz każdy zamek pod kciukami i słyszysz go uszami, a całą grę da się przejść z zamkniętymi oczami.

**Filary:**
1. **Czucie zamiast patrzenia**: haptyka i dźwięk niosą informację, a obraz ją potwierdza. Tryb „w ciemności” jest pełnoprawny, nie wybrany jako gadżet; całość działa z VoiceOver/TalkBack.
2. **Fach, nie włam**: legalny ślusarz, klient z problemem, weryfikacja prawa do lokalu. Przeciwwaga dla heist-owego rynku.
3. **Jeden mechanizm, dużo głębi**: przekrój 2,5D, rodziny zamków jako rozdziały, narzędzia w warsztacie zamiast ulepszeń za pieniądze.
4. **Prawdziwa historia**: Gablota z notkami historycznymi (encyklopedyczne, bez marek). Wyróżnik wobec Unlokee/Shear Line.
5. **Uczciwy premium**: zagraj za darmo, zapłać raz, bez reklam, energii i timerów.

**Grupy docelowe:**
| Grupa | Co ich przyciąga | Uwaga |
|---|---|---|
| Fani łamigłówek mechanicznych (The Room, puzzle-boxy, Golden Idol) | precyzja, „klik”, rzemiosło, premium bez reklam | główny rdzeń płacący; przyzwyczajeni do $4.99–9.99 |
| Fani job-sim / „cozy work” (PC: Thief Simulator, PowerWash, Unpacking) | rytm zleceń, mapa, reputacja, warsztat | Tryb Zleceń po MVP; na mobile mało premium job-simów |
| Hobbyści lockpickingu (locksport, r/lockpicking) | wierność false setu, spool, tolerancji | **ostrożnie z tonem**: nie udajemy symulatora szkoleniowego; uczciwie „to gra, nie kurs”; zapraszać jako konsultantów/testerów, nie jako target reklam |
| Gracze niewidomi i słabowidzący | grywalność bez obrazu, VoiceOver, haptyka | mała, ale lojalna i głośna społeczność (AppleVis, AudioGames.net); testować z nimi od prototypu, nie po fakcie |

---

## 3. Model biznesowy

### 3.1 Porównanie modeli

| Model | Plusy | Minusy | Przykłady 2024–2026 |
|---|---|---|---|
| **Darmowe demo + jednorazowy unlock (non-consumable IAP)** | Niski próg pobrania; widoczność w „free”; ocena konwersji; Apple wprost dopuszcza „unlocking a full version” przez IAP (3.1.1) | Część recenzji 1★ „to nie jest darmowe”; trzeba jasno komunikować | Unlokee $7.99, Vale & Daughter $4.99, [Golden Idol](https://apps.apple.com/us/app/the-case-of-the-golden-idol/id6443831605) $6.99, [Monument Valley 3](https://apps.apple.com/pl/app/monument-valley-3/id6443563379) $5.99, [A Little to the Left](https://apps.apple.com/us/app/a-little-to-the-left/id1613352146) $9.99 |
| **Płatna aplikacja (paid upfront)** | Prosto; Family Sharing domyślnie; brak IAP | Bardzo niska konwersja z wyszukiwania; brak demo (Apple 2.2: „Demos… trial versions… don't belong on the App Store”) | [Mini Metro](https://apps.apple.com/us/app/mini-metro/id837860959) $3.99 / 19,99 zł; [Gorogoa](https://apps.apple.com/us/app/gorogoa/id1269225754) $4.99; [ISLANDERS: Mobile](https://apps.apple.com/us/app/islanders-mobile/id6745312000) $3.99 (34 oceny w roku: słaby wynik); [Strange Horticulture](https://apps.apple.com/pl/app/strange-horticulture/id6450008138) 24,99 zł; [The Room: Old Sins](https://apps.apple.com/us/app/the-room-old-sins/id1286676015) $0.99 (promocja; PL 4,99 zł) |
| **Dodatki (DLC rodzin zamków, non-consumable)** | Pasuje do „gra rośnie latami”; każdy dodatek = news i powrót do sklepu | Fragmentacja oferty; ryzyko wrażenia „krojenia” | rzadko w mobile puzzle; częste na PC |
| **Apple Arcade / Google Play Pass** | Arcade: finansowanie z góry, promocja Apple, brak IAP/reklam | Kuratorowany, wymaga pitchu i zwykle wyłączności w kategorii subskrypcji; Play Pass: przychód zależny od zaangażowania, mały; mniejsza kontrola nad ceną i przyszłością | warunki niejawne; **do zbadania przez kontakt z Apple** |

### 3.2 Zasady sklepów (stan 4.11.2026)
- **Apple 3.1.1**: odblokowanie „pełnej wersji” musi iść przez IAP. Darmowy okres próbny czasowy dopuszczalny jako non-consumable IAP za 0 („XX-day Trial”) z jasną informacją o długości i dalszych kosztach. **Nasz model (demo treściowe + IAP „Pełna wersja”) jest zgodny** i nie wymaga triala czasowego.
- **Apple 2.2**: osobne aplikacje „demo/trial” są niedozwolone → demo ma być **tą samą aplikacją** z blokadą treści.
- **Apple 2.3.7**: nazwa/podtytuł nie mogą zawierać informacji o cenie → **nie dopisujemy „Free to try”/„Darmowe” do nazwy**. Apple sam pokazuje „In-App Purchases”. W opisie: pierwszy akapit „Pierwsze zlecenia za darmo; jedna płatność odblokowuje całość. Bez reklam i subskrypcji” (wzór: Unlokee, Vale & Daughter).
- **Family Sharing (Apple)**: dla non-consumable IAP włączane **per produkt** w App Store Connect, **nieodwracalnie** ([App Store Connect Help](https://developer.apple.com/help/app-store-connect/configure-in-app-purchase-settings/turn-on-family-sharing-for-in-app-purchases)). Rekomendacja: włączyć dla „Pełnej wersji” i dodatków (gest premium, mały koszt).
- **Google Play**: brak natywnego „triala” dla aplikacji płatnych → ten sam model: darmowa aplikacja + jednorazowy produkt w aplikacji. **Family Library historycznie nie obejmuje zakupów w aplikacji** (tylko płatne aplikacje); to minus modelu IAP na Androidzie. Do potwierdzenia w aktualnej pomocy Play Console.
- **Wiek/oceny**: Apple od 2025 r. ma progi 4+/9+/13+/16+/18+ i nowy kwestionariusz (obowiązkowy przy aktualizacjach). Podobne gry: Unlokee 4+ / PEGI 3, Vale & Daughter 4+, Shear Line 9+ (heist + reklamy), Lockpick 101 PEGI 3–7 (rozbieżne odczyty). **Oczekiwany wynik dla nas: 4+ / PEGI 3** (brak przemocy; ślusarz legalny).

### 3.3 Rekomendacja (decyzja właściciela)
**Darmowa aplikacja z demem + jednorazowy IAP „Pełna wersja”, później płatne dodatki z rodzinami zamków; Family Sharing włączone.** Apple Arcade jako opcjonalny pitch równoległy (nie blokuje planu).

**Cena „Pełnej wersji” na start:**
| Rynek | Cena | Uzasadnienie |
|---|---|---|
| US | **$5.99** | Między Vale ($4.99) a Unlokee ($7.99); jak Monument Valley 3; niżej niż Golden Idol/ALttL, bo MVP ma mniej treści (tylko Tryb Ciągły) |
| EU (EUR) | **5,99 €** | ten sam próg cenowy Apple w EUR (VAT w cenie) |
| PL | **24,99 zł** | próg jak Strange Horticulture; Mini Metro $3.99 = 19,99 zł, więc $5.99 ≈ 29,99 zł, ale siła nabywcza i rynek ojczysty uzasadniają niższy próg |

- Dodatki (rodziny zamków): **$2.99 / 2,99 € / 12,99–14,99 zł** każdy, ewentualnie pakiet „wszystko” z rabatem. Tryb Zleceń jako duża darmowa aktualizacja dla posiadaczy pełnej wersji (buduje dobrą wolę i recenzje) albo jako większy dodatek ($3.99) — do decyzji po MVP.
- Promocja premierowa −30–40% przez pierwszy tydzień, pre-order na iOS.
- Demo: Tryb Ciągły w ograniczonym zakresie (np. pierwsza rodzina zamków + tryb „w ciemności” dostępny od razu). **Dostępność nigdy za paywallem.**

---

## 4. Ryzyka

| # | Ryzyko | P-stwo | Wpływ | Mitigacja |
|---|---|---|---|---|
| R1 | **Kolizja nazwy „Lockwright”** (gra na lockwright.app, firma ślusarska @LockWright, zajęte .com/.app) | wysokie (już zaistniało) | wysoki | §5.4: decyzja właściciela teraz; zgłoszenie znaku EUIPO przed zapowiedzią; alternatywy nazw na liście rezerwowej |
| R2 | **Konkurencja w rdzeniu** (Unlokee: dwa palce + przekrój + demo/$7.99; Vale: blind mode) | wysokie | wysoki | Wyróżniać się ramą (pogotowie, klienci, Gablota), tonem i pełną dostępnością (VoiceOver); nie reklamować „pierwsza gra w ciemności” |
| R3 | **Realizm kontra zabawa**: prawdziwe otwieranie bywa żmudne i losowe | wysokie | wysoki | Tolerancje strojone pod grywalność; czytelny feedback w 3 kanałach; krzywa trudności; „Asysta” (szersze tolerancje) bez kar; playtesty z metryką czasu na zamek |
| R4 | **Odkrywalność premium na mobile** (małe nisze, F2P dominuje wyszukiwanie) | wysokie | wysoki | Demo w „free”; ASO na „lock picking”, „locksmith”; pitch do Apple (Today/Arcade); prasa dostępnościowa (AppleVis), PC Gamer lubi „każdy zamek inny”; krótkie wideo z dźwiękiem (TikTok/Shorts); wishlist/pre-order |
| R5 | **Fragmentacja haptyki Androida** (różne silniki, brak prymitywów `VibrationEffect.Composition` na wielu urządzeniach, API < 30) | wysokie | średni | Tier haptyki z detekcją (`areAllPrimitivesSupported`), fallback na amplitude/waveform, zawsze dźwięk + obraz; lista urządzeń testowych; Android jako drugi |
| R6 | **iPad bez Core Haptics** (`supportsHaptics == false` na iPadach) | pewne | średni | Na iPadzie: dźwięk (słuchawki) + wizualny „puls”; nie obiecywać haptyki na iPadzie w opisie; ewentualnie kontroler z haptyką |
| R7 | **Polityki sklepów / ocena wiekowa** | niskie | średni | Apple: brak zakazu tematu; ryzyko tylko przy „solicit, promote, or encourage criminal… behavior” (wstęp do sekcji 5). Google: polityka „Illegal Activities” nie wymienia lockpickingu; w sklepie są aplikacje-kursy. Legalny ślusarz, zero marek, 4+/PEGI 3. Uczciwe odpowiedzi w kwestionariuszu Apple 2025+ i IARC |
| R8 | **Ryzyko „instrukcji” (prawne/PR)**: gra odebrana jako kurs włamywania | średnie | średni | Mechanizmy wymyślone, encyklopedyczne; zero nazwanych produktów i marek; komunikat „to gra, nie kurs”; ślusarz weryfikuje prawo do lokalu; brak „szybkich trików” do realnych zamków; przegląd tekstów przez osobę z locksportu (etyka: „nie otwieraj zamków, których nie posiadasz”) |
| R9 | **Monotonia** (jeden mechanizm) | średnie | wysoki | Rodziny zamków zmieniają zasadę gry, narzędzia z warsztatu, modyfikatory (zimno, rdza), rytm sesji 3–5 min; Tryb Zleceń daje kontekst; „Lockpicks-11” jako wzór różnorodności |
| R10 | **Zakres treści** (ambicja „rośnie latami” kontra mały zespół) | wysokie | wysoki | MVP = tylko Tryb Ciągły + 1–2 rodziny; pipeline danych zamków (procedury/parametry zamiast ręcznych assetów); dodatki tylko po walidacji konwersji demo→zakup |
| R11 | **Lokalizacja** (PL+EN od dnia 1; gra na dźwięku: VoiceOver w wielu językach, długie teksty Gabloty) | średnie | średni | i18n od początku; Gablota krótkie notki; kolejne języki (DE, FR, ES, JA) po MVP; Unlokee ma 24 języki — konkurencyjna presja |
| R12 | **Dostępność obiecana, a niedowieziona** (gracze niewidomi szybko to wytkną) | średnie | wysoki | Testerzy niewidomi od prototypu; VoiceOver/TalkBack w kryteriach akceptacji; nie reklamować, zanim nie przejdzie testów |
| R13 | **Opór wobec IAP „pełnej wersji”** (recenzje „nie jest darmowe”) | średnie | niski | Pierwszy akapit opisu i ekran demo mówią jasno, co jest darmowe i ile kosztuje całość |

---

## 5. Sprawdzenie tytułu „Lockwright”

Informacyjnie, nie porada prawna. Przed zapowiedzią warto zlecić rzecznikowi patentowemu wyszukiwanie z oceną podobieństwa.

### 5.1 Sklepy i platformy

| Gdzie | Zapytania | Wynik |
|---|---|---|
| App Store (US, GB; API iTunes Search) | Lockwright, „lock wright”, Lockright | **Brak aplikacji o tej nazwie.** Same aplikacje do zamków smart (Lockly, Master Lock…). PL: API zwróciło błąd, do ponowienia |
| Google Play (US) | lockwright, „lockwright escape room” | **Brak.** Najbliższe: *Keepwright* (KAYAC, 10 tys.+), *Vaultright*, *Lockrig* |
| Steam (storesearch) | lockwright, lockright, „lock wright” | **Brak** |
| itch.io | lockwright, lockright, „lock wright” | **Brak dokładnego trafienia** (26 luźnych: *The Tempering of Lockbright*, *Loopwright*, autorzy *Lorewright*, *Larkwrighter*, *Loomwright*) |
| Web | „Lockwright” game | **Gra przeglądarkowa „Lockwright” na lockwright.app** (patrz początek dokumentu). Wyszukiwarka jej jeszcze nie indeksuje; znaleziona przez RDAP + wejście na stronę |

### 5.2 Znaki towarowe

| Rejestr | Co sprawdzono | Wynik |
|---|---|---|
| **USPTO** (API tmsearch.uspto.gov, pole wordmark) | lockwright, „lock wright”, lockright, lockwrite, lock*right, lokwright | **LOCKWRIGHT: 0 wyników.** LOCKWRITE (kl. 16, długopis z kluczykiem do kajdanek, LockWrite LLC, zarejestrowany). LOCKRIGHT (kl. 36, PNC Mortgage, porzucony 1997). Nic w kl. 9/28/41 |
| **EUIPO eSearch plus / TMview** | API TMview (POST /tmview/api/search) | **Odrzucone przez WAF („Request Rejected”)**; eSearch wymaga JS. **Do sprawdzenia ręcznie**: [TMview](https://www.tmdn.org/tmview/) i [eSearch plus](https://euipo.europa.eu/eSearch/), „Lockwright” + podobne (Lockright, Lockwrite), klasy 9, 28, 41, wszystkie urzędy UE + WIPO |
| **WIPO Global Brand Database** | API branddb | „Missing Authentication Token”, wymaga przeglądarki. **Ręcznie**: [branddb.wipo.int](https://branddb.wipo.int/) |
| **UPRP** | e-Wyszukiwarka | Aplikacja JS, bez API. **Ręcznie**: [ewyszukiwarka.pue.uprp.gov.pl](https://ewyszukiwarka.pue.uprp.gov.pl/) |
| Agregatory (Justia, Markinton — web search) | „Lockwright” trademark | brak rekordów LOCKWRIGHT; najbliżej LOCKWRITE, LOCKWELL, LOCKSWORTH |
| UK Companies House | lockwright | brak spółek o tej nazwie (firma ślusarska z X to prawdopodobnie jednoosobowa działalność; tamtejszy znak niezarejestrowany = ryzyko passing off tylko przy usługach ślusarskich, nie grach) |

### 5.3 Domeny (RDAP / whois, 2026-11-04)

| Domena | Stan | Szczegóły |
|---|---|---|
| lockwright.com | **zajęta** | rej. 2026-01-22 (IONOS), wygasa 2027-01-22; strona-szablon „My Website” → możliwy odkup lub obserwacja wygaśnięcia |
| lockwright.app | **zajęta, aktywna gra** | rej. 2026-10-09 (GoDaddy), Vercel; gra „Lockwright” |
| lockwright.game | wolna (RDAP CentralNic 404) | — |
| lockwright.games | **nieustalone** | RDAP Identity Digital zwracał 429 (limit); sprawdzić u rejestratora |
| lockwright.pl | wolna (RDAP NASK: „Not found”) | — |
| lockwright.be | wolna (API DNS Belgium: `domain.not.found`) | — |
| lockwright.eu | **nieustalone** | EURid nie ma RDAP, whois port 43 zablokowany w sandboxie; sprawdzić na eurid.eu |
| lockwrightgame.com | wolna (RDAP 404) | — |
| playlockwright.com | wolna (RDAP 404) | — |
| lockwright.net / .io | wolne (RDAP 404) | dodatkowo |

### 5.4 Uchwyty (sprawdzone, nie zakładane)

| Serwis | @lockwright | @lockwrightgame |
|---|---|---|
| X / Twitter | **zajęty**: „LockWright”, firma ślusarska (25 lat, usługi domowe/komercyjne) | wolny (404) |
| Instagram | nieustalone (429) | nieustalone (429) |
| TikTok | **zajęty** („Lock Wright”, 0 filmów, 14 obserwujących, konto z 2016) | wolny (statusCode 10221) |
| YouTube | **zajęty** (kanał „lockwright”, pusty) | wolny (404) |
| Bluesky | wolny (lockwright.bsky.social) | wolny |
| Reddit r/lockwright | nieustalone (Reddit wymaga logowania dla automatów) | — |

### 5.5 Ocena i kolejne kroki

**Ocena ryzyka: ŚREDNIE (prawnie) / WYSOKIE (marketing i ASO).** Brak zarejestrowanego znaku LOCKWRIGHT w USPTO i brak aplikacji w sklepach, ale istnieje **gra o tej samej nazwie w tej samej tematyce**, a główna domena i uchwyty są zajęte, w tym przez firmę ślusarską.

Opcje dla właściciela:
- **A. Zostajemy przy „Lockwright”** (D-01): (1) ręczne sprawdzenie TMview/eSearch/WIPO/UPRP (30 min); (2) **niezwłoczne zgłoszenie znaku słownego EUIPO w klasach 9, 28, 41** (opłata urzędowa e-filing: **850 € + 50 € + 150 € = 1 050 €**; sprawdzić dofinansowanie z EUIPO SME Fund, jeśli działa w 2026); opcjonalnie USPTO (ok. $350/klasę od 2025 r.) lub Madryt później; (3) rejestracja domen lockwrightgame.com, playlockwright.com, lockwright.game, .pl, .eu, .be; (4) uchwyty `@lockwrightgame` na X/TikTok/YouTube/Bluesky/Instagram; (5) w sklepie zawsze pełna nazwa z dopiskiem („Lockwright: Emergency Locksmith”), co odróżnia nas od escape roomu; (6) uwaga na zgłoszenia o naruszenie (twórca lockwright.app może sam zgłosić znak — wtedy pierwszeństwo ma data zgłoszenia, a jego wcześniejsze używanie może być argumentem w sprzeciwie).
- **B. Zmiana nazwy teraz** (najtańszy moment: nic nie jest opublikowane). Kryteria nowej nazwy: wolny .com lub .game, brak gry o tej nazwie, wolne uchwyty, wymawialne w PL i EN. Przed wyborem powtórzyć cały §5.

Rekomendacja researchu: **B, jeśli właścicielowi zależy na czystym .com i długim życiu marki; A, jeśli nazwa jest emocjonalnie przesądzona.** W obu wariantach zrobić krok (1) w tym tygodniu.

---

## 6. Źródła (odczyt 2026-11-04, o ile nie podano inaczej)

**Kolizja nazwy i domeny**
- https://lockwright.app (strona, manifest, sitemap, /privacy z 17.10.2026)
- RDAP: https://rdap.org/domain/lockwright.com, https://rdap.org/domain/lockwright.app, https://rdap.centralnic.com/game/domain/lockwright.game, https://rdap.dns.pl/domain/lockwright.pl, https://api.dnsbelgium.be/whois/registration/lockwright.be, https://data.iana.org/rdap/dns.json
- https://x.com/LockWright, https://x.com/lockwrightgame, https://www.tiktok.com/@lockwright, https://www.youtube.com/@lockwright, https://public.api.bsky.app/xrpc/app.bsky.actor.getProfile?actor=lockwright.bsky.social
- USPTO Trademark Search (API): https://tmsearch.uspto.gov/ — LOCKWRITE sn 77396378, LOCKRIGHT sn 75358158
- https://trademarks.justia.com/owners/lockwrite-llc-1501232
- TMview: https://www.tmdn.org/tmview/ (API odrzucone), eSearch plus: https://euipo.europa.eu/eSearch/, WIPO: https://branddb.wipo.int/, UPRP: https://ewyszukiwarka.pue.uprp.gov.pl/
- Companies House: https://find-and-update.company-information.service.gov.uk/search/companies?q=lockwright
- itch.io: https://itch.io/search?q=lockwright, https://itch.io/games/tag-lockpicking
- Opłaty EUIPO (źródła wtórne): https://www.tramatm.com/en/trademark-questions-and-answers/cost-of-trademark-registration/what-is-the-price-for-2-or-more-trademark-classes-in-the-eu, https://tmarkmetric.com/insights/eu-trademark-cost

**Konkurencja — App Store** (API iTunes Search/Lookup + strony aplikacji)
- Unlokee https://apps.apple.com/us/app/unlokee-lock-picking-puzzle/id6808786210
- Vale & Daughter https://apps.apple.com/us/app/vale-daughter-safecracker/id6820067476
- Shear Line https://apps.apple.com/us/app/shear-line-lockpicking-game/id6816888965
- Key Master https://apps.apple.com/us/app/key-master-locksmith-sim/id6809031242
- Safe Cracker: Feel the Hinge https://apps.apple.com/us/app/safe-cracker-feel-the-hinge/id6814453821
- Safecracker: The Hinge Heist https://apps.apple.com/us/app/safecracker-the-hinge-heist/id6825358652
- Crown Heist https://apps.apple.com/us/app/crown-heist-safe-cracker/id6762077725
- The Impossible Safe https://apps.apple.com/us/app/the-impossible-safe-crack-it/id1573468310
- Lock Pick 3D https://apps.apple.com/us/app/lock-pick-3d/id1517044820
- Unlocking! https://apps.apple.com/us/app/unlocking/id6455174981
- Tumbler Wizard (usunięta) https://appgoblin.info/apps/6756764419
- 12 LOCKS https://apps.apple.com/us/app/12-locks/id1504871805
- Thief Simulator mobile https://apps.apple.com/us/app/thief-simulator-sneak-steal/id6456607771
- Safe Cracker – Watch Game https://apps.apple.com/us/app/safe-cracker-watch-game/id1638618972
- Unloop https://apps.apple.com/us/app/unloop/id1632256862 · https://www.tapsmart.com/games/review-unloop/

**Konkurencja — Google Play**
- https://play.google.com/store/apps/details?id=com.Avarice.Lockpick101
- https://play.google.com/store/apps/details?id=com.dmitriyrozhkov.unlokee
- https://play.google.com/store/apps/details?id=com.crystllabs.tumbler
- https://play.google.com/store/apps/details?id=com.mmdevstudio.picklock
- https://play.google.com/store/apps/details?id=com.brotherhoodapp.picklock
- https://play.google.com/store/apps/details?id=com.peaksel.openthesafebox_3dsafebreaker_thevault
- https://play.google.com/store/apps/details?id=com.puzzlejay.locksmithmaster
- https://play.google.com/store/apps/details?id=com.fekent.dndlockpick
- https://play.google.com/store/apps/details?id=com.Kayac.Keepwright

**Konkurencja — Steam / web**
- https://store.steampowered.com/app/1651780/ (Sophie's), https://store.steampowered.com/app/1735110/ (Museum of Mechanics), https://store.steampowered.com/app/704850/ (Thief Simulator), https://store.steampowered.com/app/3414920/ (Lobsterpunk), https://store.steampowered.com/app/3957670/ (Lobsterpunk Demo), https://store.steampowered.com/app/3188360/ (True Thief), https://store.steampowered.com/app/5069860/ (Shear line PC), https://store.steampowered.com/app/1487060/ (Locksmith Simulator), https://store.steampowered.com/app/2607430/ (Lair of the Locksmith)
- PC Gamer o Lockpicks-11 (5.09.2026): https://www.pcgamer.com/games/puzzle/this-free-lockpicking-puzzler-you-can-play-in-your-browser-is-unexpectedly-one-of-the-most-thrilling-games-ive-encountered-this-year/
- Lock Craker: https://magesinstitute.itch.io/lockcraker
- Gry audio: https://www.perkins.org/resource/audio-games-for-blind-low-vision-gamers/, https://applevis.com/forum/ios-ipados-gaming-0, https://www.audiogames.net/ (403 dla automatów)

**Model biznesowy i polityki**
- App Store Review Guidelines (2.2, 2.3.6, 2.3.7, 3.1.1, 1.1.3, sekcja 5): https://developer.apple.com/app-store/review/guidelines/
- Family Sharing IAP: https://developer.apple.com/help/app-store-connect/configure-in-app-purchase-settings/turn-on-family-sharing-for-in-app-purchases, https://developer.apple.com/documentation/storekit/supporting-family-sharing-in-your-app
- Nowe oceny wiekowe Apple: https://9to5mac.com/2025/07/24/apple-notifies-developers-of-new-app-store-age-rating-system/, https://www.pocketgamer.biz/apple-overhauls-app-store-age-ratings-with-new-categories
- Google Play — Inappropriate Content: https://support.google.com/googleplay/android-developer/answer/9878810; Illegal Activities: https://support.google.com/googleplay/android-developer/answer/9878877
- Google Play Family Library (IAP wyłączone, stan 2016): https://www.androidpolice.com/2016/05/18/family-library-for-google-play-purchases-is-official-app-purchases-will-be-shared-among-up-to-six-family-members-starting-july-2nd/
- Ceny premium: Mini Metro https://apps.apple.com/us/app/mini-metro/id837860959 (PL https://apps.apple.com/pl/app/mini-metro/id837860959), ISLANDERS: Mobile https://apps.apple.com/us/app/islanders-mobile/id6745312000, Gorogoa https://apps.apple.com/us/app/gorogoa/id1269225754, The Room: Old Sins https://apps.apple.com/us/app/the-room-old-sins/id1286676015, Strange Horticulture https://apps.apple.com/pl/app/strange-horticulture/id6450008138, A Little to the Left https://apps.apple.com/us/app/a-little-to-the-left/id1613352146, Monument Valley 3 https://apps.apple.com/pl/app/monument-valley-3/id6443563379, The Case of the Golden Idol https://apps.apple.com/us/app/the-case-of-the-golden-idol/id6443831605

**Nie udało się automatycznie (do ręcznego sprawdzenia):** TMview/eSearch plus, WIPO GBD, UPRP, lockwright.eu, lockwright.games, Instagram, r/lockwright, baza AudioGames.net, App Store PL dla „lock wright”/„lockright”.
