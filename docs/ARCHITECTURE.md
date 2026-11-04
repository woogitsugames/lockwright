# Architektura — szkic (bez kodu produkcyjnego)

Status: szkic etapu researchu. Nazwy typów są robocze. Silnik jest jeszcze niewybrany (patrz `TECH.md`), dlatego szkic opisuje granice modułów, a nie API konkretnego silnika.

## 1. Zasady nadrzędne

1. **Logika zamka jest deterministyczna i nie zależy od renderu.** Stały krok symulacji (`SIM_HZ = 120`), liczby stałoprzecinkowe albo ściśle kontrolowane `float` bez zależności od FPS, własny PRNG z seedem. Zasada: ten sam `seed`, ta sama wersja reguł i ta sama sekwencja wejść dają identyczny strumień zdarzeń i wynik na iOS, Androidzie i Linuksie (CI).
2. **Rdzeń nie zna rodzin zamków.** Każda rodzina to moduł za wspólnym interfejsem. Nowa rodzina oznacza nowy katalog z modułem i danymi, a rdzeń zostaje bez zmian.
3. **Logika emituje zdarzenia, a nie efekty.** Warstwa prezentacji (obraz, dźwięk, haptyka) tłumaczy zdarzenia na sygnały przez dane (tabele mapowań), a nie przez `if` w logice.
4. **Dane są wersjonowane.** Format zamka, profilu trudności i zapisu gry ma numer wersji schematu i migracje, z myślą o dodatkach, edytorze i współdzielonym „zamku dnia”.
5. **Wszystko, co widzi gracz, przechodzi przez i18n** (klucze, PL + EN od pierwszego dnia, ICU MessageFormat dla liczb i odmian).

## 2. Warstwy

```
┌──────────────────────────────────────────────────────────────┐
│ App / Meta: tryby (Ciągły, Zlecenia), warsztat, gablota,      │
│ ekonomia, zapisy, ustawienia, i18n, IAP                       │
├──────────────────────────────────────────────────────────────┤
│ Session: LockSession (seed, profil, narzędzia, budżety)       │
│   ├─ InputSampler  (dotyk → InputFrame co krok)               │
│   ├─ LockSim       (rdzeń: pętla kroku, wspólne mechaniki)    │
│   │    └─ FamilyModule (pin_tumbler, wafer, lever, …)         │
│   └─ EventBus      (LockEvent[] na krok, z czasem symulacji)  │
├──────────────────────────────────────────────────────────────┤
│ Presentation: SignalMapper (dane) → 3 kanały                   │
│   ├─ VisualChannel  (przekrój 2,5D, HUD diegetyczny)          │
│   ├─ AudioChannel   (próbki + synteza, niska latencja)        │
│   └─ HapticChannel  (HapticsBridge → natywne iOS/Android)     │
└──────────────────────────────────────────────────────────────┘
```

Zależności idą wyłącznie w dół. `LockSim` i `FamilyModule` nie importują niczego z silnika graficznego ani audio. Dzięki temu da się je testować w CI na Linuksie bez GPU.

## 3. Wspólny interfejs rodziny (`FamilyModule`)

Pseudotyp opisuje kontrakt, nie implementację:

```
FamilyModule
  id: FamilyId                       # "pin_tumbler", "wafer", "lever", …
  rules_version: int                 # zmienia się przy każdej zmianie reguł
  required_tools(spec) -> ToolSet    # czego potrzeba, żeby w ogóle zacząć

  generate(seed, difficulty: DifficultyVector) -> LockSpec   # czyste, deterministyczne
  validate(spec) -> [SpecError]                              # schemat i spójność
  init_state(spec) -> FamilyState

  step(state, input: InputFrame, ctx: StepCtx) -> [LockEvent]   # 1 krok = 1/SIM_HZ s
  is_open(state) -> bool
  failure(state) -> FailureKind?     # break, detector_trip, …

  solver(spec, tools) -> SolveReport # weryfikator otwieralności (bot)
  describe(state) -> ViewModel       # tylko do odczytu, dla warstwy obrazu
```

- `InputFrame` jest wspólny: `tension ∈ [0,1]`, `pick_depth`, `pick_lift`, opcjonalne osie rodziny (`rotate`, `press`), aktywne narzędzie. Rodzina ignoruje osie, których nie używa.
- `StepCtx` daje PRNG sesji (strumień rozdzielony per rodzina), stałe globalne i model zużycia narzędzia. Rodzina nie ma dostępu do zegara ściennego.
- Wspólne mechaniki (model napięcia, łamanie i zużycie narzędzia, zrzut przy zbyt małym napięciu) żyją w rdzeniu jako komponenty, z których rodzina korzysta. Dzięki temu „wyczucie” jest spójne między rodzinami.
- Hybrydy (faza 3) to moduł-kompozyt, który składa dwa moduły i warunek otwarcia (AND/sekwencja). Rdzeń się nie zmienia.

## 4. Zdarzenia

```
LockEvent { t_step: int, kind: EventKind, element: int?, intensity: q16, material: MaterialId, data: map }
```

Wspólny słownik `EventKind` (szczegóły w `LOCKS.md`): `contact`, `bind`, `near_shear`, `set`, `false_set`, `counter_rotate`, `overset`, `drop`, `stress`, `break`, `wear`, `gate_align`, `detector_trip`, `open`. Ciągłe sygnały `tension_resistance` i `pick_drag` są próbkowane co krok jako wartości, a nie zdarzenia.

