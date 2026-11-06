# Zlecenie G23: klienci w pełnej postaci (scenka przyjazdu) i dłonie do widma

**Dla:** ChatGPT z generatorem obrazów. Repo `woogitsugames/lockwright`, zapis tylko do `contrib/gpt/G23/` (albo ZIP `Lockwright_G23.zip` dla właściciela). Zastępuje nieudane Magnific C i D (D-66).

## Zasady (najważniejsze)
1. **Jeden obraz = jedna wiadomość.** Nigdy kolaży, arkuszy, siatek, kilku ujęć obok siebie.
2. Postacie **wymyślone**, niepodobne do nikogo znanego. Bez napisów, logo, marek.
3. Przy postaciach **dołącz portret z gry jako obraz referencyjny** i edytuj go do pełnej postaci: **ta sama twarz, fryzura, wiek**. Pliki referencji: `game/assets/ui/gpt/cast/episodic/portrait_kazimierz.webp`, `portrait_teresa.webp` oraz większe oryginały `contrib/incoming/magnific/selected/portraits/portrait_kazimierz.jpg`, `portrait_teresa.jpg`.
4. Gdy twarz wyjdzie inna niż na referencji, powtórz. Gdy wyjdzie kolaż, powtórz.
5. Format: postacie **pion 2:3 (1024×1536)**, dłonie **1:1 (1024×1024)**.

## Część D: klienci w pełnej postaci (do wycięcia i wstawienia w scenę z Blendera)
Tło **jednolite jasnoszare**, bez cieni na tle poza miękkim cieniem pod stopami. Światło: **ciepła żarówka z góry i lekko z tyłu po lewej, miękkie wypełnienie od przodu** (tak świeci lampa w scenie). Cała postać od głowy do butów, z zapasem nad głową.

1. `D1_kazimierz_fullbody.png` (referencja: portret Kazimierza): *Edit the reference portrait into a full-body photo of the same man (same face, hair, age ~68): tweed jacket over a checked shirt, slightly loosened tie, dark trousers, worn leather shoes; coming home late from a name-day party, a little tipsy but cheerful and dignified, holding a house key in his right hand and looking at it puzzled, weight on one leg. Plain light-grey seamless studio background, warm light from above and slightly behind-left like a single stairwell bulb, soft neutral fill from the front, soft shadow under the feet only. Photorealistic, no text.*
2. `D2_teresa_fullbody.png` (referencja: portret Teresy): *Edit the reference portrait into a full-body photo of the same woman (same face, hair, age ~72): grey hair in a loose bun, soft quilted dressing gown over a nightdress, house slippers, woken up at night, peeking curiously with one hand on her chest, surprised but friendly. Same background and lighting as above. Photorealistic, no text.*

## Część C: dłonie do „widma” w samouczku
Gra wycina sylwetkę, rozmywa i robi z niej cień, więc: **czysto białe tło, ostry kontur, widok prosto z góry, dokładnie 5 palców**, dłoń ok. 55-letniego rzemieślnika, bez pierścionków i zegarka. Prompty jak w `docs/handoff/gpt5/G22-ghost-thumb-hand.md` (6 ujęć: `thumb_left_press`, `thumb_right_press`, `thumb_right_slide`, `hand_left_tool`, `hand_right_tool`, `hand_right_open`). **To muszą być fotografie, nie rysunki ani grafika proceduralna** (G22 odrzucono właśnie za to).

## Oddanie
`contrib/gpt/G23/images/<nazwa>.png` + `ASSETS.md` (narzędzie, data, pełny prompt, użyta referencja, edycje) + `README.md` po polsku (co się udało, czego nie i dlaczego).
