// Roaster.pde
// Version: 20100718 09

// Written by Randy Tsuchiyama
// This is intended to provide PID type control to roast coffee using an Arduino.
// The author has a hot air (popcorn popper) based roaster, but it should work for other roasters
// by tweaking the PID parameters, and the profile.
// The hardware platform includes the TC4 board, as described in this thread
// http://homeroasters.org/php/forum/viewthread.php?thread_id=1774&rowstart=0
// The TC4 board is an Arduino shield with 4 thermocouple inputs, and two PWM outputs.  
// Only two TC inputs are used by this program.

// This program is based on 
// pBourbon.pde and 16 x 2 LCD
// by Jim Gallt and Bill Welch
 
// This program also borrowed/used code and ideas from this project:
// A fully automatic coffee bean roaster (Arduino)
// By Rutger
// See http://www.instructables.com/id/A-fully-automatic-coffee-bean-roaster-Arduino/

// thermocouple channel 1 is intended to be Environmental Temp (ET), and is used to control the PID function
// In my roaster, ET is monitored where the hot air first contacts the bean mass, at the bottom of the roasting chamber.
// thermocouple channel 2 is intended to be Bean Temp (BT)
// Analog output 1 is (PWM) is intended to control the heater SSR (pin D9)
// Analog output 2 is (PWM) is intended to control the fan        (pin D10) optional 


// The program uses the roast profile described by the arrays Tprofile and Sprofile below.

// output on serial port:  timestamp, temperature, rise rate (degF per minute)
// LCD output is formatted for a 4x20 LCD.  First two rows will fit in a 2x16 LCD.
// output on LCD : timestamp, channel 1 temperature (ET)
//                 RoR 1, RoR 2, channel 2 temperature (BT),
//                 phase, PWM output
//                 setpoint, phase countdown timer

// Support for roaster.pde
// Randy Tsuchiyama

//  ------------------------  include files
#include <Wire.h>
#include <TypeK.h>
#include <Riser.h>
#include <LiquidCrystal.h>  //LCD library
#include <PID_Beta6.h>      //Added for PID
#include <PWM16.h>          //Added for PWM

//  ------------------------  coffee roasting profile and parameters
int Tprofile [] = {100, 100, 250, 410, 480, 500, 520, 525, 525, 525, 525, 525};      // Temperature profile (phase 1, 2, 3, etc)
int Sprofile [] = {  0,  30,  60, 180, 180, 180, 240, 240,   2,   2,   2,   2};      // Time profile in seconds (phase 1, 2, 3, etc) first time interval should be 0!
int final = 500;  // define final roasting temperature
int cool  = 40;   // temperature to cool to after roasting
int phase = 0;    // phase
int maxphase = 11; // max number of phases, program stops when it hits this number.  Add more items to Tprofile and Sprofile, then can increase.

// -------------------------- PID controller parameters and setup
double Input, Setpoint;                          // parameters for PID
double Output = 0;
int P = 10;                                      //P term
int I = 14;                                      //I term
int D = 1;                                       //D term
PID myPID(&Input, &Output, &Setpoint ,P ,I ,D); 


// -------------------------- PWM Frequency
unsigned int T = pwmN4Hz;
//Speeds that would work include pwmN4Hz, pwmN2Hz, pwmN1Hz, pwmN2sec,pwmN4sec
PWM16 pwmOut;

// ------------------------ conditional compiles

#define MIN_DELAY 300   // ms between ADC samples (tested OK at 270)
#define MCP9800_DELAY 100 // sample period for MCP9800
#define MAGIC_NUMBER 960 // not quite 1000 to make up for processing time
#define RES_11      // resolution on ambient temp chip
#define NAMBIENT 12  // number of ambient samples to be averaged
#define CFG CFG8  // select gain = 8 on ADC
#define NCHAN 2   // number of TC input channels
#define BAUD 57600  // serial baud rate
#define TC_TYPE TypeK  // thermocouple type / library
#define DP 1  // decimal places for output
// fixme This value should be user selectable
#define NSAMPLES 10 // samples used for moving average calc for temperature

// ---------------------------- calibration of ADC and ambient temp sensor
// fixme -- put this information in EEPROM
#define CAL_OFFSET  ( 0 )  // microvolts
#define CAL_GAIN 1.0035
#define TEMP_OFFSET ( 1.5 );  // Celsius offset

// -------------- ADC configuration

#define ADC_RDY 7  // ready bit
#define ADC_C1  6  // channel selection bit 1
#define ADC_C0  5  // channel selection bit 0
#define ADC_CMB 4  // conversion mode bit (1 = continuous)
#define ADC_SR1 3  // sample rate selection bit 1 (11 = 18 bit)
#define ADC_SR0 2  // sample rate selection bit 0
#define ADC_G1  1  // gain select bit 1
#define ADC_G0  0  // gain select bit 0

