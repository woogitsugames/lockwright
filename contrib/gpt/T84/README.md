# T84 — Komunikaty pobierania głosów

W bieżącym `game/i18n/strings.csv` są już krótkie komunikaty `settings.voice_pack.offline`, `settings.voice_pack.failed` i przycisk `settings.voice_pack.retry`. W `game/scripts/ui/settings_screen.gd` przyczyny `offline` i `timeout` są obecnie pokazywane jako offline, a pozostałe jako błąd ogólny. Poniżej propozycje nowych, bardziej szczegółowych komunikatów, wyłącznie do oceny; nie są podłączone do gry.

| Proponowany klucz | PL | EN | DE | FR | ES |
|---|---|---|---|---|---|
| settings.voice_pack.interrupted | Pobieranie przerwane. Spróbuj ponownie. | Download interrupted. Try again. | Download unterbrochen. Versuch es erneut. | Téléchargement interrompu. Réessaie. | Descarga interrumpida. Inténtalo de nuevo. |
| settings.voice_pack.invalid | Nie udało się sprawdzić pliku. Spróbuj ponownie. | Couldn’t verify the file. Try again. | Datei konnte nicht geprüft werden. Versuch es erneut. | Impossible de vérifier le fichier. Réessaie. | No se pudo verificar el archivo. Inténtalo de nuevo. |
| settings.voice_pack.mount_error | Nie udało się uruchomić głosów. Spróbuj ponownie. | Couldn’t load the voices. Try again. | Stimmen konnten nicht geladen werden. Versuch es erneut. | Impossible de charger les voix. Réessaie. | No se pudieron cargar las voces. Inténtalo de nuevo. |

Istniejące komunikaty informują, że napisy pozostają dostępne; przy szczegółowych wariantach należy zachować tę informację w widoku. Przypisanie przyczyn i zachowanie przycisku ponawiania wymagają weryfikacji podczas integracji; `invalid` jest nazwą propozycji, nie deklaracją istniejącego kodu błędu. Żadne pliki gry nie zostały zmienione.
