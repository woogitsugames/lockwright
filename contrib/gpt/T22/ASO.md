# T22 — ASO: frazy i warianty opisów (PL, EN, DE, FR, ES)

**Data opracowania:** 2026-11-05  
**Projekt:** Lockwright: Pogotowie Zamkowe / Lockwright: Locksmith on Call  
**Status:** rekomendacje do zatwierdzenia, **nie** potwierdzone wyniki wolumenów wyszukiwań ani gotowe zgłoszenie do sklepów.

## 1. Decyzja i pozycjonowanie

**Główne pozycjonowanie:** *spokojna, sensoryczna łamigłówka mechaniczna o pracy legalnego ślusarza*. Pierwsze pole wyszukiwań to mechanika zamków i puzzle; drugie to symulatory rzemiosła; trzecie, eksploracyjne, to gry spokojne/cozy. Nie reklamujemy włamania, napadów, szkolenia do realnych zamków ani produktów konkretnych marek.

Na podstawie `store/listing.md`, `docs/DESIGN.md`, `docs/JOBS.md` i `docs/CLIENTS.md` podstawowa obietnica dotyczy **wymyślonych mechanizmów**, wyraźnego przekroju, sprzężenia przez dźwięk/obraz/haptykę i uważnego tempa. **Tryb Zleceń i sprawdzanie uprawnienia klienta są po MVP** (`docs/JOBS.md`), dlatego wariant fabularny B **nie nadaje się do opisu wydania 1.0, dopóki funkcja nie zostanie dostarczona**.

Model biznesowy jest otwarty (D-06, D-51): żadna propozycja nie zawiera ceny, obietnicy darmowej wersji, daty premiery, dostępności, subskrypcji ani zapewnień o reklamach. Lokalizacje DE/FR/ES są **propozycjami treści marketingowej**, nie dowodem istnienia pełnego tłumaczenia interfejsu.

## 2. Metodologia i ograniczenia danych

1. Przeczytano `CLAUDE.md`, `docs/DESIGN.md`, `docs/CLIENTS.md`, `docs/JOBS.md`, `docs/DECISIONS.md` (D-06, D-32, D-51), `store/listing.md` oraz analizę 29 porównywanych tytułów z `contrib/gpt/T07/`.
2. Sprawdzono oficjalne zasady App Store i Google Play oraz przykłady języka sklepowego. W próbie niemieckojęzycznej pojawiają się *Schloss* i *Denkspiel*, w polskiej *mechaniczne łamigłówki*. To **dowód użycia słownictwa w opisach**, a nie statystyka zapytań konsumentów.
3. Dla każdego języka ułożono hipotezy fraz wyszukiwanych przez graczy. Priorytet **P1** = ścisłe dopasowanie produktu, **P2** = sensowne poszerzenie intencji, **P3** = niszowy eksperyment; **nie** oznacza zmierzonego wolumenu ani trudności.
4. Odfiltrowano nazwy konkurencji i producentów, markowe nazwy mechanizmów, słowa sugerujące heist/kradzież, prawdziwy instruktaż, niezaimplementowane tryby i rankingowe slogany.
5. Sprawdzono kodem **liczbę znaków Unicode** oraz **bajtów UTF-8**. App Store przyjmuje maks. **100 bajtów** w keywords; Google Play dopuszcza maks. **80 znaków** w short description. W App Store przecinki są bez spacji; bez powtórzeń tytułu i podtytułu tam, gdzie są już ustalone.

**Granica badania:** brak dostępu do Apple Search Ads Search Popularity, AppTweak, Sensor Tower, mobile-action, Search Console sklepów czy rzeczywistych danych o konwersji. Nie przedstawiamy wymyślonych wyników, wolumenów ani punktacji konkurencji. Przed publikacją zweryfikować zasięg i trafność w danym storefront.

## 3. Pola gotowe do wklejenia

