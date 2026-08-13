<CsoundSynthesizer>
<CsOptions>
-o liangzhu_csound.wav -d -m0
</CsOptions>
<CsInstruments>

sr = 44100
ksmps = 32
nchnls = 2
0dbfs = 1

; ---- global mix buses ----
gaDryL init 0
gaDryR init 0
gaRevL init 0
gaRevR init 0

; wavetable for physical models
giSine ftgen 0, 0, 4096, 10, 1

; ---- note tables (MIDI note numbers) ----
; 8-chord cycle: D  A  Bm  G  D  E  G  A
giRoots     ftgen 1, 0, 8, -2, 50, 45, 47, 43, 50, 52, 43, 45
giBass      ftgen 2, 0, 8, -2, 38, 33, 35, 31, 38, 40, 31, 33
giMoonLute  ftgen 3, 0, 32, -2, \
  62, 69, 74, 69,  57, 64, 69, 64,  59, 66, 71, 66,  55, 62, 67, 62, \
  62, 69, 74, 69,  64, 71, 76, 71,  55, 62, 67, 62,  57, 64, 69, 64
giXiao      ftgen 4, 0, 16, -2, \
  62, 64, 67, 69, 71, 69, 67, 64, 62, 67, 69, 71, 74, 71, 69, 67
giTheme     ftgen 5, 0, 32, -2, \
  69, 71, 74, 76, 74, 71, 69, 67, 64, 67, 69, 71, 69, 67, 64, 62, \
  71, 74, 76, 79, 76, 74, 71, 69, 67, 69, 71, 74, 69, 67, 64, 62

; Butterfly Lovers · Reverie, 72 BPM, beat = 60/72 s
; all parts repeat every 16 beats

; ---------------- scheduler ----------------
instr 1
  ibeat = 60 / 72
  iclen = 16 * ibeat
  inloops = int(p3 / iclen) + 1
  iloop = 0
loop_cycle:
  istart = iloop * iclen
  ; moon lute: plucked arpeggio, sixteenth notes
  ii = 0
loop_lute:
  inote = table(ii, giMoonLute)
  isched = istart + ii * 0.5 * ibeat
  if (isched < p3) then
    schedule 20, isched, min(0.9, p3 - isched), inote, 0.09, -0.16
  endif
  ii += 1
  if (ii < 32) goto loop_lute
  ; bass: breathy long tones, one per 2 beats
  ii = 0
loop_bass:
  inote = table(ii, giBass)
  isched = istart + ii * 2 * ibeat
  if (isched < p3) then
    schedule 21, isched, min(2.6, p3 - isched), inote, 0.075, -0.28, 1.6, 0.02
  endif
  ii += 1
  if (ii < 8) goto loop_bass
  ; xiao: answering phrase, quarter notes
  ii = 0
loop_xiao:
  inote = table(ii, giXiao)
  isched = istart + ii * 1 * ibeat
  if (isched < p3) then
    schedule 21, isched, min(1.8, p3 - isched), inote, 0.09, 0.25, 0.9, 0.01
  endif
  ii += 1
  if (ii < 16) goto loop_xiao
  ; erhu: singing theme, eighth notes
  ii = 0
loop_erhu:
  inote = table(ii, giTheme)
  isched = istart + ii * 0.5 * ibeat
  if (isched < p3) then
    schedule 22, isched, min(1.2, p3 - isched), inote, 0.11, 0.12
  endif
  ii += 1
  if (ii < 32) goto loop_erhu
  iloop += 1
  if (iloop < inloops) goto loop_cycle
endin

; ---------------- moon lute (plucked silk) ----------------
; p4 midi note, p5 amp, p6 pan
instr 20
  ifreq = cpsmidinn(p4)
  iamp = p5
  ipan = p6
  astr wgpluck2 0.5, iamp, ifreq, 0.4, 0.6
  ; plucked-string body with a touch of the octave partial
  astr = astr + (poscil(0.25, ifreq * 2.01) * expseg(1, 0.02, 0.4, p3, 0.001))
  astr = butterlp(astr, 4200)
  aL, aR pan2 astr, ipan
  gaDryL = gaDryL + aL
  gaDryR = gaDryR + aR
  gaRevL = gaRevL + aL * 0.18
  gaRevR = gaRevR + aR * 0.18
endin

; ---------------- breath flute (xiao / bass) ----------------
; p4 midi note, p5 amp, p6 pan, p7 attack, p8 vibrato depth
instr 21
  ifreq = cpsmidinn(p4)
  iamp = p5
  ipan = p6
  iatt = p7
  ivib = p8
  avib = 1 + oscili(ivib, 4.8)
  aflute = poscil(0.5, ifreq * avib) + poscil(0.14, ifreq * 2.01 * avib)
  abreath = butterbp(pinkish(0.05), ifreq * 2.4, ifreq * 1.2)
  aenv = linseg(0, iatt, 1, p3 - iatt, 0.75, 0.08, 0)
  asig = (aflute + abreath) * aenv * iamp
  asig = butterlp(asig, 4200)
  aL, aR pan2 asig, ipan
  gaDryL = gaDryL + aL
  gaDryR = gaDryR + aR
  gaRevL = gaRevL + aL * 0.2
  gaRevR = gaRevR + aR * 0.2
endin

; ---------------- erhu (singing string) ----------------
; p4 midi note, p5 amp, p6 pan
instr 22
  ifreq = cpsmidinn(p4)
  iamp = p5
  ipan = p6
  avib = 1 + oscili(0.013, 5.2)
  ; two detuned bowed partials
  abow = poscil(0.4, ifreq * 0.997 * avib) + poscil(0.4, ifreq * 1.003 * avib)
  asig = butterlp(abow, limit(ifreq * 4, 900, 4200))
  aenv = linseg(0, 0.22, 1, p3 - 0.22, 0.78, 0.1, 0)
  asig = asig * aenv * iamp
  aL, aR pan2 asig, ipan
  gaDryL = gaDryL + aL
  gaDryR = gaDryR + aR
  gaRevL = gaRevL + aL * 0.22
  gaRevR = gaRevR + aR * 0.22
endin

; ---------------- master bus + reverb ----------------
instr 99
  aRevL, aRevR freeverb gaRevL, gaRevR, 0.85, 0.35
  aL = gaDryL + aRevL * 0.5
  aR = gaDryR + aRevR * 0.5
  kfade = linseg(1, p3 - 1.5, 1, 1.5, 0)
  aL = aL * kfade
  aR = aR * kfade
  aOutL clip aL, -0.9, 0.9
  aOutR clip aR, -0.9, 0.9
  outs aOutL, aOutR
  gaDryL = 0
  gaDryR = 0
  gaRevL = 0
  gaRevR = 0
endin

</CsInstruments>
<CsScore>
; DURATION defaults to the full render length; override with
;   csound --smacro:DURATION=8 -o out.wav liangzhu/main.csd
#ifndef DURATION
#define DURATION #128#
#end
i 1 0 $DURATION
i 99 0 $DURATION
e
</CsScore>
</CsoundSynthesizer>
