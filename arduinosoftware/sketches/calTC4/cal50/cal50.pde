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
  adc.initADC();
  adc.setCal (1.00166, -3 );
  f.init( 50, 0 );
}

void loop() {
  adc.nextConversion( 2 );
  delay( 300 );
  Serial.print( i++ ); Serial.print( "," );
  Serial.print( f.doFilter( adc.getuV( rchan ) ) ); Serial.print( "," );
  Serial.println( rchan, DEC );
}

