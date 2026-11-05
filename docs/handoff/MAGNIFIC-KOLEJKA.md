# Lockwright: kolejka Magnific (wszystko do zrobienia w jednym miejscu)

Ta kolejka zbiera wszystkie zlecenia do Magnific. Nowe pozycje sesja A dopisuje na dole. Gdy wrócisz, zrób wszystko z tego pliku i wrzuć ZIP-y do Release `incoming-assets`.

---


Materiały ze zdjęć są już w grze (`art/textures/photo/`). Trzy zdjęcia trzeba zrobić jeszcze raz, bo po przeróbce na teksturę widać wady. Zasady jak w `MAGNIFIC-PROMPTS.md`: 4 warianty, 2K, ZIP-y do Release `incoming-assets`.

## R1 `iron_painted_rust.png` (1:1)
**Co było nie tak:** ostra była tylko lewa górna ćwiartka, a reszta zdjęcia wyszła nieostra. Do tego jedna duża krawędź rdzy powtarza się po złożeniu tekstury.

**Cel:** równomiernie ostra płaska blacha z drobnymi odpryskami rozsianymi po całym kadrze.
```
Flat top-down macro photograph of a black painted iron plate, many small paint chips and scratches evenly distributed across the whole surface showing dark bare metal with spots of orange rust, no single large feature, matte, uniformly sharp from corner to corner, uniform soft flat lighting, no depth of field, no perspective, the metal fills the entire frame edge to edge, photorealistic material reference, no text
```

## R2 `spring_steel_polished.png` (1:1)
**Co było nie tak:** zdjęcie miało gradient światła i perspektywę, przez co na mapie normalnej po złożeniu widać poziome pasmo.
```
Flat top-down macro photograph of a polished spring steel strip surface, fine micro scratches running lengthwise in one direction, satin sheen not mirror, perfectly uniform flat lighting with no gradient, no reflections of objects, no perspective, uniformly sharp, the metal fills the entire frame edge to edge, photorealistic material reference, no text
```

## R3 `brass_patina_grease.png` (1:1)
**Co było nie tak:** kilka dużych, charakterystycznych plam powtarza się po złożeniu tekstury.

**Cel:** patyna drobna i równomierna, bez dużych plam.
```
Flat top-down macro photograph of old machined brass with fine evenly distributed brown patina speckles and thin dark grease lines in tiny scratches, no large stains, no single dominant feature, satin finish, uniform soft flat lighting, no perspective, uniformly sharp, the metal fills the entire frame edge to edge, photorealistic material reference, no text
```

---


**Po co:** w grze 39 mówiących postaci nie ma twarzy (N-49). Stała obsada ma portrety z G09.

**Jak robić:**
- model **Nano Banana**, proporcje **1:1**, 2K, po 1 obrazie na postać (możesz zrobić 2–4 warianty, wybiorę);
- nazwa pliku `portrait_<id>.png`;
- ZIP-y wrzucaj do Release `incoming-assets`.

**Styl:** ten sam dopisek na końcu każdego promptu, już wklejony.

**Postacie z odmów** (`darek`, `claimant`, `stranger`, `norbert`, `marcel`): mają wyglądać zwyczajnie, bez złowrogiej miny. Gra uczy grzecznej odmowy, a nie podejrzliwości.

## 1. `portrait_iga.png`
```
Iga, 27, drummer in a small indie band, short dyed hair, band t-shirt under a denim jacket, drumstick behind her ear, friendly but in a hurry, photorealistic portrait photograph, head and shoulders, natural soft window light in an old Central European tenement stairwell, warm tones, shallow depth of field, everyday clothes, no logos, no text, fictional person, not resembling any celebrity
```

## 2. `portrait_gosia.png`
```
Gosia, 36, furniture restorer, linen work apron with wood dust, hair tied with a pencil in it, calm confident smile, photorealistic portrait photograph, head and shoulders, natural soft window light in an old Central European tenement stairwell, warm tones, shallow depth of field, everyday clothes, no logos, no text, fictional person, not resembling any celebrity
```

