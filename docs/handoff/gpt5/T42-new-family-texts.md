# Zlecenie T42: teksty dla 8 nowych rodzin zamków (nazwy, podpowiedzi, pierwsza lekcja, gablota)

**Dla:** ChatGPT (tekst). Repo `woogitsugames/lockwright`, gałąź `main`. Jeśli nie możesz pisać do repo, oddaj ZIP właścicielowi.
Zapisujesz **tylko** w `contrib/gpt/T42/`. Raport `README.md` po polsku. Commity `contrib/gpt/T42: <opis> [skip ci]`.

## Po co
Gra dostała 8 nowych mechanizmów (decyzje D-59/D-60 w `docs/DECISIONS.md`). Ekrany już działają, ale gracz nie ma
nazw rodzin, krótkiej podpowiedzi, kredowych kroków pierwszej lekcji ani notki w gablocie. Mechanizmy są **wymyślone**,
opisane na poziomie encyklopedycznym (`docs/LOCKS.md` §2.18–2.25, `docs/research/new-families.md`).

## Zasady tonu (obowiązkowe)
- Ciepło i legalnie: ślusarz pomaga, sprawdza prawo do lokalu. Zero słów o włamaniu, „hakowaniu”, „łamaniu zabezpieczeń”.
- Zero marek i nazw produktów (zamków, sejfów, samochodów). Postacie historyczne i patenty tylko w gablocie, jak w
  istniejących notkach (`game/data/showcase/*.json`).
- To gra, nie kurs: żadnych instrukcji do realnych zamków, wymiarów, nazw narzędzi ze sklepów.
- **PL „pin”:** element zamka bębenkowego to zawsze **„pin”** (także „pin teleskopowy”, „pin magnetyczny”).
  **„Kołek” tylko w zamku drewnianym** (tu: `egyptian`). DE: „Stift”, EN: „pin”.
- Krótko, w głosie mistrza z zeszytu: spokojnie, konkretnie, z lekkim humorem. Bez wykrzykników poza „Klik!”.

## Rodziny i sterowanie (skrót)
Lewy kciuk = napięcie/docisk (w trybie „Napięcie automatyczne” trzyma je gra), prawy kciuk w bok = wybór elementu,
prawy w górę/dół = ruch elementu.

| id | robocza nazwa PL / EN | zlecenia | co robi gracz | pułapka (czego uczy) |
|---|---|---|---|---|
| `dial_safe` | sejf z pokrętłem / dial safe | antykwariusz t1, sejf wujka t2 | prawy kręci pokrętłem jak kółkiem, lewy dociska klamkę i „nasłuchuje” | kolejne koła łapią się po pełnym obrocie; zatrzymać koło w bramce |
| `combo` | zamek z kółkami / thumbwheel lock | rower Kuby t1, kapsuła czasu t3 | prawy w bok = kółko, góra/dół = toczenie; lewy = lekki ciąg kabłąka | pod ciągiem za szybko = kółko przeskakuje wcięcie, trzeba wolniej |
| `dimple` | wkładka nawiercana / dimple cylinder | kamienica w Brukseli t2 | jak piny, dwa rzędy, płaski docisk | pin teleskopowy: najpierw tuleja, potem węższy pin w środku |
| `disc_detainer` | zamek tarczowy / disc lock | fiński marynarz t2 | lewy = lekki moment, prawy w bok = tarcza, góra/dół = obrót tarczy w obie strony | przekręcona tarcza: listwa się unosi, trzeba cofnąć |
| `egyptian` | zasuwa drewniana / wooden pin bolt | domek dla lalek t1 | prawy unosi kołki, lewy ciągiem wysuwa rygiel | kołek za wysoko klinuje się; pchnąć rygiel lekko do środka |
| `axial_slider` | zamek suwakowy / axial slider | biurko t2 | widok z czoła, suwaki dookoła; prawy **wciska** suwak w dół | fałszywe wcięcie: rdzeń lekko cofa się pod kciukiem |
| `time_lock` | zamek czasowy (naprawa) / time lock repair | muzeum t2 | **naprawa, nie otwieranie**: lewy nakręca sprężynę w paśmie, prawy osadza koła po kolei | za mocno nakręcone = rytm się sypie; równy tik przez chwilę = zegar chodzi |
| `magnetic` | zamek z pinami magnetycznymi / magnetic pin lock | nocna pielęgniarka t1 | sonda magnetyczna zamiast haczyka; prawy prowadzi pin polem | pin rusza z opóźnieniem: prowadzić płynnie, nie szarpać |

