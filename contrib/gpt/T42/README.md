# T42 — osiem nowych rodzin: teksty, lekcje i gablota

**Repozytorium:** `woogitsugames/lockwright`, `main`.
**Odczytany hash `main`:** `a1023176b12bc12bd5a39f5064693c0c241a421a` (6 listopada 2026, przed przygotowaniem paczki).

## Pliki

- `family_texts.csv` — **78 wierszy**, nagłówek `keys,en,pl,de`: nazwa, jednozdaniowy opis, podpowiedź kciuków, pięć kroków lekcji oraz warianty `_auto` dla odpowiednich rodzin. Klucze istniejących `lock.dial_hint`, `lock.combo_hint`, `lock.disc_hint` pozostają bez zmiany.
- `LESSONS.md` — osiem lekcji po **15–40 sekund**, każda z tabelą **Uczy | Przebieg (skrót) | Pułapka i eskalacja**, poziomy H1–H4, wskazówki wizualne wraz z dźwiękiem i haptyką.
- `showcase/showcase.combo.json`, `showcase/showcase.dimple.json`, `showcase/showcase.magnetic.json` — trzy nowe obiekty gabloty.
- `showcase_texts.csv` — **9 wierszy**, w tym trzy tytuły, trzy opisy i dodatkowo trzy etykiety źródeł (aby wszystkie klucze `i18n` w JSON były rozwiązywalne).

## Walidacja lokalna

Sprawdzone skryptem `python contrib/gpt/T42/validate_delivery.py` z paczki:

| Test | Wynik |
|---|---|
| Wszystkie 8 rodzin i ich pięć kroków | 8/8, bez braków |
| Wiersze `family_texts.csv` | 78/78 |
| Nazwy rodziny, EN/PL/DE ≤ 24 znaków | 0 przekroczeń |
| Krótkie opisy, EN/PL/DE ≤ 70 znaków | 0 przekroczeń |
| Podpowiedzi i kroki, EN/PL/DE ≤ 56 znaków | 0 przekroczeń |
| Obiekty gabloty, komplet pól i kluczy i18n | 3/3, 0 braków |
| Tytuły gabloty EN/PL/DE ≤ 40 znaków | 0 przekroczeń |
| Opisy PL w przedziale 300–420 znaków | combo **381**, dimple **408**, magnetic **391** |
| Eskalacje H1, H2, H3, H4 | obecne w każdej lekcji |
| Błędy / ostrzeżenia skryptu | **0 / 0** |

Dodatkowo `time_lock` wszędzie opisuje **naprawę** i przywrócenie równego rytmu. Kołki drewniane występują w rodzinie `egyptian`; w pozostałych opisach PL elementy bębenkowe są **pinami**. W tekstach nie ma firm, marek ani modeli.

## Pięć istniejących notek — zgodność z rodzinami i odblokowanie

Źródłem porównania są istniejące pliki `game/data/showcase/showcase.*.json` z `main`. Zgodnie z briefem **nie edytowano ich**.

| Rodzina | Istniejąca notka | Czy treść pasuje? | Obecny `unlocks` w repo | Uwagi |
|---|---|---|---|---|
| `egyptian` | `showcase.egyptian_name` | Tak; historia nazewnictwa drewnianej zasuwy. | „egipski drewniany, T2” oraz `job.dollhouse_wooden_lock` | Brief podaje zlecenie z T1; rozbieżność tieru. |
| `disc_detainer` | `showcase.henriksson_disc` | Tak; historia mechanizmu tarczowego. | „tarczowy, T1” oraz `job.finnish_sailor` | Brief: fiński marynarz T2; rozbieżność tieru. |
| `time_lock` | `showcase.sargent_time_lock` | Tak historycznie; notka dotyczy mechanizmu zegarowego, nie techniki naprawy. | „zamek czasowy, T1” oraz `job.museum_time_lock` | Brief: muzeum T2; rozbieżność tieru. |
| `dial_safe` | `showcase.yale_dial` | Tak; pokrętło i koła sejfu. | „sejf z tarczami, T1” oraz `job.krakow_antiquarian` | Brief obejmuje też `job.uncle_safe_heirs` w T2; dziś brak go w odblokowaniu. |
| `axial_slider` | `showcase.bramah_window` | Tak; historia suwaków osiowych i witryny. | „Bramah, T1” oraz „rurkowy, T1” | Brief: biurko w T2; odblokowanie nie wskazuje bezpośrednio tego zlecenia. |

**Rekomendacja integracyjna:** ujednolicić nazwy/tier w `unlocks` z rzeczywistą tabelą `jobs` i decyzjami D-59/D-60, zachowując stare treści historyczne. Obecne `unlocks` są tekstami opisowymi, więc nie należy zakładać, że są już podłączone do systemu progresji.

## Trzy nowe notki — źródła i pewność

- `combo`: katalog muzealny opisuje autentyczny zabytek z **czterema obracanymi pierścieniami z literami** oraz podobne zamki z XVI wieku. Źródło: https://museum.wales/collections/online/object/f33a582e-7d7d-35f0-8011-f0cac35e8aba/Post-Medieval-copper-alloy-combination-lock/ . **Pewność: wysoka** co do egzemplarza; gra używa odmiany z cyframi, nie kopiuje zabytku.
- `dimple`: encyklopedia techniczna opisuje zagłębienia na płaskiej stronie klucza, piny i możliwe odmiany teleskopowe. Źródło: https://www.lockwiki.com/index.php/Dimple . **Pewność: średnia–wysoka** co do konstrukcji; **nie potwierdzono daty pierwszego wynalezienia**, więc jej nie podano.
- `magnetic`: publikacja patentowa z marca **2010 r.** opisuje mechanizm łączący elementy magnetyczne ze zwykłymi pinami. Źródło: https://patents.google.com/patent/US20100050715 . **Pewność: wysoka** dla przykładowej zasady, **bez roszczeń do pierwszeństwa wynalazku**. Sonda w grze i opóźnienie ruchu są fikcją.

## Miejsca wymagające świadomej decyzji

| Klucz / materiał | Wątpliwość |
|---|---|
| `lock.time_lock_hint` i `tutorial.time_lock.step1` | W trybie automatycznego napięcia **nie wyłączono** czynności nakręcania sprężyny; jest ona celem naprawy. Trzeba sprawdzić semantykę przełącznika w ekranie gry. |
| `tutorial.dimple.step3` | Podwójne kliknięcie jest uproszczeniem fikcyjnego mechanizmu; nie powinno uchodzić za regułę każdego rzeczywistego zamka nawiercanego. |
| `family.combo.short` / `showcase.combo.body` | Historyczny zabytek źródłowy ma pierścienie z literami, a minigra kółka z cyframi. Są to rozwiązania pokrewne, ale nie identyczne. |
| `showcase.*.unlocks` istniejących pięciu notek | Tekstowe opisy odblokowania nie zgadzają się zawsze z tierem i nazwami zleceń w nowym briefie. |
| `family.dial_safe.short` | Etykieta dotyczy modelu rozgrywki; nie należy jej interpretować jako uniwersalnego opisu wszystkich historycznych sejfów. |

**Zalecany komunikat commita:** `contrib/gpt/T42: teksty osmiu rodzin i trzy notki gabloty [skip ci]`.