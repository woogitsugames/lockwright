# G12 v2 — rejestr zasobów / Asset register

**Data wytworzenia:** 2026-11-05  
**AI:** natywny generator obrazów ChatGPT (OpenAI), identyfikator źródłowego obrazu `17f6bd77-acce-4ab7-9531-f29e1d3568b5`  
**Postprocessing:** Python 3, Pillow, NumPy, OpenCV; własny skrypt `build_assets.py`  
**Licencja / warunki:** obraz wygenerowany na zlecenie użytkownika; wykorzystanie wyjścia regulują warunki OpenAI. Nie użyto zewnętrznych fotografii, logotypów lub bibliotek stockowych. Nie deklarowano CC0 ani wyłączności praw. Kod wytworzono na potrzeby użytkownika.

## Pełny brief źródłowy / Full generation brief

> Poprawka G12-v2: przygotuj cztery fotorealistyczne zdjęciowe projekty ikon do spokojnej, realistycznej, premium gry mobilnej Lockwright: (1) stara emaliowana tabliczka w kolorze kości słoniowej z dużą granatową literą „L” i śladami obtłuczeń; (2) front mosiężnej wkładki o satynowym połysku i śladach obróbki, bez narzędzi; (3) zamknięta, zwinięta brązowa skórzana zwijka rzemieślnika ze szwami i mosiężną napą; (4) pojedynczy stary, wymyślony klucz leżący na zużytej skórze. Jeden główny przedmiot w każdym kadrze, w przyjaznym wnętrzu starej kamienicy/warsztatu. Miękkie ciepłe światło z góry z lewej, subtelne chłodne wypełnienie. Wysoka wiarygodność materiałów: emalia, drewno, mosiądz i skóra, ślady dotyku i zużycia. Bez marek, logotypów, nazw producentów, scen używania narzędzi przy zamkach. Bez neonów, nadmiernego blasku, chromu, estetyki komiksowej, złotej kłódki, dziurki od klucza na czerni i stereotypów przestępczych. Duża sylwetka, czytelna po zmniejszeniu do 48 px. Materiał do eksportu jako cztery ikony 1024×1024 i Android adaptive 432×432 z przezroczystą warstwą pierwszego planu.

**Dokładność opisu wejścia:** natywny generator nie zwrócił tekstu rozwiniętego wewnętrznego promptu (w metadanych `prompt` jest pusty). Powyższy brief stanowi pełny opis dyspozycji użytkownika i kontekstu `G12-v2.md` oraz `docs/handoff/gpt/G12-app-icon.md` i dokumentów projektowych, którymi kierowano generowanie. Nie przedstawia się go jako dosłownego promptu modelu wygenerowanego wewnętrznie. Wynik narzędzia był jedną planszą porównawczą 1536×1024.

## Warianty, pliki, metody i modyfikacje

Zapis bazowy dla każdego wariantu: data 2026-11-05; generator obrazu ChatGPT jako źródło fotograficzne; crop 354×354; PIL Lanczos do iOS; ręcznie definiowana alfa przedmiotu (przy wariancie 04 wspomagana OpenCV GrabCut) do Androida; proceduralne tło Androida; previews z PIL; bez ręcznego retuszu pikselowego.

### 01 — Tabliczka emaliowana „L” / Enamel L plate

**Prompt szczegółowy:** „Fotografia pojedynczej starej tabliczki emaliowanej w kolorze kości słoniowej z dużym, granatowym szeryfowym L, cztery ciemne śruby i drobne odpryski na brzegach. Osadzona na prawdziwym drewnie, kadrowana niemal na cały kwadrat. Miękkie ciepłe światło z lewej góry. Bez oznaczeń firmowych, rysunkowości i poświat.”

**Pliki:** `sources/01_enamel_l_source_354.png`, `ios/01_enamel_l_1024.png`, `android/01_enamel_l_foreground_432.png`, `android/01_enamel_l_background_432.png`, `previews/01_enamel_l_light_dark_sizes.png`.

**Edytowany:** tak; kadrowanie, skalowanie, ręczna maska zaokrąglonej tabliczki, tło z NumPy, cienie, miniatury.

### 02 — Czoło wkładki / Brass cylinder face

