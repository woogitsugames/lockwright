from pathlib import Path
import json
from datetime import date
root=Path(__file__).resolve().parent
cards=json.loads((root/'cards.json').read_text(encoding='utf-8'))

readme='''# G11 — Kartki mistrza do samouczka Lockwright

**Data:** 5 listopada 2026 · **Zakres:** wyłącznie `contrib/gpt/G11/` · **Podstawa:** zlecenie G11 v2 oraz `docs/ONBOARDING.md` §4 (pin.s1–pin.s3), `docs/DESIGN.md` §1 i `docs/HUD.md` §4–5.

## Co wykonano

- **12 odrębnych diagramów** (S1: 6, S2: 3, S3: 3). Każdy w trzech wariantach: **PL**, **EN** i **clean** (bez dopisku): razem **36 kartek PNG**.
- **2 osobne pieczątki** `g11-stamp-pl.png` i `g11-stamp-en.png`, z nierównym tuszem i przezroczystym tłem. Ich tekst jest zgodny dosłownie ze zleceniem v2.
- **38 edytowalnych SVG** (36 kartek + 2 pieczątki), **2 arkusze zbiorcze PNG** i **skrypt odtwarzający** wszystkie grafiki.
- **Metadane** `cards.json`: etap, intencja, obydwa dopiski, opisy alternatywne w obu językach.
- Styl: schematy ołówkiem, lekko nierówne linie, szare kreskowanie, papier z bloczka z fałdkami i pinezką. Żadnego obrazu sprzętu w trakcie pracy z mechanizmem, żadnych marek, nieprzeznaczone do realnego instruktażu. Całość stworzona programowo bez generatora obrazów i bez zewnętrznych grafik.

## Układ plików

| Ścieżka | Zawartość |
|---|---|
| `png/g11-01-pl.png` … `png/g11-12-pl.png` | 12 kartek z polskimi dopiskami |
| `png/g11-01-en.png` … `png/g11-12-en.png` | 12 odpowiedników angielskich |
| `png/g11-01-clean.png` … `png/g11-12-clean.png` | 12 kartek bez dopisku (zachowane symbole etapu, numer i skala, gdy stanowią część diagramu) |
| `svg/` | Edytowalne SVG o odpowiadających nazwach (36 plików) |
| `stamps/g11-stamp-{pl,en}.{svg,png}` | Dwie osobne pieczątki, wersje wektorowe i PNG |
| `sheets/g11-contact-sheet-pl.png` | Szybki podgląd 12 schematów PL |
| `sheets/g11-contact-sheet-all-variants.png` | Porównanie 36 wariantów PL / EN / clean |
| `generate_cards.py` | Deterministyczny rysunek wektorowy i rasteryzacja, 1200 × 1500 |
| `cards.json` | Treści i opisy dostępności PL+EN |
| `build_docs.py` | Generator tej dokumentacji i listy zasobów |
| `ASSETS.md` | Manifest pochodzenia wszystkich grafik |

## Zawartość 12 kartek

| Kartka | Etap | Znaczenie samego szkicu | Powiązanie z onboardingiem |
|---|---|---|---|
'''
features={
'01':'Lewy kciuk; skala nacisku 0–100%; strzałka do góry, utrzymanie.',
'02':'Luźna kolumna → przechylona kolumna z trzema kreskami tarcia.',
'03':'Prawy kciuk: ruch w bok, następnie w górę.',
'04':'Klin szczeliny zwęża się w kolejnych dwóch stanach.',
'05':'Stopka ustawionego elementu + jeden znacznik na okrągłej skali.',
'06':'Ustawione znaczniki → pełny ruch umownej skali.',
'07':'Dwa sprężynujące elementy i jeden stawiający opór.',
'08':'Trzy momenty postępu: 1, potem 2, w końcu 3 ustawione elementy.',
'09':'Puść kciuk → opada tylko ostatni element (łagodny zrzut S2).',
'10':'Nieoczywista kolejność: tył (1) → przód (2) → środek (3).',
'11':'Przepchnięcie: klamra, zwarta sprężyna i lupa jako sygnał.',
'12':'Zwolnienie lewego kciuka → wszystkie elementy opadają (reset S3).'
}
source={
'01':'§4, S1, krok 1.2','02':'§4, S1, krok 1.2','03':'§4, S1, krok 1.3','04':'§4, S1, krok 1.3','05':'§4, S1, krok 1.3','06':'§4, S1, krok 1.4',
'07':'§4, S2, krok 2.2','08':'§4, S2, krok 2.3','09':'§4, S2, incydent 2.x','10':'§4, S3, krok 3.1–3.2','11':'§4, S3, incydent 3.x oraz §6 (lupa)','12':'§4, S3, wyjście z incydentu 3.x'}
for c in cards:
    readme+=f"| {c['id']} | {c['stage']} | {features[c['id']]} | `ONBOARDING.md` {source[c['id']]} |\n"
