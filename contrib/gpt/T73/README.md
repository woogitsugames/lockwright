# T73 — warianty pytań kontrolnych

Plik obejmuje wszystkie 15 kluczy `verify.card.*` z `game/i18n/strings.csv`: po dwa warianty pytania ślusarza i odpowiedzi klienta w PL, EN i DE. W kluczach `id` itd. kontekst klienta jest przykładowy; odmianę i płeć należy dostosować do konkretnej sceny bez zmiany sensu. Pytania do klientów używają form grzecznościowych.

Warianty są materiałem do integracji, nie nowymi kluczami gry. Karty z listem, zdjęciem, paragonem, fakturą czy adresem nie stanowią automatycznie wystarczającego dowodu prawa do wejścia: sprawdzenie dalszych dokumentów lub zgody należy do logiki i scenariusza. Same kwestie nie zmieniają reguł weryfikacji. Nie sprawdzono wszystkich kontekstów użycia kart ani działania gry; `i18n_lint` nie uruchomiono, ponieważ nie zmieniono słownika gry.
