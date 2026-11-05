# Testy wewnętrzne w sklepach — instrukcja dla właściciela (krok po kroku)

Dla Ciebie, nie dla programisty. Cel: zainstalować Lockwright na swoich telefonach (i telefonach kilku zaufanych osób)
**ze sklepu**, zanim gra trafi do wszystkich. Sesja B przygotowuje buildy w CI (`SESSION-B-PROMPT-4.md`: AAB podpisany
kluczem z sekretów, workflow `game-ios-release.yml`); ta instrukcja mówi, co musisz zrobić Ty.

> Ceny, czasy i nazwy przycisków są z listopada 2026 i z dokumentacji Apple/Google — sklepy zmieniają je bez zapowiedzi.
> Jeśli coś wygląda inaczej, szukaj tej samej nazwy w menu. Identyfikator aplikacji w obu sklepach:
> **`com.woogitsugames.lockwright`** (jest już w `game/export_presets.cfg`; po pierwszym wgraniu nie da się go zmienić).

## Czego nie zrobię bez Ciebie (uczciwie)

| Krok | Dlaczego tylko Ty |
|---|---|
| Założenie kont deweloperskich i opłaty | konto jest na Twoje dane i Twoją kartę; wymaga weryfikacji tożsamości (dokument, czasem wideo/telefon) |
| D-U-N-S (jeśli konto na firmę) | wniosek składa właściciel firmy |
| Wygenerowanie i przechowanie klucza podpisu Androida | klucz = tożsamość aplikacji na zawsze; musi mieć kopię u Ciebie |
| Klucz API App Store Connect, wpisanie sekretów w GitHubie | wymaga roli Admin w App Store Connect i w repo |
| Pierwsze wgranie AAB w Google Play | Google wymaga, żeby pierwsza wersja aplikacji była wgrana ręcznie w konsoli (potem CI może wgrywać przez API) |
| Zaproszenie testerów, ankiety w konsolach (rating, prywatność, Data safety) | konsole są tylko na Twoim koncie; odpowiedzi mam gotowe w `store/rating.md` i `store/privacy.md` |
| Zgoda na umowy (Apple Program License Agreement, Play Developer Distribution Agreement) | to umowy z Tobą |

## Kolejność (zalecana)

| # | Krok | Kto | Koszt | Czas oczekiwania |
|---|---|---|---|---|
| 1 | Decyzja: konto **osobiste** czy **firmowe** (patrz niżej) | Ty | — | — |
| 2 | Konto Google Play Console | Ty | 25 USD jednorazowo | weryfikacja tożsamości: zwykle od kilku godzin do kilku dni |
| 3 | Konto Apple Developer Program | Ty | 99 USD/rok (w PL zwykle ok. 399–449 zł brutto) | osoba: zwykle do 48 h; firma: D-U-N-S (do ok. 5 dni roboczych) + weryfikacja Apple (kilka dni) |
| 4 | Klucz podpisu Androida + sekrety w GitHubie | Ty (z instrukcją z §A.3) | 0 | 15 min |
| 5 | Pierwsze AAB z CI → ręcznie do testów wewnętrznych | Ty | 0 | 30 min + przetwarzanie do ok. godziny |
| 6 | Klucz API App Store Connect + sekrety | Ty | 0 | 15 min |
| 7 | Build z CI → TestFlight → testerzy wewnętrzni | CI + Ty | 0 | przetwarzanie buildu 10–60 min; testerzy wewnętrzni bez przeglądu Apple |
| 8 | (później) testy zamknięte / zewnętrzne | Ty | 0 | Google: przegląd zwykle 1–3 dni; Apple: Beta App Review zwykle ok. 1 dnia |

**Osobiste czy firmowe?** Osobiste jest szybsze, ale w sklepach widać Twoje imię i nazwisko jako twórcę, a w Google Play
**nowe konta osobiste muszą przeprowadzić test zamknięty z co najmniej 12 testerami przez 14 dni**, zanim dostaną
dostęp do produkcji (dotyczy publikacji dla wszystkich; testy wewnętrzne działają od razu). W UE sprzedaż (gra płatna,
D-06) wymaga też deklaracji „trader” z publicznym adresem i telefonem (DSA). Konto firmowe wymaga numeru D-U-N-S
(bezpłatny, wydaje Dun & Bradstreet), ale pokazuje nazwę firmy i nie ma wymogu 12 testerów. **Rekomendacja:** jeśli
masz działalność, konto firmowe w obu sklepach.

---

## A. Google Play — test wewnętrzny (internal testing)

### A.1 Konto
1. Wejdź na **play.google.com/console** → zaloguj się kontem Google, którego chcesz używać na stałe (najlepiej osobnym, „lockwright@…”, z włączoną weryfikacją dwuetapową).
2. Wybierz typ konta (osobiste / organizacja), podaj dane, zapłać **25 USD**.
3. Zweryfikuj tożsamość (zdjęcie dokumentu; dla organizacji: D-U-N-S i strona internetowa). Zweryfikuj telefon i e-mail kontaktowy.
4. Poczekaj na e-mail „Your identity has been verified”.

