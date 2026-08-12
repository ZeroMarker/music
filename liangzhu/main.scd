/* Butterfly Lovers · Reverie — original pentatonic chamber piece. */
(
s.waitForBoot {
    var tempo = 72 / 60;
    var roots = [50, 45, 47, 43, 50, 52, 43, 45];
    var theme = [69, 71, 74, 76, 74, 71, 69, 67, 64, 67, 69, 71, 69, 67, 64, 62,
        71, 74, 76, 79, 76, 74, 71, 69, 67, 69, 71, 74, 69, 67, 64, 62];
    var answer = [62, 64, 67, 69, 71, 69, 67, 64, 62, 67, 69, 71, 74, 71, 69, 67];
    var recordPath = ~liangzhuRecordPath;
    var recordDuration = ~liangzhuRecordDuration ? 128;

    ~liangzhuClock = TempoClock(tempo).permanent_(true);
    ~liangzhuGroup = Group.new;
    ~stopLiangzhu = {
        [\moonLute, \xiao, \erhu, \bass].do({ |name| Pdef(name).stop });
        ~liangzhuGroup.release(3);
        "Liangzhu reverie stopped.".postln;
    };

    SynthDef(\pluckedSilk, { |out=0, freq=440, amp=0.1, gate=1, pan=0|
        var strike = PinkNoise.ar(0.35) * EnvGen.kr(Env.perc(0.001, 0.025));
        var body = Ringz.ar(strike, [freq, freq*2.01, freq*3.98], [2.8, 1.7, 1.1], [1, .35, .12]).sum;
        var env = EnvGen.kr(Env.asr(0.002, 1, 1.6), gate, doneAction: 2);
        Out.ar(out, Pan2.ar(LPF.ar(body, 4200) * env * amp, pan));
    }).add;

    SynthDef(\breathFlute, { |out=0, freq=440, amp=0.1, gate=1, pan=0|
        var vib = SinOsc.kr(4.8, 0, 0.008, 1);
        var tone = SinOsc.ar(freq*vib) + (SinOsc.ar(freq*2.01) * .16);
        var breath = BPF.ar(PinkNoise.ar(.12), freq*2.4, .5);
        var env = EnvGen.kr(Env.adsr(.18, .2, .72, .8), gate, doneAction: 2);
        Out.ar(out, Pan2.ar((tone + breath) * env * amp, pan));
    }).add;

    SynthDef(\singingString, { |out=0, freq=440, amp=.1, gate=1, pan=0|
        var vib = SinOsc.kr(5.2 + LFNoise1.kr(.3).range(-.25,.25), 0, .013, 1);
        var bow = VarSaw.ar(freq*vib*[.997,1.003], 0, .36).sum * .45;
        var tone = RLPF.ar(bow, (freq*4).clip(900,4200), .28);
        var env = EnvGen.kr(Env.adsr(.22,.35,.78,1.1), gate, doneAction: 2);
        Out.ar(out, Pan2.ar(tone * env * amp, pan));
    }).add;

    SynthDef(\mistHall, { |out=0|
        var dry = In.ar(out, 2);
        var wet = FreeVerb2.ar(dry[0], dry[1], .38, .88, .28);
        ReplaceOut.ar(out, Limiter.ar((dry*.72)+(LPF.ar(wet,5200)*.32), .92));
    }).add;
    s.sync;
    Synth.tail(~liangzhuGroup, \mistHall);

    if (recordPath.notNil) {
        s.prepareForRecord(recordPath.standardizePath, numChannels: 2); s.sync; s.record;
    };

    Pdef(\bass, Pbind(\instrument, \breathFlute, \group, ~liangzhuGroup,
        \midinote, Pseq(roots-12, inf), \dur, 2, \legato, .86, \amp, .075, \pan, -.28)).play(~liangzhuClock, quant: 1);
    Pdef(\moonLute, Pbind(\instrument, \pluckedSilk, \group, ~liangzhuGroup,
        \midinote, Pseq(roots.collect({ |n| [n+12,n+19,n+24,n+19] }).flat, inf),
        \dur, .5, \legato, .38, \amp, Pwhite(.07,.11,inf), \pan, -.16)).play(~liangzhuClock, quant: 1);
    Pdef(\xiao, Pbind(\instrument, \breathFlute, \group, ~liangzhuGroup,
        \midinote, Pseq(answer, inf), \dur, 1, \legato, .9, \amp, .09, \pan, .25)).play(~liangzhuClock, quant: 1);
    Pdef(\erhu, Pbind(\instrument, \singingString, \group, ~liangzhuGroup,
        \midinote, Pseq(theme, inf), \dur, .5, \legato, Pseq([.9,.78,.96,.82],inf),
        \amp, Pseg(Pseq([.08,.145,.1],inf),Pseq([16,16],inf)), \pan, .12)).play(~liangzhuClock, quant: 1);

    if (recordPath.notNil) {
        Routine({ recordDuration.wait; ~stopLiangzhu.(); 4.wait; s.stopRecording; 2.wait; s.quit; 1.wait; 0.exit; }).play(SystemClock);
    };
};
)
