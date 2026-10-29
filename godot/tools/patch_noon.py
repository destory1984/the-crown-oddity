import re, sys, pathlib
v, line = sys.argv[1], sys.argv[2]
add = int(sys.argv[3]) if len(sys.argv) > 3 else 1
main = pathlib.Path("C:/_c/test1/wilds_godot/main.gd")
s = main.read_text(encoding="utf-8")
head = '\t"2026-10-28 낮",\n'
anchor = '\t"2026-10-28 새벽",\n'
if head not in s:
    s = s.replace(anchor, head + anchor, 1)
s = s.replace(head, head + f'\t"· {v}: {line}",\n', 1)
main.write_text(s, encoding="utf-8", newline="\n")
md = pathlib.Path("C:/_c/test1/rpg_demo/CHANGES.md")
t = md.read_text(encoding="utf-8")
if "### 2026-10-28 낮" not in t:
    t = t.replace("### 2026-10-28 새벽\n", "### 2026-10-28 낮\n\n### 2026-10-28 새벽\n", 1)
t = t.replace("### 2026-10-28 낮\n", f"### 2026-10-28 낮\n- {v}: {line}\n", 1)
t = re.sub(r"모두 (\d+)가지", lambda m: f"모두 {int(m[1]) + add}가지", t, count=1)
t = t.replace(f"- {v}: {line}\n\n### 2026-10-27", f"- {v}: {line}\n\n### 2026-10-27")
md.write_text(t, encoding="utf-8", newline="\n")
print("ok", re.search(r"모두 \d+가지", t)[0])
