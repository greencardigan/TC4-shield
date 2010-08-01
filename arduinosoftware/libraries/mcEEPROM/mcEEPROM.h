/*
 * mcEEPROM.h
 *
 *  Created on: Jul 27, 2010
 *      Author: Jim Gallt
 *      Copyright (C) 2010 MLG Properties, LLC
 *      All rights reserved.
 *
 *      Version 20100731
 */

#ifndef MCEEPROM_H_
#define MCEEPROM_H_

#include <WProgram.h>
#include <Wire.h>

#define ADDR_BITS B1010000
#define BUFFER_SIZE 32 // as defined in Wire.h
//#define BUFFER_SIZE 1 // as defined in Wire.h
#define DELAY delay(5)
#define MAX_COUNT 1024

class mcEEPROM {
public:
	mcEEPROM( uint8_t select = ADDR_BITS );
	uint16_t write( uint16_t ptr, uint8_t* barray, uint16_t count = 1); // returns number written
	uint16_t write( uint16_t ptr, char str[] );
	uint16_t write( uint16_t ptr, float f[] );
	uint16_t write( uint16_t ptr, int m[] );
	uint16_t read( uint16_t ptr, uint8_t* barray, uint16_t count = 1 ); // returns number read
	uint16_t read( uint16_t ptr, char str[] );
	uint16_t read( uint16_t ptr, float f[] );
	uint16_t read( uint16_t ptr, int m[] );
protected:
private:
	uint8_t chip_addr;
};

#endif /* MCEEPROM_H_ */
