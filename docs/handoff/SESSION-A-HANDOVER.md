# Lockwright: przekazanie koordynacji (sesja A → nowa sesja A)

Stan na **2026-11-05 ok. 20:15 UTC**. Poprzednia sesja A kończy pracę z powodu limitu tygodniowego. Nowa sesja pracuje na **innym koncie i innej maszynie**, więc nie ma dostępu do starych agentów, triggerów ani plików w scratchpadzie. Wszystko, co trwałe, jest w repo `woogitsugames/lockwright` (`main`).

## 1. Rola sesji A (koordynator)
- **Kontakt z właścicielem:** rozmawiasz z nim po polsku. Decyzje podejmujesz sam („ty wybierasz sam to co najlepsze, nie pytaj mnie o zdanie”). Pytasz tylko o rzeczy, które naprawdę należą do niego: styl, zakres, model biznesowy, wybór kierunku. Pytania dajesz jako **klikalne** (AskUserQuestion, 2–4 opcje, rekomendowana pierwsza).
- **Agenci:** prowadzisz własnych agentów, maks. 5 równolegle, z rozłącznymi zakresami plików. Agenci nie uruchamiają kolejnych agentów.
- **Zewnętrzni wykonawcy** (właściciel przekazuje im zlecenia):
  - **ChatGPT:** grafika, tekst, dźwięk, tłumaczenia. Zlecenie to plik `.md` w `docs/handoff/gpt*/`, wysłany właścicielowi jako ZIP.
  - **Mistral Vibe:** agent kodujący jak Claude Code. Zlecenia w `docs/handoff/mistral/`.
  - **Magnific:** tylko obrazy. Kolejka w **jednym** pliku: `docs/handoff/MAGNIFIC-KOLEJKA.md`.
  - **Gemini/Antigravity:** `docs/handoff/gemini/`.

  Oni tylko robią i wypychają albo oddają ZIP. Ty odbierasz, oceniasz (zapis `contrib/gpt/REVIEW-rundaN.md`), włączasz do gry, puszczasz CI i scalasz.
- **Sesje B i C:** inne sesje Claude właściciela.
  - **B:** gra i Android. Log: `docs/handoff/SESSION-B-LOG.md`, prompty `SESSION-B-PROMPT-*.md`.
  - **C:** strażnik CI i recenzja. Log: `SESSION-C-LOG.md`, przegląd `SESSION-C-REVIEW.md`.

  Komunikujesz się z nimi wpisami „## Od sesji A: …” w ich logach. Sesja A przejęła prompt 7 (N-52…N-62), który jest już zrobiony. B zajmuje się teraz tylko iOS/CI.
- **Zrzuty:** wysyłasz właścicielowi na bieżąco (SendUserFile): zestawienia PIL, APK.

## 2. Zasady repo (twarde, patrz CLAUDE.md)
- **Commity:** praca na `main`, małe commity, push na bieżąco: `git -c rebase.autoStash=true pull --rebase origin main && git push origin main` (przy wyścigu pushów ponów). Na końcu wiadomości commita dwie linie atrybucji zgodne z systemem nowej sesji. Bez nazw modeli w artefaktach.
- **Stop hook** wymaga commita i pusha przed końcem tury. Uwaga: commity WIP z `game/**` **restartują** `game-android` (`cancel-in-progress`). Gdy czekasz na build, commituj tylko pliki spoza `game/` (`git add -A -- . ':!game'`).
- **Importy Godota:** root `.gitignore` ignoruje `*.import`. Każdy nowy obraz w `game/assets` wymaga **`git add -f` pliku `.import`** z importem stratnym, inaczej CI zaimportuje go bezstratnie (N-30).
- **Eksport:**
  - pliki czytane przez `FileAccess` (JSON) muszą być w `include_filter` w `game/export_presets.cfg`;
  - nieużywane pliki są w `exclude_filter` (D-55);
  - CI release czyta filtry z `preset.0`.
- **Teksty:** teksty gracza tylko przez `game/i18n/strings.csv` / `content.csv` (`keys,en,pl,de`). W PL pin bębenkowy to **„pin”**, a „kołek” tylko w zamku drewnianym.
- **Heredoc w bashu:** używaj `<<'EOF'` (z cudzysłowem), bo inaczej backticki się wykonają. To już zepsuło raz briefy.
- **Licencje i zasoby:** fonty tylko OFL. Każdy zasób trafia do `docs/ASSETS.md` (AI z promptem, D-42).
- **Decyzje:** zapisujesz w `docs/DECISIONS.md`. **Następny wolny numer: D-57.**
- **Wizualne:** zakazana lista jest w CLAUDE.md (bez sepii, SaaS-kart, glassmorphism, złotego blasku…). Gra jest **fotorealistyczna** (D-05).

