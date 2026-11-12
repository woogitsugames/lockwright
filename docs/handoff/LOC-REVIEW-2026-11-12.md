# Korekta DE/FR/ES — 2026-11-12 (zadanie G10C i klucze dodane później)

Decyzja: D-114. Zakres: 177 kluczy z `docs/handoff/gpt10/G10C-keys.txt` oraz 100 kluczy dodanych lub zmienionych w `game/i18n/strings.csv` i `game/i18n/content.csv` po commicie 453d902f (8 listopada), w tym pytania i odpowiedzi do kart (D-104), blokada napięcia (D-107), rozmiar tekstu z systemu i paczki treści (D-112). Rozdział 13 (dopisywany równolegle) nie był w zakresie.

Sprawdzano: naturalność, rejestr (UI do gracza per du/tu/tú; postacie do ślusarza per Sie/vous/usted), zgodność z PL/EN, rodzaj gramatyczny, spójność terminów z resztą gry, długość (nowy tekst najwyżej +15% do starego; `lock.*` i `tutorial.*` ≤ 56 znaków).

Zmieniono tylko komórki de/fr/es istniejących wierszy. Razem **52** zmian: DE 6, FR 31, ES 15.

Klucze z nagranym głosem (`job.*.line.*`, `job.*.after.*`, `job.*.wrong_open.*`): przejrzane, **żaden nie został zmieniony**, więc `contrib/voice/REVOICE.md` zostaje bez nowych wpisów.

Jedyne przekroczenie +15%: `a11y.lock.open` FR „Ouvert” → „Ouverte” (jedna litera, tekst czytany przez czytnik ekranu).


## Klucze z listy G10C (177 kluczy z 7–8 listopada) — 31 zmian

