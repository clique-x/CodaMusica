"""Oud/plucked string melody — Gurdjieff/Dervish DNA."""

import random
from composer.scales import degree_to_midi
from composer.markov import MELODY_CHAIN, RHYTHM_CHAIN

# Characteristic oud phrases (scale degrees)
# The b2 (degree 1) appears for colour then resolves — classic maqam movement
OUD_PHRASES = {
    'whisper': [
        [0], [4], [0, 4], [0, 4, 7],
    ],
    'melodic': [
        [0, 1, 0],
        [4, 5, 4, 0],
        [7, 5, 4, 0],
        [0, 4, 5, 4],
        [4, 7, 5, 4, 1, 0],
        [0, 1, 4, 5, 4, 1],
    ],
    'ornamental': [
        [7, 8, 7, 5, 4],
        [4, 5, 4, 3, 4],
        [0, 1, 0, 7, 0],
        [5, 4, 5, 7, 5, 4, 0],
    ],
}


def generate_oud(section, bar_offset, root, scale_name):
    """Sparse, organic oud melody with characteristic maqam ornaments."""
    notes = []
    if not section.has_oud:
        return notes

    beats_per_bar = 4
    energy        = section.energy

    # Choose phrase complexity by energy
    if energy < 0.15:
        phrase_pool = OUD_PHRASES['whisper']
        note_len    = 2.0    # beats per note (slow)
        gap_bars    = random.uniform(2.0, 5.0)
    elif energy < 0.5:
        phrase_pool = OUD_PHRASES['melodic']
        note_len    = 1.0
        gap_bars    = random.uniform(1.0, 3.0)
    else:
        phrase_pool = OUD_PHRASES['melodic'] + OUD_PHRASES['ornamental']
        note_len    = 0.5
        gap_bars    = random.uniform(0.5, 2.0)

    t = bar_offset * beats_per_bar
    end_t = (bar_offset + section.bars) * beats_per_bar

    while t < end_t:
        phrase = random.choice(phrase_pool)
        oct_shift = random.choice([0, 0, 0, 1, -1])

        for deg in phrase:
            if t >= end_t:
                break
            midi = degree_to_midi(deg, root, scale_name, oct_shift + 1)

            # Velocity: oud is very dynamic — accent on b2, soft elsewhere
            if deg == 1:
                vel = random.randint(85, 105)
            elif deg in (0, 4, 7):
                vel = random.randint(70, 90)
            else:
                vel = random.randint(55, 75)

            # Note duration — short for ornaments, longer for melody notes
            dur = note_len * random.uniform(0.7, 1.1)
            dur = min(dur, note_len * 1.5)

            notes.append((t, midi, vel, dur * 0.85))  # slight staccato
            t += note_len

        # Gap between phrases
        t += gap_bars * beats_per_bar * random.uniform(0.8, 1.3)

    return notes
