# Dalsze propozycje po przeglądzie

Propozycje dotyczą istniejących kluczy `game/i18n/content.csv`. Puste kolumny oznaczają brak zmiany. Nie dodawać tych kluczy do pliku po raz drugi; zastosowanie wymaga nadpisania odpowiednich komórek na kopii i decyzji integratora.

| Klucz | Język | Było | Jest | Powód |
|---|---|---|---|---|
| job.bike_interview.line.3 | en | A holiday photo and the receipt in my email. The bike looks better than I do. | A vacation photo and the receipt in my email. The bike looks better than I do. | Amerykańskie „vacation”. |
| job.cat_bathroom.note | en | Potato the cat. Marta was home; no check needed. He didn't apologise. She promised a new sign. | Potato the cat. Marta was home; no check needed. He didn't apologize. She promised a new sign. | Pisownia amerykańska. |
| job.grandpa_chest.line.2 | en | Mum, he's not asking about the chest. He's asking if the house is yours. | Mom, he's not asking about the chest. He's asking if the house is yours. | Amerykańskie „Mom”. |
| job.liege_bakery.line.1 | en | My uncle had thirty keys and labelled none of them. | My uncle had thirty keys and labeled none of them. | Pisownia amerykańska. |
| job.liege_bakery.line.2 | en | The lock felt the wrong key and took offence. Can't fault it for that. | The lock felt the wrong key and took offense. Can't fault it for that. | Pisownia amerykańska. |
| job.night_nurse.line.2 | en | Mrs Agnieszka, flat fourteen, that's right. I've got her lease on the system. | Mrs Agnieszka, apartment fourteen, that's right. I've got her lease on the system. | Amerykańskie „apartment”. |
| job.refuse_rush_bribe.line.3 | en | She's not answering. Let's not wake the neighbours. No need for a circus. | She's not answering. Let's not wake the neighbors. No need for a circus. | Pisownia amerykańska. |
| job.krystyna_wooden_album.line.2 | en | We have a photo of him holding it. And the box is at Mum's. | We have a photo of him holding it. And the box is at Mom's. | Amerykańskie „Mom”. |
| job.refuse_sisters_flat.line.3 | en | I'd rather not involve the neighbours. They're only flowers. | I'd rather not involve the neighbors. They're only flowers. | Pisownia amerykańska. |
| job.refuse_sisters_flat.note | en | Didn't open Norbert's sister's flat. No tenant consent. Gave him the manager's number. | Didn't open Norbert's sister's apartment. No tenant consent. Gave him the manager's number. | Amerykańskie „apartment”. |
| job.shared_room_door.line.1 | en | Signed decision and the authorised residents' list. These are shared doors. | Signed decision and the authorized residents' list. These are shared doors. | Pisownia amerykańska. |
| job.grandma_broth.line.3 | pl | To mi wystarczy za papiery. List w skrzynce też jest na panią? | To pomaga. List w skrzynce też jest na panią? | Zeznanie sąsiadki pomaga w weryfikacji; oryginał EN nie stwierdza, że zastępuje dokumenty. |
| job.newlyweds_4am.line.1 | pl | Dowód mam, ale adresu na nim nie ma. Wiem, wiem. Teraz nikt nie ma. | Dowód mam, ale adresu na nim nie ma. Wiem, wiem. Teraz w dowodach nie ma adresu. | Dopowiada, że chodzi o brak adresu w dowodach, a nie o ludzi. |

Walidacja: `python tools/i18n_lint.py` na kopii po nałożeniu istniejącej dostawy, uzupełnienia i tego CSV sprawdził 948 kluczy: 0 błędów, 2 istniejące ostrzeżenia, kod 0. Kopia pochodzi ze sparse checkoutu bez skryptów `.gd` (choć drzewo HEAD zawiera 203 takie skrypty), więc kontrola odwołań z kodu nie była kompletna. Wynik nie sprawdza wymowy ani odtwarzania.
