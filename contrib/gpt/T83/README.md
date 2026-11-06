# T83 — Puste stany

Propozycja tekstów do integracji; języki w kolejności PL, EN, DE, FR, ES. Klucze `jobs.empty.*` i `jobs.complete.*` są propozycjami, nie potwierdzonymi punktami podłączenia. Nie obiecują nadejścia nowych zleceń ani określonej czynności gracza.

| Klucz | PL | EN | DE | FR | ES |
|---|---|---|---|---|---|
| jobs.empty.title | Brak zleceń | No jobs | Keine Aufträge | Aucune mission | Sin encargos |
| jobs.empty.body | Na razie nie ma tu żadnych zleceń. | There are no jobs here right now. | Hier gibt es gerade keine Aufträge. | Il n’y a aucune mission ici pour le moment. | Ahora no hay encargos aquí. |
| jobs.complete.title | Wszystkie zlecenia ukończone | All jobs completed | Alle Aufträge abgeschlossen | Toutes les missions terminées | Todos los encargos completados |
| jobs.complete.body | Wszystkie dostępne zlecenia masz już za sobą. | You’ve completed all available jobs. | Du hast alle verfügbaren Aufträge abgeschlossen. | Tu as terminé toutes les missions disponibles. | Has completado todos los encargos disponibles. |

## Brak sieci przy pobieraniu głosów

W `game/i18n/strings.csv` istnieje już `settings.voice_pack.offline`: „Brak sieci. Napisy zostają.” / “No connection. Subtitles stay on.” / „Kein Netz. Untertitel bleiben an.” / „Hors ligne. Les sous-titres restent affichés.” / „Sin conexión. Los subtítulos siguen activos.” Zalecane ponowne użycie tego klucza po sprawdzeniu podłączenia do widoku; nie proponujemy drugiego komunikatu o tym samym stanie.

Wątpliwości: rozróżnienie pustej listy od wszystkich ukończonych wymaga danych stanu kariery; sam tekst nie ustala warunków wyświetlania. Propozycje nie zmieniają plików gry.
