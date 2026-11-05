# T40 — synchronizacja siedmiu lokalizacji v2

## Migawka i zakres

- **Repozytorium:** `woogitsugames/lockwright`, gałąź `main`.
- **Hash źródeł przy rozpoczęciu:** `4914649e055b74cf11ac25bcbfec3755a72debc7` (5 listopada 2026).
- **Hash rodzica commita zapisującego zmiany:** `53770fb9d31496cc3dffb1c9be8a1f5b0d510ac4`. Przed zapisem sprawdzono, że oba pliki źródłowe i siedem plików docelowych nadal są identyczne z migawką.
- **Źródła:** `game/i18n/strings.csv` (195 kluczy), `game/i18n/content.csv` (629 kluczy). EN jest wzorcem, PL kontekstem; DE w grze pozostaje nietknięte.
- **Pliki:** `T31/strings_fr_v2.csv`, `T32/strings_es_v2.csv`, `T33/strings_it_v2.csv`, `T34/strings_pt_br_v2.csv`, `T35/strings_cs_v2.csv`, `T36/strings_uk_v2.csv`, `T37/strings_de_v2.csv`. Istniejące `content_*_v2.csv` były kompletne; nie przepisywano ich.

| Język | Pakiet | Dodane UI | Dodane content | UI po zmianie | Content po zmianie |
|---|---|---:|---:|---:|---:|
| FR | T31 | 66 | 0 | 195 / 195 | 629 / 629 |
| ES | T32 | 66 | 0 | 195 / 195 | 629 / 629 |
| IT | T33 | 66 | 0 | 195 / 195 | 629 / 629 |
| PT-BR | T34 | 66 | 0 | 195 / 195 | 629 / 629 |
| CS | T35 | 66 | 0 | 195 / 195 | 629 / 629 |
| UK | T36 | 66 | 0 | 195 / 195 | 629 / 629 |
| DE | T37 | 66 | 0 | 195 / 195 | 629 / 629 |

**Łącznie dodano 462 tłumaczenia UI.** Niemieckie nowe wartości pochodzą z kolumny `de` źródłowego `strings.csv`, z sześcioma korektami w pakiecie T37. Nie modyfikowano samego `game/i18n/strings.csv`.

## Walidacja

- **Wynik kontroli odtwarzającej logikę `contrib/gpt/validate_v2_localizations.py`: PASS; 0 brakujących kluczy; 0 błędów.**
- Sprawdzono kompletność i unikalność kluczy, nagłówki CSV, wartości niepuste, placeholdery, uzasadnienia zmienionych wartości, progi dialogów/zeszytu oraz 11–12 pól sklepowych na język.
- Dodatkowo sprawdzono wszystkie 462 dopisane wpisy: `tutorial.*` / `lock.*` ≤56, `menu.*` ≤28, `ui.controls.*_desc` ≤80, pozostałe ≤130% EN; 0 przekroczeń; 0 identycznych wpisów EN; 0 błędów placeholderów.
- **Ograniczenie środowiska:** nie uruchomiono dosłownie polecenia `python contrib/gpt/validate_v2_localizations.py`, ponieważ nie było lokalnego checkoutu repozytorium (GitHub dostępny przez konektor, bez dostępu sieciowego z kontenera). Zastosowano kontrolę równoważną regułom tego skryptu na odczytanych plikach przy SHA powyżej. Dla niezależnego potwierdzenia należy uruchomić: `python contrib/gpt/validate_v2_localizations.py --json`.

## DE — proponowane poprawki w źródłowej kolumnie `de`

W poniższej tabeli „obecnie” oznacza zawartość `game/i18n/strings.csv`. Propozycje dla nowych kluczy zapisano jako `de_new` w pakiecie T37 (oryginał pozostaje w `de_old`). Pozostałe istniejące propozycje zachowano tylko informacyjnie; pliki gry należą do sesji A.

