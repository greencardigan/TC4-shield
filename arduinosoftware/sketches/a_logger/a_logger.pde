// 4-chan TC w/ mcp3424 and mcp9800 using only standard Aurdino libraries

char *banner = "logger06";

#include <Wire.h>

#define A_ADC 0x68
#define A_AMB 0x48

#define MICROVOLT_TO_C 40.69

#define CFG 0x1C  // gain=1
// #define CFG 0x1D    // gain=2
// #define CFG 0x1E    // gain=4

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
  //sprintf(msg, "t=%ld, %ld, %ld, %ld", tod, samples[ch0], temps[ch0], ambient);
  Serial.print(tod);
  Serial.print(",");
//  Serial.print("\t");
  Serial.print(amb_f);
  Serial.print(",");
//  Serial.print("\t");
  for (int i=0; i<4; i++) {
    // Serial.print(temps[i]);
    Serial.print(samples[i]);
    if (i < 3) Serial.print(",");
//    if (i < 3) Serial.print("\t");
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
  
  // sprintf(msg, "0x%x, %x, %x, %x, %x, %x, %ld", stat, rdy, chan, mode, ss, gain, v);
  // Serial.print(msg);

  // convert to microvolts
  // divide by gain
  v = round(v * 15.625);
  v /= 1 << (CFG & 3);
  samples[chan] = v;  // units = microvolts

  // sprintf(msg, ", %ld", v);
  // Serial.print(msg);

  v = round(v / MICROVOLT_TO_C);

  v += ambient;

  // convert to F
  v = round(v * 1.8);
  v += 32;
  temps[chan] = v;

// FIXME
//if (chan == 0) {
  //static int32_t x = 0;
  //temps[chan] = x++;
//}

  // sprintf(msg, ", %ld", v);
  // Serial.println(msg);

  chan++;
  chan &= 3;
  Wire.beginTransmission(A_ADC);
  Wire.send(CFG | (chan << 5) );
  Wire.endTransmission();
}

void get_ambient()
{
  byte a;
  int32_t v;

  Wire.beginTransmission(A_AMB);
  Wire.send(0); // point to temperature reg.
  Wire.endTransmission();
  Wire.requestFrom(A_AMB, 1);
  a = Wire.receive();
  
  v = a;
  // FIXME: test temps below freezing.
  v <<= 24;
  v >>= 24;
  ambient = v;

  // convert to F
  //v = round(v * 1.8);
  //v += 32;
  amb_f = v;
}

void blinker()
{
  static char on = 0;
  if (on) {
    digitalWrite(ledPin, HIGH);
//  digitalWrite(ledPin, LOW);
  } else {
      digitalWrite(ledPin, LOW);
//    digitalWrite(ledPin, HIGH);
  }
  on ^= 1;
}

void setup()
{
  byte a;
  pinMode(ledPin, OUTPUT);     
  //Serial.begin(57600);
  Serial.begin(9600);   // JGG changed to suit laptop

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
  Wire.send(0); // 9-bit mode
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
  if (a != 0) {
    Serial.println("# Error configuring mcp9800");
  } else {
    Serial.println("# mcp9800 Config reg OK");
  }
}



