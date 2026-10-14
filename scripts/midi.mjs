// Minimal Standard MIDI File (format 1) writer for the shared finite score.
const PPQ = 480;

const varLen = (n) => {
  const bytes = [n & 0x7f];
  while ((n >>= 7)) bytes.unshift((n & 0x7f) | 0x80);
  return bytes;
};
const u32 = (n) => [n >>> 24, (n >>> 16) & 255, (n >>> 8) & 255, n & 255];
const chunk = (type, data) => [...Buffer.from(type, 'ascii'), ...u32(data.length), ...data];
const text = (type, s) => { const b = [...Buffer.from(s, 'utf8')]; return [0xff, type, ...varLen(b.length), ...b]; };

// events: [{ tick, order, bytes }]; note-offs sort before note-ons at the same tick.
const track = (events, endTick) => {
  const data = [];
  let last = 0;
  for (const e of events.sort((a, b) => a.tick - b.tick || a.order - b.order)) {
    data.push(...varLen(e.tick - last), ...e.bytes);
    last = e.tick;
  }
  data.push(...varLen(Math.max(0, endTick - last)), 0xff, 0x2f, 0);
  return chunk('MTrk', data);
};

// Amplitudes in the score are linear gains around 0.03-0.13; map them to velocity.
const velocity = (amp) => Math.max(20, Math.min(127, Math.round(Math.sqrt(amp / .12) * 108)));

export function midiFile({ bpm, endBeat, tracks }) {
  const endTick = Math.round(endBeat * PPQ);
  const tempo = Math.round(60e6 / bpm);
  const conductor = track([
    { tick: 0, order: 0, bytes: [0xff, 0x51, 3, tempo >> 16, (tempo >> 8) & 255, tempo & 255] },
    { tick: 0, order: 0, bytes: [0xff, 0x58, 4, 4, 2, 24, 8] },
  ], endTick);
  const parts = tracks.map((t, i) => {
    const ch = i >= 9 ? i + 1 : i; // channel 10 is percussion
    if (ch > 15) throw new Error('too many MIDI tracks');
    const pan = Math.max(0, Math.min(127, Math.round(64 + t.pan * 127)));
    const events = [
      { tick: 0, order: 0, bytes: text(0x03, t.name) },
      { tick: 0, order: 0, bytes: [0xc0 | ch, t.program] },
      { tick: 0, order: 0, bytes: [0xb0 | ch, 7, 100] },
      { tick: 0, order: 0, bytes: [0xb0 | ch, 10, pan] },
      { tick: 0, order: 0, bytes: [0xb0 | ch, 91, 48] },
    ];
    for (const n of t.notes) {
      const on = Math.round(n.time * PPQ), off = Math.round((n.time + n.duration) * PPQ);
      events.push({ tick: on, order: 2, bytes: [0x90 | ch, n.note, velocity(n.amp)] });
      events.push({ tick: off, order: 1, bytes: [0x80 | ch, n.note, 0] });
    }
    return track(events, endTick);
  });
  const header = chunk('MThd', [0, 1, 0, tracks.length + 1, PPQ >> 8, PPQ & 255]);
  return Buffer.from([...header, ...conductor, ...parts.flat()]);
}
