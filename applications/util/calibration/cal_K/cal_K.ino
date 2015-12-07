// Program to assist in temperature offset calibration of TC4

#include <cADC.h>
#include <Wire.h>
#include <thermocouple.h>
#include <cLCD.h>

#define BANNER_K "Cal_K 20110610" // version
#define BACKLIGHT lcd.backlight();
#define CHAN 1 // use TC2
#define CALPT 200.0
#define TEMP_OFFS -0.0
#define GAIN_CAL 1.00437
#define AMB_FILT 90
#define ADC_FILT 50

//#define REFINED
#define ADC_BITS ADC_BITS_18
#define ADC_GAIN ADC_GAIN_8
#define AMB_BITS AMB_BITS_12


cADC adc;
ambSensor amb;
filterRC f;
typeK tc;
float ctemp;
cLCD lcd; // I2C LCD interface

long i = 0;
int dly;

void setup() {
  delay(1000);
  Serial.begin(57600);
  Wire.begin();
  lcd.begin(16, 2);
  BACKLIGHT;
  lcd.setCursor( 0, 0 );
  lcd.print( BANNER_K ); // display version banner
  adc.setCal ( GAIN_CAL, 0 );
  f.init( ADC_FILT );

#ifdef REFINED
  amb.init( AMB_FILT, AMB_CONV_1SHOT );
  amb.setCfg( AMB_BITS );
  adc.setCfg( ADC_BITS, ADC_GAIN );
  int d = amb.getConvTime();
  dly = adc.getConvTime();
  dly = dly > d ? dly : d;
#else
  amb.init( AMB_FILT );
#endif

  amb.setOffset( TEMP_OFFS );
  delay( 3000 ); // display banner for a while
  lcd.clear();
}

void loop() {
  Serial.print( i++ ); Serial.print( "," );
  amb.nextConversion();  
  adc.nextConversion( CHAN );

#ifdef REFINED
  delay( dly );
#else
  delay( 300 );
#endif

  int32_t v = adc.readuV();
  int32_t fv = f.doFilter( v << 10 );
  fv >>= 10;
  Serial.print( fv ); Serial.print( "," );
  
  amb.readSensor();
  ctemp = amb.getAmbC();
  Serial.print( ctemp ); Serial.print( "," );
  float tempC = tc.Temp_C( 0.001 * fv, ctemp ) ;
  Serial.print( tempC ); Serial.print( "," );
  Serial.print( fv ); Serial.print( "," );
  Serial.print( CHAN, DEC ); Serial.print( "," );
  Serial.println( ( CALPT - tempC + TEMP_OFFS ), 2 );

  lcd.setCursor( 0, 0 );
  lcd.print( "                ");
  lcd.setCursor( 0, 1 );
  lcd.print( "                ");
  lcd.setCursor( 0, 0 );
  lcd.print( tempC, 1 );
  lcd.setCursor( 8, 0 );
  lcd.print( TEMP_OFFS, 2 );
  lcd.setCursor( 0, 1 );
  lcd.print( CALPT - tempC + TEMP_OFFS, 2 );
  lcd.setCursor( 8, 1 );
  lcd.print( "CHAN " );
  lcd.print( CHAN );
}

