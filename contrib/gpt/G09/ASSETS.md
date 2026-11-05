# G09 — Źródła i prawa do zasobów / Assets and provenance

Data przygotowania: **2026-11-05**.

## Narzędzia, pochodzenie i warunki użycia

- Generator: natywne generowanie obrazów ChatGPT (OpenAI), bez użycia zdjęć osób rzeczywistych jako wejścia.
- Przetwarzanie: Python 3 + Pillow 12.3.0 — kadrowanie, skalowanie LANCZOS, umiarkowane wyostrzenie, maska alfa, delikatna redukcja precyzji RGB do 5/6/5 bitów przy zachowaniu alfy, arkusz zbiorczy.
- Prawa: obrazy wyjściowe podlegają aktualnym warunkom korzystania z usług OpenAI. Użytkownik może wykorzystywać wyniki zgodnie z tymi warunkami i obowiązującym prawem; generatywne obrazy nie mają gwarantowanej wyłączności, nie oznaczamy ich jako CC0. Brak logotypów i identyfikowanych prawdziwych osób nie stanowi prawnej gwarancji braku podobieństw.
- Wszystkie zasoby wynikowe były **edytowane** (przycięcie, skala, miejscami korekta kadru, kompresja). Nie są natywnymi renderami 1024/1920 generatora.

## Prompt / generowanie źródła A

Narzędzie: generator obrazów ChatGPT. Data: 2026-11-05. ID generacji: `af31a41b-752d-4a28-997a-a784abe09eac`. Zapisany opis generacji (verbatim):

> A polished composite presentation for the G09 assignment, showcasing the complete fictional **Lockwright: Pogotowie Zamkowe / Locksmith on Call** asset pack: 12 diverse characters with square portraits, transparent circular avatars, and doorway scenes, plus two images of the cat Ziemniak, all arranged in a clean four-row grid with bilingual labels. The montage also includes the full Polish-English `README.md` and `ASSETS.md`, directory structure, file-count summary, prompts, licensing and editing notes, using a warm, photorealistic tenement-building aesthetic with natural lighting, everyday clothing, no logos, clichés, or real-person references.

Uwaga: pole `prompt` w metadanych narzędzia jest puste; powyższy opis jest jedynym zapisanym pełnym tekstem opisującym generację. Kontekst źródłowy: załącznik `G09-character-portraits-fictional.md` oraz `docs/CLIENTS.md`.

## Prompt / generowanie źródła B

Narzędzie: generator obrazów ChatGPT. Data: 2026-11-05. ID generacji: `a0977922-8872-49ea-b4fc-573f175ff219`. Zapisany opis generacji (verbatim):

> This is a densely organized, photorealistic character-sheet collage for the fictional Polish game *Lockwright: Pogotowie Zamkowe / Lockwright: Locksmith on Call*, featuring 12 richly varied residents, workers, and visitors—each shown in a close portrait, circular avatar, and warm apartment-doorway scene, with bilingual caption bars in Polish and English. A footer highlights the cat Ziemniak in two poses alongside the project title and set information, all presented with realistic indoor lighting, old-building details, consistent typography, and no visible branding.

Również tu pole `prompt` w metadanych generatora jest puste. Wygenerowany arkusz zawierał błędny wiek Zosi i płeć dr Rygiel; odpowiednie postacie przypisano z alternatywnych ujęć. To nadal wizualny prototyp wymagający zatwierdzenia artystycznego.

## Lista zasobów / Asset manifest

Każdy wiersz obejmuje nazwę pliku, narzędzie, datę, odwołanie do pełnego dostępnego opisu promptu, warunki i edycję. Skróty: A/B — opis generacji powyżej; `PL` — Pillow.

