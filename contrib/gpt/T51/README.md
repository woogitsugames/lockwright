# T51 — spójność postaci i nazw

Źródła: `game/i18n/content.csv`, `docs/CLIENTS.md`, `contrib/voice/CAST.md`, 41 plików `game/data/jobs*/*.json` z drzewa `main` pobranego do audytu. Automatycznie porównano liczby mówców `lines` i kluczy `.line.N`: we wszystkich 41 zleceniach liczby się zgadzają. To nie potwierdza, że w każdej pozycji przypisano właściwą osobę. Audyt treści i języków jest częściowy; nie ustalono pełnej zgodności wszystkich adresów ani scen. Żadnych plików gry nie zmieniano.

| Priorytet | Dowód | Problem i proponowane działanie |
|---|---|---|
| Wysoki | `contrib/voice/CAST.md`, wiersz `headteacher`: opis „Dyrektorka szkoły”, adnotacja o portrecie epizodycznym przedstawiającym mężczyznę. | Jawnie udokumentowana sprzeczność płci tekstu i portretu. Sprawdzić powiązany asset i poprawić portret albo rozstrzygnąć zmianę postaci z redakcją; nie zakładać, że portret nadal jest używany bez kontroli w grze. |
| Średni | `job.night_nurse.line.2` w `content.csv`: PL „Pani Agnieszka spod czternastki”; EN „Mrs Agnieszka, flat fourteen”. `docs/CLIENTS.md` powtarza tę parę. | Polski zwrot może oznaczać numer budynku, angielski jednoznacznie numer mieszkania. Ustalić, co jest numerem 14, i doprecyzować oba języki. |
| Średni | `job.brussels_townhouse.client`: PL „Od 15 lat jest tłumaczką w Brukseli”, EN „has lived in Brussels for 15 years”, DE „seit 15 Jahren in Brüssel”. | Czas wykonywania zawodu w Brukseli nie musi być tożsamy z czasem zamieszkania. Ustalić biografię Magdy i uzgodnić opisy. `line.2` „od zawsze” brzmi jak przesada Jacques’a i sama w sobie nie dowodzi błędu. |
| Średni | `job.grandma_broth.note` w `docs/CLIENTS.md`: PL „Śródmieście”, EN „Old Town”; bieżący `content.csv`: PL „Śródmieście”, EN „city centre”. | Historyczny przykład w dokumentacji wskazuje inną dzielnicę niż tekst gry. Ustalić, czy Śródmieście i Stare Miasto są odrębnymi dzielnicami, następnie poprawić dokumentację albo grę. |
| Średni | `content.csv`, 12 kluczy `job.*.client` dla nowszych zleceń (np. `job.community_notice_case.client`, `job.halina_recipe_box.client`) ma identyczny tekst EN i DE; podobnie po 12 kluczy `.title` i `.situation`. | DE pokazuje angielskie imiona i formy grzecznościowe w całych opisach. To brak lokalizacji, nie dowód na zmianę tożsamości; przetłumaczyć i sprawdzić odmianę, w tym `Mrs`/`Frau`. |
| Niski | `job.swiatniki_journeyman_padlock.client`: Władysław ma 84 lata i ukończył szkołę w latach 50. | Przy umownej dacie akcji 2026 miałby w 1959 r. około 17 lat — możliwe, ale chronologia wymaga końca dekady lub innego roku akcji. Nie jest to dowiedziona sprzeczność. |

Porównane przykłady zachowują te same osoby i wiek: Halina 81, Stefan 67, Marta 34, Zuzanna 20, Kuba 23, Gosia 36, Zbyszek 74, Iga 27, Nadia 29, Agnieszka 45; różnica form Krysia/Krystyna sama nie dowodzi, że chodzi o tę samą osobę. Sprawdzono tożsamość Kasi w `job.newlyweds_4am.client` i `CAST.md` (`bride`): zgodna. Wynik nie jest pełnym indeksem wszystkich wystąpień imion ani dowodem braku dalszych błędów.

Aktualizacja: dalsze ustalenia i kontrola identyfikatorów są w `UZUPELNIENIE.md`. `docs/ASSETS.md` odnotowuje zastąpienie portretu dyrektorki wariantem v3 6 listopada; wpis w CAST może być nieaktualny i wymaga porównania z rzeczywistym zasobem.

Kontrola rozszerzona o kwestie „dzień po” i dodatkowe ustalenia: `UZUPELNIENIE2.md`. W szczególności ujawniono brak `lena` w rejestrze obsady głosowej oraz brak plików `after` w śledzonym katalogu audio; zawartości zewnętrznych paczek głosowych nie sprawdzono.

`INDEX.csv` zawiera zestawienie 41 zleceń: dzielnicę, klucz opisu klienta, mówców `lines`/`after` i brakujące wpisy głosowe. Liczby z opisów wykrywa mechanicznie, więc wymagają interpretacji i nie zastępują kontroli redakcyjnej wieku.
