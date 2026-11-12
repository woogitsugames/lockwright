# Kwestie czekające na nagranie (lektor AI, D-57 / D-100)

Zlecenia z polem `"voice_pending": true` w `game/data/jobs/*.json` nie mają jeszcze nagranych kwestii (`*.line.N`,
`*.after.N`). Gra pokazuje wtedy same napisy: rozmowa na przyjeździe wyświetla wszystkie kwestie od razu
(`DialoguePlayer`: brak klipu = brak odtwarzania), a „dzień po” przechodzi po tapnięciu (`DayAfter._play_clip`).
Reakcje bez słów (S03) działają, bo wszystkie postacie rozdziału 13 mają już głos.

**Po nagraniu:** `python3 tools/voice_lines.py tts-payload --jobs <id,…> --lang en,pl,de,fr,es` → `finish`, potem
usuń `voice_pending` z pliku zlecenia (test `test_chapter13_jobs.gd` przypomni: zlecenie z klipami nie może mieć
tego pola) i wiersze z tej listy. Dokładne wejście TTS (głos, seed, ustawienia) dla każdego pliku:
`contrib/voice/tts_inputs_ch13.json` (wygenerowane tym samym kodem co `tts_inputs.json`; nagranych manifestów nie
ruszano). Kontrola: `python3 tools/voice_lines.py missing` (dziś: 265 = 53 klucze × 5 języków, wszystkie z rozdziału 13).

## Rozdział 13 „Wiosenne porządki” (D-111) — 53 klucze × EN/PL/DE/FR/ES = 265 plików

