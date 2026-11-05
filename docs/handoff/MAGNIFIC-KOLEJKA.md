# Lockwright: kolejka Magnific (wszystko do zrobienia w jednym miejscu)

Ta kolejka zbiera wszystkie zlecenia do Magnific. Wykonane pozycje sesja A usuwa, nowe dopisuje. Zasady jak w `MAGNIFIC-PROMPTS.md`: **4 warianty** (każdy z innego modelu), 2K, ZIP-y do Release `incoming-assets` z nazwą pliku z nagłówka.

Stan na 2026-11-05 22:00:
- **A1 (tło menu) wstrzymane:** menu idzie w render z Blendera (handover §5 pkt 2). Wróci tylko, jeśli proof z Blendera nie przejdzie.
- **A2 i portrety rozdziału 8** zrobił ChatGPT (G21), są w grze.
- **Nowe:** C (dłonie do widma, zamiast odrzuconego G22) i D (klienci w pełnej postaci do scenki przyjazdu, D-58, pilot).

---

## C. Dłonie do „widma” w samouczku (zamiast G22)
**Do czego:** gra wycina sylwetkę dłoni, rozmywa ją i kładzie jako miękki cień 35% pokazujący gest (ONBOARDING §2.2). Dlatego: **czysto białe tło, ostry kontur, widok prosto z góry, dokładnie 5 palców**. 1:1, 2K. ZIP: `magnific_C_hands.zip`.

Wspólny początek każdego promptu:
```
Overhead studio photograph shot straight down, real adult craftsman's hand about 55 years old, natural skin texture, short clean nails, no rings, no watch, no tattoos, on a seamless pure white background, soft even light, no shadow on the background, crisp clean outline, exactly five fingers, anatomically correct, photorealistic, no text, no other objects,
```
1. `C1_thumb_left_press.png`: `only the left thumb and the edge of the left hand entering from the lower left corner, thumb pointing up and slightly right, thumb pad pressed flat as if touching a phone screen, thumb tip near the centre`
2. `C2_thumb_right_press.png`: `only the right thumb and the edge of the right hand entering from the lower right corner, thumb pointing up and slightly left, thumb pad pressed flat as if touching a phone screen, thumb tip near the centre`
3. `C3_thumb_right_slide.png`: `only the right thumb and the edge of the right hand entering from the lower right corner, thumb bent and lying almost sideways as if sliding across a phone screen to the left, thumb tip near the centre`
4. `C4_hand_left_tool.png`: `a left hand entering from the lower left with the wrist visible, holding a small thin flat L-shaped plain steel bar like a small hex key between thumb and index finger, pressing it gently sideways, relaxed fingers`
5. `C5_hand_right_tool.png`: `a right hand entering from the lower right with the wrist visible, holding a long thin plain steel probe with a tiny hook at the tip like a pencil, tip pointing up-left toward the centre`
6. `C6_hand_right_open.png`: `a right hand entering from the lower right with the wrist visible, open and relaxed, palm down, fingers slightly apart, as if just letting go of something`

---

## D. Klienci w pełnej postaci do scenki przyjazdu (D-58, pilot: `job.wrong_floor`)
**Do czego:** scenka przyjazdu renderowana w Blenderze kończy się kadrem drzwi z klientem. Gra wycina postać z tła i wkomponowuje ją w oświetlenie sceny, dlatego **tło jest jednolite, jasnoszare, a światło miękkie z lewej góry** (jak lampa klatki). Postać musi wyglądać **jak na portrecie z gry**: dołącz portret jako obraz referencyjny (character reference), plik podany przy każdej pozycji. Format 9:16, 2K, cała postać od stóp do głów, z zapasem nad głową. ZIP: `magnific_D_wrong_floor.zip`.

Wspólny koniec każdego promptu:
```
full body from head to shoes, standing on a plain seamless light grey studio background, soft warm light from the upper left like a stairwell lamp, natural soft shadow at the feet only, photorealistic photograph, fictional person, not resembling any celebrity, no text, no logos
```
1. `D1_kazimierz_fullbody.png` (referencja: `game/assets/ui/gpt/cast/episodic/portrait_kazimierz.webp`): `Mr Kazimierz, about 68, the same man as in the reference portrait: short grey hair, rosy cheeks, warm grin, tweed jacket over a checked shirt, slightly loosened tie, coming home late from a name-day party, a little tipsy but cheerful and dignified, holding a house key in his right hand and looking at it puzzled, slight lean on one leg,`
2. `D2_teresa_fullbody.png` (referencja: `game/assets/ui/gpt/cast/episodic/portrait_teresa.webp`): `Mrs Teresa, about 72, the same woman as in the reference portrait: grey hair in a loose bun, soft quilted dressing gown over a nightdress, house slippers, woken up at night, peeking curiously with one hand on her chest, surprised but friendly,`
