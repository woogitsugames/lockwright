#!/usr/bin/env python3
"""Static site for Lockwright (session C, stage 3, task 5). No framework: this script writes site/public/.
Sources: art/renders/, mockups/realizm/png/ (images), docs/MARKETING.md §3 (press kit), store/privacy.md §1–2
(privacy policy). Text is generated from those files so the site never drifts from them.
   python3 site/build.py            # writes site/public/
   python3 site/build.py --check    # build + forbidden-phrase / link / size checks (exit 1 on failure)
"""
import html, pathlib, re, shutil, sys
from PIL import Image

ROOT = pathlib.Path(__file__).resolve().parent.parent
SITE = ROOT / 'site'
OUT = SITE / 'public'

RENDERS = [  # (file, alt PL, alt EN)
    ('section.jpg', 'Przekrój wymyślonego zamka bębenkowego: mosiężny rdzeń, piny i sprężyny w stalowym korpusie',
     'Cutaway of an invented pin tumbler lock: brass plug, pins and springs in a steel body'),
    ('lever.png', 'Wymyślony zamek zapadkowy w przekroju: stos zapadek nad ryglem',
     'An invented lever lock in cutaway: a stack of levers above the bolt'),
    ('warded.png', 'Wymyślony zamek przerwowy: przerwy w obudowie i klucz z wycięciami',
     'An invented warded lock: wards in the case and a cut key'),
    ('wafer.png', 'Wymyślony zamek płytkowy: płaskie płytki w rdzeniu',
     'An invented wafer lock: flat wafers in the plug'),
    ('wooden_pin.png', 'Drewniany zamek kołkowy: kołki w drewnianym ryglu',
     'A wooden pin lock: pegs in a wooden bolt'),
    ('loupe.png', 'Widok przez lupę: szczelina linii podziału z bliska',
     'Through the loupe: the shear line up close'),
]
MOCKUPS = [  # portrait mockups of the chosen direction (D-05)
    ('01-lock', 'Ekran zamka: dwa kciuki, bez paneli', 'Lock screen: two thumbs, no panels'),
    ('02-loupe', 'Lupa: makro na linię podziału', 'Loupe: macro on the shear line'),
    ('03-job', 'Zlecenie: kto dzwoni i dlaczego', 'A job: who is calling and why'),
    ('04-workshop', 'Warsztat: narzędzia zamiast ulepszeń za pieniądze', 'Workshop: tools instead of paid upgrades'),
    ('05-chalk', 'Kreda: opcjonalne znaki stanów na przekroju', 'Chalk: optional state marks on the cutaway'),
]
FONTS = ['BonaNova-Regular.ttf', 'BonaNova-Bold.ttf', 'AtkinsonHyperlegibleNext-wght.ttf',
         'OFL-bonanova.txt', 'OFL-atkinsonhyperlegiblenext.txt']

