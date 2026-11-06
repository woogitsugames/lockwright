# T118 — audyt danych zleceń

Przebadano wszystkie 83 JSON-ów `game/data/jobs/*.json` na stanie `b50ea45`: obecność pól id, chapter, district, family, tier, verification, reward_coins, tone, i18n, lines, cards, threshold, place, time, kluczy linii w `content.csv`, rozkład nagród i porównanie rodziny/tieru. Braki badanych pól: 0, brakujące klucze linii: 0. Szczegóły każdego rekordu w `inventory.csv`; walidacja obecności nie dowodzi poprawności semantycznej.

## Zakres tierów

Przyjęto tabelę `docs/LOCKS.md` §3, z późniejszymi wariantami D-59 dla ośmiu nowych rodzin (§2.18–2.25). 13 rekordów nie mieści się w tych zakresach, w tym odmowy i sprawy bez gry w zamek; ich listę podaje CSV. Przykłady: `job.liege_bakery` ma `lever_detector` 2 wobec 5–6; `job.pizzeria_pays_pizza` ma `lever` 1 wobec 3–5. Część starszych zleceń może używać historycznej skali poziomów zadań, nie identycznej ze skalą lockcore (`docs/ECONOMY.md` §7); nie zakładać automatycznie błędu wykonawczego. Potrzebne sprawdzenie faktycznego przekazania tieru oraz zakresu silnika przed zmianą.

## Nagrody

Mediany nie rosną monotonicznie między rozdziałami. Pominięto wyłącznie zadania `job.refuse*`; pozostały także zlecenia bez zamka i zerowe nagrody, więc jest to rozkład danych, nie wycena trudności.

| rozdział | liczba | min | mediana | max |
|---|---:|---:|---:|---:|
| 1 | 5 | 60 | 70 | 80 |
| 2 | 5 | 0 | 90 | 150 |
| 3 | 5 | 50 | 95 | 140 |
| 4 | 3 | 0 | 120 | 160 |
| 5 | 4 | 0 | 102.5 | 130 |
| 6 | 4 | 0 | 137.5 | 150 |
| 7 | 10 | 75 | 105.0 | 145 |
| 8 | 10 | 75 | 145.0 | 210 |
| 9 | 7 | 40 | 60 | 90 |
| 10 | 6 | 100 | 125.0 | 150 |
| 11 | 6 | 40 | 165.0 | 185 |
| 12 | 7 | 185 | 198 | 200 |

Szczególnie mediana rozdziału 8 wynosi 145, a 9 — 60; sprawy konsultacyjne za 40 oraz zerowe płatności wpływają na rozkład. Należy zdecydować, czy wymagana jest monotoniczność median, pojedynczych prac, czy tylko ogólny trend; wymuszenie wzrostu zmieniłoby ekonomię i wymaga ponownej symulacji. W rozdziałach 1–6 brak jawnego `order`, lista gry stosuje wtedy porządek ID; porównanie kolejnych nagród nie oznacza wymuszonej kolejności ukończenia. Nie modyfikowano danych.
