# T05 — Przegląd zgodności z zasadami sklepów

**Data:** 2026-11-05  
**Repozytorium:** woogitsugames/lockwright, baza main  
**Zakres zmian:** wyłącznie contrib/gpt/T05/

## Co zrobiono

Wykonano przegląd zasad App Store Review Guidelines i Google Play Developer Policy dla mobilnej gry o legalnym ślusarzu. Sprawdzono aktualne oficjalne zasady sklepów, istniejące opisy PL/EN i rating, założenia prywatności, sekcje projektu i przykładowe ścieżki weryfikacji prawa do lokalu w kodzie. Przygotowano rejestr 14 ryzyk z odwołaniami do zasad, rekomendowane brzmienia PL/EN, porównanie płatnej aplikacji z bezpłatnym początkiem i zakupem, omówienie ratingów i dzieci oraz checklistę 36 punktów.

**Istotne ustalenie:** game/scripts/ui/job_verify.gd zawiera bezwarunkowe przejście w funkcji _accept() do sceny zamka, również gdy job.id zaczyna się od job.refuse. Ten fakt jest sprzeczny z komentarzem w pliku i może pozwalać ominąć fabularną odmowę. Weryfikacja progu uprawnień również nie jest widoczna w tym miejscu. Wymaga poprawki i testu po stronie zespołu B. **Nie zmieniono kodu gry ze względu na ograniczenie katalogu T05.**

Pozostałe blokady publikacji: pola w polityce prywatności, ostateczny model D-06, finalna kontrola metadanych i ratingu IARC/Apple oraz potwierdzenie stanu SDK i danych w paczce release.

## Lista plików

- **STORE-POLICY.md** — główny raport zgodności, 14 ryzyk z wytycznymi, warianty zakupów, przykłady PL/EN, notatka dla recenzenta i checklista 36 punktów.
- **README.md** — sprawozdanie, zakres, ograniczenia i działania do wykonania.
- **ASSETS.md** — manifest pusty: w ramach T05 nie powstały grafiki, dźwięki ani pliki binarne.

## Co się nie udało / czego nie zrobiono

- Nie wykonano testów UI na skompilowanych wydaniach iOS/Android, zakupów sandbox, audytu ruchu sieciowego ani realnego formularza IARC/App Store Connect. Nie ma dostępu do wyników recenzji sklepów.
- Nie wprowadzono zmian w game/, store/ ani docs/, zgodnie z wyraźnym zakazem zlecenia.
- Nie zatwierdzono ceny/modelu biznesowego; D-06 nadal wymaga decyzji właściciela.
- Nie da się zagwarantować 4+ / PEGI 3 ani akceptacji przez sklep na etapie dokumentacji.

## Kolejne kroki — właściciele innych katalogów

1. **B — blokada premiery:** poprawić _accept() / odmowy / weryfikację progu w game/scripts/ui/job_verify.gd i nawigację oraz dopisać testy e2e trzech job.refuse_*.
2. **C + właściciel:** uzupełnić prawdziwe dane i URL w store/privacy.md; sprawdzić finalny eksport, deklaracje App Privacy i Data safety.
3. **Właściciel + B/C:** zdecydować D-06, zaimplementować i sprawdzić zakup/restore albo bezpośrednią płatną dystrybucję.
4. **A/C:** po finalnych screenshotach i gameplayu usunąć z opisu obietnice nieobecne w 1.0; wzmacniać ramę legalnego ślusarza.
5. **C:** uczciwie wypełnić rzeczywiste formularze Apple i IARC, w szczególności pytania o odniesienia do nielegalnych działań. Zachować wyniki.
6. **A/B:** wyjaśnić starszy schemat HUD w docs/DESIGN.md §2 w zestawieniu z docs/HUD.md / D-12 (bez naruszania T05).

Oficjalne źródła i dokładne odsyłacze znajdują się w **STORE-POLICY.md §10**.
