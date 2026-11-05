# Klasyfikacja wiekowa — App Store i IARC (Google Play)

Status: szkic do akceptacji · 2026-11-04. Cel: **App Store 4+ · PEGI 3 · ESRB E (Everyone) · USK 0** (plus IARC 3+, ClassInd L, ACB G).

Brzmienie pytań odtwarzamy z kwestionariusza Apple po zmianie z 2025 r. (progi 4+/9+/13+/16+/18+,
obowiązkowy od 31 I 2026) i z kwestionariusza IARC w Play Console. **W dniu wypełniania porównać z
formularzem**, bo oba są zmieniane bez zapowiedzi. Odpowiedzi muszą opisywać **wersję wysyłaną do
sklepu**, a nie plany. Gdy wejdzie Tryb Zleceń (`JOBS.md`), trzeba przejść kwestionariusze jeszcze raz (§4).

---

## 1. App Store Connect — Age Rating

### 1.1 In-App Controls
| Pytanie | Odpowiedź | Uzasadnienie |
|---|---|---|
| Parental Controls | **No** | Gra nie ma kontroli rodzicielskiej. Nie jest potrzebna, bo nie ma treści ani funkcji, które trzeba ograniczać. Zakup (jeśli D-06 = wariant A) blokuje systemowe „Ask to Buy” i Screen Time. |
| Age Assurance | **No** | Nie weryfikujemy wieku i nie mamy kont. |

### 1.2 Capabilities
| Pytanie | Odpowiedź | Uzasadnienie |
|---|---|---|
| Unrestricted Web Access | **No** | Gra nie ma przeglądarki ani WebView. Ewentualny link do polityki prywatności otwiera się w zewnętrznej przeglądarce systemu. |
| User-Generated Content | **No** | Gracz nie tworzy ani nie publikuje treści. „Zamek dnia” (jeśli w 1.0) daje tekst wyniku do systemowego arkusza „Udostępnij”, a gra niczego nie publikuje. |
| Messaging and Chat | **No** | Brak komunikacji między graczami. |
| Advertising | **No** | Brak reklam (zasada projektu). |

### 1.3 Mature Themes
| Pytanie | Odpowiedź | Uzasadnienie |
|---|---|---|
| Profanity or Crude Humor | **None** | Suchy humor ślusarza, bez wulgaryzmów i żartów fizjologicznych. |
| Horror/Fear Themes | **None** | Spokojna klatka schodowa, ciepłe światło. Tryb „w ciemności” to wygaszony ekran, a nie straszenie: brak jump scare’ów, potworów, napięcia grozy. |
| Alcohol, Tobacco, or Drug Use or References | **None** | Brak. Przy pisaniu dialogów zleceń pilnować, żeby klient nie był „po imprezie”. |

### 1.4 Medical or Wellness
| Pytanie | Odpowiedź | Uzasadnienie |
|---|---|---|
| Medical or Treatment Information | **None** | Brak. |
| Health or Wellness Topics | **No** | Gra nie ma funkcji zdrowotnych. „Relaks” nie pada w metadanych jako obietnica zdrowotna. |

### 1.5 Sexuality or Nudity
| Pytanie | Odpowiedź |
|---|---|
| Mature or Suggestive Themes | **None** |
| Sexual Content or Nudity | **None** |
| Graphic Sexual Content and Nudity | **None** |

### 1.6 Violence
| Pytanie | Odpowiedź | Uzasadnienie |
|---|---|---|
| Cartoon or Fantasy Violence | **None** | Jedyne „zniszczenie” to pęknięty wytrych (narzędzie). Nikt nie jest raniony. |
| Realistic Violence | **None** | Jak wyżej. Wiertarka w Trybie Zleceń (D-09) niszczy wkładkę zamka, nie osobę. |
| Prolonged Graphic or Sadistic Realistic Violence | **None** | |
| Guns or Other Weapons | **None** | Wytrych, napinacz, lupa i wiertarka warsztatowa nie są bronią i nie są używane przeciw nikomu. |

### 1.7 Chance-Based Activities
| Pytanie | Odpowiedź | Uzasadnienie |
|---|---|---|
| Simulated Gambling | **None** | Brak kasyna, ruletki, automatów. Losowość generatora zamków to układ łamigłówki, a nie zakład. |
| Contests | **None** | Rankingi „Jeden wytrych” i „Na czas” są lokalne, bez nagród. |
| Gambling (real money) | **No** | |
| Loot Boxes | **No** | Monet nie da się kupić, nie ma skrzynek ani losowych nagród za pieniądze. |

