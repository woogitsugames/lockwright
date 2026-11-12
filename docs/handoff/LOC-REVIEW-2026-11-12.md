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

## Dopisek z 12 listopada (D-115): francuskie „tu” i nazwy rodzin — 63 zmian

Wykonane dwa pierwsze punkty z listy „Zauważone, nie zmienione”. Konsoli Play jeszcze nie ma, więc opisy osiągnięć można było zmienić bez skutków w sklepie. Zmieniono tylko komórki fr istniejących wierszy (60 w `content.csv`, 3 w `strings.csv`); nagrane kwestie (`job.*.line.*`, `job.*.after.*`, `job.*.wrong_open.*`) nietknięte, `contrib/voice/REVOICE.md` bez nowych wpisów.

### Rejestr „vous” → „tu” (osiągnięcia, porady, zasady w notesie) — 53 zmian

W 5 opisach osiągnięć przy okazji poprawiona nazwa rodziny („serrure à leviers” → „serrure à gorges”, „serrure à plaquettes” → „serrure à paillettes”). Nazwa osiągnięcia `steel_warning` dostała formę bezosobową („Alerte entendue”), jak PL „Usłyszany sygnał” i EN „Heard the Warning”.

| klucz | było | jest |
|---|---|---|
| `notebook.rule.1` | Demandez d'abord à qui cela appartient. Ensuite, regardez la serrure. | Demande d'abord à qui cela appartient. Ensuite, regarde la serrure. |
| `notebook.rule.4` | Annoncez le devis avant l'intervention. Pas de surprises sur la facture. | Annonce le devis avant l'intervention. Pas de surprises sur la facture. |
| `ach.achievement.first_set.desc` | Effectuez votre premier placement net hors du tutoriel. | Effectue ton premier placement net hors du tutoriel. |
| `ach.achievement.first_open.desc` | Terminez votre première serrure en mode Service continu. | Termine ta première serrure en mode Service continu. |
| `ach.achievement.pin_school.desc` | Terminez les trois leçons sur les serrures à goupilles. | Termine les trois leçons sur les serrures à goupilles. |
| `ach.achievement.wafer_school.desc` | Terminez les trois leçons sur les serrures à plaquettes. | Termine les trois leçons sur les serrures à paillettes. |
| `ach.achievement.false_note.desc` | Ouvrez une serrure à goupilles après avoir entendu un faux placement. | Ouvre une serrure à goupilles après avoir entendu un faux placement. |
| `ach.achievement.after_drop.desc` | Récupérez après une chute et ouvrez sans casser de crochet. | Récupère après une chute et ouvre sans casser de crochet. |
| `ach.achievement.after_overset.desc` | Ouvrez après une surélévation sans casser de crochet. | Ouvre après une surélévation sans casser de crochet. |
| `ach.achievement.counter_sense.desc` | Terminez une serrure après avoir ressenti sa contre-rotation. | Termine une serrure après avoir ressenti sa contre-rotation. |
| `ach.achievement.steel_warning.name` | Vous avez entendu l'alerte | Alerte entendue |
| `ach.achievement.steel_warning.desc` | Ouvrez après un avertissement de tension sans casser de crochet. | Ouvre après un avertissement de tension sans casser de crochet. |
| `ach.achievement.clean_receipt.desc` | Obtenez le tampon « travail soigné » : aucune chute, aucun crochet cassé. | Obtiens le tampon « travail soigné » : aucune chute, aucun crochet cassé. |
| `ach.achievement.hard_clean.desc` | Ouvrez une serrure de niveau 5 ou plus sans chute ni crochet cassé. | Ouvre une serrure de niveau 5 ou plus sans chute ni crochet cassé. |
| `ach.achievement.pin_master.desc` | Terminez la cinquième serrure à goupilles de maître sans casser de crochet. | Termine la cinquième serrure à goupilles de maître sans casser de crochet. |
| `ach.achievement.wafer_master.desc` | Terminez la troisième serrure à plaquettes de maître sans casser de crochet. | Termine la troisième serrure à paillettes de maître sans casser de crochet. |
| `ach.achievement.wafer_clean.desc` | Ouvrez une serrure à plaquettes sans chute ni crochet cassé. | Ouvre une serrure à paillettes sans chute ni crochet cassé. |
| `ach.achievement.pin_plain.desc` | Ouvrez une serrure à goupilles de niveau 3 sans faux placement ni surélévation. | Ouvre une serrure à goupilles de niveau 3 sans faux placement ni surélévation. |
| `ach.achievement.first_gate.desc` | Ouvrez une serrure à leviers en alignant la vraie encoche. | Ouvre une serrure à gorges en alignant la vraie encoche. |
| `ach.achievement.detector_return.desc` | Ouvrez une serrure à détecteur après son déclenchement et une remise à zéro réussie. | Ouvre une serrure à détecteur après son déclenchement et une remise à zéro réussie. |
| `ach.achievement.ring_false.desc` | Ouvrez une serrure à anneaux après un faux placement. | Ouvre une serrure à anneaux après un faux placement. |
| `ach.achievement.wooden_creak.desc` | Ouvrez une serrure à goupilles en bois après avoir entendu son grincement. | Ouvre une serrure à goupilles en bois après avoir entendu son grincement. |
| `ach.achievement.iron_no_drop.desc` | Ouvrez une serrure à garnitures sans faire tomber de pièce. | Ouvre une serrure à garnitures sans faire tomber de pièce. |
| `ach.achievement.lever_true.desc` | Ouvrez une serrure à leviers sans faux placement. | Ouvre une serrure à gorges sans faux placement. |
| `ach.achievement.first_dark.desc` | Terminez votre première serrure dans le noir. | Termine ta première serrure dans le noir. |
| `ach.achievement.dark_clean.desc` | Ouvrez dans le noir sans chute ni crochet cassé. | Ouvre dans le noir sans chute ni crochet cassé. |
| `ach.achievement.one_pick.desc` | Terminez un défi « Un seul crochet » sans perdre votre unique crochet. | Termine un défi « Un seul crochet » sans perdre ton unique crochet. |
| `ach.achievement.daily_lock.desc` | Terminez une fois la serrure du jour. Pas besoin de série. | Termine une fois la serrure du jour. Pas besoin de série. |
| `ach.achievement.timed_care.desc` | Terminez un défi chronométré sans casser de crochet. | Termine un défi chronométré sans casser de crochet. |
| `ach.achievement.bench_stop.desc` | Atteignez la première halte à l'atelier d'un service continu. | Atteins la première halte à l'atelier d'un service continu. |
| `ach.achievement.tool_care.desc` | Réparez un outil usé à l'atelier pour la première fois. | Répare un outil usé à l'atelier pour la première fois. |
| `ach.achievement.permission.desc` | Vérifiez le droit d'accès avant votre première ouverture sous contrat. | Vérifie le droit d'accès avant ta première ouverture sous contrat. |
| `ach.achievement.witness.desc` | Terminez une intervention après confirmation de l'accès par un témoin indépendant. | Termine une intervention après confirmation de l'accès par un témoin indépendant. |
| `ach.achievement.first_no.desc` | Refusez une intervention sans droit d'accès confirmé. | Refuse une intervention sans droit d'accès confirmé. |
| `ach.achievement.ex_partner.desc` | Résolvez l'affaire de l'ex-partenaire sans ouvrir la porte. | Résous l'affaire de l'ex-partenaire sans ouvrir la porte. |
| `ach.achievement.bribe.desc` | Refusez le supplément proposé pour éviter les vérifications. | Refuse le supplément proposé pour éviter les vérifications. |
| `ach.achievement.aunt_alive.desc` | Terminez l'affaire de la tante sans ouvrir son logement. | Termine l'affaire de la tante sans ouvrir son logement. |
| `ach.achievement.wrong_floor.desc` | Résolvez une erreur d'étage sans ouvrir de porte. | Résous une erreur d'étage sans ouvrir de porte. |
| `ach.achievement.heirs.desc` | Attendez tous les héritiers habilités avant d'ouvrir le coffre. | Attends tous les héritiers habilités avant d'ouvrir le coffre. |
| `ach.achievement.partial_refusal.desc` | Ouvrez le coffret du client, mais refusez la cassette d'un tiers. | Ouvre le coffret du client, mais refuse la cassette d'un tiers. |
| `ach.achievement.museum_papers.desc` | Ouvrez le coffre du musée après autorisation de l'établissement. | Ouvre le coffre du musée après autorisation de l'établissement. |
| `ach.achievement.kazimierz.desc` | Terminez l'intervention documentée sur le portail de Kazimierz. | Termine l'intervention documentée sur le portail de Kazimierz. |
| `ach.achievement.capsule.desc` | Ouvrez la capsule temporelle de l'école avec son autorisation. | Ouvre la capsule temporelle de l'école avec son autorisation. |
| `tip.ethics_01` | Demandez d'abord à qui appartient la porte. Le mécanisme peut attendre. | Demande d'abord à qui appartient la porte. Le mécanisme peut attendre. |
| `tip.ethics_07` | Si l'histoire ne tient pas debout, proposez d'appeler le gestionnaire. | Si l'histoire ne tient pas debout, propose d'appeler le gestionnaire. |
| `tip.ethics_10` | Convenez du prix d'abord. Laissez les surprises à la bouilloire. | Conviens du prix d'abord. Laisse les surprises à la bouilloire. |
| `tip.feel_08` | Trois traces de frottement sont un indice du jeu, pas une note sur votre bulletin. | Trois traces de frottement sont un indice du jeu, pas une note sur ton bulletin. |
| `tip.workshop_02` | Les outils gardent le souvenir de chaque service. Examinez leurs bords après l'intervention. | Les outils gardent le souvenir de chaque service. Examine leurs bords après l'intervention. |
| `tip.dark_07` | Le silence n'est pas vide. Écoutez combien de temps il dure. | Le silence n'est pas vide. Écoute combien de temps il dure. |
| `tip.dark_08` | Vous pouvez rallumer. Il n'y a pas de médaille pour les yeux fatigués. | Tu peux rallumer. Il n'y a pas de médaille pour les yeux fatigués. |
| `tip.people_02` | La version des faits d'un chat aide rarement. Demandez au propriétaire. | La version des faits d'un chat aide rarement. Demande au propriétaire. |
| `tip.people_08` | Chaque porte a deux côtés. Pensez à la personne de l'autre. | Chaque porte a deux côtés. Pense à la personne de l'autre. |
| `tip.calm_10` | Le travail fini, laissez les gens reprendre leur journée. | Le travail fini, laisse les gens reprendre leur journée. |

