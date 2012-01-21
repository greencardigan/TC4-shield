// This sketch writes calibration block information to EEPROM
// WARNING:  it will overwrite existing calibration block information

// Author:  Jim Gallt

// Use this sketch to initialize the EEPROM on a TC4 shield to default values, or
// to values determined by calibration.

// Open a serial monitor (57600 baud) screen in the Arduino IDE to confirm that the values were
// correctly written and can be read back from the EEPROM.

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
  "TC4C_CONTROLLER",
  "1.10",  // edit this field to comply with the version of your TC4 board
  1.00, // gain
  0, // uV offset
  -0.0, // type T offset temp
  -0.0 // type K offset temp
};

infoBlock inforx = {
  "",
  "",
  -99.0,
  -99,
  -99.0,
  -99.0
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

  
  
