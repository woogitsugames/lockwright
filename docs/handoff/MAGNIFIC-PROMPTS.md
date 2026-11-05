# Lockwright: prompty do Magnific, po jednym obrazie (v2)

**Jak używać:** wybierz model według tabeli niżej, ustaw podane proporcje i rozdzielczość **2K** (albo najwyższą dostępną), wklej prompt i pobierz obraz w najwyższej rozdzielczości. Nazwij plik tak jak w nagłówku. Gotowe pliki spakuj do jednego ZIP-a (np. `magnific-1.zip`) i wyślij do sesji A. Obróbkę (tekstury bezszwowe, mapy, przycinanie) robi sesja A.

## Który model do czego
| Grupa | Model | Uwagi |
|---|---|---|
| **A, B, C** (skóra, metal, posadzki) | **ten, który dał wynik nr 2 w teście `leather_brown_new`** (równe, matowe ziarno, płaskie światło) | Jeśli wolisz porównywać, zrób pierwszy obraz z każdej grupy na 2 modelach i przyślij oba. |
| **D** (papier) | ten sam co A | Papier może mieć ciemne tło dookoła, bo przytnę go po krawędzi kartki. |
| **E** (ikona z literą/cyfrą) | **Ideogram** | Najlepiej radzi sobie z literami i cyframi. |
| **F** (key art) | **Nano Banana** | Zrób F1, potem F2–F4 z F1 jako obrazem referencyjnym i dopiskiem „same people, same scene, same clothes”. |

## Czego unikać w teksturach (z testu skóry)
- **Regularne plamy i cętki** (test nr 1): po powieleniu robi się wzór.
- **Ramka albo tło dookoła materiału** (testy nr 2 i 3): materiał ma wypełniać cały kadr.
- **Jedna oś symetrii pośrodku** (test nr 3, „grzbiet” skóry): po powieleniu widać powtórzenia.
- **Odblask, winieta, perspektywa** (test nr 4): ładne zdjęcie, ale nie tekstura.

Prompty w grupach A, B i C mają już te zakazy dopisane na końcu.

**Zasady w każdym prompcie:** w zdjęciu nie ma narzędzi w zamkach, ludzi przy zamkach, tekstu, logo ani marek. Jeśli generator odmówi, usuń z promptu słowa „lock” i „key” i spróbuj jeszcze raz.

---

## A. Skóra (brakujące z NB01)

### A1 `leather_brown_new.png` (1:1)
```
Top-down macro photograph of smooth new brown full-grain cowhide leather, fine natural grain and pores, evenly lit with soft diffused light, no shadows, no perspective, sharp focus across the whole frame, 30 cm wide sample, photorealistic texture reference, no text, no logo, the material fills the entire frame edge to edge, no border, no background visible, uniform flat lighting with no hotspot or vignette, no perspective, no single central axis or symmetry
```

### A2 `leather_brown_worn.png` (1:1)
```
Top-down macro photograph of old brown leather worn smooth and slightly glossy by hands, subtle lighter rubbed areas, fine creases, small scuffs, evenly lit with soft diffused light, no shadows, no perspective, sharp focus, photorealistic texture reference, no text, no logo, the material fills the entire frame edge to edge, no border, no background visible, uniform flat lighting with no hotspot or vignette, no perspective, no single central axis or symmetry
```

### A3 `leather_stitching_strip.png` (3:1)
```
Close-up photograph of two parallel rows of hand saddle stitching with waxed natural linen thread on brown leather, straight horizontal seam, slight thread wear, soft even light from above, shallow relief visible, photorealistic, no text, no logo
```

### A4 `leather_brass_snap.png` (1:1)
```
Top-down close-up photograph of a single round antique brass snap button set in brown leather, satin brushed brass with light patina and fine scratches, not shiny, soft even studio light, photorealistic product macro, no text, no logo
```

---

## B. Metal z bliska (makro)

### B1 `brass_turned.png` (1:1)
```
Extreme macro photograph of a flat turned brass surface with fine concentric lathe marks, satin finish, soft diffused light, no mirror reflections, no chrome, sharp focus, photorealistic material reference, no text, the material fills the entire frame edge to edge, no border, no background visible, uniform flat lighting with no hotspot or vignette, no perspective, no single central axis or symmetry
```

### B2 `brass_face_milled.png` (1:1)
```
Extreme macro photograph of a face-milled brass surface showing overlapping curved tool arcs, satin finish, soft diffused light, no mirror reflections, sharp focus, photorealistic material reference, no text, the material fills the entire frame edge to edge, no border, no background visible, uniform flat lighting with no hotspot or vignette, no perspective, no single central axis or symmetry
```

