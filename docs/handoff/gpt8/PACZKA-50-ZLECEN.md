# Paczka 50 zleceń dla ChatGPT (T75–T124), 2026-11-06
n> **Nieaktualne (2026-11-08):** zastąpione przez `docs/handoff/gpt10/PACZKA-GPT10.md`.

**Repo** `woogitsugames/lockwright`, `main`. **Zapis tylko do `contrib/gpt/<ID>/`**, każde zlecenie osobnym commitem z `README.md` (PL: co zrobione, wątpliwości). Integrację robi sesja A.
**Zasady:** `CLAUDE.md`; ton ciepły i legalny (ślusarz weryfikuje prawo do lokalu), zero marek i instrukcji do prawdziwych produktów; PL „pin” (kołek tylko drewniany/egipski); UI do gracza na ty/du/tu/tú, postacie per pan/Sie/vous/usted (D-67); limity `tutorial.*`/`lock.*` ≤ 56, `menu.*` ≤ 28; kwestie pod lektora: liczby słownie. Poprawki istniejących tekstów jako tabela `klucz | było | jest | powód`. Obrazy: jeden obraz = jedna wiadomość, bez kolaży, fikcyjne osoby, bez logo. Słowniczek: `docs/GLOSSARY.md`.

## A. Treść gry (teksty)
- T75 Sceny „dzień po” dla 10 zleceń rozdz. 8 bez `after` (mówca + PL/EN/DE/FR/ES).
- T76 Dodatkowe „dzień po” po odmowach (wszystkie `refuse_*`): krótka, pojednawcza kwestia.
- T77 Wpisy zeszytu dla rozdziałów 7–12 (po 1 na zlecenie, głos ślusarza, §6 CLIENTS).
- T78 Notatki gabloty dla 8 nowych rodzin zamków (historia encyklopedyczna, źródła w README).
- T79 Opisy wyposażenia warsztatu (lampa, imadło, półki itd., D-71): nazwa ≤ 28, opis ≤ 80, 5 języków.
- T80 Zdania dyspozytora trybu dyżuru, druga partia 20 (różne pory dnia i pogody).
- T81 Wskazówki mistrza (`tip.*`), 20 nowych o nowych rodzinach i weryfikacji.
- T82 Osiągnięcia rozdziałów 7–12 (8 propozycji z realnymi warunkami).
- T83 Teksty pustych stanów (brak zleceń, wszystko ukończone, brak sieci przy pobieraniu głosów).
- T84 Komunikaty błędów pobierania paczek głosów (krótkie, przyjazne), 5 języków.
- T85 Epilog kariery po rozdziale 12 (3–5 krótkich scen tekstowych, obsada stała).
- T86 Teksty ekranu postępu rozdziałów (tytuł + 1 zdanie na rozdział 1–12).
- T87 Dzielnice rozdziałów 7–12 na mapę (nazwa + 1–2 zdania).
- T88 Opisy rodzin zamków do „Gabloty — leksykon” (1 akapit encyklopedyczny na rodzinę).
- T89 Krótkie podpisy narzędzi w zwijce (≤ 24 znaki).

## B. Korekta i tłumaczenia
- T90 Korekta PL kwestii rozdziałów 7–8 (naturalność, spójność postaci).
- T91 Korekta EN (US spelling) rozdziałów 7–12.
- T92 Korekta DE rozdziałów 7–12.
- T93 Korekta FR/ES rozdziałów 7–8 (rozdz. 9–12 sprawdzone w T74).
- T94 Spójność imion, wieku, dzielnic w rozdz. 1–12 (raport).
- T95 Audyt powtórzeń w kwestiach rozdz. 7–12 (raport + propozycje).
- T96 Audyt odmów rozdz. 7–12 vs CLIENTS §4 (raport).
- T97 Audyt długości DE/FR w kluczach UI dodanych od T71 (raport).
- T98 Słowniczek: uzupełnij `docs/GLOSSARY.md` o terminy nowych rodzin i wyposażenia (propozycja w contrib).
- T99 Lista kwestii z liczbami/skrótami do zapisu słownego w TTS (wszystkie języki).

## C. Głosy i obsada
- T100 Tagi audio ElevenLabs dla kwestii rozdz. 7–8 (format `contrib/voice/tags.json`).
- T101 Opisy reakcji bez słów (8 emocji) dla postaci bez nich — scenariusz brzmienia każdej.
- T102 Karty postaci (wiek, charakter, sposób mówienia) dla całej obsady w jednym CSV.
- T103 Prompty Voice Design dla ewentualnych przyszłych postaci (szablon + 5 przykładów).

## D. Obrazy (ChatGPT image)
- T104 Portrety brakujących postaci, jeśli jakieś pozostały bez `portrait_*.webp` (sprawdź `game/assets/ui/gpt/cast/episodic/` vs `content.csv cast.*`).
- T105 Pełne postacie do scenek przyjazdu: 4 klientów z rozdz. 1–2 (referencja: ich portret; tło jasnoszare; światło ciepłe z góry/z tyłu z lewej; cała sylwetka).
- T106 Pełne postacie: 4 klientów z rozdz. 3–4 (jak T105).
- T107 Pełne postacie: 4 klientów z rozdz. 9–10.
- T108 Pełne postacie: 4 klientów z rozdz. 11–12.
- T109 Zdjęcia rekwizytów weryfikacji (dowód osobisty fikcyjny bez danych realnych, rachunek za prąd, umowa najmu) — tło neutralne, bez prawdziwych wzorów dokumentów.
- T110 Tła przyjazdu brakujących miejsc (sprawdź `place` w jobs vs `game/assets/ui/gpt/arrival`) — fotografie 9:16 bez ludzi i napisów.
- T111 Ikona aplikacji — 4 warianty tabliczki „L” (D-50) w 1024² na różnych tłach.

## E. Dokumenty (nie marketing)
- T112 FAQ dla graczy (sterowanie, haptyka, pobieranie głosów, prywatność) PL/EN.
- T113 Instrukcja dostępności (czytnik ekranu, ograniczenie ruchu, kreda) PL/EN.
- T114 Lista kontrolna przed wydaniem Android (na bazie `docs/handoff/RELEASE-CHECKLIST.md`) — uzupełnienia.
- T115 Szablon notatki o wydaniu (changelog) dla testerów.
- T116 Plan testów z graczami (5–8 osób): scenariusz, pytania, metryki.
- T117 Ankieta po teście (10 pytań, skala + otwarte).

## F. Audyty techniczno-treściowe (tylko raporty)
- T118 Spójność danych zleceń (`game/data/jobs/*.json`): pola, nagrody rosnące, rodziny/tiery vs `docs/LOCKS.md`.
- T119 Karty weryfikacji: czy każde zlecenie ma sensowne karty i próg.
- T120 Ekonomia: przegląd `docs/ECONOMY.md` po D-71 (propozycje cen wyposażenia).
- T121 Dostępność kolorów i kontrastu w zrzutach `docs/handoff/device-tests/fixes/**` (raport).
- T122 Teksty a zrzuty: ucięcia/nachodzenia widoczne na zrzutach (raport z listą plików).
- T123 Lista brakujących kluczy i18n w kodzie (`I18n.t(&"…")` vs CSV) — raport.
- T124 Przegląd `docs/ASSETS.md`: brakujące wpisy, niejasne licencje (raport).

**Kolejność:** B (90–99) → A → C → D → E → F.
