// ═════════════════════════════════════════════════════════════
// CodaMusica — "Psybient Journey"
//
// A living, breathing multi-stage composition.
// Psybient core. Progressive pulse. Psychedelic depth.
//
// STAGES:
//   0 — Void          Pure space. No rhythm. Just texture.
//   1 — Awakening     A pulse stirs. Low and distant. Pads breathe.
//   2 — Midway        The sweet spot. Ambient + progressive in balance.
//   3 — Drive         Rhythm leads now. Psychedelic lead voice enters.
//   4 — Open Space    Rhythm recedes. Infinite. Expanded.
//
// LOAD ORDER:
//   s.boot;
//   load(Platform.userHomeDir ++ "/CodaMusica/synths/voices.scd");
//   load(Platform.userHomeDir ++ "/CodaMusica/synths/psy_voices.scd");
//   load(Platform.userHomeDir ++ "/CodaMusica/utils/scales.scd");
//   load(Platform.userHomeDir ++ "/CodaMusica/utils/markov.scd");
//   load(Platform.userHomeDir ++ "/CodaMusica/scores/psybient_journey.scd");
//
// STOP:
//   ~journey.stop;
// ═════════════════════════════════════════════════════════════

(
// ─────────────────────────────────────────────────────────────
// GLOBALS
// ─────────────────────────────────────────────────────────────
~bpm         = 104;
~clock       = TempoClock(~bpm / 60);
~beat        = ~bpm / 60;       // seconds per beat
~stage       = 0;
~running     = true;

// Scale: Phrygian Dominant — dark, psychedelic, a bit Arabic
// Root: B2 (MIDI 47) — deep but present
~psyRoot     = 47;
~psyScale    = [0, 1, 4, 5, 7, 8, 10];   // Phrygian dominant
~psyRootOpts = [47, 45, 43, 50];          // B, A, G, D — modal drift roots

// Harmonic state
~rootDeg     = 0;
~melDeg      = 4;
~leadDeg     = 4;
~melRhythm   = 1.0;

// Stage duration in seconds (not beats — feels more natural)
~stageDur = [
    120,   // Stage 0: Void         — 2 min
    150,   // Stage 1: Awakening    — 2.5 min
    180,   // Stage 2: Midway       — 3 min
    180,   // Stage 3: Drive        — 3 min
    0      // Stage 4: Open Space   — infinite
];

// Per-stage parameters (interpolated by routines reading ~stage)
~stageParams = [
    // [kickAmp, bassAmp, padAmp, shimmerAmp, leadAmp, droneAmp, hatAmp, bassNoteLen, kickPeriod]
    [0.0,  0.0,  0.35, 0.18, 0.0,  0.18, 0.0,  2.0,  16],  // 0 Void
    [0.25, 0.15, 0.30, 0.15, 0.0,  0.14, 0.05, 1.5,  8 ],  // 1 Awakening
    [0.45, 0.30, 0.28, 0.14, 0.0,  0.10, 0.12, 1.0,  4 ],  // 2 Midway
    [0.55, 0.40, 0.22, 0.12, 0.22, 0.08, 0.18, 0.5,  4 ],  // 3 Drive
    [0.20, 0.15, 0.38, 0.22, 0.10, 0.18, 0.06, 2.0,  8 ],  // 4 Open Space
];

// Helper: degree → freq in psy scale
~psyFreq = { |deg, root, octShift=0|
    var size = ~psyScale.size;
    var oct  = (deg / size).floor + octShift;
    var d    = deg % size;
    (root + ~psyScale[d] + (oct * 12)).midicps
};

// ─────────────────────────────────────────────────────────────
// BOOT EFFECTS CHAIN
// ─────────────────────────────────────────────────────────────
~fxGroup = Group.head(s);
~srcGroup = Group.after(~fxGroup);

// Reverb + Delay always running, fed by ~reverbBus / ~delayBus
~reverbSynth = Synth(\globalReverb, [\in, ~reverbBus, \out, 0, \mix, 0.65, \room, 0.97], ~fxGroup);
~delaySynth  = Synth(\globalDelay,  [\in, ~reverbBus, \out, 0, \delL, (3/8) * (~beat), \delR, (1/2) * (~beat), \fdbk, 0.40, \mix, 0.28], ~fxGroup);

// ─────────────────────────────────────────────────────────────
// DRONE — always running, volume changes with stage
// ─────────────────────────────────────────────────────────────
~droneSynth = Synth(\drone, [
    \out, 0, \freq, ~psyRoot.midicps * 0.5,
    \amp, 0.1, \cutoff, 250, \cutMod, 120, \modRate, 0.04
], ~srcGroup);

// ─────────────────────────────────────────────────────────────
// VOICE: SWEEP PADS — slow, wide, breathing
// ─────────────────────────────────────────────────────────────
~padRoutine = Routine({
    var deg = 0, prevDeg = 0;
    loop {
        var p    = ~stageParams[~stage];
        var amp  = p[2] * rrand(0.85, 1.15);
        var freq, dur, pan;

        // Slow harmonic movement — mostly root, fifth, minor third
        deg  = if(0.6.coin) {
            [0, 2, 4, 0, 0, 4].choose
        } {
            ~markov[\next].value(~melodyChain, deg)
        };
        freq = ~psyFreq.value(deg, ~psyRoot, rrand(0,1));
        dur  = rrand(8.0, 16.0);
        pan  = rrand(-0.5, 0.5);

        if(amp > 0.05) {
            Synth(\sweepPad, [
                \out, 0, \freq, freq, \amp, amp,
                \atk, rrand(3.0, 6.0), \sus, dur * 0.5, \rel, rrand(5.0, 9.0),
                \cutLo, if(~stage >= 2) { 600 } { 300 },
                \cutHi, if(~stage >= 3) { 4000 } { 2000 },
                \modRate, 0.05 + (~stage * 0.01),
                \pan, pan, \detune, rrand(0.008, 0.016)
            ], ~srcGroup);
        };
        rrand(5.0, 9.0).wait;
    }
}).play(~clock);

// ─────────────────────────────────────────────────────────────
// VOICE: SHIMMER — high crystal layer
// ─────────────────────────────────────────────────────────────
~shimmerRoutine = Routine({
    loop {
        var p    = ~stageParams[~stage];
        var amp  = p[3];
        var degs = [0, 4, 7, 2, 11];
        var deg  = degs.choose;
        var freq = ~psyFreq.value(deg, ~psyRoot, 2 + rrand(0,1));
        var dur  = rrand(10.0, 22.0);

        if(amp > 0.05) {
            Synth(\shimmerPad, [
                \out, 0, \freq, freq, \amp, amp * rrand(0.8, 1.2),
                \atk, rrand(4.0, 8.0), \rel, rrand(7.0, 14.0),
                \pan, rrand(-0.8, 0.8)
            ], ~srcGroup);
        };
        rrand(8.0, 16.0).wait;
    }
}).play(~clock);

// ─────────────────────────────────────────────────────────────
// VOICE: KICK PULSE — emerges in stage 1, rhythmic in 2/3
// ─────────────────────────────────────────────────────────────
~kickRoutine = Routine({
    var beatCount = 0;
    loop {
        var p      = ~stageParams[~stage];
        var amp    = p[0];
        var period = p[8];  // beats between kicks
        var swing  = if(~stage >= 2) { rrand(-0.02, 0.02) } { 0 };

        if(amp > 0.05) {
            Synth(\kickPulse, [
                \out, 0, \amp, amp * rrand(0.9, 1.1),
                \punch, 75 + (~stage * 5),
                \body,  38 + (~stage * 2),
                \dur,   0.6 + (~stage * 0.05)
            ], ~srcGroup);
        };

        // In stage 2+: add subtle off-beat accent every 2 kicks
        if(~stage >= 2 && beatCount.even && 0.3.coin) {
            (period * 0.5 * ~beat).wait;
            if(~stageParams[~stage][0] > 0.1) {
                Synth(\kickPulse, [\out, 0, \amp, ~stageParams[~stage][0] * 0.4,
                    \punch, 60, \body, 35, \dur, 0.4], ~srcGroup);
            };
            (period * 0.5 * ~beat + swing).wait;
        } {
            (period * ~beat + swing).wait;
        };
        beatCount = beatCount + 1;
    }
}).play(~clock);

// ─────────────────────────────────────────────────────────────
// VOICE: BASSLINE — acid phrygian walk
// ─────────────────────────────────────────────────────────────
~bassRoutine = Routine({
    var deg = 0, pattern, step = 0;
    // Bassline patterns per stage — degree sequences
    var patterns = [
        [[0, 0]],                                           // Stage 0: nothing
        [[0, 0, 0, 4]],                                     // Stage 1: root pulse
        [[0, 0, 3, 4], [0, 3, 0, 7], [0, 0, 3, 0]],       // Stage 2: moving
        [[0,3,4,3,0,7,4,0], [0,0,3,4,5,4,3,0]],           // Stage 3: running
        [[0, 0, 4, 0], [0, 3, 0, 7]],                      // Stage 4: spacious
    ];

    loop {
        var p        = ~stageParams[~stage];
        var amp      = p[1];
        var noteLen  = p[7];
        var curPats  = patterns[~stage];
        var seq      = curPats.choose;
        var cutFreq  = [400, 500, 700, 1200, 500][~stage] * rrand(0.9, 1.1);
        var res      = [0.5, 0.55, 0.65, 0.75, 0.55][~stage];

        seq.do { |d|
            var freq  = ~psyFreq.value(d, ~psyRoot, -1);
            var dur   = noteLen * ~beat * rrand(0.9, 1.05);
            if(amp > 0.05) {
                Synth(\psyBass, [
                    \out, 0, \freq, freq,
                    \amp, amp * rrand(0.85, 1.1),
                    \atk, 0.008, \rel, noteLen * 0.7,
                    \cutoff, cutFreq, \res, res,
                    \cutMod, cutFreq * 0.5,
                    \modRate, 0.3 + (~stage * 0.2)
                ], ~srcGroup);
                // Sub on root note only
                if(d == 0) {
                    Synth(\subBass, [
                        \out, 0, \freq, ~psyRoot.midicps * 0.25,
                        \amp, amp * 1.2, \atk, 0.02, \rel, noteLen * 0.9
                    ], ~srcGroup);
                };
            };
            dur.wait;
        };
    }
}).play(~clock);

// ─────────────────────────────────────────────────────────────
// VOICE: PSY LEAD — enters in stage 3, fades in stage 4
// ─────────────────────────────────────────────────────────────
~leadRoutine = Routine({
    var deg = 4;
    loop {
        var p   = ~stageParams[~stage];
        var amp = p[4];
        var dur, freq;

        if(amp > 0.02) {
            // Lead follows scale but with wider leaps in stage 3
            deg  = if(~stage >= 3) {
                ~markov[\next].value(~melodyChain, deg)
            } {
                [0, 2, 4, 7].choose  // more constrained in stage 4
            };
            freq = ~psyFreq.value(deg, ~psyRoot, 1 + rrand(0,1));
            dur  = [0.5, 1.0, 1.5, 2.0].wchoose([0.3, 0.35, 0.25, 0.1]) * ~beat;

            Synth(\psyLead, [
                \out, 0, \freq, freq,
                \amp, amp * rrand(0.85, 1.1),
                \atk, 0.08, \sus, dur * 0.6, \rel, dur * 1.2,
                \modIdx,   2.5 + (~stage * 0.5),
                \modRatio, [1.5, 2.0, 2.5, 3.0].choose,
                \wobble,   0.2 + LFNoise0.kr(0.1).range(0, 0.4),
                \pan, rrand(-0.5, 0.5)
            ], ~srcGroup);
        };
        (rrand(0.5, 3.0) * ~beat * (5 - ~stage.min(4)) * 0.25 + 0.5).wait;
    }
}).play(~clock);

// ─────────────────────────────────────────────────────────────
// VOICE: HI-HAT — subtle, brushed, evolves
// ─────────────────────────────────────────────────────────────
~hatRoutine = Routine({
    var beatCount = 0;
    loop {
        var p   = ~stageParams[~stage];
        var amp = p[6];

        // 16th note grid, but stochastic — fires ~60% of slots in stage 2+
        16.do { |i|
            var fire = case
                { ~stage <= 0 } { false }
                { ~stage == 1 } { i == 8 && 0.4.coin }
                { ~stage == 2 } { [0,4,8,12].includes(i) || (0.2.coin) }
                { ~stage == 3 } { [0,3,6,9,12,15].includes(i) || (0.35.coin) }
                { ~stage == 4 } { [0, 8].includes(i) || (0.15.coin) };

            if(fire && amp > 0.02) {
                Synth(\hat, [
                    \out, 0, \amp, amp * rrand(0.6, 1.2),
                    \dur, rrand(0.04, 0.14),
                    \tone, rrand(7000, 11000),
                    \pan, rrand(-0.6, 0.6)
                ], ~srcGroup);
            };
            (~beat / 4).wait;
        };
        beatCount = beatCount + 1;
    }
}).play(~clock);

// ─────────────────────────────────────────────────────────────
// STAGE CONTROLLER — the director
// ─────────────────────────────────────────────────────────────
~stageNames = ["Void", "Awakening", "Midway", "Drive", "Open Space"];

~stageController = Routine({
    ~stageDur.do { |dur, i|
        ~stage = i;
        "=== Stage % — % ===".format(i, ~stageNames[i]).postln;

        // Transition effect at stage change (except stage 0)
        if(i > 0) {
            Synth(\riser, [
                \out, 0,
                \amp, 0.15,
                \dur, 6.0,
                \loFreq, if(i <= 2) { 80 } { 200 },
                \hiFreq, if(i <= 2) { 1500 } { 5000 }
            ], ~srcGroup);
            3.0.wait;
        };

        // Update drone
        ~droneSynth.set(
            \amp,     ~stageParams[i][5],
            \cutoff,  [250, 300, 400, 500, 350][i],
            \cutMod,  [100, 150, 200, 250, 150][i],
            \modRate, [0.03, 0.05, 0.07, 0.09, 0.04][i]
        );

        // Wait for stage duration (0 = infinite — loop forever)
        if(dur > 0) { dur.wait } { nil.wait };   // nil.wait = hang forever
    };
}).play;

// ─────────────────────────────────────────────────────────────
// GLOBAL STOP — run this block to stop everything
// ─────────────────────────────────────────────────────────────
~journey = {
    ~padRoutine.stop;
    ~shimmerRoutine.stop;
    ~kickRoutine.stop;
    ~bassRoutine.stop;
    ~leadRoutine.stop;
    ~hatRoutine.stop;
    ~stageController.stop;
    ~droneSynth.free;
    ~reverbSynth.free;
    ~delaySynth.free;
    s.freeAll;
    "Journey ended.".postln;
};

"".postln;
"╔══════════════════════════════════════════╗".postln;
"║   PSYBIENT JOURNEY — Playing            ║".postln;
"║   BPM: %  Root: %  Scale: Phrygian Dom ║".format(~bpm, ~psyRoot).postln;
"║                                          ║".postln;
"║   ~journey.value  →  stop everything   ║".postln;
"╚══════════════════════════════════════════╝".postln;
"".postln;
)


// ─── MANUAL STAGE JUMP ────────────────────────────────────────
// Jump to any stage instantly (while playing):
// ~stage = 0;   // Void
// ~stage = 1;   // Awakening
// ~stage = 2;   // Midway  ← sweet spot
// ~stage = 3;   // Drive
// ~stage = 4;   // Open Space
