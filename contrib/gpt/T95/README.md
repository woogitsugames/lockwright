# T95 — powtórzenia kwestii rozdziałów 7–12

Na bazie main b50ea45 porównano wszystkie niepuste job.<id>.line.<n> dla 54 zleceń rozdziałów 7–12 w game/i18n/content.csv, osobno dla PL, EN, DE, FR i ES. Usunięto skrajne białe znaki i pominięto różnicę wielkości liter. Nie wykryto identycznych pełnych kwestii; plik exact_duplicates.csv zawiera sam nagłówek. Metoda nie wykrywa parafraz.

Pięć kwestii w odmowach zaczyna się od „Tu nie otworzę.”: job.refuse_t43_09_empty_flat.line.4, job.refuse_t43_10_early_clearance.line.4, job.refuse_t43_11_other_stall.line.4, job.refuse_t43_12_surprise_key.line.4 i job.refuse_wrong_letterbox.line.4. Wspólna formuła podkreśla granicę, ale część można zróżnicować:

| klucz | było | jest | powód |
|---|---|---|---|
| job.refuse_t43_09_empty_flat.line.4 | Tu nie otworzę. Mogę pomóc ustalić inny termin. | Bez zgody lokatorki nie otworzę. Pomogę ustalić inny termin. | Powód łączy się z poprzednim pytaniem o zgodę. |
| job.refuse_t43_10_early_clearance.line.4 | Tu nie otworzę. Mogę wrócić na uzgodnione przekazanie. | Poczekajmy na zgodę lokatora. Wrócę na uzgodnione przekazanie. | Inny rytm, zachowana alternatywa. |
| job.refuse_t43_11_other_stall.line.4 | Tu nie otworzę. Zapytajmy o zapasowy przedłużacz. | Cudzego stoiska nie otworzę. Zapytajmy o zapasowy przedłużacz. | Konkretny obiekt i spokojna granica. |

Przed wdrożeniem należy sprawdzić tłumaczenia, nagrania, długość i mówców. Nie przeprowadzono pełnej stylistycznej oceny wszystkich parafraz pięciu języków.
