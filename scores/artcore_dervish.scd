// ═════════════════════════════════════════════════════════════
// CodaMusica — "Artcore Dervish"
//
// Built from analysis of your 4 reference tracks:
//   Astrix – Artcore (Hi Profile Remix)      → 144 BPM, B minor, psy energy
//   Gurdjieff – Psychedelic Dervish          → 152 BPM, D minor, oud warmth
//   Relax Shiva (Extended)                   → 123 BPM, warm psybient
//   Tarang                                   → 123 BPM, ultra-sub, dense percussion
//
// SYNTHESIS:
//   Root    : D (MIDI 50) — matches Tarang + Dervish
//   Scale   : Phrygian Dominant [0,1,4,5,7,8,10] — appeared in 3/4 tracks
//   BPM     : 132 — midpoint between Shiva (123) and Artcore (144)
//   Spectral: 65% sub / 25% bass target (Tarang 75%, Shiva 62% averaged)
//
// STAGES:
//   0 — Desert Night    Pure tanpura drone + oud whispers. No pulse.
//   1 — First Breath    Kick pulse stirs. Sub wakes up. Oud melodic.
//   2 — The Middle Way  Psybient + progressive in full balance. (your sweet spot)
//   3 — Dervish Drive   Full Artcore energy. Acid bass. Psy lead. Spinning.
//   4 — Open Desert     Rhythm softens. Space returns. Infinite.
//
// LOAD ORDER:
//   s.boot;
//   load(Platform.userHomeDir ++ "/CodaMusica/synths/artcore_voices.scd");
//   load(Platform.userHomeDir ++ "/CodaMusica/utils/scales.scd");
//   load(Platform.userHomeDir ++ "/CodaMusica/utils/markov.scd");
//   load(Platform.userHomeDir ++ "/CodaMusica/scores/artcore_dervish.scd");
//
// STOP:   ~dervish.value;
// STAGE:  ~stage = 2;  (jump anytime while playing)
// ═════════════════════════════════════════════════════════════

