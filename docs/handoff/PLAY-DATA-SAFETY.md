# Google Play — Data safety, uprawnienia, pobierane treści (szkic odpowiedzi)

Stan na 2026-11-09 · inżynier wydania (D-106). Opisuje **build release z `game-android` → `release-aab`**, nie plany.
Źródła prawdy: `store/privacy.md` (polityka PL/EN i stan faktyczny), `docs/TECH.md` §9 (paczki głosów),
`tools/release/check_aab.py` (co CI sprawdza w każdym AAB). To nie jest porada prawna — punkty oznaczone
**[PRAWNIK]** rozstrzyga właściciel z osobą znającą RODO.

## 1. Co gra robi z danymi (stan faktyczny, sprawdzony w kodzie)

| Co | Gdzie | Opuszcza urządzenie? |
|---|---|---|
| Postęp (monety, narzędzia, zlecenia, notki, statystyki) | `user://save.json` (`game/scripts/autoload/save.gd`) | **Nie.** Android Auto Backup wyłączony: manifest release ma `android:allowBackup="false"` (domyślne w Godot 4.7, potwierdzone `bundletool dump manifest`). |
| Ustawienia | `user://settings.cfg` (`settings.gd`) | **Nie.** |
| Log błędów (5 plików × 512 KB, rotacja) | `user://logs/` (`error_log.gd`) | **Nie.** „Zgłoś problem” w Ustawieniach tylko kopiuje log do schowka; wysyła go sam gracz, jeśli chce (to nie jest zbieranie przez aplikację). |
| Paczki głosów (PL/DE/FR/ES, 18–20 MB każda) | `user://voice_packs/` | Pobierane **do** urządzenia (niżej). |
| Analityka, reklamy, raporty awarii, konta, identyfikatory | — | **Brak.** Żadnego SDK firm trzecich (grep: brak Firebase/Sentry/Crashlytics/analytics w `game/`; jedyny kod sieciowy to `voice_packs.gd`). Brak `AD_ID` w manifeście. |

**Ruch sieciowy (jedyny):** `game/scripts/autoload/voice_packs.gd` → `HTTPClient` z `TLSOptions.client()` (HTTPS z weryfikacją
certyfikatu), `GET` na adresy z `game/data/voice_packs.json`:
`https://github.com/woogitsugames/lockwright/releases/download/voice-packs-<wersja>/voice_<język>.pck`
(GitHub przekierowuje na swój CDN w domenie `*.githubusercontent.com`). Nagłówki: `Accept: application/octet-stream`
i przy wznowieniu `Range: bytes=N-`. Bez ciasteczek, identyfikatorów, danych gry. Kiedy: przy pierwszym uruchomieniu
dla języka gry ≠ EN (w tle, bez pytania, z notką o rozmiarze — D-100), ponowne próby przy braku sieci, oraz ręcznie
w Ustawieniach → Głosy postaci (tam też wyłączenie automatu i usuwanie). Plik jest sprawdzany SHA-256 z manifestu
w podpisanej aplikacji.

## 2. Uprawnienia w manifeście release (pełna lista)

Odczyt z AAB release (`bundletool dump manifest`, run 42542243431) i z APK debug (`aapt2 dump permissions`).
Po D-106 CI przerywa build, jeśli lista różni się od tej tabeli (`tools/release/check_aab.py`, `ALLOWED_PERMISSIONS`).

| Uprawnienie | Poziom | Po co | Uwagi |
|---|---|---|---|
| `android.permission.VIBRATE` | normal (bez okna) | haptyka zamka — rdzeń gry, nigdy jedyny kanał (XAG 103/110) | z wtyczki `lockwright-haptics` i `permissions/vibrate=true` |
| `android.permission.INTERNET` | normal (bez okna) | wyłącznie pobieranie paczek głosów (D-62/D-63/D-100) | **Do D-106 brakowało go w AAB release** (preset release był pisany ręcznie bez `permissions/internet`), więc w wersji ze sklepu głosy PL/DE/FR/ES by się nie pobrały. Naprawione: preset release = kopia `preset.0`. |

Nie ma: `ACCESS_NETWORK_STATE`, `AD_ID`, lokalizacji, kamery, mikrofonu, kontaktów, pamięci zewnętrznej,
`POST_NOTIFICATIONS`, `FOREGROUND_SERVICE`. W manifeście są komponenty AndroidX bez uprawnień użytkownika:
`ProfileInstallReceiver` chroniony `android.permission.DUMP` (tylko adb/system), `FileProvider` i `InitializationProvider`
z `exported=false`. Przy wariancie A D-06 dojdzie `com.android.vending.BILLING` — wtedy dopisać go do allowlisty
i do tej tabeli **przed** wydaniem.

## 3. Pobierane treści a zasady Google Play