## 3. Triggery do odtworzenia na nowym koncie (stare usunięte)
Utwórz je narzędziem `create_trigger` (fire into this session):
1. **„Lockwright: godzinna kontrola”**, cron `CRON_TZ=Europe/Warsaw 31 * * * *`. Prompt:
   > Godzinna pobudka (zlecona przez właściciela). Sprawdź stan Lockwright: agenci w tle (wyniki i zrzuty do przejrzenia i wysłania właścicielowi), `git pull` + `git log`, `docs/handoff/SESSION-B-LOG.md` i `SESSION-C-LOG.md`, CI (`game-android`, `game-tests`, `game-screens`, `qa-career`, `perf-budget`). Commituj i pushuj na main. Maks. 5 agentów, rozłączne pliki. Gdy agent skończył, zleć następną sensowną pracę z `docs/handoff/SESSION-A-HANDOVER.md` §5. Krótko zaraportuj właścicielowi po polsku.
2. **Jednorazowe sprawdzanie buildu** (`send_later`) po każdej serii zmian w `game/`. Treść zadania jest w §5 pkt 1.

**Sesja C** ma własny trigger („Sesja C: runda strażnika CI”) na starym koncie. Nie ruszaj go, jest właściciela.

## 4. Stan na teraz
**Zrobione dziś** (wszystko na `main`, lokalnie GUT 79/79):
- **Po teście właściciela na telefonie (APK run 92):**
  - N-52: „wstecz” Androida (autoload `Nav`);
  - N-53/N-59: marginesy i brak scrolla poziomego (`screen_frame.gd`, test układu);
  - N-55: uprawnienie VIBRATE plus kontrola w CI;
  - N-56: klapka pauzy (zdjęcie G21);
  - N-57: lupa z okularem;
  - N-58: dźwięk bez napięcia i podpowiedź;
  - N-60: rozmowa (wiersze, portrety 39 + 6, Ślusarz po prawej);
  - N-61: samouczek prowadzony kredą (`tutorial_coach.gd`);
  - N-62: grywalność (wejście w dp, czoło rdzenia z napinaczem `plug_face.gd`, ruch pinu 55 dp, kreda `chalk_layer.gd`).
- **Decyzje właściciela:**
  - D-52: tryb „Napięcie automatyczne” wybierany na starcie (`control_choice.tscn`, domyślnie podświetlony);
  - D-53: kreda w samouczku i pierwszych 3 zleceniach.
- **Pozostałe:**
  - D-54: zamki ćwiczebne strojone T38;
  - D-55: rozmiar paczki (pck 59,9 → 33,1 MB, limit CI 58 MB);
  - D-56: skala dp w poziomie (`DpScale`);
  - samouczek gra autorskie zamki `game/data/tutorial/s1–s3.json` (`LockcoreSession.create_from_json`);
  - głosy S03v2 w grze (Ogg; zapasowy zestaw `contrib/gpt/S03v2-py`);
  - 17 poprawek DE z T40;
  - „Rozpocznij bieg” → „Zacznij dyżur”.

