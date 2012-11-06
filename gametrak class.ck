// GameTrak controller class

public class GameTrak {
    
    Hid hi;
    HidMsg hidmsg;
    
    // MIDI Msg Setup
    MidiOut mout;
    MidiMsg msg;
    
    // Global variables
    float right[3];
    float left[3];
    float lastRight[3];
    float lastLeft[3];
    int buttonState;
    Event axis, button;
    
    
    fun void init(int p) 
    {
        // HID GameTrak input
        if(!hi.openJoystick(p))
        {
            <<<"Error - could not open GameTrak on port ", p>>>;
            me.exit();
        }
        <<<"GameTrak " + hi.name() + "ready">>>;
        
        10::ms => now;
        spork ~ update();
    }
    
    fun void initMidi(int p) 
    {
        // Set MIDI output port
        if (!mout.open(p)) 
        {
            <<<"Error - could not open MIDI port for output">>>;
            me.exit();
        }
        <<<"MIDI Port opened: ", p>>>;
        
        10::ms => now;
        spork ~ MIDIRelay();
        spork ~ MIDIButtonRelay();
    }
    
    fun void MIDIRelay() 
    {
        int scaledR[3];
        int scaledL[3];
        while (true) 
        {
            10::ms => now; // control rate of output stream
            
            // Right
            for (0 => int i; i < right.cap(); i++)
            {
                (((right[i] + 1.0)/2.0) *127.0) $ int => scaledR[i];
                176 => msg.data1; // control change on channel 0
                i => msg.data2;
                scaledR[i] => msg.data3;
                mout.send(msg);
            } 
            for (0 => int i; i < left.cap(); i++)
            {
                (((left[i] + 1.0)/2.0) *127.0) $ int => scaledL[i];
                177 => msg.data1; // control change on channel 1
                i => msg.data2;
                scaledL[i] => msg.data3;
                mout.send(msg);
            }
        }
    }
    
    fun void MIDIButtonRelay()
    {
        while (true)
        {
            button => now;
            
            // Send note On Event
            144 => msg.data1;
            0 => msg.data2;
            buttonState => msg.data3;
            mout.send(msg);
        }
    }
    
    fun void update() 
    {
        while (true)
        {
            hi => now;
            while(hi.recv(hidmsg))
            {
                if (hidmsg.isAxisMotion())
                {
                    axis.broadcast();
                    // LEFT
                    if (hidmsg.which ==  0)
                    {
                        left[0] => lastLeft[0];
                        hidmsg.axisPosition => left[0];
                    }
                    else if (hidmsg.which ==  1)
                    {
                        left[1] => lastLeft[1];
                        hidmsg.axisPosition => left[1];
                    }
                    else if (hidmsg.which ==  2)
                    {
                        left[2] => lastLeft[2];
                        hidmsg.axisPosition => left[2];
                    }
                    // RIGHT
                    else if (hidmsg.which ==  3)
                    {
                        right[0] => lastRight[0];
                        hidmsg.axisPosition => right[0];
                    }
                    else if (hidmsg.which ==  4)
                    {
                        right[1] => lastRight[1];
                        hidmsg.axisPosition => right[1];
                    }
                    else if (hidmsg.which ==  5)
                    {
                        right[2] => lastRight[2];
                        hidmsg.axisPosition => right[2];
                    }
                }
                else if (hidmsg.isButtonDown())
                {
                    1 => buttonState;
                    button.broadcast();
                }
                else if (hidmsg.isButtonUp())
                {
                    0 => buttonState;
                    button.broadcast();
                }
            }
        }
    }
    
    
}                                                           