### Nazwy rodzin i części poza osiągnięciami — 10 zmian

Rodzina dźwigniowa to po francusku „serrure à gorges”, jej części „gorges”; rodzina płytkowa „serrure à paillettes”, części „paillettes” (tak w `family.*.name`, `lock.*`, `receipt.service.*`, `tool.pk_lever.desc`). Poprawione pozostałe miejsca, które mówiły „leviers” / „plaquettes” (długie teksty skrócone w tabeli; zmienione jest tylko to słowo).

| klucz | było | jest |
|---|---|---|
| `practice.t18.goal` | Attends le clic juste du levier. | Attends le clic juste de la gorge. |
| `practice.t19.goal` | Laisse tomber le levier ; retiens l'effet du ressort. | Laisse tomber la gorge ; retiens l'effet du ressort. |
| `practice.t24.goal` | Compte les encoches des leviers, sans sauter. | Compte les encoches des gorges, sans sauter. |
| `showcase.barron_1778.body` | En 1778, le serrurier londonien Robert Barron fit breveter une amélioration majeure de la serrure à leviers. Dans son modèle, le pêne restait bloqu… | En 1778, le serrurier londonien Robert Barron fit breveter une amélioration majeure de la serrure à gorges. Dans son modèle, le pêne restait bloqué… |
| `showcase.chubb_detector.body` | En 1818, Jeremiah Chubb fit breveter une serrure à leviers munie d'un détecteur capable de signaler une tentative de manipulation. Il n'était pas l… | En 1818, Jeremiah Chubb fit breveter une serrure à gorges munie d'un détecteur capable de signaler une tentative de manipulation. Il n'était pas le… |
| `tool.pk_lever.name` | Manivelle à leviers | Manivelle à gorges |
| `notebook.extra.wafer_rattle` | Les plaquettes ont tinté comme des couverts dans un tiroir. La porte s'est finalement ouverte. | Les paillettes ont tinté comme des couverts dans un tiroir. La porte s'est finalement ouverte. |
| `notebook.extra.wafer_overset` | Un choc sourd des plaquettes, sans cascade ensuite. J'ai noté la différence. | Un choc sourd des paillettes, sans cascade ensuite. J'ai noté la différence. |
| `notebook.extra.lever_false` | Les leviers ont donné deux réponses incertaines. L'histoire n'était pas finie. | Les gorges ont donné deux réponses incertaines. L'histoire n'était pas finie. |
| `job.t43_12_02_detective_cabinet.situation` | Un coffre de démonstration à serrure à leviers avec détecteur doit aller à la salle commune. Rygiel commande l'ouverture de l'accessoire vide avant… | Un coffre de démonstration à serrure à gorges avec détecteur doit aller à la salle commune. Rygiel commande l'ouverture de l'accessoire vide avant … |

### Zostawione

- `ach.achievement.ex_partner.name` „Ce ne sont pas vos clés”: to słowa ślusarza do klienta, a ślusarz mówi do klientów per „vous” — rejestr poprawny.
- `notebook.rule.3`, `notebook.rule.5` i pozostałe porady: bezosobowe albo w pierwszej osobie, bez zmian.
- Historyczne pliki wejściowe `contrib/gpt/T12`, `contrib/gpt/T31` (stare wersje tych tekstów) nie są źródłem gry — bez zmian.
- Apostrofy typograficzne w 18 starszych kluczach i pozostałe punkty listy powyżej: nadal otwarte.

Sprawdzenie: `python3 tools/i18n_lint.py` (0 błędów), `python3 data/tools/loc_qa.py` (OK), `python3 data/tools/validate.py` (OK), `python3 -m pytest tools/tests` (64 testy). Żaden ze zmienionych tekstów nie występuje w `game/**/*.gd`, `*.json`, `*.tscn`.
