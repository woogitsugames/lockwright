# Android — uzupełnienie listy przed wydaniem

Wersja aplikacji / commit: ______  Numer kompilacji: ______  Data: ______  Osoba: ______

Każdy punkt oznacz: **OK / błąd / N/D**, z linkiem do dowodu i numerem zgłoszenia. Puste pole nie oznacza zaliczenia. Lista uzupełnia `docs/handoff/RELEASE-CHECKLIST.md`; tamtejsze statusy z 5 listopada są historyczne i wymagają ponownej weryfikacji.

| Punkt | Kontrola | Wynik / dowód |
|---|---|---|
| A1 · CI i artefakt | Sprawdź wymagane workflow na dokładnym commicie wydania; zachowaj linki do wyników. Zbuduj podpisany AAB, sprawdź podpis i rosnący versionCode (T1–T2). | |
| A2 · Rozmiar | Zmierz artefakt i rozmiar pobrania odpowiedniemu wariantowi; porównaj z progami T4, zapisując urządzenie i metodę. | |
| A3 · Zimny start | Zmierz czas do menu na tanim i średnim telefonie według T5; zanotuj wersję i warunki. | |
| A4 · Wydajność i pamięć | Przeprowadź dziesięciominutowy test T6 i pomiar PSS z T7 na wskazanych urządzeniach; zachowaj surowe wyniki. | |
| A5 · Haptyka i dźwięk | Zmierz opóźnienia według T8; sprawdź działanie bez haptyki i przy jej wyłączeniu. | |
| A6 · Przejście gry | Wykonaj qa-career oraz rzeczywisty przebieg kariery i odmów; zbadaj ekrany bez wyjścia (T11, C7). | |
| A7 · Przerwania i zapis | Android Back, tło, blokada, restart, powrót do zlecenia i ustawień; porównaj z T13 i listą testów telefonu. | |
| A8 · Teksty | Sprawdź PL/EN, ucięcia przy powiększeniu, pion i poziom oraz safe-area na urządzeniu (C1–C2). | |
| A9 · Dostępność | Cele dotyku, skala tekstu, warstwa kredy, ograniczenie ruchu i czytnik ekranu. Zapisz osobno ograniczenia każdego ekranu (A1–A4, A7). | |
| A10 · Głosy i sieć | Sprawdź paczki dostępne w manifeście wydania: pobranie, przerwanie, brak sieci, ponowienie, weryfikację, tekst bez nagrania; sprawdź uprawnienia w finalnym manifeście. | |
| A11 · Prawa i zasoby | Porównaj zasoby z ASSETS, dołącz wymagane informacje o licencjach i potwierdź brzmienie informacji „to gra, nie kurs” (C3–C6). | |
| A12 · Sklep i prywatność | Uzupełnij kontakt, politykę, Data safety, klasyfikację, grafiki i informacje o sprzedawcy; zweryfikuj dane na podstawie faktycznego buildu (S2, S4–S9, L2–L3). | |
| A13 · Test zamknięty | Sprawdź aktualne wymagania właściwe dla konta w Play Console; zaplanuj uczestników i czas, zbierz wyniki oraz crash-free (T10). Nie zakładaj, że warunek z historycznej listy dotyczy każdego konta. | |
| A14 · Decyzja | Zbierz otwarte błędy i wyjątki, wskaż właściciela decyzji o wydaniu oraz zatwierdzony commit i artefakt. | |

W testach na urządzeniu użyj też `docs/handoff/TEST-CHECKLIST.md` i szablonu zgłoszeń `docs/handoff/BUG-TEMPLATE.md`.