Rodziny mogą dodawać zdarzenia z prefiksem (`lever.gate_skip`). Gdy w tabeli mapowań brakuje wpisu, `SignalMapper` używa najbliższego zdarzenia bazowego.

## 5. SignalMapper (zdarzenie → 3 kanały)

- Dane, nie kod: `signals/<pack>.json` mapuje `(EventKind, material, intensity band)` na trzy wpisy: `visual` (animacja i kształt), `audio` (próbka lub patch syntezy, wariacje, głośność), `haptic` (identyfikator wzorca z biblioteki `TECH.md`).
- Reguły kanałów: priorytety, limit transientów na sekundę, ducking oporu przy kliknięciu, skalowanie suwakiem intensywności, wyłącznik haptyki.
- **Każde zdarzenie ma wpis we wszystkich trzech kanałach** (XAG 103/110). Test w CI sprawdza kompletność tabeli.
- Tryb „w ciemności” wyłącza `VisualChannel` dla przekroju i zostawia minimalny HUD dostępności. Kanały audio i haptyki dostają profil „dark” z mocniejszymi różnicami.
- Opóźnienia: zdarzenia trafiają do kanałów w tym samym kroku. Haptyka i audio nie czekają na klatkę renderu (osobny wątek lub natychmiastowe wywołanie mostka).

## 6. Dane: wersjonowany format zamka

```jsonc
// locks/<family>/<id>.lock.json
{
  "schema": "lockwright.lock/1",
  "family": "pin_tumbler",
  "rules_version": 3,
  "id": "mvp.pin.tutorial.01",
  "source": "authored | generated | daily | dlc:<pack>",
  "seed": 918273,                 // dla generated/daily
  "difficulty": { "elements": 3, "tolerance": 0.7, "security": [], "spring": 0.4 },
  "spec": { /* parametry rodziny, opis w LOCKS.md */ },
  "presentation": { "material_set": "brass_steel", "skin": "default" },
  "i18n": { "title": "lock.mvp.pin.tutorial.01.title" }
}
```

- `schema` z wersją główną. Migracje są jednokierunkowe (`1 → 2`), testowane na korpusie przykładowych plików.
- `rules_version` pozwala odtworzyć stary zamek dnia albo powtórkę na starych regułach. Moduł trzyma reguły zgodności albo odrzuca powtórkę jawnie.
- Paczki dodatków (`dlc:<pack>`) dostarczają moduł rodziny, dane, sygnały, zasoby i klucze i18n. Manifest zawiera wymagany `core_api` (semver).
- Zapis gry (`save/1`) przechowuje zdobyte narzędzia, ich zużycie, gablotę, reputację i postęp trybów, a nie stan symulacji w trakcie zamka.

## 7. Determinizm i testy

- **Powtórki:** `Replay = {schema, family, rules_version, seed, difficulty, inputs: [InputFrame co krok, kompresja RLE]}`. Test złoty: powtórka daje identyczny hash strumienia zdarzeń na każdej platformie (spike 5 w `TECH.md`).
- **Generator:** `generate()` korzysta tylko z PRNG sesji (np. PCG32 lub xoshiro128**, zaimplementowany ręcznie, nie z biblioteki silnika).
- **Weryfikator otwieralności:** dla każdej rodziny bot `solver()` musi otworzyć zamek posiadanymi narzędziami w budżecie kroków i bez złamania. Test CI: 10 000 seedów na każdy tier i każdą rodzinę, zero porażek. Statystyki trudności (mediana kroków, liczba zrzutów) idą do raportu balansu.
- **Testy jednostkowe zdarzeń:** scenariusze wejść („za duże napięcie przez 0,5 s” → `stress`, potem `break`).
- **Kompletność:** każde `EventKind` ma mapowanie w 3 kanałach, a każdy klucz i18n istnieje w PL i EN.

## 8. Wejście

- `InputSampler` zamienia dotyk na `InputFrame` w każdym kroku. Lewa strefa (napięcie) to oś pionowa albo nacisk (jeśli jest dostępny), z krzywą czułości z ustawień. Prawa strefa (wytrych) to 2D: głębokość i uniesienie.
- Wygładzanie i martwa strefa działają w samplerze, a nie w logice. Parametry są w powtórce, żeby powtórki były wierne.
- Dostępność: alternatywne schematy (jedna ręka: przełączanie trybu kciuka), regulowana strefa, kontroler sprzętowy (później).

## 9. Meta i rozbudowa latami

- Rejestr rodzin, narzędzi, zleceń i notek gabloty jest ładowany z danych, a każda pozycja ma `introduced_in` (wersja/paczka).
- Profile trudności to dane (`DifficultyVector` na tier), więc balans nie wymaga zmian w kodzie.
- Tryb Zleceń to graf danych: rozdział → dzielnica → zlecenie → scena (klucze i18n) → zamek (`authored` lub `generated` z ograniczeniami).
- Edytor (faza 3) zapisuje ten sam format `lock/1`. `validate()` i `solver()` są bramką publikacji.

## 10. Otwarte kwestie (do rozstrzygnięcia po wyborze silnika)

- Język logiki: rekomendacja z `TECH.md` to biblioteka C++20 `lockcore` niezależna od silnika (stały przecinek, testy natywne w CI). Silnik dostaje ją przez GDExtension (Godot) albo natywny plugin (Unity).
- Kompresja i podpis powtórek dla „zamka dnia” (bez serwera w MVP, seed liczony z daty UTC).
