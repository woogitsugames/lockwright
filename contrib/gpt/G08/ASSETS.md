# G08 — ASSETS / Rejestr źródeł

**Data generowania:** 2026-11-05.  
**Narzędzie generujące:** ChatGPT Image Generator (OpenAI).  
**Narzędzie obróbki:** Pillow (Python; kadrowanie, skalowanie Lanczos, delikatne wyostrzenie, eksport WebP i skład arkusza).  
**Warunki prawne:** obrazy wygenerowane w usłudze OpenAI podlegają obowiązującym [Warunkom korzystania z OpenAI](https://openai.com/policies/terms-of-use/) i odpowiednim zasadom publikowania oraz prawom osób trzecich; OpenAI nie udziela w tym pliku oddzielnej licencji CC0/OFL. To nie jest certyfikat wyłączności ani gwarancja braku podobieństwa do innych utworów.  
**Źródła wejściowe:** trzy obrazy wygenerowane w tej sesji, użyto dwóch arkuszy B/C; arkusz A nie dostarczył finalnych wycinków.  
**Prompty:** poniżej zapisano pełne jawne opisy użyte przy wywołaniach generatora obrazów; faktyczne wewnętrzne rozszerzenie promptu nie jest dostępne w metadanych (pole `prompt` zwrócone jako pusty ciąg znaków).  
**Edycja:** TAK, wszystkie 11 zdjęć kadrowano z arkuszy, interpolowano i zapisano w WebP; arkusz zbiorczy złożono ponownie z wyeksportowanych zdjęć.  

## Prompty wejściowe widoczne w sesji (pełne)

**Prompt A (archiwalny arkusz, nieużyty w finalnych plikach):**

> A cinematic, photorealistic collage presents an empty locksmith’s workshop (“Pogotowie Zamkowe”) through 11 labeled panels—eight wider views and three close-ups—featuring warm natural and lamp light, rich wood and metal textures, tools, plants, locks, a key duplicator, training mechanisms, a display cabinet, and a handwritten bilingual master’s logbook; the complete documentation and asset folder is intended for `contrib/gpt/G08/`. Arranged in four rows with cream borders and dark caption strips, the scenes progress from morning through evening and include bilingual Polish/English titles, emphasizing a cozy, lived-in urban workspace with no people present.

**Prompt B (źródło kadrów 04–08):**

> A polished concept-art presentation board for “Lockwright: Pogotowie Zamkowe / Locksmith on Call” presents 11 photorealistic, warmly lit workshop renders in a clean labeled grid: eight larger scenes above and three detailed close-ups below, all captioned bilingually in Polish and English. The people-free locksmith studio includes benches, tools, machines, cutaway locks, notebooks, displays, plants, and shifting morning-to-evening light, rendered with rich cinematic detail, realistic materials, and a cozy professional atmosphere.

**Prompt C (źródło kadrów 01–03 i 09–11):**

> A cinematic, photorealistic contact-sheet collage presents a legal locksmith’s vintage workshop through nine carefully labeled Polish/English panels, spanning morning, afternoon, and evening scenes. Warm wood, worn metal, organized tools, key-cutting equipment, practice locks, notebooks, cabinets, lockpick boards, and richly textured details create a realistic, tidy-yet-used atelier atmosphere, with no people or brands visible.

## Pliki i przekształcenia

| Plik | Generator / prompt | Edytowany? | Kadr źródła (x0,y0,x1,y1) | Rozmiar | Bajty | SHA-256 |
|---|---|---|---|---|---:|---|
| `images/01-workshop-morning-portrait.webp` | ChatGPT Image Generator, **C** — pełny prompt wyżej | tak (crop → Lanczos → WebP) | `(58, 62, 313, 615)` | 720 × 1560 | 129112 | `d915346c06d659b2440a5c5d24caa26ce125f86cffbf073a0a0ed856e25a0bd5` |
| `images/02-key-cutter-afternoon-portrait.webp` | ChatGPT Image Generator, **C** — pełny prompt wyżej | tak (crop → Lanczos → WebP) | `(421, 62, 676, 615)` | 720 × 1560 | 95154 | `029264108fb2375c8291460ad7fab7a072c32d8a7ea4ed80945dffbaeea731aa` |
| `images/03-workshop-evening-portrait.webp` | ChatGPT Image Generator, **C** — pełny prompt wyżej | tak (crop → Lanczos → WebP) | `(799, 62, 1054, 615)` | 720 × 1560 | 92686 | `53cee03c8ea0ce6ac6797a30c58f46ca6369aad5f4ee4ceb4c13ec6f39d9e05f` |
| `images/04-tool-board-portrait.webp` | ChatGPT Image Generator, **B** — pełny prompt wyżej | tak (crop → Lanczos → WebP) | `(687, 1, 849, 352)` | 720 × 1560 | 82956 | `80163978ce7fdd6b05485a8c60118e9669b8c8d1f2aee864ad6ab6498573f941` |
| `images/05-display-cabinet-portrait.webp` | ChatGPT Image Generator, **B** — pełny prompt wyżej | tak (crop → Lanczos → WebP) | `(1299, 1, 1461, 352)` | 720 × 1560 | 83752 | `e87c16c62175cf8f195a441d9ad6b78dbed0b3453755d8c1e8707d8fda96710d` |
| `images/06-workbench-afternoon-landscape.webp` | ChatGPT Image Generator, **B** — pełny prompt wyżej | tak (crop → Lanczos → WebP) | `(24, 416, 491, 632)` | 1560 × 720 | 146366 | `b1063d43dc3f53da658ffb6f48d4313f428bb627387f2121e5ee9a489c667bfc` |
| `images/07-workshop-overview-landscape.webp` | ChatGPT Image Generator, **B** — pełny prompt wyżej | tak (crop → Lanczos → WebP) | `(548, 416, 1015, 632)` | 1560 × 720 | 124748 | `23b29504f5aea82c28b0dee1234b86f8e9f24ca3d08c5036146092df3eafb71c` |
| `images/08-lamplight-evening-landscape.webp` | ChatGPT Image Generator, **B** — pełny prompt wyżej | tak (crop → Lanczos → WebP) | `(1057, 416, 1524, 632)` | 1560 × 720 | 90406 | `73ade8a53f87c42a3882fc1a86f9f4b0bcad852d2dc101ffb9f6a2313d6c3342` |
| `images/09-master-notebook-closeup.webp` | ChatGPT Image Generator, **C** — pełny prompt wyżej | tak (crop → Lanczos → WebP) | `(28, 670, 508, 940)` | 1280 × 720 | 105526 | `b4a620ddd33d3e5cf0c7e019821e5bb09a84aa478e9790cd14f81fac91315623` |
| `images/10-display-cabinet-closeup.webp` | ChatGPT Image Generator, **C** — pełny prompt wyżej | tak (crop → Lanczos → WebP) | `(591, 670, 1071, 940)` | 1280 × 720 | 90476 | `230dbba89d52af3f2ae975fcc44d9049c70f6854a35cd55b04bac0b4c357e11f` |
| `images/11-pick-board-closeup.webp` | ChatGPT Image Generator, **C** — pełny prompt wyżej | tak (crop → Lanczos → WebP) | `(1158, 670, 1638, 940)` | 1280 × 720 | 117712 | `990b63a19f8a7d782ff7f2d4ad4061ce4642bdded2aaafe3e5bac86e4c2844f7` |
| `contact-sheet.webp` | Pillow, z 11 plików powyżej (nie nowy prompt AI) | tak (układ redakcyjny + podpisy PL/EN) | nie dotyczy | 2400 × 2330 | 639650 | `62111c1eb91beb8023858b53bcf9d884e6c3f3ef4f84eda0990ed0311d9607e1` |

## Reprodukcja i proweniencja

- Arkusz **B**: `a_single_composite_concept_art_presentation_boa.png` (1536 × 1024, lokalny obraz wygenerowany przez ChatGPT).
- Arkusz **C**: `a_detailed_art_directed_portfolio_collage_image.png` (1672 × 941, lokalny obraz wygenerowany przez ChatGPT).
- Współrzędne kadrowania są podane wyżej; ich jednostką jest piksel w arkuszu źródłowym. Odtworzenie identycznych kadrów wymaga posiadania oryginalnych dwóch arkuszy wygenerowanych w sesji.
- Wygenerowana sztuka koncepcyjna nie zawiera weryfikowanych technicznie mechanizmów ślusarskich; traktować jako inspirację scenograficzną.