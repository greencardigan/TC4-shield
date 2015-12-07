// Hooking up an 8-bit MCP23008 expander via I2C.
//  Based on JeeLabs expander plug
// see http://www.jeelabs.org/2009/07/07/io-expander/

#define BANNER "23008 Button Demo"
#include <Wire.h>
#include <c23008.h>
#include <cLCD.h>

#define UP    1
#define DOWN 16
#define LEFT  2
#define RIGHT 4
#define ENTER 8
#define MINUS 32
#define PLUS 128

#define BACKLIGHT ;
#define RS 2
#define ENABLE 4
#define D4 7
#define D5 8
#define D6 12
#define D7 13
LiquidCrystal lcd( RS, ENABLE, D4, D5, D6, D7 ); // standard 4-bit parallel interface

c23008Expander mcp;
byte OldButton;

void setup() { 
  Wire.begin();
  lcd.begin(2,16);
  Serial.begin(57600);
  Serial.print(BANNER);
  mcp.begin();      // use default address 0
  mcp.setInputs(0xff);  //set all ports to input
  mcp.setPullups(0xFF);  // turn on 100K pullup internally
  mcp.setInverse(0xFF);   //invert reading on all ports
  lcd.clear();
  lcd.print( BANNER);
  lcd.setCursor(0,1);
  lcd.print( "Button=0  Start");

}

byte read_button() { 
  String pstr;

  byte button =  mcp.readByte();
 // byte button =  mcp.readButtons();

  if(button > 0){
    if(OldButton != button){  //Check if button held down
      switch (button) {
      case DOWN: 
        pstr = "DOWN";
        break;
      case ENTER :  
        pstr = "ENTER";
        break;   
      case UP :  
        pstr = "UP";
        break;
      case LEFT :
        pstr = "LEFT"; 
        break; 
      case RIGHT :  
        pstr = "RIGHT";
        break;
      case MINUS :  
        pstr = "MINUS";
        break; 
      case PLUS :  
        pstr = "PLUS";
        break;        
      default :
        pstr = "Unknown"; 
       break; 
      }  
      lcd.setCursor(0,1);
      lcd.print( "Button=");
      lcd.print( button, DEC);
      lcd.print( "  ");
      lcd.print( pstr);
      lcd.print( "       ");  
    } 
  }
  OldButton = button;
  return button;
}

void loop() {
  byte data = read_button();
  Serial.print("Button=");
  Serial.println(data, DEC);
  delay(250);
}






