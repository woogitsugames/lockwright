# T87 — dzielnice na mapę

Propozycje dla sześciu dzielnic występujących w danych zleceń rozdziałów 7–12. Nazwy i realia oparto na `docs/JOBS.md` §4 oraz polu `district` w `game/data/jobs/*.json`, stan `b50ea45`. Nazwy EN są zgodne z biblią; DE/FR/ES to propozycje do uzgodnienia. Teksty opisują miejsca, a nie sugerują, że każda dzielnica pojawia się w każdym rozdziale.

| ID | Język | Nazwa | Opis |
|---|---|---|---|
| district.oldtown | PL | Śródmieście | W kamienicach za każdymi drzwiami czeka inna historia. Tu spotykają się sąsiedzi, studenci i antykwariusze. |
| district.oldtown | EN | Old Town | Every apartment building holds another story. Neighbors, students and antique dealers meet here. |
| district.oldtown | DE | Altstadt | Hinter den Türen der alten Häuser warten viele Geschichten. Hier begegnen sich Nachbarn, Studierende und Antiquitätenhändler. |
| district.oldtown | FR | Centre ancien | Derrière les portes des immeubles anciens, les histoires se croisent. Voisins, étudiants et antiquaires s’y rencontrent. |
| district.oldtown | ES | Casco antiguo | Tras las puertas de los edificios antiguos esperan muchas historias. Aquí se encuentran vecinos, estudiantes y anticuarios. |
| district.sunny_estate | PL | Osiedle Słoneczne | Wśród bloków toczy się codzienne życie mieszkańców. Czasem drobna przysługa wystarczy, by dzień ruszył dalej. |
| district.sunny_estate | EN | Sunny Estate | Everyday life goes on among the apartment blocks. Sometimes a small favor gets the day moving again. |
| district.sunny_estate | DE | Sonnensiedlung | Zwischen den Wohnblocks spielt sich der Alltag ab. Manchmal hilft eine kleine Gefälligkeit durch den Tag. |
| district.sunny_estate | FR | Cité du Soleil | La vie suit son cours entre les immeubles. Parfois, un petit service suffit à relancer la journée. |
| district.sunny_estate | ES | Barrio Soleado | La vida cotidiana transcurre entre los bloques. A veces, un pequeño favor ayuda a continuar el día. |
| district.campus | PL | Kampus | Studenci, portierzy i zespoły muzyczne dzielą ten kawałek miasta. Zawsze jest tu jakaś sprawa do załatwienia. |
| district.campus | EN | Campus | Students, porters and bands share this part of town. There is always something to take care of. |
| district.campus | DE | Campus | Studierende, Pförtner und Bands teilen sich diesen Teil der Stadt. Hier gibt es immer etwas zu erledigen. |
| district.campus | FR | Campus | Étudiants, concierges et groupes de musique partagent ce quartier. Il y a toujours quelque chose à faire. |
| district.campus | ES | Campus | Estudiantes, conserjes y grupos de música comparten esta zona. Siempre hay algo que hacer. |
| district.night_market | PL | Nocny Rynek | Restauracje, kluby i targowe stoiska nadają temu miejscu własny rytm. Nie wszystkie sprawy kończą się przed zmrokiem. |
| district.night_market | EN | Night Market | Restaurants, clubs and market stalls give this place its own rhythm. Not every job ends before dark. |
| district.night_market | DE | Nachtmarkt | Restaurants, Clubs und Marktstände geben diesem Ort seinen Rhythmus. Nicht jeder Auftrag endet vor Einbruch der Dunkelheit. |
| district.night_market | FR | Marché de nuit | Restaurants, clubs et stands donnent au lieu son rythme. Toutes les interventions ne se terminent pas avant la nuit. |
| district.night_market | ES | Mercado nocturno | Restaurantes, clubes y puestos marcan el ritmo de este lugar. No todos los encargos terminan antes de anochecer. |
| district.villa_hill | PL | Willowa Górka | Domy i strychy kryją przedmioty przekazywane z pokolenia na pokolenie. Każdy z nich ma swoją opowieść. |
| district.villa_hill | EN | Villa Hill | Houses and attics hold objects passed down through generations. Each has a story of its own. |
| district.villa_hill | DE | Villenhügel | In Häusern und auf Dachböden liegen Gegenstände aus vielen Generationen. Jeder erzählt seine eigene Geschichte. |
| district.villa_hill | FR | Colline des villas | Les maisons et les greniers gardent des objets transmis de génération en génération. Chacun a son histoire. |
| district.villa_hill | ES | Colina de las villas | Las casas y los desvanes guardan objetos transmitidos de generación en generación. Cada uno tiene su historia. |
| district.port | PL | Port | Tu pracują ludzie portu i Muzeum Techniki. Codzienne sprawy spotykają się z historią rzemiosła. |
| district.port | EN | Harbour & Museum | Port workers and the Museum of Technology share this area. Everyday work meets the history of the craft. |
| district.port | DE | Hafen und Museum | Hier arbeiten Menschen im Hafen und im Technikmuseum. Der Alltag trifft auf die Geschichte des Handwerks. |
| district.port | FR | Port et musée | Le port et le musée technique partagent ce quartier. Le quotidien y rencontre l’histoire du métier. |
| district.port | ES | Puerto y museo | El puerto y el Museo de Tecnología comparten esta zona. El trabajo cotidiano se encuentra con la historia del oficio. |

Wątpliwości: `district` w danych bywa zapisywane nazwą, a nie identyfikatorem `district.*`; przed integracją potrzebna jest jawna mapa tych wartości. Teksty nie zostały podłączone do mapy ani sprawdzone wizualnie. W obecnej tabeli `docs/JOBS.md` występuje nazwa EN „Harbour & Museum”; ewentualną zmianę brytyjskiej pisowni na US należy rozstrzygnąć osobno.