readme+='''
## Parametry eksportu i regeneracja

- Obszar kartki: PNG **1200 × 1500**, RGBA, **alfa = 0 poza papierem** (nie jest to pełna, nieprzezroczysta bitmapa). Pieczątki również RGBA, z alfą poza tuszem.
- Każdy plik ma mniej niż **20 MB**, obrazy nie używają czcionek jako plików dołączonych do repozytorium.
- Pismo odręczne: **Comic Neue Italic** (SIL Open Font License 1.1), używane w zainstalowanym środowisku; SVG przechowuje tekst jako edytowalny element `<text>`. Na innym komputerze przed rasteryzacją należy zainstalować ten font, np. pakiet `fonts-comic-neue` na Debianie. Projekt nie udostępnia ani nie dołącza plików fontów.
- Uruchomienie w tym katalogu: `python3 -m pip install cairosvg pillow && python3 generate_cards.py && python3 build_docs.py`. Skrypt **zastępuje** tylko wygenerowane zasoby G11. Zależności są narzędziami build-time, nie częścią gry.
- Arkusz jest narzędziem redakcyjnym. W grze należy wyświetlać pojedynczą kartkę jako **przedmiot w skórzanej zwijce**, bez pływających paneli, i respektować obszary dotykowe `HUD.md`.

## Weryfikacja

**Automatycznie sprawdzono:** 12 unikalnych scen, 36 PNG kartek, 2 PNG pieczątek, komplet 38 SVG, oba arkusze, rozmiar **1200 × 1500**, tryb **RGBA**, przezroczysty narożnik i limit rozmiaru **< 20 MB**. Podgląd PL i wariantu EN sprawdzono wizualnie; kontrast opiera się na formie, nie na barwie.

**Test na osobie nieznającej gry — NIE WYKONANO.** Nie było dostępu do niezależnego ludzkiego testera; nie należy uznawać kryterium „szkic zrozumiały bez czytania” za potwierdzone. Proponowany test: pokazać kolejno 12 wersji `clean` co najmniej 3 nowicjuszom, po 5–8 sekund każdą; bez tłumaczenia zapytać o ruch i rezultat, zaznaczyć błędy na numerach kart, a następnie poprawić niejednoznaczne rysunki. Osobno powtórzyć w rozdzielczości telefonu oraz w 50% jasności i w skali szarości (A7/A9).

## Ograniczenia i uwagi dla integracji

- To **schematy abstrakcyjnych stanów gry**, nie przekroje prawdziwych mechanizmów ani poradnik pracy przy rzeczywistych drzwiach. Celowo nie pokazano narzędzi włożonych w jakikolwiek mechanizm, zgodnie ze zleceniem v2.
- W pierwszym uruchomieniu `ONBOARDING.md` §3.3 opisuje inną, dłuższą wersję notki prawnej. Obie pieczątki mają **dokładną treść wymaganą w zleceniu v2**. Wdrożenie powinno uzgodnić ostateczny wariant ze specyfikacją onboardingu; bez ingerowania tutaj w dokumenty innych zespołów.
- W S2 puszczenie napięcia zrzuca **tylko ostatni** element, a w S3 po błędzie **wszystkie**. Kartki 09 i 12 odzwierciedlają to rozróżnienie; nie należy ich zamieniać miejscami.
- Wizualizacje są statyczne. Nie implementują sygnałów dźwiękowych, haptycznych ani animowanych stopni H1–H4 z `ONBOARDING.md`. Ruch jest sugerowany strzałkami i kolejnymi kadrami.
- Do rozważenia: wersja „clean” powinna w implementacji nadal mieć opis dostępności w etykiecie semantycznej, a nie w obrazie.
'''
(root/'README.md').write_text(readme,encoding='utf-8')

