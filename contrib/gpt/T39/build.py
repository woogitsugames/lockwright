#!/usr/bin/env python3
"""Regenerate UTF-8 tutorial_lines.csv and validate 56-char limit."""
from pathlib import Path
import csv
import io

DATA = "keys,en,pl,de\ntutorial.s1.step1,Left thumb gently up. Easy does it.,\"Lewy kciuk lekko w górę. Spokojnie, trzymaj.\",Linker Daumen sanft hoch. Schön ruhig.\ntutorial.s1.step2,\"Right thumb: sideways to choose, up to lift.\",\"Prawy kciuk: w bok wybierz, w górę unieś.\",\"Rechter Daumen: seitlich wählen, hochheben.\"\ntutorial.s1.step3,That pin is resisting. Just right.,Ten kołek stawia opór. Dobrze.,Der Stift hält dagegen. Genau richtig.\ntutorial.s1.step4,Click! One set. Find the next.,Klik! Jeden osiadł. Szukaj następnego.,Klick! Einer sitzt. Such den nächsten.\ntutorial.s1.overset,Too high. Release tension; try more gently.,Za wysoko. Puść napięcie i spróbuj lżej.,\"Zu hoch. Spannung lösen, sanfter versuchen.\"\ntutorial.s1.near_break,Too much force. The tool is bending. Ease off.,Za mocno. Napinacz się ugina. Poluzuj.,Zu viel Druck. Der Spanner biegt sich. Lass locker.\ntutorial.s1.done,It's open. Nicely done. Steady hands.,\"Otwarte. Dobra robota, spokojna ręka.\",Offen. Gut gemacht. Ruhige Hand.\ntutorial.s2.intro,Three pins. Only one resists at a time.,Trzy kołki. Opór stawia tylko jeden naraz.,Drei Stifte. Nur einer sperrt zugleich.\ntutorial.s3.intro,A new order. Too far? Start lighter.,Inna kolejność. Za wysoko? Zacznij lżej.,Andere Reihenfolge. Zu hoch? Sanfter neu.\ntutorial.hint.no_tension,Pins feel loose? Hold a little left tension.,Kołki luźne? Lewym kciukiem trzymaj napięcie.,Stifte locker? Links etwas Spannung halten.\ntutorial.hint.flap,Need a pause? Close the leather flap.,Potrzebna pauza? Zamknij klapkę zwijki.,Pause nötig? Schließ die Lederlasche.\ntutorial.hint.loupe,The magnifier shows a closer view.,Lupa pokaże kołek z bliska.,Mit der Lupe siehst du den Stift näher.\ntutorial.intro.frame1,Left thumb: gently up — tension.,Lewy kciuk: lekko w górę — napięcie.,Linker Daumen: sanft hoch – Spannung.\ntutorial.intro.frame2,\"Right thumb: sideways to select, up to lift.\",\"Prawy: w bok wybór, w górę podnoszenie.\",\"Rechts: seitlich wählen, nach oben heben.\"\ntutorial.intro.frame3,Click — pin set. Find the next.,Klik — kołek osiadł. Szukaj następnego.,Klick – Stift sitzt. Such den nächsten.\ntutorial.intro.note,\"A game, not a course. The parts are invented.\",\"To gra, nie kurs. Mechanizmy są wymyślone.\",\"Ein Spiel, kein Kurs. Die Mechanik ist erfunden.\"\n"
EXPECTED = set(["tutorial.s1.step1","tutorial.s1.step2","tutorial.s1.step3","tutorial.s1.step4","tutorial.s1.overset","tutorial.s1.near_break","tutorial.s1.done","tutorial.s2.intro","tutorial.s3.intro","tutorial.hint.no_tension","tutorial.hint.flap","tutorial.hint.loupe","tutorial.intro.frame1","tutorial.intro.frame2","tutorial.intro.frame3","tutorial.intro.note"])

def main():
    parsed = list(csv.reader(io.StringIO(DATA)))
    assert parsed[0] == ['keys', 'en', 'pl', 'de']
    assert len(parsed) == 17 and {r[0] for r in parsed[1:]} == EXPECTED
    assert all(len(r) == 4 and all(0 < len(t) <= 56 for t in r[1:]) for r in parsed[1:])
    for key, en, pl, de in parsed[1:]:
        assert all('włam' not in t.lower() for t in (en, pl, de))
        assert all(t.count('!') == (1 if key == 'tutorial.s1.step4' else 0) for t in (en, pl, de))
    Path(__file__).with_name('tutorial_lines.csv').write_text(DATA, encoding='utf-8')
    print('OK:', len(parsed) - 1, 'keys, max', max(map(len, [t for r in parsed[1:] for t in r[1:]])), 'characters')

if __name__ == '__main__':
    main()
