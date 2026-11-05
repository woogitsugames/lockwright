# store/legal/ — szkice dokumentów prawnych (sesja C, etap 3, zadanie 7)

> **Szkic do konsultacji z prawnikiem.** Żaden z tych tekstów nie jest poradą prawną. Przed publikacją: uzupełnić pola
> `[…]`, rozstrzygnąć miejsca oznaczone **[D-06]** (model biznesowy) i dać całość do przeczytania osobie znającej prawo
> konsumenckie UE/PL i RODO.

| Plik | Co to jest | Gdzie trafi |
|---|---|---|
| `terms_pl.md`, `terms_en.md` | Warunki korzystania / umowa licencyjna (EULA) dla gry premium | strona (`site/`), link w opisie sklepu; w App Store zob. niżej |
| `privacy_pl.md`, `privacy_en.md` | Polityka prywatności — **kopia** tekstów z `store/privacy.md` §1–§2 (źródło prawdy) | strona `site/…/privacy.html` generuje się z `store/privacy.md` |
| `notice_pl.md`, `notice_en.md` | Nota „to gra, nie kurs” w wersji formalnej (ekran „O grze”, strona, sklep) | `game/i18n` (sesja B, klucz `about.notice`), strona |

**App Store:** Apple domyślnie stosuje swoją Standard EULA (Licensed Application End User License Agreement). Rekomendacja:
zostawić Standard EULA i dodać nasze warunki jako dokument uzupełniający (link w opisie), bo własna EULA w App Store
Connect musi zawierać minimalne postanowienia Apple (Apple jako strona trzecia uprawniona, brak obowiązku wsparcia po
stronie Apple itd.). **Google Play:** brak wbudowanej EULA — obowiązują nasze warunki (link w karcie sklepu i w grze).

**Miejsca zależne od D-06:**
- wariant **P** — gra płatna z góry: brak zakupów w aplikacji;
- wariant **A** — darmowe pobranie z jednorazowym odblokowaniem pełnej wersji (IAP);
- w obu: bez reklam, energii, losowania i kupowania monet (to już przesądzone).

Synchronizacja: `privacy_*.md` muszą być identyczne z `store/privacy.md` §1–§2 — sprawdza to
`python3 store/legal/check_sync.py` (kod wyjścia 1 przy rozjeździe).
