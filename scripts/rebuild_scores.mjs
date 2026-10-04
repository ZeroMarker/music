import { readFile, writeFile } from 'node:fs/promises';

// The three engines share this finite score: time and duration are in beats.
// Run npm run rebuild:music after changing a theme or the arrangement below.
const projects = {
  canon: {
    bpm: 84, step: .25, cycles: 11,
    chords: [[50,57,62,66],[45,52,57,61],[47,54,59,62],[42,50,54,57],[43,50,55,59],[50,57,62,66],[43,50,55,59],[45,52,57,61]],
    theme: [74,73,74,66,69,71,73,69,71,73,74,71,69,66,69,62,62,66,69,74,73,69,66,62,64,67,71,76,74,71,67,64,69,71,73,74,76,73,74,71,69,71,73,66,69,67,66,62,57,62,66,69,71,66,69,62,64,69,73,76,78,73,76,69],
    voices: {
      pianoLeft: { sc: 'softPiano', cs: 10, pan: -.16, sound: 'triangle', filter: 1500, attack: .004, release: .65 },
      pianoRight: { sc: 'softPiano', cs: 10, pan: -.06, sound: 'triangle', filter: 3200, attack: .003, release: .3 },
      cello: { sc: 'bowedString', cs: 11, pan: -.3, sound: 'sawtooth', filter: 650, attack: .2, release: .55, extra: [.2,.25,280,.004] },
      viola: { sc: 'bowedString', cs: 11, pan: .16, sound: 'triangle', filter: 1400, attack: .09, release: .22, extra: [.09,.65,400,.005] },
      violin: { sc: 'bowedString', cs: 11, pan: .3, sound: 'sawtooth', filter: 2400, attack: .07, release: .3, extra: [.07,1.1,520,.007] },
    },
  },
  liangzhu: {
    bpm: 72, step: .5, cycles: 9,
    chords: [[50,57,62,69],[45,52,57,64],[47,54,59,66],[43,50,55,62],[50,57,62,69],[52,59,64,71],[43,50,55,62],[45,52,57,64]],
    theme: [69,71,74,76,74,71,69,67,64,67,69,71,69,67,64,62,71,74,76,79,76,74,71,69,67,69,71,74,69,67,64,62],
    answer: [62,64,67,69,71,69,67,64,62,67,69,71,74,71,69,67],
    voices: {
      bass: { sc: 'breathFlute', cs: 21, pan: -.22, sound: 'sine', filter: 650, attack: .18, release: .5, extra: [.18,.003] },
      moonLute: { sc: 'pluckedSilk', cs: 20, pan: -.18, sound: 'triangle', filter: 3000, attack: .003, release: .45 },
      xiao: { sc: 'breathFlute', cs: 21, pan: .25, sound: 'sine', filter: 2400, attack: .12, release: .4, extra: [.12,.004] },
      erhu: { sc: 'singingString', cs: 22, pan: .08, sound: 'sawtooth', filter: 1800, attack: .1, release: .35 },
    },
  },
};

