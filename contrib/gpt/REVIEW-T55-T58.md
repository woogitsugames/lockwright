# Odbiór T55 i T58 (drugie podejście)

Sesja A, 2026-11-06. Poprzedni przegląd (`REVIEW-T53-T68.md`) odłożył obie dostawy, bo nie było odbiorcy tekstów. Decyzja: **D-75**.

| Zadanie | Decyzja | Gdzie |
|---|---|---|
| T58 rozdziały 9–12 | **przyjęte z redakcją**, rozszerzone na rozdz. 1–12 | `game/i18n/content.csv` (`chapter.<n>.name/.desc`), `game/i18n/strings.csv` (`jobs.chapter`, `jobs.chapter_named`), `game/scripts/ui/jobs_list.gd` |
| T55 cele ćwiczeń | **nie zintegrowane** | zostaje w `contrib/gpt/T55/` |

## T58 — nazwy i opisy rozdziałów
- **Gdzie w grze:** lista zleceń nie miała żadnego podziału na rozdziały (tylko sortowanie). Teraz nad pierwszym widocznym zleceniem każdego rozdziału jest nagłówek „Rozdział N · nazwa” i jednozdaniowy opis. Mapa w Warsztacie (obrazy 1–6) bez zmian.
- **Klucze:** `district.chapterNN.*` → `chapter.<n>.name` / `chapter.<n>.desc`. `district.*` w `docs/JOBS.md` to dzielnice (Śródmieście, Port…), a te teksty opisują rozdziały, nie miejsca.
- **Spójność:** nagłówki tylko dla 9–12 wyglądałyby jak błąd, więc dopisano nazwy 1–8 (1–6 z `docs/JOBS.md` §4, 7 „Wspólny klucz” z T09, 8 „Zima w kamienicy” z T18) i krótkie opisy z tematów tych rozdziałów, we wszystkich pięciu językach.
- **Redakcja tekstów GPT (sprawdzone z zleceniami `job.t43_09_*`–`t43_12_*`):**
  - rozdz. 9: nazwa zostaje; opis „Zima trzyma klatki schodowe w ryzach” był nienaturalny („trzymać w ryzach” = dyscyplinować) i ogólnikowy → „Zima jeszcze trzyma. Zostają zapasowe koce, zeszyty z kolędami i klucze w kieszeniach płaszczy.” (zlecenia: zimowy płaszcz, koce, kolędy).
  - rozdz. 10: nazwa „Remont, który łączy” zostaje (DE poprawione na „Ein Umbau, der verbindet”); opis „miejsce na cudze pomysły” brzmiał dziwnie, DE/FR/ES rozjeżdżały się z PL → „W świetlicy trwa remont. Klucze krążą między ekipą a sąsiadami.” (rusztowanie, dozorca, nowe drzwi świetlicy).
  - rozdz. 11: „Targ i warsztaty” → **„Sąsiedzki targ”**: w zleceniach nie ma warsztatów, są drewniane stragany, rower na wystawę, skrzynia z narzędziami, nuty z próby. Opis przepisany pod te zlecenia.
  - rozdz. 12: nazwa „Miejsce przy stole” trafna (finał przy ławie Henryka) — zostaje; opis doprecyzowany „po remoncie” (łączy się z rozdz. 10).
  - EN pisownia US jak w reszcie gry („neighbors”, „harbor”).
- Lint: 0 błędów; limity długości dotyczą `tutorial.*`, `lock.*`, `menu.*` — nowych kluczy nie obejmują, opisy trzymane w jednym zdaniu–dwóch (≤ ~100 znaków).

## T55 — cele ćwiczeń: nadal NIE zintegrowane
- W grze (Godot) **nie ma ekranu praktyki**: żaden skrypt nie czyta `practice.*` (nawet istniejące `practice.t01–t30.goal` czekają na tryb praktyki; zamki są tylko w `lockcore/practice/`).
- Lekcje nowych rodzin (D-68, `game/data/lessons/<rodzina>.json`) mają własne kroki i linię końcową; dopisanie tam „celu” dublowałoby krok lekcji, a dwa cele na rodzinę odpowiadają dwóm ćwiczeniom, których nie ma.
- `t31–t46` bez zamków `lockwright.lock/1` i `lesson_target` (D-54) byłyby martwymi kluczami, więc ich nie dodano.
- Uwagi do tekstów na później: `t42` PL „Poradź sobie z fałszywym wcięciem” jest mętne (lepiej: „Rozpoznaj fałszywe wcięcie i wróć do prawdziwego”); `t32` EN/PL niespójne („Recover after passing” vs „Wróć do bramki”); `t43/t44` (time_lock) to naprawa — `check_locks` zakłada otwarcie, trzeba sprawdzić wyrażalność `lesson_target`. Reszta poprawna, zgodna ze słowniczkiem (pin/kołek).
