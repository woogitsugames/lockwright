#!/usr/bin/env python3
"""Generate UTF-8 PL/EN/DE tutorial line bundle with reproducible length table."""
from __future__ import annotations
import csv
from pathlib import Path
DIR = Path(__file__).resolve().parent
ROWS = [
 ('tutorial.s1.step1','Left thumb gently up. Easy does it.','Lewy kciuk lekko w górę. Spokojnie, trzymaj.','Linker Daumen sanft hoch. Schön ruhig.'),
 ('tutorial.s1.step2','Right thumb: sideways to choose, up to lift.','Prawy kciuk: w bok wybierz, w górę unieś.','Rechter Daumen: seitlich wählen, hochheben.'),
 ('tutorial.s1.step3','That pin is resisting. Just right.','Ten kołek stawia opór. Dobrze.','Der Stift hält dagegen. Genau richtig.'),
 ('tutorial.s1.step4','Click! One set. Find the next.','Klik! Jeden osiadł. Szukaj następnego.','Klick! Einer sitzt. Such den nächsten.'),
 ('tutorial.s1.overset','Too high. Release tension; try more gently.','Za wysoko. Puść napięcie i spróbuj lżej.','Zu hoch. Spannung lösen, sanfter versuchen.'),
 ('tutorial.s1.near_break','Too much force. The tool is bending. Ease off.','Za mocno. Napinacz się ugina. Poluzuj.','Zu viel Druck. Der Spanner biegt sich. Lass locker.'),
 ('tutorial.s1.done',"It's open. Nicely done. Steady hands.",'Otwarte. Dobra robota, spokojna ręka.','Offen. Gut gemacht. Ruhige Hand.'),
 ('tutorial.s2.intro','Three pins. Only one resists at a time.','Trzy kołki. Opór stawia tylko jeden naraz.','Drei Stifte. Nur einer sperrt zugleich.'),
 ('tutorial.s3.intro','A new order. Too far? Start lighter.','Inna kolejność. Za wysoko? Zacznij lżej.','Andere Reihenfolge. Zu hoch? Sanfter neu.'),
 ('tutorial.hint.no_tension','Pins feel loose? Hold a little left tension.','Kołki luźne? Lewym kciukiem trzymaj napięcie.','Stifte locker? Links etwas Spannung halten.'),
 ('tutorial.hint.flap','Need a pause? Close the leather flap.','Potrzebna pauza? Zamknij klapkę zwijki.','Pause nötig? Schließ die Lederlasche.'),
 ('tutorial.hint.loupe','The magnifier shows a closer view.','Lupa pokaże kołek z bliska.','Mit der Lupe siehst du den Stift näher.'),
 ('tutorial.intro.frame1','Left thumb: gently up — tension.','Lewy kciuk: lekko w górę — napięcie.','Linker Daumen: sanft hoch – Spannung.'),
 ('tutorial.intro.frame2','Right thumb: sideways to select, up to lift.','Prawy: w bok wybór, w górę podnoszenie.','Rechts: seitlich wählen, nach oben heben.'),
 ('tutorial.intro.frame3','Click — pin set. Find the next.','Klik — kołek osiadł. Szukaj następnego.','Klick – Stift sitzt. Such den nächsten.'),
 ('tutorial.intro.note','A game, not a course. The parts are invented.','To gra, nie kurs. Mechanizmy są wymyślone.','Ein Spiel, kein Kurs. Die Mechanik ist erfunden.'),
]

ALTERNATIVES = {
 'tutorial.s1.step1': [
  ('Left thumb up — just a touch. Hold it.','Lewy kciuk w górę — odrobinę. Trzymaj.','Links ein wenig hoch. Dann ruhig halten.'),
  ('A little tension with the left thumb.','Lewym kciukiem dodaj odrobinę napięcia.','Links sanft spannen. Nicht eilen.')],
 'tutorial.s1.step4': [
  ('Click! That one is set. Keep looking.','Klik! Ten już siedzi. Szukaj dalej.','Klick! Der sitzt. Weiter zum nächsten.'),
  ('A clean click! Now find another pin.','Wyraźny klik! Teraz poszukaj kolejnego.','Ein klarer Klick! Such den nächsten.')],
}


def main():
    expected={
        'tutorial.s1.step1','tutorial.s1.step2','tutorial.s1.step3','tutorial.s1.step4',
        'tutorial.s1.overset','tutorial.s1.near_break','tutorial.s1.done',
        'tutorial.s2.intro','tutorial.s3.intro',
        'tutorial.hint.no_tension','tutorial.hint.flap','tutorial.hint.loupe',
        'tutorial.intro.frame1','tutorial.intro.frame2','tutorial.intro.frame3','tutorial.intro.note'
    }
    assert len(ROWS)==len(expected)==16
    assert {row[0] for row in ROWS}==expected
    for key,*texts in ROWS:
        assert all(0<len(t)<=56 and '\n' not in t for t in texts),(key,[(len(t),t) for t in texts])
        assert all('włam' not in t.lower() for t in texts)
        assert all(t.count('!')==1 for t in texts) if key.endswith('step4') else all('!' not in t for t in texts)
        assert all('"' not in t for t in texts),key
    with (DIR/'tutorial_lines.csv').open('w',encoding='utf-8',newline='') as f:
        wr=csv.writer(f,lineterminator='\n');wr.writerow(['keys','en','pl','de']);wr.writerows(ROWS)
    # Read back as parser used by importers.
    with (DIR/'tutorial_lines.csv').open('r',encoding='utf-8',newline='') as f:
        rr=list(csv.reader(f))
    assert rr[0]==['keys','en','pl','de'] and rr[1:]==[list(row) for row in ROWS]
    return ROWS

if __name__=='__main__':
    rows=main()
    for key,en,pl,de in rows:print(f'{key:27s} {len(en):2d} {len(pl):2d} {len(de):2d}')
