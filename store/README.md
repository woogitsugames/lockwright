# store/ — materiały do App Store i Google Play

Status: szkice do akceptacji właściciela (etap researchu, nic nie jest wysłane do sklepów).

| Plik | Co zawiera |
|---|---|
| `listing.md` | Nazwa, podtytuł, tekst promocyjny, słowa kluczowe, krótki i pełny opis, „Co nowego” 1.0 — PL i EN, osobno App Store i Google Play. Tabela znaków i lista zgodności (Apple 2.3.x, Play Metadata). |
| `tools/check_lengths.py` | Sprawdza limity znaków (i bajtów dla słów kluczowych), powtórzenia słów kluczowych, zakazane słowa; przepisuje tabelę w `listing.md`. |
| `rating.md` | Odpowiedzi do kwestionariusza wiekowego Apple (4+/9+/13+/16+/18+) i IARC (PEGI 3 / ESRB E / USK 0), ryzyko tematu „lockpicking”, notatka dla recenzenta. |
| `privacy.md` | Polityka prywatności PL i EN do hostowania, App Privacy (Data Not Collected), Data safety, grupa docelowa / Families, manifest `PrivacyInfo.xcprivacy`. |
| `screenshots/PLAN.md` | 8 kadrów z podpisami PL/EN, rozmiary, lista renderów do zamówienia. |
| `screenshots/make_screens.py` | Generator zrzutów (Pillow) z `art/renders/`, fonty z `mockups/fonts/`. |
| `screenshots/out/<lang>/<rozmiar>/NN.png` | Wygenerowane makiety (iPhone 6,9" i Android). |

## Polecenia

```bash
python3 store/tools/check_lengths.py                      # liczy znaki i aktualizuje tabelę w listing.md
python3 store/screenshots/make_screens.py --lang all --quantize            # makiety do repo (~25 MB, 256 kolorów)
python3 store/screenshots/make_screens.py --lang all --sizes all          # pełne RGB + iPad 13" (do wysyłki, ok. 2,5 min, poza repo)
python3 store/screenshots/make_screens.py --lang pl --sizes iphone69      # jeden język, jeden rozmiar
```

Wymaga Pythona 3 z Pillow (≥ 10). Pliki w `out/` w repo są w trybie 256 kolorów (`--quantize`), żeby
nie przekroczyć ok. 25 MB. Do faktycznej wysyłki do sklepów generować bez `--quantize` (pełne RGB,
bez kanału alfa).