### 1.8 Pozostałe ustawienia
| Pole | Wartość |
|---|---|
| Made for Kids | **Nie zaznaczać.** Gra jest dla wszystkich, ale nie jest projektowana dla dzieci (patrz `privacy.md` §5). Kategoria Kids pociąga za sobą wymogi 1.3, których nie potrzebujemy. |
| Age Rating Override (podniesienie progu) | **Nie** (zostaje wynik kwestionariusza). |
| Age Suitability URL | Opcjonalne. Można podać stronę „O grze” z notką „to gra, nie kurs”. |
| **Oczekiwany wynik** | **4+** |

---

## 2. IARC (Google Play Console → Content rating)

Kategoria aplikacji: **Game** (Gra). Adres e-mail do certyfikatu IARC: `ratings@<domain-tbd>` (do uzupełnienia, ten sam co kontakt w sklepie).

| Kategoria IARC | Pytanie (skrót) | Odpowiedź | Uzasadnienie |
|---|---|---|---|
| **Violence** | Czy gra zawiera przemoc (w tym kreskówkową, fantastyczną, realistyczną), krew, zabijanie ludzi lub zwierząt? | **No** na wszystkie | Pękający wytrych to jedyna „szkoda”. |
| **Fear** | Czy zawiera sceny lub dźwięki mogące przestraszyć małe dzieci (groza, potwory, nagłe wstrząsy)? | **No** | Tryb „w ciemności”: ekran czarny, ale bez straszenia. Dźwięki metalu są ciche i mechaniczne. Uwaga: dźwięk „break” (trzask) jest krótki i nieprzerażający, nie projektować go jako jump scare. |
| **Sexuality** | Nagość, treści seksualne, aluzje? | **No** | |
| **Gambling** | Symulowany hazard, prawdziwe pieniądze, mechaniki losowe za pieniądze (loot boxy)? | **No** | |
| **Language** | Wulgaryzmy, obraźliwy język, dyskryminacja? | **No** | |
| **Controlled Substances** | Alkohol, tytoń, narkotyki (użycie, odniesienia)? | **No** | |
| **Crude Humour** | Humor fizjologiczny, wulgarny? | **No** | |
| **Criminal / illegal acts** (jeśli formularz pyta o „encouragement of criminal activity” lub „depictions of illegal acts”) | Czy gra pokazuje lub zachęca do przestępstw? | **No** | Gracz jest legalnym ślusarzem i otwiera zamki na zlecenie osób, które mają prawo do lokalu. W 1.0 nie ma scen przestępstw. Patrz §3. |
| **Miscellaneous: User interaction** | Czy użytkownicy mogą się komunikować lub wymieniać treści? | **No** | Brak czatu i UGC. Wynik „Zamka dnia” jako tekst przez systemowy arkusz udostępniania to akcja użytkownika poza grą. Jeśli formularz pyta o „share content to social media”, odpowiedzieć **Yes** z tym opisem (nie zmienia oceny wiekowej). |
| **Shares location** | Czy aplikacja udostępnia fizyczną lokalizację innym? | **No** | Brak uprawnień lokalizacji. |
| **Digital purchases** | Czy można kupować dobra cyfrowe? | **No** (wariant „płatna aplikacja”) / **Yes** (wariant A: jednorazowe odblokowanie pełnej wersji) | Wariant A dodaje deskryptor **„In-Game Purchases”** (PEGI, ESRB, USK, IARC). Nie zmienia wieku. |
| **Unrestricted internet** | Czy można przeglądać internet bez ograniczeń? | **No** | |
| **Random items for purchase (loot boxes)** | | **No** | |
| **Is the app a web browser or search engine / news / social?** | | **No** | |

**Oczekiwany wynik:** PEGI 3, ESRB E (Everyone), USK 0 (ab 0 freigegeben), ClassInd L, ACB G, IARC 3+.
W wariancie A z dopiskiem „In-Game Purchases” / „Zakupy w grze”.

---

## 3. Ryzyko: „lock picking” odebrany jako technika przestępcza

**Ocena: niskie ryzyko odrzucenia, średnie ryzyko PR i ręcznej weryfikacji** (por. `RESEARCH.md` R7, R8).

