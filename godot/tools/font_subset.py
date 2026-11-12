"""Cut Noto Sans JP / SC down to the characters the ja and zh_CN columns of i18n/text.csv use, as woff2, into fonts/noto.

Run it after the table changes:  py -3.13 tools/font_subset.py <folder with the full fonts>
The full fonts (OFL 1.1) are NotoSansJP-Regular.otf and NotoSansSC-Regular.otf from
https://github.com/notofonts/noto-cjk (Sans/SubsetOTF/JP and SC); the sizes above are the 2026-11 downloads, with its LICENSE as LICENSE.txt.
They are 4.6 MB and 8 MB, so they stay out of the repository; the subsets are about 0.5 MB each.
"""
import csv, io, shutil, sys
from pathlib import Path
from fontTools import subset

ROOT = Path(__file__).resolve().parent.parent
DL = Path(sys.argv[1])
rows = list(csv.reader(io.StringIO((ROOT / "i18n" / "text.csv").read_text(encoding="utf-8"))))
head = rows[0]
chars = set("日本語简体中文English한국어" + "、。，．・：；？！「」『』（）【】〜ー…—＋－％／0123456789")
for r in rows[1:]:
    for lang in ("ja", "zh_CN"):
        chars |= set(r[head.index(lang)])
chars = {c for c in chars if ord(c) > 0x7F and not ("가" <= c <= "힣")}
text = "".join(sorted(chars))
out = ROOT / "fonts" / "noto"
out.mkdir(parents=True, exist_ok=True)
for name in ("NotoSansJP", "NotoSansSC"):
    opts = subset.Options()
    opts.flavor = "woff2"
    opts.layout_features = ["*"]
    opts.name_IDs = ["*"]
    f = subset.load_font(str(DL / f"{name}-Regular.otf"), opts)
    s = subset.Subsetter(opts)
    s.populate(text=text)
    s.subset(f)
    dst = out / f"{name}.sub.woff2"
    subset.save_font(f, str(dst), opts)
    print(dst, dst.stat().st_size // 1024, "KB")
shutil.copy(DL / "LICENSE.txt", out / "LICENSE.txt")
print(len(text), "characters")
