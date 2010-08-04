// aBourbon.pde
//

// N-channel Rise-o-Meter
// output on serial port:  timestamp, temperature, rise rate (degF per minute)
// output on LCD : timestamp, channel 1 temperature
//                   RoR 1,    channel 2 temperature

// Support for pBourbon.pde and 16 x 2 LCD
// Jim Gallt and Bill Welch
// Version: 20100724 (support for hardware interfaces moved to cADC library)

// This code was adapted from the a_logger.pde file provided
// by Bill Welch.

#include <Wire.h>
#include <TypeK.h>
#include <Riser.h>
#include <LiquidCrystal.h>
#include <cADC.h>

// ------------------------ conditional compiles

#define MIN_DELAY 300   // ms between ADC samples (tested OK at 270)
#define MAGIC_NUMBER 960 // not quite 1000 to make up for processing time
#define NCHAN 2   // number of TC input channels
#define BAUD 57600  // serial baud rate
#define TC_TYPE TypeK  // thermocouple type / library
#define DP 1  // decimal places for output
#define BT_FILTER 50 // filtering level (percent) for T1
#define ET_FILTER 50 // filtering level (percent) for T2

// fixme This value should be user selectable
#define NSAMPLES 10 // samples used for moving average calc for temperature

// --------------------------------------------------------------
// global variables

void get_samples();
void blinker();
void logger();

// class objects
cADC adc( A_ADC );
ambSensor amb( A_AMB, NAMBIENT );
filterRC fT[NCHAN];


int ledPin = 13;
//char msg[80];

// updated at intervals of DELAY ms
int32_t samples[NCHAN];
int32_t temps[NCHAN];

int adc_delay;

// class objects perform RoR calculations
Riser rise1( NSAMPLES );
Riser rise2( NSAMPLES );
Riser rise3( NSAMPLES );
Riser rise4( NSAMPLES );

// LCD output strings
char smin[3],ssec[3],st1[6],st2[6],st3[6],sRoR1[7];
char LCD01[17];
char LCD02[17];

// LCD interface definition
#define RS 2
#define ENABLE 4
#define DB4 7
#define DB5 8
#define DB6 12
#define DB7 13
LiquidCrystal lcd( RS, ENABLE, DB4, DB5, DB6, DB7 );

float timestamp = 0;

// ------------------------------------------------------------------
void logger()
{
  float tod;
  int i;
  float RoR,t1,t2,t_amb;

  // print timestamp
  tod = millis() * 0.001;
  Serial.print(tod, DP);

  // print ambient
  Serial.print(",");
  t_amb = (float)amb.getCurrent() * AMB_LSB;
  Serial.print( C_TO_F(t_amb), DP );
   
  // print temperature, rate for each channel
  i = 0;
  if( NCHAN >= 1 ) {
    Serial.print(",");
    Serial.print( t1 = 0.01 * temps[i], DP );
    Serial.print(",");
    Serial.print( RoR = rise1.CalcRate( tod, 0.01 * temps[i++] ), DP );
  };
  
  if( NCHAN >= 2 ) {
    Serial.print(",");
    Serial.print( t2 = 0.01 * temps[i], DP );
    Serial.print(",");
    Serial.print( rise2.CalcRate( tod, 0.01 * temps[i++] ), DP );
  };
  
  if( NCHAN >= 3 ) {
    Serial.print(",");
    Serial.print( 0.01 * temps[i], DP );
    Serial.print(",");
    Serial.print( rise3.CalcRate( tod, 0.01 * temps[i++] ), DP );
  };
  
  if( NCHAN >= 4 ) {
    Serial.print(",");
    Serial.print( 0.01 * temps[i], DP );
    Serial.print(",");
    Serial.print( rise4.CalcRate( tod, 0.01 * temps[i++] ), DP );
  };
  
  Serial.println();
   
  // ----------------------------- LCD output
  // form the TOD output string in min:sec format
  int itod = round( tod );
  if( itod > 3599 ) itod = 3599;
  sprintf( smin, "%02u", itod / 60 );
  sprintf( ssec, "%02u", itod % 60 );
  strcpy( LCD01, smin );
  strcat( LCD01, ":" );
  strcat( LCD01, ssec );

  // channel 1 temperature and RoR
  int it01 = round( t1 );
  if( it01 > 999 ) 
    it01 = 999;
  else
    if( it01 < -999 ) it01 = -999;
  sprintf( st1, "%4d", it01 );

  int iRoR = round( RoR );
  if( iRoR > 99 ) 
    iRoR = 99;
  else
   if( iRoR < -99 ) iRoR = -99; 
  sprintf( sRoR1, "%0+3d", iRoR );

  strcat( LCD01, "    T1:" );
  strcat( LCD01, st1 );
  strcpy( LCD02, "RoR1:");
  strcat( LCD02, sRoR1 );
  strcat( LCD02, " T2:" );

  // channel 2 temperature 
  int it02 = round( t2 );
  if( it02 > 999 ) it02 = 999;
  else if( it02 < -999 ) it02 = -999;
  sprintf( st2, "%4d", it02 );
  strcat( LCD02, st2 );
  
  lcd.setCursor(0,0);
  lcd.print(LCD01);
  lcd.setCursor(0,1);
  lcd.print(LCD02);
  
  // Serial.println("0123456789ABCDEF");
  // Serial.println( LCD01 );
  // Serial.println( LCD02 );
};

