# Zlecenie G26: dłonie do „widma” v2 (sylwetka czytelna jako płaska wycinanka)

**Dla:** ChatGPT z generatorem obrazów. Zapis tylko do `contrib/gpt/G26/` (albo ZIP `Lockwright_G26.zip` dla właściciela). Zastępuje G23 część C (D-77).

## Dlaczego poprawka
Od D-77 gra rysuje dłoń jako **płaską wycinankę z papieru**: jednolite jasne wypełnienie + ciemna krawędź 2 dp. Widać więc **tylko obrys**. Obrysy G23 (kciuk + kawałek dłoni od góry) czytają się jak odcisk buta, a nie jak kciuk. Zrzut problemu: `docs/handoff/screens/ghosthand-v2-portrait.png` (środkowy panel).

## Zasady
1. **Jeden obraz = jedna wiadomość.** Bez kolaży, siatek i kilku ujęć naraz.
2. **Fotografia**, nie rysunek (G22 odrzucono za grafikę). Dłoń ok. 55-letniego rzemieślnika, bez pierścionków, zegarka, tatuaży.
3. **Czysto białe tło, ostry kontur, brak cienia na tle**, format 1:1 (1024×1024).
4. **Sylwetka musi być czytelna sama w sobie** (test: zamaluj dłoń na czarno; czy od razu widać kciuk i jego kierunek?). Dlatego:
   - kciuk wyraźnie **odsunięty od reszty dłoni** (szczelina tła między kciukiem a palcem wskazującym),
   - widoczny **paznokieć i opuszek** kciuka na końcu (kontur zwęża się i zaokrągla),
   - pozostałe palce **zgięte i zwarte**, ale ich kłykcie tworzą rozpoznawalny obrys dłoni,
   - dłoń wchodzi w kadr **od dolnej krawędzi** (nadgarstek ucięty kadrem), czubek kciuka w górnej połowie kadru.
5. Ujęcie jak przy trzymaniu telefonu: aparat **nad ekranem**, patrzy na kciuk dotykający szyby, lekki skos (10–20°), nie ściśle z góry.

## Ujęcia (nazwy plików)
1. `thumb_left_press.png`: lewa dłoń, kciuk naciska punkt na ekranie (napięcie). *Photo of a left hand of a ~55-year-old craftsman holding a phone from below, seen from above the screen at a slight angle; the thumb is clearly separated from the curled fingers with a visible gap, pressing the glass with its pad, thumbnail visible; wrist enters from the bottom edge of the frame; pure white seamless background, sharp outline, no shadow on the background, no rings, no watch, photorealistic, no text.*
2. `thumb_right_press.png`: to samo, prawa dłoń.
3. `thumb_right_slide.png`: prawa dłoń, kciuk wyciągnięty dalej, w trakcie przesuwania w górę (lekko rozmyty tylko czubek kciuka nie jest potrzebny — kontur ostry).
4. `hand_left_tool.png`, `hand_right_tool.png`, `hand_right_open.png`: jak w G22/G23, ale z zasadą 4 (rozpoznawalny obrys, palce rozdzielone szczeliną tam, gdzie to możliwe).

## Oddanie
`contrib/gpt/G26/images/<nazwa>.png` + `ASSETS.md` (narzędzie, data, pełny prompt, edycje) + `README.md` po polsku. W README dołącz **własny test obrysu**: dla każdego ujęcia wersję z dłonią zamalowaną na płasko (`<nazwa>_silhouette.png`) i jedno zdanie, czy kciuk jest rozpoznawalny.
