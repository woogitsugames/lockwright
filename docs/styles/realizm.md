# Kierunek: Realizm / Photoreal (wybrany przez właściciela, D-05)

> Status: **wybrany**. Kierunki `plansza`, `przeswit`, `klatka` i `sodowa` zostają w repo jako archiwum. Z `klatka` przejmujemy świat (kamienica, emaliowane tabliczki, lamperia) i czasem kredę jako opcjonalną pomoc.

## Idea
**Zamek ma wyglądać jak prawdziwy: przekrój obrobionego metalu w prawdziwych drzwiach, w świetle, które go modeluje.**

Gracz ma czuć, że pod palcami jest mechanizm, a nie rysunek. Realizm wspiera grę na wyczucie, bo obraz, dźwięk i haptyka opowiadają o tym samym, fizycznym przedmiocie. Mechanizm jest wymyślony i bez marki, a proporcje są dobrane pod czytelność (np. szczelina linii podziału 0,2 mm zamiast realnych ~0,05 mm, piny ≥ 28 dp).

## Jak realizm tłumaczy mechanikę
Stany są czytelne z **geometrii i ruchu**, czyli z tego, co w prawdziwym przekroju zobaczyłby ślusarz:

| Stan | Co widać w realistycznym przekroju |
|---|---|
| swobodny | pin górny przechodzi przez linię podziału, sprężyna luźna |
| binding | pin górny lekko przechylony i dociśnięty do ścianki otworu (2–3°), drga przy ruchu wytrycha |
| near_shear | szczelina między pinem dolnym a linią podziału zwęża się do szpary światła |
| set | pin górny siedzi na krawędzi rdzenia, a pod nim widać jasną szczelinę nad opadniętym pinem dolnym |
| false set | szpulka: wyraźna talia na linii podziału, rdzeń obrócony głębiej |
| counter_rotate | napinacz i czoło rdzenia cofają się pod kciukiem |
| overset | pin dolny przechodzi przez linię podziału, sprężyna ściśnięta prawie zwój w zwój |
| stress | wytrych i napinacz uginają się widocznie (realna deformacja sprężystej stali) |
| break | końcówka zostaje w kanale |

Uzupełnienie dostępności: **opcjonalna warstwa „kreda”** (z kierunku Klatka) rysuje znaki kodu stanów (`DESIGN.md`) na wierzchu. Jest domyślnie włączona w samouczku S1–S3 i w opcji „Pomoc w czytaniu”. Ścieżka testu A7 („stany rozróżnialne bez koloru”) obejmuje oba warianty.

## Materiały

| Materiał | Wygląd | Rola |
|---|---|---|
| Nikiel / stal (korpus) | satynowa, ślady frezu czołowego, chłodny walor jasny | tło dla pinów, rama |
| Mosiądz (rdzeń, piny dolne) | ciepły, toczony, nieco jaśniejszy na pinach | to, czym „kręcimy” |
| Stal hartowana (piny górne) | ciemniejsza, gładka, ostrzejszy odblask | odróżnia górne od dolnych walorem |
| Stal sprężynowa (wytrych, napinacz) | polerowana, anizotropowa | ręka gracza |
| Żelazo (szyld) | matowe, ciemne | rama drzwi |
| Drewno (skrzydło) | słoje wzdłuż ramiaka, lakier | kontekst „prawdziwe drzwi” |
| Skóra (zwijka) | ziarno, przetarcia, przeszycia | HUD żyć (zapasowe wytrychy) |

Zasady: żadnego chromu (szorstkość ≥ 0,16), żadnego bloomu ani poświaty. Na linii podziału nie ma odblasku: szczelina jest ciemna, a krawędzie sfazowane ze zmatowieniem.

## Światło
Ciepła żarówka klatki schodowej (klucz, góra z lewej) i chłodne okno (wypełnienie). Duży softbox w kierunku odbicia płaszczyzny cięcia (połysk produktowy wydobywa ślady obróbki), do tego HDRI wnętrza (CC0, Poly Haven, dołączone do Blendera). Tryb „w ciemności”: gaśnie minutnik.

## Pipeline
- **Look-dev:** Blender 4.2 LTS, Cycles, skrypty proceduralne `art/blender/*.py`. Każdy element jest generowany z parametrów, więc nowa rodzina oznacza nowy skrypt, a nie ręczne modelowanie.
- **Gra:** ten sam model eksportowany do glTF i wczytywany w Godot 4.7 (renderer Mobile). Oświetlenie wypiekane (LightmapGI) dla nieruchomych części, a dynamiczne światło tylko dla ruchomych elementów. Spike 4 z `TECH.md` sprawdza 60 FPS na tanim Androidzie.
- **Makiety ekranów:** `mockups/realizm/` (render plus minimalny HTML UI).

## UI
Bez pływających paneli. Strefy kciuków są wytłoczone w skórze zwijki. Nagłówek to emaliowana tabliczka mieszkania (Bona Nova), a tekst to Atkinson Hyperlegible Next. Paski i liczniki nie istnieją: napięcie pokazuje kąt napinacza i czoło rdzenia, a życia to wytrychy w kieszeniach zwijki.

## Ryzyka
- **Wydajność na tanim Androidzie:** plan B to wypiekane oświetlenie i matcapy.
- **Realizm może sugerować instrukcję:** mechanizmy są wymyślone, proporcje grywalne, bez marek, a w grze jest notka „to gra, nie kurs”.
- **Koszt treści:** proceduralne skrypty Blendera na rodzinę.
