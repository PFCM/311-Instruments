Wii wii;
wii.init(5600);

LPD8 lpd8;
lpd8.init(1);

2000 => int GESTURE_LENGTH;

SndBuf s => blackhole;
LiSa l => dac;


["data/HailClick.aif", "data/MXR Crash.wav",
"data/convolvedpianochord.aif", "data/sbs+24aifPVAR.aif",
"data/Thunder1.aif", "data/bell.wav", "data/28353__petaj__old-telephone-ring.wav"] @=> string files[];

// SndBuf variables
//s.samples() => s.pos;

// Lisa
0 => int vIndex;
8 => l.maxVoices;
8 => int MAX_VOICES;
int voiceStates[MAX_VOICES];

// record files into LiSa
<<<"Constructing LiSa buffer">>>;
10::minute => l.duration;
//1 => l.record;
0 => int bufferLength; // serves as our offset into l's buffer
// TODO - loops on individual samples only

/*for (0 => int i; i < files.cap()-1; i++) {
files[i] => s.read;
s.samples() +=> bufferLength;
//bufferLength::samp => l.duration;
<<<"Recording: ", files[i], s.samples(), bufferLength>>>;
for (0 => int j; j < s.samples(); j++) {
    if (j::samp < l.duration())
        (s.valueAt(j), (bufferLength+j)::samp) => l.valueAt;
}
}*/

files[6] => s.read;
s.samples()::samp => l.duration;
s.samples() +=> bufferLength;
for (0 => int i; i < s.samples(); i++) {
    (s.valueAt(i), i::samp) => l.valueAt;
}
<<<"Recorded">>>;
for (0 => int i; i < MAX_VOICES; i++)
{
    Math.random()*(bufferLength-44100) => int loopStart;
    (i, (loopStart + Math.randomf()*500 + 60)::samp) => l.loopEnd;
    (i, loopStart::samp) => l.loopStart;
    (i, 100::ms) =>l.rampDown;
}


500::ms => dur loopDelay;

float currentGesture[3][GESTURE_LENGTH];
float loopOne[3][GESTURE_LENGTH];
float loopTwo[3][GESTURE_LENGTH];
int loopOneCap;
int loopOneState;
int loopTwoCap;
int loopTwoState;
0 => int loopTwoVoice;

int aState, bState;
int gCap;
1 => int direction;

1 => int LOOP;
0 => int ONE_SHOT;
ONE_SHOT => int mode;
0 => int one_state;


spork ~buttonListener();
spork ~runKontrols();
spork ~runPads();
while (true)
{
    if (wii.orientation[1] < -70) 1 => direction;
    if (wii.orientation[1] > 70) -1 => direction;
    if (bState == 1) makeNoise(vIndex);
    15::ms => now;
}

fun void buttonListener()
{
    while(true)
    {
        wii.buttonEvent => now;
        if (wii.buttonEvent.which == "b") {
            if (wii.buttonEvent.state == 1) {
                1 => bState;
                <<<"B Down">>>;
            }
            else {
                0 => bState;
                <<<"B Up">>>;
            }
        }
        else if (wii.buttonEvent.which == "a") {
            if (wii.buttonEvent.state == 1)
            {
                1 => aState;
                spork ~record();
            }
            else
                0 => aState;
        }
        else if (wii.buttonEvent.which == "one") {
            if (wii.buttonEvent.state == 1 && one_state == 0) {
                1 => one_state;
                if (mode == LOOP) {
                    <<<"current mode - ONE SHOT">>>;
                    ONE_SHOT => mode;
                    for (0 => int i; i < MAX_VOICES; i++)
                    {
                        (i, 100::ms) => l.rampDown;
                    }
                }
                else if (mode == ONE_SHOT) {
                    <<<"current mode - LOOP">>>;
                    LOOP => mode;
                }
            }
            else {
                0 => one_state;
            }
        }
        else if (wii.buttonEvent.which == "two")
        {
            if (loopTwoState == 0 && wii.buttonEvent.state == 1)
            {
                <<<"Start Loop 2">>>;
                copyGesture(loopTwo, direction);
                gCap => loopTwoCap;
                1 => loopTwoState;
                spork ~loopGestureTwo(loopTwo, loopTwoCap, loopDelay, direction, loopTwoVoice);
            }
            else if (loopTwoState == 1 && wii.buttonEvent.state == 1)
            {
                <<<"End Loop 2">>>;
                0 => loopTwoState; 
            }
        }
        else if (wii.buttonEvent.which == "left")
        {
            if (vIndex > 0 && wii.buttonEvent.state == 1) {
                vIndex--;
                <<<"Currently in loop: ", vIndex+1>>>;
            }
        }
        else if (wii.buttonEvent.which == "right")
        {
            if (vIndex < MAX_VOICES-1 && wii.buttonEvent.state == 1) {
                vIndex++;
                <<<"Currently in loop: ", vIndex+1>>>;
            }
        }
    }
}