for (const [name, p] of Object.entries(projects)) {
  const events = Object.fromEntries(Object.keys(p.voices).map(v => [v, []]));
  const add = (voice, time, note, duration, amp) => {
    // Repeatable phrasing: accent the downbeat, soften the phrase ending.
    const accent = time % 2 === 0 ? 1 : .88;
    events[voice].push({ time, note, duration, amp: +(amp * accent).toFixed(4) });
  };
  for (let cycle = 0; cycle < p.cycles; cycle++) {
    const start = cycle * 16;
    const closing = cycle === p.cycles - 1;
    const lift = closing ? .72 : cycle >= 6 ? 1.12 : cycle >= 3 ? 1 : .8;
    for (let c = 0; c < 8; c++) {
      const chord = p.chords[c], t = start + c * 2;
      if (name === 'canon') {
        add('cello', t, chord[0]-12, 1.8, .105 * lift);
        add('pianoLeft', t, chord[0], 1.3, .12 * lift);
        if (cycle >= 1) {
          const arp = [0,1,2,3,2,1,2,3];
          const density = cycle < 3 || closing ? .5 : .25;
          for (let i = 0; i < 2/density; i++) add('pianoRight', t+i*density, chord[arp[i]]+12, density*.7, .055*lift);
        }
        if (cycle >= 2 && cycle !== 5) {
          for (let i=0; i<2; i++) add('viola', t+i, chord[i+1], .82, .045*lift);
        }
      } else {
        add('bass', t, chord[0]-12, 1.7, .085*lift);
        const count = closing || cycle === 4 ? 2 : 4;
        for (let i=0; i<count; i++) add('moonLute', t+i*2/count, chord[[2,3,2,1][i]], .35, .075*lift);
      }
    }
    if (name === 'canon' && cycle >= 2) {
      for (let i=0; i<32; i++) {
        // A quiet middle section gives the melody space before the return.
        if (cycle === 5 && i >= 16) continue;
        add('violin', start+i*.5, p.theme[((cycle-2)%2)*32+i], .44, .10*lift);
      }
    }
    if (name === 'liangzhu') {
      // Long, breathing theme phrases alternate with the flute response.
      if ([1,3,4,7,8].includes(cycle)) {
        for (let i=0; i<8; i++) add('xiao', start+i*2, p.answer[(cycle%2)*8+i], i%4===3 ? 1.1 : 1.65, .09*lift);
      }
      if ([2,3,5,6,7,8].includes(cycle)) {
        const offsets = [0,1,2,4,5,6,8,10,11,12,14];
        const indices = [0,1,2,3,4,6,8,9,10,12,15];
        for (let i=0; i<offsets.length; i++) {
          const d = (offsets[i+1] ?? 16) - offsets[i];
          add('erhu', start+offsets[i], p.theme[(cycle%2)*16+indices[i]], d*.9, .10*lift);
        }
      }
    }
  }
  const cadence = p.cycles*16;
  if (name === 'canon') {
    add('cello', cadence, 38, 3.5, .075);
    [50,57,62,66].forEach((n,i)=>add('pianoLeft', cadence+i*.25, n, 3-i*.25, .075));
    add('violin', cadence, 74, 3, .065);
  } else {
    add('bass', cadence, 38, 3.5, .06);
    [62,69,74].forEach((n,i)=>add('moonLute', cadence+i*.5, n, 2.5-i*.5, .06));
    add('erhu', cadence, 74, 3, .065);
  }
  const beats = cadence+4, seconds = beats*60/p.bpm;
  const grids = Object.entries(p.voices).map(([voice, v]) => {
    const steps = Array.from({length: beats/p.step},()=>null);
    for (const e of events[voice]) steps[Math.round(e.time/p.step)] = e;
    return { voice, ...v, steps };
  });
  const browser = `\n// Generated by scripts/rebuild_scores.mjs. One cycle = four beats.\nconst voices = ${JSON.stringify(grids).replaceAll('"', "'")};\nconst parts = voices.map(v => fastcat(...v.steps.map(e => e\n  ? note(e.note).gain(e.amp).clip(e.duration / ${p.step})\n  : silence))\n  .slow(${beats/4}).sound(v.sound).lpf(v.filter)\n  .attack(v.attack).decay(.2).sustain(.65).release(v.release)\n  .pan(v.pan / 2 + .5).room(.23));\nconst ending = signal(t => t < ${beats/4} ? 1 : 0);\nstack(...parts).mask(ending).postgain(1.8).fast(${p.bpm/120})\n`;
  const htmlPath = `${name}/strudel.html`;
  let html = await readFile(htmlPath,'utf8');
  html = html.replace(/(const\s+(?:canonCode|music)\s*=\s*(?:String\.raw)?`)[\s\S]*?(`;)/,(_,a,b)=>a+browser+b);
  await writeFile(htmlPath,html);

  const sc = grids.map(v => {
    const notes = v.steps.map(e=>e ? e.note : 'Rest()').join(',');
    const amps = v.steps.map(e=>e ? e.amp : 0).join(',');
    const lengths = v.steps.map(e=>e ? e.duration : p.step).join(',');
    let extra = '';
    if (v.cs===11) extra = `, \\attack, ${v.extra[0]}, \\bright, ${v.extra[1]}, \\bodyResFreq, ${v.extra[2]}, \\vibrato, ${v.extra[3]}`;
    return `    Pdef(\\${v.voice}, Pbind(\\instrument, \\${v.sc}, \\group, ~${name}Group,\n        \\midinote, Pseq([${notes}], 1),\n        \\amp, Pseq([${amps}], 1), \\sustain, Pseq([${lengths}], 1),\n        \\dur, ${p.step}, \\pan, ${v.pan}${extra})).play(~${name}Clock, quant: 1);`;
  }).join('\n');
  const scPath = `${name}/main.scd`;
  let source = await readFile(scPath,'utf8');
  const generatedStart = source.indexOf('    // Generated finite arrangement');
  const begin = generatedStart >= 0 ? generatedStart : source.indexOf(name==='canon' ? '    // ----- Harmony and Melody -----' : '    Pdef(\\bass,');
  const end = source.indexOf('    if (recordPath.notNil) {',begin);
  if (begin < 0 || end < 0) throw new Error(`${scPath}: arrangement markers missing`);
  source = source.slice(0,begin)+`    // Generated finite arrangement (${seconds.toFixed(2)} s plus release tails).\n${sc}\n\n`+source.slice(end);
  // Remove generated data declarations; the score is defined above in one place.
  if (name==='canon') source=source.replace('    var progression, canonA, canonB, canonC, canonD;\n','').replace('    var bassNotes, pianoRoots, violaInner, pianoArpegg;\n','');
  else source=source.replace(/    var roots = [\s\S]*?    var recordPath/, '    var recordPath');
  await writeFile(scPath,source);

  const csPath = `${name}/main.csd`;
  let cs = await readFile(csPath,'utf8');
  const scheduler = Object.entries(events).flatMap(([voice, notes])=>notes.map(e=>({ ...e, v:p.voices[voice] }))).sort((a,b)=>a.time-b.time).map(e=> {
    const at=e.time*60/p.bpm, len=e.duration*60/p.bpm;
    const extra = e.v.extra ? ', '+e.v.extra.join(', ') : '';
    return `  if (p3 > ${at.toFixed(6)}) then\n    schedule ${e.v.cs}, ${at.toFixed(6)}, min(${len.toFixed(6)}, p3 - ${at.toFixed(6)}), ${e.note}, ${e.amp}, ${e.v.pan}${extra}\n  endif`;
  }).join('\n');
  cs=cs.replace(/(?:; ---- note tables|; Generated finite score:)[\s\S]*?endin/, `; Generated finite score: intro, development, return, tonic cadence.\ninstr 1\n${scheduler}\nendin`);
  await writeFile(csPath,cs);
  console.log(`Rebuilt ${name}: ${beats} beats, cadence at ${(cadence*60/p.bpm).toFixed(2)} s`);
}
