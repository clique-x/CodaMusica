"""Atmospheric pad chord generator."""

import random
from composer.scales import degree_to_midi, SCALES


# Chord voicings: intervals above root note (in scale degrees)
# These create the wide, lush pad sound
VOICINGS = [
    [0, 4, 7],          # basic triad
    [0, 4, 7, 11],      # seventh
    [0, 4, 7, 14],      # octave voicing
    [0, 7, 14],         # open fifth
    [0, 5, 7],          # sus4-ish
]

# Harmonic progressions (root degrees) — Phrygian Dominant
PROGRESSIONS = [
    [0, 0, 4, 0],
    [0, 5, 4, 0],
    [0, 7, 5, 4],
    [0, 4, 0, 7],
    [0, 1, 0, 4],       # uses the dark b2
]


def generate_pads(section, bar_offset, root, scale_name):
    """Long sustained pad chords with slow voice leading."""
    notes = []
    if not section.has_pad:
        return notes

    beats_per_bar  = 4
    chord_len_bars = section.pad_chord_len
    chord_len_beat = chord_len_bars * beats_per_bar
    energy         = section.energy

    # Pick a harmonic progression for this section
    prog    = random.choice(PROGRESSIONS)
    voicing = random.choice(VOICINGS)

    bar = 0
    i   = 0
    while bar < section.bars:
        abs_bar  = bar_offset + bar
        t        = abs_bar * beats_per_bar
        deg      = prog[i % len(prog)]
        dur      = chord_len_beat * 0.97   # slight gap between chords
        oct_base = 0 if random.random() < 0.6 else 1

        for v_offset in voicing:
            midi = degree_to_midi(deg + v_offset, root, scale_name, oct_base)
            # Velocity: low = atmospheric, higher = present
            vel = random.randint(
                int(35 + energy * 30),
                int(55 + energy * 25)
            )
            # Slight velocity variation per voice — upper voices quieter
            vel = max(20, vel - v_offset * 3)
            notes.append((t, midi, vel, dur))

        bar += chord_len_bars
        i   += 1

    return notes
