"""Scale definitions and degree-to-MIDI utilities."""

SCALES = {
    'phrygian_dominant': [0, 1, 4, 5, 7, 8, 10],   # The Astrix/Tarang/Shiva DNA
    'dorian':            [0, 2, 3, 5, 7, 9, 10],   # Gurdjieff/Dervish DNA
    'phrygian':          [0, 1, 3, 5, 7, 8, 10],
    'minor_pentatonic':  [0, 3, 5, 7, 10],
    'double_harmonic':   [0, 1, 4, 5, 7, 8, 11],   # Byzantine / very dark
}

# Chord voicings per scale (degree offsets from root degree)
VOICINGS = {
    'phrygian_dominant': {
        0: [0, 4, 7],        # root chord
        1: [1, 5, 8],        # b2 chord — tension
        4: [4, 7, 11],       # "major" feel
        5: [5, 8, 12],       # fourth
        7: [7, 10, 14],      # fifth
    }
}

def degree_to_midi(degree, root, scale_name, octave_shift=0):
    """Convert a scale degree to MIDI note number."""
    intervals = SCALES[scale_name]
    size = len(intervals)
    oct_offset = (degree // size) + octave_shift
    deg = degree % size
    note = root + intervals[deg] + (oct_offset * 12)
    return max(0, min(127, note))

def chord_notes(root_degree, root, scale_name, octave_shift=0):
    """Return MIDI notes for a chord voicing."""
    voicing = VOICINGS.get(scale_name, {}).get(root_degree, [0, 4, 7])
    return [degree_to_midi(root_degree + v, root, scale_name, octave_shift)
            for v in [0, 4, 7]]  # fallback to triad-ish
