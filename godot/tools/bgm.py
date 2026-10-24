"""The Crown Oddity background music, synthesised from code (no recordings).

Two families, as the user chose (2026-10-25):
- FM rock (late-80s PC-88 action-RPG manner, original melodies) for fields, dungeons and bosses:
  2-operator FM lead and slap bass, square-wave 16th arpeggios, FM brass stabs, noise drums.
- slow lyrical pieces for the title, the village, night and the ending.

Every track is one seamless loop. Run: python tools/bgm.py [names...]
Writes audio/bgm/<name>.wav, then ffmpeg turns each into <name>.ogg (Vorbis q4) if ffmpeg is on PATH."""
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

    def __init__(self, bpm, bars, seed):
        self.beat = 60.0 / bpm
        self.n = int(bars * 4 * self.beat * SR)
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
        OUT.mkdir(parents=True, exist_ok=True)
        path = OUT / f"{name}.wav"
        with wave.open(str(path), "wb") as w:
            w.setnchannels(2); w.setsampwidth(2); w.setframerate(SR)
            w.writeframes((mix * 32767).astype(np.int16).tobytes())
        if shutil.which("ffmpeg"):
            subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", str(path), "-c:a", "libvorbis", "-q:a", "4",
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
    n = int(dur * SR); p = max(2, int(SR / hz(note)))
    buf = rng.uniform(-1, 1, p); out = np.zeros(n)
    for i in range(n):  # Karplus-Strong; fine for a few seconds of string
        out[i] = buf[i % p]
        buf[i % p] = damp * 0.5 * (buf[i % p] + buf[(i + 1) % p])
    return out * env(n, 0.002, 0, 1, 0.05)


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


def check(mel, bars):
    total = sum(b for _, b in mel)
    assert abs(total - bars * 4) < 1e-6, f"melody has {total} beats, needs {bars * 4}"


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


TRACKS = {
    "field_marsh": field_marsh, "field_wild": field_wild, "dungeon": dungeon,
    "boss": lambda: boss("boss"), "boss_final": lambda: boss("boss_final", shift=-2, bpm=150, seed=9),
    "village": village, "night": night, "title": lambda: night("title", "musicbox", 60), "ending": ending,
}

if __name__ == "__main__":
    for name in sys.argv[1:] or TRACKS:
        TRACKS[name]()
