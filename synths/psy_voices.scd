// ═════════════════════════════════════════════════════════════
// CodaMusica — Psybient / Progressive Voices (psy_voices.scd)
// ═════════════════════════════════════════════════════════════

(
// ── Effects buses — free old ones first if reloading ─────────
if(~reverbBus.notNil) { ~reverbBus.free };
if(~delayBus.notNil)  { ~delayBus.free  };
~reverbBus = Bus.audio(s, 2);
~delayBus  = Bus.audio(s, 2);

// ── Global reverb tail (all voices feed into this) ────────────
SynthDef(\globalReverb, { |in, out=0, mix=0.6, room=0.95, damp=0.4|
    var sig = In.ar(in, 2);
    var wet = GVerb.ar(sig.sum, 200, 15, damp, 0.5, 15, 0.5, 0.5, 0.3);
    Out.ar(out, XFade2.ar(sig, wet, mix.linlin(0,1,-1,1)));
}).add;

// ── Psychedelic delay (stereo ping-pong) ──────────────────────
SynthDef(\globalDelay, { |in, out=0, delL=0.375, delR=0.5, fdbk=0.45, mix=0.3|
    var sig  = In.ar(in, 2);
    var delSig, wet;
    delSig = LocalIn.ar(2);
    wet = [ DelayC.ar(sig[0] + (delSig[1] * fdbk), 2.0, delL),
            DelayC.ar(sig[1] + (delSig[0] * fdbk), 2.0, delR) ];
    LocalOut.ar(wet);
    Out.ar(out, XFade2.ar(sig, wet, mix.linlin(0,1,-1,1)));
}).add;

// ── Sub bass — pure sine, the floor of the universe ──────────
SynthDef(\subBass, { |out=0, freq=55, amp=0.5, atk=0.8, rel=2.0, pan=0|
    var sig, env;
    env = EnvGen.kr(Env.perc(atk, rel, 1, -4), doneAction: 2);
    sig = SinOsc.ar(freq) + SinOsc.ar(freq * 0.5, 0, 0.3);
    sig = HPF.ar(sig, 30);
    sig = sig * env * amp;
    Out.ar(out, Pan2.ar(sig, pan));
}).add;

// ── Psy bassline — resonant acid saw, the spine ───────────────
SynthDef(\psyBass, { |out=0, freq=55, amp=0.35, atk=0.01, rel=0.4,
                        cutoff=400, res=0.7, cutMod=200, modRate=0.5|
    var sig, env, fenv, lfo;
    env  = EnvGen.kr(Env.perc(atk, rel, 1, -3), doneAction: 2);
    fenv = EnvGen.kr(Env.perc(0.005, rel * 0.8, 1, -5));
    lfo  = SinOsc.kr(modRate, 0, cutMod);
    sig  = LFSaw.ar(freq, 0, 0.7) + LFSaw.ar(freq * 1.002, 0, 0.3);
    sig  = RLPF.ar(sig, (cutoff + (fenv * cutMod * 3) + lfo).max(80), res.linlin(0,1,0.01,0.99));
    sig  = sig * env * amp;
    Out.ar(~reverbBus, Pan2.ar(sig, 0));
    Out.ar(out, Pan2.ar(sig * 0.6, 0));
}).add;

// ── Sweep pad — the wide, breathing heart of psybient ─────────
SynthDef(\sweepPad, { |out=0, freq=220, amp=0.25, atk=4.0, sus=4.0, rel=6.0,
                         cutLo=300, cutHi=2500, modRate=0.08, pan=0, detune=0.012|
    var sig, env, filt, lfo, cutoff;
    env    = EnvGen.kr(Env([0,1,1,0], [atk, sus, rel], \sine), doneAction: 2);
    lfo    = SinOsc.kr(modRate + LFNoise2.kr(0.02, 0.02), 0);
    cutoff = lfo.linlin(-1, 1, cutLo, cutHi);
    sig = Mix([
        LFSaw.ar(freq * (1 - detune),        0, 0.25),
        LFSaw.ar(freq,                        0, 0.25),
        LFSaw.ar(freq * (1 + detune),         0, 0.20),
        LFSaw.ar(freq * (1 + detune * 2),     0, 0.15),
        SinOsc.ar(freq * 0.5,                 0, 0.15),
    ]);
    sig  = RLPF.ar(sig, cutoff, 0.4);
    sig  = sig + (sig * 0.15 * SinOsc.ar(freq * 3.01));  // subtle chorus
    sig  = sig * env * amp;
    // Wide stereo spread
    sig  = [ sig * SinOsc.kr(0.07, 0, 0.5, 0.5),
             sig * SinOsc.kr(0.07, pi, 0.5, 0.5) ];
    Out.ar(~reverbBus, sig);
    Out.ar(out, Pan2.ar(sig.sum * 0.5, pan));
}).add;

// ── Shimmer pad — high frequency crystal layer ────────────────
SynthDef(\shimmerPad, { |out=0, freq=880, amp=0.12, atk=5.0, rel=8.0, pan=0|
    var sig, env, lfo;
    env = EnvGen.kr(Env.perc(atk, rel, 1, \sine), doneAction: 2);
    lfo = LFNoise2.kr(0.3, 0.5, 1.0);
    sig = Mix([
        SinOsc.ar(freq * 1.0,   0, 0.4),
        SinOsc.ar(freq * 2.0,   0, 0.25),
        SinOsc.ar(freq * 3.01,  0, 0.15),
        SinOsc.ar(freq * 4.02,  0, 0.1),
        LFTri.ar(freq * 1.003,  0, 0.1),
    ]);
    sig = BPF.ar(WhiteNoise.ar(0.05), freq * lfo, 0.1) + sig;
    sig = sig * env * amp;
    Out.ar(~reverbBus, Pan2.ar(sig, pan));
    Out.ar(out, Pan2.ar(sig * 0.3, pan));
}).add;

// ── Psy lead — FM voice, the thing that speaks ───────────────
SynthDef(\psyLead, { |out=0, freq=440, amp=0.2, atk=0.1, sus=1.0, rel=2.0,
                        modIdx=3.5, modRatio=2.0, wobble=0.3, pan=0|
    var sig, env, mod, wobbleLfo, pitchLfo;
    env      = EnvGen.kr(Env([0,1,0.7,0], [atk, sus, rel], [4,-2,-4]), doneAction: 2);
    wobbleLfo = SinOsc.kr(wobble + LFNoise2.kr(0.1, 0.1), 0, modIdx * 0.3);
    pitchLfo  = SinOsc.kr(0.5 + LFNoise2.kr(0.05, 0.2), 0, 0.007);
    mod  = SinOsc.ar((freq * modRatio) * (1 + pitchLfo), 0,
                      freq * (modIdx + wobbleLfo));
    sig  = SinOsc.ar(freq * (1 + pitchLfo) + mod);
    sig  = sig + (SinOsc.ar(freq * 0.5 + mod * 0.5) * 0.3);
    sig  = LPF.ar(sig, 4000 * env + 500);
    sig  = sig * env * amp;
    Out.ar(~reverbBus, Pan2.ar(sig, pan));
    Out.ar(out, Pan2.ar(sig, pan));
}).add;

// ── Kick pulse — deep sine thump, not a club kick ─────────────
SynthDef(\kickPulse, { |out=0, amp=0.6, punch=80, body=40, dur=0.8|
    var sig, env, freqEnv;
    env     = EnvGen.kr(Env.perc(0.003, dur, 1, -5), doneAction: 2);
    freqEnv = EnvGen.kr(Env([punch, body], [0.06], \exp));
    sig  = SinOsc.ar(freqEnv) + (SinOsc.ar(freqEnv * 0.5) * 0.4);
    sig  = sig + (WhiteNoise.ar(0.08) * EnvGen.kr(Env.perc(0.001, 0.015)));
    sig  = HPF.ar(sig, 28);
    sig  = sig * env * amp;
    Out.ar(out, sig ! 2);
}).add;

// ── Hi-hat / noise transient ──────────────────────────────────
SynthDef(\hat, { |out=0, amp=0.15, dur=0.08, tone=8000, pan=0|
    var sig, env;
    env = EnvGen.kr(Env.perc(0.002, dur, 1, -6), doneAction: 2);
    sig = BPF.ar(WhiteNoise.ar(1), tone, 0.5);
    sig = HPF.ar(sig, 6000);
    sig = sig * env * amp;
    Out.ar(out, Pan2.ar(sig, pan));
}).add;

// ── Riser — tension builder for stage transitions ─────────────
SynthDef(\riser, { |out=0, amp=0.3, dur=8.0, loFreq=100, hiFreq=4000|
    var sig, env, freq;
    env  = EnvGen.kr(Env([0,0.8,1,0], [dur*0.1, dur*0.8, dur*0.1], \sine), doneAction: 2);
    freq = XLine.kr(loFreq, hiFreq, dur);
    sig  = BPF.ar(WhiteNoise.ar(1), freq, 0.08);
    sig  = sig + (SinOsc.ar(freq * 0.5) * 0.2);
    sig  = LFNoise2.kr(8, 0.5, 0.5) * sig;
    sig  = sig * env * amp;
    Out.ar(~reverbBus, sig ! 2);
    Out.ar(out, sig ! 2);
}).add;

// ── Texture drone — continuous background breath ───────────────
SynthDef(\drone, { |out=0, freq=55, amp=0.1, cutoff=300, cutMod=150, modRate=0.05|
    var sig, lfo, filt;
    lfo  = SinOsc.kr(modRate + LFNoise2.kr(0.02, modRate * 0.3), 0);
    filt = lfo.linlin(-1, 1, cutoff - cutMod, cutoff + cutMod);
    sig  = Mix([
        LFSaw.ar(freq,       0, 0.3),
        LFSaw.ar(freq * 1.5, 0, 0.2),
        LFSaw.ar(freq * 2.0, 0, 0.15),
        SinOsc.ar(freq * 0.5,0, 0.35),
    ]);
    sig = RLPF.ar(sig, filt.max(60), 0.3);
    sig = sig * amp;
    Out.ar(~reverbBus, sig ! 2);
    Out.ar(out, sig ! 2);
}).add;

"psy_voices.scd loaded — 9 synths + effects buses ready".postln;
)
