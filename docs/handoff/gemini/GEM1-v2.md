# Zlecenie GEM1-v2: zwiastun, wersja 2

**Dla:** ta sama sesja Gemini w Antigravity, która zrobiła GEM1. Zasady z `GEM1.md` obowiązują dalej. Przeczytaj `docs/DECISIONS.md` D-49.

## Co poprawić
1. **Plansza końcowa:** usuń „Dostępne na Android · iOS”. Zostaje tylko logo „Lockwright” na emaliowanej tabliczce i dopisek „Pogotowie Zamkowe” / „Locksmith on Call”. Gra nie jest jeszcze w sklepach.
2. **Ludzie i historia:** na początku i w środku wstaw ujęcia z key artu: `contrib/incoming/magnific/selected/keyart_16x9.jpg`, `keyart_9x16.jpg` i `keyart_1x1.jpg` (pion). Zrób to jako ujęcia z lekkim ruchem kamery (Ken Burns, 2–3 s, powolny dolly/zoom, bez efektów). Kolejność: klientka w drzwiach → notes ślusarza (weryfikacja) → przekrój → otwarcie → klientka się uśmiecha (ostatnie ujęcie przed planszą).
3. **Materiały przekroju:** jeśli w `art/textures/photo/` są już gotowe materiały (`brass_turned`, `brass_face_milled`, `steel_ground`, `spring_steel_polished`, `nickel_satin`), podmień nimi proceduralne materiały w `art/blender/marketing/` i wyrenderuj ujęcia przekroju jeszcze raz (OptiX, 128–256 spp). Mosiądz i stal mają być satynowe, nie lustrzane.
4. **Mniej zbliżeń, więcej czytelności:** maksymalnie 40% czasu w ekstremalnym zbliżeniu. Przynajmniej raz pokaż cały przekrój z napinaczem i wytrychem w kadrze.

## Jak oddać
Jak w GEM1: skrypty na `main`, filmy do Release `gemini-gem1-v2`, raport `art/marketing/REPORT-v2.md`.
