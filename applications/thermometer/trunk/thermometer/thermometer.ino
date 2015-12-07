// THERMOMETER
// simple program using TC4 to measure and display temperatures
// this is the most basic use of the TC4
// temperatures are output to the serial monitor (set up for 57600 baud)

#include <Wire.h> // Arduino I2C library

// these TC4 libraries must be present in your sketchbook libraries folder
#include <thermocouple.h>
#include <cADC.h>

#define MIN_DELAY 300 // minimum time needed to perform ADC conversions
#define TC_TYPE typeT // thermocouple must be typeT, typeK, or typeJ

// class objects
cADC adc( A_ADC ); // set up the MCP3424 chip with standard I2C address
ambSensor amb( A_AMB ); // set up the MCP9800 chip with standard I2C address
TC_TYPE tc; // thermocouple object

// ----------------------------------------------
// this function reads a temperature from the TC4
float read_thermocouple() {
  float t_amb; // ambient temperature reading from MCP9800
  int32_t v; // 32 bit temperature microvolt value read from MCP3424
  float mv; // millivolt reading from MCP3424
  float tempC, tempF; // temperature values
  uint32_t tod; // time of day, used in delay loop
  
  adc.nextConversion( 0 ); // start the reading on channel 0 of MCP3424
  amb.nextConversion(); // start the reading on MCP9800
  
  tod = millis(); // read the system clock
  while( millis() < tod + MIN_DELAY ) { // wait for chips to get done
  }
  
  amb.readSensor(); // retrieve value from MCP9800
  t_amb = amb.getAmbC(); // convert to temperature reading
  v = adc.readuV(); // retrieve microvolt sample from MCP3424
  mv = 0.001 * v; // convert to millivolts
  tempC = tc.Temp_C( mv, t_amb ); // perform thermocouple calculation
  tempF = C_TO_F( tempC ); // convert to F units
  // return tempC;
  return tempF;
}

// -----------------------------------------
// setup
void setup() {
  Wire.begin(); // initiate I2C communications
  Serial.begin( 57600 ); // initiate serial communications
  amb.setOffset( -0.50 ); // standard approx. offset correction
  adc.setCal( 1.003, 0.0 ); // some standard values for calibration
}

// -----------------------------------------
// main loop
void loop() {
  Serial.println( read_thermocouple(), 1 ); // print current temperature reading
}