T = {
    'pl': dict(
        lang='pl', title='Lockwright: Pogotowie Zamkowe', other='en', other_label='English',
        nav=[('index', 'Gra'), ('fair', 'Jak gramy uczciwie'), ('press', 'Dla prasy'), ('privacy', 'Prywatność'), ('contact', 'Kontakt')],
        status='W przygotowaniu na iOS i Androida.',
        lede_h='Ktoś stoi pod własnymi drzwiami. Dzwoni po ciebie.', about_h='O grze',
        how_h='Zamek czujesz kciukami',
        how=[('Kciuk', 'Pin, który wiąże, stawia opór i skrobie. Pin, który siada, daje krótki, suchy klik w kciuku.'),
             ('Ucho', 'Każdy stan ma swój dźwięk: mosiądz, stal, drewno. Haptyka nigdy nie jest jedynym sygnałem.'),
             ('Oko', 'Fotorealistyczny przekrój pokazuje to samo, co czujesz: szczelinę, przechył, opór.')],
        dark_h='Tryb „w ciemności”', dark='Ekran gaśnie, zostaje dotyk i dźwięk. Całą grę da się przejść bez patrzenia na ekran.',
        locks_h='Wymyślone mechanizmy', locks_p='Każdy zamek w grze jest wymyślony i bez marki. Proporcje są dobrane tak, żeby dało się je czytać.',
        screens_h='Makiety ekranów', screens_p='Kierunek wizualny „realizm” (makiety, nie zrzuty z gotowej gry).',
        honest='To gra, nie kurs. Zamki są wymyślone. Prawdziwy ślusarz zawsze sprawdza, czy klient ma prawo wejść do lokalu; w grze też.',
        promises='Bez reklam, bez energii, bez kupowania monet.',
        press_title='Dla prasy', keyart_alt='Ślusarz z notesem i torbą na klatce schodowej kamienicy, w drzwiach mieszkania 3A uśmiechnięta klientka w szlafroku z kubkiem w dłoni.', keyart_cap='Przyjazd: najpierw rozmowa i sprawdzenie, czyje to mieszkanie.', dl_h='Do pobrania', dl_icon='Ikona (512 px, PNG)', dl_key='Key art 16:9 (1600 px, JPG)', dl_note='Grafiki robocze (generowane AI, D-42), ostateczne wersje przed premierą.', fair_title='Jak gramy uczciwie', privacy_title='Polityka prywatności', contact_title='Kontakt',
        contact=[('Kontakt ogólny', '[adres e-mail — do uzupełnienia]'), ('Prasa', '[adres e-mail — do uzupełnienia]'),
                 ('Prywatność', 'privacy@[domena — do ustalenia]'), ('Twórca / wydawca', '[nazwa studia lub imię i nazwisko]'),
                 ('Siedziba', '[miasto, kraj]')],
        contact_p='Ta strona nie ma formularza ani skryptów zbierających dane. Pisz bezpośrednio na adres poniżej.',
        todo_note='Pola w nawiasach kwadratowych uzupełnia właściciel przed publikacją.',
        footer='Lockwright · fonty: Bona Nova, Atkinson Hyperlegible Next (SIL OFL 1.1) · grafiki własne',
        skip='Przejdź do treści'),
    'en': dict(
        lang='en', title='Lockwright: Locksmith on Call', other='pl', other_label='Polski',
        nav=[('index', 'Game'), ('fair', 'Playing fair'), ('press', 'Press'), ('privacy', 'Privacy'), ('contact', 'Contact')],
        status='In development for iOS and Android.',
        lede_h='Someone is stuck outside their own door. They call you.', about_h='About the game',
        how_h='You feel the lock with your thumbs',
        how=[('Thumb', 'A pin that binds pushes back and scrapes. A pin that sets gives a short, dry click under your thumb.'),
             ('Ear', 'Every state has its own sound: brass, steel, wood. Haptics are never the only signal.'),
             ('Eye', 'A photoreal cutaway shows what you feel: the gap, the tilt, the resistance.')],
        dark_h='“In the dark” mode', dark='The screen goes dark; touch and sound remain. The whole game can be played without looking.',
        locks_h='Invented mechanisms', locks_p='Every lock in the game is invented and unbranded, with proportions chosen so you can read them.',
        screens_h='Screen mockups', screens_p='The “realism” visual direction (mockups, not screenshots of a finished game).',
        honest='A game, not a course. The locks are invented. A real locksmith always checks that the customer has the right to enter; so do you.',
        promises='No ads, no energy, coins can’t be bought.',
        press_title='Press', keyart_alt='A locksmith with a notepad and a bag on a tenement staircase; in the doorway of flat 3A a smiling client in a bathrobe holds a mug.', keyart_cap='Arrival: first a chat and a check of whose flat it is.', dl_h='Downloads', dl_icon='Icon (512 px, PNG)', dl_key='Key art 16:9 (1600 px, JPG)', dl_note='Work-in-progress art (AI-generated, D-42); final versions before launch.', fair_title='Playing fair', privacy_title='Privacy policy', contact_title='Contact',
        contact=[('General', '[e-mail address — to be filled in]'), ('Press', '[e-mail address — to be filled in]'),
                 ('Privacy', 'privacy@[domain — tbd]'), ('Developer / publisher', '[studio name or owner’s name]'),
                 ('Based in', '[city, country]')],
        contact_p='This site has no forms and no scripts that collect data. Write directly to the address below.',
        todo_note='Fields in square brackets are filled in by the owner before publishing.',
        footer='Lockwright · fonts: Bona Nova, Atkinson Hyperlegible Next (SIL OFL 1.1) · own artwork',
        skip='Skip to content'),
}

# ---------------------------------------------------------------- tiny markdown (subset used in the sources)
def inline(s: str) -> str:
    s = html.escape(s, quote=False)
    s = re.sub(r'`([^`]+)`', r'<code>\1</code>', s)
    s = re.sub(r'\*\*([^*]+)\*\*', r'<strong>\1</strong>', s)
    s = re.sub(r'\[([^\]]+)\](?!\()', r'<span class="todo">[\1]</span>', s)  # owner placeholders
    return s


