#!/usr/bin/env python3
"""Assemble the complete App Store + Google Play graphics set and check every file against the store limits.

    python3 store/tools/build_store_set.py --game DIR [--icon 01_enamel_l] [--out DIR]

--game: captures from store/screenshots/capture_game.sh (real plan B lock screen at 1320x2868).
Sources: screenshots = store/screenshots/make_screens.py (--from-game), icon = contrib/gpt/G12/v2 (direction chosen
with --icon; the owner's pick, see contrib/REVIEW.md), feature graphic = contrib/gpt/G13/feature (v1, no bars).
Output (default: /tmp/lw_store_set, outside the repo: ~60 MB): apple/<lang>/..., google/<lang>/..., icons, feature graphic.
Writes store/sets/REPORT.md (checks) and store/sets/contact_<lang>.jpg (small preview) into the repo.
"""
import argparse, json, pathlib, shutil, subprocess, sys

from PIL import Image

ROOT = pathlib.Path(__file__).resolve().parents[2]
SETS = ROOT / 'store' / 'sets'
G12 = ROOT / 'contrib' / 'gpt' / 'G12' / 'v2'
G13 = ROOT / 'contrib' / 'gpt' / 'G13' / 'feature'

# Store limits (App Store Connect help "Screenshot specifications", "App icon"; Play Console help
# "Add preview assets to showcase your app"), checked 2026-11.
APPLE_SHOTS = {'iphone69': (1320, 2868), 'iphone65': (1284, 2778)}
APPLE_SHOT_COUNT = (1, 10)
GOOGLE_SHOT_COUNT = (2, 8)
GOOGLE_SHOT_MAX_BYTES = 8 * 1024 * 1024
GOOGLE_ICON = (512, 512, 1024 * 1024)
GOOGLE_FEATURE = (1024, 500, 15 * 1024 * 1024)


def check_apple_shot(p, size):
    im = Image.open(p)
    errs = []
    if im.size != size:
        errs.append(f'rozmiar {im.size} ≠ {size}')
    if im.mode not in ('RGB', 'P', 'L') or (im.mode == 'P' and 'transparency' in im.info):
        errs.append(f'kanał alfa / tryb {im.mode}')
    return errs


