public class LPD8 
{
    MidiIn min;
    MidiMsg msg;
    
    class PadEvent extends Event 
    {
        int index;
    }
    
    PadEvent padHit;
    int pad[8];
    int knob[8];
    
    fun void init(int p)
    {
        if (!min.open(p))
        {
            <<<"Could not open LPD8 on MIDI port ", p>>>;
        }
        spork ~ poller();
    }
    
    fun void poller()
    {
        while (true) 
        {
            min => now;
            while (min.recv(msg))
            {
                if (msg.data1 == 144)
                {// note on, current channel
                    msg.data3 => pad[msg.data2-36];
                    msg.data2-36 => padHit.index;
                    // put into correct place
                    padHit.broadcast(); // tell everyone
                }
                if (msg.data1 == 128)
                {// note off channel 1
                    0 => pad[msg.data2-36];
                    -1 => padHit.index;
                    padHit.broadcast;
                }
                if (msg.data1 == 176)
                {// cc channel 1
                    msg.data3 => knob[msg.data2-1];
                }
            }
        }
    }
}