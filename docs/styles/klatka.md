# Kierunek: Klatka schodowa / Stairwell

**Typ:** fizycznie oświetlony, realistyczny (three.js w makiecie; w grze PBR w silniku).

## Idea
**Klatka schodowa: prawdziwy metal w prawdziwym miejscu, a stany zaznacza kreda ślusarza.**

Zamek pokazujemy w przekroju skrzydła drzwi w kamienicy, w ciepłym świetle żarówki z minutnika. Realizm daje wiarygodne wyczucie materiału: satynowa stal, mosiądz z patyną, chropowate żelazo szyldu, drewno drzwi. Fotorealizm sam nie tłumaczy stanów, dlatego na wierzch nakładamy **warstwę kredy**, czyli znaki, które fachowiec stawia na drzwiach. To ten sam słownik znaków co w `DESIGN.md`: kreski tarcia, klin, klamra, przerywany obrys szpulki i podkreślenie stopki.

Pasuje do Lockwright z dwóch powodów:
- Przekrój jest czytelny, bo komory i kanał to głęboka czerń (15:1 do kredy, 9:1 do stali), a elementy to jasny metal o różnym walorze.
- Miejsce akcji (lamperia, emaliowane numery, posadzka w szachownicę, torba na wycieraczce) od razu mówi „pogotowie u ludzi w domu”, a nie „włamanie” ani „warsztat”.

Celowo nie stawiamy zamka na drewnianym blacie warsztatu, bo tę scenografię mają już Unlokee i Key Master.

## Paleta (sprawdzona: `mockups/klatka/palette.json`, 0 FAIL, także protan/deutan/tritan)

| Nazwa | Hex | Rola |
|---|---|---|
| Lamperia | `#3F5A4C` | dolna, olejna część ściany. Tło menu i pasków |
| Ściana | `#D9D2C2` | górna, klejowa część ściany. Pole wordmarku |
| Pasek | `#7A2E22` | lamperyjna linia podziału ściany, rękojeści, akcent |
| Emalia | `#F3EFE6` | tabliczki i przyciski (jak numery mieszkań) |
| Granat emalii | `#1E2A33` | tekst na emalii, przycisk główny |
| Kreda | `#F1EEE6` | warstwa znaków stanu |
| Filc | `#2A2622` | strefy kciuków |
| Mosiądz UI | `#C9A35E` | gałka napięcia, monety (tylko kontur) |
| Stal / Mosiądz / Zagłębienie / Drewno | `#B5B6B2` / `#A7854A` / `#15130F` / `#6A4026` | średnie walory renderu do kontroli kontrastu |

Wyniki kontrastu (WCAG): granat na emalii 12,8:1, kreda na filcu 13:1, emalia na lamperii 6,6:1, stal na zagłębieniu 9,1:1, mosiądz na zagłębieniu 5,4:1, kreda na drewnie 7,6:1. Linia podziału to ciemna szczelina 4 dp między jasną stalą a mosiądzem, bez speculara (wysoka szorstkość krawędzi).

## Typografia
- **Nagłówki: Bona Nova** (OFL; cyfrowa wersja „Bony” Andrzeja Heidricha). To polska antykwa o ciepłym, „emaliowanym” charakterze, użyta w tabliczkach, wordmarku i kredowych literach.
- **Tekst: Atkinson Hyperlegible Next** (OFL), dla czytelności liczb, stawek i drobnych opisów na telefonie. Cyfry zawsze nautyczne (lining), bo Bona Nova ma domyślnie cyfry nautyczne o wyglądzie „o”.

## Materiały UI i język ikon
- **Przyciski to emaliowane tabliczki numerów mieszkań:** kremowa emalia, podwójna granatowa ramka, odpryski na brzegach. Przycisk główny jest w negatywie.
- Pauza to **przycisk minutnika** światła na klatce.
- Karty i notatki to **papier**: kartka dyspozytora przyklejona taśmą do drzwi, kwit zlecenia z perforacją i niebieską liniaturą.
- Ikony: linia 1,8–2,2 dp, granat na emalii, rysowane pod grę (dowód, sąsiadka, umowa, rodziny zamków jako schematyczne przekroje).

## Wygląd mechanizmu

| Materiał | Walor | Faktura i szorstkość |
|---|---|---|
| Stal (obudowa) | najjaśniejszy | szczotkowana poziomo, roughness 0,55, rysy |
| Mosiądz (rdzeń, piny dolne) | średni | szczotkowany pionowo, roughness 0,58, patyna |
| Stal hartowana (piny górne) | średni chłodny | gładsza, roughness 0,42 |
| Żelazo (szyld) | ciemny | matowe, roughness 0,82, bez odblasków |
| Drewno (drzwi) | średni ciepły | słoje, przetarcia |

Bez chromu: metalness 0,7–0,8 i miękkie otoczenie (PMREM, intensywność 0,3–0,55). Bez bloomu, bez tone-mappingu z poświatą.

