"""Sora's away-diagonal walk rows: frames 2 and 3 get frames 0 and 1 with the legs mirrored, so the feet alternate.
Usage: python tools/sora_legs.py <sheet> <out> <k>   (k = cell width / 72: 1 for art/sora/px96/sora-v3-diag.png,
2.6667 for art/sora/sora-v3-diag.png; the owner, 2026-10-28: "2시 방향으로 걸을 때 언제나 왼발이 앞으로", 10시
방향은 오른발). Frames 0 and 1 of the sheet are read, so it can run again on its own output.
v0.1.73 (the owner, 2026-10-29: "2시 방향으로 걸을 떄, 언제나 왼발이 앞에 있어"): the first pass mirrored the legs about
their own middle from mid-thigh down, so the stepping boot hardly moved (4 px). Now the box starts right under the skirt
hem and turns about the hip (the skirt's middle), so the boot moves to the other side of the body (8 px)."""
import sys
from PIL import Image
src, out, k = sys.argv[1], sys.argv[2], float(sys.argv[3])
im = Image.open(src).convert("RGBA")
cw, ch = im.width // 4, im.height // 4
# per row (72x96 cell units): the hip column (the skirt's middle), the half width that holds both legs but not the
# skirt's hanging ribbons, and the first row under the hem
ROWS = {2: (41.5, 12, 68), 3: (32.5, 10, 68)}
for r, (mid, half, y_top) in ROWS.items():
    x0, x1 = round((mid - half) * k), round((mid + half) * k)
    y0 = round(y_top * k)
    for src_f, dst_f in ((0, 2), (1, 3)):
        a = im.crop((src_f * cw, r * ch, (src_f + 1) * cw, (r + 1) * ch))
        nb = a.copy() # the whole source frame, then its legs turned about the hip
        legs = a.crop((x0, y0, x1, ch)).transpose(Image.FLIP_LEFT_RIGHT)
        nb.paste((0, 0, 0, 0), (x0, y0, x1, ch))
        nb.alpha_composite(legs, (x0, y0))
        im.paste(nb, (dst_f * cw, r * ch))
im.save(out)
print(out, im.size)
