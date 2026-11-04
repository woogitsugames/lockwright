# Decyzje

Format: **D-NN — tytuł** · data · status (przyjęta / proponowana / czeka na właściciela) · uzasadnienie.

## D-01 — Tytuł: Lockwright
2026-11-04 · przyjęta (właściciel)
„-wright” = rzemieślnik (wheelwright, playwright): pasuje do tonu uczciwego fachowca. Sklep PL: „Lockwright: Pogotowie Zamkowe”, EN: „Lockwright: Emergency Locksmith”. Wynik sprawdzenia kolizji: `docs/RESEARCH.md`.

## D-02 — Praca na `main`
2026-11-04 · przyjęta (właściciel)
Właściciel polecił pracować bezpośrednio na `main`, pushować i scalać na bieżąco oraz wysyłać zrzuty ekranów w trakcie pracy, żeby kierunek dało się korygować wcześnie. Zastępuje wcześniejszą zasadę gałęzi roboczej.

## D-03 — Kolizja tytułu: lockwright.app (escape room)
2026-11-04 · odłożona przez właściciela („nazwa potem”); wracamy przed publikacją
Pod lockwright.app od X 2026 działa darmowa przeglądarkowa gra „Lockwright · Free Online 3D Escape Room Game” (osoba prywatna). lockwright.com zajęta (pusty szablon). Brak znaku LOCKWRIGHT w USPTO; EUIPO/TMview do sprawdzenia ręcznie. Opcje: (A) zostać przy nazwie i zgłosić znak EUIPO kl. 9/28/41 (ok. 1 050 € opłaty) i zabezpieczyć lockwrightgame.com/.pl/.game; (B) zmienić nazwę teraz, przed publikacją. Rekomendacja koordynatora: patrz podsumowanie etapu.

## D-04 — Silnik
2026-11-04 · **przyjęta (właściciel): Godot 4.7 + lockcore** · **Godot 4.7.x (MIT)** + logika zamka jako osobna biblioteka C++20 `lockcore` (stały przecinek, testy na Linuksie) + własne mostki natywne: haptyka iOS (Core Haptics), haptyka Android (plugin v2, Composition/Builder) i niskolatencyjny dźwięk Android (Oboe/AAudio, bo Godot 4.7.2 używa OpenSL ES z buforem ok. 46 ms). Alternatywa: Unity 6.3 LTS URP. Kryteria zmiany decyzji: `TECH.md` §1.

## D-05 — Kierunek wizualny: realizm fotograficzny
2026-11-04 · **przyjęta (właściciel)** · żaden z 4 kierunków nie został wybrany. Właściciel: „To ma być realistyczny wygląd, zamek ma wyglądać na prawdziwy”. Kierunek: fotorealistyczny przekrój prawdziwej (wymyślonej, bez marki) wkładki, obrobionego mosiądzu i stali, z oświetleniem fizycznym. Kod stanów z `DESIGN.md` zostaje obowiązkowy i musi być realizowany środkami realistycznymi (ruch, pozycja, cień, odbicie), z ewentualną lekką warstwą znaków. Kierunki ilustracyjne zostają w repo jako archiwum.

## D-06 — Model biznesowy i cena
2026-11-04 · **odłożona przez właściciela** („potem zobaczymy”) · rekomendacja z `RESEARCH.md`: darmowe demo w tej samej aplikacji + jednorazowy zakup pełnej wersji ($5.99 / 5,99 € / 24,99 zł), potem dodatki z rodzinami po $2.99. Family Sharing włączone. Bez reklam, energii i pay-to-win.

## D-07 — Symulacja: 120 Hz, stały przecinek, własny PRNG
2026-11-04 · przyjęta (koordynator) · krok 1/120 s pasuje do ekranów 120 Hz, a 240 Hz nic nie daje przy opóźnieniu haptyki. Pozycje Q16, czasy w tickach, PRNG PCG32/xoshiro zaimplementowany w `lockcore`. Warunek determinizmu z `ARCHITECTURE.md`.

## D-08 — Nazwy rodzin w grze są ogólne
2026-11-04 · przyjęta (koordynator) · w grze „zamek suwakowy” (`axial_slider`), a nie nazwisko wynalazcy. „Dźwigniowy z detektorem”, „tarczowy” itd. Nazwiska historyczne (Bramah, Chubb, Hobbs, Yale, Sargent) pojawiają się tylko w notkach gabloty jako historia, ze źródłem. Uwaga z researchu: część nazwisk to nadal działające marki. Notki trzymamy przy faktach historycznych sprzed ponad 100 lat, bez współczesnych produktów.

## D-09 — Wiertarka tylko w Trybie Zleceń
2026-11-04 · przyjęta (koordynator) · w Trybie Ciągłym metod niszczących nie ma. W Zleceniach wiertarka kosztuje części i reputację, a mini-gra jest abstrakcyjna (docisk i chłodzenie, bez miejsc wiercenia).

## D-10 — Minimalne systemy
2026-11-04 · proponowana · iOS 18 (ok. 93% iPhone'ów) i Android API 30 (ok. 88% urządzeń, `VibrationEffect.Composition`). iPad wspierany, ale bez Core Haptics (tylko dźwięk i obraz).

## D-11 — Makiety: HTML/SVG/three.js renderowane Playwrightem
2026-11-04 · przyjęta (koordynator) · `mockups/tools/render.mjs` (lokalny serwer, pion i poziom @2x, skala szarości, 50% jasności), `contrast.mjs` (WCAG + symulacja CVD), `contact.mjs` (zestawienie). Narzędzie projektowe, nie kod gry.
