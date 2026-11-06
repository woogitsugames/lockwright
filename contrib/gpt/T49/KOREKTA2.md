# Dalsze propozycje po przeglądzie

Propozycje dotyczą istniejących kluczy `game/i18n/content.csv`. Puste kolumny oznaczają brak zmiany. Nie dodawać tych kluczy do pliku po raz drugi; zastosowanie wymaga nadpisania odpowiednich komórek na kopii i decyzji integratora.

| Klucz | Język | Było | Jest | Powód |
|---|---|---|---|---|
| job.halina_recipe_box.line.1 | fr | Ma recette de pierogi est dedans. Je me souviens juste du mot « poignée ». | Ma recette de boulettes de pâte est dedans. Je me souviens juste du mot « poignée ». | Kluski nie muszą być pierogami; zachowuje ogólne znaczenie. |
| job.halina_recipe_box.line.1 | es | Dentro está mi receta de pierogi. Solo recuerdo la palabra «puñado». | Dentro está mi receta de bolitas de masa. Solo recuerdo la palabra «puñado». | Kluski nie muszą być pierogami; zachowuje ogólne znaczenie. |
| job.shared_room_door.line.4 | fr | Et moi, des pierogi. La porte peut attendre. Pas eux. | Et moi, des boulettes de pâte. La porte peut attendre. Pas elles. | Kluski nie są jednoznacznie pierogami. |
| job.shared_room_door.line.4 | es | Y yo traje pierogi. La puerta puede esperar. Ellos no. | Y yo traje bolitas de masa. La puerta puede esperar. Ellas no. | Kluski nie są jednoznacznie pierogami. |
| job.shared_room_door.note | fr | Vieille Ville, salle commune. Vote signé, gestionnaire et témoin. Chaises, photos et pierogi sont arrivés les premiers. | Vieille Ville, salle commune. Vote signé, gestionnaire et témoin. Chaises, photos et boulettes de pâte sont arrivées en premier. | Kluski nie są jednoznacznie pierogami; nazwa dzielnicy pozostaje do uzgodnienia T51. |
| job.shared_room_door.note | es | Casco antiguo, sala común. Votación firmada, administradora y testigo. Llegaron primero las sillas, las fotos y los pierogi. | Casco antiguo, sala común. Votación firmada, administradora y testigo. Llegaron primero las sillas, las fotos y las bolitas de masa. | Kluski nie są jednoznacznie pierogami; nazwa dzielnicy pozostaje do uzgodnienia T51. |

| job.refuse_aunt_alive.after.2 | es | Menos mal que dijiste que no. No habría pegado ojo. | Menos mal que dijo que no. No habría pegado ojo. | Uprzejma forma usted wobec ślusarza, zgodna z obsadą. |
| job.refuse_ex_partner.after.2 | es | Me enteré en la parada. Eres de fiar. ¿Un periódico? | Me enteré en la parada. Es usted de fiar. ¿Un periódico? | Uprzejma forma usted wobec ślusarza, zgodna z obsadą. |
| job.refuse_rush_bribe.after.2 | es | Ayer un hombre trajeado preguntó por un cerrajero. Lo mandé a verte. Lo siento. | Ayer un hombre trajeado preguntó por un cerrajero. Lo envié a verlo. Lo siento. | Uprzejma forma usted wobec ślusarza, zgodna z obsadą. |
| job.wrong_floor.after.1 | es | ¿Eres el cerrajero que no abrió mi puerta? Te hice un pastel. Por no abrirla. | ¿Es usted el cerrajero que no abrió mi puerta? Le hice un pastel. Por no abrirla. | Uprzejma forma usted wobec ślusarza, zgodna z obsadą. |

Walidacja: `python tools/i18n_lint.py` na kopii po nałożeniu istniejącej dostawy, uzupełnienia i tego CSV sprawdził 948 kluczy: 0 błędów, 2 istniejące ostrzeżenia, kod 0. Kopia pochodzi ze sparse checkoutu bez skryptów `.gd` (choć drzewo HEAD zawiera 203 takie skrypty), więc kontrola odwołań z kodu nie była kompletna. Wynik nie sprawdza wymowy ani odtwarzania.
