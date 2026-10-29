"""Dev harness for Oddity of the Wilds (Godot 4).

    python tools/dev.py check                 parse every script headless; fail on SCRIPT ERROR
    python tools/dev.py shot [SCENE ...]      screenshot scenes into shots/SCENE.png (default: start)
    python tools/dev.py scenes                list scene names
    python tools/dev.py build                 export the web build to export/web/
    python tools/dev.py ship -m "message"     check, commit here, build, copy build + source into the
                                              site repo and commit there. Never pushes.
    python tools/dev.py ship -m "..." --quick a,b   same, but runs only the named tests, not the full suite; the full
                                              suite then runs before the next push (the owner, 2026-10-30)
    python tools/dev.py kill                  close stray Godot processes
    python tools/dev.py test [NAME]           autoplay tests (tools/autoplay.gd); exit code = failures
    python tools/dev.py sound                 write every effect to shots/sounds/*.wav and print its shape
    python tools/dev.py baseline [SCENE ...]  keep the current shots as the reference for later diffs
    python tools/bgm.py [NAME ...]            re-render the background tunes into audio/bgm/ (needs numpy and ffmpeg)

Paths can be overridden with the GODOT_DIR and SITE_REPO environment variables.
On Linux (cloud sessions) the Godot binary is GODOT_BIN, else GODOT_DIR/Godot_v4.7.2-stable_linux.x86_64
(GODOT_DIR defaults to ~/.cache/godot there). Only check, test, sound and scenes are meant for Linux;
shot, build and ship stay Windows-only.
"""
import argparse
import os
import re
import shutil
import subprocess
import sys
import tarfile
import io
import time
import datetime
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
if os.name == "nt":
    GODOT_DIR = Path(os.environ.get("GODOT_DIR", Path.home() / "Downloads" / "Godot_v4.7.2-stable_win64"))
    GODOT_GUI = GODOT_DIR / "Godot_v4.7.2-stable_win64.exe"
    GODOT_CLI = GODOT_DIR / "Godot_v4.7.2-stable_win64_console.exe"
else:  # Linux cloud sessions: one binary for both
    GODOT_DIR = Path(os.environ.get("GODOT_DIR", Path.home() / ".cache" / "godot"))
    GODOT_GUI = GODOT_CLI = Path(os.environ.get("GODOT_BIN", GODOT_DIR / "Godot_v4.7.2-stable_linux.x86_64"))
SITE = Path(os.environ.get("SITE_REPO", ROOT.parent / "rpg_demo"))
PLAY = Path(os.environ.get("PLAY_DIR", ROOT.parent / "play"))  # the folder the user plays from
SHOTS = ROOT / "shots"
EXPORT = ROOT / "export" / "web"


def run(cmd, timeout=120, cwd=ROOT):
    return subprocess.run(cmd, cwd=cwd, capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=timeout)


def kill():
    """Close every Godot process; a stuck test window blocks the next run."""
    if os.name != "nt":
        pids = run(["pgrep", "-f", str(GODOT_CLI)]).stdout.split()
        for pid in pids:
            run(["kill", "-9", pid])
        return len(pids)
    out = run(["tasklist", "/FO", "CSV", "/NH"]).stdout
    pids = [l.split('","')[1] for l in out.splitlines() if l.lower().startswith('"godot_v4')]
    for pid in pids:
        run(["taskkill", "/PID", pid, "/F"])
    return len(pids)


def import_once():
    """A fresh Linux clone has no .godot/ cache; without it fonts and textures fail to load."""
    if os.name != "nt" and not (ROOT / ".godot" / "imported").exists():
        print("first run: importing assets into .godot/ ...")
        run([str(GODOT_CLI), "--headless", "--path", ".", "--import"], timeout=600)


def check():
    kill()
    import_once()
    tr = run([sys.executable, str(ROOT / "tools" / "i18n.py"), "--check"])
    if tr.returncode:
        print(tr.stdout.strip())
        print("CHECK FAILED")
        return 1
    r = run([str(GODOT_CLI), "--headless", "--path", ".", "--quit-after", "20"], timeout=90)
    errors = [l for l in (r.stdout + r.stderr).splitlines() if "SCRIPT ERROR" in l or "Parse Error" in l or re.search(r"^\s+at: ", l)]
    if errors:
        print("\n".join(errors))
        print("CHECK FAILED")
        return 1
    print("check ok")
    return 0


def scene_names():
    src = (ROOT / "sys" / "scenes.gd").read_text(encoding="utf-8")  # the SCENES table moved out of main.gd
    block = src[src.index("const SCENES := {"):]
    block = block[: block.index("\n}\n")]
    return re.findall(r'^\t"(\w+)":', block, re.M)