| klucz | język | było | jest | powód |
|---|---|---|---|---|
| `verify.paper.witness.body` | fr | Je connais cette personne depuis des années et je me porte garant. | Je connais cette personne depuis des années et je réponds d'elle. | „je me porte garant” zakłada świadka-mężczyznę; forma neutralna |
| `verify.reply.manager_access.1` | fr | La gestion. Signature et tampon sont là. | La gérance. Signature et tampon sont là. | jw. |
| `verify.reply.manager_storage.1` | fr | Oui. La gestion tient la liste des usagers. | Oui. La gérance tient la liste des usagers. | jw. |
| `verify.ask.manager_storage.2` | fr | La gestion le confirmera-t-elle ? | La gérance le confirmera-t-elle ? | „la gestion” nie oznacza po francusku zarządu budynku; „gérance” jak w verify.paper.issuer.tenement |
| `lock.axial_slider_hint` | es | Izquierdo sujeta; derecho hacia arriba la hunde. | Izquierdo sujeta; derecho arriba hunde la corredera. | zaimek „la” bez poprzednika; nazwany element, limit 56 zachowany |
| `tutorial.frame_lift_one` | fr | Pouce droit sous la goupille, haut pour lever. | Pouce droit sous la goupille, monte pour la lever. | „haut pour lever” to telegraficzna kalka; limit 56 zachowany |
| `tutorial.frame_lift_one` | es | Pulgar derecho bajo el perno, arriba elevas. | Pulgar derecho bajo el perno; sube para elevarlo. | „arriba elevas” niegramatyczne; limit 56 zachowany |
| `practice.note` | fr | Les exercices ne rapportent rien et ne sont pas chronométrés. L'objectif est écrit à la craie au-dessus de la serrure. | Les exercices ne rapportent pas de pièces et ne sont pas chronométrés. L'objectif est écrit à la craie au-dessus de la serrure. | zgodność z PL/EN: chodzi o monety, nie „nic” |
| `practice.locked` | de | Frei nach deinem ersten Auftrag mit diesem Schloss | Verfügbar nach deinem ersten Auftrag mit diesem Schloss | „Frei nach …” znaczy po niemiecku „luźno według …” |
| `family.warded.name` | fr | Serrure à garniture | Serrure à garnitures | termin fachowy w liczbie mnogiej; spójność z tool.pk_ward.name i osiągnięciem |
| `a11y.lock_screen_auto` | de | Das Spiel hält die Spannung. Rechte Hälfte: seitlich ein Teil wählen, nach oben anheben. Tipp auf die linke Hälfte, um die Spannung zu lösen. | Das Spiel hält die Spannung. Rechte Hälfte: seitlich ein Teil wählen, nach oben anheben. Tippe auf die linke Hälfte, um die Spannung zu lösen. | „Tipp” to rzeczownik (wskazówka); tryb rozkazujący: „Tippe” |
| `a11y.lock_screen_auto` | es | El juego mantiene la tensión. Mitad derecha: desliza al lado para elegir una pieza y arriba para elevarla. Toca la mitad izquierda para soltar la tensión. | El juego mantiene la tensión. Mitad derecha: desliza hacia un lado para elegir una pieza y hacia arriba para elevarla. Toca la mitad izquierda para soltar la tensión. | „desliza al lado” = „przesuń obok”; poprawnie „hacia un lado / hacia arriba” |
| `a11y.lock_screen_manual` | es | Mitad izquierda: desliza arriba para dar tensión. Mitad derecha: al lado para elegir una pieza y arriba para elevarla. | Mitad izquierda: desliza hacia arriba para dar tensión. Mitad derecha: a un lado para elegir una pieza y hacia arriba para elevarla. | jw. |
| `a11y.lock.false_set` | de | {n}: falsch gesetzt — zu tief | {n}: falscher Halt — zu tief | spójność terminu z practice.t20 i osiągnięciami („falscher Halt”) |
| `a11y.lock.false_set` | fr | {n} : fausse prise, trop profond | {n} : faux placement, trop profond | spójność terminu z osiągnięciami („faux placement”) |
| `a11y.lock.false_set` | es | {n}: falso asiento, demasiado hondo | {n}: falso asentamiento, demasiado hondo | spójność terminu z osiągnięciami („falso asentamiento”) |
| `a11y.lock.counter_rotate` | es | El rotor empuja hacia atrás | El núcleo retrocede | spójność: rdzeń to wszędzie „núcleo” (practice.t21, tip.feel_*), nie „rotor”; zgodnie z PL „się cofa” |
| `a11y.lock.drop` | de | Alles gefallen — noch einmal | Alles zurückgefallen — von vorn | „Alles gefallen” brzmi jak „wszystko się spodobało”; „von vorn” = od nowa |
| `a11y.lock.drop` | es | Todo ha caído, otra vez | Todo ha caído: de nuevo | „otra vez” po przecinku czyta się jak „znowu opadło”, a ma znaczyć „od nowa” |
| `a11y.lock.gate_align` | es | {n}: en la ranura | {n}: en la muesca | spójność: bramka zapadki to „muesca” (lock.lever_coach), „ranura” to szczelina na grot |
| `a11y.lock.open` | fr | Ouvert | Ouverte | rodzaj: „la serrure” (jak ES „Abierta”) |
| `a11y.sfx.ward_scrape` | fr | [la sonde racle une garde] | [la sonde racle la garniture] | spójność: przegrody to „garnitures” (tool.pk_ward, family.warded), nie „garde” |
| `a11y.sfx.counter_rotate` | es | [chirrido, el rotor empuja] | [chirrido, el núcleo retrocede] | jw. |
| `a11y.sfx.gate_align` | es | [toc suave, en la ranura] | [toc suave, en la muesca] | jw. |
| `a11y.sfx.detector_trip` | de | [Klank — Detektor] | [Klacken — Detektor] | „Klank” nie jest niemieckim słowem |
| `settings.swap_thumbs` | de | Daumen tauschen (Linkshänder) | Daumen tauschen (für Linkshänder) | zgodność z PL „dla leworęcznych”; neutralne |
| `settings.swap_thumbs` | fr | Inverser les pouces (gaucher) | Inverser les pouces (gauchers) | liczba mnoga, neutralniej niż „gaucher” |
| `settings.swap_thumbs` | es | Cambiar pulgares (zurdo) | Cambiar pulgares (zurdos) | liczba mnoga, neutralniej niż „zurdo” |
| `a11y.warded_bit` | fr | Tête de sonde : changer d’embout | Tête de sonde : changer d'embout | typografia: apostrof prosty jak w pozostałych tekstach UI |
| `a11y.card_ask` | es | Toca para preguntar al cliente por ello | Toca para preguntárselo al cliente | naturalność: „por ello” to kalka; krócej |
| `job.halina_christmas_tin.photo.reply` | es | En mi puerta, el número siete. La lata vive en mi cocina. | Delante de mi puerta, la del siete. La lata vive en mi cocina. | „En mi puerta, el número siete” nienaturalne; zdjęcie zrobiono pod drzwiami nr 7 |

