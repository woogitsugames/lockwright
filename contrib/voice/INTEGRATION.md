# Lektor AI: propozycja odtwarzania w grze (faza 2, D-57)

Stan: pliki gotowe (`game/assets/audio/lines/<lang>/<job_id>.line.<N>.ogg`, PL i EN), kod gry jeszcze ich nie używa.

1. **Ścieżka pliku** z klucza napisu: `res://assets/audio/lines/%s/%s.ogg % [lang, key]`, gdzie `lang` = `TranslationServer.get_locale()` przycięte do `pl`/`en`. Brak pliku (np. DE) → sam napis, bez dźwięku, bez błędu (`ResourceLoader.exists`).
2. **Kolejność:** kwestia po kwestii. Napis pojawia się razem z dźwiękiem; następna kwestia startuje po `finished` + 250 ms przerwy. Wokalizacja S03/S03v2 zostaje tylko jako reakcja przy zdarzeniu (ulga, śmiech), nigdy równocześnie z kwestią tej samej postaci.
3. **Tap = przewiń:** pierwszy tap w trakcie kwestii kończy ją (krótki fade 80 ms) i pokazuje pełny napis; drugi tap przechodzi do następnej. Przytrzymanie / przycisk „Pomiń rozmowę” kończy całą scenę.
4. **Magistrala `Voice`:** nowy bus w `default_bus_layout.tres`, suwak „Głosy” w Ustawieniach (osobno od SFX i muzyki). Muzyka i ambient przy kwestii ściszane (ducking) najwyżej o 6 dB, z powrotem po 300 ms.
5. **Napisy zawsze widoczne** (dostępność, granie bez dźwięku); dźwięk jest dodatkiem. Haptyka nie towarzyszy kwestiom.
6. **Głośność:** pliki mają −18 LUFS integrated; bus `Voice` na 0 dB daje kwestie wyraźnie nad ambientem (−28 LUFS wokalizacji S03).
7. **Nowe języki:** `python3 tools/voice_lines.py manifest --lang de` + generowanie tym samym `voice_id` z `game/data/voice_cast.json`; kod nie wymaga zmian.
