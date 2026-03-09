// ─────────────────────────────────────────────────────────────
// CodaMusica — Hello Sound (sketches/hello_sound.scd)
// The simplest possible test — run this first to verify
// SuperCollider audio is working.
// ─────────────────────────────────────────────────────────────

// Step 1 — Boot the server (run this line alone first):
s.boot;

// Step 2 — Play a quick tone to confirm audio works:
{ SinOsc.ar(440, 0, 0.2) ! 2 }.play;

// Step 3 — Stop it:
// s.freeAll;

// Step 4 — Try a pluck:
(
SynthDef(\testPluck, { |out=0, freq=220, amp=0.4|
    var sig = Pluck.ar(WhiteNoise.ar(amp), Impulse.kr(0), freq.reciprocal, 3, 0.25);
    var env = EnvGen.kr(Env.perc(0.001, 3), doneAction: 2);
    Out.ar(out, (sig * env) ! 2);
}).add;
)
Synth(\testPluck, [\freq, 220]);
Synth(\testPluck, [\freq, 330]);
Synth(\testPluck, [\freq, 440]);