def shot(names, extra):
    SHOTS.mkdir(exist_ok=True)
    known = scene_names()
    failed = 0
    for name in names or ["start"]:
        if name not in known:
            print(f"unknown scene {name!r}; known: {', '.join(known)}")
            failed += 1
            continue
        kill()
        out = SHOTS / f"{name}.png"
        out.unlink(missing_ok=True)
        # the GUI exe renders reliably; the console exe sometimes exits before drawing
        p = subprocess.Popen([str(GODOT_GUI), "--audio-driver", "Dummy", "--path", ".", "--", f"--scene={name}", f"--shot={out.as_posix()}", *extra],
                             cwd=ROOT, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        deadline = time.time() + 45
        while time.time() < deadline and not out.exists():
            time.sleep(0.5)
        time.sleep(0.5)
        if p.poll() is None:
            p.kill()
        if out.exists():
            ref = BASE / out.name
            note = f"  diff vs baseline {diff_pct(ref, out):.1f}%" if ref.exists() else ""
            print(f"shot {out}{note}")
        else:
            print(f"shot FAILED for {name}")
            failed += 1
    kill()
    return 1 if failed else 0


BASE = SHOTS / "baseline"


def diff_pct(a, b):
    """Mean per-channel difference between two screenshots, 0-100."""
    from PIL import Image, ImageChops, ImageStat
    x, y = Image.open(a).convert("RGB"), Image.open(b).convert("RGB")
    if x.size != y.size:
        y = y.resize(x.size)
    return sum(ImageStat.Stat(ImageChops.difference(x, y)).mean) / 3 / 255 * 100


def baseline(names):
    BASE.mkdir(parents=True, exist_ok=True)
    for f in (SHOTS / f"{n}.png" for n in names) if names else SHOTS.glob("*.png"):
        if f.exists():
            shutil.copy2(f, BASE / f.name)
            print(f"baseline {f.name}")
    return 0


def test(name):
    kill()
    import_once()
    try:
        r = run([str(GODOT_CLI), "--headless", "--path", ".", "--", f"--test={name or 'all'}"], timeout=1500 if os.name == "nt" else 1800)  # the cloud box is slower; 182 tests take a bit over 600 s on the PC
    except subprocess.TimeoutExpired:
        kill()
        print("TESTS TIMED OUT (a script error usually stops the runner; run check, or read the Godot log)")
        return 1
    lines = [l for l in (r.stdout + r.stderr).splitlines() if l.startswith(("TEST", "SCRIPT ERROR"))]
    print("\n".join(lines) or (r.stdout + r.stderr)[-2000:])
    return r.returncode


def sound():
    kill()
    out = (SHOTS / "sounds").resolve()
    r = run([str(GODOT_CLI), "--headless", "--path", ".", "--", f"--sounds={out.as_posix()}"], timeout=120)
    print("\n".join(l for l in r.stdout.splitlines() if l.startswith("SOUND")))
    print(f"wav files in {out}")
    print("zcr = zero crossings per sample; above about 0.15 sounds hissy")
    return 0


def build():
    kill()
    if EXPORT.exists():
        shutil.rmtree(EXPORT)
    EXPORT.mkdir(parents=True)
    r = run([str(GODOT_CLI), "--headless", "--path", ".", "--export-release", "Web", str(EXPORT / "index.html")], timeout=400)
    errs = [l for l in (r.stdout + r.stderr).splitlines() if "ERROR" in l]
    if errs or not (EXPORT / "index.wasm").exists():
        print("\n".join(errs) or "export produced no index.wasm")
        print("BUILD FAILED")
        return 1
    size = sum(f.stat().st_size for f in EXPORT.iterdir()) / 1e6
    print(f"build ok ({size:.1f} MB)")
    return 0


def git(args, cwd):
    r = run(["git", *args], cwd=cwd)
    if r.returncode:
        raise SystemExit(f"git {' '.join(args)} failed in {cwd}:\n{r.stdout}{r.stderr}")
    return r.stdout


# Every ship is one feature: raise the last number of application/config/version by one (the user,
# 2026-10-23: "한 가지 기능 추가할 때마다 하나씩 올려", starting at v0.0.1) and stamp the day in Korean time.
def bump_version():
    p = ROOT / "project.godot"
    s = p.read_bytes().decode("utf-8")
    m = re.search(r'config/version="(\d+)\.(\d+)\.(\d+)"', s)
    if not m:
        raise SystemExit("project.godot has no config/version")
    # SHIP_VERSION=0.1.0 sets a milestone version instead of the next patch number (the owner, 2026-10-27: "0.1.0으로 올려볼까")
    v = os.environ.get("SHIP_VERSION") or f"{m[1]}.{m[2]}.{int(m[3]) + 1}"
    day = (datetime.datetime.now(datetime.timezone.utc) + datetime.timedelta(hours=9)).strftime("%Y-%m-%d")
    s = s[:m.start()] + f'config/version="{v}"' + s[m.end():]
    s = re.sub(r'config/updated="[^"]*"', f'config/updated="{day}"', s, count=1)
    p.write_bytes(s.encode("utf-8"))
    print(f"version v{v} ({day})")
    return v


def ship(message, quick=None):
    if quick is not None and not quick:
        print("--quick needs the batch's test names (a,b,c)")
        return 1
    if check() or test(quick):
        print("SHIP STOPPED: fix the failures above first")
        return 1
    v = bump_version()
    message = f"v{v}: {message}"
    if git(["status", "--porcelain"], ROOT).strip():
        git(["add", "-A"], ROOT)
        git(["commit", "-qm", message + "\n\nCo-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"], ROOT)
    if build():
        return 1
    # web build at the site root
    for f in EXPORT.iterdir():
        if f.suffix == ".import":
            continue
        try:
            shutil.copy2(f, SITE / f.name)
        except PermissionError:
            raise SystemExit(f"{SITE / f.name} is locked; stop the preview server that serves the site folder and retry")
    # the picture shown when the page link is shared (og:image in export_presets.cfg head_include)
    shutil.copy2(ROOT / "art" / "ui" / "portrait.png", SITE / "og.png")
    # project source under godot/, exactly what is committed here
    dst = SITE / "godot"
    # a folder held open (an Explorer window on godot/art/story) cannot be removed: drop what can go and write over the rest
    shutil.rmtree(dst, ignore_errors=True)
    dst.mkdir(exist_ok=True)
    archive = subprocess.run(["git", "archive", "HEAD"], cwd=ROOT, capture_output=True, check=True).stdout
    tarfile.open(fileobj=io.BytesIO(archive)).extractall(dst, filter="data")
    (dst / "LICENSE").unlink(missing_ok=True)  # the site repo has its own LICENSE
    git(["add", "-A"], SITE)
    if git(["status", "--porcelain"], SITE).strip():
        git(["commit", "-qm", message + "\n\nCo-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"], SITE)
    # refresh the user's play folder with the shipped build (user asked for this on every ship)
    if PLAY.exists():
        arch = subprocess.run(["git", "archive", "HEAD"], cwd=SITE, capture_output=True, check=True).stdout
        tarfile.open(fileobj=io.BytesIO(arch)).extractall(PLAY, filter="data")
        print(f"play folder refreshed: {PLAY}")
    print("shipped:", git(["log", "--oneline", "-1"], ROOT).strip(), "|", git(["log", "--oneline", "-1"], SITE).strip())
    print("not pushed; push only when asked")
    return 0


def main():
    # test lines carry U+2060 word joiners (Ko.keep_words); a Korean Windows console (cp949) cannot print them
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("cmd", choices=["check", "shot", "scenes", "build", "ship", "kill", "test", "sound", "baseline"])
    ap.add_argument("names", nargs="*")
    ap.add_argument("-m", "--message")
    ap.add_argument("--hour")
    ap.add_argument("--pseudo", action="store_true", help="shot: pseudo-translate text to spot strings missing from i18n/text.csv")
    ap.add_argument("--day")
    ap.add_argument("--quick", help="ship: run only these tests (comma list) instead of the full suite")
    a = ap.parse_args()
    if a.cmd == "kill":
        print(f"closed {kill()} Godot process(es)")
        return 0
    if a.cmd == "check":
        return check()
    if a.cmd == "scenes":
        print("\n".join(scene_names()))
        return 0
    if a.cmd == "shot":
        extra = [f"--hour={a.hour}"] * bool(a.hour) + [f"--day={a.day}"] * bool(a.day) + ["--pseudo"] * a.pseudo
        return shot(a.names, extra)
    if a.cmd == "test":
        return test(a.names[0] if a.names else None)
    if a.cmd == "sound":
        return sound()
    if a.cmd == "baseline":
        return baseline(a.names)
    if a.cmd == "build":
        return build()
    if a.cmd == "ship":
        if not a.message:
            ap.error("ship needs -m MESSAGE")
        return ship(a.message, a.quick)


if __name__ == "__main__":
    sys.exit(main())
