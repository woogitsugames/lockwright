# Lockwright — FAQ dla testerów (test zamknięty) / Tester FAQ (closed test)

Stan: 2026-11-12. Dokument dla 5–8 osób w teście zamkniętym Google Play. Nie jest to tekst marketingowy.
Źródła faktów: `docs/ACCESSIBILITY.md`, `docs/HUD.md`, `docs/handoff/PLAY-DATA-SAFETY.md`, `store/privacy.md`,
`game/i18n/strings.csv`. Gdy gra się zmieni, poprawić tutaj (nazwy przycisków jak w `strings.csv`).

---

## PL

**Co to za gra?**
Jesteś ślusarzem z pogotowia zamkowego. Pomagasz ludziom, którzy nie mogą wejść do domu, piwnicy czy szafki.
Zanim otworzysz, sprawdzasz, czy klient ma prawo do lokalu albo rzeczy: dokumenty, świadkowie, rozmowa. Czasem
trzeba uprzejmie odmówić. Mechanizmy zamków są wymyślone. To gra, a nie kurs otwierania zamków.

**Jak się steruje zamkiem?**
Na pierwszym starcie wybierasz tryb:
- **Napięcie automatyczne** (domyślne, „dla zaczynających”): napięcie trzyma się samo na bezpiecznym poziomie,
  a Ty prowadzisz wytrych jednym kciukiem. Gdy element wejdzie za wysoko, stuknij krótko lewą stronę ekranu,
  czyli puść napięcie.
- **Dwa kciuki**: lewy kciuk trzyma napięcie (ruch liczony od miejsca dotknięcia), prawy prowadzi wytrych.
  Puszczenie lewego kciuka zrzuca napięcie.

Tryb zmienisz w **Ustawienia → Sterowanie**. Tam też: **Zamień kciuki (dla leworęcznych)** i **Blokada
napięcia** (tylko dwa kciuki: po puszczeniu stuknij dwa razy lewą połowę, żeby napięcie zostało; jedno stuknięcie
je puszcza).

**Co znaczą znaki kredą?**
Kreda na zamku pokazuje stan każdej części: wiąże, siedzi na miejscu, za wysoko, fałszywie siada. Te same stany
słychać i czuć w wibracji. Jeśli długo nic się nie dzieje, gra podpowiada coraz wyraźniej (najpierw dźwięk, potem
kreda i tekst). Kredę wyłączysz w **Ustawienia → Język i dostępność → Warstwa kredy**.

**Po co wibracje? Mój telefon słabo wibruje.**
Wibracja to jeden z trzech kanałów: obraz, dźwięk i haptyka mówią to samo. Gra jest w pełni grywalna bez wibracji.
W **Ustawienia → Wyczucie (haptyka)** jest **Kalibracja** („Czujesz dwa kliknięcia?”) i **Intensywność haptyki**.
Jeśli czujesz jedno kliknięcie zamiast dwóch albo nic, napisz nam, jaki to telefon.

**Dlaczego postacie mówią po angielsku?**
W grze są nagrania po angielsku. Głosy w języku gry (domyślnie w języku telefonu) gra pobiera w tle przy pierwszym
uruchomieniu i pokazuje rozmiar pobrania. Inne języki pobierzesz w **Ustawieniach** (sekcja **Głosy postaci**),
tam też je usuniesz i wyłączysz automatyczne pobieranie. Bez pobranych głosów napisy działają we wszystkich
językach. Uwaga: najnowsze zlecenia mogą jeszcze nie mieć nagrań — wtedy są tylko napisy.

**Obraz jest miękki albo telefon się grzeje.**
**Ustawienia → Grafika i pomoc → Jakość grafiki**: Auto (mierzona) / Wysoka / Średnia / Niska (tanie telefony).
Auto dobiera profil po pierwszych sekundach gry. Napisz nam, jaki profil wybrał Twój telefon.

**Dostępność**
- **Czytnik ekranu (TalkBack):** przyciski, przełączniki i suwaki mają nazwy. Na zamku gra ogłasza stany
  (**Ogłaszaj stany zamka**). Zamek z TalkBack: stuknij dwa razy i przytrzymaj, potem przesuwaj; przy TalkBack
  wybierz napięcie automatyczne.
