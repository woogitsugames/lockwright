# Nowe rodziny lockcore (D-59) — research i projekt gry

Status: 2026-11-05, noc. Research na poziomie encyklopedycznym przed implementacją ośmiu rodzin, których brakuje
11 zleceniom (`game/data/jobs/*.json`): `dial_safe` (2 zlecenia: t1, t2), `combo` (2: t1, t3), potem po jednym:
`dimple`, `disc_detainer`, `egyptian`, `axial_slider`, `time_lock`, `magnetic`.

Zasady (CLAUDE.md): mechanizmy w grze są **wymyślone** na bazie ogólnej zasady działania; bez marek, bez modeli,
bez instrukcji do realnych, nazwanych produktów. Tolerancje i sygnały są dobrane pod grywalność, nie pod realizm.
Nazwiska wynalazców i nazwy firm w sekcji „Historia” to wyłącznie kontekst tego dokumentu (jak w `docs/LOCKS.md`);
w grze rodziny mają nazwy ogólne. Gry innych twórców oglądamy tylko po to, żeby wiedzieć, czego **nie** kopiować
i co w ogóle sprawia frajdę — nie przenosimy UI, nazw ani grafik.

Wejścia lockcore zostają bez zmian (`InputFrame`): lewy kciuk `tension` 0..1, prawy kciuk `pick_depth` 0..1 (oś X)
i `pick_lift` −1..1 (oś Y). Nowe rodziny używają **tylko tych trzech osi**, żeby ekran planu B (płyta + ruchome
części, `session.step(t, depth, lift)`) działał bez nowych kontrolek. `rotate`/`push` zostają dla starszych rodzin.

## Wnioski ogólne z gier i projektów (czego się trzymać)