### A.2 Aplikacja w konsoli
1. **Utwórz aplikację** → nazwa „Lockwright: Locksmith on Call” (EN; PL dodasz w opisie), język domyślny, **Gra**, **Płatna/Bezpłatna** — uwaga: aplikacji raz udostępnionej jako bezpłatna nie da się później zmienić na płatną (D-06!). Na czas testów to bez znaczenia, ale wybór obowiązuje od pierwszej publikacji.
2. Zaakceptuj oświadczenia (zasady dla deweloperów, przepisy eksportowe USA).
3. Panel → **Konfiguracja aplikacji**: polityka prywatności (URL — gdy strona będzie opublikowana, `site/`), dostęp do aplikacji (bez logowania), reklamy (**nie**), ocena treści (kwestionariusz IARC: odpowiedzi w `store/rating.md` §2 i §5), grupa docelowa (`store/rating.md` §6.1), Data safety (`store/privacy.md` §4: nic nie zbieramy). Te pola są potrzebne do publikacji; do testu wewnętrznego część może poczekać, ale lepiej wypełnić od razu.

### A.3 Klucz podpisu i sekrety w GitHubie (raz)
Google używa **Play App Signing**: Google trzyma klucz podpisu aplikacji, a my podpisujemy wgrywane pliki **kluczem przesyłania** (upload key). Jeśli upload key zginie, Google pozwala go wymienić — ale kopia i tak jest obowiązkowa.
1. Na komputerze z Javą (lub poproś sesję B o uruchomienie w CI z wynikiem w artefakcie tylko dla Ciebie — mniej bezpieczne):
   `keytool -genkeypair -v -keystore lockwright-upload.jks -alias upload -keyalg RSA -keysize 4096 -validity 10000`
   Zapisz hasła w menedżerze haseł. **Plik `.jks` skopiuj w dwa bezpieczne miejsca.** Nigdy nie wrzucaj go do repo.
2. Zakoduj plik: `base64 -w0 lockwright-upload.jks > upload.b64` (na Macu: `base64 -i lockwright-upload.jks -o upload.b64`).
3. GitHub → repo → **Settings → Secrets and variables → Actions → New repository secret**, cztery sekrety (nazwy jak w `SESSION-B-PROMPT-4.md`):
   `ANDROID_KEYSTORE_BASE64` (zawartość `upload.b64`), `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS` (`upload`), `ANDROID_KEY_PASSWORD`.
4. Usuń `upload.b64` z dysku.

### A.4 Pierwsze AAB z CI → test wewnętrzny
1. GitHub → **Actions** → workflow budujący wydanie Androida (sesja B; nazwa w jej logu, np. `game-android`) → **Run workflow** albo najnowszy zielony run → artefakt z plikiem **`.aab`** → pobierz i rozpakuj.
2. Play Console → **Testowanie → Testy wewnętrzne → Utwórz wersję** → przy pierwszym razie zaakceptuj **Play App Signing** → przeciągnij `.aab` → nazwa wersji (np. `0.1.0 (1)`) → informacje o wersji (PL/EN: „Pierwsza wersja testowa”) → **Zapisz → Sprawdź wersję → Rozpocznij wdrażanie**.
3. Zakładka **Testerzy** → utwórz listę e-maili (do **100 osób**, konta Google) → zapisz → skopiuj **link do testów**.
4. Testerzy otwierają link na telefonie (zalogowani tym kontem Google), klikają **Zostań testerem**, potem **Pobierz z Google Play**. Pierwsza wersja bywa widoczna po kilkunastu minutach do ok. godziny.
5. Następne wersje: numer `versionCode` musi rosnąć (CI sesji B nadaje go z numeru runu).

### A.5 Wgrywanie z CI (później, opcjonalnie)
Po pierwszym ręcznym wgraniu CI może wysyłać AAB sam: Google Cloud → konto usługi z dostępem do **Google Play Android Developer API** → w Play Console **Użytkownicy i uprawnienia** → zaproś e-mail konta usługi z uprawnieniem do wersji testowych → plik JSON klucza jako sekret `PLAY_SERVICE_ACCOUNT_JSON`. To zadanie dla sesji B, gdy powiesz „tak”.

---

## B. App Store — TestFlight