| klucz | mówca | PL | EN |
|---|---|---|---|
| `job.ch13_01_balcony_boxes.line.1` | halina | Pelargonie przezimowały w piwnicy, synku. Kłódka też, tylko gorzej to zniosła. | The geraniums wintered in the cellar, son. So did the padlock, but it took it harder. |
| `job.ch13_01_balcony_boxes.line.2` | zosia | Komórka numer siedem, Halinki. Moja jest obok, od czterdziestu lat. | Storage number seven is Halina's. Mine has been next to it for forty years. |
| `job.ch13_01_balcony_boxes.line.3` | locksmith | Wykaz się zgadza. Sto pięćdziesiąt monet i pelargonie wracają na słońce. | The list checks out. One hundred and fifty coins, and the geraniums go back in the sun. |
| `job.ch13_01_balcony_boxes.line.4` | halina | Zgoda. Zosia poniesie konewkę, a ja zapraszam pana na rosół. | Agreed. Zosia will carry the watering can, and I'll have you over for broth. |
| `job.ch13_01_balcony_boxes.after.1` | halina | Pelargonie stoją na balkonie. Zosia mówi, że krzywo, więc rosną po mojemu. | The geraniums are on the balcony. Zosia says they're crooked, so they're growing my way. |
| `job.ch13_02_first_ice_cream.line.1` | stefan | Lody przyjechały, kluczyk nie. Zimował lepiej ode mnie, bo do dziś nie wrócił. | The ice cream is here, the key isn't. It had a better winter than me; it still hasn't come back. |
| `job.ch13_02_first_ice_cream.line.2` | krysia | To jego zamrażarka. Od maja do września stoję przy niej codziennie. | It's his freezer. From May to September I stand next to it every day. |
| `job.ch13_02_first_ice_cream.line.3` | locksmith | Faktura pasuje. Sto pięćdziesiąt pięć monet, zanim lody zmiękną. | The invoice matches. One hundred and fifty-five coins, before the ice cream goes soft. |
| `job.ch13_02_first_ice_cream.line.4` | stefan | Zgoda. Pierwszy rożek jest dla pani Krysi, drugi dla pana. | Agreed. The first cone goes to Mrs Krysia, the second to you. |
| `job.ch13_02_first_ice_cream.after.1` | krysia | Śmietankowe, jak co roku. Stefan przywiązał kluczyk do zamrażarki sznurkiem. | Vanilla, same as every year. Stefan has tied the key to the freezer with string. |
| `job.ch13_03_allotment_gate.line.1` | zbyszek | Sezon zaczyna się dziś, a brama myśli, że jeszcze jest zima. | The season starts today, and the gate thinks it's still winter. |
| `job.ch13_03_allotment_gate.line.2` | waldek | Klucz zimował w mojej altanie. Altana jest za bramą. Sam to wymyśliłem. | The key spent the winter in my shed. The shed is behind the gate. My own idea. |
| `job.ch13_03_allotment_gate.line.3` | locksmith | Uchwała zarządu jest. Sto sześćdziesiąt monet, otwieram przy panach. | The board's resolution is here. One hundred and sixty coins, and I open it with you both present. |
| `job.ch13_03_allotment_gate.line.4` | zbyszek | Zgoda. Rozsada pomidorów czeka w bagażniku i się niecierpliwi. | Agreed. The tomato seedlings are waiting in the trunk, and they're getting impatient. |
| `job.ch13_03_allotment_gate.after.1` | zbyszek | Brama otwarta, pomidory w ziemi. Waldek nosi teraz klucz na szyi. | The gate is open and the tomatoes are in the ground. Waldek wears the key around his neck now. |
| `job.refuse_ch13_04_winter_bike.line.1` | marek | Stoi tu od listopada. Jak nikt nie rusza, to znaczy, że niczyj. | It's been here since November. If nobody touches it, it's nobody's. |
| `job.refuse_ch13_04_winter_bike.line.2` | locksmith | Może czyjś, tylko cierpliwy. Zapytajmy pana Romana, on zna ten stojak. | Or somebody's, and patient. Let's ask Mr Roman; he knows this stand. |
| `job.refuse_ch13_04_winter_bike.line.3` | marek | Po co zaraz administrator. Zdejmie pan kłódkę i po sprawie. | No need to drag the manager into it. Take the lock off and we're done. |
| `job.refuse_ch13_04_winter_bike.line.4` | locksmith | Tu nie otworzę. Pan Roman powiesi na nim kartkę. Kto tęskni, ten się odezwie. | I can't open this one. Mr Roman will tag it with a notice. Whoever misses it will speak up. |
| `job.refuse_ch13_04_winter_bike.after.1` | roman | Kartka wisiała trzy dni. Rower jest pani Teresy, zimą miała nogę w gipsie. | The notice was up for three days. The bicycle is Mrs Teresa's; her leg was in a cast all winter. |
| `job.refuse_ch13_04_winter_bike.after.2` | teresa | Już jeżdżę. Dobrze, że kłódka trafiła na rozsądnego człowieka. | I'm riding again. A good thing the lock met a sensible man. |
| `job.ch13_05_planted_key.line.1` | hania | Zasadziłam klucz. Podlewam go codziennie, ale jeszcze nic nie wyrosło. | I planted the key. I water it every day, but nothing has come up yet. |
| `job.ch13_05_planted_key.line.2` | tomasz | Skrzynka jest Hani, sam ją zrobiłem. Klucz jest gdzieś pod rzodkiewką. | The box is Hania's; I made it myself. The key is somewhere under the radishes. |
| `job.ch13_05_planted_key.line.3` | locksmith | Zdjęcie i słowo taty mi wystarczą. Sto czterdzieści monet, a grządka zostaje w spokoju. | The photo and your dad's word will do. One hundred and forty coins, and the garden bed stays undisturbed. |
| `job.ch13_05_planted_key.line.4` | hania | Zgoda. Nasiona idą jutro do szkoły, a klucz niech sobie rośnie. | Agreed. The seeds go to school tomorrow, and the key can keep growing. |
| `job.ch13_05_planted_key.after.1` | hania | Rzodkiewka wyrosła, klucz nie. Tata zrobił nowy i nie pozwala go podlewać. | The radishes came up, the key didn't. Dad made a new one and won't let me water it. |
| `job.ch13_06_bike_repair_stand.line.1` | borys | Pompka, klucze, łatki. Wszystko gotowe, tylko szafka nie chce współpracować. | Pump, wrenches, patches. Everything is ready; only the cabinet won't cooperate. |
| `job.ch13_06_bike_repair_stand.line.2` | roman | Szafka administracji. Borys ma ją wyposażyć, jest w zleceniu. | The cabinet belongs to the estate office. Borys is to stock it; it's in the order. |
| `job.ch13_06_bike_repair_stand.line.3` | locksmith | Potwierdzenie się zgadza. Sto siedemdziesiąt monet. | The confirmation checks out. One hundred and seventy coins. |
| `job.ch13_06_bike_repair_stand.line.4` | borys | Zgoda. Pierwsze pompowanie ma pan u mnie za darmo. | Agreed. Your first pump-up is on the house. |
| `job.ch13_06_bike_repair_stand.after.1` | kuba | Napompowałem koła przed pracą. Pierwszy raz byłem gdzieś przed czasem. | I pumped up my tires before work. For the first time I got somewhere early. |
| `job.ch13_07_museum_night_case.line.1` | rygiel | Klucz jest bezpieczny. Leży w gablocie, którą miał otwierać. | The key is safe. It is lying in the display case it was meant to open. |
| `job.ch13_07_museum_night_case.line.2` | locksmith | Pismo dyrekcji sprawdzone. Sto osiemdziesiąt monet, pracuję w rękawiczkach. | The directorate's letter checks out. One hundred and eighty coins, and I'll work in gloves. |
| `job.ch13_07_museum_night_case.line.3` | zuzanna | To ja go tam położyłam. Na aksamicie wyglądał jak eksponat. | I put it there. On the velvet it looked like an exhibit. |
| `job.ch13_07_museum_night_case.line.4` | rygiel | Zgoda. Zuzanna dopisze klucz do protokołu, ale nie do wystawy. | Agreed. Zuzanna will add the key to the record, but not to the exhibition. |
| `job.ch13_07_museum_night_case.after.1` | zuzanna | Przyszło czterysta osób. Klucz ma teraz własną smycz i numer w inwentarzu. | Four hundred people came. The key now has its own lanyard and an inventory number. |
| `job.refuse_ch13_08_found_cashbox.line.1` | oskar | Stała za starym kredensem. Znalezione nie kradzione, prawda? | It was behind an old dresser. Finders keepers, right? |
| `job.refuse_ch13_08_found_cashbox.line.2` | locksmith | Znalezione jest dalej czyjeś. Zanieśmy ją do pani Elżbiety. | Found things still belong to someone. Let's take it to Elżbieta. |
| `job.refuse_ch13_08_found_cashbox.line.3` | oskar | A jeśli w środku jest skarb? Najpierw zajrzyjmy, potem się powie. | What if there's treasure inside? Let's look first and tell them after. |
| `job.refuse_ch13_08_found_cashbox.line.4` | locksmith | Tu nie otworzę. Pani Elżbieta wywiesi ogłoszenie i właściciel się znajdzie. | I can't open this one. Elżbieta will post a notice, and the owner will turn up. |
| `job.refuse_ch13_08_found_cashbox.after.1` | elzbieta | Kasetka jest pani Janki, szukała jej od przeprowadzki. W środku były zdjęcia ślubne. | The cashbox is Mrs Janka's; she'd been looking for it since she moved. Her wedding photos were inside. |
| `job.refuse_ch13_08_found_cashbox.after.2` | oskar | Dostałem znaleźne: słoik ogórków i tytuł uczciwego znalazcy. | I got a finder's reward: a jar of pickles and the title of honest finder. |
| `job.ch13_09_pizzeria_terrace.line.1` | renata | Zimą zmieniłam kod na łatwiejszy. Tak łatwy, że od razu wyleciał mi z głowy. | In winter I changed the code to an easier one. So easy it slipped my mind at once. |
| `job.ch13_09_pizzeria_terrace.line.2` | mietek | Sejf jest jej, sam go z nią wnosiłem. Krzyż pamięta to do dziś. | The safe is hers; I helped her carry it in. My back remembers it to this day. |
| `job.ch13_09_pizzeria_terrace.line.3` | locksmith | Umowa i faktura pasują. Sto osiemdziesiąt pięć monet. | The lease and the invoice match. One hundred and eighty-five coins. |
| `job.ch13_09_pizzeria_terrace.line.4` | renata | Zgoda. Tym razem płacę monetami, a pizzę dostanie pan na dokładkę. | Agreed. This time I'm paying in coins, and the pizza comes on top. |
| `job.ch13_09_pizzeria_terrace.after.1` | renata | Ogródek pełny od pierwszego wieczoru. Nowy kod zna też pan Mietek, na wszelki wypadek. | The terrace has been full since the first evening. Mr Mietek knows the new code too, just in case. |
| `job.ch13_10_courtyard_door.line.1` | elzbieta | Uchwała jest jednogłośna. Te drzwi otworzą się pierwszy raz od trzydziestu lat. | The resolution was unanimous. This door will open for the first time in thirty years. |
| `job.ch13_10_courtyard_door.line.2` | halina | Stół się w sali nie mieści, synku. Zaprosiłam trochę więcej gości. | The table won't fit in the room, son. I invited a few more guests. |
| `job.ch13_10_courtyard_door.line.3` | locksmith | Zgoda wspólnoty jest. Dwieście monet i trochę cierpliwości dla starego zamka. | The residents' consent is here. Two hundred coins, and a little patience for an old lock. |
| `job.ch13_10_courtyard_door.line.4` | elzbieta | Zgoda. Marta już powiesiła plakat: stół zaczyna się w sali, a kończy pod lipą. | Agreed. Marta has already put up the poster: the table starts in the room and ends under the linden tree. |
| `job.ch13_10_courtyard_door.after.1` | halina | Stół sięgał aż pod lipę. Rosołu wystarczyło, bo gotowałam w dwóch garnkach. | The table reached all the way to the linden tree. There was enough broth; I cooked it in two pots. |
| `job.ch13_10_courtyard_door.after.2` | locksmith | Drzwi na podwórko zostają otwarte do jesieni. Nowy klucz wisi w świetlicy, podpisany. | The courtyard door stays open until autumn. The new key hangs in the common room, labeled. |

Razem: **53** kluczy.