- **Polityka „Device and Network Abuse”:** aplikacja z Google Play nie może pobierać i wykonywać kodu (dex, JNI/.so,
  skrypty interpretowane przez aplikację) spoza Google Play. Treści/zasoby (audio, obrazy) wolno pobierać.
- **Nasze paczki to wyłącznie dane audio:**
  - presety „Voice pl/de/fr/es” w `game/export_presets.cfg`: `export_filter="resources"` bez wybranych plików,
    `include_filter="assets/audio/lines/<lang>/*.ogg"`, `exclude_filter="*.gd,*.gdshader,*.gdshaderinc,*.svg,*.gdextension"`;
  - `tools/build_voice_packs.py` → `check_data_only()` czyta katalog pck i **odrzuca** każdy plik poza
    `res://assets/audio/lines/<lang>/*.ogg.import`, `res://.godot/imported/*.oggvorbisstr` i czterema plikami
    porządkowymi Godota (`project.binary`, `uid_cache.bin`, `global_script_class_cache.cfg`, `icon.svg`); szyfrowany
    katalog pck też jest odrzucany. Build w `voice-packs.yml` pada, zanim cokolwiek trafi do GitHub Release;
  - gra montuje paczkę z `replace_files=false` (paczka tylko dodaje `res://assets/audio/lines/<lang>/…`, nie może podmienić
    skryptu ani sceny z paczki głównej) i tylko po zgodności SHA-256 z manifestem zaszytym w podpisanej aplikacji.
  - Uwaga: `global_script_class_cache.cfg` i `project.binary` to pliki konfiguracyjne Godota (lista klas / ustawienia),
    nie kod wykonywalny; przy `replace_files=false` nie nadpisują wersji z aplikacji.
- **Wniosek:** zgodne z polityką (dodatkowe treści nie-wykonywalne, HTTPS, gra działa bez nich — napisy).
  Play Asset Delivery odrzucone w D-63 (brak wsparcia w Godot 4.7); limit modułu bazowego 200 MB (D-99) jest pilnowany
  budżetem `aab_release_mb` 185/198 MB, obecnie **124,9 MB**.

## 4. Data safety — odpowiedzi do formularza (Play Console → Zasady → Zawartość aplikacji → Bezpieczeństwo danych)

| Pytanie | Odpowiedź | Uzasadnienie |
|---|---|---|
| Does your app collect or share any of the required user data types? | **No** | Aplikacja nie przesyła poza urządzenie żadnych danych użytkownika; zapis, ustawienia i logi są lokalne (§1). |
| Is all of the user data collected by your app encrypted in transit? | (nie pojawia się przy „No”) — gdyby pytało: **Yes** | Jedyny ruch to HTTPS z weryfikacją certyfikatu. |
| Do you provide a way for users to request that their data is deleted? | (nie pojawia się przy „No”) — gdyby pytało: dane są tylko na urządzeniu; usuwa je odinstalowanie lub „Wyczyść dane”; paczki głosów — Ustawienia → Głosy postaci → Usuń | Brak kont, więc URL usuwania danych nie jest wymagany. |
| Independent security review | **No** | |
| Privacy policy URL | **wymagane** — `https://<domena>/en/privacy.html` (PL: `/privacy.html`), strona gotowa w `site/` | Publikacja strony czeka na właściciela (D-51). |

**Wynik na karcie:** „No data collected” · „No data shared with third parties”.

Uzasadnienie „No” mimo `INTERNET`: Google definiuje „collect” jako przesłanie danych z urządzenia przez aplikację
(lub jej SDK) do dewelopera albo strony trzeciej. Żądanie GET nie zawiera danych użytkownika; adres IP jest częścią
samego połączenia sieciowego i trafia do logów dostawcy hostingu (GitHub), których nie odbieramy i nie używamy
(w szczególności nie wyprowadzamy z IP lokalizacji — wtedy trzeba by deklarować „Approximate location”).
**[PRAWNIK — znacznik 3]** potwierdzić tę kwalifikację (Apple: „Identifiers”, Google: brak typu „IP”) — §5.

Nie deklarujemy (zbiera Google jako operator sklepu/systemu, nie nasz kod): Android vitals / raporty ANR i awarii
w Play Console, Play Billing (wariant A D-06). Jeśli kiedykolwiek dojdzie SDK sieciowy (Firebase, Sentry itp.),
formularz i polityka **przed** wydaniem.

## 5. Trzy znaczniki do weryfikacji prawnej (nie rozstrzygnięte)

Polityka: `store/privacy.md` §1/§2 → kopie `store/legal/privacy_{pl,en}.md` (`check_sync.py`) → `site/public/{,en/}privacy.html`
(`site/build.py`). W tekście publicznym są dwa znaczniki `[DO WERYFIKACJI PRAWNEJ …]` / `[LEGAL REVIEW NEEDED …]` w każdej
wersji językowej; trzeci siedzi w deklaracjach sklepowych (`store/privacy.md` §3 „Identifiers” i §4 „Do weryfikacji (D-63)”).
Proponowane neutralne brzmienia poniżej — **do decyzji właściciela/prawnika**, w plikach znaczniki zostają.