def md(text: str, shift: int = 1) -> str:
    out, para, lst, tbl = [], [], [], []
    def flush():
        nonlocal para, lst, tbl
        if para: out.append('<p>' + inline(' '.join(para)) + '</p>'); para = []
        if lst: out.append('<ul>' + ''.join(f'<li>{inline(x)}</li>' for x in lst) + '</ul>'); lst = []
        if tbl:
            rows = [r for r in tbl if not re.match(r'^\|[\s|:-]+\|$', r)]
            cells = [[c.strip() for c in r.strip('|').split('|')] for r in rows]
            body = ''.join('<tr>' + (f'<th scope="row">{inline(c[0])}</th>' + ''.join(f'<td>{inline(x)}</td>' for x in c[1:])) + '</tr>'
                           for c in cells if any(c))
            out.append(f'<table class="facts">{body}</table>'); tbl = []
    for line in text.splitlines():
        st = line.strip()
        if not st or st == '---':
            flush(); continue
        m = re.match(r'^(#{1,6})\s+(.*)', st)
        if m:
            flush(); lvl = min(6, len(m.group(1)) + shift)
            out.append(f'<h{lvl}>{inline(m.group(2))}</h{lvl}>'); continue
        if st.startswith('|'):
            if para or lst: flush()
            tbl.append(st); continue
        if st.startswith('- '):
            if para or tbl: flush()
            lst.append(st[2:]); continue
        if lst and line.startswith('  '):
            lst[-1] += ' ' + st; continue
        if tbl: flush()
        para.append(st)
    flush()
    return '\n'.join(out)


def section(text: str, start: str, end: str) -> str:
    a = text.index(start)
    b = text.index(end, a + len(start)) if end else len(text)
    return text[a:b]

# ---------------------------------------------------------------- images and fonts
def images():
    (OUT / 'img').mkdir(parents=True, exist_ok=True)
    for f, *_ in RENDERS:
        im = Image.open(ROOT / 'art/renders' / f).convert('RGB')
        for w in (800, 1600):
            r = im.resize((w, round(im.height * w / im.width)), Image.LANCZOS)
            r.save(OUT / 'img' / f'{pathlib.Path(f).stem}-{w}.jpg', quality=80, optimize=True, progressive=True)
    for f, *_ in MOCKUPS:
        im = Image.open(ROOT / 'mockups/realizm/png' / f'{f}.portrait.png').convert('RGB')
        w = 480
        im.resize((w, round(im.height * w / im.width)), Image.LANCZOS).save(
            OUT / 'img' / f'{f}-{w}.jpg', quality=82, optimize=True, progressive=True)
    # stage 4 task 7: accepted G12 v2 icon (direction 01) and G13 key art 16:9, derived copies in site/assets/
    for f in (SITE / 'assets').glob('*'):
        shutil.copy2(f, OUT / 'img' / f.name)
    (OUT / 'fonts').mkdir(exist_ok=True)
    for f in FONTS:
        shutil.copy2(ROOT / 'mockups/fonts' / f, OUT / 'fonts' / f)


def size(path):
    with Image.open(OUT / 'img' / path) as im:
        return im.size

# ---------------------------------------------------------------- pages
def page(lang: str, name: str, title: str, body: str, depth: int) -> str:
    t = T[lang]
    up = '../' * depth
    here = f'{name}.html'
    other_href = (up + (f'{t["other"]}/' if t['other'] == 'en' else '')) + here
    nav = ''.join(f'<li><a href="{n}.html"{" aria-current=\"page\"" if n == name else ""}>{lbl}</a></li>' for n, lbl in t['nav'])
    full_title = t['title'] if name == 'index' else f'{title} · {t["title"]}'
    return f'''<!doctype html>
<html lang="{lang}">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{html.escape(full_title)}</title>
<meta name="description" content="{html.escape(t['lede_h'])}">
<link rel="alternate" hreflang="{t['other']}" href="{other_href}">
<link rel="stylesheet" href="{up}style.css">
<link rel="icon" type="image/png" href="{up}img/icon-180.png">
<link rel="apple-touch-icon" href="{up}img/icon-180.png">
</head>
<body>
<a class="skip" href="#main">{t['skip']}</a>
<header class="masthead">
  <a class="wordmark" href="index.html">Lockwright</a>
  <nav aria-label="{'Główne' if lang == 'pl' else 'Main'}"><ul>{nav}<li><a href="{other_href}" hreflang="{t['other']}" lang="{t['other']}">{t['other_label']}</a></li></ul></nav>
</header>
<main id="main">
{body}
</main>
<footer class="foot"><p>{t['footer']}</p><p class="honest">{t['honest']}</p></footer>
</body>
</html>
'''


