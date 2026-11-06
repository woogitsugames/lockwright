# T68 — słowniczek pięciu języków

Źródło nazw rodzin: `game/i18n/strings.csv`, klucze `family.*.name`; terminy elementów według `contrib/gpt/REVIEW-T42.md` i `REVIEW-T41.md`, z EN/DE uzupełnionymi redakcyjnie na podstawie tekstów gry. Puste pole oznacza termin jeszcze nieuzgodniony, nie brak tłumaczenia całego tekstu gry. Słownik jest propozycją dla redakcji, nie zmianą plików gry.

## Rodziny — wartości z CSV

| ID | PL | EN | DE | FR | ES |
|---|---|---|---|---|---|
| dial_safe | Sejf z pokrętłem | Dial safe | Tresor mit Drehscheibe | Coffre-fort à cadran | Caja fuerte con dial |
| combo | Zamek z kółkami | Thumbwheel lock | Zahlenschloss | Serrure à molettes | Cerradura de ruedecillas |
| dimple | Wkładka nawiercana | Dimple cylinder | Bohrmuldenzylinder | Cylindre à alvéoles | Cilindro de puntos |
| disc_detainer | Zamek tarczowy | Disc lock | Scheibenschloss | Serrure à disques | Cerradura de discos |
| egyptian | Zasuwa drewniana | Wooden bolt | Holzriegel | Verrou en bois | Cerrojo de madera |
| axial_slider | Zamek suwakowy | Axial slider | Schiebeschloss | Serrure à coulisseaux | Cerradura de correderas |
| time_lock | Naprawa zamka czasowego | Time lock repair | Zeitschloss-Reparatur | Réparer une serrure à minuterie | Reparar una cerradura de tiempo |
| magnetic | Zamek magnetyczny | Magnetic pin lock | Magnetstiftschloss | Serrure à goupilles magnétiques | Cerradura de pernos magnéticos |

## Elementy i interfejs

| PL | EN | DE | FR | ES | Uwagi |
|---|---|---|---|---|---|
| pin | pin | Stift | goupille | perno | Pin bębenkowy; nie kołek. |
| kołek drewniany | wooden peg | Holzstift | cheville | pasador de madera | Tylko zamek drewniany/egipski. |
| pokrętło sejfu | dial | Drehscheibe | cadran | dial | DE odróżnia je od wewnętrznego koła. |
| kółko szyfrowe | thumbwheel |  | molette | ruedecilla | FR `roue` i ES `rueda` występują wariantowo. |
| tarcza | disc | Scheibe | disque | disco | Element mechanizmu tarczowego. |
| suwak | slider | Schieber | coulisseau | corredera |  |
| sprężyna | spring | Feder | ressort | muelle |  |
| kabłąk | shackle | Bügel | anse | arco |  |
| rygiel | bolt | Riegel | pêne | cerrojo | ES `cerrojo` bywa też nazwą całej zasuwy. |
| zamek czasowy | time lock | Zeitschloss | serrure à minuterie | cerradura de tiempo | W grze chodzi o naprawę. |
| samouczek | tutorial | Tutorial | tutoriel | tutorial | Nazwy ogólne do sprawdzenia w kontekście. |
| ustawienia | settings | Einstellungen | paramètres | ajustes |  |
| dostępność | accessibility | Barrierefreiheit | accessibilité | accesibilidad |  |

## Rozbieżności do rozstrzygnięcia

- `REVIEW-T42` wskazuje `molette` dla kółka szyfrowego, a wcześniejszy `lock.combo_hint` używa FR `roue`; analogicznie ES `ruedecilla` / `rueda`. Ujednolicać po sprawdzeniu długości i kontekstu: wewnętrzne koło nie musi być tym samym elementem co zewnętrzne kółko szyfrowe.
- `family.magnetic.name`: PL „Zamek magnetyczny” pomija piny obecne w nazwach EN/DE/FR/ES. Można rozważyć „Zamek z pinami magnetycznymi”, o ile mechanizm i limit UI na to pozwalają.
- `family.axial_slider.name`: EN „Axial slider” nie zawiera słowa lock, podczas gdy pozostałe wersje nazywają zamek; sprawdzić czy skrót jest zamierzony.
- `family.combo.name`: DE „Zahlenschloss” jest szersze znaczeniowo niż zamek z kółkami. Rozważyć doprecyzowanie bez sugerowania innej mechaniki.
- `REVIEW-T42` po końcowym rozstrzygnięciu usuwa kierunek „w dół” z tekstów axial slider: nie powielać go w nowych tłumaczeniach.
- `REVIEW-T41`: UI zwraca się do gracza per ty/du/tu/tú; postacie do ślusarza per pan/Sie/vous/usted, z udokumentowanymi wyjątkami dialogowymi. W tekstach czytanych liczby słownie.

Nie wykonano pełnego przeszukania wszystkich wystąpień terminów w `content.csv` ani przeglądu każdego przycisku; przed integracją należy sprawdzić kontekst i limity. `i18n_lint` nie uruchomiono — raport nie zmienia CSV.
