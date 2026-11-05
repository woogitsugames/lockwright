# Przegląd dostawy ChatGPT, runda 4 (sesja A, 2026-11-05)

- **G17 puste tabliczki: PRZYJĘTE.** 14 PNG z alfą i marginesami 9-slice w `manifest.json`. Idą do agenta UI (menu, przyciski, inicjały). Uwaga: warianty `pressed` różnią się bardzo słabo. Gra doda przesunięcie 2 dp i mniejszy cień w kodzie.
- **G18 kadry samouczka: ODRZUCONE w obecnej formie.**
  - postarzały papier w sepii z plamami to pastisz, który jest na liście zakazanej (CLAUDE.md);
  - linie są cienkie i blade, więc przy 96–200 dp na telefonie są nieczytelne;
  - kciuki wyglądają jak kłódki.

  Gra używa na razie kadrów agenta zamka. Do ewentualnej poprawki (G18-v2): jasny kremowy papier bez plam, kreska ≥ 6 px przy 1080, kciuki jako proste owale z paznokciem, pin podnoszony wyraźnie wyżej niż pozostałe.
- **T39 teksty samouczka: PRZYJĘTE Z POPRAWKĄ.** W grze piny wkładki bębenkowej to po polsku **„pin”**. „Kołek” jest zarezerwowany dla drewnianych zamków (`wooden_pin`). Agent zamka podmienia „kołek” → „pin” i dopasowuje gramatykę. Limity długości są spełnione (max 51 znaków).
