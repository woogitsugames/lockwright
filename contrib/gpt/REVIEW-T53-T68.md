# Przegląd dostaw GPT: T53, T55, T56, T58, T64, T66, T67, T68

Sesja Claude, 2026-11-06. Kontrola: `tools/i18n_lint.py` po integracji: 980 kluczy, 0 błędów, 2 ostrzeżenia bazowe (`settings.voice_pack.line`); `pytest tools/tests` 26 OK; `achievements.json` poprawny JSON; `store/legal/check_sync.py` OK; `site/build.py --check` OK. **GUT/Godot nie uruchamiano** (CI wymaga zbudowania godot-cpp i Godota 4.7.2; lokalnie brak). Zmiana w `achievements.gd` nie ma testu GUT.

| Zadanie | Decyzja | Gdzie |
|---|---|---|
| T53 zeszyt | przyjęte, 16 wpisów | `game/i18n/content.csv` (dopisane na końcu) |
| T55 ćwiczenia | **nie zintegrowane** | zostaje w `contrib/gpt/T55/` |
| T56 osiągnięcia | przyjęte, 8, z poprawionymi warunkami | `game/data/achievements.json`, `content.csv`, `achievements.gd` |
| T58 dzielnice | **nie zintegrowane** | zostaje w `contrib/gpt/T58/` |
| T64 prywatność | przyjęte jako **poprawka istniejącej polityki**, nie osobny plik | `store/privacy.md`, `store/legal/privacy_*.md`, `site/` |
| T66 / T67 / T68 | przyjęte z poprawkami | `docs/handoff/TEST-CHECKLIST.md`, `BUG-TEMPLATE.md`, `docs/GLOSSARY.md` |

## T53 — wpisy zeszytu
- Zeszyt czyta tylko klucze `notebook.extra.*` (`showcase_screen.gd`, losowo, bez warunku rodziny). Klucze GPT `notebook.<rodzina>.N` nigdy by się nie wyświetliły, więc przemianowane na `notebook.extra.<rodzina>_1/_2`.
- Teksty: poprawna polszczyzna, bez marek, ciepły ton, limit 130 znaków spełniony. Słabsze, ale do przyjęcia: `magnetic.2` („Pomoc czasem przychodzi cicho…”) i `time_lock.1` są ogólnikowe i nic nie mówią o mechanizmie; wpisy są w 3. osobie obserwacji, istniejące `extra` w 1. osobie mistrza („zapisałem”). Do ewentualnej redakcji, nie blokuje.
- Efekt uboczny: wpis o rodzinie może wylosować się graczowi, który jej jeszcze nie spotkał (lekki spoiler, bez wpływu na rozgrywkę). Wyświetlanie warunkowane rodziną wymagałoby zmiany kodu: nie robiono.
- DE jest tu rzeczywiście przetłumaczone (istniejące `extra` mają DE = EN i dają ostrzeżenia lintu). To plus.

## T55 — cele ćwiczeń: NIE zintegrowane
- `lockcore/practice/` ma tylko `t01`–`t30` i żadnej lekcji dla ośmiu nowych rodzin. GPT sam pisze, że `t31`–`t46` to wymyślone identyfikatory bez plików zamków i zdarzeń `lesson_target`. Klucz `practice.<id>.goal` jest czytany z metadanych istniejącego pliku zamka, więc cele bez zamków byłyby martwymi kluczami.
- Do zrobienia przy pracy nad praktyką (D-54): zaprojektować 16 zamków `lockwright.lock/1` z `presentation.practice`, sprawdzić `check_locks` (bot skryptowy, clumsy ≥ 30 %, feeling ≥ 95 %), dopiero potem wpisać cele. Uwaga na `t43`/`t44` (time_lock): gra w tej rodzinie to naprawa, a bot `check_locks` zakłada otwarcie; trzeba sprawdzić, czy `lesson_target` da się tam wyrazić.
- Teksty celów wyglądają sensownie (jedno zdanie, rozróżnienie sygnałów / powrót po pułapce), używają „pin”/„kołek” zgodnie ze słowniczkiem. PL `t33`: „kółko stawiające opór”, `t39`: „kołek” (drewniany, zgodnie z regułą).

