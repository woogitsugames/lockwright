# Lockwright — G21: skórzany język pauzy i portrety

Wykonano **7 wymaganych obrazów** oraz **1 opcjonalny wariant alternatywny**. Każdy obraz jest oddzielnym zdjęciem w formacie PNG, 1024×1024 piksele.

## Pliki

- `images/leather_tab_snap_topdown.png` — brązowy skórzany język z mosiężnym zatrzaskiem, widok z góry
- `images/portrait_janka.png` — Janka, około 73 lat, bordowy beret i torba z kocami
- `images/portrait_mila.png` — Mila, około 23 lat, kręcone włosy i papierowa gwiazda
- `images/portrait_oskar.png` — Oskar, około 32 lat, wełniany płaszcz i torba prezentów
- `images/portrait_pawel.png` — Paweł, około 46 lat, granatowa kurtka robocza i teczka
- `images/portrait_karol.png` — Karol, około 41 lat, szara czapka i torba na ramię
- `images/portrait_leon.png` — Leon, około 55 lat, kurier w rękawiczkach
- `images/leather_tab_snap_topdown_alt.png` — opcjonalna alternatywna wersja skórzanego języka

## Weryfikacja

- 8 plików PNG; wszystkie 1024×1024, RGB.
- Portrety przedstawiają wymyślone postacie; nie korzystano z fotografii rozpoznawalnych osób ani z materiałów zewnętrznych.
- Jeden kadr na jeden plik, bez kolaży, tytułów, znaków wodnych i logo.
- Wszystkie pliki zostały wygenerowane przez natywny generator obrazów ChatGPT, a następnie zmniejszone przez Pillow przy użyciu algorytmu LANCZOS. Jest to jedyna obróbka końcowa.
- Próby, w których generator zwracał powtórzony obraz skórzanego języka zamiast portretu, zostały odrzucone i nie trafiły do paczki.

## Ograniczenia

Nie ma brakujących obowiązkowych obrazów i nie było blokad. Nie można zagwarantować pikselowej zgodności z opisem ani niepowtarzalności twarzy względem wszystkich obrazów istniejących w świecie. Generator udostępnia identyfikatory generacji, ale nie pełne wewnętrzne prompty; `ASSETS.md` dokumentuje kompletne prompty wejściowe ze zlecenia.

## Integracja

Docelowy katalog w repozytorium: `contrib/gpt/G21/images/`. Archiwum nie zmienia repozytorium i nie zawiera commita.
