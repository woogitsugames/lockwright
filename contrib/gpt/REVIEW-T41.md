# Odbiór T41 (ChatGPT): kwestie FR/ES pod lektora + napisy UI

**Data:** 2026-11-06 · **Odbiera:** sesja A (Claude) · **Brief:** `docs/handoff/gpt5/T41-fr-es-lines.md`
**Dostawa:** `contrib/gpt/T41/` (na `main`: 4baee34, 25b66b1) + ZIP właściciela `Lockwright_T41_T42_2026-11-06.zip`.

## ZIP a `main`
ZIP ma te same pliki co `main` (T41, T42, `T41-input.csv`); różnica to tylko brak końcowego znaku nowej linii
w wersjach z `main`. Nic nowszego w ZIP-ie nie było, zostaje wersja z `main`. Skryptów z ZIP-a nie uruchamiałem;
skrypty z repo (`apply_to_repo.py`, `validate_delivery.py`) przeczytane przed uruchomieniem: piszą tylko do
czterech pakietów T31/T32 i czytają CSV, nic więcej.

## Werdykt
**Przyjęte z poprawkami.** Kwestie brzmią jak mowa, liczby są słownie, vous/usted w dialogach trzymane prawie
wszędzie, poprawka „tú” w `job.allotment_shed.line.2` zrobiona („¿Tiene la tarjeta…?”). Wyjątki Hania (tu/tú)
i Halina („mon petit”/„hijo”) zgodnie z briefem. Konwencja tytułów: FR **Monsieur/Madame X** (pełne słowa dla
lektora), ES **señor/señora X** — przyjmuję, zapisane tu jako obowiązujące.

Poprawiłem: **FR 27 + 6, ES 20 + 5 wartości** (kwestie + UI + 19 kluczy dodatkowych). Pakiety T31/T32
zsynchronizowane `apply_to_repo.py` (notatki „T41: …” w kolumnie `note`).

## Najważniejsza zmiana: forma zwracania się do gracza w UI
Dostawa pisała **wszystkie napisy UI** (`lock.*`, `tutorial.say_*`, `tutorial.s1_pick_one`) per **vous/usted**.
Istniejące UI z T31/T32 (samouczek `tutorial.s1_*`, `lock.hint_tension`, `practice.*`) mówi do gracza
**tu/tú** — tak jak PL („trzymaj”, „Potem ty”) i DE („du”). Na jednym ekranie zamka mieszały się więc
„Pon algo de tensión” i „Presione un poco”. Rozstrzygnięcie (zgodne z PL/DE): **dialogi postaci per vous/usted
(brief), UI i głos mistrza do gracza per tu/tú.** Przepisałem 16 FR i 15 ES napisów UI z T41 oraz 6 starszych
napisów FR z T31, które jako jedyne mówiły „vous” (`boot.calib_title`, `settings.report_copied`, `verify.hint`,
`settings.haptics_calibration_two_clicks`, `settings.dark_mode_note`, `run.rubber_band`).

## Poprawki w kwestiach
| Klucz | Język | Problem → poprawka |
|---|---|---|
| `job.allotment_shed.line.2` | FR | „Un voisin peut confirmer ?” urwane → „Et un voisin qui peut en témoigner ?” |
| `job.bramah_bureau.line.2` | FR/ES | zgubiona „witryna sklepu” z EN → „exposée dans une vitrine à Londres” / „estuvo en un escaparate de Londres” |
| `job.bramah_bureau.line.4` | FR | „une fois fini” niezręczne → „quand j'aurai fini” |
| `job.brussels_townhouse.line.3` | FR/ES | „l'adresse à la commune” / „domicilio” gubiło sens „adres z gminy” → „l'inscription à la commune” / „el padrón del ayuntamiento”; „Ne vous penchez pas”, „No se asome” |
| `job.drummer_locker.line.1` | FR | zgubione „but I'd rather not” → „mais sans façon” |
| `job.kiosk_shutter.line.3` | FR/ES | zgubiona puenta „lepsze niż kiosk” → „plus belle que le kiosque” / „lucía más que el quiosco” |
| `job.krakow_antiquarian.line.1` | FR/ES | „Je loue à la ville” / „Alquilo al ayuntamiento” bez dopełnienia → „Je loue la boutique à la ville…” / „Alquilo el local al ayuntamiento…” |
| `job.krakow_tenement_gate.line.2` | FR | „Il a raison” po „Le service du patrimoine” (zgoda) → „Ils ont raison” |
| `job.krakow_tenement_gate.line.3` | FR/ES | „Hello again” zgubione, „Merci, chambre…” dziwne → „Rebonjour… La chambre quatre cent douze m'a aidée.” / „Hola otra vez… La habitación cuatrocientos doce ayudó.” |
| `job.museum_time_lock.line.2` | FR | „verrou à minuterie” niezgodne z resztą FR → „serrure à minuterie” (jak T31 i gablota) |
| `job.newlyweds_4am.line.1` | FR | „C'est normal, aujourd'hui” gubiło żart → „Je sais, plus aucune n'en a.” |
| `job.newlyweds_4am.line.2` | ES | „cuesta apuntar” (celować?) → „Con este velo no es fácil.” |
| `job.pizzeria_pays_pizza.line.1` | FR | „Faim ?” za krótkie dla lektora → „Vous avez faim ?” |
| `job.student_dorm.line.1` | FR | „Moi, dans le couloir.” → „Et moi, dans le couloir.” |
| `job.uncle_safe_heirs.line.4` | ES | „caja con rueda” niezgodne ze słownikiem → „caja fuerte con dial” |

