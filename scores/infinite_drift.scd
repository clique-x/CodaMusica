// ═════════════════════════════════════════════════════════════
// CodaMusica — "Infinite Drift"
// An algorithmically composed, infinite, never-repeating score.
//
// Architecture:
//   - 3 independent voices, each driven by its own Markov chains
//   - Voices drift through scales independently (slow modulation)
//   - A "macro clock" shifts the overall harmonic root every ~30s
//   - Rhythmic density breathes via a slow LFO (Pbrown)
//   - Nothing loops on a fixed period — the music evolves forever
//
// USAGE:
//   1. Boot server:  s.boot
//   2. Load synths:  load("/path/to/CodaMusica/synths/voices.scd")
//   3. Load utils:   load("/path/to/CodaMusica/utils/scales.scd")
//                    load("/path/to/CodaMusica/utils/markov.scd")
//   4. Load score:   load this file
//   5. To stop:      ~drift.stop; ~driftBass.stop; ~driftAir.stop;
// ═════════════════════════════════════════════════════════════

(
// ── Shared state ──────────────────────────────────────────────
~root      = 48;   // MIDI C3 — root note, will drift
~scaleKey  = \dorian;
~melDeg    = 0;    // current melody degree
~bassDeg   = 0;    // current bass degree
~airDeg    = 4;    // current air/high voice degree
~rhythmDur = 0.5;
~bassRhythm = 1.0;
~airRhythm  = 2.0;
~dynMel    = 0.2;
~dynBass   = 0.15;
~dynAir    = 0.1;
~regMel    = 0;
~regBass   = -1;
~regAir    = 1;

// ── Macro clock — root + scale drift every 25–45 seconds ─────
~macroClock = Task({
    var scaleOptions = [
        \dorian, \phrygian, \lydian, \mixolydian,
        \pentatonicMinor, \japanese, \wholeTone
    ];
    var rootOptions = [36, 38, 40, 41, 43, 45, 48]; // C2–C3 range
    loop {
        (25 + 20.rand).wait;
        ~scaleKey = scaleOptions.choose;
        ~root     = rootOptions.choose;
        ("*** Macro shift → root: % scale: %".format(~root, ~scaleKey)).postln;
    }
}).play;

// ── Voice 1: Melody (mallet) ───────────────────────────────────
~drift = Routine({
    loop {
        var freq, dur, amp, pan;

        // Advance Markov chains
        ~melDeg    = ~markov[\next].value(~melodyChain, ~melDeg);
        ~rhythmDur = ~markov[\next].value(~rhythmChain, ~rhythmDur);
        ~dynMel    = ~markov[\next].value(~dynamicsChain, ~dynMel);
        ~regMel    = ~markov[\next].value(~registerChain, ~regMel);

        freq = ~scales[\degToFreq].value(~scaleKey, ~melDeg, ~root, ~regMel + 1);
        dur  = ~rhythmDur;
        amp  = ~dynMel;
        pan  = rrand(-0.4, 0.4);

        Synth(\mallet, [
            \freq, freq,
            \amp,  amp,
            \pan,  pan
        ]);

        dur.wait;
    }
}).play;

// ── Voice 2: Bass (pluck) ──────────────────────────────────────
~driftBass = Routine({
    loop {
        var freq, dur, amp;

        ~bassDeg    = ~markov[\next].value(~melodyChain, ~bassDeg);
        ~bassRhythm = ~markov[\next].value(~rhythmChain, ~bassRhythm);
        ~dynBass    = ~markov[\next].value(~dynamicsChain, ~dynBass);

        // Bass gravitates toward root/fifth — occasional override
        if (0.3.coin) { ~bassDeg = [0, 4, 7].choose };

        freq = ~scales[\degToFreq].value(~scaleKey, ~bassDeg, ~root, -1);
        dur  = ~bassRhythm * rrand(0.8, 1.4);  // slight human timing
        amp  = ~dynBass * 1.5;

        Synth(\pluck, [
            \freq,  freq,
            \amp,   amp,
            \pan,   rrand(-0.6, 0.6),
            \decay, rrand(1.5, 4.0)
        ]);

        dur.wait;
    }
}).play;

// ── Voice 3: Air layer (pad + breath) ─────────────────────────
~driftAir = Routine({
    loop {
        var freq, dur, amp, useBreath;

        ~airDeg    = ~markov[\next].value(~melodyChain, ~airDeg);
        ~airRhythm = ~markov[\next].value(~rhythmChain, ~airRhythm);
        ~dynAir    = ~markov[\next].value(~dynamicsChain, ~dynAir);
        ~regAir    = ~markov[\next].value(~registerChain, ~regAir);

        freq      = ~scales[\degToFreq].value(~scaleKey, ~airDeg, ~root, ~regAir + 1);
        dur       = (~airRhythm * rrand(2.0, 5.0)).max(2.0);  // always slow
        amp       = ~dynAir * 0.8;
        useBreath = 0.35.coin;

        if (useBreath) {
            Synth(\breath, [
                \freq, freq * rrand(0.98, 1.02),
                \amp,  amp * 0.6,
                \atk,  rrand(1.0, 3.0),
                \rel,  rrand(3.0, 8.0),
                \pan,  rrand(-0.7, 0.7)
            ]);
        } {
            Synth(\pad, [
                \freq,   freq,
                \amp,    amp,
                \atk,    rrand(0.5, 2.5),
                \rel,    rrand(3.0, 7.0),
                \pan,    rrand(-0.5, 0.5),
                \cutoff, rrand(800, 3000)
            ]);
        };

        dur.wait;
    }
}).play;

"────────────────────────────────────────────────────".postln;
"Infinite Drift is playing.".postln;
"To stop: ~drift.stop; ~driftBass.stop; ~driftAir.stop; ~macroClock.stop;".postln;
"────────────────────────────────────────────────────".postln;
)


// ── STOP ALL ─────────────────────────────────────────────────
// Uncomment and run this block to stop everything gracefully:
/*
(
~drift.stop;
~driftBass.stop;
~driftAir.stop;
~macroClock.stop;
s.freeAll;
"Stopped.".postln;
)
*/
