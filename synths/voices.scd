// ─────────────────────────────────────────────────────────────
// CodaMusica — SynthDefs (voices.scd)
// Load this first: s.boot; then load this file
// ─────────────────────────────────────────────────────────────

(
// --- Slow atmospheric pad ---
SynthDef(\pad, { |out=0, freq=440, amp=0.2, atk=2, rel=4, pan=0, cutoff=2000|
    var sig, env;
    env = EnvGen.kr(Env.perc(atk, rel), doneAction: 2);
    sig = Mix([
        SinOsc.ar(freq, 0, 0.5),
        SinOsc.ar(freq * 1.001, 0, 0.3),    // slight detune for warmth
        SinOsc.ar(freq * 2.0,   0, 0.15),   // octave
        SinOsc.ar(freq * 3.0,   0, 0.05),   // third harmonic
    ]);
    sig = LPF.ar(sig, cutoff);
    sig = sig * env * amp;
    sig = Pan2.ar(sig, pan);
    Out.ar(out, sig);
}).add;

// --- Plucked string (Karplus-Strong style) ---
SynthDef(\pluck, { |out=0, freq=220, amp=0.4, pan=0, decay=3|
    var sig, env;
    env = EnvGen.kr(Env.perc(0.001, decay), doneAction: 2);
    sig = Pluck.ar(
        WhiteNoise.ar(amp),
        Impulse.kr(0),
        freq.reciprocal,
        decay,
        0.25
    );
    sig = sig * env;
    sig = Pan2.ar(sig, pan);
    Out.ar(out, sig);
}).add;

// --- Mallet / marimba-like tone ---
SynthDef(\mallet, { |out=0, freq=440, amp=0.3, pan=0|
    var sig, env;
    env = EnvGen.kr(Env.perc(0.005, 1.2 + (freq.reciprocal * 200)), doneAction: 2);
    sig = SinOsc.ar(freq) * 0.6;
    sig = sig + (SinOsc.ar(freq * 4.07) * 0.2 * EnvGen.kr(Env.perc(0.001, 0.08)));
    sig = sig * env * amp;
    sig = Pan2.ar(sig, pan);
    Out.ar(out, sig);
}).add;

// --- Breath / wind tone ---
SynthDef(\breath, { |out=0, freq=200, amp=0.15, atk=3, rel=5, pan=0|
    var sig, env, noise;
    env  = EnvGen.kr(Env.perc(atk, rel), doneAction: 2);
    noise = BPF.ar(WhiteNoise.ar(1), freq, 0.08);
    sig  = noise + (SinOsc.ar(freq) * 0.3);
    sig  = sig * env * amp;
    sig  = Pan2.ar(sig, pan);
    Out.ar(out, sig);
}).add;

"voices.scd loaded — 4 synths ready: \\pad, \\pluck, \\mallet, \\breath".postln;
)