**APK:** run **131** (https://github.com/woogitsugames/lockwright/actions/runs/42100326036) jest zielony i ma VIBRATE w manifeście. AAB w artefakcie ma 55,6 MB. APK `Lockwright-debug-run131.apk` wysłany właścicielowi 2026-11-05 ok. 20:40 UTC. Czekamy na jego test (lista w §5 pkt 1).

**Restart kontenera ok. 20:50 UTC przerwał obu ostatnich agentów.** Poprzednia sesja ich nie wznawiała, bo kończył się limit. Ich zapisany stan jest w repo:
- menu: `art/blender/menu_gate.py` (scena), pierwszy roboczy render `art/renders/menu/menu_portrait.png` (commit a4f59d1), `menu_hits*.json`. **Do poprawy** według uwag właściciela i sesji A: dramatyczne światło jak w zamkach, tablica na ok. 75% szerokości, mniej równe litery, większe zawieszki, przetarcia ściany. Dalej wersja pozioma i stan „wciśnięty”;
- rendery zamków: oddane wafer, lever, ring_combo, wooden_pin. Do zrobienia: warded oraz poprawki lever (patyna) i ring_combo („E” → cyfra).

Te zadania przejmij nowymi agentami.

**Agenci, którzy mogli jeszcze pracować w chwili przekazania** (dokończą i wypchną):
- **Render menu w Blenderze (proof):** `art/blender/menu_gate.py` → `art/renders/menu/` (`menu_portrait.png`, `menu_landscape.png`, `menu_pressed_example.png`, `menu_hits.json`).
- **Rendery zamków z materiałami ze zdjęć** (`art/renders/*.png`): zapadkowy (patyna za duża → poprawka), szyfrowy (litera „E” na bębenku → cyfra), z zastawkami.

Sprawdź `git log` i zawartość tych katalogów.

## 5. Co dalej (kolejność)
0. **N-63 (KRYTYCZNE, wpis w SESSION-B-LOG.md):** 25 z 30 zleceń to rodziny inne niż `pin_tumbler`, a te idą do starego, prowizorycznego `lock.tscn`. Właściciel trafił na to w APK z runu 131 („jakieś g…”).
   - **Najpierw (zrobione):** prowizorka jest odcięta; `JobRun.PHOTOREAL_READY = [pin_tumbler]`, a lista zleceń i tryb biegu pokazują tylko te rodziny. **Sprawdź `qa-career` i `test_e2e_career`**, bo kariera ma teraz mniej zleceń. Gdy powstanie plan B dla rodziny, dopisz ją do `PHOTOREAL_READY`.
   - **Potem:** plan B dla warded, wafer i lever, na bazie `art/renders/*.png` z materiałami ze zdjęć.
1. **Build i APK dla właściciela:**
   - zielony `game-android` dla najnowszego commitu w `game/`. Jeśli nie ma, użyj `workflow_dispatch`, ale nie pushuj nic do `game/`, dopóki trwa;
   - pobierz artefakt `lockwright-android-debug` przez API GitHub (`/actions/runs/<id>/artifacts` → `archive_download_url`, `curl -L` z tokenem);
   - sprawdź w Pythonie, że `AndroidManifest.xml` z APK zawiera `VIBRATE` w UTF-16LE;
   - zanotuj rozmiar AAB (cel ≤ 58 MB);
   - wyślij APK z listą: wstecz, wibracje („Impuls próbny”), wybór sterowania, samouczek S1–S3 w obu trybach, lupa, klapka pauzy, warsztat, rozmowa z portretami i głosami, poziom.
2. **Wygląd menu i ekranów (najważniejsza otwarta sprawa).**
   - Właściciel uznał obecne ekrany (enamelowe tabliczki, karty) za „AI slop”. Makiety HTML/CSS (`mockups/ui-directions/`, `docs/styles/ui-directions.md`) za „tani badziew” obok fotorealistycznej gry. Podobały mu się **kierunki** 1 (tablica lokatorów z filcu) i 4 (zawieszki z punktu dorabiania kluczy), ale nie wykonanie.
   - **Ustalona metoda:** menu i ekrany **renderowane w Blenderze** jak zamki (materiały ze zdjęć `art/textures/photo/`, światło z klatki), a gra kładzie niewidoczne strefy dotyku z `menu_hits.json` i podmienia zapieczone stany „wciśnięty”.
   - **Kolejność:** pokaż właścicielowi proof menu z `art/renders/menu/` (zestawienie obok renderów zamków). Dopiero po akceptacji rób ustawienia, zlecenia, warsztat i rozmowę w tym samym duchu, potem integrację w Godot. **Nie pokazuj makiet CSS.**
3. **Drobne z raportów agentów:**
   - w poziomie dolny pas ekranu zamka ucina wytrychy i lupę;
   - tekst kroku „w bok wybierasz pin” nie pasuje do zamka z 1 pinem;
   - S1 bot otwiera w 1,4 s, więc sprawdź na telefonie, czy nie za łatwy;
   - „ręka ducha” (H2/H4) i eskalacja po 15 s z ONBOARDING §2 nie są zrobione;
   - tablica tła menu w poziomie (G20 jest tylko 9:16).
4. **Zewnętrzni:**
   - **Magnific:** w kolejce zostaje A1 (tło menu docelowe 9:16 i 16:9). Może się zdezaktualizować, jeśli menu idzie w Blender, więc zdecyduj po akceptacji proofu.
   - **Mistral Vibe:** dostał `docs/handoff/mistral/V01-i18n-assets-lint.md` (narzędzia `tools/i18n_lint.py`, `tools/assets_lint.py`, `lint.yml`). Gdy wypchnie, sprawdź raport `V01-REPORT.md` i popraw wykryte błędy.
   - **ChatGPT:** wszystko oddane (G17, G19, G20 częściowo, G21, S05, T39, T40). Odrzucone G18 (sepia). Kolejne zlecenia dopiero po wyborze wyglądu menu (grafiki do niego) i na „rękę ducha”. Tłumaczenia 7 języków (`contrib/gpt/T31–T37`) nie są jeszcze w grze, bo gra ma PL/EN/DE. Przy nowych kluczach daj krótkie zlecenie z walidatorem `contrib/gpt/validate_v2_localizations.py`.
   - **Sesja C:** test ASR głosów (`contrib/gpt/S03v2/` ma skrypt faster-whisper) i odsłuch próbki.
5. **Sprawdzenie TECH §8 i pomiary na telefonie właściciela:** D-33, `docs/handoff/POMIARY.md`.

## 6. Ważne preferencje właściciela
- **Testowanie:** testuje na Androidzie i nagrywa ekran. Klatki z nagrania wyciągaj `ffmpeg -vf fps=…,tile=…` i oglądaj. Testy z telefonu zapisuj jako N-xx w `SESSION-B-LOG.md` ze zrzutami w `docs/handoff/device-tests/<run>/`.
- **Priorytety:** Android przed iOS (iOS na końcu, konto Apple jest). Strona idzie na Cloudflare Pages, publikacja tylko na sygnał. Model biznesowy jeszcze otwarty (D-06).
- **Jakość:** chce jakości na poziomie fotorealistycznych renderów i **ostro ocenia wszystko, co wygląda tanio lub generycznie**. Zanim mu coś pokażesz, porównaj to sam z renderami zamków.
- **Zlecenia dla wykonawców:** krótkie, jeden obraz na wiadomość dla ChatGPT (kolaże i fałszywe blokady były problemem). Dla Magnific prompty po angielsku, 4 warianty.

## 7. Prompt startowy dla nowej sesji
Patrz `docs/handoff/SESSION-A-START-PROMPT.md`.

## 8. Nowa sesja A (2026-11-05, ok. 21:15 UTC)
- Trigger „Lockwright: godzinna kontrola” utworzony na nowym koncie (`CRON_TZ=Europe/Warsaw 31 * * * *`).
- APK **run 132** (42088d4, ze stopgapem N-63) zielony, VIBRATE w manifeście (UTF-16LE) ✓, AAB 55,6 MB ✓ — wysłany właścicielowi.
- `game-tests` 131 czerwony tylko przez `test_e2e_career` (5 grywalnych zleceń < 10 po N-63) — test poprawiony (7cb0deb): każde zlecenie rodziny z `PHOTOREAL_READY` musi być grywalne.
- Proof menu `art/renders/menu/menu_portrait.png` **nie pokazany** właścicielowi: płaskie światło, tablica za mała obok renderów zamków. Do poprawy po instalacji Blendera (pobranie z blender.org czeka na zgodę właściciela w nowym środowisku).
- Agenci: plan B dla warded → wafer → lever (N-63, zakres `game/scripts/photoreal*`, `game/scripts/lock`, sceny photoreal, `export_presets.cfg`); odbiór Mistral V01 (`tools/`, `lint.yml`, `game/i18n/*.csv`, `docs/ASSETS.md`).

## 9. Noc 2026-11-05/06 (tryb autonomiczny, do 6 agentów, raport rano 9:00 Bruksela)
Agenci w toku (stan 22:00 UTC): menu w Blenderze (`menu_gate.py`), poprawki renderów zamków (lever/ring_combo/warded), plan B warded → wafer → lever + N-65 rozdzielczość, QA N-64/N-66 (przepływ po samouczku, rachunek, tryb ciągły), głosy ElevenLabs PL+EN (D-57, korekta tekstów), nowe rodziny lockcore dial_safe → combo (D-59).
Kolejka, gdy ktoś skończy:
1. Integracja głosów w `job_arrival.gd` (kwestia po kwestii, napisy, tap przewija, magistrala `Voice`) — po agencie QA.
2. Wpięcie V02 (`HintLadder`, `GhostHand`) w `tutorial_coach.gd` / widok zamka — po agencie planu B; odbiór `V02-REPORT.md`.
3. Proof scenki przyjazdu D-58 (`job.wrong_floor`) w Blenderze — po agencie menu (CPU); postacie z Magnific D (do tego czasu sylwetki zastępcze).
4. Głosy DE, potem FR/ES (teksty z T31–T37 po korekcie).
5. Plan B dla nowych rodzin lockcore, gdy będą gotowe.
6. Rano: paczki Magnific (sekcje C, D), ChatGPT (`gpt5/`), Mistral (V03) + APK + zestawienia.
- **Właściciel 2026-11-05 22:05:** na razie **tylko rozwój gry** — żadnych filmów, zwiastunów (GEM1-v2 wstrzymany), rolek ani materiałów marketingowych. **Gemini niedostępny** (brak limitu) — bez zleceń dla niego. Rendery GPU i testy przez adb może robić lokalna sesja Claude Code u właściciela (RTX 5070, 64 GB RAM).

### Pytania do właściciela na rano (klikalne)
1. **Rozmiar paczki z głosami:** PL+EN+DE = 21,1 MB nagrań → pck ok. 54 MB (limit 58). FR/ES się nie zmieszczą. Opcje: języki głosów pobierane na żądanie (Play Asset Delivery / osobne paczki), mocniejsza kompresja mowy (mono 24–32 kHz, −20–30%), albo w paczce tylko PL+EN, reszta do pobrania.
2. **Hania (7 lat):** ElevenLabs blokuje głosy dzieci; czyta ją jasny dorosły głos (jak dubbing animacji). Zostawić czy dać jej tylko napisy i wokalizacje?
3. **Plan ElevenLabs:** potwierdzić, że konto ma licencję komercyjną (D-42, ASSETS.md).
4. Drobne: „Dyrektorka” ma na portrecie mężczyznę — głos żeński według tekstu; podmienić portret?

## 10. Pauza 2026-11-06 ok. 10:50 UTC (limit 5 h)
Wszystko na `main`. Trigger godzinny wyłączony; wznowienie przypomnieniem ok. 12:26 UTC (włącza trigger z powrotem). Do dokończenia: teksty zamka z suwakami (axial_slider) kierunkowo neutralne + pełny GUT; czekamy na GPT G23/T43 i wyniki testu APK run 175.

## 11. Stan 2026-11-06 ok. 16:45 UTC (limit — przekazanie)
- **Gra:** kariera 1–12 (83 zlecenia, ok. 2 h 15 min), 15 rodzin zamków z ekranami planu B (8 nowych z D-59), lekcje pierwsze dla nowych rodzin, podpowiedzi H0–H4 z sylwetkami dłoni (G23), menu 75 % z GPU, głosy PL/EN w paczce + DE jako pck na żądanie (D-63), portrety obsady (G21/G24), pełne postacie Kazimierz/Teresa (G23/G25). Ostatni zielony APK: run 189 (`9ee23f9`), wysłany właścicielowi.
- **Decyzje:** D-57…D-72 (głosy, scenki 2.5D, nowe rodziny, menu 75 %, budżet 150 MB, rozdziały 7–8, wyposażenie warsztatu, remap rodzin).
- **W toku (agenci mogli zostać przerwani):** głosy FR/ES + reakcje 11 postaci + 3 kwestie do odsłuchu; scenka przyjazdu `wrong_floor` w grze (Kazimierz v2); wyposażenie warsztatu (D-71, rendery w toku). Ich WIP jest w commitach `[skip ci]` — dokończyć, potem pełne CI.
- **Zewnętrzni:** Mistral V04 (sceny „dzień po”) zlecony; GPT: nowa paczka 50 zleceń `docs/handoff/gpt8/PACZKA-50-ZLECEN.md` (ZIP `paczka-gpt-50-zlecen-2026-11-06.zip`). Sesja lokalna (Codex, GPU): `docs/handoff/LOCAL-SESSION-PROMPT.md` (cienie postaci, finał menu/wyposażenia).
- **Trigger** „Lockwright: godzinna kontrola” (trig_01MTXV8ofhPWFvi8qwGrzixU) włączony.
