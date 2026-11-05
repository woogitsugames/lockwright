# T29 — Pomoc w grze i FAQ

## Wykonane

- Przygotowano dwujęzyczną pomoc do gry **Lockwright**: **43 pytań i odpowiedzi** po polsku i angielsku, w 7 grupach tematycznych.
- Uwzględniono sterowanie dwoma kciukami, wszystkie 14 opisanych stanów i zdarzeń mechanizmu, haptykę i jej brak, wyzwanie „w ciemności”, dostępność, prywatność, zasadę „to gra, nie kurs” oraz zgłaszanie problemów.
- CSV ma kolumny dokładnie `key,en,pl`. Każde pytanie i odpowiedź otrzymały osobny stabilny klucz i18n; nagłówki i wstęp też mają klucze.
- Skontrolowano programowo liczbę wpisów, unikalność kluczy i limit odpowiedzi **≤ 300 znaków** w obu językach. Maksimum: PL 169 znaków, EN 172 znaków.
- Nie deklarowano ceny, premiery ani dostępności w sklepach (D-06, D-51). Nie podano żadnych marek mechanizmów.

## Pliki

- `HELP.md` — gotowe teksty dla gracza po polsku i angielsku.
- `help.csv` — klucze i18n, nagłówki, pytania i odpowiedzi (`95` wierszy danych).
- `README.md` — raport z wykonania, źródła i ograniczenia.

## Źródła w repozytorium

- `CLAUDE.md`, `docs/DESIGN.md` §1, §3–4 — głos i sygnały stanów.
- `docs/HUD.md` §4–6, §9–10 — sterowanie, pauza, ustawienia, dostępność, tryb w ciemności.
- `docs/ONBOARDING.md` §1–3, §7, §11 — wskazówki, samouczek, kalibracja i zachowanie bez haptyki.
- `docs/CLIENTS.md`, `docs/JOBS.md` §1–2 — legalny ton i odmowy.
- `docs/DECISIONS.md` D-06, D-51 — nierozstrzygnięty model biznesowy.
- `store/legal/privacy_pl.md`, `privacy_en.md`, `notice_pl.md`, `notice_en.md` — prywatność i nota o fikcyjnych mechanizmach.
- `site/public/contact.html` i `site/public/en/contact.html` — sekcja Kontakt w projekcie strony.

## Co się nie udało / wymaga dopięcia przed publikacją

- **Brak zatwierdzonego adresu kontaktowego**: aktualne strony Kontakt zawierają pola `[adres e-mail — do uzupełnienia]`. FAQ wskazuje na sekcję Kontakt, ale właściciel musi wstawić działający adres przed opublikowaniem FAQ.
- Nie uruchamiano gry na urządzeniach ani testów dostępności: dokumenty opisują projektowane zachowania, których implementację trzeba sprawdzić w buildzie (zwłaszcza odczyt ekranu, haptykę i pauzę).
- Nie modyfikowano niczego poza `contrib/gpt/T29/`.
