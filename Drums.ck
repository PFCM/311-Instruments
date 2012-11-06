"/Users/pfcmathews/Desktop/Drums/[KB6]_Casio_Rapman/HH16.WAV" => string hatfile2;
"/Users/pfcmathews/Desktop/Drums/[KB6]_Technics_U90/Hihat Closed.wav" => string hatfile;
"/Users/pfcmathews/Desktop/Drums/[KB6]_MXR_185/MXR Kick.wav" => string kickfile;
"/Users/pfcmathews/Desktop/Drums/[KB6]_Electro-Harmonix_DRM-16/EH16 CLAP3  .wav" => string snarefile;
SndBuf kick => dac;
SndBuf snare => dac;
SndBuf hat => dac;
SndBuf hat2 => dac;
hatfile2 => hat2.read;
hatfile => hat.read;
snarefile => snare.read;
snare.samples() => snare.pos;
kickfile => kick.read;
15 => hat.gain;
8 => kick.gain;
12 => snare.gain;
.8 => snare.rate;
0.6 => kick.rate;
.75::second => dur beat;
0 => int count;

Noise n => HPF l => LPF l2 => dac;
400=>l.freq;
800 => l2.freq;

fun void hat2play(dur lag) 
{
    lag => now;
    0 => hat2.pos;
}

fun void noiseDuck(float gain, float ratio) 
{
    gain => float initial;
    initial*ratio => float target;
    (initial-target)/10.0 => float step;
    
    for (0 => int i; i < 10; i++) 
    {
        step -=> initial;
        initial => n.gain;
        10::ms => now;
    }
    for (0 => int i; i < 10; i++) 
    {
        step +=> target;
        target => n.gain;
        20::ms => now;
    }
    gain => n.gain;
}

while (true) 
{
    if (count % 16 == 0) {
        0 => kick.pos;
        spork ~ noiseDuck(1, 0.1);
    }
    if (count % 21 == 0) {
        0 => kick.pos;
        spork ~ noiseDuck(1, 0.1);
    }
    if (count % 16 == 8) {
        0 => snare.pos;
        spork ~ noiseDuck(1, 0.5);
    }
    
    if (count % 7 == 0 || count % 8 == 4 || count > 115) 
    {
        0 => hat.pos;
        spork ~ hat2play(Math.rand2(10,100)::ms);
        Math.rand2f(0.5,3) => hat2.rate;
    }
    
    count++;
    if (count > (4*32-1))
        0 => count;
    beat/8 => now;
}