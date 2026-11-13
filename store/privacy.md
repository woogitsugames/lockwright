# Prywatność — polityka (PL + EN), App Privacy, Data safety, manifest

Status: szkic do akceptacji · 2026-11-04, stan faktyczny uzupełniony 2026-11-13 o paczki treści (D-112, D-128). To nie jest porada prawna. Przed publikacją uzupełnić pola
`[…]` i dać tekst do przeczytania osobie znającej RODO/GDPR.

Stan faktyczny, na którym opiera się polityka (sprawdzić przed każdym wydaniem):
- Gra działa offline. Brak kont, reklam, analityki, SDK firm trzecich do śledzenia lub raportów awarii. **Jedyne użycie sieci (D-63, D-100, D-112):** pobieranie plików gry z jednego hostingu, wspólnym kodem `game/scripts/autoload/pack_store.gd`. (1) Paczka głosu `voice_<język>.pck` (w paczce gry tylko głosy EN; głosy języka gry/telefonu pobierane w tle przy pierwszym uruchomieniu, bez pytania, z widoczną notką o rozmiarze; pozostałe języki i wyłączenie automatu w Ustawieniach → Głosy postaci): zwykłe żądania HTTPS GET (z `Range` przy wznowieniu), bez ciasteczek, identyfikatorów i analityki, sumę SHA-256 sprawdza gra (`game/scripts/autoload/voice_packs.gd`, `game/data/voice_packs.json`). (2) Paczka treści `content_<id>.pck` — rozdział do pobrania (D-112; rozdziały 13+ wg decyzji właściciela z 2026-11-13, D-128): te same żądania HTTPS GET, te same nagłówki (`Accept`, przy wznowieniu `Range`) i ten sam host co głosy, bez ciasteczek, identyfikatorów i danych o postępie; **nigdy samoczynnie** — tylko po stuknięciu „Pobierz” przy rozdziale na liście zleceń albo w Ustawieniach → Rozdziały do pobrania, gdzie paczkę się też usuwa (zapis gry zostaje); SHA-256 z `game/data/content_packs.json` (`content_packs.gd`). Dostawca hostingu (obecnie GitHub Releases, po sygnale właściciela Cloudflare, D-51/D-63) widzi adres IP i dane techniczne żądania. Projekt T64 (`contrib/gpt/T64`) wcielono 2026-11-06, zob. `contrib/gpt/REVIEW-T53-T68.md`.
- Zapis lokalny: `user://save.json` (postęp: monety, narzędzia, odblokowane notki, statystyki) i `user://settings.cfg` (ustawienia). Zob. `game/scripts/autoload/save.gd`, `settings.gd`.
- Uprawnienia Android: `VIBRATE` (haptyka; uprawnienie „normal”, bez danych) i `INTERNET` (D-63, D-112, wyłącznie pobieranie paczek głosów i paczek treści; „normal”, bez okna zgody). W wariancie A D-06 dojdzie `com.android.vending.BILLING`. **Pilnowane w CI (D-106):** `tools/release/check_aab.py` w jobie `release-aab` przerywa build, gdy manifest AAB ma jakiekolwiek inne uprawnienie albo gdy brakuje jednego z tych dwóch (brak `ACCESS_NETWORK_STATE`, `AD_ID`, lokalizacji itd.).
- iOS: Core Haptics, AVAudioSession. Brak dostępu do zdjęć, kontaktów, lokalizacji, mikrofonu, kamery, IDFA (brak ATT).
- Zakup (wariant A): obsługuje Apple (StoreKit) / Google (Play Billing). Dostajemy tylko potwierdzenie uprawnienia na urządzeniu.

