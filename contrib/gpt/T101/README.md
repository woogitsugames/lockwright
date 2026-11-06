# T101 — scenariusze reakcji bez słów

`reactions.csv` zawiera 96 propozycji (12 postaci × 8 typów) dla osób z `game/data/voice_cast.json`, dla których w drzewie Git `game/assets/audio/voices/` nie znaleziono żadnego pliku reakcji WAV/OGG. Każdy wiersz łączy osobny scenariusz dźwięku z charakterem głosu postaci; typy odpowiadają `tools/import_episodic_voices.py`: `greeting`, `surprise`, `relief`, `thanks`, `impatient`, `sad`, `laugh`, `goodbye`. To scenariusze do reżyserii, nie nagrania.

Identyfikatory: alicja, borys, celina, dorota, janka, karol, leon, locksmith, mila, oskar, pawel, seweryn. Uwzględniono ślusarza, bo jest w obsadzie i mówi w zleceniach; decyzja o używaniu jego wokalizacji pozostaje otwarta. `ola` i `krystyna` korzystają ze wspólnego katalogu `ola_krystyna` zgodnie z `Sfx.VOICE_DIR`, więc nie zostały błędnie uznane za brakujące. Audyt sprawdza obecność plików w Git, nie jakość, treść bez słów ani kompletność poszczególnych emocji dla pozostałych osób.

Nie podano ID głosów ani nie wygenerowano audio. Przed realizacją zachować ciągłość z zatwierdzoną obsadą, dopasować głośność do istniejącej ścieżki Voice, sprawdzić naturalność; dźwięki nie powinny zachodzić na kwestię tej samej postaci (`contrib/voice/INTEGRATION.md`). Obecny `job_arrival.gd` korzysta z bezsłownego powitania jako fallbacku, więc szersze użycie emocji wymaga osobnej integracji. Stan `b50ea45`.
