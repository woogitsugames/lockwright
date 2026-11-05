#!/usr/bin/env python3
"""Compose store screenshots from the photoreal renders in art/renders/.

No phone frames, no gradients: each shot is a solid caption band (warm near-black from the
realism palette) on top and a cover-fit crop of a render below. Captions use Bona Nova (OFL),
the optional second line uses Atkinson Hyperlegible Next (OFL), both from mockups/fonts/.

Usage:
    python3 store/screenshots/make_screens.py --lang pl|en|all [--sizes iphone69,android,ipad13]
                                              [--quantize]
Output: store/screenshots/out/<lang>/<size>/NN.png (RGB, no alpha: App Store rejects alpha).
"""
import argparse
from pathlib import Path

from PIL import Image, ImageDraw, ImageEnhance, ImageFont

ROOT = Path(__file__).resolve().parents[2]
RENDERS = ROOT / "art" / "renders"
FONTS = ROOT / "mockups" / "fonts"
OUT = Path(__file__).resolve().parent / "out"

SIZES = {
    "iphone69": (1320, 2868),  # App Store 6.9" portrait (required)
    "iphone65": (1284, 2778),  # App Store 6.5" portrait (older iPhones; optional when 6.9" is given)
    "android": (1080, 1920),   # Google Play phone portrait
    "ipad13": (2064, 2752),    # App Store 13" iPad portrait (only if iPad support stays, D-10)
}
DEFAULT_SIZES = ["iphone69", "iphone65", "android"]

INK = (20, 17, 14)          # warm near-black, realism palette --ink family
LEATHER = (42, 23, 11)      # tool-roll leather, mockups/realizm/realizm.css
CHALK = (241, 238, 230)     # --chalk
CHALK_DIM = (196, 190, 178)

# focus = (cx, cy) in 0..1 of the source; zoom = crop height as a fraction of the source height.
# mode "cover": crop fills the image area. mode "strip": a wide render sits on a solid fill.
SHOTS = [
    dict(src="section.png", mode="cover", focus=(0.46, 0.5), zoom=1.0,
         pl="Czujesz każdy kołek pod kciukiem.", en="Feel every pin under your thumb."),
    dict(src="section.png", mode="cover", focus=(0.62, 0.58), zoom=0.52,
         pl="Klik. Ten już siedzi.", en="Click. That one's set."),
    dict(src="section.png", mode="stack", focus=(0.42, 0.62), zoom=0.8,
         pl="Lewy kciuk napina, prawy szuka.", en="Left thumb tensions, right thumb picks."),
    dict(src="loupe.png", mode="cover", focus=(0.5, 0.5), zoom=0.9,
         pl="Lupa pokazuje linię podziału.", en="The loupe shows the shear line."),
    dict(src="section.png", mode="cover", focus=(0.46, 0.5), zoom=1.0, darken=0.10,
         pl="Zgaś ekran. Graj dotykiem i słuchem.", en="Screen off. Play by touch and ear."),
    dict(src="tray.png", mode="strip", focus=(0.25, 0.5), zoom=1.7,
         pl="Zapasowe wytrychy. Licz je.", en="Spare picks. Count them."),
    dict(src="lever.png", mode="cover", focus=(0.5, 0.5), zoom=0.85,
         pl="Każdy mechanizm prosi o inną rękę.", en="Every mechanism asks for a different hand."),
    dict(src="section.png", mode="cover", focus=(0.5, 0.3), zoom=0.56, darken=0.55,
         pl="Bez reklam. Bez sieci. Bez pośpiechu.", en="No ads. Offline. No rush.",
         sub_pl="To gra, nie kurs. Zamki są wymyślone.",
         sub_en="A game, not a course. The locks are invented."),
]


# --from-game: shot index -> capture from capture_game.sh (real plan B lock screen, 1320x2868)
GAME_SHOTS = {0: "lock_early.png", 1: "lock_late.png", 2: "lock_spool.png", 4: "lock_dark.png", 5: "lock_lastpick.png"}
GAME_DIR = None