Skąd ryzyko:
- Apple, wstęp do sekcji 5: aplikacje nie mogą „solicit, promote, or encourage criminal or clearly reckless behavior”. Recenzent może skojarzyć lockpicking z włamaniem, zwłaszcza po zrzutach z drzwiami mieszkania.
- Google Play, polityka „Illegal Activities” i „Dangerous Products”: zakaz ułatwiania działań nielegalnych i instrukcji czynności niebezpiecznych. Lockpicking nie jest w nich wymieniony, a w sklepie są aplikacje-kursy i gry o sejfach.
- Konkurencja z ramą „heist” (Shear Line: 9+) pokazuje, że rama kradzieży podnosi ocenę i ryzyko. Naszą ramą jest pomoc.

Jak odpowiadamy (i co pokazać recenzentowi):
1. **Rama legalnego zawodu.** Gracz to ślusarz z pogotowia zamkowego, który pomaga ludziom zatrzaśniętym przed własnymi drzwiami. Opis sklepu i pierwsze zrzuty to pokazują („Ktoś stoi pod drzwiami bez kluczy. Dzwonią po ciebie.”).
2. **Weryfikacja prawa do lokalu.** Ślusarz sprawdza, czy klient ma prawo wejść. W Trybie Zleceń odmowa podejrzanego zlecenia jest nagradzana, a otwarcie bez weryfikacji karane (`JOBS.md` §2–3). W 1.0 zasada jest w notce „O grze” i w opisie sklepu.
3. **Mechanizmy wymyślone, poziom encyklopedyczny.** Żadnych marek zamków i aut, żadnych nazwanych produktów, żadnych „trików na model X”. Proporcje są zmienione dla czytelności (szczelina 0,2 mm zamiast ok. 0,05 mm). Wiedza w grze nie przenosi się wprost na realny zamek.
4. **Notka „to gra, nie kurs”** w ekranie „O grze” (`game/i18n/strings.csv`, klucz `about.notice`) i w opisie sklepu.
5. **Brak estetyki złodzieja.** Bez kominiarek, nocnych włamań, łupów, uciekania przed policją. Policja w Zleceniach jest uprzejma i zwyczajna (`JOBS.md`).
6. **Gablota** to historia i kontekst muzealny ze źródłami, a nie poradnik.

Notatka dla recenzenta Apple (App Review Information → Notes), gotowa do wklejenia:

> Lockwright is a puzzle game about a professional emergency locksmith who helps people locked out of their own homes. All lock mechanisms are fictional and simplified for readability; no real products or brands are depicted, and nothing in the game is a technique for a real, named lock. The locksmith character always checks that the customer has the right to enter, and the in-game "About" screen states: "This is a game, not a course." The game is fully offline, has no ads, no accounts, and collects no data. Haptics are a core feature but never the only signal (all cues are also audible and visible).

Uwaga: celowo „professional”, a nie „licensed”: w PL ślusarz nie jest zawodem licencjonowanym (`JOBS.md` §1.1).

---

## 4. Kiedy przejść kwestionariusze ponownie

| Zmiana | Wpływ |
|---|---|
| Tryb Zleceń (dialogi z klientami, odmowa, policja, wiertarka) | Prawdopodobnie bez zmiany (4+/PEGI 3), ale pytania o „Mature or Suggestive Themes” i „criminal acts” odpowiadać świadomie. Sceny z podejrzanymi klientami są symboliczne i nie pokazują przestępstwa (`JOBS.md`). Przegląd tekstów przed wysyłką. |
| Zakup w aplikacji (wariant A D-06) | Deskryptor „In-Game Purchases”, wiek bez zmian. |
| Ranking online, Game Center, udostępnianie wyników z poziomu gry | Pytania o UGC/interakcję, prywatność (`privacy.md`). |
| Dowolny SDK sieciowy (analityka, crash reporting) | Najpierw `privacy.md`, potem odpowiedzi w obu formularzach. |

---

## 5. Stan na 2026-11-05 (etap 3): Tryb Zleceń jest w grze — odpowiedzi po przeglądzie treści

Gra ma już 29 zleceń z dialogami (`game/i18n/content.csv`, `data/jobs/`), w tym 3 zlecenia do odmowy
(`job.refuse_aunt_alive`, `job.refuse_ex_partner`, `job.refuse_rush_bribe`): ktoś próbuje wejść do cudzego mieszkania,
ślusarz odmawia, proponuje telefon do rodziny lub na policję. Przejrzałem teksty pod kątem kwestionariuszy (§4).

