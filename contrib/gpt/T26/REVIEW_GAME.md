# T26 — przegląd kodu GDScript (Godot 4.7)

**Data:** 2026-11-05  
**Repozytorium:** woogitsugames/lockwright, gałąź main  
**Podstawa przeglądu:** stan main 9f3ce645a340f4998faad68e6699996d3285b5f2  
**Charakter:** audyt statyczny, propozycje poprawek; **żadnej zmiany kodu produkcyjnego**.  

## Wynik

33 zlokalizowane uwagi: **17 High, 13 Medium, 3 Low**. Przebadano kontrolery zamka i rodzin, fallbacki, sampler dotyku, autoloady audio/haptyki, przepływ menu/zleceń, sceny .tscn, testy oraz natywne wiązanie lockcore. Wyraźnie problematyczne są: osiągalność stanów fallbacków, rozjazd między sześciopolowym wejściem lockcore i trzyargumentowym wywołaniem, tryb ciągły, zapisywanie wyniku oraz Android Back/pauza.

**Zasada raportu:** każda sekcja zawiera jedno miejsce w kodzie z numerem linii, opis, ryzyko i diff propozycji. Diffy **nie są zastosowane** i nie stanowią gotowej, połączonej serii patchy; przy nakładających się zmianach (zwłaszcza H09/M19/M30 i H16/M29) trzeba je scalić i przetestować. Numery linii odnoszą się do powyższego commita main.

## Ustalenia

### H01 — Fallback nie akceptuje sześciu argumentów step()