def fig(src_stem, w_small, alt, cls='', caption=None):
    w, h = size(f'{src_stem}-{w_small}.jpg')
    big = OUT / 'img' / f'{src_stem}-1600.jpg'
    srcset = f' srcset="IMG/{src_stem}-{w_small}.jpg {w_small}w, IMG/{src_stem}-1600.jpg 1600w" sizes="(min-width: 60rem) 56rem, 100vw"' if big.exists() and w_small != 1600 else ''
    cap = f'<figcaption>{html.escape(caption)}</figcaption>' if caption else ''
    return (f'<figure class="{cls}"><img src="IMG/{src_stem}-{w_small}.jpg"{srcset} width="{w}" height="{h}" '
            f'alt="{html.escape(alt)}" loading="lazy" decoding="async">{cap}</figure>')


def home(lang):
    t = T[lang]; i = 1 if lang == 'pl' else 2
    hero_alt = RENDERS[0][i]
    how = ''.join(f'<div class="channel"><h3>{h}</h3><p>{p}</p></div>' for h, p in t['how'])
    renders = ''.join(fig(pathlib.Path(f).stem, 800, r[i], 'plate', r[i]) for f, *rest in RENDERS[1:] for r in [(f, *rest)])
    mocks = ''.join(fig(f, 480, r[i], 'phone', r[i]) for f, *rest in MOCKUPS for r in [(f, *rest)])
    mk = MARKETING_PL if lang == 'pl' else MARKETING_EN
    one_line = re.search(r'\*\*(?:Krótko \(1 zdanie\)|One line)\.\*\*\s*(.+?)\n\n', mk, re.S).group(1).replace('\n', ' ')
    about = re.search(r'\*\*(?:Opis \(ok\. 100 słów\)|About \(approx\. 100 words\))\.\*\*\s*(.+?)\n\n', mk, re.S).group(1).replace('\n', ' ')
    return f'''<section class="hero">
  {fig('section', 1600, hero_alt, 'hero-img')}
  <div class="hero-text">
    <h1>{t['title']}</h1>
    <p class="lede">{inline(one_line)}</p>
    <p class="status">{t['status']} {t['promises']}</p>
  </div>
</section>
<section class="prose">
  <h2>{t['about_h']}</h2>
  <p>{inline(about)}</p>
</section>
<section>{fig('key-art', 800, t['keyart_alt'], 'wide', t['keyart_cap'])}</section>
<section class="channels" aria-labelledby="how">
  <h2 id="how">{t['how_h']}</h2>
  <div class="channel-row">{how}</div>
</section>
<section class="dark" aria-labelledby="dark"><h2 id="dark">{t['dark_h']}</h2><p>{t['dark']}</p></section>
<section aria-labelledby="locks"><h2 id="locks">{t['locks_h']}</h2><p class="intro">{t['locks_p']}</p>
  <div class="plates">{renders}</div></section>
<section aria-labelledby="screens"><h2 id="screens">{t['screens_h']}</h2><p class="intro">{t['screens_p']}</p>
  <div class="phones">{mocks}</div></section>
'''


def press(lang):
    mk = MARKETING_PL if lang == 'pl' else MARKETING_EN
    body = re.sub(r'^\*\*Lockwright:[^*]+\*\*\s*$', '', mk, flags=re.M)
    t = T[lang]
    dl = (f'<h2>{t["dl_h"]}</h2><ul><li><a href="IMG/icon-512.png">{t["dl_icon"]}</a></li>'
          f'<li><a href="IMG/key-art-1600.jpg">{t["dl_key"]}</a></li></ul><p class="note">{t["dl_note"]}</p>')
    return f'<section class="prose wide"><h1>{t["press_title"]}</h1><p class="note">{t["todo_note"]}</p>\n{md(body, 1)}{dl}</section>'


def privacy(lang):
    src = PRIVACY_PL if lang == 'pl' else PRIVACY_EN
    src = re.sub(r'^#\s+.*$', '', src, count=1, flags=re.M)  # page has its own h1
    return f'<section class="prose"><h1>{T[lang]["privacy_title"]}</h1><p class="note">{T[lang]["todo_note"]}</p>\n{md(src, 1)}</section>'


