# T124 — audyt rejestru zasobów

Na bazie danych main b50ea45 porównano listę plików śledzonych przez Git z parserem wpisów docs/ASSETS.md z tools/assets_lint.py. Zakres automatyczny: 2685 plików binarnych pod game/assets/ o rozszerzeniach rozpoznawanych przez lint; pliki .import i inne katalogi nie wchodzą do tego wyniku. Lista Git uwzględnia pliki także poza rzadkim checkoutem. Wynikiem jest 116 ścieżek niedopasowanych przez is_listed; pełna lista znajduje się w unmatched_assets.csv.

Wszystkie 116 to game/assets/arrival/wrong_floor/: 38 day, 38 evening i 40 night. Obejmują klatki seq oraz warstwy plate i figure. Rejestr opisuje powiązane rendery, kompozyty i pochodzenie postaci w sekcjach „Local GPU arrival and menu finals” i G23, ale nie zawiera czytelnego wpisu obejmującego te 116 ścieżek eksportu gry. Propozycja: dodać jednoznaczny wzorzec ścieżek wraz z narzędziem eksportu art/tools/arrival_export.py, pochodzeniem warstw, prawami i powiązaniem z G23. Sam brak dopasowania nie dowodzi braku praw.

## Kwestie do wyjaśnienia przed wydaniem

- Rejestr sam odnotowuje przy game/addons/gut/fonts/* brak not copyright dla Courier Prime i Lobster Two w lokalnym OFL.txt. Sprawdzić komplet licencji i sposób dystrybucji; deklaracja wyłączenia z eksportu nie zastępuje przeglądu paczki.
- Ogólny wpis portretów epizodycznych wskazuje Magnific, natomiast późniejsze wpisy G21/G24 i osobny wpis dyrektorki wskazują różne źródła i przetworzenia. Utrzymać rozróżnienie per zasób i potwierdzić, że wskazane prompty oraz warunki obejmują użycie w grze. Nie oceniano tu treści bieżących umów dostawców.
- Rejestr opisuje płatny plan ElevenLabs w chwili generacji jako potwierdzony przez właściciela. To zapis projektowy, a nie niezależnie zweryfikowany dowód warunków i zakresu wykorzystania. Zweryfikować dokumentację zamówienia i właściwych warunków dla wszystkich partii.

Ograniczenia: parser używa wzorców i może dopasować zbyt szeroki wpis, a przegląd praw był selektywny. Nie sprawdzono licencji każdego pliku poza game/assets ani aktualnego stanu kont dostawców. Lista wyników nie jest opinią prawną ani pełnym audytem licencyjnym.
