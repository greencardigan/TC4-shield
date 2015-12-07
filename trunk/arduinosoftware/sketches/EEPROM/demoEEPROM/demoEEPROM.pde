// Test of mcEEPROM write/read of byte array

#include <mcEEPROM.h>
#include <Wire.h>

#define ADDR B1010000
#define N 600
#define PTR 0xFF00

int tod;
uint16_t ptr = PTR;
uint16_t nr, nw;
mcEEPROM ep;
uint8_t tx[N];
uint8_t rx[N];

void setup() {
  Serial.begin(57600);
  delay(1000);

//  for( int i = 0; i < len; i++ )
//   tx[i] = (uint8_t)tstr[i];

  for( int i = 0; i < N; i++ )
    tx[i] = N - i & 0xFF;
  
  Serial.print("Writing to EEPROM @ 0x"); Serial.print( ptr, HEX); Serial.print(" ... ");
  tod = millis();
  nw = ep.write( ptr, tx, N );
  Serial.print( nw, DEC );Serial.println(" bytes written.");
  Serial.print("Elapsed = ");Serial.println( millis() - tod );
  
  Serial.print("Reading from EEPROM...");
  tod = millis();
  nr = ep.read( ptr, rx, nw );
  Serial.print(nr, DEC); Serial.println (" bytes read.");
  Serial.print("Elapsed = ");Serial.println( millis() - tod );

  for( int i = 0; i < nr; i++ ) {
    Serial.print( i, DEC ); Serial.print(" : ");
    Serial.print( tx[i], DEC ); Serial.print(" : ");
    Serial.println( rx[i], DEC );
  };
 
}

void loop() {
}

