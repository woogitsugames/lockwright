# Lockwright — plan testu z graczami (test zamknięty, 5–8 osób)

Stan: 2026-11-12. Cel: sprawdzić, czy nowy gracz sam rozumie sterowanie, weryfikację klienta i kod stanów zamka,
oraz zebrać dane do decyzji D-06 (model biznesowy) i kalibracji trudności (D-60: bot czujący ma 100 % — trzeba ludzi).
Testerom dajemy `CLOSED-TEST-FAQ.md` **dopiero po sesji** (sesja ma pokazać, czego gra nie tłumaczy sama).
Ankieta po sesji: `CLOSED-TEST-SURVEY.md`.

## 1. Uczestnicy
- 5–8 osób, co najmniej: 2 osoby, które nie grają w gry mobilne regularnie; 1 osoba leworęczna; 1 osoba z tanim
  telefonem (≤ 4 GB RAM); jeśli się da, 1 osoba korzystająca z TalkBack albo powiększenia tekstu.
- Języki: co najmniej 3 osoby PL, 1–2 EN, opcjonalnie DE/FR/ES (sprawdzenie tłumaczeń i paczek głosów).
- Nikt, kto widział grę wcześniej.

## 2. Przygotowanie (prowadzący)
- Build z zielonego `game-android` (test zamknięty Play albo APK), świeża instalacja — bez starego zapisu.
- Telefon testera, głośność ok. 60 %, wibracje włączone w systemie, Wi-Fi (pierwsze uruchomienie pobiera głosy).
- Arkusz obserwacji (§5) i stoper. Nagranie ekranu systemowym rejestratorem — tylko za zgodą testera.
- Prowadzący **nie podpowiada**. Pytanie testera → „Co byś teraz zrobił(a)?”. Pomoc tylko po 3 min zablokowania
  (zapisać jako „pomoc prowadzącego”).

## 3. Scenariusz (45 min)
| Czas | Zadanie | Co mówi prowadzący |
|---|---|---|
| 0–3 | Wprowadzenie | „Testujemy grę, nie Ciebie. Myśl na głos. Nie pomogę, chyba że utkniesz na dłużej.” |
| 3–8 | Pierwsze uruchomienie: wybór trybu sterowania, pobieranie głosu | nic |
| 8–20 | Samouczek i pierwszy zamek | nic |
| 20–30 | Pierwsze zlecenia: weryfikacja klienta (karty, pytania), zamek | „Graj dalej, jak w domu.” |
| 30–35 | Zadanie: znajdź w Ustawieniach, jak zmienić sterowanie na drugi tryb, i zagraj jeden zamek | to zdanie |
| 35–38 | Zadanie: odwiedź Warsztat i Gablotę, kup/obejrzyj coś | to zdanie |
| 38–45 | Ankieta (`CLOSED-TEST-SURVEY.md`) + krótka rozmowa | pytania §6 |

## 4. Metryki (zapisuje prowadzący)
- **T1** czas od uruchomienia do pierwszego otwartego zamka (samouczek), w sekundach.
- **T2** czas pierwszego zamka poza samouczkiem.
- **Porzucenia:** wyjście z zamka (`Wyjdź`), restart zamka, odłożenie telefonu / prośba o pomoc — liczba i moment.
- **Podpowiedzi:** ile razy pojawiła się eskalacja podpowiedzi (dźwięk → kreda → tekst) i na którym zamku.
- **Złamane wytrychy / overset:** liczba na zamek (czy gracz rozumie „za wysoko — popuść napięcie”).
- **Weryfikacja:** czy gracz otworzył karty dokumentów, czy zadał pytanie, czy przy odmowie zrozumiał dlaczego.
- **Tryb sterowania:** wybrany na starcie; czy zmienił; czy dwa kciuki działały.
- **Techniczne:** profil jakości wybrany przez Auto (Ustawienia), czy telefon się grzał, czy głos się pobrał, błędy.
- Z logu gry (Ustawienia → Zgłoś problem → wkleić do arkusza): błędy, czasy, ostrzeżenia.

## 5. Arkusz obserwacji (jeden na testera)
```
Tester: __  Telefon: __________  RAM: __  Android: __  Język: __  Ręka: L/P
Tryb na starcie: auto / dwa kciuki      Głos pobrany: tak / nie / nie dotyczy
T1: ____ s   T2: ____ s   Profil Auto: ______
Porzucenia (czas, ekran, powód): ____________________________________
Podpowiedzi (zamek, poziom): ________________________________________
Overset / złamania: ____ / ____   Pomoc prowadzącego (czas, temat): ____
Weryfikacja: karty otwarte tak/nie, pytanie zadane tak/nie, odmowa zrozumiana tak/nie/nie wystąpiła
Cytaty (dosłownie): __________________________________________________
Błędy techniczne: ____________________________________________________
```

## 6. Rozmowa po ankiecie (5 min)
1. Co w tej grze robisz? (Sprawdzamy, czy ton „pomagam, weryfikuję” dotarł.)
2. Jak rozpoznawałeś(-aś), że część zamka „siedzi”? Obraz, dźwięk czy wibracja?
3. Co było najbardziej frustrujące?
4. Ile zapłaciłbyś(-abyś) za pełną grę? Wolisz zapłacić raz z góry czy zagrać za darmo pierwsze rozdziały i potem
   kupić resztę? (Dane do D-06 — nie podawać naszych cen.)

## 7. Po teście (koordynator)
- Zebrać arkusze i ankiety do `docs/handoff/device-tests/closed-test-<data>/` (bez danych osobowych: tester A, B, …).
- Błędy → `SESSION-B-LOG.md` jako N-xx z priorytetem; wnioski o trudności → kalibracja t2/t3 (D-60).
- Podsumowanie dla właściciela: mediany T1/T2, top 3 problemy, odpowiedzi o cenie.
