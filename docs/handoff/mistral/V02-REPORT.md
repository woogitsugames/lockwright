# Raport V02 (Mistral Vibe): HintLadder (H0–H4) + GhostHand + poprawki lintów

Zlecenie: `docs/handoff/mistral/V02-hint-ladder-ghost.md`. Zmienione wyłącznie pliki z zakresu
zlecenia: `game/scripts/tutorial/hint_ladder.gd`, `game/scripts/tutorial/ghost_hand.gd`,
`game/tests/gut/test_hint_ladder.gd`, `game/tests/gut/test_ghost_hand.gd` (+ pliki `.uid`),
`tools/assets_lint.py`, `tools/i18n_lint.py`, `tools/tests/test_assets_lint.py`,
`tools/tests/test_i18n_lint.py`, ten raport. Wpięcie w samouczek i weryfikację zostawiono
sesji A — `tutorial_coach.gd` i sceny nie były ruszane.

## Commity

- `4ebcfa5` — HintLadder H0–H4 (ONBOARDING §2.1) + testy GUT
- `3b50a8f` — GhostHand, cień kciuka (ONBOARDING §2.2) + testy GUT
  (przypadkiem wypchnięte puste `test_hint_ladder.gd` — naprawione następnym commitem)
- `951c7fd` — poprawka: właściwa treść `test_hint_ladder.gd`
- `f8c2c5c` — poprawki lintów z REVIEW-V01 + testy `[skip ci]`
- (ten commit) — raport `[skip ci]`

## 1. `hint_ladder.gd` — eskalacja H0–H4

`class_name HintLadder extends RefCounted` — czysta logika bez węzłów: scena samouczka
podaje własny `delta` w `update()` i prezentuje kanały z `channels()` (kreda, dźwięki
i haptykę gra gdzie indziej).

- `start_step(step_id: StringName)` — zeruje licznik utknięcia, poziom i flagę H4
  (w każdym kroku H4 może zagrać ponownie).
- `progress()` — zdarzył się realny postęp w kroku (np. bind albo set):
  licznik wraca do zera i poziom do H0. Samo machanie bez postępu **nie** zeruje
  licznika (liczymy czas od ostatniego postępu, nie od ostatniego dotyku).
- `update(delta: float) -> int` — dothora licznik o `delta`, zwraca poziom 0–4.
  W ticku, w którym zagrawa H4, zwraca 4; potem 3 (H4 najwyżej raz na krok,
  licznik dalej rośnie, ale poziom zostaje na 3).
- Sygnał `level_changed(level: int, step_id: StringName)` — emitowany raz przy każdym
  wejściu na wyższy poziom (duży `delta` przekraczający kilka progów emituje
  po jednym sygnale na poziom, w kolejności).
- `thresholds: PackedFloat32Array` — domyślnie `[15, 30, 45, 60]` s (H1–H4);
  konfigurowalne, bo S2–S3 skracają drogę „H2 → H4 po 30 s”.
  (`DEFAULT_THRESHOLDS` jest zwykłą tablicą — `PackedFloat32Array` nie jest
  const-expression w Godot 4.7.)
- `dark_mode: bool` — w trybie „w ciemności” poziomy i czasy te same, zmieniają się
  kanały (ONBOARDING §7.2): H1–H3 dźwięk + haptyka (bez obrazu), H4 dodatkowo
  na moment zapala się światło, żeby widmo było widoczne.
- `channels(level := -1) -> Dictionary` — `{visual, sound, haptic, light}` wg tabeli §2.1:

  | poziom | normalnie | w ciemności |
  |---|---|---|
  | H1–H3 | obraz + cichy dźwięk elementu | dźwięk + haptyka (bez obrazu) |
  | H4   | wszystkie kanały + haptyka      | wszystkie + światło |

  Haptyka tylko w ciemności i na H4 — wskazówka nigdy nie może brzmieć jak
  feedback zamka.
- Telemetria (ONBOARDING §12): `history: Array[Dictionary]` — wpis
  `{step: StringName, level: int, t: float}` przy każdym wejściu wyżej oraz
  `{step, level: 0, t}` przy każdym `progress()`; sesja może wyliczyć najwyższy
  poziom na krok i metrykę „otwarte bez H4” do testu A1.
- Determinizm: żadnych wywołań `Time`, żadnej losowości; czas tylko przez `delta`.
  Dodatkowo `h4_done() -> bool`.

## 2. `ghost_hand.gd` — widmo kciuka/dłoni

`class_name GhostHand extends Control`, `mouse_filter = IGNORE` (ustawiane w `_init`) —
widmo nigdy nie przechwytuje dotyku gracza. To **cień, nie poświata**: czarny,
krycie 35 %, miękka krawędź ~12 dp, bez obrysu, bez koloru, bez cząsteczek, bez tekstu
(ONBOARDING §2.2).

- `texture: Texture2D` — sylwetka alfa (jej własna miękka krawędź), rysowana czarnym
  tintem 35 %. Bez tekstury shader `canvas_item` rysuje zastępczy zaokrąglony owal
  ok. 22×56 dp z miękką krawędzią (resolution-independent: maska liczona w dp).
  `texture_scale` przelicza piksele tekstury na dp.
