#include <TimerOne.h>

// Choose which 2 pins you will use for output.
// Can be any valid output pins.
int clockPin = 3;
int dataPin = 2;
int lightCount = 20;

byte  SendMode=0;   // Used in interrupt 0=start,1=header,2=data,3=data done
byte  BitCount=0;   // Used in interrupt
byte  LedIndex=0;   // Used in interrupt - Which LED we are sending.
byte  BlankCounter=0;  //Used in interrupt.
unsigned int BitMask;   //Used in interrupt.

//Holds the 15 bit RGB values for each LED.
//You'll need one for each LED, we're using 10 LEDs here.
//Note you've only got limited memory on the Arduino, so you can only control 
//Several hundred LEDs on a normal arduino. Double that on a Duemilanove.

unsigned int Display[20];  

void setup() {
  byte Counter;

  pinMode(clockPin, OUTPUT);
  pinMode(dataPin, OUTPUT);

  // Turn all LEDs off.
  for(Counter=0;Counter < lightCount; Counter++)
    Display[Counter]=Color(Counter,0,31-Counter);
  
  show();

  Timer1.initialize(25);           // initialize timer1, 25 microseconds refresh rate.
  Timer1.attachInterrupt(LedOut);  // attaches callback() as a timer overflow interrupt

}


//Interrupt routine.
//Frequency was set in setup(). Called once for every bit of data sent
//In your code, set global Sendmode to 0 to re-send the data to the pixels
//Otherwise it will just send clocks.
void LedOut()
{
  switch(SendMode)
  {
    case 3:            //Done..just send clocks with zero data
      digitalWrite(dataPin, 0);
      digitalWrite(clockPin, HIGH);
      digitalWrite(clockPin, LOW);
      break;
    case 2:               //Sending Data
      if (BitCount==0)    //First bit is always 1
        {  digitalWrite(dataPin, 1);
            BitMask=0x8000;//Init bit mask
        }
      else if(BitMask & Display[LedIndex])  //If not the first bit then output the next bits (Starting with MSB bit 15 down.)
        digitalWrite(dataPin, 1);
      else
        digitalWrite(dataPin, 0);
      
      BitMask>>=1;
      BitCount++;
      
      if(BitCount == 16)    //Last bit?
      {
        LedIndex++;        //Move to next LED
        if (LedIndex < lightCount) //Still more leds to go or are we done?
        {
          BitCount=0;      //Start from the fist bit of the next LED             
        }
        else
          SendMode=3;  //No more LEDs to go, we are done!
      }
      // Clock out data.
      digitalWrite(clockPin, HIGH);
      digitalWrite(clockPin, LOW);
      break;      
    case 1:            //Header
        if (BitCount < 32)              
        {
        digitalWrite(dataPin, 0);
        BitCount++;
        if(BitCount==32) 
          {
            SendMode++;      //If this was the last bit of header then move on to data.
            LedIndex=0;
            BitCount=0;
          }
        }
      digitalWrite(clockPin, HIGH);
      digitalWrite(clockPin, LOW);

      break;
    case 0:            //Start
      if(!BlankCounter)    //AS SOON AS CURRENT pwm IS DONE. BlankCounter 
      {
        BitCount=0;
        LedIndex=0;
        SendMode=1; 
      }  
      digitalWrite(clockPin, HIGH);
      digitalWrite(clockPin, LOW);

      break;   
  }
  //Keep track of where the LEDs are at in their pwm cycle. 
  BlankCounter++;
}

void show()
{
  // The interrupt routine will see this as re-send LED color data.
  SendMode = 0;
}

// Create a 15 bit color value from R,G,B
unsigned int Color(byte r, byte g, byte b)
{
  //Take the lowest 5 bits of each value and append them end to end
  return( ((unsigned int)g & 0x1F )<<10 | ((unsigned int)b & 0x1F)<<5 | (unsigned int)r & 0x1F);
}


// Show a colour bar going up from 0 to 9
void ColorUp( unsigned int ColourToUse)
{
  byte Counter;
  for(Counter=0;Counter <= lightCount; Counter++)
  {
    Display[Counter]=ColourToUse;
    show();
    delay(25);
  }  
}

// Show a colour bar going down from 9 to 0
void ColorDown( unsigned int ColourToUse)
{
  byte Counter;
  for(Counter=lightCount;Counter > 0; Counter--)
  {
    Display[Counter-1]=ColourToUse;
    show();
    delay(25);
  }  
}

void loop() {
  
  ColorWipingFunction(500);
}

void ColorWipingFunction(uint8_t wait){
  int Counter;
  
  for(Counter=0;Counter < 2;Counter++){
    ColorUp(Color(0,0,0));
    delay(wait);
    ColorDown(Color(random(0,32),random(0,32),random(0,32)));
    delay(wait);
  }//end for

}//end function
