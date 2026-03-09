"""Song structure — sections, energy curves, timing."""

from dataclasses import dataclass, field
from typing import List

@dataclass
class Section:
    name: str
    bars: int           # length in bars
    energy: float       # 0.0–1.0
    has_kick: bool
    has_bass: bool
    has_pad: bool
    has_lead: bool
    has_oud: bool
    has_perc: bool
    kick_density: float     # 0–1, how many 16ths get a kick
    bass_note_len: int      # 16th notes per bass note
    pad_chord_len: int      # bars per chord change
    lead_gap_bars: float    # average bars between lead phrases
    description: str = ""

# At 132 BPM: 1 bar = 4 beats = 1.818 seconds
# Total ≈ 544 bars = 16.5 minutes

ARTCORE_DERVISH_SECTIONS: List[Section] = [
    Section(
        name="Intro", bars=64, energy=0.08,
        has_kick=False, has_bass=False, has_pad=True,
        has_lead=False, has_oud=True, has_perc=False,
        kick_density=0, bass_note_len=16, pad_chord_len=8,
        lead_gap_bars=99, description="Tanpura drone, oud whispers. Pure space."
    ),
    Section(
        name="Rise", bars=48, energy=0.30,
        has_kick=True, has_bass=True, has_pad=True,
        has_lead=False, has_oud=True, has_perc=True,
        kick_density=0.25, bass_note_len=8, pad_chord_len=8,
        lead_gap_bars=16, description="Kick stirs. Sub enters. Phrygian pulse."
    ),
    Section(
        name="Groove", bars=112, energy=0.62,
        has_kick=True, has_bass=True, has_pad=True,
        has_lead=False, has_oud=True, has_perc=True,
        kick_density=1.0, bass_note_len=2, pad_chord_len=4,
        lead_gap_bars=8, description="Full psybient. The sweet spot."
    ),
    Section(
        name="Breakdown", bars=32, energy=0.12,
        has_kick=False, has_bass=False, has_pad=True,
        has_lead=False, has_oud=True, has_perc=False,
        kick_density=0, bass_note_len=16, pad_chord_len=16,
        lead_gap_bars=8, description="Strip back. Oud + pad only. Tension builds."
    ),
    Section(
        name="Build", bars=32, energy=0.45,
        has_kick=True, has_bass=True, has_pad=True,
        has_lead=False, has_oud=False, has_perc=True,
        kick_density=0.5, bass_note_len=4, pad_chord_len=8,
        lead_gap_bars=99, description="Kick and bass return. Gathering energy."
    ),
    Section(
        name="Peak", bars=128, energy=0.90,
        has_kick=True, has_bass=True, has_pad=True,
        has_lead=True, has_oud=True, has_perc=True,
        kick_density=1.0, bass_note_len=1, pad_chord_len=4,
        lead_gap_bars=4, description="Full Artcore/Dervish energy. Everything."
    ),
    Section(
        name="Outro", bars=64, energy=0.10,
        has_kick=False, has_bass=False, has_pad=True,
        has_lead=False, has_oud=True, has_perc=False,
        kick_density=0, bass_note_len=16, pad_chord_len=8,
        lead_gap_bars=99, description="Dissolution. Return to space."
    ),
]

def section_start_bars(sections: List[Section]) -> List[int]:
    """Return the bar number where each section starts."""
    starts = []
    current = 0
    for s in sections:
        starts.append(current)
        current += s.bars
    return starts

def total_bars(sections: List[Section]) -> int:
    return sum(s.bars for s in sections)