def contact(lang):
    t = T[lang]
    rows = ''.join(f'<tr><th scope="row">{k}</th><td>{inline(v)}</td></tr>' for k, v in t['contact'])
    return f'<section class="prose"><h1>{t["contact_title"]}</h1><p>{t["contact_p"]}</p><table class="facts">{rows}</table><p class="note">{t["todo_note"]}</p></section>'



FAIR = {
    'pl': """
<p class="lede">Lockwright jest grą o ślusarzu z pogotowia, który pomaga ludziom. Tak samo jak w prawdziwym zawodzie,
najpierw sprawdzamy, czy ktoś ma prawo wejść, a dopiero potem otwieramy.</p>
<h2>Najpierw: czy to na pewno twoje drzwi</h2>
<p>Przed każdym zamkiem jest krótka scena przy drzwiach. Klient kładzie na stole jedną, dwie albo trzy karty: dowód
tożsamości, umowę najmu, list z adresem, sąsiada, który go zna. Gracz może poprosić o coś jeszcze. Karty są symboliczne
— gra nigdy nie pokazuje, jak wygląda prawdziwy dokument ani jak go „sprawdzić” technicznie. Liczy się zdrowy rozsądek:
czy historia klienta trzyma się kupy.</p>
<h2>Czasem trzeba odmówić</h2>
<p>Niektóre zlecenia są po to, żeby powiedzieć „nie”: ktoś chce wejść do mieszkania byłej partnerki, ktoś inny proponuje
podwójną stawkę „bez procedur”. W takich scenach jedyną dobrą decyzją jest spokojna odmowa — albo telefon do rodziny
czy na policję. Gra nagradza odmowę reputacją, a nie karze za nią. Policja w grze jest zwyczajna i uprzejma; nie ma
ucieczek ani pościgów.</p>
<h2>To gra, nie kurs</h2>
<p>Wszystkie zamki, kłódki i sejfy w grze są wymyślone. Nie mają marek i nie odwzorowują prawdziwych produktów, a ich
proporcje celowo zmieniliśmy, żeby dało się je czytać (na przykład szczelina linii podziału jest kilka razy szersza niż
w prawdziwej wkładce). Gra uczy czucia mechanizmu, nie otwierania prawdziwych drzwi. Jeśli zatrzasnęły ci się drzwi,
zadzwoń do ślusarza albo do zarządcy budynku.</p>
<h2>Bez estetyki włamywacza</h2>
<p>W Lockwright nie ma kominiarek, łupów, nocnych skoków ani skradania. Jest klatka schodowa z ciepłym światłem,
warsztat, kot w łazience i rosół na gazie. Ślusarz wychodzi, kiedy drzwi są otwarte bez jednej rysy, a klient jest u
siebie.</p>
<h2>Uczciwie wobec gracza</h2>
<ul>
<li>Bez reklam, bez energii, bez kupowania monet i bez losowania nagród. Narzędzia zarabiasz pracą w warsztacie.</li>
<li>Gra działa bez internetu i nie zbiera danych (szczegóły: <a href="privacy.html">polityka prywatności</a>).</li>
<li>Haptyka nigdy nie jest jedynym sygnałem: wszystko, co czujesz w kciuku, słychać i widać.</li>
</ul>
""",
    'en': """
<p class="lede">Lockwright is a game about an emergency locksmith who helps people. Just like in the real trade, we
check first that someone has the right to enter, and only then do we open the door.</p>
<h2>First: is this really your door?</h2>
<p>Before every lock there is a short scene at the door. The customer lays one, two or three cards on the table: an ID,
a lease, a letter with the address, a neighbour who knows them. The player can ask for one more thing. The cards are
symbolic — the game never shows what a real document looks like or how to "check" one technically. What counts is
common sense: does the customer's story hold together?</p>
<h2>Sometimes the answer is no</h2>
<p>Some jobs exist to say "no": someone wants to get into an ex-partner's flat, someone else offers double the rate
"without the procedures". In those scenes the only good choice is a calm refusal — or a call to the family or the
police. The game rewards refusing with reputation; it never punishes it. The police in the game are ordinary and
polite; there are no getaways or chases.</p>
<h2>A game, not a course</h2>
<p>Every lock, padlock and safe in the game is invented. They carry no brands and depict no real products, and their
proportions were changed on purpose so you can read them (the shear-line gap, for example, is several times wider than
in a real cylinder). The game teaches you to feel a mechanism, not to open real doors. If you're locked out, call a
locksmith or your building manager.</p>
<h2>No burglar aesthetic</h2>
<p>There are no balaclavas, no loot, no night-time jobs on the sly in Lockwright. There's a stairwell in warm light, a
workshop, a cat in the bathroom and soup on the stove. The locksmith leaves when the door is open without a scratch
and the customer is home.</p>
<h2>Fair to the player</h2>
<ul>
<li>No ads, no energy, no buying coins and no randomised rewards. You earn your tools by working.</li>
<li>The game works offline and collects no data (details: <a href="privacy.html">privacy policy</a>).</li>
<li>Haptics are never the only signal: everything you feel under your thumb can also be heard and seen.</li>
</ul>
""",
}


