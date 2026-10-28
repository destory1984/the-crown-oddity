"""Sora's away-diagonal walk rows: frames 2 and 3 get frames 0 and 1 with the legs mirrored, so the feet alternate.
Usage: python tools/sora_legs.py <sheet> <out> 1   (the 96 px sheet art/sora/px96/sora-v3-diag.png; the owner, 2026-10-28:
"2시 방향으로 걸을 때 언제나 왼발이 앞으로", 10시 방향은 오른발)"""
import sys
from PIL import Image
src, out, k = sys.argv[1], sys.argv[2], float(sys.argv[3])
im = Image.open(src).convert("RGBA")
cw, ch = im.width // 4, im.height // 4
# per row: the legs' middle column and the box (96 px cell units)
ROWS = {2: 41.0, 3: 30.5}
Y0, HALF = 72, 10
for r, mid in ROWS.items():
    for src_f, dst_f in ((0, 2), (1, 3)):
        a = im.crop((src_f * cw, r * ch, (src_f + 1) * cw, (r + 1) * ch))
        b = im.crop((dst_f * cw, r * ch, (dst_f + 1) * cw, (r + 1) * ch))
        x0, x1 = round((mid - HALF) * k), round((mid + HALF) * k)
        y0 = round(Y0 * k)
        nb = a.copy() # the whole source frame, then its legs mirrored about the middle column
        legs = a.crop((x0, y0, x1, ch)).transpose(Image.FLIP_LEFT_RIGHT)
        nb.paste((0, 0, 0, 0), (x0, y0, x1, ch))
        nb.alpha_composite(legs, (round(2 * mid * k) - x1, y0))
        im.paste(nb, (dst_f * cw, r * ch))
im.save(out)
print(out, im.size)
