# T77 — wpisy zeszytu, rozdziały 7–12

`notes.csv` zawiera po jednym wpisie dla każdego z 54 zleceń z `game/data/jobs/*.json` w rozdziałach 7–12, we wszystkich pięciu językach: łącznie 270 niepustych tekstów. Każdy ma ≤ 130 punktów kodowych Unicode. Klucze `job.*.note` już istnieją w `game/i18n/content.csv`; zestaw w większości zachowuje je bez zmian, z jedną proponowaną korektą w pięciu językach. To kompletne pokrycie kluczy, a nie 270 nowo napisanych wpisów.

Przy magazynku w Nocnym Rynku wyraźnie zapisano odmowę i usunięto odbiór paczek rano, który nie jest częścią zakończonej interwencji. Pozostałe istniejące wpisy wymagają pełnego przeglądu redakcyjnego pod kątem zasad §6 CLIENTS (weryfikacja, perspektywa czasu przeszłego i dyskrecja), zgodności z dialogiem oraz korekty DE/FR/ES; automatyczny test liczby znaków tego nie rozstrzyga. Nie zmieniono danych gry.

Źródła: `docs/CLIENTS.md` §6, `game/data/jobs/*.json`, `game/i18n/content.csv`; stan bazowy `b50ea45`.

## Proponowana zmiana istniejącego tekstu

| klucz | było | jest | powód |
|---|---|---|---|
| job.refuse_unapproved_stockroom.note [pl] | Nocny Rynek, magazyn sklepu. List przewozowy bez zgody; paczki odebrane rano. | Nocny Rynek, magazynek sklepu. List przewozowy bez zgody właściciela. Nie otworzyłem. | Odmowa zapisana wprost; pominięto przyszły odbiór paczek. |
| job.refuse_unapproved_stockroom.note [en] | Night Market stockroom. Delivery note, no owner's consent. Parcels handed over in the morning. | Night Market stockroom. A delivery note, but no owner's consent. I did not open it. | Odmowa zapisana wprost; pominięto przyszły odbiór paczek. |
| job.refuse_unapproved_stockroom.note [de] | Nachtmarkt, Lager eines Ladens. Lieferschein, aber keine Zustimmung; Pakete am Morgen übergeben. | Nachtmarkt, Ladenlager. Lieferschein, aber keine Zustimmung des Besitzers. Ich öffnete nicht. | Odmowa zapisana wprost; pominięto przyszły odbiór paczek. |
| job.refuse_unapproved_stockroom.note [fr] | Réserve du Marché de Nuit. Bon de livraison, pas d'accord du propriétaire. Colis remis le matin. | Réserve du Marché de Nuit. Bon de livraison, mais pas d'accord du propriétaire. Je n'ai pas ouvert. | Odmowa zapisana wprost; pominięto przyszły odbiór paczek. |
| job.refuse_unapproved_stockroom.note [es] | Almacén del Mercado Nocturno. Albarán sin consentimiento del dueño. Paquetes entregados por la mañana. | Almacén del Mercado Nocturno. Albarán, pero sin permiso del dueño. No abrí. | Odmowa zapisana wprost; pominięto przyszły odbiór paczek. |
