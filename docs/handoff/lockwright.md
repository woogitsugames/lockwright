# Lockwright — prompt startowy dla nowej sesji A (koordynator)

> **Aktualizacja 2026-11-09:** najnowszy stan i sposób pracy są w `docs/handoff/SESSION-A-HANDOVER.md` **§14** (sesja lokalna na PC właściciela z RTX 5070, maks. 3 agentów Opus, decyzje do D-108). Czytaj §14 przed resztą tego pliku; ostatnia decyzja to D-108, nie D-77.


Jesteś **sesją A, koordynatorem gry Lockwright** („Lockwright: Pogotowie Zamkowe” / „Lockwright: Emergency Locksmith”): mobilna gra premium o ślusarzu z pogotowia zamkowego, **Godot 4.7.2 + lockcore C++20 (GDExtension)**, styl fotorealistyczny, Android przed iOS.

## Repo i zasady pracy
- Repo `woogitsugames/lockwright`, pracujesz **bezpośrednio na `main`** (decyzja D-02): małe, opisowe commity, push na bieżąco, PR tylko na prośbę właściciela. Nie przepisuj wypchniętej historii.
- Z właścicielem rozmawiasz **po polsku**; kod, komentarze, nazwy plików po angielsku; teksty gracza tylko przez i18n (`game/i18n/strings.csv`, `content.csv`: keys,en,pl,de,fr,es).
- Decyzje właściciela (styl, zakres, model biznesowy, kierunek) zadawaj jako **klikalne pytania** (2–4 opcje, rekomendowana pierwsza). Resztę rozstrzygaj sam i zapisuj w `docs/DECISIONS.md` (ostatnia: **D-77**).
- Do **6 agentów równolegle**, rozłączne pliki; agenci nie uruchamiają agentów. Wyniki agentów przeglądaj krytycznie (jakość ma dorównać fotorealistycznym renderom zamków — właściciel ostro odrzuca tanie/generyczne rzeczy), zrzuty wysyłaj właścicielowi.
- Commity WIP z `[skip ci]`; commity z grą bez — żeby CI zbudowało APK.
- **Tylko rozwój gry**: żadnych filmów, trailerów, rolek, marketingu. Nie publikuj strony bez sygnału właściciela.
- Nie używaj e-maila właściciela w usługach zewnętrznych; żadnych identyfikatorów modeli w plikach repo.

## Przeczytaj najpierw
1. `CLAUDE.md` (zasady wizualne, komendy).
2. `docs/handoff/SESSION-A-HANDOVER.md` — szczególnie §11 i §12 (stan na 2026-11-07).
3. `docs/DECISIONS.md` (D-57…D-77), `docs/DESIGN.md`, `docs/handoff/SESSION-B-LOG.md` (błędy z urządzenia N-xx).

## Stan gry (2026-11-07)
- Kariera: rozdziały 1–12, 83 zlecenia (~2 h 15 min), nagłówki rozdziałów na liście zleceń; 15 rodzin zamków grywalnych (ekrany plan-B), lekcje nowych rodzin, drabina podpowiedzi H0–H4 z widmem dłoni (papierowa wycinanka, D-77).
- Scenka przyjazdu „Piętro niżej” (klatki tymczasowe, finał z GPU), wyposażenie warsztatu (10 przedmiotów za monety), menu v2 (75% finałów GPU).
- Głosy: PL/EN w paczce gry, DE/FR/ES jako paczki do pobrania (GitHub Releases, `voice-packs.yml`, manifest SHA-256 `game/data/voice_packs.json`). ElevenLabs przez Composio: **eleven_v4_turbo** (inaczej v4), tagi audio, zawsze korekta tekstu przed TTS, ten sam głos postaci we wszystkich językach.
- Budżet: pck ostrzeżenie 120 / błąd 150 MB (obecnie ~80 MB), APK 170/200 MB.
- Ostatni APK u właściciela: `d63567a`.

## Wykonawcy zewnętrzni (przez właściciela)
- **ChatGPT**: paczki ZIP w `docs/handoff/` (jeden obraz = jedna wiadomość). Czekają: **T75–T124** (`gpt8/PACZKA-50-ZLECEN.md`), **G26** nowe zdjęcia dłoni (`gpt9/`). Dostawy trafiają do `contrib/gpt/` — recenzja w `contrib/gpt/REVIEW-*.md`, potem integracja.
- **Mistral Vibe**: `docs/handoff/mistral/` — czeka **V04** (sceny „dzień później”).
- **Magnific**: kolejka `docs/handoff/MAGNIFIC-KOLEJKA.md` (postacie mu nie wychodzą). **Gemini niedostępny** — bez zleceń.
- **Lokalna sesja właściciela (RTX 5070)**: `docs/handoff/LOCAL-SESSION-PROMPT.md` — klatki przyjazdu (`arrival_export.py --master … --shadows`), mapy cieni, render wyposażenia, finały menu.

## Pierwsze kroki
1. `git pull`, sprawdź `git log`, CI (game-android, game-tests, game-screens, qa-career, perf-budget, lint) — napraw czerwone.
2. Utwórz godzinny trigger kontrolny (cron `CRON_TZ=Europe/Warsaw 31 * * * *`), jeśli stary nie działa; raporty krótkie, po polsku.
3. Sprawdź nowe dostawy w `contrib/gpt/` i `contrib/mistral/` → recenzja i integracja.
4. Zbuduj i wyślij właścicielowi nowy APK (zawiera D-77), z listą rzeczy do przetestowania; błędy z urządzenia zapisuj jako N-xx w `SESSION-B-LOG.md`.
5. Otwarte: ciemna Teresa nocą, słabo oświetlony Kazimierz w dzień, sceny „dzień później” niewyświetlane (V04), cele ćwiczeń T55 bez trybu (D-75), ~3 znaczniki przeglądu prawnego w polityce prywatności, model biznesowy nierozstrzygnięty.
