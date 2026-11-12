"""Make the YouTube Shorts promo (plan A, "자동 전투 없음") from recorded game clips.

  python tools/shorts.py record [clip ...]   record clips with Godot's Movie Maker into shots/reel/<clip>/
  python tools/shorts.py compose [tune[@s] ...] put them into shots/shorts/crown_a_<tune>.mp4 (1080x1920, 30 fps), tune = audio/bgm/<tune>.ogg

The game drives itself during a recording (tools/reel.gd, started by --reel=<clip>).
A clip's first 1.5 s (the title fading out) is cut.
"""
import json
import os
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
REEL = ROOT / "shots" / "reel"
OUT = ROOT / "shots" / "shorts"
GODOT = Path(os.environ.get("GODOT_DIR", Path.home() / "Downloads" / "Godot_v4.7.2-stable_win64")) / "Godot_v4.7.2-stable_win64_console.exe"
FPS = 30
LEAD = 1.5  # seconds cut from the front of every clip

CLIPS = {"rush": "wolves", "parry": "boss", "skills": "wolves", "king_down": "boss", "title": "title"}

# (clip, start s after LEAD, length s, top caption); the parry shot is slowed around the flash guard
CUTS = [
    ("rush", 0.0, 2.0, "자동 전투 없는|클래식 액션 RPG"),
    ("rush", 2.0, 6.0, "직접 베고, 구르고, 막는다"),
    ("parry", None, 6.0, "맞기 직전에 누르면 패링"),
    ("skills", 0.0, 6.0, "회오리, 불씨탄, 빛파동"),
    ("king_down", 0.0, 5.0, "광고 0, 결제 0"),
    ("title", 0.5, 3.0, "Google Play에서 무료"),
]
CAPTION_FONT = REEL / "jua.ttf"  # the game's title font (fonts/jua, OFL), unpacked from woff2
BAR_FONT = Path("C:/Windows/Fonts/malgunbd.ttf")
BAR_TEXT = "Google Play · The Crown Oddity"


def ff(*args):
    subprocess.run(["ffmpeg", "-loglevel", "error", "-y", *args], check=True)


def record(names):
    REEL.mkdir(parents=True, exist_ok=True)
    for name in names or list(CLIPS):
        d = REEL / name
        d.mkdir(exist_ok=True)
        for f in d.glob("f*.png"):
            f.unlink()
        p = subprocess.run([str(GODOT), "--path", str(ROOT), "--write-movie", str(d / "f.png"), "--fixed-fps", str(FPS),
                            "--resolution", "1600x900", "--", f"--scene={CLIPS[name]}", f"--reel={name}"],
                           capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=900)
        flashes = [float(x) for x in re.findall(r"REEL_FLASH ([\d.]+)", p.stdout)]
        info = {"flashes": flashes, "frames": len(list(d.glob("f*.png")))}
        (d / "info.json").write_text(json.dumps(info))
        print(name, info, (re.findall(r"REEL \S+ .*", p.stdout) or [""])[0])


def esc(s):
    return s.replace("\\", "\\\\").replace(":", "\\:").replace("'", "\\'").replace(",", "\\,")


def font(p):
    return p.as_posix().replace(":", "\\:")


def caption_text(caption):
    """Top caption; "|" breaks it into lines, centred above the game picture."""
    lines = caption.split("|")
    out = ""
    for k, line in enumerate(lines):
        y = 470 - (len(lines) - 1) * 55 + k * 110
        out += (f"drawtext=fontfile='{font(CAPTION_FONT)}':text='{esc(line)}':fontsize=88:fontcolor=white:"
                f"borderw=6:bordercolor=0x101418:x=(w-text_w)/2:y={y}-text_h/2,")
    return out