**Priorytet:** High · **Plik:linia:** [game/scripts/lock/fake_lock_session.gd:46](https://github.com/woogitsugames/lockwright/blob/9f3ce645a340f4998faad68e6699996d3285b5f2/game/scripts/lock/fake_lock_session.gd#L46)

**Opis:** lock_scene.gd:134 przekazuje (tension, depth, lift, rotate, push, tool), zgodnie z natywnym LockcoreSession; FakeLockSession.step() przyjmuje tylko trzy argumenty. Uruchomienie lock.tscn bez GDExtension wywołuje błąd liczby argumentów.

**Ryzyko:** Rozgrywka fallback kończy się błędem w pierwszym ticku.

**Proponowany diff (niezastosowany):**

~~~diff
--- a/game/scripts/lock/fake_lock_session.gd
+++ b/game/scripts/lock/fake_lock_session.gd
@@
-func step(tension: float, depth: float, lift: float) -> Array:
+func step(tension: float, depth: float, lift: float,
+	_rotate: float = 0.0, _push: float = 0.0, _tool: int = 0) -> Array:
~~~

### H02 — Wszystkie rodziny zamków trafiają do pięciopinowego fallbacku

**Priorytet:** High · **Plik:linia:** [game/scripts/lock/lock_scene.gd:33](https://github.com/woogitsugames/lockwright/blob/9f3ce645a340f4998faad68e6699996d3285b5f2/game/scripts/lock/lock_scene.gd#L33)

**Opis:** Gdy brakuje LockcoreSession, linia 37 tworzy FakeLockSession niezależnie od family. Fallback FakeLockSession ignoruje family i tier; dla wafer/lever/warded/wooden_pin emuluje błędną mechanikę. Dla ring_combo w repo nie ma równoważnego fallbacku.

**Ryzyko:** Niewłaściwy przebieg zleceń, testów i poziomów bez rozszerzenia natywnego.

**Proponowany diff (niezastosowany):**

~~~diff
--- a/game/scripts/lock/lock_scene.gd
+++ b/game/scripts/lock/lock_scene.gd
@@
-		session = FakeLockSession.create(family, seed, tier)
+		if family == &"pin_tumbler":
+			session = FakeLockSession.create(family, seed, tier)
+		elif family in [&"wafer", &"lever", &"lever_detector", &"warded", &"wooden_pin"]:
+			session = FamilyLockSession.create(family, seed, tier)
+		else:
+			push_error("No fallback for family: %s" % family)
+			set_physics_process(false)
+			return
~~~

### H03 — Element spool utknie na zawsze w false_set

**Priorytet:** High · **Plik:linia:** [game/scripts/lock/fake_lock_session.gd:92](https://github.com/woogitsugames/lockwright/blob/9f3ce645a340f4998faad68e6699996d3285b5f2/game/scripts/lock/fake_lock_session.gd#L92)

**Opis:** Przy wejściu w okno element spool przechodzi z bound na false_set (94–97). Ruch elementu jest przetwarzany tylko dla stanów bound/free (74), a warunek otwarcia wymaga wszystkich set (125). Sesja zawierająca spool staje się nieotwieralna.

**Ryzyko:** Blokada samouczka i zleceń we wszystkich przebiegach korzystających z fallbacku.

**Proponowany diff (niezastosowany):**

~~~diff
--- a/game/scripts/lock/fake_lock_session.gd
+++ b/game/scripts/lock/fake_lock_session.gd
@@
-	if p["state"] == "bound" or p["state"] == "free":
+	if p["state"] in ["bound", "free", "false_set"]:
@@
-			if p["state"] == "bound":
+			if p["state"] == "false_set" and p["pos"] >= 1.0 - SHEAR_WINDOW and _tension >= T_HOLD:
+				p["state"] = "set"
+				events.append({"kind": &"set", "element": active, "intensity": 0.95, "material": &"brass", "tick": _tick})
+			elif p["state"] == "bound":
~~~

### H04 — Gałąź cofająca overset jest nieosiągalna

**Priorytet:** High · **Plik:linia:** [game/scripts/lock/fake_lock_session.gd:101](https://github.com/woogitsugames/lockwright/blob/9f3ce645a340f4998faad68e6699996d3285b5f2/game/scripts/lock/fake_lock_session.gd#L101)

**Opis:** Instrukcja elif p.state == overset znajduje się wewnątrz if p.state == bound i zarazem wewnątrz warunku zewnętrznego dopuszczającego tylko bound/free. Reset pozycji przy zwolnieniu napięcia nie może zajść.

**Ryzyko:** Trwała blokada elementu po overset.

**Proponowany diff (niezastosowany):**

~~~diff
--- a/game/scripts/lock/fake_lock_session.gd
+++ b/game/scripts/lock/fake_lock_session.gd
@@
 	var p: Dictionary = _pins[active]
+	if p["state"] == "overset" and _tension < T_RELEASE:
+		p["state"] = "free"
+		p["pos"] = 0.0
@@
-			elif p["state"] == "overset" and _tension < T_RELEASE:
-				p["state"] = "free"
-				p["pos"] = 0.0
~~~

### H05 — Przekroczenie progu złamania nie wyzwala break podczas naporu

**Priorytet:** High · **Plik:linia:** [game/scripts/lock/fake_lock_session.gd:82](https://github.com/woogitsugames/lockwright/blob/9f3ce645a340f4998faad68e6699996d3285b5f2/game/scripts/lock/fake_lock_session.gd#L82)

**Opis:** Po zwiększeniu _stress w gałęzi bound/high tension kod sprawdza elif _stress >= S_MAX dołączony do tego samego if. W chwili przekroczenia progu gałąź elif jest niedostępna; złamanie może nastąpić dopiero po zmianie warunków.

**Ryzyko:** Rozbieżność stanów i opóźniona/nieoczekiwana porażka.

**Proponowany diff (niezastosowany):**

~~~diff
--- a/game/scripts/lock/fake_lock_session.gd
+++ b/game/scripts/lock/fake_lock_session.gd
@@
-			elif _stress >= S_MAX:
-					_broken = true
-					events.append({"kind": &"break", "sub": 0, "name": &"break.0", "element": active, "intensity": 1.0, "material": &"steel", "tick": _tick})
 			else:
 				_stress = maxf(0.0, _stress - 0.002)
+			if _stress >= S_MAX and not _broken:
+				_broken = true
+				events.append({"kind": &"break", "element": active, "intensity": 1.0, "material": &"steel", "tick": _tick})
~~~

### H06 — Detektor wymaga nieosiągalnego ujemnego napięcia

**Priorytet:** High · **Plik:linia:** [game/scripts/photoreal_families/family_lock_session.gd:120](https://github.com/woogitsugames/lockwright/blob/9f3ce645a340f4998faad68e6699996d3285b5f2/game/scripts/photoreal_families/family_lock_session.gd#L120)

**Opis:** Reset _jammed wymaga _tension < -0.25, podczas gdy InputSampler clampuje napięcie do 0..1 (input_sampler.gd:79), a natywny mostek również do 0..1 (lockcore_session_gd.cpp:46). Fallback lever_detector nie daje się odblokować sterowaniem gry.

**Ryzyko:** Miękka blokada rozgrywki po zadziałaniu detektora.

**Proponowany diff (niezastosowany):**

~~~diff
--- a/game/scripts/photoreal_families/family_lock_session.gd
+++ b/game/scripts/photoreal_families/family_lock_session.gd
@@
-		if _tension < -0.25:
+		# Fallback: release tension to reset; reverse tension is unavailable.
+		if _tension <= 0.01:
 			_reset_progress = clampf(_reset_progress + 0.04, 0.0, 1.0)
+		else:
+			_reset_progress = 0.0
~~~

### H07 — Overset emituje zdarzenie i podnosi stress co tick

**Priorytet:** High · **Plik:linia:** [game/scripts/photoreal_families/family_lock_session.gd:158](https://github.com/woogitsugames/lockwright/blob/9f3ce645a340f4998faad68e6699996d3285b5f2/game/scripts/photoreal_families/family_lock_session.gd#L158)

**Opis:** Dopóki position > hi+0.14, blok overset wykonuje się przy każdym z 120 kroków/s, w tym dla stanu już overset. Przyrost 0.025/tick osiąga stress=1 po ok. 0,33 s, a haptyka i audio otrzymują serię powtórek.

**Ryzyko:** Fałszywe złamania, spam sygnałów i zacięcia dźwięku/haptyki.

**Proponowany diff (niezastosowany):**

~~~diff
--- a/game/scripts/photoreal_families/family_lock_session.gd
+++ b/game/scripts/photoreal_families/family_lock_session.gd
@@
 		if pos > hi + 0.14 and _tension > 0.15:
+			if el["state"] == &"overset" or el["state"] == &"jammed":
+				continue
 			if String(family) == "lever_detector":
~~~

### H08 — Kanał push pozostaje stale zerowy

**Priorytet:** High · **Plik:linia:** [game/scripts/lock/input_sampler.gd:24](https://github.com/woogitsugames/lockwright/blob/9f3ce645a340f4998faad68e6699996d3285b5f2/game/scripts/lock/input_sampler.gd#L24)

**Opis:** _push_raw jest inicjalizowane na 0, zerowane przy puszczeniu i nigdy nie ustawiane na wartość dodatnią. Kanał push wysyłany w sample() do lockcore nie rejestruje przytrzymania; część rodzin mechanicznych potrzebujących osiowego nacisku nie działa.

**Ryzyko:** Nieosiągalne stany w rodzinach korzystających z push.

**Proponowany diff (niezastosowany):**

~~~diff
--- a/game/scripts/lock/input_sampler.gd
+++ b/game/scripts/lock/input_sampler.gd
@@
 var _push_raw := 0.0
+@export var push_on_right_hold := false  # Set by controllers of families that need push.
@@
 			else:
 				_touch_pick = event.index
+				_push_raw = 1.0 if push_on_right_hold else 0.0
 				_pick_start = event.position
~~~

### H09 — Obie fotorealistyczne sceny odrzucają rotate/push/tool

**Priorytet:** High · **Plik:linia:** [game/scripts/photoreal/lock_photoreal.gd:124](https://github.com/woogitsugames/lockwright/blob/9f3ce645a340f4998faad68e6699996d3285b5f2/game/scripts/photoreal/lock_photoreal.gd#L124)

**Opis:** lock_photoreal.gd:124 i lock_photoreal_family.gd:269 wywołują session.step wyłącznie z 3 polami, chociaż C++ API udostępnia 6 (lockcore_session_gd.cpp:14). Dane rotate/push/tool z InputSampler są więc ignorowane.

**Ryzyko:** Zablokowane mechaniki pierścieniowe i inne rodziny korzystające z dodatkowych osi.

**Proponowany diff (niezastosowany):**

~~~diff
--- a/game/scripts/photoreal/lock_photoreal.gd
+++ b/game/scripts/photoreal/lock_photoreal.gd
@@
-	var events: Array = session.step(input["tension"], input["pick_depth"], input["pick_lift"])
+	var events: Array = session.step(input["tension"], input["pick_depth"], input["pick_lift"], input["rotate"], input["push"], input["tool"])
--- a/game/scripts/photoreal_families/lock_photoreal_family.gd
+++ b/game/scripts/photoreal_families/lock_photoreal_family.gd
@@
-	var events: Array = session.step(input["tension"], input["pick_depth"], input["pick_lift"])
+	var events: Array = session.step(input["tension"], input["pick_depth"], input["pick_lift"], input["rotate"], input["push"], input["tool"])
# Extend FamilyLockSession.step signature with optional args, as in H01.
~~~

### H10 — Tryb ciągły resetuje licznik po każdym otwarciu

**Priorytet:** High · **Plik:linia:** [game/scripts/ui/run_loop.gd:5](https://github.com/woogitsugames/lockwright/blob/9f3ce645a340f4998faad68e6699996d3285b5f2/game/scripts/ui/run_loop.gd#L5)

**Opis:** _n/_breaks są polami sceny i zawsze startują od zera. Events.gd:30–31 po sukcesie ładuje nowy run_loop.tscn, a metoda on_lock_finished() nie jest nigdzie wywoływana. Gra wznawia zawsze run.0, bez postępu, nagród i odejmowania żyć.

**Ryzyko:** Cała pętla trybu ciągłego nie działa.

**Proponowany diff (niezastosowany):**

~~~diff
--- a/game/scripts/lock/job_run.gd
+++ b/game/scripts/lock/job_run.gd
@@
 static var lives := 3
+static var run_n := 0
+static var run_breaks := 0
--- a/game/scripts/ui/run_loop.gd
+++ b/game/scripts/ui/run_loop.gd
@@
-var _n := 0
-var _breaks := 0
+var _n: int:
+	get: return JobRun.run_n
+	set(v): JobRun.run_n = v
+var _breaks: int:
+	get: return JobRun.run_breaks
+	set(v): JobRun.run_breaks = v
--- a/game/scripts/autoload/events.gd
+++ b/game/scripts/autoload/events.gd
@@
 	if JobRun.mode == &"run":
+		JobRun.run_n += 1
 		get_tree().change_scene_to_file("res://scenes/run_loop.tscn")
# Additionally handle lock_failed, lives and rewards in a shared run-result function.
~~~

### H11 — Play uruchamia zamek bez aktywnego zlecenia lub trybu

**Priorytet:** High · **Plik:linia:** [game/scripts/ui/main_menu.gd:38](https://github.com/woogitsugames/lockwright/blob/9f3ce645a340f4998faad68e6699996d3285b5f2/game/scripts/ui/main_menu.gd#L38)

**Opis:** Po zakończeniu samouczka przycisk Play wywołuje JobRun.lock_scene_path() z pustym current_job. lock_scene_path() zwraca lock_job.tscn, ale Events.gd nie ma ścieżki wyjścia dla pustego current_job i mode=job. Po otwarciu ekran nie nawiguję dalej.

**Ryzyko:** Użytkownik po ukończeniu samouczka trafia w martwy przebieg.

**Proponowany diff (niezastosowany):**

~~~diff
--- a/game/scripts/ui/main_menu.gd
+++ b/game/scripts/ui/main_menu.gd
@@
 		if Save.get_value("tutorial_done", false):
-			get_tree().change_scene_to_file(JobRun.lock_scene_path())
+			get_tree().change_scene_to_file("res://scenes/run_loop.tscn")
 		else:
~~~

### H12 — Niepełne aliasy rodzin przy generowaniu trybu ciągłego

**Priorytet:** High · **Plik:linia:** [game/scripts/lock/job_run.gd:17](https://github.com/woogitsugames/lockwright/blob/9f3ce645a340f4998faad68e6699996d3285b5f2/game/scripts/lock/job_run.gd#L17)

**Opis:** IMPLEMENTED zawiera wooden_pin i ring_combo, ale FAMILY_MAP nie mapuje tych identyfikatorów na same siebie. run_loop.gd:31 wybiera je bezpośrednio, family_for() oddaje pusty StringName. lock_scene może zainicjalizować nieznaną rodzinę.

**Ryzyko:** Błędne zlecenie lub niezainicjalizowana sesja po przejściu do tych rodzin.

**Proponowany diff (niezastosowany):**

~~~diff
--- a/game/scripts/lock/job_run.gd
+++ b/game/scripts/lock/job_run.gd
@@
 	"warded": &"warded",
+	"wooden_pin": &"wooden_pin",
+	"ring_combo": &"ring_combo",
 	"lever_detector": &"lever_detector",
~~~

### H13 — Porażka w scenie podstawowej pozostawia martwy ekran

**Priorytet:** High · **Plik:linia:** [game/scripts/lock/lock_scene.gd:141](https://github.com/woogitsugames/lockwright/blob/9f3ce645a340f4998faad68e6699996d3285b5f2/game/scripts/lock/lock_scene.gd#L141)

**Opis:** Po finished() bez open następuje tylko Events.lock_failed.emit(...), a następnie set_physics_process(false); nie ma zmiany sceny, ponownej próby ani aktualizacji żyć. Nie ma też połączenia Events.lock_failed z obsługą trybu ciągłego.

**Ryzyko:** Softlock po złamaniu narzędzia, utrata sprawności pętli gry.

**Proponowany diff (niezastosowany):**

~~~diff
--- a/game/scripts/lock/lock_scene.gd
+++ b/game/scripts/lock/lock_scene.gd
@@
 		else:
 			Events.lock_failed.emit(session.failure())
+			get_tree().paused = false
+			if JobRun.mode == &"run":
+				get_tree().call_deferred("change_scene_to_file", "res://scenes/run_loop.tscn")
+			elif JobRun.mode == &"tutorial":
+				get_tree().call_deferred("change_scene_to_file", "res://scenes/tutorial.tscn")
+			else:
+				get_tree().call_deferred("change_scene_to_file", "res://scenes/job_verify.tscn")
 		set_physics_process(false)
# In parallel, record run failure/lives through a single owner of run state.
~~~

### H14 — Rachunek nie pokazuje napiwku, postęp zapisuje się zbyt późno

**Priorytet:** High · **Plik:linia:** [game/scripts/ui/job_payment.gd:25](https://github.com/woogitsugames/lockwright/blob/9f3ce645a340f4998faad68e6699996d3285b5f2/game/scripts/ui/job_payment.gd#L25)

**Opis:** W _ready wyświetlany jest JobRun.last_tip, lecz jego wartość wylicza dopiero JobRun.complete() w handlerze Continue (43–45). Przed kliknięciem tip jest równy 0, a zamknięcie aplikacji przed Continue gubi nagrodę i status ukończenia.

**Ryzyko:** Błędny wynik na rachunku oraz utrata postępu po ubiciu procesu.

**Proponowany diff (niezastosowany):**

~~~diff
--- a/game/scripts/ui/job_payment.gd
+++ b/game/scripts/ui/job_payment.gd
@@
 	var job: Dictionary = JobRun.current_job
+	if not job.is_empty():
+		JobRun.complete()  # Finalize once on arrival, before rendering the receipt.
@@
 	continue_button.pressed.connect(func() -> void:
-		JobRun.complete()
 		get_tree().change_scene_to_file("res://scenes/jobs_list.tscn"))
~~~

### H15 — Reset ustawień wywołuje _ready() ponownie i mnoży sygnały

**Priorytet:** High · **Plik:linia:** [game/scripts/ui/settings_screen.gd:92](https://github.com/woogitsugames/lockwright/blob/9f3ce645a340f4998faad68e6699996d3285b5f2/game/scripts/ui/settings_screen.gd#L92)

**Opis:** Callback reset_button.pressed wykonuje _ready() na istniejącym węźle. Każde wywołanie dokłada nowe lambdy dla sliderów, przycisków, language_changed oraz samego resetu. Reset N razy powoduje kaskadę handlerów i zapisów.

**Ryzyko:** Wyciek połączeń, lawinowe I/O i nieprzewidywalne zachowanie UI.

**Proponowany diff (niezastosowany):**

~~~diff
--- a/game/scripts/ui/settings_screen.gd
+++ b/game/scripts/ui/settings_screen.gd
@@
 	reset_button.pressed.connect(func() -> void:
 		for key in Settings.DEFAULTS:
 			Settings.set_value(key, Settings.DEFAULTS[key])
-		_ready())
+		get_tree().reload_current_scene())
~~~

### H16 — Android Back nie ma obsługi scenowej

**Priorytet:** High · **Plik:linia:** [game/scripts/photoreal/lock_photoreal.gd:142](https://github.com/woogitsugames/lockwright/blob/9f3ce645a340f4998faad68e6699996d3285b5f2/game/scripts/photoreal/lock_photoreal.gd#L142)

**Opis:** Kontrolery lock_scene.gd:278, lock_photoreal.gd:148 i lock_photoreal_family.gd:293 reagują tylko na KEY_ESCAPE. Android Back wysyła NOTIFICATION_WM_GO_BACK_REQUEST i przy domyślnym quit_on_go_back może zamknąć grę. Gdy SceneTree jest w pauzie, pausable root nie obsłuży ponadto wejścia klawiatury.

**Ryzyko:** Przypadkowe wyjście z gry i niemożność prawidłowego wycofania się z pauzy.

**Proponowany diff (niezastosowany):**

~~~diff
--- a/game/project.godot
+++ b/game/project.godot
@@
 [application]
+config/quit_on_go_back=false
--- a/game/scripts/photoreal/lock_photoreal.gd
+++ b/game/scripts/photoreal/lock_photoreal.gd
@@
+func _notification(what: int) -> void:
+	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
+		if _paused:
+			_on_resume()
+		else:
+			_on_pause()
# Apply the same notification handling to lock_scene.gd, family controller and menus.
~~~

### H17 — Handler zakończenia run przyznaje monety także za porażkę

**Priorytet:** High · **Plik:linia:** [game/scripts/ui/run_loop.gd:41](https://github.com/woogitsugames/lockwright/blob/9f3ce645a340f4998faad68e6699996d3285b5f2/game/scripts/ui/run_loop.gd#L41)

**Opis:** on_lock_finished(opened) odejmuje życie przy !opened, ale w linii 49 przyznaje nagrodę bez warunku. Po naprawie brakującego połączenia z Events będzie można zarabiać na celowo przegrywanych zamkach.

**Ryzyko:** Błąd ekonomii i obejście progresji.

**Proponowany diff (niezastosowany):**

~~~diff
--- a/game/scripts/ui/run_loop.gd
+++ b/game/scripts/ui/run_loop.gd
@@
-	Save.set_value("coins", Save.get_value("coins", 0) + 10 * _tier_for(_n))
+	if opened:
+		Save.set_value("coins", Save.get_value("coins", 0) + 10 * _tier_for(_n))
~~~

### M18 — Throttle kanału ciągłego zapamiętuje wartości, których nie wysłał

**Priorytet:** Medium · **Plik:linia:** [game/scripts/autoload/feedback_director.gd:107](https://github.com/woogitsugames/lockwright/blob/9f3ce645a340f4998faad68e6699996d3285b5f2/game/scripts/autoload/feedback_director.gd#L107)

**Opis:** W gałęzi now_ms - _last_continuous_sent <16ms kod nadpisuje _last_continuous[id] i wraca bez wywołania Haptics.update_continuous. Później porównuje nowy poziom z tym niewysłanym i może trwale pominąć zmianę.

**Ryzyko:** Zalegający opór haptyczny, niezgodność sprzężenia z widokiem.

**Proponowany diff (niezastosowany):**

~~~diff
--- a/game/scripts/autoload/feedback_director.gd
+++ b/game/scripts/autoload/feedback_director.gd
@@
 	if now_ms - _last_continuous_sent < UPDATE_MIN_INTERVAL_MS:
-		_last_continuous[id] = [intensity, sharpness]
 		return
~~~

### M19 — Prezentacja 3D i przesył shader uniforms wykonywane 120 razy/s

**Priorytet:** Medium · **Plik:linia:** [game/scripts/photoreal/lock_photoreal.gd:115](https://github.com/woogitsugames/lockwright/blob/9f3ce645a340f4998faad68e6699996d3285b5f2/game/scripts/photoreal/lock_photoreal.gd#L115)

**Opis:** _physics_process wywołuje describe() i view.present() w każdym ticku. View.present (lock_photoreal_view.gd:114–136) zmienia transformacje, resize PackedVector4Array i zestaw parametrów shaderów. Drugi kontroler rodziny powiela wzorzec (lock_photoreal_family.gd:260–285).

**Ryzyko:** CPU/GPU overhead i utrata budżetu 8,33 ms symulacji na słabszych Androidach.

**Proponowany diff (niezastosowany):**

~~~diff
--- a/game/scripts/photoreal/lock_photoreal.gd
+++ b/game/scripts/photoreal/lock_photoreal.gd
@@
 var _last_input := {"tension": 0.0, "pick_depth": 0.5, "pick_lift": 0.0}
+var _render_vm: Dictionary = {}
@@
-	view.present(vm, input, delta)
+	_render_vm = vm
@@
 func _process(delta: float) -> void:
+	if not _render_vm.is_empty() and not _paused:
+		view.present(_render_vm, _last_input, delta)
 	if _shot_frames > 0:
# Mirror in family controller; keep session.step/events on physics ticks.
~~~

### M20 — sample() alokuje nowy Dictionary przy każdym odczycie

**Priorytet:** Medium · **Plik:linia:** [game/scripts/lock/input_sampler.gd:106](https://github.com/woogitsugames/lockwright/blob/9f3ce645a340f4998faad68e6699996d3285b5f2/game/scripts/lock/input_sampler.gd#L106)

**Opis:** Wersja bazowa pobiera sample() zarówno w fizyce (lock_scene.gd:133), jak i w renderze (lock_scene.gd:223), a fotorealistyczna co tick fizyki. Oprócz mapy tworzone są zmienne wariantowe podczas indeksowania słownikowego.

**Ryzyko:** Nadmierna presja na allocator/GC i niestabilny czas p99 klatki.

**Proponowany diff (niezastosowany):**

~~~diff
--- a/game/scripts/lock/input_sampler.gd
+++ b/game/scripts/lock/input_sampler.gd
@@
-func sample() -> Dictionary:
-	return {
-		"tension": tension, "pick_depth": pick_depth, "pick_lift": pick_lift,
-		"rotate": rotate, "push": push, "tool": tool,
-	}
+func sample_into(out: Dictionary) -> void:
+	out["tension"] = tension
+	out["pick_depth"] = pick_depth
+	out["pick_lift"] = pick_lift
+	out["rotate"] = rotate
+	out["push"] = push
+	out["tool"] = tool
# Allocate out once per controller; never share it with a snapshot that must be immutable.
~~~

### M21 — Drugi palec nadpisuje indeks właściciela strefy

**Priorytet:** Medium · **Plik:linia:** [game/scripts/lock/input_sampler.gd:35](https://github.com/woogitsugames/lockwright/blob/9f3ce645a340f4998faad68e6699996d3285b5f2/game/scripts/lock/input_sampler.gd#L35)

**Opis:** Każdy touch.pressed po lewej/prawej ustawia _touch_tension/_touch_pick, nawet jeśli inny indeks już steruje strefą. Zwolnienie pierwszego palca zostanie zignorowane, a napięcie lub podnoszenie może utknąć.

**Ryzyko:** Skoki sterowania i pozostałe aktywne gesty po puszczeniu kciuka.

**Proponowany diff (niezastosowany):**

~~~diff
--- a/game/scripts/lock/input_sampler.gd
+++ b/game/scripts/lock/input_sampler.gd
@@
 			if event.position.x < half:
+				if _touch_tension != -1:
+					return
 				_touch_tension = event.index
@@
 			else:
+				if _touch_pick != -1:
+					return
 				_touch_pick = event.index
~~~

### M22 — Gest obrotu przeskakuje przy przejściu przez granicę -PI/PI

**Priorytet:** Medium · **Plik:linia:** [game/scripts/lock/input_sampler.gd:70](https://github.com/woogitsugames/lockwright/blob/9f3ce645a340f4998faad68e6699996d3285b5f2/game/scripts/lock/input_sampler.gd#L70)

**Opis:** Różnica dwóch angle() jest odejmowana bez zawinięcia. Przejście z +179° do -179° zwraca około -6,25 rad zamiast +0,035 rad; clamp nasyca obrót do końca.

**Ryzyko:** Gwałtowne, pozornie losowe ruchy pierścieni/elementów obrotowych.

**Proponowany diff (niezastosowany):**

~~~diff
--- a/game/scripts/lock/input_sampler.gd
+++ b/game/scripts/lock/input_sampler.gd
@@
-			_rotate_raw = clampf(_rotate_raw + (a1 - a0), -1.0, 1.0)
+			var angle_delta := wrapf(a1 - a0, -PI, PI)
+			_rotate_raw = clampf(_rotate_raw + angle_delta, -1.0, 1.0)
~~~

### M23 — Zmiana Quality.msaa nie aktualizuje istniejącego SubViewport

**Priorytet:** Medium · **Plik:linia:** [game/scripts/lock/lock_job.gd:19](https://github.com/woogitsugames/lockwright/blob/9f3ce645a340f4998faad68e6699996d3285b5f2/game/scripts/lock/lock_job.gd#L19)

**Opis:** _apply_quality ustawia view.msaa, lecz LockPhotorealView przypisuje wartość do viewport.msaa_3d wyłącznie podczas _build_viewport (lock_photoreal_view.gd:183–190). Profil zmieniany w trakcie gry nie wyłącza antyaliasingu na realnym render target.

**Ryzyko:** Profil low nie przynosi oszczędności renderingu oczekiwanej przez gracza.

**Proponowany diff (niezastosowany):**

~~~diff
--- a/game/scripts/lock/lock_job.gd
+++ b/game/scripts/lock/lock_job.gd
@@
 	if view:
 		view.msaa = Quality.msaa_index()
+		if view.viewport:
+			view.viewport.msaa_3d = [
+				Viewport.MSAA_DISABLED, Viewport.MSAA_2X, Viewport.MSAA_4X
+			][Quality.msaa_index()]
~~~

### M24 — Auto Quality mierzy menu zamiast ekranu zamka

**Priorytet:** Medium · **Plik:linia:** [game/scripts/autoload/quality.gd:38](https://github.com/woogitsugames/lockwright/blob/9f3ce645a340f4998faad68e6699996d3285b5f2/game/scripts/autoload/quality.gd#L38)

**Opis:** Autoload Quality uruchamia _auto_time od bootu. Po 10 sekundach w menu ustala profil na podstawie taniego interfejsu 2D, zanim wejdzie się w kosztowny SubViewport gry. Profil może zostać na high mimo problemów GPU.

**Ryzyko:** Niewłaściwe ustawienia i spadek FPS lub throttling na urządzeniu docelowym.

**Proponowany diff (niezastosowany):**

~~~diff
--- a/game/scripts/autoload/quality.gd
+++ b/game/scripts/autoload/quality.gd
@@
 	if Settings.get_value("quality_profile", "auto") == "auto" and not _auto_done:
+		var scene := get_tree().current_scene
+		if scene == null or not scene.scene_file_path in [
+			"res://scenes/lock.tscn", "res://scenes/lock_job.tscn"
+		]:
+			return
 		_auto_time += delta
# Include photoreal family scenes when they enter the production flow.
~~~

### M25 — Zmiana sceny pozostawia ciągłe SFX/haptykę i filtr muzyki

**Priorytet:** Medium · **Plik:linia:** [game/scripts/photoreal/lock_photoreal.gd:194](https://github.com/woogitsugames/lockwright/blob/9f3ce645a340f4998faad68e6699996d3285b5f2/game/scripts/photoreal/lock_photoreal.gd#L194)

**Opis:** Autoload Sfx.begin_loop i Haptics.begin_continuous są inicjowane w _ready (86–89), lecz kontrolery zamka nie wywołują end_loop/end_continuous przy _on_quit, zwycięstwie, złamaniu ani _exit_tree. Autoload przeżywa scenę. Filtr muzyki aktywowany w _ready:55 również może pozostać.

**Ryzyko:** Dźwięki i wibracje na ekranie płatności/menu; ciągle żywe AudioStreamPlayer; stan poprzedniej sceny.

**Proponowany diff (niezastosowany):**

~~~diff
--- a/game/scripts/photoreal/lock_photoreal.gd
+++ b/game/scripts/photoreal/lock_photoreal.gd
@@
+func _exit_tree() -> void:
+	Sfx.end_loop(&"tension_resistance")
+	Sfx.end_loop(&"pick_drag")
+	Haptics.end_continuous(&"tension_resistance")
+	Sfx.set_music_lowpass(false)
+	FeedbackDirector.reset()
# Use the same teardown in lock_scene.gd and family controller.
~~~

### M26 — Zmiana głośności wyzwala zmianę języka

**Priorytet:** Medium · **Plik:linia:** [game/scripts/autoload/i18n.gd:111](https://github.com/woogitsugames/lockwright/blob/9f3ce645a340f4998faad68e6699996d3285b5f2/game/scripts/autoload/i18n.gd#L111)

**Opis:** Każde Settings.set_value (również volume_sfx lub haptics_intensity) emituje changed, a I18n._on_settings_changed bezwarunkowo woła apply_language(), które zawsze emituje language_changed. Przesuwanie suwaka może wielokrotnie przebudowywać etykiety.

**Ryzyko:** Zbędne sygnały/UI reflow i dodatkowy koszt podczas regulacji parametrów.

**Proponowany diff (niezastosowany):**

~~~diff
--- a/game/scripts/autoload/i18n.gd
+++ b/game/scripts/autoload/i18n.gd
@@
 func _on_settings_changed() -> void:
-	apply_language(Settings.language())
+	var wanted := Settings.language()
+	if wanted != TranslationServer.get_locale():
+		apply_language(wanted)
~~~

### M27 — Każdy transient tworzy nowy Tween duckingu

**Priorytet:** Medium · **Plik:linia:** [game/scripts/autoload/sfx.gd:361](https://github.com/woogitsugames/lockwright/blob/9f3ce645a340f4998faad68e6699996d3285b5f2/game/scripts/autoload/sfx.gd#L361)

**Opis:** Sfx.play wywołuje duck_ambience przy niemal każdym zdarzeniu (152–158). duck_ambience zabija poprzedni Tween i tworzy nowy. Przy wysokiej częstotliwości kontaktów gra alokuje/kasuje Tween kilkadziesiąt razy/s.

**Ryzyko:** Churn węzłów procesowanych przez SceneTree i nierówne miksowanie ambience.

**Proponowany diff (niezastosowany):**

~~~diff
--- a/game/scripts/autoload/sfx.gd
+++ b/game/scripts/autoload/sfx.gd
@@
 var _duck_tween: Tween = null
+var _last_duck_ms := -1000
@@
 func duck_ambience(db: float, ms: float) -> void:
 	if _ambience == null or not _ambience.playing:
 		return
+	var now := Time.get_ticks_msec()
+	if db > -12.0 and now - _last_duck_ms < 50:
+		return
+	_last_duck_ms = now
 	if _duck_tween != null:
~~~

### M28 — Jeden zakup powoduje trzy zapisy i trzy przebudowy listy

**Priorytet:** Medium · **Plik:linia:** [game/scripts/ui/workshop_screen.gd:115](https://github.com/woogitsugames/lockwright/blob/9f3ce645a340f4998faad68e6699996d3285b5f2/game/scripts/ui/workshop_screen.gd#L115)

**Opis:** _buy wykonuje trzy Save.set_value, każde wywołuje Save.save() i sygnał changed. _ready:74 łączy changed z _refresh, który queue_free wszystkich wierszy i wczytuje tools.json; dzieje się to trzykrotnie podczas jednego kliknięcia.

**Ryzyko:** Zbędne I/O, mikrozacięcia i potencjalne migotanie UI na telefonie.

**Proponowany diff (niezastosowany):**

~~~diff
--- a/game/scripts/autoload/save.gd
+++ b/game/scripts/autoload/save.gd
@@
 func set_value(path: String, value: Variant) -> void:
@@
 	save()
+
+func set_many(patches: Dictionary) -> void:
+	# Implement a shared path setter with deferred save().
+	for path in patches:
+		_set_value_without_save(path, patches[path])
+	save()
--- a/game/scripts/ui/workshop_screen.gd
+++ b/game/scripts/ui/workshop_screen.gd
@@
-	Save.set_value("coins", coins - price)
-	Save.set_value("tools/%s/owned" % tool_id, true)
-	Save.set_value("tools/%s/integrity" % tool_id, 100)
+	Save.set_many({
+		"coins": coins - price,
+		"tools/%s/owned" % tool_id: true,
+		"tools/%s/integrity" % tool_id: 100
+	})
# _set_value_without_save must reuse set_value's path traversal; do not duplicate save().
~~~

### M29 — Brak pewnego auto-pause na Androidzie przy przejściu w tło

**Priorytet:** Medium · **Plik:linia:** [game/scripts/photoreal/lock_photoreal.gd:194](https://github.com/woogitsugames/lockwright/blob/9f3ce645a340f4998faad68e6699996d3285b5f2/game/scripts/photoreal/lock_photoreal.gd#L194)

**Opis:** lock_scene.gd:63 reaguje na root.focus_exited, ale fotorealistyczne kontrolery nie podpinają analogicznej obsługi. Na telefonie należy obsłużyć NOTIFICATION_APPLICATION_PAUSED i po wznowieniu wyzerować aktywne dotknięcia/input; samo focus_exited nie pokrywa cyklu aplikacji.

**Ryzyko:** Pozostawione napięcie/wibracja podczas zablokowania ekranu, nieoczekiwany postęp po wznowieniu.

**Proponowany diff (niezastosowany):**

~~~diff
--- a/game/scripts/photoreal/lock_photoreal.gd
+++ b/game/scripts/photoreal/lock_photoreal.gd
@@
+func _notification(what: int) -> void:
+	if what == NOTIFICATION_APPLICATION_PAUSED and not _paused:
+		_on_pause()
+		sampler.reset_touches()
# Merge this branch with H16 Android Back notification; add reset_touches() to InputSampler.
~~~

### M30 — Pełne kopiowanie modelu elementów w każdej klatce symulacji

**Priorytet:** Medium · **Plik:linia:** [game/scripts/photoreal_families/family_lock_session.gd:204](https://github.com/woogitsugames/lockwright/blob/9f3ce645a340f4998faad68e6699996d3285b5f2/game/scripts/photoreal_families/family_lock_session.gd#L204)

**Opis:** describe() zawsze wywołuje _elements.duplicate(true) (line224), co alokuje nowe słowniki elementów. Kontroler photoreal_families woła describe() przy 120 Hz i dodatkowo podczas stanu frozen.

**Ryzyko:** Alokacje proporcjonalne do liczby elementów i wahania frame time na mobilnym CPU.

**Proponowany diff (niezastosowany):**

~~~diff
--- a/game/scripts/photoreal_families/lock_photoreal_family.gd
+++ b/game/scripts/photoreal_families/lock_photoreal_family.gd
@@
-	var vm: Dictionary = session.describe()
+	# Keep native event feedback on the 120 Hz path; build the VM on render ticks.
+	var vm: Dictionary = {}
@@
-	view.present(vm, input, delta)
+	_render_input = input
# In _process(delta): var vm := session.describe(); view.present(vm, _render_input, delta)
# Consider a cached shallow snapshot only if mutation/ownership is made explicit.
~~~

### L31 — Pomoc do czytania sprawdza niewłaściwy magazyn danych

**Priorytet:** Low · **Plik:linia:** [game/scripts/ui/tutorial.gd:23](https://github.com/woogitsugames/lockwright/blob/9f3ce645a340f4998faad68e6699996d3285b5f2/game/scripts/ui/tutorial.gd#L23)

**Opis:** _add_card używa Save.get_value('reading_aid'), lecz to ustawienie zdefiniowane w Settings.DEFAULTS. Czysta karta ułatwiająca odczyt nigdy nie zostaje wybrana na podstawie przełącznika ustawień.

**Ryzyko:** Niedziałająca opcja dostępności dla kart samouczka.

**Proponowany diff (niezastosowany):**

~~~diff
--- a/game/scripts/ui/tutorial.gd
+++ b/game/scripts/ui/tutorial.gd
@@
-	if Save.get_value("reading_aid", false):
+	if Settings.get_value("reading_aid", false):
~~~

### L32 — Próg rozdziału stref gestu jest przesunięty na węższych ekranach

**Priorytet:** Low · **Plik:linia:** [game/scripts/lock/input_sampler.gd:38](https://github.com/woogitsugames/lockwright/blob/9f3ce645a340f4998faad68e6699996d3285b5f2/game/scripts/lock/input_sampler.gd#L38)

**Opis:** maxf(vp.x,412) wymusza half co najmniej 206; jeśli szerokość canvas jest mniejsza, prawa strefa zaczyna się dalej niż w połowie. Jest to m.in. problem podczas części układów wielookienkowych.

**Ryzyko:** Niezgodność obszarów dotyku z bieżącym układem widoku.

**Proponowany diff (niezastosowany):**

~~~diff
--- a/game/scripts/lock/input_sampler.gd
+++ b/game/scripts/lock/input_sampler.gd
@@
-			var half := maxf(vp.x, 412.0) * 0.5
+			var half := (vp.x if vp.x > 0.0 else 412.0) * 0.5
~~~

### L33 — reset() nie czyści wszystkich znaczników czasu

**Priorytet:** Low · **Plik:linia:** [game/scripts/autoload/feedback_director.gd:124](https://github.com/woogitsugames/lockwright/blob/9f3ce645a340f4998faad68e6699996d3285b5f2/game/scripts/autoload/feedback_director.gd#L124)

**Opis:** reset() zeruje tablice, lecz pozostawia _duck_until_ms i _last_continuous_sent. Po ponownym wejściu w zamek w krótkim odstępie może przez chwilę tłumić nowe sygnały.

**Ryzyko:** Krótkotrwały brak oporu po zmianie sceny.

**Proponowany diff (niezastosowany):**

~~~diff
--- a/game/scripts/autoload/feedback_director.gd
+++ b/game/scripts/autoload/feedback_director.gd
@@
 func reset() -> void:
@@
 	_last_continuous.clear()
+	_last_continuous_sent = 0.0
+	_duck_until_ms = 0.0
~~~

## Pokrycie i testy odbiorcze

1. **Kontrakt sesji:** uruchomić sceny lock.tscn, lock_job.tscn i wszystkie rodziny w trybie natywnym oraz po wyłączeniu GDExtension; porównać step() z sześcioma osiami. Dla fallbacku sprawdzić deterministyczne zakończenie false_set, overset i detector_trip.
2. **120 Hz:** profilować 5 minut na fizycznym średnim Androidzie: p50/p95/p99 CPU, frame time, allocations/frame, GC, audio underruns, liczbę sygnałów/s oraz haptics latency. Wersja bez renderowego describe() na physics tick musi dawać takie same stany.
3. **Sceny i pauza:** otwarcie→płatność→Continue, porażka→retry, tutorial S1–S3, 10 kolejnych zamków w run, 0 żyć, wielokrotny reset ustawień, 100 przejść scena↔scena; sprawdzić brak pozostających AudioStreamPlayer/continuous haptics i zero paused po wyjściu.
4. **Android:** Back w zamku, przy otwartym menu pauzy, w menu głównym, po wygaszeniu i wznowieniu ekranu; gesty 2–3 palców, obrót 179°→−179°, szerokości poniżej 412 dp. Sprawdzić politykę systemowego Back na urządzeniu i przy gestowej nawigacji.
5. **Regresja:** rozbudować test_pause_quit.gd o lock_job/family oraz Android Back notification, test_input_sampler.gd o nakładające się palce/push/rotate, test_e2e_career.gd o faktyczne nawigacje, a lock_test.gd o twardy warunek is_open() lub kontrolowane failure zamiast tylko obecności zdarzeń.

### Status weryfikacji API Godot 4.7

Przegląd konfiguracji, API GDScript, scen i wiązania C++ potwierdza użycie interfejsów z rodziny Godot 4 (np. SceneTree.change_scene_to_file(), Node.PROCESS_MODE_ALWAYS, DisplayServer, InputEventScreenTouch, CanvasLayer, SubViewport). **Nie stwierdzono w przeglądanych fragmentach jednoznacznie wywołania z Godot 3, które należałoby mechanicznie zamienić.** Ryzyka API to przede wszystkim niepoprawne założenia o trybie pauzy, Android Back i zgodności kontraktu step() z lokalnym fallbackiem.

Źródła oficjalne do sprawdzenia zachowania platformowego:
- https://docs.godotengine.org/en/stable/tutorials/scripting/pausing_games.html
- https://docs.godotengine.org/en/latest/tutorials/inputs/handling_quit_requests.html
- https://docs.godotengine.org/en/stable/classes/class_node.html
- https://docs.godotengine.org/en/latest/classes/class_mainloop.html

**Ograniczenia:** nie uruchamiano Godota 4.7.2, importu projektu, profilerów GPU ani testów na Androidzie w tej sesji; środowisko wykonawcze nie udostępnia binarki Godot. Wskazane skutki wynikają z analizy kodu i kontraktów, a nie z pomiarów empirycznych. Fragmenty diffów oznaczone komentarzem o integracji wymagają dodatkowego kodu oraz testów przed użyciem w produkcji.

### Kontekst produktu

Uwzględniono zasady CLAUDE.md, docs/DESIGN.md, docs/CLIENTS.md, docs/JOBS.md i docs/DECISIONS.md (D-06 i D-51): gra o legalnej pomocy ślusarskiej, mechanizmy wymyślone, Android jako aktualny priorytet, brak zobowiązań co do ceny i premiery. Raport nie zmienia tekstów gracza ani ekonomii poza wskazaniem błędu przyznawania nagród.