// --------------------------------------------------------------------------
void get_samples()
{
  byte chan;
  int32_t v;
  TC_TYPE tc;
  float tempC;
   
  v = adc.getuV( chan ); // get a microvolt sample from MCP3424 ADC
  samples[chan] = v; // units = microvolts

  // convert mV to temperature using ambient temp adjustment
  tempC = tc.Temp_C( 0.001 * v, (float)amb.getCurrent() * AMB_LSB );
  tempC += amb.getOffset();

  // convert to F and multiply by 100 to preserve precision while storing in integer variable
  v = round( C_TO_F( tempC ) * 100 );
  temps[chan] = fT[chan].doFilter( v );

  if( NCHAN == ++chan ) chan = 0;
  
  adc.nextConversion( chan ); // setup the ADC register for next conversion
};
  
// ---------------------------------------------------------------------
void blinker()
{
  static char on = 0;
  if (on) {
    digitalWrite(ledPin, HIGH);
  } else {
      digitalWrite(ledPin, LOW);
  }
  on ^= 1;
}

// ------------------------------------------------------------------------
// MAIN
//
void setup()
{
  pinMode(ledPin, OUTPUT);
  lcd.begin(16, 2);

// want delay between sample sets to be at least 1 second
  adc_delay = MAGIC_NUMBER / NCHAN;
  if( adc_delay < MIN_DELAY ) adc_delay = MIN_DELAY ;
  Serial.begin(BAUD);

  while ( millis() < 1000) {
    blinker();
    delay(100);
  }

//  Serial.println(msg);
  Serial.print("# time,ambient,T0,rate0");
  if( NCHAN >= 2 ) Serial.print(",T1,rate1");
  if( NCHAN >= 3 ) Serial.print(",T2,rate2");
  if( NCHAN >= 4 ) Serial.print(",T3,rate3");
  Serial.println();
 
  while ( millis() < 3000) {
    blinker();
    delay(100);
  }

  Wire.begin(); 
  adc.initADC(); // initialize the MCP3424
  amb.config(); // configure MCP9800
  amb.init();  // initialize ambient temp averaging
  amb.setOffset( 1.4 / 1.8 );
  fT[0].init( BT_FILTER ); // digital filtering on BT
  fT[1].init( ET_FILTER ); // digital filtering on ET
}

// -----------------------------------------------------------------
void loop()
{
  float idletime;

  // limit sample rate to once per second
  while ( (millis() % 1000) != 0 ) ;  
  timestamp = float(millis()) / 1000.;

  amb.readAmbientC(); // read new ambient value from chip
  amb.calcAvg(); // performing ambient averaging
  
  for (int i=0; i<NCHAN; i++) { // read each ADC channel
    get_samples();
    blinker();
    delay( adc_delay );
  }
  logger();

  idletime = float(millis()) / 1000.;
  idletime = 1.0 - (idletime - timestamp);
  // arbitrary: complain if we don't have at least 10mS left
  if (idletime < 0.010) {
    Serial.print("# idle: ");
    Serial.println(idletime);
  }

}

