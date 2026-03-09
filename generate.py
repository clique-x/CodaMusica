#!/usr/bin/env python3
"""
CodaMusica — Song Generator
Generates an algorithmically composed MIDI song, ready for GarageBand.

Usage:
    python generate.py
    python generate.py --name "desert_journey"
    python generate.py --bpm 138 --root 47   # 47 = B
    python generate.py --count 3             # generate 3 different songs

Roots: C=48  C#=49  D=50  D#=51  E=52  F=53  F#=54  G=55  A=57  B=59
"""

import argparse
import os
import sys
import random

sys.path.insert(0, os.path.dirname(__file__))
from composer.midi_writer import generate_song

STYLES = {
    'artcore_dervish': {
        'bpm': 132,
        'root': 50,             # D
        'scale': 'phrygian_dominant',
        'desc': 'Astrix × Gurdjieff. Psybient to Artcore. D Phrygian Dominant.',
    },
    'deep_dervish': {
        'bpm': 120,
        'root': 50,             # D
        'scale': 'dorian',
        'desc': 'Slower, deeper. Gurdjieff/oud character. D Dorian.',
    },
    'tarang_drive': {
        'bpm': 138,
        'root': 55,             # G
        'scale': 'phrygian_dominant',
        'desc': 'Faster, more percussive. Tarang × Artcore energy. G Phrygian Dom.',
    },
}

def main():
    parser = argparse.ArgumentParser(description='CodaMusica MIDI Generator')
    parser.add_argument('--style',  default='artcore_dervish',
                        choices=list(STYLES.keys()),
                        help='Musical style preset')
    parser.add_argument('--name',   default=None,
                        help='Output filename (without .mid)')
    parser.add_argument('--bpm',    type=int, default=None,
                        help='Override BPM')
    parser.add_argument('--root',   type=int, default=None,
                        help='Override root MIDI note (48=C, 50=D, 55=G, 59=B)')
    parser.add_argument('--count',  type=int, default=1,
                        help='How many songs to generate')
    parser.add_argument('--outdir', default='/Users/earthclique/CodaMusica/output',
                        help='Output directory')
    args = parser.parse_args()

    os.makedirs(args.outdir, exist_ok=True)

    style = STYLES[args.style]
    bpm   = args.bpm  or style['bpm']
    root  = args.root or style['root']
    scale = style['scale']

    print(f"\n{'═'*55}")
    print(f"  CodaMusica — Generating '{args.style}'")
    print(f"  {style['desc']}")
    print(f"  BPM: {bpm}  Root: {root}  Scale: {scale}")
    print(f"{'═'*55}\n")

    for i in range(args.count):
        if args.count > 1:
            print(f"── Song {i+1}/{args.count} ──────────────────────────────────")

        # Slight random variation per song
        actual_bpm  = bpm  + random.randint(-2, 2)
        actual_root = root + random.choice([0, 0, 0, 2, -2])  # occasional modal shift

        name = args.name or f"{args.style}_{i+1:02d}"
        path = os.path.join(args.outdir, f"{name}.mid")

        generate_song(
            bpm        = actual_bpm,
            root       = actual_root,
            scale_name = scale,
            output_path= path,
        )

        print(f"\n  ✓ Open in GarageBand: open \"{path}\"")
        print()

    print("─"*55)
    print("  HOW TO USE IN GARAGEBAND:")
    print()
    print("  1. Open GarageBand → New Project")
    print("  2. File → Open  (select the .mid file)")
    print("     GarageBand auto-creates one track per instrument")
    print()
    print("  3. Assign sounds to each track:")
    print("     Track 1 Kick+Hat  → Drummer or Classic Studio Kit")
    print("     Track 2 Sub Bass  → Moog Bass (Dark Sub)")
    print("     Track 3 Acid Bass → Vintage Electric Bass or Moog Bass")
    print("     Track 4 Pads      → Vintage Pads, Ethereal, or Choir Pad")
    print("     Track 5 Lead      → Saw Lead, FM Electric Piano, or Retro Lead")
    print("     Track 6 Oud/Pluck → Sitar, Indian Strings, or Acoustic Guitar")
    print()
    print("  4. Add reverb + delay to taste")
    print("  5. Export: Share → Export Song to Disk")
    print("─"*55)

if __name__ == '__main__':
    main()