Kopia zapasowa systemu: iCloud Backup może kopiować pliki gry razem z resztą urządzenia. **Android: stan faktyczny
(D-106) to `android:allowBackup="false"`** — domyślna opcja eksportu Godota `user_data_backup/allow`, więc Auto Backup
zapisu nie kopiuje (decyzja z §4 „zostawić włączoną” nie była wdrożona; włączenie wymaga też wykluczenia
`user://voice_packs/` i `user://content_packs/`, bo paczki (głosy ~18–20 MB każda, rozdziały więcej) przekroczyłyby limit 25 MB Auto Backup — decyzja właściciela). To funkcja
systemu na koncie użytkownika, my do niej nie mamy dostępu. Jeśli kiedyś dodamy
iCloud Key-Value / Saved Games w Play Games, trzeba zaktualizować ten dokument.

---

## 1. Polityka prywatności — wersja polska (do opublikowania)

# Polityka prywatności gry Lockwright

Obowiązuje od: [DATA — do uzupełnienia]

**Kto odpowiada za grę.** Administratorem w rozumieniu RODO, gdyby doszło do przetwarzania danych osobowych, jest [NAZWA ADMINISTRATORA, ADRES — do uzupełnienia]. Kontakt w sprawach prywatności: privacy@[domena — do ustalenia].

**W skrócie.** Lockwright nie ma kont, reklam ani analityki i nie sprzedaje żadnych danych o tobie. Gra działa bez internetu. Z sieci korzysta tylko po to, żeby pobrać własne pliki: paczki głosów i dodatkowe rozdziały, o których pobranie sam poprosisz (opis niżej). Bez głosów gra pokazuje napisy, a bez dodatkowych rozdziałów reszta gry działa jak zwykle.

**Co zostaje na twoim urządzeniu.** Gra zapisuje na urządzeniu twój postęp (np. monety, narzędzia, otwarte zamki, odblokowane notki w gablocie) i ustawienia (np. dźwięk, haptyka). Te pliki nie opuszczają urządzenia za naszym pośrednictwem i nie mamy do nich dostępu. Usuniesz je, odinstalowując grę albo czyszcząc jej dane w ustawieniach systemu.

**Pobieranie głosów i rozdziałów (jedyne użycie sieci).** Napisy działają we wszystkich językach gry od razu. Nagrania głosów po angielsku są w grze; głosy w języku gry (domyślnie języku telefonu) gra pobiera w tle przy pierwszym uruchomieniu i pokazuje przy tym rozmiar pobrania. Pozostałe języki pobierasz sam w Ustawieniach, gdzie możesz też wyłączyć automatyczne pobieranie i usunąć pobrane głosy. Część rozdziałów to osobne pliki do pobrania. Rozdziału gra nigdy nie pobiera sama: robi to dopiero wtedy, gdy stukniesz „Pobierz” przy nim na liście zleceń albo w Ustawieniach, gdzie widać też jego rozmiar. Każde pobranie, głosów i rozdziału, to zwykłe żądanie HTTPS do tego samego serwera z plikami gry. Gra nie wysyła w nim żadnego identyfikatora, konta ani danych o rozgrywce, a nie używa ciasteczek ani analityki. Jak każde połączenie z internetem, ujawnia ono jednak serwerowi twój adres IP i podstawowe dane techniczne żądania (np. czas i adres pliku). Mogą one trafić do dzienników dostawcy hostingu: obecnie [DOSTAWCA HOSTINGU — GitHub, a po przejściu na własny hosting Cloudflare; do potwierdzenia], z którego dzienników my nie korzystamy do identyfikowania graczy. [DO WERYFIKACJI PRAWNEJ: rola dostawcy (odrębny administrator czy podmiot przetwarzający), podstawa prawna i cel logów, okres przechowywania, lokalizacje i transfery poza EOG.] Bez pobranych głosów gra pokazuje napisy, a rozdział, którego nie pobrałeś, czeka na liście zleceń, aż go pobierzesz. Pobrane głosy i rozdziały usuniesz w Ustawieniach gry (usunięcie rozdziału nie kasuje postępów), czyszcząc dane gry albo odinstalowując ją.

**Kopie zapasowe systemu.** Jeśli masz włączoną kopię zapasową urządzenia (np. iCloud na iPhonie lub kopię zapasową Google na Androidzie), system może skopiować pliki gry razem z resztą danych. Tę kopię prowadzi Apple lub Google na twoim koncie, zgodnie z ich zasadami. My jej nie widzimy.