| Lokalizacja | App Store — znaki | App Store — UTF-8 | Google Play short — znaki | W granicach |
|---|---:|---:|---:|---|
| pl-PL | 88 | 94 / 100 | 63 / 80 | tak |
| en-US | 95 | 95 / 100 | 70 / 80 | tak |
| de-DE | 92 | 94 / 100 | 70 / 80 | tak |
| fr-FR | 90 | 94 / 100 | 78 / 80 | tak |
| es-ES | 91 | 93 / 100 | 64 / 80 | tak |

**Ważne:** Apple indeksuje słowa z tytułu i podtytułu. Dla PL/EN uwzględniono ich zatwierdzone brzmienie ze `store/listing.md`; dla DE/FR/ES należy **ponownie sprawdzić duplikaty**, gdy powstaną lokalne nazwy i podtytuły. W en-GB warto rozważyć *cosy* zamiast *cozy*, ale to osobny test lokalizacyjny.

### pl-PL — polski

**App Store keywords — 88 znaków, 94 bajtów UTF-8:**
```text
ślusarz,wytrych,wkładka,łamigłówka,mechanizm,haptyka,rzemiosło,relaks,warsztat,symulator
```

**Google Play short description — 63 znaków:**
```text
Spokojne łamigłówki ślusarskie. Dwa kciuki, dźwięk i mechanika.
```

**Dlaczego:** Ślusarz i wytrych kotwiczą zawód oraz czynność; wkładka i mechanizm zawężają intencję do mechaniki, nie zamków-budowli; łamigłówka i symulator opisują gatunek, haptyka jest wyróżnikiem, a relaks i warsztat poszerzają zasięg bez sensacji.

| Klaster | Kandydaci i intencja | Priorytet | Uwagi |
|---|---|---|---|
| Mechanika i fach | ślusarz; wytrych; wkładka; mechanizm | P1 | Bliski rdzeń gry i zgodne z jej etycznym kontekstem. |
| Łamigłówki | łamigłówka; symulator | P1 | Frazy gatunkowe; powinny docierać także do osób bez zainteresowania ślusarstwem. |
| Zmysły i spokój | haptyka; relaks; rzemiosło; warsztat | P2 | Pozycjonowanie przez uważność, detal i wyczucie, nie kradzież. |

**Hipotezy dłuższych fraz wyszukiwania (do walidacji; nie są osobnym polem Google Play):**

- **gra o otwieraniu zamków** (P1, mechanika) — Propozycja zapytania szerokiego; sprawdzić udział intencji fantasy/escape room.
- **łamigłówki mechaniczne** (P1, puzzle) — Blisko mechanicznego rdzenia gry; termin występuje w polskich opisach puzzli.
- **symulator ślusarza** (P1, zawód) — Zgodny z rolą bohatera; narracyjne zlecenia są po MVP.
- **gra z wytrychem** (P2, mechanika) — Dobre dopasowanie mechaniki, lecz kontrolować skojarzenia z poradnikami.
- **spokojna gra logiczna** (P2, cozy) — Hipoteza segmentu spokojnej rozgrywki, bez dowodu wolumenu.
- **gra na wyczucie** (P2, zmysły) — Podkreśla zmysłowy interfejs; w App Store pokrywa go podtytuł.

### en-US — English

**App Store keywords — 95 znaków, 95 bajtów UTF-8:**
```text
lockpicking,craft,puzzle,simulator,haptic,tactile,mechanism,workshop,pin,tumbler,cozy,precision
```

**Google Play short description — 70 znaków:**
```text
A calm locksmith puzzle. Explore mechanisms by touch, sound and sight.
```

**Dlaczego:** Lockpicking i puzzle to rdzeń odkrywalności gatunkowej; simulator i craft kierują do graczy lubiących fach oraz proces; haptic/tactile/pin/tumbler precyzują mechanikę; cozy pozostaje dodatkową hipotezą, nie jedyną obietnicą.

