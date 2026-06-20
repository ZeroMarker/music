/*
Canon in D — piano + violin + viola + cello

Run this whole file in SuperCollider. It defines a small ensemble and starts
Pachelbel's Canon-inspired loop in D major. Evaluate ~stopCanon.() to stop.
*/

(
s.waitForBoot {
    var tempo = 84 / 60;
    var progression, canonA, canonB, canonC, canonD;
    var recordPath, recordDuration;
    var bassNotes, pianoRoots, violaInner, pianoArpegg;

    ~canonClock = TempoClock(tempo).permanent_(true);
    ~canonGroup = Group.new;

    ~stopCanon = {
        Pdef(\pianoRight).stop;
        Pdef(\pianoLeft).stop;
        Pdef(\violin).stop;
        Pdef(\viola).stop;
        Pdef(\cello).stop;
        ~canonGroup.release(2);
        "Canon stopped.".postln;
    };

    // ----- SynthDefs -----

    SynthDef(\softPiano, { |out = 0, freq = 440, amp = 0.15, gate = 1, pan = 0|
        var hammer, body, bloom, damper, soundboard, env, tone;

        // Shaped hammer — bandpass noise focused around 2.5kHz where real piano hammers strike
        hammer = BPF.ar(WhiteNoise.ar(0.5), 2500, 0.7) * EnvGen.kr(Env.perc(0.0005, 0.025));

        // Inharmonic string resonance (stiff strings, stretched tuning)
        body = Klank.ar(
            `[
                [freq, freq * 1.997, freq * 3.01, freq * 4.02, freq * 5.04, freq * 6.01],
                [1.0, 0.42, 0.22, 0.13, 0.08, 0.05],
                [3.8, 3.1, 2.4, 1.7, 1.25, 0.85]
            ],
            hammer
        );

        // Harmonic bloom with gentle chorus detune — adds air and sparkle
        bloom = Mix.fill(3, { |i|
            var ratio = [1, 2.002, 3.01][i];
            var detune = LFNoise1.kr(0.3 + (i * 0.5)).range(0.998, 1.002);
            SinOsc.ar(freq * ratio * detune) * (0.14 / (i + 0.7))
        });

        // Damper filter — wider range for more high-end clarity
        damper = LPF.ar(body + bloom, freq.linexp(60, 1400, 1200, 7200).clip(1200, 7600));

        // Fixed soundboard resonance for woody warmth
        soundboard = BPF.ar(body + bloom, 320, 0.45) * 0.07;

        env = EnvGen.kr(Env.adsr(0.003, 0.16, 0.42, 1.8, curve: -4), gate, doneAction: 2);
        tone = LeakDC.ar((damper + soundboard) * env);
        Out.ar(out, Pan2.ar(tone * amp, pan));
    }).add;

    SynthDef(\bowedString, { |out = 0, freq = 440, amp = 0.12, gate = 1, pan = 0,
        vibrato = 0.015, attack = 0.16, bright = 1, bodyResFreq = 0|

        var vib, vibAM, bow, scratch, core, body, air, env, cutoff, resonance;

        // Vibrato with coupled amplitude modulation for natural bowing
        vib = SinOsc.kr(5.1 + LFNoise1.kr(0.3).range(-0.4, 0.4), Rand(0, 2pi), vibrato, 1);
        vibAM = 1 + (SinOsc.kr(5.1, Rand(0, 2pi)) * vibrato * 2.5); // subtle AM from vibrato

        bow = LFNoise2.kr(7).range(0.88, 1.08);

        core = Mix.ar([
            VarSaw.ar(freq * vib * Rand(0.996, 1.004), 0, 0.38, 0.48),
            VarSaw.ar(freq * vib * 0.501 * Rand(0.997, 1.003), 0, 0.48, 0.24),
            Pulse.ar(freq * vib * 2.002, 0.42, 0.08)
        ]) * bow * vibAM;

        // Subtle bow attack scratch
        scratch = BPF.ar(WhiteNoise.ar(0.12), 4500, 0.6) * EnvGen.kr(Env.perc(0.002, 0.035), gate);
        core = core + scratch;

        // Instrument body filter
        cutoff = (freq * (3.2 + bright)).clip(900, 5200);
        resonance = 0.32 - (amp * 0.35).clip(0, 0.2);
        body = RLPF.ar(core, cutoff, resonance);
        body = body + BPF.ar(core, freq * 2.02, 0.18, 0.18);

        // Per-instrument body resonance (cello ~280, viola ~400, violin ~520)
        body = body + (BPF.ar(core, bodyResFreq, 0.3) * 0.14 * (bodyResFreq > 0));

        air = HPF.ar(LPF.ar(WhiteNoise.ar(0.018), 5200), 1800) * EnvGen.kr(Env.asr(0.3, 1, 0.4), gate);
        env = EnvGen.kr(Env.adsr(
            attack * amp.linexp(0.05, 0.3, 1.4, 0.6),
            0.45, 0.74, 0.85, curve: -3
        ), gate, doneAction: 2);
        Out.ar(out, Pan2.ar(LeakDC.ar((body * env) + air) * amp, pan));
    }).add;

    SynthDef(\smallHall, { |out = 0, mix = 0.30|
        var sig = In.ar(out, 2);
        var early = DelayC.ar(sig, 0.04, [0.017, 0.023]) * 0.25;
        var wet = FreeVerb2.ar(sig[0], sig[1], mix, 0.78, 0.35);
        // High-frequency damping for natural warm hall decay
        wet = LPF.ar(wet, 5500);
        ReplaceOut.ar(out, Limiter.ar((sig * 0.65) + early + (wet * 0.35), 0.92));
    }).add;

    s.sync;
    ~canonReverb = Synth.tail(~canonGroup, \smallHall);

    // ----- Recording -----

    recordPath = ~canonRecordPath;
    recordDuration = ~canonRecordDuration ? 137.2;
    if (recordPath.notNil) {
        s.prepareForRecord(recordPath.standardizePath, numChannels: 2);
        s.sync;
        s.record;
        ("Recording Canon in D to " ++ recordPath ++ " for " ++ recordDuration.round(0.1) ++ " seconds.").postln;
    };

    // ----- Harmony and Melody -----

    progression = [
        [50, 57, 62, 66], // D
        [45, 52, 57, 61], // A
        [47, 54, 59, 62], // Bm
        [42, 50, 54, 57], // F#m
        [43, 50, 55, 59], // G
        [50, 57, 62, 66], // D
        [43, 50, 55, 59], // G
        [45, 52, 57, 61]  // A
    ];

    canonA = [74, 73, 74, 66, 69, 71, 73, 69, 71, 73, 74, 71, 69, 66, 69, 62];
    canonB = [62, 66, 69, 74, 73, 69, 66, 62, 64, 67, 71, 76, 74, 71, 67, 64];
    canonC = [69, 71, 73, 74, 76, 73, 74, 71, 69, 71, 73, 66, 69, 67, 66, 62];
    canonD = [57, 62, 66, 69, 71, 66, 69, 62, 64, 69, 73, 76, 78, 73, 76, 69];

    // Pre-compute all progression-derived patterns once
    pianoRoots  = progression.collect({ |chord| chord[0] });
    bassNotes   = progression.collect({ |chord| chord[0] - 12 });
    violaInner  = progression.collect({ |chord| [chord[1], chord[2], chord[3], chord[2]] }).flat;
    pianoArpegg = progression.collect({ |chord|
        [chord[0] + 12, chord[1] + 12, chord[2] + 12, chord[3] + 12,
         chord[2] + 12, chord[1] + 12, chord[2] + 12, chord[3] + 12]
    }).flat;

    // ----- Patterns -----

    Pdef(\pianoLeft,
        Pbind(
            \instrument, \softPiano,
            \group, ~canonGroup,
            \midinote, Pseq(pianoRoots, inf),
            \dur, 2,
            \legato, 0.72,
            \amp, 0.18,
            \pan, -0.16
        )
    ).play(~canonClock, quant: 1);

    Pdef(\pianoRight,
        Pbind(
            \instrument, \softPiano,
            \group, ~canonGroup,
            \midinote, Pseq(pianoArpegg, inf),
            \dur, 0.25,
            \legato, Pwhite(0.52, 0.64, inf),
            \amp, Pwhite(0.055, 0.088, inf),
            \pan, Pwhite(-0.08, 0.08, inf)
        )
    ).play(~canonClock, quant: 1);

    Pdef(\cello,
        Pbind(
            \instrument, \bowedString,
            \group, ~canonGroup,
            \midinote, Pseq(bassNotes, inf),
            \dur, 2,
            \legato, 0.96,
            \amp, 0.16,
            \pan, -0.34,
            \vibrato, 0.007,
            \attack, 0.28,
            \bright, 0.25,
            \bodyResFreq, 280
        )
    ).play(~canonClock, quant: 1);

    Pdef(\viola,
        Pbind(
            \instrument, \bowedString,
            \group, ~canonGroup,
            \midinote, Pseq(violaInner, inf),
            \dur, 0.5,
            \legato, Pseq([0.86, 0.74, 0.92, 0.8], inf),
            \amp, 0.088,
            \pan, 0.18,
            \vibrato, 0.011,
            \attack, 0.2,
            \bright, 0.75,
            \bodyResFreq, 400
        )
    ).play(~canonClock, quant: 1);

    Pdef(\violin,
        Pbind(
            \instrument, \bowedString,
            \group, ~canonGroup,
            \midinote, Pseq(canonA ++ canonB ++ canonC ++ canonD, inf),
            \dur, 0.5,
            \legato, Pseq([0.86, 0.74, 0.92, 0.8], inf),
            \amp, Pseg(Pseq([0.085, 0.135, 0.105], inf), Pseq([16, 16], inf)),
            \pan, 0.38,
            \vibrato, 0.016,
            \attack, 0.14,
            \bright, 1.35,
            \bodyResFreq, 520
        )
    ).play(~canonClock, quant: 1);

    "Canon in D started. Evaluate ~stopCanon.() to stop.".postln;

    if (recordPath.notNil) {
        Routine({
            recordDuration.wait;
            ~stopCanon.();
            4.wait;
            s.stopRecording;
            2.wait;
            s.quit;
            1.wait;
            0.exit;
        }).play(SystemClock);
    };
};
)
