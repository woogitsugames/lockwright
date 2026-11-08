# N-93: TalkBack przez most D-97 — SM-A165F, 2026-11-08

APK `tools/local/build_apk.sh` z gałęzi D-97 (ten sam klucz co CI), `adb install -r` na zapisie właściciela.
TalkBack (`com.samsung.android.accessibility.talkback`) włączony przez `settings put secure`, po teście przywrócony
(`a11y_settings_baseline.txt` = `a11y_settings_after.txt`). Telefon zajęty przez `build/phone.lock` ok. 17:55–18:22.

- `01_menu_talkback_off.jpg` — menu przed włączeniem TalkBack.
- `02_menu_talkback_on.jpg` — okno uprawnień TalkBack zaraz po włączeniu (zostawione bez decyzji, gra wysunięta na wierzch).
- `03_menu_dump_bridge.xml` — `uiautomator dump`: 6 przycisków menu z nazwami i prostokątami (węzły mostu).
- `04_menu_focus_settings.jpg` — ramka fokusu TalkBack (niebieska) po skrótach klawiszowych: cały ekran, nie przycisk.
- `06_settings.jpg`, `06_settings_dump.xml` — Ustawienia: 23 węzły (przełącznik ze stanem, suwaki z wartością, teksty).
- `07_practice_lock.jpg`, `08_practice_after_lift.jpg` — ćwiczenie wafer (przerwane, bez monet) z TalkBack.
- `09_pause_talkback.jpg` — pauza; most publikuje tylko jej 4 węzły.
- `logcat_bridge.txt` — `LockwrightA11y` / `UiA11y`: liczby węzłów na każdym ekranie, ogłoszona linia kredy.