| Plik | Narzędzie | Data | Prompt | Warunki | Edytowany? |
|---|---|---|---|---|---|
| `characters/01_halina/portrait.jpg` | ChatGPT + PL | 2026-11-05 | B; `docs/CLIENTS.md` §3 | OpenAI Terms | Tak — kadr, skala |
| `characters/01_halina/avatar.png` | ChatGPT + PL | 2026-11-05 | B; `docs/CLIENTS.md` §3 | OpenAI Terms | Tak — kadr, skala, alfa |
| `characters/01_halina/doorway.jpg` | ChatGPT + PL | 2026-11-05 | B; `docs/CLIENTS.md` §3 | OpenAI Terms | Tak — kadr, skala |
| `characters/02_zosia/portrait.jpg` | ChatGPT + PL | 2026-11-05 | A; `docs/CLIENTS.md` §3 | OpenAI Terms | Tak — kadr, skala |
| `characters/02_zosia/avatar.png` | ChatGPT + PL | 2026-11-05 | A; `docs/CLIENTS.md` §3 | OpenAI Terms | Tak — kadr, skala, alfa |
| `characters/02_zosia/doorway.jpg` | ChatGPT + PL | 2026-11-05 | A; `docs/CLIENTS.md` §3 | OpenAI Terms | Tak — kadr, skala |
| `characters/03_stefan/portrait.jpg` | ChatGPT + PL | 2026-11-05 | B; `docs/CLIENTS.md` §3 | OpenAI Terms | Tak — kadr, skala |
| `characters/03_stefan/avatar.png` | ChatGPT + PL | 2026-11-05 | B; `docs/CLIENTS.md` §3 | OpenAI Terms | Tak — kadr, skala, alfa |
| `characters/03_stefan/doorway.jpg` | ChatGPT + PL | 2026-11-05 | B; `docs/CLIENTS.md` §3 | OpenAI Terms | Tak — kadr, skala |
| `characters/04_roman/portrait.jpg` | ChatGPT + PL | 2026-11-05 | B; `docs/CLIENTS.md` §3 | OpenAI Terms | Tak — kadr, skala |
| `characters/04_roman/avatar.png` | ChatGPT + PL | 2026-11-05 | B; `docs/CLIENTS.md` §3 | OpenAI Terms | Tak — kadr, skala, alfa |
| `characters/04_roman/doorway.jpg` | ChatGPT + PL | 2026-11-05 | B; `docs/CLIENTS.md` §3 | OpenAI Terms | Tak — kadr, skala |
| `characters/05_lena/portrait.jpg` | ChatGPT + PL | 2026-11-05 | B; `docs/CLIENTS.md` §3 | OpenAI Terms | Tak — kadr, skala |
| `characters/05_lena/avatar.png` | ChatGPT + PL | 2026-11-05 | B; `docs/CLIENTS.md` §3 | OpenAI Terms | Tak — kadr, skala, alfa |
| `characters/05_lena/doorway.jpg` | ChatGPT + PL | 2026-11-05 | B; `docs/CLIENTS.md` §3 | OpenAI Terms | Tak — kadr, skala |
| `characters/06_marta/portrait.jpg` | ChatGPT + PL | 2026-11-05 | B; `docs/CLIENTS.md` §3 | OpenAI Terms | Tak — kadr, skala |
| `characters/06_marta/avatar.png` | ChatGPT + PL | 2026-11-05 | B; `docs/CLIENTS.md` §3 | OpenAI Terms | Tak — kadr, skala, alfa |
| `characters/06_marta/doorway.jpg` | ChatGPT + PL | 2026-11-05 | B; `docs/CLIENTS.md` §3 | OpenAI Terms | Tak — kadr, skala |
| `characters/07_zuzanna/portrait.jpg` | ChatGPT + PL | 2026-11-05 | B; `docs/CLIENTS.md` §3 | OpenAI Terms | Tak — kadr, skala |
| `characters/07_zuzanna/avatar.png` | ChatGPT + PL | 2026-11-05 | B; `docs/CLIENTS.md` §3 | OpenAI Terms | Tak — kadr, skala, alfa |
| `characters/07_zuzanna/doorway.jpg` | ChatGPT + PL | 2026-11-05 | B; `docs/CLIENTS.md` §3 | OpenAI Terms | Tak — kadr, skala |
| `characters/08_edek/portrait.jpg` | ChatGPT + PL | 2026-11-05 | B; `docs/CLIENTS.md` §3 | OpenAI Terms | Tak — kadr, skala |
| `characters/08_edek/avatar.png` | ChatGPT + PL | 2026-11-05 | B; `docs/CLIENTS.md` §3 | OpenAI Terms | Tak — kadr, skala, alfa |
| `characters/08_edek/doorway.jpg` | ChatGPT + PL | 2026-11-05 | B; `docs/CLIENTS.md` §3 | OpenAI Terms | Tak — kadr, skala |
| `characters/09_ola_krystyna/portrait.jpg` | ChatGPT + PL | 2026-11-05 | B; `docs/CLIENTS.md` §3 | OpenAI Terms | Tak — kadr, skala |
| `characters/09_ola_krystyna/avatar.png` | ChatGPT + PL | 2026-11-05 | B; `docs/CLIENTS.md` §3 | OpenAI Terms | Tak — kadr, skala, alfa |
| `characters/09_ola_krystyna/doorway.jpg` | ChatGPT + PL | 2026-11-05 | B; `docs/CLIENTS.md` §3 | OpenAI Terms | Tak — kadr, skala |
| `characters/10_wladyslaw/portrait.jpg` | ChatGPT + PL | 2026-11-05 | B; `docs/CLIENTS.md` §3 | OpenAI Terms | Tak — kadr, skala |
| `characters/10_wladyslaw/avatar.png` | ChatGPT + PL | 2026-11-05 | B; `docs/CLIENTS.md` §3 | OpenAI Terms | Tak — kadr, skala, alfa |
| `characters/10_wladyslaw/doorway.jpg` | ChatGPT + PL | 2026-11-05 | B; `docs/CLIENTS.md` §3 | OpenAI Terms | Tak — kadr, skala |
| `characters/11_rygiel/portrait.jpg` | ChatGPT + PL | 2026-11-05 | A; `docs/CLIENTS.md` §3 | OpenAI Terms | Tak — kadr, skala |
| `characters/11_rygiel/avatar.png` | ChatGPT + PL | 2026-11-05 | A; `docs/CLIENTS.md` §3 | OpenAI Terms | Tak — kadr, skala, alfa |
| `characters/11_rygiel/doorway.jpg` | ChatGPT + PL | 2026-11-05 | A; `docs/CLIENTS.md` §3 | OpenAI Terms | Tak — kadr, skala |
| `characters/12_jadwiga/portrait.jpg` | ChatGPT + PL | 2026-11-05 | B; `docs/CLIENTS.md` §3 | OpenAI Terms | Tak — kadr, skala |
| `characters/12_jadwiga/avatar.png` | ChatGPT + PL | 2026-11-05 | B; `docs/CLIENTS.md` §3 | OpenAI Terms | Tak — kadr, skala, alfa |
| `characters/12_jadwiga/doorway.jpg` | ChatGPT + PL | 2026-11-05 | B; `docs/CLIENTS.md` §3 | OpenAI Terms | Tak — kadr, skala |
| `cat/ziemniak_resting.jpg` | ChatGPT + PL | 2026-11-05 | B; `docs/CLIENTS.md` §3 | OpenAI Terms | Tak — kadrowanie/kompresja |
| `cat/ziemniak_looking_up.jpg` | ChatGPT + PL | 2026-11-05 | B; `docs/CLIENTS.md` §3 | OpenAI Terms | Tak — kadrowanie/kompresja |
| `sources/character_sheet_a.jpg` | ChatGPT + PL | 2026-11-05 | A; `docs/CLIENTS.md` §3 | OpenAI Terms | Tak — kadrowanie/kompresja |
| `sources/character_sheet_b.jpg` | ChatGPT + PL | 2026-11-05 | B; `docs/CLIENTS.md` §3 | OpenAI Terms | Tak — kadrowanie/kompresja |
| `character_contact_sheet.jpg` | ChatGPT + PL | 2026-11-05 | B; `docs/CLIENTS.md` §3 | OpenAI Terms | Tak — kadrowanie/kompresja |

**Pliki `cast.json`, `README.md` i `ASSETS.md` są dokumentacją/metadanymi**, nie zdjęciami. Wszystkie pliki obrazów mają poniżej 20 MB.
