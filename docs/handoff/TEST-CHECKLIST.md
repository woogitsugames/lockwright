# Lista kontrolna testu na telefonie

Źródło: `contrib/gpt/T66` (ChatGPT), przejrzane i poprawione pod stan gry z 2026-11-06 (zob. `contrib/gpt/REVIEW-T53-T68.md`). Zgłoszenia błędów: szablon `docs/handoff/BUG-TEMPLATE.md`.

Urządzenie / system: __________ Rozdzielczość i skala: __________ Wersja APK / commit: __________ Data: __________ Tester: __________

W każdym wierszu wpisz OK / błąd / N/D (z przyczyną) i numer zrzutu lub nagrania. Przy błędzie dodaj identyfikator N-xx. **Pusty wiersz to nie zaliczenie.**

## A. Ogólne

| Kontrola | Wynik | Zrzut / N-xx |
|---|---|---|
| Instalacja, pierwsze uruchomienie (ekran wyboru trybu napięcia D-52), ponowne uruchomienie | | |
| Menu: wszystkie pozycje, powrót, czytelność, cele dotyku ≥ 48 dp | | |
| Pion i poziom, bezpieczne marginesy, wycięcia, klawiatura | | |
| Fold: złożony, rozłożony, przełączenie w grze i obrót | | |
| Samouczek S1 / S2 / S3, napięcie ręczne (3 wiersze) | | |
| Samouczek S1 / S2 / S3, napięcie automatyczne (3 wiersze) | | |
| Zmiana trybu napięcia w ustawieniach (Sterowanie) w trakcie gry | | |
| Tryb ćwiczeń (praktyka): lista, ukończenie jednej lekcji, powrót | | |
| Zlecenie: przyjazd, weryfikacja prawa do lokalu, rachunek, napiwek | | |
| Zlecenie z odmową (`refuse_*`): ton, brak otwarcia, reputacja | | |
| Warsztat, naprawa narzędzia, mapa dzielnicy bieżącego rozdziału | | |
| Gablota (showcase) i wpis zeszytu | | |
| Osiągnięcia: lista, odblokowanie po zleceniu | | |
| Głosy PL/EN: głośność, napisy, przewinięcie kwestii | | |
| Pobranie paczki głosu (jedyne użycie sieci, D-63): sukces, przerwanie, brak sieci, ponowienie; pytanie raz z rozmiarem | | |
| Android Back: każdy ekran, dialog i pauza; brak utraty postępu (D-65) | | |
| Wibracje: włącz/wyłącz, suwak; ta sama informacja także przez obraz i dźwięk | | |
| Dostępność: ograniczenie ruchu, skala tekstu, czytnik ekranu, pomoc w czytaniu | | |
| Wznowienie po tle, blokadzie ekranu, połączeniu przychodzącym, restarcie | | |
| Zapis i wczytanie postępu, ustawień i języka (PL/EN; DE/FR/ES tylko w `dev_mode`, D-67) | | |

## B. Rodziny zamków (grywalne w kompilacji z 2026-11-06)

Dla każdej: pierwsza lekcja rodziny (D-68, tylko pierwsze zlecenie), potem zwykłe zlecenie; oba tryby napięcia; informacja zwrotna widoczna w skali szarości, słyszalna i wyczuwalna; ukończenie.

| Rodzina | Lekcja (1. zlecenie) | Tryb ręczny | Tryb automatyczny | Zrzut / N-xx |
|---|---|---|---|---|
| pin_tumbler | (S1–S3) | | | |
| warded | | | | |
| wafer | (S1–S3) | | | |
| lever | | | | |
| dial_safe | | | | |
| combo | | | | |
| dimple | | | | |
| disc_detainer | | | | |
| egyptian | | | | |
| axial_slider | | | | |
| time_lock (naprawa zegara, bez otwarcia rygla) | | | | |
| magnetic | | | | |

## C. Rodziny jeszcze niegrywalne (wpisz N/D, dopóki widok plan B nie istnieje)

`lever_detector`, `wooden_pin`, `ring_combo` (lockcore gotowy, brak widoku w grze lub mapowania zleceń: `JobRun.PHOTOREAL_READY`, `FAMILY_MAP`), oraz zaplanowane w `progression.json`: `tubular`, `bramah`, `sidebar`, `wafer_double`. Jeśli któraś pojawi się w kompilacji, dopisz ją do tabeli B, nie zaliczaj jej tutaj.

## D. Rozdziały 9–12 (po integracji T43)

| Kontrola | Wynik | Zrzut / N-xx |
|---|---|---|
| Rozdział 9: pierwsze zlecenie widoczne, kolejność, monety | | |
| Rozdział 10: zlecenie z naprawą zegara (bez otwarcia rygla, nie jest odmową) | | |
| Rozdział 11: zlecenie bez otwarcia (rozpoznanie), odmowa | | |
| Rozdział 12: finał, napisy końcowe | | |