def font(name, size, weight=None):
    f = ImageFont.truetype(str(FONTS / name), size)
    if weight is not None:
        try:
            f.set_variation_by_axes([weight])
        except Exception:
            pass
    return f


def wrap(text, fnt, max_w, max_lines):
    words, lines, cur = text.split(), [], ""
    for w in words:
        trial = (cur + " " + w).strip()
        if fnt.getlength(trial) <= max_w:
            cur = trial
        else:
            if cur:
                lines.append(cur)
            cur = w
    lines.append(cur)
    if len(lines) > max_lines or any(fnt.getlength(l) > max_w for l in lines):
        return None
    return lines


def balanced(text, fnt, max_w):
    """Prefer one line; for two lines, pick the break that makes them closest in width."""
    one = wrap(text, fnt, max_w, 1)
    if one:
        return one
    words = text.split()
    best = None
    for i in range(1, len(words)):
        a, b = " ".join(words[:i]), " ".join(words[i:])
        wa, wb = fnt.getlength(a), fnt.getlength(b)
        # breaking after a sentence or clause reads calmer than an even split
        score = abs(wa - wb) + (0 if a[-1] in ".,:;" else max_w * 0.35)
        if max(wa, wb) <= max_w and (best is None or score < best[0]):
            best = (score, [a, b])
    return best[1] if best else None


def fit_caption(text, W, H, max_w):
    size = int(min(W * 0.072, H * 0.036))
    while size > 24:
        fnt = font("BonaNova-Bold.ttf", size)
        lines = balanced(text, fnt, max_w)
        if lines:
            return fnt, lines, size
        size -= 2
    raise ValueError(f"caption does not fit: {text}")


def cover_crop(img, focus, zoom, aspect):
    sw, sh = img.size
    ch = sh * zoom
    cw = ch * aspect
    if cw > sw:
        cw = sw
        ch = cw / aspect
    cx, cy = focus[0] * sw, focus[1] * sh
    x0 = min(max(cx - cw / 2, 0), sw - cw)
    y0 = min(max(cy - ch / 2, 0), sh - ch)
    return img.crop((round(x0), round(y0), round(x0 + cw), round(y0 + ch)))


