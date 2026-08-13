<CsoundSynthesizer>
<CsOptions>
-o canon_csound.wav -d -m0
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
; harmonic cycle (8 chords): D  A  Bm  F#m  G  D  G  A
giPianoRoots ftgen 1, 0, 8, -2, 50, 45, 47, 42, 43, 50, 43, 45
giBass      ftgen 2, 0, 8, -2, 38, 33, 35, 30, 31, 38, 31, 33
giViola     ftgen 3, 0, 32, -2, \
  57, 62, 66, 62,  52, 57, 61, 57,  54, 59, 62, 59,  50, 54, 57, 54, \
  50, 55, 59, 55,  57, 62, 66, 62,  50, 55, 59, 55,  52, 57, 61, 57
giArpeggio  ftgen 4, 0, 64, -2, \
  62, 69, 74, 78, 74, 69, 74, 78,  57, 64, 69, 73, 69, 64, 69, 73, \
  59, 66, 71, 74, 71, 66, 71, 74,  54, 61, 66, 69, 66, 61, 66, 69, \
  55, 62, 67, 71, 67, 62, 67, 71,  62, 69, 74, 78, 74, 69, 74, 78, \
  55, 62, 67, 71, 67, 62, 67, 71,  57, 64, 69, 73, 69, 64, 69, 73
giViolin    ftgen 5, 0, 64, -2, \
  74, 73, 74, 66, 69, 71, 73, 69, 71, 73, 74, 71, 69, 66, 69, 62, \
  62, 66, 69, 74, 73, 69, 66, 62, 64, 67, 71, 76, 74, 71, 67, 64, \
  69, 71, 73, 74, 76, 73, 74, 71, 69, 71, 73, 66, 69, 67, 66, 62, \
  57, 62, 66, 69, 71, 66, 69, 62, 64, 69, 73, 76, 78, 73, 76, 69

; Canon in D, 84 BPM, beat = 60/84 s

; ---------------- scheduler ----------------
instr 1
  ; schedules all note events that start before p3 (total render duration)
  ibeat = 60 / 84
  ; harmonic parts repeat every 16 beats (one chord = 2 beats)
  iclen = 16 * ibeat
  inloops = int(p3 / iclen) + 1
  iloop = 0
loop_harm:
  istart = iloop * iclen
  ; piano left: chord roots, one per 2 beats
  ii = 0
loop_pL:
  inote = table(ii, giPianoRoots)
  isched = istart + ii * 2 * ibeat
  if (isched < p3) then
    schedule 10, isched, min(3.0, p3 - isched), inote, 0.18, -0.16
  endif
  ii += 1
  if (ii < 8) goto loop_pL
  ; cello: bass roots, one per 2 beats
  ii = 0
loop_cello:
  inote = table(ii, giBass)
  isched = istart + ii * 2 * ibeat
  if (isched < p3) then
    schedule 11, isched, min(3.5, p3 - isched), inote, 0.16, -0.34, 0.28, 0.25, 280, 0.007
  endif
  ii += 1
  if (ii < 8) goto loop_cello
  ; viola: inner voices, eighth notes
  ii = 0
loop_viola:
  inote = table(ii, giViola)
  isched = istart + ii * 0.5 * ibeat
  if (isched < p3) then
    schedule 11, isched, min(1.2, p3 - isched), inote, 0.088, 0.18, 0.2, 0.75, 400, 0.011
  endif
  ii += 1
  if (ii < 32) goto loop_viola
  ; piano right: arpeggio, sixteenth notes
  ii = 0
loop_pR:
  inote = table(ii, giArpeggio)
  isched = istart + ii * 0.25 * ibeat
  if (isched < p3) then
    schedule 10, isched, min(1.5, p3 - isched), inote, 0.07, 0.0
  endif
  ii += 1
  if (ii < 64) goto loop_pR
  iloop += 1
  if (iloop < inloops) goto loop_harm
  ; violin melody: 64 eighth notes over 32 beats (two harmonic cycles)
  imlen = 32 * ibeat
  imloops = int(p3 / imlen) + 1
  iloop = 0
loop_vln:
  istart = iloop * imlen
  ii = 0
loop_vln_i:
  inote = table(ii, giViolin)
  isched = istart + ii * 0.5 * ibeat
  if (isched < p3) then
    schedule 11, isched, min(1.4, p3 - isched), inote, 0.11, 0.38, 0.14, 1.35, 520, 0.016
  endif
  ii += 1
  if (ii < 64) goto loop_vln_i
  iloop += 1
  if (iloop < imloops) goto loop_vln
endin

; ---------------- soft piano ----------------
; p4 midi note, p5 amp, p6 pan
instr 10
  ifreq = cpsmidinn(p4)
  iamp = p5
  ipan = p6
  ; hammer transient (filtered noise)
  aclick = butterbp(rand(0.8), 2500, 1400)
  aclick = aclick * expseg(1, 0.005, 0.001, 0.04, 0.0001)
  ; inharmonic string body
  abody = poscil(0.55, ifreq) + poscil(0.24, ifreq * 1.997) + poscil(0.13, ifreq * 3.01)
  aenv = expseg(0.001, 0.004, 1, 0.25, 0.4, p3, 0.0001)
  asig = (abody * aenv + aclick * 0.9) * iamp
  asig = butterlp(asig, 4200)
  aL, aR pan2 asig, ipan
  gaDryL = gaDryL + aL
  gaDryR = gaDryR + aR
  gaRevL = gaRevL + aL * 0.25
  gaRevR = gaRevR + aR * 0.25
endin

; ---------------- bowed string ----------------
; p4 midi note, p5 amp, p6 pan, p7 attack, p8 bright, p9 body resonance, p10 vibrato
instr 11
  ifreq = cpsmidinn(p4)
  iamp = p5
  ipan = p6
  iatt = p7
  ibright = p8
  ibody = p9
  ivib = p10
  asig wgbow iamp * 1.5, ifreq, 1.0, 0.5, 5.1, ivib, giSine, 60
  acut = limit(ifreq * (3.0 + ibright), 900, 5200)
  asig = butterlp(asig, acut)
  ares = butterbp(asig, ibody, ibody * 0.3) * 0.16
  asig = asig + ares
  aenv = linseg(0, iatt, 1, p3 - iatt, 0.72, 0.06, 0)
  asig = asig * aenv
  aL, aR pan2 asig, ipan
  gaDryL = gaDryL + aL
  gaDryR = gaDryR + aR
  gaRevL = gaRevL + aL * 0.22
  gaRevR = gaRevR + aR * 0.22
endin

; ---------------- master bus + reverb ----------------
instr 99
  aRevL, aRevR freeverb gaRevL, gaRevR, 0.78, 0.4
  aL = (gaDryL + aRevL * 0.55) * 2.2
  aR = (gaDryR + aRevR * 0.55) * 2.2
  ; gentle master fade over the last 1.5 s
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
;   csound --smacro:DURATION=8 -o out.wav canon/main.csd
#ifndef DURATION
#define DURATION #137.2#
#end
i 1 0 $DURATION
i 99 0 $DURATION
e
</CsScore>
</CsoundSynthesizer>
