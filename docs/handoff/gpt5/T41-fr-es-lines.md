# Zlecenie T41: kwestie dialogów po francusku i hiszpańsku (pod lektora) + brakujące napisy UI

**Dla:** ChatGPT (tekst). Repo `woogitsugames/lockwright`, gałąź `main`. Jeśli nie możesz pisać do repo, oddaj ZIP właścicielowi.
**Zasady ogólne:** legalny ślusarz (pomaga ludziom, sprawdza prawo do lokalu), ciepły ton z lekkim humorem, zero marek,
zero słów kojarzących się z włamaniem, zero instrukcji do realnych zamków.

## Po co
Wszystkie 164 kwestie dialogów w zleceniach (`*.line.N`) są czytane przez lektora AI z osobnym głosem dla każdej postaci
(decyzja D-57). Po PL, EN i DE kolej na **FR i ES**. Masz już tłumaczenia z T31 (FR) i T32 (ES), ale pisane do czytania.
Teraz mają **brzmieć naturalnie na głos**: krótkie zdania, rytm mowy, bez urzędowych konstrukcji.

## Wejście
`docs/handoff/gpt5/T41-input.csv` (w ZIP-ie obok briefu). Kolumny:
`keys, kind (line|ui), speaker, speaker_note (wiek i charakter postaci), max_len, en, pl, fr_current, es_current`.
- 164 wiersze `line`: EN to wzorzec, PL pomaga złapać ton (PL jest oryginałem gry).
- 17 wierszy `ui`: nowe napisy interfejsu, których brakuje w T31/T32 (wskazówki na ekranie zamka, rachunek, suwak „Głosy”).

## Zadanie
1. **Kwestie (164):** popraw lub napisz od nowa `fr` i `es` tak, żeby dało się je wypowiedzieć jednym oddechem.
   Nie tłumacz słowo w słowo: zachowaj sens, żart i informację potrzebną do weryfikacji (dokument, świadek, nazwisko).
2. **Formy grzecznościowe (najważniejsze, sprawdź każdą kwestię):**
   - ślusarz (`locksmith`) mówi do klientów **„vous” / „usted”** (para lub grupa: „vous” / „ustedes”), klienci do niego też
     per vous/usted, chyba że postać jest bardzo młoda lub poufała;
   - wyjątki: Hania (7 lat) mówi do ślusarza „tu” / „tú”, a ślusarz do niej też „tu” / „tú”; starsza pani Halina mówi
     „mon petit” / „hijo” (PL „synku”);
   - przykład błędu do poprawienia: `job.allotment_shed.line.2` ES „¿Tienes la tarjeta…?” → „¿Tiene la tarjeta…?”;
   - tytuły: „pan/pani X” → „M. X / Mme X” i „don X / doña X” albo „el señor X / la señora X” — wybierz jedną konwencję
     na język i trzymaj się jej w całej grze (zapisz ją w raporcie).
3. **Głos postaci:** kieruj się `speaker_note` (wiek, charakter). Monsieur Jacques i pani Martine to Belgowie: w FR mówią
   naturalnie po francusku (lekki belgijski koloryt dozwolony, ale bez „septante” w liczbach — liczby i tak słownie).
   Aino i kapitan (Finowie), brat Pieter (Flamand): prosto i krótko, bez udawania akcentu w pisowni.
4. **Pod lektora:**
   - **liczby słownie** (np. „'94” → „quatre-vingt-quatorze” / „noventa y cuatro”, „412” → „quatre cent douze” /
     „cuatrocientos doce”), bez cyfr, skrótów i symboli (%, €, nr, n°);
   - bez nawiasów, ukośników, emotikon i wielokropków w środku zdania; pytanie kończy się „?” (ES: „¿…?”);
   - żadnych tagów audio w tekście (dodajemy je sami);
   - długość ≤ `max_len` (90 znaków), najlepiej podobna do EN.
5. **Słownik** (spójnie z T31/T32 i z `docs/LOCKS.md`):

   | PL | EN | FR | ES |
   |---|---|---|---|
   | pin (bębenkowy) | pin | goupille | pin / perno |
   | napinacz | tension wrench | clé de tension | llave de tensión |
   | wytrych | pick | crochet | ganzúa |
   | linia podziału | shear line | ligne de cisaillement | línea de corte |
   | wkładka | cylinder | cylindre | cilindro (bombín) |
   | płytka (zamek płytkowy) | wafer | paillette | lámina |
   | zapadka (zamek zapadkowy) | lever | gorge (serrure à gorges) | palanca (cerradura de palancas) |
   | zastawka | ward | garde | guarda |
   | pokrętło, koło (sejf) | dial, wheel | cadran, roue | dial, rueda |
   | kłódka | padlock | cadenas | candado |
   | ślusarz z pogotowia | emergency locksmith | serrurier d'urgence | cerrajero de urgencias |

   Zachowaj wybór z Twoich pakietów T31/T32, jeśli jest inny i spójny; zapisz to w raporcie. Bez słów
   „crocheter” w sensie włamania / „forzar” jako opisu pracy ślusarza: ślusarz „ouvre”, „abre”.
6. **UI (17 wierszy `ui`):** przetłumacz z limitem `max_len` (wskazówki `lock.*` ≤ 56 znaków = 2 linie na 412 dp).
   Tu liczby mogą zostać cyframi. Placeholdery `{…}` bez zmian.

## Oddanie
1. `contrib/gpt/T41/lines_fr_es.csv` — kolumny dokładnie `keys,fr,es`, 181 wierszy (164 kwestie + 17 UI), UTF-8, przecinek,
   cudzysłowy CSV tam, gdzie trzeba.
2. Te same wartości wpisane do pakietów `contrib/gpt/T31/content_fr_v2.csv` / `strings_fr_v2.csv` i
   `contrib/gpt/T32/content_es_v2.csv` / `strings_es_v2.csv` (kolumna `<lang>_new`; przy każdej zmianie krótka `note`,
   np. „T41: vous”, „T41: liczba słownie”). Potem:
   ```bash
   python contrib/gpt/validate_v2_localizations.py
   ```
   Wynik dla wierszy **fr** i **es**: 0 brakujących kluczy, 0 błędów (pozostałe języki nas teraz nie obchodzą).
3. `contrib/gpt/T41/README.md` po polsku: hash `main`, konwencja tytułów (M./Mme, don/doña…), liczba zmienionych kwestii
   na język, lista niepewnych miejsc (`klucz | wątpliwość`).
Commity: `contrib/gpt/T41: <opis> [skip ci]`.

## Kryteria odbioru
- każda kwestia ślusarza do dorosłego klienta w formie vous/usted;
- zero cyfr w kwestiach; zero tekstu EN wstawionego jako FR/ES;
- walidator: fr i es bez błędów i braków;
- przeczytane na głos brzmią jak mowa, nie jak napisy.
