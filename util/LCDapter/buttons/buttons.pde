#include <cLCD.h>
#include <cButton.h>
#include <Wire.h>

#define TYPEMATIC 50

cLCD lcd;
cButtonPE16 buttons;
byte val[4];
uint8_t bits;
int32_t mspr[4];

void printVals() {
  lcd.setCursor( 0, 1 );
  lcd.print( val[0], DEC ); lcd.print("  ");
  lcd.setCursor( 8, 1 );
  lcd.print( val[1], DEC ); lcd.print("  ");
}

void buttonAction( uint8_t key ) {
  switch( key ) {
    case 3: ++val[0]; break;
    case 2: --val[0]; break;
    case 1: ++val[1]; lcd.backlight(); break;
    case 0: --val[1]; lcd.noBacklight(); break;
  }
}

void setup() {
  Wire.begin();
  Serial.begin(57600);
  lcd.begin(16, 2);
  lcd.backlight();
  lcd.print("BUTTONS v2.6");
  buttons.begin(4);
  for( int i = 0; i < 2; i++ ) {
//    val[i] = 100 + i + 1;
    val[i] = 100;
  }
}

void loop() {
  // first, check and see if at least one button has changed state
  if( buttons.readButtons() != 0 ) {
    for( int i = 0; i < 4; i++ ) {
      if( buttons.keyPressed( i ) && buttons.keyChanged( i ) ) {
        mspr[i] = millis(); // mark the time when the key was pressed
        Serial.println( i );
        buttonAction( i );
      }
    }
  }
  // if there has been no change in key status, see if one of them has been held > 1 sec
  else if( buttons.anyPressed() ) { 
    for( int i = 0; i< 4; i++ ) {
      int32_t ms = millis();
      if( buttons.keyPressed( i )) {
        if( ms - mspr[i] >=  1000 ) {
         Serial.println( i );
         buttonAction( i );
          mspr[i] += TYPEMATIC;  // typematic rate
        }
      }
    }
  }
  printVals();
  buttons.ledUpdate( val[0] & 0x7 );
}
