// Program to assist in gain calibration of TC4

#include <cADC.h>
#include <Wire.h>
#include <cLCD.h>

#define BANNER_CALMV "Cal_mV 20110530" // version
#define BACKLIGHT lcd.backlight();
#define CHAN 0
#define CALPT 50000.0
#define DEFAULT_CAL 1.000

cADC adc;
filterRC f;
cLCD lcd; // I2C LCD interface

long i = 0;
float uv_cal;
float stored_cal = DEFAULT_CAL;
long uv;


void setup() {
  Serial.begin(57600);
  Wire.begin();
  lcd.begin(16, 2);
  BACKLIGHT;
  lcd.setCursor( 0, 0 );
  lcd.print( BANNER_CALMV ); // display version banner

  uv_cal = stored_cal;
  adc.setCal (stored_cal, 0 );
  f.init( 50 );

  delay( 3000 ); // display banner for a while
  lcd.clear();

}

void loop() {
  adc.nextConversion( CHAN );
  delay( 300 );
  uv = f.doFilter( adc.readuV() );
  Serial.print( i++ ); Serial.print( "," );
  Serial.print( (float)uv * 0.001, 3 ); Serial.print( "," );
  Serial.print( uv ); Serial.print( "," );
  if( uv != 0.0 )
    uv_cal = stored_cal * CALPT / (float) uv;
  Serial.print( uv_cal, 5 ); Serial.print( "," );
  Serial.println( round( uv_cal * (float) uv ) );
  
  lcd.setCursor( 0, 0 );
  lcd.print( "                ");
  lcd.setCursor( 0, 1 );
  lcd.print( "                ");
  
  lcd.setCursor( 0, 0 );
  lcd.print( (float)uv * 0.001, 3 );
  lcd.setCursor( 8, 0 );
  lcd.print( stored_cal, 5 );
  lcd.setCursor( 0, 1 );
  lcd.print( uv_cal, 5 );
  lcd.setCursor( 8, 1 );
  lcd.print( "CHAN " );
  lcd.print( CHAN );
  
}

