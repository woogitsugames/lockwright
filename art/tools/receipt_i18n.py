"""VA-18: receipt papers for DE / FR / ES, made the way contrib/gpt/G14/generate.py made receipt_pl/en.

Same procedural paper (G14 `paper()`, the PL receipt's seed, so the grain and edges match), the same rules
and blank lines at the same pixel positions, so job_payment.gd's FIELDS (fractions of 1080x1500) fit every
language. Only the printed words change. G14 rasterised Liberation Serif + Lato (not in the repo); here the
game's own OFL fonts are used instead (Bona Nova Bold for the heading, Atkinson Hyperlegible Next for the
labels). Every label is fitted so it ends before the hand-written value starts (field x in job_payment.gd).

    python art/tools/receipt_i18n.py            # writes game/assets/ui/gpt/verify/receipt_{de,fr,es}.webp
    python art/tools/receipt_i18n.py --png DIR  # also writes the RGBA PNG masters into DIR
"""
import argparse
import os

import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..'))
FONTS = os.path.join(ROOT, 'game', 'assets', 'fonts')
OUT = os.path.join(ROOT, 'game', 'assets', 'ui', 'gpt', 'verify')
SERIF_BOLD = os.path.join(FONTS, 'BonaNova-Bold.ttf')
SANS = os.path.join(FONTS, 'AtkinsonHyperlegibleNext-wght.ttf')
INK = (52, 47, 41, 255)
W, H = 1080, 1500
SEED = 22  # G14: receipt_pl = draw('receipt', 'pl', 14 + 1 * 8 + 0)

# Printed words per language. Keys mirror G14's receipt block.
TEXT = {
    'de': dict(sub='Schlüsseldienst • fiktiver Vordruck', title='QUITTUNG', number='Beleg-Nr.:', date='Datum',
               client='Kunde', service='Leistung', desc='Beschreibung', amount='Betrag', total='Summe:',
               pay='Zahlung:', cash='bar', transfer='Überweisung', sign='Unterschrift:'),
    'fr': dict(sub='Serrurerie • imprimé fictif', title='REÇU', number='Reçu n° :', date='Date', client='Client',
               service='Prestation', desc='Désignation', amount='Montant', total='Total :', pay='Réglé :',
               cash='espèces', transfer='virement', sign='Signature :'),
    'es': dict(sub='Cerrajería • impreso ficticio', title='RECIBO', number='Recibo n.º:', date='Fecha',
               client='Cliente', service='Servicio', desc='Descripción', amount='Importe', total='Total:',
               pay='Pago:', cash='efectivo', transfer='transferencia', sign='Firma:'),
}

# Where the hand-written values start (job_payment.gd FIELDS x * 1080), minus a margin
NUMBER_X = int(0.33 * W) - 12
FIELD_X = int(0.26 * W) - 12
TOTAL_X = int(0.24 * W) - 12
CASH_BOX_X = int(0.219 * W) - 6   # the "x" is written at 0.219: the box sits under it


def paper(w=W, h=H, col=(236, 226, 207), seed=SEED):
    """G14 paper(): grain, wavy torn side edges, faint folds and tick marks (shape='paper')."""
    rng = np.random.default_rng(seed)
    arr = np.empty((h, w, 4), dtype=np.uint8)
    noise = rng.normal(0, 4, (h, w))
    y, x = np.indices((h, w))
    grain = noise + 3 * np.sin(x / 71 + y / 193) + 2 * np.sin(x / 23 - y / 99)
    for c in range(3):
        arr[:, :, c] = np.clip(col[c] + grain, 0, 255)
    edge = 24 + rng.integers(-5, 6, size=h)
    alpha = np.zeros((h, w), dtype=np.uint8)
    for yy in range(h):
        left = int(edge[yy] + 4 * np.sin(yy / 21))
        alpha[yy, max(0, left):min(w, w - left)] = 255
    for xx in range(w):
        top = int(20 + 6 * np.sin(xx / 37) + rng.integers(-2, 3))
        bot = int(h - 20 - 5 * np.sin(xx / 41))
        alpha[:top, xx] = 0
        alpha[bot:, xx] = 0
    arr[:, :, 3] = alpha
    im = Image.fromarray(arr, 'RGBA')
    d = ImageDraw.Draw(im)
    for xx in range(80, w - 60, 90):
        d.line([(xx, 29), (xx + 8, 33)], fill=(130, 100, 70, 45), width=1)
    for yy in range(80, h - 50, 130):
        d.arc((25, yy, w - 25, yy + 130), 0, 10, fill=(125, 99, 65, 18), width=2)
    return im, d


