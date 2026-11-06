# T96 — audyt odmów w rozdziałach 7–12

Źródła: docs/CLIENTS.md §4, game/data/jobs/*.json, polskie kwestie game/i18n/content.csv oraz statyczna lektura game/scripts/ui/job_verify.gd. Baza b50ea45. Przejrzano wszystkie osiem zleceń o identyfikatorze job.refuse_* w rozdziałach 7–12. Nie uruchamiano gry.

| Zlecenie | Zgrzyt | Rozwiązanie proponowane w scenie |
|---|---|---|
| refuse_sisters_flat | Nie ma zgody nieobecnej siostry. | Poczekać na zgodę lub zadzwonić do zarządcy. |
| refuse_unapproved_stockroom | List przewozowy nie uprawnia do wejścia. | Uzgodnić bezpieczny odbiór paczek. |
| refuse_wrong_letterbox | Kartka trafiła do cudzej skrzynki. | Zostawić liścik i poczekać na sąsiadów. |
| refuse_unapproved_repair | Wizyta niepotwierdzona, propozycja dopłaty. | Telefon do zarządczyni i oczekiwanie na potwierdzenie. |
| refuse_t43_09_empty_flat | Brak zgody lokatorki. | Ustalić inny termin. |
| refuse_t43_10_early_clearance | Właściciel chce wejść przed przekazaniem mieszkania. | Poczekać na uzgodnione przekazanie z lokatorem. |
| refuse_t43_11_other_stall | Klientka chce wejść do cudzego stoiska. | Poprosić o zapasowy przedłużacz. |
| refuse_t43_12_surprise_key | Brak zgody zarządczyni świetlicy. | Zapytać ją po cichu, by zachować niespodziankę. |

Każda scena zawiera wyraźną odmowę i spokojną alternatywę, a dane deklarują zero monet. W CSV dla każdego zlecenia jest co najmniej jedna kwestia after. To obserwacje danych, nie potwierdzenie odtworzenia scen.

Wszystkie osiem JSON ma outcome: open, co jest semantycznie mylące. Nie dowodzi to, że gracz może otworzyć zamek: job_verify.gd ukrywa przycisk akceptacji dla identyfikatora zaczynającego się od job.refuse, a odmowa zapisuje stan i dodaje 5 reputacji. Warto ujednolicić model danych i dodać test tej reguły.

Ścieżka odmowy w job_verify.gd zapisuje stan i wraca do listy, bez wywołania sceny after. Sama obecność kwestii nie potwierdza spełnienia wymogu sceny następnego dnia. Integracja powinna sprawdzić, czy odtwarza je inny mechanizm.

Wątpliwość: pole verification to opis, nie dowód wykonywania wymienionych flag. Nie oceniano innych zleceń ani ścieżek gry.
