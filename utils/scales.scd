// ─────────────────────────────────────────────────────────────
// CodaMusica — Scale & Harmony Utilities (scales.scd)
// ─────────────────────────────────────────────────────────────

(
~scales = (

    // Named scale pools — degrees relative to root
    pentatonicMinor: [0, 3, 5, 7, 10],
    pentatonicMajor: [0, 2, 4, 7, 9],
    dorian:          [0, 2, 3, 5, 7, 9, 10],
    phrygian:        [0, 1, 3, 5, 7, 8, 10],
    lydian:          [0, 2, 4, 6, 7, 9, 11],
    mixolydian:      [0, 2, 4, 5, 7, 9, 10],
    wholeTone:       [0, 2, 4, 6, 8, 10],
    diminished:      [0, 2, 3, 5, 6, 8, 9, 11],
    japanese:        [0, 1, 5, 7, 8],   // In scale
    arabic:          [0, 2, 4, 5, 6, 8, 10],

    // Convert scale degree + root + octave to frequency
    degToFreq: { |scaleKey, degree, root=48, octave=0|
        var pool = ~scales[scaleKey];
        var size = pool.size;
        var oct  = (degree / size).floor + octave;
        var deg  = degree % size;
        (root + pool[deg] + (oct * 12)).midicps
    },

    // Random walk on a scale — returns next degree given current
    // weights: stay near current position (Gaussian-ish)
    walk: { |current, size, stepSize=2|
        var step = ((-stepSize..stepSize).choose);
        (current + step).clip(0, size - 1)
    }
);

"scales.scd loaded — ~scales utility ready".postln;
)