## 3. `portrait_elzbieta.png`
```
Elżbieta, 55, residents' building manager, neat cardigan, reading glasses on a cord, holding a binder, warm and organised, photorealistic portrait photograph, head and shoulders, natural soft window light in an old Central European tenement stairwell, warm tones, shallow depth of field, everyday clothes, no logos, no text, fictional person, not resembling any celebrity
```

## 4. `portrait_basia.png`
```
Basia, 48, residents' committee secretary, practical fleece, clipboard, cheerful, photorealistic portrait photograph, head and shoulders, natural soft window light in an old Central European tenement stairwell, warm tones, shallow depth of field, everyday clothes, no logos, no text, fictional person, not resembling any celebrity
```

## 5. `portrait_pieter.png`
```
Brother Pieter, 66, gentle older man in a plain grey cardigan over a simple shirt, a bicycle with a wicker basket softly blurred behind him, kind eyes, photorealistic portrait photograph, head and shoulders, natural soft window light in an old Central European tenement stairwell, warm tones, shallow depth of field, everyday clothes, no logos, no text, fictional person, not resembling any celebrity
```

## 6. `portrait_jacques.png`
```
Monsieur Jacques, 72, Belgian neighbour, flat cap, scarf, holding a ring with one gate key, polite, photorealistic portrait photograph, head and shoulders, natural soft window light in an old Central European tenement stairwell, warm tones, shallow depth of field, everyday clothes, no logos, no text, fictional person, not resembling any celebrity
```

## 7. `portrait_magda.png`
```
Magda, 41, translator, wrapped in a knitted shawl, slightly embarrassed smile, standing on a small balcony, photorealistic portrait photograph, head and shoulders, natural soft window light in an old Central European tenement stairwell, warm tones, shallow depth of field, everyday clothes, no logos, no text, fictional person, not resembling any celebrity
```

## 8. `portrait_marek.png`
```
Marek, 45, impatient heir in a rain jacket, checking his watch, photorealistic portrait photograph, head and shoulders, natural soft window light in an old Central European tenement stairwell, warm tones, shallow depth of field, everyday clothes, no logos, no text, fictional person, not resembling any celebrity
```

## 9. `portrait_piotr.png`
```
Piotr, 38, quiet heir in a sweater, holding an old photograph, photorealistic portrait photograph, head and shoulders, natural soft window light in an old Central European tenement stairwell, warm tones, shallow depth of field, everyday clothes, no logos, no text, fictional person, not resembling any celebrity
```

## 10. `portrait_ewa.png`
```
Ewa, 50, heir arriving in a hurry, coat open, car keys in hand, determined, photorealistic portrait photograph, head and shoulders, natural soft window light in an old Central European tenement stairwell, warm tones, shallow depth of field, everyday clothes, no logos, no text, fictional person, not resembling any celebrity
```

## 11. `portrait_aino.png`
```
Aino, 50, Finnish ship chief engineer, navy work overalls, short grey-blond hair, weathered friendly face, photorealistic portrait photograph, head and shoulders, natural soft window light in an old Central European tenement stairwell, warm tones, shallow depth of field, everyday clothes, no logos, no text, fictional person, not resembling any celebrity
```

## 12. `portrait_captain.png`
```
ship captain, 60, Nordic, dark uniform jumper with epaulettes, beard, holding a clipboard, photorealistic portrait photograph, head and shoulders, natural soft window light in an old Central European tenement stairwell, warm tones, shallow depth of field, everyday clothes, no logos, no text, fictional person, not resembling any celebrity
```

## 13. `portrait_teresa.png`
```
Mrs Teresa, 65, neighbour in a dressing gown, surprised but amused, photorealistic portrait photograph, head and shoulders, natural soft window light in an old Central European tenement stairwell, warm tones, shallow depth of field, everyday clothes, no logos, no text, fictional person, not resembling any celebrity
```

## 14. `portrait_kazimierz.png`
```
Mr Kazimierz, 60, in a slightly crooked suit after a family celebration, rosy cheeks, cheerful, photorealistic portrait photograph, head and shoulders, natural soft window light in an old Central European tenement stairwell, warm tones, shallow depth of field, everyday clothes, no logos, no text, fictional person, not resembling any celebrity
```