def segment(i, clip, start, length, caption):
    d = REEL / clip
    info = json.loads((d / "info.json").read_text())
    slow = None
    if start is None:  # parry: 2 s before the flash, the 1 s around it at half speed, then the counter
        fl = (info["flashes"] or [LEAD + 3.0])[0] - LEAD
        start = max(0.0, fl - 2.0)
        slow = (fl - 0.4 - start, fl + 0.6 - start)
    src = ["-framerate", str(FPS), "-start_number", str(int((LEAD + start) * FPS)), "-i", str(d / "f%08d.png"),
           "-ss", str(LEAD + start), "-i", str(d / "f.wav")]
    vf = []
    af = []
    if slow:
        a, b = slow
        vf.append(f"[0:v]split=3[v1][v2][v3];[v1]trim=0:{a},setpts=PTS-STARTPTS[p1];"
                  f"[v2]trim={a}:{b},setpts=2*(PTS-STARTPTS)[p2];[v3]trim={b},setpts=PTS-STARTPTS[p3];"
                  f"[p1][p2][p3]concat=n=3:v=1:a=0,trim=0:{length},setpts=PTS-STARTPTS[g]")
        af.append(f"[1:a]asplit=3[a1][a2][a3];[a1]atrim=0:{a},asetpts=PTS-STARTPTS[q1];"
                  f"[a2]atrim={a}:{b},asetpts=PTS-STARTPTS,atempo=0.5[q2];[a3]atrim={b},asetpts=PTS-STARTPTS[q3];"
                  f"[q1][q2][q3]concat=n=3:v=0:a=1,atrim=0:{length},asetpts=PTS-STARTPTS[a]")
    else:
        vf.append(f"[0:v]trim=0:{length},setpts=PTS-STARTPTS[g]")
        af.append(f"[1:a]atrim=0:{length},asetpts=PTS-STARTPTS[a]")
    vf.append("[g]scale=1080:608:flags=lanczos[s];color=c=0x101418:s=1080x1920:r=30[bg];"
              "[bg][s]overlay=0:656:shortest=1,"
              + caption_text(caption) +
              f"drawtext=fontfile='{font(BAR_FONT)}':text='{esc(BAR_TEXT)}':fontsize=42:fontcolor=0xf2c94c:"
              f"x=(w-text_w)/2:y=1450,format=yuv420p[v]")
    out = OUT / f"seg{i}.mp4"
    ff(*src, "-filter_complex", ";".join(vf + af), "-map", "[v]", "-map", "[a]", "-t", str(length),
       "-c:v", "libx264", "-crf", "21", "-preset", "medium", "-r", str(FPS), "-c:a", "aac", "-b:a", "192k", "-ar", "48000", str(out))
    return out


def compose(tunes):
    """One tune under the whole reel (the clips carry only sound effects); one video per tune."""
    OUT.mkdir(parents=True, exist_ok=True)
    segs = [segment(i, *c) for i, c in enumerate(CUTS)]
    lst = OUT / "list.txt"
    lst.write_text("".join(f"file '{s.as_posix()}'\n" for s in segs))
    joined = OUT / "joined.mp4"
    ff("-f", "concat", "-safe", "0", "-i", str(lst), "-c", "copy", str(joined))
    total = sum(c[2] for c in CUTS)
    for tune in tunes or ["title"]:
        tune, _, at = tune.partition("@")  # "song.mp3@1.0" starts the tune 1.0 s in (past a silent lead-in)
        at = float(at or 0)
        music = Path(tune) if Path(tune).is_file() else ROOT / "audio" / "bgm" / f"{tune}.ogg"  # a game tune or any audio file
        final = OUT / f"crown_a_{music.stem}.mp4"
        # bring the tune's first stretch to a mean of -13 dB (the game tunes sit at -17, mastered songs near -14)
        vd = subprocess.run(["ffmpeg", "-hide_banner", "-ss", str(at), "-t", str(total), "-i", str(music), "-af", "volumedetect", "-vn", "-f", "null", "-"],
                            capture_output=True, text=True, encoding="utf-8", errors="replace").stderr
        mean = float(re.search(r"mean_volume: (-?[\d.]+)", vd).group(1))
        ff("-i", str(joined), "-ss", str(at), "-i", str(music), "-filter_complex",
           f"[1:a]atrim=0:{total},asetpts=PTS-STARTPTS,afade=t=in:d=0.3,afade=t=out:st={total - 1.5}:d=1.5,volume={-13 - mean:.1f}dB[m];"
           f"[0:a]volume=0.8[s];[s][m]amix=inputs=2:duration=first:normalize=0,alimiter=limit=0.89[a]",
           "-map", "0:v", "-map", "[a]", "-c:v", "copy", "-c:a", "aac", "-b:a", "192k", "-movflags", "+faststart", str(final))
        print(final)


if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else ""
    if cmd == "record":
        record(sys.argv[2:])
    elif cmd == "compose":
        compose(sys.argv[2:])
    else:
        print(__doc__)
