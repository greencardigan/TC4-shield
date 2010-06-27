// 4-chan TC w/ mcp3424 and mcp9800 using only standard Aurdino libraries
// Bill Welch 2010 http://github.com/bvwelch/arduino
// MIT license: http://opensource.org/licenses/mit-license.php
// Note: this small example is for K-type thermocouples only.
// FIXME: use Jim Gallt's library for a full-featured logger.
//       http://code.google.com/p/tc4-shield/ 

char *banner = "logger08b";

#include <Wire.h>

#define A_ADC 0x68
#define A_AMB 0x48

#define MICROVOLT_TO_C 40.69 // K-type only, linear approx.

#define CFG 0x1C  // gain=1
// #define CFG 0x1D    // gain=2
// #define CFG 0x1E    // gain=4

#define A_BITS12 B01100000

void get_samples();
void get_ambient();
void blinker();
void logger();

int ledPin = 13;
char msg[80];

// updated every two seconds
int32_t samples[4];
int32_t temps[4];

int32_t ambient = 0;
int32_t amb_f = 0;

void loop()
{
  get_ambient();
  for (int i=0; i<4; i++) {
    get_samples();
    blinker();
    delay(500);
  }
  logger();
}

void logger()
{
  unsigned long tod;

  tod = millis() / 1000;
  Serial.print(tod);
  Serial.print(",");
  Serial.print(amb_f);
  Serial.print(",");
  for (int i=0; i<4; i++) {
    Serial.print(temps[i]);
    if (i < 3) Serial.print(",");
  }
  Serial.println();
}

void get_samples()
{
  int stat;
  byte a, b, c, rdy, gain, chan, mode, ss;
  int32_t v;

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
  // divide by gain
  v = round(v * 15.625);
  v /= 1 << (CFG & 3);
  samples[chan] = v;  // units = microvolts

  v = round(v / MICROVOLT_TO_C);

  v += ambient;

  // convert to F
  v = round(v * 1.8);
  v += 32;
  temps[chan] = v;

  chan++;
  chan &= 3;
  Wire.beginTransmission(A_ADC);
  Wire.send(CFG | (chan << 5) );
  Wire.endTransmission();
}

// FIXME: test temps below freezing.
void get_ambient()
{
  byte a, b;
  int32_t v;

  Wire.beginTransmission(A_AMB);
  Wire.send(0); // point to temperature reg.
  Wire.endTransmission();
  Wire.requestFrom(A_AMB, 2);
  a = Wire.receive();
  b = Wire.receive();

  v = a;
  
  // handle sign-bit
  v <<= 24;
  v >>= 24;

  // round up if fraction is >= 0.5
  if (b & 0x80) v++;

  ambient = v;

  // convert to F
  v = round(v * 1.8);
  v += 32;
  amb_f = v;
}

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

void setup()
{
  byte a;
  pinMode(ledPin, OUTPUT);     
  Serial.begin(57600);

  while ( millis() < 3000) {
    blinker();
    delay(500);
  }

  sprintf(msg, "\n# %s: 4-chan TC", banner);
  Serial.println(msg);
  Serial.println("# time,ambient,T0,T1,T2,T3");
 
  while ( millis() < 6000) {
    blinker();
    delay(500);
  }

  Wire.begin();

  // configure mcp3424
  Wire.beginTransmission(A_ADC);
  Wire.send(CFG);
  Wire.endTransmission();

  // configure mcp9800.
  Wire.beginTransmission(A_AMB);
  Wire.send(1); // point to config reg
  Wire.send(A_BITS12); // 12-bit mode
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
  if (a != A_BITS12) {
    Serial.println("# Error configuring mcp9800");
  } else {
    Serial.println("# mcp9800 Config reg OK");
  }
}

