#!/usr/bin/env python3
"""Build the Lockwright app icon set from the approved G12 v2 #01 enamel "L" plate (D-50).

Inputs (approved package, unchanged):
  contrib/gpt/G12/v2/ios/01_enamel_l_1024.png                 full icon, RGB 1024
  contrib/gpt/G12/v2/android/01_enamel_l_foreground_432.png   plate on alpha, RGBA 432
  contrib/gpt/G12/v2/android/01_enamel_l_background_432.png   backdrop, RGB 432

Outputs:
  game/icon.png                                    project / window icon (128, RGBA rounded square; stored raw in every pck)
  game/assets/icon/android/foreground_432.png      adaptive foreground, plate scaled into the 66 dp safe zone
  game/assets/icon/android/background_432.png      adaptive background (full bleed, opaque)
  game/assets/icon/android/monochrome_432.png      themed-icon layer: plate silhouette with the "L" cut out
  game/assets/icon/android/main_192.png            legacy launcher icon (rounded square)
  game/assets/icon/ios/icon_1024.png               iOS / App Store icon (opaque RGB, system applies the mask)
  store/icon/play-icon-512.png                     Google Play listing icon (512, opaque, full bleed)
  docs/handoff/device-tests/fixes/icon/masks.png   preview sheet: launcher masks, safe zone, themed, small sizes

Adaptive icon geometry: 108 dp layer = 432 px (4 px/dp), launchers show the centre 72 dp (288 px) through a
mask; everything that must stay visible lies inside the 66 dp (264 px, radius 132 px) safe circle.
Usage: python tools/build_app_icon.py [--check]   (--check only verifies the committed outputs)
"""
import argparse
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "contrib", "gpt", "G12", "v2")
SRC_IOS = os.path.join(SRC, "ios", "01_enamel_l_1024.png")
SRC_FG = os.path.join(SRC, "android", "01_enamel_l_foreground_432.png")
SRC_BG = os.path.join(SRC, "android", "01_enamel_l_background_432.png")

OUT_ANDROID = os.path.join(ROOT, "game", "assets", "icon", "android")
OUT_IOS = os.path.join(ROOT, "game", "assets", "icon", "ios")
OUT = {
    "window": os.path.join(ROOT, "game", "icon.png"),
    "fg": os.path.join(OUT_ANDROID, "foreground_432.png"),
    "bg": os.path.join(OUT_ANDROID, "background_432.png"),
    "mono": os.path.join(OUT_ANDROID, "monochrome_432.png"),
    "main": os.path.join(OUT_ANDROID, "main_192.png"),
    "ios": os.path.join(OUT_IOS, "icon_1024.png"),
    "play": os.path.join(ROOT, "store", "icon", "play-icon-512.png"),
    "sheet": os.path.join(ROOT, "docs", "handoff", "device-tests", "fixes", "icon", "masks.png"),
}

LAYER = 432
DP = LAYER / 108.0
SAFE_R = 33 * DP          # 66 dp safe zone -> radius 132 px
VIEW_R = 36 * DP          # 72 dp visible viewport -> half side 144 px
TARGET_R = SAFE_R - 6     # keep a small margin inside the safe circle
ALPHA_SOLID = 200         # plate body (excludes the soft drop shadow)
ALPHA_ANY = 16            # anything visible, shadow included


def max_radius(alpha, threshold):
    ys, xs = np.nonzero(alpha > threshold)
    c = (alpha.shape[0] - 1) / 2.0
    return float(np.sqrt((xs - c) ** 2 + (ys - c) ** 2).max())


def rounded_mask(size, radius_frac):
    m = Image.new("L", (size * 4, size * 4), 0)
    ImageDraw.Draw(m).rounded_rectangle((0, 0, size * 4 - 1, size * 4 - 1), radius=int(size * 4 * radius_frac), fill=255)
    return m.resize((size, size), Image.LANCZOS)


def build_foreground(src_fg):
    a = np.array(src_fg)[:, :, 3]
    r = max_radius(a, ALPHA_ANY)
    scale = min(1.0, TARGET_R / r)
    side = int(round(LAYER * scale))
    small = src_fg.resize((side, side), Image.LANCZOS)
    out = Image.new("RGBA", (LAYER, LAYER), (0, 0, 0, 0))
    off = (LAYER - side) // 2
    out.alpha_composite(small, (off, off))
    return out, scale