manifest='''# G11 — ASSETS / pochodzenie plików

**Data powstania:** 2026-11-05. **Autor narzędziowy:** samodzielnie napisany `generate_cards.py` (Python + CairoSVG), wykorzystujący własne prymitywy kształtów. **Generator obrazów AI:** nieużywany. **Zewnętrzne grafiki/dźwięki:** nieużywane.

**Pełny prompt:** **nie dotyczy** — materiały są generowane kodem, a nie z promptu generatora AI. Jedyny opis wejściowy to zlecenie „G11 — Kartki samouczka”, wersja 2, `cards.json` (treści i alt-teksty) oraz opis funkcji w skrypcie (wyczerpująca specyfikacja geometrii). Nie istnieje prompt do ukrycia ani do odtworzenia.

**Warunki prawne:** oryginalne procedury rysowania bez kopiowania prac z zewnątrz. Materiały dostarczone do użycia przez właściciela projektu w ramach warunków korzystania z ChatGPT/OpenAI. **Comic Neue**: Craig Rozynski i współtwórcy, licencja **SIL Open Font License 1.1** (komercyjne użycie wygenerowanych grafik dozwolone na warunkach OFL); font nie został dołączony ani przekazany. Biblioteki: CairoSVG (LGPLv3), Pillow (HPND). Ich oddzielne licencje dotyczą narzędzi build-time; generowane bitmapy nie dziedziczą automatycznie licencji narzędzi.

Każdy plik w tabeli powstał **2026-11-05** z podanego narzędzia i bez ręcznej późniejszej edycji. Render PNG to automatyczna rasteryzacja odpowiadającego SVG; arkusze są składane z plików PNG, bez retuszu.

| Plik | Narzędzie / metoda | Data | Prompt | Warunki / licencja | Edytowany po renderze? |
|---|---|---|---|---|---|
'''
for c in cards:
  for loc in ('pl','en','clean'):
    base=f'g11-{c["id"]}-{loc}'
    manifest+=f'| `svg/{base}.svg` | Python, własne ścieżki SVG | 2026-11-05 | nie dotyczy (kod) | oryginalna grafika + font OFL | nie |\n'
    manifest+=f'| `png/{base}.png` | CairoSVG, rasteryzacja własnego SVG | 2026-11-05 | nie dotyczy (kod) | oryginalna grafika + font OFL | nie |\n'
for loc in ('pl','en'):
  manifest+=f'| `stamps/g11-stamp-{loc}.svg` | Python, szkic z nierównym konturem | 2026-11-05 | nie dotyczy (kod) | oryginalna grafika + font OFL | nie |\n'
  manifest+=f'| `stamps/g11-stamp-{loc}.png` | CairoSVG, rasteryzacja własnego SVG | 2026-11-05 | nie dotyczy (kod) | oryginalna grafika + font OFL | nie |\n'
for name in ('g11-contact-sheet-pl.png','g11-contact-sheet-all-variants.png'):
  manifest+=f'| `sheets/{name}` | Python + Pillow, skład z własnych PNG | 2026-11-05 | nie dotyczy (kod) | oryginalne grafiki + font OFL | nie |\n'
manifest+='''
**Zakres manifestu:** grafiki PNG/SVG i arkusze są rozpisane indywidualnie. Pliki `cards.json`, `generate_cards.py`, `build_docs.py`, `README.md` i niniejszy manifest są danymi, kodem i dokumentacją, a nie pozyskanymi zasobami binarnymi.
'''
(root/'ASSETS.md').write_text(manifest,encoding='utf-8')
print('Docs:',len(readme),len(manifest))
