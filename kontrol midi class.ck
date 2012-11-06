public class Kontrol{
    MidiIn min;
    MidiMsg msg;
    
    int sliders[9];
    int knobs[9];
    int upperButtons[9];
    int lowerButtons[9];
    int rewind,play,fastfoward,loop,stop,rec;
    
    fun void init(int p)
    {
        if (!min.open(p)){
            <<<"Error, could not open port ", p>>>;
        }
        spork ~ poller();
    }
    
    fun void poller()
    {
        while (true) {
            min => now;
            while (min.recv(msg))
            {
                if (msg.data1 == 176) // from Kontrol
                {
                    if (msg.data2 > 13 && msg.data2 < 23)
                    { // all knobs
                        msg.data3 => knobs[msg.data2-14];
                    }
                    else if (msg.data2 >= 23 && msg.data2 <=31)
                    { // upperButtons
                        msg.data3 => upperButtons[msg.data2-23];
                    }
                    else if (msg.data2 >= 33 && msg.data2 <=41)
                    { // lowerButtons
                        msg.data3 => lowerButtons[msg.data2-33];
                    }
                    // Sliders
                    else if (msg.data2 > 1 && msg.data2 < 7)
                    {// 1-5
                        msg.data3 => sliders[msg.data2-2];
                    }
                    else if (msg.data2 == 8 || msg.data2 == 9)
                    {// 6,7
                        msg.data3 => sliders[msg.data2-3];
                    }
                    else if (msg.data2 == 12 || msg.data2 == 13)
                    {// 8,9
                        msg.data3 => sliders[msg.data2-5];
                    }
                    
                    // other buttons
                    else if (msg.data2 == 47)
                        msg.data3 => rewind;
                    else if (msg.data2 == 45)
                        msg.data3 => play;
                    else if (msg.data2 == 48)
                        msg.data3 => fastfoward;
                    else if (msg.data2 == 49)
                        msg.data3 => loop;
                    else if (msg.data2 == 46)
                        msg.data3 => stop;
                    else if (msg.data2 == 44)
                        msg.data3 => rec;
                }
            }
        }
    }
    
}