## HUD diegetyczny
- **Napięcie:** czoło wkładki w żelaznym szyldzie. Skala jest wygrawerowana na pierścieniu, a kąt szczeliny i napinacza pokazuje obrót rdzenia. Głęboka kreska oznacza false set („za głęboko — popuść”, kredą).
- **Życia:** skórzana zwijka na 3 wytrychy. Brak wytrycha to puste, odciśnięte gniazdo.
- **Zużycie:** zadziory na końcówce wytrycha w zwijce i w przekroju.
- **Postęp:** liczba ustawionych pinów to podziałki obrotu rdzenia. W trybie Zleceń w nagłówku jest emaliowana tabliczka mieszkania.

## Realizacja kodu stanów (DESIGN.md)

| Stan | W tym stylu |
|---|---|
| swobodny | pin w osi komory, równe zwoje, zero kredy |
| binding | pin dociśnięty do ściany, 3 kreski kredy tarcia przy krawędzi |
| near_shear | dwa trójkąty kredy zbliżają się do linii |
| set | pin górny na półce rdzenia, kredowe podkreślenie stopki, rdzeń +1 podziałka |
| false set | szpulka z talią w szczelinie, przerywany kredowy obrys, rdzeń +2 podziałki |
| counter_rotate | czoło wkładki i napinacz cofają się (animacja), kredowy łuk wstecz |
| overset | sprężyna ściśnięta zwój w zwój (jednolita bryła), kredowa klamra nad komorą |
| stress | wytrych realnie wygięty, 1–3 kredowe rysy w poprzek zgięcia |
| break | końcówka zostaje w kanale, w zwijce pojawia się puste gniazdo |

Kreda w skali szarości jest bielą na czerni lub średnim tle, więc działa bez koloru (zob. `png/*.gray.png`, `*.dim.png`).

## Ruch i dźwięk
- Ruch fizyczny i krótki (120–200 ms): pin siada na półce bez odbicia, sprężyna gaśnie krytycznie tłumiona. Kreda dopisuje się „pociągnięciem” w 150 ms.
- Brzmienie: suche kliknięcia mosiądzu, wysoki jęk stali przy stresie, pogłos klatki schodowej jako tło (krótki reverb płytowy). Tryb „w ciemności”: zgasł minutnik.
- Haptyka według `TECH.md`. Gaśnięcie minutnika to długi, miękki wzorzec.

## Marka
- **Wordmark:** Bona Nova Bold, „wright” podkreślone paskiem lamperii (`#7A2E22`).
- **Ikona:** jeden pin w przekroju (stal, mosiądz, sprężyna) na lamperii z paskiem, z kredową linią podziału. W siatce sklepu to jedyna zielono-kremowa ikona wśród czarno-złotych kłódek, tarcz sejfów i fioletowych gradientów (`png/05-brand.*`).
- **Menu:** podest przed drzwiami nr 14, kartka od dyspozytora na drzwiach, torba na posadzce, emaliowane tabliczki jako przyciski.

## Ocena unikalności
- **Minigry z dużych RPG** (czoło zamka i dziurka na czerni) oraz **Thief Simulator** (drzwi z perspektywy włamywacza): u nas przekrój i ton pomocy. Kreda zamiast pasków.
- **Museum of Mechanics:** muzealne, sterylne gabloty. U nas żywe miejsce i ludzie.
- **Lockpick 101 / Lock Pick 3D:** hyper-casual, chrom i złoto. U nas satynowy metal i realna scenografia polskiej kamienicy.
- **Unlokee:** blueprint i drewniany blat. **Key Master:** brązowy warsztat. **Shear Line:** granat ze świecącymi pinami. My nie mamy blatu ani świecenia, za to mamy lamperię, emalię i kredę.

## Ryzyka i koszt produkcji
- **Wydajność:** PBR, cienie i PMREM na tanim Androidzie wymagają spike'u 4 z `TECH.md`. Plan B: wypiekane oświetlenie i matcapy (wygląd zostaje, koszt GPU spada).
- **Koszt treści:** każda rodzina wymaga modeli 3D. Taniej niż ilustracja ręczna, bo części (pin, sprężyna, płytka, dźwignia) są parametryczne i generowane z danych zamka.
- **Ryzyko „za realne”:** realizm może sugerować instrukcję. Mitygacja: wymyślone proporcje, kreda jako język gry, notka „to gra, nie kurs”.
- Lokalny koloryt (lamperia) może być mniej czytelny za granicą. Akceptujemy to jako charakter, a sceny belgijskie dostają własne klatki.

## Lista PNG (`mockups/klatka/png/`)
`01-lock`, `02-workshop`, `03-job`, `04-menu`, `05-brand`, każdy w wariantach `.portrait.png` (412×915 @2x), `.landscape.png` (915×412 @2x), `.portrait.gray.png`, `.portrait.dim.png`.
