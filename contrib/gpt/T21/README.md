# T21 — raport oddania

**Zlecenie:** dostępność dla niewidomych: granie bez wzroku, TalkBack, VoiceOver, komunikaty zamka, fokus, gesty i tryb „w ciemności”.  
**Data:** 5 listopada 2026  
**Zakres zapisów:** wyłącznie `contrib/gpt/T21/`.  
**Status:** **specyfikacja i gotowe treści**, nie funkcja wdrożona w grze.

## Co zrobiono

1. Przeanalizowano `CLAUDE.md`, `docs/DESIGN.md`, `docs/CLIENTS.md`, `docs/JOBS.md`, `docs/DECISIONS.md` (D-06 i D-51), `docs/FEEL.md`, `docs/HUD.md`, `docs/handoff/A11Y-AUDIT.md`, aktualne sceny `game/scenes/` i źródło `game/i18n/strings.csv`.
2. Opracowano `BLIND_PLAY.md`: kontrakt semantyczny, mapa i kolejność fokusu **24 typów widoków**, szczegółowy wykaz opcji, gesty TalkBack/VoiceOver, alternatywne sterowanie fikcyjnym zamkiem bez dwóch kciuków, profil „w ciemności”, reguły TTS, architektura natywnego mostka Android/iOS, testy oraz granice wdrożenia.
3. Przygotowano `a11y_strings.csv` w wymaganym formacie **`key,en,pl`**: **303 unikalne klucze** z angielskimi i polskimi komunikatami, w tym nazwy ekranów i przycisków, stany, błędy, zdarzenia `lockcore` i podstawowe opisy scen.
4. Sprawdzono w trakcie tworzenia CSV: brak duplikatów, brak pustych tłumaczeń, jednakowe nazwy i liczby placeholderów w EN/PL, obecność wszystkich konkretnych kluczy cytowanych w `BLIND_PLAY.md`.
5. Dodano odniesienia do **oficjalnych** wytycznych Xbox Accessibility Guidelines v3.2, Apple i Google (numery XAG i WCAG, API mobilne, dokumentacja Godot 4.7). Zweryfikowano m.in. **XAG 106 = Screen narration**, **107 = Input**, **112 = UI navigation**, **113 = UI focus handling**, **114 = UI context**, **115 = Error messages**, **116 = Time limits**.

## Lista plików

- `BLIND_PLAY.md` — kompletna specyfikacja, mapa ekranów, zachowanie systemowych czytników, testy i wytyczne.
- `a11y_strings.csv` — 303 dwujęzyczne klucze dla dostępności (`key,en,pl`).
- `README.md` — niniejszy raport oddania, otwarte problemy i wskazówki integracyjne.

## Co się nie udało / czego nie wykonano

- **Nie wdrożono TalkBack/VoiceOver do gry.** Godot 4.7 deklaruje obsługę screen readerów na desktopach, nie gotowy mobilny bridge; `accessibility_name` bez natywnego połączenia nie spełni tego wymagania.
- **Nie wykonano testu na fizycznym Androidzie/iOS** z TalkBack i VoiceOver oraz na urządzeniu bez haptyki.
- **Nie zweryfikowano 10 000 seedów i wszystkich tierów siedmiu rodzin** względem kroku regulacji alternatywnego sterowania. Liczby kroków w dokumencie są propozycją projektową, nie potwierdzonym balansem.
- **Nie zintegrowano tłumaczeń z istniejącą tabelą gry.** `game/i18n/strings.csv` ma nagłówek `keys,en,pl,de`, a zlecenie wymaga osobnego pliku `key,en,pl`. Potrzebny kontrolowany import bez nadpisania niemieckich i istniejących wartości.
- Nie zmieniono scen `game/`, natywnych pluginów, logiki `lockcore` ani dokumentów `docs/`, zgodnie z ograniczeniem zakresu.

## Zadania dla integratora (w innych katalogach; **nie wykonano**)

| Priorytet | Gdzie | Co zrobić |
|---|---|---|
| P0 | `game/` + plugin Android | `AccessibilityNodeProvider`, drzewo semantyczne i akcje oraz natywna obsługa TalkBack |
| P0 | `game/` + plugin iOS | `UIAccessibilityElement`, kolejność fokusu, regulowane elementy i akcje VoiceOver |
| P0 | `game/scripts/lock/` / `game/scripts/photoreal/` | Oddzielne, krokowe sterowanie fikcyjnymi parametrami zamka, alternatywa dla dwóch kciuków, pauza bez skoku wartości |
| P0 | `game/` | Kluczowe zdarzenia TTS z ograniczeniem częstotliwości, odczyt ostatniego zdarzenia na żądanie, bez utraty SFX |
| P0 | `game/i18n/` | Kontrolowany import kluczy T21, testy placeholderów/lokalizacji; nie zastępować `strings.csv` |
| P0 | `game/` i QA | Test każdego ekranu z TalkBack, potem VoiceOver, bez wzroku; rodziny/tiery/seed-y i urządzenia H0 |
| P1 | `docs/HUD.md` | Dopisać w przyszłym przeglądzie założenia semantyczne B01–B24 i zachowanie czytnika w ciemności, bez dodawania wizualnych paneli HUD |
| P1 | `docs/handoff/A11Y-AUDIT.md` | Utrzymać A-09 otwarte do testu natywnego mostka; uwzględnić XAG 106 jako narrację; powtórzyć A-10/A-11 na telefonach |
| P1 | `game/` | Dostępne potwierdzenia decyzji o odmowie/wyjściu, brak gestu przytrzymania jako jedynej drogi do „zachowaj rachunek” |
| P1 | `game/` | Ograniczenie ruchu, 200% tekstu, screen reader oraz dostępne opisy scen, optyki i przedmiotów |

## Istotne zastrzeżenia projektowe

- Żaden tryb dostępności nie może ujawniać ukrytej wartości rozwiązania ani wyjaśniać obchodzenia realnych zamków lub weryfikacji prawdziwych dokumentów. Mechanizmy w grze pozostają fikcyjne.
- D-06 i D-51 pozostawiają model biznesowy i cenę otwarte; T21 niczego nie obiecuje w sklepach.
- „Tryb w ciemności” nie jest funkcją automatycznie gwarantującą dostępność. Dźwięk, haptyka i czytnik mają osobne ograniczenia; ścieżka normalnej gry pozostaje osiągalna.
- XAG to wytyczne jakościowe, nie certyfikat zgodności prawnej.

## Wynik

**Zlecenie dokumentacyjne ukończone.** Gotowe do recenzji i implementacji, z jawną listą niezaimplementowanych zależności.