(
// ─────────────────────────────────────────────────────────────
// CLEANUP — safe to reload anytime
// ─────────────────────────────────────────────────────────────
[~oudRoutine, ~padRoutine, ~kickRoutine, ~bassRoutine,
 ~leadRoutine, ~hatRoutine, ~subRoutine, ~stageCtrl].do { |r|
    if(r.notNil) { r.stop }
};
[~tanpuraSynth, ~reverbSynth, ~delaySynth, ~fxGrp, ~srcGrp].do { |n|
    if(n.notNil) { n.free }
};

// ─────────────────────────────────────────────────────────────
// GLOBALS
// ─────────────────────────────────────────────────────────────
~bpm      = 132;
~clock    = TempoClock(~bpm / 60);
~beat     = 60 / ~bpm;
~stage    = 0;

// Phrygian Dominant in D — dark, Arabic, psychedelic
// D  Eb  F#  G  A  Bb  C
~root     = 50;         // D3
~scale    = [0,1,4,5,7,8,10];

// Helper: scale degree → Hz
~freq = { |deg, octShift=0|
    var size = ~scale.size;
    var oct  = (deg / size).floor.asInteger + octShift;
    var d    = (deg % size).asInteger;
    (~root + ~scale[d] + (oct * 12)).midicps
};

// ── Stage parameter table ─────────────────────────────────────
// [kickAmp, bassAmp, padAmp, oudAmp, leadAmp, hatAmp,
//  subAmp, bassNoteDur(beats), kickEvery(beats), cutLo, cutHi]
~sp = [
    [0.0,  0.0,  0.28, 0.45, 0.0,  0.0,  0.30, 4.0, 16, 180, 900 ],  // 0 Desert Night
    [0.40, 0.20, 0.25, 0.38, 0.0,  0.06, 0.45, 2.0, 4,  250, 1400],  // 1 First Breath
    [0.60, 0.35, 0.22, 0.28, 0.0,  0.12, 0.55, 1.0, 4,  350, 2200],  // 2 Middle Way
    [0.70, 0.45, 0.18, 0.20, 0.24, 0.18, 0.60, 0.5, 4,  500, 3200],  // 3 Dervish Drive
    [0.25, 0.18, 0.30, 0.40, 0.10, 0.07, 0.40, 2.0, 8,  220, 1600],  // 4 Open Desert
];

~stageNames = ["Desert Night","First Breath","Middle Way","Dervish Drive","Open Desert"];
~stageDurs  = [120, 150, 200, 200, 0];  // seconds, 0 = infinite

// ─────────────────────────────────────────────────────────────
// BOOT — groups + fx chain
// ─────────────────────────────────────────────────────────────
fork {
    ~fxGrp  = Group.head(s);
    ~srcGrp = Group.after(~fxGrp);
    s.sync;

    ~reverbSynth = Synth(\artReverb, [
        \in, ~reverbBus, \out, 0, \mix, 0.58, \room, 0.98
    ], ~fxGrp);

    ~delaySynth = Synth(\artDelay, [
        \in, ~reverbBus, \out, 0,
        \delL, ~beat * (3/8),
        \delR, ~beat * (5/8),
        \fdbk, 0.38, \mix, 0.22
    ], ~fxGrp);

    // Tanpura drone — always running, amplitude set by stage
    ~tanpuraSynth = Synth(\tanpura, [
        \out, 0, \freq, ~root.midicps * 0.5,  // D2 — sub register
        \amp, 0.28, \cutoff, 220, \modRate, 0.035
    ], ~srcGrp);

    s.sync;

    // ─────────────────────────────────────────────────────────
    // VOICE: OUD — melodic, harmonic, Gurdjieff-inspired
    // ─────────────────────────────────────────────────────────
    ~oudRoutine = Routine({
        // Melodic patterns per stage (degree sequences)
        var pats = [
            [[0],[0,4],[0,4,7,4]],               // Stage 0: whispers, root-ish
            [[0,4,0,7],[0,3,4,3]],               // Stage 1: small movement
            [[0,4,7,4,3,4],[0,1,4,5,4,1]],       // Stage 2: full phrases
            [[0,1,4,5,4,3,1,0],[4,5,7,5,4,3]],  // Stage 3: running
            [[0,4,0,7],[0,0,4]],                 // Stage 4: spacious again
        ];
        loop {
            var p    = ~sp[~stage];
            var amp  = p[3];
            var seq  = pats[~stage].choose;
            var base = if(~stage <= 1) { rrand(0.8,1.6) } { rrand(0.4,1.0) };

            seq.do { |deg|
                var f    = ~freq.value(deg, rrand(0,1));
                var dur  = base * ~beat * rrand(0.85, 1.2);
                var dec  = rrand(1.5, 3.5);
                var pan  = rrand(-0.55, 0.55);
                if(amp > 0.02) {
                    Synth(\oud, [
                        \out, 0, \freq, f, \amp, amp * rrand(0.8,1.15),
                        \decay, dec, \pan, pan,
                        \bright, if(~stage >= 3) { 0.45 } { 0.25 }
                    ], ~srcGrp);
                };
                dur.wait;
            };
            // Occasional silence between phrases
            if(0.35.coin) { (rrand(0.5, 2.0) * ~beat).wait };
        }
    }).play(~clock);

    // ─────────────────────────────────────────────────────────
    // VOICE: DARK PAD — slow, filtered, wide
    // ─────────────────────────────────────────────────────────
    ~padRoutine = Routine({
        loop {
            var p   = ~sp[~stage];
            var amp = p[2];
            var deg = [0, 0, 4, 7, 0].wchoose([0.35, 0.25, 0.2, 0.15, 0.05]);
            var f   = ~freq.value(deg, rrand(0,1));
            var dur = rrand(9.0, 18.0);
            var atk = rrand(3.0, 7.0);

            if(amp > 0.02) {
                Synth(\darkPad, [
                    \out, 0, \freq, f, \amp, amp,
                    \atk, atk, \sus, dur * 0.4, \rel, rrand(5.0, 10.0),
                    \cutLo, p[9], \cutHi, p[10],
                    \modRate, 0.04 + (~stage * 0.015),
                    \pan, rrand(-0.5, 0.5)
                ], ~srcGrp);
            };
            rrand(6.0, 12.0).wait;
        }
    }).play(~clock);

    // ─────────────────────────────────────────────────────────
    // VOICE: PSYTRANCE KICK — the Artcore spine
    // ─────────────────────────────────────────────────────────
    ~kickRoutine = Routine({
        loop {
            var p          = ~sp[~stage];
            var amp        = p[0];
            var kickEvery  = p[8];

            if(amp > 0.05) {
                Synth(\psyKick, [
                    \out, 0,
                    \amp,       amp * rrand(0.92, 1.05),
                    \punch,     if(~stage >= 3) { 155 } { 135 },
                    \body,      if(~stage >= 3) { 42  } { 46  },
                    \sweepTime, 0.052,
                    \tail,      0.65
                ], ~srcGrp);

                // Sub thump under every kick
                Synth(\subThump, [
                    \out, 0, \freq, ~root.midicps * 0.5,
                    \amp, p[6], \dur, 0.7
                ], ~srcGrp);
            };

            // Off-beat accent kick in stages 2-3
            if(~stage >= 2 && kickEvery == 4) {
                (~beat * 2).wait;
                if(p[0] > 0.1 && 0.5.coin) {
                    Synth(\psyKick, [
                        \out, 0, \amp, p[0] * 0.35,
                        \punch, 100, \body, 50, \tail, 0.4
                    ], ~srcGrp);
                };
                (~beat * 2).wait;
            } {
                (~beat * kickEvery).wait;
            };
        }
    }).play(~clock);

    // ─────────────────────────────────────────────────────────
    // VOICE: ACID BASS — 16th note rolling bassline
    // Phrygian Dominant patterns (the b2 interval is the key — degree 1)
    // ─────────────────────────────────────────────────────────
    ~bassRoutine = Routine({
        // Bassline sequences: degree + accent (1=accented)
        // Degree 1 = b2 = the dark "Arabic" note — use it sparingly for tension
        var seqs = [
            [[0,0,0,0]],                            // Stage 0: silent
            [[0,0,0,4]],                            // Stage 1: root pulse
            [[0,0,4,0,0,7,4,0],[0,0,0,4,3,4,0,0]], // Stage 2
            [[0,0,4,0,1,0,7,4,0,0,4,0,1,4,7,4],    // Stage 3: full acid
             [0,1,4,5,4,1,0,4]],
            [[0,0,4,0],[0,0,0,7]],                  // Stage 4: spacious
        ];
        loop {
            var p    = ~sp[~stage];
            var amp  = p[1];
            var dur  = p[7];
            var seq  = seqs[~stage].choose;
            var cut  = p[9] * rrand(1.0, 1.5);
            var cenv = p[10] * 0.6;

            seq.do { |deg|
                var f   = ~freq.value(deg, -1);
                var d   = dur * ~beat * rrand(0.92, 1.05);
                var acc = if(deg == 1) { 1.3 } { 1.0 };  // accent b2

                if(amp > 0.02) {
                    Synth(\acidBass, [
                        \out, 0, \freq, f,
                        \amp, amp * acc * rrand(0.85, 1.1),
                        \dur, d * 0.85,
                        \cutoff, cut, \res, 0.72 + (~stage * 0.03),
                        \cutEnvAmt, cenv,
                        \cutDecay, 0.12 + (~stage * 0.02)
                    ], ~srcGrp);
                };
                d.wait;
            };
        }
    }).play(~clock);

    // ─────────────────────────────────────────────────────────
    // VOICE: PSY LEAD — enters stage 3, FM psychedelic
    // ─────────────────────────────────────────────────────────
    ~leadRoutine = Routine({
        loop {
            var p   = ~sp[~stage];
            var amp = p[4];

            if(amp > 0.02) {
                var deg = [0,1,4,5,7,4,0,7].choose;
                var f   = ~freq.value(deg, 1 + rrand(0,1));
                var dur = [0.5,0.5,1.0,1.5,2.0].wchoose([0.15,0.3,0.3,0.15,0.1]) * ~beat;

                Synth(\psyLead2, [
                    \out, 0, \freq, f,
                    \amp, amp * rrand(0.85, 1.1),
                    \atk, 0.05, \sus, dur * 0.5, \rel, dur * 1.5,
                    \modIdx,   3.5 + (~stage * 0.3),
                    \modRatio, [1.5, 2.0, 2.01, 3.0, 2.5].choose,
                    \wobble,   0.18 + LFNoise0.kr(0.2).range(0, 0.3),
                    \pan, rrand(-0.55, 0.55)
                ], ~srcGrp);
            };
            // Lead plays sparsely — longer waits for psychedelic space
            (rrand(1.0, 5.0) * ~beat).wait;
        }
    }).play(~clock);

    // ─────────────────────────────────────────────────────────
    // VOICE: SHAKER / HAT — Tarang-style high density
    // ─────────────────────────────────────────────────────────
    ~hatRoutine = Routine({
        loop {
            var p   = ~sp[~stage];
            var amp = p[5];

            // 32nd note grid — fires stochastically based on stage density
            32.do { |i|
                var fire = case
                    { ~stage == 0 } { false }
                    { ~stage == 1 } { [7, 23].includes(i) && 0.5.coin }
                    { ~stage == 2 } { [0,8,16,24].includes(i) || ([3,11,19,27].includes(i) && 0.5.coin) }
                    { ~stage == 3 } { (i % 4 == 0) || ((i % 4 == 2) && 0.6.coin) || (0.2.coin) }
                    { ~stage == 4 } { [0, 16].includes(i) || (0.1.coin) };

                if(fire && (amp > 0.02)) {
                    Synth(\shaker, [
                        \out, 0,
                        \amp, amp * rrand(0.5, 1.3),
                        \dur, rrand(0.04, 0.12),
                        \tone, rrand(7500, 12000),
                        \pan, rrand(-0.7, 0.7)
                    ], ~srcGrp);
                };
                (~beat / 8).wait;
            };
        }
    }).play(~clock);

    // ─────────────────────────────────────────────────────────
    // STAGE CONTROLLER
    // ─────────────────────────────────────────────────────────
    ~stageCtrl = Routine({
        ~stageDurs.do { |dur, i|
            ~stage = i;
            "".postln;
            "▶ Stage % — %  [BPM: %  Root: D  Scale: Phrygian Dominant]"
                .format(i, ~stageNames[i], ~bpm).postln;

            // Riser before stages 1-3
            if(i > 0 && i < 4) {
                Synth(\artRiser, [
                    \out, 0, \amp, 0.18, \dur, 7.0,
                    \loFreq, [55, 80, 120, 200][i-1],
                    \hiFreq, [1000, 2000, 4000, 6000][i-1]
                ], ~srcGrp);
                3.5.wait;
            };

            // Adjust tanpura to match stage energy
            ~tanpuraSynth.set(
                \amp,     [0.28, 0.22, 0.18, 0.14, 0.25][i],
                \cutoff,  [220, 260, 310, 350, 240][i],
                \modRate, [0.03, 0.04, 0.055, 0.07, 0.035][i]
            );

            if(dur > 0) { dur.wait } { nil.wait };
        };
    }).play;

    // ─────────────────────────────────────────────────────────
    // STOP FUNCTION
    // ─────────────────────────────────────────────────────────
    ~dervish = {
        [~oudRoutine, ~padRoutine, ~kickRoutine, ~bassRoutine,
         ~leadRoutine, ~hatRoutine, ~stageCtrl].do(_.stop);
        [~tanpuraSynth, ~reverbSynth, ~delaySynth].do(_.free);
        s.freeAll;
        "Artcore Dervish — ended.".postln;
    };

    "".postln;
    "╔══════════════════════════════════════════════╗".postln;
    "║  ARTCORE DERVISH — Playing                  ║".postln;
    "║  BPM: 132  Root: D  Phrygian Dominant       ║".postln;
    "║                                              ║".postln;
    "║  Stage jump:  ~stage = 0..4                 ║".postln;
    "║  Stop:        ~dervish.value                ║".postln;
    "╚══════════════════════════════════════════════╝".postln;
    "".postln;

}; // close fork
)

// ─── MANUAL CONTROLS ─────────────────────────────────────────
// ~stage = 0;  // Desert Night — pure ambient
// ~stage = 1;  // First Breath — kick + oud
// ~stage = 2;  // Middle Way   — the sweet spot ← start here
// ~stage = 3;  // Dervish Drive — full Artcore energy
// ~stage = 4;  // Open Desert  — infinite space