**Zakupy.** Jeśli gra oferuje zakup w aplikacji, płatność obsługuje w całości Apple (App Store) lub Google (Google Play). Nie dostajemy twoich danych płatniczych ani danych konta. Gra sprawdza na urządzeniu tylko to, czy zakup został zrobiony.

**Raporty o awariach.** Gra nie ma własnych narzędzi do raportowania błędów. Jeśli w ustawieniach urządzenia zgodzisz się na udostępnianie danych diagnostycznych twórcom aplikacji, Apple lub Google mogą przekazać nam zanonimizowane raporty o awariach. Używamy ich wyłącznie do naprawiania błędów.

**Jeśli do nas napiszesz.** Gdy wyślesz nam e-mail, użyjemy twojego adresu i treści wiadomości tylko po to, żeby odpowiedzieć (podstawa: art. 6 ust. 1 lit. f RODO, nasz uzasadniony interes w odpowiedzi na wiadomość). Usuwamy korespondencję, gdy sprawa jest zamknięta, najpóźniej po [12 miesiącach — do potwierdzenia]. Nie przekazujemy jej nikomu, poza dostawcą poczty [NAZWA DOSTAWCY — do uzupełnienia].

**Twoje prawa.** Masz prawo do dostępu do swoich danych, ich sprostowania, usunięcia, ograniczenia przetwarzania, sprzeciwu i przeniesienia, a także prawo do skargi do organu nadzorczego ([np. Prezes UODO, ul. Stawki 2, 00-193 Warszawa — do dostosowania do siedziby administratora]). Ponieważ gra nie zbiera danych, w praktyce dotyczy to korespondencji e-mail oraz ewentualnych dzienników dostawcy hostingu plików gry, czyli głosów i rozdziałów (w sprawie tych dzienników skontaktuj się z nami, a wskażemy właściwy podmiot). [DO WERYFIKACJI PRAWNEJ: faktyczny zakres praw wobec logów hostingu.]

**Dzieci.** Gra nie jest kierowana specjalnie do dzieci, ale nadaje się dla każdego (4+ / PEGI 3). Nie zbieramy danych od nikogo, więc także od dzieci. Jeśli dziecko napisało do nas e-mail, a rodzic chce go usunąć, wystarczy wiadomość na adres wyżej.

**Śledzenie.** Nie śledzimy cię w innych aplikacjach ani na stronach. Gra nie używa identyfikatora reklamowego.

**Zmiany.** Jeśli zmienimy tę politykę (na przykład dodamy kolejną funkcję korzystającą z sieci), opublikujemy nową wersję pod tym adresem z nową datą obowiązywania, a istotne zmiany opiszemy w notce do aktualizacji gry. Nie zaczniemy zbierać danych bez wcześniejszej informacji.

---

## 2. Privacy Policy — English version (ready to host)

# Lockwright Privacy Policy

Effective date: [DATE — to be filled in]

**Who is responsible.** The controller under the GDPR, should any personal data be processed, is [CONTROLLER NAME, ADDRESS — to be filled in]. Privacy contact: privacy@[domain — tbd].

**In short.** Lockwright has no accounts, ads or analytics and does not sell any data about you. The game works offline. It uses the network only to download its own files: voice packs, and extra chapters when you ask for them (see below). Without voices the game shows subtitles, and without the extra chapters the rest of the game works as usual.

**What stays on your device.** The game saves your progress (for example coins, tools, opened locks, unlocked showcase notes) and your settings (for example sound and haptics) on your device. These files never leave your device through us, and we have no access to them. To delete them, uninstall the game or clear its data in your system settings.

