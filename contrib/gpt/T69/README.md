# T69 — audyt tonu odmów

Zakres: polskie kwestie `job.refuse_*` w `game/i18n/content.csv` zestawione z `docs/CLIENTS.md` §4. Kontrola wyłącznie tekstowa; nie sprawdzono kodu, alternatywnych gałęzi ani efektów rozgrywki. Zalecenia są propozycjami, nie zmianami istniejących kluczy. Wzorzec przewiduje spokojną odmowę, inną drogę i scenę następnego dnia; nie wolno przyjmować, że sam tekst dowodzi działania mechaniki.

| Scena | Dowód i ocena | Propozycja |
|---|---|---|
| `refuse_ex_partner` | `line.4`: „Tu nie otworzę. Spokojnie, policja może pomóc odebrać rzeczy. Zadzwonić?” Stanowczo i pomocnie; „Spokojnie” może brzmieć protekcjonalnie. | „Tu nie otworzę. Może pan zwrócić się o pomoc do policji. Zadzwonić?” |
| `refuse_rush_bribe` | `line.2`: „Procedur nie da się dopłacić” brzmi nienaturalnie. `line.4`: „To dobranoc. A dla porządku dam znać dzielnicowej.” Nie zawiera jednoznacznej odmowy i zapowiedź zawiadomienia może zabrzmieć jak groźba. | `line.2`: „Dopłata nie zastąpi zgody. Proszę zadzwonić do siostry, poczekam.” `line.4`: „Bez potwierdzenia nie otworzę. Mogę pomóc panu skontaktować się z dzielnicową.” Zmiana sposobu kontaktu z policją wymaga decyzji narracyjnej: oryginał zapowiada własne zgłoszenie. |
| `refuse_aunt_alive` | `line.4`: „To zadzwońmy do pani Lucyny razem. A potem do aspirant Sowy.” Proponuje weryfikację, lecz nie stwierdza wprost odmowy; drugi telefon może sprawiać wrażenie automatycznej sankcji. | „Nie otworzę bez potwierdzenia. Zadzwońmy razem do pani Lucyny, a potem do aspirant Sowy.” Zachowuje oba telefony i dodaje wyraźną granicę. |
| `refuse_sisters_flat` | `line.2` proponuje kontakt, `line.4`: „Bez jej zgody nie otworzę. Tu jest numer do zarządcy.” Jasne i życzliwe. | Pozostawić. Jeśli fabuła przewiduje inny udokumentowany tytuł do wejścia, zgrać tekst z zasadami gry. |
| `refuse_unapproved_stockroom` | `line.2` odróżnia list przewozowy od zgody; `line.4` odmawia i proponuje bezpieczny odbiór. Ton rzeczowy bez oskarżeń. | Pozostawić. |

W scenach pokrewnych `wrong_floor`, `uncle_safe_heirs` i `krakow_antiquarian` §4.4 wskazuje inny rodzaj rozstrzygnięcia; pełnego audytu tych gałęzi tu nie wykonano. Nie zweryfikowano scen dnia następnego ani zasady braku zapłaty. Propozycje policji i zarządcy są rozwiązaniami fabularnymi, nie gwarancją ich uprawnień prawnych.
