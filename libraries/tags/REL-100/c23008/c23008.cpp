//Generic library for MCP23008 port expander
// Ports library definitions
// 10-20-2010 <patf11@hotmail.com> http://opensource.org/licenses/mit-license.php


#include <Wire.h>
#include <avr/pgmspace.h>
#include "c23008.h"
#include <WProgram.h>

void c23008Expander::begin(uint8_t unit) {

  deviceAddress = unit;

  Wire.beginTransmission(BASE_ADDRESS | deviceAddress);
  Wire.send(IODIR);
  Wire.send(0xFF);  // all inputs
  Wire.endTransmission();
}

void c23008Expander::begin(void) {
  begin(0);
}

void c23008Expander::begin(uint8_t unit, uint8_t ports) {
  begin(unit);
  setPullups(ports);
  setInverse(ports);
}

void c23008Expander::setInputs(uint8_t ports) {

  Wire.beginTransmission(BASE_ADDRESS | deviceAddress);
  Wire.send(IODIR);
  Wire.send(ports);	
  Wire.endTransmission();
}

void c23008Expander::setPullups(uint8_t ports) {
  Wire.beginTransmission(BASE_ADDRESS | deviceAddress);
  Wire.send(GPPU);
  Wire.send(ports);	
  Wire.endTransmission();
}

void c23008Expander::setInverse(uint8_t ports) {
  Wire.beginTransmission(BASE_ADDRESS | deviceAddress);
  Wire.send( IPOL );
  Wire.send(ports);	
  Wire.endTransmission();
}


uint8_t c23008Expander::readByte(void) { 
  // read the current GPIO
  Wire.beginTransmission(BASE_ADDRESS | deviceAddress);
  Wire.send(GPIO);	
  Wire.endTransmission();  
  Wire.requestFrom(BASE_ADDRESS | deviceAddress, 1);
  return Wire.receive();
}

void c23008Expander::writeByte(uint8_t data) {

  Wire.beginTransmission(BASE_ADDRESS | deviceAddress);
  Wire.send(GPIO);
  Wire.send(data);	
  Wire.endTransmission();
}