def render_shot(shot, lang, W, H):
    canvas = Image.new("RGB", (W, H), INK)
    draw = ImageDraw.Draw(canvas)
    side = round(W * 0.075)
    max_w = W - 2 * side

    caption = shot[lang]
    sub = shot.get("sub_" + lang)
    fnt, lines, size = fit_caption(caption, W, H, max_w)
    line_h = round(size * 1.18)
    sub_fnt = font("AtkinsonHyperlegibleNext-wght.ttf", round(size * 0.52), 400) if sub else None
    sub_h = round(size * 0.52 * 1.9) if sub else 0
    pad_top = round(H * 0.045)
    pad_bottom = round(H * 0.035)
    band_h = max(round(H * 0.20), pad_top + line_h * len(lines) + sub_h + pad_bottom)

    # image area
    area = (0, band_h, W, H)
    aw, ah = W, H - band_h
    game = shot.get("game")
    if game:
        # real game frame: fill the image area, keep the cutaway (top) and the roll (bottom) in view
        src = Image.open(game).convert("RGB")
        crop = cover_crop(src, (0.5, 0.5), 1.0, aw / ah)
        canvas.paste(crop.resize((aw, ah), Image.LANCZOS), (0, band_h))
        src = None
    else:
        src = Image.open(RENDERS / shot["src"]).convert("RGB")
    if src is None:
        pass
    elif shot["mode"] == "cover":
        crop = cover_crop(src, shot["focus"], shot["zoom"], aw / ah)
        pic = crop.resize((aw, ah), Image.LANCZOS)
        if "darken" in shot:
            pic = ImageEnhance.Brightness(pic).enhance(shot["darken"])
        canvas.paste(pic, (0, band_h))
    elif shot["mode"] == "stack":
        tray = Image.open(RENDERS / "tray.png").convert("RGB")
        th = round(tray.size[1] * aw / tray.size[0])
        canvas.paste(LEATHER, area)
        canvas.paste(tray.resize((aw, th), Image.LANCZOS), (0, H - th))
        sec_h = ah - th
        crop = cover_crop(src, shot["focus"], shot["zoom"], aw / sec_h)
        canvas.paste(crop.resize((aw, sec_h), Image.LANCZOS), (0, band_h))
    else:  # strip: wide render on a solid fill, scaled by zoom relative to frame width
        # fill with the render's own leather tone so the strip edge stays quiet
        sw, sh = src.size
        edge = src.crop((0, 0, sw, 12)).resize((1, 1), Image.BOX).getpixel((0, 0))
        canvas.paste(edge, area)
        scale = aw * shot["zoom"] / sw
        pw, ph = round(sw * scale), round(sh * scale)
        pic = src.resize((pw, ph), Image.LANCZOS)
        x = round(aw / 2 - shot["focus"][0] * pw)
        x = min(0, max(aw - pw, x))
        y = band_h + round(ah * 0.5 - ph / 2)
        canvas.paste(pic, (x, y))

    # caption band: solid fill, text centred
    draw.rectangle((0, 0, W, band_h), fill=INK)
    # optical centring: measure the real ink box of the caption block
    cap_top = fnt.getbbox(lines[0], anchor="ma")[1]
    last_bottom = fnt.getbbox("x", anchor="ma")[3]
    block_h = line_h * (len(lines) - 1) + last_bottom - cap_top + sub_h
    y = round((band_h - block_h) / 2 - cap_top)
    for line in lines:
        draw.text((W / 2, y), line, font=fnt, fill=CHALK, anchor="ma")
        y += line_h
    if sub:
        draw.text((W / 2, y + round(sub_h * 0.25)), sub, font=sub_fnt, fill=CHALK_DIM, anchor="ma")
    return canvas


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--lang", choices=["pl", "en", "all"], default="all")
    ap.add_argument("--sizes", default=",".join(DEFAULT_SIZES),
                    help="comma list of: " + ",".join(SIZES) + " (or 'all')")
    ap.add_argument("--quantize", action="store_true",
                    help="write 256-colour dithered PNGs (much smaller, slight grain)")
    ap.add_argument("--from-game", metavar="DIR",
                    help="use real game captures (capture_game.sh) for the lock-screen shots")
    args = ap.parse_args()
    shots = [dict(sh) for sh in SHOTS]
    if args.from_game:
        for i, name in GAME_SHOTS.items():
            f = Path(args.from_game) / name
            if f.exists():
                shots[i]["game"] = f
            else:
                print(f"missing capture {f}, keeping the render for shot {i + 1:02d}")
    langs = ["pl", "en"] if args.lang == "all" else [args.lang]
    sizes = list(SIZES) if args.sizes == "all" else args.sizes.split(",")
    total = 0
    for lang in langs:
        for sz in sizes:
            W, H = SIZES[sz]
            d = OUT / lang / sz
            d.mkdir(parents=True, exist_ok=True)
            for i, shot in enumerate(shots, 1):
                im = render_shot(shot, lang, W, H)
                p = d / f"{i:02d}.png"
                if args.quantize:
                    im.quantize(colors=256, method=Image.Quantize.MEDIANCUT,
                                dither=Image.Dither.FLOYDSTEINBERG).save(p, optimize=True)
                else:
                    im.save(p, optimize=True)
                total += p.stat().st_size
    print(f"wrote {len(langs) * len(sizes) * len(shots)} files, {total / 1e6:.1f} MB")


if __name__ == "__main__":
    main()