#define CFG1 (_BV(ADC_CMB) | _BV(ADC_SR1) | _BV(ADC_SR0) ) // 18 bit, gain = 1
#define CFG2 (_BV(ADC_CMB) | _BV(ADC_SR1) | _BV(ADC_SR0) | _BV(ADC_G0) ) // 18 bit, gain = 2 
#define CFG4 (_BV(ADC_CMB) | _BV(ADC_SR1) | _BV(ADC_SR0) | _BV(ADC_G1) ) // 18 bit, gain = 4 
#define CFG8 (_BV(ADC_CMB) | _BV(ADC_SR1) | _BV(ADC_SR0) | _BV(ADC_G1) | _BV(ADC_G0) ) // 18 bit, gain = 8

#define A_BITS9  B00000000
#define A_BITS10 B00100000
#define A_BITS11 B01000000
#define A_BITS12 B01100000

#define BITS_TO_uV 15.625  // LSB = 15.625 uV

// -------------------- MCP9800 configuration
#ifdef RES_12
#define A_BITS A_BITS12
#endif
#ifdef RES_11
#define A_BITS A_BITS11
#endif
#ifdef RES_10
#define A_BITS A_BITS10
#endif
#ifdef RES_9
#define A_BITS A_BITS9
#endif

// --------------------------
#define A_ADC 0x68
#define A_AMB 0x48

// -------------------------- output connections from TC4 to Arduino
int fanpin = 10;               // fan motor connected to pwm pin 10
int heatpin = 9;               // heating coil SSR connected to pin 9

// --------------------------------------------------------------
// global variables

void get_samples();
void get_ambient();
void init_ambient();
void avg_ambient();
void blinker();
void logger();

int countdown;    // count down seconds till end of phase
int overshoot=3;  // max Temp overshoot before turn off heating coil
float slope;      // setpoint slope
int serialTime;   // determine phase
float et;         // Environmental temp, based on t1
float bt;         // Bean temp, based on t2

int ledPin = 13;
//char msg[80];

// updated at intervals of DELAY ms
int32_t samples[NCHAN];
int32_t temps[NCHAN];
int32_t ambs[NAMBIENT];

int32_t ambient = 0;
int32_t amb_f = 0;
int32_t sumamb = 0;
int32_t avgamb = 0;

int adc_delay;

Riser rise1( NSAMPLES );
Riser rise2( NSAMPLES );
Riser rise3( NSAMPLES );
Riser rise4( NSAMPLES );

// LCD output strings
char smin[3],ssec[3],st1[6],st2[6],st3[6],sRoR1[7],sRoR2[7];
//added for PID display
char smode[3];

//char LCD01[16];  //Use this line for a 1 or 2 x 16 LCD
//char LCD02[16];  //Add this line for a 2 x 16 LCD
//Added for 4x20 LDC
char LCD01[20];
char LCD02[20];
char LCD03[20];
char LCD04[20];

// LCD settings for homeroaster wiring
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
  float RoR1,RoR2,t1,t2;

  // print timestamp
  tod = millis() * 0.001;
  Serial.print(tod, DP);

  // print ambient
  Serial.print(",");
  Serial.print( C_TO_F(avgamb * 0.01), DP );
   
  // print temperature, rate for each channel
  i = 0;
  if( NCHAN >= 1 ) {
    Serial.print(",");
    Serial.print( t1 = 0.01 * temps[i], DP );  //Get temp from channel 1
    Serial.print(",");
    Serial.print( RoR1 = rise1.CalcRate( tod, 0.01 * temps[i++] ), DP );  //calculate Rate of change for ch 1
    et = t1;  //set environmental temp to ch 1 temp
  };
  
  if( NCHAN >= 2 ) {
    Serial.print(",");
    Serial.print( t2 = 0.01 * temps[i], DP );  //Get temp from channel 2
    Serial.print(",");
    Serial.print( RoR2 = rise2.CalcRate( tod, 0.01 * temps[i++] ), DP );  //calculate Rate of change for ch 2
    bt = t2;  //set bean temp to ch 2 temp
  };
  
// if( NCHAN >= 3 ) {
//   Serial.print(",");
//   Serial.print( 0.01 * temps[i], DP );
//   Serial.print(",");
//  Serial.print( rise3.CalcRate( tod, 0.01 * temps[i++] ), DP );
// };
  
//  if( NCHAN >= 4 ) {
//    Serial.print(",");
//    Serial.print( 0.01 * temps[i], DP );
//    Serial.print(",");
//    Serial.print( rise4.CalcRate( tod, 0.01 * temps[i++] ), DP );
//  };
  
  Serial.println();
   
  // ----------------------------- LCD output
