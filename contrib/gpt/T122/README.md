# T122 — teksty na zrzutach: ucięcia i nachodzenie

Przejrzano wszystkie 257 obrazów PNG/JPG w docs/handoff/device-tests/fixes/**, w tym 19 przez drugiego recenzenta. Pełna lista jest w T121/README.md. Nie uruchamiano gry; przewijanie i aktualne wersje ekranów pozostają do sprawdzenia. Część dużych zrzutów i zestawień była automatycznie pomniejszona, co ogranicza ocenę drobnego tekstu.

## Konkretne obserwacje

1. **ui/control_choice_915x412.jpg** — opis w lewej karcie „Napięcie automatyczne — dla początkujących” jest ucięty u dołu wiersza „bezpiecznym…”. Widać wskaźnik przewijania przy prawej krawędzi obszaru. Nie wiadomo ze zrzutu, czy cały tekst można przewinąć; sprawdzić na urządzeniu, czy gracz może przeczytać i porównać obie opcje przed wyborem. Rozważyć krótszą treść lub układ zajmujący mniej wysokości.
2. **landscape/tutorial_s1_authored_915x412.png** — odręczny napis „tension” przy dolnej lewej krawędzi jest przecięty przez granicę obrazu. Sprawdzić pozycję podpisu i bezpieczny obszar dla poziomu.
3. **ui/job_arrival_915x412.jpg** — druga karta dialogu jest przecięta przy dolnej krawędzi przewijanego obszaru; widoczny jest tylko podpis „Ślusarz”, nie tekst. Wskaźnik przewijania sugeruje dalszą treść, ale statyczny obraz nie potwierdza, czy użytkownik może ją odczytać i czy przycisk nie zasłania końca. Zweryfikować przewijanie i ostatnią linię.
4. **ui/jobs_list_360x800.jpg** — ostatni widoczny wiersz jest przecięty u dołu zrzutu. Pasek po prawej sugeruje listę przewijaną; samo ucięcie granicą widoku nie dowodzi utraty treści. Sprawdzić możliwość dotarcia do końca listy.
5. **lessons/arrival_family_caption_combo_412x915.jpg** — tytuł „Rozmowa o 9:30” łamie się na dwa wiersze pomiędzy przyciskami. Pozostaje widoczny, ale zwiększa wysokość nagłówka; warto sprawdzić dłuższe tłumaczenia.

6. **landscape/tutorial_intro_915x412.png** — przycisk „Back” widoczny w pionowym landscape/tutorial_intro_412x915.png nie mieści się na zrzucie poziomym; po prawej widać pasek przewijania. Sprawdzić, czy użytkownik może łatwo przewinąć i wrócić bez uruchamiania ćwiczenia.
7. **furnishings/before_workshop_412x915.png** oraz **furnishings/before_workshop_915x412.png** — zielony licznik FPS nakłada się na górną część przycisku Back. To może być wyłącznie nakładka diagnostyczna; przed wydaniem należy sprawdzić, że jest wyłączona.
8. Drugi recenzent nie stwierdził ucięć ani nakładania widocznych napisów w 19 obejrzanych wariantach menu_v2_gpu; czerwone prostokąty oznaczają strefy diagnostyczne. U dołu wariantu 1916×2160 jest fragment jasnego elementu, którego nie można z tego podglądu pewnie określić jako tekst.

Na pozostałych obejrzanych obrazach nie stwierdzono jednoznacznego ucięcia tekstu w widocznym fragmencie; nie stanowi to testu wszystkich treści, stanów ani języków. Szczegóły kontrastu opisano osobno w T121.
