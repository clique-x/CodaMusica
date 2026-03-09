// ─────────────────────────────────────────────────────────────
// CodaMusica — Markov Chain Engine (markov.scd)
// ─────────────────────────────────────────────────────────────
// A Markov chain picks the *next* state based on weighted
// probability from the *current* state.
// Use it for: melody, rhythm, dynamics, scale selection,
//             register, texture density — anything that should
//             flow naturally but never mechanically repeat.
// ─────────────────────────────────────────────────────────────

(
~markov = (

    // Build a transition table from an array of [from, to, weight] triples
    build: { |triples|
        var table = Dictionary.new;
        triples.do { |t|
            var from = t[0], to = t[1], w = t[2];
            table[from] = table[from].isNil.if(
                { [[to, w]] },
                { table[from] ++ [[to, w]] }
            );
        };
        table
    },

    // Choose next state given current state and a table
    next: { |table, current|
        var options = table[current];
        var totalW, r, acc;
        options.isNil.if({ ^current });
        totalW = options.collect(_[1]).sum;
        r = totalW.rand;
        acc = 0;
        options.detect { |pair|
            acc = acc + pair[1];
            acc >= r
        }[0]
    }
);

// ---- Example tables (you can override / extend these) --------

// Melodic interval tendencies (in scale degrees)
// From each degree, where does the melody like to go?
~melodyChain = ~markov[\build].value([
    // [from, to, weight] — higher weight = more likely
    [0, 1, 5], [0, 2, 4], [0, 4, 3], [0, 7, 2],
    [1, 0, 4], [1, 2, 5], [1, 3, 3],
    [2, 1, 4], [2, 3, 5], [2, 4, 4], [2, 0, 2],
    [3, 2, 4], [3, 4, 5], [3, 1, 2],
    [4, 3, 3], [4, 5, 5], [4, 2, 3], [4, 6, 2],
    [5, 4, 4], [5, 6, 5], [5, 3, 2],
    [6, 5, 4], [6, 4, 3], [6, 0, 4],
    [7, 6, 3], [7, 5, 3], [7, 0, 5],
]);

// Rhythmic feel — durations in beats
// Each state is a duration; transitions model natural phrasing
~rhythmChain = ~markov[\build].value([
    [0.25, 0.25, 6], [0.25, 0.5,  4], [0.25, 1.0,  1],
    [0.5,  0.25, 4], [0.5,  0.5,  5], [0.5,  1.0,  3], [0.5,  2.0,  1],
    [1.0,  0.5,  4], [1.0,  1.0,  4], [1.0,  2.0,  3], [1.0,  0.25, 2],
    [2.0,  1.0,  4], [2.0,  2.0,  2], [2.0,  0.5,  3],
]);

// Register zones — octave offsets
~registerChain = ~markov[\build].value([
    [-1, -1, 3], [-1,  0, 5], [-1,  1, 1],
    [ 0, -1, 3], [ 0,  0, 5], [ 0,  1, 3],
    [ 1,  0, 4], [ 1,  1, 3], [ 1, -1, 1],
]);

// Dynamics — amplitude values
~dynamicsChain = ~markov[\build].value([
    [0.05, 0.05, 2], [0.05, 0.1,  5], [0.05, 0.2,  2],
    [0.1,  0.05, 2], [0.1,  0.1,  4], [0.1,  0.2,  4], [0.1,  0.3, 1],
    [0.2,  0.1,  3], [0.2,  0.2,  4], [0.2,  0.3,  3],
    [0.3,  0.2,  4], [0.3,  0.1,  2], [0.3,  0.4,  2],
    [0.4,  0.3,  4], [0.4,  0.2,  3],
]);

"markov.scd loaded — ~markov engine + 4 chains ready".postln;
)
