#!/usr/bin/env python3
"""
CodaMusica — Audio Analyzer
Extracts BPM, key, scale, spectral profile, rhythm patterns from an audio file.
"""

import sys
import warnings
warnings.filterwarnings("ignore")

import numpy as np
import librosa

def analyze(path, duration=90):
    print(f"\n{'='*60}")
    print(f"  {path.split('/')[-1]}")
    print(f"{'='*60}")

    # Load first `duration` seconds (enough for solid analysis)
    y, sr = librosa.load(path, duration=duration, mono=True)

    # ── BPM / Tempo ────────────────────────────────────────────
    tempo, beats = librosa.beat.beat_track(y=y, sr=sr)
    tempo = float(np.atleast_1d(tempo)[0])
    beat_times = librosa.frames_to_time(beats, sr=sr)
    # Groove: measure beat interval variance (tightness vs swing)
    if len(beat_times) > 2:
        intervals = np.diff(beat_times)
        groove_var = float(np.std(intervals) / np.mean(intervals) * 100)
    else:
        groove_var = 0.0

    print(f"\nTEMPO")
    print(f"  BPM          : {tempo:.1f}")
    print(f"  Groove var   : {groove_var:.1f}%  ({'loose/swung' if groove_var > 5 else 'tight/mechanical'})")

    # ── Key + Scale ────────────────────────────────────────────
    chroma = librosa.feature.chroma_cqt(y=y, sr=sr)
    chroma_mean = chroma.mean(axis=1)
    note_names = ['C','C#','D','D#','E','F','F#','G','G#','A','A#','B']
    root_idx = int(np.argmax(chroma_mean))
    root_name = note_names[root_idx]

    # Major vs minor profile correlation
    major_profile = np.array([6.35,2.23,3.48,2.33,4.38,4.09,2.52,5.19,2.39,3.66,2.29,2.88])
    minor_profile = np.array([6.33,2.68,3.52,5.38,2.60,3.53,2.54,4.75,3.98,2.69,3.34,3.17])
    major_scores, minor_scores = [], []
    for i in range(12):
        shifted = np.roll(chroma_mean, -i)
        major_scores.append(np.corrcoef(shifted, major_profile)[0,1])
        minor_scores.append(np.corrcoef(shifted, minor_profile)[0,1])
    best_major = np.argmax(major_scores)
    best_minor = np.argmax(minor_scores)
    if major_scores[best_major] > minor_scores[best_minor]:
        detected_key = f"{note_names[best_major]} Major"
        mode = "major"
        key_midi = best_major
    else:
        detected_key = f"{note_names[best_minor]} Minor"
        mode = "minor"
        key_midi = best_minor

    # Top 5 active pitch classes
    top_pcs = np.argsort(chroma_mean)[::-1][:6]
    top_notes = [note_names[i] for i in top_pcs]

    print(f"\nHARMONY")
    print(f"  Detected key : {detected_key}")
    print(f"  Root MIDI    : {key_midi + 48} (octave 3)")
    print(f"  Active notes : {' '.join(top_notes)}")

    # Guess scale from active pitch classes relative to root
    intervals = sorted([(pc - key_midi) % 12 for pc in top_pcs])
    print(f"  Intervals    : {intervals}")
    scale_guess = guess_scale(intervals)
    print(f"  Scale guess  : {scale_guess}")

    # ── Spectral Character ─────────────────────────────────────
    spectral_centroid = float(np.mean(librosa.feature.spectral_centroid(y=y, sr=sr)))
    spectral_rolloff  = float(np.mean(librosa.feature.spectral_rolloff(y=y, sr=sr, roll_percent=0.85)))
    spectral_contrast = librosa.feature.spectral_contrast(y=y, sr=sr)
    contrast_mean     = spectral_contrast.mean(axis=1)
    zcr               = float(np.mean(librosa.feature.zero_crossing_rate(y)))
    rms               = float(np.mean(librosa.feature.rms(y=y)))

    # Sub-band energy ratios
    stft = np.abs(librosa.stft(y))
    freqs = librosa.fft_frequencies(sr=sr)
    def band_energy(lo, hi):
        mask = (freqs >= lo) & (freqs < hi)
        return float(stft[mask].mean()) if mask.any() else 0.0

    sub    = band_energy(20, 80)
    bass   = band_energy(80, 300)
    mid    = band_energy(300, 2000)
    hi_mid = band_energy(2000, 6000)
    air    = band_energy(6000, 20000)
    total  = sub + bass + mid + hi_mid + air + 1e-10

    brightness = spectral_centroid / (sr / 2)
    texture = "bright/aggressive" if brightness > 0.15 else ("warm/mid" if brightness > 0.08 else "dark/deep")

    print(f"\nSPECTRAL")
    print(f"  Centroid     : {spectral_centroid:.0f} Hz  ({texture})")
    print(f"  Rolloff      : {spectral_rolloff:.0f} Hz")
    print(f"  Sub (20-80)  : {sub/total*100:.1f}%")
    print(f"  Bass (80-300): {bass/total*100:.1f}%")
    print(f"  Mids (300-2k): {mid/total*100:.1f}%")
    print(f"  Hi-mid(2-6k) : {hi_mid/total*100:.1f}%")
    print(f"  Air (6k+)    : {air/total*100:.1f}%")
    print(f"  Roughness/ZCR: {zcr:.4f}  ({'noisy/distorted' if zcr > 0.1 else 'tonal/smooth'})")

    # ── Rhythm / Onset Density ─────────────────────────────────
    onset_env    = librosa.onset.onset_strength(y=y, sr=sr)
    onsets       = librosa.onset.onset_detect(onset_envelope=onset_env, sr=sr)
    onset_times  = librosa.frames_to_time(onsets, sr=sr)
    onset_density = len(onset_times) / duration  # onsets per second

    # Percussiveness: ratio of high-freq to low-freq onset strength
    onset_hi = librosa.onset.onset_strength(y=librosa.effects.harmonic(y, margin=8), sr=sr)
    onset_lo = librosa.onset.onset_strength(y=librosa.effects.percussive(y, margin=8), sr=sr)
    percussiveness = float(np.mean(onset_lo)) / (float(np.mean(onset_hi)) + 1e-6)

    print(f"\nRHYTHM")
    print(f"  Onset density: {onset_density:.2f} onsets/sec")
    print(f"  Percussive   : {percussiveness:.2f}  ({'drum-heavy' if percussiveness > 1.5 else ('balanced' if percussiveness > 0.8 else 'melodic/tonal')})")

    # ── Dynamic Range ──────────────────────────────────────────
    rms_frames = librosa.feature.rms(y=y)[0]
    dyn_range = float(20 * np.log10(rms_frames.max() / (rms_frames.min() + 1e-10)))
    print(f"\nDYNAMICS")
    print(f"  RMS level    : {20*np.log10(rms+1e-10):.1f} dB")
    print(f"  Dynamic range: {dyn_range:.1f} dB  ({'compressed' if dyn_range < 15 else ('moderate' if dyn_range < 30 else 'wide/organic')})")

    # ── SuperCollider Summary ──────────────────────────────────
    print(f"\nSUPERCOLLIDER TARGETS")
    print(f"  ~bpm      = {round(tempo)};")
    print(f"  ~psyRoot  = {key_midi + 48};   // {note_names[key_midi]} octave 3")
    print(f"  ~psyScale = {intervals};")
    kick_period = round(240 / tempo)  # beats between kicks (1 bar / 4)
    print(f"  kickPeriod= {kick_period};   // beats per kick")
    cutoff_lo = int(spectral_centroid * 0.3)
    cutoff_hi = int(spectral_centroid * 2.0)
    print(f"  cutLo     = {cutoff_lo};   // filter sweep low")
    print(f"  cutHi     = {cutoff_hi};   // filter sweep high")
    print(f"  bassWeight= {bass/total:.2f};   // 0–1, how heavy the bass should be")

    return {
        "bpm": tempo, "key_midi": key_midi + 48, "key_name": detected_key,
        "intervals": intervals, "scale": scale_guess,
        "centroid": spectral_centroid, "sub_pct": sub/total,
        "bass_pct": bass/total, "percussiveness": percussiveness,
        "groove_var": groove_var, "dyn_range": dyn_range,
    }

