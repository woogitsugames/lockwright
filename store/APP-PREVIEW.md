# App Preview i film Google Play — scenariusz i lista ujęć

Status: szkic do akceptacji właściciela · 2026-11-05 (sesja C, etap 3, zadanie 6). Podstawa: `docs/MARKETING.md` §0–§2
(ton, napisy SDH, zakazy), `store/screenshots/PLAN.md` (kolejność kadrów). Wersja „filmowa” z renderami Blendera to
zwiastun z MARKETING §1; **ten dokument dotyczy wersji sklepowej**, nagranej z aplikacji.

## 1. Wymogi techniczne (sprawdzić w dniu wysyłki — Apple i Google zmieniają je bez zapowiedzi)

| | App Store (App Preview) | Google Play (film promocyjny) |
|---|---|---|
| Źródło obrazu | **wyłącznie nagranie z aplikacji** (dozwolone: przycięcie, napisy, przejścia, dźwięk) | link do YouTube (publiczny lub niepubliczny, bez reklam, bez ograniczenia wiekowego) |
| Długość | 15–30 s | dowolna; zalecamy tę samą wersję 30 s |
| Rozmiar (pion) | iPhone 6,9"/6,5": 886 × 1920; iPad 13" (jeśli D-10 zostawi iPada): 1200 × 1600 | 1080 × 1920 (wgrywamy na YouTube jako Shorts/pion) |
| Klatki, kodek | ≤ 30 kl./s, H.264 lub ProRes 422 HQ, .mov/.m4v/.mp4, ≤ 500 MB | jak YouTube |
| Dźwięk | stereo AAC 256 kb/s, 44,1/48 kHz | jak YouTube |
| Liczba | do 3 na język i rozmiar | 1 |
| Kadr plakatowy | wybierany w App Store Connect (domyślnie 5. sekunda) — ustawić na S3 („klik”) | miniatura YouTube: ten sam kadr |
| Zakazy | ramki/dłonie trzymające telefon, treści spoza aplikacji, cena | reklamy w filmie, linki zachęcające do kliknięcia |

Napisy SDH **wypalone w obrazie** (App Preview zwykle gra wyciszony). Strefa bezpieczna: boki 7,5%, góra 8% (pasek
stanu nagrania jest zamaskowany przez obraz gry bez paska), dół 12% (przyciski sklepu nachodzą na podgląd).

## 2. Scenariusz 30 s (PL i EN — dwa osobne pliki)

Oś jak w zwiastunie: wezwanie → dwa kciuki → pin siada → szpulka kłamie → ciemność → otwarte → plansza.
Każde ujęcie to nagranie ekranu gry (patrz §4, jak nagrywać); kadry S1–S2 i S9 zwiastuna filmowego wypadają.

| # | Czas | Ekran gry (nagranie) | Dźwięk z gry | Napis PL | Napis EN |
|---|---|---|---|---|---|
| P1 | 0:00–0:03 | Lista zleceń → karta zlecenia „Pokój 412” (przyjazd: kto dzwoni, adres bez szczegółów). Jedno dotknięcie. | kartka, telefon zleceń (audio v2) | Ktoś stoi pod drzwiami bez kluczy. | Someone's locked out. |
| P2 | 0:03–0:06 | Weryfikacja: klient kładzie dwie karty, ślusarz akceptuje. | papier, krótka pauza | Najpierw: czy to na pewno jego mieszkanie. | First: is it really their flat? |
| P3 | 0:06–0:10 | Ekran zamka (plan B), oba kciuki widoczne jako wgniecenia; napinacz wychyla się, rdzeń drga. | pętla oporu, skrobanie | Lewy kciuk napina, prawy szuka. `[opór pod kciukiem]` | Left thumb tensions, right thumb searches. `[resistance under the thumb]` |
| P4 | 0:10–0:13 | Pin trzeci siada: szczelina nad pinem dolnym (stan set), ruch 150 ms. **Kadr plakatowy.** | suchy klik | Klik. Ten siedzi. `[suchy klik w kciuku]` | Click. That one's set. `[a dry click under the thumb]` |
| P5 | 0:13–0:16 | Szpulka: false set, rdzeń obraca się głębiej; pauza bez ruchu 0,5 s; popuszczenie (counter-rotate). | pusty stuk, cisza, zgrzyt | A ten udaje. Popuść. `[za łatwo]` | This one's pretending. Ease off. `[too easy]` |
| P6 | 0:16–0:21 | Pauza → „W ciemności” → ekran gaśnie; 3 s prawie czerni, dwa kliki. | klik, klik | Zgaś ekran. Graj dotykiem i słuchem. | Screen off. Play by touch and ear. |
| P7 | 0:21–0:25 | Światło wraca, rdzeń obraca się do końca → ekran zapłaty: otwarte drzwi, motyw „dzięki”, monety do skrzynki. | otwarcie drzwi, motyw „dzięki”, kasa monet | Otwarte. Bez jednej rysy. | Open. Not a scratch. |
| P8 | 0:25–0:28 | Warsztat: zwijka z nowym wytrychem, dotknięcie „Napraw”. | skóra zwijki | Narzędzia zarabiasz pracą. | You earn your tools by working. |
| P9 | 0:28–0:30 | Ekran tytułowy gry (logo w grze, nie dodana plansza). | cicha fraza | To gra, nie kurs. Zamki są wymyślone. | A game, not a course. The locks are invented. |

