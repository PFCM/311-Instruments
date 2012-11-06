GameTrak gametrak;// gametrak

gametrak.init(0);

// global variables
float left[3];
float right[3];
int buttonState, gate;
int numLoops, wayUp;
Event lightningEvent;
0 => int counter; 
0 => int trigger;
9 => int freq;

// delay lines
DelayL delay1 => DelayL delay2 => JCRev r;
delay1 => Gain delayFB => LPF delayLP => delay1;
//delay2 => delayFB => delay2;

// set delay and reverb
1::second => delay1.max => delay2.max;
.666::second => delay1.delay;
.2::second => delay2.delay;
.4 => delayFB.gain;
0.01 => r.mix;
0.01 => delayLP.Q;
500 => delayLP.freq;

// pitcshifter 
r => PitShift p => dac;
r => dac;
1 => p.shift;
1 => p.mix;
2.0 => r.gain;

// loop buffers
SndBuf loops[6]; Pan2 loopPan[loops.cap()];
"/Users/pfcmathews/Documents/ChucK/311/data/HailClatter.aif" => loops[3].read;
"/Users/pfcmathews/Documents/ChucK/311/data/HailClatterShort.aif" => loops[5].read;
"/Users/pfcmathews/Documents/ChucK/311/data/HailClatterShortest.aif" => loops[0].read;
"/Users/pfcmathews/Documents/ChucK/311/data/HailClatter2.aif" => loops[1].read;
"/Users/pfcmathews/Documents/ChucK/311/data/HailClick.aif" => loops[2].read;
"/Users/pfcmathews/Documents/ChucK/311/data/HailClick2.aif" => loops[4].read;

// background sound
SndBuf background => LPF l => HPF h => r;
"/Users/pfcmathews/Documents/ChucK/311/data/BGHail.aif" => background.read;
200 => l.freq;
1 => background.loop;

// thunder clap
SndBuf lightning => Pan2 lightningPan => dac;
"/Users/pfcmathews/Documents/ChucK/311/data/Thunder2.aif" => lightning.read;
lightning.samples() => lightning.pos;

// set up loop buffers
for (0 => int i; i < loops.cap(); i++) {
    loops[i] => loopPan[i] => delay1;
    loops[i].samples() => loops[i].pos;
    1.2 => loops[i].gain;
    -1.0 + (2.0/6.0 * i) => loopPan[i].pan;
}

// spork pollers
spork ~ axes(gametrak);
spork ~ button(gametrak);
spork ~ lightningPoller();

while (true) {
    // loop loops
    for (0 => int i; i < numLoops; i++) {
        if (counter % (i+freq) == 0 && loops[i].pos() >= loops[i].samples())
            0 => loops[i].pos; 
    }
    
    // keep thunder relative
    (numLoops/(loops.cap()$float))*1.5 + 1 => lightning.gain;
    
    // exit gracefully
    if (numLoops < 0) {
        me.exit();
    }
    counter++;
    200::ms => now;
}

fun void axes(GameTrak gt) {
    now => time lastRand; // for less frequent randomness
    while (true) {
        gt.axis => now;
        gt.left @=> left; // get left and right
        gt.right @=> right;
        // scale and use values
        ((left[0]+1)/2.0) * 2000 + 20 => l.freq;
        ((left[1]+1)/2.0)* 1000 + 20 => h.freq;
        (1-((right[2]+1)/2.0)) *3 + 1 => p.shift;
        ((((left[2]+1)/2.0) * 14)+1) $ int => freq;
        ((right[0]+1)/2.0) => p.gain;
        // random pitch variation
        if (now-lastRand > Math.rand2(300,500)::ms) {
            Math.rand2f((right[1]+1)/2.0,((right[1]+1)/2.0)+2)  + p.shift() => p.shift;
            now => lastRand;
        }
        // thunder triger
        if ((gt.right[2]-gt.lastRight[2]) < -0.02) {
            ((gt.right[0]+1)/2.0)*-1 => lightningPan.pan;
            lightningEvent.broadcast();
        }
        
        if  ((gt.left[2]-gt.lastLeft[2]) < -0.02) {
            1-((gt.left[0]+1)/2.0) => lightningPan.pan;
            lightningEvent.broadcast();
        }
    }
}

fun void button(GameTrak gt) {
    while (true) {
        gt.button => now;
        // when button is used
        gt.buttonState => buttonState;
        
        if (buttonState == 1 && gate == 0) {
            if (numLoops < loops.cap() && wayUp == 0) {
                
                numLoops++;
            }
            else {
                numLoops--;
                1 => wayUp;
            }
            <<<numLoops>>>;
            1 => gate;
        } else if (buttonState == 0 && gate == 1) {
            0 => gate;
        }
        
    }
}

fun void lightningPoller() {
    while(true) {
        lightningEvent => now;
        0 => lightning.pos;
    }
}