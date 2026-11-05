# Lista kontrolna przed wydaniem 1.0

Prowadzi: sesja C (etap 4, zadanie 4). Stan na **2026-11-05 11:17 UTC**. Aktualizuję przy każdej rundzie przeglądu.
Legenda stanu: ✅ gotowe · 🟡 częściowo / w toku · ❌ brak / czerwone · ⏸ czeka na decyzję lub dane właściciela.
Odpowiedzialni: **A** (lockcore, art, mockups, `game/*/photoreal/`), **B** (`game/`, `platform/`, `data/`, `game-*.yml`),
**C** (QA, sklep, prawo, strona, audyty), **W** (właściciel).

## 1. Technika

| # | Punkt | Próg / wymaganie | Stan | Odp. | Dowód |
|---|---|---|---|---|---|
| T1 | CI zielone na `main` (game-tests, game-android, game-ios, game-screens, lockcore, qa-career, perf-budget, spike-determinism*) | wszystkie zielone na commicie wydania | ❌ game-tests, game-android, game-ios, game-screens czerwone | B | `SESSION-C-REVIEW.md` N-19, N-21…N-24 |
| T2 | Build wydaniowy Android: AAB podpisany kluczem z sekretów | AAB w artefakcie, `versionCode` rośnie | ❌ AAR nie kompiluje się (N-23) | B, W (klucz) | `SESSION-B-PROMPT-4.md` §8, `TESTY-SKLEPY.md` §A.3 |
| T3 | Build wydaniowy iOS: IPA podpisany → TestFlight | `game-ios-release.yml` z sekretami | ❌ build iOS nie kompiluje się (N-24); sekrety ⏸ | B, W | `TESTY-SKLEPY.md` §B |
| T4 | Rozmiar APK / IPA | APK ≤ 80 MB (twardo 150), IPA ≤ 100 MB pobrania | 🟡 zasoby 26,5 MB (pck), APK do zmierzenia po T2 | C | `POMIARY.md` §8, `perf-budget` |
| T5 | Start do menu | tani ≤ 4 s, średni ≤ 2 s (zimny) | 🟡 headless 0,36 s (proxy); telefon niezmierzony | C, W | `POMIARY.md` §8 |
| T6 | FPS ekranu zamka (plan B) | p95 ≤ 16,7 ms, 1% low ≥ 55 FPS przez 10 min na tanim Androidzie | ⏸ APK `planb-perf-apk` gotowe, pomiar właściciela | W | `POMIARY.md` §7a |
| T7 | Pamięć | ≤ 350 MB PSS (tani), ≤ 450 MB (średni) | ⏸ pomiar na telefonie | W, C | `POMIARY.md` §8 |
| T8 | Opóźnienia haptyki i dźwięku (spike 1–3) | progi `TECH.md` §4 | ⏸ aplikacja „LW Pomiary” gotowa, pomiar właściciela | W | `POMIARY.md` §1–6 |
| T9 | Determinizm lockcore na urządzeniach | identyczne hashe powtórek host ↔ arm64 | ✅ qemu/macOS (spike-determinism); ✅ APK arm64 w emulatorze Android 14: 630/630, digest = host (run 42012656332); 🟡 API 30 i telefon natywny | C | `spike-determinism-apk`, `spikes/determinism/README.md` |
| T10 | Crash-free | ≥ 99,5% sesji w teście zamkniętym (Play Console vitals / TestFlight) | ⏸ wymaga testu w sklepach | W, B | `TESTY-SKLEPY.md` |
| T11 | Kariera przechodnia bez soft-locków | `qa-career`: 0 soft-locków, 0 ekranów bez wyjścia | ❌ HEAD: bloker N-29 (`lock_job.gd` nie kompiluje się, 0/29); z poprawką N-29 (2 linie): ✅ 19/29 (wszystkie widoczne poza odmowami), samouczek ukończony, 0 soft-locków | B | `SESSION-C-REVIEW.md` runda 5, `qa/run_matrix.sh` |
| T12 | Brak `float` w lockcore, testy i fuzz | `ctest`, fuzz 100k | ✅ | A | workflow `lockcore` |
| T13 | Auto-pauza przy wyjściu z aplikacji, zapis stanu | zachowanie R-03 | 🟡 w `lock_scene.gd`; ekran planu B do sprawdzenia | B, A | `lock_photoreal.gd` |

