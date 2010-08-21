// aBourbon.pde
//
// N-channel Rise-o-Meter
// output on serial port:  timestamp, temperature, rise rate (degF per minute)
// output on LCD : timestamp, channel 1 temperature
//                   RoR 1,  channel 2 temperature

// Support for pBourbon.pde and 16 x 2 LCD
// Jim Gallt and Bill Welch
// Version: 20100820

// This code was adapted from the a_logger.pde file provided
// by Bill Welch.

#include <Wire.h>
#include <TypeK.h>
#include <LiquidCrystal.h>
#include <cADC.h>

// ------------------------ conditional compiles

#define MIN_DELAY 300   // ms between ADC samples (tested OK at 270)
//#define MAGIC_NUMBER 960 // not quite 1000 to make up for processing time
#define NCHAN 2   // number of TC input channels
#define BAUD 57600  // serial baud rate
#define TC_TYPE TypeK  // thermocouple type / library
#define DP 1  // decimal places for output
#define BT_FILTER 10 // filtering level (percent) for T1
#define ET_FILTER 10 // filtering level (percent) for T2
#define RISE_FILTER 70 // heavy filtering for RoR calculations
#define CAL_GAIN 1.00 // substitute known values from calibration
#define CAL_OFFSET 0 // subsitute known value for uV offset in ADC
#define AMB_OFFSET 0 // substitute known value for amb temp offset
#define AMB_FILTER 70 // 70% filtering on ambient sensor readings
#define D_MULT 0.001 // multiplier to convert temperatures from int to float

// --------------------------------------------------------------
// global variables

void get_samples();
void logger();

// class objects
cADC adc( A_ADC );
ambSensor amb( A_AMB );
filterRC fT[NCHAN];
filterRC fRise[NCHAN]; // heavily filtered for calculating RoR

int32_t temps[NCHAN];
int32_t ftemps[NCHAN]; // heavily filtered temps
int32_t ftimes[NCHAN];
int32_t flast[NCHAN]; // for calculating derivative
int32_t lasttimes[NCHAN];

//int adc_delay;

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
boolean first;

// ---------------------------------------------------
// T1, T2 = temperatures x 100
// t1, t2 = time marks, milliseconds
float calcRise( int32_t T1, int32_t T2, int32_t t1, int32_t t2 ) {
  int32_t dt = t2 - t1;
  if( dt == 0 ) return 0.0;
  float dT = (T2 - T1) * D_MULT;
  float dS = dt * 0.001;
  return ( dT / dS ) * 60.0; // rise per minute
}

// ------------------------------------------------------------------
void logger()
{
  int i;
  float RoR,t1,t2,t_amb;
  float rx;

  // print timestamp
  Serial.print( timestamp, DP );

  // print ambient
  Serial.print(",");
  t_amb = amb.getAmbF();
  Serial.print( t_amb, DP );
   
  // print temperature, rate for each channel
  i = 0;
  if( NCHAN >= 1 ) {
    Serial.print(",");
    Serial.print( t1 = D_MULT*temps[i], DP );
    Serial.print(",");
    RoR = calcRise( flast[i], ftemps[i], lasttimes[i], ftimes[i] );
    Serial.print( RoR , DP );
    i++;
  };
  
  if( NCHAN >= 2 ) {
    Serial.print(",");
    Serial.print( t2 = D_MULT * temps[i], DP );
    Serial.print(",");
    rx = calcRise( flast[i], ftemps[i], lasttimes[i], ftimes[i] );
    Serial.print( rx , DP );
    i++;
  };
  
  if( NCHAN >= 3 ) {
    Serial.print(",");
    Serial.print( D_MULT * temps[i], DP );
    Serial.print(",");
    rx = calcRise( flast[i], ftemps[i], lasttimes[i], ftimes[i] );
    Serial.print( rx , DP );
    i++;
  };
  
  if( NCHAN >= 4 ) {
    Serial.print(",");
    Serial.print( D_MULT * temps[i], DP );
    Serial.print(",");
    rx = calcRise( flast[i], ftemps[i], lasttimes[i], ftimes[i] );
    Serial.print( rx , DP );
    i++;
  };
  
  Serial.println();
   
  // ----------------------------- LCD output
  // form the TOD output string in min:sec format
  int itod = round( timestamp );
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
  
};

// -------------------------------
void checkStatus( uint32_t ms ) {
  uint32_t tod = millis();
  while( millis() - tod < ms ) {};
}

// --------------------------------------------------------------------------
void get_samples()
{
  int32_t v;
  TC_TYPE tc;
  float tempC;
  
  for( int j = 0; j < NCHAN; j++ ) {
    adc.nextConversion( j );
    amb.nextConversion();
    checkStatus( MIN_DELAY );
    ftimes[j] = millis();
    amb.readSensor();
    v = adc.readuV(); // microvolt sample from MCP3424
    tempC = tc.Temp_C( 0.001 * v, amb.getAmbC() ); // convert to Celsius
    v = round( C_TO_F( tempC ) / D_MULT ); // store results as integers
    temps[j] = fT[j].doFilter( v ); // apply digital filtering
    ftemps[j] =fRise[j].doFilter( v ); // heavy filtering for RoR
  }
};
  
// ------------------------------------------------------------------------
// MAIN
//
void setup()
{
  delay(500);
  lcd.begin(16, 2);

  Serial.begin(BAUD);
  Serial.print("# time,ambient,T0,rate0");
  if( NCHAN >= 2 ) Serial.print(",T1,rate1");
  if( NCHAN >= 3 ) Serial.print(",T2,rate2");
  if( NCHAN >= 4 ) Serial.print(",T3,rate3");
  Serial.println();
 
  Wire.begin(); 
  adc.setCal( CAL_GAIN, CAL_OFFSET );
  amb.init( AMB_FILTER );  // initialize ambient temp filtering
  amb.setOffset( AMB_OFFSET );
  fT[0].init( BT_FILTER ); // digital filtering on BT
  fT[1].init( ET_FILTER ); // digital filtering on ET
  fRise[0].init( RISE_FILTER ); // digital filtering for RoR calculation
  fRise[1].init( RISE_FILTER ); // digital filtering for RoR calculation
  first = true;
}

// -----------------------------------------------------------------
void loop()
{
  float idletime;

  // limit sample rate to once per second
  while ( (millis() % 1000) != 0 ) ;  
  timestamp = float(millis()) / 1000.;

  get_samples();
  if( first )
    first = false;
  else
    logger();

  for( int j = 0; j < NCHAN; j++ ) {
   flast[j] = ftemps[j]; // use previous values for calculating RoR
   lasttimes[j] = ftimes[j];
  }

  idletime = float(millis()) / 1000.;
  idletime = 1.0 - (idletime - timestamp);
  // arbitrary: complain if we don't have at least 10mS left
  if (idletime < 0.010) {
    Serial.print("# idle: ");
    Serial.println(idletime);
  }

}