| Klaster | Kandydaci i intencja | Priorytet | Uwagi |
|---|---|---|---|
| Mechanical intent | lockpicking; pin; tumbler; mechanism | P1 | Najbliższe rzeczywistym czynnościom w grze, bez nazw marek. |
| Genre and profession | puzzle; simulator; craft; workshop | P1 | Krzyżowanie łamigłówek z rzemiosłem; bez sugerowania nauki realnych obejść. |
| Feel and pacing | haptic; tactile; cozy; precision | P2 | Motyw audio-haptyczny, spokojne podejście i dokładność. |

**Hipotezy dłuższych fraz wyszukiwania (do walidacji; nie są osobnym polem Google Play):**

- **lockpicking puzzle** (P1, mechanics) — Wyrażenie kategorii widoczne w porównywalnych opisach; nie oznacza realnego instruktażu.
- **locksmith simulator** (P1, profession) — Odróżnia legalną usługę od narracji heist; funkcje zleceń po MVP.
- **mechanical puzzle game** (P1, puzzle) — Szeroka, ale spójna intencja gatunkowa.
- **haptic puzzle** (P2, feel) — Cecha różnicująca; sprzęt i wdrożenie trzeba potwierdzić.
- **calm puzzle game** (P2, cozy) — Test segmentu spokojnego grania; nie twierdzenie o wolumenie.
- **precision game** (P3, feel) — Hipoteza niskiej precyzji wyszukiwania; do sprawdzenia.

### de-DE — Deutsch

**App Store keywords — 92 znaków, 94 bajtów UTF-8:**
```text
schlüsseldienst,schlossrätsel,dietrich,mechanik,haptik,handwerk,werkstatt,knobeln,simulation
```

**Google Play short description — 70 znaków:**
```text
Ruhige Schlossrätsel: Spüre den Widerstand und höre auf jedes Klicken.
```

**Dlaczego:** Schlüsseldienst to legalna usługa, a Schlossrätsel wskazuje na zagadkę zamiast na zamki jako budowle; Dietrich jest nazwą ogólną narzędzia; Mechanik/Haptik opisują pętlę, Handwerk/Werkstatt budują ton fachu. Unikamy obietnicy praktycznej nauki otwierania.

| Klaster | Kandydaci i intencja | Priorytet | Uwagi |
|---|---|---|---|
| Legalny fach | Schlüsseldienst; Dietrich; Handwerk; Werkstatt | P1 | Pryzmat usługi i narzędzi; nie romantyzujemy włamania. |
| Mechaniczna zagadka | Schlossrätsel; Mechanik; knobeln; Simulation | P1 | Przesuwa zapytania od niejednoznacznego Schloss ku rozgrywce logicznej. |
| Zmysły | Haptik | P2 | Celuje w wyróżnik, ale bez gwarantowania sprzętowej haptyki. |

**Hipotezy dłuższych fraz wyszukiwania (do walidacji; nie są osobnym polem Google Play):**

- **Schlossrätsel** (P1, puzzle) — Złożenie określa zamek-mechanizm w kontekście łamigłówki.
- **Schlüsseldienst Spiel** (P1, profession) — Szukający symulatora zawodu; zlecenia po MVP.
- **mechanisches Rätsel** (P1, puzzle) — Gatunek odpowiadający przekrojom i precyzji.
- **ruhiges Denkspiel** (P2, cozy) — Spokojny nurt bez etykiety heist.
- **Handwerk Simulation** (P2, profession) — Szeroki segment gier o pracy ręcznej.
- **Dietrich Spiel** (P2, mechanics) — Termin związany z mechaniką; nie oferować instrukcji do prawdziwych zamków.

### fr-FR — français

**App Store keywords — 90 znaków, 94 bajtów UTF-8:**
```text
serrurier,serrure,énigme,casse-tête,mécanique,tactile,atelier,artisanat,détente,simulation
```

**Google Play short description — 78 znaków:**
```text
Des énigmes de serrurier à résoudre par le toucher, l'écoute et l'observation.
```

**Dlaczego:** Serrurier i serrure określają legalny zawód i obiekt; énigme/casse-tête kierują do gatunku; mécanique/tactile do sensorycznej mechaniki; atelier/artisanat/détente wzmacniają spokojny, rzemieślniczy charakter.

