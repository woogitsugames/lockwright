#!/usr/bin/env python3
"""N-60: blank enamel plates for initials and UI buttons.

Erases the printed number from G01 plates with OpenCV inpainting (TELEA) and
writes the results next to the source plates:
  plate_02.png (cream, black digits) -> plate_blank.png
It also writes a tight, downscaled 3x nine-patch source for buttons:
  game/assets/ui/plate_button.png
Usage: python3 data/tools/ui_plate_blank.py
"""
import pathlib
import cv2
import numpy as np

ROOT = pathlib.Path(__file__).resolve().parents[2]
PLATES = ROOT / "game/assets/ui/gpt/plates"
UI = ROOT / "game/assets/ui"


def blank(src: str, dst: str, dark_digit: bool) -> np.ndarray:
    img = cv2.imread(str(PLATES / src), cv2.IMREAD_UNCHANGED)
    bgr, alpha = img[:, :, :3], img[:, :, 3]
    h, w = alpha.shape
    gray = cv2.cvtColor(bgr, cv2.COLOR_BGR2GRAY)
    # the number sits in the middle third of the plate, between the screws
    region = np.zeros_like(gray)
    ys, xs = np.where(alpha > 200)
    x0, x1, y0, y1 = xs.min(), xs.max(), ys.min(), ys.max()
    pw, ph = x1 - x0, y1 - y0
    region[y0 + int(ph * 0.12): y1 - int(ph * 0.12), x0 + int(pw * 0.17): x1 - int(pw * 0.17)] = 255
    # anything that differs from the enamel's own tone is print (incl. anti-aliased edges)
    enamel = float(np.median(gray[region > 0]))
    if dark_digit:
        ink = (gray < enamel - 22).astype(np.uint8) * 255
    else:
        ink = (gray > enamel + 70).astype(np.uint8) * 255
    mask = cv2.bitwise_and(ink, region)
    mask = cv2.dilate(mask, np.ones((9, 9), np.uint8), iterations=4)
    out = cv2.inpaint(bgr, mask, 12, cv2.INPAINT_TELEA)
    # break up the smooth inpaint with the plate's own grain
    noise = cv2.GaussianBlur(np.random.default_rng(7).normal(0, 4, (h, w)).astype(np.float32), (0, 0), 1.2)
    soft = cv2.GaussianBlur(mask, (0, 0), 6).astype(np.float32) / 255.0
    out = np.clip(out.astype(np.float32) + (noise * soft)[:, :, None], 0, 255).astype(np.uint8)
    res = np.dstack([out, alpha])
    cv2.imwrite(str(PLATES / dst), res)
    return res[y0:y1 + 1, x0:x1 + 1]


def button_source(plate: np.ndarray, dst: str) -> None:
    # 3x source for a NinePatchRect drawn at scale 1/3 (crisp on 2.6x phones)
    h, w = plate.shape[:2]
    target_h = 64 * 3
    scale = target_h / h
    small = cv2.resize(plate, (int(w * scale), target_h), interpolation=cv2.INTER_AREA)
    cv2.imwrite(str(UI / dst), small)


if __name__ == "__main__":
    cream = blank("plate_02.png", "plate_blank.png", dark_digit=True)
    button_source(cream, "plate_button.png")
    print("ok")
