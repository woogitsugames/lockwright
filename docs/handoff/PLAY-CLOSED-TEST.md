# Google Play — test zamknięty: lista dla właściciela

Stan na 2026-11-09 · inżynier wydania (D-106). Tylko gotowość techniczna i formalna — bez zrzutów, filmów i tekstów
marketingowych. Uzupełnia `docs/handoff/RELEASE-CHECKLIST.md` (T2, S4–S9, L2–L3) i `docs/handoff/TESTY-SKLEPY.md`.
Formularze Play Console zmieniają się bez zapowiedzi — w dniu wypełniania porównać nazwy pól.

## 0. Co już jest zrobione w repo

| Obszar | Stan | Gdzie |
|---|---|---|
| AAB release w CI | ✅ każdy push do `game/**` na `main` i ręcznie (Actions → game-android → Run workflow) buduje `lockwright-release.aab` (artefakt `lockwright-android-release-aab`) | `.github/workflows/game-android.yml` → `release-aab` |
| Podpis kluczem uploadu | ✅ gotowe, **czeka na sekrety** (§1). Bez sekretów AAB jest niepodpisany i Play go nie przyjmie | jw. |
| versionCode / versionName | ✅ `versionCode = 10000 + numer runu` (rośnie z każdym buildem), `versionName` z ostatniego tagu `v*` (+ `-ci.<run>`, gdy HEAD nie jest tagiem). Ręczne nadpisanie kodu: pole `version_code` przy „Run workflow” | §2 |
| target / min SDK | ✅ target 36 (Play wymaga ≥ 35), min 30 (D-10) | `preset.0`, sprawdza `check_aab.py` |
| Tylko 64-bit | ✅ wyłącznie `arm64-v8a` | jw. |
| Strony pamięci 16 KB | ✅ wszystkie 4 biblioteki `.so` wyrównane do 16 KB (wymóg Play dla Androida 15+) | jw. |
| Brak `debuggable` | ✅ szablon release Godota, atrybut nieobecny | jw. |
| R8 / minify | nie dotyczy: kod gry to GDScript w pck + biblioteki natywne; szablon Gradle Godota nie minifikuje Javy (kilkaset KB). Play pokaże ostrzeżenia „brak pliku deobfuskacji” i „brak symboli natywnych” — można zignorować na teście zamkniętym | — |
| Uprawnienia | ✅ tylko `VIBRATE` + `INTERNET` (allowlista w CI) — **`INTERNET` brakowało w AAB do D-106**, głosy by się nie pobierały | `PLAY-DATA-SAFETY.md` §2 |
| Paczki głosów zgodne z polityką Play | ✅ tylko audio (sprawdzane przy budowaniu), HTTPS, SHA-256 | `PLAY-DATA-SAFETY.md` §3 |
| Rozmiar | ✅ AAB 124,9 MB (budżet 185/198 MB, limit bazy Play 200 MB) | `qa/budget/budgets.json` |
| Data safety | ✅ szkic odpowiedzi: „No data collected / shared” | `PLAY-DATA-SAFETY.md` §4 |
| Polityka prywatności PL/EN | 🟡 tekst gotowy i zgodny z grą (D-100 poprawione w D-106); pola `[…]` i 3 znaczniki prawne czekają na właściciela | `store/privacy.md`, `site/public/privacy.html` |
| Klasyfikacja IARC | ✅ szkic odpowiedzi | §3, `store/rating.md` §2, §5 |
| Grupa docelowa | ✅ rekomendacja 13+ | §4 |
| Dostępność | ✅ opis funkcji i ograniczeń | `docs/ACCESSIBILITY.md` |

## 1. Klucz uploadu i sekrety GitHub (robi właściciel, raz)

**Play App Signing** (obowiązkowe dla nowych aplikacji): Google trzyma właściwy klucz podpisu aplikacji, a my podpisujemy
AAB tylko **kluczem uploadu**. Zgubiony klucz uploadu da się zresetować przez Play Console (wniosek o reset), ale
**nazwy pakietu `com.woogitsugames.lockwright` nie da się zmienić po pierwszym wgraniu**.

1. Wygeneruj klucz (Git Bash albo PowerShell; JDK jest w `C:\tools\jdk-17\bin`). Hasło podasz w okienku — nie wpisuj go w linię
   poleceń. Format PKCS12 ma jedno hasło dla magazynu i klucza, a tego wymaga szablon Gradle Godota:
   ```bash
   /c/tools/jdk-17/bin/keytool -genkeypair -v -storetype PKCS12 \
     -keystore lockwright-upload.p12 -alias upload -keyalg RSA -keysize 4096 -validity 10000
   ```
   (Pyta o imię/organizację/kraj — trafiają do certyfikatu, nie do sklepu.) Trzymaj plik **poza repo** (np. w menedżerze
   haseł + kopia offline). `.gitignore` ignoruje `*.p12`, `*.jks`, `upload*.b64`, `lockwright-upload*`.
