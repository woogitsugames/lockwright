# G13 — ASSETS / pochodzenie i warunki

**2026-11-05**. Każdy plik ma opis narzędzia i źródła. Skrypt i konfiguracje SVG są edytowalnym źródłem.

## Źródła zapisane w tym commicie

| Plik | Narzędzie / pochodzenie | Prompt | Warunki | Edytowany |
|---|---|---|---|---|
| `source/stairwell-render.png` | Blender / skrypt repo `art/blender/stairwell.py`, kopia bloba `art/renders/stairwell.png` | Proceduralna klatka starej kamienicy z dębowymi drzwiami, emaliowaną tabliczką i ciepłą żarówką, jak w pliku skryptu | Praca projektu; zob. `docs/ASSETS.md` | Nie |
| `source/workshop-reference.jpg` | Blender + render podglądowy repo `mockups/realizm/img/workshop.jpg` | Proceduralny warsztat przyjaznego ślusarza o zmierzchu, jak w `art/blender/workshop.py` | Praca projektu; zob. `docs/ASSETS.md` | Nie |

## Wszystkie pliki SVG

**Pliki:** `key-art/*.svg`, `feature/*.svg`, `social/*.svg`, `logos/*.svg`, `preview/contact-sheet.svg`.
**Narzędzie:** programowy SVG / połączenie konturów, tekstu, kompozycji i istniejących renderów za pomocą GitHub connector; **data:** 2026-11-05.
**Pełna instrukcja projektowa („prompt”):** „Zbuduj fotorealistyczny plakat promocyjny Lockwright na podstawie własnego renderu kamienicy; oprawa ciepła, spokojna, legalna, bez przestępstwa i instruktażu. Cztery key arty o proporcjach 16:9 i 9:16, 2 feature graphic Google Play 1024×500, trzy banery social w PL/EN. Trzy typograficzne znaki Lockwright w klasycznej antykwie, z podpisami Pogotowie Zamkowe lub Locksmith on Call, w barwach kości słoniowej i mosiądzu, z indywidualnym rytmem linii i ornamentów. Bez fioletowo-niebieskich gradientów, blasku neonu, HUD i obcych znaków towarowych.”
**Licencja/warunki:** kompozycje wykonane dla projektu; materiał bazowy to wewnętrzny render gry, zasady `docs/ASSETS.md`; **edytowane:** tak, kadrowanie/winieta/napisy/ornamenty.

**Uwaga o fontach:** GitHubowe SVG odwołują się przez CSS do **EB Garamond** (SIL Open Font License 1.1) i mogą podstawić inny serif, jeżeli font nie jest zainstalowany. ZIP dostarczony w rozmowie zawiera **autorskie kontury wektorowe**, niezależne od zainstalowanego fontu, z fontu EB Garamond 12 na licencji OFL.

## Obrazy AI w pełnej paczce ZIP (binaria nieobecne w GitHub)

Każdy z poniższych obrazów jest wygenerowany w **ChatGPT image generation** dnia 2026-11-05; nie są automatycznie licencjonowane jako CC0. Zastosowanie według aktualnych [warunków OpenAI](https://openai.com/policies/terms-of-use/). W ZIP źródła są nieedytowane, a ich eksporty są edytowane kodem Python / Pillow (kadrowanie, skalowanie, winieta, typografia). Metadane generatora nie zawierały tekstu promptu, poniżej zapis instrukcji z sesji:

### `source/arrival-evening.png`
**Pełny prompt:** Cinematic, photorealistic key art set in a warmly lit historic tenement hallway: a bearded locksmith in a worn cap and work jacket stands in the left foreground with a leather tool bag, notebook, and pen, speaking with a relieved woman in a cozy robe who smiles from the open apartment doorway while holding a blue-floral mug. Rich oak paneling, a “3A” enamel plate, brass lock cylinder left untouched, aged plaster, ornate stair railing, window plants, and a glowing globe sconce create a welcoming, textured scene focused on professional human interaction.

### `source/arrival-landing.png`
**Pełny prompt:** A warm, cinematic promo package for Lockwright presents a photorealistic locksmith visit in a weathered Polish-style tenement, with the primary 16:9 key art leaving clear logo space on the left and showing a relieved resident greeting a professional tradesman at apartment 12. Supporting assets include a vertical poster, dusk workshop, lock close-up, Google Play banner, three social formats, and three bilingual logo concepts.

### `source/arrival-bag.png`
**Pełny prompt:** A warm, cinematic key art for Lockwright set in a richly textured old tenement hallway, showing a professional locksmith in a worn olive work jacket with a leather satchel and clipboard speaking helpfully to a smiling woman in a beige robe holding a blue-floral mug at the apartment door. Amber lighting, dark wood, aged green-and-cream walls, ornate stairs, globe lamp, window, and plants.

### `source/study-sheet.png`
**Pełny prompt:** A polished, grid-based promotional collage for the narrative game Lockwright blends warm cinematic realism with cozy yet serious locksmith motifs, including an old apartment hallway, a grateful resident, a workshop, close-up material studies, and logo variations featuring “Pogotowie Zamkowe” and “Locksmith on Call”. The layout includes cinematic key art, vertical images, three logo concepts, and square, vertical and wide social tiles.

**Eksporty ZIP:** `key-art/*.{jpg}`, `feature/*.{png,svg}`, `social/*.jpg`, `logos/*.{png,svg}`, `preview/*.{jpg}`. Dla każdego pliku: narzędzie Python 3 + Pillow + FontTools + CairoSVG; data 2026-11-05; kompletna instrukcja w `generate_g13.py` z ZIP (kod zastępuje prompt, bo są to przekształcenia deterministyczne); edytowany tak; warunki jak dla obrazu źródłowego i EB Garamond OFL 1.1 dla konturów.

**Ograniczenie jakości:** źródła AI 1672×941, formaty docelowe uzyskane przez skalowanie i kadrowanie. `preview/workshop-concept-lowres.jpg` tylko studium, nie finalny baner.