**Wersja 15 s:** P3 (0–3 s) → P4 (3–6) → P5 (6–9) → P6 (9–12, skrócone do 1,5 s czerni) → P9 (12–15).

Zakazy z MARKETING §0 obowiązują: bez lektora, odliczania, „epickiego”, ceny, „za darmo”, bez trzęsienia kamery
„od haptyki”. P8 nie obiecuje funkcji spoza 1.0 — jeśli warsztat nie wejdzie do 1.0, P8 wypada, a P7 trwa do 0:28.

## 3. Lista ujęć do nagrania (shot list)

| Ujęcie | Scena | Stan startowy | Co zrobić | Długość surowa |
|---|---|---|---|---|
| U1 | `jobs_list.tscn` → `job_arrival.tscn` | zapis z 3 ukończonymi zleceniami (lista z ✓) | przewinąć, dotknąć „Pokój 412” | 6 s |
| U2 | `job_verify.tscn` | zlecenie `job.student_dorm` | poczekać na karty, „Przyjmij” | 5 s |
| U3 | `lock_photoreal.tscn`, pin_tumbler, seed zlecenia | wszystkie kołki wolne | napięcie + szukanie pinu 3 do binding | 8 s |
| U4 | jak U3 | pin 3 w binding | podnieść do set (jeden klik) | 4 s, 3 duble |
| U5 | pin_tumbler z szpulką (tier ≥ 3) | dwa kołki set | false set, pauza, popuszczenie | 6 s |
| U6 | jak U3, przełącznik „w ciemności” w pauzie | trzy kołki set | ustawić dwa ostatnie w ciemności | 8 s |
| U7 | koniec U6 → `job_payment.tscn` | — | otwarcie, ekran zapłaty | 6 s |
| U8 | `workshop.tscn` | 120 monet, jedno narzędzie zużyte | „Napraw” | 5 s |
| U9 | `main_menu.tscn` | — | statycznie | 3 s |

Do U3–U7 potrzebny jest przebieg powtarzalny: nagrywamy **powtórkę** (`lockcore/build/replay_tool record … --feel`
odtworzoną w grze) zamiast ręcznego grania, żeby duble były identyczne, a stany trafiały w zaplanowane sekundy.
Blokery na dziś (2026-11-05): ekran planu B nie przechodzi do zapłaty i nie bierze seeda zlecenia (N-13, N-14 w
`docs/handoff/SESSION-C-REVIEW.md`); menu mają jeszcze domyślny wygląd silnika na zrzutach desktopowych (U1, U2, U8, U9).

## 4. Jak nagrywać

- **iPhone (App Preview):** QuickTime na Macu → „Nowe nagranie filmu” → źródło: iPhone na kablu. Nagrywa z
  dźwiękiem, w rozdzielczości urządzenia; potem skalowanie do 886 × 1920 (iPhone 6,9" nagrywa 1320 × 2868 — proporcje
  są te same z dokładnością do paska, przyciąć 4 px). Alternatywa bez Maca: Godot `--write-movie` z kopii gry na
  komputerze w 886 × 1920 (to wciąż nagranie z aplikacji), dźwięk z `--write-movie` (.avi z PCM).
- **Android / YouTube:** wbudowane nagrywanie ekranu (z dźwiękiem multimediów) albo ten sam `--write-movie` w 1080 × 1920.
- Wyłączyć powiadomienia, tryb samolotowy, bateria 100% (pasek stanu i tak przycinamy), jasność ekranu stała.
- Montaż: napisy Bona Nova Bold (główny) i Atkinson Hyperlegible Next (SDH), kreda `#F1EEE6` na `#14110E` 85%; czas
  napisu ≥ 1,5 s; przejścia tylko cięcia albo przenikanie ≤ 200 ms.
- Kontrola przed wysyłką: wyciszony telefon (czy napisy wystarczą), skala szarości P3–P5 (stany rozróżnialne), długość
  15–30 s co do klatki, brak ceny i obietnic spoza 1.0.

## 5. Dane do uzupełnienia przez właściciela
- [Czy iPad zostaje (D-10) → czy potrzebny App Preview 1200 × 1600]
- [Kanał YouTube do filmu Google Play: nazwa, konto]
- [Akceptacja napisów PL/EN z §2]