def sans(size, bold=False):
    f = ImageFont.truetype(SANS, size)
    try:
        f.set_variation_by_axes([700 if bold else 400])
    except Exception:  # noqa: BLE001 - static build of the font: regular only
        pass
    return f


def fitted(text, size, max_w, bold=False):
    """Largest size <= `size` whose text is at most max_w px wide."""
    while size > 18:
        f = sans(size, bold)
        if f.getlength(text) <= max_w:
            return f
        size -= 1
    return sans(18, bold)


def rule(d, y):
    d.line((100, y, 980, y), fill=(100, 88, 70, 150), width=3)


def blank(d, x0, y_text, x1, f):
    """Printed underscores from x0 to x1 on the text baseline (G14 used '__________')."""
    asc = f.getmetrics()[0]
    yb = y_text + asc + 2
    d.line((x0, yb, x1, yb), fill=INK, width=2)


def draw(lang):
    t = TEXT[lang]
    im, d = paper()
    # header (G14 header(): brand, subtitle, rule, document title)
    d.text((100, 100), 'LOCKWRIGHT', font=ImageFont.truetype(SERIF_BOLD, 57), fill=INK)
    d.text((100, 167), t['sub'], font=sans(25), fill=INK)
    rule(d, 224)
    d.text((100, 265), t['title'], font=ImageFont.truetype(SERIF_BOLD, 49), fill=INK)
    # receipt no. + blank
    f = fitted(t['number'], 30, NUMBER_X - 100)
    d.text((100, 355), t['number'], font=f, fill=INK)
    blank(d, max(100 + int(f.getlength(t['number'])) + 10, NUMBER_X - 4), 355, 590, f)
    # date / customer / service: label + full-width line under it (G14 line())
    for y, key in zip((440, 545, 650), ('date', 'client', 'service')):
        s = t[key] + ':' if lang != 'fr' else t[key] + ' :'
        d.text((100, y), s, font=fitted(s, 31, FIELD_X - 100), fill=INK)
        d.line((100, y + 78, 980, y + 78), fill=(93, 84, 73, 180), width=2)
    # line items
    d.text((100, 810), t['desc'], font=fitted(t['desc'], 30, 600, True), fill=INK)
    d.text((790, 810), t['amount'], font=fitted(t['amount'], 30, 180, True), fill=INK)
    for y in (870, 940, 1010):
        rule(d, y)
    # total + blank
    f = fitted(t['total'], 38, TOTAL_X - 100, True)
    d.text((100, 1100), t['total'], font=f, fill=INK)
    blank(d, max(100 + int(f.getlength(t['total'])) + 10, TOTAL_X - 4), 1100, 520, f)
    # payment: two tick boxes, the cash box under the hand-written "x"
    f = fitted(t['pay'], 29, CASH_BOX_X - 100 - 12)
    d.text((100, 1205), t['pay'], font=f, fill=INK)
    fc = sans(29)
    by = 1205 + fc.getmetrics()[0] - 20
    d.rectangle((CASH_BOX_X, by, CASH_BOX_X + 20, by + 20), outline=INK, width=2)
    d.text((CASH_BOX_X + 32, 1205), t['cash'], font=fc, fill=INK)
    bx = CASH_BOX_X + 32 + int(fc.getlength(t['cash'])) + 34
    d.rectangle((bx, by, bx + 20, by + 20), outline=INK, width=2)
    d.text((bx + 32, 1205), t['transfer'], font=fc, fill=INK)
    # signature
    f = sans(28)
    d.text((100, 1300), t['sign'], font=f, fill=INK)
    blank(d, 100 + int(f.getlength(t['sign'])) + 10, 1300, 520, f)
    return im


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--png', default='')
    ap.add_argument('--langs', default='de,fr,es')
    a = ap.parse_args()
    for lang in a.langs.split(','):
        im = draw(lang)
        if a.png:
            os.makedirs(a.png, exist_ok=True)
            im.save(os.path.join(a.png, 'receipt_%s.png' % lang))
        p = os.path.join(OUT, 'receipt_%s.webp' % lang)
        im.save(p, 'WEBP', quality=90, method=6)
        print('WROTE', p, os.path.getsize(p))


if __name__ == '__main__':
    main()