## 2. Treść

| # | Punkt | Wymaganie | Stan | Odp. | Dowód |
|---|---|---|---|---|---|
| C1 | i18n PL + EN 100% | każdy klucz w obu językach, brak tekstów na sztywno | ✅ `loc_qa.py`: OK (105 + 357 wierszy); 🟡 ostrzeżenia o długości EN (np. `job.refuse_rush_bribe.title`) | B | `data/tools/loc_qa.py` |
| C2 | Ucięte teksty na ekranach (PL, EN, 150% tekstu) | brak | 🟡 skalowanie ✅ (A-11); safe-area poprawna na telefonie, na desktopie/CI nadal poza ekranem (A-10) → zrzuty EN do powtórzenia | B | `A11Y-AUDIT.md`, `SESSION-C-REVIEW.md` runda 5 |
| C3 | Notka „to gra, nie kurs” | w grze (O grze + start), w sklepie, na stronie | 🟡 gra: `about.notice` ✅, start: panel 3 s (N-12); sklep ✅; strona ✅ | B, C | `store/legal/notice_*.md`, `site/` |
| C4 | Licencje zasobów | każdy plik w `docs/ASSETS.md` (własne / CC0 / OFL / AI z promptem, D-42) | 🟡 do sprawdzenia przed wydaniem automatem (lista plików `game/` vs ASSETS) | C | `docs/ASSETS.md` |
| C5 | `THIRD-PARTY-NOTICES` w aplikacji (Godot MIT, FreeType, ICU…, godot-cpp, fonty OFL) | ekran „Licencje” lub plik w aplikacji | ❌ pliku nie ma w repo | B, C (lista) | `store/legal/DEPENDENCIES.md` (zad. 8) |
| C6 | Brak marek, brak instruktażu do realnych zamków, ton „pomagamy” | przegląd tekstów i grafik | 🟡 teksty gry przejrzane pod rating (`store/rating.md` §5); dostawy ChatGPT — przegląd na bieżąco | C | `contrib/REVIEW.md` |
| C7 | Odmowy zleceń: jednorazowa nagroda, zapis | JOBS.md §5 | ✅ N-15 naprawione (828e019) | B | `SESSION-C-REVIEW.md` runda 5 |

## 3. Sklep

