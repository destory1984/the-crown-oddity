# Key the magenta out of the GPT sheets in this folder and write one square 256 px picture per item to art/items/.
# usage: python art/items/src/cut_items.py
import os
import numpy as np
from PIL import Image, ImageChops, ImageFilter
from scipy import ndimage
HERE = os.path.dirname(os.path.abspath(__file__))
SHEETS = {"keep_1": (4, 2, ["firefly", "", "", "acorn", "sprout", "", "", "shoes"]),
	"keep_2": (4, 2, ["oar_ring", "whistle", "knot", "dial", "oil", "", "cushion", "bait"]),
	"keep_3": (3, 3, ["cog", "buckler", "postcard", "", "tea", "cloud", "bookmark", "lamp", "medal"]),
	"keep_4": (3, 2, ["pearl", "lantern13", "ring", "feather", "bori_lamp", "armour"])}
SIDE = 256
PAD = 8
for name, (cols, rows, ids) in SHEETS.items():
	im = Image.open(os.path.join(HERE, name + ".png")).convert("RGB")
	r, g, b = im.split()
	pink = ImageChops.subtract(ImageChops.darker(r, b), g) # min(r, b) - g
	alpha = pink.point(lambda v: 0 if v > 90 else (255 if v <= 12 else 255 - v * 2))
	alpha = alpha.filter(ImageFilter.MinFilter(3)) # one pixel in, the last of the pink edge
	# the fringe keeps its grey, not the pink
	r = Image.composite(g, r, pink.point(lambda v: 255 if v > 12 else 0))
	b = Image.composite(g, b, pink.point(lambda v: 255 if v > 12 else 0))
	im = Image.merge("RGBA", (r, g, b, alpha))
	W, H = im.size
	cw, ch = W / cols, H / rows
	for i, id in enumerate(ids):
		if id == "":
			continue
		c, r0 = i % cols, i // cols
		cell = im.crop((round(c * cw), round(r0 * ch), round((c + 1) * cw), round((r0 + 1) * ch)))
		a = np.array(cell.getchannel("A"))
		spots, n = ndimage.label(a > 40)
		areas = ndimage.sum(a > 40, spots, range(1, n + 1))
		keep = np.isin(spots, [i + 1 for i in range(n) if areas[i] >= areas.max() * 0.02]) # a neighbour's tip poking into this cell goes
		cell.putalpha(Image.fromarray(np.where(ndimage.binary_dilation(keep, iterations=2), a, 0).astype("uint8")))
		part = cell.crop(cell.getchannel("A").getbbox())
		k = (SIDE - 2 * PAD) / max(part.size)
		part = part.resize((max(1, round(part.width * k)), max(1, round(part.height * k))), Image.LANCZOS)
		out = Image.new("RGBA", (SIDE, SIDE))
		out.paste(part, ((SIDE - part.width) // 2, (SIDE - part.height) // 2))
		out.save(os.path.join(HERE, "..", id + ".png"))