def fair(lang):
    return f'<section class="prose"><h1>{T[lang]["fair_title"]}</h1>{FAIR[lang]}</section>'

PAGES = {'index': home, 'fair': fair, 'press': press, 'privacy': privacy, 'contact': contact}


def build():
    global MARKETING_PL, MARKETING_EN, PRIVACY_PL, PRIVACY_EN
    mk = (ROOT / 'docs/MARKETING.md').read_text()
    MARKETING_PL = section(mk, '### 3.1 PL', '### 3.2 EN').split('\n', 1)[1]
    MARKETING_EN = section(mk, '### 3.2 EN', '\n## 4.').split('\n', 1)[1]
    pv = (ROOT / 'store/privacy.md').read_text()
    PRIVACY_PL = section(pv, '## 1. Polityka', '## 2. Privacy').split('\n', 1)[1]
    PRIVACY_EN = section(pv, '## 2. Privacy', '## 3.').split('\n', 1)[1]
    if OUT.exists():
        shutil.rmtree(OUT)
    OUT.mkdir(parents=True)
    images()
    shutil.copy2(SITE / 'style.css', OUT / 'style.css')
    shutil.copy2(SITE / '_headers', OUT / '_headers')  # Cloudflare Pages headers (D-51)
    for lang in ('pl', 'en'):
        d = OUT if lang == 'pl' else OUT / 'en'
        d.mkdir(exist_ok=True)
        depth = 0 if lang == 'pl' else 1
        for name, fn in PAGES.items():
            title = {'index': '', 'fair': T[lang]['fair_title'], 'press': T[lang]['press_title'], 'privacy': T[lang]['privacy_title'],
                     'contact': T[lang]['contact_title']}[name]
            doc = page(lang, name, title, fn(lang), depth).replace('IMG/', '../' * depth + 'img/')
            (d / f'{name}.html').write_text(doc)


FORBIDDEN = [r'\bwelcome\b', r'get started', r'unlock your', r'\bepic', r'epick', r'ultimate', r'#1\b', r'rewolucj',
             r'are you ready', r'can you crack', r'\bfree\b', r'za darmo', r'darmow', r'\bsale\b', r'najbardziej realistyczn',
             r'pierwsza gra w ciemności', r'linear-gradient', r'backdrop-filter', r'box-shadow:\s*0 0', r'text-shadow:\s*0 0',
             r'font-family:[^;]*(inter|roboto|system-ui|-apple-system)[^;]*;', r'<script']


def check() -> int:
    bad = 0
    files = list(OUT.rglob('*.html')) + [OUT / 'style.css']
    for p in files:
        s = p.read_text()
        low = s.lower()
        for pat in FORBIDDEN:
            if re.search(pat, low):
                print(f'FORBIDDEN {pat!r} in {p.relative_to(OUT)}'); bad += 1
        for href in re.findall(r'(?:href|src)="([^"#]+)"', s):
            if re.match(r'^[a-z]+:', href):
                continue
            if not (p.parent / href).resolve().exists():
                print(f'BROKEN {href} in {p.relative_to(OUT)}'); bad += 1
        if p.suffix == '.html':
            for img in re.findall(r'<img [^>]+>', s):
                if 'alt="' not in img or 'alt=""' in img:
                    print(f'NO ALT {img[:80]} in {p.relative_to(OUT)}'); bad += 1
    total = sum(f.stat().st_size for f in OUT.rglob('*') if f.is_file())
    print(f'site/public: {len(files) - 1} pages, {total / 1e6:.1f} MB')
    if total > 8e6:
        print('TOO BIG (> 8 MB)'); bad += 1
    print('OK' if not bad else f'{bad} problem(s)')
    return 1 if bad else 0


if __name__ == '__main__':
    build()
    if '--check' in sys.argv:
        sys.exit(check())