fun void record() {
    int index;
    int pos;
    int loopWidth;
    <<<"RECORDING, loop ", vIndex+1>>>;
    (vIndex, 100::ms) => l.rampUp;
    //(vIndex, (loopWidth/10)::samp) => l.rampDown;
    while (aState == 1 && index < GESTURE_LENGTH) {
        wii.accels[0] => currentGesture[0][index];
        wii.accels[1] => currentGesture[1][index];
        wii.accels[2] => currentGesture[2][index];
        makeNoise(vIndex);
        //  (vIndex, (Math.pow(wii.accels[0]/350, 2))*direction) => l.rate;
        //  Std.fabs((wii.accels[1]/250)*bufferLength ) $ int => pos;
        //  Std.fabs(Std.fabs(wii.accels[2]*50) )$ int => loopWidth;
        
        //0::ms => l.playPos;
        // (vIndex, pos::samp) => l.loopStart;
        // (vIndex, (pos+loopWidth)::samp) => l.loopEnd;
        if (index%100 == 0)
            <<<l.rate(vIndex), l.loopStart(vIndex), l.loopEnd(vIndex)>>>;
        index++;
        5::ms => now;
    }
    l.loop(vIndex, 1);
    index => gCap;
    <<<"END RECORD  ", l.loopStart(vIndex), l.loopEnd(vIndex)>>>;
}

fun void makeNoise(int voice) {
    // (voice, 1::ms) => l.rampUp;
    //(voice, (Math.pow(wii.accels[0]/350, 2))*direction) => l.rate;
    l.loopStart(voice) => dur pos;
    (Std.fabs((wii.accels[1]/300-1)*bufferLength ) $ int )::samp => dur apos;
    (Std.fabs(wii.accels[2]*50 )$ int )::samp => dur loopWidth;
    
    if (apos > pos || apos < (bufferLength/2)::samp) apos => pos;
    
    //0::ms => l.playPos;
    (voice, (pos > 0::samp)? pos : 0::samp) => l.loopStart;
    (voice, ((pos+loopWidth) <= l.duration())? (pos+loopWidth) : l.duration()) => l.loopEnd;
    
    //(vIndex, 100::ms) => l.rampUp;
    //(vIndex, (loopWidth/10)::samp) => l.rampDown;
}
fun void makeNoise(int voice, float accels0, float accels1, float accels2) {
    // (voice, 1::ms) => l.rampUp;
    //(voice, (Math.pow(wii.accels[0]/350, 2))*direction) => l.rate;
    Std.fabs((accels1/300-1)*bufferLength ) $ int => int pos;
    Std.fabs(accels2*50 )$ int => int loopWidth;
    
    //0::ms => l.playPos;
    (voice, (pos > 0)? pos::samp : 0::samp) => l.loopStart;
    (voice, ((pos+loopWidth)::samp <= l.duration())? (pos+loopWidth)::samp : l.duration()) => l.loopEnd;
    
    //(vIndex, 100::ms) => l.rampUp;
    //(vIndex, (loopWidth/10)::samp) => l.rampDown;
}

fun void playGesture() {
    <<<"PLAY">>>;
    int index;
    direction => int dir; //don't want scrubbing
    if (dir == 1)
        0 => index;
    else if (dir == -1)
        gCap-1 => index;
    while (index < gCap && index > -1 && bState == 1)
    {
        // make sound
        index+dir => index;
        5::ms => now;
    }
}

