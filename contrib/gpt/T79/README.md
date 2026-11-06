# T79 — wyposażenie warsztatu

Komplet propozycji w `texts.csv`: dziesięć istniejących przedmiotów z `game/data/furnishings.json`, nazwa i opis w pięciu językach. Pozostawiono istniejący tekst tam, gdzie mieści się w limicie; w pozostałych przypadkach skrócono go, zachowując główny sens. Lampa została ujęta jako istniejąca listwa świetlna pod półką. Wyposażenie jest kosmetyczne według D-71.

Walidacja: każdy tekst nazwy ≤ 28 i opisu ≤ 80 punktów kodowych Unicode. Jest to limit tekstowy, nie pomiar szerokości; zalecany przegląd redakcyjny wszystkich języków i test w grze. Skrócenie opisów półki usuwa część szczegółów, a nazwa zestawu do gabloty wymaga kontekstu z opisu. Źródła: `game/i18n/strings.csv`, `game/data/furnishings.json`, `docs/DECISIONS.md` D-71, `docs/GLOSSARY.md`, stan bazowy `b50ea45`.

## Proponowane zmiany istniejących tekstów

| klucz | było | jest | powód |
|---|---|---|---|
| furnishing.plant.name [pl] | Pelargonia w glinianej doniczce | Pelargonia w doniczce | Skrócenie do limitu 28 znaków. |
| furnishing.rug.desc [es] | Una alfombra de lana a rayas bajo el banco. Pies más calientes en las noches de invierno. | Alfombra de lana a rayas bajo el banco. Más calor en las noches de invierno. | Skrócenie do limitu 80 znaków. |
| furnishing.shelf_light.name [fr] | Réglette lumineuse sous l'étagère | Lumière sous l’étagère | Skrócenie do limitu 28 znaków. |
| furnishing.radio.desc [es] | Una radio pequeña con caja de nogal. Tarda un minuto en calentarse antes de sonar. | Una radio en caja de nogal. Tarda un minuto en calentarse antes de sonar. | Skrócenie do limitu 80 znaków. |
| furnishing.case_velvet.name [pl] | Aksamit i tabliczki do gabloty | Aksamit i tabliczki | Skrócenie do limitu 28 znaków. |
| furnishing.case_velvet.name [en] | Velvet and plaques for the showcase | Velvet and plaques | Skrócenie do limitu 28 znaków. |
| furnishing.case_velvet.name [de] | Samt und Schildchen für die Vitrine | Samt und Schildchen | Skrócenie do limitu 28 znaków. |
| furnishing.case_velvet.name [fr] | Velours et plaques pour la vitrine | Velours et plaques | Skrócenie do limitu 28 znaków. |
| furnishing.case_velvet.name [es] | Terciopelo y placas para la vitrina | Terciopelo y placas | Skrócenie do limitu 28 znaków. |
| furnishing.case_velvet.desc [fr] | Velours bordeaux, petites plaques en laiton et une seconde lumière dans la vitrine. | Velours bordeaux, plaques en laiton et seconde lumière dans la vitrine. | Skrócenie do limitu 80 znaków. |
| furnishing.clock.desc [en] | A round wall clock with a red second hand. You hear it tick when the street is quiet. | A round clock with a red second hand. It ticks when the street is quiet. | Skrócenie do limitu 80 znaków. |
| furnishing.clock.desc [de] | Eine runde Wanduhr mit rotem Sekundenzeiger. Man hört sie ticken, wenn die Straße still ist. | Runde Wanduhr mit rotem Sekundenzeiger. Sie tickt, wenn die Straße still ist. | Skrócenie do limitu 80 znaków. |
| furnishing.clock.desc [es] | Un reloj redondo de pared con segundero rojo. Se oye cuando la calle está en silencio. | Reloj redondo con segundero rojo. Se oye cuando la calle está en silencio. | Skrócenie do limitu 80 znaków. |
| furnishing.thanks_cards.desc [de] | Karten von deinen Kunden, an die Lochwand geklemmt. Eine ist eine Kinderzeichnung. | Karten deiner Kunden an der Lochwand. Eine zeigt eine Kinderzeichnung. | Skrócenie do limitu 80 znaków. |
| furnishing.thanks_cards.desc [fr] | Des cartes de tes clients, pincées au panneau perforé. L'une est un dessin d'enfant. | Cartes de tes clients sur le panneau. L'une est un dessin d'enfant. | Skrócenie do limitu 80 znaków. |
| furnishing.exhibit_shelf.desc [pl] | Dębowa półka na tablicy: stary zamek nawierzchniowy, duży żelazny klucz i kłódka z pierścieniami. | Dębowa półka: stary zamek nawierzchniowy, żelazny klucz i kłódka. | Skrócenie do limitu 80 znaków. |
| furnishing.exhibit_shelf.desc [en] | An oak shelf on the pegboard: an old rim lock, a big iron key and a ring padlock. | An oak shelf: an old rim lock, an iron key and a ring padlock. | Skrócenie do limitu 80 znaków. |
| furnishing.exhibit_shelf.desc [de] | Ein Eichenregal an der Lochwand: ein altes Kastenschloss, ein großer Eisenschlüssel und ein Ringschloss. | Eichenregal: ein altes Kastenschloss, ein Eisenschlüssel und ein Ringschloss. | Skrócenie do limitu 80 znaków. |
| furnishing.exhibit_shelf.desc [fr] | Une étagère en chêne sur le panneau : une vieille serrure en applique, une grosse clé en fer et un cadenas à anneaux. | Étagère en chêne : serrure ancienne, clé en fer et cadenas à anneaux. | Skrócenie do limitu 80 znaków. |
| furnishing.exhibit_shelf.desc [es] | Un estante de roble en el panel: una vieja cerradura de sobreponer, una gran llave de hierro y un candado de anillas. | Estante de roble: cerradura antigua, llave de hierro y candado de anillas. | Skrócenie do limitu 80 znaków. |
