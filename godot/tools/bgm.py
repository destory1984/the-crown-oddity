"""The Crown Oddity background music, synthesised from code (no recordings).

Two families, as the user chose (2026-10-25):
- FM rock (late-80s PC-88 action-RPG manner, original melodies) for fields, dungeons and bosses:
  2-operator FM lead and slap bass, square-wave 16th arpeggios, FM brass stabs, noise drums.
- slow lyrical pieces for the title, the village, night and the ending.

Every track is one seamless loop. Run: python tools/bgm.py [names...]
Every place has five tunes (the owner, 2026-10-27): <slot>.ogg and <slot>_2 .. <slot>_5.ogg; the five village tunes are
the Lantern Village set (music-box twinkles for the lamp flames). Writes audio/bgm/<name>.wav, then ffmpeg turns each
into a mono 48 kbps <name>.ogg if ffmpeg is on PATH (45 tunes, about 12 MB)."""
import os
import shutil
import subprocess
import sys
import wave
from pathlib import Path

import numpy as np

SR = 32000
OUT = Path(__file__).resolve().parent.parent / "audio" / "bgm"


def hz(n):
    return 440.0 * 2 ** ((n - 69) / 12)


def env(n, a, d, s, r):
    e = np.ones(n) * s
    a = max(1, min(int(a * SR), n)); e[:a] = np.linspace(0, 1, a)
    d = min(int(d * SR), n - a); e[a:a + d] = np.linspace(1, s, d)
    r = min(int(r * SR), n)
    if r > 0:
        e[-r:] *= np.linspace(1, 0, r)
    return e


class Track:
    """A loop of `bars` 4/4 bars; add() wraps sound that runs past the end back to the start."""

    def __init__(self, bpm, bars, seed, bpb=4):
        self.beat = 60.0 / bpm; self.bpb = bpb
        self.n = int(bars * bpb * self.beat * SR)
        self.L = np.zeros(self.n); self.R = np.zeros(self.n)
        self.rng = np.random.default_rng(seed)

    def add(self, sig, start, pan=0.0, gain=1.0):
        i = int(start * SR) % self.n; pos = 0
        gl, gr = gain * (1 - pan) * 0.707, gain * (1 + pan) * 0.707
        while pos < len(sig):
            j = (i + pos) % self.n; k = min(len(sig) - pos, self.n - j)
            self.L[j:j + k] += sig[pos:pos + k] * gl; self.R[j:j + k] += sig[pos:pos + k] * gr
            pos += k

    def save(self, name, drive=1.4):
        mix = np.stack([self.L, self.R], 1)
        mix = np.tanh(mix / np.max(np.abs(mix)) * drive) / np.tanh(drive) * 0.85
        mono = (mix[:, 0] + mix[:, 1]) * 0.7071  # what ffmpeg -ac 1 makes of it
        rms_db = 20 * np.log10(np.sqrt(np.mean(mono ** 2)) + 1e-9)
        g = min(10 ** ((-17.0 - rms_db) / 20), 0.65 / np.max(np.abs(mono)))  # mono mean about -17 dB, peak at most -3.7 dB
        mix = mix * g
        OUT.mkdir(parents=True, exist_ok=True)
        path = OUT / f"{name}.wav"
        with wave.open(str(path), "wb") as w:
            w.setnchannels(2); w.setsampwidth(2); w.setframerate(SR)
            w.writeframes((mix * 32767).astype(np.int16).tobytes())
        if shutil.which("ffmpeg"):
            subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", str(path), "-ac", "1", "-c:a", "libvorbis", "-b:a", "48k",
                            str(OUT / f"{name}.ogg")], check=True)
            path.unlink()
        print(f"{name}: {self.n / SR:.1f} s")


# ---------------------------------------------------------------- instruments
def fm(f, n, ratio, idx0, idx1, idx_t, vib=0.0):
    t = np.arange(n) / SR
    idx = idx1 + (idx0 - idx1) * np.exp(-t / idx_t)
    fr = f * (1 + vib * np.sin(2 * np.pi * 5.5 * t) * np.clip((t - 0.15) / 0.3, 0, 1))
    ph = 2 * np.pi * np.cumsum(fr) / SR
    return np.sin(ph + idx * np.sin(ph * ratio))


def square(f, n, duty=0.5):
    t = np.arange(n) / SR
    return np.where((t * f) % 1.0 < duty, 1.0, -1.0)


def fm_lead(note, dur):
    n = int(dur * SR)
    v = fm(hz(note), n, 1.0, 3.2, 1.1, 0.12, 0.006) * 0.7 + fm(hz(note) * 1.003, n, 2.0, 1.5, 0.4, 0.2, 0.006) * 0.3
    return v * env(n, 0.008, 0.15, 0.75, 0.06)


def tri(f, n, vib=0.004):
    t = np.arange(n) / SR
    fr = f * (1 + vib * np.sin(2 * np.pi * 5.0 * t) * np.clip((t - 0.2) / 0.4, 0, 1))
    return 2 / np.pi * np.arcsin(np.sin(2 * np.pi * np.cumsum(fr) / SR))


def flute(note, dur, rng):
    n = int(dur * SR)
    sig = tri(hz(note), n) + rng.normal(0, 1, n) * 0.04 * env(n, 0.02, 0.12, 0.3, 0.1)
    return sig * env(n, 0.06, 0.1, 0.8, min(0.3, dur * 0.4))


def accordion(note, dur):
    n = int(dur * SR); t = np.arange(n) / SR
    f = hz(note)
    sig = sum(np.sin(2 * np.pi * f * k * t) / k * 0.85 ** k for k in range(1, 7))
    sig += sum(np.sin(2 * np.pi * f * 1.004 * k * t) / k * 0.85 ** k for k in range(1, 7))  # the reed beat
    return sig * 0.35 * (1 + 0.15 * np.sin(2 * np.pi * 6 * t)) * env(n, 0.04, 0.1, 0.85, min(0.15, dur * 0.3))


def musicbox(note, dur):
    n = int(dur * SR); t = np.arange(n) / SR; f = hz(note)
    sig = np.sin(2 * np.pi * f * t) + 0.35 * np.sin(2 * np.pi * f * 3.01 * t) * np.exp(-t * 6) + 0.2 * np.sin(2 * np.pi * f * 5.4 * t) * np.exp(-t * 12)
    return sig * np.exp(-t * 2.0) * env(n, 0.003, 0, 1, 0.05)


