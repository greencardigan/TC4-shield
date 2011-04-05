// Program to assist in gain calibration of TC4

#include <cADC.h>
#include <Wire.h>

cADC adc;
filterRC f;

byte rchan;
long i = 0;
float uv_cal;
long uv;


void setup() {
  Serial.begin(57600);
  Wire.begin();
  uv_cal = 1.000;
  adc.setCal (uv_cal, 0 );
  f.init( 50 );
}

void loop() {
  adc.nextConversion( 0 );
  delay( 300 );
  uv = f.doFilter( adc.readuV() );
  Serial.print( i++ ); Serial.print( "," );
  Serial.print( (float)uv * 0.001, 3 ); Serial.print( "," );
  Serial.print( uv ); Serial.print( "," );
  uv_cal = 50000.0 / (float) uv;
  Serial.print( uv_cal, 5 ); Serial.print( "," );
  Serial.println( round( uv_cal * (float) uv ) );
  
}

