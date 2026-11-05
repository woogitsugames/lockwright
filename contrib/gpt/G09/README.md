# G09 — Portrety postaci fikcyjnych / Fictional character portraits

Projekt: **Lockwright: Pogotowie Zamkowe / Lockwright: Locksmith on Call**. Stan: **zestaw prototypowy, do oceny artystycznej**. Data: 2026-11-05.

## Wykonane

- **12 slotów fabularnych** z `docs/CLIENTS.md` §3: po 1 portrecie `1024×1024` (JPG), 1 awatarze `1024×1024` (PNG/RGBA z przezroczystością poza kołem (kanały RGB 5/6/5-bit, alfa 8-bit)) i 1 kadrze „w drzwiach” `1080×1920` (JPG) = **36 plików**.
- Pozycja 9 to wspólne ujęcia **Oli i mamy Krystyny** (dwie osoby, jeden slot); łącznie na fotografiach występuje 13 bohaterów.
- **Kot Ziemniak:** dwa różne ujęcia (`cat/`).
- **Arkusz zbiorczy:** `character_contact_sheet.jpg` (wizerunki, avatar, kadr drzwiowy).
- **Źródła:** dwie wyjściowe plansze (`sources/`); pełny wykaz, opis generacji, data, warunki i edycje w `ASSETS.md`.
- **Metadane i18n:** `cast.json` (PL i EN, identyfikatory, ścieżki plików).

## Obsada i pliki

| Postać PL / EN | Opis | Portret | Awatar | W drzwiach |
|---|---|---|---|---|
| Pani Halina / Mrs Halina | 81, emerytka, rosół i kapcie | `characters/01_halina/portrait.jpg` | `characters/01_halina/avatar.png` | `characters/01_halina/doorway.jpg` |
| Pani Zosia / Mrs Zosia | ok. 75, sąsiadka Haliny | `characters/02_zosia/portrait.jpg` | `characters/02_zosia/avatar.png` | `characters/02_zosia/doorway.jpg` |
| Pan Stefan / Mr Stefan | 67, prowadzi kiosk | `characters/03_stefan/portrait.jpg` | `characters/03_stefan/avatar.png` | `characters/03_stefan/doorway.jpg` |
| Pan Roman / Mr Roman | 58, administrator osiedla | `characters/04_roman/portrait.jpg` | `characters/04_roman/avatar.png` | `characters/04_roman/doorway.jpg` |
| Aspirant Lena Sowa / Officer Lena Sowa | 39, dzielnicowa (bez oznaczeń) | `characters/05_lena/portrait.jpg` | `characters/05_lena/avatar.png` | `characters/05_lena/doorway.jpg` |
| Marta / Marta | 34, graficzka i opiekunka kota | `characters/06_marta/portrait.jpg` | `characters/06_marta/avatar.png` | `characters/06_marta/doorway.jpg` |
| Zuzanna Wilk / Zuzanna Wilk | 20, studentka konserwacji zabytków | `characters/07_zuzanna/portrait.jpg` | `characters/07_zuzanna/avatar.png` | `characters/07_zuzanna/doorway.jpg` |
| Pan Edek / Mr Edek | 63, portier akademika | `characters/08_edek/portrait.jpg` | `characters/08_edek/avatar.png` | `characters/08_edek/doorway.jpg` |
| Ola i pani Krystyna / Ola and Mrs Krystyna | 38, nauczycielka, z matką Krystyną | `characters/09_ola_krystyna/portrait.jpg` | `characters/09_ola_krystyna/avatar.png` | `characters/09_ola_krystyna/doorway.jpg` |
| Pan Władysław / Mr Władysław | 84, nauczyciel mistrza Henryka | `characters/10_wladyslaw/portrait.jpg` | `characters/10_wladyslaw/avatar.png` | `characters/10_wladyslaw/doorway.jpg` |
| Dr Anna Rygiel / Dr Anna Rygiel | kuratorka Muzeum Techniki | `characters/11_rygiel/portrait.jpg` | `characters/11_rygiel/avatar.png` | `characters/11_rygiel/doorway.jpg` |
| Pani Jadwiga / Mrs Jadwiga | emerytowana wychowawczyni klasy 3b | `characters/12_jadwiga/portrait.jpg` | `characters/12_jadwiga/avatar.png` | `characters/12_jadwiga/doorway.jpg` |

## Kontrola jakości i ograniczenia

- Rozmiary plików docelowych zostały zweryfikowane, podobnie jak kanał alfa awatarów. Nie użyto zdjęć referencyjnych prawdziwych ludzi, logotypów ani czytelnych oznaczeń służbowych.
- **Istotne ograniczenie:** generator zwrócił zbiorcze arkusze 1536×1024 zamiast osobnych portretów w rozdzielczości produkcyjnej. Wycięte ujęcia zostały skalowane do wymaganych wymiarów, więc mają **niższą efektywną szczegółowość** niż natywne 1024×1024 i 1080×1920. To materiał do oceny składu, nie do ostatecznego eksportu gry.
- Pierwotne podpisy/generacje były niezgodne z bio (Zosia za młoda, dr Anna Rygiel przedstawiona jako mężczyzna). Skorygowano dobór wizerunków z obu arkuszy: Zosia = starsza kobieta z A, Rygiel = dorosła kobieta z A, Zuzanna = młoda kobieta z B.
- Wspólny portret Oli i Krystyny może sugerować młodszy wiek Oli niż zapisane 38 lat. Niezbędne dodatkowe ujęcia do akceptacji finalnej.
- Dwa kadry tej samej postaci w arkuszu mogą zawierać drobne różnice twarzy/stroju. Przed publikacją należy zapewnić ścisłą tożsamość między ujęciami, ocenić zgodność wieku, charakteru i brak podobieństwa do osób znanych.
- Próba uproszczenia kadrów zachowała naturalne wnętrza, bez neonów, nazw marek, policyjnych emblematów, UI i estetyki przestępczej.

## Sugestie na iterację produkcyjną

- Wygenerować **oddzielne, natywne** obrazy postaci 1024×1024 i 1080×1920 ze spójnym ref. seed/character sheet dla każdego bohatera, zamiast kadrowania kolaży.
- Dla dr Rygiel dodać muzeum i jasne rękawiczki, dla Jadwigi kontekst szkoły, dla Zosi wygląd około 75 lat, dla Oli około 38 lat.
- Dla Ziemniaka zablokować umaszczenie i proporcje we wszystkich kadrach.

## Scope / własność plików

Wszystkie zmiany ograniczone do `contrib/gpt/G09/`. Inne katalogi projektu nie były modyfikowane.
Uwaga do zespołu: `docs/CLIENTS.md` §3 liczy **12 pozycji fabularnych**, ale 13 różnych osób z powodu Oli i Krystyny. Nie trzeba zmieniać tabeli, jeśli oba ujęcia pozostają wspólne.