2. Odcisk certyfikatu (do porównania z Play Console):
   ```bash
   /c/tools/jdk-17/bin/keytool -list -v -keystore lockwright-upload.p12 -alias upload | grep SHA256
   ```
3. Sekrety repozytorium (GitHub → Settings → Secrets and variables → Actions, albo `gh`):
   | Sekret | Wartość |
   |---|---|
   | `ANDROID_KEYSTORE_BASE64` | plik `.p12` w base64 (jedna linia) |
   | `ANDROID_KEYSTORE_PASSWORD` | hasło magazynu (= hasło klucza) |
   | `ANDROID_KEY_ALIAS` | `upload` |
   | `ANDROID_KEY_PASSWORD` | opcjonalny; jeśli ustawiony, musi być równy `ANDROID_KEYSTORE_PASSWORD` (CI to sprawdza) |
   ```bash
   base64 -w0 lockwright-upload.p12 > upload.b64
   gh secret set ANDROID_KEYSTORE_BASE64 -R woogitsugames/lockwright < upload.b64
   gh secret set ANDROID_KEYSTORE_PASSWORD -R woogitsugames/lockwright      # pyta o wartość
   gh secret set ANDROID_KEY_ALIAS -R woogitsugames/lockwright --body upload
   rm upload.b64
   ```
4. Actions → **game-android** → **Run workflow** (main). W podsumowaniu joba `release-aab`: tabela „Release AAB gate”
   (`signed: True`, wersja, uprawnienia) i „Upload certificate” z SHA-256 — ma się zgadzać z punktem 2. Pobierz artefakt
   `lockwright-android-release-aab`.

## 2. Wersje

- `versionCode` = 10000 + `github.run_number` workflow `game-android` (pierwszy build po D-106 ≈ 10242). Każde wgranie do
  Play musi mieć wyższy kod niż wszystkie poprzednie, na każdej ścieżce. Ponowne uruchomienie tego samego runu („Re-run”)
  daje ten sam kod — do nowego wgrania użyj „Run workflow”.
- `versionName`: przed wydaniem 1.0 `0.1.0-ci.<run>`. Wersja „ładna”: `git tag v0.2.0 && git push origin v0.2.0`, potem
  „Run workflow” na tym commicie → `versionName = 0.2.0`. Tagi `voice-packs-*` nie wpływają na wersję (przed D-106 wpływały:
  AAB z runu 241 miał `versionName = oice-packs-98c87b828e16`).
- AAB budowane lokalnie (`tools/local/build_apk.sh --aab`) mają `versionCode = liczba commitów` i nazwę `…-local.<sha>` —
  **nie wgrywać ich do Play**.

## 3. Klasyfikacja treści — kwestionariusz IARC (szkic)

Kategoria: **Game**. E-mail do certyfikatu: adres kontaktowy właściciela (nie wpisujemy go do repo).
Pełne uzasadnienia: `store/rating.md` §2 i §5. Stan treści 2026-11-09: 83 zlecenia (D-104), w tym odmowy podejrzanych zleceń.

| Pytanie (skrót) | Odpowiedź | Uwagi |
|---|---|---|
| Przemoc (kreskówkowa, fantastyczna, realistyczna), krew, krzywdzenie ludzi/zwierząt | **No** | jedyna „szkoda” to pęknięty wytrych lub zniszczona wkładka (wiertarka, D-09) |
| Elementy mogące przestraszyć | **No** | tryb „w ciemności” to wygaszony ekran, bez straszenia |
| Seksualność, nagość, aluzje | **No** | |
| Hazard symulowany / za pieniądze, loot boxy | **No** | monet nie da się kupić |
| Wulgaryzmy, dyskryminacja | **No** | przegląd PL/EN; teksty DE/FR/ES też bez wulgaryzmów |
| Alkohol, tytoń, narkotyki | **No** | skan `game/i18n` PL i EN (alkohol/piwo/wódka/papieros/narkotyki, alcohol/beer/wine/cigarette/drug…): 0 trafień |
| Humor wulgarny | **No** | |
| Odniesienia do przestępstw | **Tak, jeśli formularz pyta o „references”: odniesienie, bez pokazywania i bez nagrody** | odmowy: ktoś próbuje wejść do cudzego lokalu, propozycja „podwójnej stawki”; jedyna akcja gracza to odmowa i propozycja telefonu na policję. Wariant ostrożny wg `rating.md` §5: możliwe PEGI 7 / USK 6 |
| Interakcja użytkowników, czat, UGC | **No** | |
| Udostępnianie lokalizacji | **No** | |
| Zakupy cyfrowe | **No** dla płatnej aplikacji / **Yes** dla wariantu A D-06 (odblokowanie w aplikacji) | deskryptor „In-Game Purchases”, wiek bez zmian |
| Nieograniczony dostęp do internetu | **No** | gra pobiera tylko własne paczki głosów ze stałych adresów; brak przeglądarki/WebView |

