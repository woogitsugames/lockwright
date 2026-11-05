# Lockwright — audyt lokalizacji v2 i głosów S03v2

**Migawka źródeł (main):** `e7aa59a4a5c301a3be3d417052bd859d227fce69` (5 listopada 2026 r.). Repozytorium jest aktywnie rozwijane; liczby w tym raporcie dotyczą tej wersji, a nie kolejnych commitów.

## Lokalizacje T31–T37

| Język | Pakiet | Wpisy UI | Wpisy narracyjne | Brakujące nowe klucze UI |
|---|---|---:|---:|---:|
| fr | T31 | 129 / 194 | 629 / 629 | 65 |
| es | T32 | 129 / 194 | 629 / 629 | 65 |
| it | T33 | 129 / 194 | 629 / 629 | 65 |
| pt_br | T34 | 129 / 194 | 629 / 629 | 65 |
| cs | T35 | 129 / 194 | 629 / 629 | 65 |
| uk | T36 | 129 / 194 | 629 / 629 | 65 |
| de | T37 | 129 / 194 | 629 / 629 | 65 |

Wykonano korektę 26 wpisów `job.*.note` przekraczających limit 130 znaków, a wcześniej wyeliminowano dialogi `*.line.*` i `*.after.*` przekraczające 90 znaków. Dodano w językach docelowych klucze `tutorial.start` oraz `nav.quit_confirm`, `nav.quit_yes`, `nav.quit_no`. Dostępne teksty sklepowe przeszły kontrole limitów długości.

**Nie należy uznawać tłumaczeń za zsynchronizowane z bieżącym `main`:** nowe elementy UI wprowadzane równolegle nie były częścią pierwotnych szkiców. Nie wolno wypełniać ich automatycznie tekstem EN i przedstawiać jako przetłumaczonych. Wymagają tłumaczenia i osobnej redakcji. Poniższe 65 kluczy jest wspólną luką wszystkich siedmiu pakietów w tej migawce.

- `menu.subtitle`
- `settings.section_sound`
- `settings.section_controls`
- `settings.section_access`
- `settings.section_other`
- `workshop.not_enough`
- `workshop.price`
- `workshop.reward_hint`
- `arrival.situation`
- `ui.controls.title`
- `ui.controls.auto`
- `ui.controls.auto_desc`
- `ui.controls.manual`
- `ui.controls.manual_desc`
- `ui.controls.note`
- `ui.controls.selected`
- `ui.controls.auto_toggle`
- `practice.t01.goal`
- `practice.t02.goal`
- `practice.t03.goal`
- `practice.t04.goal`
- `practice.t05.goal`
- `practice.t06.goal`
- `practice.t07.goal`
- `practice.t08.goal`
- `practice.t09.goal`
- `practice.t10.goal`
- `practice.t11.goal`
- `practice.t12.goal`
- `practice.t13.goal`
- `practice.t14.goal`
- `practice.t15.goal`
- `practice.t16.goal`
- `practice.t17.goal`
- `practice.t18.goal`
- `practice.t19.goal`
- `practice.t20.goal`
- `practice.t21.goal`
- `practice.t22.goal`
- `practice.t23.goal`
- `practice.t24.goal`
- `practice.t25.goal`
- `practice.t26.goal`
- `practice.t27.goal`
- `practice.t28.goal`
- `practice.t29.goal`
- `practice.t30.goal`
- `tutorial.s1_tension`
- `tutorial.s1_pick`
- `tutorial.s1_binding`
- `tutorial.s1_click`
- `tutorial.s1_overset`
- `tutorial.s1_overset_auto`
- `tutorial.s1_open`
- `tutorial.frame_tension`
- `tutorial.frame_lift`
- `tutorial.frame_click`
- `tutorial.frame_lift_auto`
- `tutorial.note_game`
- `lock.zone_tension`
- `lock.flap_pause`
- `lock.hint_tension`
- `tutorial.s2_intro`
- `tutorial.s3_intro`
- `tutorial.s1_near_break`

## Powtarzalna walidacja

Uruchom z katalogu głównego:

```sh
python contrib/gpt/validate_v2_localizations.py --json
```

Program korzysta tylko z biblioteki standardowej Pythona; sprawdza dokładność kluczy, duplikaty, placeholdery, limity dialogów/zeszytu i sklepu, drukuje brakujące nowe klucze oraz kończy się błędem, gdy pakiety nie są kompletne. **Obecny wynik globalny powinien być FAIL**, ponieważ 65 × 7 kluczy UI pozostaje do tłumaczenia (stan na SHA powyżej).

## S03v2 — weryfikacja metadanych GitHub

- Sprawdzono niezależnie listę w drzewie `contrib/gpt/S03v2/voices` i wszystkie wpisy `manifest.json`: **39 postaci × 8 emocji = 312 istniejących plików WAV**, bez braków i zbędnych nazw.
- Wszystkie 312 rozmiarów plików są zgodne z czasami zapisanymi w manifeście dla WAV PCM16/48 kHz mono.
- Metadane manifestu: czas 0,52096–1,35829 s, −28 LUFS momentary, maksymalny onset 8,04 ms, najdłuższy ogon ciszy 39,08 ms; brak przekroczeń zadanych progów.
- Test ASR **nie był wykonywany**, bo dostępne środowisko nie ma zainstalowanego modelu rozpoznawania mowy. Bezsłowny generator nie jest równoważny testowi ASR. Dodałem skrypt `contrib/gpt/S03v2/asr_smoke_test.py`, który oznaczy ewentualne transkrypcje do ręcznego odsłuchu po zainstalowaniu `faster-whisper` i modelu.
- Odsłuch aktorski i testy wyświetlania tłumaczeń w rzeczywistej aplikacji pozostają do wykonania; sama kontrola statyczna ich nie zastępuje.

## Status

**Gotowe:** spójność podstawowych kluczy T31–T37 na migawce sprzed rozbudowy UI, korekty ograniczeń tekstowych, obecność i parametry WAV S03v2, narzędzia audytowe.

**Otwarte:** 65 nowych kluczy UI × 7 języków, niezależna korekta native, testy UI na urządzeniu oraz ASR/odsłuch postaci.