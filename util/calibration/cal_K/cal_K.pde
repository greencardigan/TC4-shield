// Program to assist in temperature offset calibration of TC4

#include <cADC.h>
#include <Wire.h>
#include <TypeK.h>
#include <cLCD.h>

#define BANNER_K "Cal_K 20110530" // version
#define BACKLIGHT lcd.backlight();
#define CHAN 1 // use TC2
#define CALPT 200.0
#define DEFAULT_OFFS 0.0
#define DEFAULT_CAL 1.0000

cADC adc;
ambSensor amb;
filterRC f;
TypeK tc;
float ctemp;
cLCD lcd; // I2C LCD interface

float stored_offs = DEFAULT_OFFS;
float stored_cal = DEFAULT_CAL;

long i = 0;
int dly;

void setup() {
  Serial.begin(57600);
  Wire.begin();
  lcd.begin(16, 2);
  BACKLIGHT;
  lcd.setCursor( 0, 0 );
  lcd.print( BANNER_K ); // display version banner

  adc.setCal ( stored_cal, 0 );
//  adc.setCfg( ADC_BITS_18 );
  f.init( 70 );
  amb.init( 70 );
//  amb.init( 70, AMB_CONV_1SHOT );
//  amb.setCfg( AMB_BITS_12 );
  amb.setOffset( stored_offs );
//  int d = amb.getConvTime();
//  dly = adc.getConvTime();
//  dly = dly > d ? dly : d;
  
  delay( 3000 ); // display banner for a while
  lcd.clear();

}

void loop() {
  Serial.print( i++ ); Serial.print( "," );

  amb.nextConversion();  
  adc.nextConversion( CHAN );
  delay( 300 );
  //delay( dly );
  int32_t v = adc.readuV();
  Serial.print( v ); Serial.print( "," );
  
  amb.readSensor();
  ctemp = amb.getAmbC();
  Serial.print( ctemp ); Serial.print( "," );
  
  float tempC = tc.Temp_C( 0.001 * v, ctemp ) ;
  Serial.print( tempC ); Serial.print( "," );
  
  v = round( C_TO_F( tempC ) * 100 );
  
  v = f.doFilter( v );
  
  Serial.print( v ); Serial.print( "," );
  Serial.println( CHAN, DEC );

  lcd.setCursor( 0, 0 );
  lcd.print( "                ");
  lcd.setCursor( 0, 1 );
  lcd.print( "                ");
  
  lcd.setCursor( 0, 0 );
  lcd.print( tempC, 1 );
  lcd.setCursor( 8, 0 );
  lcd.print( stored_offs, 2 );
  lcd.setCursor( 0, 1 );
  lcd.print( CALPT - tempC + stored_offs, 2 );
  lcd.setCursor( 8, 1 );
  lcd.print( "CHAN " );
  lcd.print( CHAN );
  

}