### B3 `steel_ground.png` (1:1)
```
Extreme macro photograph of surface-ground steel with fine straight parallel grinding lines, matte satin grey, soft diffused light, no mirror reflections, sharp focus, photorealistic material reference, no text, the material fills the entire frame edge to edge, no border, no background visible, uniform flat lighting with no hotspot or vignette, no perspective, no single central axis or symmetry
```

### B4 `steel_heat_tint.png` (1:1)
```
Extreme macro photograph of hardened steel with a very subtle straw-gold to faint blue heat tint, matte satin, soft diffused light, no neon, no mirror reflections, sharp focus, photorealistic material reference, no text, the material fills the entire frame edge to edge, no border, no background visible, uniform flat lighting with no hotspot or vignette, no perspective, no single central axis or symmetry
```

### B5 `spring_steel_polished.png` (1:1)
```
Extreme macro photograph of polished spring steel strip with fine micro scratches running lengthwise, satin sheen not chrome, soft diffused light, sharp focus, photorealistic material reference, no text, the material fills the entire frame edge to edge, no border, no background visible, uniform flat lighting with no hotspot or vignette, no perspective, no single central axis or symmetry
```

### B6 `brass_patina_grease.png` (1:1)
```
Extreme macro photograph of old machined brass with uneven brown patina and dark grease residue in small grooves and corners, satin finish, soft diffused light, sharp focus, photorealistic material reference, no text, the material fills the entire frame edge to edge, no border, no background visible, uniform flat lighting with no hotspot or vignette, no perspective, no single central axis or symmetry
```

### B7 `nickel_satin.png` (1:1)
```
Extreme macro photograph of satin brushed nickel plate with light everyday scratches and slight fingerprints, soft diffused light, no mirror reflections, sharp focus, photorealistic material reference, no text, the material fills the entire frame edge to edge, no border, no background visible, uniform flat lighting with no hotspot or vignette, no perspective, no single central axis or symmetry
```

### B8 `iron_painted_rust.png` (1:1)
```
Extreme macro photograph of black painted iron plate with chipped paint, worn edge showing bare metal and orange rust, matte, soft diffused light, sharp focus, photorealistic material reference, no text, the material fills the entire frame edge to edge, no border, no background visible, uniform flat lighting with no hotspot or vignette, no perspective, no single central axis or symmetry
```

---

## C. Posadzki (z góry)

### C1 `terrazzo_grey_red.png` (1:1)
```
Top-down photograph of an old polished terrazzo floor, grey base with red, white and black stone chips 2 to 15 mm, slightly dull from foot traffic, evenly lit, no shadows, no perspective, about 1 m wide, sharp, photorealistic texture reference, no text, the material fills the entire frame edge to edge, no border, no background visible, uniform flat lighting with no hotspot or vignette, no perspective, no single central axis or symmetry
```

### C2 `cement_tiles.png` (1:1)
```
Top-down photograph of old encaustic cement floor tiles with a simple original geometric pattern in muted red, grey-blue and cream, slight colour variation between tiles, worn pattern, grout lines, a few hairline cracks, evenly lit, no shadows, no perspective, photorealistic texture reference, no text, the material fills the entire frame edge to edge, no border, no background visible, uniform flat lighting with no hotspot or vignette, no perspective, no single central axis or symmetry
```

### C3 `pine_floor_painted.png` (1:1)
```
Top-down photograph of old pine floorboards painted red-brown floor paint, worn through to bare wood along a walking path, gaps between boards, small nail heads, evenly lit, no shadows, no perspective, photorealistic texture reference, no text, the material fills the entire frame edge to edge, no border, no background visible, uniform flat lighting with no hotspot or vignette, no perspective, no single central axis or symmetry
```

### C4 `workshop_concrete.png` (1:1)
```
Top-down photograph of a workshop concrete floor with natural irregular oil stains, fine cracks and small chips, evenly lit, no shadows, no perspective, photorealistic texture reference, no text, the material fills the entire frame edge to edge, no border, no background visible, uniform flat lighting with no hotspot or vignette, no perspective, no single central axis or symmetry
```

### C5 `coconut_doormat.png` (3:2)
```
Top-down photograph of a plain coconut coir doormat, worn and flattened in the centre, on an even neutral grey background, soft even light, photorealistic, no text, no pattern, no logo
```

---

## D. Papier (pusty, do rekwizytów)

### D1 `paper_receipt_pad.png` (3:4)
```
Top-down photograph of a blank sheet torn from a small receipt pad with perforation at the top, slightly crumpled, warm off-white paper fibres, on a dark wooden surface, soft even light, completely blank, no text, no lines, no print
```

