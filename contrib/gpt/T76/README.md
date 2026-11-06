# T76 — dodatkowe kwestie po odmowach

Na bazie main b50ea45 wszystkie 11 zleceń o identyfikatorze job.refuse_* ma już co najmniej jedną kwestię after. Plik scenes.csv proponuje po jednej dodatkowej, pojednawczej kwestii dla każdego, z identyfikatorem mówcy i tłumaczeniem na pięć języków. Nowe klucze mają kolejny numer po istniejących kwestiach; nie zastępują ich.

W plikach danych trzeba dopisać mówcę do tablicy after, a teksty włączyć do i18n dopiero po akceptacji. Nie udowodniono, że gra odtwarza sceny następnego dnia: ścieżka odmowy w job_verify.gd wraca do listy. Do sprawdzenia przed integracją: działanie odtwarzania, długości, forma grzecznościowa i nagrania.
