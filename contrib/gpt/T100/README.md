# T100 — tagi głosowe rozdziałów 7–8

`tags.json` to słownik `klucz: "[tag]"` w formacie `contrib/voice/tags.json`; zawiera 96 kwestii z pól `lines` 24 zleceń rozdziałów 7–8. Zachowano 53 tagów już istniejących w pliku produkcyjnym; pozostałe wybrano według kontekstu polskiej kwestii i charakteru sceny. Neutralny, powściągliwy ton ślusarza i rzeczowe odmowy są celowe. Nie włączono scen `after`, które nie są inwentaryzowane przez `tools/voice_lines.py`.

To propozycja do scalenia z `contrib/voice/tags.json`, a nie plik zastępujący całość: zastąpienie nim usuwa tagi pozostałych rozdziałów. Tagi mogą być różnie interpretowane przez model i wymagają przesłuchania pięciu języków, zwłaszcza śmiechu i tonu odmowy; nie generowano nagrań, nie sprawdzano działania u dostawcy. Teksty kwestii nie są zmienione; tagi służą tylko wejściu TTS. Stan źródeł `b50ea45`.
