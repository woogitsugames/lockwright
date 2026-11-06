# T121 — czytelność kolorów i kontrastu na zrzutach

Przegląd wizualny 46 z 257 plików PNG/JPG w docs/handoff/device-tests/fixes/**, w oryginalnej rozdzielczości zrzutów. To wybór próbek, nie pełny audyt. Obejrzano pliki:

- ui/job_arrival_360x800.jpg, ui/job_arrival_915x412.jpg;
- ui/settings_360x800.jpg, ui/settings_915x412.jpg, ui/jobs_list_360x800.jpg;
- ui/control_choice_360x800.jpg, ui/control_choice_915x412.jpg;
- ui/showcase_915x412.jpg, ui/workshop_360x800.jpg;
- landscape/tutorial_intro_915x412.png, landscape/tutorial_s1_authored_915x412.png;
- hints/h3_chalk_portrait.jpg, hints/h4_master_landscape.jpg;
- lessons/arrival_family_caption_combo_412x915.jpg, lessons/time_lock_step1_wind_412x915.jpg, lessons/dimple_step3_two_clicks_auto_412x915.jpg.
- menu_v2_gpu/menu_360x800_de.png, menu_v2_gpu/menu_915x412_en.png, menu_v2_gpu/menu_412x915_pl_pressed_jobs.png;
- planb_axial_slider/set_915x412.png, planb_combo/slip_915x412.png, planb_combo/open_412x915.png;
- lessons/combo_step1_pull_412x915.jpg, lessons/axial_slider_step2_press_412x915.jpg, lessons/disc_detainer_step2_auto_412x915.jpg, lessons/magnetic_step2_guide_auto_412x915.jpg;
- ui/main_menu_360x800.jpg, ui/main_menu_915x412.jpg, ui/showcase_360x800.jpg, ui/workshop_915x412.jpg, ui/jobs_list_915x412.jpg;
- landscape/settings_915x412.png, landscape/tutorial_intro_412x915.png, landscape/tutorial_s1_authored_412x915.png;
- hints/h1_imprint_landscape.jpg, hints/h2_ghost_landscape.jpg, hints/h3_chalk_landscape.jpg, hints/h4_master_portrait.jpg;
- planb_dial_safe/rest_412x915.png, planb_disc_detainer/rest_915x412.png, planb_egyptian/rest_412x915.png, planb_time_lock/rest_915x412.png, planb_magnetic/rest_412x915.png, planb_dimple/rest_915x412.png;
- lessons/egyptian_step1_pull_412x915.jpg, lessons/dial_safe_step2_turn_412x915.jpg.

## Obserwacje wizualne

- ui/workshop_360x800.jpg: mały szary tekst „Integralność 100%” i „Naprawa: 5 monet” na ciemnym, zmiennym tle jest słabiej czytelny niż nazwy elementów. Warto sprawdzić kontrast w kilku miejscach tła i rozmiar na urządzeniu.
- ui/control_choice_360x800.jpg: szary podpis nad przyciskiem na tle fotografii ma drobny krój i niski odbierany kontrast. Warto zapewnić mu jednolite tło lub mocniejszy kontrast.
- lessons/time_lock_step1_wind_412x915.jpg: biała odręczna wskazówka leży częściowo na jasnej fakturze i jest drobna; ocenić czytelność na rzeczywistym ekranie i przy powiększeniu tekstu.
- hints/h3_chalk_portrait.jpg: cienki odręczny napis pod strzałką ma mniejszą czytelność niż sama strzałka. Podobnie w hints/h4_master_landscape.jpg napis przy tarczy jest drobny.
- ui/job_arrival_360x800.jpg oraz ui/settings_915x412.jpg: główne teksty na jednolitych panelach są wizualnie wyraźne w tej próbce. Nie dowodzi to zgodności wszystkich stanów lub języków.
- planb_dial_safe/rest_412x915.png: małe liczby na tarczy są trudniejsze do odczytania od dużych elementów sterujących; sprawdzić czytelność w ruchu i przy docelowych wymiarach urządzenia.
- menu_v2_gpu/menu_360x800_de.png: dolne pozycje menu są ciemniejsze od górnych; należy pomierzyć kontrast w rzeczywistym stanie i sprawdzić przy niskiej jasności ekranu.

## Pomiary i ograniczenia

Nie wykonano pomiarów współczynnika kontrastu ani symulacji zaburzeń widzenia barw. Obserwacja wizualna nie jest wynikiem WCAG: tło fotografii, antyaliasing, kompresja JPEG i różne stany wymagają pomiaru rzeczywistych kolorów w kontekście oraz testu na urządzeniu. Nie obejrzano pozostałych 211 obrazów, w tym większości wariantów menu i rodzin zamków. Zrzuty są historycznymi dowodami stanu, a nie gwarancją obecnego wyglądu gry.
