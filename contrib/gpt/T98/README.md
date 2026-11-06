# T98 — propozycja uzupełnienia słowniczka

Nazwy rodzin D-59 już występują w `docs/GLOSSARY.md` w pięciu językach; nie proponujemy duplikowania ani zmiany istniejących nazw. Poniższa nowa tabela przepisuje nazwy wyposażenia z `game/i18n/strings.csv`, według dziesięciu identyfikatorów z `game/data/furnishings.json` (HEAD `b50ea45`). Jest materiałem do integracji, nie decyzją o zmianie UI.

| ID | PL | EN | DE | FR | ES |
|---|---|---|---|---|---|---|
| plant | Pelargonia w glinianej doniczce | Geranium in a clay pot | Geranie im Tontopf | Géranium en pot de terre | Geranio en maceta de barro |
| rug | Tkany chodnik | Woven runner | Gewebter Läufer | Tapis de laine tissé | Alfombra tejida |
| shelf_light | Listwa świetlna pod półką | Light strip under the shelf | Lichtleiste unter dem Regal | Réglette lumineuse sous l'étagère | Tira de luz bajo el estante |
| radio | Radio lampowe | Valve radio | Röhrenradio | Poste à lampes | Radio de válvulas |
| certificate | Dyplom w ramce | Framed certificate | Gerahmter Gesellenbrief | Diplôme encadré | Diploma enmarcado |
| case_velvet | Aksamit i tabliczki do gabloty | Velvet and plaques for the showcase | Samt und Schildchen für die Vitrine | Velours et plaques pour la vitrine | Terciopelo y placas para la vitrina |
| clock | Zegar warsztatowy | Workshop clock | Werkstattuhr | Horloge d'atelier | Reloj de taller |
| thanks_cards | Kartki z podziękowaniami | Thank-you cards | Dankeskarten | Cartes de remerciement | Tarjetas de agradecimiento |
| vise | Imadło obrotowe | Swivel vise | Drehbarer Schraubstock | Étau pivotant | Tornillo de banco giratorio |
| exhibit_shelf | Półka z eksponatami | Exhibit shelf | Regal mit Exponaten | Étagère d'exposition | Estante de piezas antiguas |

## Wątpliwości

- To pełne nazwy przedmiotów, a nie rozstrzygnięty słownik każdego elementu. Niektóre są długie; przed użyciem w nowym UI sprawdzić limit i kontekst.
- `case_velvet` obejmuje także tabliczki, a `shelf_light` to listwa świetlna pod półką — nie osobna lampa. `vise` jest kosmetyczne (D-71), nie daje premii mechanicznej.
- Nazewnictwo rodzin oraz rozbieżności opisane w obecnym `docs/GLOSSARY.md` pozostają otwarte; `kołek` stosować tylko do wariantu drewnianego/egipskiego.

Źródła: `docs/GLOSSARY.md`, `docs/DECISIONS.md` D-71, `game/data/furnishings.json`, `game/i18n/strings.csv`. Plików źródłowych nie zmieniono.
