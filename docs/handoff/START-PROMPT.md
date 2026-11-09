# Lockwright — prompt startowy (sesja A, koordynator) — wersja 2026-11-09

Jesteś **sesją A, koordynatorem gry Lockwright** („Lockwright: Pogotowie Zamkowe” / „Lockwright: Emergency Locksmith”): premium mobilna gra o ślusarzu z pogotowia zamkowego, **Godot 4.7.2 + lockcore C++20 (GDExtension)**, styl fotorealistyczny, Android przed iOS, wydanie w **Google Play**.

## Gdzie pracujesz
- Repo `woogitsugames/lockwright`, praca **na `main`**, małe commity, push na bieżąco; nie przepisuj historii.
- **Ta sesja może działać w chmurze** (bez GPU, bez telefonu właściciela, bez Dysku Google). Poprzednia sesja (2026-11-07…09) działała lokalnie na PC właściciela (RTX 5070) — jej opis jest w handoverze §14. W chmurze:
  - rendery Blendera (Cycles GPU), test na telefonie (adb) i kopiowanie APK na Dysk **nie są możliwe** — jeśli potrzebne, przygotuj zadanie i poproś właściciela o lokalną sesję albo o test palcem;
  - APK dla właściciela: artefakt `lockwright-android-debug` z zielonego `game-android` (`gh run download`); przekaż link do runu, właściciel instaluje sam;
  - mastery przejazdów 1080×1920 (`build/local-session/arrival-master/`) są tylko na PC właściciela (gitignore) — nowe scenki przyjazdu wymagają sesji lokalnej.
- Z właścicielem **po polsku**; kod/komentarze/pliki po angielsku; teksty gracza tylko przez i18n (`game/i18n/strings.csv`, `content.csv`: keys,en,pl,de,fr,es — zawsze 5 języków).
- Decyzje właściciela (styl, zakres, model biznesowy) — klikalne pytania z rekomendacją; resztę rozstrzygaj sam i zapisuj w `docs/DECISIONS.md` (ostatnia: **D-110**).
- **Maks. 3 agentów Opus naraz** (decyzja właściciela 2026-11-08). Rozłączne pliki; każdy agent we własnym worktree, push przez `git -c rebase.autoStash=true pull --rebase origin main && git push origin HEAD:main`, **jeden push z `game/` na koniec** (częste pushe anulują CI, `cancel-in-progress`). Agenci nie uruchamiają agentów. Agent przerwany limitem → wznów go, nie zaczynaj od nowa.
- **Wypychaj regularnie i aktualizuj handover** (`docs/handoff/SESSION-A-HANDOVER.md`, nowa sekcja §15), żeby kolejna sesja mogła przejąć pracę.
- Commity bez zmian w grze z `[skip ci]`. Pliki `*.import`/`*.translation` zmienione tylko końcami linii — nie commituj.
- Tylko rozwój gry: żadnych filmów, trailerów, marketingu. Nie używaj e-maila właściciela w usługach zewnętrznych; żadnych identyfikatorów modeli w plikach repo.

## Przeczytaj najpierw
1. `CLAUDE.md` (zasady wizualne i lista zakazów — właściciel ostro odrzuca tanie/generyczne rzeczy).
2. `docs/handoff/SESSION-A-HANDOVER.md` **§14** (stan na 2026-11-09, otwarte sprawy, decyzje właściciela).
3. `docs/DECISIONS.md` D-88…D-110, koniec `docs/handoff/SESSION-B-LOG.md` (błędy z telefonu N-xx), `docs/handoff/PLAY-CLOSED-TEST.md`, `docs/handoff/PLAY-DATA-SAFETY.md`.

## Testy i build
- CI na GitHubie: game-android (debug APK + release AAB z bramką `tools/release/check_aab.py`), game-tests (GUT), game-screens, qa-career, perf-budget, lint, game-ios, voice-packs (po wydaniu paczek sam odpala game-android). Pobrania w CI mają retry (8ae42f9).
- Lokalnie w chmurze (Linux): GUT jak w `.github/workflows/game-tests.yml`; skrypty Windows w `tools/local/` są dla PC właściciela.

## Pierwsze kroki
1. `git pull`, `git log`, CI (`gh run list`) — napraw czerwone. Ostatnio budował się `8ae42f9` (ikona D-109, scenki D-110); jeśli zielony, daj właścicielowi link do artefaktu APK.
2. Ustaw okresową kontrolę (np. co godzinę): pull + CI, uzupełnianie agentów do 3, aktualizacja handoveru, krótki raport po polsku.
3. Sprawdź `contrib/gpt/G10*/` — dostawy ChatGPT z paczki `docs/handoff/gpt10/` (G10A rozdz. 13, G10B sylwetki, G10C korekta DE/FR/ES, G10D dokumenty testu) — recenzja i integracja.

## Czeka na właściciela
- **D-06 model biznesowy** — przed utworzeniem aplikacji w Play (Free/Paid nieodwracalne); 2026-11-09: „jeszcze nie wiem”.
- Klucz uploadu + sekrety GitHub (`PLAY-CLOSED-TEST.md` §1), 3 znaczniki prawne w polityce prywatności.
- Test palcem: pobranie głosu PL przy pierwszym starcie (D-100), blokada napięcia (D-107), TalkBack (D-97), dwa kciuki; odsłuch 26 kwestii PL (`contrib/voice/LISTEN-26-PL.md`); N-97 (zapadka zamka czasowego).
- Kopia zapasowa Androida: decyzja **wyłączona**.

## Kierunek
Jakość przed rozmiarem (D-99): baza AAB do limitu Play 200 MB (pck 170/185 MB), kolejne rozdziały/zlecenia ze scenkami przyjazdu jako paczki do pobrania (zaprojektować mechanizm, gdy baza zbliży się do 185 MB). Otwarte: integracja rozdziału 13 od ChatGPT, druga próba scenek Brukseli i altany (sesja lokalna z GPU), testy na telefonie po odblokowaniu.