### Znacznik 1 — rola dostawcy hostingu i logi (akapit „Pobieranie głosów”)
Obecnie: `[DO WERYFIKACJI PRAWNEJ: rola dostawcy (odrębny administrator czy podmiot przetwarzający), podstawa prawna i cel logów, okres przechowywania, lokalizacje i transfery poza EOG.]`

Propozycja PL:
> Pliki głosów udostępnia [GitHub, Inc. (USA), w ramach usługi GitHub Releases]. Dostawca przetwarza adres IP i dane
> techniczne żądania, aby dostarczyć plik i chronić swoją usługę, jako [odrębny administrator, na zasadach własnej
> polityki prywatności: <link>] / [podmiot przetwarzający działający w naszym imieniu]. Podstawą jest nasz prawnie
> uzasadniony interes w dostarczeniu ci zamówionej treści (art. 6 ust. 1 lit. f RODO). Dane mogą być przekazywane
> do USA na podstawie [Ram ochrony danych UE–USA / standardowych klauzul umownych]. Okres przechowywania logów określa
> dostawca; my ich nie pobieramy.

Propozycja EN:
> Voice files are served by [GitHub, Inc. (USA) via GitHub Releases]. The provider processes your IP address and basic
> request data to deliver the file and protect its service, as [an independent controller under its own privacy
> statement: <link>] / [a processor acting on our behalf]. The legal basis is our legitimate interest in delivering
> the content you requested (Art. 6(1)(f) GDPR). Data may be transferred to the USA under [the EU–US Data Privacy
> Framework / standard contractual clauses]. Log retention is set by the provider; we do not retrieve those logs.

Do rozstrzygnięcia: wybór wariantów w nawiasach; czy po przejściu na Cloudflare (D-51) zmienia się rola i lokalizacja.

### Znacznik 2 — zakres praw wobec logów hostingu (akapit „Twoje prawa”)
Obecnie: `[DO WERYFIKACJI PRAWNEJ: faktyczny zakres praw wobec logów hostingu.]`

Propozycja PL:
> Nie mamy dostępu do dzienników dostawcy hostingu i nie możemy powiązać ich wpisów z tobą. Jeśli dostawca jest
> odrębnym administratorem, swoje prawa wobec tych dzienników wykonujesz bezpośrednio u niego ([link do jego polityki]);
> chętnie pomożemy wskazać właściwy kontakt.

Propozycja EN:
> We have no access to the hosting provider's logs and cannot link their entries to you. If the provider is an
> independent controller, you exercise your rights over those logs directly with it ([link to its policy]); we are
> happy to point you to the right contact.

### Znacznik 3 — czy IP w logach hostingu to „zbieranie” (App Privacy „Identifiers”, Data safety)
Obecnie: `store/privacy.md` §3 („**Do weryfikacji prawnej** przy definicji „collect” Apple”) i §4 („**Do weryfikacji (D-63)** … Potwierdzić z aktualnym wzorem Data safety, że to nie jest „collected””).

Proponowane stanowisko (neutralne, do potwierdzenia): aplikacja nie przesyła identyfikatorów; IP jest widoczne dla
hostingu wyłącznie jako element połączenia potrzebnego do dostarczenia treści, nie jest przez nas odbierane, łączone
z innymi danymi ani używane do lokalizacji → Data safety „No data collected”, App Privacy „Data Not Collected”.
Wariant ostrożny, gdyby prawnik uznał inaczej: Data safety → „Device or other IDs: collected, not shared, processed
ephemerally, required, purpose: App functionality” i odpowiednia zmiana polityki **przed** wydaniem.

## 6. Pozostałe deklaracje „Zawartość aplikacji” (skrót; szczegóły `store/rating.md` §6.1)

| Deklaracja | Odpowiedź |
|---|---|
| Reklamy | **No** (brak SDK reklamowych) |
| Dostęp do aplikacji | **All functionality is available without special access** (brak logowania) |
| Identyfikator wyświetlania reklam (Advertising ID) | **No** — manifest bez `com.google.android.gms.permission.AD_ID` (pilnuje `check_aab.py`) |
| Funkcje finansowe / zdrowie / aplikacja rządowa / wiadomości / COVID | **No** |
| Grupa docelowa | 13–15, 16–17, 18+ (bez grup < 13) — `docs/handoff/PLAY-CLOSED-TEST.md` §4 |
| Klasyfikacja treści (IARC) | `docs/handoff/PLAY-CLOSED-TEST.md` §3 |
