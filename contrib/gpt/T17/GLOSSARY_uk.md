# T17 — słowniczek ukraiński (uk-UA)

Szkic do przeglądu przez native speakera. Terminy ustalone na podstawie `game/i18n/strings.csv`, `game/i18n/content.csv`, `store/listing.md`, `docs/DESIGN.md`. Mechanizmy opisujemy jako fikcyjne i bez porad dotyczących realnych, nazwanych zamków.

## Forma zwracania się do gracza

**Rekomendacja: uprzejme «ви» (z małej litery) i odpowiednie formy czasowników w liczbie mnogiej** w interfejsie, samouczku, opisie sklepowym i instrukcjach. Gracz występuje jako fachowiec mający obowiązek sprawdzać uprawnienia klientów; ten rejestr brzmi po ukraińsku profesjonalnie, bez przesadnej formalności. W krótkich etykietach preferowane są bezokoliczniki lub rzeczowniki (np. «Перевірити право на вхід», «Відмовити»). Wypowiedzi **postaci** zachowują własny charakter, np. dziecko może mówić swobodnie, a notatki mistrza mogą mieć instrukcje w trybie poufałym; nie narzucamy jednolitej formy wszystkim bohaterom.

## Uzgodnione terminy (81)

| EN | PL (punkt odniesienia) | UK (zalecane) | Uwagi |
|---|---|---|---|
| locksmith | ślusarz | **слюсар** | Fachowiec działający legalnie; nie „złodziej” ani „włamywacz”. |
| locksmith on call | ślusarz z pogotowia | **слюсар на виклик** | Ustalona nazwa ukraińska w UI i sklepach. |
| lock / locking mechanism | zamek / mechanizm | **замок / замковий механізм** | Mechanizmy gry są fikcyjne. |
| invented lock | wymyślony zamek | **вигаданий замок** | Ważne w opisach sklepowych. |
| pick | wytrych | **відмичка** | Stała nazwa narzędzia. |
| hook pick | haczyki / wytrych haczykowy | **відмичка-гачок** | Gatunek narzędzia. |
| flag pick | chorągiewka | **відмичка-прапорець** | Gatunek narzędzia. |
| ripple pick | falownik | **хвильова відмичка** | Nazwa w wyposażeniu. |
| crown pick | koronka | **корончаста відмичка** | Nazwa w wyposażeniu. |
| tension wrench | napinacz | **натягувач** | Nie tłumaczyć jako klucz dynamometryczny. |
| angled tension wrench | napinacz kątowy | **кутовий натягувач** | Narzędzie. |
| bar tension wrench | napinacz listwowy | **пластинчастий натягувач** | Narzędzie. |
| tension | napięcie | **натяг** | Nie mylić z naprężeniem materiału. |
| resistance | opór | **опір** | Wyczuwalny opór elementu. |
| continuous resistance | opór ciągły | **безперервний опір** | Ustawienie haptyczne. |
| pick stress | naprężenie wytrycha | **перенапруження відмички** | Sygnał przed złamaniem. |
| pin | kołek / pin | **штифт** | Nie 'пін' w tekstach dla gracza. |
| pin stack | stos kołków | **набір штифтів** | Dotyczy rodziny kołkowej. |
| wooden pin | drewniany kołek | **дерев'яний штифт** | W drewnianym zamku. |
| pin tumbler | zamek bębenkowy | **штифтовий циліндр** | Forma dla wyświetlania lekcji. |
| wafer | płytka | **пластина** | W rodzinie zamków płytkowych. |
| wafer lock | zamek płytkowy | **пластинчастий замок** | Nie mylić z zamkiem dźwigniowym. |
| lever / lever lock | dźwignia / zamek dźwigniowy | **сувальда / сувальдний замок** | Nazewnictwo mechanizmu. |
| ward / warded lock | zastawka / zamek zastawkowy | **заставка / замок із заставками** | Stałe przeszkody wewnętrzne. |
| disc lock | zamek tarczowy | **дисковий замок** | Obracające się dyski. |
| ring lock | zamek pierścieniowy | **кільцевий замок** | Rodzina mechanizmu. |
| combination | kod / szyfr | **код / комбінація** | W dialogach zależnie od kontekstu. |
| dial | tarcza szyfrowa | **кодовий диск** | W sejfie. |
| shear line | linia podziału | **лінія розділу** | Termin wymagany w T17. |
| core / plug | rdzeń | **серцевина** | Część obrotowa mechanizmu. |
| keyway | kanał na klucz | **канал для ключа** | Nie instruktaż techniczny. |
| keyhole | otwór na klucz | **замкова щілина** | W historii zamków. |
| binding | wiązanie / zakleszczanie | **заклинювання** | Stan oporu elementu. |
| set (state) | prawdziwe ustawienie | **правильне встановлення** | Odróżnić od false set. |
| false set | fałszywe osadzenie / ustawienie | **хибне встановлення** | Termin wymagany w T17. |
| overset | przepchnięcie | **надмірне підняття** | Termin wymagany w T17. |
| near shear | blisko linii podziału | **біля лінії розділу** | Stan przejściowy. |
| counter-rotation | kontrrotacja | **зворотний поворот** | Nie 'обертання в інший бік' w UI. |
| drop | zrzut | **скидання** | Opadanie uprzednio ustawionych części. |
| reset | reset / skasowanie | **скидання** | Zresetowanie stanu detektora / ustawień. |
| gate | bramka | **паз** | Wycięcie współpracujące z elementem. |
| false gate | fałszywa bramka | **хибний паз** | Pułapka w grze. |
| gate alignment | zgranie bramki | **суміщення паза** | Stan prawidłowego zgrania. |
| detector | detektor | **детектор** | Fikcyjny w grze; nie opis realnego produktu. |
| detector trip | zadziałanie detektora | **спрацювання детектора** | Stan blokady. |
| shackle | kabłąk | **дужка** | Część kłódki. |
| padlock | kłódka | **навісний замок** | Rodzaj zamka. |
| bolt | rygiel / zasuwa | **засув** | Konsekwentnie dla elementu blokującego. |
| latch | zasuwka | **засувка** | Zamknięcie np. drzwi łazienki. |
| spring | sprężyna | **пружина** | W dźwiękach i mechanice. |
| burrs | zadziory | **задирки** | Ślady zużycia. |
| wear | zużycie | **зношення** | Stan narzędzia. |
| tool condition | stan narzędzia | **стан інструмента** | UI warsztatu. |
| spare picks | zapasowe wytrychy | **запасні відмички** | Nie 'życia' w UI. |
| tool roll | zwijka narzędziowa | **шкіряний згорток** | Fizyczny rekwizyt HUD. |
| watchmaker's loupe | lupa zegarmistrzowska | **лупа годинникаря** | Narzędzie obserwacji. |
| borescope | wziernik | **бороскоп** | Narzędzie obserwacji. |
| haptics | haptyka | **тактильний відгук** | W całym UI i sklepie. |
| haptic pulse | impuls haptyczny | **тактильний імпульс** | Krótki sygnał. |
| audio ambience | dźwięki tła | **звуки довкілля** | Ustawienia. |
| high contrast | wysoki kontrast | **висока контрастність** | Dostępność. |
| chalk markings | znaki kredą | **позначки крейдою** | Pomoc wzrokowa. |
| in the dark | tryb w ciemności | **у темряві** | Tryb gry. |
| continuous mode / endless shift | tryb ciągły | **Нескінченна зміна** | Spójność UI / osiągnięć. |
| shift | dyżur / zmiana | **зміна** | U ślusarza. |
| job / contract | zlecenie | **замовлення** | Nie kontrakt prawny. |
| right of entry | prawo do lokalu / wejścia | **право на вхід** | Podstawa odpowiedzialnej decyzji. |
| verify | weryfikować | **перевірити** | Zawsze przed otwarciem, gdy potrzebne. |
| evidence | dowód / potwierdzenie | **доказ / підтвердження** | Nie zawsze dowód osobisty. |
| witness | świadek | **свідок** | Osoba potwierdzająca uprawnienia. |
| building manager | zarządca / administrator | **управитель будинку** | Stałe w dialogach. |
| lease | umowa najmu | **договір оренди** | Dowód uprawnienia. |
| deed | akt własności | **документ про право власності** | Potoczna, neutralna etykieta, nie wzór urzędowy. |
| residents' resolution | uchwała mieszkańców | **рішення мешканців** | Kontekst wspólnotowy. |
| consent | zgoda | **згода** | W tym zgoda najemcy i spadkobierców. |
| decline a job | odmówić zlecenia | **відмовитися від замовлення** | Ciepły, stanowczy ton. |
| clean opening | czyste otwarcie | **акуратне відкриття** | Bez uszkodzeń. |
| workshop | warsztat | **майстерня** | UI. |
| showcase | gablota | **вітрина** | UI, notki historyczne. |
| master's notebook | zeszyt mistrza | **зошит майстра** | Narracja. |
| time lock | zamek czasowy | **часовий замок** | Encyklopedycznie, bez realnej instrukcji. |

## Uwagi do przeglądu native speakera

- **Weryfikacja fachowa:** sprawdzić, czy «лінія розділу», «надмірне підняття», «паз» i «натягувач» są najlepszymi określeniami dla *fikcyjnych* schematów w grze; ewentualne zmiany stosować globalnie we wszystkich plikach, bez zmiany kluczy.
- **Pisownia nazw:** polskie imiona i nazwiska spolszczone w dialogach transliterowano na ukraiński (m.in. Збишек, Зузанна, Маґда). Nazwy miejsc i historycznych postaci warto zweryfikować względem ukraińskich uzusów encyklopedycznych; pozostawiono oryginał słów obcojęzycznych w celowym code-switchingu postaci (`Depuis toujours`, `C'est à votre famille`, `pierogi`).
- **Długość UI:** pełna lista kluczy z przyrostem długości UK względem EN powyżej 30% jest w `README.md`; skróty wymagają sprawdzenia na urządzeniach, nie tylko według procentu.
- **Nazwy historyczne:** nazwiska dawnych wynalazców w notkach historycznych nie są reklamą producentów współczesnych zamków. Nie dodajemy do tekstu instrukcji praktycznego obchodzenia zabezpieczeń.