**Prompt szczegółowy:** „Fotorealistyczne czoło mosiężnej wkładki wymyślonego mechanizmu, satynowe powierzchnie, drobne ślady toczenia i zużycia, jedna duża kolista tarcza z ciemnym centralnym otworem. Bez marki, bez klucza, bez narzędzi, bez blasku. Ciepły studyjny softbox z lewej góry, spokojny warsztatowy ton.”

**Pliki:** `sources/02_brass_cylinder_source_354.png`, `ios/02_brass_cylinder_1024.png`, `android/02_brass_cylinder_foreground_432.png`, `android/02_brass_cylinder_background_432.png`, `previews/02_brass_cylinder_light_dark_sizes.png`.

**Edytowany:** tak; kadrowanie, skalowanie, na Androidzie wyodrębniono tylko koliste czoło bez pionowej części korpusu, proced. tło, miniatury.

### 03 — Skórzana zwijka / Closed leather tool roll

**Prompt szczegółowy:** „Jedna zamknięta, zwinięta brązowa skórzana zwijka rzemieślnicza z drobnymi szwami i pojedynczą satynową mosiężną napą. Wiarygodne ziarno skóry, zagięcia i przetarcia. Leży ukośnie na ciemnym drewnie warsztatowym, ciepłe miękkie światło z lewej góry, brak widocznych narzędzi i logo.”

**Pliki:** `sources/03_leather_roll_source_354.png`, `ios/03_leather_roll_1024.png`, `android/03_leather_roll_foreground_432.png`, `android/03_leather_roll_background_432.png`, `previews/03_leather_roll_light_dark_sizes.png`.

**Edytowany:** tak; kadrowanie, skalowanie, ręczna maska organiczna skórzanej sylwetki, proced. tło, miniatury.

### 04 — Stary klucz / Old key on leather

**Prompt szczegółowy:** „Pojedynczy stary klucz metalowy o wymyślonym profilu, leżący po przekątnej na zużytej brązowej skórze. Fotografia studyjna z lewej góry, matowy metal, odciski i przetarcia, bez marek, bez innych przedmiotów, bez połysku chromu. Mocna, rozpoznawalna sylwetka ma przetrwać w 48 px.”

**Pliki:** `sources/04_old_key_source_354.png`, `ios/04_old_key_1024.png`, `android/04_old_key_foreground_432.png`, `android/04_old_key_background_432.png`, `previews/04_old_key_light_dark_sizes.png`.

**Edytowany:** tak; kadrowanie, skalowanie, alfa izolowana przez OpenCV GrabCut z ręcznymi wskazówkami, tło proceduralne, miniatury.

## Pliki pomocnicze i pochodzenie

- `sources/native_imagegen_contact_sheet.png`: **oryginalny wynik generatora** 1536×1024 z czterema studiami na górze i dodatkowymi oznaczeniami w dolnej części; source ID powyżej; nieedytowany.
- `previews/contact_sheet_v2.png`: własna plansza porównawcza z miniaturami 48 i 29 px; narzędzie Pillow; pełny prompt składu: „Zestaw cztery zdjęciowe warianty obok siebie, podpisy PL/EN, miniatury w 48 i 29 px i rekomendacja wariantu 01”; edytowany / składany: tak.
- `previews/android_adaptive_round_mask.png`: test rozkładu obiektów w centralnej masce kołowej Androida na 432×432; narzędzie Pillow; prompt: „Pokazać cztery wyniki warstwa pierwszego planu na tle, ograniczone do kołowej maski o średnicy 288 px”; edytowany: tak.
- `previews/*_light_dark_sizes.png`: generowane Pillow; pełny prompt składu: „Dwa rzędy miniatur dokładnie 180, 120, 60, 48, 29 px tego samego źródłowego PNG, na jasnym i ciemnym tle, czytelne podpisy PL/EN”; edytowany: tak.
- `android/*_background_432.png`: proceduralne tła NumPy, własny kod na bazie oryginalnej palety kolorystycznej. Bez stocków; edytowany: tak.
- `build_assets.py`, `qa_manifest.json`, `requirements.txt`: skrypt, metryki plików i deklaracja środowiska, nie są osobnymi zdjęciami.

**Warunki i ograniczenie:** z natywnego zdjęciowego generatora otrzymano kadry o rzeczywistej szerokości 354 piksele, dlatego PNG 1024×1024 to eksporty po upscale; patrz `README.md`. Nie deklarujemy natywnego fotodetalu 1024×1024 ani pozytywnych wyników badań użytkowników.
