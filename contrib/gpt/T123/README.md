# T123 — brakujące klucze i18n w kodzie

Statycznie porównano wywołania `I18n.t` z dosłownym argumentem w plikach `game/**/*.gd` z pierwszą kolumną obu `game/i18n/*.csv`, baza `b50ea45`. Nie znaleziono brakującego dosłownego klucza. Dwa dopasowania widoczne w `missing.csv` są **szablonami dynamicznymi**, nie rzeczywistymi nazwami kluczy: `cast.%s.name` oraz `verify.card.%s`.

Dodatkowo rozwinięto te dwa szablony na podstawie wszystkich wartości `lines`, `after` i `cards` w 83 plikach `game/data/jobs/*.json`: zero brakujących kluczy dla tych wystąpień. Nie oznacza to pełnej kontroli wszystkich dynamicznie budowanych kluczy, np. w samouczkach, scenach i innych źródłach danych. Nie badano kompletności tłumaczeń poszczególnych języków ani działania w uruchomionej grze. Skrypt tekstowy obejmuje pojedyncze linie i bezpośrednie zapisy łańcuchów, nie analizuje składni języka GDScript.

`missing.csv` zachowuje dwa trafienia heurystyki wraz z lokalizacją, aby nie ukrywać wyjątków. Nie zmieniono plików gry.
