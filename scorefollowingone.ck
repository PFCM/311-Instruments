Moog s => dac;//LPF l => dac;
//.5 => s.gain;
//.0 => s.stringDetune;
//s.set(100::ms, 100::ms, .6, 100::ms);

Wii wii;
wii.init(5600);

SndBuf cymbal => dac;
"data/MXR Kick.wav" => cymbal.read;
cymbal.samples() => cymbal.pos;
//2 => cymbal.gain;
SndBuf snare => dac;
"data/RapII Snare1.wav" => snare.read;
snare.samples() => snare.pos;
//2 => snare.gain;

s.noteOff(1);

spork ~controlChange();
spork ~drum();

// approximately
[48,52,55,60,59,55,62,60,62,60,59,57,55,57,53,52,
48,52,55,60,59,55,62,60,62,60,59,57,55,57,53,52,
55,59,60,59,60,59,59,60,59,57,59,55,62,64,65,64,
62,64,60,67,68,69,65,64,62,60,59,60] @=> int notes[];
-1 => int index;
while (true)
{                
    wii.buttonEvent => now;
    if (wii.buttonEvent.state == 1) 
    {
        (index+1)%notes.cap() => index;
        Std.mtof(notes[index])*2 => s.freq;
        s.noteOn(1);
        <<<"note " + index>>>;
    } else if (wii.buttonEvent.state == 0)
    {
        s.noteOff(1);
    }
}

fun void controlChange()
{
    while (true)
    {
        ((wii.orientation[0]/150)+0.3)/3 =>  float detune;
        if (detune < 0.0) 0.0 => s.vibratoGain; 
        else if (detune > .8) .8 => s.vibratoGain;
        else detune => s.vibratoGain;
        (wii.orientation[1]/150 +1) *10 => s.vibratoFreq;
        //wii.accels[0]*10 => l.freq;;
        
        10::ms => now;
    }
}

fun void drum() 
{
    while (true)
    {
        wii.accelEvent => now;
        if (wii.accelEvent.axis == 2)
            0 => cymbal.pos;
        else if (wii.accelEvent.axis == 1)
            0 => snare.pos;
    }
    
}