## 15. `portrait_darek.png`
```
Darek, about 40, tense, hoodie and jacket, phone held face-down, avoiding eye contact (not threatening, just frustrated), photorealistic portrait photograph, head and shoulders, natural soft window light in an old Central European tenement stairwell, warm tones, shallow depth of field, everyday clothes, no logos, no text, fictional person, not resembling any celebrity
```

## 16. `portrait_tomasz.png`
```
Tomasz, 40, carpenter, flannel shirt, pencil behind ear, kneeling next to his daughter, photorealistic portrait photograph, head and shoulders, natural soft window light in an old Central European tenement stairwell, warm tones, shallow depth of field, everyday clothes, no logos, no text, fictional person, not resembling any celebrity
```

## 17. `portrait_hania.png`
```
Hania, 7, girl in a hand-knitted sweater holding a rag doll, hopeful expression, photorealistic portrait photograph, head and shoulders, natural soft window light in an old Central European tenement stairwell, warm tones, shallow depth of field, everyday clothes, no logos, no text, fictional person, not resembling any celebrity
```

## 18. `portrait_wanda.png`
```
Mrs Wanda, 62, tenement manager, elegant coat, binder of residents' resolutions under her arm, photorealistic portrait photograph, head and shoulders, natural soft window light in an old Central European tenement stairwell, warm tones, shallow depth of field, everyday clothes, no logos, no text, fictional person, not resembling any celebrity
```

## 19. `portrait_headteacher.png`
```
school headteacher, 50, smart blazer, lanyard, welcoming, photorealistic portrait photograph, head and shoulders, natural soft window light in an old Central European tenement stairwell, warm tones, shallow depth of field, everyday clothes, no logos, no text, fictional person, not resembling any celebrity
```

## 20. `portrait_irena.png`
```
Mrs Irena, 79, retired librarian, cardigan with a brooch, gentle sad smile, photorealistic portrait photograph, head and shoulders, natural soft window light in an old Central European tenement stairwell, warm tones, shallow depth of field, everyday clothes, no logos, no text, fictional person, not resembling any celebrity
```

## 21. `portrait_hall_manager.png`
```
rehearsal hall manager, 45, black t-shirt, keys on a carabiner, relaxed, photorealistic portrait photograph, head and shoulders, natural soft window light in an old Central European tenement stairwell, warm tones, shallow depth of field, everyday clothes, no logos, no text, fictional person, not resembling any celebrity
```

## 22. `portrait_neighbour_lucyna.png`
```
Mrs Lucyna, 70, observant neighbour peeking out of her doorway, house slippers, arms folded, photorealistic portrait photograph, head and shoulders, natural soft window light in an old Central European tenement stairwell, warm tones, shallow depth of field, everyday clothes, no logos, no text, fictional person, not resembling any celebrity
```

## 23. `portrait_claimant.png`
```
a woman in her thirties in a smart trench coat, overly confident, clutching a handbag, photorealistic portrait photograph, head and shoulders, natural soft window light in an old Central European tenement stairwell, warm tones, shallow depth of field, everyday clothes, no logos, no text, fictional person, not resembling any celebrity
```

## 24. `portrait_martine.png`
```
Madame Martine, 74, Belgian, silver bob, wool coat, holding an old iron cashbox, photorealistic portrait photograph, head and shoulders, natural soft window light in an old Central European tenement stairwell, warm tones, shallow depth of field, everyday clothes, no logos, no text, fictional person, not resembling any celebrity
```

## 25. `portrait_kuba.png`
```
Kuba, 23, nervous young man in a borrowed blazer too big for him, holding a bike helmet, photorealistic portrait photograph, head and shoulders, natural soft window light in an old Central European tenement stairwell, warm tones, shallow depth of field, everyday clothes, no logos, no text, fictional person, not resembling any celebrity
```

## 26. `portrait_zbyszek.png`
```
Mr Zbyszek, 74, allotment gardener, flat cap, garden gloves, muddy boots, photorealistic portrait photograph, head and shoulders, natural soft window light in an old Central European tenement stairwell, warm tones, shallow depth of field, everyday clothes, no logos, no text, fictional person, not resembling any celebrity
```

## 27. `portrait_waldek.png`
```
Mr Waldek, 70, allotment neighbour, vest over a checked shirt, holding a watering can, photorealistic portrait photograph, head and shoulders, natural soft window light in an old Central European tenement stairwell, warm tones, shallow depth of field, everyday clothes, no logos, no text, fictional person, not resembling any celebrity
```

