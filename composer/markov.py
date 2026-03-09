"""Markov chain engine for melodic and rhythmic movement."""

import random

class MarkovChain:
    def __init__(self, transitions):
        """transitions: list of (from_state, to_state, weight)"""
        self.table = {}
        for from_s, to_s, weight in transitions:
            self.table.setdefault(from_s, []).append((to_s, weight))

    def next(self, current):
        options = self.table.get(current)
        if not options:
            return current
        states, weights = zip(*options)
        return random.choices(states, weights=weights)[0]


# ── Melodic movement — Phrygian Dominant feel ────────────────────────────────
# Degree 1 (b2) is the dark Arabic note — approach it, leave it quickly
MELODY_CHAIN = MarkovChain([
    (0, 0, 4), (0, 1, 2), (0, 4, 5), (0, 7, 3),
    (1, 0, 6), (1, 4, 3), (1, 5, 2),             # b2 resolves quickly
    (2, 1, 2), (2, 4, 5), (2, 5, 3),
    (3, 2, 3), (3, 4, 5), (3, 5, 3),
    (4, 0, 3), (4, 3, 3), (4, 5, 5), (4, 7, 3),
    (5, 4, 4), (5, 7, 5), (5, 3, 2),
    (6, 5, 4), (6, 4, 3), (6, 7, 4),
    (7, 0, 5), (7, 5, 3), (7, 4, 3),
])

# ── Rhythm durations (in 16th notes) ────────────────────────────────────────
RHYTHM_CHAIN = MarkovChain([
    (1, 1, 6), (1, 2, 4), (1, 4, 1),
    (2, 1, 4), (2, 2, 5), (2, 4, 3), (2, 8, 1),
    (4, 2, 3), (4, 4, 5), (4, 8, 4), (4, 1, 2),
    (8, 4, 4), (8, 8, 3), (8, 16, 2), (8, 2, 2),
    (16, 8, 4), (16, 16, 3), (16, 4, 2),
])

# ── Velocity/dynamics ────────────────────────────────────────────────────────
VELOCITY_CHAIN = MarkovChain([
    (40, 40, 2), (40, 55, 5), (40, 70, 2),
    (55, 40, 3), (55, 55, 5), (55, 70, 4), (55, 85, 2),
    (70, 55, 3), (70, 70, 5), (70, 85, 3), (70, 95, 1),
    (85, 70, 4), (85, 85, 4), (85, 95, 2),
    (95, 85, 4), (95, 70, 3),
])