- `play_gesture(from_dp: Vector2, to_dp: Vector2, duration_s: float, repeats := 2,
  hold_s := 0.0)` — fazy: FADE_IN 150 ms na pozie startowej → przejazd `from → to`
  z easingiem cubic ease-in-out (przyspiesza i zwalnia) → HOLD (`hold_s`, gest
  „połóż i trzymaj” używa 1,5 s) → powtórzenia (`repeats`) → FADE_OUT i
  `gesture_finished`. Między powtórzeniami widmo wraca na pozycję startową.
- Sygnał `gesture_progress(t: float)` — wygaszony 0..1 bieżącego przejazdu (0 na
  starcie, 1 podczas trzymania), żeby scena mogła „odpowiedzieć” gestowi
  (np. obracać napinacz). Sygnał `gesture_finished` po ostatnim powtórzeniu.
- `mirror: bool` — opcja „zamień kciuki” dla leworęcznych: widmo odbija się
  względem środka parenta (współrzędne gestu są w dp parenta, więc odbicie
  działa też dla gestów zapisanych dla prawej ręki).
- Jednostki: dp == jednostki canvas (dp_scale trzyma bazę 412×915 ze stretch
  `canvas_items`), więc `from_dp`/`to_dp` to zwykłe współrzędne parenta —
  bez mnożnika. Publiczne `ghost_center` ułatwia scenie/testom śledzenie pozycji.
- Reduce Motion (§11): scena po prostu nie woła `play_gesture` — klasa nie
  renderuje samej siebie w ruchu.

## Przykład wpięcia w TutorialCoach (pseudokod, bez zmian w `tutorial_coach.gd`)

```gdscript
# scena samouczka — szykuje drabinkę i widmo (TutorialCoach nietknięty)
var ladder := HintLadder.new()
@onready var ghost: GhostHand = $GhostHand   # dodany do sceny samouczka

func _ready() -> void:
	# S1: 15/30/45/60 s; S2–S3 skracają: np. [10.0, 20.0, 30.0, 40.0] (H2 → H4 po 30 s)
	ladder.thresholds = PackedFloat32Array([15.0, 30.0, 45.0, 60.0])
	ladder.dark_mode = Settings.get("a11y/dark_mode", false)
	ghost.mirror = Settings.get("hud/left_handed", false)
	ladder.level_changed.connect(_on_hint_level)

func _on_hint_level(level: int, _step: StringName) -> void:
	var ch := ladder.channels(level)
	if level == 2 and ch["visual"]:
		ghost.play_gesture(_thumb_from(), _thumb_to(), 1.2, 2)          # H2: cień kciuka
	elif level == 3 and ch["visual"]:
		_chalk.show_arrows(_step_touchpoints())                        # H3: kreda
	elif level == 4:
		ghost.play_gesture(_thumb_from(), _thumb_to(), 1.2, 1, 1.5)     # H4: dłoń mistrza, „połóż i trzymaj”
		if ch["light"]:
			_lamp.flash_short()                                        # ciemność: moment światła

# w _process/aktualizacji sceny, po coach.update(...):
	var before := coach.step
	coach.update(vm, input, events, left_down, right_down, delta)
	if coach.step != before:
		ladder.start_step(coach.text_key())   # nowy krok: drabinka od zera
	elif _player_bound_or_set(coach):
		ladder.progress()                     # realny postęp → H0
	ladder.update(delta)                      # poza H0: kanały z ladder.channels()
```

`gesture_progress(t)` scena może od razu przeliczać na kąt napinacza
(`wrench.rotation = t * MAX_TURN`), żeby zamknięcie reagowało na gest widma.

## 3. Testy GUT (`game/tests/gut/`)

`test_hint_ladder.gd` (8 testów): progi domyślne 15/30/45/60; `progress()` zeruje
poziom; brak `progress()` (samo machanie) nie zeruje licznika; H4 najwyżej raz na
krok (kolejne `update` zwracają 3); nowy krok startuje od zera; własne progi;
kanały w trybie normalnym i w ciemności.

`test_ghost_hand.gd` (6 testów): `mouse_filter == IGNORE`; `play_gesture` kończy
się `gesture_finished` po oczekiwanym czasie (symulacja `simulate()` z tickami
`_process`); `gesture_progress` rośnie od 0 do 1; `hold_s` trzyma t = 1;
`mirror` odbija pozycję względem środka parenta; brak tekstury — zastępczy owal
bez błędów.

Lokalnie (Godot 4.7.2 headless): **14 testów / 97 asercji, wszystkie zielone**
(GUT: `--headless -s res://addons/gut/gut_cmdln.gd -gdir=res://tests/gut -gexit`;
w sandboxie bez `liblockcore_gd.so` uruchomiono oba pliki w katalogu
tymczasowym — pełny suite odpala CI `game-tests`).

## 4. Poprawki lintów (przegląd V01: `contrib/mistral/REVIEW-V01.md`)

### `tools/assets_lint.py` — wpis musi mieć zgodny katalog