Oczekiwany wynik: **PEGI 3 / ESRB E / USK 0 / IARC 3+** (z zastrzeżeniem wariantu ostrożnego).

## 4. Grupa docelowa i dostępność

- **Target audience:** zaznaczyć **13–15, 16–17, 18+**, bez grup poniżej 13 lat (te włączają program Families i jego
  wymogi). „Czy aplikacja może nieumyślnie przyciągać dzieci?” → **No**: fotorealistyczny warsztat, bez stylistyki
  kreskówkowej; postacie dzieci występują tylko jako klienci w zleceniach (np. siedmiolatka z domkiem dla lalek, D-104),
  a gra jest projektowana dla dorosłych miłośników łamigłówek. PEGI 3 i grupa 13+ nie są sprzeczne (`store/privacy.md` §5).
  Jeśli właściciel chce rynku rodzinnego — osobna decyzja przed zaznaczeniem grup < 13.
- **Dostępność:** Play Console nie wymaga deklaracji. Opis funkcji (TalkBack przez własny most D-97, ogłaszanie stanów
  zamka, napisy, ograniczenie ruchu, skala szarości, zamiana kciuków, tryb „w ciemności”) i znanych braków:
  `docs/ACCESSIBILITY.md` (§1.1 — gest TalkBack na samym zamku nie był sprawdzony palcem). Warto dać testerom ten plik jako
  listę rzeczy do sprawdzenia.

## 5. Play Console — kroki po kolei

1. **Konto dewelopera** (play.google.com/console): opłata jednorazowa, weryfikacja tożsamości; konto **osobiste** czy
   **organizacji** (organizacja wymaga D-U-N-S). Ważne: nowe konta osobiste muszą przed produkcją przejść test zamknięty
   z **≥ 12 testerami zapisanymi przez 14 dni z rzędu** (konta organizacji — nie). Nazwa dewelopera i publiczny e-mail
   kontaktowy są widoczne w sklepie; przy sprzedaży w UE dochodzi status „trader” (DSA) z adresem (`RELEASE-CHECKLIST.md` L3).
2. **Decyzja D-06 przed pierwszym wydaniem na jakiejkolwiek ścieżce testów poza wewnętrzną:** aplikacji opublikowanej jako
   **bezpłatna nie da się później zmienić na płatną**. Rekomendacja z D-06 (darmowe demo + jednorazowe odblokowanie) jest
   zgodna z „Free”; płatna aplikacja wymaga ustawienia „Paid” od początku i profilu płatności (merchant).
3. **Klucz uploadu i podpisany AAB** — §1 (bez tego nie ma czego wgrać).
4. **Utwórz aplikację:** nazwa (≤ 30 znaków), język domyślny, **Gra**, **Bezpłatna/Płatna** (pkt 2), oświadczenia
   (zasady programu dla deweloperów, przepisy eksportowe USA).
5. **Panel → „Skonfiguruj aplikację” (App content)**, odpowiedzi gotowe:
   - Polityka prywatności: URL `…/en/privacy.html` — wymaga publikacji strony (D-51) i uzupełnienia pól `[…]` (§6);
   - Dostęp do aplikacji: bez ograniczeń · Reklamy: nie · Identyfikator reklamowy: nie;
   - Klasyfikacja treści: §3 · Grupa docelowa: §4 · Bezpieczeństwo danych: `PLAY-DATA-SAFETY.md` §4;
   - Aplikacje informacyjne / rządowe / finansowe / zdrowotne: nie;
   - Kategoria: **Gry → Łamigłówki**, e-mail kontaktowy (wymagany), opcjonalnie strona WWW.
6. **Test wewnętrzny** (do 100 osób, bez przeglądu, dostępny w kilka minut): Testowanie → Testy wewnętrzne → utwórz wersję →
   przy pierwszej wersji **zaakceptuj Play App Signing** („Google zarządza kluczem podpisywania”) → wgraj AAB z §1 →
   informacje o wersji → zapisz → udostępnij. Lista testerów: adresy e-mail kont Google. Testerzy instalują przez link
   „dołącz do testu”. **Smoke test na telefonie z Play:** start, samouczek, haptyka, pobranie głosów PL przy języku telefonu
   PL (to sprawdza `INTERNET`), Ustawienia → Głosy postaci → Usuń/Pobierz, TalkBack, zapis po aktualizacji z Play.
