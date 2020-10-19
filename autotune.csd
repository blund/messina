<CsoundSynthesizer>
<CsOptions>
-b128 -B256
</CsOptions>
<CsInstruments>

sr = 44100
ksmps = 32
nchnls = 2

massign 0, 0 ; Disable default MIDI assignments.
massign 1, 2 ; Assign MIDI channel 1 to instr 2.
zakinit 2, 1 ; Create 2 a-rate zak channels and 1 k-rate zak channel.

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

iwinsize = 512
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

aout PitchShifter asig,kratioport,0,0.1,5 

       xout     aout, ktarget
endop


instr 1
interv1 = 2^(5/12)

ainl 	inch 1
ainr 	inch 2   
gaoutl, gkfrequency 	Autotune ainl, 0.0001, 1, 3 ,  1  
	zawm gaoutl, 1
; 	outch 1, gaoutl, 2, gaoutl
endin

instr 2
iCps    cpsmidi   ;get the frequency from the key pressed
iAmp    ampmidi   0dbfs * 0.3 ;get the amplitude
kratio = iCps/gkfrequency

aout PitchShifter gaoutl,kratio,0,0.1,5

; aOut    poscil    iAmp, iCps ;generate a sine tone
	 zawm aout, 2
endin

; Effects instrument.  Always-on and score activated.
instr 4
    a2 zar 1      ; Read autotune
    a3 zar 2      ; Read midi harmonizer
    denorm a2, a3 ; Prevent CPU spikes on Intel processors.
     
    aMix = a3 + a2
    outch 1, aMix, 2, aMix

    zacl 0, 2  ; Clear audio channels to prevent audio build-up.
endin
</CsInstruments>
<CsScore>

f3 0 8 -2  0 2 4 5 7 9 11 12 ; major mode
f4 0 8 -2  0 2 3 5 7 8 10 12 ; minor mode
f5 0 16384 20 1

i1 0 86400
i4 0 3600 ; Activate the Reverb/Flanger always-on instrument.
e

</CsScore>
</CsoundSynthesizer> 