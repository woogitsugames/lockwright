# G13 — Rejestr pochodzenia zasobów (ASSETS.md)

Data: **2026-11-05**. Właściciel materiałów: projekt Lockwright. Pliki z wyjściem w `contrib/gpt/G13/`.

## 1. Źródłowe obrazy AI

Narzędzie każdego źródła: **generator obrazów ChatGPT / OpenAI**. Warunki: wyniki podlegają [Warunkom korzystania z usług OpenAI](https://openai.com/policies/terms-of-use/) i pozostałym obowiązującym zasadom; wygenerowane obrazy **nie są oznaczone licencją CC0**. OpenAI nie rości praw do wyników w zakresie dozwolonym przez prawo; przed publikacją należy sprawdzić prawa osób trzecich. Osoby przedstawione są fikcyjne.

Metadane udostępnione przez generator dla tych wyjść nie zawierały treści promptu (`prompt: ""`), dlatego poniżej zapisano treść polecenia na podstawie sesji; jest to zapis tekstowy, nie metadana kryptograficzna.

### `source/arrival-evening.png`
- **Narzędzie:** generator obrazów ChatGPT. **Data:** 2026-11-05.
- **Edytowany:** nie (plik źródłowy skopiowany bez zmian); eksporty pochodne były kadrowane, skalowane, miejscowo przyciemniane i typograficznie opracowane.
- **Licencja/warunki:** jw., OpenAI Terms of Use; nie jest CC0.
- **Pełny prompt:**

```text
Cinematic, photorealistic key art set in a warmly lit historic tenement hallway: a bearded locksmith in a worn cap and work jacket stands in the left foreground with a leather tool bag, notebook, and pen, speaking with a relieved woman in a cozy robe who smiles from the open apartment doorway while holding a blue-floral mug. Rich oak paneling, a “3A” enamel plate, brass lock cylinder left untouched, aged plaster, ornate stair railing, window plants, and a glowing globe sconce create a welcoming, textured scene focused on professional human interaction—not lockpicking or tools in use.
```

### `source/arrival-landing.png`
- **Narzędzie:** generator obrazów ChatGPT. **Data:** 2026-11-05.
- **Edytowany:** nie (plik źródłowy skopiowany bez zmian); eksporty pochodne były kadrowane, skalowane, miejscowo przyciemniane i typograficznie opracowane.
- **Licencja/warunki:** jw., OpenAI Terms of Use; nie jest CC0.
- **Pełny prompt:**

```text
A warm, cinematic promo package for Lockwright presents a photorealistic locksmith visit in a weathered Polish-style tenement, with the primary 16:9 key art leaving clear logo space on the left and showing a relieved resident greeting a professional tradesman at apartment 12. Supporting assets include a vertical poster, dusk workshop, lock close-up, Google Play banner, three social formats, and three bilingual logo concepts, all documented in Polish with prompts, file details, licensing notes, limitations, and placement guidance for contrib/gpt/G13/.
```

### `source/arrival-bag.png`
- **Narzędzie:** generator obrazów ChatGPT. **Data:** 2026-11-05.
- **Edytowany:** nie (plik źródłowy skopiowany bez zmian); eksporty pochodne były kadrowane, skalowane, miejscowo przyciemniane i typograficznie opracowane.
- **Licencja/warunki:** jw., OpenAI Terms of Use; nie jest CC0.
- **Pełny prompt:**

```text
A warm, cinematic key art for Lockwright set in a richly textured old tenement hallway, showing a professional locksmith in a worn olive work jacket with a leather satchel and clipboard speaking helpfully to a smiling woman in a beige robe holding a blue-floral mug at the open apartment door marked “12.” Amber lighting, dark wood, aged green-and-cream walls, ornate stairs, globe lamp, window, and plants create a cozy storybook realism, with no on-screen manipulation of door hardware.
```

### `source/study-sheet.png`
- **Narzędzie:** generator obrazów ChatGPT. **Data:** 2026-11-05.
- **Edytowany:** nie (plik źródłowy skopiowany bez zmian); eksporty pochodne były kadrowane, skalowane, miejscowo przyciemniane i typograficznie opracowane.
- **Licencja/warunki:** jw., OpenAI Terms of Use; nie jest CC0.
- **Pełny prompt:**

```text
A polished, grid-based promotional collage for the narrative game Lockwright blends warm cinematic realism with cozy yet serious locksmith motifs, including an old apartment hallway, a grateful resident, detailed locks and tools, workshop scenes, and logo variations featuring “Pogotowie Zamkowe” and “Locksmith on Call.” The layout includes cinematic key art, a vertical lock close-up, three logo concepts, a dusk rooftop feature banner, and square, vertical, and wide social tiles, all presented with refined typography, realistic lighting, and understated asset labels.
```

## 2. Eksporty pochodne — ewidencja plik po pliku

**Narzędzia:** Python 3 + Pillow (kadrowanie, skalowanie, winieta, napisy, zapis JPEG/PNG); FontTools (kontury liter z EB Garamond 12); CairoSVG (renderowanie wektora). **Data:** 2026-11-05. **Licencja/warunki obrazów:** takie jak w `source/`; wektory i układ własne. **Font wejściowy:** EB Garamond 12, SIL Open Font License 1.1, autor Georg Duffner; plików fontu nie udostępniamy, do logo trafiają jedynie kontury liter i autorskie modyfikacje. **Edycja:** tak, względem źródeł.

Dla grafik powstałych programowo „prompt” oznacza dokładną regułę produkcji w `generate_g13.py` (kod jest pełnym źródłem instrukcji), a nie prompt do modelu generatywnego.

| Plik | Narzędzie / prompt produkcyjny | Edytowany? | Warunki |
|---|---|---|---|
| `feature/google-play-1024x500-clean.png` | Pillow/FontTools/CairoSVG: kadr 1024×500; wariant title dodaje wektor Lockwright | Tak, wygenerowany programowo | Źródło AI: OpenAI; kontury: EB Garamond OFL 1.1 |
| `feature/google-play-1024x500-title.png` | Pillow/FontTools/CairoSVG: kadr 1024×500; wariant title dodaje wektor Lockwright | Tak, wygenerowany programowo | Źródło AI: OpenAI; kontury: EB Garamond OFL 1.1 |
| `feature/google-play-title-overlay.svg` | Pillow/FontTools/CairoSVG: kadr 1024×500; wariant title dodaje wektor Lockwright | Tak, wygenerowany programowo | Źródło AI: OpenAI; kontury: EB Garamond OFL 1.1 |
| `key-art/key-art-2160x3840-clean.jpg` | Pillow: kompozycja źródłowa + kadr do docelowego wymiaru, winieta; logo-space ma dodatkowe przyciemnienie pola tytułu | Tak, wygenerowany programowo | Źródło AI: OpenAI; kontury: EB Garamond OFL 1.1 |
| `key-art/key-art-2160x3840-logo-space.jpg` | Pillow: kompozycja źródłowa + kadr do docelowego wymiaru, winieta; logo-space ma dodatkowe przyciemnienie pola tytułu | Tak, wygenerowany programowo | Źródło AI: OpenAI; kontury: EB Garamond OFL 1.1 |
| `key-art/key-art-3840x2160-clean.jpg` | Pillow: kompozycja źródłowa + kadr do docelowego wymiaru, winieta; logo-space ma dodatkowe przyciemnienie pola tytułu | Tak, wygenerowany programowo | Źródło AI: OpenAI; kontury: EB Garamond OFL 1.1 |
| `key-art/key-art-3840x2160-logo-space.jpg` | Pillow: kompozycja źródłowa + kadr do docelowego wymiaru, winieta; logo-space ma dodatkowe przyciemnienie pola tytułu | Tak, wygenerowany programowo | Źródło AI: OpenAI; kontury: EB Garamond OFL 1.1 |
| `logos/concept-01-en.png` | FontTools: EB Garamond OFL → własne ścieżki SVG, ręcznie opisane ornamenty; CairoSVG → przezroczysty PNG | Tak, wygenerowany programowo | Źródło AI: OpenAI; kontury: EB Garamond OFL 1.1 |
| `logos/concept-01-en.svg` | FontTools: EB Garamond OFL → własne ścieżki SVG, ręcznie opisane ornamenty; CairoSVG → przezroczysty PNG | Tak, wygenerowany programowo | Źródło AI: OpenAI; kontury: EB Garamond OFL 1.1 |
| `logos/concept-01-pl.png` | FontTools: EB Garamond OFL → własne ścieżki SVG, ręcznie opisane ornamenty; CairoSVG → przezroczysty PNG | Tak, wygenerowany programowo | Źródło AI: OpenAI; kontury: EB Garamond OFL 1.1 |
| `logos/concept-01-pl.svg` | FontTools: EB Garamond OFL → własne ścieżki SVG, ręcznie opisane ornamenty; CairoSVG → przezroczysty PNG | Tak, wygenerowany programowo | Źródło AI: OpenAI; kontury: EB Garamond OFL 1.1 |
| `logos/concept-02-en.png` | FontTools: EB Garamond OFL → własne ścieżki SVG, ręcznie opisane ornamenty; CairoSVG → przezroczysty PNG | Tak, wygenerowany programowo | Źródło AI: OpenAI; kontury: EB Garamond OFL 1.1 |
| `logos/concept-02-en.svg` | FontTools: EB Garamond OFL → własne ścieżki SVG, ręcznie opisane ornamenty; CairoSVG → przezroczysty PNG | Tak, wygenerowany programowo | Źródło AI: OpenAI; kontury: EB Garamond OFL 1.1 |
| `logos/concept-02-pl.png` | FontTools: EB Garamond OFL → własne ścieżki SVG, ręcznie opisane ornamenty; CairoSVG → przezroczysty PNG | Tak, wygenerowany programowo | Źródło AI: OpenAI; kontury: EB Garamond OFL 1.1 |
| `logos/concept-02-pl.svg` | FontTools: EB Garamond OFL → własne ścieżki SVG, ręcznie opisane ornamenty; CairoSVG → przezroczysty PNG | Tak, wygenerowany programowo | Źródło AI: OpenAI; kontury: EB Garamond OFL 1.1 |
| `logos/concept-03-en.png` | FontTools: EB Garamond OFL → własne ścieżki SVG, ręcznie opisane ornamenty; CairoSVG → przezroczysty PNG | Tak, wygenerowany programowo | Źródło AI: OpenAI; kontury: EB Garamond OFL 1.1 |
| `logos/concept-03-en.svg` | FontTools: EB Garamond OFL → własne ścieżki SVG, ręcznie opisane ornamenty; CairoSVG → przezroczysty PNG | Tak, wygenerowany programowo | Źródło AI: OpenAI; kontury: EB Garamond OFL 1.1 |
| `logos/concept-03-pl.png` | FontTools: EB Garamond OFL → własne ścieżki SVG, ręcznie opisane ornamenty; CairoSVG → przezroczysty PNG | Tak, wygenerowany programowo | Źródło AI: OpenAI; kontury: EB Garamond OFL 1.1 |
| `logos/concept-03-pl.svg` | FontTools: EB Garamond OFL → własne ścieżki SVG, ręcznie opisane ornamenty; CairoSVG → przezroczysty PNG | Tak, wygenerowany programowo | Źródło AI: OpenAI; kontury: EB Garamond OFL 1.1 |
| `preview/contact-sheet.jpg` | Pillow: kompozycja kontrolna / wycinek materiału; workshop ma wyłącznie niską rozdzielczość koncepcyjną | Tak, wygenerowany programowo | Źródło AI: OpenAI; kontury: EB Garamond OFL 1.1 |
| `preview/oak-and-brass-detail-1080x1920.jpg` | Pillow: kompozycja kontrolna / wycinek materiału; workshop ma wyłącznie niską rozdzielczość koncepcyjną | Tak, wygenerowany programowo | Źródło AI: OpenAI; kontury: EB Garamond OFL 1.1 |
| `preview/workshop-concept-lowres.jpg` | Pillow: kompozycja kontrolna / wycinek materiału; workshop ma wyłącznie niską rozdzielczość koncepcyjną | Tak, wygenerowany programowo | Źródło AI: OpenAI; kontury: EB Garamond OFL 1.1 |
| `social/social-1080x1080-en.jpg` | Pillow/FontTools/CairoSVG: wariant PL/EN, kadr, dyskretny cień pod tekst i logotyp | Tak, wygenerowany programowo | Źródło AI: OpenAI; kontury: EB Garamond OFL 1.1 |
| `social/social-1080x1080-pl.jpg` | Pillow/FontTools/CairoSVG: wariant PL/EN, kadr, dyskretny cień pod tekst i logotyp | Tak, wygenerowany programowo | Źródło AI: OpenAI; kontury: EB Garamond OFL 1.1 |
| `social/social-1080x1920-en.jpg` | Pillow/FontTools/CairoSVG: wariant PL/EN, kadr, dyskretny cień pod tekst i logotyp | Tak, wygenerowany programowo | Źródło AI: OpenAI; kontury: EB Garamond OFL 1.1 |
| `social/social-1080x1920-pl.jpg` | Pillow/FontTools/CairoSVG: wariant PL/EN, kadr, dyskretny cień pod tekst i logotyp | Tak, wygenerowany programowo | Źródło AI: OpenAI; kontury: EB Garamond OFL 1.1 |
| `social/social-1500x500-en.jpg` | Pillow/FontTools/CairoSVG: wariant PL/EN, kadr, dyskretny cień pod tekst i logotyp | Tak, wygenerowany programowo | Źródło AI: OpenAI; kontury: EB Garamond OFL 1.1 |
| `social/social-1500x500-pl.jpg` | Pillow/FontTools/CairoSVG: wariant PL/EN, kadr, dyskretny cień pod tekst i logotyp | Tak, wygenerowany programowo | Źródło AI: OpenAI; kontury: EB Garamond OFL 1.1 |

## 3. Weryfikacja i ograniczenia

- Zdjęcia źródłowe miały **1672 × 941 px**. Eksporty 4K mają wymagane rozmiary pikselowe, ale skalowanie nie przywraca drobnych szczegółów nieobecnych w źródłach.
- `preview/workshop-concept-lowres.jpg` jest **studyjnym wycinkiem kolażu**, NIE grafiką sklepową produkcyjną. Zastąpić pełnowymiarowym renderem warsztatu, gdy będzie gotowy.
- `key-art/...logo-space` nie zawiera tytułu: to osobne wersje z obszarem gotowym do nałożenia lokalizowanego logotypu.
- Zdjęcia są materiałami promocyjnymi, nie przedstawiają rzeczywistego zrzutu rozgrywki. Nie zastępują obowiązkowych zrzutów ekranu aplikacji.
- Wszystkie pliki mają mniej niż 20 MiB; suma kontrolna i wymiary w `manifest.json`.
