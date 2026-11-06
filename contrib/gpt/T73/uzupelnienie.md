# T73 — format i walidacja

Istniejące `verification_variants.csv` zawiera 30 par (15 kart po dwie); `verification_i18n.csv` przedstawia te same kwestie w żądanym formacie `keys,en,pl,de,fr,es`, po dwa klucze na parę. FR/ES celowo puste. Klucze `verify.extra.*` są propozycją do integracji, nie są wykorzystywane przez grę. Jedyna korekta treści: amerykańska pisownia `neighbor` zamiast `neighbour` w EN (przy pytaniu i odpowiedzi). `convert_i18n.py` odtwarza plik z wersji HEAD.

Przed integracją trzeba dopasować formę i kontekst do zlecenia: „pan/pani” i odpowiedzi nie są neutralne płciowo. Odpowiedź lub dokument nie stanowią automatycznego dowodu prawa wejścia. Różnica merytoryczna i integracja w mechanizmie pozostają do sprawdzenia przez zespół gry.

Walidacja: 60 różnych kluczy, dla każdej z 15 kart dwa pytania i dwie odpowiedzi. `tools/i18n_lint.py` na tymczasowej kopii obu CSV z dopisanymi kluczami: **0 błędów, 4 ostrzeżenia**. Dwa ostrzeżenia dotyczą 60 celowo pustych FR/ES, dwa istniejących identycznych wartości `settings.voice_pack.line`. Kopia nie zawierała skryptów gry, więc sprawdzenie odwołań z kodu nie było częścią tego wyniku.
