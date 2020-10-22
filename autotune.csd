<CsoundSynthesizer>
<CsOptions>
-b128 -B256
</CsOptions>
<CsInstruments>

sr = 44100
ksmps = 16
nchnls = 4

gi_pitch_table ftgen	5, 0, 16384, 20, 1
gi_major_table ftgen 3, 0, 8, -2, 0, 2, 4, 5, 7, 9, 11, 12
gi_minor_table ftgen 4, 0, 8, -2, 0, 2, 3, 5, 7, 8, 10, 12

chn_k "formant",       1
chn_k "formantEnable", 1

massign 0, 0 ; Disable default MIDI assignments.
massign 1, 3 ; Assign MIDI channel 1 to instr 2.

opcode  PitchShifter, a, akki
         setksmps  1
asig,kpitch,kfdb,idel xin
kdelrate = (kpitch-1)/idel
avdel   phasor 	-kdelrate
avdel2  phasor 	-kdelrate, 0.5
afade   tablei 	avdel, gi_pitch_table, 1, 0, 1
afade2  tablei 	avdel2,gi_pitch_table, 1, 0, 1
adump   delayr 	idel
atap1   deltapi 	avdel*idel
atap2   deltapi 	avdel2*idel
amix    = atap1*afade + atap2*afade2
        delayw  	asig+amix*kfdb 
        xout  	amix
endop


opcode AutotuneHelper, kk, aiii
	setksmps  1

ibase     = 440
ibasemidi = 69

asig,ism,itrans,ifn xin

kfr, kamp ptrack asig, 1024
if (kfr > 10) kgoto ok
kfr = 440
ok:
	ktemp = 12 * (log(kfr / ibase) / log(2)) + ibasemidi
	kmidi = round(ktemp)
	kpos init 0
	itrans = 2
test:
	knote table kpos, ifn ; get a pitch class
	ktest = kmidi % 12 ; note mod 12
	knote = (knote+itrans) % 12
	if ktest == knote kgoto next ; test if note matches pitch class +  transposition
	kpos = kpos + 1 ; increment table pos
	if kpos >= 7 kgoto shift ; if more than or pitch class set we need to  shift it
	kgoto test ; loop back
shift:
	if (ktemp >= kmidi) kgoto plus
	kmidi = kmidi - 1
	kgoto next
plus:
	kmidi = kmidi + 1
next:
	kpos = 0
	ktarget = ibase * (2 ^ ((kmidi - ibasemidi) / 12))
	kratio = ktarget/kfr
	kratioport port kratio, ism, ibase

xout kratioport, ktarget

endop


instr 1
ifftsize  = 1024
ioverlap  = ifftsize/4 
iwinsize  = 1024
iwinshape = 1

ksemitones      chnget "formant" 
kformant_enable chnget "formantEnable"

ga_clean	 inch 1

kratio, gk_main_freq AutotuneHelper, ga_clean, 0.01, 1, 3
fsig pvsanal ga_clean, ifftsize, ioverlap, iwinsize, iwinshape

if kformant_enable == 1 then
	; Here, we do one shift preserving formants, 
	; and another that does not preserve formants.
	; The result of this will be the same pitch, 
	; but with formants related to the first pitch.
	; We combine the first shift with the 
	; ratio for the pitch correction to save
	; a scaling operation, and to avoid a bug
	; that occured when doing 3 pvscale's.
	
	ktoneratio      = 1.05946309436
	kpreserve_ratio = ktoneratio ^ -ksemitones 
	kreturn_ratio   = ktoneratio ^ ksemitones 
	
	fpreserve       = pvscale(fsig, kratio*kpreserve_ratio, 2)
	fresult         = pvscale(fpreserve, kreturn_ratio, 0)
else
	fresult         = pvscale(fsig, kratio, 2)
endif

atuned pvsynth fresult
ga_tuned butlp buthp(atuned, 60), 15000

endin


instr 3
; Get the frequency and amplitude from the midi-key
ithis_freq  = cpsmidi()  
iamp 	     = 0.5 + 4*(ampmidi(0.125)) ; scale the ampplitude to give some room for dynamics
kenv        = linsegr(0.1, 0.1, 1, 0.1, 0)

; Calculate the ratio between the midi-note and the tuned note
; and shift the tuned audio it by that ratio
kratio   = ithis_freq / gk_main_freq
aharmony = kenv * iamp * PitchShifter(ga_tuned, kratio, 0, 0.1)

ipanrange = 0.25
ipan = random(0.5-ipanrange, 0.5+ipanrange)
aharmony_l, aharmony_r pan2 aharmony, ipan, 1

; Add this pitch to the harmonies buffer
ga_harmonies_l += aharmony_l
ga_harmonies_r += aharmony_r

endin


instr 99
	; Prevent CPU spikes on Intel processors.
	denorm ga_clean, ga_tuned, ga_harmonies_l, ga_harmonies_r
	outch 1, ga_clean, 2, ga_tuned, 3, ga_harmonies_l, 4, ga_harmonies_r

; Clear globals to avoid buildup
ga_clean = 0
ga_tuned = 0
ga_harmonies_l = 0
ga_harmonies_r = 0
endin


</CsInstruments>
<CsScore>

i1  0 86400
i99 0 86400 ; Activate the Reverb/Flanger always-on instrument.
e

</CsScore>
</CsoundSynthesizer> 