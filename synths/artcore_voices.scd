// ═════════════════════════════════════════════════════════════
// CodaMusica — Artcore/Dervish Voice Library (artcore_voices.scd)
// Tuned from analysis of: Astrix Artcore, Gurdjieff/Dervish,
//                         Relax Shiva, Tarang
//
// Spectral targets: 60-75% sub (20-80Hz), 20-30% bass (80-300Hz),
//                   minimal mids/highs — dark, deep, psychedelic
// ═════════════════════════════════════════════════════════════

(
// ── Free and reallocate buses on reload ──────────────────────
if(~reverbBus.notNil) { ~reverbBus.free };
if(~delayBus.notNil)  { ~delayBus.free  };
~reverbBus = Bus.audio(s, 2);
~delayBus  = Bus.audio(s, 2);

// ── Global reverb — long cave-like tail ───────────────────────
SynthDef(\artReverb, { |in, out=0, mix=0.55, room=0.98, damp=0.3|
    var sig = In.ar(in, 2);
    var wet = GVerb.ar(sig.sum, 300, 20, damp, 0.5, 20, 0.5, 0.5, 0.25);
    Out.ar(out, XFade2.ar(sig, wet, mix.linlin(0,1,-1,1)));
}).add;

// ── Ping-pong delay — psychedelic echo ───────────────────────
SynthDef(\artDelay, { |in, out=0, delL=0.333, delR=0.666, fdbk=0.38, mix=0.25|
    var sig = In.ar(in, 2);
    var d = LocalIn.ar(2);
    var wet = [DelayC.ar(sig[0]+(d[1]*fdbk), 2, delL),
               DelayC.ar(sig[1]+(d[0]*fdbk), 2, delR)];
    LocalOut.ar(wet);
    Out.ar(out, XFade2.ar(sig, wet, mix.linlin(0,1,-1,1)));
}).add;

// ── Tanpura drone — the infinite floor ───────────────────────
// Inspired by the Gurdjieff track's deep bass body (77% bass)
SynthDef(\tanpura, { |out=0, freq=36.7, amp=0.3, cutoff=280, modRate=0.03|
    var sig, lfo, filt;
    lfo  = SinOsc.kr(modRate, 0, 0.4, 1.0);
    sig  = Mix([
        SinOsc.ar(freq,       0, 0.45),   // fundamental
        SinOsc.ar(freq * 2,   0, 0.25),   // octave
        SinOsc.ar(freq * 3,   0, 0.15),   // fifth
        SinOsc.ar(freq * 4,   0, 0.10),   // double octave
        SinOsc.ar(freq * 5,   0, 0.05),   // major third harmonic
        // Slow beating between detuned partials — gives the tanpura "spin"
        SinOsc.ar(freq * 2.001, 0, 0.08),
        SinOsc.ar(freq * 3.002, 0, 0.05),
    ]);
    filt = RLPF.ar(sig, cutoff * lfo, 0.5);
    // Sub reinforcement — Tarang/Shiva style (60-75% sub target)
    filt = filt + (SinOsc.ar(freq * 0.5) * 0.3);
    filt = HPF.ar(filt, 25);
    filt = filt * amp;
    Out.ar(~reverbBus, filt ! 2);
    Out.ar(out, filt ! 2);
}).add;

// ── Oud — plucked string with body resonance ─────────────────
// Captures Gurdjieff track warmth: dark centroid (629Hz),
// heavy bass body, organic decay
SynthDef(\oud, { |out=0, freq=110, amp=0.5, decay=2.5, pan=0, bright=0.3|
    var sig, body, env, buzz;
    // Karplus-Strong core
    sig  = Pluck.ar(
        WhiteNoise.ar(amp),
        Impulse.kr(0),
        freq.reciprocal,
        decay * 1.5,
        bright.linlin(0,1,0.1,0.45)
    );
    // Body resonance — comb filter tuned to string harmonics
    body = CombL.ar(sig, 0.1, (freq * 2).reciprocal, decay * 0.5, 0.4);
    body = body + CombL.ar(sig, 0.1, (freq * 3).reciprocal, decay * 0.3, 0.2);
    // Attack buzz (characteristic oud nasal attack)
    buzz = BPF.ar(WhiteNoise.ar(0.3), freq * 4, 0.2) *
           EnvGen.kr(Env.perc(0.001, 0.03));
    sig  = sig + (body * 0.4) + (buzz * amp * 0.5);
    // Warm low-pass — keep it dark like the analysis says (centroid 629Hz)
    sig  = LPF.ar(sig, 1800);
    sig  = HPF.ar(sig, 60);
    env  = EnvGen.kr(Env.perc(0.002, decay, 1, -3), doneAction: 2);
    sig  = sig * env;
    Out.ar(~reverbBus, Pan2.ar(sig * 0.6, pan));
    Out.ar(out, Pan2.ar(sig, pan));
}).add;

// ── Psytrance kick — Astrix-style punch ──────────────────────
// Sine sweep: 150→45 Hz in 55ms, hard transient, long sub tail
// Matches Artcore's sub dominance (64% sub)
SynthDef(\psyKick, { |out=0, amp=0.85, punch=150, body=44, click=0.4,
                        sweepTime=0.055, tail=0.7|
    var sig, env, freqEnv, clickSig;
    freqEnv = EnvGen.kr(Env([punch, body, body*0.8], [sweepTime, tail], \exp));
    env     = EnvGen.kr(Env.perc(0.003, tail + sweepTime + 0.1, 1, -5), doneAction: 2);
    sig     = SinOsc.ar(freqEnv);
    // Sub octave reinforcement
    sig     = sig + (SinOsc.ar(freqEnv * 0.5) * 0.5);
    // Hard click transient
    clickSig = WhiteNoise.ar(click) * EnvGen.kr(Env.perc(0.001, 0.008));
    sig     = HPF.ar(sig + clickSig, 28);
    sig     = sig * env * amp;
    Out.ar(out, sig ! 2);
}).add;

// ── Rolling acid bass — Artcore's 16th note engine ───────────
// The characteristic Astrix rolling bassline
// Cutoff envelope gives the "wah" feel, modRate gives movement
SynthDef(\acidBass, { |out=0, freq=55, amp=0.45, dur=0.12,
                          cutoff=350, res=0.75, cutEnvAmt=800, cutDecay=0.15|
    var sig, env, fenv;
    env  = EnvGen.kr(Env.perc(0.004, dur, 1, -4), doneAction: 2);
    fenv = EnvGen.kr(Env.perc(0.003, cutDecay, 1, -5));
    sig  = LFSaw.ar(freq, 0, 0.7) + LFSaw.ar(freq * 1.003, 0, 0.3);
    // Sub sine underneath for the Tarang-style sub dominance (75% sub)
    sig  = sig + (SinOsc.ar(freq * 0.5) * 0.6);
    sig  = RLPF.ar(sig, (cutoff + (fenv * cutEnvAmt)).max(60), 1 - res);
    sig  = sig * env * amp;
    sig  = HPF.ar(sig, 30);
    Out.ar(~reverbBus, sig ! 2 * 0.3);
    Out.ar(out, sig ! 2);
}).add;

// ── Wide sweep pad — dark, filtered, psychedelic ─────────────
// Spectral target: warm/mid (centroid ~1400Hz), not bright
SynthDef(\darkPad, { |out=0, freq=110, amp=0.2, atk=4.0, sus=6.0, rel=7.0,
                         cutLo=200, cutHi=1800, modRate=0.06, pan=0, detune=0.014|
    var sig, env, lfo, cut;
    env = EnvGen.kr(Env([0,1,1,0],[atk,sus,rel],\sine), doneAction: 2);
    lfo = SinOsc.kr(modRate + LFNoise2.kr(0.03, 0.015));
    cut = lfo.linlin(-1, 1, cutLo, cutHi);
    sig = Mix([
        LFSaw.ar(freq * (1-detune),    0, 0.3),
        LFSaw.ar(freq,                 0, 0.3),
        LFSaw.ar(freq * (1+detune),    0, 0.2),
        SinOsc.ar(freq * 0.5,          0, 0.2),   // sub octave warmth
    ]);
    sig = RLPF.ar(sig, cut, 0.35);
    sig = sig * env * amp;
    sig = [ sig * SinOsc.kr(0.05, 0, 0.5, 0.5),
            sig * SinOsc.kr(0.05, pi, 0.5, 0.5) ];
    Out.ar(~reverbBus, sig * 0.5);
    Out.ar(out, Pan2.ar(sig.sum * 0.5, pan));
}).add;

// ── Psy lead — FM, wobbling, modal ───────────────────────────
// The Artcore-style psychedelic voice
SynthDef(\psyLead2, { |out=0, freq=220, amp=0.22, atk=0.06, sus=0.8, rel=1.8,
                          modIdx=4.0, modRatio=2.01, wobble=0.25, pan=0|
    var sig, env, mod, pitchLfo;
    env      = EnvGen.kr(Env([0,1,0.65,0],[atk,sus,rel],[3,-2,-4]), doneAction: 2);
    pitchLfo = SinOsc.kr(wobble + LFNoise2.kr(0.08, 0.15), 0, 0.008);
    mod      = SinOsc.ar(freq * modRatio * (1+pitchLfo), 0, freq * modIdx);
    sig      = SinOsc.ar(freq * (1+pitchLfo) + mod);
    sig      = sig + (SinOsc.ar(freq * 0.5 + mod*0.3) * 0.25);
    sig      = LPF.ar(sig, 3500 * env + 400);
    sig      = sig * env * amp;
    Out.ar(~reverbBus, Pan2.ar(sig, pan));
    Out.ar(out, Pan2.ar(sig, pan));
}).add;

// ── Hi-hat / shaker — Tarang-style high density ──────────────
SynthDef(\shaker, { |out=0, amp=0.12, dur=0.06, tone=9000, pan=0|
    var sig, env;
    env = EnvGen.kr(Env.perc(0.001, dur, 1, -7), doneAction: 2);
    sig = BPF.ar(WhiteNoise.ar(1), tone, 0.4) + BPF.ar(WhiteNoise.ar(0.5), tone*1.3, 0.3);
    sig = HPF.ar(sig, 5000);
    sig = sig * env * amp;
    Out.ar(out, Pan2.ar(sig, pan));
}).add;

// ── Sub thump — pure sub, fills the 20-80Hz zone ─────────────
SynthDef(\subThump, { |out=0, freq=36.7, amp=0.6, dur=0.9|
    var sig, env;
    env = EnvGen.kr(Env.perc(0.005, dur, 1, -5), doneAction: 2);
    sig = SinOsc.ar(freq) + (SinOsc.ar(freq * 0.5) * 0.4);
    sig = HPF.ar(sig, 20);
    sig = sig * env * amp;
    Out.ar(out, sig ! 2);
}).add;

// ── Riser — stage transition builder ─────────────────────────
SynthDef(\artRiser, { |out=0, amp=0.25, dur=8.0, loFreq=60, hiFreq=3000|
    var sig, env, freq;
    env  = EnvGen.kr(Env([0,0.7,1,0],[dur*0.1,dur*0.8,dur*0.1],\sine), doneAction: 2);
    freq = XLine.kr(loFreq, hiFreq, dur);
    sig  = BPF.ar(WhiteNoise.ar(1), freq, 0.06) * 0.7;
    sig  = sig + (SinOsc.ar(freq * 0.5) * 0.3 * LFNoise2.kr(6, 0.5, 0.5));
    sig  = sig * env * amp;
    Out.ar(~reverbBus, sig ! 2);
    Out.ar(out, sig ! 2);
}).add;

"artcore_voices.scd loaded — 11 synths ready".postln;
"  tanpura  oud  psyKick  acidBass  darkPad  psyLead2".postln;
"  shaker   subThump  artReverb  artDelay  artRiser".postln;
)
