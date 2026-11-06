# T82 — osiem propozycji osiągnięć

`achievements.csv` zawiera osiem propozycji dla rozdziałów 7–12: sześć za konkretne ukończone sprawy i dwie za odmowę bez zgody. Kolumna `save_array` i `job_id` określa precyzyjny warunek: podany identyfikator musi występować w `Save.jobs_completed` albo `Save.jobs_refused`; odblokowanie tylko raz. Warunki wybrano ze zleceń faktycznie obecnych w `game/data/jobs/`. Dla spraw `outcome=talk` warunkiem jest ukończenie sprawy, nie otwarcie zamka; naprawa zegara nie jest otwarciem zamka.

**Wszystkie osiem wymaga nowej obsługi**: `game/scripts/autoload/achievements.gd` nasłuchuje zdarzeń zamka i obsługuje tylko część `event=`/`result=open`; nie interpretuje warunków dla zleceń ani list zapisu. Nie wystarczy dopisanie definicji do JSON: należy sprawdzać stan po zapisie wyniku i przy migracji wcześniejszego zapisu, bez ponownego przyznawania. Refusale rejestruje `job_verify.gd`; sprawdzić też ścieżki `talk` i `repair` oraz moment zapisu `jobs_completed`. Punkty i widoczność do decyzji integratora. Brak integracji usług platformowych.

Propozycje tekstów PL/EN/DE/FR/ES nie były testowane w interfejsie ani przez korektora językowego. Źródła: `game/data/jobs/`, `game/data/achievements.json`, `game/scripts/autoload/achievements.gd`, `game/scripts/ui/job_verify.gd`, `docs/DECISIONS.md` D-70; stan `b50ea45`. Bez zmian gry.