## Klucze dodane po 8 listopada (D-104, D-107, D-112 i sąsiednie) — 9 zmian

| klucz | język | było | jest | powód |
|---|---|---|---|---|
| `receipt.service.warded` | fr | Ouverture serrure à garniture | Ouverture serrure à garnitures | spójność z family.warded.name |
| `settings.help.tension_lock` | fr | Avec deux pouces : après avoir lâché, touche deux fois la moitié gauche pour garder la tension ; une touche la relâche. Glisse pour la changer. | À deux pouces seulement : après avoir lâché, touche deux fois la moitié gauche pour garder la tension ; un seul appui la relâche. Glisse pour la changer. | „une touche” = klawisz; brakowało „tylko” |
| `a11y.tension_released` | es | Tensión soltada | Tensión liberada | „soltada” nienaturalne jako komunikat stanu |
| `pack.row.note` | fr | De préférence en Wi-Fi. Seul le fichier du chapitre est téléchargé : ni compte, ni suivi. Vous pouvez le supprimer dans les Paramètres. | De préférence en Wi-Fi. Seul le fichier du chapitre est téléchargé : ni compte, ni suivi. Tu peux le supprimer dans les Paramètres. | rejestr: UI zwraca się do gracza per „tu” |
| `pack.row.downloading` | fr | Téléchargement : {pct} % de {size}. Vous pouvez continuer à jouer. | Téléchargement : {pct} % de {size}. Tu peux continuer à jouer. | rejestr: „tu” |
| `pack.row.offline` | fr | Pas de connexion. Ce qui est déjà téléchargé est conservé : réessayez une fois en ligne. | Pas de connexion. Ce qui est déjà téléchargé est conservé : réessaie une fois en ligne. | rejestr: „tu” |
| `pack.row.failed` | fr | Le téléchargement n'a pas abouti. Réessayez. | Le téléchargement n'a pas abouti. Réessaie. | rejestr: „tu” |
| `pack.row.update` | fr | Ce chapitre nécessite une version plus récente du jeu. Mettez d'abord le jeu à jour. | Ce chapitre nécessite une version plus récente du jeu. Mets d'abord le jeu à jour. | rejestr: „tu” |
| `settings.content.note` | fr | Supprimer un chapitre libère de la place sans effacer votre progression : les interventions terminées le restent et reviennent avec le chapitre. | Supprimer un chapitre libère de la place sans effacer ta progression : les interventions terminées le restent et reviennent avec le chapitre. | rejestr: „tu” |

## Starsze klucze poprawione przy okazji — 12 zmian

