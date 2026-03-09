"""Bass generator — sub bass + Astrix-style acid bassline."""

import random
from composer.scales import degree_to_midi, SCALES
from composer.markov import MELODY_CHAIN, RHYTHM_CHAIN

# Acid bassline patterns (16th note degree sequences)
# Degree 1 = b2 = the dark Arabic tension note
ACID_PATTERNS = {
    'sparse':    [[0,0,0,0], [0,0,0,4]],
    'mid':       [[0,0,4,0,0,7,4,0], [0,0,0,4,3,4,0,0], [0,4,0,4,0,7,0,4]],
    'full':      [
        [0,0,4,0,1,0,7,4,0,0,4,0,1,4,7,4],
        [0,0,0,4,0,0,4,7,0,1,0,4,0,7,4,0],
        [0,4,7,4,0,4,1,0,4,7,4,0,7,4,0,4],
    ],
    'breakdown': [[0,0,0,0,0,0,0,4]],
}


def generate_sub_bass(section, bar_offset, root, scale_name):
    """Long sub bass notes — the floor. One per chord change."""
    notes = []
    if not section.has_bass:
        return notes

    beats_per_bar = 4
    note_len_bars = max(1, section.pad_chord_len)  # match pad changes

    # Progression — mostly root, some movement
    progression = _make_progression(section.bars, note_len_bars)

    for i, (bar, deg) in enumerate(progression):
        abs_bar  = bar_offset + bar
        t        = abs_bar * beats_per_bar
        midi     = degree_to_midi(deg, root, scale_name, octave_shift=-2)
        dur      = note_len_bars * beats_per_bar * 0.95
        vel      = random.randint(75, 90)
        notes.append((t, midi, vel, dur))

    return notes


def generate_acid_bass(section, bar_offset, root, scale_name):
    """16th note rolling acid bassline — Astrix DNA."""
    notes = []
    if not section.has_bass:
        return notes

    beats_per_bar = 4
    sixteenth     = 0.25
    energy        = section.energy

    # Pick pattern complexity by energy
    if energy < 0.2:
        pool = ACID_PATTERNS['sparse']
    elif energy < 0.5:
        pool = ACID_PATTERNS['mid']
    elif energy < 0.85:
        pool = ACID_PATTERNS['full'][:2]
    else:
        pool = ACID_PATTERNS['full']

    # Vary pattern every 2 bars
    bars_per_pattern = 2
    current_deg      = 0

    for bar in range(section.bars):
        abs_bar  = bar_offset + bar
        bar_beat = abs_bar * beats_per_bar

        if bar % bars_per_pattern == 0:
            pattern = random.choice(pool)

        for step, deg in enumerate(pattern[:16]):
            t    = bar_beat + step * sixteenth
            midi = degree_to_midi(deg, root, scale_name, octave_shift=-1)

            # Velocity: accent on degree-1 (the b2 Arabic tension note)
            # and on downbeats — simulates filter-envelope accent
            if deg == 1:
                vel = random.randint(95, 115)   # b2 accent
            elif step % 4 == 0:
                vel = random.randint(85, 100)   # beat accent
            elif step % 2 == 0:
                vel = random.randint(65, 80)
            else:
                vel = random.randint(45, 65)    # 16th note ghost

            # Note length depends on energy — shorter = more staccato acid
            if energy > 0.7:
                dur = sixteenth * random.choice([0.5, 0.6, 0.8])
            else:
                dur = sixteenth * random.choice([0.7, 0.9, 1.2])

            notes.append((t, midi, vel, dur))

    return notes


def _make_progression(total_bars, bars_per_chord):
    """Generate a chord root degree progression."""
    # Phrygian Dominant harmonic movement — cadential patterns
    progressions = [
        [0, 0, 4, 0],
        [0, 5, 4, 0],
        [0, 7, 5, 0],
        [0, 0, 7, 5],
    ]
    prog = random.choice(progressions)
    result = []
    bar = 0
    i = 0
    while bar < total_bars:
        result.append((bar, prog[i % len(prog)]))
        bar += bars_per_chord
        i += 1
    return result