- **Ogranicz ruch:** mniej przejść i ruchomych podpowiedzi, wszystkie informacje zostają.
- **Rozmiar tekstu:** domyślnie jak w systemie; można ustawić własny.
- **Wysoki kontrast, Napisy dźwięków, Szersze okna** — w sekcji **Język i dostępność**.

**Co gra wysyła do internetu? Reklamy?**
Bez reklam, bez konta, bez analityki i śledzenia. Jedyne użycie sieci to pobranie plików gry (głosy, a później
paczki z nowymi rozdziałami) zwykłym żądaniem HTTPS, bez identyfikatora i bez danych o grze. Serwer z plikami,
jak każdy serwer, widzi adres IP. Szczegóły: polityka prywatności.

**Jak zgłosić błąd?**
**Ustawienia → Zgłoś problem** kopiuje log do schowka (nic nie wysyła się samo). Wklej go do wiadomości razem z:
model telefonu, co robiłeś, co się stało, czego się spodziewałeś; zrzut ekranu bardzo pomaga.

**Czy postęp przetrwa aktualizację?**
Tak, zapis jest w pamięci aplikacji. Odinstalowanie albo „Wyczyść dane” go usuwa (kopia zapasowa Androida jest
wyłączona).

---

## EN

**What is this game?**
You are an emergency locksmith. You help people locked out of their home, cellar or locker. Before opening anything
you check that the client has the right to the place or the item: documents, witnesses, conversation. Sometimes you
politely refuse. The lock mechanisms are invented. This is a game, not a lockpicking course.

**How do I control the lock?**
At first launch you pick a mode:
- **Automatic tension** (default, "for beginners"): tension holds at a safe level by itself and you guide the pick
  with one thumb. If a part goes too high, tap the left side briefly to release tension.
- **Two thumbs**: the left thumb holds tension (measured from where you touch), the right one guides the pick.
  Lifting the left thumb drops the tension.

Change it in **Settings → Controls**, where you also find **Swap thumbs (left-handed)** and **Tension lock** (two
thumbs only: after letting go, double-tap the left half to keep the tension; a single tap lets it go).

**What do the chalk marks mean?**
Chalk on the lock shows each part's state: binding, set, too high, false set. You also hear and feel the same
states. If nothing happens for a while, hints escalate (sound first, then chalk and text). Turn chalk off in
**Settings → Language and accessibility → Chalk markings**.

**Why vibration? My phone vibrates weakly.**
Vibration is one of three channels: picture, sound and haptics say the same thing. The game is fully playable
without it. **Settings → Feel (haptics)** has **Calibration** ("Do you feel two clicks?") and **Haptic strength**.
If you feel one click or none, tell us your phone model.

**Why do characters speak English?**
English recordings ship with the game. Voices in the game language (by default your phone's language) download in
the background on first launch, showing the size. Other languages: **Settings → Character voices**, where you can
also remove them or turn off auto-download. Subtitles work in every language without downloads. The newest jobs may
not have recordings yet — those are subtitles only.

**The picture is soft or the phone gets hot.**
**Settings → Graphics and help → Graphics quality**: Auto (measured) / High / Medium / Low (cheap phones). Auto
picks a profile after the first seconds of play. Tell us which profile your phone got.

**Accessibility**
- **Screen reader (TalkBack):** buttons, switches and sliders are named; on the lock the game announces states
  (**Announce lock states**). With TalkBack on the lock: double-tap and hold, then slide; use automatic tension.
- **Reduce motion:** fewer fades and moving hints, all information stays.
- **Text size:** follows the system by default; you can set your own.
- **High contrast, Sound captions, Wider windows** — under **Language and accessibility**.

**What does the game send online? Ads?**
No ads, no account, no analytics or tracking. The only network use is downloading game files (voices, later packs
with new chapters) with a plain HTTPS request, without identifiers or gameplay data. Like any server, the file host
sees your IP address. Details: privacy policy.

**How do I report a bug?**
**Settings → Report a problem** copies the log to the clipboard (nothing is sent automatically). Paste it into your
message with: phone model, what you did, what happened, what you expected; a screenshot helps a lot.

**Does progress survive updates?**
Yes, the save is in app storage. Uninstalling or "Clear data" removes it (Android backup is off).
