# Kwestie do ponownego nagrania (zmiana słów po nagraniu)

Lista kluczy `*.line.N` z `game/i18n/content.csv`, w których po nagraniu (D-57; PL/EN/DE w `game/assets/audio/lines/`) zmieniły się **słowa**. Same zmiany pisowni (np. EN brytyjska → amerykańska: *neighbour → neighbor*) i interpunkcji nie wymagają nagrania. Po nagraniu: `tools/voice_lines.py tts-payload --jobs <id> --lang <lang>` → `finish`, potem usuń wiersz z tej listy.

| klucz | język | było (nagrane) | jest (napis) | źródło |
|---|---|---|---|---|
| `job.night_nurse.line.2` | pl | „Pani Agnieszka spod czternastki, zgadza się. …” | „Pani Agnieszka spod piątki, zgadza się. …” | N-81 / D-91: drzwi nr 5 na zdjęciu G07 (noc) |
| `job.night_nurse.line.2` | en | „Mrs Agnieszka, flat fourteen, that's right. …” | „Mrs Agnieszka, flat five, that's right. …” | N-81 / D-91: drzwi nr 5 na zdjęciu G07 (noc) |
| `job.night_nurse.line.2` | de | „Frau Agnieszka, Wohnung vierzehn, stimmt. …” | „Frau Agnieszka, Wohnung fünf, stimmt. …” | N-81 / D-91: drzwi nr 5 na zdjęciu G07 (noc) |
| `job.night_nurse.line.2` | fr | „Madame Agnieszka, appartement quatorze. …” | „Madame Agnieszka, appartement cinq. …” | N-81 / D-91: drzwi nr 5 na zdjęciu G07 (noc) |
| `job.night_nurse.line.2` | es | „La señora Agnieszka, piso catorce. …” | „La señora Agnieszka, piso cinco. …” | N-81 / D-91: drzwi nr 5 na zdjęciu G07 (noc) |

Razem: **5** plików (2026-11-08, N-81: `job.night_nurse.line.2` we wszystkich językach; PL/EN w grze, DE/FR/ES w paczkach głosów — do czasu nagrania napis mówi „piątka”, głos „czternastka”). Wcześniej: 0 — oba PL nagrane ponownie 2026-11-06 (tym samym głosem i seedem, wpis w `docs/ASSETS.md`). EN i DE bez zmian słów. Przegląd: `contrib/gpt/REVIEW-T44-T73.md`.

## Sprawdzone po fladze ASR, bez ponownego nagrania (2026-11-06)

Flagi z `contrib/voice/qa_ch8.json` (faster-whisper small) sprawdzone modelem **medium** (beam 5): wszystkie trzy pliki transkrybują się dokładnie jak napis, więc to błędy małego modelu, nie lektora.

| plik | small | medium |
|---|---|---|
| `pl/job.heating_service_cupboard.line.4.ogg` | „Cóż nie, jedna zimna zagadka naraz.” | „Słusznie. Jedna zimna zagadka na raz.” |
| `pl/job.warm_room_for_neighbours.line.3.ogg` | „Prawowe iść potwierdzone…” | „Prawo wejścia potwierdzone. Cena zostaje taka, jak ustaliliśmy.” |
| `de/job.halina_christmas_tin.line.2.ogg` | „…als CC-Abschluss.” | „…als sie sie abschloss.” |

## Kwestie „dzień po” po polsku z wymową do poprawy (D-78, 2026-11-07)

Nagrane (455 plików, PL/EN/DE/FR/ES), ale ASR (faster-whisper small, potwierdzone modelem **medium**, beam 5) słyszy w 26 kwestiach PL zniekształcone ł/ś/ą/ę („Płaszcze” → „Poaszcze”, „Słyszałem” → „Sojszałem”, „są” → „se”). Ponowne próby (seed 101 i model zapasowy `eleven_v4`, inne ustawienia głosu) dały to samo — to **zmiana modelu po stronie ElevenLabs**: identyczne zapytanie z 2026-11-05 dla `pl/job.kiosk_shutter.line.1` daje dziś „kółka” zamiast „kłódka” (plik w repo czyta się poprawnie). Pliki zostają w grze (napis zawsze widoczny); do ponownego nagrania, gdy właściciel zdecyduje (inny model, np. `eleven_multilingual_v2`, albo odsłuch i akceptacja). Szczegóły: `contrib/voice/qa_after_medium.json`.

