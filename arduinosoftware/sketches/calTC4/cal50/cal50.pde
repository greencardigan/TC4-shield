// Program to assist in gain calibration of TC4

#include <cADC.h>
#include <Wire.h>

cADC adc;
filterRC f;

byte rchan;
long i = 0;

void setup() {
  Serial.begin(57600);
  Wire.begin();
  adc.setCal (1.00311, -1 );
  f.init( 50 );
}

void loop() {
  adc.nextConversion( 1 );
  delay( 300 );
  Serial.print( i++ ); Serial.print( "," );
  Serial.print( f.doFilter( adc.readuV() ) ); Serial.print( "," );
  Serial.println( rchan, DEC );
}

