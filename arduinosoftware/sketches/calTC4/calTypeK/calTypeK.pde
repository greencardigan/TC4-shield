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
  adc.initADC();
  adc.setCal (1.00166, -3 );
  f.init( 80, 7200 );
  amb.config();
  amb.init();
  amb.setOffset( -0.9 / 1.8 );
}

void loop() {
  Serial.print( i++ ); Serial.print( "," );

  amb.readAmbientC();
  amb.calcAvg();
  
  adc.nextConversion( 0 );
  delay( 300 );
  int32_t v = adc.getuV( rchan );
  Serial.print( v ); Serial.print( "," );
  
  ctemp = amb.getCurrent() * AMB_LSB;
  Serial.print( ctemp ); Serial.print( "," );
  
  float tempC = tc.Temp_C( 0.001 * v, ctemp ) ;
  tempC += amb.getOffset();
  Serial.print( tempC ); Serial.print( "," );
  
  v = round( C_TO_F( tempC ) * 100 );
  
  v = f.doFilter( v );
  
  Serial.print( v ); Serial.print( "," );
  Serial.println( rchan, DEC );

  

}