## T56 — osiągnięcia
- **Błąd w propozycji GPT i w kodzie:** w `achievements.gd` gałąź `result=open*` nie znała klucza `family=` (nieznane klucze są po cichu pomijane). Czyli `result=open;family=combo` odblokowałoby się przy KAŻDYM otwarciu. Dotyczy to też istniejących wpisów (`false_note`, `wafer_clean`, `pin_plain`, `iron_no_drop` itd.). Dodano obsługę `family=` w `_check_result_triggers` (rodzina bieżącego zlecenia; brak zlecenia, czyli S1–S3 i praktyka, liczy się jako `pin_tumbler`, jak w `JobRun.lock_scene_path`). Skutek uboczny: wpisy dla rodzin bez widoku w grze (`wooden_pin`, `ring_combo`) przestają się odblokowywać po pierwszym otwarciu czegokolwiek, co było błędem. Wymaga sprawdzenia w GUT/na telefonie.
- `achievement.safe_first`: GPT dał `verified=true`, klucz nieobsługiwany i zbędny (każde zlecenie przechodzi weryfikację). Usunięty; warunek `result=open;family=dial_safe`.
- `achievement.clock_repaired`: GPT dał `result=clock_repaired`, którego nie emituje żaden kod. Zamieniono na `result=open;family=time_lock`, bo ukończenie minigry time_lock emituje `lock_opened`. **Do potwierdzenia przez agenta od T43:** zlecenia `kind: clock_repair` (`job.t43_10_03_exhibit_clock`) muszą kończyć się `Events.lock_opened` (albo tym zdarzeniem trzeba rozszerzyć wyzwalacz), inaczej to osiągnięcie nie odblokuje się z nowych zleceń.
- Klucze: GPT `achievement.<id>.name/.description`; gra używa `ach.achievement.<id>.name/.desc`. Przemianowane. Faza `extended`, punkty 10 (zgodne z istniejącymi „pierwsze…”). Treść bez przemocy i włamań; „Otwórz sejf po weryfikacji uprawnień” OK.
- Uwaga: PL „zamek szyfrowy” (`combo_first`) vs nazwa rodziny „Zamek z kółkami”, „zamek nawiercany” vs „Wkładka nawiercana”, „zamek suwakowy” OK, „zamek drewniany” vs „Zasuwa drewniana”. Drobna niespójność ze słowniczkiem; nie blokuje.

## T58 — dzielnice: NIE zintegrowane
- Mapa (`workshop_screen.gd`) to obrazy `zameczno_chapter_1..6` z `clampi(chapter, 1, 6)`; nie ma tekstu dzielnic ani obrazów dla rozdziałów 9–12. Klucze `district.chapterNN.*` nie miałyby odbiorcy.
- Treść zgodna z łukiem T43 (Po sąsiedzkiej Wigilii / Remont, który łączy / Targ i warsztaty / Miejsce przy stole). Opisy są ogólnikowe i podobne do siebie; DE rozdz. 10 („Platz für neue Ideen”) trochę odbiega od PL/EN (stół, pomysły „cudze”). Do użycia, gdy powstanie mapa 9–12 i ekran rozdziału.

