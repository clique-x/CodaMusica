"""Psychedelic lead melody — Artcore/FM-style sparse voice."""

import random
from composer.scales import degree_to_midi
from composer.markov import MELODY_CHAIN, RHYTHM_CHAIN, VELOCITY_CHAIN


def generate_lead(section, bar_offset, root, scale_name):
    """Sparse, floating psychedelic lead melody."""
    notes = []
    if not section.has_lead:
        return notes

    beats_per_bar = 4
    energy        = section.energy
    gap_bars      = section.lead_gap_bars

    t     = bar_offset * beats_per_bar
    end_t = (bar_offset + section.bars) * beats_per_bar

    deg     = random.choice([0, 4, 7])
    vel_state = 70

    while t < end_t:
        # How many notes in this phrase
        phrase_len = random.randint(3, 8) if energy > 0.7 else random.randint(2, 5)

        for _ in range(phrase_len):
            if t >= end_t:
                break

            deg       = MELODY_CHAIN.next(deg)
            dur_16ths = RHYTHM_CHAIN.next(random.choice([2, 4, 8]))
            dur_beats = dur_16ths * 0.25
            oct_shift = random.choices([1, 2, 0], weights=[0.5, 0.3, 0.2])[0]

            midi      = degree_to_midi(deg, root, scale_name, oct_shift)
            vel_state = VELOCITY_CHAIN.next(vel_state)
            vel       = min(120, vel_state + random.randint(-8, 8))

            notes.append((t, midi, vel, dur_beats * 0.88))
            t += dur_beats

        # Rest between phrases — the "psychedelic space" between notes
        t += gap_bars * beats_per_bar * random.uniform(0.6, 1.5)

    return notes
