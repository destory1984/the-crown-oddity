"""Story picture 15 from the game: the scene old_picture (the eight moonkeepers of a hundred years ago at the
clock room's key) cropped square round the key and aged into the faded painting Sora finds in the cupboard.

    python tools/dev.py shot old_picture
    python tools/old_picture.py            -> art/story/15_old_picture.jpg (512 x 512)
"""
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
SHOT = ROOT / "shots" / "old_picture.png"
OUT = ROOT / "art" / "story" / "15_old_picture.jpg"
CROP = (620, 10, 1180, 570)  # the key and all eight, square
SIZE = 512


def age(im: Image.Image, seed: int = 15) -> Image.Image:
    rnd = np.random.default_rng(seed)
    a = np.asarray(im.convert("RGB")).astype(np.float32) / 255.0
    # faded: less saturation and contrast, lifted blacks, a warm yellow cast
    grey = a.mean(axis=2, keepdims=True)
    a = grey + (a - grey) * 0.62
    a = 0.16 + a * 0.74
    a *= np.array([1.06, 0.98, 0.80])
    # paper: fine grain and a few soft worn blotches
    h, w = a.shape[:2]
    a += rnd.normal(0, 0.025, (h, w, 1))
    blot = Image.new("L", (w, h), 0)
    d = ImageDraw.Draw(blot)
    for _ in range(9):
        x, y, r = rnd.uniform(0, w), rnd.uniform(0, h), rnd.uniform(10, 38)
        d.ellipse((x - r, y - r, x + r, y + r), fill=int(rnd.uniform(40, 90)))
    blot = np.asarray(blot.filter(ImageFilter.GaussianBlur(14))).astype(np.float32)[..., None] / 255.0
    a = a * (1 - blot) + np.array([0.86, 0.80, 0.62]) * blot
    # two creases: a thin light line with a dark side
    cr = Image.new("L", (w, h), 0)
    d = ImageDraw.Draw(cr)
    d.line((0, h * 0.52, w, h * 0.47), fill=150, width=2)
    d.line((w * 0.36, 0, w * 0.40, h), fill=110, width=2)
    cr = np.asarray(cr.filter(ImageFilter.GaussianBlur(1.2))).astype(np.float32)[..., None] / 255.0
    a = a + cr * 0.22
    # darker, browner edges
    yy, xx = np.mgrid[0:h, 0:w]
    r = np.hypot((xx - w / 2) / (w / 2), (yy - h / 2) / (h / 2))
    v = np.clip((r - 0.55) / 0.85, 0, 1)[..., None]
    a = a * (1 - 0.55 * v) + np.array([0.30, 0.22, 0.12]) * 0.25 * v
    return Image.fromarray((np.clip(a, 0, 1) * 255).astype(np.uint8))


def main() -> int:
    im = Image.open(SHOT).crop(CROP).resize((SIZE, SIZE), Image.LANCZOS)
    age(im).save(OUT, quality=90)
    print(OUT)
    return 0


if __name__ == "__main__":
    sys.exit(main())