## T64 — polityka prywatności
- **Ważne odkrycie:** repo ma już politykę (`store/privacy.md` §1/§2, źródło prawdy dla `site/public/privacy.html` i `store/legal/privacy_*.md`; `docs/legal/PRIVACY.md` nie istnieje). Jest **nieaktualna po D-63**: twierdziła „nie wysyła żadnych danych, działa bez internetu” i „brak `INTERNET`”. Szkic GPT jest krótszy i uboższy od istniejącej polityki (brak zakupów, raportów awarii, dzieci, śledzenia, podstawy prawnej korespondencji, kopii zapasowych w pełnej formie), więc **nie zastąpiono nim** istniejącego tekstu, tylko wprowadzono do niego z T64 treść o pobieraniu głosów.
- Zmiany: „W skrócie” (jedyne użycie sieci to opcjonalne pobranie głosu), nowy akapit „Pobieranie głosów (jedyne użycie sieci)”, „Twoje prawa”, „Zmiany”, w PL i EN; opisy faktów na górze pliku; §3 (Apple: IP w logach hostingu) i §4 (Google Data safety: szyfrowanie w tranzycie = tak) z uwagą „do weryfikacji”. Skopiowano do `store/legal/privacy_*.md` (`check_sync.py` OK), przebudowano `site/public` (`privacy.html`, `en/privacy.html`; w `build.py` poprawiono zdania „działa bez internetu i nie zbiera danych” na stronie „Jak gramy uczciwie”). Strona nadal statyczna, CSP bez skryptów, pola `[…]` podświetlone jako do uzupełnienia. **Nie wdrażano** (D-51).
- Miejsca wymagające weryfikacji prawnej (oznaczone w tekście `[DO WERYFIKACJI PRAWNEJ]` / `[LEGAL REVIEW NEEDED]`): rola dostawcy hostingu (GitHub teraz, Cloudflare później), podstawa i okres logów, transfery poza EOG, zakres praw wobec logów, a w §3/§4, czy adres IP w logach hostingu liczy się jako „collected” w definicjach Apple i Google. Dopisano też, że po stronie gry nie ma ciasteczek ani identyfikatorów (zgodnie z D-63; tego nie sprawdzono w pełnym eksporcie).
- Obserwacje poza zakresem (nie edytowane): `store/listing.md` („Działa offline”) i `store/rating.md` („fully offline… collects no data”) pozostają prawdziwe co do rdzenia gry, ale „fully offline” warto przy najbliższej okazji zmienić na „works offline; optional voice download”. `docs/handoff/RELEASE-CHECKLIST.md` i manifest Androida: potwierdzić brak innych uprawnień sieciowych niż `INTERNET`.
- Szkic GPT zakładał „Planowany hosting: GitHub Releases”: zgodne z D-63. Do ujawnienia kontaktu: adres `privacy@[domena]` nadal do uzupełnienia przez właściciela.

## T66 — lista testu na telefonie
- Zachowano strukturę GPT, ale: tabela rodzin mieszała grywalne i niegrywalne. W kodzie (`JobRun.PHOTOREAL_READY`, `FAMILY_MAP`) grywalnych jest 12 rodzin; `lever_detector`, `wooden_pin`, `ring_combo` nie mają widoku/mapowania, a `tubular`, `bramah`, `sidebar`, `wafer_double` to tylko wpisy w `progression.json`. Rozdzielono na tabelę B (grywalne) i C (N/D).
- Dodano pominięte kontrole: ekran wyboru trybu D-52 i zmiana w ustawieniach, praktyka, rachunek/napiwek, zlecenie z odmową, mapa, gablota/zeszyt, osiągnięcia, pierwsze lekcje rodzin (D-68), pobranie głosu (jedyne użycie sieci), rozdziały 9–12 po integracji T43 (naprawa zegara to nie odmowa).

## T67 — szablon błędu
- Przyjęty; dodano pola specyficzne dla gry (zlecenie `job.…`, rodzina i tier, tryb, tryb napięcia, stan głosu) oraz skąd wziąć log (`ErrorLog`, ekran „Zgłoś problem”, `user://logs/session.log`, nic nie jest wysyłane automatycznie).

## T68 — słowniczek
- Tabele „Rodziny” i „UI” sprawdzono skryptem z `strings.csv`: zgodne co do znaku. Rozbieżności GPT są trafne (`run.lives_left` PL „Pozostałe życia” kontra EN/FR/ES „zapasowe wytrychy”: licznik to `JobRun.lives`, więc PL jest odstępstwem; `molette`/`roue`; „Axial slider” bez „lock”). Zostawione jako pytania w `docs/GLOSSARY.md`, bez zmian tekstów gry. Nie było pełnego przeszukania `content.csv`.