7. **Strona sklepu (minimum do testu zamkniętego)** — §6.
8. **Test zamknięty:** Testowanie → Testy zamknięte → ścieżka (np. „Alpha”) → kraje → testerzy (lista e-mail albo Grupa
   Google) → adres/URL do opinii → „Promuj wersję” z testu wewnętrznego (ten sam AAB) → wyślij do przeglądu
   (dla nowych kont zwykle kilka dni). Opcjonalnie „Zarządzana publikacja”, żeby samemu wybrać moment udostępnienia.
9. **Przez 14 dni:** ≥ 12 zapisanych testerów (licznik w Play Console), raport przedpremierowy (Pre-launch report: awarie,
   zrzuty, dostępność), Android vitals (crash-free ≥ 99,5% — `RELEASE-CHECKLIST.md` T10). Kolejne buildy: nowe „Run workflow”
   → wyższy `versionCode` → nowa wersja na tej samej ścieżce.
10. **Wniosek o dostęp do produkcji** (Panel → „Zastosuj w wersji produkcyjnej”): pytania o przebieg testu, opinie testerów,
    gotowość. Dopiero potem ścieżka produkcyjna.

## 6. Minimum na stronę sklepu i co jeszcze należy do właściciela

Wymagane pola (wymiary według Play Console): nazwa (≤ 30), krótki opis (≤ 80), pełny opis (≤ 4000), ikona 512×512 PNG
(≤ 1 MB), grafika promocyjna 1024×500, min. 2 zrzuty z telefonu. Stan materiałów (bez nowej pracy marketingowej):
teksty PL/EN w `store/listing.md` (`store/tools/check_lengths.py` OK), ikona `store/icon/play-icon-512.png` (G12 v2 #01, D-50/D-109),
grafika promocyjna i zrzuty — `RELEASE-CHECKLIST.md` S2/S8. Test wewnętrzny działa bez kompletu tych materiałów.

Do uzupełnienia przez właściciela (nie trafia do repo jako dane osobowe ani hasła): nazwa wydawcy, kontakt e-mail,
domena i publikacja `site/` (D-51), data i administrator w polityce prywatności, decyzje przy trzech znacznikach prawnych
(`PLAY-DATA-SAFETY.md` §5), D-06.

## 7. Ryzyka otwarte (stan 2026-11-09)

| Ryzyko | Wpływ | Co zrobić |
|---|---|---|
| D-06 otwarte | wybór Free/Paid przy tworzeniu aplikacji jest jednokierunkowy | zdecydować przed pkt 4 §5 |
| Brak sekretów klucza uploadu | AAB z CI niepodpisany → Play odrzuca | §1 |
| ~~Ikona w telefonie: zastępczy `game/icon.svg`~~ — **zamknięte (D-109):** G12 v2 #01 w presecie (adaptacyjna + monochromatyczna + 192), plansza masek `device-tests/fixes/icon/masks.png` | — | ikona do Play Console: `store/icon/play-icon-512.png` |
| ~~Nazwa pod ikoną „Lockwright: Locksmith on Call”~~ — **zamknięte (D-109):** `package/name="Lockwright"` we wszystkich językach; pełny tytuł w grze i sklepie | — | — |
| Auto Backup wyłączony (`allowBackup=false`) | postęp nie przechodzi na nowy telefon przez kopię Google | decyzja właściciela; włączenie wymaga wykluczenia `user://voice_packs/` (limit 25 MB) |
| Pobieranie głosów w tle bez pytania (D-100) na danych komórkowych | Play: dozwolone (treść, nie kod); Apple 4.2.3 przy iOS — osobna ocena | rozmiar jest pokazywany; ewentualnie ograniczyć do Wi-Fi |
| Hosting głosów na GitHub Releases | dostępność i limity GitHub; zmiana hostingu = zmiana polityki (znacznik 1) | Cloudflare po sygnale właściciela (D-51), `VOICE_PACKS_BASE_URL` |
| IARC „references to crime” | możliwe PEGI 7 / USK 6 zamiast 3 | odpowiadać świadomie (§3); decyzja treściowa przy wyniku |
| Wymogi Play (target API, 16 KB, 12 testerów/14 dni) zmieniają się co rok | odrzucenie aktualizacji | `check_aab.py` (`TARGET_SDK_MIN`), przegląd przed każdym wydaniem |
