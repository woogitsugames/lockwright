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

## D-12 — Ekran zamka bez paneli UI
2026-11-04 · przyjęta (koordynator, po uwagach właściciela „UI/HUD jak AI”) · ekran zamka to wyłącznie fotorealistyczna scena: przekrój i zwijka z narzędziami. Brak nagłówków, pasków, kart i liczników w trakcie otwierania. Napięcie pokazuje napinacz i czoło rdzenia, życia to wytrychy w kieszeniach zwijki, a zużycie widać na grocie. Jedyna afordancja systemowa to pauza (48 dp, róg). Strefy kciuków są niewidoczne i pokazują tylko miękki odcisk pod palcem. Informacje o kliencie i monetach pojawiają się przed zamkiem i po nim.

## D-13 — Narzędzia obserwacji: lupa, potem mikroskop i wziernik
2026-11-04 · przyjęta (właściciel: „mikroskop albo coś, żeby lepiej widzieć”) · lupa zegarmistrzowska (start) leży na zwijce, a dotknięcie daje okrągłe pole okularu z makro-widokiem linii podziału przy pinie pod wytrychem. Zasady gry: podczas patrzenia przez lupę prawy kciuk trzyma pozycję, a napięcie dalej działa. Później w warsztacie: mikroskop warsztatowy (większe powiększenie, widać zadziory i fałszywe bramki), wziernik (podgląd elementów głęboko w kanale, np. dźwignie, tarcze). Narzędzia obserwacji nie zastępują wyczucia, tylko je potwierdzają (w trybie „w ciemności” są niedostępne).

## D-14 — lockcore: PCG32, FNV-1a 64, wyprowadzanie seedów
2026-11-04 · przyjęta (programista lockcore) · PRNG to własna implementacja PCG32 (XSH-RR 64/32, test na wektorze referencyjnym pcg32-demo). Każda rodzina i cel mają osobny strumień: `gen` (generator), `sim` (losowość w `step`, np. szum kontaktów), `bot` (drżenie ręki bota). Seed: `derive_seed(seed, family_id, rules_version, purpose)` na SplitMix64. Hash strumienia zdarzeń: FNV-1a 64 po polach zdarzenia w little-endian (zamiast xxHash64 ze spike'u 5 w TECH.md): prostszy, bez zależności i wystarczający do wykrywania rozbieżności (to nie jest podpis).

## D-15 — lockcore bez cudzego kodu: własny JSON (tylko liczby całkowite) i własny runner testów
2026-11-04 · przyjęta (programista lockcore) · zamiast nlohmann/doctest: ok. 400 wierszy własnego parsera i ok. 80 wierszy runnera. Parser przyjmuje wyłącznie liczby całkowite i odrzuca ułamki. Każda wielkość ułamkowa w `lockwright.lock/1` i `lockwright.replay/1` jest liczbą Q16 w polu `*_q16`, a czasy są w krokach (`*_steps`) albo w ms. Dzięki temu odczyt jest bit w bit, bez `float` w ścieżce gry, a zapis jest deterministyczny (kolejność kluczy). Seedy zapisujemy jako napisy dziesiętne, bo Godot i JS czytają liczby JSON jako double. Ręczne autorstwo zamków wymaga przeliczenia (0,12 → 7864), co później zrobi edytor. Bez zależności nie trzeba też wpisu w `ASSETS.md`.

## D-16 — pin_tumbler v0.1: doprecyzowanie modelu z LOCKS.md
2026-11-04 · przyjęta (programista lockcore) · (1) Stres rośnie od **docisku** (pozycja wytrycha minus pozycja kołka, maks. 0,5), a nie od |Δlift|. Trzymanie wytrycha pod wiążącym kołkiem przy zbyt dużym napięciu też łamie narzędzie (ok. 0,35–0,45 s przy T = 1). (2) `set` następuje przy dolnej krawędzi okna. Zapas do overset to `win_shear + overset_margin` (t7: 12% skoku). (3) Stałe generatora: `t_hold 0,10`, `t_release 0,05`, `band_lo 0,20–0,25`, `tau_safe = max t_stick + 0,06`, pasmo szpulki `cr 0,12–0,21`. (4) Na t2 `drop` zrzuca tylko ostatni element, od t3 wszystkie (LOCKS §1.5). (5) Bot kwantyzuje wejście do 1/256 (jak gra), a nie do 1/64 z LOCKS §1.9. Parametry tierów t2–t7 z karty zostały bez zmian i wszystkie dają się otworzyć: 10 000 seedów na tier, 0 porażek.

## D-17 — Druga rodzina v0.1: wafer (nie warded); tiery wafer t1–t3
2026-11-04 · przyjęta (programista lockcore) · `wafer` korzysta z tego samego modelu napięcia, więc dobrze sprawdza, czy interfejs i komponenty wspólne nie zależą od rodziny. `warded` wymaga osi `rotate` i geometrii przeszkód, dlatego przechodzi do v0.2. Karta podaje dla wafer jeden tier (t2) z zakresami 3→5 płytek, okno 14→10%, pasmo 0,30→0,22 i margines 12→8%. Rozkładamy je na tiery t1, t2 i t3. Overset płytki znika przy `T < t_release = 0,16`, czyli powyżej `t_hold = 0,08`, więc naprawa nie kosztuje zrzutu („łatwiejszy do naprawy”). Wyrocznia wymaga, żeby pasmo między `t_hold` a `t_release` było ≥ δ_human.

## D-18 — Weryfikator v0.1: twarda bramka = wyrocznia + bot skryptowy; bot „niezdarny” jako miara miękka
2026-11-04 · przyjęta (programista lockcore) · Bramka A3 (0 porażek) to wyrocznia analityczna i bot skryptowy z ograniczeniami człowieka (drżenie ±0,03, 1,5/s i 3/s, reakcja 180 ms, dwell 100 ms, budżet = połowa limitu czasu tieru, S < 0,8 S_max). Bot ten prawie nie popełnia błędów, więc rozkład dropów w raporcie jest pusty. Dlatego `verify_seeds` uruchamia też bota „niezdarnego”: drżenie ±0,06, unoszenie 0,7/s (0,3/s po `near_shear`), reakcja 250 ms, bez wiedzy o granicy overset, zwalnia po każdym overset. Jego wskaźnik sukcesu, dropy i oversety to miara balansu, nie bramka. Wynik dla 10 000 seedów: t2–t5 ≥ 99,9%, t6 93,6%, t7 24,2%, wafer 100%. Bot czujący (etap 3 z LOCKS §1.9) jest otwartą kwestią na v0.2.

## D-19 — i18n: CSV jako źródło prawdy, ładowane w runtime przez autoload I18n
2026-11-04 · przyjęta (koordynator) · Godot 4.7 headless nie importuje CSV `internationalization/locale/translations` do zasobów `.translation`, więc runtime ładowałby puste tłumaczenia. `game/i18n/*.csv` (kolumny `keys,en,pl`) są ładowane i parsowane przez `scripts/autoload/i18n.gd` przy starcie — działa identycznie w edytorze, headless i eksporcie. PL i EN od pierwszego dnia, fallback EN.