//Row 1
  // form the TOD output string in min:sec format
  int itod = round( tod );
  if( itod > 3599 ) itod = 3599;
  sprintf( smin, "%02u", itod / 60 );
  sprintf( ssec, "%02u", itod % 60 );

  // channel 1 temperature and RoR
  int it01 = round( t1 );
  if( it01 > 999 ) 
    it01 = 999;
  else
    if( it01 < -999 ) it01 = -999;
  sprintf( st1, "%3d", it01 );

  strcpy( LCD01, smin );
  strcat( LCD01, ":" );
  strcat( LCD01, ssec );
  strcat( LCD01, "       E" );
  strcat( LCD01, st1 );

//Row 2
//Format ET RoR
  int iRoR1 = round( RoR1 );
  if( iRoR1 > 99 ) 
    iRoR1 = 99;
  else
   if( iRoR1 < -99 ) iRoR1 = -99; 
  sprintf( sRoR1, "%0+3d", iRoR1 );

//Format BT RoR
  int iRoR2 = round( RoR2 );
  if( iRoR2 > 99 ) 
    iRoR2 = 99;
  else
   if( iRoR2 < -99 ) iRoR2 = -99; 
  sprintf( sRoR2, "%0+3d", iRoR2 );

  // channel 2 temperature 
  int it02 = round( t2 );
  if( it02 > 999 ) it02 = 999;
  else if( it02 < -999 ) it02 = -999;
  sprintf( st2, "%3d", it02 );

  strcpy( LCD02, "ER");
  strcat( LCD02, sRoR1 );
  strcat( LCD02, " BR");
  strcat( LCD02, sRoR2 );
  strcat( LCD02, " B" );
  strcat( LCD02, st2 );
  
//Write to the LCD
  lcd.home();
  lcd.print(LCD01);
  lcd.setCursor(0,1);
  lcd.print(LCD02);
  
};

// --------------------------------------------------------------------------
void get_samples()
{
  int stat;
  byte a, b, c, rdy, gain, chan, mode, ss;
  int32_t v;
  TC_TYPE tc;
  float tempC;

  Wire.requestFrom(A_ADC, 4);
  a = Wire.receive();
  b = Wire.receive();
  c = Wire.receive();
  stat = Wire.receive();

  rdy = (stat >> 7) & 1;
  chan = (stat >> 5) & 3;
  mode = (stat >> 4) & 1;
  ss = (stat >> 2) & 3;
  gain = stat & 3;
  
  v = a;
  v <<= 24;
  v >>= 16;
  v |= b;
  v <<= 8;
  v |= c;
  
  // convert to microvolts
  v = round(v * BITS_TO_uV);

  // divide by gain
  v /= 1 << (CFG & 3);
  v += CAL_OFFSET;  // adjust calibration offset
  v *= CAL_GAIN;    // calibration of gain
  samples[chan] = v;  // units = microvolts

  // convert mV to temperature using ambient temp adjustment
  tempC = tc.Temp_C( 0.001 * v, avgamb * 0.01 );
  tempC += TEMP_OFFSET;

  // convert to F and multiply by 100 to preserve precision
  v = round( C_TO_F( tempC ) * 100 );
  temps[chan] = v;

  if( NCHAN == ++chan ) chan = 0;

  Wire.beginTransmission(A_ADC);
  Wire.send(CFG | (chan << 5) ); // setup the register for next conversion
  Wire.endTransmission();
}

// ---------------------------------------------------------------------
void get_ambient()
{
  byte a,b;
  int32_t v,va,vb;

  Wire.beginTransmission(A_AMB);
  Wire.send(0); // point to temperature reg.
  Wire.endTransmission();
  Wire.requestFrom(A_AMB, 2);
  a = Wire.receive();
  b = Wire.receive();
  va = a;
  vb = b;
  
#ifdef RES_12
// 12-bit code
  v = ( ( va << 8 ) +  vb ) >> 4;
  v = ( 100 * v ) >> 4;
#endif
#ifdef RES_11
// 11-bit code
  v = ( ( va << 8 ) +  vb ) >> 5;
  v = ( 100 * v ) >> 3;
#endif
#ifdef RES_10
// 10-bit code
  v = ( ( va << 8 ) +  vb ) >> 6;
  v = ( 100 * v ) >> 2;
#endif
#ifdef RES_9
// 9-bit code
  v = ( ( va << 8 ) +  vb ) >> 7;
  v = ( 100 * v ) >> 1;
#endif

 ambient = v;  
}

// --------------------------------------------------------------------
void init_ambient() {
  int i;
  int n;
  n = NAMBIENT;
  if( NAMBIENT < 1 ) n = NAMBIENT; 
  for( i = 0; i < n; i++ ) {
    get_ambient();
    delay( MCP9800_DELAY );
    sumamb += ambient;
    ambs[i] = ambient;
  }
}