| klucz | język | było | jest | powód |
|---|---|---|---|---|
| `practice.t06.goal` | fr | Compare les embouts; le bon se fait discret. | Compare les embouts ; le bon se fait discret. | typografia FR: spacja przed średnikiem |
| `practice.t07.goal` | fr | Va trop loin après un clic; reconnais le blocage. | Va trop loin après un clic ; reconnais le blocage. | typografia FR: spacja przed średnikiem |
| `practice.t08.goal` | fr | Pousse une plaque trop loin; relâche sans perdre les autres. | Pousse une plaque trop loin ; relâche sans perdre les autres. | typografia FR: spacja przed średnikiem |
| `practice.t11.goal` | fr | Écoute les crans; le passage sonne autrement. | Écoute les crans ; le passage sonne autrement. | typografia FR: spacja przed średnikiem |
| `practice.t12.goal` | fr | Trouve l'anneau bloqué; laisse les autres. | Trouve l'anneau bloqué ; laisse les autres. | typografia FR: spacja przed średnikiem |
| `practice.t15.goal` | fr | Va trop loin une fois; relâche et reprends calmement. | Va trop loin une fois ; relâche et reprends calmement. | typografia FR: spacja przed średnikiem |
| `practice.t19.goal` | fr | Laisse tomber le levier; retiens l'effet du ressort. | Laisse tomber le levier ; retiens l'effet du ressort. | typografia FR: spacja przed średnikiem |
| `practice.t22.goal` | es | Detecta la puerta falsa; escucha el segundo toque. | Detecta el paso falso; escucha el segundo toque. | „puerta falsa” = fałszywe drzwi; bramka to „paso” (practice.t11, t17) |
| `practice.t22.goal` | fr | Repère la fausse encoche; écoute le second toc. | Repère la fausse encoche ; écoute le second toc. | typografia FR: spacja przed średnikiem |
| `practice.t25.goal` | fr | Écoute bobine et stries; distingue-les. | Écoute bobine et stries ; distingue-les. | typografia FR: spacja przed średnikiem |
| `practice.t27.goal` | fr | Active le détecteur une fois; reconnais l'alerte. | Active le détecteur une fois ; reconnais l'alerte. | typografia FR: spacja przed średnikiem |
| `tutorial.frame_lift_auto` | fr | Un pouce choisit et lève; le jeu garde la tension. | Un pouce choisit et lève ; le jeu garde la tension. | typografia FR: spacja przed średnikiem |

## Zauważone, nie zmienione (do decyzji albo osobnego zadania)

- **FR, rejestr w starszych tekstach:** opisy osiągnięć `ach.achievement.*.desc` (ok. 45 kluczy), część porad `tip.*` i zasady `notebook.rule.*` zwracają się do gracza per „vous” („Ouvrez…”, „Terminez…”), a reszta UI per „tu”; jedno osiągnięcie (`clock_repaired.desc`) już jest per „tu”. Nie ruszane: to teksty sprzed zakresu, a opisy osiągnięć mogą być już wpisane w konsoli sklepu. Rekomendacja: ujednolicić do „tu” jednym osobnym zadaniem.
- **FR, nazwy rodzin w osiągnięciach:** `ach.*` mówi „serrure à leviers” i „serrure à plaquettes”, a nazwy rodzin to „Serrure à gorges” i „Serrure à paillettes”.
- **FR, apostrofy:** 18 starszych kluczy (notatki zleceń, `chapter.*.desc`, `notebook.extra.*`) ma apostrof typograficzny ’, pozostałe 700 prosty. Bez wpływu na grę; do ujednolicenia przy okazji.
- **DE, `job.refuse_unapproved_stockroom`:** nagrana kwestia `line.2` i pytanie do karty mówią „Frachtbrief” (zgodnie z PL „list przewozowy”), notatka zlecenia „Lieferschein”. Zostawione, bo kwestia jest nagrana.
- **FR, `job.wooden_winter_village.after.1` (nagrane):** „Madame Rygiel” zamiast „Dr Rygiel” jak w pozostałych kwestiach. Drobne, zostawione.
- **FR/ES, `job.night_nurse.line.2` (nagrane):** brak odpowiednika „zgadza się”. Sens zachowany, zostawione.
- **ES, `family.lever.name`:** „Cerradura de palancas” jest zrozumiałe i używane konsekwentnie w całej grze; termin fachowy to „cerradura de gorjas”. Zostawione.
- **DE, `verify.paper.purpose.resident.head`:** „WOHNBESTÄTIGUNG” jest poprawne, naturalniejsze byłoby „WOHNSITZBESTÄTIGUNG”, ale przekracza +15% na nagłówku dokumentu.

## Sprawdzenie

`python3 tools/i18n_lint.py` (0 błędów), `python3 data/tools/loc_qa.py` (OK), `python3 data/tools/validate.py` (OK). Testy GUT nie porównują żadnego ze zmienionych tekstów (przeszukane `game/**/*.gd`, `*.json`, `*.tscn`).