def build_monochrome(fg):
    arr = np.array(fg).astype(np.int16)
    r, g, b, a = arr[..., 0], arr[..., 1], arr[..., 2], arr[..., 3]
    plate = a > ALPHA_SOLID
    # The navy enamel letter: blue clearly above red, dark.
    letter = plate & (b - r > 18) & ((r + g + b) < 330)
    letter_img = Image.fromarray((letter * 255).astype(np.uint8)).filter(ImageFilter.MedianFilter(5))
    letter_img = letter_img.filter(ImageFilter.MaxFilter(3))
    plate_img = Image.fromarray((plate * 255).astype(np.uint8)).filter(ImageFilter.MedianFilter(5))
    mono = np.clip(np.array(plate_img).astype(np.int16) - np.array(letter_img).astype(np.int16), 0, 255).astype(np.uint8)
    alpha = Image.fromarray(mono).filter(ImageFilter.GaussianBlur(0.6))
    out = Image.new("RGBA", (LAYER, LAYER), (255, 255, 255, 0))
    out.putalpha(alpha)
    return out, float(letter.mean()), float(plate.mean())


def superellipse_mask(size, n=5.0):
    """iOS / Pixel-like squircle |x|^n + |y|^n <= 1."""
    s = size * 4
    yy, xx = np.mgrid[0:s, 0:s]
    u = (xx + 0.5) / s * 2 - 1
    v = (yy + 0.5) / s * 2 - 1
    m = ((np.abs(u) ** n + np.abs(v) ** n) <= 1.0).astype(np.uint8) * 255
    return Image.fromarray(m).resize((size, size), Image.LANCZOS)


def circle_mask(size):
    m = Image.new("L", (size * 4, size * 4), 0)
    ImageDraw.Draw(m).ellipse((0, 0, size * 4 - 1, size * 4 - 1), fill=255)
    return m.resize((size, size), Image.LANCZOS)


