# Sesja C — etap 3 (długa praca, 1 agent naraz)

Kontynuujesz pracę jako **sesja C** nad grą **Lockwright** (repo `woogitsugames/lockwright`, gałąź `main`). Etapy 1 i 2 masz za sobą. Obowiązują zasady z `SESSION-C-PROMPT.md`, `SESSION-C-PROMPT-2.md` i `CLAUDE.md`:
- pracujesz na `main`, w małych commitach po angielsku;
- przed każdym pushem robisz `git pull --rebase origin main`; konflikty rozwiązujesz do końca i **nigdy nie commitujesz znaczników konfliktu**;
- co godzinę dopisujesz wpis do `docs/handoff/SESSION-C-LOG.md`;
- naraz pracuje najwyżej 1 agent;
- nikt nie odpowie na pytania: decyzje zapisujesz w `docs/DECISIONS.md` jako kolejne wolne D-NN (najpierw sprawdź najwyższy numer; teraz to D-40).

Zadania wykonuj **jedno po drugim, w tej kolejności**, aż do końca listy.

## Najpierw przeczytaj
`docs/FEEL.md` (spec haptyki i dźwięku dla 7 rodzin), `docs/CLIENTS.md`, `docs/ECONOMY.md`, `docs/MARKETING.md`, `docs/COMPLIANCE-AUDIT.md`, `docs/handoff/SESSION-B-PROMPT-3.md` (co robi teraz sesja B), `docs/DECISIONS.md` od D-31.

## Kto jest właścicielem jakich katalogów
- **Twoje:** `spikes/`, `store/`, `audio/v2/`, nowe `haptics/` (pliki wzorców), nowe `qa/` (automaty testujące), nowe `site/` (strona gry), `docs/handoff/POMIARY.md`, `docs/handoff/A11Y-AUDIT.md`, `docs/handoff/SESSION-C-REVIEW.md`.
- **Sesja B (Mistral):** `game/` (bez `*/photoreal/`), `platform/`, `data/`, `game-*.yml`.
- **Sesja A:** `lockcore/`, `art/`, `mockups/`, `game/*/photoreal/`, `tools/`.

Cudzego kodu nie zmieniasz. Uwagi do niego wpisujesz do `SESSION-C-REVIEW.md` jako N-13 i dalej.

## Zadania

1. **Wzorce haptyki jako pliki (`haptics/`).** Z `FEEL.md` wygeneruj skryptem:
   - pliki AHAP dla iOS (Core Haptics);
   - pliki kompozycji dla Androida (prymitywy z łańcuchem zastępczym A4→A0 oraz wersje envelope/amplitude);
   - dla każdego zdarzenia i pod-zdarzenia wszystkich 7 rodzin.

   Dodaj walidator, który sprawdza zgodność z budżetem intensywności FEEL.md (RMS, wypełnienie, mocne impulsy na 10 s). Dodaj podgląd w HTML, który rysuje krzywe i odtwarza dźwięk z `audio/v2` zsynchronizowany z obwiednią haptyki. Napisz README, jak sesja B ma je wczytać.
2. **Dźwięk, część 2 (`audio/v2/`).** Kontynuuj syntezę modalną, bez cudzych sampli:
   - pętle otoczenia: klatka schodowa, warsztat, noc z minutnikiem, deszcz za oknem;
   - dźwięki UI w stylu diegetycznym: skóra zwijki, kartka, kreda, zeszyt, telefon zleceń, szuflada gabloty;
   - nagrody: otwarcie drzwi, „dzięki” bez głosu (ciepły motyw 2–3 s), kasa monet.

   Dodaj zasady miksu w README: głośność w LUFS, priorytety i ducking zgodne z FEEL.md. Sprawdzaczem pilnuj onsetu ≤ 2 ms dla zdarzeń zamka. Wszystko wpisz do ASSETS.md.
3. **Automat QA (`qa/`).** Skrypt, który uruchamia grę headless (Godot z repo, `--headless`) i przechodzi całą karierę botem lockcore (samouczek, 29 zleceń, zakupy, gablota). Raportuje soft-locki, crashe, brakujące klucze i18n, ekrany bez wyjścia i czas sesji. Workflow `qa-career.yml`: nocny i na każdy push do `game/`, z raportem jako artefakt. Znalezione błędy wpisuj jako N-xx do `SESSION-C-REVIEW.md`.
4. **Ciągły przegląd sesji B.** Co godzinę sprawdzaj nowe commity B w `game/`, `platform/` i `data/`:
   - weryfikuj poprawki oznaczone `→ naprawione w <hash>`;
   - szukaj regresji;
   - sprawdzaj zgodność z FEEL.md, D-12 (bez paneli) i zasadami z CLAUDE.md.

   Wpisy dopisuj do `SESSION-C-REVIEW.md`. To zadanie trwa równolegle przez cały etap: po każdym zadaniu z tej listy zrób rundę przeglądu.
5. **Strona gry (`site/`).** Statyczny HTML, bez frameworków, PL i EN:
   - strona główna z renderami z `art/renders/` i makietami z `mockups/realizm/png/`;
   - press kit z `MARKETING.md` §3;
   - polityka prywatności (wariant bez zbierania danych, zgodny z `store/privacy.md`);
   - kontakt jako pole do uzupełnienia.

   Fonty OFL. Bez klisz z listy zakazów w `DESIGN.md`. Workflow publikacji na GitHub Pages przygotuj, ale nie włączaj (wymaga zgody właściciela; opisz to w logu).
6. **Sklep, część 2.** Gdy sesja B ma job `game-screens`, zbuduj zrzuty sklepowe z prawdziwych ekranów gry (szablon z etapu 2). Przygotuj scenariusz App Preview (15–30 s, nagranie z aplikacji, zgodnie z MARKETING.md) i listę ujęć. Uzupełnij ankiety IARC i Apple. Dane właściciela zostaw jako pola.
7. **Dokumenty prawne (`store/legal/`).** Szkice PL i EN: regulamin i EULA (dla wariantu premium; model D-06 jest otwarty, więc zaznacz miejsca zależne od niego), polityka prywatności i informacja „to gra, nie kurs” w formie prawnej (gra nie uczy otwierania realnych zamków; mechanizmy są wymyślone). Na górze: „szkic do konsultacji z prawnikiem”.
8. **Audyt dostępności, runda 2.** Po poprawkach sesji B (zadanie 9 w jej prompcie) sprawdź ponownie wszystkie punkty `A11Y-AUDIT.md` na zrzutach z `game-screens` i dopisz wynik.
9. **Budżety wydajności.** Zapisz w `docs/handoff/POMIARY.md` (§8) progi FPS, pamięci, rozmiaru APK/IPA i czasu startu dla tanich i średnich urządzeń, plus automat w CI, który zgłasza przekroczenie rozmiaru paczki i czasu startu headless.
10. **Weryfikacja determinizmu na buildach gry.** Rozszerz `spikes/determinism` tak, żeby porównywał hashe powtórek z `lockcore_gd` w APK (emulator Androida arm64 w CI, jeśli się da; inaczej qemu jak w etapie 1) z hashami z hosta.

Na końcu dopisz do logu tabelę statusów wszystkich 10 zadań. Potem kontynuuj zadanie 4 (ciągły przegląd) aż do wyczerpania limitu.