### D2 `paper_office_folded.png` (3:4)
```
Top-down photograph of a blank old office paper sheet folded in three and flattened, staple hole in the corner, faint yellowing, on a dark surface, soft even light, completely blank, no text, no print
```

### D3 `paper_card_stock.png` (3:2)
```
Top-down photograph of a blank worn cream cardboard card with rounded corners and rubbed edges, on a dark surface, soft even light, completely blank, no text, no print
```

### D4 `envelope_front.png` (3:2)
```
Top-down photograph of a plain old cream paper envelope, front side, slightly creased, on a dark surface, soft even light, completely blank, no text, no stamp
```

### D5 `envelope_back.png` (3:2)
```
Top-down photograph of a plain old cream paper envelope, back side with closed flap, slightly creased, on a dark surface, soft even light, completely blank, no text
```

### D6 `paper_note_torn.png` (3:4)
```
Top-down photograph of a blank lined page torn out of an old school notebook, ragged left edge, slight coffee ring, on a dark wooden surface, soft even light, no writing
```

### D7 `ink_oval_blank.png` (1:1)
```
Top-down photograph of a single empty oval rubber stamp impression in faded dark blue ink on white paper, uneven ink, partially faint, no text inside, no symbols, plain oval ring only
```

---

## E. Ikona (dodatkowe obiekty)

### E1 `icon_enamel_L.png` (1:1)
```
Studio product photograph of a small old enamel sign with a single capital letter L, navy letter on ivory enamel, chipped edges with rust, two screws, centred on a dark graphite background with 12 percent margin, soft warm light from upper left, photorealistic
```

### E2 `icon_doorbell.png` (1:1)
```
Studio product photograph of an antique brass apartment doorbell push with a white porcelain button, satin brass with patina, centred on a dark bottle-green background with 12 percent margin, soft warm light from upper left, photorealistic, no text
```

### E3 `icon_number_plate_7.png` (1:1)
```
Studio product photograph of a small old enamel house number plate showing the number 7, ivory number on navy enamel, chipped edges, two screws, centred on a dark graphite background with 12 percent margin, soft warm light from upper left, photorealistic
```

---

## F. Key art (każda proporcja osobno)

Scena dla wszystkich: *Landing of an old Central European tenement staircase, warm bulb light, green painted lower wall, an oak apartment door with an enamel number plate. A friendly craftsman about 40 years old in a flat cap and work jacket, leather bag on his shoulder, holding a notebook, seen partly from behind, talks with a smiling woman in a bathrobe holding a mug of tea in the open doorway. A leather bag stands on the doormat. Warm, calm, helpful mood, photorealistic, cinematic but natural, no text, no logo.*

### F1 `keyart_16x9.png` (16:9)
```
Landing of an old Central European tenement staircase, warm bulb light, green painted lower wall, an oak apartment door with an enamel number plate. A friendly craftsman about 40 years old in a flat cap and work jacket, leather bag on his shoulder, holding a notebook, seen partly from behind on the left, talks with a smiling woman in a bathrobe holding a mug of tea in the open doorway on the right. A leather bag stands on the doormat. Warm, calm, helpful mood, photorealistic, natural light, no text, no logo
```

### F2 `keyart_9x16.png` (9:16)
```
Vertical composition. Landing of an old Central European tenement staircase, warm bulb light, green painted lower wall, an oak apartment door with an enamel number plate. A smiling woman in a bathrobe holding a mug of tea stands in the open doorway, a friendly craftsman in a flat cap and work jacket with a notebook is visible partly from behind in the foreground. A leather bag on the doormat. People in the upper two thirds, calm empty floor in the lower third. Warm, helpful mood, photorealistic, no text, no logo
```

### F3 `keyart_1x1.png` (1:1)
```
Square composition. Old tenement staircase landing, warm bulb light, green painted lower wall, oak apartment door with enamel number plate. A friendly craftsman in a flat cap seen partly from behind, holding a notebook, talks with a smiling woman in a bathrobe with a mug of tea in the doorway. Leather bag on the doormat. Warm, calm, photorealistic, no text, no logo
```

### F4 `keyart_3x1.png` (3:1)
```
Very wide panoramic composition. Old tenement staircase landing with warm bulb light and green painted lower wall on the left side as calm empty space, on the right an oak apartment door where a smiling woman in a bathrobe with a mug of tea talks to a friendly craftsman in a flat cap seen partly from behind. Leather bag on the doormat. Warm, photorealistic, no text, no logo
```

---

Razem: 4 + 8 + 5 + 7 + 3 + 4 = **31 obrazów**. Kolejność według ważności dla gry: **A, F, B, C, D, E**.