Dotychczas sama nazwa pliku w `is_listed` pasowała w **dowolnym** katalogu
(sufiks `*/X` dla byle wpisu `X`), więc wpis `mockups/fonts/X` „pokrywał”
`game/assets/.../X` (fałszywa negatywa). Teraz:

- sufiks ścieżki (`*/pat`) dopasowuje tylko wpisy, które nazywają katalog
  (`pat` zawiera `/`); goła nazwa pliku nie pasuje nigdzie;
- goła nazwa w wierszu dziedziczy katalog „rodzeństwa” z tego samego wiersza
  (anchor per wiersz: listy z przecinkiem, osobne backticki i rozwinięcia
  `{a,b}` współdzielą katalog pierwszej ścieżki w wierszu, w kolejności
  czytania) — wpisy pisane względem rodzeństwa nadal działają;
- goła nazwa w wierszu bez katalogu nie pokrywa nic.

Nowe testy w `tools/tests/test_assets_lint.py` (6): goły „rodzeńak” nie pokrywa
innego katalogu (StrayFont.ttf), dziedziczenie katalogu z listy przecinkowej,
z osobnych backticków i z rozwinięcia `{a,b}`, sufiks z katalogiem pokrywa,
goła nazwa bez katalogu nie pokrywa nic.

### `tools/i18n_lint.py` — klucz dynamiczny musi mieć trafienie w CSV

Klucze dynamiczne (`cast.%s.name`, `%s.line.%d`, `verify.card.%s`) nie są już
tylko ostrzeżeniem „do ręcznej weryfikacji”: lint kompiluje wzorzec do regexa
(`%s` → dowolny ciąg bez przecinka, `%d` → cyfry) i wymaga **co najmniej
jednego** klucza w CSV pasującego do wzorca. Brak trafienia = błąd (wzorzec
nigdy nie zresoluuje się do istniejącego klucza). Jest trafienie → czysto.

Nowe testy w `tools/tests/test_i18n_lint.py` (3, w miejsce usuniętego
`test_dynamic_keys_are_warnings_not_errors`): brak trafienia = błąd;
wzorzec z trafieniami przechodzi; `%d` wymaga cyfr w kluczu.

## 5. Wyniki testów lintów

- `python3 tools/tests/` (runner pytest-kompatybilny): **23/23 PASS**
  (14 assets + 9 i18n; sandbox bez `pip install pytest`, uruchomiono runnerem
  ad-hoc emulującym `pytest tools/tests`).
- `python tools/i18n_lint.py` na repo: **824 klucze, 0 błędów, 0 ostrzeżeń**
  — wszystkie klucze dynamiczne z kodu mają trafienia w CSV.
- `python tools/assets_lint.py` na repo: **5 błędów** — wszystkie nowe,
  wywołane ostrzejszą regułą katalogu (stary lint: 0 błędów). Lista niżej.

## 6. Nowe trafienia lintów (do naprawy w `docs/ASSETS.md` przez sesję A)

`docs/ASSETS.md` nie było ruszane (poza zakresem). Nowe błędy `assets_lint`
na drzewie `main` (snapshot przy `f8c2c5c`, rejestr ASSETS.md aktualny):

1. `game/assets/fonts/AtkinsonHyperlegibleNext-wght.ttf` — jedyny wpis z tą
   nazwą to gołe „rodzeństwo” w wierszu
   `spikes/measure/android/app/fonts/BonaNova-Bold.ttf, AtkinsonHyperlegibleNext-wght.ttf`
   (dziedziczy teraz katalog `spikes/.../fonts/`, a kopia w `game/assets/fonts/`
   nie ma własnego wpisu). Naprawa: dopisać pełną ścieżkę
   `game/assets/fonts/AtkinsonHyperlegibleNext-wght.ttf`.
2–5. `game/assets/photoreal_families/{lever,wafer,warded,wooden_pin}/*_baked.glb`
   — wiersz rejestru wymienia `*_baked.glb` bez katalogu, a anchor wiersza
   (pierwsza ścieżka) wskazuje `.../{rodzina}/tex/`, więc pliki GLB w katalogu
   rodziny nie są już pokryte. Naprawa: wypisać wprost
   `game/assets/photoreal_families/{wafer,lever,warded,wooden_pin}/*_baked.glb`
   jako wpis z katalogiem.

Do czasu uzupełnienia ASSETS.md job lintu w CI (`lint.yml`) będzie czerwony
na tych 5 pozycjach — to świadomy efekt zlecenia („popraw ewentualne nowe
trafienia tylko w raporcie”). Wpisy `mockups/`/`spikes/`/`contrib/` poza
`game/assets/**` nie są lintowane poza fontami OFL, więc pozostała część
rejestru jest nietknięta.

## Weryfikacja lokalna

- Godot 4.7.2 headless: 2 skrypty testowe GUT → 14 testów, 97 asercji,
  „All tests passed!”.
- Lint testy: 23/23 PASS; `i18n_lint` na repo: 0 błędów; `assets_lint`
  na repo: dokładnie 5 błędów z listy w §6, 0 fontów bez OFL, 0 plików > 8 MB.
- Składnia obu lintów: `python -m py_compile` OK.
