# Korekta kwestii przed nagraniem lektora (D-57)

2026-11-05 · sesja lektora AI. Sprawdzono wszystkie 164 kwestie `*.line.N` (PL i EN): gramatyka, rejestr mówiony, interpunkcja pod prozodię TTS, formy pan/pani/państwo, termin „pin” (w kwestiach nie występuje ani „pin”, ani „kołek”), ciepły i legalny ton. Zmieniono tylko kolumny `en`/`pl` wierszy `*.line.N`; DE bez zmian.

Liczby w kwestiach (np. „pokój 412”, „’94”) zostają w napisach cyframi; dla lektora `tools/voice_lines.py` podaje zapis słowny (`TTS_OVERRIDES`), żeby uniknąć błędnej odmiany.

| klucz | kol. | było | jest | powód |
|---|---|---|---|---|
| `job.bike_interview.line.2` | pl | Rower stoi na ulicy. Ma pan coś, co mówi, że jest pana? | Rower stoi na ulicy. Ma pan coś, co potwierdza, że jest pana? | kalka z ang. „says”; naturalniej „potwierdza” |
| `job.charleroi_letters.line.4` | pl | Obie chcecie, żeby się otworzyła. Najprostsza weryfikacja w mojej karierze. | Obie panie chcą, żeby się otworzyła. Najprostsza weryfikacja w mojej karierze. | ślusarz zwraca się do klientek per pani (spójność form) |
| `job.finnish_sailor.line.3` | pl | Kapitan ręczy, książeczka żeglarska się zgadza. To zobaczymy. | Kapitan ręczy, książeczka żeglarska się zgadza. Zobaczmy. | „To zobaczymy” brzmi jak powątpiewanie; EN: „Let’s have a look” |
| `job.grandpa_chest.line.1` | pl | Tato nigdy nie mówił, co tam trzyma. Nawet nam. | Tata nigdy nie mówił, co tam trzyma. Nawet nam. | „tato” to wołacz; w mianowniku „tata” |
| `job.liege_bakery.line.4` | pl | Papiery wystarczą. Gofry o szóstej będą. | Papiery wystarczą. O szóstej liczę na gofry. | szyk niejasny (kto obiecuje?); zgodnie z EN |
| `job.newlyweds_4am.line.4` | pl | Wszystkiego najlepszego. Dwie minuty i jesteście w domu. | Wszystkiego najlepszego. Dwie minuty i są państwo w domu. | do pary klientów: forma „państwo”, jak w całej grze |
| `job.refuse_ex_partner.line.4` | pl | Tu nie otworzę. Policja pomaga odebrać rzeczy, spokojnie. Zadzwonić? | Tu nie otworzę. Spokojnie, policja może pomóc odebrać rzeczy. Zadzwonić? | ton: propozycja zamiast stwierdzenia; „spokojnie” na początku lepiej dla intonacji |
| `job.zuzanna_catalogue_drawer.line.4` | pl | Podpiszę wystawę „Obchodzić się ostrożnie”. Od tej szuflady zacznę. | Na wystawie dam napis „Obchodzić się ostrożnie”. Zacznę od tej szuflady. | „podpisać wystawę” to błąd znaczeniowy (chodzi o napis/etykietę) |
| `job.newlyweds_4am.line.1` | en | I've got ID, but no address on it. I know. Nobody's does these days. | I've got ID, but no address on it. I know. Nobody's ID does these days. | niejasny elipsa „Nobody’s does”; TTS czytał to niezręcznie |
| `job.night_nurse.line.2` | en | Mrs Agnieszka, flat fourteen, that's right. I've got her tenancy details on the building system. | Mrs Agnieszka, flat fourteen, that's right. I've got her lease on the system. | zbyt długie i urzędowe jak na mówioną kwestię; PL: „Umowę mam w systemie” |
