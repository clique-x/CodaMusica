# CodaMusica

> Music made with code. Infinite, never-repeating algorithmic scores.

## Stack

- **SuperCollider 3.14** — audio synthesis + live coding
- **sclang** — SuperCollider's pattern/algorithmic language
- **Markov chains** — melodic/rhythmic flow
- **Stochastic processes** — dynamics, register, texture

## Project Structure

```
CodaMusica/
├── synths/
│   └── voices.scd        — SynthDef library (pad, pluck, mallet, breath)
├── utils/
│   ├── scales.scd         — Scale definitions + degree→frequency helpers
│   └── markov.scd         — Markov chain engine + default chains
├── scores/
│   └── infinite_drift.scd — Full score: 3 voices, infinite, never-repeating
├── sketches/
│   └── hello_sound.scd    — Quick audio sanity check
└── README.md
```

## How to Run "Infinite Drift"

1. Open **SuperCollider.app**
2. Open `sketches/hello_sound.scd` — boot server, confirm audio works
3. In the SuperCollider IDE, load files in order (Cmd+Enter on each block):

```supercollider
load(Platform.userHomeDir ++ "/CodaMusica/synths/voices.scd");
load(Platform.userHomeDir ++ "/CodaMusica/utils/scales.scd");
load(Platform.userHomeDir ++ "/CodaMusica/utils/markov.scd");
load(Platform.userHomeDir ++ "/CodaMusica/scores/infinite_drift.scd");
```

4. The music starts immediately. It will never repeat.

To stop everything:
```supercollider
~drift.stop; ~driftBass.stop; ~driftAir.stop; ~macroClock.stop; s.freeAll;
```

---

## How It Works

### Three Layers of Infinity

| Layer | Mechanism | Effect |
|---|---|---|
| **Micro** | Markov chains on melody, rhythm, dynamics | Each note flows naturally from the last |
| **Meso** | Stochastic register + humanized timing | Phrases wander unpredictably |
| **Macro** | Timer shifts root + scale every 25–45s | The harmonic world itself slowly changes |

### Voices

- **Voice 1 — mallet** — melodic lead, walks the scale via Markov chain
- **Voice 2 — pluck** — bass, gravitates toward root/fifth but wanders
- **Voice 3 — pad/breath** — slow atmospheric layer, 2–10s note durations

### Scales Available

`dorian` `phrygian` `lydian` `mixolydian` `pentatonicMinor`
`pentatonicMajor` `wholeTone` `diminished` `japanese` `arabic`

---

## Ideas / Roadmap

- [ ] MIDI export — record a session to file
- [ ] Score 2: "Cellular Automata" — Conway's Game of Life → rhythm grid
- [ ] OSC bridge → visualizer (p5.js / Processing)
- [ ] Global reverb/effects bus
- [ ] L-system melody generator
- [ ] CLI launcher script