## 28. `portrait_agnieszka.png`
```
Agnieszka, 45, hospital nurse after a night shift, jacket over scrubs, tired but kind, photorealistic portrait photograph, head and shoulders, natural soft window light in an old Central European tenement stairwell, warm tones, shallow depth of field, everyday clothes, no logos, no text, fictional person, not resembling any celebrity
```

## 29. `portrait_leopold.png`
```
Mr Leopold, 70, antiquarian, bow tie, tweed waistcoat, magnifier on a chain, photorealistic portrait photograph, head and shoulders, natural soft window light in an old Central European tenement stairwell, warm tones, shallow depth of field, everyday clothes, no logos, no text, fictional person, not resembling any celebrity
```

## 30. `portrait_mietek.png`
```
Mietek, 30, pizza cook, white t-shirt with flour, cap, photorealistic portrait photograph, head and shoulders, natural soft window light in an old Central European tenement stairwell, warm tones, shallow depth of field, everyday clothes, no logos, no text, fictional person, not resembling any celebrity
```

## 31. `portrait_renata.png`
```
Mrs Renata, 52, pizzeria owner, apron, flour on her elbows, talking fast with a big smile, photorealistic portrait photograph, head and shoulders, natural soft window light in an old Central European tenement stairwell, warm tones, shallow depth of field, everyday clothes, no logos, no text, fictional person, not resembling any celebrity
```

## 32. `portrait_bartek.png`
```
Bartek, 30, groom in a slightly loosened wedding suit holding a bouquet, sheepish smile, photorealistic portrait photograph, head and shoulders, natural soft window light in an old Central European tenement stairwell, warm tones, shallow depth of field, everyday clothes, no logos, no text, fictional person, not resembling any celebrity
```

## 33. `portrait_bride.png`
```
Kasia, 29, bride with a crooked veil and a wedding dress, laughing, holding her shoes, photorealistic portrait photograph, head and shoulders, natural soft window light in an old Central European tenement stairwell, warm tones, shallow depth of field, everyday clothes, no logos, no text, fictional person, not resembling any celebrity
```

## 34. `portrait_neighbour_robe.png`
```
sleepy neighbour, 50, in a dressing gown and slippers, holding a mug, photorealistic portrait photograph, head and shoulders, natural soft window light in an old Central European tenement stairwell, warm tones, shallow depth of field, everyday clothes, no logos, no text, fictional person, not resembling any celebrity
```

## 35. `portrait_nadia.png`
```
Nadia, 29, baker, white apron, hair net, flour on her hands, early-morning tired smile, photorealistic portrait photograph, head and shoulders, natural soft window light in an old Central European tenement stairwell, warm tones, shallow depth of field, everyday clothes, no logos, no text, fictional person, not resembling any celebrity
```

## 36. `portrait_krysia.png`
```
Krysia, 60, kiosk regular, raincoat, newspaper under her arm, photorealistic portrait photograph, head and shoulders, natural soft window light in an old Central European tenement stairwell, warm tones, shallow depth of field, everyday clothes, no logos, no text, fictional person, not resembling any celebrity
```

## 37. `portrait_norbert.png`
```
Norbert, 43, worried brother holding a watering can, polite, photorealistic portrait photograph, head and shoulders, natural soft window light in an old Central European tenement stairwell, warm tones, shallow depth of field, everyday clothes, no logos, no text, fictional person, not resembling any celebrity
```

## 38. `portrait_marcel.png`
```
Marcel, 29, courier with a hand trolley of parcels, high-visibility vest without any logo, photorealistic portrait photograph, head and shoulders, natural soft window light in an old Central European tenement stairwell, warm tones, shallow depth of field, everyday clothes, no logos, no text, fictional person, not resembling any celebrity
```

## 39. `portrait_stranger.png`
```
a fast-talking man in his forties in a neat suit, polite smile, holding out an envelope (no money visible), photorealistic portrait photograph, head and shoulders, natural soft window light in an old Central European tenement stairwell, warm tones, shallow depth of field, everyday clothes, no logos, no text, fictional person, not resembling any celebrity
```
