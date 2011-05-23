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
#define BUFFER_SIZE BUFFER_LENGTH // 32 as defined in current Wire.h
#define DELAY delay(5)
//#define MAX_COUNT 1024 // this should not be needed
#define PAGE_SIZE 128
#define STR_MAX 128 // default maximum string variable size
#define MAX_ADDR 0xFFFF // this is a 64K EEPROM

class mcEEPROM {
public:

	mcEEPROM( uint8_t select = ADDR_BITS );

	uint16_t write( uint16_t ptr, uint8_t barray[], uint16_t count = 1); // returns number written
	uint16_t write( uint16_t ptr, char str[] );
	uint16_t write( uint16_t ptr, float f[] );
	uint16_t write( uint16_t ptr, double xx[] );
	uint16_t write( uint16_t ptr, int16_t m[] );
	uint16_t write( uint16_t ptr, uint16_t m[] );
	uint16_t write( uint16_t ptr, int32_t m[] );
	uint16_t write( uint16_t ptr, uint32_t m[] );

	uint16_t read( uint16_t ptr, uint8_t barray[], uint16_t count = 1 ); // returns number read
	uint16_t read( uint16_t ptr, char str[], uint16_t max = STR_MAX );
	uint16_t read( uint16_t ptr, float f[] );
	uint16_t read( uint16_t ptr, double xx[] );
	uint16_t read( uint16_t ptr, int16_t m[] );
	uint16_t read( uint16_t ptr, uint16_t m[] );
	uint16_t read( uint16_t ptr, int32_t m[] );
	uint16_t read( uint16_t ptr, uint32_t m[] );

protected:
	uint16_t bytesOnPage( uint16_t ptr ); // returns bytes remaining till end of page

private:
	uint8_t chip_addr;
};

#endif /* MCEEPROM_H_ */