| plik | napis | ASR medium | WER |
|---|---|---|---|
| `pl/job.allotment_shed.after.1.ogg` | Pomidory zdążyły do ziemi. Dziękują panu. | Pomidory zdeoczyłeś do ziemi, dziękuję panu. | 0.333 |
| `pl/job.attic_drying_room.after.1.ogg` | Płaszcze wyschły, chór zaśpiewał. Klucz do suszarni wisi teraz u pana Romana. | Poaszcze wyschły, chór zapiewa. Klucz do suszarni wisi teraz u pana Romana. | 0.167 |
| `pl/job.edek_rehearsal_store.after.1.ogg` | Krzesła są gotowe na zebranie. Policzyłem dwa razy. | Krzesa se gotowe na zebranie. Policzyłem dwa razy. | 0.25 |
| `pl/job.finnish_sailor.after.1.ogg` | Wypłynęliśmy na czas. Skrzynia jest już przywiązana. | Wypełnaliśmy na czas. Skrzynia jest już przywiezana. | 0.286 |
| `pl/job.grandpa_chest.after.1.ogg` | Pamiątki znów są razem. Listy też. | Pamiętki znów se razem. Listy też. | 0.333 |
| `pl/job.krakow_tenement_gate.after.1.ogg` | Brama znów służy mieszkańcom. Następny będzie dzwonek. | Brama znów słuchaczy mieszkacom. Następny będzie dzwonek. | 0.286 |
| `pl/job.night_nurse.after.1.ogg` | Spałam jedenaście godzin. Klucz od razu trafił do miseczki. | Spałam 11 godzin, klucz od razu trafi do miseczki. | 0.222 |
| `pl/job.refuse_aunt_alive.after.2.ogg` | Ulżyło mi, że pan odmówił. Ja bym nie spała. | Użyło mi, że Pan odmówi. Ja bym nie spała. | 0.222 |
| `pl/job.refuse_ex_partner.after.2.ogg` | Słyszałem na przystanku. Porządny z pana człowiek. Gazeta? | Soj szałem na przystanku, pożet nyspa na człowiek, gazeta? | 0.625 |
| `pl/job.refuse_t43_11_other_stall.after.1.ogg` | Oddałam przedłużacz organizatorowi. Sąsiadowi pożyczyłam czajnik. | Oddałam przedłuczacz organizatorowi. Sesiadowi poszłyczyłam czajnik. | 0.5 |
| `pl/job.refuse_wrong_letterbox.after.1.ogg` | Szesnastka oddała kartkę. Babcia Oskara dostała ją w drugi dzień świąt. | Szesnastka oddała kartkę. Babcia Oskara dostała je w drugi dzień wiedzy. | 0.182 |
| `pl/job.stefan_book_tin.after.1.ogg` | Numerki do wypożyczalni wróciły do obiegu. Pierwszy dostała Krysia. | Numerki do wypoczyczalni wrócił do obiegu. Pierwszy dostała Krysia. | 0.222 |
| `pl/job.student_dorm.after.1.ogg` | Zdążyłam na egzamin. Zamki historyczne na piątkę. | Zdeoszczujam na egzamin! Zamki historyczne na pietkę! | 0.286 |
| `pl/job.swiatniki_journeyman_padlock.after.1.ogg` | Kłódka ma jeszcze swoją historię. Teraz ma dwie. | Koczka ma jeszcze swoje historia, teraz ma dwie. | 0.375 |
| `pl/job.t43_09_03_wooden_postbox.after.1.ogg` | Ktoś napisał, że chciałby tam zamieszkać. Przekazuję tylko tyle. | Kto napisał, że chciałby tam zamieszkał? Przekazuję tylko tyle. | 0.222 |
| `pl/job.t43_09_05_receipt_safe.after.1.ogg` | Rachunek od pana dostał osobną przegródkę. | Rachunek od Pana dostało osobne przegródkę. | 0.333 |
| `pl/job.t43_10_02_scaffold_store.after.1.ogg` | Na odprawie był komplet. Łącznie z kluczem. | Na odprawie było komplet, ocznie z kluczem. | 0.286 |
| `pl/job.t43_10_04_design_cabinet.after.1.ogg` | Świetlica ma tabliczkę. Ziemniak chciał podpisać się łapą. | Owietlica ma tabliczkę, ziemniak chciał podpisać się apa. | 0.25 |
| `pl/job.t43_10_06_shared_room_entry.after.1.ogg` | Sala pachnie farbą. Herbata już próbuje wygrać. | Sala pachnie farbę. Herbata już próbuje wygra. | 0.286 |
| `pl/job.t43_11_02_bicycle_stand.after.1.ogg` | Borys naprawił mi dzwonek. Rower teraz pierwszy zaczyna rozmowę. | Boris naprawiał mi dzwonek. Rower teraz pierwszy zaczyna rozmowę. | 0.222 |
| `pl/job.t43_11_04_sailors_stall.after.1.ogg` | Pokaz się udał. Narzędzia wróciły ze mną, klucz jeszcze płynie. | Pokaz się udał, Narżędzia wróciła ze mne, klucz jeszcze pojnie. | 0.4 |
| `pl/job.t43_11_05_rehearsal_chest.after.1.ogg` | Słyszałem koncert. Znam tę perkusistkę, kiedyś zgubiła klucz. | Sojszalem koncert. Znam tę perkusistkę, kiedy zgubiała klucz. | 0.375 |
| `pl/job.t43_12_08_henryks_bench.after.2.ogg` | Zamknąłem warsztat. Klucz sprawdziłem przed wyjściem. | Zamknę mWarsztat. Klucz sprawdziłem przed wyjściem. | 0.333 |
| `pl/job.warm_room_for_neighbours.after.1.ogg` | Sąsiedzi przespali noc w cieple. Ziemniak obszedł wszystkie koce i żadnego nie zatwierdził. | Sasiedzi przespali noc w cieple, ziemniak oprzedał wszystkie koce i szładnego nie zatwierdzi. | 0.308 |
| `pl/job.winter_bicycle_cellar.after.1.ogg` | Ostatnia paczka dojechała trzydziestego pierwszego. Kłódka zimuje teraz pod pokrowcem. | Ostatnia paczka dojechała 31. Kółka zimuje teraz pod pokrowcem. | 0.3 |
| `pl/job.zuzanna_catalogue_drawer.after.1.ogg` | Kopie gotowe dla świetlicy. Oryginały zostają w szufladzie. | Kopie gotowe dla owietlicy. Oryginały zostaje w szufladzie. | 0.25 |
