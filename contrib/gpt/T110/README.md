# T110 — inwentarz teł przyjazdu

Zestawiono wartości place i time ze wszystkich 83 zleceń z mapą ARRIVAL_BG oraz logiką fallback w game/scripts/ui/job_arrival.gd. Lista 16 kombinacji i liczby zleceń znajduje się w places.csv. Istnienie plików sprawdzono w drzewie Git na bazie danych main b50ea45.

W danych występuje siedem miejsc: apartment, attic, cellar, kiosk, locker, gate i workshop. Każde jest mapowane na istniejące tło; cztery pory apartment mają osobne pliki, a pozostałe miejsca korzystają z jednego wspólnego pliku niezależnie od pory. Żadna z 16 kombinacji nie wymaga awaryjnego obrazu mieszkania wynikającego z braku wpisu w mapie.

To nie rozstrzyga, czy dla scen fabularnych są potrzebne bardziej specyficzne lokalizacje lub warianty pogody, ani czy istniejące obrazy wizualnie pasują do każdej sceny. Nie sprawdzano renderowania w grze. Tła nie zostały wygenerowane w tym zadaniu.