### B.1 Konto
1. Na iPhonie lub Macu włącz **weryfikację dwuetapową** Apple ID (Ustawienia → Twoje imię → Logowanie i bezpieczeństwo).
2. Zainstaluj aplikację **Apple Developer** (App Store) → **Account → Enroll Now** (najprościej z iPhone'a: weryfikacja dokumentem) albo **developer.apple.com/programs/enroll**.
3. Wybierz **Individual** albo **Organization** (wtedy D-U-N-S i osoba z prawem reprezentacji firmy). Zapłać **99 USD/rok**.
4. Poczekaj na e-mail „Welcome to the Apple Developer Program”. Zaakceptuj umowy w **App Store Connect → Business** (dla gry płatnej także **Paid Apps Agreement**, dane bankowe i podatkowe — do testów niepotrzebne).

### B.2 Rekord aplikacji
1. **developer.apple.com → Certificates, Identifiers & Profiles → Identifiers → +** → App IDs → App → Bundle ID **explicit** `com.woogitsugames.lockwright` → Capabilities: nic dodatkowego nie trzeba (haptyka i dźwięk nie wymagają uprawnień).
2. **appstoreconnect.apple.com → Aplikacje → + → Nowa aplikacja** → iOS, nazwa „Lockwright: Locksmith on Call”, język główny, wybierz Bundle ID z punktu 1, SKU dowolne (np. `lockwright-001`), dostęp pełny.

### B.3 Certyfikaty i profile — wariant prosty (rekomendowany)
Nie musisz ręcznie robić certyfikatu ani profilu, jeśli CI użyje **klucza API App Store Connect** z automatycznym podpisywaniem (`TECH.md` §5.4):
1. App Store Connect → **Użytkownicy i dostęp → Integracje → App Store Connect API → Klucze zespołu → +** → nazwa „CI”, rola **App Manager** (wystarczy do TestFlight; Admin daje więcej, niż trzeba).
2. Pobierz plik **`AuthKey_XXXX.p8`** (da się pobrać **tylko raz** — zachowaj kopię), zanotuj **Key ID** i **Issuer ID** (na górze strony).
3. GitHub → Secrets → dodaj: `APP_STORE_CONNECT_KEY_ID`, `APP_STORE_CONNECT_ISSUER_ID`, `APP_STORE_CONNECT_KEY_P8` (zawartość pliku `.p8` w base64), `APPLE_TEAM_ID` (developer.apple.com → Membership details). Dokładne nazwy potwierdzi sesja B w `game-ios-release.yml`.
4. Wariant ręczny (gdyby automatyczne podpisywanie nie działało w CI): na Macu Keychain → Certificate Assistant → CSR → developer.apple.com → Certificates → **Apple Distribution** → pobierz → eksport `.p12` z hasłem; Profiles → **App Store** dla `com.woogitsugames.lockwright` → pobierz `.mobileprovision`; oba jako sekrety base64. Bez Maca CSR i `.p12` zrobisz też `openssl`em — sesja B może przygotować polecenia.

### B.4 Build z CI → TestFlight
1. GitHub → Actions → **`game-ios-release`** → **Run workflow** (jest wyłączony z automatu do czasu sekretów). Workflow buduje, podpisuje i wysyła do App Store Connect.
2. App Store Connect → aplikacja → **TestFlight**: build pojawia się po przetworzeniu (10–60 min). Przy pierwszym buildzie odpowiedz na pytanie o **szyfrowanie**: gra używa tylko szyfrowania systemu → „Nie” (warto, żeby Info.plist miał `ITSAppUsesNonExemptEncryption = NO`, `store/rating.md` §6.2 — wtedy pytanie znika).
3. **Testerzy wewnętrzni** (do 100 osób z Twojego zespołu w App Store Connect: Użytkownicy i dostęp → dodaj osobę z dowolną rolą, np. „Marketing”) → TestFlight → Wewnętrzne testowanie → grupa → dodaj osoby i build. **Bez przeglądu Apple.**
4. Testerzy instalują aplikację **TestFlight** z App Store i przyjmują zaproszenie z e-maila. Build działa 90 dni.
5. **Testerzy zewnętrzni** (do 10 000, wystarczy e-mail lub publiczny link): wymagają **Beta App Review** dla pierwszego buildu wersji (zwykle ok. 1 dnia) i opisu testu + kontaktu. Notka dla recenzenta jest gotowa w `store/rating.md` §3.

---

## C. Co sprawdzić na telefonach testerów (po instalacji)
1. Pomiary z `POMIARY.md` (§4–§7a) — teraz już na wersji ze sklepu.
2. Samouczek do końca, trzy zlecenia, warsztat, gablota (lista błędów znanych: `SESSION-C-REVIEW.md` N-13…).
3. Tryb „w ciemności” ze słuchawkami.
4. Prześlij zrzut ekranu i model telefonu (Play Console i TestFlight mają też wbudowane zgłaszanie opinii ze zrzutem).

## D. Koszty w skrócie
| Pozycja | Kwota | Kiedy |
|---|---|---|
| Google Play Console | 25 USD | raz |
| Apple Developer Program | 99 USD | co rok |
| D-U-N-S (konto firmowe) | 0 | raz |
| CI (GitHub Actions) | w ramach limitu repo; buildy iOS na macOS zużywają minuty ×10 | co miesiąc — sprawdzić w Settings → Billing |
| Codemagic (alternatywa dla buildów iOS, `TECH.md` §5) | opcjonalnie | — |
