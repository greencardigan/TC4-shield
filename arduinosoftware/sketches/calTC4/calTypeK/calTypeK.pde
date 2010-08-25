// Program to assist in temperature offset calibration of TC4

#include <cADC.h>
#include <Wire.h>
#include <TypeK.h>

cADC adc;
ambSensor amb;
filterRC f;
TypeK tc;
float ctemp;

byte rchan;
long i = 0;

void setup() {
  Serial.begin(57600);
  Wire.begin();
  adc.setCal (1.00311, -1 );
  f.init( 70 );
  amb.init( 70 );
  amb.setOffset( -0.3 );
}

void loop() {
  Serial.print( i++ ); Serial.print( "," );

  amb.nextConversion();  
  adc.nextConversion( 0 );
  delay( 300 );
  int32_t v = adc.readuV();
  Serial.print( v ); Serial.print( "," );
  
  amb.readSensor();
  ctemp = amb.getAmbC();
  Serial.print( ctemp ); Serial.print( "," );
  
  float tempC = tc.Temp_C( 0.001 * v, ctemp ) ;
//  tempC += amb.getOffset();
  Serial.print( tempC ); Serial.print( "," );
  
  v = round( C_TO_F( tempC ) * 100 );
  
  v = f.doFilter( v );
  
  Serial.print( v ); Serial.print( "," );
  Serial.println( rchan, DEC );

  

}

