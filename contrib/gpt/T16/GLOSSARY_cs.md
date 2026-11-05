# GLOSSARY_cs — słowniczek czeski Lockwright

**Status:** wersja robocza do korekty przez native speakera (cs-CZ). Źródło: EN w `game/i18n/strings.csv`, `game/i18n/content.csv` i `store/listing.md`, PL pomocniczo.

## Reguła zwracania się do gracza

**Interfejs, samouczek i teksty sklepowe: czeskie „tykání”.** Krótkie formy w 2. osobie liczby pojedynczej (np. „Otevři“, „Zkus“, „Počkej“, „Co cítíš?“) brzmią naturalnie w grze na telefonie, oszczędzają miejsce i utrzymują spokojny głos mistrza. Nie używać „Vy“ w systemowych komunikatach do gracza.

**Dialogi w świecie gry: „vykání” w rozmowach ślusarza z dorosłymi klientami**, chyba że relacja bohaterów uzasadnia inaczej; do dziecka można mówić na „ty”. Postaci takie jak Halina mogą mówić czule i potocznie. **Notatki w zeszycie: 1. osoba liczby pojedynczej**, jako prywatne zapiski ślusarza. Nie zamieniać uprzejmych odmów w oskarżenia. Zachować polskie imiona własne i znaki (Władysław, Zuzanna, Świątniki).

## Słowniczek terminologiczny

