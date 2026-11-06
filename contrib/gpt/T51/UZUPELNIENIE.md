# T51 — uzupełnienie kontroli nazw i obsady

Podstawa: `game/i18n/content.csv`, 41 plików `game/data/jobs*/*.json`, `contrib/voice/CAST.md`, `game/data/voice_cast.json` i fragmenty `docs/CLIENTS.md`; stan bazowy `5cfc4194eb77839a9ca507a76174075b9b879c1f`. Niniejszy plik uzupełnia istniejący raport T51, nie zastępuje go. Przegląd pozostaje częściowy: nie zestawiono wszystkich adresów, odmian imion ani każdego głosu z każdym zdaniem we wszystkich językach.

| Priorytet | Dowód | Ustalenie i działanie |
|---|---|---|
| Średni | `job.community_notice_case.json` i `job.shared_room_door.json` mają `district: Śródmieście`. W `content.csv` odpowiednie `.note` podają EN „Old Town”, FR „Vieille Ville”, ES „Casco antiguo”, a PL „Śródmieście”; DE powtarza tekst EN. | Dwa dalsze wystąpienia rozbieżności zgłoszonej wcześniej dla Haliny. Te przekłady sugerują Stare Miasto; jeśli dzielnice są odrębne, trzeba uzgodnić jedną nazwę we wszystkich wersjach. Najpierw ustalić oficjalne tłumaczenie nazwy dzielnicy — sam JSON nie rozstrzyga, czy „Old Town” jest jej przyjętą lokalizacją. |
| Średni | `job.refuse_aunt_alive.note`: FR „Le voisin” wobec PL „Sąsiadka”, DE „Die Nachbarin”, ES „La vecina”; `CAST.md` identyfikuje `neighbour_lucyna` jako kobietę i JSON przypisuje jej kwestię w scenie. | Francuska notatka zmienia płeć sąsiadki; propozycja „La voisine est arrivée à temps”. Uzgodnić przy integracji z resztą zdania. |
| Niski | `job.edek_rehearsal_store.client`: PL „portier akademika”, EN/FR/ES „portier kampusu”; `CAST.md` i `docs/CLIENTS.md` opisują Edka jako portiera akademika. | To może być szerszy opis miejsca jego pracy, a nie sprzeczność. Potwierdzić zakres obowiązków Edka i ujednolicić określenie, jeśli ma jedno konkretne stanowisko. |

Kontrola struktury: z 41 plików zleceń zebrano 52 różne identyfikatory mówców w `lines`. Każdy ma klucz `cast.<id>.name` w `content.csv` i wpis w `game/data/voice_cast.json`. To kontrola obecności, a nie potwierdzenie przypisania właściwego głosu, wieku ani płci w nagraniach. Wszystkie linie PL zestawiono z identyfikatorami mówców; nie jest to pełna redakcyjna ocena każdej sceny w pięciu językach.