- Frajda bierze się z **czytelnego odczytu reakcji zamka** (dźwięk ustawienia, „chrupnięcie”), a nie z zgadywania
  kąta; mechaniki „szukaj kąta, aż zadrży” gracze oceniają jako mniej satysfakcjonujące
  ([PC Gamer](https://www.pcgamer.com/which-lockpicking-or-hacking-minigame-are-you-good-at),
  [TV Tropes](https://tvtropes.org/pmwiki/pmwiki.php/Main/LockpickingMinigame)).
- Sejfy w grach zwykle opierają się na **dźwięku jako głównym kanale** + przed-sygnale bliskości
  (narastające drżenie/kliknięcie) i pauzie na liczbie; grozi monotonia, gdy minigra jest długa
  ([przykład projektu studenckiego](https://jktemple.itch.io/interactive-game-poster),
  [przegląd gatunku](https://retro-replay.com/db/dos/safe-opening-simulator)). U nas: krótkie zamki (1–2 min),
  przed-sygnał `near_shear`, wyraźne potwierdzenie `set`, a do tego rytm „obrotów” jako zrozumiała struktura.
- Głębokość minigry dopasować do częstotliwości jej występowania
  ([bugnet](https://bugnet.io/blog/how-to-design-a-hacking-or-lockpicking-minigame)) — nowe rodziny występują
  w 1–2 zleceniach, więc t1–t2 muszą być do opanowania w pierwszym podejściu, z samouczkiem pierwszej lekcji.
- Unikamy: zielonego „OK”/czerwonego X, pasków wytrzymałości, drgającego pokrętła jako jedynej wskazówki (DESIGN.md).

---

## 1. `dial_safe` — sejf z pokrętłem (pakiet kół)

**Historia i zasada (encyklopedycznie).** Zamek szyfrowy z pokrętłem ma **pakiet kół**: pokrętło obraca krzywkę
napędową, a jej zabierak po prawie pełnym obrocie łapie „skrzydełko” sąsiedniego koła, to koło następne itd.
Każde koło ma bramkę; gdy wszystkie bramki stoją pod **płotkiem** dźwigni, płotek opada we wcięcie krzywki i rygiel
można cofnąć. Liczba kół = liczba liczb kombinacji. Stąd znana procedura „kilka obrotów w jedną stronę, potem
w drugą o jeden mniej…”: zmiana kierunku zostawia ustawione koło w spokoju, bo luz między zabierakiem a skrzydełkiem
to prawie cały obrót. Rozwój: połowa XIX w. (zamki bankowe), potem zabezpieczenia przeciw odczytowi
([Wikipedia: Rotary combination lock](https://en.wikipedia.org/wiki/Rotary_combination_lock),
[Lockwiki: Wheel pack](https://lockwiki.com/index.php/Wheel_pack),
[HowStuffWorks](https://home.howstuffworks.com/combination-lock.htm),
[Locksmith Ledger: anatomia zamka trzykołowego](https://www.locksmithledger.com/safes/article/10228880/anatomy-of-a-safe-lock-three-wheel-combination-locks-old-and-new)).

**Wariant gry (wymyślony).** Zlecenia to legalne otwarcia (spadek z dokumentem, antykwariat z umową) — „pan od
sejfów” słucha pakietu kół. Uproszczenia:
- 2–4 koła, pokrętło 20–40 działek (nie 100), luz zabieraka = dokładnie pół obrotu w każdą stronę, więc koło
  niesione przez pokrętło zawsze pokazuje tę samą liczbę co pokrętło.
- **Nasłuch słyszy tylko koło, które ostatnie dołączyło do pakietu** (najdalsze z niesionych). Gracz najpierw kręci
  w prawo, aż zbierze wszystkie koła (każde dołączenie = `safe.pickup`, opór pokrętła rośnie), potem słucha
  bramki koła 0, zatrzymuje się na niej, zmienia kierunek, zbiera koła do koła 1 i słucha jego bramki itd.
- Przekręcenie o jeden obrót za daleko zabiera ustawione koło (`drop` z numerem koła): czytelna kara bez łamania.
- Na końcu pokrętło na znacznik otwarcia (0), docisk klamki → `safe.fence_drop` → przytrzymanie → `open`.
- `tension` = **docisk klamki/nasłuchu**: poniżej pasma płotek nie dotyka kół (cisza, tylko działki), w paśmie
  słychać bramki, powyżej pasma pakiet się zakleszcza (pokrętło staje, opór).
- Od t2 płytkie fałszywe wcięcia: `false_set` (głuchszy, krótszy), koło w nich nie otworzy zamka.

**Sygnały (3 kanały).**

| Stan | Kształt/ruch | Dźwięk | Haptyka |
|---|---|---|---|
| koło niesione (`bound`) | koło obraca się z pokrętłem, zabierak widoczny przy skrzydełku | `safe.pickup` (metaliczne „tyk-tok”, wyżej dla bliższych kół) | krótki twardy impuls |
| blisko bramki (`near`) | płotek schodzi o 2 dp | narastający szmer | narastające drżenie ciągłe (`tension_resistance` mięknie) |
| bramka / ustawione (`set`) | płotek w bramce, koło stoi | głuchy „klap” | jeden miękki, dłuższy impuls |
| fałszywe wcięcie (`false_set`) | płotek dotyka, nie wchodzi | krótszy, wyższy „tik” | ostry krótki impuls |
| zabrane ustawione koło (`drop`) | koło rusza, płotek podskakuje | zgrzyt | podwójny impuls |
| zakleszczenie (`jammed`) | koła stoją, pokrętło drga 2 dp | tarcie | ciągły opór |

**Trudność t1–t6** (zaimplementowane t1–t3; t4–t6 jako kierunek):

| Tier | Koła | Działki | Okno bramki | Pasmo nasłuchu | Fałszywe | gate_feel |
|---|---|---|---|---|---|---|
| t1 | 2 | 20 | ±1 działka | 0,20–0,60 | 0 | 0,9 |
| t2 | 3 | 30 | ±1 | 0,22–0,52 | 0–1 | 0,7 |
| t3 | 3–4 | 40 | ±0,6 | 0,24–0,46 | 1 | 0,55 |
| t4–t6 | 4–5 | 50–100 | ±0,5 | węższe | 1–2, szum | 0,45–0,3 |

**Ryzyka.** Monotonia przy wielu obrotach (szybki obrót przy dużym wychyleniu kciuka, mało kół);
niezrozumienie „zmiany kierunku” (samouczek pierwszej lekcji z ghost hand); długie zamki przy 100 działkach
(dlatego 20–40); ryzyko realizmu — brak odczytu punktów kontaktu i wykresów z realnej manipulacji.

---

## 2. `combo` — zamek szyfrowy z kółkami (rowerowy, skrzynka)

**Zasada.** Kółka z cyframi na tulejkach; każda tulejka ma wcięcie. Gdy wszystkie wcięcia stoją pod występem
rygla/zatrzasku, rygiel przechodzi. W tanich konstrukcjach pod ciągiem zatrzasku tulejki dociska się nierówno,
więc jedna stawia opór — to ogólnie znana słabość tej klasy (poziom encyklopedyczny)
([patent ogólny: zamek bagażowy](https://patents.google.com/patent/US4722208A/en),
[HowStuffWorks](https://home.howstuffworks.com/combination-lock.htm)).

**Wariant gry.** Różni się od `ring_combo` (kłódka z pierścieniami, `rotate`): kółka kręci się **pionowym
przeciągnięciem kciuka** (`pick_lift` = prędkość kółka), `pick_depth` wybiera kółko, `tension` = ciąg linki/zatrzasku.
Nowa reguła: **poślizg tulejki** — kółko pod ciągiem kręcone za szybko „przeskakuje” wcięcie (`combo.slip`,
podstawa `overset`): nie wpada w bramkę i trzeba okrążyć jeszcze raz wolniej. Uczy: „pod ciągiem — powoli”.
t1 (rower, Kuba przed rozmową o pracę): 3 kółka, mocne sygnały, bez fałszywych wcięć; t3 (kapsuła czasu):
4 kółka, fałszywe wcięcia, słabsze sygnały.

**Sygnały.** `combo.detent` (cyfra), `bind` (kółko twardnieje), `near_shear` (lekkie „zapadnięcie”),
`gate_align`+`set` (wyraźny klik, kółko staje), `false_set` (głuchy), `combo.slip` (ostry zgrzyt + kółko podskakuje
o 2 dp), `drop` (puszczenie ciągu: tylko flagi, cyfry zostają).

**Trudność t1–t6** (zaimplementowane t1–t4): kółka 3→5, `gate_feel` 0,85→0,35, fałszywe 0→2 od t3, pasmo
ciągu 0,32→0,18, próg poślizgu niższy na wyższych tierach.

**Ryzyka.** Za blisko `ring_combo` → inna oś, inny widok (rząd kółek z przodu), poślizg jako nowa lekcja.

---

## 3. `dimple` — wkładka z nawierceniami

**Zasada.** Wkładka bębenkowa, ale nacięcia klucza są wiercone w płaskiej stronie; kołki wchodzą z boku,
często kilka rzędów, czasem kołki teleskopowe (kołek w kołku)
([Lockwiki: Dimple](https://lockwiki.com/index.php/Dimple), [Lockwiki: Pin-in-pin](https://lockwiki.com/index.php/Pin-in-pin),
[Wikipedia: Pin tumbler](https://en.wikipedia.org/wiki/Pin_tumbler_lock)).

**Wariant gry.** Zlecenie z kamienicy w Brukseli (t2). Elementy w dwóch rzędach (`pick_depth` przechodzi przez oba,
różny `variant`), **kołek teleskopowy**: najpierw zewnętrzna tuleja (`set` 1), potem wewnętrzny kołek ma węższe
okno (`dimple.inner`, podstawa `set`) — dwa okna na jeden element. `pick_lift` = dociśnięcie (płaski nacisk).
Wspólny model napięcia (§1.5), boty domyślne.

**Trudność:** n 4→7, teleskopowe 0→3, okno 0,14→0,09, pasmo 0,30→0,16. **Ryzyka:** podobieństwo do `pin_tumbler`
— różnicuje teleskop i widok z boku płaskiego klucza.

---

## 4. `disc_detainer` — zamek tarczowy

**Zasada.** Zamiast sprężyn obrotowe tarcze z wycięciami; klucz obraca je jak koła sejfu, aż wycięcia ustawią się
pod listwą boczną, która wpada i pozwala obrócić rdzeń. Wynalazek z Finlandii (1907, patent 1918/19)
([Wikipedia: Disc tumbler lock](https://en.wikipedia.org/wiki/Disc_tumbler_lock)).

**Wariant gry.** Zlecenie fińskiego marynarza (t2). `tension` = moment na rdzeń (listwa dociska tarcze), `pick_depth`
= która tarcza, `pick_lift` = obrót tarczy (prędkość, w obie strony). Pod momentem jedna tarcza wiąże; obrót do bramki
→ listwa „siada” na niej (`set`), następna wiąże. Fałszywe wycięcia od t2. **Przekręcenie ustawionej tarczy**
= `overset` (listwa się podnosi, wszystkie ustawione spadają przy zwolnieniu). Tarcza zerująca z przodu (od t3):
obraca się tylko o zero, „reset”.

**Trudność:** tarcze 5→9, bramka 0,08→0,045 obrotu, fałszywe 0→2. **Ryzyka:** podobieństwo do pierścieni —
inny widok (stos tarcz w przekroju), obrót w obie strony, kara za przekręcenie.

---

## 5. `egyptian` — zasuwa kołkowa „starożytna” (domek dla lalek)

**Zasada.** Najstarszy znany typ: drewniany rygiel z otworami, z góry opadają w nie kołki; klucz z kołkami
podnosi je na właściwą wysokość i rygiel można wysunąć — ta sama idea co dzisiejsza wkładka bębenkowa
([Britannica: Lock](https://www.britannica.com/technology/lock-security),
[Univ. of Illinois: Introduction to Locks and Keys](https://web.extension.illinois.edu/artifact/shared/pdf/intro/Introduction%20to%20Keys%20and%20Locks.pdf)).

**Wariant gry.** Zlecenie „drewniany zamek domku dla lalek” (t1, miniaturka). Różnica wobec `wooden_pin`:
**kołki opadają grawitacyjnie** (bez sprężyny, wolniej), rygiel trzeba **wysunąć** ciągłym ciągiem
(`hold_progress`), a podniesiony za wysoko kołek **klinuje się** w nadprożu (`egypt.wedge`, podstawa `overset`)
i spada dopiero po popchnięciu rygla do środka (ciąg < `t_release`). Nic się nie łamie.

**Trudność:** t1 3 kołki, okno 0,18; t2 4–5 kołków, okno 0,14. **Ryzyka:** zbyt łatwe — zaletą jest ciepły ton zlecenia.

---

## 6. `axial_slider` — zamek suwakowy (osiowy)

**Zasada.** Klucz rurkowy z podłużnymi nacięciami różnej głębokości wciska suwaki promieniowo rozłożone wokół
osi; gdy każdy suwak zejdzie na właściwą głębokość, jego wcięcie mija płytkę zamykającą i rdzeń się obraca.
Konstrukcja z 1784 r., wyzwanie w witrynie (1790) otwarte dopiero w 1851; w 1817 dodano **fałszywe wcięcia**
([Linda Hall Library](https://www.lindahall.org/about/news/scientist-of-the-day/joseph-bramah/),
[Wikipedia: Bramah lock](https://en.wikipedia.org/wiki/Bramah_lock),
[Amusing Planet](https://www.amusingplanet.com/2025/08/the-invincible-bramah-lock.html)).

**Wariant gry.** Zlecenie biurka (t2). `tension` = moment rdzenia, `pick_depth` = suwak na obwodzie (widok z czoła,
promieniście), `pick_lift` **ujemny** = wciskanie suwaka w dół (`Plan::lift_sign = −1`). Fałszywe wcięcia
(`false_set` + przeciwobrót jak w szpulkach). Wspólny model napięcia, boty domyślne.

**Trudność:** suwaki 4→8, fałszywe 0→1 na suwak, okno 0,12→0,08. **Ryzyka:** widok kołowy musi spełnić ≥ 28 dp
na element (max 8 suwaków na pierścieniu 280 dp).

---

## 7. `time_lock` — zamek czasowy (naprawa, nie otwieranie)

**Zasada.** Mechanizmy zegarowe (zwykle 2–4, redundancja) blokują rygiel skarbca do ustawionej godziny, nawet przy
znanej kombinacji; wystarczy, że jeden mechanizm dojdzie do zera. Pierwszy udany montaż w banku: 1874
([Sargent & Greenleaf: historia](https://ftp.sargentandgreenleaf.com/MN-timeDelay.php),
[kolekcja zamków czasowych](https://www.my-time-machines.net/my_time_lock_collection.htm)).

**Wariant gry.** Muzeum (t2): zegar stanął, trzeba **przywrócić chód**. `tension` = nakręcanie sprężyny (pasmo;
za mocno → `stress`, potem pęknięcie sprężyny = `break`, koszt monet), `pick_depth` = które koło, `pick_lift` =
osadzanie koła na osi (okno głębokości). Gdy wszystkie koła osadzone i sprężyna w paśmie: `time.tick` w rytmie,
`hold_progress` = równy rytm przez 5 s → `open` (= zegar chodzi). Rytm nierówny (`time.beat_off`, podstawa
`near_shear`), gdy naciąg poza pasmem.

**Trudność:** koła 3→6, mechanizmy 1→3, pasmo naciągu 0,30→0,15. **Ryzyka:** musi „coś robić” (bez martwych
zębatek, DESIGN.md); 5 s czekania — rytm jako metronom i haptyka w rytmie.

---

## 8. `magnetic` — zamek z kołkami magnetycznymi

**Zasada.** Kołki z magnesami ukryte w rdzeniu; klucz ma magnesy o określonej polaryzacji, które odpychają lub
przyciągają kołki na właściwą pozycję. Nie da się ich podnieść mechanicznie
([Wikipedia: Magnetic keyed lock](https://en.wikipedia.org/wiki/Magnetic_keyed_lock),
[Lockwiki: Magnetic](https://lockwiki.com/index.php/Magnetic)).

**Wariant gry.** Nocna pielęgniarka (t1). „Sonda magnetyczna” zamiast haczyka: `pick_lift` = siła i biegun
(dodatnie przyciąga, ujemne odpycha), `pick_depth` = kołek, `tension` = moment rdzenia. Każdy kołek ma swój biegun:
zły biegun pcha go w przeciwną stronę (`magnet.flip`, podstawa `contact`). Kołek nie ma „pchnięcia”: porusza się
z opóźnieniem (bezwładność pola), więc trzeba prowadzić płynnie. Wspólny model napięcia z `lift_sign` per element.

**Trudność:** kołki 3→6, okno 0,16→0,10, opóźnienie 80→160 ms. **Ryzyka:** magnesy kojarzą się z „hackami” —
ton: to klient z kartą najmu, sonda to narzędzie warsztatowe; zero odwołań do realnych kluczy.

---

## Stan implementacji (lockcore v0.6, 2026-11-05/06)

Wszystkie osiem rodzin zbudowane; karty z ostatecznymi regułami i tabelami: `docs/LOCKS.md` §2.18–2.25.
`dial_safe` to nowy moduł; pozostałe to flagi istniejących modułów (jak `lever_detector`), żeby dzielić
sprawdzony model napięcia i boty weryfikatora:

| Rodzina | Moduł | Tiery | Różnice wobec szkicu powyżej |
|---|---|---|---|
| `dial_safe` | nowy (`dial_safe.cpp`) | 1–3 | pasmo nasłuchu 0,20–0,60 / 0,25–0,55 / 0,29–0,51 |
| `combo` | `ring_combo` + flaga | 1–4 | — |
| `dimple` | `pin_tumbler` + flaga | 1–3 | teleskop = reguła szpulki (fałszywe ustawienie + pasmo przeciwobrotu) |
| `disc_detainer` | `ring_combo` + flaga | 1–3 | 5–6 tarcz zamiast 5–9; tarcza zerująca odłożona |
| `egyptian` | `wooden_pin` + flaga | 1–2 | — |
| `axial_slider` | `lever` + flaga | 1–3 | — |
| `time_lock` | `wafer` + flaga | 1–2 | jeden mechanizm; bieg 2–3 s zamiast 5 s (tempo); koła zazębiają się po kolei |
| `magnetic` | `pin_tumbler` + flaga | 1–2 | bez biegunów (wymagałyby ujemnego `pick_lift`); zostaje opóźnienie pola |
