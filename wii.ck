public class Wii {
    0 =>  int BUTTON_A;
    1 =>  int BUTTON_B;
    2 =>  int BUTTON_ONE;
    3 =>  int BUTTON_TWO;
    4 =>  int BUTTON_LEFT;
    5 =>  int BUTTON_RIGHT;
    6 =>  int BUTTON_UP;
    7 =>  int BUTTON_DOWN;
    
    8 =>  int NUM_BUTTONS;
    
    public class ButtonEvent extends Event
    {
        string which;
        int state;
    }
    public class AccelEvent extends Event
    {
        int val;
        int axis;
    }
    OscRecv recv;
    
    recv.event("/wii/acc , fff") @=> OscEvent acc;
    recv.event("/wii/orientation, ff") @=> OscEvent ori;
    recv.event("/wii/button/b, i") @=> OscEvent b;
    recv.event("/wii/button/a, i") @=> OscEvent a;
    recv.event("/wii/button/one, i") @=> OscEvent one;
    recv.event("/wii/button/two, i") @=> OscEvent two;
    recv.event("/wii/button/left, i") @=> OscEvent left;
    recv.event("/wii/button/right, i") @=> OscEvent right;
    
    
    ButtonEvent buttonEvent;
    AccelEvent accelEvent;
    
    float accels[3];
    float lastAccels[3];
    float orientation[2];
    float lastOrientation[2];
    int buttons[NUM_BUTTONS];
    
    int count,gate2,gate1;
    
    fun void init(int port) 
    {
        
        port => recv.port;
        recv.listen();
        spork ~runAcc();
        //spork ~runOri();
        spork ~runButton();
        spork ~runButtonA();
        spork ~runButtonOne();
        spork ~runButtonTwo();
        spork ~runButtonLeft();
        spork ~runButtonRight();
    }
    
    fun void runAcc() {
        while (true)
        {
            acc => now;
            if (acc.nextMsg() != 0)
            {
                for (0 => int i; i < accels.cap(); i++)
                {
                    accels[i] => lastAccels[i];
                    acc.getFloat() => accels[i];
                    (accels[i]+lastAccels[i])/2 => accels[i];
                }
                if (accels[2]-lastAccels[2] > 30 && gate2 == 0 && lastAccels[2]>0)
                {
                    1 => gate2;
                    2 => accelEvent.axis;
                    accelEvent.broadcast();
                }
                if (accels[2]-lastAccels[2] < 30 && gate2 == 1)
                {
                    0 => gate2;
                }
                if (accels[1]-lastAccels[1] > 30 && gate1 == 0 && lastAccels[1]>0)
                {
                    1 => gate1;
                    1 => accelEvent.axis;
                    accelEvent.broadcast();
                }
                if (accels[1]-lastAccels[1] < 30 && gate1 == 1)
                {
                    0 => gate1;
                }
                10::ms => now;
            }
        }
    }
    
    fun void runOri() {
        while (true)
        {
            ori => now;
            if (ori.nextMsg() != 0)
            {
                orientation[0] => lastOrientation[0];
                orientation[1] => lastOrientation[1];
                ori.getFloat() => orientation[0];
                ori.getFloat() => orientation[1];
                
                (orientation[0]+lastOrientation[0]) /2 => orientation[0];
                (orientation[1]+lastOrientation[1]) /2 => orientation[1];
            }
        }
    }
    
    fun void runButton() {
      while (true)
      {
          b => now;
          if (b.nextMsg() != 0)
          {
              b.getInt() => buttonEvent.state => buttons[BUTTON_B];
              "b" => buttonEvent.which;
              buttonEvent.broadcast();
          }
      }  
    } 
    fun void runButtonA() {
        while(true)
        {
            a => now;
            if (a.nextMsg() != 0)
            {
                a.getInt() => buttonEvent.state => buttons[BUTTON_A];
                "a" => buttonEvent.which;
                buttonEvent.broadcast();
            }
        }
    }
    
    fun void runButtonOne() {
        while (true)
        {
            one => now;
            if (one.nextMsg() != 0)
            {
                one.getInt() => buttonEvent.state => buttons[BUTTON_ONE];
                "one" => buttonEvent.which;
                buttonEvent.broadcast();
            }
        }
    }
    fun void runButtonTwo() {
        while (true)
        {
            two => now;
            if (two.nextMsg() != 0)
            {
                two.getInt() => buttonEvent.state => buttons[BUTTON_TWO];
                "two" => buttonEvent.which;
                buttonEvent.broadcast();
            }
        }
    }
    fun void runButtonLeft() {
        while (true)
        {
            left => now;
            if (left.nextMsg() != 0)
            {
                left.getInt() => buttonEvent.state => buttons[BUTTON_LEFT];
                "left" => buttonEvent.which;
                buttonEvent.broadcast();
            }
        }
    }
    fun void runButtonRight() {
        while (true)
        {
            right => now;
            if (right.nextMsg() != 0)
            {
                right.getInt() => buttonEvent.state => buttons[BUTTON_RIGHT];
                "right" => buttonEvent.which;
                buttonEvent.broadcast();
            }
        }
    }
}