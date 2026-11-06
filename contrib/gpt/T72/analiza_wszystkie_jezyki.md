# T72 — inwentarz wszystkich języków

`phrases_all_languages.csv` obejmuje 174 kwestie `job.*.line.N` oraz `job.*.after.N` w każdym z pięciu języków. Każdy wiersz to ciąg trzech kolejnych słów powtarzający się w co najmniej dwóch kwestiach; kolumny podają klucze i pełne konteksty. Porównanie ignoruje wielkość liter i interpunkcję. W apostrofach traktuje człony osobno, więc daje także przypadkowe frazy typu „ce n est”. `scan_phrases.py` odtwarza wynik. Liczba fraz nie jest liczbą problemów redakcyjnych. Metoda nie wykrywa wszystkich parafraz: nie twierdzimy, że je wyczerpuje.

W analizie kontekstowej proponujemy przede wszystkim zmiany treści źródłowej PL z `analiza_kontekstowa.md`; tłumaczenia po zaakceptowaniu PL trzeba przełożyć i ponownie zweryfikować spójność scen. Dodatkowe obserwacje po przejrzeniu powtarzających się czterowyrazowych ciągów:

Jedna propozycja dla wszystkich pięciu języków, `job.shared_room_door.line.2`, zachowuje potwierdzenie dokumentów, ceny i możliwość otwarcia:

| Język | Było | Jest |
|---|---|---|
| PL | Dokumenty się zgadzają. Cena też. Możemy otwierać. | Dokumenty i cena są w porządku. Możemy otwierać. |
| EN | The documents match. So does the fee. We can open now. | The documents and the fee are in order. We can open now. |
| DE | Die Unterlagen stimmen. Der Preis auch. Wir können öffnen. | Unterlagen und Preis stimmen. Wir können öffnen. |
| FR | Les documents concordent. Le tarif aussi. On peut ouvrir. | Les documents et le tarif sont en ordre. On peut ouvrir. |
| ES | Los documentos coinciden. El precio también. Podemos abrir. | Los documentos y el precio están en orden. Podemos abrir. |

| Język i fragmenty | Ocena i propozycja |
|---|---|
| EN `i'll tell you` (biurko, domek, marynarz) | W różnych sytuacjach zwykła obietnica opowieści. Dla `job.finnish_sailor.line.4`: „If you open it, I'll tell you where this invention came from.” → „If you open it, I'll explain where this invention came from.” Zachowany jest warunek i wynalazek. |
| EN `name on the mailbox` w ex-partner i wrong-floor | Ta sama obserwacja ma inną funkcję; sama nazwa nie przesądza prawa do lokalu. Zmianę proponować dopiero łącznie z PL. |
| DE `steht auf meiner Liste` w student-dorm i edek-rehearsal | Znak rozpoznawczy portiera; celowe echo postaci, zostawić. |
| DE `Zustimmung öffne ich nicht` w sisters-flat i stockroom | Spójna granica odmowy. Można zmienić szyk w jednym zdaniu po akceptacji PL; nie osłabiać odmowy ani nie gubić zgody. |
| FR `concordent le tarif aussi` i ES `coinciden el precio también` w edek-rehearsal i shared-room | Odpowiadają powtórzeniu PL „się zgadzają, cena też”. Po akceptacji propozycji PL przetłumaczyć ją na obie wersje z zachowaniem dokumentów i ceny. |
| FR `elle ne répond pas` w rush-bribe i sisters-flat | W obu przypadkach konkretna osoba nie odbiera; prosty fakt sytuacyjny, zostawić. |
| ES `el precio está acordado` w marta-poster, roman-service, stefan-book | Wspólne potwierdzenie ceny może brzmieć formalnie i powtarzalnie; po sprawdzeniu scen można zmienić jeden wariant na „El precio ya está acordado” albo „Ya acordamos el precio”. Nie usuwać informacji o cenie. |
| EN/DE/FR/ES porównanie „jest tu dłużej niż…” w allotment-shed i kiosk-shutter | Podobna figura w dwóch żartach o stażu. Różne przedmioty i postacie; opcjonalna redakcja, nie usuwać szczegółów bez sprawdzenia scen. |

Wyniki są przeglądem tekstu, bez odsłuchania głosów i uruchomienia gry. Nowe klucze i18n nie są dodawane, lint nie dotyczy raportu. Akceptacja proponowanego skrótu lub parafrazy wymaga ponownej kontroli w pięciu językach.
