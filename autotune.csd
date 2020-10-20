<CsoundSynthesizer>
<CsOptions>
-b128 -B256
</CsOptions>
<CsInstruments>

sr = 44100
; ksmps = 32
nchnls = 4

massign 0, 0 ; Disable default MIDI assignments.
massign 1, 2 ; Assign MIDI channel 1 to instr 2.

opcode  PitchShifter, a, akkii
         setksmps  1                   ; kr=sr
asig,kpitch,kfdb,idel,iwin  xin
kdelrate = (kpitch-1)/idel
avdel   phasor -kdelrate               ; 1 to 0
avdel2  phasor -kdelrate, 0.5          ; 1/2 buffer offset
afade  tablei avdel, iwin, 1, 0, 1     ; crossfade windows
afade2 tablei avdel2,iwin, 1, 0, 1
adump  delayr idel
atap1  deltapi avdel*idel           ; variable delay taps
atap2  deltapi avdel2*idel
amix   =   atap1*afade + atap2*afade2  ; fade in/out the delay taps
        delayw  asig+amix*kfdb          ; in+feedback signals
        xout  amix
endop

opcode AutotunePV, ak, aiii
ifftsize = 1024
iwtype = 1
ibase = 440
ibasemidi = 69
asig,ism,itrans,ifn xin
fsig pvsanal asig, ifftsize, ifftsize / 4, ifftsize, iwtype;
kfr, kamp pitchamdf asig, 130, 1040
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
fauto pvscale fsig, kratioport ; transpose it (optional param: formants)
aout pvsynth fauto
xout aout, (kratioport*kfr)
endop



/**** autotune  ***********************************/
/* aout Autotune asig,ism,ikey,ifn[,imeth]           */
/* asig -  
input                                                           */
/* ism - smoothing time in secs                            */
/* ikey - key (0 = C,... ,11 = B                       */
/* ifn - table containing scale pitch classes (7)  */
/* imeth - pitch track method: 0 - pitch (default) */
/*         1 - ptrack, 2 - pitchamdf                              */
/***************************************************/

opcode Autotune, ak, aiiio

iwinsize = 1024
ibase = 440
ibasemidi = 69

asig,ism,itrans,ifn,im  xin

if im == 0 then
kfr, kamp pitch asig,0.01,6.00,9.00,0
kfr = cpsoct(kfr)
elseif im == 1 then
kfr, kamp ptrack asig, 512
else
kfr, kamp pitchamdf asig,130,1500
endif

if (kfr > 10) kgoto ok
kfr = 440
ok:

ktemp = 12 * (log(kfr / ibase) / log(2)) + ibasemidi
ktet = round(ktemp)

kpos init 0
itrans = 2
test:
knote table kpos, ifn     ; get a pitch class from table
ktest = ktet % 12       ;  note mod 12
knote = (knote+itrans) % 12 ; plus transpose interval mod 12
if ktest == knote kgoto next ; test if note matches pitch class +  transposition
kpos = kpos + 1           ; increment table pos
if kpos >= 7  kgoto shift ; if more than or pitch class set we need to  shift it
kgoto test                ; loop back

shift:
if (ktemp >= ktet) kgoto plus
ktet = ktet - 1
kgoto next
plus:
ktet = ktet + 1

next:
kpos = 0
ktarget = ibase * (2 ^ ((ktet - ibasemidi) / 12))
kratio = ktarget/kfr
kratioport port kratio, ism, ibase

aout PitchShifter asig,kratioport, 0, 0.1, 5 

       xout     aout, (kratioport*kfr)
endop


instr 1

gaClean	inch 1

; Autotune the input signal and store the result and its 
; target frequency in global buffers
gaTuned, gkFrequency AutotunePV, gaClean, 0.0001, 1, 3

endin

instr 2
; Get the frequency and amplitude from the midi-key
iCps    	cpsmidi   
iAmp    	ampmidi   0dbfs * 0.5 

; Calculate the ratio between the midi-note and the tuned note
; and shift the tuned audio it by that ratio
kRatio =      iCps/gkFrequency
aHarmony 	PitchShifter gaTuned, kRatio, 0, 0.1, 5 
iPan 	random 0, 1

aHarmonyL, aHarmonyR pan2 aHarmony, iPan

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
i99 0 86400 ; Activate the Reverb/Flanger always-on instrument.
e

</CsScore>
</CsoundSynthesizer> 