| Klaster | Kandydaci i intencja | Priorytet | Uwagi |
|---|---|---|---|
| Profession et objet | serrurier; serrure; atelier; artisanat | P1 | Dobrze opisuje rolę i otoczenie bez sugestii przestępstwa. |
| Puzzle | énigme; casse-tête; simulation | P1 | Łączy intencję łamigłówkową z gatunkiem. |
| Sensation et détente | mécanique; tactile; détente | P2 | Odróżnia sterowanie i tempo gry. |

**Hipotezy dłuższych fraz wyszukiwania (do walidacji; nie są osobnym polem Google Play):**

- **jeu de serrurier** (P1, profession) — Prosta nazwa gatunku, do potwierdzenia na danych wyszukiwarki.
- **casse-tête mécanique** (P1, puzzle) — Podkreśla rozumowanie o mechanizmach.
- **énigme de serrure** (P1, puzzle) — Wąska hipoteza niszowa.
- **jeu tactile** (P2, feel) — Skojarzenie ze sterowaniem przez dotyk.
- **jeu relaxant** (P2, cozy) — Test spokojnego tonu, nie twierdzenie o dynamice pobrań.
- **simulation d'artisan** (P3, profession) — Fraza szeroka; sprawdzić trafność przed inwestycją.

### es-ES — español (España)

**App Store keywords — 91 znaków, 93 bajtów UTF-8:**
```text
cerrajero,cerradura,rompecabezas,acertijo,mecánica,táctil,taller,oficio,relajante,simulador
```

**Google Play short description — 64 znaków:**
```text
Puzles de cerrajería: siente cada mecanismo y escucha sus clics.
```

**Dlaczego:** Cerrajero/cerradura i oficio/taller podkreślają uczciwą pracę; rompecabezas/acertijo obejmują dwa rejestry zagadek; mecánica/táctil zaznaczają mechanizm; relajante kieruje do graczy szukających spokojnego tempa. Rompecabezas jest szeroko rozumiane poza Hiszpanią, puzles naturalniejsze w es-ES.

| Klaster | Kandydaci i intencja | Priorytet | Uwagi |
|---|---|---|---|
| Oficio | cerrajero; cerradura; oficio; taller | P1 | Zawód i przedmiot bez sensacyjnego słownictwa. |
| Puzles | rompecabezas; acertijo; simulador | P1 | Logiczne i symulacyjne aspekty gry. |
| Mecánica tranquila | mecánica; táctil; relajante | P2 | Dotyk i rytm jako wyróżniki. |

**Hipotezy dłuższych fraz wyszukiwania (do walidacji; nie są osobnym polem Google Play):**

- **juego de cerrajero** (P1, profession) — Intencja gry o fachu, a nie kursu otwierania rzeczywistych zamków.
- **rompecabezas de cerraduras** (P1, puzzle) — Opisowa dłuższa fraza logiczna.
- **puzles mecánicos** (P1, puzzle) — Formuła naturalna dla Hiszpanii; sprawdzić wariant LatAm.
- **juego relajante** (P2, cozy) — Segment odpoczynku, bez obietnic medycznych.
- **simulador de cerrajería** (P2, profession) — Niszowy opis symulatora zawodu.
- **juego táctil** (P2, feel) — Test wyróżnika sterowania dotykowego.

## 4. Pierwsze dwa zdania opisu — testy A/B

Trzy osobne **hipotezy komunikacyjne** w każdej lokalizacji: **A — mechanika i uważność (bezpieczny wariant startowy)**, **B — zawód, klient, weryfikacja (tylko po uruchomieniu Trybu Zleceń)**, **C — spokój i rzemiosło (do testu przeciw A na MVP)**. To nie trzy równoczesne zmiany SEO. Wszystkie teksty dotyczą fikcyjnych mechanizmów i nie zawierają instrukcji otwierania rzeczywistych produktów.