def guess_scale(intervals):
    known = {
        (0,1,4,5,7,8,10): "Phrygian Dominant",
        (0,2,3,5,7,9,10): "Dorian",
        (0,1,3,5,7,8,10): "Phrygian",
        (0,2,4,6,7,9,11): "Lydian",
        (0,2,4,5,7,9,10): "Mixolydian",
        (0,2,3,5,7,8,10): "Aeolian (Natural Minor)",
        (0,2,4,5,7,9,11): "Major (Ionian)",
        (0,3,5,7,10):     "Minor Pentatonic",
        (0,2,4,7,9):      "Major Pentatonic",
        (0,2,4,6,8,10):   "Whole Tone",
        (0,1,5,7,8):      "Japanese In",
        (0,2,3,6,7,8,11): "Double Harmonic / Byzantine",
        (0,1,4,5,7,8,11): "Harmonic Minor",
    }
    key = tuple(sorted(set(intervals)))
    # Exact match
    if key in known:
        return known[key]
    # Fuzzy — find closest
    best, best_score = "Unknown", 0
    for k, name in known.items():
        overlap = len(set(key) & set(k))
        if overlap > best_score:
            best, best_score = name, overlap
    return f"{best} (approx, {best_score}/{len(key)} match)"

if __name__ == "__main__":
    files = sys.argv[1:]
    results = {}
    for f in files:
        try:
            results[f] = analyze(f)
        except Exception as e:
            print(f"  ERROR on {f}: {e}")

    print(f"\n{'='*60}")
    print("  CROSS-TRACK SUMMARY")
    print(f"{'='*60}")
    for f, r in results.items():
        name = f.split('/')[-1][:45]
        print(f"\n  {name}")
        print(f"    BPM={r['bpm']:.0f}  Key={r['key_name']}  Scale={r['scale']}")
        print(f"    Bass={r['bass_pct']*100:.0f}%  Percussive={r['percussiveness']:.1f}  DynRange={r['dyn_range']:.0f}dB")
