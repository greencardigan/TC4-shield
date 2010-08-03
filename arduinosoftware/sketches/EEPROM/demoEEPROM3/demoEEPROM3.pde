
#include <mcEEPROM.h>
#include <Wire.h>

struct infoBlock {
  char PCB[40]; // identifying information for the board
  char version[16];
  float cal_gain;  // calibration factor of ADC at 50000 uV
  int16_t cal_offset; // uV, probably small in most cases
  float T_offset; // temperature offset (Celsius) at 0.0C (type T)
  float K_offset; // same for type K
};

infoBlock infotx = {
  "TC4_SHIELD",
  "1.06RE",
  1.00166,
  -3,
  -0.50,
  -0.50
};

infoBlock inforx = {
  "",
  "",
  0.0,
  0,
  0.0,
  0.0
};

mcEEPROM ep;

void setup() {
  
  delay( 1000 );
  
  ep.write( 0, (uint8_t*) &infotx, sizeof( infotx ) );
  ep.read( 0, (uint8_t*) &inforx, sizeof( inforx ) );
  
  Serial.begin(57600);
  Serial.println(inforx.PCB);
  Serial.println(inforx.version);
  Serial.println(inforx.cal_gain, DEC);
  Serial.println(inforx.cal_offset);
  Serial.println(inforx.T_offset);
  Serial.println(inforx.K_offset);
  
}

void loop() {
}

  
  