### pl-PL

- **A (mechanika):** To nie siła otwiera te wymyślone zamki, lecz cierpliwość. Obserwuj mechanizm, słuchaj kliknięć i wyczuwaj opór.
- **B (klienci — dopiero po MVP):** Ktoś czeka przed drzwiami własnego mieszkania. Zanim pomożesz, sprawdzasz, czy rzeczywiście ma prawo wejść.
- **C (cozy / rzemiosło):** W cichym warsztacie nawet drobny klik ma znaczenie. Poznaj łamigłówki, w których liczą się słuch, dotyk i spokojne tempo.

### en-US

- **A (mechanika):** These fictional locks reward patience, not force. Read the mechanism, listen for the click and feel the resistance.
- **B (klienci — dopiero po MVP):** Someone is locked out of their own home. You can help, but first you must make sure they have the right to enter.
- **C (cozy / rzemiosło):** In a quiet workshop, a tiny click can say a lot. Take your time with careful, tactile mechanical puzzles.

### de-DE

- **A (mechanika):** Diese erfundenen Schlösser öffnen sich nicht mit Gewalt. Beobachte die Mechanik, höre auf das Klicken und spüre den Widerstand.
- **B (klienci — dopiero po MVP):** Jemand steht vor der eigenen verschlossenen Tür. Du hilfst erst, wenn feststeht, dass die Person hinein darf.
- **C (cozy / rzemiosło):** In einer stillen Werkstatt sagt ein leises Klicken oft alles. Nimm dir Zeit für mechanische Rätsel und sorgfältiges Handwerk.

### fr-FR

- **A (mechanika):** Ces serrures imaginaires ne cèdent pas à la force. Observez le mécanisme, écoutez les clics et sentez la résistance.
- **B (klienci — dopiero po MVP):** Quelqu'un ne peut plus rentrer chez soi. Avant d'aider, vous vérifiez que la personne a le droit d'entrer.
- **C (cozy / rzemiosło):** Dans un atelier calme, un petit clic peut tout changer. Prenez votre temps avec des casse-têtes mécaniques.

### es-ES

- **A (mechanika):** Estas cerraduras imaginarias no se abren por la fuerza. Observa el mecanismo, escucha el clic y siente su resistencia.
- **B (klienci — dopiero po MVP):** Alguien se ha quedado fuera de su propia casa. Antes de ayudar, compruebas que tiene derecho a entrar.
- **C (cozy / rzemiosło):** En un taller tranquilo, un pequeño clic lo dice todo. Disfruta de puzles mecánicos a tu ritmo.

## 5. Plan testowania i praktyczne decyzje

1. **Dla MVP:** kontrola A (mechaniczna obietnica) kontra C (spokój/gesty); w każdym kraju testować jedną zmienną i nie przełączać równolegle ikon ani zrzutów. Wariant B włączyć dopiero po faktycznym dodaniu weryfikacji klienta i Trybu Zleceń.
2. **Google Play:** w Store listing experiments testować lokalizowane warianty opisu lub short description, o ile dany typ eksperymentu jest dostępny dla konta/wersji. Główna miara: unikalne instalacje/otwarcia zgodnie z panelem, wspierana oglądalnością karty i stabilnością źródeł ruchu. Nie kończyć po pierwszej różnicy bez odpowiedniego ruchu.
3. **App Store:** nie obiecywać natywnego A/B na *keywords* i tekst pierwszych zdań. Dokumentacja Apple PPO głównie wymienia ikonę, zrzuty i wideo; osobna strona Analytics wspomina też opisy — **sprawdzić faktyczne opcje aktualnego App Store Connect**, zanim nazwiemy test tekstów randomizowanym A/B. W przeciwnym razie porównania kolejnych wydań nie są równoważne testowi kontrolowanemu.
4. **Keywords:** oddzielnie po opublikowaniu sprawdzać widoczność i trafność zapytań na każdy język; przy małym ruchu nie optymalizować wyłącznie pod pozycję. Zmienna *trafny użytkownik* jest ważniejsza niż szerokie słowo związane z zamkiem zamkowym (budowlą).
5. **Kontrola redakcyjna:** native-review de/fr/es; dopasowanie *puzles* (es-ES) vs *rompecabezas* (LatAm), *cozy* vs *cosy* (en-US/en-GB); test telefonów z haptyką i bez; weryfikacja zakresu 1.0, zanim jakąkolwiek obietnicę oznaczymy jako wdrożoną.

