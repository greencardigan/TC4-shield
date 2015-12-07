// MCP23017.h
// definitions ofr MCP23017 port expander

// Revision history:
//  20120126: Arduino 1.0 compatibility

#ifndef MCP23017_h
#define MCP23017_h

#if defined(ARDUINO) && ARDUINO >= 100
#include <Arduino.h>
#else
#include <WProgram.h>
#endif

// control register bits
#define BANK (uint8_t)B10000000 // bank = 1, 8 bit operation
#define MIRROR (uint8_t)B01000000
#define SEQOP (uint8_t)B00100000
#define DISSLW (uint8_t)B00010000
#define HAEN (uint8_t)B00001000
#define ODR (uint8_t)B00000100
#define INTPOL (uint8_t)B00000010

#define MCP23_ADDR (uint8_t)B0100100 // A2 = 1, A1 = A0 = 0
#define LCDPINS (uint8_t)B00001111 // data pins for 4-bit LCD interface
#define BKLTPIN (uint8_t)B10000000 // pin controls the backlight
#define RWPIN   (uint8_t)B01000000 // R/W pin needs to be held low
#define ENPIN   (uint8_t)B00100000
#define RSPIN   (uint8_t)B00010000
#define DB7     (uint8_t)B00001000
#define DB6     (uint8_t)B00000100
#define DB5     (uint8_t)B00000010
#define DB4     (uint8_t)B00000001


// registers
#define IODIRA (uint8_t)0x00
#define IODIRB (uint8_t)0x10
#define IPOLA (uint8_t)0x01
#define IPOLB (uint8_t)0x11
#define GPINTENA (uint8_t)0x02
#define GPINTENB (uint8_t)0x12
#define DEFVALA (uint8_t)0x03
#define DEFVALB (uint8_t)0x13
#define INTCONA (uint8_t)0x04
#define INTCONB (uint8_t)0x14
#define IOCON (uint8_t)0x05 // address when BANK = 1
#define IOCONZ (uint8_t)0x0B  // address when BANK = 0
#define GPPUA (uint8_t)0x06
#define GPPUB (uint8_t)0x16
#define INTFA (uint8_t)0x07
#define INTFB (uint8_t)0x17
#define INTCAPA (uint8_t)0x08
#define INTCAPB (uint8_t)0x18
#define GPIOA (uint8_t)0x09
#define GPIOB (uint8_t)0x19
#define OLATA (uint8_t)0x0A
#define OLATB (uint8_t)0x1A

#endif
