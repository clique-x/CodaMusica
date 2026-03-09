"""Assembles all instrument tracks into a GarageBand-compatible MIDI file."""

from midiutil import MIDIFile
from composer.song import ARTCORE_DERVISH_SECTIONS, section_start_bars, total_bars
from composer.instruments.kick import generate_kick, generate_hihat
from composer.instruments.bass import generate_sub_bass, generate_acid_bass
from composer.instruments.pads import generate_pads
from composer.instruments.oud  import generate_oud
from composer.instruments.lead import generate_lead

# MIDI channel assignments (0-indexed)
CH_DRUMS    = 9   # Channel 10 in GM — always drums
CH_SUB      = 0
CH_ACID     = 1
CH_PAD      = 2
CH_LEAD     = 3
CH_OUD      = 4

# Track indices
TRK_DRUMS   = 0
TRK_SUB     = 1
TRK_ACID    = 2
TRK_PAD     = 3
TRK_LEAD    = 4
TRK_OUD     = 5

TRACK_NAMES = [
    "Kick + Hi-Hat  [GarageBand: Drum Kit]",
    "Sub Bass       [GarageBand: Deep Sub Bass]",
    "Acid Bass      [GarageBand: Classic Electric Bass / Moog Bass]",
    "Pads           [GarageBand: Vintage Pads / Ethereal Voices]",
    "Lead           [GarageBand: Saw Lead / FM Electric Piano]",
    "Oud / Pluck    [GarageBand: Sitar / Acoustic Guitar Fingerpick]",
]


def generate_song(
    bpm=132,
    root=50,           # D3
    scale_name='phrygian_dominant',
    sections=None,
    output_path="song.mid",
):
    if sections is None:
        sections = ARTCORE_DERVISH_SECTIONS

    num_tracks  = 6
    midi        = MIDIFile(num_tracks, adjust_origin=False)
    starts      = section_start_bars(sections)

    # ── Global setup ─────────────────────────────────────────
    for trk in range(num_tracks):
        midi.addTrackName(trk, 0, TRACK_NAMES[trk])
        midi.addTempo(trk, 0, bpm)
        midi.addTimeSignature(trk, 0, 4, 2, 24)  # 4/4

    # ── Generate each section ────────────────────────────────
    for section, bar_offset in zip(sections, starts):
        print(f"  Composing: {section.name:12s} ({section.bars} bars, energy {section.energy:.2f})  —  {section.description}")

        # Drums
        for (t, note, vel, dur) in generate_kick(section, bar_offset):
            midi.addNote(TRK_DRUMS, CH_DRUMS, note, t, dur, vel)
        for (t, note, vel, dur) in generate_hihat(section, bar_offset):
            midi.addNote(TRK_DRUMS, CH_DRUMS, note, t, dur, vel)

        # Sub bass
        for (t, note, vel, dur) in generate_sub_bass(section, bar_offset, root, scale_name):
            midi.addNote(TRK_SUB, CH_SUB, note, t, dur, vel)

        # Acid bass
        for (t, note, vel, dur) in generate_acid_bass(section, bar_offset, root, scale_name):
            midi.addNote(TRK_ACID, CH_ACID, note, t, dur, vel)

        # Pads
        for (t, note, vel, dur) in generate_pads(section, bar_offset, root, scale_name):
            midi.addNote(TRK_PAD, CH_PAD, note, t, dur, vel)

        # Lead
        for (t, note, vel, dur) in generate_lead(section, bar_offset, root, scale_name):
            midi.addNote(TRK_LEAD, CH_LEAD, note, t, dur, vel)

        # Oud
        for (t, note, vel, dur) in generate_oud(section, bar_offset, root, scale_name):
            midi.addNote(TRK_OUD, CH_OUD, note, t, dur, vel)

    # ── Write file ───────────────────────────────────────────
    with open(output_path, "wb") as f:
        midi.writeFile(f)

    total = total_bars(sections)
    mins  = (total * 4 / bpm)
    print(f"\n  Total: {total} bars = {mins:.1f} minutes at {bpm} BPM")
    print(f"  Saved: {output_path}")
    return output_path
