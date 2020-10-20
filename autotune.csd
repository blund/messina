<CsoundSynthesizer>
<CsOptions>
-b128 -B256
</CsOptions>
<CsInstruments>

#include "udo.txt"

sr = 44100
ksmps = 32
nchnls = 4

chn_k "formant", 1
chn_k "formantEnable", 1

massign 0, 0 ; Disable default MIDI assignments.
massign 1, 3 ; Assign MIDI channel 1 to instr 2.


instr 1
kFormant chnget "formant"
gkFormantEnable chnget "formantEnable"
gkFormant portk kFormant, 0.01
endin

instr 2

gaClean	inch 1

; Autotune the input signal and store the result and its 
; target frequency in global buffers
aTuned, gkFrequency AutotunePV, gaClean, 0.0001, 1, 3

ifftsize = 1024
iwtype = 1
fsig pvsanal aTuned, ifftsize, ifftsize / 4, ifftsize, iwtype;


if gkFormantEnable == 1 then

	if gkFormant == 0 then
	gkFormant = 1
	endif

	fresult = pvscale(pvscale(fsig, 1/gkFormant, 1), gkFormant, 0)

else
	fresult = fsig
endif

gaTuned pvsynth fresult
endin

instr 3
; Get the frequency and amplitude from the midi-key
iCps    	cpsmidi   
iAmp = 0.5 + 4*(ampmidi(0.125))

kEnv     linsegr   0.001, 0.1, 1, 0.1, 0

; Calculate the ratio between the midi-note and the tuned note
; and shift the tuned audio it by that ratio
kRatio =      iCps/gkFrequency
aHarmony = kEnv * iAmp * PitchShifter(gaTuned, kRatio, 0, 0.1, 5)

iPanRange = 0.25
iPan = random(0.5-iPanRange, 0.5+iPanRange)
aHarmonyL, aHarmonyR pan2 aHarmony, iPan, 1

; Add this pitch to the harmonies buffer
gaHarmoniesL += aHarmonyL
gaHarmoniesR += aHarmonyR

endin


instr 99
	; Prevent CPU spikes on Intel processors.
	denorm gaClean, gaTuned, gaHarmoniesL, gaHarmoniesR
	outch 1, gaClean, 2, gaTuned, 3, gaHarmoniesL, 4, gaHarmoniesR

; Clear globals to avoid buildup
gaClean = 0
gaTuned = 0
gaHarmoniesL = 0
gaHarmoniesR = 0
endin


</CsInstruments>
<CsScore>

f3 0 8 -2 0 2 4 5 7 9 11 12
f4 0 8 -2 0 2 3 5 7 8 10 12
f5 0 16384 20 1

i1  0 86400
i2  0 86400
i99 0 86400 ; Activate the Reverb/Flanger always-on instrument.
e

</CsScore>
</CsoundSynthesizer> 