fun void loopGestureOne(float gesture[][], int cap, dur delay, int state)
{
    TriOsc tri => LPF low => ADSR env  => dac;
    env.set(100::ms, 100::ms, .5, 100::ms);
    while (loopOneState == 1)
    {
        env.keyOn(1);
        for (int i; i < cap; i++)
        {
            (gesture[2][i]-gesture[0][i])*4 => tri.freq;
            (gesture[1][i]/256)-1.0 => tri.width;
            //(gesture[0][i]+gesture[1][i]+gesture[2][i])/3 => nLow.freq;
            5::ms => now;
        }
        env.keyOff(1);
        delay => now;
    }
}

fun void loopGestureTwo(float gesture[][], int cap, dur delay, int state, int voice)
{
    while (loopTwoState == 1)
    {
        
        // (voice, 100::ms) => l.rampUp;
        for (int i; i < cap; i++)
        {
            makeNoise(voice, gesture[0][i], gesture[1][i], gesture[2][i]);
            5::ms => now;
        }
    }
}

fun void copyGesture(float to[][], int dir)
{
    if (dir > 0)
    {
        for (0 => int i; i < gCap; i++)
        {
            currentGesture[0][i] => to[0][i];
            currentGesture[1][i] => to[1][i];
            currentGesture[2][i] => to[2][i];
        }
    }
    else if (dir < 0)
    {
        0 => int bottom;
        for (gCap-1 => int i; i >= 0; i--)
        {
            currentGesture[0][i] => to[0][bottom];
            currentGesture[1][i] => to[1][bottom];
            currentGesture[2][i] => to[2][bottom];
            bottom++;
        }
    }
}

fun void runKontrols() 
{
    while (true)
    {
        /*(0, k.sliders[0]/127.0) => l.voiceGain;
        (1, k.sliders[1]/127.0) => l.voiceGain;
        (2, k.sliders[2]/127.0) => l.voiceGain;
        (3, k.sliders[3]/127.0) => l.voiceGain;
        (4, k.sliders[4]/127.0) => l.voiceGain;
        (5, k.sliders[5]/127.0) => l.voiceGain;
        (6, k.sliders[6]/127.0) => l.voiceGain;
        (7, k.sliders[7]/127.0) => l.voiceGain;
        k.sliders[8]/127.0 => dac.gain;
        
        (0, (k.knobs[0]/127.0 - 0.5)*3) => l.rate;
        (1, (k.knobs[1]/127.0 - 0.5)*3) => l.rate;
        (2, (k.knobs[2]/127.0 - 0.5)*3) => l.rate;
        (3, (k.knobs[3]/127.0 - 0.5)*3) => l.rate;
        (4, (k.knobs[4]/127.0 - 0.5)*3) => l.rate;
        (5, (k.knobs[5]/127.0 - 0.5)*3) => l.rate;
        (6, (k.knobs[6]/127.0 - 0.5)*3) => l.rate;
        (7, (k.knobs[7]/127.0 - 0.5)*3) => l.rate;*/
        
        
        
        // k.knobs[8]/127.0 * 4 => pitch.shift;
        
        
        for (0 => int i; i < MAX_VOICES; i++)
        {
            (i, (lpd8.knob[i]/127.0 - 0.5)*3) => l.rate;
        }
        
        10::ms => now;
    }
}

fun void runPads() 
{
    while (true)
    {
        lpd8.padHit => now;
        if (lpd8.padHit.index == -1) break;
        if (mode == ONE_SHOT)
        {
            (lpd8.padHit.index, (500-(lpd8.knob[lpd8.padHit.index]/127.0)*100)::ms) => l.rampUp;
            (lpd8.padHit.index, 0) => l.loop;
            <<<"hit on pad ", lpd8.padHit.index+1>>>;
            
        }
        else if (mode == LOOP) {
            if (voiceStates[lpd8.padHit.index] > 0) // if it is on
            {
                (lpd8.padHit.index, 100::ms) => l.rampDown;
                0 => voiceStates[lpd8.padHit.index];
                <<<"voice ", lpd8.padHit.index+1, " off.">>>;
            } 
            else 
            {
                1 => voiceStates[lpd8.padHit.index];
                (lpd8.padHit.index, 1) => l.loop;
                (lpd8.padHit.index, 100::ms) => l.rampUp;
                //(lpd8.padHit.index, (lpd8.pad[lpd8.padHit.index]/127.0)) => l.voiceGain;    
                <<<"voice ", lpd8.padHit.index+1, " on.">>>;   
            }
        }
    }
}