| # | EN | PL — odniesienie | CS — preferowana forma | Uwagi |
|---:|---|---|---|---|
| 1 | locksmith | ślusarz | **zámečník** | Bohater wykonuje legalne zlecenia. |
| 2 | locksmith on call | pogotowie zamkowe | **zámečník v terénu** | W tytule gry; nie dodawać obietnicy całodobowej dostępności. |
| 3 | lock | zamek | **zámek** | Neutralny mechanizm, bez marek. |
| 4 | padlock | kłódka | **visací zámek** | Nie `zámek` bez określenia w gablocie historycznej. |
| 5 | lock cylinder | wkładka zamka | **cylindrická vložka** | W skrótach: `vložka`. |
| 6 | core / plug | rdzeń | **jádro vložky** | W luźnych opisach: `jádro`. |
| 7 | key | klucz | **klíč** | |
| 8 | keyhole | otwór na klucz | **klíčová dírka** | |
| 9 | pick / lock pick | wytrych | **planžeta** | Termin konsekwentny w UI, fabule i sklepie. |
| 10 | hook pick | wytrych hakowy | **háčková planžeta** | Nazwa narzędzia. |
| 11 | tension wrench | napinacz | **napínák** | Nie mylić z `klíč`. |
| 12 | angled tension wrench | napinacz kątowy | **zahnutý napínák** | `tool.tw_angle.name`. |
| 13 | bar tension wrench | napinacz listwowy | **plochý napínák** | `tool.tw_bar.name`. |
| 14 | tension | napięcie | **napětí** | Kontekst wyłącznie mechaniki fikcyjnej gry. |
| 15 | binding | wiązanie elementu | **váznutí** | Nie tłumaczyć jako prawne „svazování“. |
| 16 | binding pin | wiążący pin | **váznoucí stavítko** | W opisie może być `stavítko, které vázne`. |
| 17 | pin | pin / kołek | **stavítko** | Ważne: zwykle NIE `špendlík`. |
| 18 | pin stack | stos pinów | **soustava stavítek** | W tekstach skracać do `stavítka`. |
| 19 | upper pin | górny pin | **horní stavítko** | |
| 20 | lower pin | dolny pin | **dolní stavítko** | |
| 21 | wooden pin | drewniany kołek | **dřevěné stavítko** | Nie mylić z narzędziem `kolík`. |
| 22 | shear line | linia podziału | **dělicí rovina** | Stała postać; nie `čára střihu`. |
| 23 | near shear | blisko linii podziału | **blízko dělicí roviny** | Stan mechanizmu. |
| 24 | set / clean set | ustawienie pinu | **správné usazení** | Czasownik: `usadit stavítko`. |
| 25 | false set | fałszywe osadzenie | **falešné usazení** | Stan; nie `nepravý zámek`. |
| 26 | spool pin | pin szpulowy / szpulka | **cívkové stavítko** | Stała nazwa dla fikcyjnego elementu. |
| 27 | serrated pin | pin ząbkowany | **ozubené stavítko** | W kontekście drobnych kliknięć. |
| 28 | overset | przepchnięcie | **přetlačení stavítka** | Nie `otevření` ani `překročení`. |
| 29 | counter-rotation | kontrrotacja | **zpětné pootočení** | Zachować sens reakcji mechanizmu. |
| 30 | drop / dropped pins | zrzut pinów | **pád stavítek** | Nie pomylić z upuszczeniem przedmiotu. |
| 31 | stress | naprężenie / stan krytyczny | **přetížení** | Ostrzeżenie o ryzyku uszkodzenia planžety. |
| 32 | break / broken pick | złamanie wytrycha | **zlomení planžety** | `zlomená planžeta`. |
| 33 | wear | zużycie | **opotřebení** | Stan narzędzia. |
| 34 | burr | zadzior | **otřep** | `otřepy` w UI lupy. |
| 35 | spring | sprężyna | **pružina** | |
| 36 | ward / warded lock | stała przeszkoda / zamek piórowy | **pevná překážka / zámek s pevnými překážkami** | Opisowe, bez marek. |
| 37 | wafer | płytka / zastawka płytkowa | **lamela** | |
| 38 | wafer lock | zamek płytkowy | **lamelový zámek** | |
| 39 | lever | dźwignia | **páka** | |
| 40 | lever lock | zamek dźwigniowy | **pákový zámek** | |
| 41 | gate | bramka / wycięcie | **výřez** | Wycięcie w elemencie, nie „brána“ budynku. |
| 42 | false gate | fałszywa bramka | **falešná drážka** | Spójne z ekranem optyki. |
| 43 | detector | detektor | **detektor** | Mechanizm wykrywania manipulacji w fikcyjnej grze. |
| 44 | detector trip | zadziałanie detektora | **spuštění detektoru** | |
| 45 | reset | reset / odblokowanie stanu | **reset** | W ustawieniach: `obnovit`. |
| 46 | disc lock | zamek dyskowy | **kotoučový zámek** | |
| 47 | ring lock | zamek pierścieniowy | **kroužkový zámek** | |
| 48 | shackle | kabłąk | **třmen** | |
| 49 | bolt | rygiel / zasuwa | **závora** | |
| 50 | latch | zapadka | **západka** | |
| 51 | combination | szyfr / kombinacja | **kombinace** | |
| 52 | time lock | zamek czasowy | **časový zámek** | |
| 53 | watchmaker's loupe | lupa zegarmistrzowska | **hodinářská lupa** | |
| 54 | microscope | mikroskop | **mikroskop** | `dílenský mikroskop` w nazwie narzędzia. |
| 55 | borescope | wziernik | **inspekční endoskop** | Nazwa narzędzia; opis: hluboké prvky. |
| 56 | haptics | haptyka | **hmatová odezva** | `vibrace` tylko gdy chodzi o drgania silnika. |
| 57 | vibration motor | silnik wibracyjny | **vibrační motor** | Opis Google Play. |
| 58 | sound effect | efekt dźwiękowy | **zvukový efekt** | |
| 59 | cutaway | przekrój | **řez mechanismem** | |
| 60 | high contrast | wysoki kontrast | **vysoký kontrast** | |
| 61 | chalk markings | oznaczenia kredą | **křídové značky** | |
| 62 | in the dark | tryb „w ciemności” | **potmě** | Nazwa trybu w UI. |
| 63 | tutorial / lesson | samouczek / lekcja | **výuka / lekce** | W nagłówku: `Výuka — cvičný zámek`. |
| 64 | challenge | wyzwanie | **výzva** | |
| 65 | tier | poziom trudności | **úroveň** | |
| 66 | workshop | warsztat | **dílna** | Nie `pracovna`. |
| 67 | workbench | stół warsztatowy | **pracovní ponk** | Krócej `ponk`. |
| 68 | tool roll | zwijka narzędzi | **(kožené) pouzdro** | W sklepie i notatkach. |
| 69 | showcase | gablota | **vitrína** | |
| 70 | notebook | zeszyt mistrza | **zápisník** | `mistrův zápisník`. |
| 71 | master | mistrz | **mistr** | |
| 72 | shift | dyżur | **směna** | |
| 73 | endless shift | tryb ciągły | **nekonečná směna** | |
| 74 | job / contract | zlecenie | **zakázka** | |
| 75 | right to enter | prawo wejścia | **právo vstupu** | Neutralne, bez sugestii porady prawnej. |
| 76 | check evidence | sprawdź dowody | **ověřit doklady** | Samo okazanie nie przesądza o prawie wejścia. |
| 77 | witness | świadek | **svědek** | |
| 78 | building manager | zarządca budynku | **správce domu** | W dialogach `správkyně domu` dla Elżbiety. |
| 79 | lease agreement | umowa najmu | **nájemní smlouva** | |
| 80 | deed | akt własności | **list vlastnictví** | Funkcja dowodowa w grze; nie utożsamiać z poradą prawną dla konkretnego kraju. |
| 81 | inheritance document | dokument spadkowy | **dědický dokument** | |
| 82 | receipt | paragon | **účtenka** | |
| 83 | invoice | faktura | **faktura** | |
| 84 | bailiff | komornik | **soudní vykonavatel** | Kontekst jurysdykcji pozostaje niesprecyzowany. |
| 85 | decline a job | odmówić zlecenia | **odmítnout zakázku** | Uprzejmy ton, nie oskarżenie. |
| 86 | clean opening | otwarcie bez śladów | **otevření beze stop** | |
| 87 | bill / fee | rachunek / opłata | **účet / cena** | Unikać obietnicy stawki. |
| 88 | coins | monety | **mince** | Przy liczbach stosować etykietę przed licznikiem, aby ominąć odmianę. |
| 89 | offline | offline | **offline** | W opisie sklepu. |
| 90 | Potato (cat) | Ziemniak (kot) | **Brambora** | Imię kota lokalizowane konsekwentnie. |

## Zasady redakcyjne

- **Klucze i placeholdery:** nigdy nie tłumaczyć `key`, `{n}`, `{0}`, nazw zmiennych, identyfikatorów, licencji ani nazw plików.
- **Nazwy własne:** zachować pierwotne polskie znaki i nazwy miast (Saint-Gilles, Charleroi, Liège, Świątniki); osoby historyczne pozostają pod imionami oryginalnymi.
- **Nazwy narzędzi:** krótkie, opisowe; wyłącznie fikcyjne mechanizmy, brak nazw handlowych.
- **Brak kursu otwierania zamków:** opisy stanów mają charakter narracyjny i encyklopedyczny.
- **Wariant sklepu A:** wyłącznie tekst warunkowy — nie zakładać ceny ani modelu monetyzacji.
- **Do sprawdzenia przez native speakera:** naturalność `bekináž` (beguinage), odmiana nazwisk i imion, lokalizowane imię kota `Brambora`, wybór `list vlastnictví` przy ogólnej jurysdykcji, techniczne `cívkové stavítko` i `falešné usazení`.
