# T120 — ekonomia wyposażenia po D-71

Stan `b50ea45`. Odczytano D-71, `docs/ECONOMY.md` §6a–7, `game/data/furnishings.json` oraz `tools/econ_sim.py`. Uruchomiono `python tools/econ_sim.py --careers 200 --out contrib/gpt/T120/simulation.md`; plik raportu jest pełnym wynikiem lokalnej symulacji. Ceny w repo nie zostały zmienione.

## Stan bazowy i propozycja

Wszystkie 10 przedmiotów kosztuje razem 6750 monet. Ceny i rozdziały w poniższej tabeli odpowiadają JSON. Rekomendacja: **pozostawić obecny cennik** do testów z graczami. W modelu realizuje on opisany w `docs/ECONOMY.md` cel: profil careful kupuje całość, average i clumsy większość, a najdroższa półka pozostaje celem na końcówkę.

| Przedmiot | Rozdział | Obecna cena | Proponowana cena |
|---|---:|---:|---:|
| Roślina | 1 | 150 | 150 |
| Chodnik | 1 | 300 | 300 |
| Listwa świetlna | 2 | 400 | 400 |
| Radio | 3 | 600 | 600 |
| Dyplom | 4 | 350 | 350 |
| Aksamit i tabliczki | 5 | 900 | 900 |
| Zegar | 6 | 800 | 800 |
| Kartki z podziękowaniami | 9 | 450 | 450 |
| Imadło | 10 | 1200 | 1200 |
| Półka z eksponatami | 11 | 1600 | 1600 |

Na obecnych cenach w 200 deterministycznych symulacjach na profil careful kupił wszystkie przedmioty w 200/200, average w 0/200, clumsy w 0/200. Medianowo odpowiednio kupiono 10, 9 i 9 przedmiotów; zostało 637, 1347 i 615 monet. Mediana pozostałych monet jest obliczana osobno, a nie z pojedynczej reprezentatywnej kariery. Duża pozostałość average przy 9/10 oznacza, że przy rezerwie 50 model nie uzbierał ceny półki; nie dowodzi to frustracji prawdziwych graczy.

## Test alternatywy

Dodatkowo uruchomiono w pamięci ten sam `simulate('C', profile, 200, ...)`, zmieniając wyłącznie cenę `exhibit_shelf`, przy identycznych seedach. Wyniki należy traktować jako propozycje do decyzji, nie wdrożony cennik:

| Cena półki | Całość careful | Całość average | Całość clumsy | Mediana monet average po zakupach |
|---:|---:|---:|---:|---:|
| 1600 (obecna) | 200/200 | 0/200 | 0/200 | 1347 |
| 1400 | 200/200 | 41/200 | 0/200 | 1280,5 |
| 1200 | 200/200 | 162/200 | 0/200 | 216,5 |

Jeżeli testy pokażą, że average powinien często kończyć kolekcję przed finałem, 1200 jest konkretnym wariantem do dalszego testu; to zmienia założony cel końcowy i obniża medianę rezerwy. Wariant 1400 pozostawia finałowym zakupem półkę większości średnich graczy, ale część ją kupuje. W obu wariantach zachowanie clumsy w modelu nie zmienia się w tej mierze.

## Granice wniosku

Wyniki opisują model, nie rzeczywiste sesje: założono kolejność zakupów, rezerwę na naprawy, profil, ceny narzędzi, nagrody i napiwki. Potrzebny playtest z pomiarem dobrowolnych zakupów, salda, kolejności i odczuć, a po zmianach nagród lub kolejności — nowa symulacja. W tym raporcie testowano tylko zmianę ceny półki, nie alternatywne zasady zakupów ani inne elementy wyposażenia.
