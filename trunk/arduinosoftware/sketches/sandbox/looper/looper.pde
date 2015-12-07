//#include <cADC.h>
#include <LiquidCrystal.h>
#include <TypeT.h>
#include <Wire.h>
#include <cADC.h>

#define A_ADC 0x68
#define CFG B10001111 // configuration for one shot mode
//#define CFG B10011111 // configuration for continuous mode
#define BITS_TO_uV 15.625
#define AMB_LSB 0.0625
#define AMB_FILTER 70 // level of digital filtering on amb temp signal

#define A_AMB 0x48
#define ACFG B11100001 // one shot mode, 12-bit resolution on MCP9800
#define SHUTDOWN B00000001 // puts device in shutdown mode

TypeT tc;
filterRC famb;
ambSensorF as;

uint8_t cfg = CFG;
uint8_t acfg = ACFG;
uint8_t adc = A_ADC;
uint8_t amb = A_AMB;
int32_t uv[4];
float c[4];  // ambient temperatures
float t[4]; // temperatures
int anlg = 0; // analog input
uint32_t time;

// LCD interface definition
#define RS 2
#define ENABLE 4
#define DB4 7
#define DB5 8
#define DB6 12
#define DB7 13
LiquidCrystal lcd( RS, ENABLE, DB4, DB5, DB6, DB7 );

// ----------------------------------
void checkStatus( uint32_t ms ) {
  uint32_t tod = millis();
  int32_t aval = 0;
  while( millis() < tod + ms ) {
   aval = analogRead( anlg );
   aval *= 100;
   aval /= 1024;
   //delay(100);
   lcd.setCursor( 13, 1 );
   lcd.print( aval ); lcd.print("%");
//   Serial.println( aval, DEC );
  };
}

// ------------------------------------
void nextConversion( uint8_t chan ) {
  Wire.beginTransmission( adc );
  Wire.send( cfg | ( chan << 5 ) );
  Wire.endTransmission();
//  Serial.println( cfg | ( chan << 5 ), BIN );
}

// ----------------------------------
int32_t getuV( uint8_t chan ) {
  uint8_t a, b, c, stat, gain;
  uint8_t byte5;
  uint8_t rdy, mode, ss;
  int32_t v;
  float xv;
  Wire.requestFrom( adc, (uint8_t)4 );
//  Serial.println( Wire.available(), DEC );
  a = Wire.receive();
  b = Wire.receive();
  c = Wire.receive();
  stat = Wire.receive();
  gain = stat & B11;
//  byte5 = Wire.receive();
//  Serial.print( a, BIN ); Serial.print(" / ");
//  Serial.print( b, BIN ); Serial.print(" / ");
//  Serial.print( c, BIN ); Serial.print(" / ");
//  Serial.print( stat, BIN ); Serial.print(" / ");
//  Serial.println();
//  Serial.println( byte5, BIN );
//  rdy = ( stat >> 7 ) & B01;
//  Serial.println( rdy, DEC );
  
  v = a;
  v <<= 24;
  v >>= 16;
  v |= b;
  v <<= 8;
  v |= c;
  
  xv = v;
  v = round( xv * BITS_TO_uV );
  v >>= gain;
  return v;
}

// ---------------------------------------
void ambConfig() {
  Wire.beginTransmission( amb );
  Wire.send( 1 ); // configuration register
  Wire.send( (uint8_t)SHUTDOWN ); // must put in shutdown mode first for one shot
  Wire.endTransmission();
}


// -------------------------------------------
void nextAmbient() {
  Wire.beginTransmission( amb );
  Wire.send( 1 ); // configuration register
  Wire.send( acfg ); // request a one-shot conversion
  Wire.endTransmission();
}

// -------------------------------------------
float readAmbientC() {
  uint8_t a, b;
  int32_t v, va, vb;
  Wire.beginTransmission( amb );
  Wire.send( 0 ); // temperature register
  Wire.endTransmission();
  Wire.requestFrom( amb, (uint8_t)2 );
  va = a = Wire.receive();
  vb = b = Wire.receive();
  v = ( ( va << 8 ) +  vb ) >> 4; // LSB = 0.0625C
  v = famb.doFilter( v );
  return AMB_LSB * (float)v;
}

void setup() {
  Serial.begin( 57600 );
  Wire.begin();
  lcd.begin(16, 2);
  // put ambient sensor in shutdown mode to enable one-shot
  ambConfig();
  famb.init( AMB_FILTER ); // % filtering for ambient temps
  time = millis();
}

void loop() {
  int32_t tt;
  for( uint8_t i = 0; i < 2; i++ ) {
    nextConversion( i );
    nextAmbient();
    checkStatus( 300 );
    uv[i] = getuV( i );
    c[i] = readAmbientC();
//    tt = micros();
    t[i] = C_TO_F(tc.Temp_C( 0.001 * uv[i], c[i] ));
    t[i] = 0.1 * round( 10.0 * t[i] );
//    tt = micros() - tt;
//    Serial.print( "tc conversion = "); Serial.println( tt );
  }
  Serial.println( t[0] ); //Serial.print(" / "); Serial.println( c[0], DEC );
  Serial.println( t[1] ); //Serial.print(" / "); Serial.println( c[1], DEC );
//  Serial.println( uv[2], DEC );
//  Serial.println( uv[3], DEC );
  
  lcd.setCursor( 0, 0 );
  lcd.print( t[0] ); lcd.print(" ");
  lcd.print( t[1] );
  lcd.setCursor( 0, 1 );
  lcd.print( C_TO_F(c[0]) ); lcd.print(" ");
  lcd.print( C_TO_F(c[1]) );
  Serial.println( millis() - time );
  Serial.println("-------------------");
  time = millis();
}


