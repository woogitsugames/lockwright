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

## Sceny otoczenia: klatka schodowa (przyjazd) i warsztat (hub)
Skrypty: `art/blender/stairwell.py`, `art/blender/workshop.py`, wspólne materiały w `art/blender/env_common.py` (dąb z łukami słojów i porami, olejna lamperia z odpryskami, wapno ze spękaniami, lastryko, emalia, papier, bakelit, cegła pod wapnem, zabrudzenia jako przezroczyste naklejki). Wszystko z parametrów, bez pobranych modeli i tekstur; jedyny obraz to HDRI `interior.exr` z Blendera (CC0). Makiety: `mockups/realizm/03-job.html`, `04-workshop.html`.

- **Kadr 9:16** (master 2160×3840). Ważne rzeczy leżą w środkowych ~80% szerokości, bo telefon 9:19,5 przycina boki. Kamera architektoniczna (poziom, pion prosty, przesunięcie obiektywu), ogniskowa jak w telefonie (24 mm / 18 mm), bez DOF; w postprodukcji tylko lekka winieta i aberracja chromatyczna obiektywu.
- **Klatka:** drzwi płycinowe z osobnymi ramiakami, płycinami i listwami (każdy element ma własny słój), wymyślona wkładka z długim szyldem, emaliowana tabliczka z numerem (Bona Nova), wizytówka w mosiężnej ramce, wycieraczka z kokosu (kępki włókien w rzędach), lamperia, lastryko z wytartą ścieżką, poręcz na tralkach, włącznik minutnika z kontrolką, opalowy klosz. Ślady życia: kopeć nad lampą, brud wokół włącznika, ulotka w szczelinie drzwi.
- **Tekst tylko na przedmiotach.** Blender eksportuje obok renderu `<render>.json`: rzut narożników powierzchni, na których da się pisać (kartka zlecenia na podkładce w dłoni, wizytówka, tabliczki, ekran telefonu, etykieta zeszytu, karta na szufladzie), oraz obszary dotyku (włącznik, wkładka, imadło, gablota). `mockups/realizm/anchors.js` nakłada tekst homografią (`matrix3d`), więc druk i ołówek leżą w perspektywie zdjęcia, a cele dotyku mają ≥ 48 px. Teksty są przykładowe (PL); w grze idą przez i18n.
- **Przyjazd (Tryb Zleceń, HUD §7.1):** ślusarz trzyma podkładkę z kartką z dyspozytorni (kadr ucina podkładkę, ręce poza kadrem). Na kartce: adres, klient, sytuacja, stawka, i dwa pola ołówkiem: „Pytam o dokumenty” (przejście do weryfikacji, JOBS §2) i „Odmawiam”. Dotknięcie włącznika minutnika to wyzwanie „w ciemności” (HUD §10), dotknięcie wkładki to podgląd zamka.
- **Wariant nocny (`--night`):** minutnik zgaszony; zostaje chłodne okno klatki, sodowa latarnia zza okna, ciepła smuga pod drzwiami i w wizjerze (w mieszkaniu pali się lampa) i pomarańczowa kontrolka włącznika, po której gracz go znajduje.
- **Warsztat (hub):** blat z klejonych listew bukowych, imadło z wkładką ćwiczebną, wymyślona kopiarka kluczy, tablica perforowana z narzędziami i zestawem wytrychów, tablica półfabrykatów, gablota z otwartymi zamkami (własne światło), lampa przegubowa jako ciepły klucz, chłodne okno z lewej. Wyjścia z huba to przedmioty: kartka dyżuru na podkładce (Tryb Ciągły), telefon (Tryb Zleceń), metka przy imadle (ćwiczenia), metka gabloty, etykieta zeszytu (ustawienia), karta w ramce szuflady (narzędzia).
- **Koszt:** 2160×3840 przy 48 próbkach i odszumianiu to kilka godzin na 2 wątkach CPU (podział z innymi agentami). Wersja docelowa 160 próbek wymaga mocniejszej maszyny albo GPU; skrypty przyjmują `--samples`.