def pluck(note, dur, rng, damp=0.996):
    """A soft nylon-string guitar (the owner, 2026-10-27: the old Karplus-Strong string was harsh and, on a whole-sample
    delay, out of tune up high). Additive: harmonics plucked a fifth of the way along, the upper ones dying faster,
    a hint of string stiffness, a 4 ms attack and a muffled thumb noise. `damp` keeps its old meaning: closer to 1 rings longer."""
    n = int(dur * SR); t = np.arange(n) / SR; f = hz(note)
    r0 = float(np.clip(f * (1 - damp), 0.35, 4.0))  # the fundamental's decay per second, as the old string's
    sig = np.zeros(n)
    for k in range(1, 13):
        fk = k * f * np.sqrt(1 + 1.2e-5 * k * k)
        if fk > SR * 0.4:
            break
        amp = abs(np.sin(k * np.pi * 0.2)) / k ** 1.7
        sig += amp * np.sin(2 * np.pi * fk * t + rng.uniform(0, 2 * np.pi)) * np.exp(-t * r0 * (1 + 0.45 * (k - 1) ** 1.25))
    thump = rng.uniform(-1, 1, min(n, int(0.012 * SR)))
    thump = np.convolve(thump, np.ones(24) / 24, "same") * np.exp(-np.arange(thump.size) / (0.003 * SR)) * 0.25
    sig[:thump.size] += thump
    sig /= np.max(np.abs(sig)) + 1e-9
    return sig * 0.8 * env(n, 0.004, 0, 1, 0.05)


def pad(notes, dur, a=1.0, r=1.0, det=0.12):
    n = int(dur * SR); t = np.arange(n) / SR; sig = np.zeros(n)
    for k, nt in enumerate(notes):
        for d in (-det, det):
            sig += np.sin(2 * np.pi * hz(nt) * (1 + d / 100) * t + k)
    return sig / (len(notes) * 2) * env(n, a, 0.5, 0.9, r)


def strings(notes, dur):
    n = int(dur * SR); t = np.arange(n) / SR; sig = np.zeros(n)
    for nt in notes:
        f = hz(nt)
        for d in (-0.3, 0.0, 0.3):
            ph = 2 * np.pi * f * (1 + d / 100) * t
            sig += sum(np.sin(k * ph) / k for k in range(1, 6))
    return sig / (len(notes) * 9) * env(n, 0.8, 0.5, 0.9, 1.0)


