"""Breathing sheets: four frames of a standing picture with the upper body eased down.

Usage: python breath.py <sheet.png> <frame_w> <neck_row> <waist_row> <out.png> [d0,d1,d2,d3]
Rows above the neck move down by d px, rows between the neck and the waist by a share that falls to 0 at the waist,
rows below the waist stay. Nearest rows only, so the pixel art stays crisp.
"""
import sys
from PIL import Image

src, fw, neck, waist, out = sys.argv[1], int(sys.argv[2]), int(sys.argv[3]), int(sys.argv[4]), sys.argv[5]
ds = [int(v) for v in (sys.argv[6] if len(sys.argv) > 6 else "0,2,3,2").split(",")]
im = Image.open(src).convert("RGBA")
f = im.crop((0, 0, fw, im.height))
sheet = Image.new("RGBA", (fw * len(ds), im.height), (0, 0, 0, 0))
for i, d in enumerate(ds):
    fr = Image.new("RGBA", f.size, (0, 0, 0, 0))
    for y in range(f.height):
        if y >= waist:
            s = 0
        elif y <= neck + d:
            s = d
        else:
            s = round(d * (waist - y) / (waist - neck - d))
        sy = y - s
        if 0 <= sy < f.height:
            fr.paste(f.crop((0, sy, fw, sy + 1)), (0, y))
    sheet.paste(fr, (i * fw, 0))
sheet.save(out)
print(out, sheet.size)