| Klucz | Obecnie (main) | Proponuję | Dlaczego |
|---|---|---|---|
| `boot.calib_title` | Two taps 120 ms apart — how many do you feel and hear? | Zwei Impulse im Abstand von 120 ms — wie viele spürst und hörst du? | W kolumnie gry pozostał tekst EN; korekta jest już w pakiecie T37. |
| `boot.calib_two` | Two | Zwei | W kolumnie gry pozostał tekst EN; korekta jest już w pakiecie T37. |
| `boot.calib_one` | One | Einen | W kolumnie gry pozostał tekst EN; korekta jest już w pakiecie T37. |
| `boot.calib_none` | None | Keinen | W kolumnie gry pozostał tekst EN; korekta jest już w pakiecie T37. |
| `boot.calib_skip` | Skip | Überspringen | W kolumnie gry pozostał tekst EN; korekta jest już w pakiecie T37. |
| `settings.feel_section` | Feel (haptics) | Spielgefühl (Haptik) | W kolumnie gry pozostał tekst EN; korekta jest już w pakiecie T37. |
| `settings.quality` | Graphics quality | Grafikqualität | W kolumnie gry pozostał tekst EN; korekta jest już w pakiecie T37. |
| `settings.quality_auto` | Auto (measured) | Automatisch (gemessen) | W kolumnie gry pozostał tekst EN; korekta jest już w pakiecie T37. |
| `settings.quality_high` | High | Hoch | W kolumnie gry pozostał tekst EN; korekta jest już w pakiecie T37. |
| `settings.quality_medium` | Medium | Mittel | W kolumnie gry pozostał tekst EN; korekta jest już w pakiecie T37. |
| `settings.quality_low` | Low (cheap phones) | Niedrig (einfachere Handys) | W kolumnie gry pozostał tekst EN; korekta jest już w pakiecie T37. |
| `showcase.notebook_prefix` | From the master's notebook: | Aus dem Heft des Meisters: | W kolumnie gry pozostał tekst EN; korekta jest już w pakiecie T37. |
| `about.licenses` | Fonts: Bona Nova, Atkinson Hyperlegible Next (SIL OFL 1.1). Engine: Godot 4 (MIT). Extensions: godot-cpp (MIT), GUT (MIT). Full list: THIRD-PARTY-NOTICES.txt in the app. | Schriften: Bona Nova, Atkinson Hyperlegible Next (SIL OFL 1.1). Engine: Godot 4 (MIT). Erweiterungen: godot-cpp (MIT), GUT (MIT). Vollständige Liste: THIRD-PARTY-NOTICES.txt in der App. | W kolumnie gry pozostał tekst EN; korekta jest już w pakiecie T37. |
| `about.post_release_unlocked` | Chapter 7 (A Shared Key) unlocked. | Kapitel 7 („Ein gemeinsamer Schlüssel“) freigeschaltet. | W kolumnie gry pozostał tekst EN; korekta jest już w pakiecie T37. |
| `settings.report_problem` | Report a problem | Problem melden | W kolumnie gry pozostał tekst EN; korekta jest już w pakiecie T37. |
| `settings.report_copied` | Log copied to clipboard. Paste it in your message — nothing is sent automatically. | Protokoll in die Zwischenablage kopiert. Füge es in deine Nachricht ein — es wird nichts automatisch gesendet. | W kolumnie gry pozostał tekst EN; korekta jest już w pakiecie T37. |
| `settings.report_empty` | Log is empty. | Protokoll leer. | W kolumnie gry pozostał tekst EN; korekta jest już w pakiecie T37. |
| `menu.play` | Einsatz starten | Dienst beginnen | Skrócono lub poprawiono istniejący wpis DE zgodnie z limitami T40. |
| `settings.dark_mode_assist` | Kontrasthilfe | Hoher Kontrast | Skrócono lub poprawiono istniejący wpis DE zgodnie z limitami T40. |
| `settings.dark_mode_note` | Dunkelmodus braucht Ton (und Haptik auf dem Handy). | Im Dunkeln hilft der Ton. Handyhaptik unterstützt. | Skrócono lub poprawiono istniejący wpis DE zgodnie z limitami T40. |
| `run.title` | Endloslauf | Endlosdienst | Skrócono lub poprawiono istniejący wpis DE zgodnie z limitami T40. |
| `run.lives_left` | Verbleibende Versuche | Ersatz-Dietriche | Skrócono lub poprawiono istniejący wpis DE zgodnie z limitami T40. |
| `run.finished` | Lauf beendet – {n} Münzen | Dienst zu Ende — Münzen: {n} | Skrócono lub poprawiono istniejący wpis DE zgodnie z limitami T40. |
| `pause.dark_mode` | Dunkelmodus | Im Dunkeln | Skrócono lub poprawiono istniejący wpis DE zgodnie z limitami T40. |
| `about.notice` | Dies ist ein Spiel, kein Lehrgang. Die Mechanismen sind erfunden und vereinfacht. Ein echter Schlüsseldienst prüft immer, ob der Kunde zum Betreten berechtigt ist. | Dies ist ein Spiel, kein Lehrgang. Die Mechanismen sind erfunden und vereinfacht. Ein verantwortungsbewusster Schlüsseldienst prüft, ob der Kunde Zutrittsrecht hat. | Skrócono lub poprawiono istniejący wpis DE zgodnie z limitami T40. |
| `workshop.reward_hint` | Schaltet sich mit dem Fortschritt frei | Wird beim Spielen frei | Skrócono etykietę (limit EN +30%). |
| `practice.t18.goal` | Warte auf den richtigen Klick am Tor der Zuhaltung. | Warte auf den richtigen Klick der Zuhaltung. | Skrócono cel treningowy. |
| `practice.t24.goal` | Zähl jedes Tor jeder Zuhaltung; nichts auslassen. | Zähl jedes Tor der Zuhaltungen, ohne Lücke. | Zachowano liczenie bramek, skrócono tekst. |
| `tutorial.frame_lift_auto` | Ein Daumen: seitlich wählen, nach oben heben. Die Spannung hält das Spiel. | Ein Daumen wählt und hebt; das Spiel hält Spannung. | Skrócono samouczek do 56 znaków. |
| `lock.flap_pause` | Pause | Halt | Słowo «Pause» jest takie samo jak EN; zapis alternatywny do weryfikacji. |
| `ui.job_done` | erledigt | OK | Etykieta «erledigt» przekracza limit 5 znaków; użyto «OK». |
| `settings.language_system` | System | Gerätesprache | W źródle EN chodzi o język urządzenia, nie jedynie «system». |

## Miejsca niepewne i uwagi redakcyjne

- `lock.zone_tension` (FR: `force`) i `lock.flap_pause` (FR: `arrêt`, DE: `Halt`) zastosowano, aby nie kopiować identycznych słów EN; wymaga to weryfikacji w kontekście właściwych kontrolek. W niemieckim naturalne `Pause` jest homografem EN.
- `ui.job_done` wymaga zwięzłej formy przy limicie pięciu znaków; CS i DE używają `OK`, a UK `Є!`. Należy przetestować z faktycznym stanem UI.
- `practice.t06.goal`, `practice.t11.goal` i `practice.t22.goal`: terminy `bits`/`gate` w fikcyjnych mechanizmach można zatwierdzić dopiero po obejrzeniu odpowiednich grafik i słowniczka gry.
- Wskazana korekta językowa przez native speakerów FR/ES/IT/PT-BR/CS/UK/DE przed finalną publikacją. Instrukcje dotyczą wyłącznie fikcyjnych mechanizmów ćwiczebnych w grze; nie dodawano marek ani odwołań do włamań.

Wszystkie zmiany ograniczono do siedmiu plików UI w katalogach T31–T37 i niniejszego raportu T40.