# ---------------------------------------------------------------- FM rock band
def rock_band(tr, chords, tones, kick=(0.0, 2.0, 2.5), fills=(), bass_pat=(0, 0, 12, 0, 7, 0, 12, 10),
              arp=True, stabs=(0.0, 1.5), lead_gain=0.30):
    B = tr.beat
    for bar, ch in enumerate(chords):
        t0 = bar * 4 * B; tn = tones[ch]
        for i, iv in enumerate(bass_pat):
            n = int(B / 2 * SR * 0.9)
            tr.add(fm(hz(tn[0] + iv), n, 1.0, 4.0, 0.8, 0.03) * env(n, 0.003, 0.08, 0.6, 0.03), t0 + i * B / 2, -0.05, 0.30)
        if arp:
            for i in range(16):
                n = int(B / 4 * SR * 0.8)
                tr.add(square(hz(tn[1:][i % 4] + 24), n, 0.25) * env(n, 0.002, 0.05, 0.4, 0.01), t0 + i * B / 4, 0.45 - 0.9 * ((i // 2) % 2), 0.035)
        for st in stabs:
            n = int(B * 0.45 * SR)
            chord = sum(fm(hz(x + 12), n, 1.0, 2.5, 0.8, 0.05) for x in tn[2:])
            tr.add(chord / 3 * env(n, 0.004, 0.1, 0.5, 0.05), t0 + st * B, -0.25, 0.10)
        for i in range(8):
            n = int(0.05 * SR); hh = np.diff(tr.rng.normal(0, 1, n + 1)) * np.exp(-np.arange(n) / SR * 90)
            tr.add(hh, t0 + i * B / 2, 0.3, 0.05 if i % 2 == 0 else 0.03)
        for kb in kick:
            n = int(0.25 * SR); tt = np.arange(n) / SR
            tr.add(np.sin(2 * np.pi * (50 + 110 * np.exp(-tt * 40)) * tt) * np.exp(-tt * 14), t0 + kb * B, 0, 0.45)
        for sb in (1.0, 3.0):
            n = int(0.18 * SR); tt = np.arange(n) / SR
            sn = tr.rng.normal(0, 1, n) * np.exp(-tt * 22) * 0.7 + np.sin(2 * np.pi * 190 * tt) * np.exp(-tt * 30) * 0.5
            tr.add(sn, t0 + sb * B, -0.05, 0.25)
        if bar in fills:
            for k in range(4):
                n = int(0.1 * SR); tt = np.arange(n) / SR
                tr.add(tr.rng.normal(0, 1, n) * np.exp(-tt * 30), t0 + (3 + k / 4) * B, 0.1 * k - 0.15, 0.12 + 0.03 * k)


def play(tr, mel, voice, pan=0.05, gain=0.3, echo=(0.75, 0.22), shift=0, legato=0.97):
    t = 0.0
    for nt, b in mel:
        if nt is not None:
            v = voice(nt + shift, b * tr.beat * legato)
            tr.add(v, t, pan, gain)
            if echo:
                tr.add(v, t + tr.beat * echo[0], -pan * 6 - 0.3, gain * echo[1])
        t += b * tr.beat
    return t


def check(mel, bars, bpb=4):
    total = sum(b for _, b in mel)
    assert abs(total - bars * bpb) < 1e-6, f"melody has {total} beats, needs {bars * bpb}"


# ---------------------------------------------------------------- chords
T = {  # bass root then chord tones
    "Dm": [38, 45, 50, 53, 57], "Bb": [34, 41, 46, 50, 53], "C": [36, 43, 48, 52, 55], "A": [33, 40, 45, 49, 52],
    "Gm": [31, 38, 43, 46, 50], "F": [29, 36, 41, 45, 48], "Em": [40, 47, 52, 55, 59], "D": [38, 45, 50, 54, 57],
    "B": [35, 42, 47, 51, 54], "Am": [33, 40, 45, 48, 52], "Cm": [36, 43, 48, 51, 55], "Ab": [32, 39, 44, 48, 51],
    "G": [31, 38, 43, 47, 50], "Fm": [29, 36, 41, 44, 48], "E": [28, 35, 40, 44, 47],
}


# ---------------------------------------------------------------- tracks
def field_marsh():  # reed marsh, south lake, windy hill: D minor, 140
    ch = ["Dm", "Bb", "C", "Dm", "Dm", "Bb", "C", "A", "Gm", "Bb", "F", "C", "Gm", "Bb", "A", "A",
          "Dm", "Bb", "C", "Dm", "Dm", "Bb", "C", "Dm"]
    A = [(81, 1), (86, 1), (84, .5), (81, .5), (79, .5), (81, .5), (77, 1.5), (79, .5), (81, 1), (82, 1),
         (84, 1.5), (82, .5), (81, .5), (79, .5), (76, 1), (77, .5), (76, .5), (74, 3),
         (81, 1), (86, 1), (88, .5), (89, .5), (88, .5), (86, .5), (84, 1.5), (82, .5), (81, 1), (77, 1),
         (79, .5), (81, .5), (82, .5), (84, .5), (82, 1), (79, 1)]
    Bm = [(86, 2), (82, 1), (79, 1), (89, 2), (86, 1), (82, 1), (84, 1.5), (86, .5), (84, 1), (81, 1),
          (79, 1.5), (81, .5), (82, 1), (84, 1), (86, 1), (91, 1), (89, .5), (86, .5), (82, 1),
          (89, 1.5), (86, .5), (82, 1), (86, 1), (85, 1), (88, 1), (91, 1), (89, .5), (88, .5), (88, 3), (None, 1)]
    mel = A + [(81, 2), (76, 1), (73, 1)] + Bm + A + [(74, 4)]
    check(mel, len(ch)); tr = Track(140, len(ch), 87)
    rock_band(tr, ch, T, fills=(7, 15, 23)); play(tr, mel, fm_lead); tr.save("field_marsh")


def field_wild():  # hardened forest, cloud mound, moon stairs, the last road: E minor, 132
    ch = ["Em", "C", "D", "Em", "Em", "C", "D", "B", "Am", "Em", "C", "D", "Am", "C", "B", "B",
          "Em", "C", "D", "Em", "Em", "C", "D", "Em"]
    A = [(76, 1), (79, .5), (83, .5), (81, 1), (79, 1), (76, 1.5), (79, .5), (76, 1), (72, 1),
         (74, 1), (78, 1), (81, 1), (79, .5), (78, .5), (76, 3), (71, 1),
         (76, 1), (79, .5), (83, .5), (88, 1), (86, .5), (83, .5), (84, 1.5), (83, .5), (79, 1), (76, 1),
         (78, .5), (79, .5), (81, .5), (83, .5), (81, 1), (78, 1)]
    Bm = [(81, 2), (84, 1), (88, 1), (83, 2), (79, 1), (76, 1), (84, 1), (88, 1), (91, 1), (88, .5), (84, .5),
          (86, 3), (81, 1), (84, 1), (83, .5), (81, .5), (88, 1), (84, 1), (79, 1.5), (81, .5), (83, 1), (84, 1),
          (87, 1), (90, 1), (87, 1), (83, 1), (90, 3), (None, 1)]
    mel = A + [(78, 2), (75, 1), (71, 1)] + Bm + A + [(76, 4)]
    check(mel, len(ch)); tr = Track(132, len(ch), 91)
    rock_band(tr, ch, T, fills=(7, 15, 23), bass_pat=(0, 12, 0, 12, 7, 12, 0, 10))
    play(tr, mel, fm_lead, shift=-12 + 12); tr.save("field_wild")


def dungeon():  # caves, the undercroft, the sunken castle: C minor, 120, sparse lead
    ch = ["Cm", "Ab", "Bb", "Cm", "Cm", "Ab", "G", "G", "Fm", "Cm", "Ab", "G", "Fm", "Ab", "G", "G"]
    mel = [(None, 16),
           (79, 1), (75, 1), (72, 1), (74, .5), (75, .5), (77, 2), (75, 1), (72, 1),
           (74, 1.5), (75, .5), (74, 1), (71, 1), (67, 3), (None, 1),
           (80, 2), (79, 1), (77, 1), (75, 2), (79, 1), (84, 1),
           (84, 1), (82, .5), (80, .5), (79, 1), (75, 1), (74, 2), (71, 1), (67, 1),
           (77, 1), (80, 1), (84, 1), (80, 1), (87, 2), (84, 1), (80, 1),
           (83, 1), (86, 1), (89, 1), (86, 1), (83, 3), (None, 1)]
    check(mel, len(ch)); tr = Track(120, len(ch), 33)
    rock_band(tr, ch, T, kick=(0.0, 2.5), fills=(15,), bass_pat=(0, 0, 0, 12, 0, 0, 10, 7), stabs=(0.0,))
    play(tr, mel, fm_lead, gain=0.24, echo=(1.0, 0.3)); tr.save("dungeon")


def boss(name="boss", shift=0, bpm=160, seed=5):
    ch = ["Em", "Em", "C", "D", "Em", "Em", "C", "B", "Am", "Am", "Em", "Em", "C", "D", "B", "B"]
    mel = [(76, .5), (76, .5), (79, .5), (76, .5), (83, 1), (81, 1), (79, .5), (78, .5), (76, 1), (74, 1), (76, 1),
           (84, .5), (83, .5), (79, 1), (76, 1), (79, 1), (78, 1), (81, 1), (86, 2),
           (88, .5), (86, .5), (83, 1), (79, 1), (83, 1), (88, 1), (90, 1), (91, 2),
           (88, 1), (84, 1), (79, 1), (84, 1), (83, 2), (87, 1), (90, 1),
           (81, 1.5), (84, .5), (88, 1), (84, 1), (86, .5), (84, .5), (83, 1), (81, 2),
           (79, 1.5), (83, .5), (88, 1), (83, 1), (88, 4),
           (84, 1), (88, 1), (91, 1), (88, 1), (86, 1), (90, 1), (93, 1), (90, 1),
           (90, 2), (87, 1), (83, 1), (83, 2), (87, .5), (90, .5), (83, 1)]
    check(mel, len(ch)); tr = Track(bpm, len(ch), seed)
    tones = {k: [x + shift for x in v] for k, v in T.items()}
    rock_band(tr, ch, tones, kick=(0.0, 0.5, 2.0, 2.5, 3.5), fills=(7, 15), bass_pat=(0, 12, 0, 12, 0, 12, 7, 10),
              stabs=(0.0, 1.5, 3.0))
    play(tr, mel, fm_lead, shift=shift, gain=0.32, echo=(0.5, 0.18))
    if name == "boss_final":  # a held choir-like pad over the final fight
        for bar, c in enumerate(ch):
            tr.add(strings([x + 24 for x in tones[c][1:4]], 4 * tr.beat + 0.6), bar * 4 * tr.beat, 0, 0.16)
    tr.save(name, drive=1.6)


def village():  # Lantern Village by day: F major, 92, accordion and guitar
    ch = ["F", "C", "Dm", "Bb", "F", "C", "Bb", "C"] * 2
    mel = [(69, 1), (72, 1), (77, 1.5), (76, .5), (76, 1), (74, 1), (72, 2),
           (74, 1), (77, 1), (81, 1), (79, .5), (77, .5), (77, 3), (None, 1),
           (81, 1.5), (79, .5), (77, 1), (81, 1), (79, 1.5), (77, .5), (76, 1), (72, 1),
           (74, 1), (77, 1), (82, 1), (81, .5), (79, .5), (79, 3), (None, 1),
           (84, 2), (81, 1), (77, 1), (79, 1), (76, 1), (72, 2),
           (77, 1), (81, 1), (86, 1.5), (84, .5), (82, 1), (81, 1), (79, 1), (77, 1),
           (81, 1.5), (84, .5), (81, 1), (77, 1), (79, 1), (76, 1), (79, 1), (82, 1),
           (81, 1), (79, 1), (77, 1), (79, 1), (77, 3), (None, 1)]
    check(mel, len(ch)); tr = Track(92, len(ch), 12)
    for bar, c in enumerate(ch):
        t0 = bar * 4 * tr.beat; tn = T[c]
        tr.add(pad([x + 12 for x in tn[1:4]], 4 * tr.beat + 1.0, 0.5, 0.8), t0, 0, 0.07)
        for i in range(8):
            nt = [tn[0], tn[2], tn[3], tn[2], tn[1] + 12, tn[2], tn[3], tn[2]][i] + 12
            tr.add(pluck(nt, 1.0, tr.rng, 0.993), t0 + i * tr.beat / 2 + tr.rng.uniform(0, 0.006), -0.3 + 0.15 * (i % 2), 0.17)
        tr.add(pluck(tn[0], 2.0, tr.rng), t0, 0.1, 0.20); tr.add(pluck(tn[0] + 7, 1.5, tr.rng), t0 + 2 * tr.beat, 0.1, 0.14)
        for i in range(4):
            n = int(0.1 * SR)
            tr.add(tr.rng.normal(0, 1, n) * np.exp(-np.arange(n) / SR * 45), t0 + i * tr.beat + tr.beat / 2, 0.4, 0.04)
    play(tr, mel, accordion, pan=0.1, gain=0.22, echo=None)
    tr.save("village", drive=1.2)


def night(name="night", voice="flute", bpm=66):  # every place at night, and the title: A minor, slow
    ch = ["Am", "F", "C", "G", "Am", "F", "E", "E"] * 2
    mel = [(76, 2), (72, 2), (69, 2), (72, 1), (74, 1), (76, 3), (79, 1), (74, 4),
           (76, 2), (81, 2), (79, 1), (77, 1), (76, 2), (74, 2), (71, 1), (68, 1), (71, 4),
           (84, 2), (83, 1), (81, 1), (81, 2), (79, 1), (77, 1), (76, 2), (79, 1), (84, 1), (83, 2), (86, 2),
           (84, 2), (81, 2), (77, 2), (81, 1), (79, 1), (80, 2), (83, 1), (76, 1), (76, 4)]
    check(mel, len(ch)); tr = Track(bpm, len(ch), 21)
    for bar, c in enumerate(ch):
        t0 = bar * 4 * tr.beat; tn = T[c]
        tr.add(pad([x + 12 for x in tn[1:4]], 4 * tr.beat + 2.0, 1.6, 1.6, 0.2), t0, 0, 0.09)
        tr.add(np.sin(2 * np.pi * hz(tn[0]) * np.arange(int(4 * tr.beat * SR)) / SR) * env(int(4 * tr.beat * SR), 0.8, 0, 1, 0.8), t0, 0, 0.08)
        for i in range(4):
            tr.add(musicbox([tn[2], tn[3], tn[1] + 12, tn[3]][i] + 24, 2.5), t0 + i * tr.beat + tr.rng.uniform(0, 0.01), 0.3 - 0.2 * (i % 2), 0.08)
    if voice == "flute":
        play(tr, mel, lambda nt, d: flute(nt, d, tr.rng), pan=0.1, gain=0.20, echo=(1.0, 0.3))
    else:
        play(tr, mel, lambda nt, d: musicbox(nt + 12, d + 1.5), pan=0.1, gain=0.16, echo=(0.5, 0.3), legato=1.0)
    n = tr.n; bed = np.convolve(tr.rng.normal(0, 1, n), np.ones(700) / 700, mode="same") * 0.25
    tr.L += bed; tr.R += np.roll(bed, SR // 3)
    tr.save(name, drive=1.1)


def ending():  # the clock room, the festival, after the ending: G major, 80, harp and strings
    ch = ["G", "D", "Em", "C", "G", "D", "C", "D"] * 2
    base = [(69, 1), (72, 1), (77, 1.5), (76, .5), (76, 1), (74, 1), (72, 2),
            (74, 1), (77, 1), (81, 1), (79, .5), (77, .5), (77, 3), (None, 1),
            (81, 1.5), (79, .5), (77, 1), (81, 1), (79, 1.5), (77, .5), (76, 1), (72, 1),
            (74, 1), (77, 1), (82, 1), (81, .5), (79, .5), (79, 3), (None, 1),
            (84, 2), (81, 1), (77, 1), (79, 1), (76, 1), (72, 2),
            (77, 1), (81, 1), (86, 1.5), (84, .5), (82, 1), (81, 1), (79, 1), (77, 1),
            (81, 1.5), (84, .5), (81, 1), (77, 1), (79, 1), (76, 1), (79, 1), (82, 1),
            (81, 1), (79, 1), (77, 1), (79, 1), (77, 3), (None, 1)]
    mel = [(None if n is None else n + 2, b) for n, b in base]  # the village tune, a tone up, slower
    check(mel, len(ch)); tr = Track(80, len(ch), 44)
    TG = dict(T); TG["G"] = [31, 38, 43, 47, 50]; TG["D"] = [38, 45, 50, 54, 57]
    for bar, c in enumerate(ch):
        t0 = bar * 4 * tr.beat; tn = TG[c]
        tr.add(strings([x + 12 for x in tn[1:4]], 4 * tr.beat + 1.2), t0, 0, 0.18)
        for i in range(6):
            nt = [tn[0], tn[1], tn[2], tn[3], tn[2] + 12, tn[3] + 12][i] + 12
            tr.add(pluck(nt, 2.5, tr.rng, 0.998), t0 + i * tr.beat * 2 / 3, 0.35 - 0.1 * i, 0.13)
    play(tr, mel, lambda nt, d: flute(nt, d, tr.rng), pan=0.1, gain=0.22, echo=(1.0, 0.25))
    tr.save("ending", drive=1.1)


# ---------------------------------------------------------------- generated variants (<slot>_2 .. _5)
# Each variant has its own key, mode, tempo, chord loop and melody. The melody is composed from the
# chord loop: phrases of 4 bars (A, B, C), strong beats snap to chord tones, the rest walks the scale.
import math

NOTE = {"C": 0, "C#": 1, "Db": 1, "D": 2, "Eb": 3, "E": 4, "F": 5, "F#": 6, "Gb": 6, "G": 7, "Ab": 8, "A": 9, "Bb": 10, "B": 11}
MODES = {"min": [0, 2, 3, 5, 7, 8, 10], "dor": [0, 2, 3, 5, 7, 9, 10], "maj": [0, 2, 4, 5, 7, 9, 11],
         "mix": [0, 2, 4, 5, 7, 9, 10], "harm": [0, 2, 3, 5, 7, 8, 11]}
DEG = {"i": (0, "m"), "I": (0, "M"), "bII": (1, "M"), "ii": (2, "m"), "II": (2, "M"), "bIII": (3, "M"), "iii": (4, "m"),
       "IV": (5, "M"), "iv": (5, "m"), "V": (7, "M"), "v": (7, "m"), "bVI": (8, "M"), "vi": (9, "m"), "bVII": (10, "M")}
RHY = {
    "fast": ([1, 1, 1, 1], [1.5, .5, 1, 1], [.5, .5, 1, 2], [1, .5, .5, 1, 1], [.5, .5, .5, .5, 1, 1], [1, 1, .5, .5, 1],
             [2, 1, .5, .5], [.5, .5, 1, 1, 1], [1.5, .5, .5, .5, 1]),
    "boss": ([.5] * 8, [.5, .5, 1, .5, .5, 1], [1, .5, .5, .5, .5, 1], [.5, .5, .5, .5, 1, 1], [1.5, .5, 1.5, .5],
             [1, 1, .5, .5, .5, .5], [1.5, .5, 1, 1]),
    "sparse": ([2, 1, 1], [2, 2], [1, 1, 2], [1, -1, 2], [1.5, .5, 2], [-1, 1, 2], [3, 1], [1, 1, 1, 1]),
    "mid": ([1, 1, 1, 1], [1.5, .5, 1, 1], [1, 1, 2], [2, 1, 1], [1, .5, .5, 1, 1], [.5, .5, 1, 2], [1.5, .5, 2], [1, 2, 1]),
    "waltz": ([1, 1, 1], [2, 1], [1, .5, .5, 1], [1.5, .5, 1], [1, 2], [.5, .5, 1, 1], [1, 1, .5, .5]),
    "slow": ([2, 2], [2, 1, 1], [1, 1, 2], [3, 1], [1, 1, 1, 1], [1.5, .5, 2], [2, 1.5, .5], [4]),
}
CAD = {
    "fast": ([1, 1, 2], [.5, .5, 1, 2], [1.5, .5, 2], [1, 1, 1, -1], [2, 2], [1, .5, .5, 2]),
    "mid": ([1, 1, 2], [2, 2], [1.5, .5, 2], [3, 1], [2, 1, -1]),
    "slow": ([2, 2], [3, -1], [2, 1, 1], [1, 3], [4]),
}
CAD["waltz"] = ([1, 2], [2, 1], [3], [1.5, .5, 1])
CAD["boss"] = CAD["sparse"] = CAD["fast"]
STEPS = {"fast": [-3, -2, -1, -1, 0, 1, 1, 2, 3], "boss": [-3, -2, -1, -1, 0, 1, 1, 2, 3, 4, -4],
         "sparse": [-3, -2, -1, -1, 1, 1, 2, 3], "mid": [-2, -1, -1, 0, 1, 1, 2, 3, -3], "slow": [-2, -1, -1, 1, 1, 2, -3, 3], "waltz": [-2, -1, -1, 0, 1, 1, 2, 3, -3]}
PLANS = {3: "ABA", 4: "ABAC", 5: "AABAC", 6: "AABACA", 7: "AABACBA", 8: "AABBACBA", 9: "AABBACBAC", 10: "AABBACBBAC"}


def chord_of(tonic, tok):
    off, q = DEG[tok]
    return (NOTE[tonic] + off) % 12, q


def chord_name(pc, q):
    return f"{pc}{q}"


def chord_tones(pc, q):
    b = 28 + ((pc - 28) % 12)
    return [b, b + 7, b + 12, b + 12 + (3 if q == "m" else 4), b + 19]


def compose(spec, fam, lo, hi, intro=False, min_s=40.5):
    bpb = spec.get("bpb", 4)
    """Returns (chord names, tones table, melody, bars) for a spec."""
    tonic, mode, bpm = spec["key"], spec["mode"], spec["bpm"]
    bars = spec.get("bars") or 4 * math.ceil(min_s * bpm / (60 * bpb) / 4)
    n_ph = bars // 4
    plan = ("-" + PLANS[n_ph - 1]) if intro else PLANS[n_ph]
    progs = dict(zip("ABC", spec["prog"]))
    tones = {}; chords = []
    for letter in plan:
        toks = progs.get(letter if letter != "-" else "A").split()
        for tk in toks:
            pc, q = chord_of(tonic, tk)
            tones[chord_name(pc, q)] = chord_tones(pc, q); chords.append((pc, q))
    chords[-1] = chord_of(tonic, "I" if mode in ("maj", "mix") else "i")  # end on the tonic chord
    tones[chord_name(*chords[-1])] = chord_tones(*chords[-1])
    names = [chord_name(*c) for c in chords]
    tpc = NOTE[tonic]
    scale = {(tpc + x) % 12 for x in MODES[mode]}
    grid = [m for m in range(lo, hi + 1) if m % 12 in scale]
    center = len(grid) // 2
    pats, cads, steps = RHY[fam], CAD[fam], STEPS[fam]
    seed = spec["seed"]; memo = {}; occ = {}; mel = []; idx = center
    for p, letter in enumerate(plan):
        if letter == "-":
            mel.append((None, 16)); continue
        occ[letter] = occ.get(letter, 0) + 1
        if letter not in memo:
            r = np.random.default_rng(seed * 131 + ord(letter))
            tpl = []
            for k in range(3):
                rh = list(pats[r.integers(len(pats))])
                tpl.append((rh, [int(r.choice(steps)) for _ in rh]))
            memo[letter] = (tpl, int(r.integers(-3, 4)))
        tpl, off = memo[letter]
        r2 = np.random.default_rng(seed * 977 + ord(letter) * 13 + occ[letter])
        crh = list(cads[r2.integers(len(cads))])
        tpl4 = tpl + [(crh, [int(r2.choice(steps)) for _ in crh])]
        idx = max(0, min(len(grid) - 1, center + off))
        for k, (rh, st) in enumerate(tpl4):
            bar = p * 4 + k; pc, q = chords[bar]
            cpcs = {pc, (pc + (3 if q == "m" else 4)) % 12, (pc + 7) % 12}
            t = 0.0
            if bar == bars - 1:
                near = min(range(len(grid)), key=lambda g: (grid[g] % 12 != tpc, abs(g - idx)))
                nb = min(range(len(grid)), key=lambda g: (grid[g] % 12 not in cpcs or g == near, abs(g - idx)))
                mel += [(grid[nb], 1), (grid[near], 2), (None, 1)] if bpb == 4 else [(grid[nb], 1), (grid[near], 2)]
                continue
            for d, s in zip(rh, st):
                dur = abs(d)
                if d < 0:
                    mel.append((None, dur)); t += dur; continue
                idx += s
                if idx > center + 6 and s > 0: idx -= 2 * s
                if idx < center - 7 and s < 0: idx -= 2 * s
                idx = max(0, min(len(grid) - 1, idx))
                if (t % 2 == 0 if bpb == 4 else t == 0) or dur >= 2:
                    cand = [g for g in (idx, idx - 1, idx + 1, idx - 2, idx + 2) if 0 <= g < len(grid) and grid[g] % 12 in cpcs]
                    if cand: idx = cand[0]
                mel.append((grid[idx], dur)); t += dur
    return names, tones, mel, bars


def fm_variant(name, spec, fam="fast", lo=69, hi=91, boss_like=False, final=False, dungeon=False, lead_gain=0.30):
    ch, tones, mel, bars = compose(spec, fam, lo, hi, intro=dungeon)
    check(mel, bars)
    tr = Track(spec["bpm"], bars, spec["seed"])
    BASS = [(0, 0, 12, 0, 7, 0, 12, 10), (0, 12, 0, 12, 7, 12, 0, 10), (0, 0, 0, 12, 0, 0, 10, 7), (0, 12, 0, 12, 0, 12, 7, 10),
            (0, 7, 12, 7, 0, 7, 12, 10), (0, 0, 7, 0, 12, 0, 7, 5), (0, 12, 7, 12, 0, 12, 10, 12)]
    KICK = [(0.0, 2.0, 2.5), (0.0, 0.5, 2.0, 2.5), (0.0, 2.0), (0.0, 1.5, 2.5), (0.0, 0.5, 2.0, 2.5, 3.5), (0.0, 1.0, 2.0, 3.0)]
    STAB = [(0.0, 1.5), (0.0,), (0.0, 2.0), (0.0, 1.5, 3.0), (0.0, 0.5, 2.0)]
    o = spec["band"]
    fills = tuple(b for b in range(bars) if b % 8 == 7 or b == bars - 1)
    if boss_like:
        kick, stabs = KICK[4 - o[1] % 2], STAB[3 if o[2] % 2 else 0]
    else:
        kick, stabs = KICK[o[1] % len(KICK)], STAB[o[2] % len(STAB)]
    if dungeon:
        kick, stabs = (0.0, 2.5), (0.0,)
    rock_band(tr, ch, tones, kick=kick, fills=fills, bass_pat=BASS[o[0] % len(BASS)], stabs=stabs)
    play(tr, mel, fm_lead, gain=0.24 if dungeon else (0.32 if boss_like else lead_gain),
         echo=(1.0, 0.3) if dungeon else ((0.5, 0.18) if boss_like else (0.75, 0.22)))
    if final:
        for bar, c in enumerate(ch):
            tr.add(strings([x + 24 for x in tones[c][1:4]], 4 * tr.beat + 0.6), bar * 4 * tr.beat, 0, 0.16)
    tr.save(name, drive=1.6 if boss_like else 1.4)


def village_variant(name, spec):
    ch, tones, mel, bars = compose(spec, "mid", 65, 86)
    check(mel, bars); tr = Track(spec["bpm"], bars, spec["seed"])
    VA = [[0, 1, 2, 1, 3, 1, 2, 1], [0, 1, 2, 3, 2, 1, 2, 1], [0, 2, 1, 2, 0, 2, 1, 2], [0, 1, 3, 2, 1, 2, 3, 2], [0, 2, 3, 2, 1, 3, 2, 1]]
    pat = VA[spec["band"][0] % len(VA)]
    for bar, c in enumerate(ch):
        t0 = bar * 4 * tr.beat; tn = tones[c]
        tr.add(pad([x + 12 for x in tn[1:4]], 4 * tr.beat + 1.0, 0.5, 0.8), t0, 0, 0.07)
        P = [tn[0], tn[2], tn[3], tn[1] + 12]
        for i in range(8):
            tr.add(pluck(P[pat[i]] + 12, 1.0, tr.rng, 0.993), t0 + i * tr.beat / 2 + tr.rng.uniform(0, 0.006), -0.3 + 0.15 * (i % 2), 0.17)
        tr.add(pluck(tn[0], 2.0, tr.rng), t0, 0.1, 0.20); tr.add(pluck(tn[0] + 7, 1.5, tr.rng), t0 + 2 * tr.beat, 0.1, 0.14)
        for i in range(4):
            n = int(0.1 * SR)
            tr.add(tr.rng.normal(0, 1, n) * np.exp(-np.arange(n) / SR * 45), t0 + i * tr.beat + tr.beat / 2, 0.4, 0.04)
    play(tr, mel, accordion, pan=0.1, gain=0.22, echo=None)
    tr.save(name, drive=1.2)


def lantern_variant(name, spec):
    """Lantern Village: music-box twinkles over accordion or flute, guitar arpeggio, soft pad."""
    bpb = spec["bpb"]; fam = "waltz" if bpb == 3 else "mid"
    ch, tones, mel, bars = compose(spec, fam, 65, 86)
    check(mel, bars, bpb); tr = Track(spec["bpm"], bars, spec["seed"], bpb)
    VA = {4: [[0, 1, 2, 1, 3, 1, 2, 1], [0, 1, 2, 3, 2, 1, 2, 1], [0, 2, 1, 2, 0, 2, 1, 2], [0, 1, 3, 2, 1, 2, 3, 2]],
          3: [[0, 1, 2, 3, 2, 1], [0, 2, 1, 3, 1, 2], [0, 1, 3, 2, 3, 1], [0, 2, 3, 1, 3, 2]]}[bpb]
    pat = VA[spec["band"][0] % len(VA)]
    for bar, c in enumerate(ch):
        t0 = bar * bpb * tr.beat; tn = tones[c]
        tr.add(pad([x + 12 for x in tn[1:4]], bpb * tr.beat + 1.0, 0.5, 0.8), t0, 0, 0.07)
        P = [tn[0], tn[2], tn[3], tn[1] + 12]
        for i in range(2 * bpb):
            tr.add(pluck(P[pat[i]] + 12, 1.0, tr.rng, 0.993), t0 + i * tr.beat / 2 + tr.rng.uniform(0, 0.006), -0.3 + 0.15 * (i % 2), 0.15)
        tr.add(pluck(tn[0], 2.0, tr.rng), t0, 0.1, 0.20); tr.add(pluck(tn[0] + 7, 1.5, tr.rng), t0 + (2 if bpb == 4 else 1) * tr.beat, 0.1, 0.13)
        Tw = [tn[2], tn[3], tn[1] + 12, tn[4]]  # the lamp flames: bell tones, some of them each half beat
        for i in range(2 * bpb):
            if tr.rng.random() < 0.55:
                nt = Tw[int(tr.rng.integers(4))] + 24 + 12 * int(tr.rng.integers(0, 2))
                tr.add(musicbox(nt, 2.0), t0 + i * tr.beat / 2 + tr.beat / 4 * (i % 2), float(tr.rng.uniform(-0.6, 0.6)), 0.075)
    if spec["lead"] == "flute":
        play(tr, mel, lambda nt, d: flute(nt, d, tr.rng), pan=0.1, gain=0.22, echo=(1.0, 0.25))
    else:
        play(tr, mel, accordion, pan=0.1, gain=0.22, echo=None)
    tr.save(name, drive=1.2)


def night_variant(name, spec, voice="flute"):
    ch, tones, mel, bars = compose(spec, "slow", 69 if voice == "flute" else 66, 88 if voice == "flute" else 84)
    check(mel, bars); tr = Track(spec["bpm"], bars, spec["seed"])
    NA = [[0, 1, 2, 1], [0, 2, 1, 2], [2, 1, 0, 1], [0, 1, 2, 0]]
    pat = NA[spec["band"][0] % len(NA)]
    for bar, c in enumerate(ch):
        t0 = bar * 4 * tr.beat; tn = tones[c]
        tr.add(pad([x + 12 for x in tn[1:4]], 4 * tr.beat + 2.0, 1.6, 1.6, 0.2), t0, 0, 0.09)
        tr.add(np.sin(2 * np.pi * hz(tn[0]) * np.arange(int(4 * tr.beat * SR)) / SR) * env(int(4 * tr.beat * SR), 0.8, 0, 1, 0.8), t0, 0, 0.08)
        P = [tn[2], tn[3], tn[1] + 12]
        for i in range(4):
            tr.add(musicbox(P[pat[i]] + 24, 2.5), t0 + i * tr.beat + tr.rng.uniform(0, 0.01), 0.3 - 0.2 * (i % 2), 0.08)
    if voice == "flute":
        play(tr, mel, lambda nt, d: flute(nt, d, tr.rng), pan=0.1, gain=0.20, echo=(1.0, 0.3))
    else:
        play(tr, mel, lambda nt, d: musicbox(nt + 12, d + 1.5), pan=0.1, gain=0.16, echo=(0.5, 0.3), legato=1.0)
    n = tr.n; bed = np.convolve(tr.rng.normal(0, 1, n), np.ones(700) / 700, mode="same") * 0.25
    tr.L += bed; tr.R += np.roll(bed, SR // 3)
    tr.save(name, drive=1.1)


def ending_variant(name, spec):
    ch, tones, mel, bars = compose(spec, "mid", 67, 86)
    check(mel, bars); tr = Track(spec["bpm"], bars, spec["seed"])
    HA = [[0, 1, 2, 3, 4, 5], [0, 2, 3, 4, 3, 2], [0, 1, 3, 5, 3, 1], [0, 2, 1, 3, 5, 4]]
    pat = HA[spec["band"][0] % len(HA)]
    for bar, c in enumerate(ch):
        t0 = bar * 4 * tr.beat; tn = tones[c]
        tr.add(strings([x + 12 for x in tn[1:4]], 4 * tr.beat + 1.2), t0, 0, 0.18)
        Q = [tn[0], tn[1], tn[2], tn[3], tn[2] + 12, tn[3] + 12]
        for i in range(6):
            tr.add(pluck(Q[pat[i]] + 12, 2.5, tr.rng, 0.998), t0 + i * tr.beat * 2 / 3, 0.35 - 0.1 * i, 0.13)
    play(tr, mel, lambda nt, d: flute(nt, d, tr.rng), pan=0.1, gain=0.22, echo=(1.0, 0.25))
    tr.save(name, drive=1.1)


def S(key, mode, bpm, a, b, c, seed, band=(0, 0, 0), **kw):
    return dict(key=key, mode=mode, bpm=bpm, prog=(a, b, c), seed=seed, band=band, **kw)


SPECS = {
    "field_marsh": [S("G", "dor", 148, "i IV bVII i", "bVI bVII i v", "IV bVII i i", 201, (1, 1, 1)),
                    S("A", "harm", 126, "i iv V i", "bVI iv V V", "i bIII bVII V", 202, (2, 3, 0)),
                    S("Eb", "dor", 146, "i IV bVII i", "bIII bVII IV i", "bVI bVII i i", 207, (2, 2, 1)),  # field_marsh_4 replaced (the owner, 2026-10-28)
                    S("E", "min", 132, "i bVII bVI bVII", "bIII bVII iv i", "bVI bVII i i", 204, (5, 5, 2))],
    "field_wild": [S("F#", "dor", 125, "i bVII IV i", "bVI bVII i bVII", "IV bVII i i", 211, (3, 2, 1)),
                   S("D", "maj", 140, "I V vi IV", "IV I V V", "vi IV I V", 212, (6, 0, 4)),
                   S("G", "harm", 118, "i bVI bVII i", "iv bVI V V", "i bIII iv V", 213, (0, 3, 0)),
                   S("A", "mix", 150, "I bVII IV I", "vi IV bVII I", "IV bVII I I", 214, (1, 4, 3))],
    "dungeon": [S("F#", "harm", 140, "i bVI iv i", "bII bVII i i", "iv bVI V V", 221),
                S("Bb", "min", 126, "i bVI bVII i", "iv i bVI bVII", "bII bVII i i", 222, (3, 0, 0)),
                S("D", "harm", 136, "i bVII bVI V", "iv bVI bVII i", "i iv V V", 223, (2, 0, 0)),
                S("C#", "min", 132, "i bIII bVI bVII", "iv bVI bVII i", "bVI bVII i i", 224, (6, 0, 0))],
    "boss": [S("A", "harm", 176, "i bVI bVII V", "iv i bVI V", "i bIII bVII V", 231, (1, 0, 0)),
             S("D", "harm", 150, "i bVII bVI V", "bIII bVII iv V", "i i bVI V", 232, (3, 1, 1)),
             S("B", "harm", 168, "i iv bVI V", "bVI bVII i V", "bII bVII bVI V", 233, (4, 0, 0)),
             S("C", "harm", 182, "i bII i V", "iv bVI bVII V", "bVI V i i", 234, (6, 1, 1))],
    "boss_final": [S("G", "harm", 160, "i bVI bVII V", "iv bVI i V", "bIII bVII bVI V", 241, (1, 0, 1)),
                   S("F#", "harm", 170, "i bVII bVI V", "iv bVI bVII V", "i bIII bVI V", 242, (4, 1, 0)),
                   S("Bb", "harm", 142, "i bVI iv V", "bIII bVII bVI V", "bII V i i", 243, (0, 0, 1)),
                   S("Eb", "harm", 136, "i iv bVII bVI", "bVI bVII i V", "bII bVII bVI V", 244, (6, 1, 0))],
    "village": [S("G", "maj", 88, "I vi IV V", "IV I ii V", "vi IV I V", 251, (1,), bpb=4, lead="flute", bars=20),
                S("Bb", "maj", 88, "I V vi iii", "IV I V vi", "ii V I I", 252, (2,), bpb=3, lead="accordion", bars=20),
                S("A", "maj", 100, "I IV I V", "vi IV ii V", "I vi IV V", 253, (3,), bpb=4, lead="accordion", bars=20),
                S("C", "maj", 84, "I vi ii V", "IV iii vi V", "IV V I I", 254, (0,), bpb=3, lead="flute", bars=20)],
    "night": [S("D", "harm", 58, "i bVI bIII bVII", "iv i bVI V", "bVI bVII i i", 261, (1,)),
              S("E", "dor", 72, "i IV i bVII", "bVI bVII i i", "IV bVII i i", 262, (2,)),
              S("B", "min", 62, "i bVII bVI bVII", "bIII bVII iv i", "bVI iv i i", 263, (3,)),
              S("F#", "min", 75, "i bIII bVII iv", "bVI bVII i v", "iv bVII i i", 264, (1,))],
    "title": [S("F", "min", 54, "i bVI bIII bVII", "iv i bVI bVII", "bVI bVII i i", 271, (1,)),
              S("D", "dor", 66, "i IV bVII i", "bVI bVII i v", "IV bVII i i", 272, (2,)),
              S("G", "maj", 57, "I iii IV V", "vi IV I V", "IV I V I", 273, (3,)),
              S("Eb", "maj", 69, "I V vi IV", "IV I V V", "vi IV I I", 274, (0,))],
    "ending": [S("D", "maj", 72, "I V vi IV", "IV I V vi", "ii V I I", 281, (1,)),
               S("A", "maj", 88, "I IV I V", "vi IV I V", "ii V I I", 282, (2,)),
               S("Eb", "maj", 76, "I vi IV V", "iii IV I V", "IV V I I", 283, (3,)),
               S("C", "maj", 91, "I iii vi IV", "IV I ii V", "vi IV I I", 284, (0,))],
}
BUILD = {
    "field_marsh": lambda n, s: fm_variant(n, s), "field_wild": lambda n, s: fm_variant(n, s),
    "dungeon": lambda n, s: fm_variant(n, s, fam="sparse", lo=67, hi=89, dungeon=True),
    "boss": lambda n, s: fm_variant(n, s, fam="boss", lo=71, hi=93, boss_like=True),
    "boss_final": lambda n, s: fm_variant(n, s, fam="boss", lo=71, hi=93, boss_like=True, final=True),
    "village": lantern_variant, "night": night_variant,
    "title": lambda n, s: night_variant(n, s, "musicbox"), "ending": ending_variant,
}
FAMILY = {"dungeon": "sparse", "boss": "boss", "boss_final": "boss", "village": "mid", "night": "slow", "title": "slow", "ending": "mid"}


def _mk(slot, k):
    return lambda: BUILD[slot](f"{slot}_{k + 2}", SPECS[slot][k])


TRACKS_NEW = {f"{s}_{k + 2}": _mk(s, k) for s in SPECS for k in range(4)}
DROPPED = ["ending", "ending_4", "ending_5", "boss_3", "boss_4", "boss_final_4", "boss_final_5", "field_marsh_3", "field_marsh_4", "field_marsh_5", "night_2"]  # the owner took these out (2026-10-27, 8 more 10-28); sys/music.gd skips them
TRACKS_NEW["village"] = lambda: lantern_variant("village", S("D", "maj", 96, "I V vi IV", "vi iii IV V", "IV I V I", 250, (0,), bpb=3, lead="accordion", bars=24))


TRACKS = {
    "field_marsh": field_marsh, "field_wild": field_wild, "dungeon": dungeon,
    "boss": lambda: boss("boss"), "boss_final": lambda: boss("boss_final", shift=-2, bpm=150, seed=9),
    "village": village, "night": night, "title": lambda: night("title", "musicbox", 60), "ending": ending,
}
TRACKS.update(TRACKS_NEW)
for _d in DROPPED:
    TRACKS.pop(_d)

if __name__ == "__main__":
    for name in sys.argv[1:] or TRACKS:
        TRACKS[name]()