def check_google_shot(p):
    im = Image.open(p)
    w, h = im.size
    errs = []
    if not (320 <= min(w, h) and max(w, h) <= 3840):
        errs.append(f'bok poza 320–3840: {im.size}')
    if max(w, h) > 2 * min(w, h):
        errs.append(f'proporcja > 2:1: {im.size}')
    if p.stat().st_size > GOOGLE_SHOT_MAX_BYTES:
        errs.append(f'plik {p.stat().st_size / 1e6:.1f} MB > 8 MB')
    if im.mode in ('RGBA', 'LA') or 'transparency' in im.info:
        errs.append('kanał alfa')
    return errs


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--game', required=True)
    ap.add_argument('--icon', default='01_enamel_l')
    ap.add_argument('--out', default='/tmp/lw_store_set')  # outside the repo (~60 MB)
    a = ap.parse_args()
    out = pathlib.Path(a.out)
    if out.exists():
        shutil.rmtree(out)
    rows, ok = [], True

    def rec(what, path, errs):
        nonlocal ok
        ok = ok and not errs
        rows.append((what, str(path.relative_to(out)) if path else '—', 'OK' if not errs else '; '.join(errs)))

    # screenshots (full RGB, no quantize) via make_screens.py
    gen = ROOT / 'store' / 'screenshots' / 'out'
    subprocess.run([sys.executable, str(ROOT / 'store/screenshots/make_screens.py'), '--lang', 'all',
                    '--sizes', 'iphone69,iphone65,android', '--from-game', a.game], check=True)
    for lang in ('pl', 'en'):
        for sz, dim in APPLE_SHOTS.items():
            files = sorted((gen / lang / sz).glob('*.png'))
            dst = out / 'apple' / lang / sz
            dst.mkdir(parents=True, exist_ok=True)
            for f in files:
                shutil.copy(f, dst / f.name)
                rec(f'App Store {sz} {lang}', dst / f.name, check_apple_shot(dst / f.name, dim))
            n = len(files)
            rec(f'App Store {sz} {lang}: liczba', None,
                [] if APPLE_SHOT_COUNT[0] <= n <= APPLE_SHOT_COUNT[1] else [f'{n} zrzutów'])
        files = sorted((gen / lang / 'android').glob('*.png'))
        dst = out / 'google' / lang / 'phone'
        dst.mkdir(parents=True, exist_ok=True)
        for f in files:
            shutil.copy(f, dst / f.name)
            rec(f'Google Play telefon {lang}', dst / f.name, check_google_shot(dst / f.name))
        n = len(files)
        rec(f'Google Play telefon {lang}: liczba', None,
            [] if GOOGLE_SHOT_COUNT[0] <= n <= GOOGLE_SHOT_COUNT[1] else [f'{n} zrzutów'])

    # icons: App Store 1024 RGB without alpha; Play 512 32-bit PNG <= 1 MB
    src = G12 / 'ios' / f'{a.icon}_1024.png'
    im = Image.open(src)
    flat = Image.new('RGB', im.size, (20, 17, 14))
    flat.paste(im.convert('RGBA'), (0, 0), im.convert('RGBA'))
    p = out / 'apple' / 'icon_1024.png'
    flat.save(p, optimize=True)
    rec('App Store ikona', p, [] if Image.open(p).size == (1024, 1024) and Image.open(p).mode == 'RGB' else ['zły rozmiar/tryb'])
    p = out / 'google' / 'icon_512.png'
    im.convert('RGBA').resize((512, 512), Image.LANCZOS).save(p, optimize=True)
    w, h, mx = GOOGLE_ICON
    rec('Google Play ikona', p, [] if Image.open(p).size == (w, h) and p.stat().st_size <= mx else ['zły rozmiar lub > 1 MB'])
    for layer in ('foreground', 'background'):
        f = G12 / 'android' / f'{a.icon}_{layer}_432.png'
        if f.exists():
            shutil.copy(f, out / 'google' / f'adaptive_{layer}_432.png')

    # feature graphic: 1024x500, JPEG or 24-bit PNG, no alpha
    p = out / 'google' / 'feature_1024x500.jpg'
    Image.open(G13 / 'google-play-1024x500-title.png').convert('RGB').save(p, quality=92)
    w, h, mx = GOOGLE_FEATURE
    rec('Google Play feature graphic', p,
        [] if Image.open(p).size == (w, h) and p.stat().st_size <= mx else ['zły rozmiar lub > 15 MB'])

    # previews into the repo (small)
    SETS.mkdir(parents=True, exist_ok=True)
    for lang in ('pl', 'en'):
        files = sorted((out / 'apple' / lang / 'iphone69').glob('*.png'))
        tw = 220
        th = round(tw * 2868 / 1320)
        sheet = Image.new('RGB', (tw * len(files) + 240, th), (20, 17, 14))
        for i, f in enumerate(files):
            sheet.paste(Image.open(f).convert('RGB').resize((tw, th), Image.LANCZOS), (i * tw, 0))
        ic = Image.open(out / 'apple' / 'icon_1024.png').resize((200, 200), Image.LANCZOS)
        sheet.paste(ic, (tw * len(files) + 20, 20))
        fg = Image.open(out / 'google' / 'feature_1024x500.jpg').resize((200, 98), Image.LANCZOS)
        sheet.paste(fg, (tw * len(files) + 20, 240))
        sheet.save(SETS / f'contact_{lang}.jpg', quality=82)

    total = sum(f.stat().st_size for f in out.rglob('*') if f.is_file())
    md = ['# Zestaw grafik sklepowych — kontrola wymiarów i limitów', '',
          f'Wygenerowane: `python3 store/tools/build_store_set.py --game <zrzuty> --icon {a.icon}` → `--out` (domyślnie `/tmp/lw_store_set`) '
          f'(poza repo, {total / 1e6:.0f} MB). Podgląd: `contact_pl.jpg`, `contact_en.jpg`.', '',
          f'**Wynik: {"wszystko w limitach" if ok else "SĄ PROBLEMY"}** ({sum(1 for r in rows if r[2] == "OK")}/{len(rows)} kontroli OK)', '',
          '| Element | Plik | Kontrola |', '|---|---|---|']
    md += [f'| {w} | `{p}` | {c} |' for w, p, c in rows]
    (SETS / 'REPORT.md').write_text('\n'.join(md) + '\n')
    (SETS / 'manifest.json').write_text(json.dumps({'icon': a.icon, 'ok': ok, 'checks': len(rows)}, indent=2))
    print(f'{"OK" if ok else "PROBLEMS"}: {len(rows)} checks, {total / 1e6:.0f} MB in {out}')
    return 0 if ok else 1


if __name__ == '__main__':
    sys.exit(main())