| # | Punkt | Stan | Odp. | Dowód |
|---|---|---|---|---|
| S1 | Nazwy, podtytuły, opisy PL/EN w limitach znaków | ✅ (`check_lengths.py` ALL OK) | C | `store/listing.md`, `store/tools/check_lengths.py` |
| S2 | Zrzuty (iPhone 6,9" + Android, PL/EN) z prawdziwej gry | 🟡 5/8 kadrów z gry (wersja robocza), menu w domyślnym wyglądzie | C, B | `store/screenshots/PLAN.md`, `contact_game_*.png` |
| S3 | App Preview / film Play | 🟡 scenariusz i ujęcia gotowe; nagranie po N-13/N-14 | C, W | `store/APP-PREVIEW.md` |
| S4 | Klasyfikacja wiekowa (Apple, IARC) | ✅ odpowiedzi gotowe; ⏸ wypełnienie w konsoli | C, W | `store/rating.md` |
| S5 | Prywatność: App Privacy, Data safety, manifest `PrivacyInfo.xcprivacy` | ✅ odpowiedzi + manifest zweryfikowany | C, W | `store/privacy.md` |
| S6 | Kontakt, URL wsparcia i polityki | ⏸ domena i e-mail | W | `store/rating.md` §6.3 |
| S7 | Ikona aplikacji (wszystkie rozmiary) | ⏸ czeka na G12 (ChatGPT) i przegląd | A, C | `contrib/REVIEW.md` |
| S8 | Grafika promocyjna Google Play 1024×500 | ⏸ czeka na G13 | A, C | `contrib/REVIEW.md` |
| S9 | Model biznesowy i cena | ⏸ D-06 | W | `docs/DECISIONS.md` |
| S10 | Notatka dla recenzenta Apple | ✅ | C | `store/rating.md` §3 |

## 4. Prawo

| # | Punkt | Stan | Odp. | Dowód |
|---|---|---|---|---|
| L1 | Warunki korzystania / EULA (PL/EN) | 🟡 szkic, miejsca D-06; ⏸ prawnik | C, W | `store/legal/terms_*.md` |
| L2 | Polityka prywatności (PL/EN) | 🟡 szkic zgodny z grą; ⏸ dane administratora, prawnik | C, W | `store/privacy.md`, `store/legal/privacy_*.md` |
| L3 | DSA: status „trader”, dane kontaktowe w sklepach | ⏸ | W | `TESTY-SKLEPY.md` |
| L4 | Sprawdzenie nazwy (znaki towarowe) | 🟡 wstępnie w `RESEARCH.md`; ⏸ wyszukanie w EUIPO/USPTO przed premierą | W, C | `docs/RESEARCH.md` |
| L5 | Licencje zależności i obowiązki | ⏸ zadanie 8 | C | `store/legal/DEPENDENCIES.md` |

## 5. Dostępność

| # | Punkt | Stan | Odp. | Dowód |
|---|---|---|---|---|
| A1 | Cele dotyku ≥ 48 dp, elementy ≥ 28 dp | 🟡 cele ✅; klapka pauzy planu B ~14 dp (A-03) | A | `A11Y-AUDIT.md` |
| A2 | Safe-area na wszystkich ekranach | 🟡 A-10: poprawne na telefonie (okno = ekran), na desktopie/CI menu poza widokiem | B | `SESSION-C-REVIEW.md` runda 5 |
| A3 | Stany rozróżnialne w skali szarości, 3 kanały | ✅ ekran zamka | A, B | `A11Y-AUDIT.md`, `DESIGN.md` §1 |
| A4 | Rozmiar tekstu, ogranicz ruch | 🟡 rozmiar tekstu ✅ (A-11); „ogranicz ruch” — do sprawdzenia (A-07) | B, A | `A11Y-AUDIT.md` |
| A5 | Krój pisma OFL (nie systemowy jako jedyny) | 🟡 Atkinson ✅, Bona Nova nieużyta | B | `A11Y-AUDIT.md` A-04 |
| A6 | Tryb „w ciemności”: bez nagród na wyłączność, informacja o dźwięku | ✅ nota w ustawieniach | B | A-06 |
| A7 | Czytniki ekranu (nazwy elementów bez tekstu) | ❌ A-09 | B, A | `A11Y-AUDIT.md` |

## 6. Marketing

| # | Punkt | Stan | Odp. | Dowód |
|---|---|---|---|---|
| M1 | Strona gry PL/EN | ✅ zbudowana; ⏸ publikacja (zgoda, domena) | C, W | `site/`, `site/deploy/pages.yml` |
| M2 | Press kit | 🟡 karta ✅; paczka `press/` (logo, ikona, zwiastuny) po G12/G13 i nagraniach | C, A | `docs/MARKETING.md` §3, `site/…/press.html` |
| M3 | Zwiastuny 30 s / 15 s | ⏸ rendery R01–R13 (A), montaż | A, C | `docs/MARKETING.md` §1–2, §4 |
| M4 | Strona „Jak gramy uczciwie” | ⏸ zadanie 7 etapu 4 | C | — |

## 7. Ostatni dzień (kolejność)
1. T1–T3 zielone na tym samym commicie; tag `v1.0.0`.
2. `qa-career` OK (T11), `perf-budget` OK, `loc_qa.py` OK, lista zasobów vs ASSETS (C4).
3. Test zamknięty: ≥ 12 testerów × 14 dni (konto osobiste Google) lub zgodnie z planem testów; crash-free (T10).
4. Konsole: rating, prywatność, Data safety, ceny, kraje, kontakt (S4–S9, L3).
5. Wysyłka do przeglądu: Apple (zwykle 1–2 dni), Google (zwykle 1–3 dni, dla nowych kont dłużej).
