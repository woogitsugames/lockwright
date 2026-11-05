# G14 — rekwizyty papierowe

## Wykonane

14 niezależnych tekstur PNG RGBA z przezroczystym otoczeniem, po 7 typów w językach polskim i angielskim. Dłuższy bok każdej grafiki wynosi 1500 px. Wzory są fabularne, celowo odróżnione od autentycznych dokumentów urzędowych: nie zawierają godła, MRZ, hologramu, logotypów ani prawdziwych numerów dokumentów. Przygotowano metodą proceduralną (Python, Pillow i NumPy), aby uzyskać ostre, kontrolowane napisy.

## Zawartość `png/`

| Pliki | Zastosowanie |
| --- | --- |
| `job_pl.png`, `job_en.png` | Karta zlecenia: adres, godzina, klient, uwagi i weryfikacja prawa do lokalu. |
| `receipt_pl.png`, `receipt_en.png` | Pokwitowanie usługi, pola kwot, daty i podpisu. |
| `lease_pl.png`, `lease_en.png` | Kartka umowy ze zszywką, czytelny wyłącznie nagłówek, nieczytelna treść. |
| `manager_pl.png`, `manager_en.png` | Pismo zarządcy ze stemplem fikcyjnej administracji Lipowej. |
| `tenant_pl.png`, `tenant_en.png` | Tekturowa karta spółdzielni, świadomie niebędąca dowodem osobistym. |
| `envelope_pl.png`, `envelope_en.png` | Koperta z fikcyjnym adresem pani Haliny w Zamecznie. |
| `note_pl.png`, `note_en.png` | Odręczna w stylu kartka „Rosół czeka.” / „Soup is waiting.” |

## Uwagi i propozycje

- To wzory 2D do nałożenia na modele/rekwizyty; oświetlenie, perspektywa, zszywka 3D i deformacja papieru mogą zostać dodane po stronie Godot/Blender.
- Wersje PL/EN stanowią oddzielne tekstury, gotowe do powiązania z i18n.
- Pismo zarządcy i karta spółdzielni nie są potwierdzeniem rzeczywistego prawa do lokalu: to rekwizyty narracyjne.
- Fonty do renderowania: Liberation Serif i Lato (środowisko lokalne). Przed redystrybucją sprawdzić warunki konkretnych binariów fontów; pliki fontów nie są dołączone.