### Ryzyka i wyłączenia

- **Nieużyte:** `thief`, `heist`, `burglary`, `break-in`, instruktaż `how to pick a lock`, nazwy konkurencyjnych gier i producentów zamków. `escape room` także nie jest deklarowanym gatunkiem Lockwright, więc nie przechwytujemy tego ruchu.
- **Kategoria 'cozy':** używana jako hipoteza nastroju, nie jako obietnica zerowego stresu, bezstresowego testu czy nowego trybu.
- **Haptyka i dostępność:** nie reklamować pełnej gry bez wzroku ani wsparcia każdego telefonu, zanim nie potwierdzą tego testy rzeczywistej kompilacji i zgodności z czytnikami ekranu.
- **Rozbieżność repozytorium:** `CLAUDE.md` nadal podaje starszy tytuł EN *Emergency Locksmith*, podczas gdy D-32 i `store/listing.md` przyjmują *Locksmith on Call*. T22 trzyma się decyzji D-32; pliku poza własnym katalogiem nie zmieniano.
- **Konflikt nazwy Lockwright:** T07 sygnalizuje użycie tej nazwy w innym projekcie. Ten raport nie jest badaniem prawnym znaku; konieczne niezależne sprawdzenie przed publikacją.

## 6. Źródła (odczyt 2026-11-05)

- [Apple — App Store Connect, platform version information: keywords do 100 bajtów](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information)
- [Apple — Creating Your Product Page: zasady fraz i zakaz nazw konkurencji](https://developer.apple.com/app-store/product-page/)
- [Apple — Product Page Optimization overview: zakres testowania](https://developer.apple.com/help/app-store-connect/create-product-page-optimization-tests/overview-of-product-page-optimization/)
- [Apple — App Store Connect Analytics: sprawdzić rozbieżność dotyczącą opisów](https://developer.apple.com/help/app-store-connect-analytics/acquisition/product-page-optimization)
- [Google Play — Create and set up your app: short description do 80 znaków](https://support.google.com/googleplay/android-developer/answer/9859152?hl=en)
- [Google Play — Best practices for your store listing: brak keyword stuffing](https://support.google.com/googleplay/android-developer/answer/13393723?hl=en)
- [Google Play — Run A/B tests on your store listing](https://support.google.com/googleplay/android-developer/answer/12053285?hl=en)
- [Google Play — przykład polskich opisów gatunku: mechaniczne łamigłówki](https://play.google.com/store/apps/details?hl=pl&id=com.bluebraingames.thehouseofdavinci)
- [Google Play — przykład niemieckich opisów: Schloss, Denkspiel](https://play.google.com/store/apps/details?hl=de&id=com.MetalPop.UnlockIt)
- [Lockwright — wewnętrzny raport T07 o 29 tytułach](https://github.com/woogitsugames/lockwright/blob/main/contrib/gpt/T07/COMPETITORS-2026.md)
- [Lockwright — obowiązujący szkic opisu sklepowego](https://github.com/woogitsugames/lockwright/blob/main/store/listing.md)
- [Lockwright — decyzje D-06, D-32, D-51](https://github.com/woogitsugames/lockwright/blob/main/docs/DECISIONS.md)

**Uwagi metodologiczne:** lokalne frazy EN/DE/FR/ES opracowano językowo z intencji i obserwowanych opisów; **nie wykonano pomiaru autosuggest w pięciu storefrontach ani estymacji popularności fraz**. Wszystkie teksty służą do dalszej walidacji w konsolach sklepów.