def teardrop_mask(size):
    s = size * 4
    m = Image.new("L", (s, s), 0)
    d = ImageDraw.Draw(m)
    d.ellipse((0, 0, s - 1, s - 1), fill=255)
    d.rectangle((s // 2, s // 2, s - 1, s - 1), fill=255)
    return m.resize((size, size), Image.LANCZOS)


def font(px):
    for name in ("segoeui.ttf", "arial.ttf", "DejaVuSans.ttf", "NotoSans-Regular.ttf"):
        try:
            return ImageFont.truetype(name, px)
        except OSError:
            continue
    return ImageFont.load_default()


def build_sheet(fg, bg, mono, main, play):
    comp = bg.convert("RGBA")
    comp.alpha_composite(fg)
    # Launchers show the centre 72 dp of the 108 dp layer.
    lo, hi = int(LAYER / 2 - VIEW_R), int(LAYER / 2 + VIEW_R)
    view = comp.crop((lo, lo, hi, hi))
    vs = view.size[0]
    cell, pad, label_h = 320, 28, 54
    cols = 5
    W = cols * cell + (cols + 1) * pad
    H = 3 * (cell + label_h) + 4 * pad + 70
    sheet = Image.new("RGB", (W, H), (236, 231, 222))
    d = ImageDraw.Draw(sheet)
    d.text((pad, 18), "Lockwright launcher icon - G12 v2 #01 enamel L (D-50); adaptive 108 dp, safe zone 66 dp", fill=(30, 30, 30), font=font(28))

    def put(img, col, row, caption, bgcol=None):
        x = pad + col * (cell + pad)
        y = 70 + pad + row * (cell + label_h + pad)
        if bgcol is not None:
            d.rectangle((x, y, x + cell - 1, y + cell - 1), fill=bgcol)
        im = img
        if im.size[0] > cell or im.size[0] < cell * 0.5:
            im = im.resize((cell - 20, cell - 20), Image.LANCZOS) if im.size[0] > cell else im
        ox = x + (cell - im.size[0]) // 2
        oy = y + (cell - im.size[1]) // 2
        sheet.paste(im.convert("RGB"), (ox, oy), im.convert("RGBA").split()[3])
        d.text((x, y + cell + 6), caption, fill=(30, 30, 30), font=font(20))

    # Row 0: full layer with guides, then four mask shapes.
    guide = comp.copy()
    gd = ImageDraw.Draw(guide)
    c = LAYER / 2
    gd.rectangle((lo, lo, hi - 1, hi - 1), outline=(80, 200, 255, 255), width=2)
    gd.ellipse((c - SAFE_R, c - SAFE_R, c + SAFE_R, c + SAFE_R), outline=(255, 70, 70, 255), width=2)
    put(guide.resize((300, 300), Image.LANCZOS), 0, 0, "108 dp: view 72 (blue), safe 66 (red)")
    shapes = [("circle", circle_mask(vs)), ("squircle", superellipse_mask(vs)),
              ("rounded square", rounded_mask(vs, 0.18)), ("teardrop", teardrop_mask(vs))]
    for i, (name, m) in enumerate(shapes):
        im = view.copy()
        im.putalpha(m)
        im = im.resize((260, 260), Image.LANCZOS)
        put(im, i + 1, 0, "mask: " + name)

    # Row 1: themed icon (monochrome tinted) light/dark, legacy main, Play 512 with Play mask, iOS mask.
    for i, (bgc, tint, name) in enumerate([((232, 222, 248), (60, 40, 110), "themed (light)"),
                                           ((40, 36, 48), (210, 196, 240), "themed (dark)")]):
        tile = Image.new("RGBA", (LAYER, LAYER), bgc + (255,))
        ink = Image.new("RGBA", (LAYER, LAYER), tint + (255,))
        tile.paste(ink, (0, 0), mono.split()[3])
        t = tile.crop((lo, lo, hi, hi))
        t.putalpha(circle_mask(vs))
        put(t.resize((260, 260), Image.LANCZOS), i, 1, "monochrome " + name, bgcol=(250, 250, 250) if i == 0 else (20, 20, 24))
    put(main, 2, 1, "legacy main_192 (1:1)")
    p = play.convert("RGBA")
    p.putalpha(rounded_mask(512, 0.20))
    put(p.resize((280, 280), Image.LANCZOS), 3, 1, "Play 512 (Play mask 20%)")
    ios = play.convert("RGBA").resize((280, 280), Image.LANCZOS)
    ios.putalpha(superellipse_mask(280))
    put(ios, 4, 1, "iOS (squircle)")

    # Row 2: real launcher sizes on a wallpaper-ish strip, circle mask: 48 dp at mdpi..xxxhdpi.
    x0 = pad
    y0 = 70 + pad + 2 * (cell + label_h + pad)
    d.rectangle((x0, y0, W - pad, y0 + cell), fill=(58, 74, 66))
    x = x0 + 30
    for px in (192, 144, 96, 72, 48, 36):
        for m in (circle_mask, superellipse_mask):
            im = view.resize((px, px), Image.LANCZOS)
            im.putalpha(m(px))
            sheet.paste(im.convert("RGB"), (x, y0 + (cell - px) // 2), im.split()[3])
            x += px + 18
    d.text((x0, y0 + cell + 6), "launcher sizes 192/144/96/72/48/36 px (circle + squircle), label below icon: \"Lockwright\"", fill=(30, 30, 30), font=font(20))
    return sheet


def check(outputs):
    ok = True
    fg = Image.open(outputs["fg"])
    a = np.array(fg)[:, :, 3]
    r_any, r_solid = max_radius(a, ALPHA_ANY), max_radius(a, ALPHA_SOLID)
    print("foreground: max radius %.1f px (shadow incl.), plate %.1f px, safe zone %.1f px" % (r_any, r_solid, SAFE_R))
    if r_any > SAFE_R:
        print("ERROR: foreground leaves the 66 dp safe zone"); ok = False
    expect = {"fg": ((432, 432), "RGBA"), "bg": ((432, 432), "RGB"), "mono": ((432, 432), "RGBA"),
              "main": ((192, 192), "RGBA"), "ios": ((1024, 1024), "RGB"), "play": ((512, 512), "RGB"),
              "window": ((128, 128), "RGBA")}
    for k, (size, mode) in expect.items():
        im = Image.open(outputs[k])
        if im.size != size or im.mode != mode:
            print("ERROR: %s is %s %s, expected %s %s" % (outputs[k], im.size, im.mode, size, mode)); ok = False
    play_bytes = os.path.getsize(outputs["play"])
    print("play icon: %d bytes (limit 1 MiB)" % play_bytes)
    if play_bytes > 1024 * 1024:
        print("ERROR: Play icon over 1 MiB"); ok = False
    return ok


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true")
    args = ap.parse_args()
    if args.check:
        sys.exit(0 if check(OUT) else 1)
    for p in OUT.values():
        os.makedirs(os.path.dirname(p), exist_ok=True)

    ios = Image.open(SRC_IOS).convert("RGB")
    src_fg = Image.open(SRC_FG).convert("RGBA")
    bg = Image.open(SRC_BG).convert("RGB")

    fg, scale = build_foreground(src_fg)
    mono, letter_frac, plate_frac = build_monochrome(fg)
    print("foreground scale %.3f; monochrome plate %.1f%%, letter %.1f%% of layer" % (scale, plate_frac * 100, letter_frac * 100))

    main_icon = ios.resize((192, 192), Image.LANCZOS).convert("RGBA")
    main_icon.putalpha(rounded_mask(192, 0.18))
    window = ios.resize((128, 128), Image.LANCZOS).convert("RGBA")
    window.putalpha(rounded_mask(128, 0.18))
    play = ios.resize((512, 512), Image.LANCZOS)

    fg.save(OUT["fg"], optimize=True)
    bg.save(OUT["bg"], optimize=True)
    mono.save(OUT["mono"], optimize=True)
    main_icon.save(OUT["main"], optimize=True)
    window.save(OUT["window"], optimize=True)
    ios.save(OUT["ios"], optimize=True)
    play.save(OUT["play"], optimize=True)
    build_sheet(fg, bg, mono, main_icon, play).save(OUT["sheet"], optimize=True)
    sys.exit(0 if check(OUT) else 1)


if __name__ == "__main__":
    main()