## Poprawki UI (poza formą tu/tú)
- `receipt.tip`: „Pour ouverture soignée” / „Por apertura cuidadosa” gubiły słowo **napiwek** → „Pourboire (sans trace)” / „Propina (sin marcas)” (≤ 24).
- `lock.dial_hint`, `lock.combo_hint`, `lock.disc_hint`: T42 zmienił EN/PL/DE tych kluczy (oba kciuki), więc FR/ES przetłumaczone na nowo do nowego EN.
- `lock.detector_reset_auto` FR „Détecteur actif” → „Détecteur déclenché” (spójnie z wersją ręczną); `lock.warded_turn` FR „montez pour tourner, baissez pour retour” (niegramatyczne) → „en haut tourne, en bas revient”.
- `tutorial.say_lift` ES miał **57 znaków** (limit 56; walidator dostawy nie sprawdzał kluczy dodatkowych) → 56; FR „pièce dure” → „pièce qui résiste”.
- `settings.voice_pack.failed` FR „Téléchargement échoué” → „Échec du téléchargement.”

## Wątpliwości z README dostawy — rozstrzygnięcia
| Klucz | Rozstrzygnięcie |
|---|---|
| `job.dollhouse_wooden_lock.line.3` | Zostaje do Hani (tu/tú) — ona pyta o klucz w następnej kwestii, więc to naturalne. |
| `job.kiosk_shutter.line.3` | „quatre-vingt-quatorze” / „noventa y cuatro” bez stulecia — OK (EN też „'94”). |
| `job.krakow_tenement_gate.line.3` | Liczba pełna, przeformułowane (wyżej). |
| `tutorial.say_*` | Przyjęte, poprawione na tu/tú. |
| `receipt.tip` | Poprawione (wyżej). |

## Integracja w grze
- `game/i18n/strings.csv` i `content.csv` mają teraz kolumny **`keys,en,pl,de,fr,es`**; FR/ES z pakietów
  T31/T32 po T41. Stan: strings **233/310** (puste: 77 nowych kluczy T42), content **629/638**
  (brakuje 9 nowych notek gabloty T42). Pusta komórka = brak wpisu = Godot pokazuje EN.
- `I18n.SUPPORTED` + `fr`, `es`; **FR/ES za flagą `dev_mode`** jak DE (lista języków w ustawieniach:
  „Français (dev)”, „Español (dev)”), a dodatkowo **nie są wybierane z języka urządzenia bez flagi**
  (`I18n.DEV_ONLY`, `language_for_locale()`). Powody: (1) teksty T42 (nazwy rodzin, podpowiedzi, kroki lekcji,
  3 notki) nie mają jeszcze FR/ES; (2) brak nagrań FR/ES (D-59: najpierw DE), odtwarzacz pokaże same napisy;
  (3) menu z Blendera ma rendery tylko PL/EN/DE — FR/ES dostają EN (`pick_lang` → fallback).
  Kiedy właściciel zechce FR/ES dla graczy: przetłumaczyć 86 kluczy T42 (nowe zlecenie dla GPT), usunąć
  `fr`/`es` z `DEV_ONLY` i z bramki w `Settings.language()`.
- `tools/i18n_lint.py`: `fr`/`es` opcjonalne (puste = ostrzeżenie zbiorcze), wypełnione sprawdzane jak reszta
  (placeholdery, limity 56/28, „włam”). Testy w `tools/tests/test_i18n_lint.py`.
- Lektor: `tools/voice_lines.py` ma nadal `LANGS = pl, en, de`; kwestie FR/ES są gotowe do nagrania (liczby
  słownie, bez skrótów), więc `TTS_OVERRIDES` dla FR/ES nie są potrzebne.

## Walidatory
- `python3 contrib/gpt/T42/validate_delivery.py`: 0 błędów, 0 ostrzeżeń.
- `python3 contrib/gpt/validate_v2_localizations.py`: FR i ES — 0 błędów; **brakujące klucze = nowe klucze
  gry** (79 w strings: 77 z T42 + `settings.language_fr/es`, które w grze mają już FR/ES; 9 w content) — to oczekiwane, pakiety v2 dostaną je razem z tłumaczeniem T42.
  Pozostałe języki (it, pt_br, cs, uk, de) mają stare luki — poza zakresem.
- `tools/i18n_lint.py`: 0 błędów (ostrzeżenia: zbiorcze puste FR/ES + znany `settings.voice_pack.line`).