// ----------------------------------------------------------------------
void avg_ambient() {
  int i;
  if( NAMBIENT <= 1 ) 
    avgamb = ambient;
  else {
    sumamb += ambient - ambs[0];  // delete oldest value
    for( i = 0; i < NAMBIENT-1; i++ ) {
      ambs[i] = ambs[i+1];
    }
   ambs[NAMBIENT-1] = ambient;
   avgamb = sumamb / NAMBIENT;
  }
}  
  
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
  byte a;
  pinMode(ledPin, OUTPUT);

//  lcd.begin(16, 2); //use for 2x17 LCD
  lcd.begin(19, 4);  //use for 4x20 LCD
  
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
//  if( NCHAN >= 3 ) Serial.print(",T2,rate2");
//  if( NCHAN >= 4 ) Serial.print(",T3,rate3");
  Serial.println();
 
  while ( millis() < 3000) {
    blinker();
    delay(100);
  }

  Wire.begin();

  // configure mcp3424
  Wire.beginTransmission(A_ADC);
  Wire.send(CFG);
  Wire.endTransmission();

  // configure mcp9800.
  Wire.beginTransmission(A_AMB);
  Wire.send(1); // point to config reg
  Wire.send(A_BITS); 
  Wire.endTransmission();

  // see if we can read it back.
  Wire.beginTransmission(A_AMB);
  Wire.send(1); // point to config reg
  Wire.endTransmission();
  Wire.requestFrom(A_AMB, 1);
  a = 0xff;
  if (Wire.available()) {
    a = Wire.receive();
  }
  if (a != A_BITS) {
    Serial.println("# Error configuring mcp9800");
  } else {
    Serial.println("# mcp9800 Config reg OK");
  }
  
  // initialize ambient temperature ring buffer
  init_ambient();
  
  //turn the PID on
  myPID.SetMode(AUTO);

  //Set PWM output frequency
  pwmOut.Setup( T );

}

// -----------------------------------------------------------------
void loop()
{
  float idletime;
  int heat;
  
  // limit sample rate to once per second
  while ( (millis() % 1000) != 0 ) ;  
  timestamp = float(millis()) / 1000.;

  get_ambient();
  avg_ambient();
  for (int i=0; i<NCHAN; i++) {
    get_samples();
    blinker();
    delay( adc_delay );
  }
  logger();   //send data to Com port and LCD, get BT and ET.

 
// go directly to sp during phase 0
 if (phase == 0) {
  Setpoint = Tprofile [phase];                    // jump directly to setpoint in first phase
  if (et >= (Setpoint - 10) ) { countdown=-1;}   // start phase 1 when setpoint is reached
 }

// if countdown ends, start new phase and count down
if (countdown < 0) {
phase = phase + 1;
serialTime = millis () / 1000;
serialTime = serialTime + (Sprofile [phase]);
slope =  ( (Tprofile [phase]) - (Tprofile [(phase - 1)]) );
slope =  (slope / (Sprofile [phase]));
}

// check to see if at the end of the roast profile
if (phase > maxphase) {
 pwmOut.Out( 0,100 ); //shut off heater, leave fan on full
 lcd.clear();
 lcd.home();
 lcd.print("Roast Complete");
 lcd.setCursor(0,1);
 lcd.print("  turn off");
 lcd.setCursor(0,2);
 lcd.print("  when cool");
 while (1>0) {  //wait forever, until power down
 }
}

// determine setpoint during phase 1+
if (phase > 0) {
 countdown = serialTime - ((millis ())/1000);
 Setpoint = Tprofile [(phase - 1)] + (slope *  ((Sprofile [phase]) - countdown));
}

// PID control, adjust heater output 
Input = et;  //input to PID is Environmental Temp
myPID.Compute();

//map function calulates a value from one range to another map(value, fromLow, fromHigh, toLow, toHigh)
heat =  map (Output,0,255,0,100); 
// analogWrite (heatpin, Output);
pwmOut.Out( heat, heat );


// Print LCD Line 3 with PID info
  lcd.setCursor(0,2);
  lcd.print("Ph: ");
  lcd.print(phase);
  lcd.setCursor(8,2);
  lcd.print("Out: ");
  lcd.print(heat);

// Print LCD Line 4 with more PID info
  lcd.setCursor(0,3);
  lcd.print("sp: ");
  lcd.print(Setpoint);

  lcd.print(" cnt: ");
  lcd.print(countdown);

  idletime = float(millis()) / 1000.;
  idletime = 1.0 - (idletime - timestamp);
  // arbitrary: complain if we don't have at least 10mS left
  if (idletime < 0.010) {
    Serial.print("# idle: ");
    Serial.println(idletime);
  }

}

