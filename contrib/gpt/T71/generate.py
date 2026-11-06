import csv
from pathlib import Path

source = Path('game/i18n/strings.csv')
out = Path('contrib/gpt/T71/lengths.csv')
short = {
 ('fr','common.off'): 'Arrêt',
 ('fr','menu.play'): 'Prendre service',
 ('fr','settings.haptics'): 'Haptique',
 ('de','settings.reset'): 'Optionen zurücksetzen',
 ('fr','settings.dark_mode_note'): 'Dans le noir, fie-toi au son. Les vibrations du mobile aident aussi.',
 ('fr','family.dimple.short'): 'Deux rangées de goupilles ; certaines cachent une goupille plus fine en douille.',
 ('fr','tutorial.egyptian.step3'): 'Écoute le toc du bois ; regarde tomber la cheville.',
 ('fr','tutorial.dimple.step2'): 'Droit : choisis la rangée, puis presse une goupille.',
 ('de','menu.jobs'): 'Jobs',
 ('fr','menu.jobs'): 'Missions',
 ('de','jobs.title'): 'Jobs',
 ('fr','jobs.title'): 'Missions',
 ('fr','pause.title'): 'Pause',
 ('fr','pause.resume'): 'Continuer',
 ('fr','workshop.repair_cost'): 'Réparer : {0} pièces',
 ('de','ui.job_done'): 'fertig',
 ('fr','boot.calib_title'): 'Deux impulsions à 120 ms : combien sens-tu et entends-tu ?',
 ('de','settings.feel_section'): 'Gefühl (Haptik)',
 ('fr','settings.feel_section'): 'Sensation (haptique)',
 ('de','settings.quality_auto'): 'Auto (gemessen)',
 ('de','settings.quality_low'): 'Niedrig (einfache Handys)',
 ('de','about.post_release_unlocked'): 'Kapitel 7 („Ein gemeinsamer Schlüssel“) ist frei.',
 ('de','settings.report_copied'): 'Protokoll in Zwischenablage kopiert. Füge es in deine Nachricht ein — nichts wird automatisch gesendet.',
 ('de','menu.play'): 'Dienst starten',
 ('fr','job.refuse'): 'Refuser la mission',
 ('de','job.opened'): 'Schloss offen. Rechnung bezahlt.',
 ('fr','job.tip_fmt'): 'Pourboire (sans trace) : {n} pièces',
 ('de','receipt.tip'): 'Trinkgeld (ohne Spuren)',
 ('de','job.verify'): 'Zutrittsrecht prüfen',
 ('de','verify.title'): 'Zutrittsrecht prüfen',
 ('de','settings.volume_ambience'): 'Umgebung',
 ('de','settings.reduce_motion'): 'Weniger Bewegung',
 ('de','pause.resume'): 'Weiter',
 ('de','settings.voice_pack.retry'): 'Wiederholen',
 ('fr','verify.card.receipt'): 'Ticket de caisse',
 ('fr','verify.card.bailiff'): 'Huissier',
 ('fr','verify.refused'): 'Justificatifs insuffisants. Je ne peux pas ouvrir.',
 ('fr','tutorial.start'): 'Débuter l’entraînement',
 ('fr','settings.haptics_enabled'): 'Haptique activée',
 ('fr','settings.haptics_test'): 'Test haptique',
 ('fr','settings.language_de'): 'Deutsch (dev)',
 ('de','settings.wide_windows'): 'Breitere Sichtfenster',
 ('fr','settings.reset'): 'Réinitialiser les réglages',
 ('de','optics.loupe'): 'Scherlinie vergrößert',
 ('fr','optics.loupe'): 'Gros plan de la ligne de césure',
 ('de','optics.borescope'): 'Tiefe Elemente',
 ('fr','optics.borescope'): 'Éléments profonds',
 ('fr','workshop.owned'): 'Acquis',
 ('de','workshop.reward'): 'Fortschrittsbelohnung',
 ('fr','dev.haptics_lab.title'): 'Labo haptique',
 ('de','practice.t18.goal'): 'Warte auf den richtigen Klick am Zuhaltungstor.',
 ('de','practice.t24.goal'): 'Zähl jedes Zuhaltungstor; lass keines aus.',
 ('de','settings.voice_pack.stop'): 'Stoppen',
 ('fr','settings.voice_pack.stop'): 'Stopper',
 ('de','family.dial_safe.name'): 'Drehscheibentresor',
 ('fr','family.dial_safe.name'): 'Coffre à cadran',
 ('de','tutorial.dial_safe.step2'): 'Kreise rechts mit dem Daumen auf der Drehscheibe.',
 ('fr','family.axial_slider.short'): 'De face, les coulisseaux forment un cercle autour du centre.',
 ('fr','tutorial.axial_slider.step5'): 'Coulisseaux en place. Le bureau est prêt.',
 ('fr','family.time_lock.name'): 'Réparer la serrure à minuterie',
 ('de','tutorial.magnetic.step4'): 'Stift hängt nach? Ruhig führen, nicht rucken.',
 ('fr','tutorial.magnetic.step4'): 'Goupille en retard ? Doucement, sans à-coups.',
 ('de','verify.ask_more'): 'Weiteren Nachweis erbitten',
 ('de','workshop.owned'): 'Vorhanden',
 ('de','workshop.reward_hint'): 'Durch Fortschritt frei',
 ('fr','settings.volume_ambience'): 'Ambiance',
 ('fr','settings.reduce_motion'): 'Moins d’animations',
 ('fr','settings.text_scale'): 'Taille du texte',
 ('fr','settings.voice_pack.not_now'): 'Plus tard',
 ('fr','settings.voice_pack.auto'): 'Télécharger les voix auto',
 ('fr','nav.quit_no'): 'Continuer',
 ('fr','settings.wide_windows'): 'Fenêtres larges',
 ('fr','settings.voice_pack.failed'): 'Téléchargement échoué. Les sous-titres restent affichés.',
 ('fr','settings.voice_pack.offline'): 'Hors ligne. Les sous-titres restent affichés.',
}
with source.open(encoding='utf-8-sig', newline='') as f, out.open('w', encoding='utf-8', newline='') as g:
    rows = csv.DictReader(f)
    writer = csv.writer(g)
    writer.writerow(['key','language','english','original','en_chars','original_chars','ratio_percent','proposal','proposal_chars','note'])
    for row in rows:
        for lang in ('de','fr'):
            en, value = row['en'], row[lang]
            if not en or not value or len(value) * 10 <= len(en) * 13:
                continue
            proposal = short.get((lang,row['keys']), '')
            if proposal and len(proposal) >= len(value):
                proposal = ''
            key = row['keys']
            if proposal:
                note = 'propozycja wymaga przeglądu w kontekście UI'
            elif key.startswith('verify.card.'):
                note = 'nazwa dowodu lub osoby: skrót grozi pomyleniem kategorii'
            elif key.startswith('family.'):
                note = 'nazwa lub opis mechanizmu: skrót może pominąć cechę rodziny'
            elif key.startswith(('lock.', 'tutorial.')):
                note = 'instrukcja: skrót mógłby pominąć część gestu lub sygnału'
            elif key == 'run.lives_left':
                note = 'EN i DE różnią się znaczeniem; najpierw ustalić stan w grze'
            elif key.startswith('settings.voice_pack.'):
                note = 'zachować etap pobierania i jasne działanie; brak bezpiecznego skrótu'
            elif len(value) <= 12:
                note = 'krótkie słowo: skrót lub symbol mógłby utrudnić zrozumienie'
            else:
                note = 'bez bezpiecznego skrótu zachowującego sens i funkcję kontrolki'
            writer.writerow([key,lang,en,value,len(en),len(value),round(100*len(value)/len(en),1),proposal,len(proposal) if proposal else '',note])
