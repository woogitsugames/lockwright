# T119 — karty i próg weryfikacji

Zakres: wszystkie 83 zlecenia na stanie `b50ea45`. W `verification.csv` podano karty, próg i deklarowany opis weryfikacji każdego zlecenia. Wszystkie mają niepustą listę kart i próg; brakujących kluczy `verify.card.*`: 0. To kontrola struktury i wybranych przykładów, nie dowód, że każdy zestaw merytorycznie wystarcza.

## Ustalenia

1. **Próg nie steruje akceptacją.** `game/scripts/ui/job_verify.gd` wyświetla karty, ale `_accept()` nie czyta `threshold`, wag ani flag. Zadania `job.refuse*` mają ukryty przycisk akceptacji według samego prefiksu ID. Nie należy traktować liczby w JSON jako działającej ochrony.
2. **Widoczność kart.** Kod ustawia `_shown = min(2, cards.size())` i go później nie zwiększa. Zleceń z ponad dwiema kartami: 9. W ich przypadku dalsze karty nie są renderowane przez ten ekran.
3. **Opis a próg.** `job.cat_bathroom` opisuje próg 0, a pole `threshold` wynosi 3. `job.refuse_t43_10_early_clearance` ma kartę `deed` i próg 3, ale własność nie dowodzi zgody lokatora — i właśnie dlatego jest to odmowa. Sama suma hipotetycznych punktów byłaby więc niewystarczająca. `job.refuse_sisters_flat` ma jedynie `id`: to potwierdzenie tożsamości, nie zgody.
4. **Obrazki zastępcze.** `CARD_PROP` w `job_verify.gd` nie definiuje wszystkich rodzajów i korzysta dla nich z obrazka `note`. Wystąpienia według rodzaju: {'address_app': 1, 'deed': 6, 'inheritance': 2, 'institution': 22, 'invoice': 11, 'letter': 6, 'photo': 9, 'resolution': 5}; etykieta wciąż korzysta z właściwego klucza i18n.

Rekomendacja: sprawdzić każdą sprawę z narracją i regułami `docs/JOBS.md` §2, rozstrzygnąć czy próg ma pozostać dokumentacyjny czy być zaimplementowany, oraz zapewnić dostęp do wszystkich kart. Sama punktacja nie zastępuje sprawdzania kontekstu i sprzeczności. Bez zmian w grze; bez testu uruchomieniowego.
