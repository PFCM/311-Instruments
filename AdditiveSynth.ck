private class PitchDelay extends Chugen 
{
    0.5 => float wetdry;
    0.2 => float fb;
    500::ms => dur delay_length;
    (delay_length/1::samp) $int => int delay_samp;
    2::second => dur DELAY_MAX;
    (2::second/1::samp) $ int => int DELAY_MAX_SAMP;
    DELAY_MAX_SAMP/delay_samp => int step;
    float delay_buf[DELAY_MAX_SAMP*2]; // buffer, twice the size of the delay max
    0 => int index_in; // where we put new samples
    step => int index_out; // where we get delayed samples from, should always be step higher than index_in
    
    
    
    // does work, called for every sample
    fun float tick(float in)
    {
        delay_buf[index_out] => float delayed;
        step +=> index_out;
        
        delayed*fb + in => delay_buf[index_in];
        step +=> index_in;
        
        // rotate through buffer if necessary
        if (index_out >= delay_samp)
            0 => index_out;
        if (index_in >= delay_samp)
            0 => index_in;
        
        return delayed*wetdry+in*(1-wetdry);
    }
    
    // setters and getters, overloaded in chuck fashion
    fun float mix(float in)
    {
        in => wetdry;
        return wetdry;
    }
    fun float mix()
    {
        return wetdry;
    }
    fun dur delay(dur in)
    {
        if (in <= DELAY_MAX && in > 0::samp) in => delay_length;
        else 
        {
            //DELAY_MAX => delay_length;
            <<<"AnalogDelay error, attempted to set bad delay time">>>;
        }
        (delay_length/1::samp) $ int => delay_samp;
        DELAY_MAX_SAMP/delay_samp => step;
        return delay_length;
    }
    fun dur delay()
    {
        return delay_length;
    }
    fun dur delayMax()
    {
        return DELAY_MAX;
    }
    fun float feedback(float in)
    {
        in => fb;
        return fb;
    }
    fun float feedback()
    {
        return fb;
    }
}

SinOsc s[8];
PitchDelay a => dac;
[2411.0, 2293.0, 1442.0, 608.0, 484.0, 355.0, 236.0, 118.0]  @=>  float freqs_a[];
[1281.0, 958.0, 764.0, 592.0, 419.0, 247.0, 118.0, 75.0] @=> float freqs_b[];
[1442.0, 753.0, 581.0, 409.0, 279.0, 226.0, 107.0, 64.0] @=> float freqs_c[];

float interps[8];
for (0 => int i; i < 8; i++)
{
    s[i] => a;
    0 => s[i].gain;
    // nb - set to a meaningful spectrum
    freqs_a[i] => s[i].freq;
}
Kontrol k; 
k.init(0);
2::second => a.delay;
.6 => a.feedback;
0 => int lastState;
while (true)
{
    if (k.knobs[8] > 0)
        ((k.knobs[8]/127.0) *2)::second => a.delay;
    k.sliders[8]/127.0 => a.feedback;
    for (0 => int i; i < 8; i++)
    {
        (k.sliders[i]/127.0)/8.0 => s[i].gain;
        if (k.rec == 0)
            (k.knobs[i]/127.0) => interps[i];
        else
            (k.knobs[0]/127.0) => interps[i];
        
        //do interpolation
        if (interps[i] <= 0.5)
            freqs_a[i] + (interps[i]*2)*(freqs_b[i]-freqs_a[i]) => s[i].freq;
        else 
            freqs_b[i] + (interps[i]*2-1)*(freqs_c[i]-freqs_b[i]) => s[i].freq;
    }
    10::ms => now;
} 