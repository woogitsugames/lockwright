# Zlecenie T43: około 30 nowych zleceń (rozdziały 9–12)

**Dla:** ChatGPT (tekst). Repo `woogitsugames/lockwright`, zapis tylko do `contrib/gpt/T43/`. Cel (D-66): kariera ok. 2 h zamiast 40–60 min.

## Przeczytaj najpierw
- `CLAUDE.md` (ton: ciepło i legalnie, ślusarz weryfikuje prawo do lokalu, zero marek, zero instrukcji do prawdziwych produktów; pin bębenkowy po polsku to **„pin”**, „kołek” tylko w zamku drewnianym/egipskim).
- `docs/CLIENTS.md` (zasady pisania §1, obsada stała §3, odmowy §4, łuk miasta §5, głos zeszytu §6, przykłady dialogów §8), `docs/JOBS.md`, `docs/PROGRESSION.md`.
- Wzór danych: `game/data/jobs/*.json` (pola `id, chapter, district, family, tier, verification, reward_coins, tone, i18n, lines, after, cards, threshold, place, time`) i klucze w `game/i18n/content.csv` (`<id>.title/client/situation/line.N/note/after.N`).
- Rodziny i tiery: `docs/LOCKS.md` (§2.18–2.25 nowe rodziny), `lockcore/BALANCE.md`. Dostępne rodziny: pin_tumbler, warded, wafer, lever, lever_detector, dial_safe, combo, dimple, disc_detainer, egyptian, axial_slider, time_lock (naprawa zegara, nie otwieranie), magnetic.

## Co napisać
- **4 rozdziały po 7–8 zleceń (razem 28–32):** każdy rozdział ma motyw (np. zima w kamienicy, remont dzielnicy, targ i warsztaty, finał z obsadą stałą) i rosnącą trudność (tiery 2–6). Rozłóż rodziny tak, żeby każda nowa rodzina z D-59 miała co najmniej 2 zlecenia, a w każdym rozdziale były 1–2 **odmowy** (wzór §4) i 1 zlecenie **bez otwierania** (np. pomyłka, naprawa, rozmowa).
- **Dla każdego zlecenia:** dane JSON (jak wzór; `reward_coins` 40–200 rosnąco, `place`/`time` z istniejących wartości), PL i EN (DE opcjonalnie) dla `title`, `client`, `situation` (2–3 zdania), **4–6 kwestii dialogu** (mówca przy każdej; ślusarz po prawej), `note` do zeszytu, 1–2 kwestie „dzień po”. Kwestie **do czytania przez lektora**: naturalna mowa, liczby słownie, bez skrótów.
- **Nowe postacie:** lista z imieniem, wiekiem, charakterem i jednym zdaniem opisu wyglądu (do portretu i głosu); powtarzaj też obsadę stałą (§3) i postacie z rozdziałów 1–8 tam, gdzie pasuje (ciągłość miasta).
- **Weryfikacja:** dla każdego zlecenia jakie karty/dowody (`cards`) i próg (`threshold`) — jak w istniejących zleceniach.

## Oddanie (`contrib/gpt/T43/`)
- `jobs/*.json` — jedno zlecenie na plik;
- `content_t43.csv` (`keys,en,pl,de`), `cast_t43.csv` (`id,name_pl,name_en,age,character,look`);
- `README.md` po polsku: łuk rozdziałów, tabela zleceń (id, rodzina, tier, nagroda, odmowa tak/nie), lista nowych postaci;
- uruchom `python3 tools/i18n_lint.py` na kopii z dopisanymi kluczami, jeśli masz dostęp, i opisz wynik.