Istniejące klucze (popraw, jeśli możesz lepiej; zachowaj klucz): `lock.dial_hint`, `lock.combo_hint`, `lock.disc_hint`
w `game/i18n/strings.csv`. Wzorzec tonu i długości: `tutorial.s1_*`, `tutorial.say_*`, `lock.wafer_coach`.

## Zadanie
### 1. `contrib/gpt/T42/family_texts.csv` — nagłówek `keys,en,pl,de`
Dla każdej z 8 rodzin (`<id>` jak w tabeli):
- `family.<id>.name` — krótka nazwa dla gracza, ≤ 24 znaki (lista zleceń, gablota);
- `family.<id>.short` — jedno zdanie „co to za zamek”, ≤ 70 znaków;
- `lock.<id>_hint` — **jedna** podpowiedź na ekranie zamka, **≤ 56 znaków** w każdym języku (2 linie na 412 dp);
  dla `dial_safe`, `combo`, `disc_detainer` użyj istniejących kluczy `lock.dial_hint`, `lock.combo_hint`, `lock.disc_hint`;
- `lock.<id>_hint_auto` — wariant dla trybu „Napięcie automatyczne”, tylko gdy tekst o lewym kciuku przestaje pasować;
- `tutorial.<id>.step1` … `step5` — kroki kredowe pierwszej lekcji, **≤ 56 znaków** każdy: (1) co robi lewy kciuk,
  (2) co robi prawy, (3) jak brzmi/wygląda opór, (4) pułapka rodziny i jak z niej wyjść, (5) otwarcie + krótka pochwała
  (`time_lock`: „zegar chodzi”, nie „otwarte”). Wariant `_auto` tylko dla kroku 1, jeśli trzeba.
Placeholdery `{…}` nie występują. DE: forma „du” w podpowiedziach (jak w `strings.csv`).

### 2. `contrib/gpt/T42/LESSONS.md` — pierwsza lekcja rodziny (po polsku)
Dla każdej rodziny jedna tabela w stylu `docs/ONBOARDING.md` §8: **Uczy** | **Przebieg (skrót)** | **Pułapka i eskalacja**
(H1 drgnięcie elementu, H2 widmo kciuka pokazuje gest, H3 znak kredą, H4 ręka mistrza raz). 15–40 s na lekcję.
Pisz tylko o tym, co gra pokazuje (kształt, ruch, dźwięk, haptyka razem; nigdy sam kolor, nigdy sama haptyka).
Bez zielonych ptaszków, czerwonych X i pasków wytrzymałości.

### 3. Gablota: `contrib/gpt/T42/showcase/`
- Istniejące notki już pasują do: `egyptian` (`showcase.egyptian_name`), `disc_detainer` (`showcase.henriksson_disc`),
  `time_lock` (`showcase.sargent_time_lock`), `dial_safe` (`showcase.yale_dial`), `axial_slider` (`showcase.bramah_window`).
  Dla nich tylko w README: czy treść pasuje do rodziny i którym zleceniem ją odblokować (`unlocks`).
- **Nowe notki** dla `combo`, `dimple`, `magnetic`: plik `showcase.<slug>.json` w formacie
  `game/data/showcase/showcase.egyptian_name.json` (`id`, `unlocks`, `source` = URL, `confidence`, `i18n`) oraz wiersze
  `showcase.<slug>.title` (≤ 40 znaków) i `.body` (PL 300–420 znaków, jak istniejące) w `showcase_texts.csv`
  (`keys,en,pl,de`). Tylko fakty z podanym, sprawdzalnym źródłem; ogólna historia zasady, **bez firm i modeli**.
  Gdy brak pewnego źródła, napisz to w `confidence` i README zamiast zgadywać.

## Kryteria odbioru
- limity znaków spełnione we wszystkich trzech językach (sprawdź skryptem i wklej wynik do README);
- „pin”/„kołek” zgodnie z regułą; zero marek; `time_lock` opisany jako naprawa;
- każda podpowiedź mówi, **co zrobić kciukiem**, a nie tylko co się dzieje;
- README: hash `main`, lista niepewnych miejsc (`klucz | wątpliwość`).
