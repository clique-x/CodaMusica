"""Kick drum pattern generator — psytrance/psybient style."""

import random

# GM MIDI drum notes
KICK  = 36   # Bass Drum 1
SNARE = 38   # Acoustic Snare
CLAP  = 39   # Hand Clap (accent)
HIHAT_CLOSED = 42
HIHAT_OPEN   = 46
SHAKER = 70  # High Agogo (shaker-ish in GM)
RIDE   = 51
CRASH  = 49

def generate_kick(section, bar_offset, bars_per_chord=4):
    """
    Returns list of (beat_position, note, velocity, duration_beats).
    beat_position is absolute from song start.
    """
    notes = []
    beats_per_bar = 4
    sixteenth = 0.25  # beats

    if not section.has_kick:
        return notes

    density = section.kick_density
    energy  = section.energy

    for bar in range(section.bars):
        abs_bar = bar_offset + bar
        bar_beat = abs_bar * beats_per_bar

        for step in range(16):  # 16th note grid
            t = bar_beat + step * sixteenth

            # 4-on-the-floor positions: 0, 4, 8, 12
            on_beat = (step % 4 == 0)

            if on_beat and density >= 1.0:
                # Full 4-on-the-floor
                vel = random.randint(95, 115)
                notes.append((t, KICK, vel, sixteenth * 0.9))

            elif on_beat and density >= 0.5:
                # Half-time — only beats 1 and 3
                if step in (0, 8) and random.random() < density:
                    vel = random.randint(88, 108)
                    notes.append((t, KICK, vel, sixteenth * 0.9))

            elif on_beat and density > 0:
                # Sparse — just downbeat
                if step == 0 and random.random() < density * 1.5:
                    vel = random.randint(80, 100)
                    notes.append((t, KICK, vel, sixteenth * 0.9))

            # Off-beat ghost kicks in high energy sections
            if energy > 0.7 and not on_beat and random.random() < 0.06:
                vel = random.randint(50, 70)
                notes.append((t, KICK, vel, sixteenth * 0.7))

    return notes


def generate_hihat(section, bar_offset):
    """Hi-hat / shaker pattern."""
    notes = []
    beats_per_bar = 4
    sixteenth = 0.25

    if not section.has_perc:
        return notes

    energy  = section.energy

    for bar in range(section.bars):
        abs_bar = bar_offset + bar
        bar_beat = abs_bar * beats_per_bar

        for step in range(16):
            t = bar_beat + step * sixteenth

            # Probability of hi-hat firing scales with energy
            if energy > 0.8:
                prob = 0.85 if step % 2 == 0 else 0.45
            elif energy > 0.5:
                prob = 0.7 if step % 4 == 0 else 0.25
            elif energy > 0.2:
                prob = 0.5 if step % 8 == 0 else 0.12
            else:
                prob = 0.2 if step % 8 == 0 else 0.0

            if random.random() < prob:
                vel = random.randint(
                    int(40 + energy * 40),
                    int(65 + energy * 35)
                )
                # Mostly closed hat, occasionally open
                note = HIHAT_OPEN if (step % 8 == 6 and random.random() < 0.3) else HIHAT_CLOSED
                dur  = 0.18 if note == HIHAT_CLOSED else 0.35
                notes.append((t, note, vel, dur))

    return notes
