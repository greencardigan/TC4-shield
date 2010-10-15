#include <cLCD.h>
#include <cButton.h>
#include <Wire.h>


cLCD lcd;
cButtonPE16 buttons;
byte val[4];
uint8_t bits;

void printVals() {
  lcd.setCursor( 0, 1 );
  for( int i = 0; i < 2; i++ ) {
  lcd.print( val[i], DEC );
  lcd.print("  ");
  }
  lcd.print("   ");
}

void setup() {
  Wire.begin();
  Serial.begin(57600);
  lcd.begin(16, 2);
  lcd.print("BUTTONS v2.2");
  buttons.begin(4);
  for( int i = 0; i < 2; i++ ) {
//    val[i] = 100 + i + 1;
    val[i] = 100;
  }
}

void loop() {
  if( buttons.readButtons() != 0 ) {
    for( int i = 0; i < 4; i++ ) {
      if( buttons.keyPressed( i ) && buttons.keyChanged( i ) ) {
        Serial.println( i );
        if( i == 3 ) ++val[0];
        else if ( i == 2 ) --val[0];
        else if ( i == 1 ) ++val[1];
        else if ( i == 0 ) --val[1];
      }
    }
  }
  printVals();
  buttons.ledUpdate( val[0] & 0x7 );
}