| Pytanie | Było | Teraz | Dlaczego |
|---|---|---|---|
| Apple: Mature or Suggestive Themes | None | **None** | Odmowa jest spokojna, bez gróźb i przemocy; rozstanie pary (`refuse_ex_partner`) to tło, bez konfliktu na ekranie. |
| Apple: Violence (Realistic / Cartoon) | None | **None** | Brak. |
| IARC: Criminal / illegal acts | No | **No** (z opisem) | Gra pokazuje **próbę** nakłonienia do otwarcia cudzego lokalu i propozycję łapówki (`refuse_rush_bribe`: „Podwójna stawka…”), ale gracz nie może jej przyjąć — jedyna akcja to odmowa (+ reputacja). Jeśli formularz pyta „does the game reference or depict illegal activity”, odpowiedzieć **Yes — reference, not depicted or rewarded**; ocena nie powinna wzrosnąć ponad PEGI 3/7. Wariant ostrożny: jeżeli kwestionariusz potraktuje „bribery” jako odniesienie do przestępstwa, możliwe **PEGI 7 / USK 6** — wtedy rozważyć złagodzenie linii o stawce (decyzja treściowa, sesja B / właściciel). |
| IARC: Language | No | **No** | Sprawdzone: brak wulgaryzmów w PL i EN. |
| Apple: Contests / Gambling | None | **None** | Monety tylko z pracy, brak losowania. |

**Oczekiwany wynik bez zmian:** 4+ / PEGI 3 / ESRB E / USK 0 — z zastrzeżeniem wariantu ostrożnego wyżej.

## 6. Pozostałe deklaracje (do wypełnienia w konsolach)

### 6.1 Google Play Console → App content
| Deklaracja | Odpowiedź | Uwagi |
|---|---|---|
| Privacy policy URL | `[URL strony /privacy.html — do uzupełnienia]` | strona gotowa w `site/` (publikacja czeka na zgodę) |
| Ads | **No, my app does not contain ads** | |
| App access | **All functionality is available without special access** | brak logowania |
| Content rating | kwestionariusz IARC §2 i §5 | e-mail do certyfikatu: `[ratings@domena]` |
| Target audience and content | grupy wiekowe **13–15, 16–17, 18+** | Zaznaczenie grup poniżej 13 lat włącza program „Families” (wymogi i przegląd). Gra jest odpowiednia dla dzieci (PEGI 3), ale nie jest do nich kierowana (`privacy.md` §5). „Appeals to children?” → **No** (bez postaci dziecięcych, bez stylistyki dla dzieci). Decyzja właściciela, jeśli chce rynku rodzinnego. |
| News app | No | |
| COVID-19 contact tracing / status | No | |
| Data safety | `privacy.md` §4: **No data collected, no data shared** | |
| Government app | No | |
| Financial features | **My app doesn't provide any financial features** | |
| Health apps | No | |
| Advertising ID (Android 13+) | **No** | brak uprawnienia `AD_ID` w manifeście — sprawdzić w eksporcie release |

### 6.2 App Store Connect
| Pole | Odpowiedź | Uwagi |
|---|---|---|
| Export Compliance (`ITSAppUsesNonExemptEncryption`) | **NO** — gra nie używa szyfrowania poza systemowym | dodać klucz do Info.plist w presecie iOS, żeby nie pytało przy każdej kompilacji |
| Content Rights | **Does not contain, show, or access third-party content** | grafiki i dźwięki własne, fonty OFL (`docs/ASSETS.md`) |
| Age Rating | §1 + §5 | |
| App Privacy | `privacy.md` §3: **Data Not Collected** | |
| Privacy Policy URL | `[URL — do uzupełnienia]` | |
| Support URL | `[URL strony /contact.html — do uzupełnienia]` | |
| Copyright | `[© 2026 nazwa właściciela]` | |
| App Review: Sign-in required | **No** | |
| App Review: Notes | tekst z §3 | |
| App Review: Contact | `[imię, nazwisko, telefon, e-mail]` | |
| Kids Category | **nie** | |

### 6.3 Dane właściciela (wspólne)
- [Nazwa wydawcy / sprzedawcy (Apple: Seller name, Google: Developer name)]
- [Adres e-mail kontaktowy publiczny] · [e-mail do IARC] · [telefon dla App Review]
- [Domena strony] → URL-e: polityka prywatności, wsparcie, strona marketingowa
- [Kraj siedziby (DSA: status „trader” w UE — Apple i Google wymagają deklaracji i publicznego adresu, jeśli sprzedajesz jako przedsiębiorca)]