**Voice and chapter downloads (the only network use).** Subtitles work in every game language straight away. English voice recordings are included in the game; voices in the game's language (by default your phone's language) are downloaded in the background on first launch, and the game shows the download size while it happens. You download other languages yourself in Settings, where you can also turn automatic downloads off and remove downloaded voices. Some chapters are separate files to download. The game never downloads a chapter by itself: it does so only when you tap “Download” next to it in the job list or in Settings, where its size is shown too. Every download, of voices or of a chapter, is an ordinary HTTPS request to the same server that hosts the game's files. The game sends no identifier, account or gameplay data with it, and uses no cookies or analytics. Like any internet connection, however, it reveals your IP address and basic technical request data (such as the time and the file requested) to the server. These may appear in the hosting provider's logs: currently [HOSTING PROVIDER — GitHub, and Cloudflare after a move to our own hosting; to be confirmed], and we do not use those logs to identify players. [LEGAL REVIEW NEEDED: the provider's role (separate controller or processor), lawful basis and purpose of the logs, retention, locations and transfers outside the EEA.] Without downloaded voices the game shows subtitles, and a chapter you have not downloaded waits in the job list until you download it. You can remove downloaded voices and chapters in the game's Settings (removing a chapter keeps your progress), by clearing the game's data or by uninstalling it.

**System backups.** If device backup is on (for example iCloud on iPhone or Google backup on Android), the system may copy the game's files along with your other data. Apple or Google keeps that backup in your account under their own terms. We can't see it.

**Purchases.** If the game offers an in-app purchase, payment is handled entirely by Apple (App Store) or Google (Google Play). We don't receive your payment details or account data. The game only checks, on your device, whether the purchase was made.

**Crash reports.** The game has no crash-reporting tools of its own. If you have agreed in your device settings to share diagnostics with app developers, Apple or Google may pass anonymised crash reports on to us. We use them only to fix bugs.

**If you write to us.** If you email us, we use your address and message only to reply (legal basis: Art. 6(1)(f) GDPR, our legitimate interest in answering you). We delete the correspondence once the matter is closed, and no later than [12 months — to confirm]. We don't share it with anyone except our email provider [PROVIDER NAME — to be filled in].

**Your rights.** You have the right to access, rectify and erase your data, to restrict or object to processing, to data portability, and to lodge a complaint with a supervisory authority ([e.g. the Polish UODO — adjust to the controller's location]). Because the game collects no data, in practice this applies to email correspondence and to any logs kept by the provider that hosts the game's files, that is voices and chapters (contact us about those logs and we will point you to the right party). [LEGAL REVIEW NEEDED: actual scope of rights over hosting logs.]

**Children.** The game isn't aimed specifically at children, but it is suitable for everyone (4+ / PEGI 3). We collect no data from anyone, children included. If a child has emailed us and a parent wants that message deleted, just write to the address above.

**Tracking.** We don't track you across other apps or websites. The game doesn't use an advertising identifier.

**Changes.** If we change this policy (for example, if we add another feature that uses the network), we'll publish the new version at this address with a new effective date and describe significant changes in the update notes. We won't start collecting data without telling you first.

---

## 3. App Store Connect — App Privacy („nutrition label”)

Pytanie główne: **„Do you or your third-party partners collect data from this app?” → No.**
Wynik na karcie: **Data Not Collected**.

Uzasadnienie po kategoriach (Apple: „collect” = wysyłanie danych poza urządzenie w sposób dostępny dla nas lub partnerów dłużej niż do obsługi żądania w czasie rzeczywistym):

| Kategoria Apple | Zbierane? | Dlaczego nie |
|---|---|---|
| Contact Info (imię, e-mail, telefon, adres) | Nie | Brak kont i formularzy. E-mail wysłany przez gracza z jego poczty to nie dane zbierane przez aplikację. |
| Health & Fitness | Nie | Brak. |
| Financial Info (płatności, karta) | Nie | Zakup obsługuje Apple. Apple wprost wyłącza z deklaracji płatności przez IAP. |
| Location (precyzyjna, przybliżona) | Nie | Brak uprawnienia. |
| Sensitive Info | Nie | Brak. |
| Contacts | Nie | Brak. |
| User Content (zdjęcia, audio, gameplay content, support) | Nie | Zapis gry jest lokalny. Brak nagrywania i wysyłania. |
| Browsing History, Search History | Nie | Brak. |
| Identifiers (User ID, Device ID / IDFA, IDFV) | Nie | Nie odczytujemy i nie wysyłamy identyfikatorów. Adres IP widzi hosting paczek głosów i rozdziałów (D-63, D-112), ale to nie nasz identyfikator, a my logów nie odbieramy. **Do weryfikacji prawnej** przy definicji „collect” Apple. |
| Purchases (historia zakupów) | Nie | Uprawnienie sprawdzane lokalnie przez StoreKit, nic nie trafia do nas. |
| Usage Data (interakcje, reklamy) | Nie | Brak analityki. |
| Diagnostics (awarie, wydajność) | Nie | Raporty awarii od Apple (opt-in użytkownika na poziomie systemu) nie wymagają deklaracji, bo nie zbiera ich nasz kod ani SDK. |
| Other Data | Nie | |

Tracking: **No** (brak ATT, brak `NSUserTrackingUsageDescription`).
Privacy Policy URL: wymagany. Adres hostingu `https://[domena]/privacy` (PL) i `/en/privacy` (EN), do ustalenia z D-03.

---

## 4. Google Play Console — Data safety

| Pytanie | Odpowiedź |
|---|---|
| Does your app collect or share any of the required user data types? | **No** |
| Is all of the user data collected by your app encrypted in transit? | Nie pojawia się przy „No”. Gdyby formularz pytał: **tak** (jedyna transmisja to pobranie paczki głosu albo rozdziału po HTTPS, bez danych użytkownika). |
| Do you provide a way for users to request that their data is deleted? | Nie pojawia się przy „No”. Jeśli pyta: dane są tylko lokalne, usuwa je odinstalowanie gry lub „Wyczyść dane” w ustawieniach Androida. |
| Data deletion URL (Play wymaga, gdy aplikacja ma konta) | **Nie dotyczy** (brak kont). |
| Independent security review | Nie. |
| Privacy policy URL | Wymagany dla wszystkich aplikacji. Ten sam co w App Store. |

Wynik na karcie: **„No data collected” · „No data shared with third parties”**. Paczki treści (D-112, D-128) tego nie zmieniają: to takie samo pobranie jak głosy (ten sam host, GET bez danych użytkownika, tylko po stuknięciu „Pobierz”), nic nie jest wysyłane z urządzenia. **Do weryfikacji (D-63):** gra od teraz ma `INTERNET` i pobiera paczki głosów; adres IP trafia do logów hostingu, których my nie odbieramy. Potwierdzić z aktualnym wzorem Data safety, że to nie jest „collected” (dane przetwarzane tylko doraźnie przez usługodawcę), a jeśli jest, zmienić odpowiedź i politykę **przed** wydaniem. Pytanie o szyfrowanie w tranzycie: pobranie idzie po HTTPS (**tak**).

Uwagi:
- Play Billing (wariant A) i Android vitals zbiera Google jako operator sklepu i systemu. Tego nie deklarujemy, o ile nasz kod nie wysyła tych danych dalej.
- Android Auto Backup: build release ma dziś `android:allowBackup="false"` (domyślne w Godot 4.7, sprawdzane przez `tools/release/check_aab.py`), więc zapis nie trafia na konto Google. Gdyby właściciel go włączył (`user_data_backup/allow`), to kopia systemowa, nie „collection” w rozumieniu Data safety; trzeba wtedy wykluczyć `user://voice_packs/` i `user://content_packs/` (limit 25 MB). Pełny szkic formularza: `docs/handoff/PLAY-DATA-SAFETY.md`.
- Jeśli kiedykolwiek pojawi się Firebase, Sentry, Unity Analytics itp., formularz trzeba wypełnić od nowa **przed** wydaniem.

---

## 5. Odbiorcy docelowi (Target audience) i program Families

**Google Play → Target audience and content:**
- Rekomendacja: grupy wiekowe **13–15, 16–17, 18+**. **Nie zaznaczać grup poniżej 13 lat.**
- Powód: zaznaczenie < 13 włącza politykę Families (wymogi dla SDK, reklam, treści i ewentualny przegląd „Teacher Approved”). Gra jest bezpieczna dla dzieci (PEGI 3), ale nie jest projektowana dla nich. Temat otwierania zamków dla małych dzieci wymaga też ostrożności wizerunkowej.
- „Could your app unintentionally appeal to children?”: odpowiedź **No**, z uzasadnieniem: fotorealistyczna estetyka warsztatu, brak postaci kreskówkowych, opis i zrzuty kierowane do dorosłych miłośników mechanizmów i łamigłówek.
- Ocena PEGI 3 i grupa docelowa 13+ nie są sprzeczne: ocena mówi, dla kogo treść jest bezpieczna, grupa docelowa mówi, dla kogo gra powstała.

**Apple:** nie zaznaczać „Made for Kids” (patrz `rating.md` §1.8).

---

## 6. Apple privacy manifest (`PrivacyInfo.xcprivacy`)

Wymagany od 2024 r. dla aplikacji i SDK, które używają „required reason APIs”. Godot (od 4.3) generuje
manifest przy eksporcie iOS z opcji w presecie eksportu (sekcja `privacy/…`). **Wszystko poniżej do
weryfikacji na faktycznym eksporcie Godot 4.7** (otworzyć wygenerowany projekt Xcode i plik manifestu,
potem sprawdzić raport „Privacy Report” w Xcode Organizer po archiwizacji).

| Klucz | Wartość docelowa | Uwagi |
|---|---|---|
| `NSPrivacyTracking` | `false` | |
| `NSPrivacyTrackingDomains` | pusta lista | |
| `NSPrivacyCollectedDataTypes` | pusta lista | zgodne z „Data Not Collected” |
| `NSPrivacyAccessedAPITypes` → **File timestamp** (`NSPrivacyAccessedAPICategoryFileTimestamp`) | **C617.1** (znaczniki czasu plików w kontenerze aplikacji) | **Zweryfikowane 2026-11-05:** eksport Godota 4.7.2 domyślnie wpisuje `DDA9.1` + `C617.1`. `DDA9.1` („pokazujemy datę pliku użytkownikowi”) nas nie dotyczy → w presecie iOS ustawić `privacy/file_timestamp_access_reasons` tylko na `C617.1`. |
| → **System boot time** (`NSPrivacyAccessedAPICategorySystemBootTime`) | **35F9.1** (czas między zdarzeniami w aplikacji) | **Zweryfikowane:** Godot wpisuje `35F9.1` domyślnie. Bez zmian. |
| → **Disk space** (`NSPrivacyAccessedAPICategoryDiskSpace`) | **E174.1** (sprawdzenie miejsca przed zapisem) | **Zweryfikowane:** Godot wpisuje `E174.1` + `85F4.1`. `85F4.1` (pokazywanie miejsca na dysku) nas nie dotyczy → `privacy/disk_space_access_reasons` = `E174.1`. |
| → **User defaults** (`NSPrivacyAccessedAPICategoryUserDefaults`) | — | **Zweryfikowane:** Godot 4.7.2 tej kategorii **nie** zgłasza; dopisać `CA92.1` tylko, jeśli nasz mostek iOS zacznie używać `NSUserDefaults`. |

Źródło weryfikacji: `PrivacyInfo.xcprivacy` z eksportu Godota 4.7.2 do projektu Xcode w CI (`spike-haptics`, job `ios-godot`,
run 41990034047, artefakt `spike-haptics-ios-godot`), `NSPrivacyTracking = false`, brak `NSPrivacyCollectedDataTypes`.

Nasze mostki natywne (`platform/ios/lockwright_haptics/`, D-20): Core Haptics, `AVAudioSession` i
`UIImpactFeedbackGenerator` nie są „required reason APIs”. Jeśli mostek zacznie używać `NSUserDefaults`
lub znaczników czasu plików, dopisać powody. Każdy dodatkowy SDK (np. StoreKit wrapper) musi mieć własny
manifest i podpis, jeśli jest na liście Apple „commonly used SDKs”.
